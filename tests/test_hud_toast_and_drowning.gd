extends "res://tests/test_case.gd"

## X03-WO6 (toast hold in game time, config-driven) and X03-WO4 (drowning cue)
## on `scripts/ui/playground_hud.gd`. Tree-less, like `test_hud_widgets.gd`:
## the HUD script is instanced without its scene, and only the fields each
## function touches are supplied.

const PLAYGROUND_HUD := preload("res://scripts/ui/playground_hud.gd")
const SWIM_STATE := preload("res://scripts/player/swim_state.gd")
const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")
const HUD_CONFIG := "res://data/config/hud.json"


class FakeSwimState extends RefCounted:
	var mode: int = 0
	var drowning: bool = false


func _hud_with_message() -> Array:
	var hud: CanvasLayer = PLAYGROUND_HUD.new()
	var label := Label.new()
	label.visible = false
	hud._hotbar_message = label
	return [hud, label]


func _tick(hud: CanvasLayer, delta: float, frames: int) -> void:
	for _i in frames:
		hud._advance_hud_clock(delta)
		hud._expire_hotbar_message()


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HUD_CONFIG))
	assert_true(parsed is Dictionary, "hud.json must parse to a Dictionary")
	return parsed if parsed is Dictionary else {}


# --- X03-WO6: toast hold ----------------------------------------------------------


func test_message_holds_until_game_time_reaches_the_hold() -> void:
	var pair := _hud_with_message()
	var hud: CanvasLayer = pair[0]
	var label: Label = pair[1]
	hud._hotbar_message_seconds = 2.0
	hud._show_hotbar_message("Needs a saddle")
	assert_true(label.visible)
	_tick(hud, 0.1, 19)  # 1.9 s of process deltas
	assert_true(label.visible, "message must still be up after 1.9 s of a 2.0 s hold")
	_tick(hud, 0.1, 1)   # 2.0 s
	assert_false(label.visible, "message must hide once game time reaches the hold")
	assert_almost_eq(hud._hotbar_message_until, 0.0)
	label.free()
	hud.free()


func test_hold_ignores_wall_clock_and_bad_deltas() -> void:
	var pair := _hud_with_message()
	var hud: CanvasLayer = pair[0]
	var label: Label = pair[1]
	hud._show_hotbar_message("x")
	# No deltas at all: however much wall time passes, the message stays.
	OS.delay_msec(30)
	for _i in 5:
		hud._expire_hotbar_message()
	assert_true(label.visible)
	_tick(hud, NAN, 3)
	_tick(hud, -5.0, 3)
	_tick(hud, INF, 3)
	assert_true(label.visible, "non-finite/negative deltas must not advance the hold")
	label.free()
	hud.free()


func test_fixed_fps_frames_hold_for_the_configured_time() -> void:
	# A capture at a fixed 30 fps: 1/30 s per frame whatever each frame costs.
	var pair := _hud_with_message()
	var hud: CanvasLayer = pair[0]
	var label: Label = pair[1]
	hud._apply_hud_config(_config())
	var hold: float = hud._hotbar_message_seconds
	hud._show_hotbar_message("x")
	var frames_below := int(floor(hold * 30.0)) - 1
	_tick(hud, 1.0 / 30.0, frames_below)
	assert_true(label.visible, "visible after %d frames (< %.2f s)" % [frames_below, hold])
	_tick(hud, 1.0 / 30.0, 3)
	assert_false(label.visible, "hidden once >= %.2f s of frames have run" % hold)
	label.free()
	hud.free()


func test_config_value_is_honoured() -> void:
	var config := _config()
	var expected := float(config.toasts.hotbar_message_seconds)
	var hud: CanvasLayer = PLAYGROUND_HUD.new()
	assert_almost_eq(hud._hotbar_message_seconds, PLAYGROUND_HUD.HOTBAR_MESSAGE_SECONDS,
		0.0001, "an unconfigured HUD uses the 2.2 s fallback")
	hud._apply_hud_config(config)
	assert_almost_eq(hud._hotbar_message_seconds, expected)
	assert_almost_eq(hud._region_banner_seconds, float(config.toasts.region_banner_seconds))
	# A different configured value really drives the hold.
	hud._apply_hud_config({"toasts": {"hotbar_message_seconds": 5.0}})
	assert_almost_eq(hud._hotbar_message_seconds, 5.0)
	var label := Label.new()
	hud._hotbar_message = label
	hud._show_hotbar_message("x")
	_tick(hud, 0.5, 9)
	assert_true(label.visible, "4.5 s into a configured 5.0 s hold")
	_tick(hud, 0.5, 1)
	assert_false(label.visible)
	label.free()
	hud.free()


