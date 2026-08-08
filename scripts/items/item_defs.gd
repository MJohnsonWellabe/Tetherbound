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

## The second table. One item table split across two files, merged here.
##
## items.json belongs to the milestone that gathers and builds; consumables.json
## belongs to the milestone that eats. Two milestones editing one file is two
## sets of merge conflicts over a file neither of them owns outright, and the
## merge below costs one function.
##
## An entry there may EXTEND one here — `berries` is declared in items.json as a
## material with a comment saying this is where it becomes food, and gains its
## `food` block and its real category from the other file without items.json
## changing — or declare a whole new item.
const CONSUMABLES_PATH := "res://data/items/consumables.json"

## The categories the item tables may declare. Named here so a typo in a category
## fails a test rather than silently producing an item nothing can sort.
const CATEGORY_MATERIAL := "material"
const CATEGORY_TOOL := "tool"
const CATEGORY_ORB := "orb"
## Something that is USED UP. Not necessarily eaten: the revival draught is spent
## on a fainted pal and berries are eaten by the trainer, and both are consumed.
## `is_food()` is the narrower question and it is answered by the presence of a
## `food` block, not by the category.
const CATEGORY_CONSUMABLE := "consumable"
const CATEGORIES := [CATEGORY_MATERIAL, CATEGORY_TOOL, CATEGORY_ORB, CATEGORY_CONSUMABLE]

## Where a food's timed bonus lives inside an item definition.
const FOOD_KEY := "food"

static var _table: Dictionary = {}
static var _config: Dictionary = {}


static func table() -> Dictionary:
	if not _table.is_empty():
		return _table
	var out: Dictionary = _read_items(ITEMS_PATH, true)
	if out.is_empty():
		return {}
	_merge(out, _read_items(CONSUMABLES_PATH, false))
	_table = out
	return _table


## One file's `items` block, with its comment keys stripped.
##
## Comment keys are stripped rather than trusted to be absent, for the reason
## pal_traits.gd gives: the files invite `_comment_<topic>` keys inline, and one
## written a level too high would otherwise become a real item — a nameless thing
## with a stack limit of 1 that a player could somehow be holding. Stripped at
## every level, not just the top, so a `_comment` inside a `food` block is not
## read as a bonus.
##
## `required` separates the two tables' failure modes: items.json missing is the
## game having no items at all and is an error; consumables.json missing costs
## the food bonuses and nothing else, and a project that has not written it yet
## should still boot.
static func _read_items(path: String, required: bool) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		if required:
			push_error("%s missing" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("%s is not readable" % path)
		return {}
	var out: Dictionary = {}
	var entries: Variant = (parsed as Dictionary).get("items", {})
	if not entries is Dictionary:
		return {}
	for id: String in (entries as Dictionary).keys():
		if id.begins_with("_"):
			continue
		var entry: Variant = (entries as Dictionary)[id]
		out[id] = _strip_comments(entry) if entry is Dictionary else entry
	return out


static func _strip_comments(entry: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: String in entry.keys():
		if key.begins_with("_"):
			continue
		var value: Variant = entry[key]
		out[key] = _strip_comments(value as Dictionary) if value is Dictionary else value
	return out


## Fold `extra` into `base`, per item, key by key.
##
## SHALLOW PER KEY, deliberately. `berries` in consumables.json declares a
## category and a `food` block and says nothing about its stack limit, so the
## limit stays the one items.json set; but a `food` block is replaced whole
## rather than merged field by field, because half a bonus from each file is a
## number nobody could trace to a line.
static func _merge(base: Dictionary, extra: Dictionary) -> void:
	for id: String in extra.keys():
		var addition: Variant = extra[id]
		if not addition is Dictionary:
			continue
		if not base.has(id) or not base[id] is Dictionary:
			base[id] = addition
			continue
		var merged: Dictionary = (base[id] as Dictionary).duplicate(true)
		for key: String in (addition as Dictionary).keys():
			merged[key] = (addition as Dictionary)[key]
		base[id] = merged


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


static func is_consumable(item_id: String) -> bool:
	return category(item_id) == CATEGORY_CONSUMABLE


## --- food -----------------------------------------------------------------
##
## GAME_DESIGN.md §18: "Valheim-like buff philosophy: No starvation death. Eating
## improves health/stamina/regeneration or other preparation stats."
##
## THE ABSENCE HERE IS THE DESIGN. There is no `hunger()`, no `satiation()`, no
## decay rate and nothing that counts down when the player has not eaten, because
## CLAUDE.md makes "no starvation-death meter" a hard rule and lists "adding
## mandatory hunger/thirst" among the decisions an agent may not make. A food's
## whole effect is the timed bonus below; not eating costs nothing.

## The timed bonus an item grants, or empty for the vast majority of items that
## grant none. What is IN the block is scripts/player/player_vitals.gd's business
## — this file only knows the block is item data and belongs beside the item.
static func food(item_id: String) -> Dictionary:
	var block: Variant = definition(item_id).get(FOOD_KEY, {})
	return (block as Dictionary).duplicate(true) if block is Dictionary else {}


## Can the trainer eat this? The presence of a bonus, not the category: the
## revival draught is a consumable that is spent on a pal and can never be eaten,
## and it says so by having no `food` block rather than by being a fourth
## category.
static func is_food(item_id: String) -> bool:
	return not food(item_id).is_empty()


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
