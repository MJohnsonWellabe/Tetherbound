extends "res://tests/test_case.gd"

## F40#15 `paver_strips_1113` (LANE-LAND-CS): ships ON (GPU High, 14 Nov 2026,
## G-land-cs-overlook-seams: F40#15 5.10 -> 5.41, 3/3). The Stormward Overlook
## approach pavers (buried by the ridge join) are not built.

const OVERLOOK := preload("res://scripts/world/cloudreach_stormward_overlook.gd")
const CONFIG := "res://data/config/cloudreach_stormward_overlook_visual.json"


func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG))


func test_ships_on_with_its_verdict() -> void:
	var cfg := _cfg()
	assert_true(bool(cfg.paver_strips_1113.get("enabled", false)), "paver_strips_1113 ships ON")
	assert_true(str(cfg.paver_strips_1113.get("_why_on", "")).contains("G-land-cs-overlook-seams.md"), "ON cites its GPU verdict")
	assert_true(str(cfg.paver_strips_1113.get("_why_on", "")).contains("5.10 -> 5.41"), "and its judged score")
	assert_false(OVERLOOK.build_pavers(cfg), "ON builds no approach paver")
	cfg.paver_strips_1113.enabled = false
	assert_true(OVERLOOK.build_pavers(cfg), "OFF keeps the approach pavers")
	assert_eq((cfg.get("approach_pavers", []) as Array).size(), 4, "the four pavers stay in the config")


func test_on_skips_the_pavers() -> void:
	var cfg := _cfg()
	cfg.paver_strips_1113.enabled = true
	assert_false(OVERLOOK.build_pavers(cfg), "ON builds no approach paver")
	assert_true(OVERLOOK.build_pavers({}), "a config without the flag keeps them")
