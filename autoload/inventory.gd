extends RefCounted

## The satchel: a fixed array of slots that hold stacks.
##
## GAME_DESIGN.md 19: slot + stack, NO weight limit. There is no mass, no
## encumbrance and no carry cap anywhere in this file, and CLAUDE.md forbids
## adding one.
##
## Slots are a fixed-length array with `null` holes rather than a dense list,
## because slot POSITION is player-visible state. Dragging wood from slot 3 to
## slot 11 has to survive a save; a dense list would reshuffle the satchel on
## every load. This is the one piece of the previous prototype's Inventory.ts
## that is worth copying verbatim, and it is copied verbatim.
##
## Pure logic, no nodes, so tests/test_inventory.gd can exercise it headlessly.

const SLOT_COUNT := 24
## The first row doubles as the quick-select band (GAME_DESIGN.md 19 wants quick
## tool selection). Nothing reads it yet; it is here so the grid and the future
## hotbar cannot disagree about which slots they mean.
const HOTBAR_SLOTS := 6

## Bumped on every change. The menu polls this rather than listening to a
## signal — scripts/ui/combat_hud.gd sets the house rule that UI reads state and
## never keeps a copy of it, and a revision counter is how a poller knows to
## rebuild nodes instead of rebuilding them 60 times a second.
var revision: int = 0

var _db: RefCounted
var _slots: Array = []


func _init(db: RefCounted) -> void:
	_db = db
	_slots.resize(SLOT_COUNT)
	_slots.fill(null)


func slot_count() -> int:
	return SLOT_COUNT


## The stack in a slot, or an empty dictionary. Returns a COPY: handing the UI
## the live dictionary invites it to edit the satchel by drawing it.
func stack_at(index: int) -> Dictionary:
	if index < 0 or index >= SLOT_COUNT:
		return {}
	var stack: Variant = _slots[index]
	return {} if stack == null else (stack as Dictionary).duplicate()


func is_slot_empty(index: int) -> bool:
	return stack_at(index).is_empty()


func count(id: String) -> int:
	var total := 0
	for stack in _slots:
		if stack != null and str((stack as Dictionary).get("id", "")) == id:
			total += int((stack as Dictionary).get("n", 0))
	return total


func is_full() -> bool:
	for stack in _slots:
		if stack == null:
			return false
	return true


func used_slots() -> int:
	var used := 0
	for stack in _slots:
		if stack != null:
			used += 1
	return used


## Add items. Returns how many did NOT fit.
##
## Callers must handle the remainder rather than assume success: picking up more
## than the satchel holds is normal, and silently deleting the excess is the bug
## players only notice after losing something rare.
##
## Partial stacks are filled before new slots are opened, so a satchel cannot
## end up with three half-stacks of wood while claiming to be full.
func add(id: String, n: int) -> int:
	if n <= 0 or id.is_empty():
		return maxi(0, n)
	var maximum: int = _db.call("stack_size", id)
	var left := n

	if maximum > 1:
		for i in SLOT_COUNT:
			if left <= 0:
				break
			var stack: Variant = _slots[i]
			if stack == null:
				continue
			var dict := stack as Dictionary
			if str(dict.get("id", "")) != id or int(dict.get("n", 0)) >= maximum:
				continue
			var room: int = maximum - int(dict.get("n", 0))
			var put: int = mini(room, left)
			dict["n"] = int(dict.get("n", 0)) + put
			left -= put

	for i in SLOT_COUNT:
		if left <= 0:
			break
		if _slots[i] != null:
			continue
		var put: int = mini(maximum, left)
		_slots[i] = {"id": id, "n": put}
		left -= put

	if left != n:
		revision += 1
	return left


## Remove items. All-or-nothing: returns false and changes nothing when there is
## not enough, so a craft can never half-consume its cost.
func remove(id: String, n: int) -> bool:
	if n <= 0:
		return true
	if count(id) < n:
		return false

	var left := n
	# Drain the smallest stacks first so the satchel consolidates rather than
	# accumulating a scatter of single items.
	var order: Array[int] = []
	for i in SLOT_COUNT:
		var stack: Variant = _slots[i]
		if stack != null and str((stack as Dictionary).get("id", "")) == id:
			order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		return int((_slots[a] as Dictionary).get("n", 0)) < int((_slots[b] as Dictionary).get("n", 0)))

	for i in order:
		if left <= 0:
			break
		var dict := _slots[i] as Dictionary
		var take: int = mini(int(dict.get("n", 0)), left)
		dict["n"] = int(dict.get("n", 0)) - take
		left -= take
		if int(dict.get("n", 0)) <= 0:
			_slots[i] = null

	revision += 1
	return true


## True when `n` of `id` would fit with no remainder. Asked BEFORE a pickup, so
## the world can leave a node standing rather than harvest it into nothing.
func has_room_for(id: String, n: int) -> bool:
	var maximum: int = _db.call("stack_size", id)
	var room := 0
	for stack in _slots:
		if stack == null:
			room += maximum
		elif str((stack as Dictionary).get("id", "")) == id and maximum > 1:
			room += maximum - int((stack as Dictionary).get("n", 0))
		if room >= n:
			return true
	return room >= n


