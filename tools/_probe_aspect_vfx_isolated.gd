extends SceneTree

## Debug-only: does aspect_vfx.gd's billboard technique draw anything at all
## when nothing else is in the scene to occlude it? Isolates the VFX from the
## creature body entirely.

const ASPECT_VFX := preload("res://scripts/creatures/vfx/aspect_vfx.gd")
const OUT := "res://ralph/reports/T1-CREATURE-ART/shots/_debug_vfx_isolated.png"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	await process_frame

	var world := Node3D.new()
	root.add_child(world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.08)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.6
	env_node.environment = env
	world.add_child(env_node)

	var anchor := Node3D.new()
	world.add_child(anchor)
	var vfx: Node3D = ASPECT_VFX.attach(anchor, "nightburrow", 0.74, 2.04)
	print("vfx attach result: ", vfx)

	var camera := Camera3D.new()
	camera.fov = 50.0
	world.add_child(camera)
	camera.global_position = Vector3(0.0, 1.2, 4.0)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	camera.make_current()

	for i in 30:
		await physics_frame
	for i in 2:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	image.save_png(OUT)
	print("wrote ", OUT)
	quit(0)
