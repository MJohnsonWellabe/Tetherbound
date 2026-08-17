extends RefCounted

## The playground's world bounds, read from `terrain_playground.json` instead
## of hard-coded — `docs/MEADOWS_MACRO_LAYOUT.md` §8.6: `map_baker.gd`
## `HALF_SPAN`, `minimap.gd` `WORLD_HALF` and `map_state.gd`'s
## `GRID`/`CELL`/`ORIGIN` each independently hard-coded a ±256 m square, and
## one of them (`map_state`) writes that assumption into the save file. D09 —
## one mechanism answers "how big is the world" — so this is that one
## mechanism, and the three map files (plus `tab_map.gd`) call it instead of
## keeping their own copies of the number.
##
## Exposed as an explicit rectangle (`min_x`/`max_x`/`min_z`/`max_z`), not a
## single half-span, because the corridor world `docs/decisions/D50` commits
## to is neither square nor centred on the origin (x ∈ [−1024, +1024],
## z ∈ [−512, +7680]). Today `terrain_playground.json` only carries a square
## `world_size`, so `bounds()` derives a square centred on the origin from it
## — exactly today's ±256 m playground, byte-for-byte. Optional
## `world_min_x`/`world_max_x`/`world_min_z`/`world_max_z` fields override
## that derived square outright, so the day the corridor config lands, it is
## a data change here, not another round of hunting down hard-coded halves.

const CONFIG_PATH := "res://data/config/terrain_playground.json"


static func load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("terrain_playground.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## {min_x, max_x, min_z, max_z}, in world metres. Pass an already-loaded
## config Dictionary to avoid re-reading the file (`map_baker.bake()` is
## called per-pixel-grid-sized elsewhere in this project and every avoidable
## file read matters); omit it to load fresh.
static func bounds(config: Dictionary = {}) -> Dictionary:
	var cfg := config if not config.is_empty() else load_config()
	var world_size := float(cfg.get("world_size", 512))
	var half := world_size * 0.5
	return {
		"min_x": float(cfg.get("world_min_x", -half)),
		"max_x": float(cfg.get("world_max_x", half)),
		"min_z": float(cfg.get("world_min_z", -half)),
		"max_z": float(cfg.get("world_max_z", half)),
	}
