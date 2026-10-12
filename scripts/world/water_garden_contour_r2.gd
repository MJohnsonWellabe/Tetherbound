extends Node3D
## P2-011 independent rough candidate. Source-built support is identical for
## normal worlds, simulation worlds and every peer. No durable state or terrain
## override: the OFF flag gates the complete candidate, including floor claims.
const CONFIG := "res://data/config/water_garden_contour_r2.json"
const ASSETS := preload("res://scripts/world/water_blockout_assets.gd")
const CELL_M := 2.0

var _world: Node3D
var _tops: Array[PackedVector3Array] = []
var _cells: Dictionary = {}
var _ramps: Array[Dictionary] = []
var _enabled := false


func build(world: Node3D) -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not bool(cfg.get("contour_terraces_r2_enabled", false)): return
	_world = world
	var surfaces: Array[Dictionary] = []
	for row: Dictionary in cfg.ramps:
		_ramps.append({"id": str(row.id), "a": _v3(row.a), "b": _v3(row.b), "polygon": _polygon(row.outline_xz)})
	for row: Dictionary in cfg.floors:
		var faces := PackedVector3Array()
		var edges: Dictionary = {}
		var angular_steps := int(ceil(float(row.arc_width_m) / float(cfg.maximum_cell_m)))
		var radial_steps := int(ceil((float(row.radius_outer_m) - float(row.radius_inner_m)) / float(cfg.maximum_cell_m)))
		for radial in radial_steps:
			var r0 := lerpf(float(row.radius_inner_m), float(row.radius_outer_m), float(radial) / radial_steps)
			var r1 := lerpf(float(row.radius_inner_m), float(row.radius_outer_m), float(radial + 1) / radial_steps)
			for angular in angular_steps:
				var t0 := lerpf(float(row.angle_start_deg), float(row.angle_end_deg), float(angular) / angular_steps)
				var t1 := lerpf(float(row.angle_start_deg), float(row.angle_end_deg), float(angular + 1) / angular_steps)
				var cell := PackedVector2Array([_polar(cfg, r0, t0), _polar(cfg, r1, t0), _polar(cfg, r1, t1), _polar(cfg, r0, t1)])
				for polygon: PackedVector2Array in _without_ramps(cell):
					_append_flat(polygon, float(row.top_y), faces)
					_boundary_edges(polygon, float(row.top_y), edges)
		surfaces.append({"id": str(row.id), "faces": faces, "edges": edges})
	for ramp: Dictionary in _ramps:
		var faces := PackedVector3Array()
		var edges: Dictionary = {}
		var polygon: PackedVector2Array = ramp.polygon
		var indices := Geometry2D.triangulate_polygon(polygon)
		for i in range(0, indices.size(), 3):
			_append_triangle(faces, _ramp_point(ramp, polygon[indices[i]]), _ramp_point(ramp, polygon[indices[i + 1]]), _ramp_point(ramp, polygon[indices[i + 2]]))
		# Split long borders so the wall base follows the existing terrain.
		for i in polygon.size():
			var a := _ramp_point(ramp, polygon[i])
			var b := _ramp_point(ramp, polygon[(i + 1) % polygon.size()])
			var steps := int(ceil(a.distance_to(b) / float(cfg.maximum_cell_m)))
			for j in steps:
				_store_edge(a.lerp(b, float(j) / steps), a.lerp(b, float(j + 1) / steps), edges)
		surfaces.append({"id": str(ramp.id), "faces": faces, "edges": edges})
	# Validate the complete candidate before publishing any support or bodies.
	for surface: Dictionary in surfaces:
		if (surface.faces as PackedVector3Array).is_empty():
			push_error("Garden r2 empty support: " + str(surface.id))
			return
		for point: Vector3 in surface.faces:
			var ground := float(world.call("ground_height_at", point.x, point.z))
			if not is_finite(ground) or ground > point.y + 0.05:
				push_error("Garden r2 support intersects terrain: " + str(surface.id))
				return
		var walls := PackedVector3Array()
		for edge: Dictionary in surface.edges.values():
			if int(edge.count) != 1: continue
			var a: Vector3 = edge.a
			var b: Vector3 = edge.b
			var ga := float(world.call("ground_height_at", a.x, a.z))
			var gb := float(world.call("ground_height_at", b.x, b.z))
			if not is_finite(ga) or not is_finite(gb):
				push_error("Garden r2 nonfinite wall footing")
				return
			var bottom_a := Vector3(a.x, minf(ga, a.y) - float(cfg.footing_depth_m), a.z)
			var bottom_b := Vector3(b.x, minf(gb, b.y) - float(cfg.footing_depth_m), b.z)
			walls.append_array(PackedVector3Array([a, bottom_a, bottom_b, a, bottom_b, b]))
		surface["walls"] = walls
	var presentation := not bool(world.get("simulation_only"))
	var soil: Material = null
	var stone: Material = null
	if presentation:
		soil = _material(str(cfg.soil_texture), str(cfg.soil_tint), float(cfg.soil_texture_scale))
		stone = _material(str(cfg.stone_texture), str(cfg.stone_tint), float(cfg.stone_texture_scale))
	for surface: Dictionary in surfaces:
		var top_faces: PackedVector3Array = surface.faces
		for i in range(0, top_faces.size(), 3):
			_index_triangle(PackedVector3Array([top_faces[i], top_faces[i + 1], top_faces[i + 2]]))
		var body := StaticBody3D.new()
		body.name = str(surface.id)
		body.collision_layer = 1
		body.collision_mask = 1
		add_child(body)
		var all_faces := top_faces.duplicate()
		all_faces.append_array(surface.walls)
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(all_faces)
		var collider := CollisionShape3D.new()
		collider.name = "MatchedTopAndRetainingWalls"
		collider.shape = shape
		body.add_child(collider)
		if presentation:
			_mesh(body, "LevelSoilOrConnector", top_faces, soil)
			_mesh(body, "ContinuousRetainingWalls", surface.walls, stone)
	_enabled = true
	if presentation:
		_plant_rows(cfg)
		_lower_pool(cfg)
		preload("res://scripts/world/water_garden_detail.gd").apply(self, cfg)


