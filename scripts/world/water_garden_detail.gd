extends RefCounted
## Render-only detail over the accepted r2 support. Never replace a support mesh,
## edit its arrays, add bodies, or change the bounded floor index.
const CONFIG := "res://data/config/water_garden_detail.json"
const ASSETS := preload("res://scripts/world/water_blockout_assets.gd")
const WATER := preload("res://shaders/water.gdshader")
const MASONRY := preload("res://shaders/water_garden_masonry.gdshader")


static func apply(garden: Node3D, support: Dictionary) -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not bool(cfg.get("garden_detail_enabled", false)): return
	var detail := Node3D.new()
	detail.name = "GardenDetail"
	garden.add_child(detail)
	var stone := _masonry(cfg, support, false)
	var connector_wall := _masonry(cfg, support, true)
	var paving := _material(str(cfg.stone_texture), str(cfg.paving_tint), float(cfg.stone_repeats_per_m))
	var coping := _material(str(cfg.stone_texture), str(cfg.coping_tint), float(cfg.stone_repeats_per_m))
	coping.roughness_texture = load(str(cfg.stone_roughness)) as Texture2D
	var soil := _material(str(cfg.bed_texture), str(cfg.bed_tint), 0.65)
	for child: Node in garden.get_children():
		if child is StaticBody3D:
			var wall := child.get_node("ContinuousRetainingWalls") as MeshInstance3D
			var connector := str(child.name) in ["EntryFromExistingGround", "LowerToMiddle", "MiddleToUpper"]
			wall.material_override = connector_wall if connector else stone
			var top := child.get_node("LevelSoilOrConnector") as MeshInstance3D
			# The three ramps stay sloped and walkable; their stone paving now
			# clearly differs from the three exactly horizontal soil levels.
			top.material_override = paving if connector else soil
		elif child is Node3D and child != detail:
			# Replace only the rough planting/pool, retaining their source for review.
			(child as Node3D).visible = false
	for row: Dictionary in support.floors:
		var caps := PackedVector3Array()
		for inner: bool in [true, false]:
			var edge := float(row.radius_inner_m) if inner else float(row.radius_outer_m) - float(cfg.coping_width_m)
			_sector(garden, support, edge, edge + float(cfg.coping_width_m), float(row.angle_start_deg), float(row.angle_end_deg), float(row.top_y) + float(cfg.coping_offset_m), caps)
		garden.call("_mesh", detail, str(row.id) + "StoneCoping", caps, coping)
		var beds := PackedVector3Array()
		for radius: float in [float(row.radius_inner_m) + float(cfg.bed_inset_m), float(row.radius_outer_m) - float(cfg.bed_inset_m)]:
			var angle := float(row.angle_start_deg) + 1.0
			while angle + float(cfg.bed_span_deg) < float(row.angle_end_deg) - 0.5:
				var end := angle + float(cfg.bed_span_deg)
				# Whole bed bounds stay outside the ordinary connector corridor.
				if _bed_clear(garden, support, cfg, radius, angle, end, float(row.top_y)):
					_sector(garden, support, radius - float(cfg.bed_width_m) * 0.5, radius + float(cfg.bed_width_m) * 0.5, angle, end, float(row.top_y) + float(cfg.bed_offset_m), beds)
					for side: float in [-0.35, 0.35]:
						var plant_angle := angle + (0.28 if side < 0.0 else 0.5)
						while plant_angle < end - 0.2:
							var at: Vector2 = garden.call("_polar", support, radius + side, plant_angle)
							var drowned := str(row.id) == "LowerDrownedLevel"
							var fern := int(round(plant_angle * 10.0)) % 4 != 0
							var model := str(cfg.water_plant_model) if drowned else (str(cfg.fern_model) if fern else str(cfg.flower_model))
							var size: Array = cfg.water_plant_size_m if drowned else (cfg.fern_size_m if fern else cfg.flower_size_m)
							var plant := ASSETS.piece(model, Vector3(float(size[0]), float(size[1]), float(size[2])))
							if plant != null:
								detail.add_child(plant)
								plant.position = Vector3(at.x, float(row.top_y), at.y)
								plant.rotation.y = deg_to_rad(plant_angle * 7.0)
							plant_angle += float(cfg.plant_spacing_deg)
				angle = end + float(cfg.bed_gap_deg)
		garden.call("_mesh", detail, str(row.id) + "PlantedBeds", beds, soil)
	_infill(garden, detail, support, cfg, soil)
	_connector_joints(garden, detail, support, cfg, coping)
	var pool := PackedVector3Array()
	_sector(garden, support, float(cfg.pool_radius_inner_m), float(cfg.pool_radius_outer_m), float(cfg.pool_angle_start_deg), float(cfg.pool_angle_end_deg), float(support.floors[0].top_y) + float(cfg.pool_depth_m), pool)
	# This decorative pool is independent of support arrays. The installed
	# water shader needs upward normals and a valid normal-map tangent frame.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, pool.size(), 3):
		for index: int in [i, i + 2, i + 1]:
			surface.set_uv(Vector2(pool[index].x, pool[index].z))
			surface.add_vertex(pool[index])
	surface.generate_normals()
	surface.generate_tangents()
	var water := MeshInstance3D.new()
	water.name = "LowestLevelStandingWaterDetail"
	water.mesh = surface.commit()
	water.material_override = _water_material(cfg, support, pool)
	detail.add_child(water)


