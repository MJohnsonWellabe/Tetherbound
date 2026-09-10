extends Node3D

## Water-only exterior composition for the Veilfall gate. The production radial
## heightfield remains the hike, while these faceted static masses form physical
## shoulders and flat caps where the mountain's steep analytic slope could not
## accept ordinary vegetation scatter. Their configured footprints stay outside
## the authored route corridor and the interaction point.
const ROCK_ALBEDO := preload("res://assets/environment/stylized_nature/Rocks_Diffuse.png")
const GRASS_ALBEDO := preload("res://assets/environment/terrain/stylised/meadow_grass_Color.png")
const GRASS_NORMAL := preload("res://assets/environment/terrain/stylised/meadow_grass_NormalGL.png")
const TREES := [
	"res://assets/environment/stylized_nature/CommonTree_1.gltf",
	"res://assets/environment/stylized_nature/CommonTree_2.gltf",
	"res://assets/environment/stylized_nature/CommonTree_4.gltf",
	"res://assets/environment/stylized_nature/TwistedTree_3.gltf",
]
const SHRUBS := [
	"res://assets/environment/stylized_nature/Bush_Common.gltf",
	"res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf",
	"res://assets/environment/stylized_nature/Fern_1.gltf",
]
const GROUNDCOVER := [
	"res://assets/environment/stylized_nature/Grass_Wide_Short.gltf",
	"res://assets/environment/stylized_nature/Grass_Wispy_Tall.gltf",
	"res://assets/environment/stylized_nature/Plant_7_Big.gltf",
]

var formation_receipt: Array[Dictionary] = []
var authored_vegetation_count := 0
var _world: Node3D
var _rules: Dictionary
var _supports: Dictionary = {}
var _rock_material: StandardMaterial3D
var _cap_material: StandardMaterial3D


func build(world: Node3D, config: Dictionary) -> void:
	_world = world
	_rules = config
	_rock_material = _material(Color(str(config.get("rock_tint", "66706b"))), 0.96, true)
	_cap_material = _material(Color(str(config.get("cap_tint", "587354"))), 0.94, false)
	for formation: Dictionary in config.get("formations", []):
		_build_formation(formation)
	_build_authored_groves()


func _build_formation(spec: Dictionary) -> void:
	var raw_at: Array = spec.get("at_xz", [])
	var raw_base: Array = spec.get("base_radius_xz", [])
	var raw_top: Array = spec.get("top_radius_xz", [])
	var raw_lean: Array = spec.get("top_lean_xz", [0.0, 0.0])
	if raw_at.size() != 2 or raw_base.size() != 2 or raw_top.size() != 2 or raw_lean.size() != 2:
		push_error("Veilfall exterior formation has invalid dimensions: " + str(spec.get("id", "unknown")))
		return
	var at := Vector2(float(raw_at[0]), float(raw_at[1]))
	var world_at := to_global(Vector3(at.x, 0.0, at.y))
	var terrain_y := float(_world.call("ground_height_at", world_at.x, world_at.z))
	if not is_finite(terrain_y):
		push_error("Veilfall exterior formation has no terrain support: " + str(spec.get("id", "unknown")))
		return
	var height := float(spec.get("height_m", 12.0))
	var sink := float(spec.get("sink_m", 1.2))
	var base_y := terrain_y - global_position.y - sink
	var base_radius := Vector2(float(raw_base[0]), float(raw_base[1]))
	var top_radius := Vector2(float(raw_top[0]), float(raw_top[1]))
	var lean := Vector2(float(raw_lean[0]), float(raw_lean[1]))
	var seed_value := int(spec.get("seed", 1))
	var holder := Node3D.new()
	holder.name = str(spec.get("id", "VeilfallFormation")).to_pascal_case()
	holder.position = Vector3(at.x, base_y, at.y)
	add_child(holder)
	var body := MeshInstance3D.new()
	body.name = "FacetedCragBody"
	body.mesh = _formation_mesh(base_radius, top_radius, height + sink, lean, seed_value)
	body.material_override = _rock_material
	body.visibility_range_end = 1100.0
	body.visibility_range_end_margin = 120.0
	holder.add_child(body)
	var solid := StaticBody3D.new()
	solid.name = "PhysicalCragSupport"
	holder.add_child(solid)
	var collider := CollisionShape3D.new()
	collider.name = "CragTrimesh"
	collider.shape = (body.mesh as ArrayMesh).create_trimesh_shape()
	solid.add_child(collider)
	var cap := MeshInstance3D.new()
	cap.name = "VegetatedShelfCap"
	cap.position = Vector3(lean.x, height + sink + 0.04, lean.y)
	cap.mesh = _cap_mesh(top_radius * 0.92, seed_value + 71)
	cap.material_override = _cap_material
	cap.visibility_range_end = 900.0
	cap.visibility_range_end_margin = 100.0
	holder.add_child(cap)
	var top_global := to_global(Vector3(at.x + lean.x, base_y + height + sink + 0.08, at.y + lean.y))
	_supports[str(spec.get("id", ""))] = {
		"centre": top_global,
		"radius": minf(top_radius.x, top_radius.y) * 0.78,
	}
	formation_receipt.append({
		"id": str(spec.get("id", "")),
		"terrain_y": terrain_y,
		"top_y": top_global.y,
		"height_m": height,
		"route_edge_clearance_m": float(spec.get("route_edge_clearance_m", NAN)),
		"physical_support": collider.shape != null,
	})


