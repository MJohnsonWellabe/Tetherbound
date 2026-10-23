extends "res://scripts/world/water_garden_contour_r2.gd"
## P2-011 claude-r1: the Drowned Garden as continuous, truly flat terraces.
## Each level runs from its own retaining wall back to the next level's wall
## (no raw sand strip between levels), its top set just above the highest
## sampled terrain in its band. Switchback ramps join the levels. Support and
## collision reuse the shared contour builder (exact top/wall triangles and
## bounded floor index); this class only lays out the levels and dresses them:
## installed brick masonry, pale coping, hanging vines, full planting beds
## from installed plants, and installed water.gdshader standing on the lowest
## level with darkened edges. Independent OFF flag; older candidates untouched.
const CLAUDE_CONFIG := "res://data/config/water_garden_terraces_claude.json"
const WATER_SHADER := preload("res://shaders/water.gdshader")

var _k: Dictionary


static func enabled() -> bool:
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLAUDE_CONFIG))
	return cfg is Dictionary and bool(cfg.get("garden_terraces_claude_enabled", false))


func build(world: Node3D) -> void:
	var k: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLAUDE_CONFIG))
	if not k is Dictionary or not bool(k.get("garden_terraces_claude_enabled", false)):
		return
	# The OFF Tidewake look gate may restyle presentation keys only (wall
	# texture/tint, vines); layout, support and colliders read unchanged keys.
	_k = preload("res://scripts/world/tidewake_look_profile.gd").overlay(k, "garden_terraces")
	var cfg := _layout(world)
	if cfg.is_empty():
		return
	_build_support(world, cfg)
	if not _enabled or bool(world.get("simulation_only")):
		return
	_dress(cfg)


## Contour-format support config: flat levels from sampled terrain and ramps.
func _layout(world: Node3D) -> Dictionary:
	var cfg := {
		"origin_xz": _k.origin_xz, "maximum_cell_m": _k.maximum_cell_m,
		"footing_depth_m": _k.footing_depth_m, "external_dressing": true,
		"soil_texture": _k.level_texture, "soil_tint": _k.level_tint, "soil_texture_scale": _k.level_texture_scale,
		"stone_texture": _k.wall_texture, "stone_tint": _k.wall_tint, "stone_texture_scale": _k.wall_texture_scale,
		"floors": [], "ramps": [],
	}
	var start := float(_k.angle_start_deg)
	var end := float(_k.angle_end_deg)
	var previous_top := -INF
	for level: Dictionary in _k.levels:
		var highest := -INF
		var r := float(level.radius_inner_m)
		while r <= float(level.radius_outer_m) + 0.01:
			var angle := start
			while angle <= end + 0.01:
				var at := _polar(cfg, r, angle)
				highest = maxf(highest, float(world.call("ground_height_at", at.x, at.y)))
				angle += 0.5
			r += 1.0
		if not is_finite(highest):
			push_error("Garden claude-r1 could not sample terrain for " + str(level.id))
			return {}
		var top := maxf(highest + float(_k.floor_clearance_m), previous_top + float(_k.minimum_rise_m))
		previous_top = top
		cfg.floors.append({"id": str(level.id), "radius_inner_m": float(level.radius_inner_m),
			"radius_outer_m": float(level.radius_outer_m), "angle_start_deg": start, "angle_end_deg": end,
			"top_y": top, "arc_width_m": deg_to_rad(end - start) * float(level.radius_outer_m)})
	var width := float(_k.ramp_width_m)
	for index in range(cfg.floors.size() - 1):
		var lower: Dictionary = cfg.floors[index]
		var upper: Dictionary = cfg.floors[index + 1]
		var spec: Dictionary = _k.ramps[index]
		var boundary := float(lower.radius_inner_m)
		var a2 := _polar(cfg, boundary + float(spec.low_offset_m), float(spec.from_deg))
		var b2 := _polar(cfg, boundary - float(spec.high_offset_m), float(spec.to_deg))
		cfg.ramps.append(_ramp(str(spec.id), Vector3(a2.x, float(lower.top_y), a2.y), Vector3(b2.x, float(upper.top_y), b2.y), width))
	var entry: Dictionary = _k.entry_ramp
	var foot := Vector2(float(entry.from_xz[0]), float(entry.from_xz[1]))
	var landing := _polar(cfg, float(entry.to_radius_m), float(entry.to_deg))
	var side := (landing - foot).normalized().orthogonal() * width * 0.5
	var foot_y := -INF
	for corner: Vector2 in [foot + side, foot - side, foot]:
		foot_y = maxf(foot_y, float(world.call("ground_height_at", corner.x, corner.y)))
	cfg.ramps.push_front(_ramp(str(entry.id), Vector3(foot.x, foot_y + 0.04, foot.y), Vector3(landing.x, float(cfg.floors[0].top_y), landing.y), width))
	return cfg


