extends RefCounted

## The species table, loaded from data/creatures/species.json.
##
## Thin on purpose. Its whole job is to keep species stats out of gameplay code
## so M11 can swap placeholder capsules for real rigged creatures, and rebalance
## every creature, without a single line of combat code changing.

const SPECIES_PATH := "res://data/creatures/species.json"
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")

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
	return _table


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
	return {
		"can_carry": bool(block.get("can_carry", true)),
		"requires_item": str(block.get("requires_item", "")),
		"mount_offset": offset,
		"ride_speed_multiplier": float(block.get("ride_speed_multiplier", 1.5)),
		"dismount_distance": float(block.get("dismount_distance", 1.6)),
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
