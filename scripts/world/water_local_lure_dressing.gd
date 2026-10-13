extends Node3D
## Persistent scenery beside the disposable local-chain sites. No gameplay state,
## collision or interactables. Anchors come from the chains or named landmarks.
const CONFIG := "res://data/config/water_local_lure_dressing.json"
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const MATERIALS := preload("res://scripts/world/imported_materials.gd")
const CLOTH := preload("res://assets/props/quaternius_fantasy/survey_cloth.gdshader")
var _built := false

func build(world: Node3D) -> void:
	if _built or bool(world.get("simulation_only")):
		return
	_built = true
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	for spec: Dictionary in cfg.sites:
		var anchor := _site_position(world, spec)
		if not anchor.is_finite():
			push_error("Missing or unsupported lure anchor: " + str(spec.id))
			continue
		var site := Node3D.new()
		site.name = str(spec.id)
		add_child(site)
		site.position = anchor
		site.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		var pieces: Array = spec.pieces
		var terrace_repair := str(spec.id) == "DrownedGardenTerraceCourses" and bool(spec.get("terrace_beds_repair_enabled", false))
		if terrace_repair:
			pieces = spec.get("terrace_bed_pieces", [])
		for piece: Dictionary in pieces:
			if terrace_repair and str(piece.get("kind", "")) == "terrace_bed":
				var bed_spec: Dictionary = spec.get("terrace_bed_style", {}).duplicate(true)
				bed_spec.merge(piece, true)
				_build_terrace_bed(world, site, bed_spec)
				continue
			var prop := _piece(piece)
			if prop == null:
				continue
			site.add_child(prop)
			if float(piece.get("clear_radius_m", 0.0)) > 0.0:
				prop.add_to_group("grass_clear")
				prop.set_meta("grass_clear_radius", float(piece.clear_radius_m))
			# Each foot sits on the real baked floor, including sloped sites.
			# Upper courses explicitly inherit the anchor floor for clean joins.
			if piece.has("support"):
				var support := site.get_node(NodePath(str(piece.support))) as Node3D
				prop.position += support.position
			elif bool(piece.get("footprint_grounding", false)):
				if not _ground_footprint(world, prop):
					push_error("Unsupported lure footprint: " + str(piece.id))
					prop.free()
			elif bool(piece.get("grounded", true)):
				var at := prop.global_position
				prop.position.y += float(world.call("ground_height_at", at.x, at.z)) - site.position.y
	var terrace_blockout := preload("res://scripts/world/water_garden_terraces_blockout.gd").new()
	terrace_blockout.name = "GardenTerracesBlockout"
	add_child(terrace_blockout)
	terrace_blockout.build(world, self)

