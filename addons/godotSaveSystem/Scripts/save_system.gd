class_name SaveSystem, "../Icons/icon.svg"
extends Object


# ----------------------------------------------
# Signals
# ----------------------------------------------


## Called when any of save configuration changed
signal savesChanged(key_name, old_value, new_value)

## Called when save profile was changed
signal profileChanged(old_profile, new_profile)

## Called when new profile was created
signal profileCreated(profile)

## Called when the save process is started
signal profileSaveStart()

## Called when the save process failed
signal profileSaveFailed(error)

## Called when the saving process is finished correctly
signal profileSaved(profile)


# ----------------------------------------------
# Properties and constants
# ----------------------------------------------


## Default saves directory
const SAVE_DIR = "user://saves"

## Default saves extension file
const SAVE_EXTENSION = "sav"

## Current save profile thread
var _current_save_thread: Thread = null

## Current save profile mutex
var _current_save_mutex: Mutex = null

## Current selected profile
var _current_profile: Dictionary = {}

## Current selected profile name
var _current_profile_name: String = ""


# ----------------------------------------------
# Getters
# ----------------------------------------------


## Check if any profile is selected
func is_profile_selected() -> bool:
	# Clean profile property name
	var clean_profile_name = _current_profile_name.strip_edges()
	# Only check if property is not empty
	return not clean_profile_name.empty()


## This method returns all the information of the selected profile in the form 
## of a dictionary. 
## If no profile has been selected, it displays an error message and returns 
## a null value.
func get_current_profile():
	# Check if profile is selected
	if not is_profile_selected():
		_err_profile_not_selected()
		return null
	# Return profile result
	return _current_profile


## Gets the property of the current profile dictionary from the given path.
##
## see: [method _get_internal_property]
##      [method _get_key_path]
func get_property(key: String):
	return _get_internal_property(key)


## Gets the property of the current profile dictionary from the given path.
##
## @desc: Returns the stored value if it exists. Otherwise it returns 
##        the default value.
##        Unlike "get_property" this does not issue any error alerts on 
##        the console.
##
##        If the property does not exist, it is given a default 
##        value and it is the responsibility of the developer to manage that
##        result.
func get_property_or_default(key: String, default = null):
	# Store value in a temporal variable
	# Not emmit error (very important)
	var tmp_value = _get_internal_property(key, false)
	# Check if value is not null
	if tmp_value != null:
		return tmp_value
	# Return default value
	return default


## This method returns an array of all valid save files. 
## This array only contains the file paths and is used by another 
## method of this same class. We recommend using "get_all_named_saves" instead, 
## as it does not contain the name of the profile. 
func get_all_saves() -> Array:
	# Generate array result
	var saves_result = []
	var current_dir = Directory.new()
	# Check if directory exists
	if not current_dir.dir_exists(SAVE_DIR):
		# Try to create directory
		if current_dir.make_dir_recursive(SAVE_DIR) != OK:
			# Display error
			printerr("Error to make directory saves.")
			return saves_result
	# Try to open directory
	if current_dir.open(SAVE_DIR) != OK:
		# Display error
		printerr("Error to open directory saves.")
		return saves_result
	# List all files and ignore special directories
	current_dir.list_dir_begin(true)
	# Iterate all files
	var current_file = current_dir.get_next()
	while current_file != "":
		# Check file extension
		if current_file.get_extension() == SAVE_EXTENSION:
			# Add result to array
			saves_result.append("%s/%s" % [SAVE_DIR, current_file])
		# Next file
		current_file = current_dir.get_next()
	# Get all result files
	return saves_result


## This method returns a dictionary with all save profiles.
## The dictionary is only one-dimensional and consists of the profile 
## name and its file path.
func get_all_named_saves() -> Dictionary:
	# Generate dictionary result
	var saves_result = {}
	var saves_array = get_all_saves()
	# Iterate all saves
	for item in saves_array:
		# Clean file name
		var basename = item.subst(SAVE_DIR.length() + 1).get_basename()
		# Attach value to result
		saves_result[basename] = item
	# Return result
	return saves_result


# ----------------------------------------------
# Setters
# ----------------------------------------------


