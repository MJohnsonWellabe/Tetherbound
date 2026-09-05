extends "res://tests/smoke_cloudreach_continuous.gd"

## Focused harness regression for a live creature occupying an authored route
## node. The player starts at the normal Cloudreach entry and reaches the node
## only through real movement input; neither body is repositioned after spawn.


func _run() -> void:
	start_usec=Time.get_ticks_usec()
	output_dir="user://cloudreach_mobile_occupancy_regression"
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
	stage="mobile_occupied_route_node"
	physics_frame.connect(_record_frame)
	await _frames(20)
	var start:=player.global_position
	var occupied_target:=Vector3(-1.8,105.6,-253.2)
	var blocker: CharacterBody3D=director.spawn_wild("galecrest",occupied_target,{
		"name":"route_occupancy_regression","aggressive":false,"wander_radius":0.0})
	_require(blocker!=null,"Live production creature spawned on entry-road support")
	if blocker==null:
		quit(1)
		return
	occupied_target=blocker.global_position
	var arrived:=await _walk(occupied_target,0.4)
	var clearance:=Vector2(player.global_position.x-occupied_target.x,
		player.global_position.z-occupied_target.z).length()
	_require(arrived,"Real-stick traversal accepts a live-body-occupied route node")
	_require(player.global_position.distance_to(start)>4.0,
		"Player physically traversed from the normal Cloudreach entry")
	_require(clearance<1.25,"Arrival remained within practical interaction clearance")
	_require(rows.any(func(row: Dictionary) -> bool:
		return str(row.get("kind",""))=="travel_arrived_mobile_clearance"),
		"Arrival used the bounded recent-live-contact clearance path")
	_require(blocker.global_position.distance_to(occupied_target)<0.75,
		"Harness did not move or bypass the occupying production creature")
	_release()
	print("CLOUDREACH MOBILE OCCUPANCY %s travelled=%.1f clearance=%.2f"%[
		"FAIL" if failed else "PASS",player.global_position.distance_to(start),clearance])
	quit(1 if failed else 0)
