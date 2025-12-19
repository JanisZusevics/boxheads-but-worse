extends CharacterBody2D

@export var move_speed: float = 300
@export var wander_radius := 120
@export var idle_time_range := Vector2(0.3, 2.0)

@export var starting_direction: Vector2 = Vector2(0, -1)

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

# Keep if you still want it later (not used in pure wandering)
@export var player: Node2D

enum AIState { IDLE, WANDER }
var ai_state: AIState = AIState.IDLE

var idle_timer := 0.0
var target_position: Vector2

func _ready():
	animation_tree.set("parameters/idle/blend_position", starting_direction)
	_start_idle()

func _physics_process(delta):
	match ai_state:
		AIState.IDLE:
			_process_idle(delta)
		AIState.WANDER:
			_process_wander(delta)

	# Animation logic retained
	update_animation_parameters(_get_move_input())
	pick_new_state()

	move_and_slide()

func _process_idle(delta):
	idle_timer -= delta
	velocity = Vector2.ZERO

	if idle_timer <= 0.0:
		_pick_new_target()
		ai_state = AIState.WANDER

func _process_wander(delta):
	var to_target := target_position - global_position

	# Arrived → idle again
	if to_target.length() < 6.0:
		_start_idle()
		return

	var input_direction := to_target.normalized()
	velocity = input_direction * move_speed

func _start_idle():
	ai_state = AIState.IDLE
	idle_timer = randf_range(idle_time_range.x, idle_time_range.y)

func _pick_new_target():
	target_position = global_position + Vector2(
		randf_range(-wander_radius, wander_radius),
		randf_range(-wander_radius, wander_radius)
	)

# --- Your animation logic (kept) ---

func update_animation_parameters(move_input: Vector2):
	if move_input != Vector2.ZERO:
		animation_tree.set("parameters/walk/blend_position", move_input)
		animation_tree.set("parameters/idle/blend_position", move_input)

func pick_new_state():
	if velocity != Vector2.ZERO:
		state_machine.travel("walk")
	else:
		state_machine.travel("idle")

# Helper so animation uses the direction you’re *trying* to move
func _get_move_input() -> Vector2:
	if velocity == Vector2.ZERO:
		return Vector2.ZERO
	return velocity.normalized()
