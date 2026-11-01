extends RefCounted

## P2-074 (GPU DLG-2 1 Nov: "place Nalia with a stand beside her body").
## Resident Nalia's authored island-local offset puts her body about 12 m up
## the steep sand wall above her Shellwatch post, where no walkable stand
## exists beside her (the dialogue fixture found none within 2.5 m of her
## height). `water_npc_placement_candidate.json`, OFF by default, names a
## replacement offset per NPC on the flat ground at the foot of that wall.
## Every reader of a Water NPC's placement goes through `offset()` so the body,
## the host's speech reach and the grass clearance agree.
const PATH := "res://data/config/water_npc_placement_candidate.json"

static var _cfg: Variant = null


static func settings() -> Dictionary:
	if _cfg == null:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH)) \
			if FileAccess.file_exists(PATH) else {}
		_cfg = parsed if parsed is Dictionary else {}
	return _cfg


## The island-local offset to place `spec` at: the candidate's while it is
## enabled and names this NPC, otherwise the authored one.
static func offset(spec: Dictionary, cfg: Dictionary = {}) -> Array:
	var authored: Array = spec.get("island_local_offset", [])
	var use := cfg if not cfg.is_empty() else settings()
	if not bool(use.get("enabled", false)):
		return authored
	var moved: Variant = (use.get("offsets", {}) as Dictionary).get(str(spec.get("id", "")), null)
	return moved if moved is Array and (moved as Array).size() == 3 else authored
