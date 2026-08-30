extends SceneTree

## T1-CAMP: the assembled campsite (Camp = tent+fire+bedroll, Workbench,
## Creature Bed) as a player would place and see it, at gameplay third-person
## distance plus one closer composition frame. Reuses
## tools/_capture_structures.gd's own stage/measure/frame/shutter formula
## (same flat pad, same sun, same trainer ruler) rather than a new rig,
## scoped down to just the campsite cluster so a round-trip fits this
## session's budget instead of paying for all 27 structures.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_t1_camp.gd -- <out_dir>
##
## NEVER --headless with --rendering-driver opengl3 (hangs forever, no
## error) -- xvfb-run supplies the virtual display instead.

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const CAMP := preload("res://scripts/build/camp.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const BUILDABLES_JSON := "res://data/items/buildables.json"

const SETTLE_FRAMES := 8
const POSE_FRAMES := 3
const FOV := 55.0


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "res://shots/t1_camp"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var world := _stage(20.0)

	# T1-LIGHT: this rig has no WorldLook/day-cycle node, so campfire_glow.gd's
	# daylight energy scale (JUDGE-3 sec1b, "the point light has no daylight
	# attenuation") would otherwise never engage here -- this stage's fixed
	# sun IS daytime by construction, so tell anything that asks.
	var day_stub := Node.new()
	day_stub.set_script(load("res://tools/_capture_day_stub.gd"))
	day_stub.add_to_group(&"day_cycle")
	world.add_child(day_stub)

	# Camp at origin, exactly as camp.gd::build_real() composes it.
	var camp := CAMP.new()
	world.add_child(camp)
	camp.call("build_real")

	# Workbench and Creature Bed a believable few metres off, the same
	# spacing order of magnitude as the authored trail_camp cluster
	# (data/config/bands/band1_lower_meadows/props.json's own tent/bed/fire
	# ring sits within ~2-3m of itself).
	var workbench_holder := Node3D.new()
	workbench_holder.position = Vector3(3.4, 0.0, 1.6)
	workbench_holder.rotation.y = deg_to_rad(-40.0)
	world.add_child(workbench_holder)
	var wb_mesh := _workbench_mesh_path()
	if wb_mesh != "":
		var wb := BUILD_PIECE.new()
		workbench_holder.add_child(wb)
		wb.call("build_real", wb_mesh)

	var bed_holder := Node3D.new()
	bed_holder.position = Vector3(-3.0, 0.0, 2.2)
	bed_holder.rotation.y = deg_to_rad(35.0)
	world.add_child(bed_holder)
	var bed := CREATURE_BED.new()
	bed_holder.add_child(bed)
	bed.call("build_real", false)

	await process_frame

	var trainer := await _spawn_trainer(world, Vector3(0.5, 0.0, 4.2), Vector3(0.0, 0.0, 0.0))
	if trainer == null:
		print("WARNING: no trainer in frame")

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 200.0
	world.add_child(camera)
	camera.make_current()

	# Gameplay-distance establishing shot: roughly where a third-person
	# camera sits behind a player standing at the camp's edge.
	camera.global_position = Vector3(2.0, 2.1, 8.5)
	camera.look_at(Vector3(0.0, 0.9, 0.5), Vector3.UP)
	await _shoot_frame("%s/01-camp-establishing.png" % out_dir)

	# Closer composition, centred on the fire/tent group.
	camera.global_position = Vector3(1.2, 1.5, 4.2)
	camera.look_at(Vector3(-0.2, 0.8, 0.0), Vector3.UP)
	await _shoot_frame("%s/02-camp-close.png" % out_dir)

	print("done -> %s" % out_dir)
	quit(0)


func _workbench_mesh_path() -> String:
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
		if str(d.get("id", "")) == "workbench":
			return str(d.get("mesh", ""))
	return ""


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


func _spawn_trainer(world: Node3D, at: Vector3, look_toward: Vector3) -> Node3D:
	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	if player == null:
		return null
	player.name = "Trainer"
	world.add_child(player)
	player.global_position = at
	player.velocity = Vector3.ZERO

	for i in SETTLE_FRAMES:
		await physics_frame

	var model := player.get_node_or_null(^"Model") as Node3D
	if model != null:
		var to_target := look_toward - at
		model.rotation.y = atan2(to_target.x, to_target.z)

	return player


func _shoot_frame(path: String) -> bool:
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL: %s: viewport returned no image" % path)
		return false
	var error := image.save_png(path)
	if error != OK:
		print("FAIL: %s: save_png failed (%d)" % [path, error])
		return false
	print("    -> %s" % path)
	return true