## Small supported patches survive where rejecting a whole5m bed left the
## near terrace empty. Keep actual connector and landing runouts clear.
static func _infill(garden: Node3D, detail: Node3D, support: Dictionary, cfg: Dictionary, soil: Material) -> void:
	var occupied: Array[Vector3] = []
	for child: Node in detail.get_children():
		if child is Node3D and not child is MeshInstance3D:
			occupied.append((child as Node3D).position)
	for row: Dictionary in support.floors:
		if str(row.id) == "LowerDrownedLevel": continue
		var faces := PackedVector3Array()
		for inset: float in cfg.infill_radial_insets_m:
			var radius := float(row.radius_inner_m) + inset
			var angle := float(row.angle_start_deg) + 0.6
			while angle < float(row.angle_end_deg) - 0.6:
				var at: Vector2 = garden.call("_polar", support, radius, angle)
				var point := Vector3(at.x, float(row.top_y), at.y)
				var clear := true
				for existing: Vector3 in occupied:
					if existing.distance_to(point) < float(cfg.infill_spacing_m): clear = false
				for ramp: Dictionary in support.ramps:
					var a := Vector2(float(ramp.a[0]), float(ramp.a[2]))
					var b := Vector2(float(ramp.b[0]), float(ramp.b[2]))
					var direction := (b - a).normalized()
					if at.distance_to(Geometry2D.get_closest_point_to_segment(at, a - direction * float(cfg.infill_runout_m), b + direction * float(cfg.infill_runout_m))) < float(cfg.infill_path_clearance_m): clear = false
				# All four patch corners must lie on this exact flat support.
				for offset: Vector2 in [Vector2(-0.55, -0.55), Vector2(-0.55, 0.55), Vector2(0.55, 0.55), Vector2(0.55, -0.55)]:
					var y := float(garden.call("built_floor_height_at", at.x + offset.x, at.y + offset.y))
					if not is_finite(y) or absf(y - point.y) > 0.001: clear = false
				if clear:
					var plant := ASSETS.piece(str(cfg.fern_model), Vector3(float(cfg.fern_size_m[0]), float(cfg.fern_size_m[1]), float(cfg.fern_size_m[2])))
					if plant != null:
						plant.name = str(row.id) + "Infill"
						plant.set_meta("garden_infill", true)
						detail.add_child(plant)
						plant.position = point
						plant.rotation.y = deg_to_rad(angle * 7.0)
						occupied.append(point)
						var patch := PackedVector2Array([at + Vector2(-0.55, -0.55), at + Vector2(0.55, -0.55), at + Vector2(0.55, 0.55), at + Vector2(-0.55, 0.55)])
						garden.call("_append_flat", patch, point.y + float(cfg.bed_offset_m), faces)
				angle += float(cfg.infill_angle_step_deg)
		garden.call("_mesh", detail, str(row.id) + "InfillBeds", faces, soil)


