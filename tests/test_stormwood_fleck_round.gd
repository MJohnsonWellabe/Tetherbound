extends "res://tests/test_case.gd"

## F41#24 fleck_round_1110 (LANE-MESHY, ships ON: GPU +0.74, 10 Nov): round glints
## instead of whole-cell squares on the Stormwood cover.

const COVER := preload("res://scripts/world/stormwood_ground_cover.gd")


func _finish() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_ground_finish.json"))


func test_off_keeps_the_square_default() -> void:
	var finish := _finish()
	assert_true(bool(finish.fleck_round_1110.get("enabled", false)), "fleck_round_1110 ships ON after its judged gain")
	assert_true(str(finish.fleck_round_1110.get("_why_on", "")).contains("+0.74"), "the judged gain is recorded")
	finish.fleck_round_1110.enabled = false
	assert_false(COVER.moss_variation_params(finish).has("sw_glint_radius_m"), "OFF sets no radius (shader default 0 = shipped look)")


func test_on_sends_a_small_round_fleck_and_keeps_count_and_colours() -> void:
	var finish := _finish()
	finish.fleck_round_1110.enabled = false
	var before := COVER.moss_variation_params(finish)
	finish.fleck_round_1110.enabled = true
	var after := COVER.moss_variation_params(finish)
	if finish.moss_variation_1101.get("enabled", false):
		var radius := float(after.get("sw_glint_radius_m", 0.0))
		assert_true(radius > 0.0 and radius < 0.67 * 0.5, "a fleck is a disc well inside its 0.67 m cell (%.2f)" % radius)
		for key: String in ["sw_glint", "sw_glint_copper", "sw_glint_glass", "sw_glass_glow"]:
			assert_eq(after.get(key), before.get(key), "%s unchanged" % key)
	else:
		assert_true(after.is_empty(), "no moss variation, no fleck")
	var shader := FileAccess.get_file_as_string("res://shaders/stormwood_ground_cover.gdshader")
	assert_true(shader.contains("uniform float sw_glint_radius_m = 0.0;"), "shader default keeps the shipped look")
