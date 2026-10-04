extends "res://tests/test_case.gd"

const VEG := preload("res://scripts/world/vegetation.gd")
const TREE_PROBE := preload("res://tools/_probe_scatter_tree_prompt_height.gd")
const TARGET := Vector3(45.44734573364258, -0.18858742713928223, -62.50096893310547)

func _exact_placement() -> Dictionary:
	# Preserve the exact failed producer input from bf0f38b203^'s bake, rather
	# than requiring a retired tree to reappear in F17's scoped village rebake.
	# The production spawner and both old/new contact distances still gate.
	return {"model": "res://assets/environment/stylized_nature/CommonTree_2.gltf",
		"position": TARGET, "yaw": 4.354415416717529, "scale": 1.598110499382019,
		"harvest_layer": "trees", "harvest_index": 320,
		"harvest_item": "wood", "harvest_amount": 2}

func test_exact_failed_baked_tree_spawns_reachable_prompt_without_radius_change() -> void:
	var placement := _exact_placement()
	assert_false(placement.is_empty())
	assert_eq(placement.harvest_layer, "trees")
	assert_eq(placement.harvest_index, 320)
	var vegetation := VEG.new()
	vegetation._mesh_ids[str(placement.model)] = 0
	vegetation._spawn_harvest_point(placement)
	var point: Node3D = vegetation._harvest_nodes["trees#320"]
	var prompt: Node3D = point.get_node("Interactable")
	assert_almost_eq(float(prompt.radius), 2.6, 0.00001)
	assert_eq(point.resource_item(), "wood")
	assert_eq(point.resource_amount(), 2)
	# Actual grounded contact measured by the native production-collider probe.
	var contact := Vector3(45.45166, -0.465704, -61.39447)
	var old := Vector3(placement.position) + Vector3.UP * (1.0 + float(placement.scale))
	var current := Vector3(placement.position) + prompt.position
	assert_true(contact.distance_to(old) > float(prompt.radius))
	assert_true(contact.distance_to(current) < float(prompt.radius))
	vegetation.free()


func test_recorded_terrain_wall_requests_horizontal_tangent_and_keeps_first_side() -> void:
	var first_normal := Vector3(-0.470884, 0.630212, 0.617333)
	var first := TREE_PROBE.bank_tangent(Vector3(0, 0, -1), first_normal)
	assert_almost_eq(first.length(), 1.0, 0.0001)
	assert_almost_eq(first.y, 0.0, 0.0001)
	assert_almost_eq(first.dot(first_normal), 0.0, 0.0001)
	assert_true(first.x < 0.0 and first.z < 0.0)
	var later_normal := Vector3(-0.237581, 0.669214, 0.704066)
	var later_wanted := Vector3(0.46911, 0, -0.88314)
	var later := TREE_PROBE.bank_tangent(later_wanted, later_normal, first)
	assert_almost_eq(later.dot(later_normal), 0.0, 0.0001)
	assert_true(later.dot(first) > 0.0, "the observed changing bank cannot flip the committed side")
	assert_true(later.x < 0.0 and later.z < 0.0)
	assert_eq(TREE_PROBE.BANK_TURN_FRAMES, 26)
	assert_eq(TREE_PROBE.MAX_BANK_TURNS, 3)


func test_terrain_tangent_refuses_no_heading_no_horizontal_normal_or_nonfinite_input() -> void:
	assert_eq(TREE_PROBE.bank_tangent(Vector3.ZERO, Vector3.LEFT), Vector3.ZERO)
	assert_eq(TREE_PROBE.bank_tangent(Vector3.FORWARD, Vector3.UP), Vector3.ZERO)
	assert_eq(TREE_PROBE.bank_tangent(Vector3(INF, 0, -1), Vector3.LEFT), Vector3.ZERO)
	assert_eq(TREE_PROBE.bank_tangent(Vector3.FORWARD, Vector3(INF, 0, 1)), Vector3.ZERO)

func test_measured_large_stone_spawns_a_reachable_human_height_prompt() -> void:
	var vegetation := VEG.new()
	var placement := _exact_placement()
	vegetation._mesh_ids[str(placement.model)] = 0
	placement.position = Vector3(90.78217, -7.178252, 95.62292)
	placement.scale = 1.476089
	placement.harvest_layer = "rocks"
	placement.harvest_index = 13261
	placement.harvest_item = "stone"
	vegetation._spawn_harvest_point(placement)
	var point: Node3D = vegetation._harvest_nodes["rocks#13261"]
	var prompt: Node3D = point.get_node("Interactable")
	assert_almost_eq(prompt.position.y, 1.4, 0.00001)
	assert_almost_eq(float(prompt.radius), 2.6, 0.00001)
	# Closest normal-input fan-out pose measured in the failed fresh run. The
	# old 1+scale anchor was 2.71m away, outside the unchanged 2.6m sphere.
	var contact := Vector3(89.23442, -6.874026, 95.15967)
	var old := Vector3(placement.position) + Vector3.UP * (1.0 + float(placement.scale))
	var current := Vector3(placement.position) + prompt.position
	assert_true(contact.distance_to(old) > float(prompt.radius))
	assert_true(contact.distance_to(current) < float(prompt.radius))
	vegetation.free()

