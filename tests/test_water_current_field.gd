extends "res://tests/test_case.gd"

const FIELD := preload("res://scripts/world/water_current_field.gd")

class Flags:
	extends RefCounted
	var opened := false
	var ids: Dictionary = {}
	func has(id: String) -> bool:
		return opened or ids.has(id)
	func set_flag(id: String, value: bool = true) -> void:
		if value:
			ids[id] = true
		else:
			ids.erase(id)


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


func test_authored_return_shortcuts_bind_only_their_exact_current_routes() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_world.json"))
	var bound := FIELD.bind_return_shortcuts(config)
	var reductions: Dictionary = {}
	for current: Dictionary in bound.currents:
		if current.has("reduction_unlock_flag"):
			reductions[str(current.route_id)] = current
	assert_eq(reductions.size(), 2)
	assert_eq(reductions["brine_steps_to_shellwatch_direct"].reduction_unlock_flag,
		"water_dock_shellwatch_residents_freed_and_pump_disabled")
	assert_eq(reductions["brine_steps_to_shellwatch_direct"].strength_after_unlock_m_s, 0.08)
	assert_eq(reductions["sluice_isle_to_deep_watch_direct"].reduction_unlock_flag,
		"water_dock_deep_watch_current_charted")
	assert_eq(reductions["sluice_isle_to_deep_watch_direct"].strength_after_unlock_m_s, 0.1)
	for current: Dictionary in bound.currents:
		if str(current.route_id) not in reductions:
			assert_false(current.has("reduction_unlock_flag"),
				"an unrelated current inherited a return reward")
	assert_false(JSON.stringify(bound.currents).contains("reedhaven_maintenance_ramp"),
		"the physical ramp is not treated as a current reduction")
	assert_false(config.currents[0].has("reduction_unlock_flag"),
		"binding does not mutate the authored input dictionary")


func test_live_and_restored_shortcut_flags_reduce_only_the_authored_current() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/water_world.json"))
	var flags := Flags.new()
	var shell := _authored_current(config, "brine_steps_to_shellwatch_direct")
	var deep := _authored_current(config, "sluice_isle_to_deep_watch_direct")
	var unrelated := _authored_current(config, "first_shore_to_reedhaven_direct")
	assert_false(shell.is_empty())
	assert_false(deep.is_empty())
	assert_false(unrelated.is_empty())
	var shell_field := FIELD.new({"currents": [shell], "return_shortcuts": config.return_shortcuts}, flags)
	var deep_field := FIELD.new({"currents": [deep], "return_shortcuts": config.return_shortcuts}, flags)
	var unrelated_field := FIELD.new({"currents": [unrelated], "return_shortcuts": config.return_shortcuts}, flags)
	var shell_at := _midpoint(shell)
	var deep_at := _midpoint(deep)
	var unrelated_at := _midpoint(unrelated)
	var shell_before: float = shell_field.sample(shell_at).velocity.length()
	var deep_before: float = deep_field.sample(deep_at).velocity.length()
	var unrelated_before: Vector3 = unrelated_field.sample(unrelated_at).velocity
	assert_true(is_equal_approx(shell_before, float(shell.strength_m_s)))
	assert_true(is_equal_approx(deep_before, float(deep.strength_m_s)))

	flags.set_flag("unrelated_world_flag")
	assert_true(is_equal_approx(shell_field.sample(shell_at).velocity.length(), shell_before))
	assert_true(is_equal_approx(deep_field.sample(deep_at).velocity.length(), deep_before))
	flags.set_flag("water_dock_shellwatch_residents_freed_and_pump_disabled")
	assert_true(is_equal_approx(shell_field.sample(shell_at).velocity.length(), 0.08))
	assert_true(is_equal_approx(deep_field.sample(deep_at).velocity.length(), deep_before))
	assert_eq(unrelated_field.sample(unrelated_at).velocity, unrelated_before)
	flags.set_flag("water_dock_deep_watch_current_charted")
	assert_true(is_equal_approx(deep_field.sample(deep_at).velocity.length(), 0.1))

	# The field retains the live authoritative flag store: removing an earned
	# flag changes the next sample without reconstruction.
	flags.set_flag("water_dock_shellwatch_residents_freed_and_pump_disabled", false)
	assert_true(is_equal_approx(shell_field.sample(shell_at).velocity.length(), shell_before))
	# A reconstructed field over already-loaded completion flags starts reduced.
	var loaded_flags := Flags.new()
	loaded_flags.set_flag("water_dock_deep_watch_current_charted")
	var restored := FIELD.new({"currents": [deep], "return_shortcuts": config.return_shortcuts}, loaded_flags)
	assert_true(is_equal_approx(restored.sample(deep_at).velocity.length(), 0.1))


func _authored_current(config: Dictionary, route_id: String) -> Dictionary:
	for current: Dictionary in config.currents:
		if str(current.get("route_id", "")) == route_id:
			return current.duplicate(true)
	return {}


func _midpoint(current: Dictionary) -> Vector3:
	var points: Array = current.polyline
	var a: Array = points[0]
	var b: Array = points[1]
	return Vector3((float(a[0]) + float(b[0])) * 0.5,
		(float(a[1]) + float(b[1])) * 0.5,
		(float(a[2]) + float(b[2])) * 0.5)