## Static farm visual family: closed soil fill, four boards, furrows and plants.
## Every bed has one level top; no farm interaction, collision or terrain edit.
static func _build_terrace_bed(world: Node3D, site: Node3D, spec: Dictionary) -> void:
	var bed := Node3D.new()
	bed.name = str(spec.id)
	var at: Array = spec.at
	bed.position = Vector3(float(at[0]), 0.0, float(at[2]))
	bed.rotation.y = deg_to_rad(float(spec.yaw_deg))
	site.add_child(bed)
	var size := Vector2(float(spec.soil_size_xz[0]), float(spec.soil_size_xz[1]))
	var edge_t := float(spec.edge_thickness_m)
	var edge_h := float(spec.edge_height_m)
	var half := size * 0.5 + Vector2.ONE * edge_t
	var lowest := INF
	var highest := -INF
	for x in 9:
		for z in 23:
			var sample_at := bed.to_global(Vector3(lerpf(-half.x, half.x, float(x) / 8.0),
				0.0, lerpf(-half.y, half.y, float(z) / 22.0)))
			var ground := float(world.call("ground_height_at", sample_at.x, sample_at.z))
			if not is_finite(ground):
				push_error("Terrace bed has nonfinite terrain: " + str(spec.id))
				bed.free()
				return
			lowest = minf(lowest, ground)
			highest = maxf(highest, ground)
	var clearance := float(spec.soil_clearance_m)
	var top := highest + clearance
	var bottom := lowest - float(spec.fill_sink_m)
	var depth := top - bottom
	if not is_finite(depth) or depth <= 0.0 or depth > float(spec.max_fill_depth_m):
		push_error("Terrace bed exceeds closed-fill depth: " + str(spec.id))
		bed.free()
		return
	# Its parent is the terrain-anchored landmark; only yaw is inherited.
	bed.position.y = top - site.global_position.y
	bed.set_meta("level_soil_top_y", top)
	bed.set_meta("closed_fill_bottom_y", bottom)
	var soil := StandardMaterial3D.new()
	soil.albedo_color = Color(str(spec.soil_colour))
	soil.roughness = float(spec.roughness)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(str(spec.edge_colour))
	wood.roughness = float(spec.roughness)
	wood = preload("res://scripts/world/tidewake_material_family.gd").standard(wood, "timber")
	_terrace_box(bed, "Soil", Vector3(size.x, depth, size.y), Vector3(0.0, -depth * 0.5, 0.0), soil)
	for side: float in [-1.0, 1.0]:
		_terrace_box(bed, "EndBoard", Vector3(size.x + edge_t * 2.0, edge_h, edge_t),
			Vector3(0.0, -clearance + edge_h * 0.5, side * (size.y + edge_t) * 0.5), wood)
		_terrace_box(bed, "SideBoard", Vector3(edge_t, edge_h, size.y),
			Vector3(side * (size.x + edge_t) * 0.5, -clearance + edge_h * 0.5, 0.0), wood)
	var furrows := int(spec.furrows)
	var pitch := size.y / float(furrows + 1)
	var ridge_h := float(spec.furrow_height_m)
	for i in furrows:
		_terrace_box(bed, "Furrow", Vector3(size.x * 0.92, ridge_h, pitch * 0.42),
			Vector3(0.0, ridge_h * 0.35, -size.y * 0.5 + pitch * float(i + 1)), wood)
	var plants: Array = spec.plants
	for i in plants.size():
		var plant_spec: Dictionary = plants[i].duplicate(true)
		plant_spec["id"] = "Plant%d" % i
		plant_spec["at"] = [0.0, 0.0, 0.0]
		var plant := _piece(plant_spec)
		if plant == null:
			push_error("Terrace bed plant failed to load: " + str(plants[i].model))
			continue
		# Height-normalized installed models also fit within the narrow bed.
		var bounds := BOUNDS.measure(plant)
		var width := maxf(bounds.size.x, bounds.size.z)
		if width > size.x * 0.8:
			plant.scale *= size.x * 0.8 / width
		plant.position = Vector3(0.0, 0.0, -size.y * 0.5 + pitch * float(i + 1))
		bed.add_child(plant)

static func _terrace_box(parent: Node3D, label: String, size: Vector3,
		at: Vector3, material: StandardMaterial3D) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)

static func _site_position(world: Node3D, spec: Dictionary) -> Vector3:
	if not spec.has("landmark_id"):
		var anchor := world.get_node_or_null(NodePath(str(spec.get("anchor", "")))) as Node3D
		return anchor.position if anchor != null else Vector3.INF
	var config: Dictionary = world.get("config")
	for landmark: Dictionary in config.get("landmarks", []):
		if str(landmark.get("id", "")) != str(spec.landmark_id):
			continue
		var raw: Array = landmark.get("position", [])
		if raw.size() != 3:
			return Vector3.INF
		var ground := float(world.call("ground_height_at", float(raw[0]), float(raw[2])))
		if not is_finite(ground) or ground <= 0.0:
			return Vector3.INF
		return Vector3(float(raw[0]), ground, float(raw[2]))
	return Vector3.INF

