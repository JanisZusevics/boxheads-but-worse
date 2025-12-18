@tool
extends Panel

# This exposes the type globally
class_name BrsSSS_Panel

@export var editor_plugin : EditorPlugin

var ConfigManager = BrsConfigManager.new()

# -----------------------------------------------------------
# UI node declarations
# -----------------------------------------------------------

var nodeToMethod_Button : Button
var nodeToVar_Button : Button

var selectedToCustom1_Button : Button
var customTemplate1_TextEdit : TextEdit

var selectedToCustom2_Button : Button
var customTemplate2_TextEdit : TextEdit

var selectedToCustom3_Button : Button
var customTemplate3_TextEdit : TextEdit

var node1_Button : Button
var node2_Button : Button

var delGDtemp_Button : Button

var disableAddons_Button : Button
var enableAddons_Button : Button
var restartAddons_Button : Button

var createNodeTemplate_Button : Button

var openUserFolder_Button : Button
var openProjectFolder_Button : Button

var addonNames_TextEdit : TextEdit

var toggleScriptLanguage_CheckButton : Button
var gotIt_Button : Button
var manual_Button : Button
var test_Button : Button
var setUnique_CheckBox : CheckBox

# ------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------

@export var addonNames : Array[String] = []

var buttonPresses := 0
var DefaultBackupOptions : Dictionary
var configFilePath : String = "res://addons/BrsSSS/BrsSSS_config.json"

var selectedNode1 : Node
var selectedNode2 : Node

var useGDscript := false
var editorPlugin : EditorPlugin
var setUnique := false

var timerToAddonMap := {}

# -----------------------------------------------------------
# Constructor-like initialization
# -----------------------------------------------------------
func _init():
	var my_theme : Theme = preload("res://addons/BrsLib/GDThemes/DarkNYellow.tres")
	theme = my_theme

	DefaultBackupOptions = {
		"addonNames_TextEdit": [""],
		"toggleScriptLanguage_CheckButton": false,
		"gotIt_Button": false,
		"customText1": [""],
		"customText2": [""],
		"customText3": [""],
		"setUnique": false
	}


# -----------------------------------------------------------
# Called when node enters the SceneTree
# -----------------------------------------------------------
func _enter_tree():
	ConfigManager.default_config_file_path = "res://addons/BrsSSS/BrsSSS_config.json"

	#ConfigManager = ConfigManager.new()
	ConfigManager.default_config_file_path = configFilePath
	ConfigManager.initialize_default_config(DefaultBackupOptions)
	ConfigManager.parent_node = self
	ConfigManager.load_config()

	InitializeUINodes()


# -----------------------------------------------------------
# UI METHODS
# -----------------------------------------------------------

func OnTest_Button():
	pass


func OnSetUnique_CheckBox(is_toggled: bool):
	setUnique = is_toggled
	ConfigManager.set_config("setUnique", is_toggled)
	SaveConfig()


func MakeSelectedNodeUniqueOld():
	var selected = BrsEditor.get_selected_node()
	if selected == null:
		push_error("No node selected!")
		return
	selected.set_unique_name_in_owner(true)


func OnCustomTemplate1_TextEdit():
	ConfigManager.set("customText1", customTemplate1_TextEdit.text)
	SaveConfig()


func OnCustomTemplate2_TextEdit():
	ConfigManager.set("customText2", customTemplate2_TextEdit.text)
	SaveConfig()


func OnCustomTemplate3_TextEdit():
	ConfigManager.set("customText3", customTemplate3_TextEdit.text)
	SaveConfig()


func OnSelectedToCustom1_Button():
	SelectedNodeToTemplate(customTemplate1_TextEdit)


func OnSelectedToCustom2_Button():
	SelectedNodeToTemplate(customTemplate2_TextEdit)


func OnSelectedToCustom3_Button():
	SelectedNodeToTemplate(customTemplate3_TextEdit)


func SelectedNodeToTemplate(text_edit: TextEdit):
	var custom_code := text_edit.text
	var selected : Node = BrsEditor.get_selected_node()
	if selected == null:
		return

	var template := ReplaceTags(custom_code, selected)
	DisplayServer.clipboard_set(template)


