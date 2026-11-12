extends "res://tests/test_case.gd"

## F40#15 (LANE-BELOW6, 12 Nov 2026): `masonry_scale_1112` is a declared,
## presentation-only switch for the shared Cloudreach masonry's brick scale.


func test_flag_is_declared_with_a_finer_tile_and_no_red() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var cfg: Dictionary = parsed.get("masonry_scale_1112", {})
	assert_false(cfg.is_empty(), "masonry_scale_1112 is declared")
	assert_eq(str(cfg.get("scope", "")), "client_presentation")
	assert_true(float(cfg.get("tile", 0.0)) > 0.28, "the brick tiles more often than the shared 0.28")
	var tint := Color(str(cfg.get("tint", "#808080")))
	assert_false(tint.r > tint.g + 0.15 and tint.r > tint.b + 0.15, "the wall stone is not red")


func test_the_world_reads_the_flag_where_it_builds_the_masonry() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	var at := source.find("ENVIRONMENT_MATERIALS.masonry(material_key")
	assert_true(at > 0 and source.find("masonry_scale_1112", at) > at and source.find("masonry_scale_1112", at) < at + 900,
		"masonry_scale_1112 is applied to the shared masonry materials")
