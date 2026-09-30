extends "res://tests/test_case.gd"

const VEG := preload("res://scripts/world/vegetation.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const TARGET := Vector3(45.44735, -0.188587, -62.50097)

func _exact_placement() -> Dictionary:
	# The F17 regional generation removed this old tree without recycling its
	# durable ID. Retain the actual measured b2ea placement as a historical
	# regression input; the test still runs the real production prompt builder.
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://tests/fixtures/historical_prompt_tree_b2ea1455.json"))
	assert_true(raw is Dictionary, "the measured historical record must exist")
	if not raw is Dictionary:
		return {}
	var fixture: Dictionary = raw
	assert_eq(str(fixture.get("source_commit", "")).substr(0, 8), "b2ea1455")
	assert_false(str(fixture.get("source_blob", "")).is_empty())
	var xyz: Array = fixture.get("position", [])
	assert_eq(xyz.size(), 3)
	if xyz.size() != 3:
		return {}
	var position := Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
	assert_true(position.distance_to(TARGET) < 0.01,
		"the regression must retain the exact originally measured tree")
	return {"position": position, "model": str(fixture.model),
		"yaw": float(fixture.yaw), "scale": float(fixture.scale),
		"harvest_layer": str(fixture.layer), "harvest_index": int(fixture.order),
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
