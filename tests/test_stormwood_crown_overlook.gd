extends "res://tests/test_case.gd"

## r41 Crown Overlook deck: it stands clear of every route corridor, its
## ramp reaches back toward the Crown Sightline path, and its colliders are
## built on a simulation shell with nothing drawn.
const OVERLOOK := preload("res://scripts/world/stormwood_crown_overlook.gd")


class FixtureWorld extends Node3D:
	var simulation_only := true

	func ground_height_at(_x: float, _z: float) -> float:
		return 48.0


func _deck() -> Dictionary:
	return ((JSON.parse_string(FileAccess.get_file_as_string(OVERLOOK.CONFIG)) as Dictionary).deck as Dictionary).duplicate(true)


func test_deck_clears_route_corridors_and_ramps_to_the_path() -> void:
	var world := FixtureWorld.new()
	var cfg := _deck()
	var frame := OVERLOOK.deck_frame(world, cfg)
	var half: Array = cfg.half_m
	var routes: Array = (JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_world.json")) as Dictionary).routes
	var corridor := float((JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_stormwood.json")) as Dictionary).route_half_width) + 1.0
	for u: float in [-1.0, 0.0, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var p3 := frame * Vector3(float(half[0]) * u, 0.0, float(half[1]) * v)
			var p := Vector2(p3.x, p3.z)
			for route: Dictionary in routes:
				var points: Array = route.points
				for i in range(1, points.size()):
					var a := Vector2(float(points[i - 1][0]), float(points[i - 1][1]))
					var b := Vector2(float(points[i][0]), float(points[i][1]))
					assert_true(p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) >= corridor,
						"deck point %s keeps %.1f m from %s" % [p, corridor, route.id])
	var foot3 := frame * Vector3(0.0, 0.0, -float(half[1]) - float(cfg.ramp_m))
	var spot := Vector2(160.0, 1980.0)
	assert_true(Vector2(foot3.x, foot3.z).distance_to(spot) < Vector2(frame.origin.x, frame.origin.z).distance_to(spot),
		"the ramp foot lies toward the Crown Overlook path vertex")
	world.free()


func test_colliders_build_on_a_simulation_shell() -> void:
	var world := FixtureWorld.new()
	var cfg := _deck()
	var root := OVERLOOK.build_deck(world, cfg, false)
	var body := root.find_child("CrownOverlookDeckBody", true, false) as StaticBody3D
	assert_true(body != null and body.get_child_count() >= 6, "floor, ramp, rails and posts collide")
	assert_eq(root.find_children("*", "MeshInstance3D", true, false).size(), 0, "nothing drawn on a simulation shell")
	assert_true(absf(root.position.y - (48.0 + float(cfg.height_m))) < 0.01, "deck floor height_m above the ground")
	assert_true(float(cfg.height_m) < 4.0, "the F41 capture finds the deck floor (it probes from 4 m above the ground)")
	world.free()
