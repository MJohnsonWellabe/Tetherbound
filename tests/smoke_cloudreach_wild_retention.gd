extends SceneTree

## Real production world and all authored sites. Site-to-site relocation is an
## explicit test fixture; the final short approach uses normal controller input.
## No progression, encounter tables, wild population or geometry is substituted.
const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var world: Node3D
var player: CharacterBody3D
var director: Node
var failures: Array[String] = []
var checks := 0
var player_layer := 0
var started_usec := 0


func _init() -> void:
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("WILD RETENTION: " + label)
	print("WILD RETENTION %s %s" % ["PASS" if condition else "FAIL", label])


func frames(count: int) -> void:
	for i in count:
		await physics_frame


func input(action: String, strength: float) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = strength > 0
	event.strength = strength
	Input.parse_input_event(event)


func release() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		input(action, 0)


func supported(wild: Node3D) -> bool:
	var support: Vector3 = director.call("_wild_support", wild.global_position,
		float(wild.call("body_radius")), wild)
	return support.is_finite() and absf(support.y-wild.global_position.y) < 0.8


func approach(wild: Node3D) -> bool:
	for i in 480:
		var offer: Dictionary = director.call("interaction_offer", player.global_position)
		if str(offer.get("label", "")).begins_with("Engage "):
			release()
			print("WILD RETENTION OFFER " + JSON.stringify({"label":offer.label,
				"player":str(player.global_position),"body":str(wild.global_position)}))
			return true
		var offset := wild.global_position - player.global_position
		offset.y = 0
		var local: Vector3 = (world.get_node("CameraRig").call("planar_basis") as Basis).inverse() * offset.normalized()
		input("move_right", maxf(local.x, 0)); input("move_left", maxf(-local.x, 0))
		input("move_back", maxf(local.z, 0)); input("move_forward", maxf(-local.z, 0))
		await physics_frame
	release()
	return false


func approach_start(wild: Node3D) -> Vector3:
	for distance in [9.0, 7.0]:
		for i in 16:
			var target: Vector3 = wild.global_position + Vector3(cos(i*TAU/16.0), 0, sin(i*TAU/16.0)) * distance
			var safe: Vector3 = director.call("_wild_support", target, 0.45, wild)
			if safe.is_finite() and director.call("_wild_path_supported", safe, wild.global_position, 0.45, wild):
				return safe
	return Vector3.INF


