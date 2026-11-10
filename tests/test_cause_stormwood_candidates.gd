extends "res://tests/test_case.gd"

## Cause lane tb/cause-stormwood (owner 1 Nov): Stormwood storm light, ground,
## deck and rain candidates. Each ships OFF, changes nothing while OFF, and
## applies only its own keys when ON.

const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")
const SHAFTS := preload("res://scripts/world/stormwood_storm_shafts.gd")
const COVER := preload("res://scripts/world/stormwood_ground_cover.gd")
const DECK_LIGHT := preload("res://scripts/world/stormheart_deck_light.gd")
const PRESENTATION_PATH := "res://data/config/stormheart_presentation.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Each candidate is tested on its own: start from every candidate OFF (both
## ship ON since v1/b16), then turn on only the named ones.
func _surge_with(keys: Array) -> Dictionary:
	var config := _json(RULES.PATH)
	for key: String in RULES.PRESENTATION_CANDIDATES:
		(config.presentation[key] as Dictionary)["enabled"] = false
	for key: String in keys:
		(config.presentation[key] as Dictionary)["enabled"] = true
	return config


## Visual lane v1/b16 (3 Nov): storm sky and soft rain ship ON with their judged
## scores; turned OFF they still leave the config identical.
func test_surge_candidates_ship_on_with_scores_and_are_inert_when_off() -> void:
	var config := _json(RULES.PATH)
	# Every other candidate (phase_grade_1104, and fine_rain_1110 since it shipped ON on
	# 10 Nov) is switched off too, so this checks only that these two are inert when OFF.
	for key: String in RULES.PRESENTATION_CANDIDATES:
		if key not in ["storm_sky_1101", "soft_rain_1101"]:
			(config.presentation[key] as Dictionary)["enabled"] = false
	for key: String in ["storm_sky_1101", "soft_rain_1101"]:
		assert_true(config.presentation.has(key), "%s must be declared" % key)
		assert_true(bool(config.presentation[key].get("enabled", false)), "%s ships ON (judged gain)" % key)
		assert_true(str(config.presentation[key].get("_why_on", "")).contains("5.84"), "%s records its mapped score" % key)
		(config.presentation[key] as Dictionary)["enabled"] = false
	assert_eq(RULES.with_presentation_candidates(config), config, "OFF must leave the config identical")


func test_storm_sky_on_gives_cloud_form_shafts_and_lift_only_in_presentation() -> void:
	var base := _json(RULES.PATH)
	var on := RULES.with_presentation_candidates(_surge_with(["storm_sky_1101"]))
	var calm: Dictionary = on.presentation.phases.calm
	var calm_off: Dictionary = base.presentation.phases.calm
	assert_true(float(calm.ceiling_definition) > 0.0, "the ceiling must gain cloud form")
	assert_true(float(calm.ceiling_contrast) > float(calm_off.ceiling_contrast), "more cloud contrast")
	assert_true(float(calm.sun_energy_mult) > float(calm_off.sun_energy_mult), "the storm's sun cut eases")
	assert_true(float(calm.shafts) > 0.0, "calm carries light shafts")
	assert_eq(str(calm.sky_top), str(calm_off.sky_top), "the fixed purple sky stays")
	assert_true(bool(on.presentation.shafts.enabled), "the shaft layer switches on")
	assert_true(bool(on.presentation.ceiling.skyline.enabled), "the parked skyline switches on")
	assert_eq(on.presentation.ceiling.radius_m, base.presentation.ceiling.radius_m, "unnamed ceiling keys stay")
	assert_eq(on.presentation.rain, base.presentation.rain, "the sky candidate leaves rain alone")
	for key: String in base:
		if key != "presentation":
			assert_eq(on[key], base[key], "non-presentation section %s must not change" % key)
	# The always-on P2-042 Building row must not undo the lift.
	var building: Dictionary = on.presentation.phase_readability_candidate.phases.building
	assert_true(float(building.sun_energy_mult) > float(base.presentation.phase_readability_candidate.phases.building.sun_energy_mult),
		"the Building readability row carries the lift too")


