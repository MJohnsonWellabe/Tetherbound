extends Node3D

## A restrained night focal point for Grandpa's Village square.
##
## The well sits inside the authored street bend without occupying either road.
## Its timber posts and tiled canopy remain untouched; this child hangs two real
## kit lanterns from those posts and gives the two street legs bounded warm
## pools. The presentation creates no body, area, prompt, or collision.

const WALL_LANTERN := preload("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf")
const TORCH := preload("res://assets/props/quaternius_fantasy/Torch_Metal.gltf")
const PRESENTATION_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const LIGHT_COLOUR := Color("#ffc778")

const KIT_STONE := preload("res://assets/buildings/quaternius_medieval/T_RockTrim_BaseColor.png")
const CURB_RADIUS := 0.62
const SHAFT_RADIUS := 0.44
const CURB_HEIGHT := 0.72

var _curb_stone := _kit_stone(Color("#9a8e7f"), 1.6)
var _curb_cap := _kit_stone(Color("#6f675d"), 2.4)
var _water := _material(Color("#0f2a31"), 0.34)


func build() -> void:
	name = "VillageWellPresentation"
	_build_stone_curb()
	_build_canopy_lanterns()
	_build_path_lights()


func _build_stone_curb() -> void:
	# The old recipe crossed four complete stair-platform models at the same
	# origin. From the north those read as three shrine-sized duplicate wells.
	# Its replacement, a ring of twelve untextured pale boxes, was then read by
	# a blind visual pass as "placeholder cubes on a slab" (Meadows visual pass,
	# ralph/reports/MEADOWS-VISUAL-PASS). A round curb in the village kit's own
	# RockTrim stone, with a darker cap and a dark shaft, reads as one well.
	var curb := Node3D.new()
	curb.name = "SingleStoneCurb"
	add_child(curb)
	var wall := MeshInstance3D.new()
	wall.name = "CurbWall"
	var drum := CylinderMesh.new()
	drum.top_radius = CURB_RADIUS
	drum.bottom_radius = CURB_RADIUS + 0.05
	drum.height = CURB_HEIGHT
	drum.radial_segments = 28
	drum.material = _curb_stone
	wall.mesh = drum
	wall.position.y = CURB_HEIGHT * 0.5
	curb.add_child(wall)
	var cap := MeshInstance3D.new()
	cap.name = "CurbCap"
	var ring := TorusMesh.new()
	ring.inner_radius = SHAFT_RADIUS
	ring.outer_radius = CURB_RADIUS + 0.07
	ring.rings = 28
	ring.material = _curb_cap
	cap.mesh = ring
	cap.scale = Vector3(1.0, 0.55, 1.0)
	cap.position.y = CURB_HEIGHT
	curb.add_child(cap)
	var mouth := MeshInstance3D.new()
	mouth.name = "WellWater"
	var water_disc := CylinderMesh.new()
	water_disc.top_radius = SHAFT_RADIUS
	water_disc.bottom_radius = SHAFT_RADIUS
	water_disc.height = 0.02
	water_disc.radial_segments = 28
	water_disc.material = _water
	mouth.mesh = water_disc
	mouth.position.y = CURB_HEIGHT + 0.012
	curb.add_child(mouth)


static func _kit_stone(tint: Color, uv_scale: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.albedo_texture = KIT_STONE
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * uv_scale
	mat.roughness = 0.95
	mat.metallic = 0.0
	return mat


func _build_canopy_lanterns() -> void:
	var fixtures := Node3D.new()
	fixtures.name = "WellLanternFixtures"
	add_child(fixtures)
	for side: float in [-1.0, 1.0]:
		var holder := Node3D.new()
		holder.name = "WestLantern" if side < 0.0 else "EastLantern"
		# The well recipe's timber posts stand at local x +/-0.85 from the ground.
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


func _build_path_lights() -> void:
	var lights := Node3D.new()
	lights.name = "SquarePathLights"
	add_child(lights)
	# These are street lamps, not decoration on the well apron. The first sits
	# beside the west leg between Grandpa's door and the inn; the second sits on
	# the workshop side of the south leg. Both are outside the 3.6m painted road
	# band and on the settlement's explicit 0.9m flats. The former symmetric pair
	# at local (+/-3.35, -3.15) lit the back of the well while both actual streets
	# fell into the night tonemap's toe.
	for spec: Dictionary in [
		{"name": "WestStreetLight", "at": Vector3(-16.0, 0.0, -7.0)},
		{"name": "SouthStreetLight", "at": Vector3(-2.0, 0.0, 15.0)},
	]:
		var fixture := Node3D.new()
		fixture.name = str(spec.name)
		fixture.position = spec.at as Vector3
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
		pool.light_energy = 1.45
		pool.omni_range = 6.2
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


func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	return material


func stats() -> Dictionary:
	return {
		"curb_count": get_children().filter(func(c: Node) -> bool: return c.name == "SingleStoneCurb").size(),
		"curb_height_m": CURB_HEIGHT,
		"curb_radius_m": CURB_RADIUS,
		"lantern_count": get_node(^"WellLanternFixtures").get_child_count(),
		"light_count": 3,
		"light_range_m": (get_node(^"VillageSquareWarmPool") as OmniLight3D).omni_range,
		"path_light_count": get_node(^"SquarePathLights").get_child_count(),
		"west_light_local": (get_node(^"SquarePathLights/WestStreetLight") as Node3D).position,
		"south_light_local": (get_node(^"SquarePathLights/SouthStreetLight") as Node3D).position,
	}
