extends "res://tests/test_case.gd"

const VIEW := preload("res://scripts/world/water_current_flow_view.gd")
const FIELD := preload("res://scripts/world/water_current_field.gd")
const RESTORED := "water_currents_restored"

class Flags:
	extends RefCounted
	var ids: Dictionary = {}
	func has(id: String) -> bool:
		return bool(ids.get(id, false))

class World:
	extends RefCounted
	var flags: RefCounted

class GameFixture:
	extends Node
	var world: RefCounted


func test_pure_view_state_matches_physics_for_each_unlock_and_liberation_combination() -> void:
	var current := _current()
	current.required_unlock_flag = "lesson"
	current.closed_strength_m_s = 6.0
	current.reduction_unlock_flag = "return_route"
	current.strength_after_unlock_m_s = 0.08
	current.flow_direction_xz = [3.0, -4.0]
	var original := current.duplicate(true)
	var flags := Flags.new()
	var field := FIELD.new({"currents": [current]}, flags)
	for facts: Dictionary in [{}, {"lesson": true}, {"return_route": true},
			{"lesson": true, "return_route": true}, {RESTORED: true},
			{"lesson": true, RESTORED: true}, {"lesson": true, "return_route": true, RESTORED: true}]:
		flags.ids = facts
		var expected: Vector3 = field.sample(Vector3(0, 0, 50), flags.has(RESTORED)).velocity
		var actual := VIEW.effective_flow(current, facts)
		assert_almost_eq(actual.distance_to(expected), 0.0, 0.00001,
			"visual adapter follows the live physics rule, including reduction precedence")
	assert_eq(current, original, "the view adapter never modifies current gameplay data")


func test_production_binding_preserves_optional_routes_and_applies_exact_return_reductions() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var traversal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	var original := world.duplicate(true)
	var currents := VIEW.configured_currents(world, traversal)
	var flags := Flags.new()
	var lesson_routes := 0
	var optional_routes := 0
	var reductions := 0
	for current: Dictionary in currents:
		var id := str(current.route_id)
		var authored: Dictionary = {}
		for row: Dictionary in world.currents:
			if str(row.route_id) == id:
				authored = row
		assert_eq(current.polyline, authored.polyline, "binding preserves the authored trajectory")
		assert_eq(current.flow_direction_xz, authored.flow_direction_xz, "binding preserves adverse flow direction")
		if id.begins_with("first_shore_to_reedhaven_"):
			lesson_routes += 1
			assert_almost_eq(VIEW.effective_flow(current, {}).length(), 6.0, 0.00001,
				"closed First Shore routes visibly use the existing six-metre-per-second push")
			assert_almost_eq(VIEW.effective_flow(current, {"water_swim_lesson_complete": true}).length(),
				float(authored.strength_m_s), 0.00001, "the shared lesson flag restores authored calm flow")
		if id.begins_with("first_shore_to_lantern_cove_"):
			optional_routes += 1
			assert_false(current.has("required_unlock_flag"), "the optional crossing remains available")
			assert_almost_eq(VIEW.effective_flow(current, {}).length(), float(authored.strength_m_s), 0.00001)
		if current.has("reduction_unlock_flag"):
			reductions += 1
			flags.ids = {str(current.reduction_unlock_flag): true}
			var field := FIELD.new({"currents": [current]}, flags)
			var points: Array = current.polyline
			var a: Array = points[0]
			var b: Array = points[1]
			var at := Vector3((float(a[0]) + float(b[0])) * 0.5, 0,
				(float(a[2]) + float(b[2])) * 0.5)
			assert_almost_eq(VIEW.effective_flow(current, flags.ids).distance_to(field.sample(at).velocity),
				0.0, 0.00001, "exact-route return reductions use the same result as physics")
	assert_eq(lesson_routes, 2, "both First Shore crossing choices are covered")
	assert_eq(optional_routes, 2, "both optional Lantern Cove trajectories are covered")
	assert_eq(reductions, 2, "both authored return-current rewards are covered")
	assert_eq(world, original, "production visual binding leaves world config unchanged")


