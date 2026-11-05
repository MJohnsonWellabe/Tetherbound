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
	for section: String in ["current_flow_visual", "night_creature_floor",
			"dock_village_candidate", "dock_dressing_candidate", "surfaces_candidate",
			"veilfall_hero_candidate",
			"veilfall_facade_candidate", "forward_plus_candidate",
						"veilfall_formation_relief_fill_candidate",
				"swim_candidate",
				"veilfall_mountain_candidate",
				"current_bands_candidate", "current_tint_candidate", "veilfall_cladding_candidate", "veilfall_buttress_candidate", "swim_stroke_candidate", "beach_groups_candidate"]:
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
	# GPU TW1: the destination landmark stack (base, s3, s4, s5) beat no
	# sections by +1.24 mapped, so it ships ON with its GPU verdict beside it.
	for section: String in ["destination_landmarks_candidate", "destination_landmarks_s3_candidate",
			"destination_landmarks_s4_candidate", "destination_landmarks_s5_candidate"]:
		assert_false(off.has(section), "%s ships on after GPU TW1" % section)
		assert_false((PROFILE.settings().get(section, []) as Array).is_empty(), "%s reaches play" % section)
	assert_true(str(raw.get("_why_destination_landmarks_candidate", "")).contains("GPU TW1"),
		"the landmarks' GPU verdict is recorded in the config")
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
	# tb/vis-tidewake-1104 r3: the Veilfall near sections (rock detail, crag
	# relief, falls) lifted F39#31 CPU 4.94 -> 5.20, so they ship ON.
	for section: String in ["veilfall_rock_detail_candidate", "veilfall_formation_relief_candidate", "veilfall_falls_candidate"]:
		assert_false(off.has(section), "%s ships on after r3" % section)
		assert_true(PROFILE.settings().has(section), "%s reaches play" % section)
	assert_true(str(raw.get("_why_veilfall_near_on", "")).contains("5.20"),
		"the Veilfall near sections' mapped score is recorded in the config")
	# tb/vis-tidewake-1104 look r9: the rain trio lifted F39#30a, F39#30b and
	# F39#31 together (F39#30b CPU 5.81 -> 6.04), so it ships ON.
	for section: String in ["rain_fog_candidate", "rain_grade_candidate", "rain_veil_candidate"]:
		assert_false(off.has(section), "%s ships on after look r9" % section)
		assert_true(PROFILE.settings().has(section), "%s reaches play" % section)
	assert_true(str(raw.get("_why_rain_on", "")).contains("6.04"),
		"the rain trio's mapped score is recorded in the config")
	# tb/vis-tidewake-1104 look r13: the shore dressing lifted F39#30a, F39#30b
	# and F13#5 together (F39#30a CPU 6.19 -> 6.43), so it ships ON.
	for section: String in ["lesson_clusters_candidate", "dune_grass_candidate", "stones_candidate", "waterline_declutter_candidate"]:
		assert_false(off.has(section), "%s ships on after look r13" % section)
		assert_true(PROFILE.settings().has(section), "%s reaches play" % section)
	assert_true(str(raw.get("_why_shore_dressing_on", "")).contains("6.43"),
		"the shore dressing's mapped score is recorded in the config")
	# tb/vis-tidewake-1104 look r14: golden sky + shore water lifted F13#5 CPU
	# 5.69 -> 5.87 (shore rows unchanged), so they ship ON.
	for section: String in ["golden_sky_candidate", "shore_water_candidate"]:
		assert_false(off.has(section), "%s ships on after look r14" % section)
		assert_true(PROFILE.settings().has(section), "%s reaches play" % section)
	assert_true(str(raw.get("_why_golden_shore_water_on", "")).contains("5.87"),
		"the golden sky and shore water mapped score is recorded in the config")
	# tb/vis-tidewake-1104 look r15: the broken surf line lifted F39#30a CPU
	# 5.86 -> 6.19 and F13#5 5.31 -> 5.82, so it ships ON.
	for section: String in ["shore_surf_candidate", "shore_surf_vary_candidate"]:
		assert_false(off.has(section), "%s ships on after look r15" % section)
		assert_true(PROFILE.settings().has(section), "%s reaches play" % section)
	assert_true(str(raw.get("_why_shore_surf_on", "")).contains("6.19"),
		"the surf line's mapped score is recorded in the config")
	# tb/vis-tidewake-1104 look r18: the First Shore declutter lifted F39#30a CPU
	# 5.64 -> 5.73 and F39#30b 5.36 -> 5.45, so it ships ON.
	assert_false(off.has("first_shore_declutter_candidate"), "the First Shore declutter ships on after look r18")
	assert_true(PROFILE.settings().has("first_shore_declutter_candidate"), "the declutter reaches play")
	assert_true(str(raw.get("_why_first_shore_declutter_on", "")).contains("5.73"),
		"the declutter's mapped score is recorded in the config")
	var config := PROFILE.settings()
	for section: Variant in off:
		assert_false(config.has(str(section)), "%s must not reach play" % section)
	# Cloud yardstick 1 Nov batch-3: the current-flow lane beat main (P2-066
	# 4.12 -> 5.18), so it ships ON with its score recorded beside it.
	assert_false(off.has("current_flow"), "the judged current flow ships on")
	assert_true(str(raw.get("_why_current_flow_on", "")).contains("5.18"), "the current flow's mapped score is recorded in the config")
	var base := {"untouched": true}
	assert_ne(PROFILE.overlay(base, "current_flow", config), base, "the current flow reaches play")
	assert_eq(PROFILE.overlay(base, "current_flow_visual", config), base, "the unjudged current visual stays out of play")
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


## tb/vis-tidewake-1104 look r12: the Veilfall fall sheet stands 3 m off the rock
## so the gully ridge no longer cuts through it (F39#30b CPU 5.75 -> 5.85).
func test_veilfall_fall_sheet_clears_the_rock() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall_falls_visual.json"))
	assert_eq(float(cfg.geometry.standoff_m), 3.0)
	assert_true(str(cfg.get("_why_standoff_3m", "")).contains("5.85"))


## tb/vis-tidewake-1104 look r22: a higher golden and dawn sun shortens the
## long terrain shadows on the First Shore sand (F39#30a CPU 5.98 -> 6.18).
func test_low_sun_pitch_ships_with_its_score() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE.CONFIG))
	var times: Dictionary = raw.lighting_candidate.times
	assert_eq(float(times.golden.sun.pitch_deg), -12.0)
	assert_eq(float(times.dawn.sun.pitch_deg), -9.0)
	assert_true(str(raw.get("_why_low_sun_pitch", "")).contains("6.18"))


func test_destination_landmarks_ship_with_their_score() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROFILE.CONFIG))
	var arch := 0.0
	var garden_walls := 0
	for entry: Dictionary in raw.landmark_models:
		if str(entry.landmark_id) == "lantern_cove_drift_arch" and str(entry.model).ends_with("tidewake_drift_arch.glb"):
			arch = float(entry.height_m)
		if str(entry.landmark_id) == "drowned_garden_terraces":
			garden_walls += 1
	assert_eq(arch, 8.0, "the drift arch ships at 8 m")
	assert_eq(garden_walls, 4, "two stepped terrace walls join the two collided ones")
	assert_true(str(raw.get("_why_d3_landmarks", "")).contains("5.93"))
	assert_false("landmark_models" in raw.get("sections_off", []), "landmark models are in play")
