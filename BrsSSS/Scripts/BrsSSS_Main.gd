@tool
extends EditorPlugin

var panel
var tool_panel_scene : PackedScene = preload("res://addons/BrsSSS/Scenes/BrsSSS_Panel.tscn")

func _enter_tree():
    panel = tool_panel_scene.instantiate()
    panel.editor_plugin = self  # assuming the panel script has a variable called "editor_plugin"

    add_control_to_dock(DOCK_SLOT_LEFT_UL, panel)


func _exit_tree():
    remove_control_from_docks(panel)
    panel.queue_free()