func test_visual_scale_does_not_scale_the_human_interaction_anchor() -> void:
	var vegetation := VEG.new()
	var placement := _exact_placement()
	vegetation._mesh_ids[str(placement.model)] = 0
	var index := 0
	for item: String in ["wood", "stone"]:
		for scale_value: float in [0.6, 1.59811049938202, 2.1]:
			placement.harvest_item = item
			placement.scale = scale_value
			placement.harvest_index = index
			vegetation._spawn_harvest_point(placement)
			var point: Node3D = vegetation._harvest_nodes["trees#%d" % index]
			var prompt: Node3D = point.get_node("Interactable")
			assert_almost_eq(prompt.position.y, 1.4, 0.00001)
			assert_almost_eq(float(prompt.radius), 2.6, 0.00001)
			index += 1
	vegetation.free()


func _corridor_geometry() -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://ralph/reports/HUB/f17/tree-corridor-r23/native-failed/tree-geometry.json"))
	return data if data is Dictionary else {}


func _corridor_faces(data: Dictionary) -> PackedVector3Array:
	var faces := PackedVector3Array()
	for triangle: Array in data.mesh.triangle_indices:
		for index_value: Variant in triangle:
			var index := int(index_value)
			var vertex: Array = data.mesh.vertices[index]
			faces.append(Vector3(float(vertex[0]), float(vertex[1]), float(vertex[2])))
	return faces


func test_full_capsule_corridor_uses_adjacent_original_facets_and_refuses_direct_bank() -> void:
	var data := _corridor_geometry()
	assert_true(data.get("complete", false))
	if data.is_empty():
		return
	var faces := _corridor_faces(data)
	var target: Vector3 = TREE_PROBE.TARGET
	var start := Vector3(float(data.settled_start.position[0]), float(data.settled_start.position[1]),
		float(data.settled_start.position[2]))
	var radius := float(data.settled_start.player.shape_data.radius)
	var margin := float(data.settled_start.safe_margin)
	var angle := float(data.settled_start.floor_max_angle)
	var trunk_radius := float(data.trunk.shape_data.radius)
	var path := TREE_PROBE.tree_corridor(faces, start, target, radius, margin, angle, trunk_radius)
	assert_eq(faces.size(), 1176)
	assert_eq(path.size(), 7)
	assert_true(TREE_PROBE.corridor_clear(faces, path, target, radius + margin + 0.22, angle))
	assert_false(TREE_PROBE.corridor_clear(faces, PackedVector3Array([start, target + Vector3(0, 0, 1.12)]),
		target, radius + margin + 0.22, angle), "the full capsule still cannot cross the original steep bank")
	# A single 1m right triangle cannot contain a .4m disc (inradius .2929).
	# The valid swept corridor therefore requires the adjacent-facet union.
	assert_true(radius > (2.0 - sqrt(2.0)) * 0.5)
	assert_almost_eq(TREE_PROBE.CORRIDOR_WAYPOINT_RADIUS, 0.20, 0.000001)
	assert_almost_eq(TREE_PROBE.CORRIDOR_TRACKING_ALLOWANCE, 0.22, 0.000001)


func test_corridor_refuses_incomplete_discontinuous_or_obstructed_mesh() -> void:
	var data := _corridor_geometry()
	assert_true(data.get("complete", false))
	if data.is_empty():
		return
	var faces := _corridor_faces(data)
	var target: Vector3 = TREE_PROBE.TARGET
	var start := target + Vector3(0, 0, 4)
	var path := TREE_PROBE.tree_corridor(faces, start, target, 0.4, 0.001, 0.7854, 0.7190233469009399)
	assert_eq(path.size(), 7)
	var broken := faces.duplicate()
	broken.remove_at(broken.size() - 1)
	assert_false(TREE_PROBE.corridor_clear(broken, path, target, 0.621, 0.7854))
	broken = faces.duplicate()
	broken[0] = broken[3]
	assert_false(TREE_PROBE.corridor_clear(broken, path, target, 0.621, 0.7854))
	broken = faces.duplicate()
	broken[3] += Vector3(0, 0.1, 0)
	assert_false(TREE_PROBE.corridor_clear(broken, path, target, 0.621, 0.7854))
	broken = faces.duplicate()
	for index in broken.size():
		if Vector2(broken[index].x - target.x, broken[index].z - target.z) == Vector2(4, 4):
			broken[index].y += 4.0
	assert_false(TREE_PROBE.corridor_clear(broken, path, target, 0.621, 0.7854), "new steep facets block the route")
	assert_false(TREE_PROBE.corridor_clear(faces, PackedVector3Array([start, target + Vector3(7, 0, 4)]),
		target, 0.621, 0.7854))


func test_corridor_preserves_original_radius_margin_angle_and_fixed_spawn() -> void:
	var data := _corridor_geometry()
	assert_true(data.get("complete", false))
	if data.is_empty():
		return
	var faces := _corridor_faces(data)
	var target: Vector3 = TREE_PROBE.TARGET
	var start := target + Vector3(0, 0, 4)
	assert_eq(TREE_PROBE.tree_corridor(faces, start, target, 0.2, 0.001, 0.7854, 0.7190233469009399).size(), 0)
	assert_eq(TREE_PROBE.tree_corridor(faces, start, target, 0.4, 0.002, 0.7854, 0.7190233469009399).size(), 0)
	assert_eq(TREE_PROBE.tree_corridor(faces, start, target, 0.4, 0.001, 0.9, 0.7190233469009399).size(), 0)
	assert_eq(TREE_PROBE.tree_corridor(faces, start + Vector3.RIGHT, target, 0.4, 0.001, 0.7854, 0.7190233469009399).size(), 0)
	assert_eq(TREE_PROBE.tree_corridor(faces, start, target, 0.4, 0.001, 0.7854, 0.4).size(), 0)
	assert_eq(TREE_PROBE.tree_corridor(faces, start, target, INF, 0.001, 0.7854, 0.7190233469009399).size(), 0)
