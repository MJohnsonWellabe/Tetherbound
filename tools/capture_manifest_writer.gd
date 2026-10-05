extends RefCounted

## Stage each capture snapshot before replacing its published receipt. Keep a
## previous generation for recovery if the process stops during promotion.
## This is a single-writer transaction, not an OS power-loss guarantee.
const READ_BLOCK_BYTES := 1024 * 1024


static func write_json(path: String, document: Dictionary) -> Error:
	# Serialize before opening any file: a slow/failed serialization must not
	# truncate the receipt belonging to frames already captured.
	var bytes := (JSON.stringify(document, "\t") + "\n").to_utf8_buffer()
	var pending := path + ".pending"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(bytes)
	var write_error := file.get_error()
	file.flush()
	var flush_error := file.get_error()
	var complete := file.get_position() == bytes.size()
	file.close()
	if write_error != OK:
		return write_error
	if flush_error != OK:
		return flush_error
	if not complete:
		return ERR_FILE_CANT_WRITE
	# Windows' flush does not update FileAccess's cached error. Confirm the
	# closed staging bytes before displacing the last published generation.
	var checked := FileAccess.open(pending, FileAccess.READ)
	if checked == null:
		return FileAccess.get_open_error()
	if checked.get_length() != bytes.size():
		checked.close()
		return ERR_FILE_CANT_WRITE
	var offset := 0
	while offset < bytes.size():
		var count := mini(READ_BLOCK_BYTES, bytes.size() - offset)
		if checked.get_buffer(count) != bytes.slice(offset, offset + count):
			checked.close()
			return ERR_FILE_CANT_WRITE
		offset += count
	checked.close()

	var previous := path + ".previous"
	var moved_previous := false
	if FileAccess.file_exists(path):
		var backup_error := DirAccess.rename_absolute(path, previous)
		if backup_error != OK:
			return backup_error
		moved_previous = true
	# On Windows Godot rename removes an existing destination before moving;
	# moving the canonical file to .previous first retains recoverable bytes.
	var promote_error := DirAccess.rename_absolute(pending, path)
	if promote_error != OK and moved_previous:
		DirAccess.rename_absolute(previous, path)
	return promote_error
