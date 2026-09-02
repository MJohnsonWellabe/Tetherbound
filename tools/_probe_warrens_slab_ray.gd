extends SceneTree

## VP6 WARRENS CLEAN RESTART -- identify the pale slab by RAY-CAST, not by
## reading burrow_warrens.gd and guessing.
##
##   godot --headless --path . --script tools/_probe_warrens_slab_ray.gd
##
## Boots the world exactly the way tools/_capture_locations.gd does for the
## `04-warrens` `standing` stand (marker entrance -> look_marker hall, rig
## back 3.2 / up 1.70 / look_up 1.6, FOV 70 vertical at 1280x720), then from
## that camera casts rays through the screen points the round-10 judge named
## and prints, for each: the physics hit (collider path, script, position,
## distance, nearest MeshInstance3D and its material) AND a geometric hit
## (every MeshInstance3D whose triangles the ray crosses, sorted by distance),
## so a decorative mesh with no collider cannot hide from the answer.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const BOOT_FRAMES := 90
const ARRIVE_FRAMES := 18
const SETTLE_FRAMES := 40
const FOV := 70.0
const ASPECT := 1280.0 / 720.0
const BACK := 3.2
const UP := 1.70
const LOOK_UP := 1.6
const RAY_LEN := 400.0
const MAX_FACES := 400000
const POINTS := [
	Vector2(0.80, 0.42), Vector2(0.20, 0.35), Vector2(0.85, 0.30), Vector2(0.15, 0.55),
	Vector2(0.75, 0.55), Vector2(0.92, 0.45), Vector2(0.10, 0.40), Vector2(0.30, 0.45),
]

var _world: Node
var _player: Node3D
var _camera: Camera3D


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame
	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	_player = _world.get_node_or_null(^"Player") as Node3D
	var warrens: Node = _world.get_node_or_null(^"BurrowWarrens")
	if _player == null or warrens == null:
		print("FAIL no Player / BurrowWarrens")
		quit(1)
		return
	var entrance: Vector3 = warrens.call("marker", "entrance")
	var hall: Vector3 = warrens.call("marker", "hall")
	print("entrance marker %s  hall marker %s  warrens at %s" % [entrance, hall, (warrens as Node3D).global_position])

	var eye := Vector2(entrance.x, entrance.z)
	var floor_hint := entrance.y
	var target := Vector2(hall.x, hall.z)
	var look_floor := hall.y
	var toward := (target - eye).normalized()
	eye = _clear_of_bodies(eye, toward, floor_hint)
	var back := eye - toward * BACK

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 4000.0
	_world.add_child(_camera)
	_camera.make_current()
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", _camera)

	_player.global_position = Vector3(eye.x, floor_hint + 0.4, eye.y)
	_frame(back, floor_hint, target, look_floor)
	for i in ARRIVE_FRAMES:
		await physics_frame
	_player.global_position = Vector3(eye.x, floor_hint + 0.4, eye.y)
	_frame(back, floor_hint, target, look_floor)
	for i in SETTLE_FRAMES:
		await physics_frame
	_frame(back, floor_hint, target, look_floor)
	await physics_frame

	print("camera at %s  basis -z %s  player at %s" % [
		_camera.global_position, -_camera.global_basis.z, _player.global_position])
	print("mouth outer z (local) %.2f" % float(warrens.call("_mouth_outer_z")))

	var meshes: Array[MeshInstance3D] = []
	for node in _all(_world):
		if node is MeshInstance3D and (node as MeshInstance3D).visible and (node as MeshInstance3D).is_visible_in_tree():
			meshes.append(node as MeshInstance3D)
	print("%d visible MeshInstance3D in tree" % meshes.size())

	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	for p: Vector2 in POINTS:
		var dir := _ray_dir(p)
		var origin := _camera.global_position
		print("")
		print("=== screen (%.2f, %.2f) dir %s" % [p.x, p.y, dir])
		# --- physics
		var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * RAY_LEN)
		query.collide_with_areas = false
		query.exclude = [(_player as CollisionObject3D).get_rid()] if _player is CollisionObject3D else []
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			print("  physics: no collider along the ray")
		else:
			var collider: Node = hit["collider"] as Node
			var pos: Vector3 = hit["position"]
			print("  physics: %s  dist %.2f  at %s  script %s" % [
				collider.get_path(), origin.distance_to(pos), pos, _script_of(collider)])
			var near := _nearest_mesh(collider)
			if near != null:
				print("    nearest mesh: %s  %s" % [near.get_path(), _describe(near)])
		# --- geometry
		var hits: Array = []
		for m in meshes:
			var d := _mesh_ray_distance(m, origin, dir)
			if d >= 0.0:
				hits.append({"d": d, "m": m})
		hits.sort_custom(func(a, b): return a["d"] < b["d"])
		var shown := 0
		for h: Dictionary in hits:
			var m: MeshInstance3D = h["m"]
			print("  geom %6.2fm  %s  at %s  script %s" % [h["d"], m.get_path(), m.global_position, _script_of(_owner_script_node(m))])
			print("         %s" % _describe(m))
			shown += 1
			if shown >= 4:
				break
		if hits.is_empty():
			print("  geometry: no mesh triangles along the ray")
	quit(0)


