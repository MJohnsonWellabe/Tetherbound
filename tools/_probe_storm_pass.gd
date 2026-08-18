extends SceneTree

## RG24: photograph the storm road's collapsed-bridge blocker where it actually
## is now, so the owner can identify the "pointless gorge" he could not place
## from memory.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_probe_storm_pass.gd
##
## tools/capture_severed_spokes.gd already frames every spoke blocker, but its
## storm viewpoints are pre-OW5D: they sit at (144, 40) while the storm road now
## runs to (-34, 7513). Pointing it at the current world was more edit than a
## fresh probe, and this is a throwaway (`_probe_` per this repo's convention --
## see survey_band2.gd's note about _probe_mq2b_survey.gd).
##
## Machinery copied from tools/survey_band2.gd: viewpoint table, ground-solved
## eye heights, horizon-solved pitch, Terrain3D camera handoff, flatness guard.
##
## HONEST LIMITS: Compatibility renderer, software rendering (D06/D01) -- frame
## times from this mean nothing, and it is not a performance measurement.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/storm_pass"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 20
const FOV := 70.0
const DEFAULT_HORIZON := 0.30

# Authored geometry this is aimed at, from terrain_playground.json:
#   road ends      (-33.99, 7513.46)
#   trench centre  (-34.08, 7535.62), 60 m east-west, 11 m deep, 65.6 deg walls
#   trench ends    west (-64.0, 7533.9)   east (-4.1, 7537.3)  [zero depth]
#   far road       (-35.47, 7569.04) -> (-37.06, 7618.89)
#   stronghold     (0, 7560); spine leg wp75 (20,7480) -> wp76 (0,7560)
const VIEWPOINTS := [
	{
		# Walking up the road as a player does, blocker dead ahead.
		"name": "01-road-approach",
		"eye": Vector2(-30.0, 7455.0), "eye_h": 1.8,
		"target": Vector2(-34.0, 7540.0), "target_h": 1.0,
		"time": "day", "horizon": 0.34,
	},
	{
		# On the near lip. Does the cut read as impassable from here?
		"name": "02-at-the-near-lip",
		"eye": Vector2(-34.0, 7519.0), "eye_h": 1.8,
		"target": Vector2(-36.0, 7585.0), "target_h": 1.0,
		"time": "day", "horizon": 0.36,
	},
	{
		# THE POINT OF THIS PROBE: stand where a player heading for the
		# stronghold stands and look west along the trench's east end. The
		# 9.5 m gap between that end and the spine is the walk-around.
		"name": "03-the-way-round-east-end",
		"eye": Vector2(4.0, 7522.0), "eye_h": 1.8,
		"target": Vector2(-24.0, 7541.0), "target_h": 0.5,
		"time": "day", "horizon": 0.34,
	},
	{
		# Same gap from further back on the stronghold approach.
		"name": "04-from-stronghold-approach",
		"eye": Vector2(14.0, 7495.0), "eye_h": 1.8,
		"target": Vector2(-28.0, 7538.0), "target_h": 0.5,
		"time": "day", "horizon": 0.32,
	},
	{
		# Looking back south across the cut from the far roadbed.
		"name": "05-from-the-far-side",
		"eye": Vector2(-36.0, 7592.0), "eye_h": 1.8,
		"target": Vector2(-33.0, 7520.0), "target_h": 0.5,
		"time": "day", "horizon": 0.34,
	},
	{
		# High oblique: the whole 60 m trench, both ends, and how much
		# open ground sits past each one.
		"name": "06-oblique-whole-blocker",
		"eye": Vector2(60.0, 7452.0), "eye_h": 52.0,
		"target": Vector2(-34.0, 7545.0), "target_h": 0.0,
		"time": "day", "horizon": 0.72,
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

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)


	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])

		_pose(camera, field, view)
		# Keep the body NEAR the viewpoint. Parking it 900 m away (as an
		# earlier version of this probe did) produced frames with the trench
		# but no sign, pylons, gateposts or freight, even though a tree-walk
		# proved all of them present within 55 m -- prop residency follows the
		# player, so a far-parked body renders the world undressed.
		if player != null:
			var behind: Vector2 = view["eye"]
			player.global_position = Vector3(
				behind.x, field.height_at(behind.x, behind.y) + 0.4, behind.y)
		if look != null:
			look.call("apply_time", str(view.get("time", "day")))
		else:
			failures.append("%s: no WorldLook node, time of day not applied" % name)

		for i in SETTLE_AFTER_MOVE:
			await physics_frame
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
		if flat < 0.01:
			failures.append("%s: frame is almost a single flat colour (spread %.4f); nothing rendered" % [name, flat])
		print("  %-30s spread %.3f  ground %.1fm  -> %s" % [
			name, flat, field.height_at(float(view["eye"].x), float(view["eye"].y)), path])

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])

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
	camera.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", DEFAULT_HORIZON))),
		camera.rotation.y,
		0.0
	)


## Horizon fraction -> pitch, so "the skyline sits x of the way down the frame"
## is the authored quantity rather than a bare angle. Copied from survey_band2.gd.
func _pitch_for_horizon(fraction: float) -> float:
	var half_v := deg_to_rad(FOV) * 0.5
	return atan((0.5 - fraction) * 2.0 * tan(half_v))


## A frame that is one flat colour means the camera is inside terrain or facing
## empty sky -- worth failing loudly rather than shipping a blank PNG.
func _flatness(image: Image) -> float:
	var lo := 1.0
	var hi := 0.0
	var w := image.get_width()
	var h := image.get_height()
	for y in range(0, h, 16):
		for x in range(0, w, 16):
			var v := image.get_pixel(x, y).get_luminance()
			lo = minf(lo, v)
			hi = maxf(hi, v)
	return hi - lo
