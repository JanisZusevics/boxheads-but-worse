@tool
extends Button

func _ready() -> void:
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var editor_interface = EditorPlugin.new().get_editor_interface()
	editor_interface.restart_editor(true)
