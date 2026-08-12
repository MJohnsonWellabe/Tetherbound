extends SceneTree

## Capture EV5's water feature — the pond, the stream, the reeds — for the
## blind visual critic.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_water.gd
##
## NEVER with --headless: that silently swaps in the Dummy rendering driver
## and the capture hangs forever on frame_post_draw (see RENDER-PERF-DIAG in
## ralph/DONE.md).
##
## Same conventions as tools/survey.gd: fixed named viewpoints, XZ plus a
## height above the baked ground, horizon placed as a stated fraction of
## frame. Same honest limits too — llvmpipe software rendering, trustworthy
## for composition, colour and shape, silent about frame rate.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 20
const FOV := 70.0

## The four questions bible §15's target list asks of this feature, one frame
## each: does the shallow edge shift colour (close-up), does the surface read
## against the meadow (across-the-pond), does the stream read as water IN the
## land (course), and does the pond anchor the valley from the player's
## approach (path arrival).
const VIEWPOINTS := [
	{
		# Standing where the pond path delivers the player, looking along the
		# near shore: waterline, feather, foam band and reeds all at close
		# range, with the far bank behind them for depth.
		"name": "water-01-bank-closeup",
		"eye": Vector2(-108.0, 120.0), "eye_h": 1.8,
		"target": Vector2(-140.0, 138.0), "target_h": -1.5,
		"time": "day", "horizon": 0.25,
		"actor": Vector2(-112.0, 124.0),
	},
	{
		# From the south-west bank looking back across the whole pond toward
		# the village side: overall readability of the surface against the
		# meadow, deep-to-shallow gradient across the frame.
		"name": "water-02-across-pond",
		"eye": Vector2(-172.0, 158.0), "eye_h": 3.0,
		"target": Vector2(-105.0, 112.0), "target_h": 2.0,
		"time": "day", "horizon": 0.3,
	},
	{
		# Above the stream mid-course, looking down its run to the pond: the
		# channel, its banks, the descent, the mouth.
		"name": "water-03-stream-course",
		"eye": Vector2(-138.0, 66.0), "eye_h": 4.5,
		"target": Vector2(-140.0, 122.0), "target_h": -2.0,
		"time": "day", "horizon": 0.2,
	},
	{
		# The player's first sight of water: on the pond path where the valley
		# opens, pond below, the frame the wayfinding pays off in.
		"name": "water-04-approach",
		"eye": Vector2(-80.0, 85.0), "eye_h": 3.5,
		"target": Vector2(-145.0, 140.0), "target_h": 0.0,
		"time": "day", "horizon": 0.24,
		"actor": Vector2(-86.0, 92.0),
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

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	var failures: Array[String] = []
	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		_pose(camera, field, view)
		_place_actor(player, field, camera, view)
		if look != null:
			look.call("apply_time", str(view.get("time", "day")))
		for i in SETTLE_AFTER_MOVE:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name]
		if image.save_png(path) != OK:
			failures.append("%s: save_png failed" % name)
			continue
		print("  %-26s -> %s" % [name, path])

	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _pose(camera: Camera3D, field: RefCounted, view: Dictionary) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
	var target := Vector3(target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", 0.3))),
		camera.rotation.y,
		0.0
	)


func _place_actor(player: Node3D, field: RefCounted, camera: Camera3D, view: Dictionary) -> void:
	if player == null:
		return
	if not view.has("actor"):
		# Parked straight down from the eye, inside the streamed region — see
		# tools/survey.gd's _place_actor for why never far outside the world.
		var eye_xz: Vector2 = view["eye"]
		player.global_position = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) - 500.0, eye_xz.y)
		return
	var xz: Vector2 = view["actor"]
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + 0.4, xz.y)
	var away := player.global_position - camera.global_position
	player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)
