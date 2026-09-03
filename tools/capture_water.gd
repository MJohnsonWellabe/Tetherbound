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
## archive/ralph/DONE.md).
##
## Same conventions as tools/survey.gd: fixed named viewpoints, XZ plus a
## height above the baked ground, horizon placed as a stated fraction of
## frame. Same honest limits too — llvmpipe software rendering, trustworthy
## for composition, colour and shape, silent about frame rate.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/gate_a/water"

const READY_TIMEOUT_FRAMES := 240
const POSE_FRAMES := 6
## T1-SKY: was 4. A same-run pixel check (sky-only patch, so terrain shadow
## cannot explain it) found the first two of four viewpoints rendering
## measurably darker than the last two -- sky avg RGB (21,24,24) and
## (67,74,75) against (130,133,128) and (114,139,148) -- despite every
## viewpoint sharing the identical frozen "day" state. Not a time-of-day
## bug (the clock is pinned; see the freeze-once comment below) but a
## render-state warm-up one: this tool repositions the camera by large XZ
## jumps between viewpoints, and 4 frames is far stingier than the 15
## tools/_capture_ground_and_sky.gd budgets for the same kind of jump
## (its own ARRIVE_FRAMES/REFRAME_FRAMES) to let Terrain3D's region stream
## and the sun's shadow map catch up. Matched to that proven budget.
const SETTLE_AFTER_MOVE := 15
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
	# Terrain3D keeps its own camera reference for region/LOD preparation. The
	# authored gameplay rig is still parked at spawn, hundreds of metres from
	# the relocated pond, so making this capture camera current is not enough:
	# without the explicit handoff the pond terrain stays prepared around spawn,
	# leaving the remote site incomplete while the water surface remains visible.
	var terrain: Node = world.get("_terrain") as Node
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)

	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	# Evidence frames must be comparable across runs. WorldWeather randomises
	# its later cycle, and a long software-rendered world build can consume a
	# meaningful part of that clock before the first capture.
	#
	# FREEZE-ONCE, same as tools/_capture_ground_and_sky.gd: apply_time()/
	# set_weather() are ordinary direct method calls that write node
	# properties immediately, not through a per-frame tween, so they do not
	# need a live _process to take effect. A pin that is never frozen wears
	# off across a multi-viewpoint pass -- WorldLook's own passive clock kept
	# advancing between this call and the shutter, which is why every frame
	# from this tool came back in a dusk/night wash regardless of the
	# per-view "time" requested (judged blind in
	# ralph/reports/JUDGE-VISUAL-2026-08-29.md, subject 6).
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.call("apply_time", "day")
		look.set_process(false)
		look.set_physics_process(false)
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	var water_level := float(terrain_config.get("water", {}).get("level", 0.0))

	# T1-SKY: raising SETTLE_AFTER_MOVE to 15 above closed most, not all, of
	# the warm-up gap -- water-01 (the FIRST viewpoint shot after boot) still
	# measured a sky-only patch at RGB(53,59,60) against water-02/03/04's
	# 130-150 range, even though every viewpoint shares the identical frozen
	# "day" state. The first-ever shadow-map/Terrain3D-stream population
	# after a fresh scene boot appears to want more settle than a later
	# camera jump between two already-warm viewpoints does. One extra
	# one-time wait here, before the loop's own per-viewpoint settle, rather
	# than raising SETTLE_AFTER_MOVE further for every viewpoint.
	for i in 30:
		await physics_frame

	var failures: Array[String] = []
	for entry: Variant in viewpoints:
		var view: Dictionary = entry
		var name: String = str(view["name"])
		_pose(camera, field, view, water_level)
		_place_actor(player, field, camera, view)
		if weather != null and weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
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


func _pose(camera: Camera3D, field: RefCounted, view: Dictionary, water_level: float) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	# The heightfield returns the pond BED inside the water footprint. The old
	# across-pond view added eye height to that submerged bed, placing the
	# camera at/below the surface (the resulting frame visibly bisected the
	# image at the waterline and looked like a lighting failure). A pond survey
	# camera is a standing player's eye and must never be submerged.
	var sampled_eye_y: float = float(field.call("height_at", eye_xz.x, eye_xz.y)) + float(view["eye_h"])
	var eye_y: float = maxf(sampled_eye_y, water_level + 1.7)
	var eye := Vector3(eye_xz.x, eye_y, eye_xz.y)
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
		# STRANDED-P3 (see tools/survey_band2.gd's _place_actor and
		# tools/_capture_day_night_transition.gd): -500m straight down is
		# read by water.gd as fully submerged -- head depth below the water
		# surface has no floor -- so a body parked that far under a pond
		# viewpoint can ramp the drowning vignette across the whole capture.
		# Park far off to the side in XZ AND above ground instead, so it is
		# out of frame without tripping the water-hazard check.
		var eye_xz: Vector2 = view["eye"]
		var far_xz := eye_xz + Vector2(5000.0, 5000.0)
		player.global_position = Vector3(far_xz.x, field.height_at(far_xz.x, far_xz.y) + 1.0, far_xz.y)
		return
	var xz: Vector2 = view["actor"]
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + 0.4, xz.y)
	var away := player.global_position - camera.global_position
	player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)
