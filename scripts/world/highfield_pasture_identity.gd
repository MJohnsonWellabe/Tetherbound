extends Node3D

## A single old pasture tree closes The Highfield's missing vertical identity.
## The working gate, wagon, camp and ordinary Meadowhart encounters stay exactly
## where gameplay authored them; this tree stands behind their open lane so the
## whole stock story resolves against one natural silhouette from the south.

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const HERO_TREE := preload("res://assets/environment/stylized_nature/CommonTree_5.gltf")

const HERO_AT := Vector2(394.0, 5900.0)
const HERO_HEIGHT_M := 25.0
const HERO_WIDTH_M := 20.0
const HERO_DEPTH_M := 18.0
const TRUNK_RADIUS_M := 1.65
const TRUNK_COLLISION_HEIGHT_M := 8.5
const TIMBER := Color("#4b382a")
const IRON := Color("#2a2724")
const LANTERN_GLOW := Color("#ffc06a")

var _lantern_count := 0


func build(world: Node) -> bool:
	if world == null or not world.has_method("ground_height_at"):
		push_error("Highfield pasture identity needs production ground_height_at()")
		return false
	var ground := float(world.call("ground_height_at", HERO_AT.x, HERO_AT.y))
	if is_nan(ground) or is_inf(ground):
		push_error("Highfield pasture tree has no finite ground")
		return false
	var tree := HERO_TREE.instantiate() as Node3D
	if tree == null:
		push_error("Highfield pasture tree asset failed to instantiate")
		return false
	tree.name = "HighfieldShadeTree"
	IMPORTED_MATERIALS.make_dielectric(tree)
	var bounds := RENDER_BOUNDS.measure(tree)
	if bounds.size.x <= 0.01 or bounds.size.y <= 0.01 or bounds.size.z <= 0.01:
		push_error("Highfield pasture tree has invalid render bounds")
		return false
	tree.scale = Vector3(HERO_WIDTH_M / bounds.size.x, HERO_HEIGHT_M / bounds.size.y,
		HERO_DEPTH_M / bounds.size.z)
	tree.position = Vector3(HERO_AT.x, ground - bounds.position.y * tree.scale.y - 0.12, HERO_AT.y)
	add_child(tree)
	_build_trunk_collision(ground)
	_build_drover_lanterns(ground)
	return true


func stats() -> Dictionary:
	return {
		"hero_at": HERO_AT,
		"hero_height_m": HERO_HEIGHT_M,
		"hero_width_m": HERO_WIDTH_M,
		"hero_depth_m": HERO_DEPTH_M,
		"trunk_radius_m": TRUNK_RADIUS_M,
		"lantern_count": _lantern_count,
	}


func _build_trunk_collision(ground: float) -> void:
	var body := StaticBody3D.new()
	body.name = "HighfieldShadeTreeCollision"
	body.position = Vector3(HERO_AT.x, ground + TRUNK_COLLISION_HEIGHT_M * 0.5, HERO_AT.y)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var cylinder := CylinderShape3D.new()
	cylinder.radius = TRUNK_RADIUS_M
	cylinder.height = TRUNK_COLLISION_HEIGHT_M
	shape.shape = cylinder
	body.add_child(shape)
	add_child(body)


func _build_drover_lanterns(ground: float) -> void:
	var lanterns := Node3D.new()
	lanterns.name = "HighfieldDroverLanterns"
	add_child(lanterns)
	for side: float in [-1.0, 1.0]:
		var x := HERO_AT.x + side * 2.15
		var z := HERO_AT.y - 0.95
		_box(lanterns, "LanternArm%s" % ("West" if side < 0.0 else "East"),
			Vector3(2.4, 0.16, 0.16), Vector3(HERO_AT.x + side * 1.1, ground + 5.8, z), TIMBER)
		_box(lanterns, "LanternHook%s" % ("West" if side < 0.0 else "East"),
			Vector3(0.10, 0.72, 0.10), Vector3(x, ground + 5.48, z), IRON)
		var suffix := "West" if side < 0.0 else "East"
		var corners: Array[Vector2] = [Vector2(-0.16, -0.16), Vector2(-0.16, 0.16),
			Vector2(0.16, -0.16), Vector2(0.16, 0.16)]
		for corner_index in corners.size():
			var corner := corners[corner_index]
			_box(lanterns, "LanternRail%s_%d" % [suffix, corner_index],
				Vector3(0.045, 0.48, 0.045),
				Vector3(x + corner.x, ground + 5.0, z + corner.y), IRON)
		for cap_y: float in [4.75, 5.25]:
			_box(lanterns, "LanternCap%s_%s" % [suffix, str(cap_y)],
				Vector3(0.38, 0.05, 0.38), Vector3(x, ground + cap_y, z), IRON)
		_emissive_sphere(lanterns, "LanternGlass%s" % suffix,
			Vector3(x, ground + 5.0, z), LANTERN_GLOW)
		var glow := OmniLight3D.new()
		glow.name = "DroverLantern%s" % ("West" if side < 0.0 else "East")
		glow.position = Vector3(x, ground + 5.0, z - 0.05)
		glow.light_color = LANTERN_GLOW
		glow.light_energy = 2.15
		glow.omni_range = 18.0
		glow.shadow_enabled = false
		lanterns.add_child(glow)
		_lantern_count += 1


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		colour: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.88
	mesh.material = material
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)


func _emissive_sphere(parent: Node3D, node_name: String, at: Vector3,
		colour: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = 0.13
	mesh.height = 0.26
	mesh.radial_segments = 12
	mesh.rings = 6
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 1.8
	mesh.material = material
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)