static func _ramp(id: String, a: Vector3, b: Vector3, width: float) -> Dictionary:
	var direction := Vector2(b.x - a.x, b.z - a.z).normalized()
	var side := direction.orthogonal() * width * 0.5
	var a2 := Vector2(a.x, a.z)
	var b2 := Vector2(b.x, b.z)
	return {"id": id, "a": [a.x, a.y, a.z], "b": [b.x, b.y, b.z], "width_m": width,
		"outline_xz": [[(a2 + side).x, (a2 + side).y], [(b2 + side).x, (b2 + side).y], [(b2 - side).x, (b2 - side).y], [(a2 - side).x, (a2 - side).y]]}


func _dress(cfg: Dictionary) -> void:
	var dressing := Node3D.new()
	dressing.name = "GardenClaudeDressing"
	add_child(dressing)
	var paving := _world_material(str(_k.paving_texture), str(_k.paving_tint), float(_k.paving_texture_scale))
	var pool_floor := _world_material(str(_k.paving_texture), str(_k.pool_floor_tint), float(_k.paving_texture_scale))
	var coping := _world_material(str(_k.coping_texture), str(_k.coping_tint), float(_k.coping_texture_scale))
	var bed := _world_material(str(_k.bed_texture), str(_k.bed_tint), float(_k.bed_texture_scale))
	var ramp_ids: Array[String] = []
	for ramp: Dictionary in cfg.ramps:
		ramp_ids.append(str(ramp.id))
	for child: Node in get_children():
		if child is StaticBody3D:
			var top := child.get_node_or_null("LevelSoilOrConnector") as MeshInstance3D
			if top == null:
				continue
			if str(child.name) in ramp_ids:
				top.material_override = paving
			elif str(child.name) == str(cfg.floors[0].id):
				top.material_override = pool_floor
	var lowest: Dictionary = cfg.floors[0]
	for row: Dictionary in cfg.floors:
		_coping(cfg, row, dressing, coping)
		_vines(cfg, row, dressing)
		if row != lowest:
			_beds(cfg, row, dressing, bed)
	_pool(cfg, lowest, dressing)
	_back_wall(cfg, cfg.floors[-1], dressing, coping)


## Pale flush coping along each retaining wall top and its two ends: a cap
## band plus a short face band, so the wall reads as built masonry.
func _coping(cfg: Dictionary, row: Dictionary, parent: Node3D, material: Material) -> void:
	var y := float(row.top_y)
	var faces := PackedVector3Array()
	var inner := float(row.radius_outer_m) - float(_k.coping_width_m)
	var outer := float(row.radius_outer_m) + float(_k.coping_overhang_m)
	var start := float(row.angle_start_deg)
	var end := float(row.angle_end_deg)
	var steps := int(ceil(deg_to_rad(end - start) * outer / 0.8))
	for i in steps:
		var a := lerpf(start, end, float(i) / steps)
		var b := lerpf(start, end, float(i + 1) / steps)
		var cap := PackedVector2Array([_polar(cfg, inner, a), _polar(cfg, outer, a), _polar(cfg, outer, b), _polar(cfg, inner, b)])
		for piece: PackedVector2Array in _without_ramps(cap):
			_append_flat(piece, y + float(_k.coping_rise_m), faces)
		# Face band hangs on the wall front unless a ramp passes here.
		var mid := _polar(cfg, outer, (a + b) * 0.5)
		var crossed := false
		for ramp: Dictionary in _ramps:
			var polygon: PackedVector2Array = ramp.polygon
			if Geometry2D.is_point_in_polygon(mid, polygon) or Geometry2D.is_point_in_polygon(_polar(cfg, inner, (a + b) * 0.5), polygon):
				crossed = true
		if not crossed:
			var p := _polar(cfg, outer, a)
			var q := _polar(cfg, outer, b)
			var top := y + float(_k.coping_rise_m)
			var low := y - float(_k.coping_face_m)
			faces.append_array(PackedVector3Array([Vector3(p.x, top, p.y), Vector3(q.x, top, q.y), Vector3(q.x, low, q.y),
				Vector3(p.x, top, p.y), Vector3(q.x, low, q.y), Vector3(p.x, low, p.y)]))
	_mesh(parent, str(row.id) + "Coping", faces, material)


