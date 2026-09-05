extends "res://tests/smoke_cloudreach_continuous.gd"

## Focused production-world regression for the grounded Old Wind Observatory
## join. This declared fixture seeds only the prerequisite flags before the
## scene exists. The player then starts at Cloudreach's normal realm entry and
## uses ordinary stick input over the complete grounded route to the exact
## direction that failed continuous play. There are no post-spawn position
## writes, flag writes, Fly, or interaction shortcuts.


func _run() -> void:
	start_usec = Time.get_ticks_usec()
	root.size = Vector2i(1280, 800)
	root.content_scale_size = Vector2i(1920, 1200)
	accelerated = true
	output_dir = OUTPUT_ROOT + "/observatory-join-regression"
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.save_system = SAVE.new("user://cloudreach_observatory_join_fixture")
	for flag: String in ["realm_key_cloudreach", "cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(25, PROGRESSION.config())
		game.party.add(member)
	game.current_realm = "cloudreach"
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	physics_frame.connect(_record_frame)
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
		interaction_activations += 1
		last_activated_path = str(provider.get_path()))
	await _frames(20)
	stage = "grounded_observatory_join"
	_log("fixture_precondition", {"description":"Prerequisites declared before scene creation; normal Cloudreach entry; no post-spawn position/flag writes",
		"entry_position":str(player.global_position)})
	if not await _navigate(Vector3(430.0, 920.0, 4500.0)):
		return _finish_join()
	if not await _physical_action("upper_anchor_east", "storm_anchor_upper_east_disabled", false):
		return _finish_join()
	_require(player.is_on_floor(), "Player remains grounded on the observatory crown")
	_finish_join()


func _finish_join() -> void:
	_release()
	_write_report()
	print("CLOUDREACH OBSERVATORY JOIN %s position=%s distance_m=%.1f" % [
		"FAIL" if failed else "PASS", str(player.global_position), distance_m])
	quit(1 if failed else 0)
