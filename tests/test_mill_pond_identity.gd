extends "res://tests/test_case.gd"

const IDENTITY := preload("res://scripts/world/mill_pond_identity.gd")
const VILLAGE := preload("res://scripts/world/village.gd")


func test_pond_mill_builds_a_large_bank_facing_water_wheel() -> void:
	var identity: Node3D = IDENTITY.new()
	identity.call("build")
	assert_eq(identity.name, "PondMillIdentity")
	assert_true(identity.position.distance_to(Vector3(-4.3, 2.15, 0.0)) < 0.01,
		"the readable wheel drifted off the mill's west wall and stream race")
	assert_true(identity.get_node_or_null("Rim") != null,
		"the Pond mill has no readable circular rim")
	assert_true(identity.get_node_or_null("Axle") != null,
		"the Pond mill wheel has no axle connection to the building")
	assert_true(identity.get_node_or_null("WheelWash") != null,
		"the wheel no longer makes visible contact with the stream")

	var spokes := 0
	var paddles := 0
	for child: Node in identity.get_children():
		if child.name.begins_with("Spoke"):
			spokes += 1
		elif child.name.begins_with("Paddle"):
			paddles += 1
	assert_eq(spokes, 10, "the water wheel lost its radial spoke rhythm")
	assert_eq(paddles, 10, "the water wheel lost its working paddle rhythm")
	identity.free()


func test_village_routes_only_the_mill_to_the_pond_identity() -> void:
	var village: Node3D = VILLAGE.new()
	var mill := Node3D.new()
	village.call("_exterior_identity", mill, "mill")
	assert_true(mill.get_node_or_null("PondMillIdentity") != null,
		"the production village mill did not receive its working silhouette")

	var unrelated := Node3D.new()
	village.call("_exterior_identity", unrelated, "cottage_a")
	assert_eq(unrelated.get_child_count(), 0,
		"the Pond-specific identity leaked onto another village prefab")
	mill.free()
	unrelated.free()
	village.free()
