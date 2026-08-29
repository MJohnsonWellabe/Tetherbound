extends SceneTree

## T1-CASTLE: terrain + landmark only, same lightweight staging
## `capture_castle_lite.gd` already proved (that file's own header has the
## full reasoning for why skipping the vegetation/settlement/NPC layers is
## valid for judging the castle's own geometry and materials) -- but at the
## CURRENT post-GATE-E2 site (`landmark.gd::SITE`), with the same four stands
## `capture_castle_63.gd` uses. `capture_castle_lite.gd` itself is left
## untouched (still pointed at the old TOWER_AT, still owned by OF4-rebuild's
## history) rather than edited, since this lane needs a fast castle-only loop
## and that file's own comment says to delete it once its own remainder closes
## -- not to repurpose it for a different task's site.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_castle_t1castle.gd

const WORLD_SCRIPT := preload("res://scripts/world/playground_world.gd")
const LANDMARK := preload("res://scripts/world/landmark.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const OUT_DIR := "res://shots/t1castle"
const DATA_DIR := "res://data/terrain/playground"

const SETTLE_FRAMES := 90
const POSE_FRAMES := 4
const FOV := 65.0

const VIEWS := [
	{"name": "01-approach-gate", "offset": Vector3(2.0, 1.8, 24.0), "look_at": Vector3(2.0, 8.0, 0.0)},
	{"name": "02-silhouette-far", "offset": Vector3(4.0, 20.0, 70.0), "look_at": Vector3(2.0, 14.0, 0.0)},
	{"name": "03-corner-close", "offset": Vector3(38.0, 14.0, 38.0), "look_at": Vector3(2.0, 9.0, 12.0)},
	{"name": "04-flank-close", "offset": Vector3(24.0, 9.0, 4.0), "look_at": Vector3(2.0, 8.0, 4.0)},
]


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var stage := Node3D.new()
	root.add_child(stage)

	var world_env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = ProceduralSkyMaterial.new()
	world_env.environment = environment
	world_env.name = "WorldEnvironment"
	stage.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	stage.add_child(sun)

	var look: Node = WORLD_LOOK.new()
	look.name = "WorldLook"
	look.set("sun_path", NodePath("../Sun"))
	look.set("environment_path", NodePath("../WorldEnvironment"))
	stage.add_child(look)
	look.call("apply_time", "day")

	var site := LANDMARK.SITE
	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	camera.global_position = Vector3(site.x, 50.0, site.y)
	stage.add_child(camera)
	camera.make_current()

	var world = WORLD_SCRIPT.new()
	print("[t1castle] building terrain")
	var terrain: Node3D = world.call("_build_terrain")
	if terrain == null:
		push_error("terrain build failed -- is the bake present at %s?" % DATA_DIR)
		quit(1)
		return
	world.remove_child(terrain)
	stage.add_child(terrain)
	if terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	for i in 5:
		await physics_frame
	terrain.set("data_directory", DATA_DIR)
	for i in 5:
		await physics_frame
	terrain.set("collision_mode", 3)
	world.set("_terrain", terrain)
	world.call("_apply_ground_materials")

	print("[t1castle] building landmark at SITE=%s" % str(site))
	var landmark: Node3D = LANDMARK.new()
	landmark.name = "StrongholdSilhouette"
	stage.add_child(landmark)
	landmark.call("build", world)

	for i in SETTLE_FRAMES:
		await physics_frame
	print("[t1castle] settled, capturing")

	var ground: float = float(world.call("ground_height_at", site.x, site.y))
	if is_nan(ground):
		ground = 0.0

	var written: Array[String] = []
	var failures: Array[String] = []
	for entry: Variant in VIEWS:
		var view: Dictionary = entry
		var name_value := str(view["name"])
		var eye := Vector3(site.x, ground, site.y) + (view["offset"] as Vector3)
		var target := Vector3(site.x, ground, site.y) + (view["look_at"] as Vector3)
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		for i in 10:
			await physics_frame
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name_value)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name_value]
		if image.save_png(path) != OK:
			failures.append("%s: save_png failed" % name_value)
			continue
		written.append(path)
		print("  %-20s -> %s" % [name_value, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
