extends RefCounted

## Per-file save commit. Godot 4.7's Windows rename removes an existing
## destination BEFORE moving the source, so never rename over a live save.
## Keep the previous document beside it until the new document is installed.
## Readers use that previous document if interrupted between the two renames.
## This is not a transaction across world/character/slot files, nor an OS
## power-loss durability guarantee (FileAccess exposes flush, not fsync).
## Callers retain the existing one-owner, synchronous-write contract. Pending
## files orphaned by a crash are never loaded; only .previous is recoverable.

static func readable_path(path: String) -> String:
	if FileAccess.file_exists(path):
		return path
	return path + ".previous" if FileAccess.file_exists(path + ".previous") else path


func write(path: String, text: String) -> bool:
	var previous := path + ".previous"
	# Finish an interrupted rollback before starting another save. On refusal,
	# retain the previous file; readable_path() can still load it.
	if not FileAccess.file_exists(path) and FileAccess.file_exists(previous):
		if _rename(previous, path) != OK:
			return false
	var temporary := path + ".pending-" + Crypto.new().generate_random_bytes(16).hex_encode()
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	var bytes := text.to_utf8_buffer()
	var stored := _store(file, bytes)
	var write_error := file.get_error()
	var flush_error := _flush(file)
	var complete := stored and write_error == OK and flush_error == OK and file.get_position() == bytes.size()
	file.close()
	# Reopen after close: length AND contents detect short writes even when the
	# underlying backend failed to propagate a buffered write/close error.
	if complete:
		var check := FileAccess.open(temporary, FileAccess.READ)
		complete = check != null
		if check != null:
			complete = check.get_length() == bytes.size() and check.get_buffer(bytes.size()) == bytes
			check.close()
	if not complete:
		DirAccess.remove_absolute(temporary)
		return false
	var had_previous := FileAccess.file_exists(path)
	if had_previous:
		# A prior successful commit may have left its backup after cleanup was
		# refused. The canonical document remains present throughout this step.
		if FileAccess.file_exists(previous) and DirAccess.remove_absolute(previous) != OK:
			DirAccess.remove_absolute(temporary)
			return false
		if _rename(path, previous) != OK:
			DirAccess.remove_absolute(temporary)
			return false
	if _rename(temporary, path) != OK:
		if had_previous:
			_rename(previous, path)
		DirAccess.remove_absolute(temporary)
		return false
	if had_previous:
		DirAccess.remove_absolute(previous)
	return true


## Narrow overridable IO seams let tests produce real truncated files and
## deterministic refusal without exhausting a disk or touching user saves.
func _store(file: FileAccess, bytes: PackedByteArray) -> bool:
	return file.store_buffer(bytes)


func _flush(file: FileAccess) -> Error:
	file.flush()
	return file.get_error()


func _rename(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(from, to)
