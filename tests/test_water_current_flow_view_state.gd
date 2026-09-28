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


func test_indexed_ribbon_grid_preserves_bent_route_edges_uvs_and_separate_current_strips() -> void:
	var first := _current()
	first.polyline = [[0.0, 0.0, 0.0], [0.0, 0.0, 4.0], [3.0, 0.0, 8.0]]
	first.width_m = 4.0
	var second := first.duplicate(true)
	second.id = "separate_current"
	second.route_id = "separate_route"
	second.polyline = [[30.0, 0.0, 0.0], [30.0, 0.0, 4.0], [33.0, 0.0, 8.0]]
	second.flow_direction_xz = [1.0, 0.0]
	# Four metres straight then five on a 3-4-5 diagonal: ten shared rows at
	# one-metre spacing. Test a configured grid and the eight-segment default.
	for across: int in [4, 8]:
		var config := {"segment_m": 1.0, "width_scale": 1.0, "lift_m": 0.05}
		if across == 4:
			config["across_segments"] = across
		var view := VIEW.new()
		view.build({"currents": [first, second]}, config, Flags.new())
		var arrays := view.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
		var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var row_width := across + 1
		var vertices_per_ribbon := 10 * row_width
		assert_eq(vertices.size(), 2 * vertices_per_ribbon,
			"neighbouring cells share vertices instead of duplicating triangle corners")
		assert_eq(indices.size(), 2 * 9 * across * 6, "every longitudinal/transverse cell has two indexed triangles")
		assert_almost_eq(view.extra_cull_margin, 1.0, 0.0001,
			"wave displacement has an extra metre of culling allowance")
		var attributes_ok := true
		for strip in 2:
			var base := strip * vertices_per_ribbon
			for row in 10:
				var centre := Vector3(float(strip) * 30.0, 0.05, float(row)) if row <= 4 \
					else Vector3(float(strip) * 30.0 + float(row - 4) * 0.6, 0.05, 4.0 + float(row - 4) * 0.8)
				var left := vertices[base + row * row_width]
				var right := vertices[base + row * row_width + across]
				assert_almost_eq(((left + right) * 0.5).distance_to(centre), 0.0, 0.0001,
					"the outer edges retain the authored centre trajectory through the bend")
				var normal := Vector3(-1, 0, 0) if row <= 4 else Vector3(-0.8, 0, 0.6)
				assert_almost_eq((right - left).dot(normal), 4.0, 0.0001,
					"joined boundaries stay two metres from each authored segment")
				for column in row_width:
					var index := base + row * row_width + column
					var fraction := float(column) / float(across)
					attributes_ok = attributes_ok and vertices[index].distance_to(left.lerp(right, fraction)) < 0.0001 \
						and uvs[index].distance_to(Vector2(fraction, float(row))) < 0.0001 \
						and uv2s[index].distance_to(Vector2(float(row) / 9.0, 0.0)) < 0.0001 \
						and colours[index] == colours[base]
		assert_true(attributes_ok, "interior rows retain interpolated positions, travelled UVs, end fades and current colour")
		assert_ne(colours[0], colours[vertices_per_ribbon], "separate flow directions survive in the shared surface")
		var topology_ok := true
		var used: Dictionary = {}
		for triangle in range(0, indices.size(), 3):
			var a := indices[triangle]
			var b := indices[triangle + 1]
			var c := indices[triangle + 2]
			used[a] = true
			used[b] = true
			used[c] = true
			if mini(a, mini(b, c)) < 0 or maxi(a, maxi(b, c)) >= vertices.size():
				topology_ok = false
				continue
			var strip_a := floori(float(a) / float(vertices_per_ribbon))
			var strip_b := floori(float(b) / float(vertices_per_ribbon))
			var strip_c := floori(float(c) / float(vertices_per_ribbon))
			topology_ok = topology_ok and strip_a == strip_b and strip_a == strip_c \
				and (vertices[b] - vertices[a]).cross(vertices[c] - vertices[a]).y > 0.00001
		assert_true(topology_ok, "triangles remain valid and face upward without joining different ribbons")
		assert_eq(used.size(), vertices.size(), "all submitted grid vertices participate in the indexed surface")
		view.free()


func test_production_width_currents_have_no_folded_triangles_at_one_metre_spacing() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	var config: Dictionary = rules.current_flow.duplicate(true)
	config.segment_m = 1.0
	config.across_segments = 8
	# Reproduce the reported 12.6 m First Shore strip, or a wider live setting.
	config.width_scale = maxf(0.7, float(config.get("width_scale", 0.7)))
	var view := VIEW.new()
	view.build(world, config, Flags.new())
	var arrays := view.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var folded := 0
	var smallest_area := INF
	for triangle in range(0, indices.size(), 3):
		var a := vertices[indices[triangle]]
		var b := vertices[indices[triangle + 1]]
		var c := vertices[indices[triangle + 2]]
		var signed_area := (b - a).cross(c - a).y
		smallest_area = minf(smallest_area, signed_area)
		if signed_area <= 0.00001:
			folded += 1
	assert_eq(folded, 0,
		"all production-width bend triangles face upward (smallest signed area %.6f)" % smallest_area)
	assert_eq(view.ribbon_count, (world.currents as Array).size(), "all authored current strips remain represented")
	# Check actual submitted corner vertices: fixing winding must not narrow
	# the inside edge, move a crossing, or silently omit a problematic bend.
	var first_vertex := 0
	for current: Dictionary in world.currents:
		var points: Array = current.polyline
		var corner_row := 0
		var half := float(current.width_m) * float(config.width_scale) * 0.5
		for corner in points.size():
			var at := Vector2(float(points[corner][0]), float(points[corner][2]))
			if corner > 0:
				var previous := Vector2(float(points[corner - 1][0]), float(points[corner - 1][2]))
				corner_row += maxi(1, ceili(previous.distance_to(at)))
			var left3 := vertices[first_vertex + corner_row * 9]
			var right3 := vertices[first_vertex + corner_row * 9 + 8]
			var left := Vector2(left3.x, left3.z)
			var right := Vector2(right3.x, right3.z)
			assert_almost_eq(((left + right) * 0.5).distance_to(at), 0.0, 0.003,
				"authored corner retained on " + str(current.route_id))
			for neighbour: int in [corner - 1, corner + 1]:
				if neighbour < 0 or neighbour >= points.size():
					continue
				var other := Vector2(float(points[neighbour][0]), float(points[neighbour][2]))
				var along := (other - at).normalized()
				var normal := Vector2(-along.y, along.x)
				assert_almost_eq(absf((left - at).dot(normal)), half, 0.003,
					"left boundary preserves the physical route's visual width")
				assert_almost_eq(absf((right - at).dot(normal)), half, 0.003,
					"right boundary preserves the physical route's visual width")
		first_vertex += (corner_row + 1) * 9
	assert_eq(first_vertex, vertices.size(), "coverage checks account for every production ribbon")
	view.free()


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