func test_soft_rain_on_softens_and_tints_streaks() -> void:
	var base := _json(RULES.PATH)
	var on := RULES.with_presentation_candidates(_surge_with(["soft_rain_1101"]))
	var rain: Dictionary = on.presentation.rain
	assert_true(float(rain.soft_edge) > 0.0, "streak edges must soften")
	assert_true(float(rain.alpha) < float(base.presentation.rain.alpha), "softer streaks are fainter")
	assert_true(Color(str(rain.colour)).get_luminance() < Color(str(base.presentation.rain.colour)).get_luminance(),
		"streaks tint off white")
	assert_eq(rain.near_fade_m, base.presentation.rain.near_fade_m, "near-lens fade unchanged")
	assert_eq(rain.far_layer.inner_radius_m, base.presentation.rain.far_layer.inner_radius_m, "far ring unchanged")
	assert_eq(on.presentation.phases, base.presentation.phases, "the rain candidate leaves phases alone")


func test_both_surge_candidates_compose() -> void:
	var on := RULES.with_presentation_candidates(_surge_with(["storm_sky_1101", "soft_rain_1101"]))
	assert_true(float(on.presentation.rain.soft_edge) > 0.0 and float(on.presentation.phases.calm.shafts) > 0.0,
		"both overlays apply together")


func test_rain_shader_soft_edge_defaults_off() -> void:
	var code := FileAccess.get_file_as_string("res://scripts/world/stormwood_surge.gd")
	assert_true(code.contains("uniform float soft_edge = 0.0;"), "the soft edge must default to off")


func test_shaft_layout_is_deterministic_and_sparse() -> void:
	var cfg: Dictionary = _json(RULES.PATH).presentation.storm_sky_1101.overlay.shafts
	var a := SHAFTS.placements(Vector2i(3, -7), cfg)
	var b := SHAFTS.placements(Vector2i(3, -7), cfg)
	var ring := int(cfg.ring)
	assert_eq(a.size(), (ring * 2 + 1) * (ring * 2 + 1), "one slot per cell")
	assert_eq(a, b, "the same cell gives the same shafts")
	var lit := 0
	var cells := 0
	for x in range(-20, 20, 7):
		for z in range(-20, 20, 7):
			for p: Dictionary in SHAFTS.placements(Vector2i(x, z), cfg):
				cells += 1
				if float(p.alpha) > 0.0:
					lit += 1
	var share := float(lit) / float(cells)
	assert_true(share > float(cfg.chance) * 0.5 and share < float(cfg.chance) * 1.5,
		"about `chance` of cells carry a shaft (got %.2f)" % share)


func test_moss_variation_ships_on_with_its_score_and_sets_nothing_when_off() -> void:
	var finish := _json("res://data/config/stormwood_ground_finish.json")
	assert_true(bool(finish.moss_variation_1101.get("enabled", false)), "ships ON (judged gain, v1/b16)")
	assert_true(str(finish.moss_variation_1101.get("_why_on", "")).contains("5.84"), "records its mapped score")
	(finish.moss_variation_1101 as Dictionary)["enabled"] = false
	assert_true(COVER.moss_variation_params(finish).is_empty(), "OFF sets no uniform")
	var code := FileAccess.get_file_as_string("res://shaders/stormwood_ground_cover.gdshader")
	for zero: String in ["uniform float sw_moss_strength = 0.0;", "uniform float sw_clearing = 0.0;",
			"uniform float sw_glint = 0.0;", "uniform float sw_glass_glow = 0.0;"]:
		assert_true(code.contains(zero), "shader default must be inert: " + zero)


func test_moss_variation_on_sets_typed_uniforms_without_red() -> void:
	var finish := _json("res://data/config/stormwood_ground_finish.json")
	(finish.moss_variation_1101 as Dictionary)["enabled"] = true
	var params := COVER.moss_variation_params(finish)
	assert_true(float(params.sw_moss_strength) > 0.0, "moss variation applies")
	assert_true(params.sw_moss_copper is Color, "colours become Color")
	assert_false(params.has("enabled") or params.has("scope"), "only sw_ uniforms are set")
	for key: String in params:
		if params[key] is Color:
			var c: Color = params[key]
			assert_false(c.r > c.g * 1.6 and c.r > c.b * 2.0, "no red/oxblood tone: " + key)


