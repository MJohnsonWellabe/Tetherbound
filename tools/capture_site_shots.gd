extends SceneTree

## Capture the download page's screenshots from the real game.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_site_shots.gd
##
## Same honesty rule as tools/survey.sh: these are REAL frames, no touch-ups
## (site/README.md). Compatibility renderer caveat applies — see survey.sh's
## header. Frames land in shots/site/ as PNG; site/README.md's snippet
## converts to JPG for the page.
##
## Every viewpoint is world-space authored HERE because the shots have to
## frame specific authored content (the village square, the bedroom, the
## starter row), which the survey's fixed exploration viewpoints know nothing
## about.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT := "res://shots/site"
const SETTLE_FRAMES := 50

## name -> [camera position, look-at target]
const SHOTS := {
	"hero-meadow": [Vector3(58.0, 14.0, 28.0), Vector3(-10.0, 4.0, -12.0)],
	"village-square": [Vector3(-6.0, 6.5, 4.0), Vector3(14.0, 3.0, -8.0)],
	"opening-bedroom": [Vector3(-19.0, 8.6, -13.8), Vector3(-25.0, 7.6, -18.0)],
	"starters-by-the-door": [Vector3(-20.0, 6.2, -10.0), Vector3(-13.0, 4.6, -15.5)],
	"camp-dusk": [Vector3(24.0, 6.0, -30.0), Vector3(30.5, 3.4, -36.0)],
}


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await process_frame

	# Stage a camp for its shot: the real builder, placed as the placer would.
	var camp: Node3D = preload("res://scripts/build/camp.gd").new()
	camp.name = "SiteShotCamp"
	world.add_child(camp)
	camp.call("build_real")
	var ground := float(world.call("ground_height_at", 30.5, -36.0))
	if not is_nan(ground):
		camp.global_position = Vector3(30.5, ground, -36.0)

	var camera := Camera3D.new()
	camera.fov = 62.0
	camera.far = 2000.0
	root.add_child(camera)
	camera.make_current()
	if world.get("_terrain") != null and (world.get("_terrain") as Node).has_method("set_camera"):
		(world.get("_terrain") as Node).call("set_camera", camera)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for name: String in SHOTS.keys():
		var spec: Array = SHOTS[name]
		camera.global_position = spec[0]
		camera.look_at(spec[1])
		# Long settle per shot: Terrain3D streams regions toward the camera.
		for i in 25:
			await process_frame
		var image := root.get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT, name])
		print("shot -> %s.png" % name)

	print("done: %d frames in %s" % [SHOTS.size(), OUT])
	quit(0)
