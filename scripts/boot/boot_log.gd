extends RefCounted

## RB4: a startup diagnostic log for the ROG Ally's "Not Responding" freeze.
##
## Appends timestamped lines to user://boot_log.txt as the game passes each
## major startup phase. On an exported Windows build user:// resolves to
## %APPDATA%/Godot/app_userdata/Tetherbound/boot_log.txt — the same directory
## user://settings.json already writes to (D15).
##
## The freeze this chases leaves the process "Not Responding" rather than
## crashing, so it never gets a chance to write anything after the point it
## actually stalls — which line is LAST in the file on a frozen Ally is the
## whole diagnostic. Appends rather than truncates, because a killed-and-
## relaunched attempt must not erase the stalled run it was trying to
## capture; each launch gets its own marker line instead.
##
## Never fatal: if the file cannot be opened, the line is dropped, not boot.

const PATH := "user://boot_log.txt"

static var _marked_launch := false


static func line(message: String) -> void:
	var existed := FileAccess.file_exists(PATH)
	var file: FileAccess = FileAccess.open(PATH, FileAccess.READ_WRITE if existed else FileAccess.WRITE)
	if file == null:
		return
	if existed:
		file.seek_end()
	if not _marked_launch:
		_marked_launch = true
		file.store_line("=== launch %s (Godot %s) ===" % [
			Time.get_datetime_string_from_system(), Engine.get_version_info().string
		])
	file.store_line("[%s] %s" % [Time.get_datetime_string_from_system(), message])
	file.close()
