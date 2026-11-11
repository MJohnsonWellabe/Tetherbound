extends "res://tests/test_case.gd"

## F38#30 / F38#24 (LANE-NEWAPPROACH, GPU judged 10 Nov): the Burrow Warrens
## walk_03 route frame has a reviewed open-ground stand in capture_stands.json
## `heading_overrides`, and phase2_capture_routes.gd reads its heading and
## position. Capture tooling only.

const STANDS := "res://data/config/capture_stands.json"
const WALK03 := "meadows__band2_stone_and_root__04__the_burrow_warrens__walk_03_day"


func test_walk03_has_a_reviewed_open_ground_stand() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STANDS))
	var row: Dictionary = cfg.heading_overrides.frames.get(WALK03, {})
	assert_almost_eq(float(row.get("heading_deg", -1.0)), 231.0, 0.001, "walk_03 faces the hillside, road and ridge")
	var pos: Array = row.get("position_xz", [])
	assert_eq(pos.size(), 2, "walk_03 has an explicit stand position")
	assert_true(str(row.get("_why", "")).contains("+2.47"), "the judged gain is recorded")


func test_routes_tool_reads_heading_and_position() -> void:
	var src := FileAccess.get_file_as_string("res://tools/phase2_capture_routes.gd")
	assert_true(src.contains("heading_overrides"), "the routes tool reads the reviewed overrides")
	assert_true(src.contains("row[\"position_xz\"]"), "and applies an explicit stand position")
