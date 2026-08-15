extends RefCounted

## SB9: the smallest progression-state system that survives the chapter.
##
## Spec §15 — objective flags, completion flags, trainer-defeated state,
## bridge-unlocked, dungeon-cleared, captive-rescued, Sigils, stronghold-
## unlocked, Warden-defeated, post-Warden world state — is all one flat flag
## store. Objectives themselves are DATA (`data/progression/`, once something
## needs to enumerate them); this class only remembers which ids have fired.
##
## Deliberately NOT a quest engine — spec §19 bans one and §15 says so twice.
## No branching, no timers, no prerequisite chains, no scripting language. A
## future need for any of those is a new system to flag, not a growth of
## this one.
##
## Same shape as `autoload/map_state.gd`: pure logic, no `Node`, no
## transform, testable headlessly (`tests/test_progression_state.gd`).
## `revision` is the same polling idiom `party.gd`/`inventory.gd`/
## `map_state.gd` already use, so a quest-log UI (SB11) can redraw only when
## something actually changed instead of listening for a signal per flag.

## Bumped whenever a flag's set-state actually changes. Unchanged by a
## `set_flag()` call that redundantly sets an already-set flag or clears an
## already-unset one, so a poller does not redraw for nothing.
var revision: int = 0

## flag id -> true. Presence means set; absence means unset. There is no
## stored "false" — clearing a flag erases the key rather than writing false,
## so `all_set()` and the save payload only ever list what actually fired.
var _flags: Dictionary = {}


## True once `set_flag(id)` has been called and not since cleared.
func has(id: String) -> bool:
	return _flags.has(id)


## Same query as `has()`, spelled for objective/story call sites where
## "completed" reads better than "has" — the spec's own vocabulary splits
## "objective flags" from "completion flags", but both live in one store.
func completed(id: String) -> bool:
	return has(id)


## Sets or clears `id`. Defaults to setting (`set_flag("bridge_unlocked")`
## reads as the common case); pass `value = false` to clear one back out.
func set_flag(id: String, value: bool = true) -> void:
	if value:
		if _flags.has(id):
			return
		_flags[id] = true
	else:
		if not _flags.has(id):
			return
		_flags.erase(id)
	revision += 1


## Every currently-set flag id — for SB11's quest log to check off against
## `data/progression/`'s objective list.
func all_set() -> Array:
	return _flags.keys()


func save_data() -> Dictionary:
	return {"flags": _flags.keys()}


## Tolerant of a missing or malformed `flags` key — `load_data({})` is a
## working fresh state, the same contract `map_state.gd`'s `load_data()`
## already gives save_game.gd.
func load_data(data: Dictionary) -> void:
	_flags.clear()
	var raw: Variant = data.get("flags", [])
	if typeof(raw) == TYPE_ARRAY:
		for id: Variant in (raw as Array):
			if typeof(id) == TYPE_STRING and not (id as String).is_empty():
				_flags[id] = true
	revision += 1
