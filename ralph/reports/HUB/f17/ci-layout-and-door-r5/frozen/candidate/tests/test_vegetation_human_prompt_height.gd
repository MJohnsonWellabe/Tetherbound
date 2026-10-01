extends "res://tests/test_case.gd"

const VEG := preload("res://scripts/world/vegetation.gd")
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
