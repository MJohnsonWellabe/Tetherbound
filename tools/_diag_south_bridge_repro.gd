extends SceneTree

## Scratch: does the South Bridge entombment need the SAME play history
## smoke_traversal.gd has before it reaches the bridge (perimeter walk, then
## the kill-volume respawn), or does it reproduce from a bare teleport?
## probe_south_bridge_gully.gd's own single-teleport run came back clean, so
## this replays the real sequence to find out what's different.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

const WORLD_X_WEST := -1024.0
const WORLD_X_EAST := 1024.0
const WORLD_Z_NORTH := -512.0
const WORLD_Z_SOUTH := 7680.0
const PERIMETER_APPROACH_MARGIN := 35.0
const PERIMETER_WALK_FRAMES := 600
const KILL_TEST_Y := -150.0
const KILL_SETTLE_FRAMES := 30

const PERIMETER_STATIONS := [
	{"label": "west @ village", "edge": "west", "other": 200.0},
	{"label": "east @ village", "edge": "east", "other": 200.0},
	{"label": "west @ Band 2 midpoint", "edge": "west", "other": 2270.0},
	{"label": "east @ Band 2 midpoint", "edge": "east", "other": 2270.0},
	{"label": "west @ the marsh", "edge": "west", "other": 4000.0},
	{"label": "west @ stronghold approach", "edge": "west", "other": 7200.0},
	{"label": "east @ stronghold approach", "edge": "east", "other": 7200.0},
	{"label": "north cap", "edge": "north", "other": 60.0},
	{"label": "south cap", "edge": "south", "other": 500.0},
]

const PROBE_M := 0.45
const STEP_HEIGHT := 0.35


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame
	print("world settled")

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var camera_rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	var bridge: Node3D = world.get_node_or_null(^"SouthBridge") as Node3D
	if player == null or camera_rig == null or bridge == null:
		print("missing a node: player=%s camera_rig=%s bridge=%s" % [player, camera_rig, bridge])
		quit(1)
		return

	print("--- walking the perimeter, exactly as smoke_traversal.gd does ---")
	for entry in PERIMETER_STATIONS:
		var station: Dictionary = entry
		var edge: String = str(station["edge"])
		var other: float = float(station["other"])
		var start_xz := Vector2.ZERO
		var outward := Vector3.ZERO
		match edge:
			"west":
				start_xz = Vector2(WORLD_X_WEST + PERIMETER_APPROACH_MARGIN, other)
				outward = Vector3(-1.0, 0.0, 0.0)
			"east":
				start_xz = Vector2(WORLD_X_EAST - PERIMETER_APPROACH_MARGIN, other)
				outward = Vector3(1.0, 0.0, 0.0)
			"north":
				start_xz = Vector2(other, WORLD_Z_NORTH + PERIMETER_APPROACH_MARGIN)
				outward = Vector3(0.0, 0.0, -1.0)
			"south":
				start_xz = Vector2(other, WORLD_Z_SOUTH - PERIMETER_APPROACH_MARGIN)
				outward = Vector3(0.0, 0.0, 1.0)
		var ground: float = float(world.call("ground_height_at", start_xz.x, start_xz.y))
		if is_nan(ground):
			print("  %s: no ground, skipped" % station["label"])
			continue
		player.global_position = Vector3(start_xz.x, ground + 1.0, start_xz.y)
		player.velocity = Vector3.ZERO
		camera_rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(outward, Vector3.UP))
		for i2 in 10:
			await physics_frame
		Input.action_press("move_forward")
		for i2 in PERIMETER_WALK_FRAMES:
			await physics_frame
		Input.action_release("move_forward")
		for i2 in 20:
			await physics_frame
		print("  %s: walked to %s" % [station["label"], str(player.global_position)])

	print("--- kill volume ---")
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(0.0, KILL_TEST_Y, 0.0)
	for i in KILL_SETTLE_FRAMES:
		await physics_frame
	print("  after kill volume: %s" % str(player.global_position))

	print("--- now the South Bridge site ---")
	var site: Vector2 = bridge.call("near_point", 11.0)
	var ground2: float = float(world.call("ground_height_at", site.x, site.y))
	print("  site %s  ground_height_at=%.3f" % [str(site), ground2])
	player.global_position = Vector3(site.x, ground2 + 1.0, site.y)
	player.velocity = Vector3.ZERO
	var previous := player.global_position
	var max_step := 0.0
	var depenetration_events := 0
	for i in 90:
		await physics_frame
		var here := player.global_position
		var step := here.distance_to(previous)
		max_step = maxf(max_step, step)
		if step > 5.0:
			depenetration_events += 1
		previous = here
		if player.call("is_on_floor"):
			break
	for i in 10:
		await physics_frame
	var raised := player.global_transform.translated(Vector3.UP * STEP_HEIGHT)
	var sealed := true
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var dir := Vector3(sin(angle), 0.0, cos(angle))
		if not player.test_move(raised, dir * PROBE_M):
			sealed = false
			break
	print("  final position: %s  max_step=%.2f  depenetration_events=%d  sealed=%s" % [
		str(player.global_position), max_step, depenetration_events, sealed])

	quit(0 if not sealed else 1)
