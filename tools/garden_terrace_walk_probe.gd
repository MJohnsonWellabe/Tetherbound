extends SceneTree

## P2-011 claude-r1 walk probe (audit evidence, not progression proof).
## Loads the production Water world with whatever garden flag is on disk and
## walks a CharacterBody3D with the player's own capsule (r 0.4, h 1.8) and
## floor settings (45 deg, snap 0.4) from the dry beach up the entry ramp and
## every switchback to the top level, then checks a control walk on open
## ground beside the terraces. Prints one line per leg and a final verdict.
##   xvfb-run -a godot --path . --script tools/garden_terrace_walk_probe.gd

const SPEED := 4.5
const LEG_TIMEOUT_S := 25.0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node("/root/Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	var world := (load("res://scenes/world/water_archipelago.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(world)
	while world.has_method("shell_build_complete") and not bool(world.call("shell_build_complete")):
		await process_frame
	for i in 10:
		await physics_frame
	var garden := world.get_node_or_null("WaterGardenTerracesClaude")
	if garden == null or not bool(garden.get("_enabled")):
		print("WALK PROBE: candidate is OFF; nothing to walk")
		quit(2)
		return
	var body := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	body.add_child(shape)
	body.floor_max_angle = 0.7854
	body.floor_snap_length = 0.4
	world.add_child(body)
	var ramps: Array = garden.get("_ramps")
	var by_id := {}
	for ramp: Dictionary in ramps:
		by_id[str(ramp.id)] = ramp
	# Path: beach foot -> entry ramp -> each switchback, foot to head.
	var waypoints: Array[Vector3] = []
	for id: String in ["EntryFromExistingGround", "PoolToLower", "LowerToMiddle", "MiddleToUpper"]:
		var ramp: Dictionary = by_id[id]
		var a: Vector3 = ramp.a
		var b: Vector3 = ramp.b
		var direction := (b - a).normalized()
		waypoints.append(a - Vector3(direction.x, 0, direction.z) * 2.5)
		waypoints.append(b + Vector3(direction.x, 0, direction.z) * 2.0)
	var start := waypoints[0]
	body.global_position = Vector3(start.x, float(world.call("ground_height_at", start.x, start.z)) + 0.3, start.z)
	var ok := true
	for index in range(1, waypoints.size()):
		var reached := await _walk(body, waypoints[index])
		var built := float(garden.call("built_floor_height_at", body.global_position.x, body.global_position.z))
		print("WALK LEG %d -> (%.1f, %.1f): reached=%s at y=%.2f floor=%.2f" % [index, waypoints[index].x, waypoints[index].z, reached, body.global_position.y, built])
		ok = ok and reached
	var top_y := float((garden.get("_ramps") as Array)[-1].b[1])
	print("WALK TOP: body y %.2f vs upper level %.2f" % [body.global_position.y, top_y])
	ok = ok and absf(body.global_position.y - top_y) < 0.6
	# Control: open dune beside the terraces is still plain terrain.
	var control_from := Vector3(1085.0, 0.0, 2190.0)
	var control_to := Vector3(1100.0, 0.0, 2230.0)
	body.global_position = Vector3(control_from.x, float(world.call("ground_height_at", control_from.x, control_from.z)) + 0.3, control_from.z)
	var control := await _walk(body, control_to)
	print("WALK CONTROL open dune: reached=%s built_floor=%s" % [control, str(garden.call("built_floor_height_at", control_to.x, control_to.z))])
	ok = ok and control
	print("WALK PROBE %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _walk(body: CharacterBody3D, target: Vector3) -> bool:
	var elapsed := 0.0
	while elapsed < LEG_TIMEOUT_S:
		var flat := Vector2(target.x - body.global_position.x, target.z - body.global_position.z)
		if flat.length() < 0.6:
			return true
		var direction := flat.normalized() * SPEED
		body.velocity = Vector3(direction.x, body.velocity.y - 9.8 * (1.0 / 60.0), direction.y)
		if body.is_on_floor():
			body.velocity.y = minf(body.velocity.y, 0.0)
		body.move_and_slide()
		elapsed += 1.0 / 60.0
		# Several steps per frame: static colliders only, so the space state
		# needs no per-step sync and the probe stays fast under load.
		if int(elapsed * 60.0) % 30 == 0:
			await physics_frame
	return false
