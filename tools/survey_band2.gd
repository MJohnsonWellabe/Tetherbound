extends SceneTree

## Capture Band 2 (Stone & Root) from real player-eye-height viewpoints, for
## the MQ2B blind visual-critique loop (owner directive, OPS15: a band is not
## finished until a blind critic run against docs/reference/palworld-0*.jpg
## has nothing left it can move).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/survey_band2.gd
##
## Same shape as tools/survey.gd (viewpoint table, horizon-solved pitch,
## actor placement, Terrain3D camera handoff) but pointed at Band 2's real
## content instead of the origin: the early forest, the Old Quarry overlook,
## the ranger camp, the Burrow Warrens mouth, and the late ridge toward
## Band 3 -- day and night, since MQ2B's own checklist names both.
##
## HONEST LIMITS: Compatibility renderer, software rendering (D06/D01) --
## frame times mean nothing. Ground truth for every eye/target was checked
## against the real heightfield first (tools/_probe_mq2b_survey.gd, run and
## deleted, not committed).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/band2"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 20
const ACTOR_CLEARANCE := 0.4
const FOV := 70.0
const DEFAULT_HORIZON := 0.30

const VIEWPOINTS := [
	{
		# South Bridge -> Old Quarry leg: meadowhart/trailpup/duskhush
		# country, the first stretch of Band 2 a player actually walks.
		"name": "01-early-forest-day",
		"eye": Vector2(100.0, 1480.0), "eye_h": 1.9,
		"target": Vector2(150.0, 1550.0), "target_h": 1.2,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(120.0, 1500.0),
	},
	{
		# quarry_rim_overlook loop's own vantage: "the whole quarry floor
		# read from above before you walk into it" (macro-layout 3.2).
		"name": "02-quarry-overlook-day",
		"eye": Vector2(350.0, 1720.0), "eye_h": 2.0,
		"target": Vector2(400.0, 1800.0), "target_h": 2.0,
		"time": "day", "horizon": 0.26,
	},
	{
		# The ranger_camp_spur's own approach, camp in the mid-frame the way
		# a player would actually discover it off the road.
		"name": "03-ranger-camp-day",
		"eye": Vector2(-180.0, 2225.0), "eye_h": 1.9,
		"target": Vector2(-258.0, 2258.0), "target_h": 1.0,
		"time": "day", "horizon": 0.30,
	},
	{
		# The Burrow Warrens mouth, Band 2's required dungeon.
		"name": "04-warrens-mouth-day",
		"eye": Vector2(-390.0, 2440.0), "eye_h": 2.0,
		"target": Vector2(-420.0, 2470.0), "target_h": 2.5,
		"time": "day", "horizon": 0.28,
	},
	{
		# Past the Warrens, the sparser stretch toward Band 3 -- the "does
		# this still read as authored, not empty" check for the far half.
		"name": "05-late-ridge-day",
		"eye": Vector2(30.0, 3080.0), "eye_h": 1.9,
		"target": Vector2(60.0, 3090.0), "target_h": 1.2,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(45.0, 3082.0),
	},
	{
		# Same overlook as 02, at night: the quarry's pylons are LIT (SD16,
		# old_quarry.json) so this is the frame that tests whether that
		# reads as intended after dark.
		"name": "06-quarry-overlook-night",
		"eye": Vector2(350.0, 1720.0), "eye_h": 2.0,
		"target": Vector2(400.0, 1800.0), "target_h": 2.0,
		"time": "night", "horizon": 0.26,
	},
	{
		# Same camp as 03, at night -- duskhush (nocturnal) lives on this
		# stretch, and MQ2B's own checklist names day/night readability.
		"name": "07-ranger-camp-night",
		"eye": Vector2(-180.0, 2225.0), "eye_h": 1.9,
		"target": Vector2(-258.0, 2258.0), "target_h": 1.0,
		"time": "night", "horizon": 0.30,
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
		_place_actor(player, field, camera, view)
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
		print("  %-26s spread %.3f  -> %s" % [name, flat, path])

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
	camera.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", DEFAULT_HORIZON))),
		camera.rotation.y,
		0.0
	)


func _place_actor(player: Node3D, field: RefCounted, camera: Camera3D, view: Dictionary) -> void:
	if player == null:
		return
	if not view.has("actor"):
		var eye_xz: Vector2 = view["eye"]
		player.global_position = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) - 500.0, eye_xz.y)
		return

	var xz: Vector2 = view["actor"]
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + ACTOR_CLEARANCE, xz.y)
	var away := player.global_position - camera.global_position
	player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


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
