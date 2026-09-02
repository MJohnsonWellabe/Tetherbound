extends SceneTree

## HIST-164 — "three named landmarks are two kits used twice." The frame the
## critic described: the inn and the farmhouse standing side by side, in the
## same shot, as visible twins.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_capture_village_twins.gd -- --tag=before
##
## NEVER `--headless` with a real rendering driver (`docs/AGENT_WORKFLOW.md`).
##
## No world scene: `building_prefabs.gd::instantiate()` builds a prefab from
## its recipe with nothing else standing, so the two buildings can be put next
## to each other under a neutral light and judged against each other rather
## than against whatever the village happens to have behind them. That is the
## comparison the item is about — "the world cannot be navigated by looking at
## it" is a claim about two buildings, not about a site.
##
## Two views, because the twinning claim is about both: a straight front
## elevation (are they the same face?) and a three-quarter (are they the same
## massing and silhouette?).

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const OUT_DIR := "res://shots/hist-164"
const LEFT := "farmhouse_shell"
const RIGHT := "inn"
## Far enough apart not to intersect (each is ~6.2 x 10.4), close enough to
## read as neighbours on one square.
const SPACING := 11.0

var _tag := "before"
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--tag="):
			_tag = str(arg).substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for i in 6:
		await process_frame

	var world := Node3D.new()
	world.name = "TwinsStage"
	root.add_child(world)
	current_scene = world

	var holder := Node3D.new()
	holder.name = "Templates"
	world.add_child(holder)
	var composer: RefCounted = PREFABS.new()
	composer.call("set_template_holder", holder)
	if not bool(composer.call("load_recipes")):
		_fail("could not load building_prefabs.json")
		_finish()
		return

	# Ground and light, so the buildings are lit the same way and cast onto
	# something. Neutral on purpose -- this frame is a comparison between two
	# recipes, not a judgement of the village's own lighting.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80.0, 80.0)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.42, 0.46, 0.34)
	ground.material_override = ground_mat
	world.add_child(ground)

	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.5
	sun.rotation_degrees = Vector3(-42.0, -128.0, 0.0)
	sun.shadow_enabled = true
	world.add_child(sun)

	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.70, 0.80)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.60, 0.68)
	environment.ambient_light_energy = 0.7
	env.environment = environment
	world.add_child(env)

	for spec: Variant in [[LEFT, -SPACING * 0.5], [RIGHT, SPACING * 0.5]]:
		var pair := spec as Array
		var node: Node3D = composer.call("instantiate", str(pair[0]))
		if node == null:
			_fail("could not instantiate %s" % pair[0])
			_finish()
			return
		node.position = Vector3(float(pair[1]), 0.0, 0.0)
		world.add_child(node)
	await _settle(12)

	var camera := Camera3D.new()
	camera.fov = 50.0
	camera.far = 400.0
	world.add_child(camera)
	camera.make_current()

	# Front elevation: square on to both front gables (both face +z).
	camera.global_position = Vector3(0.0, 6.0, 34.0)
	camera.look_at(Vector3(0.0, 4.5, 0.0), Vector3.UP)
	await _settle(8)
	await _shoot("twins-front-%s" % _tag)

	# Three-quarter: the silhouette and massing view.
	camera.global_position = Vector3(20.0, 11.0, 24.0)
	camera.look_at(Vector3(0.0, 4.0, 0.0), Vector3.UP)
	await _settle(8)
	await _shoot("twins-threequarter-%s" % _tag)

	_finish()


func _shoot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		_fail("%s: viewport returned no image" % name)
		return
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(path) != OK:
		_fail("%s: save_png failed" % name)
		return
	print("  %-34s -> %s" % [name, path])


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	print("")
	print("Software rasterisation. Composition, colour and silhouette only.")
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
