extends Node3D

## P2-076 (GPU 6.92): the Kelm and Veyra dialogue frames looked onto a bare,
## flat dirt plaza. This lays installed Quaternius stone paving under each
## speaker's backdrop and stands a few installed props behind them, from
## cloudreach_look.json `dialogue_backdrops` (OFF by default).
##
## Visual only: no collision, so nothing changes where anyone can walk or
## fight; speakers, prompts and cameras are not moved. Paving follows the
## realm's own `ground_height_at` and is skipped wherever the ground under a
## tile is not flat, so a slab never floats over a ledge. Props keep their
## authored materials (no red/oxblood introduced here).

var _world: Node3D = null
var _cache: Dictionary = {}


func build(world: Node3D, cfg: Dictionary) -> void:
	_world = world
	_raycast = bool(cfg.get("raycast_ground", true))
	# Colliders the realm built this frame are only queryable after a physics
	# step; wait two before casting down onto them.
	if _raycast and is_inside_tree():
		for _frame in 2:
			await get_tree().physics_frame
	for raw: Variant in cfg.get("sites", []):
		if raw is Dictionary:
			_build_site(raw as Dictionary, cfg)


var _raycast := true


## The walkable surface under (x, z): a ray cast down onto the realm's real
## static colliders (crowns, terraces, floors), skipping characters and
## creatures. Falls back to the analytic ground_height_at with no collider.
func _surface(x: float, z: float, hint: float) -> float:
	if _raycast and is_inside_tree() and get_world_3d() != null:
		var space := get_world_3d().direct_space_state
		var query := PhysicsRayQueryParameters3D.create(Vector3(x, hint + 12.0, z), Vector3(x, hint - 12.0, z))
		query.collide_with_areas = false
		var exclude: Array[RID] = []
		for _try in 4:
			query.exclude = exclude
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				break
			var collider: Object = hit.get("collider")
			if collider is CharacterBody3D or collider is RigidBody3D:
				exclude.append(hit.get("rid"))
				continue
			return float((hit.position as Vector3).y)
	return _ground(x, z, hint)


func _build_site(site: Dictionary, cfg: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "Backdrop_%s" % str(site.get("id", "site"))
	add_child(root)
	var centre_raw: Array = site.get("centre", [0.0, 0.0, 0.0])
	var centre := Vector3(float(centre_raw[0]), float(centre_raw[1]), float(centre_raw[2]))
	var paving: Dictionary = site.get("paving", {})
	if not paving.is_empty():
		_lay_paving(root, centre, paving, cfg)
	for prop: Variant in site.get("props", []):
		if prop is Dictionary:
			_place_prop(root, centre, prop as Dictionary)


func _ground(x: float, z: float, hint: float) -> float:
	var y := float(_world.call("ground_height_at", x, z)) if _world != null and _world.has_method("ground_height_at") else hint
	return y if is_finite(y) else NAN


func _lay_paving(root: Node3D, centre: Vector3, paving: Dictionary, cfg: Dictionary) -> void:
	var scene := _scene(str(paving.get("model", cfg.get("paving_model", ""))))
	if scene == null:
		return
	var probe := scene.instantiate() as Node3D
	var tile := _footprint(probe)
	probe.free()
	var step := maxf(0.5, maxf(tile.x, tile.y) * float(paving.get("scale", 1.0)))
	var offset_raw: Array = paving.get("offset", [0.0, 0.0])
	var mid := Vector2(centre.x + float(offset_raw[0]), centre.z + float(offset_raw[1]))
	var half_raw: Array = paving.get("half_extents_m", [6.0, 6.0])
	var half := Vector2(float(half_raw[0]), float(half_raw[1]))
	var round_edge := bool(paving.get("ellipse", true))
	var flat_tol := float(paving.get("flat_tolerance_m", 0.18))
	var sink := float(paving.get("sink_m", 0.02))
	var skip_raw: Array = paving.get("skip_within_m_of", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(paving.get("seed", 76))
	var placed := 0
	var rejected := 0
	var nx := int(ceil(half.x / step))
	var nz := int(ceil(half.y / step))
	for ix in range(-nx, nx + 1):
		for iz in range(-nz, nz + 1):
			var at := mid + Vector2(ix * step, iz * step)
			var rel := Vector2((at.x - mid.x) / maxf(half.x, 0.01), (at.y - mid.y) / maxf(half.y, 0.01))
			if (round_edge and rel.length() > 1.0) or absf(rel.x) > 1.0 or absf(rel.y) > 1.0:
				continue
			# Ragged rim: the outer ring drops some slabs so the edge reads laid,
			# not stamped.
			if round_edge and rel.length() > 0.8 and rng.randf() < float(paving.get("rim_drop", 0.35)):
				continue
			var blocked := false
			for s: Variant in skip_raw:
				var sa: Array = s
				if at.distance_to(Vector2(float(sa[0]), float(sa[1]))) < float(sa[2]):
					blocked = true
			if blocked:
				continue
			var y := _surface(at.x, at.y, centre.y)
			if is_nan(y) or absf(y - centre.y) > float(paving.get("height_tolerance_m", 2.0)):
				rejected += 1
				continue
			var h := step * 0.45
			var flat := true
			for d: Vector2 in [Vector2(h, h), Vector2(-h, h), Vector2(h, -h), Vector2(-h, -h)]:
				var yy := _surface(at.x + d.x, at.y + d.y, y)
				if is_nan(yy) or absf(yy - y) > flat_tol:
					flat = false
					break
			if not flat:
				rejected += 1
				continue
			var slab := scene.instantiate() as Node3D
			_strip_collision(slab)
			slab.scale = Vector3.ONE * float(paving.get("scale", 1.0))
			slab.rotation.y = deg_to_rad(90.0 * rng.randi_range(0, 3))
			root.add_child(slab)
			slab.global_position = Vector3(at.x, y - sink, at.y)
			placed += 1
	root.set_meta("paving_tiles", placed)
	print("[cloudreach_backdrops] %s paving placed=%d rejected=%d step=%.2f" % [root.name, placed, rejected, step])


func _place_prop(root: Node3D, centre: Vector3, prop: Dictionary) -> void:
	var scene := _scene(str(prop.get("model", "")))
	if scene == null:
		return
	var off: Array = prop.get("offset", [0.0, 0.0])
	var x := centre.x + float(off[0])
	var z := centre.z + float(off[1])
	var y := _surface(x, z, centre.y)
	if is_nan(y) or absf(y - centre.y) > float(prop.get("height_tolerance_m", 2.5)):
		print("[cloudreach_backdrops] prop rejected %s" % str(prop.get("model", "")))
		return
	var node := scene.instantiate() as Node3D
	_strip_collision(node)
	node.scale = Vector3.ONE * float(prop.get("scale", 1.0))
	node.rotation.y = deg_to_rad(float(prop.get("yaw_deg", 0.0)))
	root.add_child(node)
	node.global_position = Vector3(x, y - float(prop.get("sink_m", 0.0)), z)


func _scene(path: String) -> PackedScene:
	if path.is_empty():
		return null
	if not _cache.has(path):
		_cache[path] = load(path) as PackedScene if ResourceLoader.exists(path) else null
	return _cache[path]


func _footprint(node: Node3D) -> Vector2:
	var box := AABB()
	var first := true
	for mi: Node in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var b := m.transform * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return Vector2(box.size.x, box.size.z)


func _strip_collision(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionObject3D or child is CollisionShape3D:
			child.queue_free()
		else:
			_strip_collision(child)
