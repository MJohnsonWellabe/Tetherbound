extends SceneTree

## BUILD-KIT (OP21-07/08/09) visual evidence: a real 2x2 house built from the
## same production pieces `build_placer.gd` places, at the same transforms
## `build_snap_contract.gd::resolve()` would compute for a full perimeter
## around a 2x2 floor grid -- not the R2.6 flat lineup this file's sibling
## (`capture_build_pieces.gd`) shot, and not `smoke_gate_a_build_house.gd`'s
## partial 3-wall regression footprint. Two shots: an exterior showing the
## closed door and the roof's corrected proportions, and the same house with
## the door swung open so the doorway itself is legible.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_build_kit_house.gd

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const BUILD_DOOR := preload("res://scripts/build/build_door.gd")

const DIR := "res://assets/buildings/quaternius_medieval"
const FLOOR_MESH := DIR + "/Floor_UnevenBrick.gltf"
const WALL_MESH := DIR + "/Wall_Plaster_Straight.gltf"
const ROOF_MESH := DIR + "/Roof_RoundTile_2x1.gltf"
## data/items/buildables.json's own roof `scale` field (OP21-09) -- read as a
## literal here rather than parsing the catalogue, since this capture only
## needs the one value and a parse dependency would be one more way this
## script could silently drift from what a real placement actually uses.
const ROOF_SCALE := Vector3(0.6066, 0.6066, 1.0)
const ROOF_Y := 3.05

const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 24


func _stage() -> Node3D:
	var world := Node3D.new()
	root.add_child(world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.58, 0.65)
	env.ambient_light_energy = 0.9
	env_node.environment = env
	world.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(-35.0), 0.0)
	sun.light_energy = 2.4
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	world.add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-15.0), deg_to_rad(150.0), 0.0)
	fill.light_energy = 0.5
	fill.light_color = Color(0.75, 0.82, 0.95)
	world.add_child(fill)
	return world


func _shoot(path: String, camera: Camera3D) -> void:
	camera.make_current()
	for i in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image")
		return
	var error := image.save_png(path)
	if error != OK:
		push_error("save_png failed (%d)" % error)
		return
	print("  %s -> %s" % [path.get_file(), path])


func _floor(at: Vector3, parent: Node3D) -> void:
	var p := BUILD_PIECE.new()
	parent.add_child(p)
	p.call("build_real", FLOOR_MESH)
	p.position = at


func _wall(at: Vector3, yaw_deg: float, parent: Node3D) -> void:
	var p := BUILD_PIECE.new()
	parent.add_child(p)
	p.call("build_real", WALL_MESH)
	p.position = at
	p.rotation.y = deg_to_rad(yaw_deg)


func _door(at: Vector3, yaw_deg: float, parent: Node3D) -> Node3D:
	var p := BUILD_DOOR.new()
	parent.add_child(p)
	p.call("build_real")
	p.position = at
	p.rotation.y = deg_to_rad(yaw_deg)
	return p


func _roof(at: Vector3, yaw_deg: float, parent: Node3D) -> void:
	var p := BUILD_PIECE.new()
	parent.add_child(p)
	p.call("build_real", ROOF_MESH, {}, ROOF_SCALE)
	p.position = at
	p.rotation.y = deg_to_rad(yaw_deg)


## The same 2x2 floor grid `smoke_gate_a_build_house.gd` uses, with a FULL
## perimeter this time (that regression only builds 3 walls + a door on one
## side; this shows all four sides so the house reads as enclosed) -- the
## exact positions/yaws `build_snap_contract.gd::_add_floor_edges` resolves
## for a wall/door snapped to each floor tile's own edge.
func _build_house(parent: Node3D) -> Node3D:
	for at in [Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(0, 0, 2), Vector3(2, 0, 2)]:
		_floor(at, parent)

	var door := _door(Vector3(0, 0, -1), 0.0, parent)
	_wall(Vector3(2, 0, -1), 0.0, parent)   # front, right of the door
	_wall(Vector3(0, 0, 3), 0.0, parent)    # back, left
	_wall(Vector3(2, 0, 3), 0.0, parent)    # back, right
	_wall(Vector3(-1, 0, 0), 90.0, parent)  # left side, front
	_wall(Vector3(-1, 0, 2), 90.0, parent)  # left side, back
	_wall(Vector3(3, 0, 0), 90.0, parent)   # right side, front
	_wall(Vector3(3, 0, 2), 90.0, parent)   # right side, back

	for at in [Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(0, 0, 2), Vector3(2, 0, 2)]:
		_roof(Vector3(at.x, ROOF_Y, at.z), 0.0, parent)

	return door


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _exterior_closed()
	await _exterior_open_door()
	await _interior()
	quit(0)


func _exterior_closed() -> void:
	var world := _stage()
	_build_house(world)

	var camera := Camera3D.new()
	camera.fov = 50.0
	world.add_child(camera)
	camera.look_at_from_position(Vector3(6.5, 4.4, -6.0), Vector3(1.0, 1.6, 1.0), Vector3.UP)
	await _shoot("%s/build_kit_house_exterior.png" % OUT_DIR, camera)
	world.queue_free()


func _exterior_open_door() -> void:
	var world := _stage()
	var door := _build_house(world)
	door.call("force_open", true)

	var camera := Camera3D.new()
	camera.fov = 45.0
	world.add_child(camera)
	camera.look_at_from_position(Vector3(0.5, 1.8, -4.2), Vector3(0.0, 1.2, -0.5), Vector3.UP)
	await _shoot("%s/build_kit_house_door_open.png" % OUT_DIR, camera)
	world.queue_free()


func _interior() -> void:
	var world := _stage()
	var door := _build_house(world)
	door.call("force_open", true)

	var camera := Camera3D.new()
	camera.fov = 60.0
	world.add_child(camera)
	# Inside the footprint, looking back out through the open doorway.
	camera.look_at_from_position(Vector3(1.0, 1.5, 1.6), Vector3(0.0, 1.2, -1.0), Vector3.UP)
	await _shoot("%s/build_kit_house_interior.png" % OUT_DIR, camera)
	world.queue_free()