func ReplaceTags(template: String, selected: Node) -> String:
	var placeholders := {
		"NodeType": selected.get_class(),
		"NodeName": selected.name,
		"NodePath": BrsEditor.get_selected_node_path()
	}

	var re := RegEx.new()
	re.compile("<<([^<>]+)>>")
	var result := template

	var matches := re.search_all(result)
	for m in matches:
		var key := m.get_string(1)
		if placeholders.has(key):
			result = result.replace(m.get_string(), str(placeholders[key]))

	if setUnique:
		BrsEditor.detect_and_make_nodes_unique(result, editorPlugin)

	return result


func OnManual_Button():
	var abs := ProjectSettings.globalize_path("res://addons/BrsSSS/Manual/manual.html")
	OS.shell_open(abs)


func OnGotIt_Button():
	var box := get_node("%GotIt_VBoxContainer") as Control
	box.visible = false
	ConfigManager.set("gotIt_Button", true)
	SaveConfig()


func OnToggleScriptLanguage_CheckButton(toggled: bool):
	useGDscript = toggled
	ConfigManager.set("toggleScriptLanguage_CheckButton", toggled)
	SaveConfig()


func SetNode1():
	selectedNode1 = BrsEditor.get_selected_node()


func SetNode2():
	selectedNode2 = BrsEditor.get_selected_node()
	var pathAtoB : String = BrsNode.get_node_a_path_to_b(selectedNode1, selectedNode2)
	DisplayServer.clipboard_set(pathAtoB)


func OnCreateNodeTemplate_Button():
	var selected : Node = BrsEditor.get_selected_node()
	if selected == null:
		return

	var node_name : String = selected.name
	var node_type : String = selected.get_class()
	var node_path : String = BrsEditor.get_selected_node_path();

	if node_path == "":
		return

	var template := ""
	if not useGDscript:
		template = "%s %s;\n%s = %s.get_node(\"%s\")\n%s.pressed += _on_%s\n\nfunc _on_%s():\n\tpass\n" % [
			node_type, node_name,
			node_name, node_type, node_path,
			node_name, node_name,
			node_name
		]
	else:
		template = (
			"var %s = get_node(\"%s\")\n%s.pressed.connect(_on_%s_pressed)\n\nfunc _on_%s_pressed():\n\tpass\n" % [
				node_name, node_path,
				node_name, node_name,
				node_name
			]
		)


	DisplayServer.clipboard_set(template)


func OnCopyNodePath_Get():
	var node_path : String = BrsEditor.get_selected_node_path()
	if node_path == "":
		return

	var ret := ""
	if not useGDscript:
		ret = "GetNode(\"%s\");" % node_path
	else:
		ret = "get_node(\"%s\");" % node_path

	DisplayServer.clipboard_set(ret)


func OnCopyNodePath_Var():
	var node_path : String = BrsEditor.get_selected_node_path()
	if node_path == "":
		return

	var ret := ""
	if not useGDscript:
		ret = "var someVar = GetNode(\"%s\");" % node_path
	else:
		ret = "var some_var = get_node(\"%s\");" % node_path

	DisplayServer.clipboard_set(ret)


func OnCopyNodePathWithMethod_Truncate():
	var selected_nodes : Array[Node] = BrsEditor.get_selected_nodes()
	if selected_nodes.is_empty():
		push_error("Node not found in scene.")
		return

	var p : String = selected_nodes[0].get_path()

	var rev : String  = p.reverse()
	var re := RegEx.new()
	re.compile("/(\\d{4}@)")
	var matches := re.search_all(rev)

	if matches.is_empty():
		push_error("No match for truncation.")
		return

	var rev_mod := re.sub(rev, "", true)
	var final_path := rev_mod.reverse()

	DisplayServer.clipboard_set("GetNode(\"%s\");" % final_path)


func OnDisableAddon_ButtonPressed():
	if addonNames.is_empty():
		addonNames = parse_names(addonNames_TextEdit.text)

	for addon in addonNames:
		if addon != "":
			EditorInterface.set_plugin_enabled(addon, false)
		else:
			push_error("Invalid addon name.")


func OnEnableAddon_ButtonPressed():
	if addonNames.is_empty():
		addonNames = parse_names(addonNames_TextEdit.text)

	for addon in addonNames:
		if addon != "":
			EditorInterface.set_plugin_enabled(addon, true)

		else:
			push_error("Invalid addon name.")


