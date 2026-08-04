extends RefCounted

## The species table, loaded from data/pals/species.json.
##
## Thin on purpose. Its whole job is to keep species stats out of gameplay code
## so M11 can swap placeholder capsules for real rigged creatures, and rebalance
## every creature, without a single line of combat code changing.

const SPECIES_PATH := "res://data/pals/species.json"
const INSTANCE := preload("res://scripts/pals/pal_instance.gd")
const TRAITS := preload("res://scripts/pals/pal_traits.gd")

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
## `trait_roll` is taken rather than generated, for the reason
## `catch_math.resolve()` gives about its own roll: a function that reaches for
## `randf()` internally cannot be tested and cannot be replayed. Pass a value in
## [0, 1) to decide the trait; leave it negative and one is drawn here.
##
## Every pal gets a trait. `GAME_DESIGN.md` §11 says so, and until this line the
## whole trait system existed, loaded, and was tested while nothing in the game
## ever called it — every creature in the build had `trait_id == ""`.
static func spawn(species_id: String, trait_roll: float = -1.0) -> RefCounted:
	if not has(species_id):
		push_error("unknown species '%s'; known: %s" % [species_id, ", ".join(table().keys())])
		return null
	var instance: RefCounted = INSTANCE.from_species(species_id, definition(species_id))
	if instance != null:
		var roll: float = trait_roll if trait_roll >= 0.0 else randf()
		instance.assign_trait(TRAITS.roll(roll))
	return instance


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
