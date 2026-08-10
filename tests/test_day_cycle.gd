extends "res://tests/test_case.gd"

## R5.1's clock: elapsed real seconds -> hour of day -> which named
## data/config/art.json preset is active, and whether it counts as dark.
##
## Pure math only (docs/decisions/D02) -- the rendered result (does the sun
## actually move, does the sky actually darken) is scripts/world/world_look.gd's
## job and is not testable from here. What is testable, and what shipped this
## broken before: whether the hour wraps correctly across midnight and
## whether "dark" survives that same wrap.

const DAY_CYCLE := preload("res://scripts/world/day_cycle.gd")

var _cycle: RefCounted


func before_each() -> void:
	_cycle = DAY_CYCLE.new({
		"day_length_seconds": 24.0,
		"dark_from_hour": 20.0,
		"dark_to_hour": 5.0,
		"times": {
			"night": {"hour": 0.0},
			"day": {"hour": 8.0},
			"golden": {"hour": 18.0},
			"_comment": {"not": "a keyframe, no hour key"},
		},
	})


func test_config_loads() -> void:
	var config := DAY_CYCLE.load_config()
	assert_false(config.is_empty(), "art.json should parse")
	assert_true(config.has("times"), "art.json should describe named times")


func test_hour_at_wraps_every_day_length() -> void:
	# day_length_seconds is 24 above, so 1 elapsed second == 1 in-game hour.
	assert_almost_eq(_cycle.hour_at(0.0), 0.0)
	assert_almost_eq(_cycle.hour_at(8.0), 8.0)
	assert_almost_eq(_cycle.hour_at(24.0), 0.0, 0.0001, "a full day should wrap back to hour 0")
	assert_almost_eq(_cycle.hour_at(30.0), 6.0, 0.0001, "elapsed time past one day should keep wrapping")


func test_elapsed_for_hour_is_the_inverse_of_hour_at() -> void:
	for hour in [0.0, 8.0, 13.5, 23.9]:
		var elapsed: float = _cycle.elapsed_for_hour(hour)
		assert_almost_eq(_cycle.hour_at(elapsed), hour, 0.001,
			"elapsed_for_hour(%.1f) should round-trip through hour_at" % hour)


func test_preset_at_picks_the_latest_keyframe_at_or_before_the_hour() -> void:
	assert_eq(_cycle.preset_at(8.0), "day", "exactly on a keyframe should select it")
	assert_eq(_cycle.preset_at(10.0), "day", "between day and golden should still be day")
	assert_eq(_cycle.preset_at(17.9), "day")
	assert_eq(_cycle.preset_at(18.0), "golden")
	assert_eq(_cycle.preset_at(23.0), "golden", "between golden and midnight should still be golden")


func test_preset_at_wraps_past_midnight_to_the_last_keyframe() -> void:
	# There is no keyframe between golden (18) and night (0/24); anything in
	# that band, including exactly 0, is "night" -- there is no third state
	# hiding between the last keyframe of one day and the first of the next.
	assert_eq(_cycle.preset_at(0.0), "night")
	assert_eq(_cycle.preset_at(3.0), "night")
	assert_eq(_cycle.preset_at(7.9), "night")
	assert_eq(_cycle.preset_at(24.0), "night", "hour 24 should behave exactly like hour 0")


func test_is_dark_matches_the_configured_window() -> void:
	assert_true(_cycle.is_dark(20.0), "dark_from_hour itself should already be dark")
	assert_true(_cycle.is_dark(23.0))
	assert_true(_cycle.is_dark(0.0), "midnight is inside a window that wraps past it")
	assert_true(_cycle.is_dark(4.9))
	assert_false(_cycle.is_dark(5.0), "dark_to_hour itself should no longer be dark")
	assert_false(_cycle.is_dark(12.0))
	assert_false(_cycle.is_dark(19.9))


func test_a_keyframe_with_no_hour_is_not_part_of_the_cycle() -> void:
	# "_comment" above has no "hour" key. If it leaked into the keyframe list,
	# fposmod(float(<Dictionary>), 24.0) would either crash or silently coerce
	# to 0 and collide with "night".
	assert_eq(_cycle.keyframe_names().size(), 3,
		"only day/golden/night name an hour; the comment entry must be skipped")
	assert_false(_cycle.keyframe_names().has("_comment"))


func test_day_length_seconds_is_never_zero_or_negative() -> void:
	# A zero day length would make hour_at divide by zero.
	var degenerate: RefCounted = DAY_CYCLE.new({"day_length_seconds": 0.0})
	assert_true(degenerate.day_length_seconds > 0.0,
		"a non-positive day_length_seconds must be clamped, not divided by")
