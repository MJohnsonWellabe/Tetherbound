extends SceneTree

## STRANDED-P3 CI investigation, part 2: verify-core-verb-shard's CI run 2170
## still failed smoke_traversal.gd's four-direction walk near spawn: "player
## got wedged ... at move_left at (-8, 40)", with move_back ending at
## (60.0, -7.4, 39.9). Same intermittent, load-sensitive class as the
## galecrest-on-the-deck bug (see tools/_probe_mill_stall.gd) -- did not
## reproduce locally or in earlier CI runs of the same shard. Replays the
## SAME four-direction sequence smoke_traversal.gd runs, with frame-by-frame
## is_on_wall()/collider/velocity detail once move_left starts, so a live
## collider name identifies the culprit the way it did for the mill.
##
##   godot --headless --path . --script tools/_probe_spawn_wedge.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const LEG_FRAMES := 1700


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var start := Vector3(60.0, 0.0, -60.0)
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame

	for direction in ["move_forward", "move_right", "move_back"]:
		Input.action_press(direction)
		for i in LEG_FRAMES:
			await physics_frame
			var pos := player.global_position
			if pos.x < -1024.0 + 240.0 or pos.x > 1024.0 - 240.0 \
					or pos.z < -512.0 + 240.0 or pos.z > 7680.0 - 240.0:
				break
		Input.action_release(direction)
		var here := player.global_position
		print("%-14s -> %.3f, %.3f, %.3f  grounded=%s" % [direction, here.x, here.y, here.z, str(player.is_on_floor())])
		for i in 30:
			await physics_frame

	print("")
	print("--- move_left, frame-by-frame detail on every slow/wall frame ---")
	Input.action_press("move_left")
	var last_report := -100
	for i in LEG_FRAMES:
		await physics_frame
		var pos := player.global_position
		var slow := player.velocity.length() < 1.0
		if player.is_on_wall() or slow or (i - last_report) >= 30 or i == LEG_FRAMES - 1:
			last_report = i
			print("frame %4d  pos=(%.3f,%.3f,%.3f)  on_wall=%s  on_floor=%s  vel=%s" % [
				i, pos.x, pos.y, pos.z, str(player.is_on_wall()), str(player.is_on_floor()), str(player.velocity)])
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
		if pos.x < -1024.0 + 240.0 or pos.x > 1024.0 - 240.0 \
				or pos.z < -512.0 + 240.0 or pos.z > 7680.0 - 240.0:
			break
	Input.action_release("move_left")
	print("move_left final: %s" % str(player.global_position))
	quit(0)
