extends RefCounted

## Detached proof output only. A reader sees a complete immutable JSON file.
## Each exact-cut token is fresh and each final path has one designated writer.
static func publish(path: String, value: Dictionary) -> bool:
	var temporary := path + ".writing"
	if FileAccess.file_exists(path) or FileAccess.file_exists(temporary): return false
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(temporary, path) == OK
