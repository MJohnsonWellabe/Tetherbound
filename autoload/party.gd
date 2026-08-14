extends RefCounted

## The party, and the five-creature cap.
##
## CLAUDE.md, twice over: "Player can own only five creatures total" and "Never
## implement creature storage beyond five". The cap is enforced in `add()` and
## NOWHERE ELSE, and there is no code path in this file that can produce a party
## of six. `members()` hands out a shallow copy of the list for exactly that
## reason — anything that wants a creature in the party goes through `add()`.
##
## There is no box, no bank, no reserve and no overflow list. That absence is
## the feature. If a future milestone needs somewhere to put a sixth creature, the
## answer is the release ceremony (M5), not a container.
##
## `add()` returns false rather than throwing when full. The sixth capture is a
## decision the player makes at a ceremony, not an error case, and this class
## deliberately does not know what that ceremony looks like.

const MAX_CREATURES := 5

## Polled by the menu instead of pushed on a signal. See autoload/inventory.gd
## for why.
var revision: int = 0

var _creatures: Array = []
var _active: int = 0


func size() -> int:
	return _creatures.size()


func is_full() -> bool:
	return _creatures.size() >= MAX_CREATURES


func free_slots() -> int:
	return MAX_CREATURES - _creatures.size()


## A shallow copy. The creature instances inside are the live ones — combat has to be
## able to damage them — but the LIST cannot be appended to from outside.
func members() -> Array:
	return _creatures.duplicate()


func at(index: int) -> RefCounted:
	if index < 0 or index >= _creatures.size():
		return null
	return _creatures[index]


## The only way a creature enters the party.
func add(creature: RefCounted) -> bool:
	if creature == null:
		return false
	if is_full():
		return false
	if _creatures.has(creature):
		return false
	_creatures.append(creature)
	revision += 1
	return true


## Remove a creature by slot. Used by the release ceremony (M5) and by nothing else
## yet; returns the instance so the caller can show it one last time.
func remove_at(index: int) -> RefCounted:
	if index < 0 or index >= _creatures.size():
		return null
	var gone: RefCounted = _creatures[index]
	_creatures.remove_at(index)
	if _active >= _creatures.size():
		_active = maxi(0, _creatures.size() - 1)
	revision += 1
	return gone


## Reorder. The party's order is the order the player sees and the order a
## future deploy wheel will offer, so it is state worth letting them set.
func move(from: int, to: int) -> void:
	if from == to:
		return
	if from < 0 or to < 0 or from >= _creatures.size() or to >= _creatures.size():
		return
	var moving: RefCounted = _creatures[from]
	_creatures.remove_at(from)
	_creatures.insert(to, moving)
	# The active creature is identified by slot, so reordering has to carry it along
	# or the player would swap two creatures and silently deploy the other one.
	if _active == from:
		_active = to
	elif from < _active and to >= _active:
		_active -= 1
	elif from > _active and to <= _active:
		_active += 1
	revision += 1


func active_index() -> int:
	return _active


func active() -> RefCounted:
	return at(_active)


## Choose who takes the field. A fainted creature refuses, which is why this returns
## a bool rather than assigning blindly.
func set_active(index: int) -> bool:
	var creature: RefCounted = at(index)
	if creature == null:
		return false
	if bool(creature.get("fainted")):
		return false
	_active = index
	revision += 1
	return true


## Empty the party. Used only by save/load (R3.1) to rehydrate from a slot
## without leaving whichever creatures were already in it mixed in with the loaded
## ones.
func clear() -> void:
	_creatures.clear()
	_active = 0
	revision += 1


## Every creature down means there is no fight to be had.
func all_fainted() -> bool:
	if _creatures.is_empty():
		return false
	for creature in _creatures:
		if not bool(creature.get("fainted")):
			return false
	return true
