extends SceneTree

## NEAR6-MS scratch probe (F38#29): renders grunt_a playing idle with the
## post_stance rows named on the command line (npc_post_stances.json stances),
## front three-quarter and side, so a stance's axes are checked by render.
##   godot --path . --rendering-driver opengl3 --resolution 960x540 \
##     --script tools/_probe_beaten_kneel.gd -- --stance=beaten_kneel --out=/abs/dir

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const POST_STANCE := preload("res://scripts/characters/post_stance.gd")


func _init() -> void:
	_run()


func _run() -> void:
	var stance := "beaten_kneel"
	var out := "/tmp/claude-0/kneel"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--stance="):
			stance = arg.trim_prefix("--stance=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	await process_frame
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.68)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.8)
	e.ambient_light_energy = 1.5
	env.environment = e
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(deg_to_rad(-45), deg_to_rad(-30), 0)
	world.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6, 6)
	floor_mesh.mesh = plane
	world.add_child(floor_mesh)
	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	world.add_child(model)
	if not bool(model.call("build", "grunt_a")):
		printerr("grunt_a failed to build")
		quit(1)
		return
	if model.has_method("play"):
		model.call("play", "idle")
	var rows: Array = (POST_STANCE.config().get("stances", {}) as Dictionary).get(stance, [])
	if stance != "none":
		print("rows ", rows, " -> ", POST_STANCE.attach_rows(model, rows))
	var camera := Camera3D.new()
	camera.fov = 40.0
	world.add_child(camera)
	camera.make_current()
	for view: Array in [["front34", Vector3(2.2, 1.5, 3.2)], ["side", Vector3(3.6, 1.1, 0.0)]]:
		camera.position = view[1]
		camera.look_at(Vector3(0, 0.7, 0), Vector3.UP)
		for i in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png("%s/%s-%s.png" % [out, stance, str(view[0])])
	print("done ", out)
	quit(0)
