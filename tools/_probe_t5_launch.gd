extends SceneTree

## T5-CARE probe: WHAT launches the free-play player out of the world?
##
##   godot --headless --path . --script tools/_probe_t5_launch.gd
##
## `tools/_probe_t5_spawn.gd` established the shape of it, reproducibly:
##
##   [playground] spawned at 0.0, 2.9, 0.0     <- the world places them correctly
##   player at (-6789673.5, 2686.53, 2137802.2) <- 300 physics frames later
##
## only when `opening:beat:free_play` is set, i.e. in ordinary post-opening
## play. This samples every frame from the spawn so the answer is "it happens
## on frame N, and the velocity looks like X" rather than a guess.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRAMES := 300


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	game.get("progression").call("set_flag", "opening:beat:free_play")
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		print("no player")
		quit(1)
		return

	print("")
	print("=== T5 launch trace (free play) ===")
	var last := player.global_position
	var reported := 0
	for i in FRAMES:
		await physics_frame
		var p := player.global_position
		var jump := p.distance_to(last)
		# Print the first frames, then only frames where something violent
		# happens, so the log stays readable.
		if i < 6 or jump > 5.0:
			if reported < 40:
				print("T5> frame %3d  pos (%12.1f, %9.2f, %12.1f)  moved %10.2fm  vel %s  on_floor=%s" % [
					i, p.x, p.y, p.z, jump, str(player.velocity.round()), str(player.is_on_floor())])
				reported += 1
		last = p
	var final := player.global_position
	print("T5> final     (%12.1f, %9.2f, %12.1f)" % [final.x, final.y, final.z])

	# What is standing at the origin the player is spawned into?
	var space := world.get_world_3d().direct_space_state
	var shape := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 12.0, 4.0)
	shape.shape = box
	shape.transform = Transform3D(Basis(), Vector3(0.0, 6.0, 0.0))
	shape.collide_with_areas = false
	var hits: Array = space.intersect_shape(shape, 32)
	print("")
	print("T5> bodies overlapping the spawn column at the origin: %d" % hits.size())
	for h: Variant in hits:
		var node := (h as Dictionary)["collider"] as Node
		var owner_name := node.name
		var parent := node.get_parent()
		print("T5>   %s (%s) under %s" % [owner_name, node.get_class(),
			parent.name if parent != null else "-"])
	quit(0)
