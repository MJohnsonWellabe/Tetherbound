extends "res://scripts/world/grass_field.gd"

## P2-039: realm-local mesh vocabulary for the existing terrain-bound field.
## Keep its placement, clearances, camera following and terrain binding. These
## are decorative canopy cushions, curled leaves, wet soil and tree-root flares.
## No baked scatter, harvest, collision or actor scale changes.
const FOREST_SHADER := preload("res://shaders/stormwood_ground_cover.gdshader")
var _canopy_texture: ImageTexture
var _roots_built := false
var _forest_enabled := false


func _build_cover_tiers(cfg: Dictionary, radius: float) -> void:
	var finish: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_ground_finish.json"))
	_forest_enabled = bool(finish.get("enabled", false))
	if not _forest_enabled:
		super._build_cover_tiers(cfg, radius)
		return
	var forest_cfg := cfg.duplicate(true)
	var tiers: Array[Dictionary] = []
	for source: Dictionary in cfg.get("cover_tiers", []):
		if str(source.get("name", "")) == "litter":
			for variant in 3:
				var leaf := source.duplicate(true)
				leaf["name"] = "wet_leaves_%d" % variant
				leaf["mesh"] = "stormwood_litter" if variant == 0 else "stormwood_litter_%d" % variant
				leaf["count"] = floori(float(source.get("count", 15000)) / 3.0)
				leaf["placement_seed"] = 391827 + variant * 1019
				leaf["tint_base"] = ["#292b1d", "#353020", "#30271e"][variant]
				leaf["tint_tip"] = ["#41432b", "#514730", "#473b2c"][variant]
				tiers.append(leaf)
		else:
			tiers.append(source.duplicate(true))
	for extra: Dictionary in finish.get("forest_layers", []):
		tiers.append(extra.duplicate(true))
	forest_cfg["cover_tiers"] = tiers
	super._build_cover_tiers(forest_cfg, radius)
	# Copy uniform values explicitly before swapping, including all inherited
	# lattice schedules and texture/footprint gates. Terrain maps bind afterward.
	for mat: ShaderMaterial in _cover_materials:
		var saved: Dictionary = {}
		for uniform: Dictionary in mat.shader.get_shader_uniform_list():
			var value: Variant = mat.get_shader_parameter(uniform.name)
			if value != null:
				saved[uniform.name] = value
		mat.shader = FOREST_SHADER
		for key: String in saved:
			mat.set_shader_parameter(key, saved[key])
		mat.set_shader_parameter("wet_earth", load("res://assets/environment/terrain/stylised/wet_earth_Color.png"))
		var seed_value := int(mat.get_shader_parameter("placement_seed"))
		mat.set_shader_parameter("wet_surface", 1.0 if seed_value == 392891 else (0.45 if seed_value in [391827, 392846, 393865] else 0.0))
		# Wet-surface gloss (stormwood_ground_finish.json wet_gloss); absent keeps the shader defaults.
		var gloss: Dictionary = finish.get("wet_gloss", {})
		if gloss.has("roughness"): mat.set_shader_parameter("wet_roughness", float(gloss.roughness))
		if gloss.has("specular"): mat.set_shader_parameter("wet_specular", float(gloss.specular))


func bind(terrain: Node, camera: Camera3D) -> void:
	if _forest_enabled and not _roots_built:
		_build_canopy_and_roots()
		_roots_built = true
	super.bind(terrain, camera)


