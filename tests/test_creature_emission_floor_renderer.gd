extends "res://tests/test_case.gd"

## F22#4 GPU pass: the creature emission floor washes plain-PBR creatures milky
## on Forward+, so it is renderer-aware; Compatibility keeps it exactly.

const WORLD_LOOK := preload("res://scripts/world/world_look.gd")


func test_compatibility_and_other_methods_keep_the_floor_exactly() -> void:
	var cfg := {"creature_emission_floor": 0.22, "creature_emission_floor_forward_plus_scale": 0.0}
	for method: String in ["gl_compatibility", "dummy", ""]:
		assert_almost_eq(WORLD_LOOK.creature_emission_floor_for_renderer(cfg, method), 0.22, 0.0001, method)


func test_forward_plus_and_mobile_take_the_configured_share() -> void:
	var cfg := {"creature_emission_floor": 0.2, "creature_emission_floor_forward_plus_scale": 0.25}
	for method: String in ["forward_plus", "mobile"]:
		assert_almost_eq(WORLD_LOOK.creature_emission_floor_for_renderer(cfg, method), 0.05, 0.0001, method)


func test_a_missing_scale_leaves_every_renderer_unchanged() -> void:
	var cfg := {"creature_emission_floor": 0.08}
	assert_almost_eq(WORLD_LOOK.creature_emission_floor_for_renderer(cfg, "forward_plus"), 0.08, 0.0001)
	assert_almost_eq(WORLD_LOOK.creature_emission_floor_for_renderer({}, "forward_plus"), 0.0, 0.0001)


func test_shipping_art_turns_the_floor_off_on_forward_plus_only() -> void:
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	var env: Dictionary = art.get("environment", {})
	assert_true(env.has("creature_emission_floor_forward_plus_scale"), "the base block carries the scale")
	assert_almost_eq(WORLD_LOOK.creature_emission_floor_for_renderer(env, "forward_plus"), 0.0, 0.0001)
	assert_almost_eq(WORLD_LOOK.creature_emission_floor_for_renderer(env, "gl_compatibility"),
		float(env.get("creature_emission_floor", 0.0)), 0.0001)


func test_night_keeps_a_small_forward_plus_floor_for_dark_coats() -> void:
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	var night: Dictionary = art["times"]["night"]["environment"]
	var scale := float(night.get("creature_emission_floor_forward_plus_scale", -1.0))
	assert_true(scale > 0.0 and scale <= 0.1,
		"night keeps a small Forward+ share (GPU: x0 hides Cindercub, x0.1 already washes Ripplet), got %s" % scale)
	var merged := (art.get("environment", {}) as Dictionary).duplicate()
	merged.merge(night, true)
	assert_almost_eq(WORLD_LOOK.creature_emission_floor_for_renderer(merged, "forward_plus"),
		float(night["creature_emission_floor"]) * scale, 0.0001)
	assert_almost_eq(WORLD_LOOK.creature_emission_floor_for_renderer(merged, "gl_compatibility"),
		float(night["creature_emission_floor"]), 0.0001)
