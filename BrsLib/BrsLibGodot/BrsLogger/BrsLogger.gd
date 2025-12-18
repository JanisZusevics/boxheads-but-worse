extends RefCounted
class_name Logger

# ---------------------------------------------------------
# STATIC FIELDS (same as C#)
# ---------------------------------------------------------

static var disabled: bool = false
static var brsLogger_enabled_tags: = {}       # Set of chars
static var log_to_file: bool = true
static var log_to_gdprint: bool = false
static var log_to_console: bool = false

# Rolling logs (disabled just like original)
static var roll_logs: bool = false
static var backup_limit_count: int = 10
static var backup_limit_mb: int = 11111111
static var del_mb: bool = false
static var process_interval: int = 10000

static var log_file_path: String = "user://logs/"
static var extension: String = "_Log.txt"
static var timestamp_format: String = "yyyy.MM.dd_HH-mm-ss"
static var session_timestamp: String = ""     # Must be set externally like in C#

static var tag_dict := {
	'i': "[Info]",
	'e': "[Error]",
	'w': "[Warning]",
	'v': "[Value]",
	'c': "[Critical]"
}

# ---------------------------------------------------------
# INSTANCE FIELDS
# ---------------------------------------------------------

var main_log_file_name: String = "MainLog"
var log_file_name: String = "logName"
var current_used_tags: Array
var _indentation_level: int = 0

var _file_lock := Mutex.new()
# File lock simulation (since GDScript does not have `lock`, you can just use a boolean if needed)
#var _file_lock: bool = false

# Tracks the indentation level
var _indentation_levels: Array = [0]  # use a stack implemented as an array



# ---------------------------------------------------------
# STATIC HELPERS
# ---------------------------------------------------------

static func set_enabled_tags(tags: Array) -> void:
	brsLogger_enabled_tags = {}  # Clear
	for t in tags:
		brsLogger_enabled_tags[t] = true


static func char_tag_to_string_tag(chars: Array) -> String:
	var out := ""
	for c in chars:
		out += tag_dict.get(c, "[Unknown]")
	return out


# ---------------------------------------------------------
# INIT
# ---------------------------------------------------------

func _init():
	# Nothing needed here — same as C#
	pass


# ---------------------------------------------------------
# SET LOGGER CONFIG
# ---------------------------------------------------------
func set_logger(_log_file_path: String = "", _main_log_file_name: String = "",
				_log_file_name: String = "", _extension: String = "",
				_timestamp_format: String = "") -> void:

	if _log_file_path != null:
		log_file_path = _log_file_path
	if _main_log_file_name != null:
		main_log_file_name = _main_log_file_name
	if _log_file_name != null:
		log_file_name = _log_file_name
	if _extension != null:
		extension = _extension
	if _timestamp_format != null:
		timestamp_format = _timestamp_format


# ---------------------------------------------------------
# PUBLIC LOG METHODS
# ---------------------------------------------------------

func log(message: String, tags: Array, _log_file_path: String = "",
		 _log_file_name: String = "", _extension: String = "",
		 _roll_logs: bool = false) -> void:

	if disabled:
		return
	if message == "" or message == null:
		push_error("(Logger.log) message cannot be null")
		return
	if tags == null:
		push_error("(Logger.log) tags cannot be null")
		return

	current_used_tags = tags

	# Apply defaults
	var path = _log_file_path if _log_file_path != null else log_file_path
	var name = _log_file_name if _log_file_name != null else log_file_name
	var ext = _extension    if _extension != null    else extension

	if _roll_logs != null:
		roll_logs = _roll_logs

	# Tag filtering
	var any_enabled := false
	for t in tags:
		if brsLogger_enabled_tags.has(t):
			any_enabled = true
			break

	if not any_enabled:
		return

	if log_to_file:
		var sec_path := get_file_path(path, name, ext, session_timestamp)
		var main_path := get_file_path(log_file_path, main_log_file_name, extension, session_timestamp)

		var formatted := format_message_with_indent(message)

		write_log(main_path, formatted)
		if sec_path != main_path:
			write_log(sec_path, formatted)

	if log_to_gdprint:
		print("%s: %s - %s" % [name, message, Time.get_datetime_string_from_system()])

	if log_to_console:
		print_rich("[console]%s: %s[/console]" % [name, message])


