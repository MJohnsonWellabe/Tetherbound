extends SceneTree

## T3-INSTALL. Render the nine creatures this lane put on the live roster --
## the five new-mesh species (Sparkit, Cindercub, Shadelet, Frostclaw,
## Bramblebun-redesign) and the four Aspect variants (Nightburrow, Stormtrail,
## Riftfrill, Ashtusk) -- through the REAL production path: `creature_body.gd
## ::setup(species_id)` reading `data/creatures/species.json` exactly as the
## game does, not a hand-built stand-in. This is the render owed since D1
## (`ralph/reports/DARK_FEATURES_INVENTORY_2026-08-30.md`) landed the two
## missing keys with no render to confirm them, and the first look at the
## five new species meshes standing in the world at all.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/_capture_t3_install_roster.gd
##
## Same lineup-with-a-ruler shape as preview_creatures.gd, but filtered to
## just these nine and captioned per-species so a variant's texture can be
## told apart from its base species' at a glance without cross-referencing.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const OUT := "res://ralph/reports/T3-INSTALL/shots/roster.png"

const TRAINER_HEIGHT := 1.8

## Species id -> (its own colour tag for the caption, base species it should
## visually differ from if it is a variant).
const IDS := [
	"bramblebun", "sparkit", "cindercub", "shadelet", "frostclaw",
	"nightburrow", "burrowback",
	"stormtrail", "trailpup",
	"riftfrill", "paddlenewt",
	"ashtusk", "tuskroot",
]


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	await process_frame

	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.20, 0.22, 0.24)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.80, 0.84)
	e.ambient_light_energy = 1.5
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(-35.0), 0.0)
	key.light_energy = 1.6
	world.add_child(key)

	var spacing := 2.4
	var x := -spacing * (IDS.size() - 1) * 0.5
	var built: Array[String] = []
	var missing: Array[String] = []

	for id: String in IDS:
		var body: Node3D = CREATURE_SCENE.instantiate()
		body.name = "Roster_%s" % id
		body.set_script(BODY)
		world.add_child(body)
		body.call("setup", id)
		body.global_position = Vector3(x, 0.0, 0.0)
		body.set_physics_process(false)

		var has_model: bool = bool(body.call("has_model"))
		if has_model:
			built.append(id)
		else:
			missing.append(id)

		var ruler := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.05, TRAINER_HEIGHT, 0.05)
		ruler.mesh = bar
		var grey := StandardMaterial3D.new()
		grey.albedo_color = Color(0.5, 0.5, 0.55)
		ruler.material_override = grey
		world.add_child(ruler)
		ruler.global_position = Vector3(x - 0.85, TRAINER_HEIGHT * 0.5, -0.3)

		var label3d := Label3D.new()
		label3d.text = id
		label3d.font_size = 34
		label3d.pixel_size = 0.01
		label3d.no_depth_test = true
		label3d.modulate = Color(1, 1, 0.55) if not has_model else Color(1, 1, 1)
		world.add_child(label3d)
		label3d.global_position = Vector3(x, 2.15, 0.0)

		x += spacing

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(spacing * IDS.size() + 6.0, 8)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.33, 0.30)
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)

	var camera := Camera3D.new()
	camera.fov = 50.0
	world.add_child(camera)
	camera.make_current()

	for i in 40:
		await physics_frame

	camera.global_position = Vector3(0.0, 1.6, spacing * IDS.size() * 0.62 + 2.5)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)

	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("no image")
		quit(1)
		return
	image.save_png(OUT)
	print("wrote %s" % OUT)
	print("has_model: %s" % ", ".join(built))
	if not missing.is_empty():
		print("NO MODEL (capsule fallback): %s" % ", ".join(missing))
	quit(0 if missing.is_empty() else 1)
