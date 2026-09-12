extends RefCounted

## Shared fail-closed output contract for focused visual evidence tools. A capture
## must name a new report directory explicitly; silently reusing an old round can
## make superseded pixels look like current production evidence.


static func requested(args: Array[String]) -> String:
	for arg: String in args:
		if arg.begins_with("--output="):
			return arg.trim_prefix("--output=").strip_edges().trim_suffix("/")
	return ""


static func valid(path: String) -> bool:
	return path.begins_with("res://ralph/reports/") \
		and not path.contains("..") \
		and not path.contains("\\") \
		and path.trim_prefix("res://ralph/reports/").contains("/")


static func create_fresh(path: String, label: String) -> bool:
	if not valid(path):
		push_error("%s requires an explicit --output=res://ralph/reports/<batch>/<round> directory" % label)
		return false
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute):
		push_error("%s output already exists; choose a new evidence directory: %s" % [label, path])
		return false
	if DirAccess.make_dir_recursive_absolute(absolute) != OK:
		push_error("%s could not create output directory: %s" % [label, path])
		return false
	return true