## Move or merge one slot into another.
##
## Merges when both hold the same stackable item, swaps otherwise. Swapping
## rather than refusing is deliberate: putting a stack onto an occupied slot
## means "put it here", and a move that silently does nothing feels broken.
func move_slot(from: int, to: int) -> void:
	if from == to:
		return
	if from < 0 or to < 0 or from >= SLOT_COUNT or to >= SLOT_COUNT:
		return

	var source: Variant = _slots[from]
	if source == null:
		return
	var target: Variant = _slots[to]
	var a := source as Dictionary

	if target != null:
		var b := target as Dictionary
		var id := str(a.get("id", ""))
		var cap: int = _db.call("stack_size", id)
		if str(b.get("id", "")) == id and cap > 1:
			var room: int = cap - int(b.get("n", 0))
			var moved: int = mini(room, int(a.get("n", 0)))
			b["n"] = int(b.get("n", 0)) + moved
			a["n"] = int(a.get("n", 0)) - moved
			if int(a.get("n", 0)) <= 0:
				_slots[from] = null
			revision += 1
			return

	_slots[to] = source
	_slots[from] = target
	revision += 1


## R2.2. The first slot holding `id`, or -1. Tools are `stack: 1` so there is
## normally at most one; if a future acquisition path ever grants a second,
## only the first found is read or damaged -- the same "no way to choose
## among duplicates" gap `count()`'s callers already live with.
func find_slot(id: String) -> int:
	for i in SLOT_COUNT:
		var stack: Variant = _slots[i]
		if stack != null and str((stack as Dictionary).get("id", "")) == id:
			return i
	return -1


## Current durability of the stack in `index`, or 0 if the slot is empty or
## holds something with no `durability` field. A slot with no `durability` key
## of its own reads as fully repaired -- `add()` never has to know this field
## exists, it only gets written once something actually damages or repairs it.
func durability_at(index: int) -> int:
	var stack := stack_at(index)
	if stack.is_empty():
		return 0
	var id := str(stack.get("id", ""))
	var maximum: int = _db.call("max_durability", id)
	if maximum <= 0:
		return 0
	return clampi(int(stack.get("durability", maximum)), 0, maximum)


func max_durability_at(index: int) -> int:
	var stack := stack_at(index)
	if stack.is_empty():
		return 0
	return int(_db.call("max_durability", str(stack.get("id", ""))))


## Wear the tool in `index` down by `amount`, floored at 0 (broken, not
## destroyed -- GAME_DESIGN.md 19 says repair, never replace). No-op on a
## slot with no durability to lose, so calling this on a resource stack by
## mistake can't corrupt it into carrying a stray field.
func damage_tool(index: int, amount: int = 1) -> void:
	var maximum := max_durability_at(index)
	if maximum <= 0:
		return
	var current := durability_at(index)
	var stack := _slots[index] as Dictionary
	stack["durability"] = maxi(0, current - amount)
	revision += 1


## Free, full repair -- GAME_DESIGN.md 19. No materials, no partial repair.
func repair_tool(index: int) -> void:
	var maximum := max_durability_at(index)
	if maximum <= 0:
		return
	var stack := _slots[index] as Dictionary
	if int(stack.get("durability", maximum)) == maximum:
		return
	stack["durability"] = maximum
	revision += 1


## Discard everything in a slot. Different from remove(id, n): drop targets
## the SPECIFIC slot the player is looking at, never whichever stack of a
## matching id happens to be smallest elsewhere in the satchel (which is what
## remove() would touch). Returns what was discarded, empty on a slot that
## already was.
func drop_slot(index: int) -> Dictionary:
	if index < 0 or index >= SLOT_COUNT:
		return {}
	var stack: Variant = _slots[index]
	if stack == null:
		return {}
	_slots[index] = null
	revision += 1
	return (stack as Dictionary).duplicate()


## Split a stack roughly in half into the first empty slot, the larger half
## staying put. Refuses (returns false, changes nothing) on an empty slot, a
## stack of 1 -- a tool or a single item, nothing to divide -- or a full
## satchel with nowhere to put the other half.
func split_slot(index: int) -> bool:
	if index < 0 or index >= SLOT_COUNT:
		return false
	var stack: Variant = _slots[index]
	if stack == null:
		return false
	var dict := stack as Dictionary
	var n: int = int(dict.get("n", 0))
	if n <= 1:
		return false

	var target := -1
	for i in SLOT_COUNT:
		if _slots[i] == null:
			target = i
			break
	if target == -1:
		return false

	var half := n / 2
	dict["n"] = n - half
	var moved := dict.duplicate()
	moved["n"] = half
	_slots[target] = moved
	revision += 1
	return true


## Write a slot directly, bypassing add()/remove()'s stacking and merge rules.
## Used only by save/load (R3.1) to rehydrate a satchel exactly as it was,
## position and all — the class comment above is explicit that slot POSITION
## is player-visible state, and routing a restore through `add()` would
## repack everything into whatever slots happen to be free first.
func set_slot(index: int, stack: Variant) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	_slots[index] = (stack as Dictionary).duplicate() if typeof(stack) == TYPE_DICTIONARY else null
	revision += 1


## Empty the satchel and hand back everything that was in it.
##
## This is what a death satchel is made from. CLAUDE.md: multiple death satchels
## persist, so the caller keeps the returned list — nothing here destroys it.
func drain() -> Array:
	var out: Array = []
	for i in SLOT_COUNT:
		if _slots[i] != null:
			out.append((_slots[i] as Dictionary).duplicate())
			_slots[i] = null
	if not out.is_empty():
		revision += 1
	return out