func _run() -> void:
	started_usec = Time.get_ticks_usec()
	var game := root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("save_system", SAVE.new("user://cloudreach_wild_retention_%d" % OS.get_process_id()))
	game.set("current_realm", "cloudreach")
	var member: RefCounted = SPECIES.spawn("sparkit")
	member.call("set_level", 25, PROGRESSION.config())
	game.get("party").call("add", member)
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	player_layer = player.collision_layer
	player.collision_layer = 0 # A relocating fixture cannot become a moving floor under a wild.
	director = world.get_node("EncounterDirector")
	await frames(12)
	print("WILD RETENTION STARTUP " + JSON.stringify({"boot_seconds":(Time.get_ticks_usec()-started_usec)/1000000.0,
		"world_seed":director.call("world_seed"),"fixture":"three site relocations; ordinary 60Hz wild physics; no encounter tables replaced"}))
	check(director.get("encounter_config").wild_sites.size() == 6, "all six actual authored sites remain configured")
	var resident_ids: Dictionary = {}
	for id in ["lower_cliff_foragers", "causeway_watch", "ravine_wind"]:
		var site: Dictionary = director.call("find_id", director.get("encounter_config").wild_sites, id)
		var raw: Array = site.position
		var centre := Vector3(raw[0], raw[1], raw[2])
		# Fixture relocation to the real resolved site, never moving its wilds.
		player.global_position = centre + Vector3.UP * 0.3
		player.velocity = Vector3.ZERO
		await frames(8)
		var members: Array = director.get("_site_members").get(id, [])
		check(members.size() == int(site.count), id + " admits every authored body")
		check(director.get("_site_spawned").has(id) and not director.get("_site_failures").has(id), id + " is a validated complete site")
		if members.size() != int(site.count):
			continue
		for wild: Node3D in members:
			check(supported(wild), str(wild.name) + " initial real floor supports footprint")
			resident_ids[str(wild.name)] = [wild.get_instance_id(), wild.get("instance").get_instance_id(), wild.get("home")]
			var chosen: Vector3 = director.call("_find_wild_spawn", wild, wild.get("home"), centre)
			check(chosen.is_finite() and chosen == director.call("_find_wild_spawn", wild, wild.get("home"), centre), str(wild.name) + " safe placement search is deterministic")
			print("WILD RETENTION SPAWN " + JSON.stringify({"site":id,"body":str(wild.name),
				"resolved_centre":str(centre),"position":str(wild.global_position),
				"home":str(wild.get("home")),"radius":wild.call("body_radius"),"species":wild.get("species_id"),"level":wild.get("instance").get("level")}))
		# Disable only the player's collision/motion while observing actual wild
		# physics for 30s. Otherwise a fixture parked on the tiny site can obstruct
		# a body or its 9m notice rule and falsely claim to have tested wandering.
		player.set_physics_process(false)
		player.collision_layer = 0
		player.global_position = centre + Vector3(0, 30, 0)
		for wild: Node3D in members:
			wild.set("_pause_left", 0.01)
		var moved := false
		for tick in 1800:
			await physics_frame
			if tick % 120 == 0:
				for wild: Node3D in members:
					if not supported(wild):
						check(false, str(wild.name) + " stayed on a real floor during wandering at " + str(wild.global_position))
					moved = moved or wild.global_position.distance_to(wild.get("home")) > 0.6
		check(moved, id + " actually wanders, not frozen at spawn")
		for wild: Node3D in members:
			check(supported(wild), str(wild.name) + " grounded after 30 seconds of live wandering")
		# The inherited invalid eighth-candidate fallback must stop in place.
		var first: Node3D = members[0]
		var original_check: Callable = first.get("_clearance_check")
		first.call("set_clearance_check", func(_at: Vector3) -> bool: return false)
		check(first.call("_pick_destination") == first.global_position, id + " rejects all-eight-invalid wander fallback")
		first.call("set_clearance_check", original_check)
		check(not director.call("_wild_destination_supported", centre + Vector3(500,0,500), first), id + " rejects unsupported disconnected target")
		# Recovery uses validated home, not the fallen Y or a lower stacked floor.
		first.global_position = (first.get("home") as Vector3) + Vector3.DOWN * 80
		director.call("_set_wild_active", first, true)
		check(supported(first) and first.global_position.distance_to(first.get("home")) < 0.8, id + " forced fall recovers same body at safe home")
		var safe_home: Vector3 = first.get("home")
		first.set("engaged", true)
		director.set("_engaged_with", first)
		first.global_position = safe_home + Vector3.DOWN * 15
		director.call("_set_wild_active", first, true)
		check(first.global_position.y < safe_home.y - 10, id + " active fight is never regrounded")
		first.set("engaged", false)
		director.set("_engaged_with", null)
		director.get("_faint_timers")[first] = 10.0
		director.call("_set_wild_active", first, true)
		check(first.global_position.y < safe_home.y - 10, id + " faint timer owns retention")
		director.get("_faint_timers").erase(first)
		var instance: RefCounted = first.get("instance")
		instance.set("fainted", true)
		director.call("_set_wild_active", first, true)
		check(first.global_position.y < safe_home.y - 10, id + " genuinely fainted instance is never regrounded")
		instance.set("fainted", false)
		director.get("_respawn_timers")[first] = 10.0
		director.call("_set_wild_active", first, true)
		check(first.global_position.y < safe_home.y - 10, id + " respawn timer owns retention")
		director.get("_respawn_timers").erase(first)
		director.get("_wild_gates")[first] = {"cloudreach_requires_flags":["test_wild_gate_never_earned"]}
		first.visible = false
		director.call("_set_wild_active", first, true)
		check(first.global_position.y < safe_home.y - 10 and not first.is_physics_processing(), id + " closed gate remains asleep")
		director.get("_wild_gates").erase(first)
		first.visible = true
		director.call("_set_wild_active", first, true)
		# Begin on the validated local route and use actual movement for Engage.
		var start := approach_start(first)
		check(start.is_finite(), id + " has a supported short approach outside Engage range")
		if not start.is_finite():
			continue
		player.global_position = start + Vector3.UP * 0.1
		player.velocity = Vector3.ZERO
		player.collision_layer = player_layer
		player.set_physics_process(true)
		await frames(4)
		input("creature_recall", 1)
		await frames(3)
		input("creature_recall", 0)
		await frames(8)
		check(director.call("ally_body") != null, id + " real recall input deploys owned creature")
		check(await approach(first), id + " offers real Engage through a short physical approach")
		if id == "ravine_wind":
			input("interact", 1)
			await frames(3)
			input("interact", 0)
			await frames(3)
			var manager: Node = world.get_node("CombatManager")
			var engaged: Node3D = director.get("_engaged_with")
			check(manager.call("is_fighting") and engaged != null, "actual Engage input starts production wild combat")
			if engaged != null:
				var battle_position := engaged.global_position
				engaged.global_position += Vector3.DOWN * 15 # Explicit fault injection, restored before physics.
				var injected := engaged.global_position
				director.call("_set_wild_active", engaged, false)
				director.call("_reground_if_fallen", engaged)
				check(engaged.global_position == injected and engaged.is_physics_processing(), "real active fight owns position and physics through retention checks")
				engaged.global_position = battle_position
				manager.call("_begin_resolve", "fled") # Test cleanup, not a combat-success claim.
				await frames(150)
		input("creature_recall", 1)
		await frames(3)
		input("creature_recall", 0)
		await frames(4)
		player.set_physics_process(false)
		player.collision_layer = 0
		player.global_position = centre + Vector3.UP * 300
		await frames(3)
		check(not first.is_physics_processing(), id + " sleeps beyond home activation distance")
		player.global_position = centre + Vector3.UP * 0.3
		player.set_physics_process(true)
		await frames(3)
		for wild: Node3D in members:
			var saved: Array = resident_ids[str(wild.name)]
			check(wild.get_instance_id() == saved[0] and wild.get("instance").get_instance_id() == saved[1]
				and wild.get("home") == saved[2], str(wild.name) + " wake retains body, creature instance and home without reroll")
	# Actual unsupported-spawn negative: rejected objects never enter residency.
	var before: int = director.get("_wild_creatures").size()
	var rejected: Node3D = director.call("spawn_wild", "sparkit", Vector3(15000,500,15000), {"name":"unsupported_negative", "level":19})
	check(rejected == null and director.get("_wild_creatures").size() == before, "unsupported real spawn is rejected, not retained")
	release()
	world.queue_free()
	await process_frame
	print("CLOUDREACH WILD RETENTION %s: %d checks, %d failures" % ["PASS" if failures.is_empty() else "FAIL", checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
