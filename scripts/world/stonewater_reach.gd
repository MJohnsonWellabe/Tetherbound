extends Node3D

## Broad identity pass for The Stonewater Reach: the authored haulage wreck,
## Lockwater Overlook and Springhead remain the fine dressing, while this
## composer gives the 300m sequence a commercial-scale silhouette and actual
## visible water. Everything reuses installed models or small procedural
## surfaces; there is no generated asset and no new terrain carve.

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const WAGON := preload("res://assets/buildings/quaternius_medieval/Prop_Wagon.gltf")
const ROCK_1 := preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf")
const ROCK_2 := preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf")
const ROCK_3 := preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf")
const REED := preload("res://assets/environment/stylized_nature/Grass_Wispy_Tall.gltf")

const WRECK := Vector2(-76.0, 3253.0)
const OVERLOOK := Vector2(-128.0, 3451.0)
const LOCKWATER := Vector2(-119.0, 3457.0)
const SPRING := Vector2(8.0, 3560.0)
const REGION_CENTRE := Vector2(-120.0, 3420.0)
const APPROACH := Vector2(-155.0, 3415.0)

const WATER_TEAL := Color(0.17, 0.55, 0.58, 0.90)
const WATER_EDGE := Color(0.48, 0.86, 0.78, 0.72)
const TIMBER := Color("#4b382a")
const OXBLOOD := Color("#7a2430")
const STONE := Color("#76766e")
const LANTERN := Color("#ffc06a")

var _water_area_m2 := 0.0
var _hero_stones := 0
var _reeds := 0
var _collision_shapes := 0


func build(world: Node) -> bool:
	if world == null or not world.has_method("ground_height_at"):
		push_error("Stonewater Reach needs a world with ground_height_at()")
		return false
	_build_wreck(world)
	_build_overlook(world)
	_build_springhead(world)
	return true


func stats() -> Dictionary:
	return {
		"water_area_m2": _water_area_m2,
		"hero_stones": _hero_stones,
		"reeds": _reeds,
		"collision_shapes": _collision_shapes,
		"region_to_overlook_m": REGION_CENTRE.distance_to(OVERLOOK),
		"approach_to_overlook_m": APPROACH.distance_to(OVERLOOK),
		"sequence_span_m": WRECK.distance_to(SPRING),
	}


func _build_wreck(world: Node) -> void:
	var site := Node3D.new()
	site.name = "HaulageWreckLandmark"
	add_child(site)
	var wagon := WAGON.instantiate() as Node3D
	if wagon != null:
		wagon.name = "WreckedHauler"
		IMPORTED_MATERIALS.make_dielectric(wagon)
		_ground_model(world, wagon, WRECK, 1.45, 28.0, 0.12)
		wagon.rotation.z = deg_to_rad(7.0)
		site.add_child(wagon)
	# A snapped tongue and high faction pennant make the wreck legible from the
	# road before its existing crate-scale debris resolves.
	var ground := _ground(world, WRECK)
	_box(site, "BrokenTongue", Vector3(0.38, 0.34, 6.2),
		Vector3(WRECK.x + 2.2, ground + 0.34, WRECK.y + 2.0), TIMBER,
		Vector3(0.0, deg_to_rad(-34.0), deg_to_rad(5.0)))
	_box(site, "WreckSignalPole", Vector3(0.24, 7.2, 0.24),
		Vector3(WRECK.x - 4.2, ground + 3.6, WRECK.y - 1.8), TIMBER)
	_box(site, "WreckPennant", Vector3(1.5, 2.6, 0.10),
		Vector3(WRECK.x - 3.35, ground + 5.55, WRECK.y - 1.8), OXBLOOD)
	_add_box_collision(site, "WagonCollision", WRECK, ground, Vector3(5.0, 2.4, 3.0), 28.0)


