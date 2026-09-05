extends "res://tests/smoke_cloudreach_arrival_walk.gd"

## Each yard has an explicit road-entry fixture. Within that fixture all travel
## is production controller input, including entrance, clear floor and return.
func _run() -> void:
	Engine.time_scale=4.0
	Engine.physics_ticks_per_second=240
	Engine.max_physics_steps_per_frame=32
	var game:=root.get_node("Game")
	game.call("reset_for_new_game")
	game.set("current_realm","cloudreach")
	_world=SCENE.instantiate()
	root.add_child(_world)
	current_scene=_world
	_player=_world.get_node("Player")
	for frame in 12:
		await physics_frame
	var passed:=true
	for yard: Node3D in _world.get_node("CloudreachBattleYards").get_children():
		if not yard.has_meta("road_entry"):
			continue
		var entry: Vector3=yard.get_meta("road_entry")
		_player.global_position=entry+Vector3.UP*0.2
		_player.velocity=Vector3.ZERO
		var centre:=yard.global_position
		for at in [centre,centre+Vector3(0,0,10),centre+Vector3(-10,0,0),centre+Vector3(0,0,-10),centre,entry]:
			if not await _walk_to(at):
				passed=false
				break
			if absf(_player.global_position.y-at.y)>0.7:
				push_error("Yard floor mismatch %s at %s"%[yard.name,_player.global_position])
				passed=false
				break
		_release_move()
		print("YARD WALK %s %s"%[yard.name,"PASS" if passed else "FAIL"])
		if not passed:
			break
	print("CLOUDREACH BATTLE YARDS %s"%["PASS" if passed else "FAIL"])
	quit(0 if passed else 1)
