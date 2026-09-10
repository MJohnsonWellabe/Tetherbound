extends "res://tests/test_case.gd"

const SHRINE := preload("res://scripts/world/stormwood_heart_shrine.gd")


func test_stormwood_masonry_preserves_socket_state_and_collision() -> void:
	var shrine := SHRINE.new()
	shrine.setup("stormwood", "Spark of the Stormwood", "stormwood")
	shrine._build_visual()
	shrine._build_prompt()
	var shape := shrine.get_node("ShrineCollision").get_child(0) as CollisionShape3D
	assert_true(shape.shape is CylinderShape3D)
	assert_almost_eq(shape.shape.radius, 1.15)
	assert_almost_eq(shape.shape.height, 0.62)
	assert_almost_eq(shape.position.y, 0.31)
	assert_eq(shrine.get_node("WeatheredMasonry").get_child_count(), 16)
	for index in 4:
		assert_false((shrine.get_node("StandingStone%d" % (index + 1)) as MeshInstance3D).visible)
	var socket := shrine.get_node("HeartSocket") as MeshInstance3D
	assert_true(socket.material_override == shrine._socket_material)
	assert_true(shrine._socket_material.albedo_texture != null)
	shrine._set_visual(true, true, true)
	assert_true(shrine._heart_visual.visible)
	assert_true(shrine._socket_material.emission_enabled)
	assert_true(shrine._heart_light.visible)
	shrine._set_visual(false, false, false)
	assert_false(shrine._heart_visual.visible)
	assert_false(shrine._socket_material.emission_enabled)
	assert_false(shrine._heart_light.visible)
	shrine._build_relic_slots()
	for id: String in ["meadows", "cloudreach", "water"]:
		var companion := shrine.get_node("RelicSlot_" + id)
		assert_eq(companion.get_script(), SHRINE)
		assert_true(companion.get("_companion_slot"))
		assert_eq(companion.call("realm"), "stormwood")
	shrine.free()
