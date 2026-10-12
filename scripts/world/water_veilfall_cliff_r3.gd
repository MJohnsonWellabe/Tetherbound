extends "res://scripts/world/water_veilfall_tiered_r2.gd"
## P2-010 verdict6117947777: water GO, rock HOLD. Independent OFF rock rough.
## Inherit the accepted r2 stream/spray methods and read their original config.
## Render-only cliffs; no terrain, collision, actor, route or camera mutation.
const R3_CONFIG := "res://data/config/water_veilfall_cliff_r3.json"


func build(world: Node3D, veilfall: Node3D) -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(R3_CONFIG))
	if not bool(cfg.get("cliff_crag_r3_enabled", false)) or bool(world.get("simulation_only")):
		return
	# CONFIG, _point, _stream, _spray and their mesh attributes are inherited
	# unchanged from r2. R3 supplies no water override fields.
	_cfg = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var prepared: Array[Dictionary] = []
	for tier: Dictionary in cfg.tiers:
		var surface := _cliff_surface(world, tier)
		if surface == null:
			push_error("Veilfall r3 could not ground cliff " + str(tier.id))
			return
		prepared.append({"id": str(tier.id), "surface": surface})
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = load(str(cfg.rock_texture)) as Texture2D
	stone.albedo_color = Color(str(cfg.rock_tint))
	stone.roughness = float(cfg.rock_roughness)
	stone.metallic_specular = float(cfg.rock_specular)
	stone.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	stone.uv1_triplanar = true
	stone.uv1_scale = Vector3.ONE * float(cfg.rock_texture_scale)
	for tier: Dictionary in prepared:
		_mesh(str(tier.id), tier.surface, stone)
	for lip: Dictionary in cfg.water_lips:
		_tier(lip, stone)
	var far := veilfall.get_node_or_null("VeilfallFarSilhouette")
	for path: String in ["WaterfallPassage/VeilfallExteriorComposition", "VeilfallWhiteFalls", "VeilfallFarSilhouette", "VeilfallTieredR2"]:
		var previous := veilfall.get_node_or_null(path) as Node3D
		if previous != null: previous.visible = false
	# Same water material setup and same inherited geometry as accepted r2.
	var water := ShaderMaterial.new()
	water.shader = FALL_SHADER
	for key: String in _cfg.water_shader:
		var value: Variant = _cfg.water_shader[key]
		water.set_shader_parameter(key, Color(str(value)) if value is String else value)
	water.set_shader_parameter("centre_xz", Vector2(float(_cfg.centre_xz[0]), float(_cfg.centre_xz[1])))
	_stream(water)
	var mist := ShaderMaterial.new()
	mist.shader = SPRAY_SHADER
	for key: String in _cfg.mist_shader:
		var value: Variant = _cfg.mist_shader[key]
		mist.set_shader_parameter(key, Color(str(value)) if value is String else value)
	_spray(mist)
	if far != null:
		far.call("register_fogged", water)
		far.call("register_fogged", mist)


func _cliff_surface(world: Node3D, spec: Dictionary) -> SurfaceTool:
	var outline := PackedVector2Array()
	var tops: Array[Vector3] = []
	var bottoms: Array[Vector3] = []
	for index in spec.outline_uv.size():
		var uv: Array = spec.outline_uv[index]
		outline.append(Vector2(float(uv[0]), float(uv[1])))
		var top_y := float(spec.top_y[index]) if spec.top_y is Array else float(spec.top_y)
		var top := _point([uv[0], top_y, uv[1]])
		var bottom_y := float(spec.get("bottom_y", 0.0))
		if bool(spec.get("grounded_base", false)):
			bottom_y = float(world.call("ground_height_at", top.x, top.z)) - float(spec.footing_sink_m)
			if not is_finite(bottom_y): return null
		if bottom_y >= top_y: return null
		tops.append(top)
		bottoms.append(Vector3(top.x, bottom_y, top.z))
	var indices := Geometry2D.triangulate_polygon(outline)
	if indices.is_empty(): return null
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(0, indices.size(), 3):
		_triangle(surface, tops[indices[index]], tops[indices[index + 1]], tops[indices[index + 2]], Vector3.UP)
		if not bool(spec.get("grounded_base", false)):
			_triangle(surface, bottoms[indices[index]], bottoms[indices[index + 2]], bottoms[indices[index + 1]], Vector3.DOWN)
	for index in tops.size():
		var next := (index + 1) % tops.size()
		var a := tops[index]
		var b := tops[next]
		var bottom_a := bottoms[index]
		var bottom_b := bottoms[next]
		# Existing authored approach crosses this face below the arch. Lift only
		# its visual lower edge; terrain and physical route support stay intact.
		for portal: Dictionary in spec.get("route_openings", []):
			if int(portal.edge_index) == index:
				bottom_a.y = maxf(bottom_a.y, float(portal.clear_ceiling_y))
				bottom_b.y = maxf(bottom_b.y, float(portal.clear_ceiling_y))
		var edge := b - a
		var outward := Vector3(-edge.z, 0.0, edge.x)
		# The authored UV outlines are CCW; across/outward reverses XZ handedness.
		_triangle(surface, a, bottom_a, bottom_b, outward)
		_triangle(surface, a, bottom_b, b, outward)
	return surface
