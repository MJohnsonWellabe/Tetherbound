extends "res://tests/test_case.gd"

## PT-23. `scripts/build/camp.gd` was the sole caller of `autosave_slot()` in
## the whole codebase (`tests/test_save_format.gd` covers the save FORMAT
## itself, not who calls it) -- building a camp is a mid-session action, so a
## new player had no autosave at all for their entire first session.
## `GameState._tick_autosave()` is the fix: a plain real-time cadence, ticked
## every `_process()`, independent of anything the player has built or rested
## at. This file proves it by actually reaching disk through the real
## `GameState._tick_autosave()` -> `save_system.request_fallback()` path,
## explicitly joining before checking the file. This is the same "real
## object, real file over a mock" choice `tests/test_save_format.gd` and
## `tests/test_satchel.gd` already make.
##
## GameState is instantiated directly rather than through the `Game`
## autoload, and `_ready()` is never called -- same reasoning
## `tests/test_register_building.gd` gives: this only needs `save_system`,
## which is set by hand below instead. `_tick_autosave()` is called directly
## rather than through `_process()` itself, because the rest of `_process()`
## drives discovery/objective-text bookkeeping (`progression`, `quest_log`)
## this file has no reason to stand up.

const GAME_STATE := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SESSION := preload("res://scripts/net/session.gd")

const TEST_DIR := "user://test_saves_autosave_fallback/"

class PendingJoin:
	extends Node
	func is_host() -> bool:
		return false
	func snapshot_ready() -> bool:
		return false


class AdmittedClient:
	extends Node
	func is_host() -> bool:
		return false
	func snapshot_ready() -> bool:
		return true
	func _local_character_id() -> String:
		return "admitted-client"

var game: Node = null
var saver: RefCounted = null


func before_each() -> void:
	game = GAME_STATE.new()
	saver = SAVE_GAME.new(TEST_DIR)
	game.save_system = saver
	_wipe_test_dir()


func after_each() -> void:
	if saver != null:
		saver.finish_fallback()
	if game != null:
		game.free()
		game = null
	_wipe_test_dir()


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


## The headline case: nobody ever built a camp (no `camp.gd` in this scene at
## all, since `game` was never added to a tree), yet enough real time passing
## still produces a save on the autosave slot.
func test_no_camp_ever_built_still_autosaves_once_the_fallback_interval_passes() -> void:
	assert_false(saver.has_slot(game.autosave_slot()), "nothing written yet")
	game._tick_autosave(200.0) # comfortably past the fallback interval
	assert_true(saver.finish_fallback())
	assert_true(saver.has_slot(game.autosave_slot()),
		"no camp was ever built -- the fallback timer is the only thing that could have written this")


## The fallback is a cadence, not "save on the first frame" -- proves the
## elapsed time is actually being measured rather than firing unconditionally.
func test_the_fallback_does_not_fire_before_its_interval_elapses() -> void:
	game._tick_autosave(1.0)
	assert_false(saver.has_slot(game.autosave_slot()))


func test_pending_join_cannot_autosave_a_temporary_world_or_character() -> void:
	var pending := PendingJoin.new()
	game.session = pending
	game._tick_autosave(200.0)
	assert_true(saver.finish_fallback())
	assert_false(saver.has_slot(game.autosave_slot()), "no fallback save before host snapshot")
	assert_eq(game.get("_autosave_elapsed"), 0.0, "pending time does not queue a save")
	game.session = null
	pending.free()


func test_foreign_world_remains_unsaveable_after_client_teardown_until_new_game() -> void:
	var session := SESSION.new()
	game.add_child(session)
	game.session = session
	assert_true(session.prepare_client_join(), "the production pending-client seam revokes world ownership")
	assert_false(game.world_save_owned())
	# A real client teardown clears Session mode/snapshot back to its solo
	# defaults; ownership must remain revoked across that boundary.
	session.set("_mode", "client")
	session.call("_teardown")
	assert_false(game.world_save_owned())
	game.session = null
	session.free()
	game._tick_autosave(200.0)
	assert_true(saver.finish_fallback())
	assert_false(saver.has_slot(game.autosave_slot()),
		"a former host snapshot cannot become a local title-screen autosave")
	assert_false(game.save_game(game.autosave_slot()),
		"the synchronous event-save door also refuses a foreign world")
	assert_false(game.load_game(game.autosave_slot()),
		"a failed local load cannot reclaim world-save ownership")
	assert_false(game.world_save_owned())

	game.reset_for_new_game()
	game._tick_autosave(200.0)
	assert_true(saver.finish_fallback())
	assert_true(saver.has_slot(game.autosave_slot()),
		"an explicit New Game reclaims ownership for its new local world")


func test_admitted_client_keeps_character_only_fallback_after_world_ownership_is_revoked() -> void:
	var client := AdmittedClient.new()
	game.session = client
	game.local.character_id = "admitted-client"
	game.relinquish_world_save_ownership()
	game._tick_autosave(200.0)
	assert_true(saver.finish_fallback())
	assert_false(saver.has_slot(game.autosave_slot()),
		"an admitted client fallback does not write a world slot")
	assert_true(saver.characters().has("admitted-client"),
		"an admitted client still writes its portable character")
	game.session = null
	client.free()


## Ticking in small increments across several frames must sum the same as one
## big tick -- a naive "delta >= interval" per-call check (as opposed to an
## accumulator) would never fire on realistic ~16ms frame deltas.
func test_many_small_ticks_add_up_to_a_fallback_autosave() -> void:
	for i in range(1000):
		game._tick_autosave(0.2) # 1000 * 0.2s = 200s of simulated frames
	assert_true(saver.finish_fallback())
	assert_true(saver.has_slot(game.autosave_slot()))


## The day counter travels with the fallback save exactly as it does with the
## camp-rest save `tests/test_save_format.gd` already covers -- this is not a
## second, weaker save format, it is the same one.
func test_the_fallback_autosave_carries_the_real_game_state() -> void:
	game.day = 5
	game._tick_autosave(200.0)
	assert_true(saver.finish_fallback())
	var info: Dictionary = saver.slot_info(game.autosave_slot())
	assert_eq(int(info.get("day")), 5)
