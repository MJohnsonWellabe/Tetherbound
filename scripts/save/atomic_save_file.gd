extends RefCounted

static var _validity_cache: Dictionary = {}

## Per-file save commit. Godot 4.7's Windows rename removes an existing
## destination BEFORE moving the source, so never rename over a live save.
## Keep the previous document beside it until the new document is installed.
## Readers use that previous document if interrupted between the two renames.
## This helper is not a transaction across world/character/slot files;
## save_game.gd coordinates synchronous rollback for that group. Neither is an
## OS power-loss durability guarantee (FileAccess exposes flush, not fsync).
## Callers retain the existing one-owner, synchronous-write contract. Pending
## files orphaned by a crash are never loaded; only .previous is recoverable.

static func readable_path(path: String) -> String:
	if _is_valid_document(path):
		return path
	var previous := path + ".previous"
	return previous if _is_valid_document(previous) else path


static func has_readable(path: String) -> bool:
	return _is_valid_document(readable_path(path))


static func _is_valid_document(path: String) -> bool:
	if not FileAccess.file_exists(path):
		_validity_cache.erase(path)
		return false
	var modified := FileAccess.get_modified_time(path)
	var size := FileAccess.get_size(path)
	var cached: Variant = _validity_cache.get(path)
	if cached is Dictionary and int(cached.get("modified", -1)) == modified \
			and int(cached.get("size", -1)) == size:
		return bool(cached.get("valid", false))
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	var valid := parse_error == OK and typeof(parser.data) == TYPE_DICTIONARY
	_validity_cache[path] = {"modified": modified, "size": size, "valid": valid}
	return valid


## Remove every readable generation of one save. A backup-only interrupted
## commit must not make a deleted slot reappear on the next listing.
static func delete(path: String) -> bool:
	var complete := true
	for candidate: String in [path, path + ".previous"]:
		_validity_cache.erase(candidate)
		if FileAccess.file_exists(candidate):
			complete = DirAccess.remove_absolute(candidate) == OK and complete
	return complete


## With retain_previous=true, a successful replacement keeps the old readable
## generation until finish() or rollback(). SaveGame uses that narrow mode to
## coordinate its slot/world/character group without re-reading all three files.
func write(path: String, text: String, retain_previous: bool = false) -> bool:
	var previous := path + ".previous"
	_validity_cache.erase(path)
	_validity_cache.erase(previous)
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
	var canonical_valid := _is_valid_document(path)
	var previous_valid := _is_valid_document(previous)
	var moved_canonical := false
	if canonical_valid:
		# A prior successful commit may have left its backup after cleanup was
		# refused. The canonical document remains present throughout this step.
		if FileAccess.file_exists(previous) and DirAccess.remove_absolute(previous) != OK:
			DirAccess.remove_absolute(temporary)
			return false
		if _rename(path, previous) != OK:
			DirAccess.remove_absolute(temporary)
			return false
		moved_canonical = true
	elif FileAccess.file_exists(path):
		# A truncated canonical must never displace its valid recovery copy. The
		# new document is already fully staged and verified before it is removed.
		if DirAccess.remove_absolute(path) != OK:
			DirAccess.remove_absolute(temporary)
			return false
	if _rename(temporary, path) != OK:
		if moved_canonical:
			_rename(previous, path)
		DirAccess.remove_absolute(temporary)
		return false
	if (moved_canonical or previous_valid) and not retain_previous:
		DirAccess.remove_absolute(previous)
	_validity_cache[path] = {
		"modified": FileAccess.get_modified_time(path),
		"size": FileAccess.get_size(path),
		"valid": true,
	}
	_validity_cache.erase(previous)
	return true


## Complete a retained replacement after every member of its save group wrote.
static func finish(path: String) -> bool:
	var previous := path + ".previous"
	_validity_cache.erase(previous)
	return not FileAccess.file_exists(previous) or DirAccess.remove_absolute(previous) == OK


## Undo a retained replacement. had_readable is captured before write(): when
## false, the new canonical is the first valid generation and rollback removes
## it; when true, .previous is the exact old generation to restore.
static func rollback(path: String, had_readable: bool) -> bool:
	_validity_cache.erase(path)
	_validity_cache.erase(path + ".previous")
	if not had_readable:
		return delete(path)
	var previous := path + ".previous"
	if not _is_valid_document(previous):
		return false
	if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
		return false
	if DirAccess.rename_absolute(previous, path) != OK:
		return false
	_validity_cache.erase(path)
	return _is_valid_document(path)


## Narrow overridable IO seams let tests produce real truncated files and
## deterministic refusal without exhausting a disk or touching user saves.
func _store(file: FileAccess, bytes: PackedByteArray) -> bool:
	return file.store_buffer(bytes)


func _flush(file: FileAccess) -> Error:
	file.flush()
	return file.get_error()


func _rename(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(from, to)
