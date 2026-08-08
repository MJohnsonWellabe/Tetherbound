extends RefCounted

## What the trainer is WEARING: five slots, and the rules about what may go in
## them.
##
## MEADOWS_VERTICAL_SLICE.md M9 asks for "armor slots architecture" in exactly
## those words — the structure, not a wardrobe. GAME_DESIGN.md §18 names the five:
## Helmet, Upper body, Lower body, Boots, Backpack. This file is those five slots,
## the rules that decide what fits in one, and the persistence. It is deliberately
## EMPTY at run time, because there is not one piece of armour in the game.
##
## WHAT IS NOT HERE, AND WHY NOT:
##
##   * No armour VALUE, no resistance, no warmth, no stat of any kind. §18 says
##     trainer armour protects the human, and a later biome will want cold and
##     heat resistance — none of which can be given a number before a single
##     garment exists to carry one. A `defence` field here would be a number
##     invented for an item nobody has drawn, and the first thing anyone would do
##     with it is balance the game around it.
##   * No damage reduction wired into `player_vitals.take_damage()`. Its comment
##     already names the right seam and this file will hand it a number the day
##     there is a garment with one. Plumbing a reduction that is always zero
##     through the one function that can kill the player buys nothing and can only
##     be wrong.
##   * No "the backpack gives you more slots". That is a capacity mechanic, it is
##     one short step from the carry-weight system CLAUDE.md forbids twice, and it
##     is a design decision rather than an implementation detail. The slot exists;
##     what a backpack does when one is drawn is the owner's call.
##
## WHAT DECIDES WHERE A GARMENT GOES is the garment, not this file. An item is
## wearable when its definition names an `equip_slot`, and nothing in either item
## table names one today — so `can_equip()` is false for every item in the game
## and says why with a token. That is the honest state of a milestone whose art
## does not exist, and it is one JSON field away from working.
##
## No nodes, like `inventory.gd` beside it: the rules are arithmetic over five
## references and are testable without a scene.

const DEFS := preload("res://scripts/items/item_defs.gd")

## Where a garment declares which slot it belongs in. No item in either table
## carries this key yet.
const SLOT_KEY := "equip_slot"

## §18's five, in the order they are drawn on the screen — head down, then the
## bag. These are DESIGN and not tuning: the list is in the design document, so it
## is a const here rather than a number in data/config that someone could add a
## sixth to without a conversation.
const SLOT_HEAD := "head"
const SLOT_UPPER := "upper"
const SLOT_LOWER := "lower"
const SLOT_FEET := "feet"
const SLOT_BACK := "back"
const SLOTS := [SLOT_HEAD, SLOT_UPPER, SLOT_LOWER, SLOT_FEET, SLOT_BACK]

## What each is called on screen, in §18's own words.
const SLOT_NAMES := {
	SLOT_HEAD: "Helmet",
	SLOT_UPPER: "Upper body",
	SLOT_LOWER: "Lower body",
	SLOT_FEET: "Boots",
	SLOT_BACK: "Backpack",
}

## Refusal tokens, not sentences — `party.gd` established the idiom and its reason
## holds: this file has no business knowing how a refusal is worded.
##
## NONE OF THEM IS ABOUT WEIGHT, and that is the same tripwire `inventory.gd`
## carries. A carry-weight system does not come back under its own name; it comes
## back as "that is too heavy to wear".
const REFUSED_NO_SUCH_SLOT := "no_such_slot"
const REFUSED_NOT_WEARABLE := "not_wearable"
const REFUSED_WRONG_SLOT := "wrong_slot"
const REFUSED_SLOT_OCCUPIED := "slot_occupied"
const REFUSED_EMPTY_SLOT := "empty_slot"
const REFUSALS := [
	REFUSED_NO_SUCH_SLOT,
	REFUSED_NOT_WEARABLE,
	REFUSED_WRONG_SLOT,
	REFUSED_SLOT_OCCUPIED,
	REFUSED_EMPTY_SLOT,
]

## `slot id -> item_stack`, holding only the slots that are filled. Every one of
## them is empty today.
var _worn: Dictionary = {}
var _refusal: String = ""


func last_refusal() -> String:
	return _refusal


func slots() -> Array:
	return SLOTS.duplicate()


static func slot_name(slot: String) -> String:
	return str(SLOT_NAMES.get(slot, slot))


