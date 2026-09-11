extends Node3D

## Visual-only hierarchy for the Practice Meadow / tournament ground.
##
## The four large crescent shrines beside this field are an intentional home
## circle. This layer makes the tournament read as a different place without
## moving those shrines or changing the fight floor beneath them. Nothing built
## here creates a StaticBody3D, Area3D, prompt, or gameplay state.

const CONFIG_PATH := "res://data/config/tournament_ground_presentation.json"
const PRESENTATION_BOUNDS := preload("res://scripts/characters/render_bounds.gd")

var _config: Dictionary = {}


func build(world: Node) -> void:
	# Tournament itself is rotated to face the board. This layer's data is in
	# authoritative world coordinates, so detach its transform before placing
	# the ring and furniture rather than rotating the whole field a second time.
	top_level = true
	global_transform = Transform3D.IDENTITY
	_config = _read_config()
	if _config.is_empty():
		push_warning("tournament ground presentation config missing")
		return
	_build_lists_ring(world)
	_build_marshal_canopy(world)
	_build_training_equipment(world)


func _build_lists_ring(world: Node) -> void:
	var spec := _config.get("arena", {}) as Dictionary
	var centre := _xz(spec.get("centre", []))
	var radius_x := float(spec.get("radius_x_m", 6.65))
	var radius_z := float(spec.get("radius_z_m", 5.75))
	var count := maxi(48, int(spec.get("segments", 72)))
	var width := float(spec.get("ribbon_width_m", 0.54))
	var lift := float(spec.get("lift_m", 0.035))
	var material := _material(Color(str(spec.get("colour", "#b98542"))), 0.98)
	var texture_path := str(spec.get("albedo_texture", ""))
	if ResourceLoader.exists(texture_path):
		material.albedo_texture = load(texture_path) as Texture2D
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	for index in count:
		var angle_0 := TAU * float(index) / float(count)
		var angle_1 := TAU * float(index + 1) / float(count)
		var outer_0 := centre + Vector2(cos(angle_0) * (radius_x + width * 0.5), sin(angle_0) * (radius_z + width * 0.5))
		var inner_0 := centre + Vector2(cos(angle_0) * (radius_x - width * 0.5), sin(angle_0) * (radius_z - width * 0.5))
		var outer_1 := centre + Vector2(cos(angle_1) * (radius_x + width * 0.5), sin(angle_1) * (radius_z + width * 0.5))
		var inner_1 := centre + Vector2(cos(angle_1) * (radius_x - width * 0.5), sin(angle_1) * (radius_z - width * 0.5))
		var vertices := [
			_terrain_point(world, outer_0, lift), _terrain_point(world, inner_0, lift),
			_terrain_point(world, outer_1, lift), _terrain_point(world, inner_1, lift),
		]
		if vertices.any(func(point: Vector3) -> bool: return is_nan(point.y)):
			continue
		var u0 := float(index) / 6.0
		var u1 := float(index + 1) / 6.0
		_add_ribbon_vertex(surface, vertices[0], Vector2(u0, 0.0))
		_add_ribbon_vertex(surface, vertices[1], Vector2(u0, 1.0))
		_add_ribbon_vertex(surface, vertices[2], Vector2(u1, 0.0))
		_add_ribbon_vertex(surface, vertices[2], Vector2(u1, 0.0))
		_add_ribbon_vertex(surface, vertices[1], Vector2(u0, 1.0))
		_add_ribbon_vertex(surface, vertices[3], Vector2(u1, 1.0))
	var ribbon := MeshInstance3D.new()
	ribbon.name = "TournamentListsRibbon"
	ribbon.mesh = surface.commit()
	add_child(ribbon)


func _add_ribbon_vertex(surface: SurfaceTool, point: Vector3, uv: Vector2) -> void:
	surface.set_normal(Vector3.UP)
	surface.set_uv(uv)
	surface.add_vertex(point)


func _terrain_point(world: Node, point: Vector2, lift: float) -> Vector3:
	var ground := float(world.call("ground_height_at", point.x, point.y))
	return Vector3(point.x, ground + lift if not is_nan(ground) else NAN, point.y)


