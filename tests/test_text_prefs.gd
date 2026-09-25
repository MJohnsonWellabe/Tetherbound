extends "res://tests/test_case.gd"

## UX §8: dialogue text size and background opacity, saved through the real
## settings file. The panel itself is driven by
## `smoke_dialogue_text_prefs.gd`, which needs a scene tree.

const TEXT := preload("res://scripts/ui/text_prefs.gd")
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")
const TEST_PATH := "user://__test_text_prefs.json"


func after_each() -> void:
	TEXT.reset()
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_sizes_snap_to_the_offered_steps_and_cycle() -> void:
	assert_eq(TEXT.text_percent(), 100)
	TEXT.set_text_percent(131)
	assert_eq(TEXT.text_percent(), 125, "a hand-edited value snaps to a laid-out size")
	assert_eq(TEXT.next_text_percent(), 150)
	TEXT.set_text_percent(150)
	assert_eq(TEXT.next_text_percent(), 100, "the toggle wraps")


func test_background_is_clamped_so_text_never_loses_its_plate() -> void:
	TEXT.set_background_percent(0)
	assert_eq(TEXT.background_percent(), TEXT.MIN_BACKGROUND_PERCENT)
	TEXT.set_background_percent(150)
	assert_eq(TEXT.background_percent(), 100)


func test_settings_survive_a_relaunch_through_the_real_file() -> void:
	var first: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	TEXT.set_text_percent(150)
	TEXT.set_background_percent(60)
	TEXT.store_to(first)
	assert_true(bool(first.call("save")))
	TEXT.reset()
	var second: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	assert_eq(int(second.call("load_overrides")), KEY_BINDINGS.LOAD_OK)
	TEXT.load_from(second)
	assert_eq(TEXT.text_percent(), 150)
	assert_eq(TEXT.background_percent(), 60)


func test_the_menu_applies_saved_dialogue_settings_at_launch() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/game_menu.gd")
	var start := source.find("func _load_bindings()")
	assert_true(source.substr(start, 1900).contains("TEXT_PREFS.load_from(bindings)"))
