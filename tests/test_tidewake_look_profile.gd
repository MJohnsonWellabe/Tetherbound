extends "res://tests/test_case.gd"

const PROFILE := preload("res://scripts/world/tidewake_look_profile.gd")
const CLOCK := preload("res://scripts/world/day_cycle.gd")


func test_disabled_candidate_preserves_the_shipping_inputs() -> void:
	var config := PROFILE.settings()
	config.enabled = false
	var base := CLOCK.load_config()
	assert_eq(PROFILE.overlay(base, "lighting", config), base)
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_visual.json"))
	assert_eq(PROFILE.overlay(visual, "surfaces", config), visual)


## Owner/coordinator 22 Oct: the judged Tidewake look ships ON; every
## unjudged section ships in the file but OFF in play (sections_off), and only
## the explicit capture flag brings it back.
func test_shipped_look_is_on_with_unjudged_sections_off() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE.CONFIG))
	assert_true(bool(raw.enabled), "the judged Tidewake look ships on")
	var off: Array = raw.get("sections_off", [])
	for section: String in ["current_flow", "current_flow_visual", "night_creature_floor"]:
		assert_true(off.has(section), "%s is unjudged and must ship off" % section)
		assert_true(raw.has(section), "%s ships in the file for capture" % section)
	var config := PROFILE.settings()
	for section: Variant in off:
		assert_false(config.has(str(section)), "%s must not reach play" % section)
	var base := {"untouched": true}
	assert_eq(PROFILE.overlay(base, "current_flow", config), base)
	assert_true(bool(config.enabled))


func test_candidate_preserves_clock_and_source_data() -> void:
	var config := PROFILE.settings()
	config.enabled = true
	var base := CLOCK.load_config()
	var before := base.duplicate(true)
	var look := PROFILE.overlay(base, "lighting", config)
	assert_eq(base, before, "shared art inputs cannot be recoloured for other realms")
	assert_eq(look.day_length_seconds, base.day_length_seconds)
	assert_eq(look.dark_from_hour, base.dark_from_hour)
	assert_eq(look.dark_to_hour, base.dark_to_hour)
	for time: String in ["day", "dawn", "golden", "night", "night_end"]:
		assert_eq(look.times[time].hour, base.times[time].hour)
	assert_eq(look.times.night_end.same_as, "night")
	var original_clock := CLOCK.new(base)
	var candidate_clock := CLOCK.new(look)
	for half_hour in range(48):
		var hour := float(half_hour) * 0.5
		assert_eq(candidate_clock.interpolate_at(hour), original_clock.interpolate_at(hour))
		assert_eq(candidate_clock.is_dark(hour), original_clock.is_dark(hour))


func test_rig_keeps_one_grade_and_matched_fog_horizons() -> void:
	var config := PROFILE.settings()
	config.enabled = true
	var look := PROFILE.overlay(CLOCK.load_config(), "lighting", config)
	for time: String in ["day", "dawn", "golden", "night"]:
		var sky := PROFILE.merge(look.sky, look.times[time].get("sky", {}))
		var env := PROFILE.merge(look.environment, look.times[time].get("environment", {}))
		assert_eq(env.fog_colour, sky.horizon_colour, time + " fog must meet the sky")
		for key: String in ["adjustment_brightness", "adjustment_contrast", "adjustment_saturation"]:
			assert_eq(env[key], look.environment[key], time + " uses the shared grade")
