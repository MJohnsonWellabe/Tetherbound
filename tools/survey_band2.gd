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
		# South Bridge -> Old Quarry leg: trailpup/meadowhart country. ROUND 2:
		# round 1's eye sat ~86m from the trailpup spawn centre and the critic
		# could not tell "creature, bush or rock apart" -- moved to ~39m, close
		# enough that a spawned trailpup should actually read as an animal.
		"name": "01-early-forest-day",
		"eye": Vector2(120.0, 1525.0), "eye_h": 1.8,
		"target": Vector2(150.0, 1550.0), "target_h": 1.0,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(128.0, 1533.0),
	},
	{
		# quarry_rim_overlook's own distant vista -- kept deliberately far,
		# it is meant to be an overview ("the whole quarry floor read from
		# above", macro-layout 3.2), not a close look at the props.
		"name": "02a-quarry-overlook-day",
		"eye": Vector2(350.0, 1720.0), "eye_h": 2.0,
		"target": Vector2(400.0, 1800.0), "target_h": 2.0,
		"time": "day", "horizon": 0.26,
	},
	{
		# ROUND 2, new: the quarry_station prop cluster and the lit pylon
		# line up close -- round 1's only quarry frame was the ~110m vista
		# above, so none of props.json's crates/barrels/pickaxe or the
		# pylons' own conduit cable (a real 11cm-radius CylinderMesh,
		# scripts/world/severed_spokes.gd -- not missing geometry, just
		# sub-pixel at 110m) were ever actually legible.
		"name": "02b-quarry-station-close-day",
		"eye": Vector2(390.0, 1791.0), "eye_h": 1.8,
		"target": Vector2(402.0, 1800.0), "target_h": 1.2,
		"time": "day", "horizon": 0.32,
	},
	{
		# ROUND 2: replaces round 1's ~85m road-view of the ranger camp,
		# which put every prop below a couple of pixels and read as "two
		# objects, no camp." Same distance capture_ranger_camp.gd already
		# proved legible for this exact cluster.
		"name": "03-ranger-camp-close-day",
		"eye": Vector2(-250.0, 2266.0), "eye_h": 1.8,
		"target": Vector2(-258.0, 2258.0), "target_h": 0.9,
		"time": "day", "horizon": 0.32,
	},
	{
		# The Burrow Warrens mouth, Band 2's required dungeon.
		"name": "04-warrens-mouth-day",
		"eye": Vector2(-390.0, 2440.0), "eye_h": 2.0,
		"target": Vector2(-420.0, 2470.0), "target_h": 2.5,
		"time": "day", "horizon": 0.28,
	},
	{
		# ROUND 2: retargeted onto one of the two new deadwood nodes
		# (harvest.json order 2004) instead of an arbitrary spine point --
		# round 1 showed bare grass with nothing identifiable in it, which
		# is the honest emptiness finding, but gave no read on whether the
		# content that IS there (this node, the duskhush spawn beside it)
		# is legible once you're actually near it.
		"name": "05-late-ridge-day",
		"eye": Vector2(60.0, 2955.0), "eye_h": 1.8,
		"target": Vector2(76.0, 2972.0), "target_h": 1.0,
		"time": "day", "horizon": 0.30,
		"actor": Vector2(66.0, 2961.0),
	},
	{
		# Same overlook as 02a, at night: the quarry's pylons are LIT (SD16,
		# old_quarry.json) so this is the frame that tests whether that
		# reads as intended after dark.
		"name": "06-quarry-overlook-night",
		"eye": Vector2(350.0, 1720.0), "eye_h": 2.0,
		"target": Vector2(400.0, 1800.0), "target_h": 2.0,
		"time": "night", "horizon": 0.26,
	},
	{
		# Same close camp framing as 03, at night -- duskhush (nocturnal)
		# lives on this stretch, and MQ2B's own checklist names day/night
		# readability.
		"name": "07-ranger-camp-close-night",
		"eye": Vector2(-250.0, 2266.0), "eye_h": 1.8,
		"target": Vector2(-258.0, 2258.0), "target_h": 0.9,
		"time": "night", "horizon": 0.32,
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
		# ROUND 2 fix: round 1 parked the body straight down (same XZ, -500m),
		# which round 1's critic likely caught as an unexplained "kite-shaped
		# shadow" intruding bottom-centre of 02/03/04 -- every actor-less
		# frame, and none of the frames that DID place an actor. A directional
		# light's shadow map does not reliably cull a caster on depth alone,
		# so a body straight under the eye can still throw a shadow onto
		# visible terrain even from 500m down. Parking far away in XZ as well
		# (not just deep) puts it outside the shadow frustum by any measure.
		var eye_xz: Vector2 = view["eye"]
		var far_xz := eye_xz + Vector2(5000.0, 5000.0)
		player.global_position = Vector3(far_xz.x, -500.0, far_xz.y)
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
