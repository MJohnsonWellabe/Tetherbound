extends Node3D

## Broad identity pass for The Stonewater Reach: the authored haulage wreck,
## Lockwater Overlook and Springhead remain the fine dressing, while this
## composer gives the 300m sequence a commercial-scale silhouette and actual
## visible water. Everything reuses installed models or small procedural
## surfaces; there is no generated asset and no new terrain carve.

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const IMPORTED_MATERIALS := preload("res://scripts/world/imported_materials.gd")
const WAGON := preload("res://assets/buildings/quaternius_medieval/Prop_Wagon.gltf")
const STONE_ARCH := preload("res://assets/buildings/quaternius_castle/WallEntranceBricks.obj")
const BANNER_STANDARD := preload("res://assets/props/quaternius_fantasy/Banner_1.gltf")
const ROCK_1 := preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf")
const ROCK_2 := preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf")
const ROCK_3 := preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf")
const REED := preload("res://assets/environment/stylized_nature/Grass_Wispy_Tall.gltf")
const BRICK_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
const BRICK_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
const BRICK_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")

const WRECK := Vector2(-74.0, 3251.5)
const OVERLOOK := Vector2(-128.0, 3451.0)
const LOCKWATER := Vector2(-119.0, 3457.0)
const SPRING := Vector2(8.0, 3560.0)
const LOCKWATER_RADII := Vector2(15.5, 10.0)
const SPRING_RADII := Vector2(10.0, 8.0)
const CAUSEWAY := Vector2(-84.0, 3482.0)
const SPRING_INTAKE := Vector2(14.8, 3566.8)
const REGION_CENTRE := Vector2(-120.0, 3420.0)
const APPROACH := Vector2(-155.0, 3415.0)
const RUN_CENTRES: Array[Vector2] = [
	# The first/last points meet the broad pools at their banks instead of lying
	# under them. The former deep overlaps composited twice and produced the
	# white night sheet seen across Springhead.
	Vector2(-103.0, 3467.0),
	Vector2(-91.0, 3477.0),
	Vector2(-70.0, 3485.0),
	Vector2(-52.0, 3509.0),
	Vector2(-23.0, 3519.0),
	Vector2(-13.0, 3541.0),
	Vector2(-2.0, 3551.0),
]
const RUN_WIDTHS := [5.4, 6.4, 5.2, 6.8, 5.4, 6.1, 7.2]

const WATER_TEAL := Color(0.08, 0.30, 0.34, 0.82)
const WATER_LIGHT := Color(0.30, 0.68, 0.62, 1.0)
const TIMBER := Color("#4b382a")
const OXBLOOD_CLOTH := Color("#a63c46")
const STONE := Color("#96968a")
const STONE_LIGHT := Color("#817e70")
const STONE_DARK := Color("#555b55")
const LANTERN := Color("#ffc06a")
const GRASS_CLEAR_GROUP := "grass_clear"
const GRASS_CLEAR_RADIUS_META := "grass_clear_radius"
const WATER_RADIAL_RINGS := 6
const WATER_SURFACE_LIFT_M := 0.20

var _water_area_m2 := 0.0
var _hero_stones := 0
var _reeds := 0
var _collision_shapes := 0
var _run_sections := 0
var _riffle_clusters := 0
var _riffle_stones := 0
var _stone_arches := 0
var _banner_standards := 0
var _water_clear_markers := 0
var _scatter_removed_from_water := 0
var _masonry_modules := 0
var _crested_standards := 0
var _cascade_sheets := 0


func build(world: Node) -> bool:
	if world == null or not world.has_method("ground_height_at"):
		push_error("Stonewater Reach needs a world with ground_height_at()")
		return false
	_clear_water_footprint(world)
	_build_wreck(world)
	_build_overlook(world)
	_build_reach_run(world)
	_build_springhead(world)
	return true


