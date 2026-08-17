extends SceneTree

## WALL1: the remaining 13% after BAKE-GUARDS. Two questions the COLL1 note
## left open, both answered directly against the live game rather than by
## reasoning:
##
## 1. Does the freeze coordinate sit near a HeightMapShape3D tile boundary
##    at the corrected shape_size=64? Found by walking Terrain3D's own
##    collision StaticBody3D children and reading each CollisionShape3D's
##    real world AABB, not by assuming a tiling origin.
## 2. When move_and_slide() reports is_on_wall()==true at the freeze point,
##    what collision normal does the physics engine actually report on that
##    frame? A seam/normal-discontinuity artifact should show a normal that
##    disagrees sharply with the ground's own analytic slope; a real close
##    call should show a normal consistent with a steep-but-legal grade.
##
##   godot --headless --path . --script tools/_probe_wedge_seam.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

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
	print("collision_shape_size (live): %s" % terrain.get("collision_shape_size"))
	print("region_size (live): %s" % terrain.get("region_size"))

	_dump_nearby_shapes(terrain)
	await _walk_and_report_normals(world)

	quit(0)


## Terrain3D's dynamic collision builds its shapes under an internal node.
## Walk the whole terrain subtree for CollisionShape3D and report every one
## whose global AABB is within 40m of the freeze point, sorted by distance,
## so tile boundaries near the freeze point are visible directly rather than
## assumed from a guessed tiling origin.
func _dump_nearby_shapes(terrain: Node) -> void:
	print("")
	print("--- CollisionShape3D tiles within 40m of freeze point (%.3f, %.3f) ---" % [FREEZE_X, FREEZE_Z])
	var found: Array = []
	_collect_shapes(terrain, found)
	print("total CollisionShape3D nodes found under Terrain: %d" % found.size())

	var near: Array = []
	for cs: CollisionShape3D in found:
		var gt := cs.global_transform
		var origin := gt.origin
		var dist := Vector2(origin.x - FREEZE_X, origin.z - FREEZE_Z).length()
		if dist <= 40.0:
			near.append({"node": cs, "dist": dist, "origin": origin})
	near.sort_custom(func(a, b): return a["dist"] < b["dist"])

	for entry: Dictionary in near:
		var cs: CollisionShape3D = entry["node"]
		var shape := cs.shape
		var extents := "?"
		if shape is HeightMapShape3D:
			var hm := shape as HeightMapShape3D
			extents = "HeightMapShape3D %dx%d" % [hm.map_width, hm.map_depth]
		elif shape is BoxShape3D:
			extents = "BoxShape3D size=%s" % (shape as BoxShape3D).size
		print("  %.2fm away  origin=(%.2f, %.2f, %.2f)  path=%s  shape=%s" % [
			entry["dist"], entry["origin"].x, entry["origin"].y, entry["origin"].z,
			cs.get_path(), extents])


func _collect_shapes(node: Node, out: Array) -> void:
	if node is CollisionShape3D:
		out.append(node)
	for child in node.get_children():
		_collect_shapes(child, out)


## Walk the creature-scale capsule across the freeze point exactly like
## _probe_wedge_repro.gd, but this time capture get_slide_collision() on
## every frame is_on_wall() is true: the reported normal, the collider, and
## the analytic ground slope at the body's own (x,z) that frame, side by
## side.
func _walk_and_report_normals(world: Node) -> void:
	var field := HEIGHTFIELD.new()
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
	var ground: float = float(field.call("height_at", start_x, FREEZE_Z))
	body.global_position = Vector3(start_x, ground + 1.0, FREEZE_Z)
	body.velocity = Vector3.ZERO
	for i in 10:
		await physics_frame

	print("")
	print("--- walk-across, frame-by-frame detail on every is_on_wall() frame ---")
	var wall_count := 0
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
			wall_count += 1
			var pos := body.global_position
			var slope_here: float = 0.0
			var normal_analytic := Vector3.UP
			# Central-difference slope of the analytic heightfield at this (x,z).
			var h_x0: float = float(field.call("height_at", pos.x - 0.25, pos.z))
			var h_x1: float = float(field.call("height_at", pos.x + 0.25, pos.z))
			var h_z0: float = float(field.call("height_at", pos.x, pos.z - 0.25))
			var h_z1: float = float(field.call("height_at", pos.x, pos.z + 0.25))
			var dx := (h_x1 - h_x0) / 0.5
			var dz := (h_z1 - h_z0) / 0.5
			normal_analytic = Vector3(-dx, 1.0, -dz).normalized()
			slope_here = rad_to_deg(normal_analytic.angle_to(Vector3.UP))

			var slide_count := body.get_slide_collision_count()
			print("  frame %3d  pos=(%.3f, %.3f, %.3f)  slide_collisions=%d  analytic_slope=%.1fdeg" % [
				i, pos.x, pos.y, pos.z, slide_count, slope_here])
			for s in slide_count:
				var col := body.get_slide_collision(s)
				var n: Vector3 = col.get_normal()
				var cp: Vector3 = col.get_position()
				var collider: Object = col.get_collider()
				var collider_desc := str(collider)
				if collider is Node:
					var cnode := collider as Node
					collider_desc = "%s  path=%s  parent=%s" % [cnode.name, cnode.get_path(), cnode.get_parent().name if cnode.get_parent() else "?"]
				print("      collision[%d] normal=(%.3f, %.3f, %.3f) angle_from_up=%.1fdeg  contact_pos=(%.3f, %.3f, %.3f)  collider=%s" % [
					s, n.x, n.y, n.z, rad_to_deg(n.angle_to(Vector3.UP)), cp.x, cp.y, cp.z, collider_desc])

	print("")
	print("total is_on_wall() frames: %d/%d" % [wall_count, WALK_FRAMES])
	body.queue_free()
