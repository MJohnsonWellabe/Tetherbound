extends Node3D

## The Broken Tower is the Upper Meadows' long-range skyline beat between
## Captain Vess and the Stronghold Approach. Its original implementation was
## deliberately disposable: four flat CylinderMesh drums that proved the
## location existed but rendered as a white debug obelisk in production.
##
## Build the ruin from the same installed brick family as Meadows Hall. Three
## independently placed wall leaves make an open, traversable shell: the rear
## and west leaves retain the old tower's height, while the shorter east leaf
## and its fallen continuation make the damage legible from the route. This is
## intentionally not an intact tower prefab with rubble sprinkled around it.

const WALL_BRICKS: Mesh = preload(
	"res://assets/buildings/quaternius_castle/TallWallBricks.obj")
const WALL_ENTRANCE_BRICKS: Mesh = preload(
	"res://assets/buildings/quaternius_castle/WallEntranceBricks.obj")
const STONE_ALBEDO := preload(
	"res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
const STONE_NORMAL := preload(
	"res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
const STONE_ROUGHNESS := preload(
	"res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")

const STONE_LIGHT := Color("#776c5f")
const STONE_DARK := Color("#4b443e")
const MORTAR := Color("#292725")
const WARD_TEAL := Color("#65cad3")
const OLD_TIMBER := Color("#3f3026")
const FULL_SCALE := 5.0
const LOW_SCALE := 3.05
const FULL_WALL_HEIGHT := 11.73
const LOW_WALL_HEIGHT := 7.16
const WALL_HALF_LENGTH := 3.8
const WALL_HALF_DEPTH := 1.05
# StandardMaterial3D triplanar coordinates are local to this imported OBJ.
# The wall module stands at 5x native scale, so compensate by the same factor
# to retain Meadows Hall's world-space 0.28 masonry frequency.
const STONE_TILE := 1.4


func build(world: Node, at: Vector2, facing_deg: float) -> void:
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the watchtower at %.0f, %.0f" % [at.x, at.y])
		return
	position = Vector3(at.x, ground, at.y)
	rotation.y = deg_to_rad(facing_deg)

	var shell := Node3D.new()
	shell.name = "InstalledBrickRuin"
	add_child(shell)

	var body := StaticBody3D.new()
	body.name = "TowerWallCollision"
	add_child(body)

	# Open front faces the authored route. The unequal side leaves are the
	# primary broken silhouette; players can walk into the shell between them.
	# playground_world's authored facing uses local +Z as "back down the road".
	# Keep that side open so arrivals see into the ruin instead of meeting a
	# rectangular rear facade.
	_add_wall(shell, body, "RearWall", Vector3(0.0, 0.0, -2.75), 0.0,
		FULL_SCALE, FULL_WALL_HEIGHT)
	_add_wall(shell, body, "WestWall", Vector3(-2.75, 0.0, 0.0), 90.0,
		FULL_SCALE, FULL_WALL_HEIGHT)
	_add_wall(shell, body, "BrokenEastWall", Vector3(2.75, 0.0, -0.7), 90.0,
		LOW_SCALE, LOW_WALL_HEIGHT)
	_build_route_arch(shell, body)
	_build_ruin_base(shell, body)
	_build_fractured_crown(shell)
	_build_watch_remnants(shell)
	_build_route_apron(world, shell)

	# The missing upper east leaf lies outside the walkable mouth. It uses the
	# real brick mesh too, so the collapse reads as authored damage rather than
	# another primitive placeholder.
	var fallen := _brick_instance("FallenWallSection", LOW_SCALE)
	fallen.position = Vector3(4.6, 0.55, 1.8)
	fallen.rotation = Vector3(deg_to_rad(76.0), deg_to_rad(28.0), deg_to_rad(-8.0))
	shell.add_child(fallen)
	_add_box_collision(body, "FallenWallCollision", Vector3(4.6, 0.55, 1.8),
		Vector3(4.65, 1.1, 2.2), 28.0)

	_build_rubble(shell, body)
	_build_faded_tether_ward(shell)
	_build_outer_ward_remnant(shell)


func _add_wall(shell: Node3D, body: StaticBody3D, label: String,
		at: Vector3, yaw_deg: float, scale_factor: float, height: float) -> void:
	var wall := _brick_instance(label, scale_factor)
	wall.position = at
	wall.rotation.y = deg_to_rad(yaw_deg)
	shell.add_child(wall)
	var size := Vector3(WALL_HALF_LENGTH * 2.0, height, WALL_HALF_DEPTH * 2.0)
	if scale_factor != FULL_SCALE:
		size *= scale_factor / FULL_SCALE
	_add_box_collision(body, "%sCollision" % label,
		at + Vector3.UP * height * 0.5, size, yaw_deg)


func _brick_instance(label: String, scale_factor: float,
		source_mesh: Mesh = WALL_BRICKS) -> MeshInstance3D:
	var wall := MeshInstance3D.new()
	wall.name = label
	wall.mesh = source_mesh
	wall.scale = Vector3.ONE * scale_factor
	_weather_bricks(wall)
	return wall


func _weather_bricks(instance: MeshInstance3D) -> void:
	for surface in instance.mesh.get_surface_count():
		var source := instance.get_active_material(surface)
		var material := StandardMaterial3D.new()
		if source is StandardMaterial3D:
			material = (source as StandardMaterial3D).duplicate() as StandardMaterial3D
		var key := material.resource_name.to_lower()
		if "darkrock" in key:
			material.albedo_color = STONE_DARK
		elif "black" in key:
			material.albedo_color = MORTAR
		else:
			material.albedo_color = STONE_LIGHT
		material.metallic = 0.0
		material.roughness = 0.92
		# This castle kit has no UVs. The same world-triplanar masonry used by
		# Meadows Hall is therefore the only mapping that can show real stone
		# coursing instead of a flat grey surface. Keep the black aperture slot
		# untextured so windows remain voids rather than painted bricks.
		if not "black" in key:
			material.albedo_texture = STONE_ALBEDO
			material.normal_enabled = true
			material.normal_texture = STONE_NORMAL
			material.roughness_texture = STONE_ROUGHNESS
			material.uv1_triplanar = true
			material.uv1_scale = Vector3.ONE * STONE_TILE
		instance.set_surface_override_material(surface, material)


func _ruin_stone_material(tint: Color = STONE_DARK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = STONE_ALBEDO
	material.normal_enabled = true
	material.normal_texture = STONE_NORMAL
	material.roughness_texture = STONE_ROUGHNESS
	material.roughness = 0.95
	material.uv1_triplanar = true
	material.uv1_scale = Vector3.ONE * STONE_TILE
	return material


## A real arched lower wall makes this read as a former watch building from the
## road, not three unrelated vertical slabs. The installed module is shorter
## than the surviving leaves and sits slightly off their axis, preserving the
## broken silhouette. Collision belongs only to the two piers: the measured
## 3.7 m arch and the original route-facing mouth remain open.
func _build_route_arch(shell: Node3D, body: StaticBody3D) -> void:
	var arch := _brick_instance("RouteArch", 4.2, WALL_ENTRANCE_BRICKS)
	arch.position = Vector3(-0.12, 0.02, 2.15)
	arch.rotation.y = deg_to_rad(-3.0)
	shell.add_child(arch)
	_add_box_collision(body, "RouteArchWestPierCollision",
		Vector3(-2.62, 2.35, 2.15), Vector3(1.25, 4.7, 1.55), -3.0)
	_add_box_collision(body, "RouteArchEastPierCollision",
		Vector3(2.38, 2.35, 2.15), Vector3(1.25, 4.7, 1.55), -3.0)


## The tower was built to watch this road. A partial upper deck and its broken
## ladder put that purpose inside the open shell without adding a new gameplay
## promise: both are high, visual-only remnants and the floor route stays clear.
func _build_watch_remnants(shell: Node3D) -> void:
	var remnants := Node3D.new()
	remnants.name = "WatchDeckRemnants"
	shell.add_child(remnants)
	var timber := _flat_material(OLD_TIMBER, 0.94)
	for index in 4:
		_visual_box(remnants, "DeckPlank%02d" % index,
			Vector3(1.05, 0.16, 2.7), Vector3(-1.65 + index * 1.05, 6.05,
			-1.25 + (0.10 if index % 2 == 0 else -0.06)), timber,
			-2.0 + index * 1.5)
	_visual_box(remnants, "DeckLedgerWest", Vector3(0.18, 0.28, 3.1),
		Vector3(-2.15, 5.82, -1.2), timber)
	_visual_box(remnants, "DeckLedgerRear", Vector3(4.6, 0.24, 0.18),
		Vector3(-0.1, 5.82, -2.35), timber)

	var ladder := Node3D.new()
	ladder.name = "BrokenWatchLadder"
	ladder.position = Vector3(-1.25, 0.0, 0.10)
	ladder.rotation.x = deg_to_rad(-7.0)
	remnants.add_child(ladder)
	_visual_box(ladder, "RailWest", Vector3(0.12, 5.45, 0.12),
		Vector3(-0.43, 2.82, 0.0), timber)
	_visual_box(ladder, "RailEast", Vector3(0.12, 5.05, 0.12),
		Vector3(0.43, 2.62, 0.0), timber)
	for index in 7:
		_visual_box(ladder, "Rung%02d" % index, Vector3(0.98, 0.10, 0.12),
			Vector3(0.0, 0.68 + index * 0.68, 0.0), timber,
			-2.0 if index == 5 else 0.0)


## Four terrain-sampled flagstones carry the road through the arch and keep
## grass from visually swallowing the threshold. They are deliberately uneven,
## visual-only fragments; wall/rubble collision remains authoritative.
func _build_route_apron(world: Node, shell: Node3D) -> void:
	var apron := Node3D.new()
	apron.name = "RouteFlagstones"
	shell.add_child(apron)
	var stone := _ruin_stone_material(STONE_DARK.lightened(0.12))
	var stones := [
		{"at": Vector3(-0.25, 0.0, 2.75), "size": Vector3(2.35, 0.10, 1.05), "yaw": -4.0},
		{"at": Vector3(0.32, 0.0, 3.85), "size": Vector3(2.65, 0.09, 1.00), "yaw": 5.0},
		{"at": Vector3(-0.18, 0.0, 4.95), "size": Vector3(2.15, 0.08, 0.95), "yaw": -7.0},
		{"at": Vector3(0.28, 0.0, 5.98), "size": Vector3(1.75, 0.07, 0.84), "yaw": 8.0},
	]
	for index in stones.size():
		var spec: Dictionary = stones[index]
		var local_at: Vector3 = spec.at
		# `build()` is also exercised off-tree by the focused unit fixture. This
		# landmark is an identity-transform child in production, so applying its
		# authored yaw and position directly is exact and avoids get_global_transform
		# errors outside a SceneTree.
		var horizontal := Vector3(local_at.x, 0.0, local_at.z).rotated(Vector3.UP, rotation.y)
		var world_xz := Vector2(position.x + horizontal.x, position.z + horizontal.z)
		var ground := float(world.call("ground_height_at", world_xz.x, world_xz.y))
		if is_nan(ground):
			continue
		local_at.y = ground - position.y + float(spec.size.y) * 0.5 + 0.025
		_visual_box(apron, "Flagstone%02d" % index, spec.size, local_at, stone,
			float(spec.yaw))


func _visual_box(parent: Node3D, node_name: String, size: Vector3, at: Vector3,
		material: Material, yaw_deg := 0.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	instance.mesh = mesh
	instance.position = at
	instance.rotation.y = deg_to_rad(yaw_deg)
	parent.add_child(instance)
	return instance


func _flat_material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	return material


func _add_box_collision(body: StaticBody3D, label: String, at: Vector3,
		size: Vector3, yaw_deg: float) -> void:
	var shape := CollisionShape3D.new()
	shape.name = label
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	shape.rotation.y = deg_to_rad(yaw_deg)
	body.add_child(shape)


func _build_rubble(shell: Node3D, body: StaticBody3D) -> void:
	var rubble_mat := _ruin_stone_material(STONE_DARK)
	var blocks := [
		{"at": Vector3(3.4, 0.0, 1.8), "size": Vector3(1.2, 0.8, 1.0), "yaw": 18.0},
		{"at": Vector3(-3.8, 0.0, -2.1), "size": Vector3(1.5, 0.7, 1.2), "yaw": -32.0},
		{"at": Vector3(1.8, 0.0, -3.3), "size": Vector3(0.9, 0.6, 1.0), "yaw": 55.0},
		{"at": Vector3(-4.8, 0.0, 1.1), "size": Vector3(1.8, 0.55, 1.15), "yaw": 12.0},
		{"at": Vector3(4.8, 0.0, -1.9), "size": Vector3(1.1, 0.9, 1.45), "yaw": -21.0},
		{"at": Vector3(-1.9, 0.0, -4.2), "size": Vector3(1.35, 0.45, 0.95), "yaw": 43.0},
	]
	for index in blocks.size():
		var entry: Dictionary = blocks[index]
		var at: Vector3 = entry.at
		var size: Vector3 = entry.size
		var block := MeshInstance3D.new()
		block.name = "Rubble%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = rubble_mat
		block.mesh = mesh
		block.position = at + Vector3.UP * size.y * 0.5
		block.rotation.y = deg_to_rad(float(entry.yaw))
		shell.add_child(block)
		_add_box_collision(body, "RubbleCollision%02d" % index,
			block.position, size, float(entry.yaw))


## The first production pass left the three upright leaves sitting directly on
## grass, so the distant read was still one thin slab. Offset foundation rafts
## and short masonry returns spread the ruin's weight without closing the open
## +Z route into its centre.
func _build_ruin_base(shell: Node3D, body: StaticBody3D) -> void:
	var base := Node3D.new()
	base.name = "BrokenFoundation"
	shell.add_child(base)
	var slabs := [
		{"at": Vector3(-2.6, 0.0, -2.8), "size": Vector3(5.6, 0.34, 2.4), "yaw": -3.0},
		{"at": Vector3(2.35, 0.0, -2.65), "size": Vector3(4.2, 0.28, 2.15), "yaw": 4.0},
		{"at": Vector3(-3.05, 0.0, 0.05), "size": Vector3(2.2, 0.30, 4.6), "yaw": 2.0},
		{"at": Vector3(3.0, 0.0, -0.7), "size": Vector3(1.9, 0.24, 3.2), "yaw": -5.0},
	]
	var stone := _ruin_stone_material(STONE_DARK.lightened(0.08))
	for index in slabs.size():
		var spec: Dictionary = slabs[index]
		var mesh := BoxMesh.new()
		mesh.size = spec.size
		mesh.material = stone
		var slab := MeshInstance3D.new()
		slab.name = "FoundationSlab%02d" % index
		slab.mesh = mesh
		slab.position = spec.at + Vector3.UP * float(spec.size.y) * 0.5
		slab.rotation.y = deg_to_rad(float(spec.yaw))
		base.add_child(slab)

	# Unequal stubs are surviving wall returns, not a symmetrical plinth. They
	# sit outside the two-metre entrance corridor and deepen the silhouette.
	var returns := [
		{"name": "WestFooting", "at": Vector3(-4.55, 0.18, -1.15), "yaw": 58.0,
			"scale": 1.85, "collision": Vector3(2.81, 4.34, 0.78)},
		{"name": "RearButtress", "at": Vector3(-4.05, 0.12, -3.55), "yaw": 5.0,
			"scale": 1.42, "collision": Vector3(2.16, 3.33, 0.60)},
		{"name": "EastFooting", "at": Vector3(3.55, 0.10, -2.65), "yaw": 103.0,
			"scale": 0.82, "collision": Vector3(1.25, 1.92, 0.35)},
	]
	for raw: Variant in returns:
		var spec := raw as Dictionary
		var piece := _brick_instance(str(spec.name), float(spec.scale))
		piece.position = spec.at
		piece.rotation.y = deg_to_rad(float(spec.yaw))
		base.add_child(piece)
		var collision_size: Vector3 = spec.collision
		_add_box_collision(body, "%sCollision" % str(spec.name),
			spec.at + Vector3.UP * collision_size.y * 0.5,
			collision_size, float(spec.yaw))


## A displaced high remnant breaks the kit's otherwise level crenellation and
## makes the missing east corner legible against the sky. It is presentation
## above traversal headroom and therefore intentionally owns no collider.
func _build_fractured_crown(shell: Node3D) -> void:
	var crown := _brick_instance("FracturedCrownSpur", 1.32)
	crown.position = Vector3(2.95, 6.8, -2.35)
	crown.rotation = Vector3(deg_to_rad(-5.0), deg_to_rad(-12.0), deg_to_rad(8.0))
	shell.add_child(crown)


func _build_faded_tether_ward(shell: Node3D) -> void:
	# A visible practical source keeps the route-facing interior readable after
	# dark without turning this abandoned ruin into an occupied camp. The
	# restrained teal identifies an old Team Tether ward and connects it to the
	# revive cache staged beside the tower.
	var ward := Node3D.new()
	ward.name = "FadedTetherWard"
	# The route approaches the open local +Z mouth. Mount the fixture on the
	# inside face of the rear leaf, proud toward the arriving player.
	ward.position = Vector3(0.0, 3.1, -1.55)
	shell.add_child(ward)

	var frame := MeshInstance3D.new()
	frame.name = "IronFrame"
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(0.85, 1.05, 0.18)
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color("#252a2b")
	frame_mat.metallic = 0.72
	frame_mat.roughness = 0.48
	frame_mesh.material = frame_mat
	frame.mesh = frame_mesh
	ward.add_child(frame)

	var lens := MeshInstance3D.new()
	lens.name = "WardLens"
	var lens_mesh := SphereMesh.new()
	lens_mesh.radius = 0.17
	lens_mesh.height = 0.34
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = WARD_TEAL.darkened(0.25)
	lens_mat.emission_enabled = true
	lens_mat.emission = WARD_TEAL
	lens_mat.emission_energy_multiplier = 1.35
	lens_mesh.material = lens_mat
	lens.mesh = lens_mesh
	lens.position = Vector3(0.0, 0.0, 0.16)
	ward.add_child(lens)

	var fill := OmniLight3D.new()
	fill.name = "WardFill"
	fill.light_color = WARD_TEAL
	fill.light_energy = 2.8
	fill.omni_range = 11.5
	fill.omni_attenuation = 1.35
	fill.shadow_enabled = false
	fill.position = Vector3(0.0, 0.0, 0.65)
	ward.add_child(fill)

	# The bounded omni exposes the chamber, while this route-facing cone catches
	# the broken inner edges and the first few metres of approach. Both emanate
	# from the modeled lens; there is no ambient/global exposure cheat.
	var route_fill := SpotLight3D.new()
	route_fill.name = "RouteFacingFill"
	route_fill.light_color = WARD_TEAL
	route_fill.light_energy = 4.6
	route_fill.spot_range = 22.0
	route_fill.spot_angle = 54.0
	route_fill.spot_attenuation = 1.15
	route_fill.shadow_enabled = false
	route_fill.position = Vector3(0.0, 0.0, 0.42)
	route_fill.rotation.y = PI
	ward.add_child(route_fill)


## A broken outer ward marker makes the practical readable from the long route,
## rather than asking one lens deep inside the shell to light both chamber and
## exterior. It is still a small, bounded source attached to ruin masonry.
func _build_outer_ward_remnant(shell: Node3D) -> void:
	var marker := Node3D.new()
	marker.name = "OuterWardRemnant"
	marker.position = Vector3(-2.62, 0.0, 2.62)
	shell.add_child(marker)

	var post := MeshInstance3D.new()
	post.name = "BrokenIronPost"
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.22, 2.35, 0.22)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color("#20282a")
	iron.metallic = 0.68
	iron.roughness = 0.55
	post_mesh.material = iron
	post.mesh = post_mesh
	post.position.y = 1.15
	post.rotation.z = deg_to_rad(-7.0)
	marker.add_child(post)

	var lens := MeshInstance3D.new()
	lens.name = "OuterWardLens"
	var lens_mesh := SphereMesh.new()
	lens_mesh.radius = 0.14
	lens_mesh.height = 0.28
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = WARD_TEAL.darkened(0.18)
	lens_mat.emission_enabled = true
	lens_mat.emission = WARD_TEAL
	lens_mat.emission_energy_multiplier = 1.45
	lens_mesh.material = lens_mat
	lens.mesh = lens_mesh
	lens.position = Vector3(-0.14, 2.26, 0.05)
	marker.add_child(lens)

	var fill := OmniLight3D.new()
	fill.name = "OuterWardFill"
	fill.light_color = WARD_TEAL
	fill.light_energy = 5.0
	fill.omni_range = 16.5
	fill.omni_attenuation = 1.25
	fill.shadow_enabled = false
	fill.position = lens.position + Vector3(0.0, 0.1, 0.15)
	marker.add_child(fill)

	# The modeled route-side lens now catches the arch and inner wall instead of
	# leaving the masonry a black silhouette around two white orbs. Its range is
	# confined to the ruin footprint and first threshold stones.
	var facade_fill := SpotLight3D.new()
	facade_fill.name = "FacadeFill"
	facade_fill.light_color = WARD_TEAL
	# Production R1 proved that 5.8 still left the dark stone effectively black
	# at the ordinary 21 m threshold view. This remains a narrow, source-backed
	# cone, but carries enough energy to separate the arch from its interior.
	facade_fill.light_energy = 10.5
	facade_fill.spot_range = 19.0
	facade_fill.spot_angle = 62.0
	facade_fill.spot_attenuation = 1.2
	facade_fill.shadow_enabled = false
	facade_fill.position = lens.position + Vector3(0.0, 0.08, 0.18)
	marker.add_child(facade_fill)