func stats() -> Dictionary:
	return {
		"water_area_m2": _water_area_m2,
		"hero_stones": _hero_stones,
		"reeds": _reeds,
		"collision_shapes": _collision_shapes,
		"run_sections": _run_sections,
		"riffle_clusters": _riffle_clusters,
		"riffle_stones": _riffle_stones,
		"stone_arches": _stone_arches,
		"banner_standards": _banner_standards,
		"water_clear_markers": _water_clear_markers,
		"scatter_removed_from_water": _scatter_removed_from_water,
		"masonry_modules": _masonry_modules,
		"crested_standards": _crested_standards,
		"cascade_sheets": _cascade_sheets,
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
		_ground_model(world, wagon, WRECK, 1.65, 28.0, 0.12)
		wagon.rotation.z = deg_to_rad(7.0)
		site.add_child(wagon)
	# A snapped tongue and a complete installed banner standard make the wreck
	# legible from the road before its existing crate-scale debris resolves.
	var ground := _ground(world, WRECK)
	_box(site, "BrokenTongue", Vector3(0.38, 0.34, 6.2),
		Vector3(WRECK.x + 2.2, ground + 0.34, WRECK.y + 2.0), TIMBER,
		Vector3(0.0, deg_to_rad(-34.0), deg_to_rad(5.0)))
	_build_broken_wheel(site, Vector3(WRECK.x - 1.75, ground + 1.28, WRECK.y - 0.55), 28.0)
	# The wagon sat below the road crest in final-stonewater-02. A tipped load
	# rising behind the wheel makes the damage read at the real 20-30m arrival
	# distance without relocating the authored spill or adding a new system.
	_box(site, "TippedLoadBed", Vector3(3.6, 0.36, 2.3),
		Vector3(WRECK.x + 0.15, ground + 1.42, WRECK.y + 0.15), TIMBER,
		Vector3(deg_to_rad(-13.0), deg_to_rad(28.0), deg_to_rad(9.0)))
	var spill_models: Array[PackedScene] = [ROCK_1, ROCK_2, ROCK_3]
	for i in 3:
		_add_hero_rock(world, site, "SpilledRootstone_%02d" % i,
			spill_models[i],
			WRECK + Vector2(3.2 + float(i) * 1.35, -1.5 + float(i % 2) * 1.4),
			0.42 + float(i) * 0.07, 41.0 + float(i) * 67.0)
	_add_box_collision(site, "WagonCollision", WRECK, ground, Vector3(5.0, 2.4, 3.0), 28.0)
	_dress_authored_wreck_standard(world)
	# A small warm pool beside, not inside, the wagon keeps its broken wheel and
	# load-bed silhouette from collapsing to black without making any prop emit.
	_add_lantern(site, "WreckLantern",
		Vector3(WRECK.x - 2.8, ground + 2.2, WRECK.y - 2.3), 11.0)


func _build_overlook(world: Node) -> void:
	var site := Node3D.new()
	site.name = "LockwaterOverlookLandmark"
	add_child(site)
	var water := _water_material(WATER_TEAL)
	_build_water_patch(world, site, "LockwaterLens", LOCKWATER, LOCKWATER_RADII, 48, water)

	# An asymmetric bank composition keeps the water open from the real south-west
	# arrival. The old three-stone row sat directly across that sightline and made
	# the broad reach read as three unrelated black boulders.
	_add_hero_rock(world, site, "WestGateStone", ROCK_1, Vector2(-132.0, 3465.0), 1.65, 12.0)
	_add_hero_rock(world, site, "EastGateStone", ROCK_3, Vector2(-101.5, 3471.5), 1.35, 205.0)
	_add_hero_rock(world, site, "CrownStone", ROCK_2, Vector2(-108.0, 3483.0), 1.85, 88.0)
	# The old causeway is the dominant middle-distance silhouette. Its open arch
	# sits across the wet axis, not the road, while paired jamb collisions keep
	# the aperture and both banks traversable. A smaller repeated arch at the
	# Springhead turns the whole run into one ruined civil-waterwork story.
	var causeway_at := CAUSEWAY
	_add_stone_arch(world, site, "OldReachCauseway", causeway_at, 4.6, -104.0)
	_build_overlook_deck(world, site)

	# The former standard sat exactly on the approach-to-water sightline. It now
	# marks the deck's outer shoulder and leaves the pool/causeway as the subject.
	var standard_at := Vector2(-142.5, 3454.5)
	var ground := _ground(world, standard_at)
	_add_banner_standard(world, site, "OverlookRouteStandard", standard_at, 1.55, 42.0)
	_add_lantern(site, "OverlookLantern", Vector3(standard_at.x, ground + 4.7, standard_at.y), 18.0)
	# The former lamp sat inside the masonry and left the approach face in its
	# own shadow. Put the same restrained light just forward of that face.
	var causeway_front := causeway_at + Vector2(sin(deg_to_rad(-104.0)),
		cos(deg_to_rad(-104.0))) * 3.8
	var causeway_ground := _ground(world, causeway_front)
	_add_lantern(site, "CausewayLantern",
		Vector3(causeway_front.x, causeway_ground + 3.8, causeway_front.y), 16.0)
	_add_reed_arc(world, site, LOCKWATER, Vector2(15.0, 9.7), 24, 205.0, 335.0)


func _build_springhead(world: Node) -> void:
	var site := Node3D.new()
	site.name = "SpringheadLandmark"
	add_child(site)
	_build_water_patch(world, site, "SpringPool", SPRING, SPRING_RADII, 44,
		_water_material(WATER_TEAL))
	# These are bank reeds, not plants rooted through the water sheet. A sparse
	# outer ellipse preserves the wetland frame while opening the basin itself.
	_add_reed_arc(world, site, SPRING, Vector2(11.5, 9.3), 18, 18.0, 318.0)
	_add_stone_arch(world, site, "SpringIntakeArch", SPRING_INTAKE, 4.2, -133.0)
	_build_intake_cascade(world, site, SPRING_INTAKE, -133.0)
	# Both hero stones now frame the outside bank; neither occupies the aperture
	# or sits as a dry island in the water sheet.
	_add_hero_rock(world, site, "SpringSourceStone", ROCK_3, Vector2(23.5, 3570.5), 1.75, 240.0)
	_add_hero_rock(world, site, "SpringMarkerStone", ROCK_1, Vector2(-5.5, 3575.0), 0.72, 25.0)
	var ground := _ground(world, SPRING)
	_add_lantern(site, "SpringGlow", Vector3(SPRING.x, ground + 1.1, SPRING.y), 9.0, WATER_LIGHT)
	var intake_front := SPRING_INTAKE + Vector2(sin(deg_to_rad(-133.0)),
		cos(deg_to_rad(-133.0))) * 3.0
	var intake_ground := _ground(world, intake_front)
	_add_lantern(site, "IntakeLantern",
		Vector3(intake_front.x, intake_ground + 3.2, intake_front.y), 12.0)


func _build_reach_run(world: Node) -> void:
	# Join the two authored pools into one visible reach. The earlier broad pass
	# left a teal pond at each end with ordinary grass between them; in an
	# establishing frame they read as unrelated prop-scale puddles. This shallow,
	# non-colliding ribbon follows the natural downhill line between them and
	# makes the player walk beside one continuous water story.
	var site := Node3D.new()
	site.name = "ReachRunLandmark"
	add_child(site)
	for i in RUN_CENTRES.size() - 1:
		var a := RUN_CENTRES[i]
		var b := RUN_CENTRES[i + 1]
		var midpoint := (a + b) * 0.5
		var yaw := rad_to_deg((b - a).angle())
		_build_water_patch(world, site, "RunLens_%02d" % i, midpoint,
			Vector2(a.distance_to(b) * 0.59, (RUN_WIDTHS[i] + RUN_WIDTHS[i + 1]) * 0.5),
			24, _water_material(WATER_TEAL), yaw)
		_water_area_m2 += a.distance_to(b) * (RUN_WIDTHS[i] + RUN_WIDTHS[i + 1])
		_run_sections += 1

	# Unequal bank stones carry the same silhouette language from Lockwater to
	# Springhead without forming a fence along the route.
	# Keep the former channel boulder as a bank marker, but not as a wall across
	# the causeway front. Its old 1.25x body hid half the arch in ordinary views.
	_add_hero_rock(world, site, "RunStoneWest", ROCK_2, Vector2(-94.0, 3488.0), 0.72, 42.0)
	_add_hero_rock(world, site, "RunStoneMid", ROCK_1, Vector2(-39.0, 3514.0), 1.05, 211.0)
	_add_hero_rock(world, site, "RunStoneEast", ROCK_3, Vector2(-14.0, 3537.0), 1.35, 118.0)

	# Low, irregular stone riffles interrupt the long exposed ribbon at its bends.
	# They make the water read as a shallow stony reach and conceal the worst
	# ground-cover contact lines without adding another flat bank surface. These
	# stones are deliberately non-colliding so the existing route stays unchanged.
	_add_riffle_cluster(world, site, "WestRiffle", Vector2(-96.0, 3474.0), 56.0, 0)
	_add_riffle_cluster(world, site, "MiddleRiffle", Vector2(-61.0, 3497.0), 49.0, 1)
	_add_riffle_cluster(world, site, "LowerRiffle", Vector2(-28.0, 3524.0), 43.0, 2)
	_add_riffle_cluster(world, site, "SpringRiffle", Vector2(-7.0, 3545.0), 36.0, 0)


func _add_riffle_cluster(world: Node, parent: Node3D, node_name: String,
		centre: Vector2, yaw_deg: float, variant_offset: int) -> void:
	var cluster := Node3D.new()
	cluster.name = node_name
	parent.add_child(cluster)
	var scenes: Array[PackedScene] = [ROCK_1, ROCK_2, ROCK_3]
	var local_offsets: Array[Vector2] = [
		Vector2(-1.05, -0.24), Vector2(-0.34, 0.18), Vector2(0.38, -0.12), Vector2(1.02, 0.26),
	]
	for i in local_offsets.size():
		var rock := scenes[(i + variant_offset) % scenes.size()].instantiate() as Node3D
		if rock == null:
			continue
		rock.name = "RiffleStone_%02d" % i
		_tint_model(rock, Color("#686c68"))
		var offset := local_offsets[i].rotated(deg_to_rad(yaw_deg))
		var scale_factor := 0.34 + 0.07 * float((i + variant_offset) % 3)
		_ground_model(world, rock, centre + offset, scale_factor,
			yaw_deg + float(i * 61 + variant_offset * 19), 0.32)
		cluster.add_child(rock)
		_riffle_stones += 1
	_riffle_clusters += 1


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


## The Reach is procedural water laid over the production ground, so the base
## terrain's scatter and camera-relative GrassField do not know it is wet. Use
## both existing local runtime contracts: Vegetation.clear_area() removes baked
## trees/rocks/ground cover immediately, while grass_clear markers keep the
## shader field out without a terrain or global-scatter change. One disc at
## every run centre plus one at every midpoint covers the whole retained ribbon
## with 13 markers instead of leaving gaps between quarter points. Three at
## each pool cover the broad ends without stripping their planted banks.
func _clear_water_footprint(world: Node) -> void:
	var vegetation := world.get_node_or_null(^"Vegetation")
	for raw_pool_spec: Variant in [
		{"centre": LOCKWATER + Vector2(-7.0, 0.0), "radius": 9.5},
		{"centre": LOCKWATER, "radius": 10.5},
		{"centre": LOCKWATER + Vector2(7.0, 0.0), "radius": 9.5},
		{"centre": SPRING + Vector2(-5.0, 0.0), "radius": 8.5},
		{"centre": SPRING, "radius": 9.0},
		{"centre": SPRING + Vector2(5.0, 0.0), "radius": 8.5},
	]:
		var pool_spec := raw_pool_spec as Dictionary
		_add_water_clear_disc(world, vegetation, pool_spec.centre, float(pool_spec.radius))
	for index in RUN_CENTRES.size():
		_add_water_clear_disc(world, vegetation, RUN_CENTRES[index],
			float(RUN_WIDTHS[index]) + 2.6)
	for index in RUN_CENTRES.size() - 1:
		var a := RUN_CENTRES[index]
		var b := RUN_CENTRES[index + 1]
		var radius := (float(RUN_WIDTHS[index]) + float(RUN_WIDTHS[index + 1])) * 0.5 + 2.6
		_add_water_clear_disc(world, vegetation, a.lerp(b, 0.5), radius)


func _add_water_clear_disc(world: Node, vegetation: Node, centre: Vector2, radius: float) -> void:
	if vegetation != null and vegetation.has_method("clear_area"):
		_scatter_removed_from_water += int(vegetation.call("clear_area",
			Vector3(centre.x, _ground(world, centre), centre.y), radius))
	var marker := Node3D.new()
	marker.name = "WaterGrassClear_%02d" % _water_clear_markers
	marker.position = Vector3(centre.x, 0.0, centre.y)
	marker.set_meta(GRASS_CLEAR_RADIUS_META, radius)
	marker.add_to_group(GRASS_CLEAR_GROUP)
	add_child(marker)
	_water_clear_markers += 1


func _add_stone_arch(world: Node, parent: Node3D, node_name: String,
		at: Vector2, scale_factor: float, yaw_deg: float) -> void:
	var arch := MeshInstance3D.new()
	arch.name = node_name
	arch.mesh = STONE_ARCH
	arch.scale = Vector3.ONE * scale_factor
	arch.rotation.y = deg_to_rad(yaw_deg)
	var bounds := STONE_ARCH.get_aabb()
	arch.position = Vector3(at.x,
		_ground(world, at) - bounds.position.y * scale_factor - 0.12, at.y)
	arch.set_surface_override_material(0, _masonry_material(STONE_DARK))
	if STONE_ARCH.get_surface_count() > 1:
		arch.set_surface_override_material(1, _masonry_material(STONE_LIGHT))
	parent.add_child(arch)
	_dress_waterwork_arch(world, parent, node_name, at, scale_factor, yaw_deg)

	# Two narrow jamb shapes express the real solid footprint without filling
	# the arch opening with a broad proxy box.
	var local_x := Vector2(cos(deg_to_rad(yaw_deg)), -sin(deg_to_rad(yaw_deg)))
	var jamb_offset := local_x * scale_factor * 0.61
	var jamb_radius := scale_factor * 0.24
	var jamb_height := scale_factor * 1.48
	_add_cylinder_collision(parent, "%sWestJambCollision" % node_name,
		at - jamb_offset, _ground(world, at - jamb_offset), jamb_radius, jamb_height)
	_add_cylinder_collision(parent, "%sEastJambCollision" % node_name,
		at + jamb_offset, _ground(world, at + jamb_offset), jamb_radius, jamb_height)
	_stone_arches += 1


func _dress_waterwork_arch(world: Node, parent: Node3D, node_name: String,
		at: Vector2, scale_factor: float, yaw_deg: float) -> void:
	# The installed arch supplies a true opening, but alone its flat grey face
	# read as a toy castle gate. Textured stepped buttresses, channel curbs and a
	# raised water crest turn it into a repeated civil-waterwork module while
	# leaving both the aperture and its collision contract untouched.
	var dress := Node3D.new()
	dress.name = "%sWaterworkDress" % node_name
	dress.position = Vector3(at.x, _ground(world, at), at.y)
	dress.rotation.y = deg_to_rad(yaw_deg)
	parent.add_child(dress)
	var width := scale_factor * 0.78
	var height := scale_factor * 1.38
	for side in [-1.0, 1.0]:
		var side_name := "West" if side < 0.0 else "East"
		_masonry_box(dress, "Buttress_%s" % side_name,
			Vector3(scale_factor * 0.28, height * 0.72, scale_factor * 0.48),
			Vector3(side * width, height * 0.36, 0.14), STONE_DARK)
		# A low forward foot gives the pier an unmistakable stepped side plane
		# from the actual approach instead of adding another tall box silhouette.
		_masonry_box(dress, "ButtressFoot_%s" % side_name,
			Vector3(scale_factor * 0.44, height * 0.27, scale_factor * 0.98),
			Vector3(side * width, height * 0.135, scale_factor * 0.44),
			STONE_LIGHT.darkened(0.12))
		_masonry_box(dress, "ChannelCurb_%s" % side_name,
			Vector3(scale_factor * 0.20, scale_factor * 0.24, scale_factor * 1.75),
			Vector3(side * scale_factor * 0.48, scale_factor * 0.05,
				scale_factor * 0.62), STONE_LIGHT)
	_masonry_box(dress, "WeatheredCap", Vector3(width * 2.2, scale_factor * 0.18,
		scale_factor * 0.52), Vector3(0.0, height + scale_factor * 0.07, 0.08), STONE_LIGHT)
	_add_water_crest(dress, Vector3(0.0, height * 0.79, -scale_factor * 0.23),
		scale_factor * 0.24)
	_masonry_modules += 7


func _add_water_crest(parent: Node3D, at: Vector3, radius: float) -> void:
	var crest := Node3D.new()
	crest.name = "StonewaterCrest"
	crest.position = at
	parent.add_child(crest)
	var ring := MeshInstance3D.new()
	ring.name = "RaisedRing"
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.62
	torus.outer_radius = radius
	torus.rings = 20
	torus.ring_segments = 10
	torus.material = _solid_material(WATER_LIGHT.darkened(0.28))
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	crest.add_child(ring)
	for i in 3:
		_box(crest, "FlowBar_%02d" % i,
			Vector3(radius * 1.25, radius * 0.13, radius * 0.14),
			Vector3(0.0, (float(i) - 1.0) * radius * 0.34, -radius * 0.08),
			WATER_LIGHT.darkened(0.28), Vector3(0.0, 0.0, deg_to_rad(-11.0)))


func _build_intake_cascade(world: Node, parent: Node3D, at: Vector2, yaw_deg: float) -> void:
	# The intake looks through to ordinary forest without a source surface. A
	# stepped, non-colliding cascade gives the Springhead a functional focal
	# plane; low specular response keeps it teal rather than white at night.
	var assembly := Node3D.new()
	assembly.name = "SpringIntakeCascade"
	assembly.position = Vector3(at.x, _ground(world, at), at.y)
	assembly.rotation.y = deg_to_rad(yaw_deg)
	parent.add_child(assembly)
	var cascade := MeshInstance3D.new()
	cascade.name = "IntakeWaterfall"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.25, 2.50, 0.14)
	mesh.material = _water_material(Color(0.18, 0.48, 0.48, 0.94))
	cascade.mesh = mesh
	cascade.position = Vector3(0.0, 1.55, 0.68)
	cascade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	assembly.add_child(cascade)
	_masonry_box(assembly, "SpillLintel", Vector3(4.4, 0.36, 1.0),
		Vector3(0.0, 2.86, 0.48), STONE_LIGHT)
	for i in 3:
		var step_width := 3.8 - float(i) * 0.35
		var step_y := 0.12 + float(i) * 0.18
		var step_z := 1.0 + float(i) * 0.58
		_masonry_box(assembly, "SpillStep_%02d" % i,
			Vector3(step_width, 0.24, 0.72),
			Vector3(0.0, step_y, step_z),
			STONE_LIGHT.darkened(float(i) * 0.06))
		_water_box(assembly, "CascadeSheet_%02d" % i,
			Vector3(step_width - 0.20, 0.08, 0.80),
			Vector3(0.0, step_y + 0.16, step_z + 0.04),
			Color(0.22, 0.56, 0.54, 0.92))
		_cascade_sheets += 1
	_water_box(assembly, "CascadeFoamLip", Vector3(2.95, 0.10, 0.10),
		Vector3(0.0, 2.75, 0.77), Color(0.48, 0.70, 0.65, 0.90))
	_cascade_sheets += 1
	_masonry_modules += 4


