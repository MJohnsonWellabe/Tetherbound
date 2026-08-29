extends SceneTree

## T1-CAMP: one close, well-lit frame per §17 priority asset (Tent, Campfire
## ring+logs, Player Bed/bedroll, Creature Bed, Workbench), same stage/light
## rig as tools/_capture_t1_camp.gd, for judging shared material/style family
## and per-object finish -- not a gameplay-distance shot (that's the other
## tool), a materials-inspection shot.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_t1_camp_assets.gd -- <out_dir>

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const CAMP := preload("res://scripts/build/camp.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const BUILDABLES_JSON := "res://data/items/buildables.json"

const POSE_FRAMES := 3
const FOV := 42.0


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "res://shots/t1_camp_assets"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	# The full camp gives us the tent, ring+fire and bedroll already composed
	# (camp.gd's own relative layout) -- shoot each sub-area close.
	var world := _stage(20.0)
	var camp := CAMP.new()
	world.add_child(camp)
	camp.call("build_real")
	await process_frame

	await _shoot(world, "01-tent", Vector3(-1.4, 1.2, 1.6), Vector3(-1.65, 0.7, -0.3))
	await _shoot(world, "02-campfire-ring", Vector3(0.4, 1.1, 1.9), Vector3(0.0, 0.35, 0.0))
	await _shoot(world, "03-player-bedroll", Vector3(2.4, 1.0, 2.0), Vector3(1.8, 0.15, 0.6))
	world.queue_free()

	var world2 := _stage(20.0)
	var bed := CREATURE_BED.new()
	world2.add_child(bed)
	bed.call("build_real", false)
	await process_frame
	await _shoot(world2, "04-creature-bed", Vector3(1.3, 1.0, 1.5), Vector3(0.0, 0.25, 0.0))
	world2.queue_free()

	var world3 := _stage(20.0)
	var wb_mesh := _mesh_path("workbench")
	if wb_mesh != "":
		var wb := BUILD_PIECE.new()
		world3.add_child(wb)
		wb.call("build_real", wb_mesh)
		await process_frame
		await _shoot(world3, "05-workbench", Vector3(1.6, 1.3, 1.6), Vector3(0.0, 0.45, 0.0))
	world3.queue_free()

	print("done -> %s" % out_dir)
	quit(0)


func _mesh_path(id: String) -> String:
	var file := FileAccess.open(BUILDABLES_JSON, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ""
	var list: Variant = (parsed as Dictionary).get("buildables", [])
	if not list is Array:
		return ""
	for entry: Variant in list:
		var d := entry as Dictionary
		if str(d.get("id", "")) == id:
			return str(d.get("mesh", ""))
	return ""


var _camera: Camera3D = null


func _shoot(world: Node3D, name: String, eye: Vector3, look: Vector3) -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = Camera3D.new()
		_camera.fov = FOV
		_camera.far = 100.0
	if _camera.get_parent() != null:
		_camera.get_parent().remove_child(_camera)
	world.add_child(_camera)
	_camera.make_current()
	_camera.global_position = eye
	_camera.look_at(look, Vector3.UP)
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw
	var out_dir: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "res://shots/t1_camp_assets"
	var path := "%s/%s.png" % [out_dir, name]
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL: %s: no image" % path)
		return
	var err := image.save_png(path)
	if err != OK:
		print("FAIL: %s: save_png %d" % [path, err])
		return
	print("    -> %s" % path)


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