func test_invalid_config_falls_back() -> void:
	assert_almost_eq(PLAYGROUND_HUD.hud_config_number({}, "toasts", "hotbar_message_seconds", 2.2), 2.2)
	assert_almost_eq(PLAYGROUND_HUD.hud_config_number({"toasts": {"hotbar_message_seconds": -1}},
		"toasts", "hotbar_message_seconds", 2.2), 2.2)
	assert_almost_eq(PLAYGROUND_HUD.hud_config_number({"toasts": {"hotbar_message_seconds": "3"}},
		"toasts", "hotbar_message_seconds", 2.2), 2.2)
	assert_almost_eq(PLAYGROUND_HUD.hud_config_number({"toasts": []},
		"toasts", "hotbar_message_seconds", 2.2), 2.2)
	assert_almost_eq(PLAYGROUND_HUD.hud_config_number({"toasts": {"hotbar_message_seconds": 3}},
		"toasts", "hotbar_message_seconds", 2.2), 3.0)


# --- X03-WO4: drowning cue ----------------------------------------------------------


func _hud_with_cue() -> CanvasLayer:
	var hud: CanvasLayer = PLAYGROUND_HUD.new()
	hud._apply_hud_config(_config())
	hud._health_bar_cluster = Control.new()
	hud._build_drowning_cue()
	return hud


func _free_cue_hud(hud: CanvasLayer) -> void:
	hud._health_bar_cluster.free()
	hud.free()


func test_cue_shows_only_while_a_human_swimmer_is_drowning() -> void:
	var hud := _hud_with_cue()
	var state := FakeSwimState.new()
	assert_false(hud._drowning_cue.visible, "hidden when built")
	hud._update_drowning_cue(state, 0.016)
	assert_false(hud._drowning_cue.visible, "on land, not drowning")
	state.mode = SWIM_STATE.Mode.HUMAN
	hud._update_drowning_cue(state, 0.016)
	assert_false(hud._drowning_cue.visible, "swimming with stamina left is not drowning")
	assert_false(hud._drowning_hp_frame.visible)
	state.drowning = true
	hud._update_drowning_cue(state, 0.016)
	assert_true(hud._drowning_cue.visible, "drowning human swimmer shows the cue")
	assert_true(hud._drowning_hp_frame.visible, "and emphasises the health bar")
	state.drowning = false
	hud._update_drowning_cue(state, 0.016)
	assert_false(hud._drowning_cue.visible, "cue clears the frame drowning ends")
	assert_false(hud._drowning_hp_frame.visible)
	# Mounted or combat-paused never raises the trainer's cue.
	state.drowning = true
	for mode: int in [SWIM_STATE.Mode.MOUNTED, SWIM_STATE.Mode.COMBAT_PAUSED, SWIM_STATE.Mode.LAND]:
		state.mode = mode
		hud._update_drowning_cue(state, 0.016)
		assert_false(hud._drowning_cue.visible, "mode %d must not show the cue" % mode)
	hud._update_drowning_cue(null, 0.016)
	assert_false(hud._drowning_cue.visible, "no swim state, no cue")
	_free_cue_hud(hud)


func test_cue_follows_the_real_swim_state_through_recovery_paths() -> void:
	var hud := _hud_with_cue()
	var state := SWIM_STATE.new()
	state.owner_peer_id = 1
	state.enter_water(false, 0.0)
	state.advance(1, 0.5, 10.0, 100.0, 2.8, 4.0)
	hud._update_drowning_cue(state, 0.016)
	assert_false(hud._drowning_cue.visible, "stamina left: no cue")
	var lost: Dictionary = state.advance(1, 0.5, 0.0, 100.0, 2.8, 4.0)
	assert_true(float(lost.health_lost) > 0.0, "fixture: health must be falling")
	hud._update_drowning_cue(state, 0.016)
	assert_true(hud._drowning_cue.visible, "out of stamina in deep water: cue")
	# Stamina recovers (e.g. a consumable) -> next advance clears drowning.
	state.advance(1, 0.016, 40.0, 100.0, 2.8, 4.0)
	hud._update_drowning_cue(state, 0.016)
	assert_false(hud._drowning_cue.visible, "stamina back: cue gone")
	state.advance(1, 0.5, 0.0, 100.0, 2.8, 4.0)
	hud._update_drowning_cue(state, 0.016)
	assert_true(hud._drowning_cue.visible)
	state.pause_for_combat()
	hud._update_drowning_cue(state, 0.016)
	assert_false(hud._drowning_cue.visible, "combat pause: cue gone")
	state.resume_after_combat(false)
	state.advance(1, 0.5, 0.0, 100.0, 2.8, 4.0)
	hud._update_drowning_cue(state, 0.016)
	assert_true(hud._drowning_cue.visible)
	state.leave_water()
	hud._update_drowning_cue(state, 0.016)
	assert_false(hud._drowning_cue.visible, "landed: cue gone")
	_free_cue_hud(hud)