func _ray_dir(p: Vector2) -> Vector3:
	var t := tan(deg_to_rad(FOV * 0.5))
	var local := Vector3((2.0 * p.x - 1.0) * t * ASPECT, (1.0 - 2.0 * p.y) * t, -1.0).normalized()
	return (_camera.global_basis * local).normalized()


func _frame(eye: Vector2, eye_ground: float, target: Vector2, target_ground: float) -> void:
	_camera.global_position = Vector3(eye.x, eye_ground + UP, eye.y)
	_camera.look_at(Vector3(target.x, target_ground + LOOK_UP, target.y), Vector3.UP)


func _clear_of_bodies(eye: Vector2, toward: Vector2, ground: float) -> Vector2:
	var space: PhysicsDirectSpaceState3D = (_world as Node3D).get_world_3d().direct_space_state
	var aside := Vector2(-toward.y, toward.x).normalized()
	for attempt in 4:
		var candidate := eye if attempt == 0 else eye + aside * 2.0 * float(attempt)
		var query := PhysicsShapeQueryParameters3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.6
		capsule.height = 2.6
		query.shape = capsule
		query.transform = Transform3D(Basis(), Vector3(candidate.x, ground + 1.45, candidate.y))
		query.collide_with_bodies = true
		query.collide_with_areas = false
		if _player is CollisionObject3D:
			query.exclude = [(_player as CollisionObject3D).get_rid()]
		var blocker := ""
		for hit: Dictionary in space.intersect_shape(query, 4):
			var body: Node = hit.get("collider") as Node
			if body == null or _under_terrain(body):
				continue
			blocker = body.name
			break
		if blocker == "":
			if attempt > 0:
				print("  NOTE eye moved %.1fm aside" % (candidate - eye).length())
			return candidate
	return eye


func _under_terrain(body: Node) -> bool:
	var terrain: Node = _world.get_node_or_null(^"Terrain")
	var node: Node = body
	while node != null:
		if node == terrain:
			return true
		node = node.get_parent()
	return false


func _all(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_all(child))
	return out


func _script_of(node: Node) -> String:
	if node == null:
		return "-"
	var s: Variant = node.get_script()
	return (s as Script).resource_path if s != null else "(none)"


func _owner_script_node(node: Node) -> Node:
	var n: Node = node
	while n != null:
		if n.get_script() != null:
			return n
		n = n.get_parent()
	return null


func _nearest_mesh(collider: Node) -> MeshInstance3D:
	# the collider's own subtree, then its siblings, then its parent's subtree
	for cand in [collider, collider.get_parent()]:
		if cand == null:
			continue
		for n in _all(cand):
			if n is MeshInstance3D:
				return n as MeshInstance3D
	return null


