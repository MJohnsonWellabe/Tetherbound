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
		# Place 1: the Gate Meadow (arc 0-450). ROUND 1 FIX: the first eye
		# (2,15) sat 11.7m from the practice-trainer clearing centre (13,9),
		# inside its 14m radius, so the round-1 frame was shot from inside a
		# fenced training pen rather than the open road -- the blind judge's
		# round-1 verdict ("same anchor tree, same purple flower bush") was
		# right that nothing new was visible, because nothing new was in
		# frame. Moved to (9,25), 16.5m clear of that clearing and back on
		# the road, looking straight up it at (9,90) so the new tree flanks
		# at (20,50) (23.7 degrees right) and (-5,95) (11.3 degrees left)
		# both fall inside frame instead of off to one side.
		"name": "place1-gate-meadow",
		"eye": Vector2(9.0, 25.0), "eye_h": 2.2,
		"target": Vector2(9.0, 90.0), "target_h": 2.0,
		"time": "day", "horizon": 0.32,
		"actor": Vector2(11.0, 22.0),
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
		# five-place set. ROUND 1 FIX: the first eye (-360,550) sampled the
		# analytic heightfield at -19.40m, BELOW water.level (-17.0,
		# terrain_playground.json) -- the round-1 frame was shot from
		# underwater looking up through the surface, which is exactly the
		# "smeared dark-cyan band over a featureless plain" the blind judge
		# called the single worst frame in the set.
		# ROUND 2 FIX: (-325,560) was on dry shore, but this pocket is
		# deliberately the densest vegetation on the map (contract: "do not
		# thin it") -- a headless clearance probe found every shoreline
		# point within ~2m of a trunk, and the round-2 render put one dead
		# centre in the lens. Moved to (-390,510), inside the mill's own
		# clearing (vegetation.json clearings order 5, radius 15 around
		# (-383.5,517), kept clear of blocking vegetation by design) and
		# 31m from the nearest tree, looking out across the open water
		# instead of standing in the reeds.
		# MID-LAYER-0903 RE-SITE (docs/specs/BAND1_COMPOSITION_PLAN.md 5.5,
		# 6.3): (-390,510) stood 3m from the mill's own wall, inside its
		# footprint, and shot a stone wall -- "the camera is on the wrong
		# side of the building" (JUDGE-before.md). Moved to the fisher's
		# camp (props `pond_fisher_camp`, band1 props.json), looking north
		# across the water at the mill (-383.5,517) 72m away: bench and
		# firepit near-left, water mid, mill and footbridge far, the
		# far-bank grove (5.3's anchor at (-420,560)) behind them. This
		# invalidates comparison with the WORLD-TREES before/after sheet for
		# this one frame; the two before frames of the old stand are the
		# record of why (BAND1_COMPOSITION_PLAN.md 6.3).
		"name": "place3-pond-pocket",
		"eye": Vector2(-398.0, 588.0), "eye_h": 2.2,
		"target": Vector2(-383.5, 517.0), "target_h": 2.0,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(-396.0, 585.0),
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

	# W05-TREELINE-0904: `--only=a,b` re-renders named stands into the same
	# directory without touching the others (same contract as
	# tools/_capture_band1_composition.gd), so a before/after pair on two
	# stands does not cost five full-world software-GL renders each side.
	var only := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		if only != "" and name not in only.split(","):
			continue

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