func _build_marshal_canopy(world: Node) -> void:
	var spec := _config.get("marshal_canopy", {}) as Dictionary
	var at := _xz(spec.get("at", []))
	var ground := float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		return
	var yaw := deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	var holder := Node3D.new()
	holder.name = "MarshalCanopy"
	add_child(holder)
	holder.global_position = Vector3(at.x, ground, at.y)
	holder.rotation.y = yaw

	var stall_path := "%s/%s.gltf" % [str(spec.get("dir", "")), str(spec.get("model", ""))]
	var stall := _load_prop(stall_path)
	if stall == null:
		push_warning("marshal canopy missing: %s" % stall_path)
		return
	stall.name = "InstalledMarshalStall"
	holder.add_child(stall)
	var bounds: AABB = PRESENTATION_BOUNDS.measure(stall)
	var fit_height := float(spec.get("fit_height_m", 4.35))
	var scale_factor := fit_height / maxf(bounds.size.y, 0.001)
	stall.scale = Vector3(scale_factor * float(spec.get("width_scale", 1.0)),
		scale_factor, scale_factor)
	stall.position.y = -bounds.position.y * scale_factor

	# The source stall is a complete timber/cloth model. These are the kit's
	# cloth-only pieces, hung under the outside eaves to frame the bracket; they
	# are not freestanding flags around the combat ring.
	var accent_x := [-1.18, 1.18]
	var accent_models := spec.get("accent_models", []) as Array
	for index in mini(2, accent_models.size()):
		var accent_path := "%s/%s.gltf" % [str(spec.get("dir", "")), str(accent_models[index])]
		var accent := _load_prop(accent_path)
		if accent == null:
			continue
		accent.name = "CanopyClothAccent_%d" % index
		holder.add_child(accent)
		accent.position = Vector3(accent_x[index], fit_height - 0.12, 0.72)
		accent.scale = Vector3.ONE * 0.72

	var lamp_colour := Color(str(spec.get("light_colour", "#ffd19a")))
	var lamp_mat := _material(lamp_colour, 0.45)
	lamp_mat.emission_enabled = true
	lamp_mat.emission = lamp_colour
	lamp_mat.emission_energy_multiplier = 1.6
	var lamp := MeshInstance3D.new()
	lamp.name = "MarshalLantern"
	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.13
	lamp_mesh.height = 0.26
	lamp_mesh.material = lamp_mat
	lamp.mesh = lamp_mesh
	lamp.position = Vector3(0.0, fit_height - 0.95, 0.12)
	holder.add_child(lamp)
	var light := OmniLight3D.new()
	light.name = "MarshalWarmLight"
	light.light_color = lamp_colour
	light.light_energy = 1.15
	light.omni_range = 7.0
	light.shadow_enabled = false
	light.position = lamp.position
	holder.add_child(light)


func _build_training_equipment(world: Node) -> void:
	var holder := Node3D.new()
	holder.name = "TrainingEquipment"
	add_child(holder)
	for raw: Variant in _config.get("equipment", []):
		var spec := raw as Dictionary
		var at := _xz(spec.get("at", []))
		var ground := float(world.call("ground_height_at", at.x, at.y))
		if is_nan(ground):
			continue
		var path := "%s/%s.gltf" % [str(spec.get("dir", "")), str(spec.get("model", ""))]
		var prop := _load_prop(path)
		if prop == null:
			push_warning("practice equipment missing: %s" % path)
			continue
		prop.name = str(spec.get("name", spec.get("model", "PracticeProp")))
		holder.add_child(prop)
		prop.global_position = Vector3(at.x, ground, at.y)
		prop.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		prop.scale = Vector3.ONE * float(spec.get("scale", 1.0))


func _load_prop(path: String) -> Node3D:
	var packed := load(path) as PackedScene
	return packed.instantiate() as Node3D if packed != null else null


func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	return material


func _xz(raw: Variant) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.ZERO


func _read_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
