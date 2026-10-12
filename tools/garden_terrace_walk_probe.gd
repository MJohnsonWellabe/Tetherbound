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
	# Every level end to end on its inner and outer walk lines, and the pool
	# edge. A leg that stops reports where: ramp cuttings are expected walls.
	var floors: Array = []
	for child: Node in garden.get_children():
		if child is StaticBody3D and not str(child.name) in by_id:
			floors.append(str(child.name))
	var cfg: Dictionary = garden.get("_k")
	var origin := Vector2(float(cfg.origin_xz[0]), float(cfg.origin_xz[1]))
	for level: Dictionary in cfg.levels:
		for radial: float in [float(level.radius_inner_m) + 1.2, float(level.radius_outer_m) - 1.2]:
			var from := _polar(origin, radial, float(cfg.angle_start_deg) + 1.5)
			var to := _polar(origin, radial, float(cfg.angle_end_deg) - 1.5)
			body.global_position = Vector3(from.x, float(garden.call("built_floor_height_at", from.x, from.y)) + 0.3, from.y)
			var reached := await _walk(body, Vector3(to.x, 0.0, to.y))
			var stop := Vector2(body.global_position.x, body.global_position.z)
			print("WALK LEVEL (info; ramps cross some lines by design) %s r=%.1f end-to-end: reached=%s stopped_at_deg=%.1f near_ramp=%s y=%.2f" % [level.id, radial, reached,
				rad_to_deg((stop - origin).angle()), str(garden.call("_near_ramp", stop, 1.0)), body.global_position.y])
	var pool_from := _polar(origin, float(cfg.levels[0].radius_outer_m) - 1.0, float(cfg.angle_start_deg) + 6.5)
	var pool_to := _polar(origin, float(cfg.levels[0].radius_outer_m) - 1.0, float(cfg.angle_end_deg) - 1.5)
	body.global_position = Vector3(pool_from.x, float(garden.call("built_floor_height_at", pool_from.x, pool_from.y)) + 0.3, pool_from.y)
	var pool_ok := await _walk(body, Vector3(pool_to.x, 0.0, pool_to.y))
	print("WALK POOL EDGE: reached=%s y=%.2f" % [pool_ok, body.global_position.y])
	ok = ok and pool_ok
	var contour_same := _contour_identical(world)
	ok = ok and contour_same
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


static func _polar(origin: Vector2, radius: float, degrees: float) -> Vector2:
	return origin + Vector2(cos(deg_to_rad(degrees)), sin(deg_to_rad(degrees))) * radius


## Refactor safety: Codex's original contour script (tools/_lm copy of the
## pre-refactor source, flag forced ON) against the refactored _build_support
## with the same config. Collision faces, meshes and floor answers must match.
func _contour_identical(world: Node3D) -> bool:
	var old_path := "res://tools/_lm/contour_old.gd"
	if not FileAccess.file_exists(old_path):
		print("CONTOUR CHECK skipped: no pre-refactor copy")
		return true
	var old: Node3D = load(old_path).new()
	old.name = "ContourOld"
	world.add_child(old)
	old.call("build", world)
	var new: Node3D = load("res://scripts/world/water_garden_contour_r2.gd").new()
	new.name = "ContourNew"
	world.add_child(new)
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_garden_contour_r2.json"))
	cfg["contour_terraces_r2_enabled"] = true
	new.call("_build_support", world, cfg)
	var same := true
	var compared := 0
	for child: Node in old.get_children():
		if not child is StaticBody3D:
			continue
		var twin := new.get_node_or_null(NodePath(str(child.name)))
		if twin == null:
			same = false
			continue
		var a := (child.get_node("MatchedTopAndRetainingWalls") as CollisionShape3D).shape as ConcavePolygonShape3D
		var b := (twin.get_node("MatchedTopAndRetainingWalls") as CollisionShape3D).shape as ConcavePolygonShape3D
		same = same and a.get_faces() == b.get_faces()
		for mesh_name: String in ["LevelSoilOrConnector", "ContinuousRetainingWalls"]:
			var ma := (child.get_node(mesh_name) as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var mb := (twin.get_node(mesh_name) as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
			same = same and ma == mb
		compared += 1
	var floors_same := 0
	for x in range(1080, 1200, 3):
		for z in range(2110, 2200, 3):
			var ha := float(old.call("built_floor_height_at", float(x), float(z)))
			var hb := float(new.call("built_floor_height_at", float(x), float(z)))
			if (is_nan(ha) and is_nan(hb)) or ha == hb:
				floors_same += 1
			else:
				same = false
	print("CONTOUR CHECK bodies=%d floor_samples_equal=%d identical=%s" % [compared, floors_same, same])
	old.queue_free()
	new.queue_free()
	return same and compared > 0

