extends "res://tests/smoke_cloudreach_continuous.gd"

## Focused topology regression for the finale aftermath. The prerequisite
## fixture starts the human on the completed summit deck; every subsequent
## metre follows the authored central approach through real controller input.


func _run() -> void:
	start_usec=Time.get_ticks_usec()
	accelerated=true
	Engine.time_scale=8.0
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	output_dir="res://ralph/reports/CLOUDREACH-CONTINUOUS-0905/post-relay-exit-regression"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm="cloudreach"
	for flag: String in ["realm_key_cloudreach","realm_heart_meadows_earned",
			"cloudreach_upper_route_unlocked","cloudreach_act_ii_complete",
			"cloudreach_upper_anchors_disabled","summit_extraction_engine_reached",
			"captain_veyra_defeated","cloudreach_summit_relay_west_disabled",
			"cloudreach_summit_relay_crown_disabled","cloudreach_summit_relay_east_disabled",
			"storm_anchor_network_disabled"]:
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
	await _frames(20)
	var start:=Vector3(100.0,1160.15,5450.0)
	player.global_position=start
	player.velocity=Vector3.ZERO
	last_position=start
	physics_frame.connect(_record_frame)
	stage="post_relay_central_exit"
	await _frames(20)
	_require(runtime.finale.phase=="awaiting_restoration",
		"Fixture restored the production post-relay phase")
	var crown_mount:=world.get_node("SummitArenaPresentation/InstalledRelayMount_crown")
	_require(crown_mount!=null,"Visible crown relay housing remains installed")
	_require(crown_mount.get_node_or_null("RelayHousingCollision")==null,
		"Crown housing alone leaves the authored central approach unobstructed")
	for point: Vector3 in [Vector3(100.0,1160.0,5420.0),
			Vector3(100.0,1160.0,5400.0),Vector3(100.0,1160.0,5350.0)]:
		if not await _walk(point):
			quit(1)
			return
	_require(Vector2(player.global_position.x-start.x,player.global_position.z-start.z).length()>95.0,
		"Real stick carried the human out across the complete post-relay centreline")
	_release()
	print("CLOUDREACH POST RELAY EXIT %s from=%s to=%s distance_m=%.1f"%[
		"FAIL" if failed else "PASS",start,player.global_position,distance_m])
	quit(1 if failed else 0)
