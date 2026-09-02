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
## Physics frames for the trainer to settle onto the ground after being moved.
const SETTLE_AFTER_MOVE := 20
## How far below the camera's aim line the trainer is parked when a viewpoint
## asks for one, as a fraction of the distance to them. Keeps the figure in the
## lower third rather than silhouetted on the horizon.
const ACTOR_CLEARANCE := 0.4

## Vertical FOV, matching the gameplay camera. The horizon maths below depends
## on it, and Godot treats `fov` as the vertical angle at 16:9.
const FOV := 70.0

## Where the horizon should sit, as a fraction of frame height from the top.
##
## Half of every frame in the last survey was empty sky: measured 39.8%-52.4%
## against 2.2%-21.1% across the Palworld references and 17.8% on the key art
## board. The cameras were aimed at points roughly level with themselves, which
## puts the horizon dead centre — the least interesting place it can be, and it
## costs half the frame for a two-stop gradient carrying no information.
##
## Set per viewpoint rather than globally, so the five frames are not five
## copies of the same composition.
const DEFAULT_HORIZON := 0.30

## name, eye XZ, eye height above ground, look-at XZ, look-at height above
## ground, and which named time of day from data/config/art.json.
##
## `horizon` is where the true horizon lands in frame; see `_pose`. `actor`, if
## present, moves the trainer to that XZ so there is a character in shot.
##
## `time` names an hour rather than setting a sun pitch. The previous version of
## this file rotated the DirectionalLight3D directly, which is how `01` and `05`
## ended up sharing a bit-identical sky while claiming to be different times of
## day. The sun is no longer the survey's to move.
const VIEWPOINTS := [
	{
		# Eye moved off the exact origin and the target line redirected: the
		# village overhaul (D18) placed the Barn at world (2, 2), 2.8m from
		# an eye sitting at (0, 0) and directly on the (150, 120) sightline —
		# the camera ended up nose-against the barn wall, rendering the
		# unlit inside of the building instead of the meadow. This keeps the
		# "standing near spawn, looking outward" framing but clears the
		# settlement (nearest structure is now 14m+ away) and looks toward
		# the pond-valley path instead, matching the wayfinding spine.
		"name": "01-spawn-outward",
		"eye": Vector2(-9.0, -7.0), "eye_h": 2.2,
		"target": Vector2(-140.0, 145.0), "target_h": 8.0,
		"time": "day", "horizon": 0.28,
		"actor": Vector2(-15.0, -1.0),
	},
	{
		"name": "02-valley-floor",
		"eye": Vector2(-120.0, 130.0), "eye_h": 2.2,
		"target": Vector2(40.0, 40.0), "target_h": 20.0,
		"time": "day", "horizon": 0.32,
		"actor": Vector2(-108.0, 118.0),
	},
	{
		# Eye raised from 6m and moved 14m off the peak. At the old height the
		# denser copses put a single tree three metres in front of the lens and it
		# filled two thirds of the frame — the shot is meant to be the one that
		# shows distance, and it was showing one leaf blob.
		# R7.1-found: 14m off the peak still left the eye ~14-24m from the
		# stronghold silhouette's tower cluster (landmark.gd RISE_CENTRE +
		# OFFSET, world ~134,-82) -- the two landmarks independently picked
		# the same rise, so this "shows distance" shot instead framed one
		# tower point-blank. Moved further along the same rise's flank
		# (still inside landmark.gd's own rise radius, so this is still a
		# rise-overlook), ~60m from the cluster now instead of ~20m -- safer
		# to move the eye than the towers, which R7.1-visual-remainder-2 (a
		# separate, still-open item) may reshape again.
		# EV10-found: the (190,-60)/h11 eye above had since drifted onto the
		# BASE of the ridge, not its flank -- a height-grid probe (tools/
		# _diag_probe_rise.gd, not committed) found ground at that exact XZ
		# is 5.6m while the slope 10-20m further along the same sightline
		# rises to 35-49m, i.e. the lens sat under a wall almost 30-40m
		# tall. The blind judge's round-1 report named it plainly: "a huge
		# unblended cliff face with a hard seam dominates the frame... the
		# camera reads as caught in the terrain." A sightline probe (tools/
		# _diag_sightline.gd) along the full eye-to-target ray confirmed
		# (172,-88)/h15 clears the whole ridge -- nothing between eye and
		# target reads above the eye-target ray line except the ray meeting
		# the valley floor right at the target, which is the composition
		# wanted -- and sits ~38m from the tower cluster: closer than the
		# ~60m the note above records wanting, but the cluster occupies a
		# small fraction of a 70deg-vertical/16:9 frame at that range, not
		# the point-blank fill the original R7.1 fix was escaping.
		"name": "03-rise-overlook",
		"eye": Vector2(172.0, -88.0), "eye_h": 15.0,
		"target": Vector2(-60.0, 60.0), "target_h": 0.0,
		"time": "day", "horizon": 0.24,
	},
	{
		"name": "04-three-quarter",
		"eye": Vector2(70.0, 40.0), "eye_h": 8.0,
		"target": Vector2(-90.0, -60.0), "target_h": 4.0,
		"time": "day", "horizon": 0.26,
	},
	{
		# Same repositioning as 01, and for the same reason: this shared the
		# old eye/target with 01-spawn-outward, so it shared the bug too.
		"name": "05-spawn-low-sun",
		"eye": Vector2(-9.0, -7.0), "eye_h": 2.2,
		"target": Vector2(-140.0, 145.0), "target_h": 8.0,
		"time": "golden", "horizon": 0.34,
		"actor": Vector2(-15.0, -1.0),
	},
]


