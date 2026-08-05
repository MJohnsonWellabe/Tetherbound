extends RefCounted

## The species table, loaded from data/pals/species.json.
##
## Thin on purpose. Its whole job is to keep species stats out of gameplay code
## so a creature can be added, re-modelled, resized, recoloured or rebalanced
## without a single line of combat code changing.
##
## M11 is the test of that and it held: the roster went from three species to
## eight, every model was replaced, every stat was rewritten, sizes went from a
## 1.5x spread to 5.8x, and the only code that changed was one retint function in
## `pal_body.gd`, one fallback rule in `pal_animator.gd`, and the accessors
## below. Nothing in `scripts/combat/` was touched.

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


## Every species id in the table, sorted, so a caller enumerating the roster
## gets the same order every time. `table().keys()` does not promise one.
static func ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in table().keys():
		out.append(id)
	out.sort()
	return out


## The name a player sees. Falls back to the id, which is ugly on purpose: an
## unnamed species should be obvious in a screenshot.
static func display_name(species_id: String) -> String:
	return str(definition(species_id).get("display_name", species_id))


## One of GAME_DESIGN.md §8's eight locked types.
##
## NOTHING IN THE GAME READS THIS YET. There is no chart, no multiplier and no
## same-type bonus; §8 says the chart is "tunable and should be defined before
## full Meadows balancing", and building it is a separate system. The accessor
## exists so that when the chart is built it has one place to ask, and so
## tests/test_roster.gd can assert the field is at least populated and legal.
static func type_of(species_id: String) -> String:
	return str(definition(species_id).get("type", "ground"))


## The species this one becomes, or "" for the great majority that never do.
##
## §11: evolution is limited, not universal, and starters do not evolve. Inert
## data — the requirement (level + high bond + item/condition) is a system
## nobody has built, so no code acts on this. It is here because the pair it
## names is the one thing about evolution that can be got wrong today: the
## evolved form has to be the visibly bigger, more dangerous creature, and at the
## pack's own scale it was the smaller one.
static func evolves_into(species_id: String) -> String:
	return str(definition(species_id).get("evolves_into", ""))


## The creature's gameplay height in metres. The collider is built from this and
## the art is fitted to it, so it is the one number that is true of both.
static func body_height(species_id: String) -> float:
	return float(placeholder(species_id).get("height", 1.0))


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
