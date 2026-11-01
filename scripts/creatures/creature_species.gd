extends RefCounted

## The species table, loaded from data/creatures/species.json.
##
## Thin on purpose. Its whole job is to keep species stats out of gameplay code
## so M11 can swap placeholder capsules for real rigged creatures, and rebalance
## every creature, without a single line of combat code changing.

const SPECIES_PATH := "res://data/creatures/species.json"
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const WATER_CATALOGUE := preload("res://scripts/creatures/water_species_catalog.gd")
## GPU arms (owner, 31 Oct): candidate creature scale-ups ship as named flags,
## OFF by default, so the GPU judges them on an imported tree by flipping
## `enabled`. An enabled flag multiplies a species' placeholder height and
## collider radius by the same factor (grow the smaller side, never shrink).
const SCALE_FLAGS_PATH := "res://data/config/creature_scale_flags.json"
## Candidate creature models (owner-picked remakes, 1 Nov 2026) ship the same
## way: a named flag, OFF by default, whose `species` map holds placeholder
## overrides (model, colourway source, clip map). An enabled flag merges them
## over the species' placeholder; the installed model stays the default.
## Applied before the scale flags so a scale-up still multiplies the height.
const MODEL_FLAGS_PATH := "res://data/config/creature_model_flags.json"

static var _table: Dictionary = {}
static var _fly_capabilities: Dictionary = {}


static func table() -> Dictionary:
	if not _table.is_empty():
		return _table
	var file := FileAccess.open(SPECIES_PATH, FileAccess.READ)
	if file == null:
		push_error("species.json missing at %s" % SPECIES_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_table = (parsed as Dictionary).get("species", {})
		var water := WATER_CATALOGUE.merge_catalogue(_table)
		if bool(water.ok):
			_table = water.catalogue
		else:
			push_error("Water species registration failed: %s" % water.errors)
		_apply_model_flags(_table)
		_apply_scale_flags(_table)
	return _table


static func _apply_model_flags(rows: Dictionary) -> void:
	if not FileAccess.file_exists(MODEL_FLAGS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MODEL_FLAGS_PATH))
	if not parsed is Dictionary:
		push_error("creature_model_flags.json is not an object")
		return
	merge_model_flags(rows, (parsed as Dictionary).get("flags", {}))


## Merge every enabled flag's placeholder overrides into `rows`. Split from the
## file read so a test can apply one flag as if it were enabled.
static func merge_model_flags(rows: Dictionary, flags: Dictionary) -> void:
	for flag: String in flags:
		var entry: Variant = flags[flag]
		if not entry is Dictionary or not bool(entry.get("enabled", false)):
			continue
		var overrides: Dictionary = entry.get("species", {})
		for id: String in overrides:
			var spec: Variant = overrides[id]
			if not rows.has(id) or not spec is Dictionary:
				push_error("model flag %s: %s needs a known species and an override object" % [flag, id])
				continue
			var model := str((spec as Dictionary).get("model", ""))
			if not model.is_empty() and not ResourceLoader.exists(model):
				push_error("model flag %s: %s is missing" % [flag, model])
				continue
			var row: Dictionary = rows[id]
			var look: Dictionary = (row.get("placeholder", {}) as Dictionary).duplicate(true)
			for key: String in spec:
				if not key.begins_with("_"):
					look[key] = (spec as Dictionary)[key]
			row["placeholder"] = look


static func _apply_scale_flags(rows: Dictionary) -> void:
	if not FileAccess.file_exists(SCALE_FLAGS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SCALE_FLAGS_PATH))
	if not parsed is Dictionary:
		push_error("creature_scale_flags.json is not an object")
		return
	var flags: Dictionary = (parsed as Dictionary).get("flags", {})
	for flag: String in flags:
		var entry: Variant = flags[flag]
		if not entry is Dictionary or not bool(entry.get("enabled", false)):
			continue
		var factors: Dictionary = entry.get("species", {})
		for id: String in factors:
			var factor := float(factors[id])
			if not rows.has(id) or not is_finite(factor) or factor < 1.0:
				push_error("scale flag %s: %s needs a known species and a factor >= 1" % [flag, id])
				continue
			var row: Dictionary = rows[id]
			var look: Dictionary = (row.get("placeholder", {}) as Dictionary).duplicate()
			look["height"] = float(look.get("height", 1.0)) * factor
			look["radius"] = float(look.get("radius", 0.4)) * factor
			row["placeholder"] = look


static func has(species_id: String) -> bool:
	return table().has(species_id)


static func definition(species_id: String) -> Dictionary:
	var entry: Variant = table().get(species_id)
	return entry if entry is Dictionary else {}


## Build a live creature. Returns null for an unknown id rather than a
## half-populated instance, so a typo in a species name fails loudly at the
## point of the mistake.
static func spawn(species_id: String) -> RefCounted:
	if not has(species_id):
		push_error("unknown species '%s'; known: %s" % [species_id, ", ".join(table().keys())])
		return null
	return INSTANCE.from_species(species_id, definition(species_id))