## FAST ITERATION MODE. On with `--fast` (a user script arg) or `VP_FAST=1` in
## the environment. Halves every settle wait below (floor 2 frames, via
## `_frames()`) and turns off MSAA/SSAA on the capture viewport. Output
## filenames and directories are unchanged -- this trades fidelity for a
## quicker local loop, never for the numbers that ship as evidence.
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

	# R6-CLOCK-FREEZE (weather half). world_look.gd's set_clock_frozen (below)
	# only gates WorldLook's own `_process` -- it says nothing about
	# WorldWeather, a SEPARATE node with its own `_process` that rolls a new
	# weather preset on a real-time timer (weather.json cycle_seconds_min/max,
	# 240-480s) and, on every roll, calls world_look.gd::set_weather(), which
	# unconditionally re-derives sun/sky/environment via _apply_blended() --
	# see that function's own body: it has no `_clock_frozen` check at all,
	# because it is meant to work "even while frozen" for the ordinary case of
	# a capture tool calling set_weather() directly. A random roll firing mid-
	# run comes in through that same unguarded door. A 5-viewpoint pass here is
	# comfortably inside the 240-480s window under software rendering (this
	# tool's own SETTLE_FRAMES alone is ~240 real seconds), while a short
	# 1-2 viewpoint smoke test is not -- which is exactly why an isolated
	# clock-freeze check on a couple of viewpoints came back looking correct
	# while the full five-viewpoint run did not: nothing about the mechanism
	# differs, only whether 240-480 real seconds had elapsed yet.
	#
	# tools/_capture_ground_and_sky.gd and tools/_capture_locations.gd (both
	# golden/night frames render correctly through them) already freeze BOTH
	# WorldLook and WorldWeather for exactly this reason -- this tool only
	# froze the first. Forced to "clear" and frozen HERE, before the very
	# first settle frame, rather than alongside WorldLook's own freeze below:
	# freezing it after the 240-frame initial settle would be freezing it
	# after it already had up to 240 real seconds -- most of the roll window
	# -- to fire once unobserved.
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	else:
		failures.append("no WorldWeather node with set_weather; its random cycle " +
			"timer is free to roll mid-run and overwrite a pinned time of day " +
			"through world_look.gd's own set_weather(), which is not gated by " +
			"the clock freeze")

	for i in _frames(SETTLE_FRAMES):
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
	if _fast_mode:
		root.msaa_3d = Viewport.MSAA_DISABLED
		root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	# R6-CLOCK-FREEZE (WorldLook half; see the WorldWeather freeze above for
	# the other half of "the clock"). Every viewpoint below calls apply_time()
	# expecting an exact, reproducible pinned frame -- but world_look.gd's
	# passive day/night clock (`_process`) is still running underneath it, and
	# this loop's own SETTLE_AFTER_MOVE/POSE_FRAMES waits are real frames under
	# software rendering (~1s each on this box). A previous attempt papered
	# over a black golden-hour frame by adding 120 MORE such frames after
	# apply_time("golden") and got a lit frame back that was not golden at all
	# -- neutral midday -- because those 120 frames let _process's own
	# _apply_blended(hour) re-derive the sky from a clock that had drifted ~5
	# in-game hours off the pin (see world_look.gd::set_clock_frozen's own
	# comment for the exact arithmetic).
	# Freezing once, here, BEFORE the viewpoint loop starts (and therefore
	# before every apply_time() call the loop makes), means every apply_time()
	# call below stays pinned through its settle/pose frames with no drift,
	# without touching SETTLE_AFTER_MOVE/POSE_FRAMES at all. Freezing alone is
	# not enough on its own, though -- WorldLook's OWN clock was never the
	# whole story here, see the WorldWeather block above.
	# has_method guards this tool against an older WorldLook that predates
	# set_clock_frozen -- it should degrade to the old (drift-prone) behaviour
	# rather than hard-fail.
	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)

	# Terrain3D has to be told about this camera too. `make_current()` only
	# changes what the viewport renders from; Terrain3D streams its regions —
	# and, since OW5, builds its COLLISION — around whichever camera it was
	# handed, which is still the frozen gameplay rig near spawn.
	#
	# Left unsaid, this survey moves its viewpoint and teleports the trainer far
	# away while the collision bubble stays pinned where the player spawned. It
	# worked while the world was 512m and a 256m radius happened to cover most
	# of it — the exact "it passed because nothing left the bubble" condition
	# that made the original fall-through bug invisible. The corridor is
	# 8192x2048m (OW5B-E), so that coincidence is gone and this is now load
	# bearing for every survey frame.
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	else:
		failures.append("no Terrain node with set_camera; region streaming and " +
			"collision are following the frozen gameplay rig, not these viewpoints")

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])

		_pose(camera, field, view)
		_place_actor(player, field, camera, view)
		if look != null:
			look.call("apply_time", str(view.get("time", "day")))
			# Proof the pin held: printed AFTER apply_time() and BEFORE the
			# settle/pose wait below, so a re-run can compare this against the
			# named viewpoint's own `time` and catch drift the moment it
			# starts, rather than only inferring it from a wrong-looking PNG.
			if look.has_method("time_of_day") and look.has_method("hour"):
				print("DIAG %s: time=%s hour=%.3f" % [
					name, str(look.call("time_of_day")), float(look.call("hour"))])
		else:
			failures.append("%s: no WorldLook node, so the time of day is whatever the scene was saved with" % name)

		# Physics frames, not process frames, because the trainer has to settle
		# onto the ground after being moved.
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
	# look_at fixes the heading; the pitch is then overridden so the horizon
	# lands where the composition wants it rather than wherever the target
	# happened to be. Heading is a content choice, pitch is a framing one.
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", DEFAULT_HORIZON))),
		camera.rotation.y,
		0.0
	)