## Uphill edge of the top level: a low retaining wall whose coping meets the
## dune just behind it, so the sand reads as held back rather than spilling
## onto the lawn. Render-only; it never rises more than back_wall_max_m.
func _back_wall(cfg: Dictionary, row: Dictionary, parent: Node3D, coping: Material) -> void:
	var stone := _world_material(str(_k.wall_texture), str(_k.wall_tint), float(_k.wall_texture_scale))
	var wall := PackedVector3Array()
	var cap := PackedVector3Array()
	var inner := float(row.radius_inner_m)
	var start := float(row.angle_start_deg)
	var end := float(row.angle_end_deg)
	var steps := int(ceil(deg_to_rad(end - start) * inner / 1.0))
	for i in steps:
		var a := lerpf(start, end, float(i) / steps)
		var b := lerpf(start, end, float(i + 1) / steps)
		_edge_segment(_polar(cfg, inner, a), _polar(cfg, inner, b), float(row.top_y), wall, cap)
	_mesh(parent, "UphillRetainingWall", wall, stone)
	_mesh(parent, "UphillRetainingCoping", cap, coping)
	# Cheek walls at both ends of every level hold back the dune beside them.
	var cheek_wall := PackedVector3Array()
	var cheek_cap := PackedVector3Array()
	for level: Dictionary in cfg.floors:
		for angle: float in [float(level.angle_start_deg), float(level.angle_end_deg)]:
			var r := float(level.radius_inner_m)
			while r < float(level.radius_outer_m) - 0.01:
				var r2 := minf(r + 1.0, float(level.radius_outer_m))
				var p := _polar(cfg, r, angle)
				var q := _polar(cfg, r2, angle)
				if not _near_ramp((p + q) * 0.5, 0.2):
					_edge_segment(p, q, float(level.top_y), cheek_wall, cheek_cap)
				r = r2
	_mesh(parent, "EndCheekWalls", cheek_wall, stone)
	_mesh(parent, "EndCheekCoping", cheek_cap, coping)


## One retaining segment p->q on a level edge: the face rises from just below
## the level to the dune height sampled outside the level, capped by coping.
func _edge_segment(p: Vector2, q: Vector2, y: float, wall: PackedVector3Array, cap: PackedVector3Array) -> void:
	var along := (q - p).normalized()
	var mid := (p + q) * 0.5
	var origin := Vector2(float(_k.origin_xz[0]), float(_k.origin_xz[1]))
	# Outside = the side away from the level's own floor.
	var normal := along.orthogonal()
	var test := mid + normal * 0.6
	if is_finite(float(built_floor_height_at(test.x, test.y))) and absf(float(built_floor_height_at(test.x, test.y)) - y) < 0.01:
		normal = -normal
	if mid.distance_to(origin) < 1.0:
		return
	var heights: Array[float] = []
	for at: Vector2 in [p, q]:
		var behind := at + normal * float(_k.back_wall_sample_m)
		var ground := float(_world.call("ground_height_at", behind.x, behind.y))
		heights.append(clampf(ground + 0.1 - y, float(_k.back_wall_min_m), float(_k.back_wall_max_m)))
	var low := y - 0.3
	wall.append_array(PackedVector3Array([Vector3(p.x, low, p.y), Vector3(q.x, low, q.y), Vector3(q.x, y + heights[1], q.y),
		Vector3(p.x, low, p.y), Vector3(q.x, y + heights[1], q.y), Vector3(p.x, y + heights[0], p.y)]))
	var inset := -normal * float(_k.coping_width_m)
	var over := normal * float(_k.coping_overhang_m)
	var hp := y + heights[0] + 0.05
	var hq := y + heights[1] + 0.05
	cap.append_array(PackedVector3Array([Vector3(p.x + inset.x, hp, p.y + inset.y), Vector3(p.x + over.x, hp, p.y + over.y), Vector3(q.x + over.x, hq, q.y + over.y),
		Vector3(p.x + inset.x, hp, p.y + inset.y), Vector3(q.x + over.x, hq, q.y + over.y), Vector3(q.x + inset.x, hq, q.y + inset.y)]))


