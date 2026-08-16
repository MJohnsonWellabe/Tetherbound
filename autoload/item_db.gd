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
const RECIPES_PATH := "res://data/recipes/recipes.json"
## SD18. The Rootstone tier, kept out of `RECIPES_PATH` on purpose -- see that
## file's own `_comment_scope` and this file's own `_comment` header. Merged
## into the same `_recipes` table on load so every other reader (`recipe()`,
## `recipe_ids()`, `craft_panel.gd`, `game_state.gd`) sees one recipe book,
## not two.
const ROOTSTONE_RECIPES_PATH := "res://data/recipes/recipes_rootstone.json"

## Fallback stack size for an id with no definition. One, so an unknown item
## cannot merge with anything and quietly lose itself.
const UNKNOWN_STACK := 1

var _items: Dictionary = {}
var _buildables: Array = []
var _recipes: Dictionary = {}


func _init(
	items_path: String = ITEMS_PATH,
	buildables_path: String = BUILDABLES_PATH,
	recipes_path: String = RECIPES_PATH,
	rootstone_recipes_path: String = ROOTSTONE_RECIPES_PATH
) -> void:
	_items = _read(items_path).get("items", {})
	_buildables = _read(buildables_path).get("buildables", [])
	_recipes = _read(recipes_path).get("recipes", {})
	# SD18: merge the Rootstone tier in. A duplicate id would silently favour
	# whichever file merges second; the two tables are hand-authored with no
	# overlap today, so this stays a plain merge rather than growing a
	# conflict check nothing has ever needed.
	var rootstone_recipes: Dictionary = _read(rootstone_recipes_path).get("recipes", {})
	for id: Variant in rootstone_recipes:
		_recipes[id] = rootstone_recipes[id]


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


## The tool id that gathers `id` at full amount, or "" if `id` is never
## tool-gated (berries, and anything else with no `gathered_with` entry).
func gathered_with(id: String) -> String:
	return str(definition(id).get("gathered_with", ""))


func tool_ids() -> Array:
	return ids().filter(func(id: Variant) -> bool: return kind(str(id)) == "tool")


## R2.2. The number of full-yield gathers `id` survives before it breaks, or 0
## for anything with no `durability` field (everything but the five tools).
func max_durability(id: String) -> int:
	return maxi(0, int(definition(id).get("durability", 0)))


## R2.1: bare hands still gather SOMETHING, just less than the right tool.
## Tunable — do not let this become a hidden difficulty knob nobody can find.
const BAREHANDED_FRACTION := 0.5


## What a harvest node actually pays out, given what the player owns.
## The right tool (or an ungated resource) pays the node's full `base_amount`.
## No tool at all pays a reduced, bare-handed amount. Owning tools but not
## the right one for THIS resource pays nothing — the wrong tool, not no
## tool. Pure function: the caller looks ownership up in Inventory and hands
## the two booleans in, so this stays testable with no live satchel.
func harvest_yield(id: String, base_amount: int, owns_required_tool: bool, owns_any_tool: bool) -> int:
	if gathered_with(id).is_empty() or owns_required_tool:
		return base_amount
	if owns_any_tool:
		return 0
	return maxi(1, int(base_amount * BAREHANDED_FRACTION))


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


## R2.4. Every craftable recipe, keyed by id -- {name, output: {id, n}, cost:
## [{id, n}, ...], blurb}. An id with no entry crafts nothing; callers check
## `recipe(id).is_empty()` the same way `buildable()` callers already do.
func recipe_ids() -> Array:
	return _recipes.keys()


func recipe(id: String) -> Dictionary:
	var value: Variant = _recipes.get(id, {})
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


## OF30. The progression flag `id` waits on, or "" for a recipe that is known
## from the start. See recipes.json's own `_comment_unlock`; the question
## "is it known right now" is `game_state.recipe_known()`, because only that
## side of the house can see the flag store.
func recipe_unlock_flag(id: String) -> String:
	return str(recipe(id).get("unlocked_by", ""))
