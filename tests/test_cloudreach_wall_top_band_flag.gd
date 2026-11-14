extends "res://tests/test_case.gd"

## F40#1 `wall_top_band_1113`: ships ON (GPU High, 14 Nov 2026, G-below6-wall-band-main:
## F40#1 6.19 -> 6.51, 3/3); material only.


func test_ships_on_with_its_verdict_and_scoped() -> void:
	var cfg: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var block: Dictionary = (cfg.get("landmass", {}) as Dictionary).get("wall_top_band_1113", {})
	assert_true(bool(block.get("enabled", false)), "wall_top_band_1113 ships ON")
	assert_true(str(block.get("_why_on", "")).contains("G-below6-wall-band-main.md"), "ON cites its GPU verdict")
	assert_true(str(block.get("_why_on", "")).contains("6.19 -> 6.51"), "and its judged score")
	assert_false(bool(((cfg.get("landmass", {}) as Dictionary).get("gate_crag_terrace_1113", {}) as Dictionary).get("enabled", true)),
		"the gate terraces stay OFF until judged together with the band")
	assert_eq(block.get("labels", []), ["LandmarkLedge", "CliffMass"])
	var tint := Color(str(block.get("tint", "#000000")))
	assert_true(tint.v > 0.8 and tint.s < 0.2, "a pale, near-neutral stone tint")


func test_the_band_reuses_the_wall_vertices() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("_add_geological_face(top_band_tool if top_band_tool != null else upper_tool,"),
		"the same face call, into another surface: no new geometry")