func _add_banner_standard(world: Node, parent: Node3D, node_name: String,
		at: Vector2, scale_factor: float, yaw_deg: float) -> void:
	var standard := BANNER_STANDARD.instantiate() as Node3D
	if standard == null:
		return
	standard.name = node_name
	IMPORTED_MATERIALS.make_dielectric(standard)
	_ground_model(world, standard, at, scale_factor, yaw_deg, 0.04)
	_make_banner_cloth_readable(standard)
	_decorate_standard(standard)
	parent.add_child(standard)
	_banner_standards += 1


func _dress_authored_wreck_standard(world: Node) -> void:
	# Props builds before this composer. Upgrade the one already-authored wreck
	# standard in place so the landmark keeps one pole while sharing the Reach's
	# dimensional water crest and readable non-emissive cloth treatment.
	var standard := world.get_node_or_null(^"Props/tether_haulage_wreck/Banner_1") as Node3D
	if standard == null:
		return
	_make_banner_cloth_readable(standard)
	_decorate_standard(standard)


func _decorate_standard(standard: Node3D) -> void:
	if standard.get_node_or_null(^"StonewaterStandardCrest") != null:
		return
	var crest := Node3D.new()
	crest.name = "StonewaterStandardCrest"
	# Banner_1's cloth spans local x=.62..1.43, y=-1.55...70 and faces Z.
	# A raised ring plus crossed flow bars supplies depth and an identifying mark
	# on both complete installed standards without replacing their real poles.
	crest.position = Vector3(1.02, -0.44, 0.10)
	standard.add_child(crest)
	var ring := MeshInstance3D.new()
	ring.name = "RaisedRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.18
	torus.outer_radius = 0.25
	torus.rings = 18
	torus.ring_segments = 9
	torus.material = _solid_material(WATER_LIGHT.darkened(0.22))
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	crest.add_child(ring)
	for i in 3:
		_box(crest, "FlowBar_%02d" % i, Vector3(0.43, 0.055, 0.06),
			Vector3(0.0, (float(i) - 1.0) * 0.12, -0.025),
			WATER_LIGHT.darkened(0.22), Vector3(0.0, 0.0, deg_to_rad(-12.0)))
	_crested_standards += 1