func _describe(m: MeshInstance3D) -> String:
	var parts: Array[String] = []
	var aabb := m.global_transform * m.get_aabb()
	parts.append("aabb %s..%s" % [aabb.position, aabb.end])
	parts.append("mesh %s" % (m.mesh.get_class() if m.mesh != null else "null"))
	if m.material_override != null:
		parts.append("override=" + _mat(m.material_override))
	elif m.mesh != null:
		for s in m.mesh.get_surface_count():
			var mat := m.get_surface_override_material(s)
			if mat != null:
				parts.append("surf%d_override=" % s + _mat(mat))
			else:
				var mm := m.mesh.surface_get_material(s)
				parts.append("surf%d=" % s + (_mat(mm) if mm != null else "null"))
	return " | ".join(parts)


func _mat(mat: Material) -> String:
	if mat is StandardMaterial3D:
		var sm := mat as StandardMaterial3D
		return "Std(albedo=%s tex=%s triplanar=%s)" % [
			sm.albedo_color.to_html(false),
			sm.albedo_texture.resource_path if sm.albedo_texture != null else "none",
			sm.uv1_triplanar]
	if mat is ShaderMaterial:
		var sh := mat as ShaderMaterial
		var extra := ""
		for k in ["base_tint", "stain_colour", "albedo_tex", "tint"]:
			var v: Variant = sh.get_shader_parameter(k)
			if v != null:
				extra += " %s=%s" % [k, (v as Texture2D).resource_path if v is Texture2D else str(v)]
		return "Shader(%s%s)" % [sh.shader.resource_path if sh.shader != null else "null", extra]
	return mat.get_class()


## Distance along the ray to the first triangle of this mesh it crosses, or
## -1. AABB slab test first so only candidates pay for their faces.
func _mesh_ray_distance(m: MeshInstance3D, origin: Vector3, dir: Vector3) -> float:
	if m.mesh == null:
		return -1.0
	var aabb := m.global_transform * m.get_aabb()
	if not _ray_hits_aabb(aabb, origin, dir):
		return -1.0
	var faces := m.mesh.get_faces()
	if faces.size() > MAX_FACES or faces.is_empty():
		# too big to test exactly (terrain-sized); report the AABB entry instead
		return _aabb_entry(aabb, origin, dir)
	var xf := m.global_transform
	var best := -1.0
	var i := 0
	while i + 2 < faces.size():
		var a := xf * faces[i]
		var b := xf * faces[i + 1]
		var c := xf * faces[i + 2]
		var hit: Variant = Geometry3D.ray_intersects_triangle(origin, dir, a, b, c)
		if hit == null:
			hit = Geometry3D.ray_intersects_triangle(origin, dir, a, c, b)
		if hit != null:
			var d := origin.distance_to(hit as Vector3)
			if best < 0.0 or d < best:
				best = d
		i += 3
	return best


func _ray_hits_aabb(aabb: AABB, origin: Vector3, dir: Vector3) -> bool:
	return _aabb_entry(aabb, origin, dir) >= 0.0


func _aabb_entry(aabb: AABB, origin: Vector3, dir: Vector3) -> float:
	var tmin := -INF
	var tmax := INF
	for axis in 3:
		var o := origin[axis]
		var d := dir[axis]
		var lo := aabb.position[axis]
		var hi := aabb.end[axis]
		if absf(d) < 1e-6:
			if o < lo or o > hi:
				return -1.0
			continue
		var t1 := (lo - o) / d
		var t2 := (hi - o) / d
		tmin = maxf(tmin, minf(t1, t2))
		tmax = minf(tmax, maxf(t1, t2))
	if tmax < 0.0 or tmin > tmax or tmin > RAY_LEN:
		return -1.0
	return maxf(tmin, 0.0)
