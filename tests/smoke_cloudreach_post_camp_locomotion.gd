extends "res://tests/smoke_cloudreach_continuous.gd"

## Reproduces the clean replay's exact post-rest uphill summit-loop segment.
## One declared fixture position places the player at the authored bivouac;
## recovery and all subsequent travel use actual controller input.


func _run() -> void:
	start_usec=Time.get_ticks_usec()
	accelerated=true
	live_combat=true
	Engine.time_scale=8.0
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/post-camp-locomotion-regression"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm="cloudreach"
	for flag: String in ["realm_key_cloudreach","realm_heart_meadows_earned",
			"cloudreach_upper_route_unlocked","cloudreach_act_ii_complete",
			"cloudreach_upper_anchors_disabled","defeated_cloudreach_officer_voss_summit_approach"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit","mudsnout","bramblebun","terrapup","brooktail"]:
		var member: RefCounted=SPECIES.spawn(species)
		member.set_level(25,PROGRESSION.config())
		game.party.add(member)
	game.party.at(0).set("hp",1.0)
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
	var start:=Vector3(-520.0,1080.06,5300.0)
	player.global_position=start
	player.velocity=Vector3.ZERO
	last_position=start
	physics_frame.connect(_record_frame)
	stage="post_summit_bivouac_uphill"
	await _frames(20)
	var camp: Node3D=physical.get_node("summit_bivouac")
	_require(await _recover_party_through_camp_input(camp,"summit_bivouac"),
		"Actual bed and rest input recovered the fixture member")
	# Pin the expired timer value recorded by the failed full replay. Production
	# must ignore it because only a positive timer may substitute `_deflect`.
	player.set("_deflect_left",-1.0/60.0)
	var target:=Vector3(100.0,1160.0,5350.0)
	var blocker:=world.find_child("summit_watch_0",true,false) as CharacterBody3D
	_require(blocker!=null,"Exact production summit_watch_0 exists after camp")
	if blocker==null:
		quit(1)
		return
	var contacted:=false
	var contact_normal:=Vector3.ZERO
	for frame in 2400:
		_steer(blocker.global_position-player.global_position,0.72)
		await _frames(1)
		for collision_index in player.get_slide_collision_count():
			var hit:=player.get_slide_collision(collision_index)
			if hit.get_collider()==blocker:
				contacted=true
				contact_normal=hit.get_normal()
				break
		if contacted: break
	_release()
	_require(contacted,"Real stick reproduced summit_watch_0 occupancy after rest")
	if not contacted:
		quit(1)
		return
	_log("post_camp_mobile_contact", {"blocker":str(blocker.get_path()),
		"normal":str(contact_normal),"method":"real stick; no body position write"})
	_require(await _sidestep_mobile_blocker(player,target,blocker,1),
		"Tangent arc cleared the exact post-camp summit watcher")
	_require(await _walk(target),"Post-rest real-stick input climbed the summit loop")
	_require(rows.any(func(row: Dictionary) -> bool:
		return str(row.get("kind",""))=="mobile_obstacle_cleared" and \
			str(row.get("blocker","")).ends_with("summit_watch_0")),
		"Post-rest live body used the general tangent-arc clearance path")
	_require(Vector2(player.global_position.x-start.x,player.global_position.z-start.z).length()>600.0,
		"Fresh wanted direction produced sustained forward motion after rest")
	_release()
	print("CLOUDREACH POST CAMP LOCOMOTION %s from=%s to=%s distance_m=%.1f"%[
		"FAIL" if failed else "PASS",start,player.global_position,distance_m])
	quit(1 if failed else 0)
