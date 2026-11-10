extends "res://tests/test_case.gd"

## F39#21 metal_1110 (LANE-MESHY): the Heart Chamber's metal-coloured boxes wear
## rock-trim stone when ON; the S-scroll railing sheet stays only when OFF.

func test_candidate_declared_and_stone_family() -> void:
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	var cand: Dictionary = rules.interior_dressing.metal_1110
	assert_true(cand.has("enabled"), "declared as a candidate")
	assert_false(str(cand.albedo).contains("MetalOrnaments"), "not the S-scroll railing sheet")
	assert_true(str(cand.albedo).contains("RockTrim"), "the chamber's own trim stone")
	assert_true(ResourceLoader.exists(str(cand.albedo)) and ResourceLoader.exists(str(cand.normal)), "textures installed")
	var src := FileAccess.get_file_as_string("res://scripts/world/water_veilfall_interior_dressing.gd")
	assert_true(src.contains("metal_1110"), "the dressing reads the candidate")
