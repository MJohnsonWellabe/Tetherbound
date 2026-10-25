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


## Coordinator decision (22 Oct wind-down): the judged Tidewake look ships ON; every
## unjudged section ships in the file but OFF in play (sections_off), and only
## the explicit capture flag brings it back.
func test_shipped_look_is_on_with_unjudged_sections_off() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE.CONFIG))
	assert_true(bool(raw.enabled), "the judged Tidewake look ships on")
	var off: Array = raw.get("sections_off", [])
	for section: String in ["current_flow", "current_flow_visual", "night_creature_floor",
			"dock_village_candidate", "dock_dressing_candidate", "surfaces_candidate",
			"stones_candidate", "veilfall_hero_candidate",
			"veilfall_facade_candidate", "forward_plus_candidate",
			"veilfall_rock_detail_candidate", "first_shore_declutter_candidate",
			"veilfall_formation_relief_candidate", "veilfall_formation_relief_fill_candidate",
				"shore_surf_candidate", "shore_surf_vary_candidate", "veilfall_falls_candidate", "rain_fog_candidate",
				"rain_grade_candidate", "rain_veil_candidate", "swim_candidate", "dune_grass_candidate", "shore_water_candidate",
				"veilfall_mountain_candidate", "destination_landmarks_candidate",
				"waterline_declutter_candidate", "destination_landmarks_s3_candidate", "golden_sky_candidate", "current_bands_candidate"]:
		assert_true(off.has(section), "%s is unjudged and must ship off" % section)
		assert_true(raw.has(section), "%s ships in the file for capture" % section)
	# close-1024 lt2: the time-of-day regrade cleared the CPU-provisional bar
	# (mapped 7.07 in a confirming batch), so it ships ON and must stay out of
	# sections_off, with its score recorded beside it.
	assert_true(raw.has("lighting_candidate"), "the judged regrade ships in the file")
	assert_false(off.has("lighting_candidate"), "the judged regrade ships on")
	assert_true(str(raw.get("_why_lighting_candidate", "")).contains("7.07"),
		"the regrade's mapped score is recorded in the config")
	var regraded: Dictionary = PROFILE.settings().get("lighting_candidate", {})
	assert_true(regraded.get("times", {}).has("golden"), "the regrade reaches play")
	# close-1024 p1: the Meshy beach props beat main (mapped 5.59 vs 5.02), so
	# they ship ON by the coordinator's beats-main rule, score recorded beside them.
	assert_false(off.has("landmark_props_candidate"), "the judged beach props ship on")
	assert_true(str(raw.get("_why_landmark_props_candidate", "")).contains("5.59"),
		"the props' mapped score is recorded in the config")
	assert_false((PROFILE.settings().get("landmark_props_candidate", []) as Array).is_empty(),
		"the beach props reach play")
	# close-1024 ls1: the limestone beat shipping on the close-up and held level
	# on every other view it changes, so it ships ON with its scores beside it.
	assert_false(off.has("veilfall_rock_candidate"), "the judged limestone ships on")
	assert_true(str(raw.get("_why_veilfall_rock_candidate", "")).contains("4.20"),
		"the limestone's mapped score is recorded in the config")
	# close-1024 rf1: one rock family beat shipping on the close-up and held level
	# elsewhere, so it ships ON with its scores beside it.
	assert_false(off.has("veilfall_family_candidate"), "the judged rock family ships on")
	assert_true(str(raw.get("_why_veilfall_family_candidate", "")).contains("4.51"),
		"the rock family's mapped score is recorded in the config")
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


## close-1024 vf2: the veilfall-near gully floor is the `veilfall_exploration_spine`
## hike (4 m wide). Hero pieces are presentation (the ring has a collider), so each
## sits well clear of that trail's centreline rather than on or beside it.
func test_veilfall_hero_pieces_stay_clear_of_the_hike() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE.CONFIG))
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var spine: Array = []
	for route: Dictionary in world.get("land_routes", []):
		if str(route.get("id", "")) == "veilfall_exploration_spine":
			for point: Array in route.polyline:
				spine.append(Vector2(float(point[0]), float(point[2])))
	assert_true(spine.size() >= 2, "precondition: the Veilfall hike polyline exists")
	var pieces: Array = (raw.get("veilfall_hero_candidate", []) as Array) + (raw.get("veilfall_facade_candidate", []) as Array)
	assert_false(pieces.is_empty(), "precondition: the hero pieces ship in the file")
	for piece: Dictionary in pieces:
		var at := Vector2(float(piece.position_xz_m[0]), float(piece.position_xz_m[1]))
		var nearest := INF
		for index in spine.size() - 1:
			nearest = minf(nearest, at.distance_to(Geometry2D.get_closest_point_to_segment(at, spine[index], spine[index + 1])))
		assert_true(nearest >= 15.0, "%s sits %.1f m from the hike centreline" % [piece.get("landmark_id", "?"), nearest])


## close-1024 GPU asks: `_forward_plus` keys reach only Forward+/Mobile, and
## every time block of the candidate carries the same keys so keyframe blending
## never holds one block's value across a transition.
func test_forward_plus_keys_leave_compatibility_untouched() -> void:
	const LOOK := preload("res://scripts/world/world_look.gd")
	var cfg := {"energy": 0.95, "energy_forward_plus": 1.35}
	assert_eq(LOOK.renderer_overrides(cfg, "gl_compatibility"), cfg, "Compatibility reads the base values")
	assert_almost_eq(float(LOOK.renderer_overrides(cfg, "forward_plus").energy), 1.35)
	assert_almost_eq(float(LOOK.renderer_overrides(cfg, "mobile").energy), 1.35)
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE.CONFIG))
	var times: Dictionary = raw.get("forward_plus_candidate", {}).get("times", {})
	for name: String in ["day", "golden", "night", "dawn"]:
		assert_true(times.has(name), "%s carries the Forward+ keys" % name)
		for section: String in ["sun", "environment", "sky"]:
			assert_eq((times[name][section] as Dictionary).keys().size(),
				(times["night"][section] as Dictionary).keys().size(), "%s.%s has the full key set" % [name, section])