func _build_broken_wheel(parent: Node3D, at: Vector3, yaw_deg: float) -> void:
	var wheel := Node3D.new()
	wheel.name = "BrokenHaulerWheel"
	wheel.position = at
	wheel.rotation = Vector3(deg_to_rad(83.0), deg_to_rad(yaw_deg), deg_to_rad(9.0))
	parent.add_child(wheel)
	var rim := MeshInstance3D.new()
	rim.name = "Rim"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.82
	torus.outer_radius = 1.02
	torus.rings = 24
	torus.ring_segments = 10
	torus.material = _solid_material(TIMBER.lightened(0.08))
	rim.mesh = torus
	wheel.add_child(rim)
	for i in 6:
		_box(wheel, "Spoke_%02d" % i, Vector3(1.78, 0.11, 0.13), Vector3.ZERO,
			TIMBER.lightened(0.05), Vector3(0.0, deg_to_rad(float(i) * 30.0), 0.0))


func _build_water_patch(world: Node, parent: Node3D, node_name: String,
		centre: Vector2, radii: Vector2, segments: int, material: Material,
		yaw_deg: float = 0.0) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		for ring in WATER_RADIAL_RINGS:
			var r0 := float(ring) / float(WATER_RADIAL_RINGS)
			var r1 := float(ring + 1) / float(WATER_RADIAL_RINGS)
			if ring == 0:
				_add_water_vertex(surface, world, centre, radii, yaw_deg, 0.0, 0.0)
				_add_water_vertex(surface, world, centre, radii, yaw_deg, a0, r1)
				_add_water_vertex(surface, world, centre, radii, yaw_deg, a1, r1)
				continue
			_add_water_vertex(surface, world, centre, radii, yaw_deg, a0, r0)
			_add_water_vertex(surface, world, centre, radii, yaw_deg, a0, r1)
			_add_water_vertex(surface, world, centre, radii, yaw_deg, a1, r1)
			_add_water_vertex(surface, world, centre, radii, yaw_deg, a0, r0)
			_add_water_vertex(surface, world, centre, radii, yaw_deg, a1, r1)
			_add_water_vertex(surface, world, centre, radii, yaw_deg, a1, r0)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = surface.commit()
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	_water_area_m2 += PI * radii.x * radii.y