## VIS-STORMWOOD j1 (4 Nov): the deck light ships ON with its judged score.
func test_deck_light_ships_on_and_lays_out_its_rings() -> void:
	var presentation := _json(PRESENTATION_PATH)
	var settings: Dictionary = presentation.deck_light_1101
	assert_true(bool(settings.get("enabled", false)), "ships ON (judged gain)")
	assert_true(str(settings.get("_why_on", "")).contains("3.94"), "records its mapped score")
	var poses := DECK_LIGHT.poses(settings)
	var expected := 0
	for ring: Dictionary in settings.rings:
		expected += int(ring.count)
	assert_eq(poses.size(), expected, "one lantern per ring slot")
	assert_true(expected + 1 <= 8, "lanterns plus the crown light stay inside the Compatibility per-object cap")
	for pose: Dictionary in poses:
		var at: Vector3 = pose.position
		assert_true(Vector2(at.x, at.z).length() < 46.0, "lanterns stay inside the hollow's inner clearance")


func test_crown_shaft_places_fixed_columns_without_the_camera_grid() -> void:
	var cfg: Dictionary = _json(PRESENTATION_PATH).deck_light_1101.crown_shaft
	var shaft: MultiMeshInstance3D = SHAFTS.new()
	shaft.setup(cfg)
	shaft.place_fixed([{"position": Vector3(0, 190, 0), "width": 16.0, "height": 130.0},
		{"position": Vector3(-6, 175, 5), "width": 9.0, "height": 110.0, "alpha": 0.7}])
	assert_eq(shaft.multimesh.instance_count, 2, "one instance per authored column")
	assert_false(shaft.top_level, "fixed columns follow the tree, not the camera")
	# (The headless dummy renderer keeps no MultiMesh buffer, so transforms
	# are not read back here.)
	shaft.set_strength(0.0)
	assert_false(shaft.visible, "zero strength hides the layer")
	shaft.set_strength(1.0)
	assert_true(shaft.visible, "positive strength shows it")
	shaft.free()


## VIS-STORMWOOD (4 Nov), F41#2: the per-phase grade lifts Calm into a
## higher-key sky and drops Building into a lower one, keeping the purple hue,
## Break's darkest ground and every non-presentation section.
func test_phase_grade_separates_calm_from_building_and_keeps_break_rules() -> void:
	var base := _json(RULES.PATH)
	var off := RULES.with_presentation_candidates(_surge_with(["storm_sky_1101", "soft_rain_1101"]))
	var on := RULES.with_presentation_candidates(_surge_with(["storm_sky_1101", "soft_rain_1101", "phase_grade_1104"]))
	var calm_lum := Color(str(on.presentation.phases.calm.sky_horizon)).get_luminance()
	var building_lum := Color(str(on.presentation.phases.building.sky_horizon)).get_luminance()
	var off_gap := Color(str(off.presentation.phases.calm.sky_horizon)).get_luminance() \
		- Color(str(off.presentation.phases.building.sky_horizon)).get_luminance()
	assert_true(calm_lum - building_lum > off_gap + 0.1, "Calm and Building skies separate")
	for phase: String in ["calm", "building", "break", "fading"]:
		var hue := Color(str(on.presentation.phases[phase].sky_top)).h * 360.0
		assert_true(hue >= 235.0 and hue <= 290.0, "%s sky stays purple (hue %.0f)" % [phase, hue])
		assert_eq(on.presentation.phases[phase].ambient_colour, off.presentation.phases[phase].ambient_colour, "%s ambient unchanged" % phase)
	assert_eq(on.presentation.phases.break, off.presentation.phases.break, "Break is untouched")
	var building_sun := float(on.presentation.phase_readability_candidate.phases.building.sun_energy_mult)
	assert_true(float(on.presentation.phases.calm.sun_energy_mult) > building_sun, "Calm keys brighter than Building")
	assert_true(building_sun > float(on.presentation.phases.break.sun_energy_mult), "Break keeps the lowest key light")
	assert_true(float(on.presentation.phases.calm.sun_energy_mult) <= float(on.presentation.aftermath.all.sun_energy_mult), "the aftermath key stays steadiest")
	var brk := Color(str(on.presentation.phases.break.ceiling_colour)).get_luminance()
	assert_true(Color(str(on.presentation.phases.building.ceiling_colour)).get_luminance() > brk, "the Break deck stays darkest")
	assert_true(Color(str(on.presentation.phases.calm.ceiling_colour)).get_luminance() > brk, "Calm's deck is lighter than Break's")
	for key: String in base:
		if key != "presentation":
			assert_eq(on[key], base[key], "non-presentation section %s must not change" % key)
