extends SceneTree

## Close-up frames of a rocky rise's slope material, for EV4-hillside-seam's
## local blind-judge pass.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_hillside.gd
##
## Neither tools/survey.gd's fixed five viewpoints nor tools/capture_paths.gd
## frame a rise's flank close enough or wide enough to judge whether the
## grass/soil/rock slope bands read as one coherent transition rather than a
## noisy patchwork — same reasoning as capture_paths.gd's own header, applied
## to `rises.peaks[1]` in data/config/terrain_playground.json (centre
## [-165,-150], radius 58).
##
## NOT peaks[0] (centre [140,-90]) — that is where the blind critic's
## "blotchy all over the dome" verdict came from, but it is also exactly
## where landmark.gd plants the stronghold silhouette (RISE_CENTRE + OFFSET,
## a flat-shaded cutout that fills the frame at any distance close enough to
## judge ground texture) and where paths.routes' "The Rise" ends — a first
## pass at these viewpoints landed on the silhouette and the path by
## accident and read neither texture nor material, just other content.
## peaks[1] has no landmark and no path anywhere near it, so it is the one
## that actually isolates the slope-driven bands `_control_for`/
## `_ground_colour` paint, which is what this item's fix touches.
##
## Viewpoints sit along one bearing from the peak's own centre toward the
## village, at increasing distance: a wide overview that shows the whole
## dome's silhouette, then progressively closer flank shots, ending at the
## outer edge where "a hard, unblended seam where grey rock cuts in at the
## hill's base" was reported (on peaks[0]; the mechanism is shared, so
## peaks[1] is where this item's fix gets judged instead).
##
## Same honest limits as tools/survey.gd: Compatibility renderer, software
## rendering, placeholder geometry.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/hillside"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const FOV := 70.0

const VIEWPOINTS := [
	{
		# Distant enough that the whole rise reads as one silhouette against
		# the sky — this is the "all over the dome" framing the critic used.
		"name": "dome-overview",
		"eye": Vector2(-54.0, -49.0), "eye_h": 5.0,
		"target": Vector2(-165.0, -150.0), "target_h": 16.0,
	},
	{
		# Standing near the base of the flank, looking up the slope — the
		# angle a player walking toward the rise actually sees it from.
		"name": "flank-lower",
		"eye": Vector2(-124.0, -113.0), "eye_h": 1.7,
		"target": Vector2(-154.0, -140.0), "target_h": 18.0,
	},
	{
		# Further up the same bearing, closer to the steepest part of the
		# flank where the rock band should be at its widest.
		"name": "flank-mid",
		"eye": Vector2(-139.0, -127.0), "eye_h": 1.7,
		"target": Vector2(-161.0, -147.0), "target_h": 28.0,
	},
	{
		# Right at the peak's own radius (58m from centre) — the outer edge
		# where the flank is meant to fade back to ordinary ground. This is
		# where the "hard cut" complaint should show up if it is still there.
		"name": "base-seam",
		"eye": Vector2(-122.0, -111.0), "eye_h": 1.5,
		"target": Vector2(-143.0, -130.0), "target_h": 6.0,
	},
	{
		# debug_control_probe.gd confirms the control map paints soil from
		# d~40 to d~58 along this exact bearing, but neither flank-lower nor
		# base-seam show any tan at all. Standing right on top of that band
		# (d=47, closest to the probe's own d=45/blend~0.99 sample) and
		# looking straight down + slightly ahead, to tell rendering from
		# framing.
		"name": "soil-band-direct",
		"eye": Vector2(-130.3, -118.4), "eye_h": 1.6,
		"target": Vector2(-134.0, -121.9), "target_h": 0.5,
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

	if look != null:
		look.call("apply_time", "day")

	if player != null:
		var park: Vector2 = VIEWPOINTS[0]["eye"]
		player.global_position = Vector3(park.x, field.height_at(park.x, park.y) - 500.0, park.y)
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO

	var written: Array[String] = []
	var failures: Array[String] = []

	for entry: Variant in VIEWPOINTS:
		var view: Dictionary = entry
		var name: String = str(view["name"])

		var eye_xz: Vector2 = view["eye"]
		var target_xz: Vector2 = view["target"]
		var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
		var target := Vector3(target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
		camera.global_position = eye
		camera.look_at(target, Vector3.UP)

		for i in 20:
			await physics_frame
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name)
			continue

		var path := "%s/%s.png" % [OUT_DIR, name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name, error])
			continue

		written.append(path)
		print("  %-22s -> %s" % [name, path])

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
