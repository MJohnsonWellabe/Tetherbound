extends "res://tests/test_case.gd"

## X05 save-authority work order (finale-lane finding, coordinator grant):
## 1. A former client (session torn down, so is_host() reads true) that still
##    holds a host's retained world must not write the world slot on a realm
##    transition: the realm autosaves also require world_save_owned().
## 2. Saving a local with no character id must not mint a new identity over a
##    slot whose locator already names a character.

const GAME_STATE := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const FORMAT_TEST := preload("res://tests/test_save_format.gd")


class SaveSpy:
	extends RefCounted
	var world_saves := 0

	func save(_game: Object, _slot: int, _write_split: bool = true) -> bool:
		world_saves += 1
		return true


func _format() -> Object:
	var fmt: Object = FORMAT_TEST.new()
	fmt.call("before_each")
	return fmt


func test_former_client_realm_restore_does_not_write_the_world() -> void:
	var game: Node = GAME_STATE.new()
	var spy := SaveSpy.new()
	game.set("save_system", spy)
	assert_true(bool(game.call("is_host")), "no session: the process reads as host")
	game.call("relinquish_world_save_ownership")
	var snapshot: Dictionary = game.call("_realm_transition_snapshot", str(game.get("current_realm")))
	assert_true(bool(game.call("_restore_realm_transition_state", snapshot)))
	assert_eq(spy.world_saves, 0, "a process that gave up world ownership writes no world slot")
	game.free()


func test_owning_host_realm_restore_still_writes_the_world() -> void:
	var game: Node = GAME_STATE.new()
	var spy := SaveSpy.new()
	game.set("save_system", spy)
	var snapshot: Dictionary = game.call("_realm_transition_snapshot", str(game.get("current_realm")))
	assert_true(bool(game.call("_restore_realm_transition_state", snapshot)))
	assert_eq(spy.world_saves, 1, "the owning host keeps its transition autosave")
	game.free()


func test_unidentified_local_cannot_mint_over_a_slot_that_names_a_character() -> void:
	var fmt := _format()
	var saver: RefCounted = fmt.get("saver")
	var first: RefCounted = fmt.call("_game", false)
	assert_true(bool(saver.save(first, 1)), "a fresh slot mints the first character")
	var owner := str(first.local.character_id)
	assert_false(owner.is_empty())
	assert_eq(saver.slot_locator_character(1), owner)

	var stranger: RefCounted = fmt.call("_game", false)
	assert_false(bool(saver.save(stranger, 1)), "an unidentified local is refused, not minted over it")
	assert_eq(str(stranger.local.character_id), "", "no identity was invented for the stranger")
	assert_eq(saver.slot_locator_character(1), owner, "the slot still points at its real character")
	fmt.call("after_each")


func test_unidentified_local_on_an_empty_slot_mints_explicitly() -> void:
	var fmt := _format()
	var saver: RefCounted = fmt.get("saver")
	assert_eq(saver.slot_locator_character(2), "")
	var game: RefCounted = fmt.call("_game", false)
	assert_true(bool(saver.save(game, 2)))
	assert_false(str(game.local.character_id).is_empty(), "a new game still gets its identity")
	assert_eq(saver.slot_locator_character(2), str(game.local.character_id))
	fmt.call("after_each")
