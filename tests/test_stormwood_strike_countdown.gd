extends "res://tests/test_case.gd"

## F10#3 (coordinator/owner direction 2026-09-27 13:05, #356): the strike
## warning visibly counts down, the bolt lands at the ring centre, and
## Building and Fading carry distinct presentation.

const LIGHTNING := preload("res://scripts/world/stormwood_lightning.gd")
const SURGE_PATH := "res://data/config/stormwood_surge.json"


func _surge() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SURGE_PATH))


func test_the_ring_at_0_1_s_differs_from_1_1_s() -> void:
	var cfg := _surge()
	var seconds := float(cfg.strike.telegraph_seconds)
	var ramp_s := float(cfg.presentation.telegraph.final_ramp_seconds)
	assert_almost_eq(seconds, 1.2, 0.001, "the 1.2 s telegraph (COMBAT/BOSSES)")
	var early: Dictionary = LIGHTNING.telegraph_state(0.1, seconds, ramp_s)
	var late: Dictionary = LIGHTNING.telegraph_state(1.1, seconds, ramp_s)
	assert_true(float(early.closing_radius_fraction) > 0.9, "at 0.1 s the countdown ring is still near the rim (%s)" % str(early))
	assert_true(float(late.closing_radius_fraction) < 0.1, "at 1.1 s it has closed almost to the centre (%s)" % str(late))
	assert_true(float(late.fill) > float(early.fill) * 1.5, "the fill deepens toward impact")
	assert_almost_eq(float(early.ramp), 0.0, 0.001, "no final ramp early")
	assert_true(float(late.ramp) > 0.5, "the final ramp is under way at 1.1 s")


func test_the_shader_uses_the_same_countdown() -> void:
	var code: String = LIGHTNING.TELEGRAPH_SHADER
	assert_true(code.contains("float closing_r = rim_fraction * (1.0 - progress);"), "the ring closes with progress")
	assert_true(code.contains("float ramp = smoothstep(ramp_start, 1.0, progress);"), "the ramp follows progress")
	assert_false(code.contains("countdown * pulse"), "the countdown does not pulse (reduced motion keeps it)")
	assert_almost_eq(LIGHTNING.telegraph_ramp_start(1.2, 0.3), 0.75, 0.001)


func test_the_bolt_lands_at_the_warning_ring_centre() -> void:
	var ring := Vector3(12.0, 30.08, -4.0)
	assert_eq(LIGHTNING.bolt_centre(ring, Vector3(13.5, 30.0, -2.0)), ring, "an impact elsewhere still lands on the ring")
	assert_eq(LIGHTNING.bolt_centre(null, Vector3(13.5, 30.0, -2.0)), Vector3(13.5, 30.0, -2.0), "no drawn ring: the impact point")
	var source := FileAccess.get_file_as_string("res://scripts/world/stormwood_lightning.gd")
	assert_true(source.contains("_strike_flash(bolt_centre(_warning_centres.get(id), event.at))"))


func test_building_and_fading_are_distinct() -> void:
	var phases: Dictionary = _surge().presentation.phases
	var building: Dictionary = phases.building
	var fading: Dictionary = phases.fading
	assert_true(float(building.sheet_glow) > float(fading.sheet_glow), "Building flickers in-cloud; Fading does not")
	assert_true(float(fading.ceiling_breakup) > float(building.ceiling_breakup), "Fading opens gaps in the ceiling")
	assert_true(float(fading.steam) > 0.0 and float(building.steam) == 0.0, "only Fading steams")
