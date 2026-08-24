extends "res://tests/test_case.gd"

## OP23-13 (owner playtest 2026-08-23): "Auto-run is needed." A toggle
## persisted the same way `free_build`/`debug_teleport` are (see
## `tests/test_free_build.gd`'s own settings-file coverage, which this
## mirrors for the parts that matter here), but this is a real feature, not
## D16 scaffolding, so it defaults off and needs no removal note.
##
## GameState is instantiated directly rather than reached through the `Game`
## autoload, same reasoning as test_free_build.gd: the runner shares one
## process across every test file, and flipping the live singleton would
## leak into whatever runs next.

const GAME_STATE := preload("res://autoload/game_state.gd")
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")

var game: Node = null
var path: String = ""

static var _serial: int = 0


func before_each() -> void:
	_serial += 1
	path = "user://test_auto_run_%d.json" % _serial
	game = GAME_STATE.new()


func after_each() -> void:
	if game != null:
		game.free()
		game = null
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_auto_run_is_off_by_default() -> void:
	assert_false(bool(game.auto_run), "auto-run defaults to ON")


func test_setting_it_flips_the_field() -> void:
	game.set_auto_run(true)
	assert_true(bool(game.auto_run))
	game.set_auto_run(false)
	assert_false(bool(game.auto_run))


func test_setting_it_with_nowhere_to_write_still_holds_for_the_session() -> void:
	# No menu means no settings file to reach. The toggle still flips, and
	# set_auto_run says it did not save so the screen can tell the owner --
	# same contract test_free_build.gd pins for set_free_build.
	assert_false(bool(game.set_auto_run(true)), "a state with no menu reported a successful save")
	assert_true(bool(game.auto_run), "the toggle did not take effect at all")


func test_the_choice_survives_a_relaunch() -> void:
	var prefs: RefCounted = KEY_BINDINGS.new(path)
	prefs.gameplay[GAME_STATE.PREF_AUTO_RUN] = true
	assert_true(prefs.save())

	var reloaded: RefCounted = KEY_BINDINGS.new(path)
	assert_eq(reloaded.load_overrides(), KEY_BINDINGS.LOAD_OK)
	assert_true(bool(reloaded.gameplay.get(GAME_STATE.PREF_AUTO_RUN, false)), "the toggle did not survive")
	reloaded.reset_all()


func test_a_rebind_does_not_wipe_the_toggle() -> void:
	var prefs: RefCounted = KEY_BINDINGS.new(path)
	prefs.gameplay[GAME_STATE.PREF_AUTO_RUN] = true
	prefs.save()

	var later: RefCounted = KEY_BINDINGS.new(path)
	later.load_overrides()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_L
	later.set_binding("sprint", "keyboard", key)
	later.save()
	later.reset_all()

	var reloaded: RefCounted = KEY_BINDINGS.new(path)
	reloaded.load_overrides()
	assert_true(bool(reloaded.gameplay.get(GAME_STATE.PREF_AUTO_RUN, false)), "rebinding a key turned the toggle off")
	reloaded.reset_all()


func test_no_settings_file_at_all_means_off() -> void:
	var prefs: RefCounted = KEY_BINDINGS.new(path)
	assert_eq(prefs.load_overrides(), KEY_BINDINGS.LOAD_MISSING)
	assert_false(bool(prefs.gameplay.get(GAME_STATE.PREF_AUTO_RUN, false)))


# --- input map ---------------------------------------------------------------


func test_auto_run_is_bound_to_a_spare_button_not_a_hold_chord() -> void:
	# OP23-13 asked explicitly for a toggle on a spare input, not a hold-chord.
	# `sprint` is the existing hold action -- auto_run must be a distinct
	# action so player_controller.gd can poll it with `is_action_just_pressed`
	# (a single press) rather than `is_action_pressed` (a hold).
	assert_true(InputMap.has_action("auto_run"), "no auto_run input action is registered")
	if not InputMap.has_action("auto_run"):
		return
	var auto_run_events := InputMap.action_get_events("auto_run")
	var sprint_events := InputMap.action_get_events("sprint")
	var auto_run_buttons: Array[int] = []
	for event in auto_run_events:
		if event is InputEventJoypadButton:
			auto_run_buttons.append((event as InputEventJoypadButton).button_index)
	var sprint_buttons: Array[int] = []
	for event in sprint_events:
		if event is InputEventJoypadButton:
			sprint_buttons.append((event as InputEventJoypadButton).button_index)
	assert_true(auto_run_buttons.size() > 0, "auto_run has no joypad binding at all")
	for button in auto_run_buttons:
		assert_true(not sprint_buttons.has(button),
			"auto_run shares joypad button %d with sprint; a toggle needs its own input" % button)


func test_player_controller_polls_auto_run_as_a_single_press() -> void:
	var file := FileAccess.open("res://scripts/player/player_controller.gd", FileAccess.READ)
	assert_true(file != null, "player_controller.gd is missing")
	if file == null:
		return
	var source := file.get_as_text()
	assert_true(source.contains("is_action_just_pressed(\"auto_run\")"),
		"player_controller.gd does not poll auto_run with is_action_just_pressed; a "
		+ "toggle must react to a single press, not read as a hold")
	assert_false(source.contains("is_action_pressed(\"auto_run\")"),
		"player_controller.gd polls auto_run as a hold (is_action_pressed); OP23-13 "
		+ "asked for a toggle, not a hold-chord")
