extends Node3D
## Persistent scenery beside the disposable local-chain sites. No gameplay state,
## collision or interactables. Canonical site coordinates remain owned by the chains.
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
		var anchor := world.get_node_or_null(NodePath(str(spec.anchor))) as Node3D
		if anchor == null:
			push_error("Missing lure anchor: " + str(spec.anchor))
			continue
		var site := Node3D.new()
		site.name = str(spec.id)
		add_child(site)
		site.position = anchor.position
		site.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		for piece: Dictionary in spec.pieces:
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
			elif bool(piece.get("grounded", true)):
				var at := prop.global_position
				prop.position.y += float(world.call("ground_height_at", at.x, at.z)) - site.position.y

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
