extends "res://tests/smoke_cloudreach_arrival_walk.gd"

## Declared entry fixture, then continuous ordinary controller movement across
## the real approach, open rope bridge and far abutment. No jump/warp bypass.
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
	_player.global_position=Vector3(-320,300.2,1040)
	_player.velocity=Vector3.ZERO
	var passed:=true
	for at in [Vector3(-540,330,1280),Vector3(-511.2,338.25,1305.6),Vector3(-468,338.25,1344),Vector3(-450,342,1360),Vector3(-260,390,1560),Vector3(-230,390,1575),Vector3(110,420,1815),Vector3(120,420,1830)]:
		if not await _walk_to(at):
			passed=false
			break
		if absf(_player.global_position.y-at.y)>0.7:
			push_error("Causeway authored floor mismatch at %s expected %s"%[_player.global_position,at])
			passed=false
			break
	_release_move()
	print("CLOUDREACH CAUSEWAY CROSSING %s at=%s"%["PASS" if passed else "FAIL",_player.global_position])
	quit(0 if passed else 1)
