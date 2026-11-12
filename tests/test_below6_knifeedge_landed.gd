extends "res://tests/test_case.gd"

## LANE-BELOW6 landing (G-below6-knifeedge, GPU High, 12 Nov 2026): the route
## shoulders' end faces follow their top row, which removes the black strip at
## the Three Bells bridge foot (F40#8 5.61 -> 6.37, 3/3). Ships ON.


func test_end_face_fix_ships_on_with_its_verdict() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var cfg: Dictionary = (parsed.get("landmass", {}) as Dictionary).get("end_face_follows_row_1112", {})
	assert_true(bool(cfg.get("enabled", false)), "end_face_follows_row_1112 ships ON")
	assert_true(str(cfg.get("_why_on", "")).contains("G-below6-knifeedge.md"), "ON cites its GPU verdict")
	assert_true(str(cfg.get("_why_on", "")).contains("5.61 -> 6.37"), "and its judged score")
	assert_eq(str(cfg.get("scope", "")), "client_presentation")
