extends SceneTree

## Bounded production-world diagnostic for the authored Brine Steps spine ->
## Keeper Tovin approach. The initial p3 pose is explicit diagnostic setup;
## every metre after it is ordinary player-controller movement. The candidate
## is deliberately fixed so baseline and repaired runs measure the same spot.
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const ROUTE_ID := "brine_steps_exploration_spine"
const TRAINER_ID := "water_trainer_tovin"
const REPAIR_FLAG := "water_dock_reedhaven_repaired"
const CANDIDATE_XZ := Vector2(395.0, 809.0)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.save_system = SAVE.new("user://water_tovin_approach_%d/" % Time.get_ticks_usec())
	game.reset_for_new_game()
	game.current_realm = "water"
	game.world.flags.set_flag(REPAIR_FLAG)
	var sparkit: RefCounted = SPECIES.spawn("sparkit")
	sparkit.set_level(44, PROGRESSION.config())
	game.local.party.add(sparkit)
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not world.shell_build_complete():
		_fail("Water world did not build within 90 seconds")
		return
	var director: Node = world.get_node("EncounterDirector")
	deadline = Time.get_ticks_msec() + 10000
	while not director.trainer_nodes.has(TRAINER_ID) and Time.get_ticks_msec() < deadline:
		await process_frame
	if not director.trainer_nodes.has(TRAINER_ID):
		_fail("Production Keeper Tovin body is absent")
		return
	var route := _find_id(world.config.get("land_routes", []), ROUTE_ID)
	var polyline: Array = route.get("polyline", [])
	if polyline.size() != 7:
		_fail("Brine Steps exploration spine is absent or truncated")
		return
	var player: CharacterBody3D = world.local_rig()
	var camera: Node3D = world.local_camera_rig()
	var arbiter: Node = world.get_node("InteractionArbiter")
	var tovin: Node3D = director.trainer_nodes[TRAINER_ID]
	var prompt: Node3D = director.trainer_prompts[TRAINER_ID]
	var p3 := _grounded(world, _vector3(polyline[3]), 2.0)
	var p4 := _grounded(world, _vector3(polyline[4]))
	var p5 := _grounded(world, _vector3(polyline[5]))
	var candidate := _grounded(world, Vector3(CANDIDATE_XZ.x, 0.0, CANDIDATE_XZ.y))
	var current_nearest := _nearest_route_point(Vector2(tovin.global_position.x,
		tovin.global_position.z), polyline)
	var candidate_nearest := _nearest_route_point(CANDIDATE_XZ, polyline)
	print("TOVIN_SURFACE ", JSON.stringify({
		"p3": str(p3), "p4": str(p4), "p5": str(p5),
		"tovin": str(tovin.global_position), "prompt": str(prompt.global_position),
		"current_route_distance_m": current_nearest.distance,
		"current_nearest_route": str(current_nearest.point),
		"current_direct_grade": _grade_profile(world, p3, tovin.global_position),
		"candidate": str(candidate), "candidate_route_distance_m": candidate_nearest.distance,
		"candidate_nearest_route": str(candidate_nearest.point),
		"candidate_grade_from_p5": _grade_profile(world, p5, candidate),
		"candidate_footprint": _footprint(world, player, candidate, 1.2),
		"candidate_to_departure_m": Vector2(candidate.x, candidate.z).distance_to(
			Vector2(float(polyline[6][0]), float(polyline[6][2]))),
	}))

	player.global_position = p3
	player.velocity = Vector3.ZERO
	await _frames(16)
	await _tap(&"creature_recall")
	for frame in 180:
		if director.ally_body() != null:
			break
		await physics_frame
	if director.ally_body() == null:
		_fail("Controller recall did not deploy the healthy Sparkit fixture")
		return
	var navigator := NAVIGATOR.new(self, player, camera, _send_stick)
	var legs: Array[Dictionary] = [
		{"label": "Brine spine p4", "target": p4},
		{"label": "Brine spine p5", "target": p5},
		{"label": "Tovin candidate", "target": candidate},
	]
	var walked: Array[Dictionary] = []
	var all_walks := true
	for leg: Dictionary in legs:
		var target: Vector3 = leg.target
		var horizontal := Vector2(player.global_position.x, player.global_position.z).distance_to(
			Vector2(target.x, target.z))
		var arrived: bool = await navigator.walk_to(target,
			maxi(1800, int(horizontal * 65.0)), 1.3)
		_send_stick(0.0, 0.0)
		await _frames(8)
		walked.append({"label": leg.label, "arrived": arrived,
			"player": str(player.global_position),
			"remaining_m": player.global_position.distance_to(target),
			"resets": navigator.confined_resets()})
		if not arrived:
			all_walks = false
			break

	var offer: Dictionary = {}
	var winner_matches := false
	var offered_stance := -1
	if all_walks and Vector2(tovin.global_position.x, tovin.global_position.z).distance_to(
			CANDIDATE_XZ) <= 0.25:
		for index in 8:
			var angle := TAU * float(index) / 8.0
			var at := prompt.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 2.5
			at = _grounded(world, at)
			var stance_arrived: bool = await navigator.walk_to(at, 1800, 1.0)
			_send_stick(0.0, 0.0)
			await _frames(8)
			if not stance_arrived:
				continue
			offer = prompt.interaction_offer(player.global_position)
			winner_matches = arbiter.call("winning_provider") == prompt
			if not offer.is_empty() and winner_matches:
				offered_stance = index
				break
	print("TOVIN_APPROACH ", JSON.stringify({
		"walked": walked, "all_walks": all_walks,
		"tovin_matches_candidate": Vector2(tovin.global_position.x,
			tovin.global_position.z).distance_to(CANDIDATE_XZ) <= 0.25,
		"offered_stance": offered_stance, "winner_matches": winner_matches,
		"prompt_enabled": prompt.enabled, "offer": offer,
		"player": str(player.global_position), "collision_context": _collision_context(player),
	}))
	quit(0 if all_walks and offered_stance >= 0 else 1)


