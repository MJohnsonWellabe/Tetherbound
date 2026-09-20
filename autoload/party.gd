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
var _tournament_selection: Array[String] = []

## GAME_DESIGN.md §12: "Best Creature is meaningful progression, not a
## cosmetic badge." A standing title the player sets, distinct from `_active`
## ("who takes the field next") — a fainted or benched creature can still be
## the Best Creature. -1 means nobody is flagged, same "no selection" shape
## `_active` would use if slot 0 were not always a legal default.
var _best: int = -1


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
	var invalidates_tournament := _tournament_selection.has(str(gone.get("uid")))
	_creatures.remove_at(index)
	if _active >= _creatures.size():
		_active = maxi(0, _creatures.size() - 1)
	if _best == index:
		_best = -1
	elif _best > index:
		_best -= 1
	if invalidates_tournament:
		_tournament_selection.clear()
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
	if _best == from:
		_best = to
	elif from < _best and to >= _best:
		_best -= 1
	elif from > _best and to <= _best:
		_best += 1
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
	if bool(creature.get("fainted")) or bool(creature.get("resting")):
		return false
	_active = index
	revision += 1
	return true


## Gate A / owner: one-second previous/next party selection in exploration.
## Direction is -1 or +1; wraps and skips anything that cannot take the field.
func set_resting(index: int, value: bool, bed_index: int = -1) -> bool:
	var creature: RefCounted = at(index)
	if creature == null:
		return false
	creature.set("resting", value)
	creature.set("rest_bed_index", bed_index if value else -1)
	if value:
		creature.set("rested", false)
		if index == _active:
			cycle_active(1)
	revision += 1
	return true


func cycle_active(direction: int) -> bool:
	if _creatures.is_empty() or direction == 0:
		return false
	var step := -1 if direction < 0 else 1
	for offset in range(1, _creatures.size() + 1):
		var index := posmod(_active + step * offset, _creatures.size())
		var creature: RefCounted = at(index)
		if creature == null:
			continue
		if bool(creature.get("fainted")) or bool(creature.get("resting")):
			continue
		if index == _active:
			return false
		_active = index
		revision += 1
		return true
	return false


func best_index() -> int:
	return _best


func best() -> RefCounted:
	return at(_best)


## Toggle the Best Creature designation. Pressing it again on the same slot
## clears the title rather than re-confirming it — the same "second press
## undoes the first" shape reordering's pick-up-then-place already uses.
## Unlike `set_active`, a fainted creature is still allowed: this is a
## standing title earned by play, not "who takes the field next."
func set_best(index: int) -> bool:
	if index < 0 or index >= _creatures.size():
		return false
	_best = -1 if _best == index else index
	revision += 1
	return true


## Register exactly three current party members, in the player's chosen order.
## Indices are accepted at the UI boundary but immediately converted to stable
## creature ids, so party reordering never changes the registered team.
func set_tournament_selection(indices: Array) -> bool:
	if indices.size() != 3:
		return false
	var selected: Array[String] = []
	for raw: Variant in indices:
		if typeof(raw) != TYPE_INT:
			return false
		var index := int(raw)
		var creature := at(index)
		if creature == null:
			return false
		var id := str(creature.get("uid"))
		if id.is_empty() or selected.has(id) or _members_with_uid(id).size() != 1:
			return false
		selected.append(id)
	_tournament_selection = selected
	revision += 1
	return true


func tournament_selection_ids() -> Array[String]:
	return _tournament_selection.duplicate()


## Ordered live instances, or an empty array when any selected identity is no
## longer uniquely owned. Never fills a hole with another party member.
func tournament_selection() -> Array[RefCounted]:
	var out: Array[RefCounted] = []
	if _tournament_selection.size() != 3:
		return out
	for id: String in _tournament_selection:
		var matches := _members_with_uid(id)
		if matches.size() != 1:
			return []
		out.append(matches[0] as RefCounted)
	return out


## Save/load seam. A malformed, partial, missing or ambiguous selection becomes
## explicitly unregistered; it is never repaired by choosing substitutes.
func restore_tournament_selection(ids: Variant) -> bool:
	_tournament_selection.clear()
	if typeof(ids) != TYPE_ARRAY or (ids as Array).size() != 3:
		return false
	var restored: Array[String] = []
	for raw: Variant in ids as Array:
		if typeof(raw) != TYPE_STRING:
			return false
		var id := raw as String
		if id.is_empty() or restored.has(id) or _members_with_uid(id).size() != 1:
			return false
		restored.append(id)
	_tournament_selection = restored
	revision += 1
	return true


func clear_tournament_selection() -> void:
	if _tournament_selection.is_empty():
		return
	_tournament_selection.clear()
	revision += 1


func _members_with_uid(id: String) -> Array:
	var matches: Array = []
	for creature: RefCounted in _creatures:
		if str(creature.get("uid")) == id:
			matches.append(creature)
	return matches


## Empty the party. Used only by save/load (R3.1) to rehydrate from a slot
## without leaving whichever creatures were already in it mixed in with the loaded
## ones.
func clear() -> void:
	_creatures.clear()
	_active = 0
	_best = -1
	_tournament_selection.clear()
	revision += 1


## Every creature down means there is no fight to be had.
func all_fainted() -> bool:
	if _creatures.is_empty():
		return false
	for creature in _creatures:
		if not bool(creature.get("fainted")):
			return false
	return true
