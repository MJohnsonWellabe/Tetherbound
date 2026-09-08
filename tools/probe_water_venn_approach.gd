extends SceneTree

## Bounded production-world diagnostic for the authored Veilfall spine ->
## Officer Venn approach. The initial p3 pose is explicit diagnostic setup;
## every metre after it is ordinary player-controller movement.
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const ROUTE_ID := "veilfall_exploration_spine"
const TRAINER_ID := "water_trainer_venn"
const REQUIRED_FLAG := "water_dock_sluice_isle_both_controls_disabled"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.save_system = SAVE.new("user://water_venn_approach_%d/" % Time.get_ticks_usec())
	game.world.flags.set_flag(REQUIRED_FLAG)
	var aquaryn: RefCounted = SPECIES.spawn("water_aquaryn")
	aquaryn.set_level(60, PROGRESSION.config())
	game.local.party.add(aquaryn)
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
		_fail("Production Officer Venn body is absent")
		return
	var route := _find_id(world.config.get("land_routes", []), ROUTE_ID)
	var polyline: Array = route.get("polyline", [])
	if polyline.size() < 5:
		_fail("Veilfall exploration spine is absent or truncated")
		return
	var player: CharacterBody3D = world.local_rig()
	var camera: Node3D = world.local_camera_rig()
	var venn: Node3D = director.trainer_nodes[TRAINER_ID]
	var prompt: Node3D = director.trainer_prompts[TRAINER_ID]
	var p3 := _vector3(polyline[3])
	p3.y = world.ground_height_at(p3.x, p3.z) + 2.0
	player.global_position = p3
	player.velocity = Vector3.ZERO
	await _frames(16)
	await _tap("creature_recall")
	await _frames(30)
	if director.ally_body() == null:
		_fail("Controller deployment did not produce the expected active Aquaryn")
		return
	var nearest := _nearest_route_point(Vector2(venn.global_position.x, venn.global_position.z), polyline)
	var grade := _grade_profile(world, p3, venn.global_position)
	print("VENN_BASELINE ", JSON.stringify({"p3": str(p3), "venn": str(venn.global_position),
		"prompt": str(prompt.global_position), "route_distance_m": nearest.distance,
		"nearest_route": str(nearest.point), "direct_distance_m": p3.distance_to(venn.global_position),
		"grade": grade}))
	var navigator := NAVIGATOR.new(self, player, camera, _send_stick)
	var horizontal := Vector2(p3.x, p3.z).distance_to(Vector2(venn.global_position.x,
		venn.global_position.z))
	var arrived: bool = await navigator.walk_to(venn.global_position,
		maxi(1800, int(horizontal * 65.0)), 3.0)
	_send_stick(0.0, 0.0)
	await _frames(8)
	var offer: Dictionary = {}
	var offered_stance := -1
	var stance_arrived := false
	if arrived:
		# Match the continuous harness's production interaction path: the body
		# proves the hike target, then a grounded stance around the offset prompt
		# proves proximity and line of sight without moving either actor directly.
		for index in 8:
			var angle := TAU * float(index) / 8.0
			var at := prompt.global_position + Vector3(cos(angle), 0, sin(angle)) * 2.5
			at.y = world.ground_height_at(at.x, at.z) + 0.1
			stance_arrived = await navigator.walk_to(at, 1800, 1.0)
			_send_stick(0.0, 0.0)
			if not stance_arrived:
				break
			offer = prompt.interaction_offer(player.global_position)
			if not offer.is_empty():
				offered_stance = index
				break
	print("VENN_APPROACH ", JSON.stringify({"arrived": arrived,
		"player": str(player.global_position), "venn": str(venn.global_position),
		"remaining_m": player.global_position.distance_to(venn.global_position),
		"confined_resets": navigator.confined_resets(), "stance_arrived": stance_arrived,
		"offered_stance": offered_stance, "prompt_enabled": prompt.enabled, "offer": offer,
		"collision_context": _collision_context(player, venn.global_position)}))
	quit(0 if arrived and not offer.is_empty() else 1)


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


func _collision_context(player: CharacterBody3D, target: Vector3) -> Array[String]:
	var space := player.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 4.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	var found: Array[String] = []
	for sample: Dictionary in [{"label": "player", "at": player.global_position},
			{"label": "target", "at": target}]:
		query.transform = Transform3D(Basis.IDENTITY, sample.at)
		for hit: Dictionary in space.intersect_shape(query, 24):
			var collider: Object = hit.get("collider")
			if collider is Node:
				found.append("%s:%s" % [str(sample.label), str((collider as Node).get_path())])
	return found


func _find_id(rows: Array, id: String) -> Dictionary:
	for row: Dictionary in rows:
		if str(row.get("id", "")) == id:
			return row
	return {}


func _vector3(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)


func _frames(count: int) -> void:
	for frame in count:
		await physics_frame


func _send_stick(x: float, y: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, y]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = pair[0]
		event.axis_value = clampf(float(pair[1]), -1.0, 1.0)
		Input.parse_input_event(event)


func _fail(message: String) -> void:
	push_error(message)
	print("VENN_APPROACH ", JSON.stringify({"arrived": false, "failure": message}))
	quit(1)