func _grounded(world: Node3D, point: Vector3, clearance: float = 0.1) -> Vector3:
	point.y = world.ground_height_at(point.x, point.z) + clearance
	return point


func _grade_profile(world: Node3D, from: Vector3, to: Vector3) -> Dictionary:
	var horizontal := Vector2(from.x, from.z).distance_to(Vector2(to.x, to.z))
	var steps := maxi(1, ceili(horizontal))
	var previous: float = world.ground_height_at(from.x, from.z)
	var maximum_step := 0.0
	var over_24_deg := 0
	for index in range(1, steps + 1):
		var t := float(index) / float(steps)
		var x := lerpf(from.x, to.x, t)
		var z := lerpf(from.z, to.z, t)
		var height: float = world.ground_height_at(x, z)
		var rise := absf(height - previous)
		maximum_step = maxf(maximum_step, rise)
		if rad_to_deg(atan(rise)) > 24.0:
			over_24_deg += 1
		previous = height
	return {"sample_spacing_m": horizontal / float(steps), "max_step_m": maximum_step,
		"samples_over_24_deg": over_24_deg, "samples": steps}


func _footprint(world: Node3D, player: CharacterBody3D, at: Vector3,
		radius: float) -> Array[Dictionary]:
	var space := world.get_world_3d().direct_space_state
	var result: Array[Dictionary] = []
	for index in 9:
		var offset := Vector3.ZERO if index == 0 else Vector3(
			cos((index - 1) * TAU / 8.0), 0.0, sin((index - 1) * TAU / 8.0)) * radius
		var sample := at + offset
		var expected: float = world.ground_height_at(sample.x, sample.z)
		var ray := PhysicsRayQueryParameters3D.create(
			Vector3(sample.x, expected + 1.6, sample.z),
			Vector3(sample.x, expected - 1.6, sample.z))
		ray.exclude = [player.get_rid()]
		var hit: Dictionary = space.intersect_ray(ray)
		result.append({"offset": str(offset), "expected_y": expected,
			"delta_y": expected - (at.y - 0.1),
			"hit_y": (hit.get("position", Vector3.INF) as Vector3).y,
			"normal_y": (hit.get("normal", Vector3.ZERO) as Vector3).y,
			"collider": str(hit.get("collider", "none"))})
	return result


func _nearest_route_point(point: Vector2, polyline: Array) -> Dictionary:
	var best := Vector2.INF
	var distance := INF
	for index in polyline.size() - 1:
		var a := Vector2(float(polyline[index][0]), float(polyline[index][2]))
		var b := Vector2(float(polyline[index + 1][0]), float(polyline[index + 1][2]))
		var delta := b - a
		if delta.length_squared() < 0.001:
			continue
		var at := a + delta * clampf((point - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
		if point.distance_to(at) < distance:
			distance = point.distance_to(at)
			best = at
	return {"point": best, "distance": distance}


func _collision_context(player: CharacterBody3D) -> Array[String]:
	var space := player.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 4.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	query.transform = Transform3D(Basis.IDENTITY, player.global_position)
	var found: Array[String] = []
	for hit: Dictionary in space.intersect_shape(query, 24):
		var collider: Object = hit.get("collider")
		if collider is Node:
			found.append(str((collider as Node).get_path()))
	return found


func _find_id(rows: Array, id: String) -> Dictionary:
	for row: Dictionary in rows:
		if str(row.get("id", "")) == id:
			return row
	return {}


func _vector3(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)


func _send_stick(x: float, y: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, y]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = pair[0]
		event.axis_value = clampf(float(pair[1]), -1.0, 1.0)
		Input.parse_input_event(event)


func _fail(message: String) -> void:
	push_error(message)
	print("TOVIN_APPROACH ", JSON.stringify({"all_walks": false, "failure": message}))
	quit(2)
