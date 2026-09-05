extends "res://tests/smoke_cloudreach_continuous.gd"

## Focused regression for the exact production lower_cliff_foragers_0 route
## occupancy seen by the clean continuous replay. The player begins at normal
## Cloudreach entry and all progress is real stick input; neither body is moved.


func _run() -> void:
	start_usec=Time.get_ticks_usec()
	accelerated=true
	Engine.time_scale=8.0
	Engine.physics_ticks_per_second=480
	Engine.max_physics_steps_per_frame=32
	output_dir="user://cloudreach_lower_forager_detour_regression"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	game=root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm="cloudreach"
	for flag: String in ["realm_key_cloudreach","realm_heart_meadows_earned"]:
		game.progression.set_flag(flag)
	for species: String in ["sparkit","mudsnout","bramblebun","terrapup","brooktail"]:
		game.party.add(SPECIES.spawn(species))
	world=SCENE.instantiate()
	root.add_child(world)
	current_scene=world
	player=world.get_node("Player")
	runtime=world.get_node("CloudreachRuntime")
	director=runtime.director
	manager=runtime.manager
	stage="lower_forager_tangent_detour"
	physics_frame.connect(_record_frame)
	await _frames(20)
	var start:=player.global_position
	for waypoint: Vector3 in [
		Vector3(-80,130,40),Vector3(-300,145,200),Vector3(-280,180,490),
		Vector3(-280,180,520),Vector3(-225,189,582)]:
		if not await _walk(waypoint):
			_finish()
			return
	# Cloudreach encounter sites are proximity-streamed, so resolve the exact
	# production body only after the normal authored approach has loaded it.
	var blocker:=world.find_child("lower_cliff_foragers_0",true,false) as CharacterBody3D
	_require(blocker!=null,"Exact production lower_cliff_foragers_0 exists")
	if blocker==null:
		quit(1)
		return
	var route_forward:=Vector3(160,25,180).normalized()
	# Follow the freely wandering production body with real stick input until the
	# same CharacterBody slide contact from the clean replay is reproduced. This
	# changes neither its AI nor transform.
	var contacted:=false
	for frame in 2400:
		var offset:=blocker.global_position-player.global_position
		_steer(offset,0.72)
		await _frames(1)
		for collision_index in player.get_slide_collision_count():
			if player.get_slide_collision(collision_index).get_collider()==blocker:
				contacted=true
				break
		if contacted: break
	_release()
	_require(contacted,"Real stick reproduced contact with lower_cliff_foragers_0")
	if not contacted:
		quit(1)
		return
	var blocker_at_approach:=blocker.global_position
	var beyond:=blocker_at_approach+route_forward*12.0
	_require(await _sidestep_mobile_blocker(player,beyond,blocker,1),
		"Three-point real-stick tangent arc cleared lower_cliff_foragers_0")
	_require(await _walk(beyond,0.75),
		"Real-stick traversal made forward progress past lower_cliff_foragers_0")
	var passed_plane:=(player.global_position-blocker_at_approach).dot(route_forward)
	_require(passed_plane>6.0,"Player cleared the production creature's forward plane")
	_require(rows.any(func(row: Dictionary) -> bool:
		return str(row.get("kind",""))=="mobile_obstacle_cleared" and \
			str(row.get("blocker","")).ends_with("lower_cliff_foragers_0")),
		"Exact production obstacle used the tangent-arc clearance path")
	_require(blocker.global_position.distance_to(blocker.get("home"))<=12.0,
		"Regression did not reposition or warp the production creature")
	_release()
	print("CLOUDREACH LOWER FORAGER DETOUR %s travelled=%.1f passed=%.1f"%[
		"FAIL" if failed else "PASS",player.global_position.distance_to(start),passed_plane])
	quit(1 if failed else 0)