func _build_overlook(world: Node) -> void:
	var site := Node3D.new()
	site.name = "LockwaterOverlookLandmark"
	add_child(site)
	var water := _water_material(WATER_TEAL)
	_build_water_patch(world, site, "LockwaterLens", LOCKWATER, Vector2(8.5, 5.2), 36, water)
	_build_water_patch(world, site, "LockwaterGlint", LOCKWATER + Vector2(0.4, -0.2),
		Vector2(7.3, 4.25), 32, _water_material(WATER_EDGE))

	# Three oversized, irregular stones frame the low water lens. Their open
	# south-west side preserves the real approach and turns the tiny prop shelf
	# into a place with a thumbnail silhouette.
	_add_hero_rock(world, site, "WestGateStone", ROCK_1, Vector2(-126.5, 3458.8), 2.2, 12.0)
	_add_hero_rock(world, site, "EastGateStone", ROCK_3, Vector2(-112.0, 3457.2), 1.9, 205.0)
	_add_hero_rock(world, site, "CrownStone", ROCK_2, Vector2(-119.0, 3464.0), 2.45, 88.0)
	_build_overlook_deck(world, site)

	var ground := _ground(world, Vector2(-128.5, 3451.0))
	_box(site, "OverlookBeaconPost", Vector3(0.28, 5.8, 0.28),
		Vector3(-128.5, ground + 2.9, 3451.0), TIMBER)
	_box(site, "OverlookBeaconArm", Vector3(2.2, 0.20, 0.20),
		Vector3(-127.55, ground + 5.1, 3451.0), TIMBER)
	_box(site, "OverlookPennant", Vector3(0.95, 1.7, 0.08),
		Vector3(-127.1, ground + 4.05, 3451.0), OXBLOOD)
	_add_lantern(site, "OverlookLantern", Vector3(-128.5, ground + 4.7, 3450.6), 18.0)
	_add_reed_arc(world, site, LOCKWATER, Vector2(8.2, 4.8), 18, 212.0, 328.0)


func _build_springhead(world: Node) -> void:
	var site := Node3D.new()
	site.name = "SpringheadLandmark"
	add_child(site)
	_build_water_patch(world, site, "SpringPool", SPRING, Vector2(7.2, 6.0), 40,
		_water_material(WATER_TEAL))
	_build_water_patch(world, site, "SpringInnerGlint", SPRING + Vector2(-0.5, 0.4),
		Vector2(5.3, 4.35), 36, _water_material(WATER_EDGE))
	_add_reed_arc(world, site, SPRING, Vector2(7.0, 5.8), 24, 20.0, 318.0)
	_add_hero_rock(world, site, "SpringSourceStone", ROCK_3, Vector2(12.2, 3562.6), 1.65, 240.0)
	_add_hero_rock(world, site, "SpringMarkerStone", ROCK_1, Vector2(3.0, 3564.2), 1.25, 25.0)
	var ground := _ground(world, SPRING)
	_add_lantern(site, "SpringGlow", Vector3(SPRING.x, ground + 1.1, SPRING.y), 13.0, WATER_EDGE)


func _build_overlook_deck(world: Node, parent: Node3D) -> void:
	# A human-scale timber perch turns the boulder-and-water composition into
	# somewhere people deliberately stop. It sits beside the road rather than
	# replacing it and is a shallow walkable step, not a traversal wall.
	var deck := Node3D.new()
	deck.name = "OverlookDeck"
	parent.add_child(deck)
	var centre := Vector2(-133.2, 3452.8)
	var ground := _ground(world, centre)
	for i in 7:
		_box(deck, "DeckPlank_%02d" % i, Vector3(0.76, 0.22, 4.8),
			Vector3(centre.x - 2.28 + float(i) * 0.76, ground + 0.30, centre.y), TIMBER)
	# Low far rail: enough to frame the water but below the player's sightline.
	for x in [-2.45, 0.0, 2.45]:
		_box(deck, "RailPost_%s" % str(x), Vector3(0.20, 1.15, 0.20),
			Vector3(centre.x + x, ground + 0.86, centre.y + 2.25), TIMBER)
	_box(deck, "WaterRail", Vector3(5.2, 0.18, 0.18),
		Vector3(centre.x, ground + 1.22, centre.y + 2.25), TIMBER)
	_add_box_collision(deck, "DeckCollision", centre, ground + 0.19,
		Vector3(5.4, 0.30, 4.8), 0.0)


