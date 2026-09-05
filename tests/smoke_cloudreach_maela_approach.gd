extends "res://tests/smoke_cloudreach_arrival_walk.gd"

## Explicit lower-road fixture, then the real controller crosses the mandatory
## junction and ravine chain span without Fly/upper unlock or obstacle warps.
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
	var local_aerie:="--aerie-only" in OS.get_cmdline_user_args()
	_player.global_position=Vector3(120,520.2,3380) if local_aerie else Vector3(-60,450.2,2220)
	_player.velocity=Vector3.ZERO
	var passed:=true
	var points: Array[Vector3]=[Vector3(-100,470,2440),Vector3(-520,430,2720),Vector3(-300,460,3100),Vector3(120,520,3380),Vector3(373,610,3262.5357),Vector3(392,610,3245),Vector3(403,610,3255)]
	for at in (points.slice(4) if local_aerie else points):
		if not await _walk_to(at):
			passed=false
			break
	_release_move()
	var gate:=_world.get_node("TraversalGates/UpperCounterweightGate/LockedTraversalBarrier")
	if (gate.get_child(0) as CollisionShape3D).disabled:
		push_error("The route regression accidentally unlocked the upper gate")
		passed=false
	print("CLOUDREACH MAELA APPROACH %s at=%s upper gate still locked"%["PASS" if passed else "FAIL",_player.global_position])
	quit(0 if passed else 1)
