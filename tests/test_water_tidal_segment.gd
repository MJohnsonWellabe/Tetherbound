extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_tidal_segment.gd")


func test_alpha_center_is_occupied_and_challenge_stance_clears_capsules() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var alpha: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_alpha.json"))
	var center := Vector3(alpha.placement.spawn[0], 0.0, alpha.placement.spawn[1])
	var approach := Vector3.ZERO
	for route: Dictionary in world.land_routes:
		if route.id == "tidal_cradle_exploration_spine":
			assert_eq(Vector2(route.polyline[3][0], route.polyline[3][2]), Vector2(center.x, center.z),
				"negative control: the former waypoint is exactly the colliding Alpha's center")
			approach = Vector3(route.polyline[2][0], 0.0, route.polyline[2][2])
	var look: Dictionary = preload("res://scripts/creatures/creature_species.gd").placeholder("water_aquaryn")
	var player := preload("res://scenes/player/player.tscn").instantiate()
	var player_radius := float((player.get_node("Collision") as CollisionShape3D).shape.radius)
	var radii := float(look.radius) + player_radius
	assert_true(2.5 - 1.0 < radii, "old generic stance tolerance can overlap the physical capsules")
	var stance := SEGMENT.alpha_challenge_stance(center, approach, float(look.radius), player_radius)
	assert_almost_eq(stance.distance_to(center) - 1.0, radii, 0.001)
	assert_true(stance.distance_to(center + Vector3.UP * 2.0) < float(alpha.authority.prompt_radius_m))
	assert_true((stance - center).normalized().dot((approach - center).normalized()) > 0.999,
		"approach stays on the near side of the obstacle")
	assert_false(SEGMENT.alpha_challenge_stance(center, center, float(look.radius), player_radius).is_finite())
	print("Aquaryn radius=", look.radius, " player radius=", player_radius, " stance distance=", stance.distance_to(center))
	player.free()


func test_next_crossing_requires_earned_shellwatch_gate() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var route: Dictionary = {}
	for row: Dictionary in world.water_routes:
		if str(row.id) == SEGMENT.TIDAL_ROUTE:
			route = row
	assert_true(SEGMENT.tidal_route_contract(route))
	var wrong_gate := route.duplicate(true)
	wrong_gate.required_departure_flag = "water_dock_brine_steps_trial_won"
	assert_false(SEGMENT.tidal_route_contract(wrong_gate))
	var wrong_mode := route.duplicate(true)
	wrong_mode.intended_traversal = "mounted_swimming"
	assert_false(SEGMENT.tidal_route_contract(wrong_mode))


func test_unrun_helper_cannot_claim_alpha_recipe_completion() -> void:
	var helper := SEGMENT.new()
	assert_false(helper.result().ok)
	assert_false(SEGMENT.verdict(false, []))
	assert_false(SEGMENT.verdict(true, ["Iona did not open"]))
