extends "res://tests/test_case.gd"

## F40#1 candidate `wall_top_band_1113`: OFF until a GPU verdict; material only.


func test_candidate_is_off_and_scoped() -> void:
	var cfg: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var block: Dictionary = (cfg.get("landmass", {}) as Dictionary).get("wall_top_band_1113", {})
	assert_false(bool(block.get("enabled", true)))
	assert_eq(block.get("labels", []), ["LandmarkLedge", "CliffMass"])
	var tint := Color(str(block.get("tint", "#000000")))
	assert_true(tint.v > 0.8 and tint.s < 0.2, "a pale, near-neutral stone tint")


func test_the_band_reuses_the_wall_vertices() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("_add_geological_face(top_band_tool if top_band_tool != null else upper_tool,"),
		"the same face call, into another surface: no new geometry")
