extends RefCounted

## The trainer's inventory: a fixed number of slots, each holding one stack.
##
## GAME_DESIGN.md §19 is two lines long and this file exists to enforce both of
## them: "Slot + stack system" and "No weight limit". CLAUDE.md repeats the second
## as a hard rule.
##
## THERE IS NO WEIGHT. Not a field, not a per-item mass, not a "heavy" flag, not
## a soft encumbrance that only slows you down. A field that exists gets used, and
## the first thing anyone does with a weight field is refuse an add for it — at
## which point the design has a carry-weight system it explicitly rejected, and
## picking up stone stops being free. The ONLY thing that can refuse an add here
## is running out of SLOTS.
##
## The refusal tokens are enumerated in REFUSALS below and none of them is about
## weight; tests/test_inventory.gd asserts that, so adding one is a red build
## rather than a quiet drift.
##
## No nodes, so the inventory survives a scene change, can be tested headlessly,
## and can be handed to a death satchel (§22) without a scene tree.
##
## Holds ITEMS. It cannot hold a pal, and there is no code path that would let it
## try: it stores item ids from items.json and nothing else. The five-pal cap
## lives in party.gd and this file is not a way around it.

const DEFS := preload("res://scripts/items/item_defs.gd")
const STACK := preload("res://scripts/items/item_stack.gd")

## Why the last operation was refused, as a stable token. Empty after anything
## that succeeded.
##
## Tokens and not sentences, for the reason party.gd gives: the inventory has no
## business knowing how a refusal is worded, and a sentence written here is one
## the UI cannot shorten for a toast or lengthen for a tooltip. Listed in
## REFUSALS so a UI has an exhaustive set to map — every one of these must have
## something to draw, and a token nobody handles is a silent no-op on screen.
const REFUSED_INVENTORY_FULL := "inventory_full"
const REFUSED_UNKNOWN_ITEM := "unknown_item"
const REFUSED_NO_SUCH_SLOT := "no_such_slot"
const REFUSED_EMPTY_SLOT := "empty_slot"
const REFUSED_SLOT_OCCUPIED := "slot_occupied"
const REFUSED_BAD_AMOUNT := "bad_amount"
const REFUSED_NOT_ENOUGH := "not_enough"
const REFUSED_DIFFERENT_ITEMS := "different_items"
const REFUSED_NOT_STACKABLE := "not_stackable"
const REFUSED_NOT_DURABLE := "not_durable"
const REFUSED_TOOL_BROKEN := "tool_broken"

const REFUSALS := [
	REFUSED_INVENTORY_FULL,
	REFUSED_UNKNOWN_ITEM,
	REFUSED_NO_SUCH_SLOT,
	REFUSED_EMPTY_SLOT,
	REFUSED_SLOT_OCCUPIED,
	REFUSED_BAD_AMOUNT,
	REFUSED_NOT_ENOUGH,
	REFUSED_DIFFERENT_ITEMS,
	REFUSED_NOT_STACKABLE,
	REFUSED_NOT_DURABLE,
	REFUSED_TOOL_BROKEN,
]

## One entry per slot: an item_stack, or null for an empty slot. Null rather than
## an empty stack, so "this slot is free" is one check and cannot be confused
## with a slot holding zero wood.
var _slots: Array = []
var _refusal: String = ""


## `slots` defaults to the tunable in data/items/items.json. Passed in only by a
## caller that genuinely has a different container — a death satchel or a chest —
## rather than by anyone who fancies more room, which is what the data value is
## for.
func _init(slots: int = -1) -> void:
	var count: int = slots if slots > 0 else DEFS.slot_count()
	_slots.resize(count)


func last_refusal() -> String:
	return _refusal


func slot_count() -> int:
	return _slots.size()


## A COPY of the slot array. Deliberately not the live one: GDScript passes an
## Array by reference, so handing the real one out would let any caller drop a
## stack straight into a slot without going near add(), and every rule in this
## file would hold only by politeness. The stacks inside are the live ones, the
## same way party.members() hands back real pals in a copied roster.
func slots() -> Array:
	return _slots.duplicate()


func at(index: int) -> RefCounted:
	if index < 0 or index >= _slots.size():
		return null
	return _slots[index]


func is_slot_empty(index: int) -> bool:
	var stack: RefCounted = at(index)
	return stack == null or stack.is_empty()


