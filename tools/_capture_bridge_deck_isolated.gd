extends SceneTree

## W22-BRIDGE-SIGNPOST-0904, prompt 74 §7 step 1: "read what
## `building_prefabs.json`'s deck/rail entries actually reference today ...
## and render it in isolation." The `south_bridge` prefab (and the loose kit
## pieces it is composed from), plus one four-arm signpost, stood in a bare
## lit scene with nothing else in frame -- so the deck's own planks, rails
## and abutments can be compared to board 18's "Bridge Plank & Rail" panel
## without the world's grass, gully or checkpoint in the way.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_bridge_deck_isolated.gd [-- --out=res://shots/w22/isolated]
##
## Runs in a minute or two (no world load). Never `--headless` with a
## rendering driver.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const SIGNPOST := preload("res://scripts/world/signpost.gd")
const DEFAULT_OUT_DIR := "res://shots/w22/isolated"
const SETTLE_FRAMES := 12

## eye / target in the bare scene's own metres; the deck runs along +x from
## -9.2 to +9.2 at y=0.12, rails at z=+-0.95.
const VIEWPOINTS := [
	{"name": "deck-three-quarter", "eye": Vector3(-13.0, 3.2, 7.5), "target": Vector3(-1.0, 0.4, 0.0), "fov": 55.0},
	{"name": "deck-on-the-planks", "eye": Vector3(-9.5, 1.6, 0.0), "target": Vector3(0.0, 0.5, 0.3), "fov": 62.0},
	{"name": "deck-rail-close", "eye": Vector3(-5.5, 1.4, -0.3), "target": Vector3(-2.0, 0.6, 0.95), "fov": 50.0},
	{"name": "deck-side-elevation", "eye": Vector3(0.0, 1.2, 14.0), "target": Vector3(0.0, 0.5, 0.0), "fov": 50.0},
	{"name": "signpost-front", "eye": Vector3(30.0, 1.6, 3.2), "target": Vector3(30.0, 1.5, 0.0), "fov": 45.0},
	{"name": "signpost-three-quarter", "eye": Vector3(32.4, 1.7, 2.4), "target": Vector3(30.0, 1.4, 0.0), "fov": 45.0},
]

static var _out_dir: String = DEFAULT_OUT_DIR


## The one thing `signpost.gd::build` asks of its world.
class FlatGround extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 0.0


func _init() -> void:
	_run()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	var world := FlatGround.new()
	world.name = "World"
	root.add_child(world)

	_light(world)
	_ground(world)

	var prefabs: RefCounted = PREFABS.new()
	if not bool(prefabs.call("load_recipes")):
		push_error("no building recipes")
		quit(1)
		return
	var holder := Node3D.new()
	holder.name = "PrefabTemplates"
	holder.visible = false
	world.add_child(holder)
	prefabs.call("set_template_holder", holder)

	var span: Node3D = prefabs.call("instantiate", "south_bridge")
	if span == null:
		push_error("south_bridge prefab missing")
		quit(1)
		return
	span.name = "Span"
	world.add_child(span)

	var sign: Node3D = SIGNPOST.new()
	sign.name = "Signpost"
	world.add_child(sign)
	sign.call("build", world, Vector2(30.0, 0.0), [
		{"label": "Grandpa's House", "points": [[30.0, 0.0], [30.0, 10.0]]},
		{"label": "The Pond", "points": [[30.0, 0.0], [40.0, 3.0]]},
		{"label": "Relay Station", "points": [[30.0, 0.0], [22.0, 4.0]]},
		{"label": "South Bridge", "points": [[30.0, 0.0], [32.0, -9.0]]},
	])

	var camera := Camera3D.new()
	camera.far = 500.0
	world.add_child(camera)
	camera.make_current()

	for i in SETTLE_FRAMES:
		await process_frame

	var written := 0
	var failures: Array[String] = []
	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		camera.fov = float(view.get("fov", 60.0))
		camera.global_position = view["eye"]
		camera.look_at(view["target"], Vector3.UP)
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: no image" % name)
			continue
		var path := "%s/%s.png" % [_out_dir, name]
		if image.save_png(path) != OK:
			failures.append("%s: save failed" % name)
			continue
		written += 1
		print("  %-24s -> %s" % [name, path])

	print("%d frames -> %s" % [written, _out_dir])
	for line in failures:
		print("FAIL: %s" % line)
	quit(1 if not failures.is_empty() else 0)


## Roughly the playground's own day look: one warm sun from high in the
## south-west, a pale-blue sky as ambient. Not a match for `WorldLook`, and
## not meant to be -- the world stands are the judged evidence; this is for
## reading geometry and relative colour, not absolute values.
func _light(world: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.96, 0.9)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-52.0, 35.0, 0.0)
	world.add_child(sun)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.76, 0.92)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.8, 0.9)
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)


func _ground(world: Node3D) -> void:
	var plane := MeshInstance3D.new()
	plane.name = "Ground"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(120.0, 120.0)
	plane.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.48, 0.24)
	mat.roughness = 1.0
	plane.material_override = mat
	plane.position = Vector3(10.0, -0.02, 0.0)
	world.add_child(plane)
