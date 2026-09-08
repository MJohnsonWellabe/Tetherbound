extends SceneTree

## Read-only diagnosis of rejected Salt Crown road spawns in the production world.
## Explicit probe pose; this is footing evidence, not continuous-play acceptance.
const SAVE := preload("res://scripts/save/save_game.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const REPAIRED_IDS := [
	"road_visibility_salt_crown_exploration_spine_01",
	"road_visibility_salt_crown_exploration_spine_02",
	"road_visibility_salt_crown_exploration_spine_03",
	"road_visibility_salt_crown_exploration_spine_05",
]

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.save_system = SAVE.new("user://water_footing_probe_%d" % Time.get_ticks_usec())
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	while not world.shell_build_complete():
		await process_frame
	var director: Node = world.get_node("EncounterDirector")
	var player: Node3D = world.local_rig()
	# Freeze normal admission while collecting raw footprint evidence. This probe
	# starts on First Shore, so no Salt Crown site has been admitted yet.
	director.set_process(false)
	var road_sites: Array[Dictionary] = []
	for site: Dictionary in director.encounter_config.wild_sites:
		if not str(site.id).begins_with("road_visibility_salt_crown_exploration_spine_"):
			continue
		road_sites.append(site)
		var at := Vector3(site.position[0], site.position[1], site.position[2])
		var table: Dictionary = director.find_id(director.chapter.encounter_tables, str(site.table_id))
		var plans: Array = director.site_spawn_plans(site, table,
			director.encounter_config.named_encounters, director.world_seed())
		for plan: Dictionary in plans:
			var requested := Vector3(float(plan.position[0]), float(plan.position[1]),
				float(plan.position[2]))
			var body: Node3D = load("res://scenes/creatures/creature.tscn").instantiate()
			body.set_script(WILD)
			world.add_child(body)
			body.call("populate", str(plan.species), player)
			body.global_position = requested
			body.set_physics_process(false)
			var body_radius: float = body.body_radius()
			var footprint_radius := body_radius + 0.15
			var centre_support: Vector3 = director._wild_support(at, footprint_radius, body)
			var requested_support: Vector3 = director._wild_support(requested, footprint_radius, body)
			# These are the exact requested/centre arguments production passes to
			# spawn_wild -> _find_wild_spawn, including per-member spread.
			var safe: Vector3 = director._find_wild_spawn(body, requested, at)
			print("WATER_FOOTING ", JSON.stringify({"site": site.id, "species": plan.species,
				"member_index": plan.member_index, "centre": str(at), "requested": str(requested),
				"body_radius": body_radius, "footprint_radius": footprint_radius,
				"centre_support": str(centre_support), "requested_support": str(requested_support),
				"safe": str(safe), "centre_samples": _samples(world, body, at, footprint_radius),
				"requested_samples": _samples(world, body, requested, footprint_radius),
				"safe_samples": _samples(world, body, safe, footprint_radius) if safe.is_finite() else []}))
			body.free()

	# Then let the unchanged production admission path evaluate both members at
	# every repaired site. Explicit poses make this a diagnostic, not travel
	# acceptance; the spawn result itself is production state.
	director.set_process(true)
	for site: Dictionary in road_sites:
		var at := Vector3(float(site.position[0]), 0.0, float(site.position[2]))
		player.global_position = Vector3(at.x, world.ground_height_at(at.x, at.z) + 2.0, at.z)
		for frame in 30:
			await physics_frame
	var spawned: Dictionary = director.get("_site_spawned")
	var failed: Dictionary = director.get("_site_failures")
	var production_failures: Array[String] = []
	for site: Dictionary in road_sites:
		var id := str(site.id)
		var members: Array = director.get("_site_members").get(id, [])
		var ok := spawned.has(id) and not failed.has(id) and members.size() == int(site.count)
		print("WATER_PRODUCTION_SITE ", JSON.stringify({"site": id, "ok": ok,
			"spawned": spawned.has(id), "failed": failed.has(id), "members": members.size(),
			"expected": int(site.count)}))
		if not ok:
			production_failures.append(id)
	var route: Dictionary = _find_id(world.config.land_routes, "salt_crown_exploration_spine")
	var navigator := NAVIGATOR.new(self, player, world.local_camera_rig(), _send_stick)
	for site: Dictionary in road_sites:
		var id := str(site.id)
		if id not in REPAIRED_IDS:
			continue
		var crossing := _crossing_segment(site.position, route.get("polyline", []), world)
		var passable := not crossing.is_empty() and await _walk_segment(
			player, navigator, crossing.start, crossing.finish)
		print("WATER_PLAYER_PASS ", JSON.stringify({"site": id, "ok": passable,
			"start": str(crossing.get("start", Vector3.INF)),
			"finish": str(crossing.get("finish", Vector3.INF))}))
		if not passable:
			production_failures.append(id + ":player_pass")
	print("WATER_PRODUCTION_SUMMARY ", JSON.stringify({"sites": road_sites.size(),
		"failures": production_failures}))
	quit(0 if production_failures.is_empty() else 1)