func _add_water_vertex(surface: SurfaceTool, world: Node, centre: Vector2,
		radii: Vector2, yaw_deg: float, angle: float, radial: float) -> void:
	var local := Vector2(cos(angle) * radii.x * radial, sin(angle) * radii.y * radial)
	var vertex := centre + local.rotated(deg_to_rad(yaw_deg))
	# Six radial rings sample the production terrain at a few metres rather than
	# spanning each pool with one giant triangle. This prevents unsampled hills
	# from punching turf islands through the water while preserving the authored
	# bank shape and the non-colliding traversal contract.
	var edge_alpha := clampf((1.0 - radial) / 0.16, 0.0, 1.0)
	surface.set_color(Color(1.0, 1.0, 1.0, edge_alpha))
	surface.set_uv(Vector2(0.5 + local.x / (radii.x * 2.0),
		0.5 + local.y / (radii.y * 2.0)))
	surface.add_vertex(Vector3(vertex.x, _ground(world, vertex) + WATER_SURFACE_LIFT_M, vertex.y))


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


func _masonry_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		colour: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _masonry_material(colour)
	instance.mesh = mesh
	instance.position = at
	parent.add_child(instance)


func _water_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		colour: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _water_material(colour)
	instance.mesh = mesh
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _solid_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.88
	return material