## Installed medieval-kit vines hang from the coping over each wall face.
func _vines(cfg: Dictionary, row: Dictionary, parent: Node3D) -> void:
	var models: Array = _k.vine_models
	var spacing := float(_k.vine_spacing_m)
	var radius := float(row.radius_outer_m) + 0.05
	var arc := deg_to_rad(float(row.angle_end_deg) - float(row.angle_start_deg)) * radius
	var count := int(arc / spacing)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(row.id))
	for i in count:
		var angle := lerpf(float(row.angle_start_deg), float(row.angle_end_deg), (float(i) + rng.randf_range(0.25, 0.75)) / count)
		var at := _polar(cfg, radius, angle)
		if _near_ramp(at, 1.5) or rng.randf() > float(_k.vine_chance):
			continue
		var drop := rng.randf_range(1.6, 3.0)
		var vine := ASSETS.piece(str(models[rng.randi() % models.size()]), Vector3(rng.randf_range(1.2, 2.2), drop, 0.35))
		if vine == null:
			continue
		parent.add_child(vine)
		vine.position = Vector3(at.x, float(row.top_y) + 0.2 - drop, at.y)
		# Face outward, flat against the wall.
		vine.rotation.y = -deg_to_rad(angle) + PI * 0.5


## Full planting: a deep outer bed behind the coping, a narrow fern border
## along the next wall's foot, and occasional small trees on upper levels.
func _beds(cfg: Dictionary, row: Dictionary, parent: Node3D, soil: Material) -> void:
	var y := float(row.top_y)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(row.id)) + 7
	var faces := PackedVector3Array()
	for band: Dictionary in _k.bed_bands:
		var r0 := float(row.radius_outer_m) - float(band.from_outer_m)
		var r1 := float(row.radius_outer_m) - float(band.to_outer_m)
		if bool(band.get("inner_side", false)):
			r0 = float(row.radius_inner_m) + float(band.from_outer_m)
			r1 = float(row.radius_inner_m) + float(band.to_outer_m)
		var lo := minf(r0, r1)
		var hi := maxf(r0, r1)
		var start := float(row.angle_start_deg) + 0.6
		var end := float(row.angle_end_deg) - 0.6
		var steps := int(ceil(deg_to_rad(end - start) * hi / 1.0))
		for i in steps:
			var a := lerpf(start, end, float(i) / steps)
			var b := lerpf(start, end, float(i + 1) / steps)
			var cell := PackedVector2Array([_polar(cfg, lo, a), _polar(cfg, hi, a), _polar(cfg, hi, b), _polar(cfg, lo, b)])
			if _near_ramp(_polar(cfg, (lo + hi) * 0.5, (a + b) * 0.5), float(_k.ramp_clearance_m)):
				continue
			for piece: PackedVector2Array in _without_ramps(cell):
				_append_flat(piece, y + 0.02, faces)
		var palette: Array = band.plants
		var spacing := float(band.spacing_m)
		for radial in int(band.rows):
			var radius := lerpf(lo + 0.4, hi - 0.4, (float(radial) + 0.5) / float(band.rows))
			var angle := start + rad_to_deg(spacing / radius) * rng.randf()
			while angle < end:
				var at := _polar(cfg, radius + rng.randf_range(-0.3, 0.3), angle)
				if not _near_ramp(at, float(_k.ramp_clearance_m)) and is_equal_approx(built_floor_height_at(at.x, at.y), y):
					var pick: Dictionary = palette[rng.randi() % palette.size()]
					var size: Array = pick.size_m
					var jitter := rng.randf_range(0.8, 1.25)
					var plant := ASSETS.piece(str(pick.model), Vector3(float(size[0]), float(size[1]), float(size[2])) * jitter)
					if plant != null:
						parent.add_child(plant)
						plant.position = Vector3(at.x, y, at.y)
						plant.rotation.y = rng.randf() * TAU
				angle += rad_to_deg(spacing * rng.randf_range(0.75, 1.25) / radius)
	_mesh(parent, str(row.id) + "PlantingBeds", faces, soil)
	var trees: Dictionary = _k.trees
	if str(row.id) in trees.levels:
		var angle := float(row.angle_start_deg) + float(trees.inset_deg)
		while angle < float(row.angle_end_deg) - float(trees.inset_deg) + 0.01:
			var at := _polar(cfg, float(row.radius_outer_m) - float(trees.from_outer_m), angle)
			if not _near_ramp(at, float(_k.ramp_clearance_m) + 1.0):
				var models: Array = trees.models
				var tree := ASSETS.piece(str(models[rng.randi() % models.size()]), Vector3(float(trees.size_m[0]), float(trees.size_m[1]), float(trees.size_m[2])) * rng.randf_range(0.85, 1.15))
				if tree != null:
					parent.add_child(tree)
					tree.position = Vector3(at.x, y, at.y)
					tree.rotation.y = rng.randf() * TAU
			angle += float(trees.spacing_deg)


