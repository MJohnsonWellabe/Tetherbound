extends SceneTree
## BAND1-COMPOSITION-0903 (docs/ROADMAP.md task 2.1). Six composition stands
## along the Band 1 route, one per place the composition plan names plus the
## two directions the Rise crest looks. Sited from the real heightfield with
## tools/_probe_band1_composition.gd (arc/height table), not from config.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_band1_composition.gd
##
## NEVER with `--headless` and a real rendering driver.
##
## Camera maths and safety rails are copied from tools/_capture_band1_places.gd
## (itself copied from tools/survey.gd); see those files for why each exists.
## Each stand is an EYE/LOOK pair from docs/specs/BAND1_COMPOSITION_PLAN.md:
## the eye is where a walking player stands on the road, the look is what the
## composition is asking them to look at.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots_composition"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 20
const ACTOR_CLEARANCE := 0.4
const PARK_DISTANCE := 12.0
const MAX_CAMERA_PLAYER_DISTANCE := 20.0
const FOV := 70.0
const DEFAULT_HORIZON := 0.30

const VIEWPOINTS := [
	{
		# Village approach: on the road at arc ~230 (h -0.7), looking back
		# north-east at the village square 214m away with the tutorial mound
		# (peak (140,-90), h 49) 300m behind it. The return-home frame.
		"name": "comp1-village-approach",
		"eye": Vector2(-52.0, 194.0), "eye_h": 2.2,
		"target": Vector2(10.0, -10.0), "target_h": 6.0,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(-48.0, 188.0),
	},
	{
		# Route out: just outside the road gate at arc ~60 (h -0.7), aimed at
		# the Rise crest (-225,327; h 10.6, hero TwistedTree at (-224,336))
		# 360m away, with the first-bend copses at (-136,289)/(-95,292) between.
		"name": "comp2-route-out",
		"eye": Vector2(9.0, 40.0), "eye_h": 2.2,
		"target": Vector2(-225.0, 327.0), "target_h": 12.0,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(6.0, 46.0),
	},
	{
		# The Rise, forward: on the road at the crest (arc ~443, h 10.3), the
		# hero tree 13m ahead-left, looking down 30m into the pond basin at
		# the mill (-383.5,517) 247m away.
		"name": "comp3-rise-overlook-pond",
		"eye": Vector2(-218.0, 324.0), "eye_h": 2.2,
		"target": Vector2(-383.5, 517.0), "target_h": 4.0,
		"time": "day", "horizon": 0.26,
		"actor": Vector2(-224.0, 327.0),
	},
	{
		# The Rise, back: just past the crest (h 10.4), looking back at the
		# village 415m away and the mound behind it -- the key art's top-left
		# panel (village nestled under a hill).
		"name": "comp4-rise-look-back",
		"eye": Vector2(-236.0, 334.0), "eye_h": 2.2,
		"target": Vector2(10.0, -10.0), "target_h": 6.0,
		"time": "day", "horizon": 0.28,
		"actor": Vector2(-230.0, 331.0),
	},
	{
		# Pond arrival: on the descent at arc ~654 (h -12.6), the shepherd
		# Dara at (-377,457) 15m ahead-right, looking at the mill and its
		# crossing 76m ahead where the road meets the water.
		"name": "comp5-pond-arrival",
		"eye": Vector2(-387.0, 442.0), "eye_h": 2.2,
		"target": Vector2(-384.0, 518.0), "target_h": 3.0,
		"time": "day", "horizon": 0.32,
		"actor": Vector2(-388.0, 448.0),
	},
	{
		# Bridge approach: on the road at arc ~2150 (h -0.6) where the broken
		# fence line begins on the left shoulder, aimed between the road's
		# bend and the South Bridge (8,1330) 143m away.
		"name": "comp6-bridge-approach",
		"eye": Vector2(105.0, 1226.0), "eye_h": 2.2,
		"target": Vector2(20.0, 1275.0), "target_h": 2.0,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(100.0, 1228.0),
	},
]


static var _fast_mode: bool = false


static func _frames(n: int) -> int:
	return maxi(2, n / 2) if _fast_mode else n


func _init() -> void:
	_run()


func _run() -> void:
	_fast_mode = "--fast" in OS.get_cmdline_user_args() or OS.get_environment("VP_FAST") == "1"
	if _fast_mode:
		print("[fast] iteration mode: settle halved, msaa off")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)

	var written: Array[String] = []
	var failures: Array[String] = []

	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	else:
		failures.append("no WorldWeather node with set_weather")

	for i in _frames(SETTLE_FRAMES):
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)

	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	if _fast_mode:
		root.msaa_3d = Viewport.MSAA_DISABLED
		root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	else:
		failures.append("no Terrain node with set_camera")

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])

		_pose(camera, field, view)
		_place_actor(player, field, camera, view)
		if look != null:
			look.call("apply_time", str(view.get("time", "day")))
			if look.has_method("time_of_day") and look.has_method("hour"):
				print("DIAG %s: time=%s hour=%.3f" % [
					name, str(look.call("time_of_day")), float(look.call("hour"))])
		else:
			failures.append("%s: no WorldLook node" % name)

		for i in _frames(SETTLE_AFTER_MOVE):
			await physics_frame
		for i in _frames(POSE_FRAMES):
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
			failures.append("%s: frame is almost a single flat colour (spread %.4f)" % [name, flat])
		var cam_player_dist := INF
		if player != null:
			cam_player_dist = camera.global_position.distance_to(player.global_position)
		print("  %-22s spread %.3f  cam-player %.1fm  -> %s" % [name, flat, cam_player_dist, path])
		if cam_player_dist > MAX_CAMERA_PLAYER_DISTANCE:
			push_warning("%s stands %.1fm from the player (max %.1fm)" % [
				name, cam_player_dist, MAX_CAMERA_PLAYER_DISTANCE])

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
		var target_xz: Vector2 = view["target"]
		var behind := (eye_xz - target_xz).normalized()
		var park_xz := eye_xz + behind * PARK_DISTANCE
		player.global_position = Vector3(park_xz.x, field.height_at(park_xz.x, park_xz.y) + ACTOR_CLEARANCE, park_xz.y)
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
