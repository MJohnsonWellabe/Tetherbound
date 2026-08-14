extends RefCounted

## Named move definitions, read once from data/moves/moves.json (D30).
##
## Same shape as autoload/item_db.gd on purpose: a species names a move by id,
## a fight or a menu asks here what that id actually does, and nothing else
## re-parses the JSON. Unknown ids do NOT throw -- a species entry with a typo
## in its `moves` block should show up as a silently toothless move in
## playtesting, not take the fight scene down.

const MOVES_PATH := "res://data/moves/moves.json"

## Fallback power for an id with no definition, or a definition with no
## `power` key. 1.0 is the balance-neutral multiplier, so an unknown move
## reads as "ordinary", not "broken".
const UNKNOWN_POWER := 1.0

var _moves: Dictionary = {}


func _init(moves_path: String = MOVES_PATH) -> void:
	_moves = _read(moves_path).get("moves", {})


## Convenience constructor for a one-off caller that does not want to hold an
## instance around -- mirrors the load-once-per-call convenience the static
## loaders elsewhere in scripts/creatures/ and scripts/combat/ already offer.
static func load_default() -> RefCounted:
	return (load("res://scripts/creatures/move_db.gd") as GDScript).new()


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("move data missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("move data is not a JSON object: %s" % path)
		return {}
	return parsed as Dictionary


func has(id: String) -> bool:
	return _moves.has(id)


func move_ids() -> Array:
	return _moves.keys()


func move(id: String) -> Dictionary:
	var value: Variant = _moves.get(id, {})
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


## Display name, falling back to the raw id so a mis-typed move id is still
## identifiable on screen instead of appearing blank.
func display_name(id: String) -> String:
	return str(move(id).get("display_name", id))


func power(id: String) -> float:
	return float(move(id).get("power", UNKNOWN_POWER))


func slot(id: String) -> String:
	return str(move(id).get("slot", ""))
