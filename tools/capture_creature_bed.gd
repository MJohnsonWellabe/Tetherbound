extends SceneTree

## Capture R2.8's creature bed for the required blind-judge visual pass.
## Same standalone-stage pattern as `capture_build_pieces.gd` -- no
## `meadows_playground.tscn` dependency.
##
## Two shots: the bed alone (close 3/4, so its own materials read), and the
## bed next to the workbench (R2.7, already shipped) for a size sanity
## check -- a "creature bed" that reads as human-furniture-sized would be a real
## defect, not just a taste question.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_creature_bed.gd

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 20

const BED := "res://assets/props/quaternius_fantasy/Bed_Twin1.gltf"
const WORKBENCH := "res://assets/props/quaternius_fantasy/Workbench.gltf"


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


func _piece(mesh_path: String, at: Vector3, yaw_deg: float, parent: Node3D) -> void:
	var p := BUILD_PIECE.new()
	parent.add_child(p)
	p.call("build_real", mesh_path)
	p.position = at
	p.rotation.y = deg_to_rad(yaw_deg)


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await _alone()
	await _with_workbench()
	await _occupied()
	quit(0)


func _alone() -> void:
	var world := _stage()
	_piece(BED, Vector3.ZERO, 20.0, world)

	var camera := Camera3D.new()
	camera.fov = 42.0
	world.add_child(camera)
	camera.look_at_from_position(Vector3(2.4, 1.6, 2.6), Vector3(0.0, 0.4, 0.0), Vector3.UP)
	await _shoot("%s/creature_bed_alone.png" % OUT_DIR, camera)
	world.queue_free()


func _with_workbench() -> void:
	var world := _stage()
	_piece(BED, Vector3(-1.3, 0.0, 0.0), 20.0, world)
	_piece(WORKBENCH, Vector3(1.3, 0.0, 0.0), -25.0, world)

	var camera := Camera3D.new()
	camera.fov = 45.0
	world.add_child(camera)
	camera.look_at_from_position(Vector3(0.5, 2.2, 4.6), Vector3(0.0, 0.6, 0.0), Vector3.UP)
	await _shoot("%s/creature_bed_scale_check.png" % OUT_DIR, camera)
	world.queue_free()


func _occupied() -> void:
	var world := _stage()
	var bed := CREATURE_BED.new()
	world.add_child(bed)
	bed.build_real()
	var creature: RefCounted = SPECIES.spawn("terrapup")
	if creature == null or not bed.assign(creature):
		push_error("could not assign the visual-judge creature to its bed")
		world.queue_free()
		return
	var camera := Camera3D.new()
	camera.fov = 42.0
	world.add_child(camera)
	camera.look_at_from_position(Vector3(2.8, 1.8, 2.8), Vector3(0.0, 0.55, 0.0), Vector3.UP)
	await _shoot("%s/creature_bed_occupied.png" % OUT_DIR, camera)
	world.queue_free()