## Only the exact collidable top triangles claim support; no broad sector box.
func built_floor_height_at(x: float, z: float) -> float:
	if not _enabled: return NAN
	var key := Vector2i(int(floor(x / CELL_M)), int(floor(z / CELL_M)))
	for index: int in _cells.get(key, []):
		var tri: PackedVector3Array = _tops[index]
		var a := Vector2(tri[0].x, tri[0].z)
		var u := Vector2(tri[1].x, tri[1].z) - a
		var v := Vector2(tri[2].x, tri[2].z) - a
		var p := Vector2(x, z) - a
		var denominator := u.cross(v)
		var s := p.cross(v) / denominator
		var t := u.cross(p) / denominator
		if s >= -0.00001 and t >= -0.00001 and s + t <= 1.00001:
			return tri[0].y + s * (tri[1].y - tri[0].y) + t * (tri[2].y - tri[0].y)
	return NAN


func hide_previous_presentation(dressing: Node3D) -> void:
	if not _enabled: return
	var previous := dressing.get_node_or_null("DrownedGardenTerraceCourses") as Node3D
	if previous != null: previous.visible = false


func _without_ramps(polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = [polygon]
	for ramp: Dictionary in _ramps:
		var next: Array[PackedVector2Array] = []
		for piece: PackedVector2Array in result:
			for clipped: PackedVector2Array in Geometry2D.clip_polygons(piece, ramp.polygon):
				next.append(clipped)
		result = next
	return result


func _append_flat(polygon: PackedVector2Array, y: float, faces: PackedVector3Array) -> void:
	var indices := Geometry2D.triangulate_polygon(polygon)
	for i in range(0, indices.size(), 3):
		var a := polygon[indices[i]]
		var b := polygon[indices[i + 1]]
		var c := polygon[indices[i + 2]]
		_append_triangle(faces, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y))


func _append_triangle(faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a)
	if absf(normal.y) < 0.000001: return
	faces.append_array(PackedVector3Array([a, b, c] if normal.y > 0.0 else [a, c, b]))


func _boundary_edges(polygon: PackedVector2Array, y: float, edges: Dictionary) -> void:
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		_store_edge(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), edges)


