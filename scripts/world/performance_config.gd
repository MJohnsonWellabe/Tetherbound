extends RefCounted

## PERF-ROG / OP23-01. The chapter's performance tunables, in one file.
##
## These exist because the owner's ROG Ally playtest ("feels like ten frames per
## second") could not be answered from the container: nobody here has the
## hardware. What a container CAN do is measure the SHAPE of the per-frame work
## (`tools/perf_profile.gd`) and put every lever that shape depends on somewhere
## a device-side owner can turn without a rebuild. That is this file.
##
## Loaded once and cached, the same way `scatter_rules.gd::config()` and
## `catching.gd::config()` do it: these are read from `_process`/`_ready` paths
## where a per-call `FileAccess.open` would be its own performance problem.

const PATH := "res://data/config/performance.json"

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_warning("performance.json missing; every performance lever falls back to its code default")
		_config = {"_missing": true}
		return _config
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_warning("performance.json did not parse as an object; falling back to code defaults")
		_config = {"_missing": true}
		return _config
	_config = parsed
	return _config


## Test/tool seam: drop the cache so a written config file is re-read.
static func reload() -> void:
	_config = {}
