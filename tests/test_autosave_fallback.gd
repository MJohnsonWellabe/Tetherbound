extends "res://tests/test_case.gd"

## PT-23. `scripts/build/camp.gd` was the sole caller of `autosave_slot()` in
## the whole codebase (`tests/test_save_format.gd` covers the save FORMAT
## itself, not who calls it) -- building a camp is a mid-session action, so a
## new player had no autosave at all for their entire first session.
## `GameState._tick_autosave()` is the fix: a plain real-time cadence, ticked
## every `_process()`, independent of anything the player has built or rested
## at. This file proves it by actually reaching disk through the real
## `GameState.save_game()` -> `save_system.save()` path, the same "real
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

const TEST_DIR := "user://test_saves_autosave_fallback/"

var game: Node = null
var saver: RefCounted = null


func before_each() -> void:
	game = GAME_STATE.new()
	saver = SAVE_GAME.new(TEST_DIR)
	game.save_system = saver
	_wipe_test_dir()


func after_each() -> void:
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
	assert_true(saver.has_slot(game.autosave_slot()),
		"no camp was ever built -- the fallback timer is the only thing that could have written this")


## The fallback is a cadence, not "save on the first frame" -- proves the
## elapsed time is actually being measured rather than firing unconditionally.
func test_the_fallback_does_not_fire_before_its_interval_elapses() -> void:
	game._tick_autosave(1.0)
	assert_false(saver.has_slot(game.autosave_slot()))


## Ticking in small increments across several frames must sum the same as one
## big tick -- a naive "delta >= interval" per-call check (as opposed to an
## accumulator) would never fire on realistic ~16ms frame deltas.
func test_many_small_ticks_add_up_to_a_fallback_autosave() -> void:
	for i in range(1000):
		game._tick_autosave(0.2) # 1000 * 0.2s = 200s of simulated frames
	assert_true(saver.has_slot(game.autosave_slot()))


## The day counter travels with the fallback save exactly as it does with the
## camp-rest save `tests/test_save_format.gd` already covers -- this is not a
## second, weaker save format, it is the same one.
func test_the_fallback_autosave_carries_the_real_game_state() -> void:
	game.day = 5
	game._tick_autosave(200.0)
	var info: Dictionary = saver.slot_info(game.autosave_slot())
	assert_eq(int(info.get("day")), 5)
