extends "res://tests/test_case.gd"

## F40#1 `wall_top_band_1113`: OFF. G-below6-wall-band-main was amended to DO NOT SHIP (14 Nov):
## F40#8 loses on the Three Bells bridge cliff face; material only.


func test_is_off_after_the_amended_verdict_and_scoped() -> void:
	var cfg: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var block: Dictionary = (cfg.get("landmass", {}) as Dictionary).get("wall_top_band_1113", {})
	assert_false(bool(block.get("enabled", true)), "wall_top_band_1113 is OFF (amended DO NOT SHIP)")
	assert_true(str(block.get("_why_off", "")).contains("6.29 -> 5.86"), "the F40#8 loss is recorded")
	assert_false(bool(((cfg.get("landmass", {}) as Dictionary).get("gate_crag_terrace_1113", {}) as Dictionary).get("enabled", true)),
		"the gate terraces stay OFF")
	assert_eq(block.get("labels", []), ["LandmarkLedge", "CliffMass"])
	var tint := Color(str(block.get("tint", "#000000")))
	assert_true(tint.v > 0.8 and tint.s < 0.2, "a pale, near-neutral stone tint")


func test_the_band_reuses_the_wall_vertices() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("_add_geological_face(top_band_tool if top_band_tool != null else upper_tool,"),
		"the same face call, into another surface: no new geometry")
