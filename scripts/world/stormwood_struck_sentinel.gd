extends Node3D

## Location-owned presentation for The Struck Sentinel. The canonical landmark
## seat is a viewing/encounter point on Ash Road, not the tree's trunk origin.
## Keeping this composition visual-only preserves Ranger Pax, traversal and the
## encounter arena while giving the opening landmark a complete silhouette.
const ELDER := preload("res://assets/environment/stylized_nature/DeadTree_1.gltf")
const BROKEN_LIMB := preload("res://assets/environment/stylized_nature/DeadTree_2.gltf")
const ROCK := preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf")
const VISUAL_OFFSET := Vector2(-20.0, 24.0)
const COL_CHAR := Color("#282b29")
const COL_SCAR := Color("#78e4ed")
const COL_SCAR_CORE := Color("#d0fbff")


static func visual_offset_xz() -> Vector2:
	return VISUAL_OFFSET


func build() -> void:
	_charred_ground()
	_installed_tree("LightningSplitElder", ELDER, Vector3.ZERO, 4.4, 26.0)
	var limb := _installed_tree("FallenCrownLimb", BROKEN_LIMB,
		Vector3(7.4, 1.7, 2.8), 0.86, -38.0)
	limb.rotation.z = deg_to_rad(78.0)
	_build_split_scar()
	_build_root_stones()
	var afterglow := OmniLight3D.new()
	afterglow.name = "StrikeAfterglow"
	afterglow.position = Vector3(1.3, 13.5, -1.5)
	afterglow.light_color = COL_SCAR
	afterglow.light_energy = 2.2
	afterglow.omni_range = 24.0
	afterglow.shadow_enabled = false
	add_child(afterglow)


func _charred_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "CharredRootPlate"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 9.0
	mesh.bottom_radius = 9.6
	mesh.height = 0.10
	mesh.radial_segments = 32
	ground.mesh = mesh
	ground.material_override = _material(COL_CHAR)
	ground.position.y = 0.06
	add_child(ground)


func _installed_tree(node_name: String, scene: PackedScene, at: Vector3,
		scale_factor: float, yaw_degrees: float) -> Node3D:
	var tree := scene.instantiate() as Node3D
	tree.name = node_name
	tree.position = at
	tree.scale = Vector3.ONE * scale_factor
	tree.rotation.y = deg_to_rad(yaw_degrees)
	add_child(tree)
	return tree


func _build_split_scar() -> void:
	var scar := Node3D.new()
	scar.name = "LightningSplitScar"
	add_child(scar)
	# The south-east face points back to the authored road/landmark seat. The
	# broken line widens at mid-trunk and forks toward the fallen crown.
	var points: Array[Vector3] = [
		Vector3(1.45, 2.8, -1.70), Vector3(0.85, 7.0, -1.55),
		Vector3(1.70, 11.2, -1.72), Vector3(0.75, 15.8, -1.45),
		Vector3(1.55, 20.5, -1.62), Vector3(0.60, 25.6, -1.28),
		Vector3(1.15, 31.0, -1.38),
	]
	for i in points.size() - 1:
		_energy_segment(scar, "Scar%02d" % i, points[i], points[i + 1], 0.20, COL_SCAR)
	_energy_segment(scar, "CrownFork", points[4], Vector3(4.3, 23.5, -0.8), 0.15, COL_SCAR)
	_energy_segment(scar, "RootFork", points[1], Vector3(4.8, 1.0, -4.3), 0.13, COL_SCAR_CORE)
	_energy_segment(scar, "RootForkWest", points[1], Vector3(-3.9, 0.9, -2.9), 0.13, COL_SCAR_CORE)


func _energy_segment(parent: Node3D, node_name: String, start: Vector3,
		finish: Vector3, radius: float, colour: Color) -> void:
	var segment := MeshInstance3D.new()
	segment.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.72
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(finish)
	mesh.radial_segments = 8
	segment.mesh = mesh
	segment.material_override = _material(colour, true)
	segment.position = (start + finish) * 0.5
	segment.quaternion = Quaternion(Vector3.UP, (finish - start).normalized())
	parent.add_child(segment)


func _build_root_stones() -> void:
	var roots := Node3D.new()
	roots.name = "BlastRootStones"
	add_child(roots)
	var seats: Array[Vector3] = [
		Vector3(-6.7, 0.08, -2.2), Vector3(-4.3, 0.08, 6.2),
		Vector3(3.0, 0.08, 7.0), Vector3(7.0, 0.08, -4.2),
		Vector3(2.5, 0.08, -7.2),
	]
	for i in seats.size():
		var stone := ROCK.instantiate() as Node3D
		stone.name = "RootStone%02d" % i
		stone.position = seats[i]
		stone.rotation.y = deg_to_rad(float(i * 61 + 13))
		stone.scale = Vector3.ONE * (0.85 + float(i % 3) * 0.17)
		roots.add_child(stone)


func _material(colour: Color, emissive := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.92
	if emissive:
		material.emission_enabled = true
		material.emission = colour
		material.emission_energy_multiplier = 3.0
	return material
