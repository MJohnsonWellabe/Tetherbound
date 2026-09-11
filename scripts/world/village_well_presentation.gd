extends Node3D

## A restrained night focal point for Grandpa's Village square.
##
## The well is already the authored meeting point of the village roads. Its
## timber posts and tiled canopy remain untouched; this child hangs two real
## kit lanterns from those posts and gives them one bounded warm pool. The
## presentation creates no body, area, prompt, or collision and therefore does
## not alter the well approach, NPC circulation, or opening route.

const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const TORCH := preload("res://assets/props/quaternius_fantasy/Torch_Metal.gltf")
const PRESENTATION_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const LIGHT_COLOUR := Color("#ffc778")

var _timber := _material(Color("#3a281d"), 0.9)
var _gold := _material(Color("#d6aa56"), 0.7)
var _green := _material(Color("#315447"), 0.84)
var _stone_light := _material(Color("#81786d"), 0.94)
var _stone_dark := _material(Color("#514b45"), 0.97)
var _water := _material(Color("#183f4a"), 0.34)


func build() -> void:
	name = "VillageWellPresentation"
	_build_stone_curb()
	_build_civic_sign()
	_build_canopy_lanterns()
	_build_path_lights()


func _build_stone_curb() -> void:
	# The old recipe crossed four complete stair-platform models at the same
	# origin. From the north those read as three shrine-sized duplicate wells.
	# A low twelve-block ring has one clear civic scale and leaves the authored
	# timber posts, canopy, bucket, apron, and collider doing their original jobs.
	var curb := Node3D.new()
	curb.name = "SingleStoneCurb"
	add_child(curb)
	for index in 12:
		var angle := TAU * float(index) / 12.0
		var block := MeshInstance3D.new()
		block.name = "CurbStone%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.48 if index % 3 else 0.54,
			0.50 + float(index % 2) * 0.08, 0.34)
		mesh.material = _stone_light if index % 4 else _stone_dark
		block.mesh = mesh
		block.position = Vector3(cos(angle) * 0.84,
			0.31 + float(index % 2) * 0.025, sin(angle) * 0.84)
		block.rotation.y = -angle
		curb.add_child(block)
	var mouth := MeshInstance3D.new()
	mouth.name = "WellWater"
	var water_disc := CylinderMesh.new()
	water_disc.top_radius = 0.66
	water_disc.bottom_radius = 0.66
	water_disc.height = 0.035
	water_disc.radial_segments = 32
	water_disc.material = _water
	mouth.mesh = water_disc
	mouth.position.y = 0.43
	curb.add_child(mouth)


func _build_canopy_lanterns() -> void:
	var fixtures := Node3D.new()
	fixtures.name = "WellLanternFixtures"
	add_child(fixtures)
	for side: float in [-1.0, 1.0]:
		var holder := Node3D.new()
		holder.name = "WestLantern" if side < 0.0 else "EastLantern"
		# The well recipe's timber posts stand at local x +/-0.85 from y=1.0.
		# Keep the lanterns tucked under its y=2.9 roof rather than floating
		# beyond the silhouette.
		holder.position = Vector3(side * 0.73, 2.12, -0.08)
		holder.rotation.y = deg_to_rad(90.0 if side < 0.0 else -90.0)
		holder.scale = Vector3.ONE * 0.72
		fixtures.add_child(holder)
		var lantern := WALL_LANTERN.instantiate() as Node3D
		lantern.name = "InstalledWallLantern"
		holder.add_child(lantern)
		_visible_flame(holder, Vector3(0.0, 0.08, 0.18), "CanopyLanternGlow")

	var light := OmniLight3D.new()
	light.name = "VillageSquareWarmPool"
	light.light_color = LIGHT_COLOUR
	light.light_energy = 1.8
	light.omni_range = 8.5
	light.shadow_enabled = false
	light.position = Vector3(0.0, 2.18, 0.0)
	add_child(light)


func _build_civic_sign() -> void:
	var sign := Node3D.new()
	sign.name = "VillageCivicSign"
	sign.position = Vector3(0.0, 2.42, -1.18)
	add_child(sign)
	_box("SignBoard", Vector3(2.7, 0.56, 0.10), Vector3.ZERO, _green, sign)
	_box("SignTopRail", Vector3(2.86, 0.08, 0.14), Vector3(0.0, 0.28, 0.0), _gold, sign)
	_box("SignBottomRail", Vector3(2.86, 0.08, 0.14), Vector3(0.0, -0.28, 0.0), _gold, sign)
	for side: float in [-1.0, 1.0]:
		_box("SignBracket", Vector3(0.09, 0.72, 0.09),
			Vector3(side * 1.17, 0.37, 0.0), _timber, sign)
	var label := Label3D.new()
	label.name = "VillageName"
	label.text = "GRANDPA'S VILLAGE"
	label.font_size = 64
	label.pixel_size = 0.00225
	label.modulate = Color("#f4dfad")
	label.outline_size = 4
	label.outline_modulate = Color("#1d1712")
	label.double_sided = true
	label.position = Vector3(0.0, 0.0, -0.06)
	label.rotation.y = PI
	sign.add_child(label)


func _build_path_lights() -> void:
	var lights := Node3D.new()
	lights.name = "SquarePathLights"
	add_child(lights)
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		var fixture := Node3D.new()
		fixture.name = "WestPathLight" if side < 0.0 else "EastPathLight"
		fixture.position = Vector3(side * 3.35, 0.0, -3.15)
		lights.add_child(fixture)
		var torch := TORCH.instantiate() as Node3D
		torch.name = "InstalledMetalTorch"
		var bounds: AABB = PRESENTATION_BOUNDS.measure(torch)
		var fit_height := 1.62
		var factor := fit_height / maxf(bounds.size.y, 0.001)
		torch.scale = Vector3.ONE * factor
		torch.position = Vector3(-bounds.get_center().x * factor,
			-bounds.position.y * factor, -bounds.get_center().z * factor)
		fixture.add_child(torch)
		_visible_flame(fixture, Vector3(0.0, 1.68, 0.0), "PathFlame")
		var pool := OmniLight3D.new()
		pool.name = "PathWarmPool"
		pool.light_color = LIGHT_COLOUR
		pool.light_energy = 1.15
		pool.omni_range = 5.4
		pool.shadow_enabled = false
		pool.position = Vector3(0.0, 1.64, 0.0)
		fixture.add_child(pool)


func _visible_flame(parent: Node3D, at: Vector3, node_name: String) -> void:
	var glow := MeshInstance3D.new()
	glow.name = node_name
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.20
	var material := _material(LIGHT_COLOUR, 0.35)
	material.emission_enabled = true
	material.emission = LIGHT_COLOUR
	material.emission_energy_multiplier = 2.2
	sphere.material = material
	glow.mesh = sphere
	glow.position = at
	parent.add_child(glow)


func _box(node_name: String, size: Vector3, at: Vector3, material: Material,
		parent: Node3D) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	box.material = material
	instance.mesh = box
	instance.position = at
	parent.add_child(instance)


func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	return material


func stats() -> Dictionary:
	return {
		"curb_stone_count": get_node(^"SingleStoneCurb").get_child_count() - 1,
		"lantern_count": get_node(^"WellLanternFixtures").get_child_count(),
		"light_count": 3,
		"light_range_m": (get_node(^"VillageSquareWarmPool") as OmniLight3D).omni_range,
		"path_light_count": get_node(^"SquarePathLights").get_child_count(),
		"sign_text": (get_node(^"VillageCivicSign/VillageName") as Label3D).text,
	}
