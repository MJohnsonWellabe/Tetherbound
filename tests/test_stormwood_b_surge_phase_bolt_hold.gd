extends "res://tests/test_case.gd"

## F10#3: while a real strike's ground warning is drawn, no decorative distant
## bolt appears (the code-blind judge read one as "already striking
## elsewhere"). Break keeps its in-cloud flash rhythm and the UX 8 budget.
const SURGE := preload("res://scripts/world/stormwood_surge.gd")
const MOTION_PREFS := preload("res://scripts/ui/motion_prefs.gd")


## 120 s of settled Break at 60 fps with the same seeds; `hold` re-arms the
## 1.5 s bolt hold every 1.2 s, as back-to-back warnings would.
func _run(hold: bool) -> Dictionary:
	var surge := SURGE.new()
	surge.phase = "break"
	surge._aftermath = false
	surge.settle_presentation()
	surge._sky_rng.seed = 8
	surge._flash_rng.seed = 9
	surge.sky_log.clear()
	var dt := 1.0 / 60.0
	var t := 0.0
	var next_hold := 0.0
	var bolt_peak := 0.0
	var held_frames := 0
	while t < 120.0:
		if hold and t >= next_hold:
			surge.hold_sky_bolts(1.5)
			next_hold += 1.2
		surge.call("_advance_flash", dt)
		t += dt
		bolt_peak = maxf(bolt_peak, surge.bolt_level())
		held_frames += 1 if surge.sky_bolts_held() else 0
	var onsets: Array = surge.sky_log.duplicate()
	surge.free()
	return {"onsets": onsets, "bolt_peak": bolt_peak, "held_frames": held_frames}


func _count(onsets: Array, kind: String) -> int:
	return onsets.filter(func(o: Array) -> bool: return str(o[1]).begins_with(kind)).size()


func test_no_decorative_bolt_while_a_warning_is_drawn() -> void:
	MOTION_PREFS.set_reduced_motion(false)
	var free := _run(false)
	var held := _run(true)
	assert_true(_count(free.onsets, "bolt") >= 10 and float(free.bolt_peak) > 0.5,
		"control: Break shows distant bolts without a warning (%d)" % _count(free.onsets, "bolt"))
	assert_true(int(held.held_frames) > 60 * 115, "the hold covered the run")
	assert_eq(_count(held.onsets, "bolt"), 0, "no decorative bolt onset under a live warning")
	assert_almost_eq(float(held.bolt_peak), 0.0, 0.0001, "no bolt drawn under a live warning")
	assert_true(_count(held.onsets, "cloud") >= _count(free.onsets, "cloud"),
		"held bolt events become in-cloud flashes (%d vs %d)" % [_count(held.onsets, "cloud"), _count(free.onsets, "cloud")])


func test_the_hold_expires_and_bolts_return() -> void:
	MOTION_PREFS.set_reduced_motion(false)
	var surge := SURGE.new()
	surge.phase = "break"
	surge.settle_presentation()
	surge.hold_sky_bolts(1.5)
	assert_true(surge.sky_bolts_held())
	surge.call("_advance_flash", 1.6)
	assert_false(surge.sky_bolts_held(), "a 1.5 s hold ends after 1.6 s")
	surge.free()


func test_hold_is_configured_and_lightning_arms_it_for_the_telegraph() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_surge.json"))
	assert_true(bool(cfg.presentation.sky_lightning.get("hold_bolts_during_warning", false)))
	var source := FileAccess.get_file_as_string("res://scripts/world/stormwood_lightning.gd")
	assert_true(source.contains("surge.hold_sky_bolts(float(rules.config.strike.telegraph_seconds) + 0.3)"),
		"the warning receiver arms the hold for the telegraph")


func test_a_bolt_already_on_screen_goes_out_when_a_warning_starts() -> void:
	for reduced: bool in [false, true]:
		MOTION_PREFS.set_reduced_motion(reduced)
		var surge := SURGE.new()
		surge.phase = "break"
		surge.settle_presentation()
		var cfg: Dictionary = surge.call("_sky_cfg")
		surge.call("_fire_sky_pulse", {"kind": "bolt", "at": 0.0, "first": true, "dir": Vector3.UP,
			"seed": 1, "strength": 0.6}, cfg)
		surge.call("_advance_flash", 1.0 / 60.0)
		assert_true(surge.bolt_level() > 0.5, "precondition: a bolt is on screen (reduced=%s)" % reduced)
		surge.hold_sky_bolts(1.5)
		assert_almost_eq(surge.bolt_level(), 0.0, 0.0001, "the warning puts the bolt out at once (reduced=%s)" % reduced)
		surge.call("_advance_flash", 1.0 / 60.0)
		assert_almost_eq(surge.bolt_level(), 0.0, 0.0001, "and it stays out (reduced=%s)" % reduced)
		surge.free()
	MOTION_PREFS.set_reduced_motion(false)