func _masonry_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = BRICK_ALBEDO
	material.albedo_color = colour
	material.normal_enabled = true
	material.normal_texture = BRICK_NORMAL
	material.normal_scale = 0.62
	material.roughness_texture = BRICK_ROUGHNESS
	material.roughness = 0.94
	# The castle OBJ has no UVs; world triplanar is the proven mapping used for
	# this same kit at the Stronghold. 0.28 repeats per metre keeps real masonry
	# scale and prevents the crenellated face from becoming texture noise.
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(0.28, 0.28, 0.28)
	return material


func _water_material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# This is a shallow ground-following reach, not polished glass. Metallic and
	# emissive response made the old ribbon hold a flat cyan value even in shade.
	material.roughness = 0.74
	material.metallic = 0.0
	material.metallic_specular = 0.12
	material.emission_enabled = false
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
	material.normal_scale = 0.30
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


func _make_banner_cloth_readable(model: Node) -> void:
	for found in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := found as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		for surface in mesh_instance.mesh.get_surface_count():
			var source := mesh_instance.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null or source.resource_name != "MI_Banner":
				continue
			var material := source.duplicate() as StandardMaterial3D
			# The installed cloth atlas is dark teal. Multiplying it by oxblood
			# removes nearly every colour channel and made the standard black even
			# in daylight. Retain its normal/ORM weave, but use a faction-colour
			# base and thin-cloth backlight. This remains non-emissive.
			material.albedo_texture = null
			material.albedo_color = OXBLOOD_CLOTH
			material.roughness = 0.88
			material.metallic = 0.0
			material.emission_enabled = false
			material.backlight_enabled = true
			material.backlight = Color(0.38, 0.26, 0.24, 1.0)
			mesh_instance.set_surface_override_material(surface, material)
