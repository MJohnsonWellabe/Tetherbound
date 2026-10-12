extends RefCounted
## Render-only detail over the accepted r2 support. Never replace a support mesh,
## edit its arrays, add bodies, or change the bounded floor index.
const CONFIG := "res://data/config/water_garden_detail.json"
const ASSETS := preload("res://scripts/world/water_blockout_assets.gd")


static func apply(garden: Node3D, support: Dictionary) -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not bool(cfg.get("garden_detail_enabled", false)): return
	var detail := Node3D.new()
	detail.name = "GardenDetail"
	garden.add_child(detail)
	var stone := _material(str(cfg.stone_texture), str(cfg.stone_tint), float(cfg.stone_repeats_per_m))
	stone.roughness_texture = load(str(cfg.stone_roughness)) as Texture2D
	var coping := _material(str(cfg.stone_texture), str(cfg.coping_tint), float(cfg.stone_repeats_per_m))
	coping.roughness_texture = stone.roughness_texture
	var soil := _material(str(cfg.bed_texture), str(cfg.bed_tint), 0.65)
	for child: Node in garden.get_children():
		if child is StaticBody3D:
			var wall := child.get_node("ContinuousRetainingWalls") as MeshInstance3D
			wall.material_override = stone
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
					var plant_angle := angle + 0.4
					while plant_angle < end - 0.2:
						var at: Vector2 = garden.call("_polar", support, radius, plant_angle)
						var drowned := str(row.id) == "LowerDrownedLevel"
						var fern := int(round(plant_angle * 10.0)) % 3 == 0
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
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(str(cfg.pool_tint))
	water.roughness = float(cfg.pool_roughness)
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	var pool := PackedVector3Array()
	_sector(garden, support, float(cfg.pool_radius_inner_m), float(cfg.pool_radius_outer_m), float(cfg.pool_angle_start_deg), float(cfg.pool_angle_end_deg), float(support.floors[0].top_y) + float(cfg.pool_depth_m), pool)
	garden.call("_mesh", detail, "LowestLevelStandingWaterDetail", pool, water)


static func _material(texture: String, tint: String, repeats: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(texture) as Texture2D
	material.albedo_color = Color(tint)
	material.roughness = 1.0
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * repeats
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


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
