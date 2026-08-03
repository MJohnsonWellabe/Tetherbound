extends SceneTree

## Capture the playground from fixed viewpoints, for the visual critic loop.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver vulkan --resolution 1280x720 \
##     --script tools/survey.gd
##
## Or just: tools/survey.sh
##
## Viewpoints are FIXED and named after the panels on
## docs/reference/tetherbound-meadows-keyart.png, so every frame is judged
## against the panel it is trying to be rather than against a general
## impression. Changing a viewpoint invalidates comparison with every earlier
## sheet, so change them deliberately.
##
## Positions are given as XZ plus a height ABOVE GROUND, sampled from the same
## heightfield the terrain was baked from. That way a re-bake moves the cameras
## with the terrain instead of burying them in a hill.
##
## HONEST LIMITS, which belong in any critique made from these frames:
##   * Software rendering (llvmpipe). Shading is correct; frame times are
##     meaningless and must never be quoted as performance.
##   * Placeholder art. Until there is representative art these frames support
##     judgements about composition, terrain shape, colour and framing — not
##     about model quality.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots"

## Terrain streams in over several frames and builds collision after that.
const SETTLE_FRAMES := 240
## Frames to let rendering settle after posing, before the shutter.
const POSE_FRAMES := 4

## name, eye XZ, eye height above ground, look-at XZ, look-at height above
## ground, sun pitch degrees (negative is a lower sun).
const VIEWPOINTS := [
	{
		"name": "01-spawn-outward",
		"eye": Vector2(0.0, 0.0), "eye_h": 2.2,
		"target": Vector2(150.0, 120.0), "target_h": 6.0,
		"sun_pitch": -42.0,
	},
	{
		"name": "02-valley-floor",
		"eye": Vector2(-120.0, 130.0), "eye_h": 2.2,
		"target": Vector2(40.0, 40.0), "target_h": 20.0,
		"sun_pitch": -42.0,
	},
	{
		"name": "03-rise-overlook",
		"eye": Vector2(140.0, -90.0), "eye_h": 6.0,
		"target": Vector2(-60.0, 60.0), "target_h": 0.0,
		"sun_pitch": -42.0,
	},
	{
		"name": "04-three-quarter",
		"eye": Vector2(70.0, 40.0), "eye_h": 8.0,
		"target": Vector2(-90.0, -60.0), "target_h": 4.0,
		"sun_pitch": -42.0,
	},
	{
		"name": "05-spawn-low-sun",
		"eye": Vector2(0.0, 0.0), "eye_h": 2.2,
		"target": Vector2(150.0, 120.0), "target_h": 6.0,
		"sun_pitch": -11.0,
	},
]


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)

	for i in SETTLE_FRAMES:
		await physics_frame

	# The playground's own rig follows the player every frame, so it has to stop
	# before the camera can be posed. A survey camera of our own is cleaner than
	# fighting it, and keeps the rig's tuning out of the framing.
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	# The debug HUD occludes the upper-left of every frame and is not part of
	# what a critic should be judging.
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var sun: DirectionalLight3D = world.get_node_or_null(^"Sun") as DirectionalLight3D
	var field: RefCounted = HEIGHTFIELD.new()

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])

		_pose(camera, field, view)
		if sun != null:
			# Yaw is kept fixed so only the elevation differs between the day and
			# low-sun frames; two variables would make them incomparable.
			sun.rotation = Vector3(deg_to_rad(float(view["sun_pitch"])), deg_to_rad(-38.0), 0.0)

		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue

		var flat := _flatness(image)
		var path := "%s/%s.png" % [OUT_DIR, name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name, error])
			continue

		written.append(path)
		# A frame that is one flat colour is a rendering failure dressed up as a
		# dark scene. Better to fail the run than hand it to a critic.
		if flat < 0.01:
			failures.append("%s: frame is almost a single flat colour (spread %.4f); nothing rendered" % [name, flat])
		print("  %-22s spread %.3f  -> %s" % [name, flat, path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")

	if not failures.is_empty():
		print("")
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _pose(camera: Camera3D, field: RefCounted, view: Dictionary) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye_ground: float = field.height_at(eye_xz.x, eye_xz.y)
	var target_ground: float = field.height_at(target_xz.x, target_xz.y)

	var eye := Vector3(eye_xz.x, eye_ground + float(view["eye_h"]), eye_xz.y)
	var target := Vector3(target_xz.x, target_ground + float(view["target_h"]), target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)


## Rough measure of how much the frame varies. Sampled on a grid rather than
## per pixel, which is plenty to tell "a rendered scene" from "a flat fill".
func _flatness(image: Image) -> float:
	var width := image.get_width()
	var height := image.get_height()
	var step := maxi(1, width / 64)
	var lowest := Vector3(INF, INF, INF)
	var highest := Vector3(-INF, -INF, -INF)
	for y in range(0, height, step):
		for x in range(0, width, step):
			var c := image.get_pixel(x, y)
			lowest = Vector3(minf(lowest.x, c.r), minf(lowest.y, c.g), minf(lowest.z, c.b))
			highest = Vector3(maxf(highest.x, c.r), maxf(highest.y, c.g), maxf(highest.z, c.b))
	return (highest - lowest).length()