## Standing water over the whole lowest level, inside its coping and clear of
## the ramp feet. Installed water.gdshader; a material-only bank mask makes the
## margins shallow and dark (no terrain or collision change).
func _pool(cfg: Dictionary, row: Dictionary, parent: Node3D) -> void:
	var pool: Dictionary = _k.pool
	var r0 := float(row.radius_inner_m) + float(pool.inner_margin_m)
	var r1 := float(row.radius_outer_m) - float(_k.coping_width_m) - 0.05
	var start := float(row.angle_start_deg) + float(pool.end_margin_deg)
	var end := float(row.angle_end_deg) - float(pool.end_margin_deg)
	var surface_y := float(row.top_y) + float(pool.depth_m)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var steps := int(ceil(deg_to_rad(end - start) * r1 / 0.7))
	for i in steps:
		var a := lerpf(start, end, float(i) / steps)
		var b := lerpf(start, end, float(i + 1) / steps)
		var cell := PackedVector2Array([_polar(cfg, r0, a), _polar(cfg, r1, a), _polar(cfg, r1, b), _polar(cfg, r0, b)])
		# Exact ramp cut only: each ramp foot runs down into the water.
		for piece: PackedVector2Array in _without_ramps(cell):
			var indices := Geometry2D.triangulate_polygon(piece)
			for t in range(0, indices.size(), 3):
				for index: int in [indices[t], indices[t + 2], indices[t + 1]]:
					var p := piece[index]
					lo = lo.min(p)
					hi = hi.max(p)
					surface.set_uv(p)
					surface.add_vertex(Vector3(p.x, surface_y, p.y))
	surface.generate_normals()
	surface.generate_tangents()
	var mesh := surface.commit()
	if mesh.get_surface_count() == 0:
		return
	var water := MeshInstance3D.new()
	water.name = "LowestLevelPool"
	water.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = WATER_SHADER
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RF)
	var origin := Vector2(float(cfg.origin_xz[0]), float(cfg.origin_xz[1]))
	for z in size:
		for x in size:
			var at := lo + (hi - lo) * Vector2(float(x) / (size - 1), float(z) / (size - 1))
			var polar := at - origin
			var radius := polar.length()
			var angle := rad_to_deg(atan2(polar.y, polar.x))
			var edge := minf(radius - r0, r1 - radius)
			edge = minf(edge, deg_to_rad(minf(angle - start, end - angle)) * radius)
			for ramp: Dictionary in _ramps:
				var a: Vector3 = ramp.a
				var b: Vector3 = ramp.b
				edge = minf(edge, at.distance_to(Geometry2D.get_closest_point_to_segment(at, Vector2(a.x, a.z), Vector2(b.x, b.z))) - float(_k.ramp_width_m) * 0.5)
			# Ground height encoded 0..1 over [floor, surface]: deep in the
			# middle, rising to the surface over the bank width.
			image.set_pixel(x, z, Color(1.0 - smoothstep(0.0, float(pool.bank_width_m), edge) * 0.92, 0.0, 0.0))
	material.set_shader_parameter("terrain_height", ImageTexture.create_from_image(image))
	material.set_shader_parameter("region", Vector4(lo.x, lo.y, hi.x - lo.x, hi.y - lo.y))
	material.set_shader_parameter("height_min", float(row.top_y))
	material.set_shader_parameter("height_max", surface_y)
	var look: Dictionary = pool.surface
	for key: String in look:
		var value: Variant = look[key]
		material.set_shader_parameter(key, Color(str(value)) if value is String else value)
	var donor := preload("res://scripts/world/water.gd").new()
	material.set_shader_parameter("wave_normal_a", donor.call("_noise_normal", 11, 0.05))
	material.set_shader_parameter("wave_normal_b", donor.call("_noise_normal", 12, 0.09))
	material.set_shader_parameter("foam_noise", donor.call("_noise_plain", 13, 0.11))
	donor.free()
	water.material_override = material
	parent.add_child(water)
	var reeds: Dictionary = pool.reeds
	var rng := RandomNumberGenerator.new()
	rng.seed = 2240
	var angle := start + 0.5
	while angle < end:
		for radius: float in [r0 + 0.35, r1 - 0.35]:
			var at := _polar(cfg, radius, angle + rng.randf_range(-0.4, 0.4))
			if rng.randf() < float(reeds.chance) and not _near_ramp(at, float(pool.ramp_clearance_m)):
				var reed_size: Array = reeds.size_m
				var reed := ASSETS.piece(str(reeds.model), Vector3(float(reed_size[0]), float(reed_size[1]), float(reed_size[2])) * rng.randf_range(0.8, 1.3))
				if reed != null:
					parent.add_child(reed)
					reed.position = Vector3(at.x, float(row.top_y), at.y)
					reed.rotation.y = rng.randf() * TAU
		angle += float(reeds.spacing_deg)


