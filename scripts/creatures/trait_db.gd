extends RefCounted

## Flavour trait definitions, read once from data/traits/traits.json (R4.2,
## GAME_DESIGN.md 11).
##
## Same shape as move_db.gd on purpose: a creature instance names a trait by
## id, a UI asks here what that id is called and how it reads. Traits carry
## no numeric combat effect -- nothing in GAME_DESIGN.md or
## MEADOWS_PROGRESSION_SPEC.md defines one, and CLAUDE.md forbids inventing a
## new mechanical system silently, so this stays flavour/appraisal only until
## the owner specifies otherwise.

const TRAITS_PATH := "res://data/traits/traits.json"

var _traits: Dictionary = {}


func _init(traits_path: String = TRAITS_PATH) -> void:
	_traits = _read(traits_path).get("traits", {})


## Convenience constructor for a one-off caller that does not want to hold an
## instance around -- mirrors move_db.gd's own load_default().
static func load_default() -> RefCounted:
	return (load("res://scripts/creatures/trait_db.gd") as GDScript).new()


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("trait data missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("trait data is not a JSON object: %s" % path)
		return {}
	return parsed as Dictionary


func has(id: String) -> bool:
	return _traits.has(id)


func trait_ids() -> Array:
	return _traits.keys()


func trait_data(id: String) -> Dictionary:
	var value: Variant = _traits.get(id, {})
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


## Display name, falling back to the raw id so a mis-typed trait id is still
## identifiable on screen instead of appearing blank.
func display_name(id: String) -> String:
	return str(trait_data(id).get("display_name", id))


func description(id: String) -> String:
	return str(trait_data(id).get("description", ""))


## Deterministic pick from `rng_value` (0..1, caller-supplied so tests and
## encounters stay reproducible -- the same house rule as
## progression.roll_wild_level). Empty string for an empty pool, the same
## "no crash, no move" tolerance move_db.gd's own lookups apply to an unknown id.
func roll(rng_value: float) -> String:
	var ids := trait_ids()
	if ids.is_empty():
		return ""
	var index := int(clampf(rng_value, 0.0, 0.999999) * ids.size())
	return str(ids[clampi(index, 0, ids.size() - 1)])
