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
	_build_ruin_base(shell, body)
	_build_fractured_crown(shell)

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


func _brick_instance(label: String, scale_factor: float) -> MeshInstance3D:
	var wall := MeshInstance3D.new()
	wall.name = label
	wall.mesh = WALL_BRICKS
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
	lens_mesh.radius = 0.27
	lens_mesh.height = 0.54
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = WARD_TEAL.darkened(0.25)
	lens_mat.emission_enabled = true
	lens_mat.emission = WARD_TEAL
	lens_mat.emission_energy_multiplier = 2.1
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
	marker.position = Vector3(-4.45, 0.0, 0.15)
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
	lens_mesh.radius = 0.21
	lens_mesh.height = 0.42
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = WARD_TEAL.darkened(0.18)
	lens_mat.emission_enabled = true
	lens_mat.emission = WARD_TEAL
	lens_mat.emission_energy_multiplier = 2.6
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