## Grass-cover clearance circles (x, z, radius) over the levels and ramps.
func clearance_circles() -> PackedVector3Array:
	# Few, large circles: the grass field keeps only its nearest 24.
	var out := PackedVector3Array()
	if not _enabled or _k.is_empty():
		return out
	var cfg := {"origin_xz": _k.origin_xz}
	var clear: Dictionary = _k.grass_clear
	var count := int(clear.count)
	for i in count:
		var angle := lerpf(float(_k.angle_start_deg), float(_k.angle_end_deg), (float(i) + 0.5) / count)
		var at := _polar(cfg, float(clear.radius_from_origin_m), angle)
		out.append(Vector3(at.x, at.y, float(clear.radius_m)))
	for ramp: Dictionary in _ramps:
		if str(ramp.id) == str(_k.entry_ramp.id):
			var a: Vector3 = ramp.a
			var b: Vector3 = ramp.b
			var mid := a.lerp(b, 0.35)
			out.append(Vector3(mid.x, mid.z, float(clear.ramp_radius_m)))
	return out


## Collapse static island scatter that would grow up through the levels.
func clear_scatter(root: Node) -> void:
	if not _enabled or root == null:
		return
	var circles := clearance_circles()
	for node: Node in root.find_children("*", "MultiMeshInstance3D", true, false):
		var instance := node as MultiMeshInstance3D
		var multimesh := instance.multimesh
		if multimesh == null:
			continue
		var to_world := instance.global_transform
		for index in multimesh.instance_count:
			var local := multimesh.get_instance_transform(index)
			var at := to_world * local.origin
			for circle: Vector3 in circles:
				if Vector2(at.x, at.z).distance_to(Vector2(circle.x, circle.y)) < circle.z:
					multimesh.set_instance_transform(index, Transform3D(Basis.from_scale(Vector3.ZERO), local.origin))
					break


func _near_ramp(at: Vector2, clearance: float) -> bool:
	for ramp: Dictionary in _ramps:
		var a: Vector3 = ramp.a
		var b: Vector3 = ramp.b
		var direction := Vector2(b.x - a.x, b.z - a.z).normalized()
		var nearest := Geometry2D.get_closest_point_to_segment(at, Vector2(a.x, a.z) - direction * 2.0, Vector2(b.x, b.z) + direction * 2.0)
		if at.distance_to(nearest) < float(_k.ramp_width_m) * 0.5 + clearance:
			return true
	return false


static func _world_material(texture: String, tint: String, scale_m: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(texture) as Texture2D
	material.albedo_color = Color(tint)
	material.roughness = 0.95
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * scale_m
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return preload("res://scripts/world/tidewake_material_family.gd").standard(material, "stone")
