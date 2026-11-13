extends "res://tests/test_case.gd"

## F40#15 candidate `ruin_collision_1113`: solid boxes for the overlook's piers
## and ruined wings. OFF until a GPU verdict; the arch opening stays clear.

const OVERLOOK := preload("res://scripts/world/cloudreach_stormward_overlook.gd")
const CONFIG := "res://data/config/cloudreach_stormward_overlook_visual.json"


func test_candidate_is_off_and_builds_nothing() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var block: Dictionary = cfg.get("ruin_collision_1113", {})
	assert_false(bool(block.get("enabled", true)))
	assert_eq(str(block.get("_scope", "")), "world_geometry")
	var presentation: Node3D = OVERLOOK.new()
	assert_eq(presentation.build_ruin_collision(), null)
	presentation.free()


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
