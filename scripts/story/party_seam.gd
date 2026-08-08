extends RefCounted

## The one place the opening sequence touches the party.
##
## **This is a seam, not a party.** CLAUDE.md's first hard rule is five pals
## total and no storage beyond five, and the party that enforces it is being
## built in parallel: a `GameState` autoload holding the party, and a `nickname`
## on `scripts/pals/pal_instance.gd`. Neither exists in this tree yet.
##
## TODO(depends-on: GameState autoload + PalInstance.nickname). When they land,
## the fallbacks below should be deleted and `_state()` should stop being
## optional. Nothing else in the opening needs to change: every call site goes
## through this file.
##
## The interface assumed of `GameState`, and nothing more:
##
##   GameState.add_pal(instance) -> bool     # false when the party is full
##   GameState.party() -> Array              # the pals, at most five
##   GameState.party_is_full() -> bool
##
## Duck-typed rather than statically referenced, because a `preload` of an
## autoload that does not exist is a parse error and would take the whole
## opening down with it.
##
## The fallback is deliberately NOT a party. It is a single held instance and a
## count, which is exactly enough for the opening to play end to end and far too
## little to be mistaken for the real thing or to grow into storage.

## Mirrors the design rule so a caller can ask without reaching for CLAUDE.md.
## The real limit is GameState's to enforce; this is the number the seam refuses
## at while GameState is absent.
const PARTY_LIMIT := 5

## The opening's own record, used only while there is no GameState. Static so it
## survives the sequence director being freed, and cleared by `reset()` in tests.
static var _fallback: Array[RefCounted] = []


static func _state() -> Node:
	var loop := Engine.get_main_loop() as SceneTree
	if loop == null:
		return null
	return loop.root.get_node_or_null(^"/root/GameState")


static func has_game_state() -> bool:
	return _state() != null


## Give a caught or chosen pal its name and put it in the party.
##
## Returns false when the party is full. The opening can never see that — it
## adds two pals to an empty party — but the caller is told rather than assuming,
## because the sixth-pal release ceremony is real design (GAME_DESIGN.md §3) and
## a seam that silently drops a pal would hide the day it starts mattering.
static func add(instance: RefCounted, nickname: String = "") -> bool:
	if instance == null:
		return false
	set_nickname(instance, nickname)

	var state := _state()
	if state != null and state.has_method("add_pal"):
		return bool(state.call("add_pal", instance))

	if _fallback.size() >= PARTY_LIMIT:
		return false
	_fallback.append(instance)
	return true


## Name a pal. Writes `nickname` when the field exists and falls back to
## `display_name`, which is what the HUD and every prompt already read — so a
## named pal reads as named today and reads as named after the field lands,
## without the opening being rewritten in between.
static func set_nickname(instance: RefCounted, nickname: String) -> void:
	if instance == null or nickname == "":
		return
	# `nickname` is being added to pal_instance.gd in parallel. `in` is the check
	# that does not push an error for a property that is not there yet.
	if "nickname" in instance:
		instance.set("nickname", nickname)
	instance.display_name = nickname


## What the player is carrying. GameState's list when it exists, the opening's
## own otherwise.
static func party() -> Array:
	var state := _state()
	if state != null and state.has_method("party"):
		return state.call("party") as Array
	return _fallback.duplicate()


static func size() -> int:
	return party().size()


static func is_full() -> bool:
	var state := _state()
	if state != null and state.has_method("party_is_full"):
		return bool(state.call("party_is_full"))
	return size() >= PARTY_LIMIT


## Only for tests and for starting the opening over. Does nothing once GameState
## owns the party — clearing somebody else's party is not this file's business.
static func reset() -> void:
	_fallback.clear()
