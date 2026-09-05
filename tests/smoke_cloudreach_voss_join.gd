extends "res://tests/smoke_cloudreach_continuous.gd"

## Focused fixture for the production summit-road/Voss-yard join. The sole
## setup placement starts on the authored road endpoint. From there, traversal
## and the challenge use ordinary controller input; there are no later warps.


func _run() -> void:
	Engine.time_scale=8.0
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/voss-join-regression"
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
	var yard: Node3D=world.get_node("CloudreachBattleYards/officer_voss_summit_approach_yard")
	var road: Vector3=yard.get_meta("road_entry")
	# Declared initial fixture placement only. No position write follows it.
	player.global_position=road+Vector3.UP*0.2
	player.velocity=Vector3.ZERO
	last_position=player.global_position
	physics_frame.connect(_record_frame)
	await _frames(20)
	var body: Node3D=director.trainer_nodes["officer_voss_summit_approach"]
	var prompt: Node3D=director.trainer_prompts["officer_voss_summit_approach"]
	stage="voss_route_join"
	if not await _walk(body.global_position+Vector3(3,0,0)):
		return _finish_join(road)
	if director.ally_body()==null:
		await _tap("creature_recall")
	await _frames(30)
	if not await _interact(prompt):
		return _finish_join(road)
	_require(director.trainer_battle_active(),"Real challenge input started Officer Voss")
	_finish_join(road)


func _finish_join(road: Vector3) -> void:
	_release()
	print("CLOUDREACH VOSS JOIN %s from=%s to=%s distance_m=%.1f"%[
		"FAIL" if failed else "PASS",road,player.global_position,distance_m])
	quit(1 if failed else 0)
