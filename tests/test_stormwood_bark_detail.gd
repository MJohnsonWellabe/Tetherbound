extends "res://tests/test_case.gd"

## F41#22 bark detail (LANE-NEWAPPROACH, judged on GPU 10 Nov): the giant
## Stormwood trunks get a world-space tiling bark layer and stay matte through
## the light pass, instead of reading as smooth lilac plastic.

const VEG := preload("res://scripts/world/vegetation.gd")


func _look() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(VEG.STORMWOOD_LOOK_PATH))


func test_ships_on_with_gain_recorded_and_installed_textures() -> void:
	var grade: Dictionary = _look().get("bark_detail_1110", {})
	assert_true(bool(grade.get("enabled", false)), "bark detail ships ON after the GPU judge")
	assert_true(str(grade.get("_why_on", "")).contains("6.96"), "the judged gain is recorded")
	var adj: Dictionary = grade.adjust.storm_canopy.Bark_TwistedTree
	assert_true(bool(adj.get("matte", false)), "bark is matte")
	assert_true(ResourceLoader.exists(str(adj.detail_albedo)), "detail albedo installed")
	assert_true(ResourceLoader.exists(str(adj.detail_normal)), "detail normal installed")


func test_bark_tint_keeps_red_at_or_below_green() -> void:
	var grade: Dictionary = _look().bark_detail_1110
	var tint := Color(str(grade.layers.storm_canopy.Bark_TwistedTree))
	var albedo := Color8(84, 76, 72) * tint
	assert_true(albedo.r <= albedo.g + 0.005, "Bark_TwistedTree albedo red <= green (%s)" % albedo)


func test_grade_merges_and_light_pass_keeps_bark_matte() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/world/vegetation.gd")
	assert_true(src.contains("\"bark_detail_1110\""), "the grade is merged with the others")
	assert_true(src.contains("adjust_bcs("), "texture adjusts call the engine's adjust_bcs")
	assert_false(src.contains("adjust_bsc("), "the misspelt call is gone")
	var look_src := FileAccess.get_file_as_string("res://scripts/world/stormwood_look.gd")
	assert_true(look_src.contains("stormwood_bark"), "the light pass keeps bark matte")