## A narrow bevel at the real wall/connector junction explains the contact
## between the sloped path and vertical retaining face. It adds no support,
## removes no wall, and leaves at least2.64m of the3m connector clear.
static func _connector_joints(garden: Node3D, detail: Node3D, support: Dictionary, cfg: Dictionary, stone: Material) -> void:
	var faces := PackedVector3Array()
	for ramp: Dictionary in support.ramps:
		var a := Vector3(float(ramp.a[0]), float(ramp.a[1]), float(ramp.a[2]))
		var b := Vector3(float(ramp.b[0]), float(ramp.b[1]), float(ramp.b[2]))
		var direction := Vector2(b.x - a.x, b.z - a.z).normalized()
		var side := Vector3(-direction.y, 0.0, direction.x)
		var steps := int(ceil(a.distance_to(b) / 0.4))
		for sign_value: float in [-1.0, 1.0]:
			for i in steps:
				var p := a.lerp(b, float(i) / steps) + side * sign_value * float(ramp.width_m) * 0.5
				var q := a.lerp(b, float(i + 1) / steps) + side * sign_value * float(ramp.width_m) * 0.5
				var probe_p := p + side * sign_value * 0.03
				var probe_q := q + side * sign_value * 0.03
				var floor_p := float(garden.call("built_floor_height_at", probe_p.x, probe_p.z))
				var floor_q := float(garden.call("built_floor_height_at", probe_q.x, probe_q.z))
				if not is_finite(floor_p) or not is_finite(floor_q) or minf(floor_p - p.y, floor_q - q.y) < float(cfg.joint_height_m): continue
				var inner_p := p - side * sign_value * float(cfg.joint_width_m) + Vector3.UP * 0.008
				var inner_q := q - side * sign_value * float(cfg.joint_width_m) + Vector3.UP * 0.008
				var wall_p := p + Vector3.UP * float(cfg.joint_height_m)
				var wall_q := q + Vector3.UP * float(cfg.joint_height_m)
				garden.call("_append_triangle", faces, inner_p, inner_q, wall_q)
				garden.call("_append_triangle", faces, inner_p, wall_q, wall_p)
	garden.call("_mesh", detail, "ConnectorWallStoneJoints", faces, stone)


