extends SceneTree

## OWNER-0901-CREATURE-BED-POSE. Renders several species resting on a real
## creature_bed.gd, using the exact same call path as _sync_rest_body()
## (setup -> position at REST_ANCHOR -> play_faint()), to compare the
## species the owner named as working (galecrest) against species the
## owner says still fail. Mirrors tools/_capture_creature_bed_rest.gd but
## sweeps a species list in one run instead of hardcoding terrapup.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_bed_pose_survey.gd -- <out_dir> <species,species,...>

const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

const POSE_FRAMES := 120
const FOV := 42.0


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; run under xvfb-run")
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "res://shots/bed_pose_survey"
	var species_list: Array[String] = []
	if args.size() > 1:
		for s in args[1].split(","):
			species_list.append(s)
	else:
		species_list = ["terrapup", "galewisp", "galecrest"]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var world := _stage(20.0)
	var bed: Node3D = CREATURE_BED.new()
	world.add_child(bed)
	bed.call("build_real", false)
	await process_frame

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 100.0
	world.add_child(camera)
	camera.make_current()

	for species_id in species_list:
		var body := CREATURE_SCENE.instantiate() as Node3D
		body.set_script(CREATURE_BODY)
		world.add_child(body)
		body.call("setup", species_id, false)
		body.position = CREATURE_BED.REST_ANCHOR
		body.rotation.y = PI * 0.5
		body.collision_layer = 0
		body.collision_mask = 0
		body.set_physics_process(false)
		body.call_deferred("play_faint")

		camera.global_position = Vector3(3.4, 2.2, 4.0)
		camera.look_at(Vector3(0.0, 0.45, 0.0), Vector3.UP)
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image != null:
			var path := "%s/%s-front.png" % [out_dir, species_id]
			image.save_png(path)
			print("    -> %s" % path)

		camera.global_position = Vector3(-3.6, 1.8, -3.4)
		camera.look_at(Vector3(0.0, 0.45, 0.0), Vector3.UP)
		for i in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		image = root.get_texture().get_image()
		if image != null:
			var path2 := "%s/%s-side.png" % [out_dir, species_id]
			image.save_png(path2)
			print("    -> %s" % path2)

		body.queue_free()
		await process_frame

	print("done")
	quit(0)


func _stage(half_size: float) -> Node3D:
	var world := Node3D.new()
	root.add_child(world)

	var env_holder := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_holder.environment = env
	world.add_child(env_holder)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48.0, 40.0, 0.0)
	world.add_child(sun)

	var body := StaticBody3D.new()
	body.name = "Ground"
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(half_size * 2.0, half_size * 2.0)
	mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.31, 0.38, 0.22)
	material.roughness = 1.0
	mesh.material_override = material
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(half_size * 2.0, 0.4, half_size * 2.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.2, 0.0)
	body.add_child(shape)
	world.add_child(body)

	return world