func _build_canopy_and_roots() -> void:
	var vegetation := get_parent().get_node_or_null("Vegetation")
	if vegetation == null:
		return
	var image := Image.create(1024, 1536, false, Image.FORMAT_R8)
	image.fill(Color.BLACK)
	var groups: Dictionary = {}
	var batches: Array = vegetation.get("_collision_batches")
	for batch: Dictionary in batches:
		var model := str(batch.get("model", ""))
		if not "Tree" in model:
			continue
		for placement: Dictionary in batch.get("placements", []):
			var at: Vector3 = placement["position"]
			var tree_scale := float(placement.get("scale", 3.0))
			var cell := Vector2i(floori(at.x / 64.0), floori(at.z / 64.0))
			if not groups.has(cell):
				groups[cell] = []
			groups[cell].append(placement)
			if "DeadTree" in model:
				continue
			var centre := Vector2((at.x + 2048.0) / 4.0, (at.z + 256.0) / 4.0)
			var radius := clampf(tree_scale * 2.7, 7.0, 19.0) / 4.0
			for y in range(maxi(0, floori(centre.y - radius)), mini(image.get_height(), ceili(centre.y + radius) + 1)):
				for x in range(maxi(0, floori(centre.x - radius)), mini(image.get_width(), ceili(centre.x + radius) + 1)):
					var d := Vector2(x + 0.5, y + 0.5).distance_to(centre) / radius
					var strength := 1.0 - smoothstep(0.35, 1.0, d)
					if strength > image.get_pixel(x, y).r:
						image.set_pixel(x, y, Color(strength, strength, strength))
	_canopy_texture = ImageTexture.create_from_image(image)
	for mat: ShaderMaterial in _cover_materials:
		mat.set_shader_parameter("canopy_mask", _canopy_texture)
	var roots := Node3D.new()
	roots.name = "CanopyRoots"
	add_child(roots)
	roots.top_level = true
	roots.global_transform = Transform3D.IDENTITY
	var root_material := ShaderMaterial.new()
	root_material.shader = FOREST_SHADER
	root_material.set_shader_parameter("anchored_root", true)
	root_material.set_shader_parameter("canopy_mask", _canopy_texture)
	root_material.set_shader_parameter("wet_earth", load("res://assets/environment/terrain/stylised/wet_earth_Color.png"))
	root_material.set_shader_parameter("wet_surface", 0.32)
	root_material.set_shader_parameter("item_size", 1.0)
	root_material.set_shader_parameter("size_jitter", 0.15)
	root_material.set_shader_parameter("sink", 0.0)
	root_material.set_shader_parameter("sway", 0.0)
	root_material.set_shader_parameter("normal_soften", 0.1)
	root_material.set_shader_parameter("tint_wood", Color("3c3929"))
	root_material.set_shader_parameter("allowed_base_mask", texture_mask(_terrain_texture_names(), ["grass", "soil", "damp", "forest_floor"]))
	root_material.set_shader_parameter("field_radius", float(_active_config().get("field_radius", 72.0)))
	root_material.set_shader_parameter("fade_start", float(_active_config().get("fade_start", 42.0)))
	_cover_materials.append(root_material)
	var root_mesh := _canopy_roots()
	for cell: Vector2i in groups:
		var placements: Array = groups[cell]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = root_mesh
		mm.instance_count = placements.size()
		var low := INF
		var high := -INF
		for index in placements.size():
			var placement: Dictionary = placements[index]
			var at: Vector3 = placement["position"]
			mm.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(at.x, 0.0, at.z)))
			mm.set_instance_custom_data(index, Color(clampf(float(placement.get("scale", 3.0)) * 0.55, 1.2, 3.0), 0, 0, 0))
			low = minf(low, at.y)
			high = maxf(high, at.y)
		var chunk := MultiMeshInstance3D.new()
		chunk.multimesh = mm
		chunk.material_override = root_material
		chunk.custom_aabb = AABB(Vector3(cell.x * 64.0 - 8.0, low - 12.0, cell.y * 64.0 - 8.0), Vector3(80.0, high - low + 24.0, 80.0))
		chunk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		roots.add_child(chunk)


func _cover_mesh(kind: String) -> ArrayMesh:
	match kind:
		"stormwood_wet_soil":
			return _wet_soil()
		"stormwood_moss":
			return _moss_cushions()
		"stormwood_litter":
			return _forest_litter()
		"stormwood_litter_1":
			return _forest_litter(1)
		"stormwood_litter_2":
			return _forest_litter(2)
	return super._cover_mesh(kind)