static func _masonry(cfg: Dictionary, support: Dictionary, connector: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = MASONRY
	material.set_shader_parameter("stone_texture", load(str(cfg.stone_texture)))
	material.set_shader_parameter("rough_texture", load(str(cfg.stone_roughness)))
	material.set_shader_parameter("tint", Color(str(cfg.stone_tint)))
	material.set_shader_parameter("repeats_per_m", float(cfg.stone_repeats_per_m))
	material.set_shader_parameter("connector_wall", connector)
	material.set_shader_parameter("garden_origin", Vector2(float(support.origin_xz[0]), float(support.origin_xz[1])))
	material.set_shader_parameter("angles_rad", Vector2(deg_to_rad(float(support.floors[0].angle_start_deg)), deg_to_rad(float(support.floors[0].angle_end_deg))))
	var bands := PackedVector4Array()
	var starts := PackedVector4Array()
	var ends := PackedVector4Array()
	for row: Dictionary in support.floors:
		bands.append(Vector4(float(row.radius_inner_m), float(row.radius_outer_m), float(row.top_y), 0.0))
	for row: Dictionary in support.ramps:
		starts.append(Vector4(float(row.a[0]), float(row.a[1]), float(row.a[2]), float(row.width_m) * 0.5))
		ends.append(Vector4(float(row.b[0]), float(row.b[1]), float(row.b[2]), 0.0))
	material.set_shader_parameter("floor_bands", bands)
	material.set_shader_parameter("ramp_a", starts)
	material.set_shader_parameter("ramp_b", ends)
	preload("res://scripts/world/tidewake_material_family.gd").shader(material, "stone")
	return material


static func _water_material(cfg: Dictionary, support: Dictionary, pool: PackedVector3Array) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = WATER
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for point: Vector3 in pool:
		lo = lo.min(Vector2(point.x, point.z))
		hi = hi.max(Vector2(point.x, point.z))
	var image := Image.create(128, 128, false, Image.FORMAT_RF)
	var origin := Vector2(float(support.origin_xz[0]), float(support.origin_xz[1]))
	# Material-only bank mask, not terrain or collision: depth remains6cm.
	# Taper the shoreline inward at both curved banks, ends and ramp notches.
	for z in 128:
		for x in 128:
			var at := lo + (hi - lo) * Vector2(float(x) / 127.0, float(z) / 127.0)
			var polar := at - origin
			var radius := polar.length()
			var angle := atan2(polar.y, polar.x)
			var edge := minf(radius - float(cfg.pool_radius_inner_m), float(cfg.pool_radius_outer_m) - radius)
			edge = minf(edge, radius * minf(angle - deg_to_rad(float(cfg.pool_angle_start_deg)), deg_to_rad(float(cfg.pool_angle_end_deg)) - angle))
			for ramp: Dictionary in support.ramps:
				var a := Vector2(float(ramp.a[0]), float(ramp.a[2]))
				var b := Vector2(float(ramp.b[0]), float(ramp.b[2]))
				edge = minf(edge, at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)) - float(ramp.width_m) * 0.5)
			image.set_pixel(x, z, Color(1.0 - smoothstep(0.0, float(cfg.pool_bank_width_m), edge), 0.0, 0.0))
	material.set_shader_parameter("terrain_height", ImageTexture.create_from_image(image))
	material.set_shader_parameter("region", Vector4(lo.x, lo.y, hi.x - lo.x, hi.y - lo.y))
	material.set_shader_parameter("height_min", float(support.floors[0].top_y))
	material.set_shader_parameter("height_max", float(support.floors[0].top_y) + float(cfg.pool_depth_m))
	for key: String in ["deep_colour", "shallow_colour", "fresnel_colour", "foam_colour"]:
		material.set_shader_parameter(key, Color(str(cfg.water_surface[key])))
	for key: String in ["depth_falloff", "alpha_deep", "alpha_shallow", "edge_feather", "foam_depth", "wave_uv_scale", "wave_strength", "wave_speed", "fresnel_strength", "roughness_value"]:
		material.set_shader_parameter(key, float(cfg.water_surface[key]))
	var donor := preload("res://scripts/world/water.gd").new()
	material.set_shader_parameter("wave_normal_a", donor.call("_noise_normal", 11, 0.05))
	material.set_shader_parameter("wave_normal_b", donor.call("_noise_normal", 12, 0.09))
	material.set_shader_parameter("foam_noise", donor.call("_noise_plain", 13, 0.11))
	donor.free()
	return material


static func _material(texture: String, tint: String, repeats: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(texture) as Texture2D
	material.albedo_color = Color(tint)
	material.roughness = 1.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * repeats
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return preload("res://scripts/world/tidewake_material_family.gd").standard(material, "stone")


static func _sector(garden: Node3D, support: Dictionary, r0: float, r1: float, start: float, end: float, y: float, faces: PackedVector3Array) -> void:
	var steps := int(ceil(deg_to_rad(end - start) * r1))
	for i in steps:
		var a := lerpf(start, end, float(i) / steps)
		var b := lerpf(start, end, float(i + 1) / steps)
		var polygon := PackedVector2Array([garden.call("_polar", support, r0, a), garden.call("_polar", support, r1, a), garden.call("_polar", support, r1, b), garden.call("_polar", support, r0, b)])
		var pieces: Array = garden.call("_without_ramps", polygon)
		for piece: PackedVector2Array in pieces:
			garden.call("_append_flat", piece, y, faces)


static func _bed_clear(garden: Node3D, support: Dictionary, cfg: Dictionary, radius: float, start: float, end: float, y: float) -> bool:
	for angle: float in [start, (start + end) * 0.5, end]:
		for radial: float in [radius - float(cfg.bed_width_m) * 0.5, radius + float(cfg.bed_width_m) * 0.5]:
			var at: Vector2 = garden.call("_polar", support, radial, angle)
			var floor_y := float(garden.call("built_floor_height_at", at.x, at.y))
			if not is_finite(floor_y) or absf(floor_y - y) > 0.001: return false
			for ramp: Dictionary in support.ramps:
				var a := Vector2(float(ramp.a[0]), float(ramp.a[2]))
				var b := Vector2(float(ramp.b[0]), float(ramp.b[2]))
				if at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)) < float(cfg.ramp_clearance_m): return false
	return true
