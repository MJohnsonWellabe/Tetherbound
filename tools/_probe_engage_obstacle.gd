extends SceneTree

## What stands between the catch harness's start point and `Wild_bramblebun_0_2`,
## and can the repo's own walker get around it?
##
##   godot --headless --path . --script tools/_probe_engage_obstacle.gd
##
## `tools/_probe_engage_walk.gd` established that the straight-line walk to that
## one cluster member goes `on_wall=true` at about (33.2, -47.7) and then crawls
## -- 19 of 25 sampled seconds under 0.5m -- ending 8.9m short. Its two siblings
## at 11.9m and 23.2m arrive in 102 and 229 frames. So the failure is specific to
## what sits on that one line, not to the walk speed, the aggro, or the cluster.
##
## Two questions the walk probe cannot answer, and they decide whether
## `smoke_party_count_after_catches.gd` is reporting a GAME defect or a harness
## one:
##
##   1. WHAT is the body pressed against? A named collider says whether this is
##      authored geometry doing its job or a creature spawned inside something.
##   2. Is the creature REACHABLE at all? If `stick_navigator.gd` -- the repo's
##      one walker that detours, the one `test_gate_f_rig.gd` requires every
##      continuous harness to route through -- arrives, then the world is fine
##      and the straight line is the whole defect. If it cannot, a catchable
##      creature is standing somewhere the player cannot walk, and that is a
##      real defect in the encounter placement.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SETTLE_FRAMES := 240
const START := Vector3(48.0, 0.0, -58.0)
const TARGET_NAME := "Wild_bramblebun_0_2"


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
	for i in 600:
		await physics_frame
		var candidate := director.call("wild_creature") as Node3D
		if candidate != null and candidate.visible and bool(candidate.call("is_alive")):
			break

	var target: Node3D = null
	for node in _walk_tree(world):
		if node is Node3D and str(node.name) == TARGET_NAME:
			target = node as Node3D
			break
	if target == null:
		print("no %s in the tree" % TARGET_NAME)
		quit(1)
		return
	print("target %s at %.1f, %.2f, %.1f (%.1fm from start)\n" % [
		TARGET_NAME, target.global_position.x, target.global_position.y,
		target.global_position.z, start.distance_to(target.global_position)])

	# --- 1. what is in the way -------------------------------------------------
	#
	# Sweep the body's own shape along the straight line, in half-metre steps,
	# and name the first thing it touches. `move_and_collide` with `test_only`
	# reports the collider without moving anything, so this does not disturb the
	# state the walk below starts from.
	print("straight line from the start to the target, half-metre steps:")
	var probe := player.global_position
	var to := target.global_position - probe
	to.y = 0.0
	var dir := to.normalized()
	var scan := player.global_transform
	var hit_names := {}
	for i in int(to.length() / 0.5):
		scan.origin = probe + dir * (float(i) * 0.5)
		scan.origin.y = float(world.call("ground_height_at", scan.origin.x, scan.origin.z)) + 0.35
		var collision := _shape_hit(player, scan, dir * 0.5)
		if collision != "":
			var reach := float(i) * 0.5
			if not hit_names.has(collision):
				hit_names[collision] = reach
				print("   %6.1fm along: %s" % [reach, collision])
	if hit_names.is_empty():
		print("   nothing -- the line is clear to a shape cast (so the block is dynamic)")
	print("")

	# --- 2. is it reachable at all --------------------------------------------
	player.global_position = start
	player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	var nav = NAVIGATOR.new(self, player, rig, _drive)
	var arrived: bool = await nav.walk_to(target.global_position, 3000, 3.6)
	_release()
	var final := target.global_position - player.global_position
	final.y = 0.0
	print("stick_navigator.gd: arrived=%s, final %.2fm, player at %.1f, %.2f, %.1f" % [
		str(arrived), final.length(),
		player.global_position.x, player.global_position.y, player.global_position.z])
	print("")
	if arrived:
		print("VERDICT: the creature is reachable. The straight line is the defect,")
		print("         not the world and not the encounter placement.")
	else:
		print("VERDICT: even the detouring walker cannot reach it. A catchable")
		print("         creature is standing where the player cannot go -- GAME defect.")
	quit(0)


## `move_and_collide` moves the body, so the sweep uses a throwaway transform and
## `test_move`'s collision-reporting sibling instead: put the body there, ask, and
## put it back. Cheap enough at half-metre steps over thirty metres.
func _shape_hit(player: CharacterBody3D, at: Transform3D, motion: Vector3) -> String:
	var was := player.global_transform
	player.global_transform = at
	var info := KinematicCollision3D.new()
	var touched := player.test_move(at, motion, info)
	player.global_transform = was
	if not touched:
		return ""
	var collider: Object = info.get_collider()
	if collider == null:
		return "<unnamed collider>"
	var node := collider as Node
	return str(node.name) if node != null else str(collider)


func _drive(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))


func _release() -> void:
	for action: StringName in [&"move_right", &"move_left", &"move_back", &"move_forward"]:
		Input.action_release(action)


func _walk_tree(from: Node) -> Array[Node]:
	var out: Array[Node] = [from]
	for child in from.get_children():
		out.append_array(_walk_tree(child))
	return out
