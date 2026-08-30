extends SceneTree

## What stands between the Warden Arena and the Legendary Chamber?
##
##   godot --headless --path . --script tools/_probe_hall_chamber_passage.gd
##
## `smoke_stronghold.gd` walks the five spaces in order and every hop passes
## except the last: pushed from `warden_arena` toward `legendary_chamber` the
## player ends 21.5m from the chamber's centre against a 16.0m allowance, i.e.
## it travels about 10.5m of a 32m hop and stops around x = -10.5 -- just short
## of the arena's west wall, where the passage should be. The same job passed on
## `d10b2e34`, the tip before this consolidation's Hall merges, so something
## the Hall work added is standing in the doorway.
##
## The smoke test cannot say WHAT, because it only measures how far the body
## got. This sweeps the player's own shape along that straight line in
## half-metre steps and names the first collider at each step, the same
## technique `_probe_engage_obstacle.gd` used to identify a fence panel.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const ELITE_FLAG := "defeated_stronghold_elite"


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var hold := world.get_node_or_null(^"Stronghold") as Node3D
	if player == null or hold == null:
		print("no Player or no Stronghold")
		quit(1)
		return

	# The shutter into the arena is behind the elite; open it so the arena is
	# reachable at all, exactly as the smoke test does before this hop.
	var game := root.get_node_or_null(^"/root/Game")
	if game != null and game.get("progression") != null:
		game.get("progression").call("set_flag", ELITE_FLAG)
		for i in 8:
			await physics_frame

	var from: Vector3 = hold.call("marker", "warden_arena")
	var to: Vector3 = hold.call("marker", "legendary_chamber")
	print("warden_arena     %.1f, %.2f, %.1f" % [from.x, from.y, from.z])
	print("legendary_chamber %.1f, %.2f, %.1f  (%.1fm apart)\n" % [
		to.x, to.y, to.z, from.distance_to(to)])

	var flat := to - from
	flat.y = 0.0
	var dir := flat.normalized()
	var scan := player.global_transform
	scan.basis = Basis.IDENTITY
	var seen := {}
	print("half-metre sweep of the player's own shape along the straight line:")
	for i in int(flat.length() / 0.5) + 1:
		var here := from + dir * (float(i) * 0.5)
		here.y = from.y + 0.35
		scan.origin = here
		var hit := _shape_hit(player, scan, dir * 0.5)
		if hit != "":
			var key := "%s@%.0f" % [hit, floor(float(i) * 0.5)]
			if not seen.has(key):
				seen[key] = true
				print("   %6.1fm along (x=%7.1f): %s" % [float(i) * 0.5, here.x, hit])
	if seen.is_empty():
		print("   nothing -- the line is clear to a shape cast")

	# --- the walk itself -------------------------------------------------------
	#
	# A static sweep can say the line is clear and the walk still fail, so drive
	# the SAME push the smoke test drives and log where it actually stalls and
	# what it is sliding against.
	print("\nthe push the smoke test drives, sampled every 60 frames:")
	player.global_position = from + Vector3(0.0, 1.2, 0.0)
	player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	player.set_physics_process(false)
	var last := player.global_position
	for i in 600:
		player.velocity.x = dir.x * 4.0
		player.velocity.z = dir.z * 4.0
		player.velocity.y = 0.0 if player.is_on_floor() else player.velocity.y - 0.5
		player.move_and_slide()
		await physics_frame
		if i % 60 == 59:
			var moved := player.global_position.distance_to(last)
			last = player.global_position
			var against := ""
			for c in player.get_slide_collision_count():
				var col := player.get_slide_collision(c).get_collider() as Node
				if col != null:
					against += ("" if against == "" else ", ") + str(col.name)
			print("   frame %3d: x=%7.2f y=%6.2f  moved %5.2fm  floor=%s wall=%s  against: %s" % [
				i + 1, player.global_position.x, player.global_position.y, moved,
				player.is_on_floor(), player.is_on_wall(),
				against if against != "" else "-"])
	player.set_physics_process(true)
	print("\nended %.1fm from the chamber centre" % player.global_position.distance_to(to))
	quit(0)


func _shape_hit(player: CharacterBody3D, at: Transform3D, motion: Vector3) -> String:
	var was := player.global_transform
	var info := KinematicCollision3D.new()
	var touched := player.test_move(at, motion, info)
	player.global_transform = was
	if not touched:
		return ""
	var collider: Object = info.get_collider()
	if collider == null:
		return "<unnamed collider>"
	var node := collider as Node
	if node == null:
		return str(collider)
	return "%s  (parent %s)" % [node.name, node.get_parent().name if node.get_parent() != null else "-"]
