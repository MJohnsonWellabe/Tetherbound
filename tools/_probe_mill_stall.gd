extends SceneTree

## STRANDED-P3 CI investigation: the Old Mill Crossing walk stalls short of
## BRIDGE_CROSSED_M. Reproduce the mill-only walk with frame-by-frame
## is_on_wall()/collider/velocity detail, the same method WALL1 used
## (tools/_probe_wedge_seam.gd), to find what actually stops the body.
##
##   godot --headless --path . --script tools/_probe_mill_stall.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BRIDGE_START_BACK := 11.0
const BRIDGE_WALK_FRAMES := 420


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var camera_rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	var bridge: Node3D = world.get_node_or_null(^"MillCrossing") as Node3D
	var game := root.get_node_or_null(^"Game")
	var inventory: RefCounted = game.get("inventory")

	# Open the gate for real, same as the smoke test.
	inventory.call("add", "mill_bridge_gear", 1)
	var prompt: Node3D = bridge.get_node_or_null(^"Interactable") as Node3D
	prompt.call("interaction_activate")
	await physics_frame
	print("is_open after unlock: %s" % str(bridge.call("is_open")))

	var start: Vector2 = bridge.call("near_point", BRIDGE_START_BACK)
	var target: Vector2 = bridge.call("far_point", BRIDGE_START_BACK)
	var ground: float = float(bridge.get_parent().call("ground_height_at", start.x, start.y))
	player.global_position = Vector3(start.x, ground + 1.0, start.y)
	player.velocity = Vector3.ZERO
	var outward := Vector3(target.x - start.x, 0.0, target.y - start.y).normalized()
	camera_rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(outward, Vector3.UP))
	print("start=%s target=%s outward=%s" % [str(start), str(target), str(outward)])
	for i in 10:
		await physics_frame

	var best := -INF
	Input.action_press("move_forward")
	var last_report_frame := -100
	for i in BRIDGE_WALK_FRAMES:
		await physics_frame
		var here := player.global_position
		var depth := float(bridge.call("depth_past_crossing", Vector2(here.x, here.z)))
		if depth > best:
			best = depth
		var slow := player.velocity.length() < 1.0
		if player.is_on_wall() or slow or (i - last_report_frame) >= 30 or i == BRIDGE_WALK_FRAMES - 1:
			last_report_frame = i
			var line := "frame %3d  pos=(%.3f,%.3f,%.3f)  depth=%.2f  on_wall=%s  on_floor=%s  vel=%s" % [
				i, here.x, here.y, here.z, depth, str(player.is_on_wall()), str(player.is_on_floor()), str(player.velocity)]
			print(line)
			var slide_count := player.get_slide_collision_count()
			for s in slide_count:
				var col := player.get_slide_collision(s)
				var n: Vector3 = col.get_normal()
				var collider: Object = col.get_collider()
				var collider_desc := str(collider)
				if collider is Node:
					var cnode := collider as Node
					collider_desc = "%s path=%s parent=%s" % [cnode.name, str(cnode.get_path()), cnode.get_parent().name if cnode.get_parent() else "?"]
				print("    slide[%d] normal=(%.3f,%.3f,%.3f) collider=%s" % [s, n.x, n.y, n.z, collider_desc])
	Input.action_release("move_forward")
	print("BEST depth past gap: %.2f" % best)
	quit(0)