func test_live_unlock_reload_and_restoration_change_actual_renderer_motion_once() -> void:
	var flags := Flags.new()
	var view := VIEW.new()
	var current := _current()
	var world := {"currents": [current], "docks": [
		{"outbound_edge": "crossing", "unlock_flag": "lesson"}], "terrain": {"sea_level_m": 0.0}}
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	view.build(world, config.current_flow, flags)
	var traversal: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_swimming.json"))
	var bound: Dictionary = VIEW.configured_currents(world, traversal)[0]
	var field := FIELD.new({"currents": [bound]}, flags)
	_check_rendered_velocity(view, field.sample(Vector3(0, 0, 50)).velocity)
	assert_true(view.is_in_group("progression_restore"), "load/rejoin can refresh the presentation")
	var closed_mesh: Mesh = view.mesh
	flags.ids["unrelated"] = true
	view.call("_process", 1.0)
	assert_eq(view.mesh, closed_mesh, "unrelated world flags do not rebuild current geometry")
	flags.ids["lesson"] = true
	view.call("_process", 1.0)
	assert_ne(view.mesh, closed_mesh, "the lesson flag updates the visible strip")
	_check_rendered_velocity(view, field.sample(Vector3(0, 0, 50)).velocity)
	flags.ids[RESTORED] = true
	view.call("_process", 1.0)
	_check_rendered_velocity(view, field.sample(Vector3(0, 0, 50), true).velocity)
	var material := view.material_override as ShaderMaterial
	assert_almost_eq(float(material.get_shader_parameter("calm_scale")),
		float(config.current_flow.restored_calm_scale), 0.00001,
		"final restoration still softens foam opacity while motion follows physics")
	# Restoring a different save swaps the store itself, including lost flags.
	var replacement := Flags.new()
	var host := GameFixture.new()
	var restored_world := World.new()
	restored_world.flags = replacement
	host.world = restored_world
	view.restore_progression_from_game(host)
	var reloaded_field := FIELD.new({"currents": [bound]}, replacement)
	_check_rendered_velocity(view, reloaded_field.sample(Vector3(0, 0, 50)).velocity)
	replacement.ids["lesson"] = true
	view.call("_process", 1.0)
	_check_rendered_velocity(view, reloaded_field.sample(Vector3(0, 0, 50)).velocity)
	assert_eq(view.ribbon_count, 1, "refresh replaces the ribbon rather than duplicating it")
	view.free()
	host.free()


func _check_rendered_velocity(view: MeshInstance3D, expected: Vector3) -> void:
	assert_eq(view.mesh.get_surface_count(), 1, "the flow view remains a single mesh surface")
	var colours: PackedColorArray = view.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var encoded := colours[0]
	var material := view.material_override as ShaderMaterial
	var speed := maxf(float(material.get_shader_parameter("min_speed_m_s")),
		encoded.b * float(material.get_shader_parameter("speed_scale"))) \
		* float(material.get_shader_parameter("calm_scale"))
	# Vertex colour packing can quantize strength by up to 6/255 m/s.
	assert_almost_eq(speed, expected.length(), 0.025,
		"submitted shader motion matches physics, with no minimum-speed or double-liberation error")
	var direction := Vector3(encoded.r * 2.0 - 1.0, 0, encoded.g * 2.0 - 1.0).normalized()
	assert_true(direction.dot(expected.normalized()) > 0.999,
		"foam drifts in the actual adverse direction")


func _current() -> Dictionary:
	return {"id": "crossing_sheltered_current", "route_id": "crossing_sheltered",
		"polyline": [[0.0, 0.0, 0.0], [0.0, 0.0, 100.0]], "width_m": 20.0,
		"edge_blend_m": 2.0, "flow_direction_xz": [0.0, -1.0], "strength_m_s": 0.35,
		"post_liberation_strength_multiplier": 0.25}
