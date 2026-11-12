extends "res://tests/test_case.gd"

## Stormheart dressing (LANE-BELOW6, 12 Nov 2026). GPU High G-below6-stormdeck:
## F41#15 row 4.62 -> 5.10 (+0.48, 3/3), split-facing frame 4.50 -> 4.90
## (+0.40, 3/3); a ride-along. The warm deck wood, the cloth banners and the
## aged split wood ship ON and cite that verdict; the unjudged ramp body and
## core shader stay OFF.

const PRESENTATION_PATH := "res://data/config/stormheart_presentation.json"
const SPLIT_BARK := preload("res://scripts/world/stormheart_split_bark.gd")
const VERDICT := "G-below6-stormdeck.md"


func _doc() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION_PATH))
	return parsed if parsed is Dictionary else {}


func test_three_dressing_flags_ship_on_and_cite_the_verdict() -> void:
	var doc := _doc()
	var built: Dictionary = doc.get("built_detail", {})
	var split: Dictionary = doc.get("split_bark_finish", {})
	for entry: Dictionary in [built.get("deck_wood_warm_1112", {}), built.get("banner_cloth_1112", {}), split.get("aged_heartwood_1112", {})]:
		assert_true(bool(entry.get("enabled", false)), "the dressing flag ships ON (judged)")
		assert_true(str(entry.get("_why_on", "")).contains(VERDICT), "it cites its GPU verdict")


func test_unjudged_stormheart_candidates_stay_off() -> void:
	var doc := _doc()
	assert_false(bool((doc.get("ramp_body_1112", {}) as Dictionary).get("enabled", true)), "ramp_body_1112 stays OFF")
	var heartwood: Dictionary = doc.get("heartwood_1111", {})
	assert_false(bool((heartwood.get("core_v2", {}) as Dictionary).get("enabled", true)), "core_v2 stays OFF")
	assert_false(bool(heartwood.get("body_enabled", true)), "the axis body stays OFF")


func test_aged_wood_is_fully_grey_under_the_measured_tint() -> void:
	var split: Dictionary = _doc().get("split_bark_finish", {})
	var material := SPLIT_BARK.exposed_material(split)
	assert_eq(float(material.get_shader_parameter("weathering")), 1.0, "no orange atlas left")
	var tint: Color = material.get_shader_parameter("wood_tint")
	# khaki: leans against the violet light (the first tint rendered rose-mauve)
	assert_true(tint.r > tint.b and tint.g > tint.b, "the tint is warm, not pink (%s)" % tint.to_html(false))
	assert_true(tint.h * 360.0 > 40.0 and tint.h * 360.0 < 70.0, "tint hue stays in the khaki range")
