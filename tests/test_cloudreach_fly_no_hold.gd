extends "res://tests/test_case.gd"

## SYSTEMS Fly no-hold climb and the interim `fly_descend` toggle (#356): the
## tap rules in `fly_controller.gd::apply_taps`. The behavioural witness with
## real input on a real flyer is tests/smoke_cloudreach_fly_no_hold.gd.

const FLY := preload("res://scripts/player/fly_controller.gd")
const CONFIG := "res://data/config/fly_traversal.json"


func _fly() -> Node:
	return FLY.new()


func test_the_numbers_live_in_config() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_almost_eq(float(config.get("climb_pulse_seconds", -1.0)), 0.5)
	assert_almost_eq(float(config.get("climb_pulse_mps", -1.0)), 8.0)
	assert_almost_eq(float(config.get("climb_stamina_per_second", -1.0)), 1.6)


func test_a_climb_tap_starts_one_pulse() -> void:
	var fly := _fly()
	fly.call("apply_taps", {"climb": true}, false, 0.5)
	assert_almost_eq(float(fly.get("climb_pulse_left")), 0.5, 0.0001, "one tap, one 0.5 s pulse")
	assert_false(bool(fly.get("riding_updraft")), "outside a current the tap is only the pulse")
	fly.free()


func test_a_fresh_tap_refreshes_and_never_stacks() -> void:
	var fly := _fly()
	fly.call("apply_taps", {"climb": true}, false, 0.5)
	fly.set("climb_pulse_left", 0.2)
	fly.call("apply_taps", {"climb": true}, false, 0.5)
	assert_almost_eq(float(fly.get("climb_pulse_left")), 0.5, 0.0001, "refreshed to 0.5 s, not 0.7 s")
	fly.call("apply_taps", {"climb": true}, false, 0.5)
	assert_almost_eq(float(fly.get("climb_pulse_left")), 0.5, 0.0001, "a tap at full pulse stays at 0.5 s")
	fly.free()


func test_no_tap_no_pulse_so_holding_does_not_repeat() -> void:
	var fly := _fly()
	fly.call("apply_taps", {"climb": true}, false, 0.5)
	fly.set("climb_pulse_left", 0.0)
	# A held button produces no further edge: the frame's taps are all false.
	fly.call("apply_taps", {"climb": false, "descend": false}, false, 0.5)
	assert_almost_eq(float(fly.get("climb_pulse_left")), 0.0, 0.0001, "a held A starts nothing new")
	fly.free()


func test_input_owned_frames_carry_no_taps() -> void:
	var fly := _fly()
	var taps: Dictionary = fly.call("no_hold_taps", true, false)
	assert_false(bool(taps.climb) or bool(taps.descend), "a panel or cutscene owns the buttons")
	fly.free()


func test_a_climb_tap_in_a_current_rides_it() -> void:
	var fly := _fly()
	fly.call("apply_taps", {"climb": true}, true, 0.5)
	assert_true(bool(fly.get("riding_updraft")), "a tap inside a valid updraft rides the current (no hold)")
	fly.free()


func test_descend_is_a_toggle() -> void:
	var fly := _fly()
	fly.call("apply_taps", {"descend": true}, false, 0.5)
	assert_true(bool(fly.get("descend_toggled")), "one tap starts the descent")
	fly.call("apply_taps", {}, false, 0.5)
	assert_true(bool(fly.get("descend_toggled")), "it continues with no button held")
	fly.call("apply_taps", {"descend": true}, false, 0.5)
	assert_false(bool(fly.get("descend_toggled")), "the next tap ends it")
	fly.free()


func test_descend_and_climb_taps_end_each_other() -> void:
	var fly := _fly()
	fly.call("apply_taps", {"climb": true}, true, 0.5)
	fly.call("apply_taps", {"descend": true}, false, 0.5)
	assert_true(bool(fly.get("descend_toggled")))
	assert_almost_eq(float(fly.get("climb_pulse_left")), 0.0, 0.0001, "descending cancels the pulse")
	assert_false(bool(fly.get("riding_updraft")), "and the ride")
	fly.call("apply_taps", {"climb": true}, false, 0.5)
	assert_false(bool(fly.get("descend_toggled")), "a climb tap ends a toggled descent")
	fly.free()


func test_the_controller_reads_no_held_state() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/player/fly_controller.gd")
	assert_false(source.contains("is_action_pressed(\"jump\")"), "climb never reads a held A")
	assert_false(source.contains("is_action_pressed(\"fly_descend\")"), "descent never reads a held LT")