## This method changes a property of the current profile.
## If the property path does not exist, it creates the necessary dictionaries 
## until the path is valid (JSON Structure). This method can also be used to 
## replace existing values. 
func set_property(key: String, value):
	# Check if profile is selected
	if not is_profile_selected():
		_err_profile_not_selected()
		return null
	# Store old property value
	var old_value = get_property_or_default(key)
	# Get key path
	var key_path = _get_key_path(key)
	var copy_profile = _current_profile
	# Iterate key path
	for i in len(key_path):
		# Store current item
		var item = key_path[i]
		# Check if current index is the last one
		if i < (len(key_path) - 1):
			# Check if property exists
			# If not exists create new one
			if item in copy_profile:
				copy_profile = copy_profile[item]
			else:
				copy_profile[item] = {}
				copy_profile = copy_profile[item]
		else:
			# Change property value
			copy_profile[item] = value
			# Emit change signal
			emit_signal("savesChanged", key, old_value, value)
	# Return inserted value
	return value



## This method creates a new save profile. If the profile name already exists, 
## it displays an error in the console and returns an error code such as 
## "ERR_ALREADY_EXISTS", "ERR_CANT_OPEN". 
## If everything went well, the "OK" code is returned.
func create_new_save(name: String, base_data: Dictionary = {}):
	# Get all saves
	var named_saves = get_all_named_saves()
	# Check if save already exists
	if name in named_saves:
		printerr("%s profile already exists" % name)
		return ERR_ALREADY_EXISTS
	# Create new save profile
	var save_path = "%s/%s.%s" % [SAVE_DIR, name, SAVE_EXTENSION]
	var save_file = File.new()
	# Try to open file
	if save_file.open(save_path, File.WRITE) != OK:
		printerr("Error to open %s profile file" % save_path)
		return ERR_CANT_OPEN
	# Write something	
	var out_buffer = JSON.print(base_data, "\t", true)
	save_file.store_buffer(out_buffer.to_utf8())
	# Close document
	save_file.close()
	# Emit created signal
	emit_signal("profileCreated", name)
	# Check if base data is not empty
	if not base_data.empty():
		emit_signal("profileSaved", name)
	# Ok result
	return OK


func select_profile(name: String):
	# Get all profiles
	var named_saves = get_all_named_saves()
	var clean_name = name.strip_edges()
	# Check if profile exists
	if not (clean_name in named_saves):
		printerr("Profile %s not exists" % clean_name)
		return false
	
	pass


# ----------------------------------------------
# Internal methods
# ----------------------------------------------


## Gets the property of a dictionary from the given path.
##
## @desc: The dictionary path must be separated by periods with the address of 
##        the desired property.
##        If the property is not correct, it returns a null value and if the 
##        parameter [code]"emit_error"[/code] is true, an error is displayed 
##        in the console.
func _get_internal_property(key: String, emit_error: bool = true):
	# Check if profile is selected
	if not is_profile_selected():
		_err_profile_not_selected()
		return null
	# Get property path and store current profile
	var key_path = _get_key_path(key)
	var copy_profile = _current_profile
	# Iterate all key path elements
	for item in key_path:
		# Check if current path exists in profile
		if item in copy_profile:
			# Replace current profile copy
			copy_profile = copy_profile[item]
		else:
			# Check if emit error is true
			if emit_error:
				_err_path_not_exists(key_path)
			return null
	# Return valid result
	return copy_profile


# ----------------------------------------------
# Static methods
# ----------------------------------------------


## Only shows a message saying that no profile has been selected.
static func _err_profile_not_selected() -> void:
	printerr("No profile has been selected.")


## Only shows a message saying that path not exists
static func _err_path_not_exists(path: Array) -> void:
	printerr("Target path %s not found" % path)


## Method to get the path from a dictionary.
##
## @desc: This method is used to convert a simple plain text into a 
##        valid path to find an object within a dictionary. 
##        This is because the text that is passed as a parameter is processed 
##        (in a very simple way) and an array is obtained with the path of the 
##        object.
##
## Dictionary example:
##
## [codeblock]
## {
##     "app": {
##         "name": "Example project"
##     }
## }
## [/codeblock]
##
## The path to access the name property is:
## 
## [codeblock]
## "app.name"
## [/codeblock]
##
## The method returns the next result:
## 
## [codeblock]
## ["app", "name"]
## [/codeblock]
static func _get_key_path(key: String) -> Array:
	# Split key by dots
	var key_split = key.strip_edges().split(".")
	var copy_key = []
	# Clean all split elements
	for item in key_split:
		# Remove invalid spaces
		var target_name = item.strip_edges().replacen(" ", "_")
		# Add name to array copy
		copy_key.append(target_name)
	# Return array with key path
	return copy_key
