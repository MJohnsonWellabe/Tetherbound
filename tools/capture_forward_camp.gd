extends SceneTree

## Pending shared engine queue. Synthetic composition capture ONLY, not an
## earned placement, controller, biome, authority, rest or acceptance proof.
const CAMP := preload("res://scripts/build/forward_camp.gd")

func _init() -> void: call_deferred("_capture")

func _capture() -> void:
	var output := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output=arg.trim_prefix("--out=")
	if output.is_empty() or DisplayServer.get_name() == "headless" or FileAccess.file_exists(output):
		push_error("Use a display and --out=<fresh absolute PNG path>.")
		quit(2)
		return
	root.size=Vector2i(1920,1080)
	var stage := Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("829ca5")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("c4cbd0")
	env.environment.ambient_light_energy=0.65
	stage.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-42,-25,0)
	sun.light_energy=1.2
	stage.add_child(sun)
	var floor := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size=Vector2(30,30)
	floor.mesh=mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color("667857")
	mat.roughness=1.0
	floor.material_override=mat
	stage.add_child(floor)
	var camp := CAMP.new()
	stage.add_child(camp)
	camp.build_real()
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position=Vector3(8,6,10)
	camera.look_at(Vector3(0,0.8,0))
	camera.current=true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output)
	print(JSON.stringify({"capture":"F34 synthetic composition","acceptance":false,"output":output,"error":error}))
	quit(0 if error == OK else 1)
