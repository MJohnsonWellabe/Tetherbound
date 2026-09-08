extends "res://tests/test_case.gd"

const VEG := preload("res://scripts/world/vegetation.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const TARGET := Vector3(45.44735, -0.188587, -62.50097)

func _exact_placement() -> Dictionary:
	var layers := {}
	BAKE._read_region(FileAccess.open("res://data/scatter/playground/region_0_-1.bin", FileAccess.READ), layers, {})
	for layer: String in layers:
		for record: Dictionary in layers[layer]:
			if record.placement.position.distance_to(TARGET) < 0.01:
				var placement: Dictionary = record.placement.duplicate(true)
				placement.harvest_layer = layer
				placement.harvest_index = int(record.order)
				placement.harvest_item = "wood"
				placement.harvest_amount = 2
				return placement
	return {}

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

func test_unprobed_stone_anchor_retains_existing_scale_rule() -> void:
	var vegetation := VEG.new()
	var placement := _exact_placement()
	vegetation._mesh_ids[str(placement.model)] = 0
	placement.harvest_item = "stone"
	vegetation._spawn_harvest_point(placement)
	var point: Node3D = vegetation._harvest_nodes["trees#320"]
	var prompt: Node3D = point.get_node("Interactable")
	assert_almost_eq(prompt.position.y, 1.0 + float(placement.scale), 0.00001)
	assert_almost_eq(float(prompt.radius), 2.6, 0.00001)
	vegetation.free()

func test_tree_visual_scale_does_not_scale_the_human_interaction_anchor() -> void:
	var vegetation := VEG.new()
	var placement := _exact_placement()
	vegetation._mesh_ids[str(placement.model)] = 0
	var index := 0
	for scale_value in [0.6, 1.59811049938202, 2.1]:
		placement.scale = scale_value
		placement.harvest_index = index
		vegetation._spawn_harvest_point(placement)
		var point: Node3D = vegetation._harvest_nodes["trees#%d" % index]
		var prompt: Node3D = point.get_node("Interactable")
		assert_almost_eq(prompt.position.y, 1.4, 0.00001)
		assert_almost_eq(float(prompt.radius), 2.6, 0.00001)
		index += 1
	vegetation.free()