func test_cue_says_state_and_action_in_amber_at_legible_sizes() -> void:
	var hud := _hud_with_cue()
	var config := _config()
	assert_eq(hud._drowning_title_label.text, str(config.drowning_cue.title))
	assert_eq(hud._drowning_action_label.text, str(config.drowning_cue.action))
	assert_true(hud._drowning_title_label.text.length() > 0 and hud._drowning_action_label.text.length() > 0,
		"state word and recovery action are both text, not colour alone")
	assert_true(hud._drowning_icon != null and hud._drowning_icon.custom_minimum_size.x >= 44.0,
		"a caution shape reinforces the word")
	assert_eq(hud._drowning_title_label.get_theme_color("font_color"), UITokens.WARNING)
	var title_px: int = hud._drowning_title_label.get_theme_font_size("font_size")
	var action_px: int = hud._drowning_action_label.get_theme_font_size("font_size")
	# Authored at 1920x1080; the 1280x720 raster is x(720/1080).
	assert_true(title_px * 720.0 / 1080.0 >= 22.0, "title %d authored -> >= 22 px at 720p" % title_px)
	assert_true(action_px * 720.0 / 1080.0 >= 18.0, "action %d authored -> >= 18 px at 720p" % action_px)
	# No red anywhere in the cue: plate border and frame are WARNING amber.
	var plate: StyleBoxFlat = hud._drowning_cue.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(plate.border_color, UITokens.WARNING)
	var frame: StyleBoxFlat = hud._drowning_hp_frame.get_theme_stylebox("panel") as StyleBoxFlat
	assert_eq(frame.border_color, UITokens.WARNING)
	assert_true(plate.bg_color.a >= 0.8, "text over the world sits on a plate")
	_free_cue_hud(hud)


func test_health_frame_pulse_respects_reduced_motion() -> void:
	var hud := _hud_with_cue()
	var state := FakeSwimState.new()
	state.mode = SWIM_STATE.Mode.HUMAN
	state.drowning = true
	var was := MOTION_PREFS.reduced_motion()
	MOTION_PREFS.set_reduced_motion(false)
	var seen_dim := false
	for _i in 30:
		hud._update_drowning_cue(state, 0.05)
		seen_dim = seen_dim or hud._drowning_hp_frame.modulate.a < 0.9
	assert_true(seen_dim, "frame pulses with motion on")
	MOTION_PREFS.set_reduced_motion(true)
	for _i in 30:
		hud._update_drowning_cue(state, 0.05)
		assert_almost_eq(hud._drowning_hp_frame.modulate.a, 1.0, 0.0001, "steady under reduced motion")
	assert_true(hud._drowning_cue.visible and hud._drowning_hp_frame.visible,
		"reduced motion keeps the cue and frame, only drops the pulse")
	MOTION_PREFS.set_reduced_motion(was)
	_free_cue_hud(hud)


func test_a_yielding_dock_never_hides_a_drowning_player_health() -> void:
	# Independent review: a menu does not pause a multi-peer session, so a
	# client drowning behind the Satchel keeps losing health.
	assert_true(PLAYGROUND_HUD.health_cluster_visible(false, false, false), "ordinary: shown")
	assert_false(PLAYGROUND_HUD.health_cluster_visible(false, true, false), "a panel owns input: yields")
	assert_true(PLAYGROUND_HUD.health_cluster_visible(false, true, true), "drowning behind a panel: stays up")
	assert_false(PLAYGROUND_HUD.health_cluster_visible(true, false, false), "combat: stands down")
	assert_false(PLAYGROUND_HUD.health_cluster_visible(true, true, true), "combat pauses drowning; combat wins")


func test_a_configured_pulse_is_capped_below_flashing() -> void:
	var hud: CanvasLayer = PLAYGROUND_HUD.new()
	hud._apply_hud_config({"drowning_cue": {"pulse_speed": 100.0}})
	assert_eq(hud._drowning_pulse_speed, PLAYGROUND_HUD.DROWNING_PULSE_SPEED_MAX, "a configured 100 is capped")
	hud._apply_hud_config({"drowning_cue": {"pulse_speed": 3.0}})
	assert_eq(hud._drowning_pulse_speed, 3.0, "an ordinary value is kept")
	hud.free()

