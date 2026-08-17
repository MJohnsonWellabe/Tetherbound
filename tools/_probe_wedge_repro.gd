extends SceneTree

## Direct move_and_slide reproduction of the CI-AGGRESSION / OF15 wedge, at
## the exact reported coordinates, first against the LIVE shipped
## collision_shape_size (16, silently stuck -- see _probe_shape_size_live.gd)
## and then again after correcting it to 64 in-tree (what ralph/BAKE-GUARDS'
## already-pushed fix achieves, unmerged) -- WITHOUT touching ralph/COLL1's
## own files, so this is read-only evidence for ralph/NOTES.md.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const POINTS := [
	{"label": "CI-AGGRESSION creature freeze", "x": 52.9728, "z": -122.276},
	{"label": "OF15 point A", "x": 60.0, "z": -106.0},
	{"label": "OF15 point B", "x": 65.0, "z": -108.0},
]

## A body walking INTO the point from 3m back along -x, the same shape of
## approach a chase/patrol would make -- a vertical drop test cannot catch a
## sweep-collision artifact; only a moving shape-cast can.
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
	print("=== PASS 1: live shipped state, collision_shape_size=%s ===" % terrain.get("collision_shape_size"))
	await _test_all_points(world)

	print("")
	print("=== correcting collision_shape_size to 64, in-tree (what BAKE-GUARDS achieves) ===")
	terrain.set("collision_shape_size", 64)
	var applied: int = int(terrain.get("collision_shape_size"))
	print("readback: %d" % applied)
	for i in 10:
		await physics_frame

	print("")
	print("=== PASS 2: collision_shape_size=%d ===" % applied)
	await _test_all_points(world)

	quit(0)


func _test_all_points(world: Node) -> void:
	var field := HEIGHTFIELD.new()
	for entry: Dictionary in POINTS:
		await _test_point(world, field, entry["label"], entry["x"], entry["z"])


func _test_point(world: Node, field: RefCounted, label: String, x: float, z: float) -> void:
	var body := CharacterBody3D.new()
	body.floor_max_angle = deg_to_rad(55.0)  # creature.tscn's own value -- the MORE permissive of the two
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.2
	var coll := CollisionShape3D.new()
	coll.shape = shape
	body.add_child(coll)
	root.add_child(body)

	var start_x := x - APPROACH_DISTANCE
	var ground: float = float(field.call("height_at", start_x, z))
	body.global_position = Vector3(start_x, ground + 1.0, z)
	body.velocity = Vector3.ZERO
	for i in 10:
		await physics_frame

	var start_pos := body.global_position
	var stuck_frames := 0
	var worst_stuck := 0
	var on_wall_frames := 0
	for i in WALK_FRAMES:
		body.velocity.x = SPEED
		body.velocity.z = 0.0
		if not body.is_on_floor():
			body.velocity.y -= 0.163  # ~9.8 m/s^2 at 60fps physics tick
		else:
			body.velocity.y = 0.0
		body.move_and_slide()
		await physics_frame
		if body.is_on_wall():
			on_wall_frames += 1
		if body.velocity.length() < 0.05 and i > 5:
			stuck_frames += 1
			worst_stuck = maxi(worst_stuck, stuck_frames)
		else:
			stuck_frames = 0

	var final_pos := body.global_position
	var travelled := final_pos.x - start_pos.x
	print("  %s: start_x=%.2f end_x=%.2f travelled=%.2fm (of %.2fm attempted) on_wall_frames=%d/%d worst_stuck_streak=%d" % [
		label, start_pos.x, final_pos.x, travelled, SPEED * WALK_FRAMES / 60.0, on_wall_frames, WALK_FRAMES, worst_stuck
	])
	if travelled < APPROACH_DISTANCE * 0.5:
		print("    ^ WEDGED: covered less than half the approach distance")

	body.queue_free()
