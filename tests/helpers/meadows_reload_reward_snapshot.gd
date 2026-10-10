extends RefCounted

## Compare the production handoff's detached reward carriers, not retained
## live memory. No files are written and no handoff is exported here.
const HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")
const REDESIGN := preload("res://scripts/data/redesign_state.gd")
const FIELDS := ["party", "inventory", "redesign_character"]

static func capture(game: Node) -> Dictionary:
	var observer := HANDOFF.new(null, game, "user://meadows_reload_reward_observer")
	return from_state(observer._state())

static func from_state(state: Dictionary) -> Dictionary:
	if not state.get("party") is Array or not state.get("inventory") is Dictionary \
			or not state.get("redesign_character") is Dictionary:
		return {}
	var out := {}
	for field: String in FIELDS:
		out[field] = state[field].duplicate(true)
	return out

static func preserved(before: Dictionary, after: Dictionary) -> bool:
	return not before.is_empty() and from_state(before) == before \
		and from_state(after) == after and before == after

static func clear_live_records(game: Node) -> bool:
	var personal := game.get("local") as RefCounted
	if personal == null:
		return false
	personal.set("redesign_character", REDESIGN.defaults("character"))
	return true
