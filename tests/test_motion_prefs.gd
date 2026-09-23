extends "res://tests/test_case.gd"

## UX §8 reduced motion, and the boot seam that applies saved preferences.
##
## The existing volume test round-trips through the settings object IN MEMORY
## only, which is how a real bug survived: volumes were written to
## `user://settings.json` but `load_volumes` had no caller at launch, so a
## player's Music level reset every time. These tests go through an actual
## file, the way a relaunch does.

const MOTION := preload("res://scripts/ui/motion_prefs.gd")
const AUDIO := preload("res://scripts/audio/audio_manager.gd")
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")
const TEST_PATH := "user://__test_motion_prefs.json"


func after_each() -> void:
	MOTION.set_reduced_motion(false)
	AUDIO.set_bus_percent("Music", 1.0)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_reduced_motion_is_off_by_default_and_scales_impulses_to_zero() -> void:
	MOTION.set_reduced_motion(false)
	assert_false(MOTION.reduced_motion(), "reduced motion must default off")
	assert_almost_eq(MOTION.impulse_scale(), 1.0, 0.0001)
	MOTION.set_reduced_motion(true)
	assert_almost_eq(MOTION.impulse_scale(), 0.0, 0.0001,
		"with reduced motion on, visual impulses must scale to nothing")


func test_reduced_motion_survives_a_relaunch_through_the_real_file() -> void:
	var first: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	MOTION.set_reduced_motion(true)
	MOTION.store_to(first)
	assert_true(bool(first.call("save")), "the settings file could not be written")

	# A relaunch: fresh process state, fresh object, same file.
	MOTION.set_reduced_motion(false)
	var second: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	assert_eq(int(second.call("load_overrides")), KEY_BINDINGS.LOAD_OK)
	MOTION.load_from(second)
	assert_true(MOTION.reduced_motion(), "reduced motion did not come back after a relaunch")


func test_volumes_survive_a_relaunch_through_the_real_file() -> void:
	# The bug this slice fixes. The in-memory test elsewhere could not catch it.
	var first: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	AUDIO.set_bus_percent("Music", 0.3)
	AUDIO.store_volumes(first)
	assert_true(bool(first.call("save")), "the settings file could not be written")

	AUDIO.set_bus_percent("Music", 1.0)
	var second: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	assert_eq(int(second.call("load_overrides")), KEY_BINDINGS.LOAD_OK)
	AUDIO.load_volumes(second)
	assert_almost_eq(AUDIO.bus_percent("Music"), 0.3, 0.001,
		"a saved Music volume did not come back after a relaunch")


func test_the_menu_applies_saved_preferences_at_launch() -> void:
	# The seam itself: the menu's boot load must hand the file's audio and
	# accessibility sections to their owners, not just read the controls.
	var source := FileAccess.get_file_as_string("res://scripts/ui/game_menu.gd")
	var start := source.find("func _load_bindings()")
	assert_true(start >= 0, "game_menu.gd no longer has _load_bindings")
	var body := source.substr(start, 1600)
	assert_true(body.contains("AUDIO_MANAGER.load_volumes(bindings)"),
		"the menu loads settings at launch but never applies the saved volumes")
	assert_true(body.contains("MOTION_PREFS.load_from(bindings)"),
		"the menu loads settings at launch but never applies reduced motion")
