extends "res://tests/smoke_cloudreach_continuous.gd"

## ISOLATED REGRESSION, not chapter acceptance. Readiness flags and the initial
## camp position are declared fixtures. Movement camp→launch and both service
## inputs use the production controller, floor collision and interaction arbiter.
## The override below never writes the continuous acceptance event payload.
func _run() -> void:
	Engine.time_scale = 4.0
	Engine.physics_ticks_per_second = 240
	Engine.max_physics_steps_per_frame = 32
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://cloudreach_aerie_services_regression")
	game.current_realm = "cloudreach"
	for flag: String in ["realm_key_cloudreach", "cloudreach_chapter_started", "cloudreach_crisis_learned", "cloudreach_lower_anchors_investigated", "defeated_cloudreach_senn", "causeway_survivors_reconnected", "completed_cloudreach_maela_trial_battle", "windscar_aerie_prepared", "cloudreach_act_i_complete"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		game.party.add(SPECIES.spawn(species))
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	manager = runtime.manager
	director = runtime.director
	fly = player.fly_controller
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
		interaction_activations += 1
		last_activated_path = str(provider.get_path()))
	await _frames(20)
	var camp: Node3D = physical.get_node("windscar_flight_aerie_camp")
	var launch: Node3D = physical.get_node("flight_trial_start")
	var repair: Node3D = physical.get_node("aerie_repair")
	var maela: Node3D = chapter.npc_bodies().keeper_maela
	for other: Node3D in [launch, repair, maela]:
		_require(camp.global_position.distance_to(other.global_position) >= 7.0, "Camp separated from " + other.name)
	for spot: Node3D in [camp, launch]:
		var ray := PhysicsRayQueryParameters3D.create(spot.global_position + Vector3.UP * 3.0, spot.global_position - Vector3.UP * 3.0, 1, [player.get_rid()])
		var hit := player.get_world_3d().direct_space_state.intersect_ray(ray)
		_require(not hit.is_empty() and absf((hit.position as Vector3).y - spot.global_position.y) < 0.5, "Actual floor under " + spot.name)
		if not hit.is_empty(): _log("floor", {"site":spot.name,"position":str(hit.position),"collider":str(hit.collider.get_path())})
	if failed: return _end_regression()
	# The only player-position fixture. Every subsequent metre uses input.
	player.global_position = camp.global_position + Vector3.UP * 0.2
	player.velocity = Vector3.ZERO
	await _frames(30)
	if not _require(player.is_on_floor(),"Camp fixture settles on its actual floor"): return _end_regression()
	var day_before: int = game.day
	if not await _interact(camp.get_node("Interactable"),"",false): return _end_regression()
	# The real service passes the night halfway through its 1.6-second fade.
	await _frames(120)
	if not _require(game.day == day_before + 1,"Real camp input rests once"): return _end_regression()
	if not await _walk(launch.global_position,0.4): return _end_regression()
	if not await _interact(launch.get_node("Interactable"),"",false): return _end_regression()
	_require(physical.trial_active,"Real input starts trial at the launch center")
	_require(not game.progression.has("fly_traversal_unlocked"),"Starting trial alone does not unlock Fly")
	_end_regression()


func _log(kind: String, details: Dictionary = {}) -> void:
	if kind in ["assertion", "FAIL", "floor", "input_interact"]:
		print("CLOUDREACH AERIE SERVICES " + kind + " " + JSON.stringify(details))


func _end_regression() -> void:
	_release()
	print("CLOUDREACH AERIE SERVICES %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
