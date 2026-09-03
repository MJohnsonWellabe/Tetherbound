extends SceneTree

## WORLD-TREES-0903. Captures a stand at each of BAND1_ROUTE_CONTRACT.md's
## five authored places (the Gate Meadow, the Rise, the Pond pocket, the Long
## Field, the Bridge approach), for the code-blind judge's before/after set
## alongside the standard five `tools/survey.gd` stands.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_band1_places.gd
##
## NEVER with `--headless` and a real rendering driver.
##
## Structure, camera maths and safety rails (weather/clock freeze, HUD hide,
## Terrain3D camera handoff, player-park geometry, horizon-fraction pitch) are
## copied deliberately from `tools/survey.gd` rather than re-derived -- that
## file's own comments record why each exists (maroon-wash bug, clock drift,
## streaming radius). Coordinates below are the contract's own place arcs,
## sited against the real heightfield with `tools/_probe_band1_worldtrees.gd`
## (see vegetation.json's own `_why_world_trees_0903` anchors for the same
## numbers), never guessed.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots_places"

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
		# Place 1: the Gate Meadow (arc 0-450). Standing just past the village
		# gate, looking up the road at the new near-road tree flanks (20,50)
		# and (-5,95) and the pre-existing first-bend rock line.
		"name": "place1-gate-meadow",
		"eye": Vector2(2.0, 15.0), "eye_h": 2.2,
		"target": Vector2(8.0, 90.0), "target_h": 2.0,
		"time": "day", "horizon": 0.32,
		"actor": Vector2(4.0, 12.0),
	},
	{
		# Place 2: the Rise (arc 450-900). On the road just before the crest,
		# looking up at the new hero TwistedTree anchor at (-224,336).
		"name": "place2-the-rise",
		"eye": Vector2(-215.0, 322.0), "eye_h": 2.4,
		"target": Vector2(-224.0, 336.0), "target_h": 10.0,
		"time": "day", "horizon": 0.26,
		"actor": Vector2(-212.0, 318.0),
	},
	{
		# Place 3: the Pond pocket (arc 900-1200), the approved lush
		# reference -- unchanged by this lane, captured for the judge's full
		# five-place set. Looking toward the mill/pond basin.
		"name": "place3-pond-pocket",
		"eye": Vector2(-360.0, 550.0), "eye_h": 2.2,
		"target": Vector2(-383.5, 517.0), "target_h": 3.0,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(-357.0, 546.0),
	},
	{
		# Place 4: the Long Field (arc 1200-1950). Looking at the second
		# thinnest-leg grove (arc 2100-2250 -- the lowest tree count of any
		# leg past the opening) at (5,1235).
		"name": "place4-long-field",
		"eye": Vector2(25.0, 1252.0), "eye_h": 2.2,
		"target": Vector2(5.0, 1235.0), "target_h": 4.0,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(22.0, 1249.0),
	},
	{
		# Place 5: the Bridge approach (arc 1950-2421). Not this lane's file
		# scope; captured for the judge's full five-place set and as an
		# unrelated-region control.
		"name": "place5-bridge-approach",
		"eye": Vector2(-20.0, 1318.0), "eye_h": 2.2,
		"target": Vector2(8.0, 1330.0), "target_h": 2.0,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(-17.0, 1315.0),
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