func _build_water_patch(world: Node, parent: Node3D, node_name: String,
		centre: Vector2, radii: Vector2, segments: int, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center_y := _ground(world, centre) + 0.13
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var p0 := centre + Vector2(cos(a0) * radii.x, sin(a0) * radii.y)
		var p1 := centre + Vector2(cos(a1) * radii.x, sin(a1) * radii.y)
		surface.set_uv(Vector2(0.5, 0.5))
		surface.add_vertex(Vector3(centre.x, center_y, centre.y))
		surface.set_uv(Vector2(0.5 + cos(a0) * 0.5, 0.5 + sin(a0) * 0.5))
		surface.add_vertex(Vector3(p0.x, _ground(world, p0) + 0.13, p0.y))
		surface.set_uv(Vector2(0.5 + cos(a1) * 0.5, 0.5 + sin(a1) * 0.5))
		surface.add_vertex(Vector3(p1.x, _ground(world, p1) + 0.13, p1.y))
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = surface.commit()
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	_water_area_m2 += PI * radii.x * radii.y


func _add_hero_rock(world: Node, parent: Node3D, node_name: String,
		scene: PackedScene, at: Vector2, scale_factor: float, yaw: float) -> void:
	var rock := scene.instantiate() as Node3D
	if rock == null:
		return
	rock.name = node_name
	_tint_model(rock, STONE)
	_ground_model(world, rock, at, scale_factor, yaw, 0.28)
	parent.add_child(rock)
	var ground := _ground(world, at)
	_add_cylinder_collision(parent, "%sCollision" % node_name, at, ground, 1.15 * scale_factor, 2.4 * scale_factor)
	_hero_stones += 1


func _add_reed_arc(world: Node, parent: Node3D, centre: Vector2, radii: Vector2,
		count: int, start_deg: float, end_deg: float) -> void:
	for i in count:
		var t := (float(i) + 0.35) / float(count)
		var angle := deg_to_rad(lerpf(start_deg, end_deg, t))
		var wobble := sin(float(i) * 2.37) * 0.55
		var at := centre + Vector2(cos(angle) * (radii.x + wobble), sin(angle) * (radii.y + wobble))
		var reed := REED.instantiate() as Node3D
		if reed == null:
			continue
		reed.name = "Reed_%02d" % i
		_ground_model(world, reed, at, 0.58 + 0.12 * float(i % 4), float((i * 47) % 360), 0.12)
		parent.add_child(reed)
		_reeds += 1


func _ground_model(world: Node, model: Node3D, at: Vector2, scale_factor: float,
		yaw_deg: float, sink: float) -> void:
	var bounds := RENDER_BOUNDS.measure(model)
	model.scale = Vector3.ONE * scale_factor
	model.rotation.y = deg_to_rad(yaw_deg)
	model.position = Vector3(at.x, _ground(world, at) - bounds.position.y * scale_factor - sink, at.y)


func _ground(world: Node, at: Vector2) -> float:
	var height := float(world.call("ground_height_at", at.x, at.y))
	return 0.0 if is_nan(height) else height


func _add_box_collision(parent: Node3D, node_name: String, at: Vector2, ground: float,
		size: Vector3, yaw_deg: float) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = Vector3(at.x, ground + size.y * 0.5, at.y)
	body.rotation.y = deg_to_rad(yaw_deg)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	_collision_shapes += 1


func _add_cylinder_collision(parent: Node3D, node_name: String, at: Vector2,
		ground: float, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = Vector3(at.x, ground + height * 0.5, at.y)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = height
	shape.shape = cylinder
	body.add_child(shape)
	parent.add_child(body)
	_collision_shapes += 1


func _add_lantern(parent: Node3D, node_name: String, at: Vector3,
		radius: float, colour: Color = LANTERN) -> void:
	var lamp := OmniLight3D.new()
	lamp.name = node_name
	lamp.position = at
	lamp.light_color = colour
	lamp.light_energy = 2.2
	lamp.omni_range = radius
	lamp.shadow_enabled = false
	parent.add_child(lamp)


func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		colour: Color, rotation: Vector3 = Vector3.ZERO) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _solid_material(colour)
	instance.mesh = mesh
	instance.position = at
	instance.rotation = rotation
	parent.add_child(instance)


func _solid_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.88
	return material


func _water_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.16
	material.metallic = 0.08
	material.emission_enabled = true
	material.emission = Color(colour.r, colour.g, colour.b) * 0.18
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.065
	var ripples := NoiseTexture2D.new()
	ripples.width = 128
	ripples.height = 128
	ripples.seamless = true
	ripples.as_normal_map = true
	ripples.bump_strength = 2.2
	ripples.noise = noise
	material.normal_enabled = true
	material.normal_texture = ripples
	material.normal_scale = 0.42
	return material


func _tint_model(model: Node, tint: Color) -> void:
	for found in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := found as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as StandardMaterial3D
			material.albedo_color *= tint
			material.roughness = 0.92
			mesh_instance.set_surface_override_material(surface, material)