## Low ruin courses sit beside the trail, with their configured negative Y
## burying the base. Use the lowest floor across the actual rotated footprint,
## rather than a centre sample that leaves downhill corners in open air.
static func _ground_footprint(world: Node3D, prop: Node3D) -> bool:
	var box := BOUNDS.measure(prop)
	var lowest := INF
	for across in 5:
		for depth in 3:
			var local := Vector3(lerpf(box.position.x, box.end.x, float(across) / 4.0),
				0.0, lerpf(box.position.z, box.end.z, float(depth) / 2.0))
			var at := prop.to_global(local)
			var ground := float(world.call("ground_height_at", at.x, at.z))
			if not is_finite(ground) or ground <= 0.0:
				return false
			lowest = minf(lowest, ground)
	# prop.position.y already contains the authored sink relative to its site.
	prop.position.y += lowest - prop.get_parent_node_3d().global_position.y
	return true

static func _piece(spec: Dictionary) -> Node3D:
	if spec.get("kind", "") == "post":
		return _post(spec)
	if spec.get("kind", "") == "chart":
		return _chart(spec)
	if spec.get("kind", "") == "lantern":
		var root := Node3D.new()
		root.name = str(spec.id)
		var at: Array = spec.at
		root.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		var builder := preload("res://scripts/world/water_dock_dressing.gd").new()
		builder.call("_lantern", root, spec, Vector3.ZERO, 0.0)
		builder.free()
		_strip_physics(root)
		return root
	var scene := load(str(spec.model)) as PackedScene
	if scene == null:
		return null
	var mesh := scene.instantiate() as Node3D
	_strip_physics(mesh)
	MATERIALS.make_dielectric(mesh)
	_recolour_cloth(mesh)
	var box := BOUNDS.measure(mesh)
	if box.size.y <= 0.001:
		mesh.free()
		return null
	var factor := float(spec.height_m) / box.size.y
	mesh.scale *= factor
	mesh.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * factor
	var root := Node3D.new()
	root.name = str(spec.id)
	root.add_child(mesh)
	var at: Array = spec.get("at", [0, 0, 0])
	root.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
	root.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	return root

static func _chart(spec: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = str(spec.id)
	var at: Array = spec.at
	root.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
	var paper := StandardMaterial3D.new()
	# Resource loading follows Godot's import remap in exported packages.
	paper.albedo_texture = load(str(spec.texture)) as Texture2D
	paper.roughness = 0.97
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	var panel := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(float(spec.width_m), float(spec.height_m))
	quad.material = paper
	panel.mesh = quad
	root.add_child(panel)
	# Wooden rollers suspend the sheet from the awning's two uprights.
	for sign_y: float in [-1.0, 1.0]:
		var rod := _post({"id":"ChartRoller", "height_m":float(spec.width_m) + 0.16,
			"width_m":0.075, "at":[float(spec.width_m) * 0.5 + 0.08, sign_y * float(spec.height_m) * 0.5, 0.0]})
		rod.rotation.z = PI * 0.5
		root.add_child(rod)
	return root

static func _post(spec: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = str(spec.id)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	var width := float(spec.get("width_m", 0.18))
	shape.size = Vector3(width, float(spec.height_m), width)
	var wood := StandardMaterial3D.new()
	wood.albedo_texture = load("res://assets/environment/stylized_nature/Bark_TwistedTree.png")
	wood.albedo_color = Color("ac946f")
	wood.roughness = 0.94
	wood.uv1_scale = Vector3(0.35, 1.5, 1)
	wood = preload("res://scripts/world/tidewake_material_family.gd").standard(wood, "timber")
	shape.material = wood
	mesh.mesh = shape
	mesh.position.y = float(spec.height_m) * 0.5
	root.add_child(mesh)
	var at: Array = spec.get("at", [0, 0, 0])
	root.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
	return root

static func _recolour_cloth(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count():
			var source: Material = node.get_active_material(surface)
			if source is StandardMaterial3D and source.resource_name == "MI_Banner":
				var material := ShaderMaterial.new()
				material.shader = CLOTH
				material.set_shader_parameter("source_albedo", source.albedo_texture)
				material.set_shader_parameter("source_normal", source.normal_texture)
				node.set_surface_override_material(surface, material)
	for child: Node in node.get_children():
		_recolour_cloth(child)

static func _strip_physics(node: Node) -> void:
	for child: Node in node.get_children():
		if child is CollisionObject3D or child is CollisionShape3D or child is NavigationRegion3D:
			node.remove_child(child)
			child.free()
		else:
			_strip_physics(child)
