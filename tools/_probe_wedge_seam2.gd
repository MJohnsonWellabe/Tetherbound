extends SceneTree

## WALL1 follow-up: _probe_wedge_seam.gd found every one of the 23 residual
## is_on_wall() frames at collision_shape_size=64 colliding with Captain
## Halder's own NPC body (trainers.json places him at [52.0, -122.0], ~1m
## from the freeze point and inside Galecrest's own wander radius). This
## re-runs BOTH shape sizes (16, the pre-BAKE-GUARDS live value, and 64,
## today's corrected value) and buckets every is_on_wall() frame by whether
## Halder is one of its colliders, to find out whether the 47-vs-23 gap
## BAKE-GUARDS closed is ALSO entirely Halder, or whether a genuine
## terrain-only contribution exists alongside him.
##
##   godot --headless --path . --script tools/_probe_wedge_seam2.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"

const FREEZE_X := 52.9728
const FREEZE_Z := -122.276
const APPROACH_DISTANCE := 3.0
const WALK_FRAMES := 180
const SPEED := 3.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var terrain: Node = world.get_node_or_null(^"Terrain")
	print("live collision_shape_size at boot: %s" % terrain.get("collision_shape_size"))

	print("")
	print("=== PASS A: forcing collision_shape_size back to 16 (pre-BAKE-GUARDS) ===")
	terrain.set("collision_shape_size", 16)
	for i in 10:
		await physics_frame
	print("readback: %s" % terrain.get("collision_shape_size"))
	await _walk_and_bucket(world)

	print("")
	print("=== PASS B: correcting collision_shape_size to 64 (today's live value) ===")
	terrain.set("collision_shape_size", 64)
	for i in 10:
		await physics_frame
	print("readback: %s" % terrain.get("collision_shape_size"))
	await _walk_and_bucket(world)

	quit(0)


func _walk_and_bucket(world: Node) -> void:
	var body := CharacterBody3D.new()
	body.floor_max_angle = deg_to_rad(55.0)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.2
	var coll := CollisionShape3D.new()
	coll.shape = shape
	body.add_child(coll)
	root.add_child(body)

	var start_x := FREEZE_X - APPROACH_DISTANCE
	# Ground lookup avoided here on purpose -- height doesn't matter for a
	# bucket-by-collider pass, only x/z do, and this keeps the probe from
	# depending on playground_heightfield.gd at all.
	body.global_position = Vector3(start_x, 2.0, FREEZE_Z)
	body.velocity = Vector3.ZERO
	for i in 10:
		await physics_frame

	var halder_frames := 0
	var non_halder_wall_frames := 0
	var non_halder_examples: Array = []
	for i in WALK_FRAMES:
		body.velocity.x = SPEED
		body.velocity.z = 0.0
		if not body.is_on_floor():
			body.velocity.y -= 0.163
		else:
			body.velocity.y = 0.0
		body.move_and_slide()
		await physics_frame
		if body.is_on_wall():
			var touches_halder := false
			var colliders: Array = []
			for s in body.get_slide_collision_count():
				var col := body.get_slide_collision(s)
				var c: Object = col.get_collider()
				var desc := str(c)
				if c is Node:
					desc = (c as Node).get_path()
					if "Halder" in String(desc):
						touches_halder = true
				colliders.append(desc)
			if touches_halder:
				halder_frames += 1
			else:
				non_halder_wall_frames += 1
				if non_halder_examples.size() < 5:
					non_halder_examples.append({"frame": i, "pos": body.global_position, "colliders": colliders})

	print("  is_on_wall() frames touching Captain Halder: %d/%d" % [halder_frames, WALK_FRAMES])
	print("  is_on_wall() frames NOT touching Halder (candidate terrain-only): %d/%d" % [non_halder_wall_frames, WALK_FRAMES])
	for ex: Dictionary in non_halder_examples:
		print("    frame %d pos=%s colliders=%s" % [ex["frame"], ex["pos"], ex["colliders"]])

	body.queue_free()
