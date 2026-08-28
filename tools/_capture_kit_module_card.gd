extends SceneTree

## A contact card for one unused kit module: the same mesh at four yaws, with
## an axis marker, so a recipe author can see which way it faces before writing
## an `at`/`yaw_deg` into `building_prefabs.json`.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --path . \
##     --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/_capture_kit_module_card.gd -- --module=Roof_Dormer_RoundTile
##
## NEVER `--headless` with a real rendering driver (`ralph/conventions.md`).
##
## Written for `HIST-164`. `building_prefabs.json`'s format is a bare
## `at`/`yaw_deg` per module with no offset or facing convention recorded
## anywhere, and nine modules in the installed village kit are used by no
## prefab at all -- so the first cost of reaching for one of them is finding
## out which way it points. One render answers that; guessing costs the same
## render and then another.
##
## Red bar = +x, blue bar = +z, at the origin of each copy.

const KIT := "res://assets/buildings/quaternius_medieval"
const OUT_DIR := "res://shots/kit-cards"
const SPACING := 5.0

var _module := "Roof_Dormer_RoundTile"
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if str(arg).begins_with("--module="):
			_module = str(arg).substr(9)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for i in 6:
		await process_frame

	var world := Node3D.new()
	world.name = "ModuleCard"
	root.add_child(world)
	current_scene = world

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60.0, 60.0)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.40, 0.44, 0.33)
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

	var path := "%s/%s.gltf" % [KIT, _module]
	if not ResourceLoader.exists(path):
		_fail("no such module: %s" % path)
		_finish()
		return
	var packed: PackedScene = load(path)

	var yaws := [0.0, 90.0, 180.0, 270.0]
	for i in yaws.size():
		var origin := Vector3((float(i) - 1.5) * SPACING, 0.0, 0.0)
		var node: Node3D = packed.instantiate()
		node.position = origin
		node.rotation_degrees = Vector3(0.0, float(yaws[i]), 0.0)
		world.add_child(node)
		world.add_child(_axis_bar(origin, Vector3(1.2, 0.06, 0.06), Vector3(0.6, 0.0, 0.0), Color(0.9, 0.15, 0.15)))
		world.add_child(_axis_bar(origin, Vector3(0.06, 0.06, 1.2), Vector3(0.0, 0.0, 0.6), Color(0.15, 0.3, 0.95)))
	await _settle(12)

	var camera := Camera3D.new()
	camera.fov = 45.0
	camera.far = 200.0
	world.add_child(camera)
	camera.make_current()
	camera.global_position = Vector3(0.0, 6.0, 17.0)
	camera.look_at(Vector3(0.0, 1.4, 0.0), Vector3.UP)
	await _settle(8)
	await _shoot("%s-yaw-0-90-180-270" % _module)

	_finish()


## A thin box from the copy's origin along one axis, so "which way is +x" is
## visible in the frame rather than assumed from the camera.
func _axis_bar(origin: Vector3, size: Vector3, offset: Vector3, colour: Color) -> MeshInstance3D:
	var bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	bar.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bar.material_override = mat
	bar.position = origin + offset + Vector3(0.0, 0.03, 0.0)
	return bar


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
	print("  %-40s -> %s" % [name, path])


func _settle(frames: int) -> void:
	for i in frames:
		await process_frame


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if not _failures.is_empty():
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
