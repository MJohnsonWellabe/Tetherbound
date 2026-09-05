extends "res://tests/smoke_cloudreach_continuous.gd"

## Focused real-input traversal from the authored summit threshold along the
## production overlook-loop edge to its safe bivouac. One declared fixture
## position establishes the segment start; no position write follows it.


func _run() -> void:
	Engine.time_scale=8.0
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/summit-bivouac-regression"
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
	stage="summit_threshold_to_bivouac"
	await _frames(20)
	var camp: Node3D=physical.get_node("summit_bivouac")
	if await _navigate(camp.global_position):
		var previous_clock:=await _normal_input_clock("summit bivouac interaction")
		var day_before:=int(game.day)
		if await _interact(camp.get_node("Interactable"),"",false):
			await _frames(120)
			_require(int(game.day)==day_before+1,"Real camp input passed one night at summit bivouac")
		await _restore_route_clock(previous_clock)
	_release()
	print("CLOUDREACH SUMMIT BIVOUAC %s from=%s to=%s distance_m=%.1f"%[
		"FAIL" if failed else "PASS",start,player.global_position,distance_m])
	quit(1 if failed else 0)
