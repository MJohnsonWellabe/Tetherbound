extends RefCounted

## The species table, loaded from data/creatures/species.json.
##
## Thin on purpose. Its whole job is to keep species stats out of gameplay code
## so M11 can swap placeholder capsules for real rigged creatures, and rebalance
## every creature, without a single line of combat code changing.

const SPECIES_PATH := "res://data/creatures/species.json"
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")

static var _table: Dictionary = {}


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