func first_empty_slot() -> int:
	for i in _slots.size():
		if _slots[i] == null:
			return i
	return -1


## Full means every slot is occupied. It does NOT mean "cannot take another
## thing": a full inventory with a half stack of wood in it still has room for
## more wood, and add() will find it.
func is_full() -> bool:
	return first_empty_slot() == -1


func is_empty() -> bool:
	for i in _slots.size():
		if _slots[i] != null:
			return false
	return true


func used_slots() -> int:
	var used := 0
	for i in _slots.size():
		if _slots[i] != null:
			used += 1
	return used


## How many of an item are held, across every slot. What a build cost or a recipe
## asks before it spends anything.
func count_of(item_id: String) -> int:
	var total := 0
	for i in _slots.size():
		var stack: RefCounted = _slots[i]
		if stack != null and str(stack.item_id) == item_id:
			total += int(stack.count)
	return total


func has(item_id: String, amount: int = 1) -> bool:
	return count_of(item_id) >= amount


## --- adding and removing --------------------------------------------------

## Take `amount` of an item. ALL OR NOTHING: if the whole amount does not fit,
## nothing is added and the inventory is exactly as it was.
##
## A half-applied refusal is worse than a clean one. "You picked up 12 of 30
## stone, the rest is gone" is a bug report nobody can reproduce, and a partial
## add that also returns false gives the caller no way to know what it now owes
## the world. A caller that wants the partial behaviour can ask for less.
##
## Partial stacks of the same item are filled BEFORE an empty slot is taken.
## Without that, picking up wood ten times gives ten slots of wood and a
## 24-slot inventory is full after one clearing.
func add(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		_refusal = REFUSED_BAD_AMOUNT
		return false
	if not DEFS.has(item_id):
		# Refused rather than placed as a placeholder. item_defs.placeholder()
		# exists so a stale id can be DESCRIBED without crashing; it is not a
		# licence to acquire one, and an item that is not in items.json is a typo
		# in a recipe or a drop table, not a thing the player found.
		_refusal = REFUSED_UNKNOWN_ITEM
		return false

	var plan := _plan_add(item_id, amount)
	if plan.is_empty():
		_refusal = REFUSED_INVENTORY_FULL
		return false

	for step: Dictionary in plan:
		var index := int(step["slot"])
		if _slots[index] == null:
			_slots[index] = STACK.create(item_id, 0)
		(_slots[index] as RefCounted).add(int(step["amount"]))
	_refusal = ""
	return true


## Where `amount` of an item would go, or an empty Array if it does not all fit.
##
## Computed in full before a single slot is touched, which is what makes add()
## all-or-nothing rather than "mostly".
func _plan_add(item_id: String, amount: int) -> Array:
	var left := amount
	var plan: Array = []

	for i in _slots.size():
		if left <= 0:
			break
		var stack: RefCounted = _slots[i]
		if stack == null or str(stack.item_id) != item_id:
			continue
		var space := int(stack.space())
		if space <= 0:
			continue
		var take := mini(space, left)
		plan.append({"slot": i, "amount": take})
		left -= take

	var limit := DEFS.stack_limit(item_id)
	for i in _slots.size():
		if left <= 0:
			break
		if _slots[i] != null:
			continue
		var take := mini(limit, left)
		plan.append({"slot": i, "amount": take})
		left -= take

	return plan if left <= 0 else []


## Spend `amount` of an item from wherever it is held. ALL OR NOTHING, for the
## same reason as add(): a crafting cost that takes half its wood and then fails
## has charged the player for nothing.
func remove(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		_refusal = REFUSED_BAD_AMOUNT
		return false
	if count_of(item_id) < amount:
		_refusal = REFUSED_NOT_ENOUGH
		return false

	var left := amount
	for i in _slots.size():
		if left <= 0:
			break
		var stack: RefCounted = _slots[i]
		if stack == null or str(stack.item_id) != item_id:
			continue
		left -= int(stack.remove(mini(left, int(stack.count))))
		if stack.is_empty():
			_slots[i] = null
	_refusal = ""
	return true


## Take from ONE named slot — what a UI drag onto the world does, as opposed to
## remove(), which spends from wherever.
func remove_at(index: int, amount: int = 1) -> bool:
	if index < 0 or index >= _slots.size():
		_refusal = REFUSED_NO_SUCH_SLOT
		return false
	var stack: RefCounted = _slots[index]
	if stack == null:
		_refusal = REFUSED_EMPTY_SLOT
		return false
	if amount <= 0:
		_refusal = REFUSED_BAD_AMOUNT
		return false
	if int(stack.count) < amount:
		_refusal = REFUSED_NOT_ENOUGH
		return false
	stack.remove(amount)
	if stack.is_empty():
		_slots[index] = null
	_refusal = ""
	return true


## Put an existing stack into a slot, keeping whatever durability it carries.
## The path a satchel or a chest hands something back through — a 40%-worn axe
## has to arrive as a 40%-worn axe, which add() cannot do because it builds a
## fresh one from the definition.
func place(stack: RefCounted, index: int = -1) -> bool:
	if stack == null or not DEFS.has(str(stack.item_id)):
		_refusal = REFUSED_UNKNOWN_ITEM
		return false
	if stack.is_empty():
		_refusal = REFUSED_BAD_AMOUNT
		return false
	var target := index
	if target < 0:
		target = first_empty_slot()
		if target < 0:
			_refusal = REFUSED_INVENTORY_FULL
			return false
	elif target >= _slots.size():
		_refusal = REFUSED_NO_SUCH_SLOT
		return false
	elif _slots[target] != null:
		_refusal = REFUSED_SLOT_OCCUPIED
		return false
	_slots[target] = stack
	_refusal = ""
	return true


## --- rearranging ----------------------------------------------------------

## Drag one slot onto another. Merges when the two are the same stackable item,
## swaps otherwise.
##
## Swap rather than refuse, because refusing a drag onto an occupied slot means
## reordering a full inventory is impossible without an empty slot to shuffle
## through — which is exactly when a player most wants to reorder it.
func move(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= _slots.size() or to_index < 0 or to_index >= _slots.size():
		_refusal = REFUSED_NO_SUCH_SLOT
		return false
	if from_index == to_index:
		_refusal = ""
		return true
	var from_stack: RefCounted = _slots[from_index]
	if from_stack == null:
		_refusal = REFUSED_EMPTY_SLOT
		return false

	var to_stack: RefCounted = _slots[to_index]
	if to_stack != null and to_stack.can_merge_with(from_stack):
		to_stack.merge_from(from_stack)
		# The remainder stays where it was rather than vanishing: dropping 40 wood
		# onto a stack that can take 9 leaves 31 in the hand, not 31 nowhere.
		if from_stack.is_empty():
			_slots[from_index] = null
		_refusal = ""
		return true

	_slots[to_index] = from_stack
	_slots[from_index] = to_stack
	_refusal = ""
	return true


## Pour one slot into another. The explicit half of move(), for a UI that offers
## "combine" as its own verb.
func merge_slots(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= _slots.size() or to_index < 0 or to_index >= _slots.size():
		_refusal = REFUSED_NO_SUCH_SLOT
		return false
	var from_stack: RefCounted = _slots[from_index]
	var to_stack: RefCounted = _slots[to_index]
	if from_stack == null or to_stack == null or from_index == to_index:
		_refusal = REFUSED_EMPTY_SLOT
		return false
	if str(from_stack.item_id) != str(to_stack.item_id):
		_refusal = REFUSED_DIFFERENT_ITEMS
		return false
	if to_stack.is_durable():
		# Two axes are two axes. There is no honest answer to which durability the
		# merged one would carry, so the merge is refused instead of guessed at.
		_refusal = REFUSED_NOT_STACKABLE
		return false
	if to_stack.is_full():
		_refusal = REFUSED_INVENTORY_FULL
		return false
	to_stack.merge_from(from_stack)
	if from_stack.is_empty():
		_slots[from_index] = null
	_refusal = ""
	return true


## Split `amount` off a slot into another one, or into the first free slot when
## `to_index` is negative.
##
## Splitting off nothing, or everything, is refused — see item_stack.split(). The
## first leaves an empty stack sitting in a slot and the second is a teleport
## that reads as a bug. Both are a stick slipping, and refusing means the drag
## simply does not take.
func split_slot(from_index: int, amount: int, to_index: int = -1) -> bool:
	if from_index < 0 or from_index >= _slots.size():
		_refusal = REFUSED_NO_SUCH_SLOT
		return false
	var from_stack: RefCounted = _slots[from_index]
	if from_stack == null:
		_refusal = REFUSED_EMPTY_SLOT
		return false
	if from_stack.is_durable():
		_refusal = REFUSED_NOT_STACKABLE
		return false
	if amount <= 0 or amount >= int(from_stack.count):
		_refusal = REFUSED_BAD_AMOUNT
		return false

	var target := to_index
	if target < 0:
		target = first_empty_slot()
		if target < 0:
			_refusal = REFUSED_INVENTORY_FULL
			return false
	elif target >= _slots.size():
		_refusal = REFUSED_NO_SUCH_SLOT
		return false
	elif _slots[target] != null:
		_refusal = REFUSED_SLOT_OCCUPIED
		return false

	var split: RefCounted = from_stack.split(amount)
	if split == null:
		_refusal = REFUSED_BAD_AMOUNT
		return false
	_slots[target] = split
	_refusal = ""
	return true


## --- tools ----------------------------------------------------------------

## Wear the tool in a slot. Refused, with a reason, on anything that is not a
## tool and on one already broken — M9 wants durability to be a real cost, and a
## broken axe that keeps chopping is not one.
func use_tool(index: int, amount: int = 1) -> bool:
	var stack: RefCounted = at(index)
	if stack == null:
		_refusal = REFUSED_EMPTY_SLOT if index >= 0 and index < _slots.size() else REFUSED_NO_SUCH_SLOT
		return false
	if not stack.is_durable():
		_refusal = REFUSED_NOT_DURABLE
		return false
	if stack.is_broken():
		# Broken, not gone. The tool keeps its slot and repair() is what fixes it;
		# see item_stack.durability for why it is not destroyed.
		_refusal = REFUSED_TOOL_BROKEN
		return false
	stack.use(amount)
	_refusal = ""
	return true


## Free repair, §19. No cost, no materials, no partial restore. Whoever owns the
## workbench decides where this may be called from.
func repair(index: int) -> bool:
	var stack: RefCounted = at(index)
	if stack == null:
		_refusal = REFUSED_EMPTY_SLOT if index >= 0 and index < _slots.size() else REFUSED_NO_SUCH_SLOT
		return false
	if not stack.is_durable():
		_refusal = REFUSED_NOT_DURABLE
		return false
	stack.repair()
	_refusal = ""
	return true


func clear() -> void:
	for i in _slots.size():
		_slots[i] = null
	_refusal = ""


## --- persistence ----------------------------------------------------------

## The serialisable form, and the primary one (party.gd, same discipline).
##
## The inventory owns no save path and no version number — autoload/save_manager
## keeps ONE envelope and one version for the whole game, and this Array is a
## domain's payload.
##
## The slot INDEX is stored with each stack rather than the array being written
## dense. Where the axe sits is the player's own arrangement: §19 asks for quick
## tool selection, and a reload that tidies everything leftwards moves the tool
## out from under the button they had learned.
func to_records() -> Array:
	var out: Array = []
	for i in _slots.size():
		var stack: RefCounted = _slots[i]
		if stack == null or stack.is_empty():
			continue
		var record: Dictionary = stack.to_record()
		record["slot"] = i
		out.append(record)
	return out


## Rebuild an inventory from records.
##
## Defensive in the same way party.from_records() is, and for the same reason: a
## save file is a text file on a Windows machine and will eventually be
## hand-edited, copied between builds, or written by a bug. A record naming an
## item that no longer exists, claiming a slot past the end of a shrunken
## inventory, or landing on a slot another record already took, costs ONE stack
## and not the save.
##
## Records with no slot, or an unusable one, fall through to the first free slot
## rather than being dropped. Losing the arrangement is recoverable; losing the
## 40%-worn axe is the kind of thing an owner notices an hour later.
static func from_records(records: Array, slots: int = -1) -> RefCounted:
	var inventory: RefCounted = (load("res://scripts/items/inventory.gd") as GDScript).new(slots)
	for entry: Variant in records:
		if not entry is Dictionary:
			continue
		var record: Dictionary = entry
		var stack: RefCounted = STACK.from_record(record)
		if stack == null:
			push_warning("inventory save holds an item that no longer exists; that stack is dropped")
			continue
		var slot := int(record.get("slot", -1))
		if slot < 0 or slot >= inventory.slot_count() or not inventory.is_slot_empty(slot):
			slot = -1
		if not inventory.place(stack, slot):
			push_warning("inventory save holds more stacks than there are slots; the rest are dropped")
			break
	return inventory
