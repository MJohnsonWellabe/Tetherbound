extends Node3D

## One collisionless roadside threshold at the mouth of the Trail Camp
## clearing. Ground-level members flank the real road; only the beam/sign cross
## above it. This announces the retained camp without moving its kit or turning
## a decorative presentation node into a traversal obstacle.

const WOOD_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_WoodTrim_BaseColor.png")
const WOOD_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_WoodTrim_Normal.png")
const WOOD_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_WoodTrim_Roughness.png")
const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const LANTERN_NATIVE_HEIGHT_M := 1.3370076
const LANTERN_TARGET_HEIGHT_M := 0.50


func build(at: Vector3, yaw_deg: float = 0.0) -> void:
	position = at
	rotation.y = deg_to_rad(yaw_deg)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#68472b")
	wood.albedo_texture = WOOD_ALBEDO
	wood.normal_enabled = true
	wood.normal_texture = WOOD_NORMAL
	wood.roughness_texture = WOOD_ROUGHNESS
	wood.uv1_triplanar = true
	wood.uv1_scale = Vector3.ONE * 0.34
	wood.roughness = 0.94

	_box("RoadsidePostLeft", Vector3(0.32, 3.35, 0.34),
		Vector3(-2.65, 1.63, 0.0), wood)
	_box("RoadsidePostRight", Vector3(0.32, 3.35, 0.34),
		Vector3(2.65, 1.63, 0.0), wood)
	_box("ThresholdBeam", Vector3(5.75, 0.30, 0.38),
		Vector3(0.0, 3.12, 0.0), wood)
	_box("TrailCampBoard", Vector3(2.15, 0.72, 0.16),
		Vector3(0.0, 2.62, -0.20), wood)
	_brace("LeftKneeBrace", Vector3(-2.12, 2.78, -0.02), -38.0, wood)
	_brace("RightKneeBrace", Vector3(2.12, 2.78, -0.02), 38.0, wood)
	# Label3D's readable face points toward local +Z. The south-west road
	# approach is local -Z at this threshold yaw, so the front face needs PI.
	_label("TrailCampLabelFront", Vector3(0.0, 2.62, -0.30), 180.0)
	_label("TrailCampLabelBack", Vector3(0.0, 2.62, -0.10), 0.0)
	_lantern("LeftApproachLantern", Vector3(-2.28, 2.34, -0.21))
	_lantern("RightApproachLantern", Vector3(2.28, 2.34, -0.21))


func _box(node_name: String, size: Vector3, at: Vector3,
		material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	mesh_instance.position = at
	add_child(mesh_instance)
	return mesh_instance


func _brace(node_name: String, at: Vector3, roll_deg: float,
		material: Material) -> void:
	var brace := _box(node_name, Vector3(1.22, 0.20, 0.24), at, material)
	brace.rotation.z = deg_to_rad(roll_deg)


func _label(node_name: String, at: Vector3, yaw_deg: float) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = "TRAIL CAMP"
	label.font_size = 96
	label.pixel_size = 0.006
	label.modulate = Color("#f2d79a")
	label.outline_modulate = Color("#302116")
	label.outline_size = 12
	label.position = at
	label.rotation.y = deg_to_rad(yaw_deg)
	label.no_depth_test = false
	add_child(label)


func _lantern(node_name: String, at: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = node_name
	holder.position = at
	add_child(holder)
	var lantern := WALL_LANTERN.instantiate() as Node3D
	lantern.name = "InstalledWallLantern"
	lantern.rotation.y = PI
	lantern.scale = Vector3.ONE * (LANTERN_TARGET_HEIGHT_M / LANTERN_NATIVE_HEIGHT_M)
	holder.add_child(lantern)
	var warm := Color("#e17928")
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = warm
	flame_mat.emission_enabled = true
	flame_mat.emission = warm
	flame_mat.emission_energy_multiplier = 0.90
	var source := MeshInstance3D.new()
	source.name = "VisibleWarmSource"
	var source_mesh := SphereMesh.new()
	source_mesh.radius = 0.070
	source_mesh.height = 0.14
	source.mesh = source_mesh
	source.material_override = flame_mat
	source.position = Vector3(0.0, 0.27, -0.30)
	holder.add_child(source)
	var light := OmniLight3D.new()
	light.name = "ApproachWarmPool"
	light.light_color = warm
	light.light_energy = 1.70
	light.omni_range = 6.0
	light.shadow_enabled = false
	light.position = source.position
	holder.add_child(light)
