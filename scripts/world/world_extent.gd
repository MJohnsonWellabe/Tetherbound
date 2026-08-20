extends RefCounted

## The Meadows' one world-bounds authority.
##
## The old playground was a square derived from `world_size`; the authored
## corridor is not square and is not centred on the origin. Current
## terrain_playground.json stores that real rectangle in `world_bounds`, while
## several older consumers historically looked for flat `world_min_*` keys.
## Every map/fog/minimap/world-extent consumer calls this helper so the two
## representations are reconciled here rather than independently everywhere.
##
## Priority:
##   1. current nested `world_bounds` {min_x,max_x,min_z,max_z};
##   2. legacy flat world_min_x/world_max_x/world_min_z/world_max_z;
##   3. legacy square `world_size` centred on zero.
##
## This is what makes the full Meadows corridor (today x -1024..1024,
## z -512..7680) visible to the map baker and fog grid instead of silently
## cropping both back to the original ±256 m playground.

const CONFIG_PATH := "res://data/config/terrain_playground.json"


static func load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("terrain_playground.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## {min_x, max_x, min_z, max_z}, in world metres. Pass an already-loaded
## config Dictionary to avoid re-reading the file; omit it to load fresh.
static func bounds(config: Dictionary = {}) -> Dictionary:
	var cfg := config if not config.is_empty() else load_config()

	var authored: Variant = cfg.get("world_bounds", {})
	if authored is Dictionary:
		var d := authored as Dictionary
		if d.has("min_x") and d.has("max_x") and d.has("min_z") and d.has("max_z"):
			var nested := {
				"min_x": float(d.get("min_x")),
				"max_x": float(d.get("max_x")),
				"min_z": float(d.get("min_z")),
				"max_z": float(d.get("max_z")),
			}
			if _valid(nested):
				return nested

	var world_size := float(cfg.get("world_size", 512))
	var half := world_size * 0.5
	var legacy := {
		"min_x": float(cfg.get("world_min_x", -half)),
		"max_x": float(cfg.get("world_max_x", half)),
		"min_z": float(cfg.get("world_min_z", -half)),
		"max_z": float(cfg.get("world_max_z", half)),
	}
	if not _valid(legacy):
		push_error("terrain world bounds are invalid; falling back to the legacy %dm square" % int(world_size))
		return {"min_x": -half, "max_x": half, "min_z": -half, "max_z": half}
	return legacy


static func _valid(rect: Dictionary) -> bool:
	return float(rect.get("max_x", 0.0)) > float(rect.get("min_x", 0.0)) \
		and float(rect.get("max_z", 0.0)) > float(rect.get("min_z", 0.0))