func OnReEnableAddon_ButtonPressed2():
	if addonNames.is_empty():
		addonNames = parse_names(addonNames_TextEdit.text)

	for addon in addonNames:
		if addon != "":
			EditorInterface.set_plugin_enabled(addon, false)

			var timer := Timer.new()
			timer.wait_time = 0.5
			timer.one_shot = true
			timer.autostart = true

			timerToAddonMap[timer] = addon

			timer.timeout.connect(func():
				OnTimerTimeout(timer)
			)

			EditorInterface.get_base_control().add_child(timer)
			timer.start()

func OnReEnableAddon_ButtonPressed():
	if addonNames.is_empty():
		addonNames = parse_names(addonNames_TextEdit.text)

	var ei := editor_plugin.get_editor_interface()

	for addon in addonNames:
		if addon == "":
			push_error("Invalid addon name.")
			continue

		# Disable addon
		ei.set_plugin_enabled(addon, false)

		# Engine-owned timer (survives plugin disable)
		var timer := ei.get_base_control().get_tree().create_timer(0.5)

		timer.timeout.connect(func():
			ei.set_plugin_enabled(addon, true)
		)



func OnTimerTimeout(timer: Timer):
	if timerToAddonMap.has(timer):
		var addon = timerToAddonMap[timer]
		EditorInterface.set_plugin_enabled(addon, true)

		timerToAddonMap.erase(timer)
		timer.queue_free()


func OnrestartEditor_ButtonPressed():
	editor_plugin.restart_editor(true)


func OnDelGDtemp_ButtonPressed():
	var folder := ProjectSettings.globalize_path("res://.godot")
	var dir := DirAccess.open(folder)
	if dir:
		dir.remove_directory_recursive(folder)
		print(".godot deleted")


func OnOpenUserFolder_Button():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"))


func OnOpenProjectFolder_Button():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("res://"))


static func parse_names2(input: String) -> Array:
	if input.strip_edges() == "":
		return []

	var result = []
	for s in input.split(",", false):
		var cleaned = s.strip_edges()  # removes whitespace
		cleaned = cleaned.strip_chars("\"")  # removes quotes
		result.append(cleaned)

	return result

static func parse_names(input: String) -> Array[String]:
	if input.strip_edges() == "":
		return []

	var result: Array[String] = []
	for s in input.split(",", false):
		var cleaned := s.strip_edges()

		# Remove surrounding quotes only
		if cleaned.begins_with("\"") and cleaned.ends_with("\""):
			cleaned = cleaned.substr(1, cleaned.length() - 2)

		result.append(cleaned)

	return result


func OnAddonNames_TextEdit():
	ConfigManager.set("addonNames_TextEdit", addonNames_TextEdit.text)
	SaveConfig()


# -----------------------------------------------------------
# After/Before Serialize (not really needed in GDScript)
# -----------------------------------------------------------
func OnBeforeSerialize():
	UnloadSignals()


func OnAfterDeserialize():
	InitializeUINodes()


