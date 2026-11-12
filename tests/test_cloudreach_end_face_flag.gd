extends "res://tests/test_case.gd"

## F40#15 P2-049 (LANE-BELOW6, 12 Nov 2026): `landmass.end_face_follows_row_1112`
## is a declared, render-only switch for the route shoulders' end faces.


func test_flag_is_declared_under_landmass_with_scope() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var cfg: Dictionary = (parsed.get("landmass", {}) as Dictionary).get("end_face_follows_row_1112", {})
	assert_false(cfg.is_empty(), "end_face_follows_row_1112 is declared under landmass")
	assert_eq(str(cfg.get("scope", "")), "client_presentation")
	assert_true(cfg.has("enabled"), "it has an explicit enabled value")


func test_the_builder_reads_the_flag_and_keeps_the_collider_on_the_top_rows() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("end_face_follows_row_1112"), "the ridge builder reads the flag")
	var collider := source.find("collision_tool.begin")
	assert_true(collider > 0 and source.find("_emit_shoulder_top(collision_tool, rows)", collider) > 0,
		"the collider is still built from the top rows only")
