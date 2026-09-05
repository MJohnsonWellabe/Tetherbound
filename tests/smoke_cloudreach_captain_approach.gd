extends "res://tests/smoke_cloudreach_continuous.gd"

## The captain is a reused NPC who relocates after the summit threshold event.
## This fixture starts at that authored threshold, then uses the same central
## production approach as the continuous harness and presses the real challenge.


func _run() -> void:
	Engine.time_scale=8.0
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/captain-approach-regression"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm="cloudreach"
	for flag: String in ["realm_key_cloudreach","cloudreach_upper_route_unlocked","cloudreach_act_ii_complete","cloudreach_upper_anchors_disabled"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit","mudsnout","bramblebun","terrapup","brooktail"]:
		var member: RefCounted=SPECIES.spawn(species)
		member.set_level(25,PROGRESSION.config())
		game.party.add(member)
	world=SCENE.instantiate()
	root.add_child(world)
	current_scene=world
	player=world.get_node("Player")
	runtime=world.get_node("CloudreachRuntime")
	chapter=world.get_node("CloudreachChapter")
	physical=chapter.get_node("PhysicalRuntime")
	director=runtime.director
	manager=runtime.manager
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
		interaction_activations+=1
		last_activated_path=str(provider.get_path()))
	await _frames(20)
	var start:=Vector3(100.0,1160.06,5350.0)
	player.global_position=start
	player.velocity=Vector3.ZERO
	last_position=start
	physics_frame.connect(_record_frame)
	stage="captain_central_approach"
	await _frames(30)
	_require(_has("summit_extraction_engine_reached"),"Threshold event relocated the captain")
	var arena_origin:=_vec(runtime.finale.config.get("arena_origin",[100.0,1160.0,5450.0]))
	if not await _walk(arena_origin-Vector3(0.0,0.0,50.0)):
		quit(1)
		return
	if not await _walk(arena_origin+Vector3(3.0,0.0,0.0)):
		quit(1)
		return
	# Prove the same production approach is a real exit after the finale, then
	# re-enter before pressing the challenge.
	for exit_point: Vector3 in [arena_origin-Vector3(0.0,0.0,30.0),arena_origin-Vector3(0.0,0.0,50.0),Vector3(100.0,1160.0,5350.0)]:
		if not await _walk(exit_point):
			quit(1)
			return
	if not await _walk(arena_origin-Vector3(0.0,0.0,50.0)) or not await _walk(arena_origin+Vector3(3.0,0.0,0.0)):
		quit(1)
		return
	await _tap("creature_recall")
	await _frames(30)
	var prompt: Node3D=director.trainer_prompts["captain_veyra_storm_anchor"]
	if await _interact(prompt):
		await _frames(20)
		_require(director.trainer_battle_active(),"Actual challenge input started the captain battle")
	_release()
	print("CLOUDREACH CAPTAIN APPROACH %s from=%s to=%s distance_m=%.1f"%[
		"FAIL" if failed else "PASS",start,player.global_position,distance_m])
	quit(1 if failed else 0)