## Stand the trainer in shot, for viewpoints that ask for one.
##
## The last survey had the player in none of the five exploration frames, so the
## critic's first and most important criterion — is the player readable against
## the ground? — could not be answered at all. It called that a survey-framing
## failure, correctly: a survey of a third-person game with no character in it
## is not a survey of the game.
##
## The trainer is moved rather than the camera, so the viewpoints stay exactly
## where they were and remain comparable with every earlier sheet.
func _place_actor(player: Node3D, field: RefCounted, camera: Camera3D, view: Dictionary) -> void:
	if player == null:
		return
	if not view.has("actor"):
		# Parked far out of shot rather than hidden: hiding it disables the body,
		# and a disabled body is a different scene from the one being surveyed.
		#
		# This used to be a fixed (9000, 200, 9000), nowhere near the baked
		# 512m world. That silently broke Terrain3D's own mesh streaming for
		# the rest of the scene — not just around the player — and was the
		# real cause of viewpoints 03 and 04 rendering as if the camera sat
		# below the terrain with nothing but the world-noise backdrop and
		# floating vegetation in frame: proven by re-running both with the
		# player left near the camera instead, which rendered correctly with
		# no other change. Parking straight down from the eye's own XZ keeps
		# the player inside the region Terrain3D is already streaming for
		# this shot, and 500m of dirt is more than enough to keep it out of
		# any authored viewpoint.
		var eye_xz: Vector2 = view["eye"]
		player.global_position = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) - 500.0, eye_xz.y)
		return

	var xz: Vector2 = view["actor"]
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + ACTOR_CLEARANCE, xz.y)
	# Facing away from the camera and slightly across it, which is how the game
	# actually frames them and what the key art's own panels show.
	var away := player.global_position - camera.global_position
	player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)


## The pitch that puts the true horizon at `fraction` of frame height.
##
## The horizon is the camera's own level plane at infinity, so for a pinhole
## camera it lands at exactly `0.5 - 0.5 * tan(pitch) / tan(fov/2)` down the
## frame. Solving that for pitch means the framing is stated as the thing being
## composed — "sky is 28% of this shot" — instead of as a rotation nobody can
## check. It also means the number the critic measures and the number in this
## file are the same number.
func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


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