## Placeholder presentation: colour and capsule dimensions. M2 renders creatures
## as coloured capsules, and these are chosen for silhouette readability at
## combat distance, not for appeal.
static func placeholder(species_id: String) -> Dictionary:
	var entry: Variant = definition(species_id).get("placeholder")
	return entry if entry is Dictionary else {"colour": "#cccccc", "height": 1.0, "radius": 0.4}


## Will this creature start a fight on its own?
##
## Defaults to false, which is the safe direction: a species that forgets to
## declare itself behaves like every creature did before M3 rather than
## surprising the player by charging them.
static func is_aggressive(species_id: String) -> bool:
	return bool(definition(species_id).get("aggressive", false))


## The species' base share of the catch formula. Lower is rarer.
static func catch_rate(species_id: String) -> float:
	return float(definition(species_id).get("catch_rate", 0.3))


## R6.1/R6.2: can this species be ridden, and on what terms?
##
## A species with no `rideable` block cannot be ridden at all, which is the
## whole roster except Meadowhart today. Returned as a Dictionary with every
## key filled in rather than raw, so `riding_controller.gd` never has to
## defend against half-written data — a block that names only a multiplier
## still answers `mount_offset` and `requires_item`.
##
## Deliberately NOT a bool on the species: "which creature is the mount" is a
## data question the spec answers per band (Meadowhart now, the legendary at
## R8.5), and the moment it is a hardcoded id in code the second mount needs a
## second branch instead of a second block.
static func rideable(species_id: String) -> Dictionary:
	var raw: Variant = definition(species_id).get("rideable")
	if not raw is Dictionary:
		return {}
	var block: Dictionary = raw
	var offset_raw: Variant = block.get("mount_offset", [0.0, 1.0, 0.0])
	var offset := Vector3(0.0, 1.0, 0.0)
	if offset_raw is Array and (offset_raw as Array).size() == 3:
		var list: Array = offset_raw
		offset = Vector3(float(list[0]), float(list[1]), float(list[2]))
	var leg_fit_raw: Variant = block.get("rider_leg_fit", {})
	var leg_fit: Dictionary = (leg_fit_raw as Dictionary).duplicate(true) \
		if leg_fit_raw is Dictionary else {}
	return {
		"can_carry": bool(block.get("can_carry", true)),
		"requires_item": str(block.get("requires_item", "")),
		"mount_offset": offset,
		"ride_speed_multiplier": float(block.get("ride_speed_multiplier", 1.5)),
		"dismount_distance": float(block.get("dismount_distance", 1.6)),
		# Visual rider fit belongs to the same validated species answer as the
		# physical seat. Dropping these keys here made both local and remote
		# production callers receive their defaults even though species.json
		# authored the Meadowhart-specific values.
		"rider_thigh_spread_deg": float(block.get("rider_thigh_spread_deg", -1.0)),
		"rider_leg_fit": leg_fit,
		# R8.5. The slope this mount's own body will accept as floor while it
		# is being ridden, in degrees. 0.0 means "this species has no opinion",
		# which is every mount but the legendary — riding_controller.gd then
		# leaves `floor_max_angle` exactly as the creature scene set it.
		"climb_max_slope_deg": maxf(float(block.get("climb_max_slope_deg", 0.0)), 0.0),
	}


## Shorthand for "is this thing a mount at all". False for a species with no
## block AND for one whose block says `can_carry: false`, so a species can be
## tuned before it is switched on.
static func is_rideable(species_id: String) -> bool:
	var block := rideable(species_id)
	return not block.is_empty() and bool(block.get("can_carry", false))


## Traversal capability is independent of final creature art/encounter tables.
## An entry authorizes an OWNED active creature; it never supplies one.
static func fly_capability(species_id: String) -> Dictionary:
	if _fly_capabilities.is_empty():
		var file := FileAccess.open("res://data/config/fly_traversal.json", FileAccess.READ)
		if file == null:
			return {}
		var raw: Variant = JSON.parse_string(file.get_as_text())
		if not raw is Dictionary:
			return {}
		_fly_capabilities = (raw as Dictionary).get("capabilities", {})
	var entry: Variant = _fly_capabilities.get(species_id, {})
	return (entry as Dictionary).duplicate(true) if entry is Dictionary else {}


## Best Creature's species-specific perk (GAME_DESIGN.md §12: "Best Creature
## abilities should be species-specific where possible"). Lives with the rest
## of species data rather than being copied onto every instance, the same
## split `catch_rate`/`is_aggressive` already use. Missing or malformed data
## reads as "no ability" (`kind` "") rather than crashing — a party's flagged
## Best Creature simply fights at its plain stats, never worse, if a species
## entry has none.
static func best_creature_ability(species_id: String) -> Dictionary:
	var raw: Variant = definition(species_id).get("best_creature")
	var ability: Dictionary = raw if raw is Dictionary else {}
	return {
		"id": str(ability.get("id", "")),
		"kind": str(ability.get("kind", "")),
		"value": float(ability.get("value", 0.0)),
	}
