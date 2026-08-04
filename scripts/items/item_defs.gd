extends RefCounted

## The item table, loaded from data/items/items.json.
##
## Same shape and the same job as pal_species.gd: keep what an item IS out of
## gameplay code, so the M8 material set can grow, and every stack limit and
## every tool's durability can be rebalanced, without a line of inventory code
## changing.
##
## Deliberately thin. GAME_DESIGN.md §19 asks for slots, stacks, no weight limit,
## and tools with durability and free repair — that is the whole schema. Fields
## for icons, rarity, sell value, crafting output or equipment slots are NOT here,
## because none of those systems exist yet and a field that exists gets used.
##
## Knows nothing about pals, and must not learn. An item that could name a
## creature is the first half of pal storage, and CLAUDE.md forbids the second.

const ITEMS_PATH := "res://data/items/items.json"

## The categories items.json may declare. Named here so a typo in a category
## fails a test rather than silently producing an item nothing can sort.
const CATEGORY_MATERIAL := "material"
const CATEGORY_TOOL := "tool"
const CATEGORY_ORB := "orb"
const CATEGORIES := [CATEGORY_MATERIAL, CATEGORY_TOOL, CATEGORY_ORB]

static var _table: Dictionary = {}
static var _config: Dictionary = {}


static func table() -> Dictionary:
	if not _table.is_empty():
		return _table
	var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
	if file == null:
		push_error("items.json missing at %s" % ITEMS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("items.json is not readable: %s" % ITEMS_PATH)
		return {}
	# Comment keys are stripped rather than trusted to be absent, for the reason
	# pal_traits.gd gives: the file invites `_comment_<topic>` keys inline, and one
	# written a level too high would otherwise become a real item — a nameless
	# thing with a stack limit of 1 that a player could somehow be holding.
	var out: Dictionary = {}
	var entries: Dictionary = (parsed as Dictionary).get("items", {})
	for id: String in entries.keys():
		if not id.begins_with("_"):
			out[id] = entries[id]
	_table = out
	return _table


static func has(item_id: String) -> bool:
	return table().has(item_id)


static func definition(item_id: String) -> Dictionary:
	var entry: Variant = table().get(item_id)
	return entry if entry is Dictionary else {}


static func ids() -> Array:
	return table().keys()


## What an unknown id is worth: a real, usable definition rather than an empty
## Dictionary. Same choice as pal_species.placeholder() — a stale id from a save
## file or a mistyped one in a recipe should draw as "iron_ingot, 1 per slot" in
## the UI, not divide a stack bar by a zero stack limit.
##
## It is NOT a licence to hold unknown items: inventory.add() still refuses an id
## that is not in the table. This is what the accessors below fall back to so
## that reading about a missing item cannot crash anything.
static func placeholder(item_id: String) -> Dictionary:
	return {
		"display_name": item_id,
		"category": CATEGORY_MATERIAL,
		"stack_limit": 1,
		"max_durability": 0,
	}


static func display_name(item_id: String) -> String:
	return str(definition(item_id).get("display_name", placeholder(item_id)["display_name"]))


static func category(item_id: String) -> String:
	return str(definition(item_id).get("category", placeholder(item_id)["category"]))


## How many of this item fit in one slot.
##
## A durable item is forced to 1 whatever the data says, and that is the single
## line that makes the "tools do not stack" decision impossible to break from a
## JSON edit. See the note in items.json: a stack of five axes has one durability
## value between them, and there is no honest answer to which axe the 40% belongs
## to. Never below 1, so a slot can always hold at least the thing in it.
static func stack_limit(item_id: String) -> int:
	if max_durability(item_id) > 0:
		return 1
	return maxi(1, int(definition(item_id).get("stack_limit", placeholder(item_id)["stack_limit"])))


## Full durability for a fresh one, or 0 for an item that has no durability at
## all. Zero is the answer for every material and for the orb; only tools declare
## a number, and MEADOWS_VERTICAL_SLICE.md M9 is what asks them to.
static func max_durability(item_id: String) -> int:
	return maxi(0, int(definition(item_id).get("max_durability", 0)))


static func is_durable(item_id: String) -> bool:
	return max_durability(item_id) > 0


## Named `is_tool_item` rather than `is_tool` because `Script.is_tool()` is a
## built-in that takes no arguments, and a static function of that name on a
## script object is shadowed by it — the call fails at runtime with "expected 0
## arguments" while the test around it still reports green.
static func is_tool_item(item_id: String) -> bool:
	return category(item_id) == CATEGORY_TOOL


## --- tunables -------------------------------------------------------------

## How many slots the trainer's inventory has. TUNABLE, and in data because
## "I keep running out of room" is the single most likely piece of owner feedback
## about this system and it must be answerable without touching code.
##
## It is a slot count and nothing else. §19 says no weight limit and CLAUDE.md
## repeats it as a hard rule, so there is no second number here to soften this
## one into a carry-weight system by another name.
static func slot_count() -> int:
	return maxi(1, int(config().get("slots", 24)))


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
	if file == null:
		push_error("items.json missing at %s" % ITEMS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var entry: Variant = (parsed as Dictionary).get("inventory")
		if entry is Dictionary:
			_config = entry
	return _config