func log_to_new(_message: String, _tags: Array, _log_file_path: String = "", _log_file_name: String = "", _extension: String = "") -> void:
	if disabled:
		return

	if _message == null:
		# GD.PrintErr("(Logger.Log) _message can't be null!!!")
		return
	if _tags == null:
		# GD.PrintErr("(Logger.Log) _tags is null, it needs at least one char like 'i'")
		return

	_log_file_path = _log_file_path if _log_file_path != null else log_file_path
	_log_file_name = _log_file_name if _log_file_name != null else log_file_name
	_extension = _extension if _extension != null else extension

	if log_to_file:
		# Godot 4+
		var new_timestamp = Time.get_datetime_string_from_system(false, false)

		var new_secondary_log_file_path = get_file_path(_log_file_path, _log_file_name, _extension, new_timestamp)
		var main_log_file_path = get_file_path(log_file_path, main_log_file_name, extension, session_timestamp)
		var indented_message = format_message_with_indent(_message)

		# Write to both log files
		write_log(main_log_file_path, indented_message)
		write_log(new_secondary_log_file_path, indented_message)

	if log_to_gdprint:
		# GD.Print("%s: %s" % [_log_file_name, _message])
		pass

	if log_to_console:
		print("%s: %s" % [_log_file_name, _message])


func get_file_path(file_path: String, log_file_name: String, file_extension: String, timestamp: String) -> String:
	# Use default values if any parameter is null or empty
	if file_path == "" or file_path == null:
		file_path = log_file_path
	if log_file_name == "" or log_file_name == null:
		log_file_name = main_log_file_name
	if file_extension == "" or file_extension == null:
		file_extension = extension

	# Create a session folder path based on the timestamp
	var session_folder_path = "%s%s" % [file_path, timestamp]

	# Ensure the session folder path exists
	var global_session_folder = ProjectSettings.globalize_path(session_folder_path)
	var dir = DirAccess.open(global_session_folder)
	if dir == null:
		var dirAccess = DirAccess.open(global_session_folder) 
		if dirAccess:
			dirAccess.make_dir_recursive(global_session_folder)
			dirAccess.close()

		


	# Return the full path for the log file within the session folder
	return ProjectSettings.globalize_path("%s/%s_%s%s" % [session_folder_path, log_file_name, timestamp, file_extension])


func format_message_with_indent(message: String) -> String:
	# Initialize indentation stack if null
	if _indentation_levels == null:
		_indentation_levels = [0]  # Use an Array as a stack

	var indent_level = _indentation_levels[-1]  # Peek top of stack
	var indent_spaces = " " * (indent_level * 4)

	# Format timestamp
	var unix_time = Time.get_unix_time_from_system()
	var timestamp = Time.get_datetime_string_from_unix_time(unix_time).replace(" ", "_").replace(":", "-")

	# Or, if you have a custom timestamp_format string, you can format accordingly

	# Convert tags to string
	var tags_string = char_tag_to_string_tag(current_used_tags)

	return "%s%s - %s: %s" % [indent_spaces, timestamp, tags_string, message]

func write_log(file_path: String, message: String) -> void:
	# Ensure the directory exists
	var dir = file_path.get_base_dir()
	var dir_access = DirAccess.open(dir)
	
	if dir_access == null:
		# Directory does not exist, create it
		dir_access.make_dir_recursive(dir)
		if dir_access == null:
			push_error("Failed to create directory: %s" % dir)
			return
	
	# Open file in append mode
	var file = FileAccess.open(file_path, FileAccess.WRITE_READ)
	if file:
		file.seek_end()  # Move to the end to append
		file.store_line(message)
		file.close()
	else:
		push_error("Failed to open log file: %s" % file_path)