func _moss_cushions() -> ArrayMesh:
	var points := PackedVector3Array()
	var shades := PackedVector2Array()
	# Broad rounded shoulders, with four curved rings instead of an apex fan.
	for lobe in 3:
		var phase := float(lobe) * 2.39996
		var centre := Vector3(sin(phase), 0.0, cos(phase)) * float(lobe) * 0.14
		var radius := 0.22 + float(lobe % 2) * 0.065
		for band in 4:
			for edge in 12:
				var a := _cushion_point(centre, radius, phase, band, edge)
				var b := _cushion_point(centre, radius, phase, band + 1, edge)
				var c := _cushion_point(centre, radius, phase, band + 1, (edge + 1) % 12)
				var d := _cushion_point(centre, radius, phase, band, (edge + 1) % 12)
				var low := Vector2(0.28 + float(band) * 0.10, 0.8)
				var high := Vector2(low.x + 0.10, 0.8)
				_append_face(points, shades, a, b, d if band == 3 else c, low, high, low if band == 3 else high)
				if band < 3:
					_append_face(points, shades, a, c, d, low, high, low)
	return _forest_mesh(points, shades, true)


func _cushion_point(centre: Vector3, radius: float, phase: float, band: int, edge: int) -> Vector3:
	var polar := float(band) * PI / 8.0
	var angle := TAU * float(edge) / 12.0
	var outline := 1.0 + 0.075 * sin(angle * 3.0 + phase)
	return centre + Vector3(cos(angle) * cos(polar) * radius * outline,
		sin(polar) * radius * 0.46 - 0.028,
		sin(angle) * cos(polar) * radius * 0.82 * outline)


func _forest_litter(variant: int = 0) -> ArrayMesh:
	var points := PackedVector3Array()
	var shades := PackedVector2Array()
	# One offset oval leaf per item; independent tier seeds vary the shapes.
	# Six curved sections and a gently curled margin replace the pinwheel.
	var length := 0.34 + float(variant) * 0.065
	var width := 0.09 + float(variant % 2) * 0.04
	for section in 6:
		var t0 := float(section) / 6.0
		var t1 := float(section + 1) / 6.0
		for side: float in [-1.0, 1.0]:
			var a := _leaf_point(t0, 0.0, length, width, variant)
			var b := _leaf_point(t1, 0.0, length, width, variant)
			var c := _leaf_point(t1, side, length, width, variant)
			var d := _leaf_point(t0, side, length, width, variant)
			var centre_shade := Vector2(0.40, 0.65)
			var edge_shade := Vector2(0.32, 0.65)
			_append_face(points, shades, a, b, c, centre_shade, centre_shade, edge_shade)
			_append_face(points, shades, a, c, d, centre_shade, edge_shade, edge_shade)
	return _forest_mesh(points, shades, true)


func _leaf_point(t: float, side: float, length: float, width: float, variant: int) -> Vector3:
	var envelope := pow(maxf(sin(t * PI), 0.0), 0.75)
	return Vector3(side * width * envelope * (1.0 + side * 0.17) + sin(t * PI) * 0.045,
		-0.006 + envelope * (0.014 + absf(side) * 0.013) + pow(t, 5.0) * float(variant) * 0.018,
		(t - 0.45) * length)


