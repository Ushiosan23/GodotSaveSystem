class_name IOUtils
extends Object

# ----------------------------------------------
# Static methods
# ----------------------------------------------


## This method reads the file and returns its content
static func get_file_contents(location: String) -> FileContents:
	# Generate file object
	var file_obj = File.new()
	var file_contents = FileContents.new()
	# Check if file exists
	if not file_obj.file_exists(location):
		file_contents.has_error = true
		file_contents.file_result = ERR_FILE_NOT_FOUND
		return file_contents
	# Open file
	if file_obj.open(location, File.READ) != OK:
		file_contents.has_error = true
		file_contents.file_result = ERR_CANT_OPEN
		return file_contents
	# Get file contents
	while file_obj.get_position() < file_obj.get_len():
		# Append content
		file_contents.file_content += file_obj.get_line()
	# Close file
	file_obj.close()
	# Return result
	return file_contents


## This method write content to a file
static func write_file_contents(location: String, data: String) -> WriteResult:
	# Generate file object
	var file_obj = File.new()
	var write_res = WriteResult.new()
	# Check if file exists
	if file_obj.open(location, File.WRITE) != OK:
		write_res.has_error = true
		write_res.write_result = file_obj.get_error()
		return write_res
	# Write data
	file_obj.store_buffer(data.to_utf8())
	file_obj.close()
	# Return result
	return write_res
