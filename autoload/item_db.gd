extends RefCounted

## Item definitions, read once from data/items/.
##
## Everything that wants to know how big a stack of wood is asks here. The
## previous prototype's Inventory.ts imported items.json directly and that was
## fine in a bundler; in Godot a file read per query would be a file read per
## frame, so it is loaded once and handed to whoever needs it.
##
## Unknown ids do NOT throw. A save or a harvest table naming an item that no
## longer exists must degrade to "1 per slot, shown by its id" rather than take
## the menu down — a broken satchel the player can empty beats a crash.

const ITEMS_PATH := "res://data/items/items.json"
const BUILDABLES_PATH := "res://data/items/buildables.json"

## Fallback stack size for an id with no definition. One, so an unknown item
## cannot merge with anything and quietly lose itself.
const UNKNOWN_STACK := 1

var _items: Dictionary = {}
var _buildables: Array = []


func _init(items_path: String = ITEMS_PATH, buildables_path: String = BUILDABLES_PATH) -> void:
	_items = _read(items_path).get("items", {})
	_buildables = _read(buildables_path).get("buildables", [])


func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("item data missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("item data is not a JSON object: %s" % path)
		return {}
	return parsed as Dictionary


func has(id: String) -> bool:
	return _items.has(id)


func ids() -> Array:
	return _items.keys()


func definition(id: String) -> Dictionary:
	var value: Variant = _items.get(id, {})
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


## Display name, falling back to the raw id so an unknown item is still
## identifiable on screen instead of appearing as an empty slot.
func item_name(id: String) -> String:
	return str(definition(id).get("name", id))


func stack_size(id: String) -> int:
	return maxi(1, int(definition(id).get("stack", UNKNOWN_STACK)))


func kind(id: String) -> String:
	return str(definition(id).get("kind", "unknown"))


func blurb(id: String) -> String:
	return str(definition(id).get("blurb", ""))


## Tile tint for the slot grid. Grey for anything undefined, which reads as
## "the game does not know what this is" rather than as a design choice.
func colour(id: String) -> Color:
	var raw := str(definition(id).get("colour", ""))
	return Color(raw) if raw.begins_with("#") else Color(0.35, 0.35, 0.37)


func buildables() -> Array:
	return _buildables


func buildable(id: String) -> Dictionary:
	for entry in _buildables:
		if typeof(entry) == TYPE_DICTIONARY and str((entry as Dictionary).get("id", "")) == id:
			return entry as Dictionary
	return {}