func _canopy_roots() -> ArrayMesh:
	var points := PackedVector3Array()
	var shades := PackedVector2Array()
	for root in 3:
		var angle := float(root) * 2.39996
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var across := Vector3(-direction.z, 0.0, direction.x)
		for segment in 7:
			var t0 := float(segment) / 7.0
			var t1 := float(segment + 1) / 7.0
			for arc in 4:
				var a := _root_point(direction, across, t0, arc, root)
				var b := _root_point(direction, across, t1, arc, root)
				var c := _root_point(direction, across, t1, arc + 1, root)
				var d := _root_point(direction, across, t0, arc + 1, root)
				_append_face(points, shades, a, b, c, Vector2(0.3, 2.0), Vector2(0.3, 2.0), Vector2(0.55, 2.0))
				_append_face(points, shades, a, c, d, Vector2(0.3, 2.0), Vector2(0.55, 2.0), Vector2(0.55, 2.0))
	return _forest_mesh(points, shades, true)


func _root_point(direction: Vector3, across: Vector3, t: float, arc: int, root: int) -> Vector3:
	var angle := float(arc) * PI / 4.0
	var width := 0.22 * pow(1.0 - t, 0.8) + 0.008
	var centre := direction * (0.12 + t * (1.7 + float(root) * 0.24)) + across * sin(t * PI) * 0.25
	return centre + across * cos(angle) * width + Vector3.UP * (sin(angle) * width * 1.2 - 0.014)


func _wet_soil() -> ArrayMesh:
	var points := PackedVector3Array()
	var shades := PackedVector2Array()
	for band in 4:
		for edge in 16:
			var a := _soil_point(band, edge)
			var b := _soil_point(band + 1, edge)
			var c := _soil_point(band + 1, (edge + 1) % 16)
			var d := _soil_point(band, (edge + 1) % 16)
			_append_face(points, shades, a, b, c, Vector2(0.4, float(band) / 4.0),
				Vector2(0.4, float(band + 1) / 4.0), Vector2(0.4, float(band + 1) / 4.0))
			if band > 0:
				_append_face(points, shades, a, c, d, Vector2(0.4, float(band) / 4.0),
					Vector2(0.4, float(band + 1) / 4.0), Vector2(0.4, float(band) / 4.0))
	return _forest_mesh(points, shades, true)


func _soil_point(band: int, edge: int) -> Vector3:
	var angle := TAU * float(edge) / 16.0
	var radius := float(band) / 4.0 * (0.78 + 0.14 * sin(angle * 3.0) + 0.08 * cos(angle * 5.0))
	return Vector3(cos(angle) * radius, 0.012, sin(angle) * radius * 0.72)


func _append_face(points: PackedVector3Array, shades: PackedVector2Array,
		a: Vector3, b: Vector3, c: Vector3, sa: Vector2, sb: Vector2, sc: Vector2) -> void:
	# Godot uses clockwise front faces. Keep the visible side facing upward.
	if (c - a).cross(b - a).y < 0.0:
		points.append_array([a, c, b])
		shades.append_array([sa, sc, sb])
	else:
		points.append_array([a, b, c])
		shades.append_array([sa, sb, sc])


func _forest_mesh(points: PackedVector3Array, shades: PackedVector2Array, smooth: bool = false) -> ArrayMesh:
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()
	var shared_normals: Dictionary = {}
	if smooth:
		for face in range(0, points.size(), 3):
			var weighted := (points[face + 2] - points[face]).cross(points[face + 1] - points[face])
			for corner in 3:
				var key := points[face + corner].snapped(Vector3.ONE * 0.00001)
				shared_normals[key] = (shared_normals.get(key, Vector3.ZERO) as Vector3) + weighted
	for face in range(0, points.size(), 3):
		var normal := (points[face + 2] - points[face]).cross(points[face + 1] - points[face]).normalized()
		for corner in 3:
			var index := face + corner
			var key := points[index].snapped(Vector3.ONE * 0.00001)
			var vertex_normal: Vector3 = shared_normals.get(key, normal) if smooth else normal
			normals.append(vertex_normal.normalized())
			uvs.append(Vector2(0.5, shades[index].x))
			uv2s.append(Vector2(0.5, shades[index].y))
			indices.append(index)
	return _mesh_from(points, normals, uvs, indices, uv2s)
