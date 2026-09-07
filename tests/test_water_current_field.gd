extends "res://tests/test_case.gd"

const FIELD := preload("res://scripts/world/water_current_field.gd")

class Flags:
	extends RefCounted
	var opened := false
	func has(_id: String) -> bool:
		return opened


func test_shared_dock_result_changes_actual_current_without_rebuilding_field() -> void:
	var flags := Flags.new()
	var current := _current("lesson_departure", 0.08, 30)
	current.required_unlock_flag = "water_swim_lesson_complete"
	current.closed_strength_m_s = 6.0
	var field := FIELD.new({"currents": [current]}, flags)
	assert_eq(field.sample(Vector3(0, 0, 50)).velocity, Vector3(0, 0, -6))
	flags.opened = true
	assert_eq(field.sample(Vector3(0, 0, 50)).velocity, Vector3(0, 0, -0.08))


func _current(id: String, strength: float, priority: int, offset: float = 0.0) -> Dictionary:
	return {"id": id, "polyline": [[offset, 0, 0], [offset, 0, 100]],
		"width_m": 20.0, "edge_blend_m": 2.0, "flow_direction_xz": [0, -1],
		"strength_m_s": strength, "priority": priority, "post_liberation_strength_multiplier": 0.25}


func test_priority_selects_shelter_without_adding_overlapping_current() -> void:
	var field := FIELD.new({"currents": [_current("direct", 2.0, 20), _current("sheltered", 0.3, 30)]})
	var sample: Dictionary = field.sample(Vector3(0, 0, 50))
	assert_eq(sample.id, "sheltered")
	assert_eq(sample.velocity, Vector3(0, 0, -0.3))


func test_edges_blend_and_open_sea_has_no_synthetic_wall() -> void:
	var field := FIELD.new({"currents": [_current("a", 2.0, 20)]})
	assert_eq(field.sample(Vector3(9, 0, 50)).velocity, Vector3(0, 0, -1))
	assert_eq(field.sample(Vector3(10, 0, 50)).velocity, Vector3.ZERO)
	assert_eq(field.sample(Vector3(10000, 0, 10000)).velocity, Vector3.ZERO)


func test_equal_priority_uses_nearest_centerline() -> void:
	var field := FIELD.new({"currents": [_current("a", 2.0, 20), _current("b", 1.0, 20, 5.0)]})
	assert_eq(field.sample(Vector3(4, 0, 50)).id, "b")


func test_world_liberation_changes_same_field_for_visuals_and_traversal() -> void:
	var field := FIELD.new({"currents": [_current("a", 2.0, 20)]})
	assert_eq(field.sample(Vector3(0, 0, 50), true).velocity, Vector3(0, 0, -0.5))


func test_two_independent_peers_sample_identical_authored_field() -> void:
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var host := FIELD.new(config)
	var client := FIELD.new(config)
	for point in [Vector3(0, 0, 220), Vector3(850, 0, 2960), Vector3(200, 0, 3740)]:
		assert_eq(host.sample(point), client.sample(point))
