extends "res://tests/test_case.gd"

## F40#15 candidate `ruin_collision_1113`: solid boxes for the overlook's piers
## and ruined wings. Ships ON (GPU High, 13 Nov 2026, G-below6-overlook-solid-c673:
## walk pair 4.23 -> 5.60, 3/3); the arch opening stays clear.

const OVERLOOK := preload("res://scripts/world/cloudreach_stormward_overlook.gd")
const CONFIG := "res://data/config/cloudreach_stormward_overlook_visual.json"


func test_ships_on_and_builds_the_solids() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var block: Dictionary = cfg.get("ruin_collision_1113", {})
	assert_true(bool(block.get("enabled", false)), "ruin_collision_1113 ships ON")
	assert_true(str(block.get("_why_on", "")).contains("G-below6-overlook-solid-c673.md"), "ON cites its GPU verdict")
	assert_true(str(block.get("_why_on", "")).contains("4.23 -> 5.60"), "and its judged score")
	assert_eq(str(block.get("_scope", "")), "world_geometry")
	var presentation: Node3D = OVERLOOK.new()
	var solids: Node3D = presentation.build_ruin_collision()
	assert_true(solids != null, "ON builds the solid piers and wings")
	var expected: int = (cfg.get("survey_piers", []) as Array).size() + (cfg.get("ruined_wings", []) as Array).size()
	assert_eq(solids.get_child_count(), expected, "one solid per pier and ruined wing")
	solids.free()
	presentation.free()


func test_walk_stands_are_reviewed_for_the_solid_ruin() -> void:
	var stands: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/capture_stands.json"))
	var frames: Dictionary = stands.heading_overrides.frames
	for id: String in ["walk_02_day", "walk_03_day"]:
		var row: Dictionary = frames.get("cloudreach__summit_final_stronghold__12__stormward_overlook__" + id, {})
		assert_true(row.has("heading_deg") and row.has("position_xz"), id + " has a reviewed stand")
		assert_true(str(row.get("_why", "")).contains("G-below6-overlook-solid-c673"), id + " cites the verdict")


func test_boxes_leave_the_arch_opening_clear() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var fit := float((cfg.ruin_collision_1113 as Dictionary).get("fit", 1.0))
	assert_true(fit > 0.5 and fit <= 1.0, "boxes sit inside the visible stone")
	for raw: Variant in cfg.get("survey_piers", []):
		var spec := raw as Dictionary
		var inner := absf(float(spec.position[0])) - float(spec.size[0]) * 0.5
		assert_true(inner >= 4.5, "pier clears the centre line by %.1f m" % inner)
	for raw: Variant in cfg.get("ruined_wings", []):
		var spec := raw as Dictionary
		assert_true(absf(float(spec.position[0])) - float(spec.size[0]) * 0.5 >= 4.5, "wing is outside the opening")
