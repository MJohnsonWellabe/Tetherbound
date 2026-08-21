extends SceneTree

## Capture EV5's water feature — the pond, the stream, the reeds — for the
## blind visual critic.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_water.gd
##
## NEVER with --headless: that silently swaps in the Dummy rendering driver
## and the capture hangs forever on frame_post_draw (see RENDER-PERF-DIAG in
## ralph/DONE.md).
##
## Same conventions as tools/survey.gd: fixed named viewpoints, XZ plus a
## height above the baked ground, horizon placed as a stated fraction of
## frame. Same honest limits too — llvmpipe software rendering, trustworthy
## for composition, colour and shape, silent about frame rate.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/gate_a/water"

const READY_TIMEOUT_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 4
const FOV := 70.0

func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_clear_pngs(OUT_DIR)

	var terrain_config: Dictionary = HEIGHTFIELD.load_config()
	var viewpoints := _viewpoints(terrain_config)
	if viewpoints.is_empty():
		push_error("terrain config has no current pond/stream capture anchors")
		quit(1)
		return

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

	var world: Node = packed.instantiate()
	root.add_child(world)
	if not await _wait_for_site(world):
		push_error("pond/ranger site did not finish building within %d frames" % READY_TIMEOUT_FRAMES)
		quit(1)
		return

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

	var failures: Array[String] = []
	for entry: Variant in viewpoints:
		var view: Dictionary = entry
		var name: String = str(view["name"])
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
		var path := "%s/%s.png" % [OUT_DIR, name]
		if image.save_png(path) != OK:
			failures.append("%s: save_png failed" % name)
			continue
		print("  %-26s -> %s" % [name, path])

	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## Keep the capture tied to the authored feature, not to the coordinates it had
## before OW5D moved the pond group. Offsets are deliberate compositions; the
## anchors come from the same config the live water and terrain read.
func _viewpoints(config: Dictionary) -> Array[Dictionary]:
	var water: Dictionary = config.get("water", {})
	var centre_spec: Array = water.get("pond_centre", [])
	if centre_spec.size() < 2:
		return []

	var pond := Vector2(float(centre_spec[0]), float(centre_spec[1]))
	var shore_out := Vector2(0.0, -1.0)
	var near_shore := _shore_point(config, pond, shore_out)
	var west_shore := _shore_point(config, pond, Vector2(-1.0, 0.0))

	# The four questions bible §15 asks: close shoreline transition, whole
	# surface readability, stream-in-land readability, and arrival payoff.
	return [
		{
			"name": "water-01-bank-closeup",
			# Stand three metres outside the actual waterline and look across it.
			# The former east-bank eye is now inside the relocated tree belt.
			"eye": near_shore + shore_out * 3.0, "eye_h": 1.8,
			"target": near_shore - shore_out * 10.0, "target_h": -1.5,
			"time": "day", "horizon": 0.25,
		},
		{
			"name": "water-02-across-pond",
			"eye": pond + Vector2(-27.0, 20.0), "eye_h": 3.0,
			"target": pond + Vector2(40.0, -26.0), "target_h": 2.0,
			"time": "day", "horizon": 0.3,
		},
		{
			"name": "water-03-west-bank",
			# The authored stream points intentionally remain at the pre-OW5D
			# site, hundreds of metres away. Keep this relocation harness honest:
			# its third view now verifies the current pond's opposite bank.
			"eye": west_shore + Vector2(-5.0, 0.0), "eye_h": 4.5,
			"target": pond + Vector2(30.0, 0.0), "target_h": -1.0,
			"time": "day", "horizon": 0.2,
		},
		{
			"name": "water-04-approach",
			# One bend earlier on the same pond circuit: the first long view
			# down the cleared route, rather than through the east-bank woods.
			"eye": pond + Vector2(5.0, -85.0), "eye_h": 3.5,
			"target": pond, "target_h": 0.0,
			"time": "day", "horizon": 0.24,
		},
	]


func _shore_point(config: Dictionary, pond: Vector2, out_dir: Vector2) -> Vector2:
	var field: RefCounted = HEIGHTFIELD.new(config)
	var level := float(config.get("water", {}).get("level", 0.0))
	var direction := out_dir.normalized()
	for distance in range(1, 251):
		var candidate := pond + direction * float(distance)
		if field.height_at(candidate.x, candidate.y) >= level:
			return candidate
	return pond + direction * 80.0


## playground_world.gd builds the water and settlement after asynchronous
## terrain/scatter work. Wait for the actual evidence subjects instead of a
## fixed frame count that can be too early under load and wasteful when idle.
func _wait_for_site(world: Node) -> bool:
	for i in READY_TIMEOUT_FRAMES:
		if (_find_named(world, "PondSurface") != null
				and _find_prefix(world, "ranger_station_") != null):
			return true
		await physics_frame
	return false


func _find_named(node: Node, wanted: String) -> Node:
	if str(node.name) == wanted:
		return node
	for child in node.get_children():
		var found := _find_named(child, wanted)
		if found != null:
			return found
	return null


func _find_prefix(node: Node, prefix: String) -> Node:
	if str(node.name).to_lower().begins_with(prefix):
		return node
	for child in node.get_children():
		var found := _find_prefix(child, prefix)
		if found != null:
			return found
	return null


## An evidence run must never silently inherit frames from an older layout.
## This removes only PNG products inside this harness's dedicated directory.
func _clear_pngs(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".png"):
			DirAccess.remove_absolute(ProjectSettings.globalize_path("%s/%s" % [path, entry]))
		entry = dir.get_next()
	dir.list_dir_end()


func _pose(camera: Camera3D, field: RefCounted, view: Dictionary) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye := Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) + float(view["eye_h"]), eye_xz.y)
	var target := Vector3(target_xz.x, field.height_at(target_xz.x, target_xz.y) + float(view["target_h"]), target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(
		_pitch_for_horizon(float(view.get("horizon", 0.3))),
		camera.rotation.y,
		0.0
	)


func _place_actor(player: Node3D, field: RefCounted, camera: Camera3D, view: Dictionary) -> void:
	if player == null:
		return
	if not view.has("actor"):
		# Parked straight down from the eye, inside the streamed region — see
		# tools/survey.gd's _place_actor for why never far outside the world.
		var eye_xz: Vector2 = view["eye"]
		player.global_position = Vector3(eye_xz.x, field.height_at(eye_xz.x, eye_xz.y) - 500.0, eye_xz.y)
		return
	var xz: Vector2 = view["actor"]
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + 0.4, xz.y)
	var away := player.global_position - camera.global_position
	player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)
