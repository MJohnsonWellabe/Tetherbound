extends Node3D
## Independent P2-011 layout gate: three level planted terraces, closed textured
## soil and installed stone edging. No collision, grass exclusion or interaction.
const CONFIG := "res://data/config/water_garden_terraces_blockout.json"
const ASSETS := preload("res://scripts/world/water_blockout_assets.gd")

func build(world: Node3D, dressing: Node3D) -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not bool(cfg.get("planted_terraces_blockout_enabled", false)) or bool(world.get("simulation_only")):
		return
	var soil := StandardMaterial3D.new()
	soil.albedo_texture = load(str(cfg.soil_texture)) as Texture2D
	soil.albedo_color = Color(str(cfg.soil_tint))
	soil.roughness = 1.0
	soil.uv1_triplanar = true
	soil.uv1_scale = Vector3.ONE * float(cfg.soil_texture_scale)
	for terrace: Dictionary in cfg.terraces:
		if not _terrace(world, cfg, terrace, soil):
			push_error("Garden blockout unsupported terrace: " + str(terrace.id))
			return
	var previous := dressing.get_node_or_null("DrownedGardenTerraceCourses") as Node3D
	if previous != null:
		previous.visible = false

func _terrace(world: Node3D, cfg: Dictionary, spec: Dictionary, material: Material) -> bool:
	var holder := Node3D.new()
	holder.name = str(spec.id)
	add_child(holder)
	holder.position = Vector3(float(spec.at_xz[0]), 0.0, float(spec.at_xz[1]))
	holder.rotation.y = deg_to_rad(float(spec.yaw_deg))
	var outline: Array = cfg.outline_xz
	var low := INF
	var high := -INF
	for point: Array in outline:
		var at := holder.to_global(Vector3(float(point[0]), 0.0, float(point[1])))
		var ground := float(world.call("ground_height_at", at.x, at.z))
		if not is_finite(ground): return false
		low = minf(low, ground)
		high = maxf(high, ground)
	var top := high + float(cfg.soil_clearance_m)
	var bottom := low - float(cfg.fill_sink_m)
	if top - bottom > float(cfg.maximum_fill_depth_m): return false
	holder.position.y = top
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in outline.size():
		var a: Array = outline[i]
		var b: Array = outline[(i + 1) % outline.size()]
		var av := Vector3(float(a[0]), 0.0, float(a[1]))
		var bv := Vector3(float(b[0]), 0.0, float(b[1]))
		var ab := av + Vector3.DOWN * (top - bottom)
		var bb := bv + Vector3.DOWN * (top - bottom)
		_tri(surface, Vector3.ZERO, av, bv)
		_tri(surface, av, ab, bb)
		_tri(surface, av, bb, bv)
		_tri(surface, Vector3(0.0, bottom - top, 0.0), bb, ab)
	surface.generate_normals()
	var fill := MeshInstance3D.new()
	fill.name = "LevelTexturedSoil"
	fill.mesh = surface.commit()
	fill.material_override = material
	holder.add_child(fill)
	# Broad stone courses and planted masses establish layout only; no fine detail.
	for i in outline.size():
		var a: Array = outline[i]
		var b: Array = outline[(i + 1) % outline.size()]
		var av := Vector3(float(a[0]), 0.0, float(a[1]))
		var bv := Vector3(float(b[0]), 0.0, float(b[1]))
		var edge := ASSETS.piece(str(cfg.edge_model), Vector3(av.distance_to(bv) + 0.25, top - bottom + 0.25, float(cfg.edge_depth_m)))
		if edge == null: return false
		holder.add_child(edge)
		edge.position = (av + bv) * 0.5 + Vector3(0.0, bottom - top, 0.0)
		edge.rotation.y = -atan2(bv.z - av.z, bv.x - av.x)
	for i in cfg.plants.size():
		var row: Dictionary = cfg.plants[i]
		var plant := ASSETS.piece(str(row.model), Vector3(float(row.size_m[0]), float(row.size_m[1]), float(row.size_m[2])))
		if plant == null: return false
		holder.add_child(plant)
		plant.position = Vector3(float(row.at_xz[0]), 0.04, float(row.at_xz[1]))
		plant.rotation.y = float(i) * 1.7
	return true

static func _tri(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.set_uv(Vector2(a.x, a.z)); surface.add_vertex(a)
	surface.set_uv(Vector2(b.x, b.z)); surface.add_vertex(b)
	surface.set_uv(Vector2(c.x, c.z)); surface.add_vertex(c)
