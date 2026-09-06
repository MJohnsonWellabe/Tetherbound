extends "res://tests/smoke_cloudreach_continuous.gd"

## Focused real-input traversal from the authored west summit-loop waypoint to
## the Waterward overlook crown. One declared fixture position establishes the
## segment start; no position write follows it.


func _run() -> void:
	Engine.time_scale=8.0
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/waterward-overlook-regression"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm="cloudreach"
	for flag: String in ["realm_key_cloudreach","cloudreach_upper_route_unlocked",
			"cloudreach_act_ii_complete","cloudreach_upper_anchors_disabled",
			"captain_veyra_defeated","storm_anchor_network_disabled",
			"cloudreach_winds_restored"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit","mudsnout","bramblebun","terrapup","brooktail"]:
		game.party.add(SPECIES.spawn(species))
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
	stage="summit_loop_to_waterward_overlook"
	await _frames(20)
	var target:=Vector3(-420.0,1110.0,5650.0)
	var arrived:=await _walk(target)
	var crown: Node3D=world.get_node_or_null("Landmarks/WaterwardOverlook/OverlookWalkableCrown")
	_require(arrived,"Real stick reached the authored Waterward overlook endpoint")
	_require(crown!=null and crown.get_node_or_null("Collision")!=null,
		"Waterward landmark has a thin walkable crown")
	_require(player.is_on_floor(),"Player remains grounded on the overlook crown")
	_require(player.global_position.distance_to(start)>340.0,
		"Player physically traversed the complete authored summit-loop edge")
	if not failed:
		_require(await _pickup("cr_pickup_waterward_rare_candy"),
			"Real input claimed the Waterward overlook pickup")
	if not failed:
		_require(await _talk("warden_aila","cloudreach_chapter_complete",false),
			"Real relocated-Warden dialogue claimed the Cloudreach reward")
	_require(_has("realm_heart_cloudreach_earned") and _has("realm_key_stormwood")
		and _has("stormward_route_revealed"),
		"Waterward reward footprint granted Heart, key, and route reveal")
	_require(not game.can_enter_realm("water"),
		"Waterward viewpoint remains non-enterable")
	_release()
	print("CLOUDREACH WATERWARD OVERLOOK %s from=%s to=%s distance_m=%.1f"%[
		"FAIL" if failed else "PASS",start,player.global_position,distance_m])
	quit(1 if failed else 0)
