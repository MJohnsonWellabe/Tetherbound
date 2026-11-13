extends "res://tests/test_case.gd"

## LANE-BELOW6 landing (G-below6-swim-sea-r5, GPU High, 12 Nov 2026): the surface
## crawl ships ON (F39#5 5.45 -> 5.98, F39#14 5.74 -> 6.12, 3/3) and cites its verdict.

const VERDICT := "G-below6-swim-sea-r5.md"


func _block(path: String, key: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (parsed as Dictionary).get(key, {}) if parsed is Dictionary else {}


func test_surface_crawl_ships_on_with_its_verdict() -> void:
	var cfg := _block("res://data/config/human_swim_visual.json", "surface_crawl_1112")
	assert_true(bool(cfg.get("enabled", false)), "surface_crawl_1112 ships ON")
	assert_true(str(cfg.get("_why_on", "")).contains(VERDICT), "ON cites its GPU verdict")
	assert_true(str(cfg.get("_why_on", "")).contains("5.45 -> 5.98"), "and its judged score")
	var pose: Dictionary = preload("res://scripts/player/trainer_model.gd").load_human_swim_visual()
	assert_true(float(pose.get("arm_reach_scale", 1.0)) < 1.0, "the loaded pose is the sideways sweep")
	assert_true(float(pose.get("chest_above_surface_m", 1.0)) < 0.0, "with the chest under the surface")
