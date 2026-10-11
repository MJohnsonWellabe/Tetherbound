extends RefCounted

## F26 performance: shared reader for data/config/presentation_lod.json.
## Cached once; tools may flip `enabled` on the returned Dictionary in place.

const PATH := "res://data/config/presentation_lod.json"
static var _cache: Dictionary = {}


static func config() -> Dictionary:
	if _cache.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_cache = parsed if parsed is Dictionary else {"enabled": false}
	return _cache


## The named block when presentation LOD is on, else empty (refresh always).
static func block(name: String) -> Dictionary:
	var cfg := config()
	if not bool(cfg.get("enabled", false)):
		return {}
	var value: Variant = cfg.get(name, {})
	return value if value is Dictionary else {}
