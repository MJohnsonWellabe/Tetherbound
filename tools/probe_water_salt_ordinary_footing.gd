extends SceneTree

## Focused production-footing evidence for the three rejected Salt Crown
## ordinary ecology sites. Explicit player poses are diagnostic setup; this
## does not claim route continuity or visibility acceptance.
const SAVE := preload("res://scripts/save/save_game.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const TARGET_IDS: Array[String] = [
	"water_salt_crown_wild_011",
	"water_salt_crown_wild_012",
	"water_salt_crown_wild_013",
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.save_system = SAVE.new("user://water_salt_ordinary_footing_%d/" % Time.get_ticks_usec())
	game.reset_for_new_game()
	game.current_realm = "water"
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
	var player: Node3D = world.local_rig()
	director.set_process(false)
	var sites: Dictionary = {}
	var support_failures: Array[String] = []
	for site: Dictionary in director.encounter_config.get("wild_sites", []):
		if str(site.id) in TARGET_IDS:
			sites[str(site.id)] = site
	for id: String in TARGET_IDS:
		if not sites.has(id):
			_fail("Salt ordinary footing target is absent: " + id)
			return
		var site: Dictionary = sites[id]
		var centre := _vector3(site.position)
		var table: Dictionary = director.find_id(director.chapter.encounter_tables,
			str(site.table_id))
		var plans: Array = director.site_spawn_plans(site, table,
			director.encounter_config.named_encounters, director.world_seed())
		if plans.size() != int(site.count):
			_fail("Salt ordinary footing target has an invalid production plan: " + id)
			return
		# A fresh save chooses a new world seed. Admission must therefore fit
		# every species this table can legally roll, not merely today's plan.
		var species_ids: Array[String] = []
		for entry: Dictionary in table.get("entries", []):
			var species := str(entry.get("species_id", ""))
			if not species.is_empty() and species not in species_ids:
				species_ids.append(species)
		for species: String in species_ids:
			var body: Node3D = load("res://scenes/creatures/creature.tscn").instantiate()
			body.set_script(WILD)
			world.add_child(body)
			body.call("populate", species, player)
			body.global_position = centre
			body.set_physics_process(false)
			var footprint_radius := float(body.call("body_radius")) + 0.15
			var safe: Vector3 = director._find_wild_spawn(body, centre, centre)
			print("SALT_ORDINARY_FOOTING ", JSON.stringify({"site": id,
				"species": species, "rolled_now": plans.any(func(plan: Dictionary) -> bool:
					return str(plan.species) == species),
				"centre": str(centre), "safe": str(safe),
				"body_radius": body.call("body_radius"),
				"footprint_radius": footprint_radius,
				"samples": _samples(world, body, centre, footprint_radius),
				"nearest_supported": _nearest_supported(director, body, centre,
					footprint_radius)}))
			if not safe.is_finite():
				support_failures.append(id + ":" + species)
			body.free()

	# The unchanged production loop owns the actual admission verdict.
	director.set_process(true)
	for id: String in TARGET_IDS:
		var centre := _vector3((sites[id] as Dictionary).position)
		player.global_position = centre + Vector3.UP * 2.0
		for frame in 30:
			await physics_frame
	var spawned: Dictionary = director.get("_site_spawned")
	var failures: Dictionary = director.get("_site_failures")
	var rejected: Array[String] = support_failures.duplicate()
	for id: String in TARGET_IDS:
		var site: Dictionary = sites[id]
		var members: Array = director.get("_site_members").get(id, [])
		var ok := spawned.has(id) and not failures.has(id) and members.size() == int(site.count)
		print("SALT_ORDINARY_PRODUCTION ", JSON.stringify({"site": id, "ok": ok,
			"spawned": spawned.has(id), "failed": failures.has(id),
			"members": members.size(), "expected": int(site.count)}))
		if not ok:
			rejected.append(id)
	print("SALT_ORDINARY_SUMMARY ", JSON.stringify({"sites": TARGET_IDS.size(),
		"all_table_species_supported": support_failures.is_empty(),
		"failures": rejected}))
	quit(0 if rejected.is_empty() else 1)


func _nearest_supported(director: Node, body: Node3D, centre: Vector3,
		radius: float) -> Dictionary:
	# Diagnosis only. Production coordinates change only after a candidate is
	# reviewed against the authored island/route context and rerun through the
	# normal admission loop above.
	for raw_distance in [2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 16.0, 20.0]:
		var distance := float(raw_distance)
		for index in 16:
			var angle := TAU * float(index) / 16.0
			var raw: Vector3 = centre + Vector3(cos(angle), 0, sin(angle)) * distance
			var ground: float = director.realm_world.ground_height_at(raw.x, raw.z)
			var candidate := Vector3(raw.x, ground, raw.z)
			var supported: Vector3 = director._wild_support(candidate, radius, body)
			if supported.is_finite():
				return {"position": str(candidate), "supported": str(supported),
					"distance_m": distance, "angle_index": index,
					"samples": _samples(director.realm_world, body, candidate, radius)}
	return {}


func _samples(world: Node3D, body: Node3D, at: Vector3, radius: float) -> Array:
	var samples: Array = []
	var space := world.get_world_3d().direct_space_state
	var centre_height := float(world.ground_height_near(at))
	for index in 9:
		var offset := Vector3.ZERO if index == 0 else Vector3(
			cos((index - 1) * TAU / 8.0), 0, sin((index - 1) * TAU / 8.0)) * radius
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


func _vector3(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))


func _fail(message: String) -> void:
	push_error(message)
	print("SALT_ORDINARY_SUMMARY ", JSON.stringify({"failures": [message]}))
	quit(2)
