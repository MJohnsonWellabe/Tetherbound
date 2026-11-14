extends "res://tests/test_case.gd"

## F40#1 / F40#8 WALL-BAND round 2 (LANE-LAND-CS): `wall_top_band_1113.band_depth_m`.
## Unset keeps the round 1 band (the whole first wall band); set, only the top
## metres under the rim take the pale band and the cliff face below keeps its
## ordinary material.


func test_shipped_config_leaves_the_band_off_and_unsplit() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var block: Dictionary = cfg.landmass.wall_top_band_1113
	assert_false(bool(block.get("enabled", true)), "the band stays OFF until round 2 is judged")
	assert_false(block.has("band_depth_m"), "band_depth_m is set only by the arm overlay")


func test_split_is_in_the_band_emission() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains('top_band_cfg.get("band_depth_m", 0.0)'), "the depth is read from the band config, default 0 (no split)")
	assert_true(source.contains("_add_geological_face(top_band_tool, top_ring[i], top_ring[next], mid_a, mid_b"), "the pale band ends at the split")
	assert_true(source.contains("_add_geological_face(upper_tool, mid_a, mid_b, upper_ring[i], upper_ring[next]"), "the face below keeps the ordinary material")
