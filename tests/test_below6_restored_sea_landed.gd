extends "res://tests/test_case.gd"

## LANE-BELOW6 landing (G-below6-swim-sea-r5, GPU High, 12 Nov 2026): the restored
## sea ships ON (F39#17 6.08 -> 6.27, 2/3; S3/S4 no loss) and cites its verdict.

const VERDICT := "G-below6-swim-sea-r5.md"


func _block(path: String, key: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (parsed as Dictionary).get(key, {}) if parsed is Dictionary else {}


func test_restored_sea_ships_on_with_its_verdict() -> void:
	var cfg := _block("res://data/config/water_current_flow_visual.json", "restored_sea_1112")
	assert_true(bool(cfg.get("enabled", false)), "restored_sea_1112 ships ON")
	assert_true(str(cfg.get("_why_on", "")).contains(VERDICT), "ON cites its GPU verdict")
	assert_true(str(cfg.get("_why_on", "")).contains("6.08 -> 6.27"), "and its judged score")
	assert_false(preload("res://scripts/world/water_restored_sea.gd").settings().is_empty(), "the restored-sea settings are live")
	assert_true((cfg.get("by_time", {}) as Dictionary).has("day"), "day keeps its own values (the sunset no-loss rule)")