# -----------------------------------------------------------
# Initialize all UI nodes and connect signals
# -----------------------------------------------------------
func InitializeUINodes():

	test_Button = get_node("%Test_Button")
	test_Button.pressed.connect(OnTest_Button)

	selectedToCustom1_Button = get_node("%SelectedToCustom1_Button")
	selectedToCustom1_Button.pressed.connect(OnSelectedToCustom1_Button)
	customTemplate1_TextEdit = get_node("%CustomTemplate1_TextEdit")
	customTemplate1_TextEdit.text_changed.connect(OnCustomTemplate1_TextEdit)
	customTemplate1_TextEdit.text = ConfigManager.get_config("customText1")

	selectedToCustom2_Button = get_node("%SelectedToCustom2_Button")
	selectedToCustom2_Button.pressed.connect(OnSelectedToCustom2_Button)
	customTemplate2_TextEdit = get_node("%CustomTemplate2_TextEdit")
	customTemplate2_TextEdit.text_changed.connect(OnCustomTemplate2_TextEdit)
	customTemplate2_TextEdit.text = ConfigManager.get_config("customText2")

	selectedToCustom3_Button = get_node("%SelectedToCustom3_Button")
	selectedToCustom3_Button.pressed.connect(OnSelectedToCustom3_Button)
	customTemplate3_TextEdit = get_node("%CustomTemplate3_TextEdit")
	customTemplate3_TextEdit.text_changed.connect(OnCustomTemplate3_TextEdit)
	customTemplate3_TextEdit.text = ConfigManager.get_config("customText3")

	setUnique_CheckBox = get_node("%SetUnique_CheckBox")
	setUnique_CheckBox.toggled.connect(OnSetUnique_CheckBox)
	setUnique_CheckBox.button_pressed = ConfigManager.get_config("setUnique")

	node1_Button = get_node("%Node1_Button")
	node1_Button.pressed.connect(SetNode1)

	node2_Button = get_node("%Node2_Button")
	node2_Button.pressed.connect(SetNode2)

	delGDtemp_Button = get_node("%DelGDtemp_Button")
	delGDtemp_Button.pressed.connect(OnDelGDtemp_ButtonPressed)

	disableAddons_Button = get_node("%DisableAddons_Button")
	disableAddons_Button.pressed.connect(OnDisableAddon_ButtonPressed)

	enableAddons_Button = get_node("%EnableAddons_Button")
	enableAddons_Button.pressed.connect(OnEnableAddon_ButtonPressed)

	restartAddons_Button = get_node("%RestartAddons_Button")
	restartAddons_Button.pressed.connect(OnReEnableAddon_ButtonPressed)

	openUserFolder_Button = get_node("%OpenUserFolder_Button")
	openUserFolder_Button.pressed.connect(OnOpenUserFolder_Button)

	openProjectFolder_Button = get_node("%OpenProjectFolder_Button")
	openProjectFolder_Button.pressed.connect(OnOpenProjectFolder_Button)

	addonNames_TextEdit = get_node("%AddonNames_TextEdit")
	addonNames_TextEdit.text_changed.connect(OnAddonNames_TextEdit)
	addonNames_TextEdit.text = ConfigManager.get_config("addonNames_TextEdit")

	gotIt_Button = get_node("%GotIt_Button")
	gotIt_Button.pressed.connect(OnGotIt_Button)
	if ConfigManager.get_config("gotIt_Button"):
		gotIt_Button.emit_signal("pressed")

	manual_Button = get_node("%Manual_Button")
	manual_Button.pressed.connect(OnManual_Button)


func UnloadSignals():
	test_Button.pressed.disconnect(OnTest_Button)
	selectedToCustom1_Button.pressed.disconnect(OnSelectedToCustom1_Button)
	customTemplate1_TextEdit.text_changed.disconnect(OnCustomTemplate1_TextEdit)
	selectedToCustom2_Button.pressed.disconnect(OnSelectedToCustom2_Button)
	customTemplate2_TextEdit.text_changed.disconnect(OnCustomTemplate2_TextEdit)
	selectedToCustom3_Button.pressed.disconnect(OnSelectedToCustom3_Button)
	customTemplate3_TextEdit.text_changed.disconnect(OnCustomTemplate3_TextEdit)
	setUnique_CheckBox.toggled.disconnect(OnSetUnique_CheckBox)
	node1_Button.pressed.disconnect(SetNode1)
	node2_Button.pressed.disconnect(SetNode2)
	delGDtemp_Button.pressed.disconnect(OnDelGDtemp_ButtonPressed)
	disableAddons_Button.pressed.disconnect(OnDisableAddon_ButtonPressed)
	enableAddons_Button.pressed.disconnect(OnEnableAddon_ButtonPressed)
	restartAddons_Button.pressed.disconnect(OnReEnableAddon_ButtonPressed)
	openUserFolder_Button.pressed.disconnect(OnOpenUserFolder_Button)
	openProjectFolder_Button.pressed.disconnect(OnOpenProjectFolder_Button)
	addonNames_TextEdit.text_changed.disconnect(OnAddonNames_TextEdit)
	gotIt_Button.pressed.disconnect(OnGotIt_Button)
	manual_Button.pressed.disconnect(OnManual_Button)


func _exit_tree():
	UnloadSignals()


func SaveConfig():
	ConfigManager.save_config()