static func has_slot(slot: String) -> bool:
	return SLOTS.has(slot)


func at(slot: String) -> RefCounted:
	var stack: Variant = _worn.get(slot)
	return stack if stack is RefCounted else null


func is_slot_empty(slot: String) -> bool:
	return at(slot) == null


func is_empty() -> bool:
	for slot: String in SLOTS:
		if not is_slot_empty(slot):
			return false
	return true


func worn_count() -> int:
	var count := 0
	for slot: String in SLOTS:
		if not is_slot_empty(slot):
			count += 1
	return count


## --- the rules ------------------------------------------------------------

## Which slot an item belongs in, or "" for the entire current item table.
##
## Read off the item's own definition. A `match` on item ids here would be the
## place every future garment has to be registered, and the one nobody remembers
## to edit.
static func slot_for(item_id: String) -> String:
	var slot := str(DEFS.definition(item_id).get(SLOT_KEY, ""))
	return slot if has_slot(slot) else ""


static func is_wearable(item_id: String) -> bool:
	return slot_for(item_id) != ""


## Could this go on, right now? Refused with a reason so a UI can say which of
## the three "no"s it was: not a garment at all, the wrong slot for it, or a slot
## with something already in it.
func can_equip(item_id: String, slot: String = "") -> bool:
	_refusal = ""
	var wants := slot_for(item_id)
	if wants == "":
		_refusal = REFUSED_NOT_WEARABLE
		return false
	if slot != "" and slot != wants:
		_refusal = REFUSED_WRONG_SLOT if has_slot(slot) else REFUSED_NO_SUCH_SLOT
		return false
	if not is_slot_empty(wants):
		_refusal = REFUSED_SLOT_OCCUPIED
		return false
	return true


## Put a stack on. The stack is the one from the inventory, kept whole with its
## durability — the same discipline `inventory.place()` follows and for the same
## reason: a 40%-worn thing has to stay 40% worn wherever it is put.
func equip(stack: RefCounted) -> bool:
	if stack == null:
		_refusal = REFUSED_EMPTY_SLOT
		return false
	var item_id := str(stack.item_id)
	if not can_equip(item_id):
		return false
	_worn[slot_for(item_id)] = stack
	_refusal = ""
	return true


## Take a slot's contents off and hand them back. The caller puts them somewhere;
## this file does not know what an inventory is, so a garment cannot be lost by
## being taken off with nowhere to go — it is returned, or nothing happens.
func take(slot: String) -> RefCounted:
	if not has_slot(slot):
		_refusal = REFUSED_NO_SUCH_SLOT
		return null
	var stack := at(slot)
	if stack == null:
		_refusal = REFUSED_EMPTY_SLOT
		return null
	_worn.erase(slot)
	_refusal = ""
	return stack


func clear() -> void:
	_worn.clear()
	_refusal = ""


## --- persistence ----------------------------------------------------------
##
## Records, like everything else that has to survive a relaunch. An empty
## wardrobe writes an empty Array, which is one line in the save file and the
## honest state of the game.
##
## WORN GEAR IS NOT CARRIED INVENTORY. §22 drops what the trainer is CARRYING into
## the death satchel; armour is on them, not in the bag, and
## `scripts/player/death.gd` says so where it decides what falls.

func to_records() -> Array:
	var out: Array = []
	for slot: String in SLOTS:
		var stack := at(slot)
		if stack == null:
			continue
		var record: Dictionary = stack.to_record()
		record["slot"] = slot
		out.append(record)
	return out


## Defensive in the same way `inventory.from_records()` is: a record naming a slot
## that no longer exists, or an item that no longer exists, costs that one garment
## and never the save.
static func from_records(records: Array) -> RefCounted:
	var STACK := load("res://scripts/items/item_stack.gd") as GDScript
	var out: RefCounted = (load("res://scripts/player/equipment.gd") as GDScript).new()
	for entry: Variant in records:
		if not entry is Dictionary:
			continue
		var record: Dictionary = entry
		var slot := str(record.get("slot", ""))
		if not has_slot(slot):
			push_warning("equipment save names slot '%s', which does not exist; that piece is dropped" % slot)
			continue
		var stack: RefCounted = STACK.from_record(record)
		if stack == null:
			push_warning("equipment save holds an item that no longer exists; that piece is dropped")
			continue
		out._worn[slot] = stack
	return out
