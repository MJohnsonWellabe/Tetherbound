extends SceneTree

## OP23-05/OP23-06 (owner ROG playtest, coordinator instruction 2026-08-23).
## Proves the passive clock now PROGRESSES rather than snapping, and that
## night has a floor a player can navigate by instead of crushing to black
## the instant it lands.
##
## Unlike tools/capture_night_light.gd (which calls apply_time("night") --
## an intentional exact snap, still correct for pinning a reproducible
## frame), this drives the SAME clock the real game runs: it sets
## WorldLook's own _elapsed_seconds to land on a target hour and calls its
## _apply_blended() directly (the private method _process() now calls every
## BLEND_INTERVAL seconds), so what gets rendered is exactly what a player
## would see standing at that viewpoint at that moment -- no shortcut that
## could hide a mismatch between what the smoke test drives and what a
## person on the ROG actually watches happen.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_day_night_transition.gd
##   python3 tools/frame_stats.py shots/day_night/*.png

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/day_night"
const SETTLE_FRAMES := 240
const SETTLE_AFTER_HOUR := 10
const FOV := 70.0

# One fixed viewpoint, walked through the whole day->dusk->night sweep so
# every frame is directly comparable. Reuses survey_band2's ranger-camp-close
# framing (close, ground clutter visible, a real test of "can you see to
# navigate") rather than a far horizon shot.
const EYE := Vector2(-250.0, 2266.0)
const EYE_H := 1.8
const TARGET := Vector2(-258.0, 2258.0)
const TARGET_H := 0.9
const HORIZON := 0.32

# Spans day(8) -> golden(18) -> night(24/0). Includes both sides of every
# keyframe crossing (17.9/18.1, 23.9/0.1) plus dark_from_hour (20.0) itself,
# since OP23-06 named nightfall specifically as the worst moment.
const HOURS := [8.0, 14.0, 17.5, 17.9, 18.1, 19.0, 20.0, 20.5, 22.0, 23.9, 0.1, 2.0]


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
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	if look == null:
		push_error("no WorldLook node; cannot drive time of day")
		quit(1)
		return

	# Pin AND freeze WorldWeather, same as tools/_capture_ground_and_sky.gd.
	# Left running, it rolls a new weather preset every 4-8 real seconds x60
	# (data/config/weather.json cycle_seconds_min/max = 240-480) on its own
	# real-time timer, independent of anything this tool drives. The initial
	# SETTLE_FRAMES alone, at ~2.4s per awaited software-rendered frame (see
	# tools/_capture_ground_and_sky.gd's own measured budget), can exceed that
	# window before the first hour is even shot, and the sweep's later hours
	# certainly do. "cloudy" -- the heaviest-weighted non-clear preset -- sets
	# sky top/horizon colour to #5f7386/#9aabb5, a flat grey-blue: the exact
	# look the hour-17.5/17.9/18.1 frames showed instead of golden's warm
	# amber, without one line here ever being touched. This was never a
	# blend-math bug in world_look.gd; it was uncontrolled weather layered on
	# top of a correct blend by a node this tool never told to hold still.
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)

	if player != null:
		# Park far off to the side AND above ground, not straight down at
		# -500m: a body that deep reads as fully submerged to water.gd, which
		# ramps a red drowning vignette over the whole frame (this is exactly
		# what produced the crimson hour-22/23.9/0.1/2.0 frames judged blind
		# on 2026-08-29 -- see ralph/reports/JUDGE-VISUAL-2026-08-29.md and
		# archive/ralph/DONE.md's SURVEY_BAND2 entry). Parked far away in XZ too so it
		# throws no shadow into the framed viewpoint.
		var far_xz := EYE + Vector2(5000.0, 5000.0)
		player.global_position = Vector3(far_xz.x, field.height_at(far_xz.x, far_xz.y) + 1.0, far_xz.y)

	var eye_ground: float = field.height_at(EYE.x, EYE.y)
	var target_ground: float = field.height_at(TARGET.x, TARGET.y)
	var eye := Vector3(EYE.x, eye_ground + EYE_H, EYE.y)
	var target := Vector3(TARGET.x, target_ground + TARGET_H, TARGET.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(_pitch_for_horizon(HORIZON), camera.rotation.y, 0.0)

	var written: Array[String] = []
	var cycle: RefCounted = look.get("_cycle")
	var length: float = 600.0
	if cycle != null:
		length = float(cycle.get("day_length_seconds"))

	for hour: float in HOURS:
		var elapsed: float = (hour / 24.0) * length
		look.set("_elapsed_seconds", elapsed)
		look.call("_apply_blended", hour)
		for i in SETTLE_AFTER_HOUR:
			await physics_frame
		await RenderingServer.frame_post_draw
		written.append(await _shoot("hour-%05.2f" % hour, hour))

	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering (D06/D01) -- see tools/survey.sh's own caveat.")
	quit(0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


func _shoot(name: String, hour: float) -> String:
	var image: Image = get_root().get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	image.save_png(path)
	print("  %-14s (hour %5.2f) -> %s" % [name, hour, path])
	return path