func _samples(world: Node3D, body: Node3D, at: Vector3, radius: float) -> Array:
	var samples: Array = []
	var space := world.get_world_3d().direct_space_state
	var centre_height := float(world.ground_height_near(at))
	for i in 9:
		var offset := Vector3.ZERO if i == 0 else Vector3(cos((i - 1) * TAU / 8), 0,
			sin((i - 1) * TAU / 8)) * radius
		var point := at + offset
		var expected: float = world.ground_height_near(point)
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 1.6,
			point - Vector3.UP * 1.6)
		ray.exclude = [body.get_rid()]
		var hit: Dictionary = space.intersect_ray(ray)
		samples.append({"offset": str(offset), "expected": expected,
			"delta_from_centre": expected - centre_height,
			"hit_y": (hit.get("position", Vector3.INF) as Vector3).y,
			"normal_y": (hit.get("normal", Vector3.ZERO) as Vector3).y,
			"collider": str(hit.get("collider", "none"))})
	return samples


func _crossing_segment(raw: Array, polyline: Array, world: Node3D) -> Dictionary:
	if raw.size() < 3:
		return {}
	var point := Vector2(float(raw[0]), float(raw[2]))
	var best_distance := INF
	var best := Vector2.ZERO
	var tangent := Vector2.ZERO
	for index in maxi(0, polyline.size() - 1):
		var a := Vector2(float(polyline[index][0]), float(polyline[index][2]))
		var b := Vector2(float(polyline[index + 1][0]), float(polyline[index + 1][2]))
		var delta := b - a
		if delta.length_squared() < 0.001:
			continue
		var projected := a + delta * clampf((point - a).dot(delta) / delta.length_squared(), 0.0, 1.0)
		var distance := point.distance_to(projected)
		if distance < best_distance:
			best_distance = distance
			best = projected
			tangent = delta.normalized()
	if not is_finite(best_distance) or tangent == Vector2.ZERO:
		return {}
	var start_xz := best - tangent * 12.0
	var finish_xz := best + tangent * 12.0
	return {
		"start": Vector3(start_xz.x, world.ground_height_at(start_xz.x, start_xz.y) + 2.0, start_xz.y),
		"finish": Vector3(finish_xz.x, world.ground_height_at(finish_xz.x, finish_xz.y), finish_xz.y),
	}


func _walk_segment(player: CharacterBody3D, navigator: RefCounted, start: Vector3,
		finish: Vector3) -> bool:
	player.global_position = start
	player.velocity = Vector3.ZERO
	for frame in 12:
		await physics_frame
	var arrived: bool = await navigator.walk_to(finish, 1800, 1.3)
	_send_stick(0.0, 0.0)
	return arrived


func _find_id(rows: Array, id: String) -> Dictionary:
	for row: Dictionary in rows:
		if str(row.get("id", "")) == id:
			return row
	return {}


func _send_stick(x: float, y: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, y]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = pair[0]
		event.axis_value = clampf(float(pair[1]), -1.0, 1.0)
		Input.parse_input_event(event)