func _formation_mesh(base_radius: Vector2, top_radius: Vector2, height: float,
		lean: Vector2, seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var segments := 9
	var rings: Array = []
	for ring_index in 4:
		var t := float(ring_index) / 3.0
		var eased := smoothstep(0.0, 1.0, t)
		var radius := base_radius.lerp(top_radius, eased)
		var centre := lean * eased
		var ring: Array[Vector3] = []
		for index in segments:
			var angle := TAU * float(index) / float(segments)
			var jitter := rng.randf_range(0.88, 1.12)
			ring.append(Vector3(centre.x + cos(angle) * radius.x * jitter,
				height * t, centre.y + sin(angle) * radius.y * jitter))
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring_index in 3:
		var lower: Array = rings[ring_index]
		var upper: Array = rings[ring_index + 1]
		for index in segments:
			var next := (index + 1) % segments
			_triangle(surface, lower[index], lower[next], upper[next])
			_triangle(surface, lower[index], upper[next], upper[index])
	var top_ring: Array = rings[3]
	var cap_centre := Vector3(lean.x, height, lean.y)
	for index in segments:
		_triangle(surface, cap_centre, top_ring[index], top_ring[(index + 1) % segments])
	surface.generate_normals()
	return surface.commit()


func _cap_mesh(radius: Vector2, seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var segments := 12
	var rim: Array[Vector3] = []
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		var jitter := rng.randf_range(0.88, 1.10)
		rim.append(Vector3(cos(angle) * radius.x * jitter, rng.randf_range(-0.08, 0.08),
			sin(angle) * radius.y * jitter))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in segments:
		_triangle(surface, Vector3.ZERO, rim[index], rim[(index + 1) % segments])
	surface.generate_normals()
	return surface.commit()


func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


func _build_authored_groves() -> void:
	# Host simulation shells retain the same physical crags, but WaterWorld
	# deliberately does not mount the scenic vegetation renderer in those shells.
	if bool(_world.get("simulation_only")):
		return
	var vegetation := _world.get_node_or_null("WaterVegetation")
	if vegetation == null or not vegetation.has_method("add_authored_placements"):
		push_error("Veilfall exterior needs the production Water vegetation renderer")
		return
	var placements: Array[Dictionary] = []
	for grove: Dictionary in _rules.get("groves", []):
		var support_id := str(grove.get("support", ""))
		if not _supports.has(support_id):
			push_error("Veilfall grove has no authored geological support: " + support_id)
			continue
		var support: Dictionary = _supports[support_id]
		var centre: Vector3 = support.centre
		var radius := minf(float(support.radius), float(grove.get("radius_m", support.radius)))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(grove.get("seed", 1))
		_append_grove_layer(placements, rng, centre, radius, int(grove.get("trees", 0)), TREES,
			"authored_trees", 0.90, 1.45, 900.0)
		_append_grove_layer(placements, rng, centre, radius, int(grove.get("shrubs", 0)), SHRUBS,
			"authored_shrubs", 0.62, 1.18, 520.0)
		_append_grove_layer(placements, rng, centre, radius, int(grove.get("groundcover", 0)), GROUNDCOVER,
			"authored_groundcover", 0.50, 0.92, 300.0)
	authored_vegetation_count = placements.size()
	vegetation.call("add_authored_placements", placements)


func _append_grove_layer(into: Array[Dictionary], rng: RandomNumberGenerator,
		centre: Vector3, radius: float, amount: int, models: Array, layer: String,
		min_scale: float, max_scale: float, visibility_range: float) -> void:
	for index in amount:
		var angle := TAU * (float(index) / maxf(1.0, float(amount))) + rng.randf_range(-0.42, 0.42)
		var distance := radius * sqrt(rng.randf_range(0.05, 0.86))
		var model_path := str(models[rng.randi_range(0, models.size() - 1)])
		var model_scale := 0.22 if model_path.contains("Bush_Common_Flowers") else 1.0
		into.append({
			"model": model_path,
			"position": centre + Vector3(cos(angle) * distance, -0.04, sin(angle) * distance),
			"normal": Vector3.UP,
			"yaw": rng.randf_range(-PI, PI),
			"scale": rng.randf_range(min_scale, max_scale) * model_scale,
			"align_to_slope": false,
			"visibility_range_m": visibility_range,
			"layer": layer,
			"island_id": "veilfall",
		})


func _material(tint: Color, roughness: float, rock_texture: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = roughness
	if rock_texture:
		material.albedo_texture = ROCK_ALBEDO
	else:
		material.albedo_texture = GRASS_ALBEDO
		material.normal_enabled = true
		material.normal_texture = GRASS_NORMAL
		material.normal_scale = 0.22
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_triplanar_sharpness = 5.0
	material.uv1_scale = Vector3.ONE * (0.12 if rock_texture else 0.18)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func diagnostic_receipt() -> Dictionary:
	return {
		"formations": formation_receipt.duplicate(true),
		"authored_vegetation_count": authored_vegetation_count,
	}
