extends Node3D

## The village inn's public face.
##
## The underlying building deliberately stays in the settlement's one medieval
## module family, but that once left it visually interchangeable with Grandpa's
## private farmhouse. This child supplies the things a traveller reads before
## reaching the door: a broad porch silhouette, a name on both visible faces,
## warm exterior lamps, seating and luggage. Everything is authored in the
## inn prefab's local coordinates (front = +z), so village placement/yaw remain
## the only source of world positioning.

const FANTASY_DIR := "res://assets/props/quaternius_fantasy"
const BENCH := preload("res://assets/props/quaternius_fantasy/Bench.gltf")
const APPLE_BARREL := preload("res://assets/props/quaternius_fantasy/Barrel_Apples.gltf")
const BARREL := preload("res://assets/props/quaternius_fantasy/Barrel.gltf")
const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")

const DOOR_HALF_WIDTH := 0.8
const PORCH_WIDTH := 5.5
const PORCH_DEPTH := 1.85

var _timber := _material(Color("#34251d"), 0.88)
var _green := _material(Color("#29483b"), 0.82)
var _gold := _material(Color("#e7bd67"), 0.72)


func build() -> void:
	name = "InnExteriorIdentity"
	_build_public_porch()
	_build_signs()
	_build_lanterns()
	_build_guest_yard()


func _build_public_porch() -> void:
	var porch := Node3D.new()
	porch.name = "PublicPorch"
	add_child(porch)

	# One deep, full-width awning changes the ground-floor silhouette from the
	# farmhouse's single private threshold. The slight outward pitch sheds rain
	# and stops the canopy reading as a floating horizontal slab.
	var awning := _box("PorchAwning", Vector3(PORCH_WIDTH, 0.16, PORCH_DEPTH),
		Vector3(0.0, 2.74, 5.82), _green, false, porch)
	awning.rotation.x = deg_to_rad(-10.0)
	_box("PorchFascia", Vector3(PORCH_WIDTH + 0.12, 0.28, 0.18),
		Vector3(0.0, 2.48, 6.68), _timber, false, porch)
	_box("PorchHeader", Vector3(PORCH_WIDTH, 0.2, 0.2),
		Vector3(0.0, 2.52, 5.12), _timber, false, porch)
	for side: float in [-1.0, 1.0]:
		_box("PorchPost", Vector3(0.18, 2.48, 0.18),
			Vector3(side * 2.48, 1.24, 6.55), _timber, true, porch)
		var brace := _box("PorchBrace", Vector3(0.12, 0.82, 0.12),
			Vector3(side * 2.18, 2.12, 6.52), _gold, false, porch)
		brace.rotation.z = deg_to_rad(side * 42.0)


func _build_signs() -> void:
	var signs := Node3D.new()
	signs.name = "InnSigns"
	add_child(signs)

	# The front board answers the square view. The side board answers the
	# historical twins frame, which sees the inn and farmhouse side by side.
	_sign("FrontInnSign", "THE VILLAGE INN", Vector3(0.0, 3.55, 5.18), 0.0,
		Vector3(2.75, 0.72, 0.1), signs)
	_sign("SideInnSign", "INN  •  ROOMS", Vector3(3.17, 3.75, 1.25), 90.0,
		Vector3(2.35, 0.66, 0.1), signs)


func _sign(node_name: String, words: String, at: Vector3, yaw_deg: float,
		size: Vector3, parent: Node3D) -> void:
	var sign := Node3D.new()
	sign.name = node_name
	sign.position = at
	sign.rotation.y = deg_to_rad(yaw_deg)
	parent.add_child(sign)
	_box("Board", size, Vector3.ZERO, _green, false, sign)
	_box("TopRail", Vector3(size.x + 0.14, 0.08, 0.14),
		Vector3(0.0, size.y * 0.5, 0.0), _gold, false, sign)
	_box("BottomRail", Vector3(size.x + 0.14, 0.08, 0.14),
		Vector3(0.0, -size.y * 0.5, 0.0), _gold, false, sign)
	var label := Label3D.new()
	label.name = "Label"
	label.text = words
	label.font_size = 64
	label.pixel_size = 0.0027
	label.modulate = Color("#f5dfad")
	label.outline_size = 4
	label.outline_modulate = Color("#1d1712")
	label.double_sided = true
	label.position = Vector3(0.0, 0.0, 0.065)
	sign.add_child(label)


func _build_lanterns() -> void:
	var lamps := Node3D.new()
	lamps.name = "HospitalityLanterns"
	add_child(lamps)
	for side: float in [-1.0, 1.0]:
		var holder := Node3D.new()
		holder.name = "LanternLeft" if side < 0.0 else "LanternRight"
		holder.position = Vector3(side * 2.15, 2.05, 5.28)
		holder.scale = Vector3.ONE * 0.9
		lamps.add_child(holder)
		holder.add_child(WALL_LANTERN.instantiate())
		var light := OmniLight3D.new()
		light.name = "WarmPool"
		light.light_color = Color("#ffc56f")
		light.light_energy = 1.7
		light.omni_range = 5.0
		light.shadow_enabled = false
		light.position = Vector3(0.0, 0.08, 0.3)
		holder.add_child(light)


func _build_guest_yard() -> void:
	var yard := Node3D.new()
	yard.name = "GuestYard"
	add_child(yard)
	_prop("GuestBench", BENCH, Vector3(-1.75, 0.08, 6.42), 180.0, 0.95, yard)
	_prop("AppleBarrel", APPLE_BARREL, Vector3(2.15, 0.08, 6.18), -18.0, 0.95, yard)
	_prop("TravelBarrel", BARREL, Vector3(2.55, 0.08, 5.7), 12.0, 0.82, yard)
	# Compact luggage beside the bench: occupation without placing another
	# imported family in the village or blocking the door's 1.6m lane.
	_box("GuestLuggage", Vector3(0.62, 0.42, 0.38), Vector3(-2.34, 0.21, 6.16),
		_gold, true, yard)


func _prop(node_name: String, scene: PackedScene, at: Vector3, yaw_deg: float,
		scale_value: float, parent: Node3D) -> void:
	var prop := scene.instantiate() as Node3D
	prop.name = node_name
	prop.position = at
	prop.rotation.y = deg_to_rad(yaw_deg)
	prop.scale = Vector3.ONE * scale_value
	parent.add_child(prop)


func _box(node_name: String, size: Vector3, at: Vector3, material: Material,
		solid: bool, parent: Node3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.name = "%sCollision" % node_name
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		body.position = at
		parent.add_child(body)
	return mesh


func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	return material


func stats() -> Dictionary:
	return {
		"sign_count": get_node(^"InnSigns").get_child_count(),
		"lantern_count": get_node(^"HospitalityLanterns").get_child_count(),
		"guest_prop_count": get_node(^"GuestYard").get_child_count(),
		"porch_width_m": PORCH_WIDTH,
		"door_half_width_m": DOOR_HALF_WIDTH,
	}
