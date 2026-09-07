extends RefCounted

## Pure catalogue adapter. No global Species table, save, scene or network writes.
## Stable namespacing keeps an old Meadows Mosshell distinct from the Water
## roster entry, even when the supplied base catalogue changes between releases.
const ROSTER_PATH := "res://data/config/water_roster.json"
const BOARD_IDS: Array[String] = [
	"cannonback", "riptusk", "aquaryn", "tidecoil", "mirejaw", "torrentoad",
	"cragclaw", "riverdrake", "sirenseal", "mangrove_monitor", "mosshell", "abyssal_guardian",
]
const SWIMMERS: Array[String] = ["aquaryn", "mosshell", "sirenseal", "riverdrake", "cannonback"]


static func runtime_id(board_id: String) -> String:
	return "water_" + board_id if board_id in BOARD_IDS else ""


static func board_id(runtime_species_id: String) -> String:
	if not runtime_species_id.begins_with("water_"):
		return ""
	var candidate := runtime_species_id.trim_prefix("water_")
	return candidate if candidate in BOARD_IDS else ""


static func load_roster() -> Dictionary:
	var file := FileAccess.open(ROSTER_PATH, FileAccess.READ)
	if file == null:
		return {}
	var raw: Variant = JSON.parse_string(file.get_as_text())
	return raw if raw is Dictionary else {}


## Returns {ok, catalogue, board_to_runtime, errors}. The input is the inner
## Species.table() dictionary, not the JSON document containing "species".
## Failure returns an unchanged deep copy and no mapping: never half a roster.
## A second merge accepts identical adapter output; conflicting IDs are errors.
static func merge_catalogue(base: Dictionary, roster: Dictionary = {}) -> Dictionary:
	var source := load_roster() if roster.is_empty() else roster
	var entries: Variant = source.get("species", {})
	var errors: Array[String] = []
	var additions: Dictionary = {}
	var mapping: Dictionary = {}
	if not entries is Dictionary or entries.size() != BOARD_IDS.size():
		errors.append("Water roster must contain exactly twelve board species")
		return _result(base, {}, errors)
	for id: String in BOARD_IDS:
		var raw: Variant = entries.get(id)
		if not raw is Dictionary:
			errors.append("Missing Water species: " + id)
			continue
		var definition := _definition(id, raw, base, errors)
		if definition.is_empty():
			continue
		var target := runtime_id(id)
		if base.has(target) and base[target] != definition:
			errors.append("Refusing to overwrite existing species: " + target)
			continue
		additions[target] = definition
		mapping[id] = target
	if not errors.is_empty():
		return _result(base, {}, errors)
	var merged := base.duplicate(true)
	merged.merge(additions, false)
	return _result(merged, mapping, errors)


static func _result(catalogue: Dictionary, mapping: Dictionary, errors: Array[String]) -> Dictionary:
	return {"ok": errors.is_empty(), "catalogue": catalogue.duplicate(true),
		"board_to_runtime": mapping.duplicate(true), "errors": errors.duplicate()}


static func _definition(id: String, raw: Dictionary, base: Dictionary, errors: Array[String]) -> Dictionary:
	var presentation: Variant = raw.get("placeholder")
	var swimming: Variant = raw.get("swim_mount")
	var moves: Variant = raw.get("moves")
	if not presentation is Dictionary or not swimming is Dictionary or not moves is Dictionary:
		errors.append(id + ": missing placeholder, swim_mount or moves block")
		return {}
	var source_id := str(presentation.get("source_species", ""))
	var source: Variant = base.get(source_id)
	if not source is Dictionary or not source.get("placeholder") is Dictionary:
		errors.append(id + ": installed source species is missing: " + source_id)
		return {}
	if str(raw.get("display_name", "")).is_empty():
		errors.append(id + ": missing board display name")
		return {}
	for key: String in ["base_hp", "base_attack", "base_defence", "catch_rate"]:
		if not _positive_number(raw.get(key)):
			errors.append(id + ": invalid " + key)
			return {}
	if not swimming.get("compatible") is bool or bool(swimming.compatible) != (id in SWIMMERS):
		errors.append(id + ": swim compatibility contradicts the owner roster")
		return {}
	if bool(swimming.compatible):
		for key: String in ["speed_mps", "stamina_capacity", "stamina_drain_per_s"]:
			if not _positive_number(swimming.get(key)):
				errors.append(id + ": invalid swim " + key)
				return {}
	for slot: String in ["quick", "charged"]:
		if not moves.get(slot) is String or str(moves[slot]).is_empty():
			errors.append(id + ": missing " + slot + " move")
			return {}
	var look: Dictionary = source.placeholder.duplicate(true)
	# Combat perks are explicit roster inheritance, independent of whichever
	# mesh temporarily supplies presentation. Reuse the shipped hook and value.
	var ability_source_id := str(raw.get("best_creature_source", ""))
	var ability_source: Variant = base.get(ability_source_id)
	var ability: Variant = ability_source.get("best_creature") if ability_source is Dictionary else null
	if not ability is Dictionary or str(ability.get("id", "")).is_empty() or str(ability.get("kind", "")) not in ["survivability", "energy"] or not _positive_number(ability.get("value")):
		errors.append(id + ": missing valid Best Creature source: " + ability_source_id)
		return {}
	var target_height: Variant = presentation.get("target_height_m")
	if not _positive_number(target_height) or not _positive_number(look.get("height")) or not _positive_number(look.get("radius")):
		errors.append(id + ": invalid source or target collision dimensions")
		return {}
	var ratio := float(target_height) / float(look.height)
	look.height = float(target_height)
	look.radius = float(look.radius) * ratio
	# Source radius scales with height so creature_body._fit does not shrink the
	# rig back down to fit an unrelated tiny collider. Footprint allowance stays.
	for key: String in ["model", "model_scale", "model_yaw", "animations"]:
		if presentation.has(key):
			look[key] = presentation[key].duplicate(true) if presentation[key] is Dictionary else presentation[key]
	var definition: Dictionary = {}
	for key: String in ["display_name", "type", "base_hp", "base_attack", "base_defence", "catch_rate", "aggressive", "moves", "combat_role", "epithet"]:
		if raw.has(key):
			definition[key] = raw[key].duplicate(true) if raw[key] is Dictionary else raw[key]
	definition.placeholder = look
	definition.best_creature = ability.duplicate(true)
	definition.swim_mount = swimming.duplicate(true)
	if bool(swimming.compatible):
		var geometries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_mounts.json"))
		var geometry: Dictionary = geometries.get("mounts", {}).get(runtime_id(id), {})
		if geometry.is_empty():
			errors.append(id + ": missing measured mount geometry")
			return {}
		definition.water_mount_geometry = geometry.duplicate(true)
		definition.rideable = {"can_carry":true, "requires_item":str(swimming.requires_item),
			"mount_offset":geometry.mount_offset.duplicate(), "ride_speed_multiplier":float(geometry.land_speed_multiplier),
			"dismount_distance":float(geometry.dismount_distance)}
	definition.water_board_id = id
	definition.water_placeholder = {
		"source_species": source_id,
		"replacement_model": str(presentation.get("replacement_model", "")),
		"replacement_binding": ROSTER_PATH + "#species/" + id + "/placeholder/model",
		"status": str(presentation.get("status", "installed_mesh_placeholder_unrendered")),
	}
	# Riding is authored from Water's measured geometry, never inherited from
	# the species borrowed for placeholder art.
	return definition


static func _positive_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) > 0.0
