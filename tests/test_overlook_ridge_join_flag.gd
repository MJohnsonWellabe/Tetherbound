extends "res://tests/test_case.gd"

## F40#15 `overlook_ridge_join_1113`: ships ON (GPU High, 13 Nov 2026,
## G-below6-overlook-join-c673: overlook set 4.86 -> 5.28, 3/3). Declared
## world_geometry because the collider follows the lifted rows.


func test_ships_on_with_its_verdict_and_declares_its_scope() -> void:
	var cfg: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var block: Dictionary = (cfg.get("landmass", {}) as Dictionary).get("overlook_ridge_join_1113", {})
	assert_true(bool(block.get("enabled", false)), "overlook_ridge_join_1113 ships ON")
	assert_true(str(block.get("_why_on", "")).contains("G-below6-overlook-join-c673.md"), "ON cites its GPU verdict")
	assert_true(str(block.get("_why_on", "")).contains("4.86 -> 5.28"), "and its judged score")
	assert_eq(str(block.get("_scope", "")), "world_geometry")
	assert_true(float(block.get("ease_m", 0.0)) > 0.0)


func test_world_reads_the_flag_and_never_lowers() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(source.contains("func _overlook_join_height("))
	assert_true(source.contains("return maxf(height, lerpf(height, crown"), "the lift is a max: never lowers a row")
	assert_true(source.contains("_overlook_join_height(raw,"), "applied to the ridge rows")
