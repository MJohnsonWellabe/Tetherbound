extends SceneTree

## T1-NPC-CAST install verification. One character, several poses, checked for
## deformation defects (tearing, split geometry at duplicate vertices) before
## committing to installing all 24 the same way. Scratch/evidence tool.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_npc_cast_test.gd -- <slug> <height>

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const OUT_DIR := "res://shots/npc_install_test"


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; use xvfb-run")
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		args = ["grunt_a"]

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var world := Node3D.new()
	root.add_child(world)
	_build_environment(world)
	for i in 15:
		await process_frame

	var camera := Camera3D.new()
	camera.fov = 45.0
	camera.far = 200.0
	world.add_child(camera)
	camera.make_current()

	for slug in args:
		# THROUGH THE REAL CONFIG PATH -- art.json's own entry, not a
		# hand-built dict, so this is the actual wiring being checked.
		var cfg: Dictionary = CHARACTER_MODEL.config_for(slug)
		if cfg.is_empty():
			print("FAIL %s: no art.json config found" % slug)
			continue
		var holder := Node3D.new()
		holder.set_script(CHARACTER_MODEL)
		world.add_child(holder)
		var built: bool = holder.call("build_from_config", cfg)
		if not built:
			print("FAIL %s: build_from_config returned false" % slug)
			holder.queue_free()
			continue
		var box: AABB = RENDER_BOUNDS.measure(holder)
		holder.position.y = -box.position.y * holder.scale.y

		for i in 15:
			await process_frame

		camera.global_position = Vector3(0.0, 1.1, 2.6)
		camera.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)

		for pose in ["idle", "walk", "sprint"]:
			if holder.has_method("play"):
				holder.call("play", pose)
			for f in 12:
				await process_frame
			await _shoot("%s-%s" % [slug, pose])

		holder.queue_free()
		for i in 5:
			await process_frame

	print("")
	print("install test written to %s" % OUT_DIR)
	quit(0)


func _build_environment(world: Node3D) -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.28, 0.30, 0.33)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 0.90)
	env.ambient_light_energy = 0.28
	env_node.environment = env
	world.add_child(env_node)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(400.0, 400.0)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.34, 0.35, 0.37)
	floor_mesh.material_override = floor_mat
	world.add_child(floor_mesh)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(-18.0), 0.0)
	key.light_energy = 0.9
	key.shadow_enabled = true
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(170.0), 0.0)
	fill.light_energy = 0.5
	fill.light_color = Color(0.80, 0.85, 0.95)
	world.add_child(fill)


func _shoot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		print("FAIL %s: save_png" % name)
		return
	print("  %-24s -> %s" % [name, path])
