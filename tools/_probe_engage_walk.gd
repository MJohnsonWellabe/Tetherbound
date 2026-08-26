extends SceneTree

## Why does the walk to the practice creature stop short?
##
##   godot --headless --path . --script tools/_probe_engage_walk.gd
##
## `smoke_party_count_after_catches.gd` fails intermittently on CI with
## "could not engage the real wild body at Wild_bramblebun_0_3 (stopped 23.7m
## away (engage range 6.0m))", which fails catch 3 and cascades into every
## downstream assertion. It reddens branches at random across the repo.
##
## Two explanations were on the table and one is already dead. It is NOT a chase
## that failed to converge: `combat.json` puts `wild.wander_speed` at 1.4 m/s
## against the player's 5.0 walk, and `wild.wander_radius` at 7.0 m, so the
## target cannot outrun the player and is anchored to a small disc. Twenty-five
## seconds of held forward is ~125 m of walking. Stopping 23.7 m short means the
## body was BLOCKED, not outpaced.
##
## It is also not the entombment class this repo just fixed: that failsafe fired
## zero times in a full local pass of the test, because its eight-direction probe
## correctly finds open ground behind a body merely pressed against something.
##
## So this reproduces the test's own approach -- the same start point, the same
## raw straight-line walk with the rig aimed at the target every frame -- and
## logs what the two tests never record: distance, whether the body is on a wall,
## and how far it actually moved each second. A body that is on a wall and moving
## a few centimetres a second while the stick is held is a livelock, not a walk.
##
## Note what neither test uses: `tests/helpers/stick_navigator.gd`, the repo's
## one walker that detours around geometry, which exists because "every
## straight-line walk in this project failed on the same village wall" and which
## the Gate F harness's own `move_to` routes through.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const START := Vector3(48.0, 0.0, -58.0)
const WALK_FRAMES := 1500
const SAMPLE_EVERY := 60


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	var director := world.get_node_or_null(^"EncounterDirector")
	if player == null or rig == null or director == null:
		print("missing Player/CameraRig/EncounterDirector")
		quit(1)
		return

	var start := START
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame

	var target: Node3D = null
	for i in 600:
		await physics_frame
		var candidate := director.call("wild_creature") as Node3D
		if candidate != null and candidate.visible and bool(candidate.call("is_alive")):
			target = candidate
			break
	if target == null:
		print("no wild creature appeared")
		quit(1)
		return

	print("start  player %.1f, %.2f, %.1f" % [start.x, start.y, start.z])
	print("target %s at %.1f, %.2f, %.1f  (%.1fm away)" % [
		str(target.get_path()), target.global_position.x, target.global_position.y,
		target.global_position.z, start.distance_to(target.global_position)])
	print("")
	print("%6s %9s %9s %8s %8s  %s" % ["frame", "dist", "moved/s", "on_wall", "on_floor", "position"])

	var last := player.global_position
	var stalled_seconds := 0
	for i in WALK_FRAMES:
		if not is_instance_valid(target):
			print("target freed at frame %d" % i)
			break
		var to := target.global_position - player.global_position
		to.y = 0.0
		if to.length() <= 3.6:
			print("ARRIVED at frame %d (%.2fm)" % [i, to.length()])
			break
		rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
		if i % SAMPLE_EVERY == 0:
			var here := player.global_position
			var moved := here.distance_to(last)
			if moved < 0.5:
				stalled_seconds += 1
			print("%6d %9.2f %9.2f %8s %8s  %.1f, %.2f, %.1f" % [
				i, to.length(), moved, str(player.is_on_wall()), str(player.is_on_floor()),
				here.x, here.y, here.z])
			last = here
	Input.action_release("move_forward")

	var final := target.global_position - player.global_position if is_instance_valid(target) else Vector3.ZERO
	final.y = 0.0
	print("")
	print("final distance %.2fm; %d of %d sampled seconds moved under 0.5m" % [
		final.length(), stalled_seconds, WALK_FRAMES / SAMPLE_EVERY])
	quit(0)
