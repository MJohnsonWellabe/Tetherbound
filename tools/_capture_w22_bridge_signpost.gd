extends SceneTree

## W22-BRIDGE-SIGNPOST-0904 evidence: the signpost stands and the South
## Bridge approach, from ONE world load.
##
## `docs/prompts/74-ART-REFERENCE-owner-boards-for-meshy.md` §7 asks for a
## before/after on the same stands for two separate objects -- the signpost
## (`scripts/world/signpost.gd`) and the bridge deck/rail + the checkpoint
## dressing (`scripts/world/gated_crossing.gd`, `south_bridge.gd`). A full
## software-GL world capture costs 20-50 minutes per load in the CI
## container, so this harness shoots both sets from a single load rather
## than running `tools/_capture_band1_signpost_legibility.gd` and a second
## bridge tool back to back. The signpost poses are that tool's OWN
## `VIEWPOINTS`, read from it rather than copied, so the two cannot drift.
##
##   xvfb-run -a -s "-screen 0 1280x800x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_w22_bridge_signpost.gd [-- --stands=a,b --out=res://shots/w22/after]
##
## Same honest limits as tools/capture_wayfinding.gd: Compatibility renderer,
## software rendering. Never `--headless` together with a rendering driver.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SIGNPOST_TOOL := preload("res://tools/_capture_band1_signpost_legibility.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const DEFAULT_OUT_DIR := "res://shots/w22/world"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 20
const ACTOR_CLEARANCE := 0.4
const PARK_DISTANCE := 12.0
const FOV := 70.0
const DEFAULT_HORIZON := 0.30

## The South Bridge crossing centre is (8, 1330) with the village to the
## north (smaller z); the locked leaf stands at local x = -8.5 (world z =
## 1321.5) and the checkpoint archway half a metre nearer the village. The
## crossing's local +z maps to world -x.
const BRIDGE_VIEWPOINTS := [
	{
		# The played stand `ralph/reports/GATE2-EVIDENCE-0903/JUDGE.md` graded
		# the bridge on (`G2-S05-0755-objective`): the player stood at
		# (9.66, 1319.38), two metres in front of the leaf, and the gameplay
		# camera hung behind and above. Approximated as a third-person pose
		# with the trainer standing where the trace put him.
		"name": "bridge-approach-played",
		"eye": Vector2(9.9, 1313.6), "eye_h": 2.6,
		"target": Vector2(8.0, 1321.5), "target_h": 1.5,
		"horizon": 0.42, "fov": 62.0,
		"actor": Vector2(9.66, 1319.38),
	},
	{
		# `tools/_capture_band1_places.gd`'s own `place5-bridge-approach`, the
		# posed survey stand at the gully edge.
		"name": "place5-bridge-approach",
		"eye": Vector2(-20.0, 1318.0), "eye_h": 2.2,
		"target": Vector2(8.0, 1330.0), "target_h": 2.0,
		"horizon": 0.30,
		"actor": Vector2(-17.0, 1315.0),
	},
	{
		# Close on the checkpoint from the road's own shoulder, village side:
		# the archway, whatever stands in front of it, and the near rail
		# running away toward the far bank.
		"name": "bridge-checkpoint-shoulder",
		"eye": Vector2(12.4, 1312.0), "eye_h": 1.8,
		"target": Vector2(7.5, 1323.0), "target_h": 1.3,
		"horizon": 0.40, "fov": 62.0,
		"actor": Vector2(6.0, 1311.0),
	},
	{
		# The deck itself, from the far landing looking back toward the
		# checkpoint: the plank seams and both rails at reading distance, with
		# nothing but the crossing in frame.
		"name": "bridge-deck-far-side",
		"eye": Vector2(7.3, 1341.5), "eye_h": 1.7,
		"target": Vector2(7.2, 1326.0), "target_h": 0.9,
		"horizon": 0.45, "fov": 62.0,
		"actor": Vector2(8.6, 1345.0),
	},
]

static var _out_dir: String = DEFAULT_OUT_DIR
static var _only: PackedStringArray = []


func _init() -> void:
	_run()


func _viewpoints() -> Array:
	var all: Array = []
	for entry: Variant in SIGNPOST_TOOL.VIEWPOINTS:
		all.append(entry)
	for entry: Variant in BRIDGE_VIEWPOINTS:
		all.append(entry)
	if _only.is_empty():
		return all
	var picked: Array = []
	for entry: Variant in all:
		if str((entry as Dictionary)["name"]) in _only:
			picked.append(entry)
	return picked


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stands="):
			_only = arg.substr("--stands=".length()).split(",", false)
		elif arg.begins_with("--out="):
			_out_dir = arg.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

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

	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	_hide_canvas_layers(world)

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain == null and world.get("_terrain") != null:
		terrain = world.get("_terrain") as Node
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	else:
		failures.append("no Terrain node with set_camera")

	for entry: Variant in _viewpoints():
		var view: Dictionary = entry
		var name: String = str(view["name"])
		camera.fov = float(view.get("fov", FOV))
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
		var path := "%s/%s.png" % [_out_dir, name]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name, error])
			continue
		written.append(path)
		var flat := _flatness(image)
		if flat < 0.01:
			failures.append("%s: frame is almost a single flat colour (spread %.4f)" % [name, flat])
		print("  %-28s spread %.3f -> %s" % [name, flat, path])

	print("")
	print("%d frames -> %s" % [written.size(), _out_dir])
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
	var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
	var target := Vector3(target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	if view.has("horizon"):
		camera.rotation = Vector3(
			_pitch_for_horizon(float(view["horizon"]), camera.fov), camera.rotation.y, 0.0)


func _place_actor(player: Node3D, field: RefCounted, camera: Camera3D, view: Dictionary) -> void:
	if player == null:
		return
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
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


func _pitch_for_horizon(fraction: float, fov: float) -> float:
	var half := tan(deg_to_rad(fov) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


func _hide_canvas_layers(node: Node) -> void:
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false
	for child in node.get_children():
		_hide_canvas_layers(child)


func _flatness(image: Image) -> float:
	var step := maxi(1, image.get_width() / 64)
	var lowest := Vector3(INF, INF, INF)
	var highest := Vector3(-INF, -INF, -INF)
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			var c := image.get_pixel(x, y)
			lowest = Vector3(minf(lowest.x, c.r), minf(lowest.y, c.g), minf(lowest.z, c.b))
			highest = Vector3(maxf(highest.x, c.r), maxf(highest.y, c.g), maxf(highest.z, c.b))
	return (highest - lowest).length()
