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
	var rubble_mat := StandardMaterial3D.new()
	rubble_mat.albedo_color = STONE_DARK
	rubble_mat.roughness = 0.95
	var blocks := [
		{"at": Vector3(3.4, 0.0, 1.8), "size": Vector3(1.2, 0.8, 1.0), "yaw": 18.0},
		{"at": Vector3(-3.8, 0.0, -2.1), "size": Vector3(1.5, 0.7, 1.2), "yaw": -32.0},
		{"at": Vector3(1.8, 0.0, -3.3), "size": Vector3(0.9, 0.6, 1.0), "yaw": 55.0},
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
