extends Node3D

## Visual-only hierarchy for the Practice Meadow / tournament ground.
##
## The four large crescent shrines beside this field are an intentional home
## circle. This layer makes the tournament read as a different place without
## moving those shrines or changing the fight floor beneath them. Nothing built
## here creates a StaticBody3D, Area3D, prompt, or gameplay state.

const CONFIG_PATH := "res://data/config/tournament_ground_presentation.json"

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
	var radius := float(spec.get("radius_m", 6.25))
	var count := maxi(12, int(spec.get("segments", 28)))
	var width := float(spec.get("mark_width_m", 0.32))
	var material := _material(Color(str(spec.get("colour", "#b98542"))), 0.98)
	var holder := Node3D.new()
	holder.name = "TournamentListsRing"
	add_child(holder)
	var arc_length := TAU * radius / float(count) * 0.78
	for index in count:
		# Small regular gaps keep the marking hand-laid and prevent a perfect
		# procedural torus from competing with the organic meadow.
		var angle := TAU * float(index) / float(count)
		var point := centre + Vector2(cos(angle), sin(angle)) * radius
		var ground := float(world.call("ground_height_at", point.x, point.y))
		if is_nan(ground):
			continue
		var mark := MeshInstance3D.new()
		mark.name = "ListMark_%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(arc_length, 0.035, width)
		mesh.material = material
		mark.mesh = mesh
		holder.add_child(mark)
		mark.global_position = Vector3(point.x, ground + 0.022, point.y)
		mark.rotation.y = -angle


func _build_marshal_canopy(world: Node) -> void:
	var spec := _config.get("marshal_canopy", {}) as Dictionary
	var at := _xz(spec.get("at", []))
	var ground := float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		return
	var yaw := deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	var width := float(spec.get("width_m", 5.2))
	var depth := float(spec.get("depth_m", 2.4))
	var height := float(spec.get("height_m", 4.7))
	var wood := _material(Color(str(spec.get("wood_colour", "#563923"))), 0.9)
	var roof := _material(Color(str(spec.get("roof_colour", "#315746"))), 0.94)
	var holder := Node3D.new()
	holder.name = "MarshalCanopy"
	add_child(holder)
	holder.global_position = Vector3(at.x, ground, at.y)
	holder.rotation.y = yaw

	for x in [-width * 0.5, width * 0.5]:
		for z in [-depth * 0.5, depth * 0.5]:
			_box(holder, "CanopyPost", Vector3(0.16, height - 0.45, 0.16),
				Vector3(x, (height - 0.45) * 0.5, z), wood)
	for z in [-depth * 0.5, depth * 0.5]:
		_box(holder, "CanopyBeam", Vector3(width + 0.35, 0.18, 0.20),
			Vector3(0.0, height - 0.5, z), wood)
	# A pitched village-green awning is one unmistakable roof silhouette, not
	# another arch or a run of flags. The unequal front/back pitch gives the
	# walk-up an asymmetric profile.
	var roof_y := height - 0.15
	var roof_depth := depth * 0.66
	var left := _box(holder, "CanopyRoofWest", Vector3(width + 0.5, 0.12, roof_depth),
		Vector3(0.0, roof_y, -depth * 0.28), roof)
	left.rotation.x = deg_to_rad(-14.0)
	var right := _box(holder, "CanopyRoofEast", Vector3(width + 0.5, 0.12, roof_depth),
		Vector3(0.0, roof_y - 0.04, depth * 0.28), roof)
	right.rotation.x = deg_to_rad(18.0)

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
	lamp.position = Vector3(-width * 0.18, height - 0.78, 0.0)
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
		var packed := load(path) as PackedScene
		if packed == null:
			push_warning("practice equipment missing: %s" % path)
			continue
		var prop := packed.instantiate() as Node3D
		prop.name = str(spec.get("name", spec.get("model", "PracticeProp")))
		holder.add_child(prop)
		prop.global_position = Vector3(at.x, ground, at.y)
		prop.rotation.y = deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		prop.scale = Vector3.ONE * float(spec.get("scale", 1.0))


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	node.mesh = mesh
	node.position = at
	parent.add_child(node)
	return node


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
