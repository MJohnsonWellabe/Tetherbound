extends "res://tests/test_case.gd"

## UX §8: look sensitivity and inversion per axis, applied by camera_rig.gd on
## top of its tuned numbers and saved through the real settings file.

const LOOK := preload("res://scripts/ui/look_prefs.gd")
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")
const MOTION := preload("res://scripts/ui/motion_prefs.gd")
const TEST_PATH := "user://__test_look_prefs.json"


func after_each() -> void:
	LOOK.reset()
	MOTION.set_reduced_motion(false)
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_defaults_leave_the_tuned_camera_exactly_as_it_was() -> void:
	LOOK.reset()
	var change := LOOK.apply(Vector2(3.0, -2.0))
	assert_almost_eq(change.x, 3.0)
	assert_almost_eq(change.y, -2.0)


func test_sensitivity_scales_both_axes_and_is_clamped() -> void:
	LOOK.set_sensitivity_percent(150)
	var change := LOOK.apply(Vector2(2.0, 4.0))
	assert_almost_eq(change.x, 3.0)
	assert_almost_eq(change.y, 6.0)
	LOOK.set_sensitivity_percent(1000, 25, 200)
	assert_eq(LOOK.sensitivity_percent(), 200)
	LOOK.set_sensitivity_percent(0, 25, 200)
	assert_eq(LOOK.sensitivity_percent(), 25, "the camera can be slowed, never frozen")


func test_each_axis_inverts_on_its_own() -> void:
	LOOK.set_invert_x(true)
	var change := LOOK.apply(Vector2(1.0, 1.0))
	assert_almost_eq(change.x, -1.0)
	assert_almost_eq(change.y, 1.0, 0.0001, "horizontal inversion must not touch vertical")
	LOOK.set_invert_x(false)
	LOOK.set_invert_y(true)
	change = LOOK.apply(Vector2(1.0, 1.0))
	assert_almost_eq(change.x, 1.0)
	assert_almost_eq(change.y, -1.0)


func test_a_config_that_ships_inverted_can_still_be_uninverted() -> void:
	# movement.json's `invert_y` stays the designer's default; the player's
	# choice flips it again rather than being ignored.
	assert_almost_eq(LOOK.apply(Vector2(0.0, 1.0), true).y, -1.0)
	LOOK.set_invert_y(true)
	assert_almost_eq(LOOK.apply(Vector2(0.0, 1.0), true).y, 1.0)


func test_look_settings_survive_a_relaunch_and_keep_reduced_motion() -> void:
	var first: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	MOTION.set_reduced_motion(true)
	MOTION.store_to(first)
	LOOK.set_sensitivity_percent(70)
	LOOK.set_invert_x(true)
	LOOK.store_to(first)
	assert_true(bool(first.call("save")), "the settings file could not be written")

	LOOK.reset()
	MOTION.set_reduced_motion(false)
	var second: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	assert_eq(int(second.call("load_overrides")), KEY_BINDINGS.LOAD_OK)
	LOOK.load_from(second)
	MOTION.load_from(second)
	assert_eq(LOOK.sensitivity_percent(), 70)
	assert_true(LOOK.invert_x())
	assert_false(LOOK.invert_y())
	assert_true(MOTION.reduced_motion(), "the shared accessibility section kept reduced motion")


func test_the_menu_applies_saved_look_settings_at_launch() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/game_menu.gd")
	var start := source.find("func _load_bindings()")
	assert_true(start >= 0, "game_menu.gd no longer has _load_bindings")
	assert_true(source.substr(start, 1800).contains("LOOK_PREFS.load_from(bindings)"),
		"the menu loads settings at launch but never applies the saved look settings")


func test_the_camera_rig_reads_the_players_look_settings() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/player/camera_rig.gd")
	var start := source.find("func _apply_look(")
	assert_true(start >= 0)
	assert_true(source.substr(start, 2400).contains("LOOK_PREFS.apply("),
		"the rig's look tick must apply the player's sensitivity and inversion")
