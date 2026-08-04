extends RefCounted

## One stack in one slot: what this pile of things currently is.
##
## Split from the item table the same way pal_instance is split from
## pal_species, and for the same reason (TECHNICAL_START.md, "Pal Data vs Pal
## Instance"). The table says an Axe has 120 durability; a stack says THIS axe
## has 43 left. Writing current durability onto the shared definition is the bug
## where chopping with one axe blunts every axe in the game, and it is much
## easier to avoid now than to unpick later.
##
## No nodes, so it is testable headlessly and can outlive whatever draws it.
##
## TOOLS DO NOT STACK. item_defs.stack_limit() forces any durable item to 1, so a
## durable stack is always exactly one object with exactly one durability value.
## The alternative — a stack of five axes with an array of five durabilities —
## makes every split, merge and repair take a which-one argument that no UI has
## anywhere to put. Simpler beats general here.

const DEFS := preload("res://scripts/items/item_defs.gd")

## DEFINITION data lives in items.json and is read through DEFS, never copied
## here: display name, category, stack limit, full durability. Only the two
## values below belong to THIS pile.
var item_id: String = ""
var count: int = 0

## Remaining durability. 0 on every material and every orb, because they have
## none; on a tool it counts down to 0 and stops there.
##
## A tool at 0 is BROKEN, NOT DESTROYED. It keeps its slot, refuses to be used,
## and repair() brings it back — §19 says tools "repair for free at appropriate
## station", and a tool that deleted itself the moment it hit zero would make
## that free repair unreachable. Losing the axe is also pure punishment in a game
## with no weight limit and no carry cost for the spare.
var durability: int = 0


## Build a stack. Returns null for an unknown item id rather than a stack of
## nothing, so a typo fails loudly at the point of the mistake — same contract as
## pal_species.spawn().
##
## `count` is clamped to the item's stack limit rather than refused: the caller
## that asks for 200 wood wants as much wood as a slot can hold, and the
## inventory above is what splits the rest into the next slot.
static func create(id: String, amount: int = 1) -> RefCounted:
	if not DEFS.has(id):
		push_error("unknown item '%s'; known: %s" % [id, ", ".join(DEFS.ids())])
		return null
	var stack: RefCounted = (load("res://scripts/items/item_stack.gd") as GDScript).new()
	stack.item_id = id
	stack.count = clampi(amount, 0, DEFS.stack_limit(id))
	stack.durability = DEFS.max_durability(id)
	return stack


## --- definition, read through ---------------------------------------------

func display_name() -> String:
	return DEFS.display_name(item_id)


func category() -> String:
	return DEFS.category(item_id)


func stack_limit() -> int:
	return DEFS.stack_limit(item_id)


func max_durability() -> int:
	return DEFS.max_durability(item_id)


func is_durable() -> bool:
	return DEFS.is_durable(item_id)


## --- this pile ------------------------------------------------------------

func is_empty() -> bool:
	return count <= 0


func is_full() -> bool:
	return count >= stack_limit()


## How many more of this item this slot could take.
func space() -> int:
	return maxi(0, stack_limit() - count)


## Put some in. Returns what would NOT fit, so the inventory can carry the
## remainder to the next slot instead of silently dropping it.
func add(amount: int) -> int:
	if amount <= 0:
		return maxi(0, amount)
	var taken := mini(amount, space())
	count += taken
	return amount - taken


## Take some out. Returns how many were actually removed, which is fewer than
## asked for when the stack runs out.
func remove(amount: int) -> int:
	var taken := clampi(amount, 0, count)
	count -= taken
	return taken


## Can these two piles become one?
##
## Durable items never can. Their stack limit is 1, so this is belt and braces
## with stack_limit() — but the explicit refusal is what stops a future edit from
## quietly merging two axes and having to invent which durability survived.
func can_merge_with(other: RefCounted) -> bool:
	if other == null or other == self:
		return false
	if str(other.item_id) != item_id:
		return false
	if is_durable():
		return false
	return not is_full() and not other.is_empty()


## Pour `other` into this stack, up to the limit. Returns how many moved, and
## leaves the remainder in `other` rather than destroying it.
func merge_from(other: RefCounted) -> int:
	if not can_merge_with(other):
		return 0
	var moved: int = mini(space(), int(other.count))
	other.remove(moved)
	count += moved
	return moved


## Split `amount` off into a new stack, or null if that is not a legal split.
##
## Splitting off NOTHING or EVERYTHING is refused rather than allowed as a no-op.
## Both are the player's hand slipping on a controller stick, and both have
## outcomes that look like a bug: an empty stack occupying a slot, or the pile
## teleporting whole into the slot beside it. Refusing means the drag simply does
## not take.
##
## The new stack inherits durability, which costs nothing today (a durable stack
## has count 1 and can never be split) and is the only answer that stays honest
## if that ever changes.
func split(amount: int) -> RefCounted:
	if amount <= 0 or amount >= count:
		return null
	var other: RefCounted = create(item_id, 0)
	if other == null:
		return null
	other.durability = durability
	other.count = amount
	count -= amount
	return other


## --- durability -----------------------------------------------------------

## Wear the tool. Returns false and changes nothing on an item with no durability
## or one already broken, so a broken axe cannot go negative and cannot keep
## being swung.
func use(amount: int = 1) -> bool:
	if not is_durable() or amount <= 0 or is_broken():
		return false
	durability = maxi(0, durability - amount)
	return true


func is_broken() -> bool:
	return is_durable() and durability <= 0


func durability_fraction() -> float:
	var full := max_durability()
	return 0.0 if full <= 0 else clampf(float(durability) / float(full), 0.0, 1.0)


## Free, whole, and at any time. §19: "repair for free at appropriate station" —
## the station is a place, not a price, so there is no cost argument here and no
## partial repair. Whoever owns the workbench decides WHERE this may be called;
## this file only knows what repairing means.
func repair() -> void:
	durability = max_durability()


## --- persistence ----------------------------------------------------------

## The serialisable form, and the primary one — same discipline as
## pal_instance.to_record().
##
## Durability is written ONLY for an item that has any. A material would
## otherwise carry a `"durability": 0` that reads, in a hand-inspected save, like
## a broken berry. Nothing derived is stored: the stack limit, the display name
## and the full durability all come back from items.json, so a rebalance reaches
## items already in a save instead of skipping them.
##
## No version number of its own, on purpose — autoload/save_manager.gd carries
## ONE for the whole envelope and says why.
func to_record() -> Dictionary:
	var record: Dictionary = {
		"item": item_id,
		"count": count,
	}
	if is_durable():
		record["durability"] = durability
	return record


## Rebuild a stack from a record. Returns null for an unknown item id or a count
## that is not worth a slot, so a hand-edited or stale save loses one stack
## loudly instead of producing a slot holding nothing.
static func from_record(record: Dictionary) -> RefCounted:
	var id := str(record.get("item", ""))
	if not DEFS.has(id):
		return null
	var stack: RefCounted = create(id, int(record.get("count", 0)))
	if stack == null or stack.is_empty():
		return null
	if stack.is_durable():
		# Clamped rather than trusted. A save written by an older build with a
		# tougher axe would otherwise hand back a tool above its own maximum, and
		# every durability bar in the UI would overflow its own frame.
		stack.durability = clampi(
			int(record.get("durability", stack.max_durability())), 0, stack.max_durability()
		)
	return stack
