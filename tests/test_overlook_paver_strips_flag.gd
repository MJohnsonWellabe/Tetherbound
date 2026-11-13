extends "res://tests/test_case.gd"

## F40#15 `paver_strips_1113` (LANE-LAND-CS): OFF until judged. On, the
## Stormward Overlook approach pavers (buried by the ridge join) are not built.

const OVERLOOK := preload("res://scripts/world/cloudreach_stormward_overlook.gd")
const CONFIG := "res://data/config/cloudreach_stormward_overlook_visual.json"


func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG))


func test_ships_off_and_off_builds_the_pavers() -> void:
	var cfg := _cfg()
	assert_false(bool(cfg.paver_strips_1113.get("enabled", true)), "paver_strips_1113 ships OFF until judged")
	assert_true(OVERLOOK.build_pavers(cfg), "OFF keeps the approach pavers")
	assert_eq((cfg.get("approach_pavers", []) as Array).size(), 4, "the four pavers stay in the config")


func test_on_skips_the_pavers() -> void:
	var cfg := _cfg()
	cfg.paver_strips_1113.enabled = true
	assert_false(OVERLOOK.build_pavers(cfg), "ON builds no approach paver")
	assert_true(OVERLOOK.build_pavers({}), "a config without the flag keeps them")
