class_name FileContents
extends Object

# ----------------------------------------------
# Properties
# ----------------------------------------------

## Determine if the result had any errors 
var has_error: bool = false

## Error code
var file_result: int = OK

## File contents result
var file_content: String = ""

# ----------------------------------------------
# Methods
# ----------------------------------------------

func get_content_result() -> PoolByteArray:
    if has_error:
        return PoolByteArray()
    return file_content.to_utf8()
