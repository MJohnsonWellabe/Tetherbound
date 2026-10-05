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


## Convenience accessor for a caller that does not want to hold an instance
## around. One parsed table per process, re-read only when the file changes:
## party validation calls this once per creature on every save, snapshot and
## character check, and re-parsing moves.json each time held a co-op host's
## frame for seconds after world facts landed (PERF, 2026-10-05). Read-only
## for callers: `move()` hands out copies.
static var _shared: RefCounted = null
static var _shared_stamp := ""


static func load_default() -> RefCounted:
	# Modified time and size: a test writing a temporary table within the same
	# second still reloads.
	var stamp := "%d:%d" % [FileAccess.get_modified_time(MOVES_PATH), FileAccess.get_size(MOVES_PATH)]
	if _shared == null or stamp != _shared_stamp:
		_shared = (load("res://scripts/creatures/move_db.gd") as GDScript).new()
		_shared_stamp = stamp
	return _shared


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


## A copy: the table behind `load_default()` is shared by every caller.
func move(id: String) -> Dictionary:
	return _move(id).duplicate(true)


func _move(id: String) -> Dictionary:
	var value: Variant = _moves.get(id, {})
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


## Display name, falling back to the raw id so a mis-typed move id is still
## identifiable on screen instead of appearing blank.
func display_name(id: String) -> String:
	return str(_move(id).get("display_name", id))


func power(id: String) -> float:
	return float(_move(id).get("power", UNKNOWN_POWER))


## The move's own elemental type (ground|water|air, and whatever the board's
## six planned types are called when they arrive).
##
## T3-TYPECHART made this a MECHANIC. It was flavour when this file was
## written — moves.json's header still says so, and says the type is
## deliberately not cross-checked against the wielding species' own, which is
## the property the chart is built on: a move's type is what decides its
## effectiveness, so a creature's coverage is what it has been TAUGHT rather
## than what it was born as.
##
## "" for an unknown id or a definition with no `type`, which
## `type_chart.gd::multiplier` resolves to neutral — the same "an unknown move
## reads as ordinary, not broken" position `UNKNOWN_POWER` takes above.
func type_of(id: String) -> String:
	return str(_move(id).get("type", ""))


func slot(id: String) -> String:
	return str(_move(id).get("slot", ""))
