extends RefCounted

## P2-029 local presentation candidate. Resolve only the two installed models
## under their global and Water IDs; never edit the Species catalogue itself.
const CONFIG_PATH := "res://data/config/water_creature_rest_visual.json"
const EXPECTED_MODELS := {
	"riptusk": "res://assets/creatures/tetherbound/riptusk/models/creature_riptusk_lod0.glb",
	"water_riptusk": "res://assets/creatures/tetherbound/riptusk/models/creature_riptusk_lod0.glb",
	"torrentoad": "res://assets/creatures/tetherbound/torrentoad/models/creature_torrentoad_lod0.glb",
	"water_torrentoad": "res://assets/creatures/tetherbound/torrentoad/models/creature_torrentoad_lod0.glb",
}
## Owner-rule remakes (1 Nov 2026, remake_owner1101_torrentoad / _riptusk):
## their dog3 faint ends lying prone with the legs drawn in (the endpoint the
## dog3 faint judges read as down), so the same no-op recipe finishes it. Exact
## path binding as above. The config's species allow list still decides which
## ids ship it (Riptusk stays on the legacy roll until judged on the remake).
const REMAKE_MODELS := {
	"riptusk": "res://assets/creatures/tetherbound/riptusk/candidate_owner1101/models/creature_riptusk_owner1101.glb",
	"water_riptusk": "res://assets/creatures/tetherbound/riptusk/candidate_owner1101/models/creature_riptusk_owner1101.glb",
	"torrentoad": "res://assets/creatures/tetherbound/torrentoad/candidate_owner1101/models/creature_torrentoad_owner1101.glb",
	"water_torrentoad": "res://assets/creatures/tetherbound/torrentoad/candidate_owner1101/models/creature_torrentoad_owner1101.glb",
}
static var _config: Dictionary = {}


static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
		_config = raw if raw is Dictionary else {"enabled": false}
	return _config


static func resolve(species_id: String, source: Dictionary) -> Dictionary:
	var model := str(source.get("model", ""))
	if not bool(config().get("enabled", false)) or not EXPECTED_MODELS.has(species_id) \
			or (model != str(EXPECTED_MODELS[species_id]) and model != str(REMAKE_MODELS.get(species_id, ""))):
		return source
	# Optional per-id allow list: an id whose installed faint endpoint does not
	# read as rest (Riptusk stands head-down on straight front legs) keeps the
	# legacy roll until it has a dedicated recipe.
	var allowed: Variant = config().get("species", null)
	if allowed is Array and not (allowed as Array).has(species_id):
		return source
	# Future dedicated recipes take priority over this reuse candidate.
	var authored: Variant = source.get("rest_pose", {})
	if authored is Dictionary and not (authored as Dictionary).is_empty():
		return source
	var result := source.duplicate(true)
	# A no-op root recipe keeps the installed faint endpoint in the existing
	# reversible authored-rest lifecycle. No extra roll, fit, scale or offsets.
	result["rest_pose"] = {"clip_role": "faint", "bones": {"root": {}}, "release_presence_pivot": true}
	return result