func _store_edge(a: Vector3, b: Vector3, edges: Dictionary) -> void:
	if a.distance_squared_to(b) < 0.000001: return
	var a_key := "%d,%d" % [roundi(a.x * 10000.0), roundi(a.z * 10000.0)]
	var b_key := "%d,%d" % [roundi(b.x * 10000.0), roundi(b.z * 10000.0)]
	var key := a_key + ":" + b_key if a_key < b_key else b_key + ":" + a_key
	if edges.has(key):
		edges[key].count += 1
	else:
		edges[key] = {"a": a, "b": b, "count": 1}


func _index_triangle(tri: PackedVector3Array) -> void:
	var index := _tops.size()
	_tops.append(tri)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p: Vector3 in tri:
		lo = lo.min(Vector2(p.x, p.z))
		hi = hi.max(Vector2(p.x, p.z))
	for x in range(int(floor(lo.x / CELL_M)), int(floor(hi.x / CELL_M)) + 1):
		for z in range(int(floor(lo.y / CELL_M)), int(floor(hi.y / CELL_M)) + 1):
			var key := Vector2i(x, z)
			if not _cells.has(key): _cells[key] = []
			_cells[key].append(index)


func _plant_rows(cfg: Dictionary) -> void:
	for row: Dictionary in cfg.floors:
		for radius: float in [float(row.radius_inner_m) + 1.0, float(row.radius_outer_m) - 1.0]:
			for angle in range(-125, -104, 2):
				var at := _polar(cfg, radius, float(angle))
				var near_ramp := false
				for ramp: Dictionary in _ramps:
					var a: Vector3 = ramp.a
					var b: Vector3 = ramp.b
					var nearest := Geometry2D.get_closest_point_to_segment(at, Vector2(a.x, a.z), Vector2(b.x, b.z))
					if at.distance_to(nearest) < 3.0: near_ramp = true
				if near_ramp or not is_equal_approx(built_floor_height_at(at.x, at.y), float(row.top_y)): continue
				var plant := ASSETS.piece(str(cfg.plant_model), _v3(cfg.plant_size_m))
				if plant == null: continue
				add_child(plant)
				plant.position = Vector3(at.x, float(row.top_y), at.y)
				plant.rotation.y = deg_to_rad(float(angle))


func _lower_pool(cfg: Dictionary) -> void:
	var faces := PackedVector3Array()
	for angle in range(-119, -108):
		var polygon := PackedVector2Array([_polar(cfg, 116.0, angle), _polar(cfg, 120.0, angle), _polar(cfg, 120.0, angle + 1), _polar(cfg, 116.0, angle + 1)])
		for piece: PackedVector2Array in _without_ramps(polygon):
			_append_flat(piece, float(cfg.floors[0].top_y) + float(cfg.pool_depth_m), faces)
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("477e83")
	water.roughness = 0.16
	_mesh(self, "LowestLevelStandingWater", faces, water)


func _mesh(parent: Node3D, label: String, faces: PackedVector3Array, material: Material) -> void:
	if faces.is_empty(): return
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point: Vector3 in faces:
		surface.set_uv(Vector2(point.x, point.z))
		surface.add_vertex(point)
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = surface.commit()
	mesh.material_override = material
	parent.add_child(mesh)


func _material(texture: String, tint: String, scale_m: float) -> Material:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(texture) as Texture2D
	material.albedo_color = Color(tint)
	material.roughness = 1.0
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * scale_m
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _ramp_point(ramp: Dictionary, point: Vector2) -> Vector3:
	var a: Vector3 = ramp.a
	var b: Vector3 = ramp.b
	var delta := Vector2(b.x - a.x, b.z - a.z)
	var t := (point - Vector2(a.x, a.z)).dot(delta) / delta.length_squared()
	return Vector3(point.x, lerpf(a.y, b.y, t), point.y)


func _polar(cfg: Dictionary, radius: float, degrees: float) -> Vector2:
	return Vector2(float(cfg.origin_xz[0]), float(cfg.origin_xz[1])) + Vector2(cos(deg_to_rad(degrees)), sin(deg_to_rad(degrees))) * radius


func _polygon(values: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Array in values: result.append(Vector2(float(point[0]), float(point[1])))
	return result


func _v3(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
