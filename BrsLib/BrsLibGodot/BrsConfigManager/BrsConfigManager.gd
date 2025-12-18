@tool
extends Node
class_name BrsConfigManager

# -------------------------------------------------------
#  Equivalent Fields
# -------------------------------------------------------

var parent_node: Node = null
@export var default_config_file_path: String = "res://config.json"

var config_data: Dictionary = {}
var logger          # Will assign your Logger.gd later

# -------------------------------------------------------
#  Constructor Equivalent
# -------------------------------------------------------

func _init():
	logger = Logger.new()
	Logger.session_timestamp = Time.get_datetime_string_from_system()
	Logger.log_file_path = "user://logs/"
	var _log_file_name = "BrsConfigManager"
	logger.set_logger(_log_file_name)
	Logger.set_enabled_tags(['i','e','w'])


# -------------------------------------------------------
#  Initialize Defaults
# -------------------------------------------------------

func initialize_default_config(default_config: Dictionary) -> void:
	logger.log("(BrsConfigManager.initialize_default_config) Initializing configuration with provided default values.", ['i'])

	for key in default_config.keys():
		set_config(key, default_config[key])
		logger.log("(BrsConfigManager.initialize_default_config) key:%s value:%s" % [key, default_config[key]], ['i'])

	logger.log("(BrsConfigManager.initialize_default_config) Default configuration initialized.", ['i'])

	var file_path := ProjectSettings.globalize_path(default_config_file_path)
	if not FileAccess.file_exists(file_path):
		save_config()
		logger.log("(BrsConfigManager.initialize_default_config) No config file found, created new at %s" % default_config_file_path, ['i'])


# -------------------------------------------------------
#  Save Config
# -------------------------------------------------------

func save_config() -> void:
	var file_path := ProjectSettings.globalize_path(default_config_file_path)
	logger.log("(BrsConfigManager.save_config) Started!", ['i'])

	var godot_dict := config_data.duplicate()

	# Delete old file
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

	var json_string := JSON.stringify(godot_dict)

	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		logger.log("(BrsConfigManager.save_config) Failed to open file: %s" % file_path, ['e'])
		return

	file.store_string(json_string)
	file.close()

	logger.log("(BrsConfigManager.save_config) Configuration saved to %s" % file_path, ['i'])


# -------------------------------------------------------
#  Load Config
# -------------------------------------------------------

func load_config() -> void:
	logger.log("(BrsConfigManager.load_config) Started!", ['i'])

	var file_path := default_config_file_path
	var full_path := ProjectSettings.globalize_path(file_path)

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		logger.log("(BrsConfigManager.load_config) Failed to open file: %s file is null." % file_path, ['e'])
		return

	logger.log("(BrsConfigManager.load_config) Opened file: %s successfully!" % file_path, ['i'])

	var json_text := file.get_as_text()
	var result := JSON.parse_string(json_text)

	if result is Dictionary:
		if result.size() == 0:
			logger.log("(BrsConfigManager.load_config) File empty or no valid values: %s" % file_path, ['e'])
			return

		config_data = result.duplicate()
		logger.log("(BrsConfigManager.load_config) Configuration loaded from %s" % file_path, ['i'])

		for k in config_data.keys():
			logger.log("(BrsConfigManager.load_config) Configuration Detail: %s : %s" % [k, config_data[k]], ['i'])
	else:
		logger.log("(BrsConfigManager.load_config) Failed to parse config file: %s" % file_path, ['e'])


# -------------------------------------------------------
#  Get / Set
# -------------------------------------------------------

func get_config(key: String):
	if config_data.has(key):
		logger.log("(BrsConfigManager.get) key %s found, value: %s" % [key, config_data[key]], ['i'])
		return config_data[key]

	logger.log("(BrsConfigManager.get) key %s NOT found!" % key, ['e'])
	return null


func set_config(key: String, value) -> void:
	config_data[key] = value
	logger.log("(BrsConfigManager.set) set key %s to value %s" % [key, str(value)], ['i'])


# -------------------------------------------------------
#  Utility
# -------------------------------------------------------

func pretty_print_json(json_string: String) -> String:
	var data = JSON.parse_string(json_string)
	if data == null:
		return json_string
	return JSON.stringify(data, "\t")  # Pretty-print with tabs
