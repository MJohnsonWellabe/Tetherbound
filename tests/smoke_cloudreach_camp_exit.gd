extends "res://tests/smoke_cloudreach_arrival_walk.gd"

## Bounded local regression; the initial station is a declared fixture warp.
## All movement from the camp to the lower road uses the production controller.
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
	_player.global_position=Vector3(-280,180.2,520)
	_player.velocity=Vector3.ZERO
	var passed:=await _walk_to(Vector3(-120,205,700))
	_release_move()
	print("CAMP EXIT locomotion=%s velocity=%s floor=%s owner=%s"%[_player.call("locomotion_enabled"),_player.velocity,_player.is_on_floor(),preload("res://scripts/ui/input_owner.gd").current(self)])
	print("CLOUDREACH CAMP EXIT %s"%["PASS" if passed else "FAIL"])
	quit(0 if passed else 1)
