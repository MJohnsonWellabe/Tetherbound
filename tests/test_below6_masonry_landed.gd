extends "res://tests/test_case.gd"

## LANE-BELOW6 landing (G-below6-stormraven-masonry, GPU High, 12 Nov 2026): the
## shared Cloudreach masonry tiles at human scale (F40#15 5.17 -> 5.54, 3/3;
## Sky Shrine and aviary level). Ships ON.


func test_masonry_scale_ships_on_with_its_verdict() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var cfg: Dictionary = parsed.get("masonry_scale_1112", {})
	assert_true(bool(cfg.get("enabled", false)), "masonry_scale_1112 ships ON")
	assert_true(str(cfg.get("_why_on", "")).contains("G-below6-stormraven-masonry.md"), "ON cites its GPU verdict")
	assert_true(str(cfg.get("_why_on", "")).contains("5.17 -> 5.54"), "and its judged score")
	assert_true(float(cfg.get("tile", 0.0)) > 0.28, "the brick repeats more often than the old 0.28")
