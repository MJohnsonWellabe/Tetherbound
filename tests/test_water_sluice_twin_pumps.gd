extends "res://tests/test_case.gd"

const FIELD := preload("res://scripts/world/water_heightfield.gd")
const PUMPS := preload("res://scripts/world/water_sluice_twin_pumps.gd")


class GroundFixture:
	extends Node3D
	var config: Dictionary = {}
	var field: RefCounted
	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)


func test_twin_pumps_are_grounded_solid_and_leave_the_main_route_open() -> void:
	var config := FIELD.load_config()
	var world := GroundFixture.new()
	world.config = config
	world.field = FIELD.new(config)
	var pumps := PUMPS.new()
	world.add_child(pumps)
	pumps.build(world)
	assert_eq(pumps.get_child_count(), 2, "both named machines are present")
	var route: Dictionary = {}
	for candidate: Dictionary in config.land_routes:
		if str(candidate.id) == "sluice_isle_exploration_spine":
			route = candidate
			break
	assert_false(route.is_empty())
	for index in pumps.get_child_count():
		var pump := pumps.get_child(index) as Node3D
		assert_true(pump.get_node_or_null("ApprovedPumpStation") != null,
			"approved visible machine is mounted")
		var collision := pump.get_node_or_null("PumpFootprint/MeasuredPumpBounds") as CollisionShape3D
		assert_true(collision != null and collision.shape is BoxShape3D,
			"machine has a solid measured footprint")
		assert_true(pump.position.y > 1.0, "machine stands on dry sand")
		var point := Vector2(pump.position.x, pump.position.z)
		var nearest := INF
		for segment_index in route.polyline.size() - 1:
			var a: Array = route.polyline[segment_index]
			var b: Array = route.polyline[segment_index + 1]
			var closest := Geometry2D.get_closest_point_to_segment(point,
				Vector2(float(a[0]), float(a[2])), Vector2(float(b[0]), float(b[2])))
			nearest = minf(nearest, point.distance_to(closest))
		assert_true(nearest > 15.0, "route stays clear of the large pump footprint")
	world.free()
