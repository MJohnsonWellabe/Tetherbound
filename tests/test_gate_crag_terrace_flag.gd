extends "res://tests/test_case.gd"

## F40#1 candidate `gate_crag_terrace_1113`: OFF until a GPU verdict. Every lip
## is at or under the walker's 0.35 m step height.


func test_candidate_is_off_and_walkable_by_design() -> void:
	var cfg: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var block: Dictionary = (cfg.get("landmass", {}) as Dictionary).get("gate_crag_terrace_1113", {})
	assert_false(bool(block.get("enabled", true)))
	assert_eq(str(block.get("_scope", "")), "world_geometry")
	assert_true(float(block.get("lip_m", 1.0)) <= 0.35, "each lip can be stepped")
	var reach := float(block.get("radius_m", 0.0)) * (1.0 + 1.45 * float(block.get("wave", 0.0)))
	var centre: Array = block.get("centre_xz", [0.0, 0.0])
	assert_true(reach + Vector2(float(centre[0]), float(centre[1])).length() < 20.7,
		"the terrace stays inside the crown's 20.7 m flat radius")
