extends SceneTree

## NONSHIPPING Gate A visual-evidence harness for daytime pond-route
## readability. It deliberately combines the player, a real wild creature,
## the traversable route, and the pond landmark in one frame; landscape-only
## views cannot answer whether shaded travel remains readable in play.
##
## The second frame is an exposed-path control. Both frames apply the named
## `day` preset after the complete world is ready, and write only under this
## harness's own output directory.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/gate_a/pond_day_readability"
const READY_TIMEOUT_MS := 300_000
const FOV := 70.0
const BAKE_HEIGHT_TOLERANCE_M := 0.35
const SAMPLE_COLUMNS := 32
const SAMPLE_ROWS := 18
## These are capture-integrity floors, not a visual-quality score. A valid day
## frame must contain rendered scene values rather than the near-zero buffer
## produced while Terrain3D is still preparing a remote region.
const NONBLANK_P99_LUMA := 0.15
const NONBLANK_SPREAD := 0.10
const CONSECUTIVE_GOOD_FRAMES := 2

var _preflight_only := false


func _init() -> void:
	_run()


func _run() -> void:
	# Godot keeps arguments after `--` in the user-argument list. Reading the
	# engine-argument list here would silently run a writing capture when a
	# coordinator explicitly requested preflight-only evidence.
	_preflight_only = OS.get_cmdline_user_args().has("--preflight-only")
	if not _preflight_only:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
		_clear_pngs(OUT_DIR)
	var config: Dictionary = HEIGHTFIELD.load_config()
	var pond_spec: Array = config.get("water", {}).get("pond_centre", [])
	if pond_spec.size() < 2:
		_fail("terrain config has no pond centre")
		return
	var pond := Vector2(float(pond_spec[0]), float(pond_spec[1]))
	var water_level := float(config.get("water", {}).get("level", 0.0))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		_fail("could not load Meadows scene")
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	if not await _wait_for_ready(world):
		_fail("world did not finish the pond/ranger site within %dms" % READY_TIMEOUT_MS)
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
	var terrain: Node = world.get("_terrain") as Node
	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
	if look != null:
		look.call("apply_time", "day")
	if not _assert_live_day_environment(world):
		return

	var field: RefCounted = HEIGHTFIELD.new()
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var director: Node = world.get_node_or_null(^"EncounterDirector")
	var route_actor := pond + Vector2(65.0, 42.0)
	_place_actor(player, field, route_actor, Vector2(-1.0, -0.4))
	# This is an ordinary spawned creature using the live encounter director and
	# installed roster. It exists only to make the frame test player-facing
	# silhouette/readability; it is never gameplay evidence or a new placement.
	var probe_wild: Node3D = null
	if director != null and director.has_method("spawn_wild"):
		var wild_xz := pond + Vector2(52.0, 32.0)
		probe_wild = director.call("spawn_wild", "mosshell", Vector3(
			wild_xz.x, field.height_at(wild_xz.x, wild_xz.y) + 0.2, wild_xz.y
		), {"level": 3, "name": "PondReadabilityProbeWild"}) as Node3D
	if probe_wild == null:
		_fail("could not create real pond wild for player-facing composition")
		return

	var views: Array[Dictionary] = [
		{
			"name": "day-route-player-wild-pond-landmark",
			"eye": pond + Vector2(69.0, 44.0),
			"target": pond + Vector2(3.0, 13.0),
			"horizon": 0.22,
			"actor": route_actor,
		},
		{
			"name": "day-exposed-path-control",
			"eye": pond + Vector2(5.0, -85.0),
			"target": pond,
			"horizon": 0.24,
			"actor": pond + Vector2(1.0, -81.0),
		},
	]
	for view: Dictionary in views:
		_pose(camera, field, view, water_level)
		_place_actor(player, field, view["actor"], Vector2(-1.0, -0.4))
		# Terrain3D begins preparing around the camera it is registered with.
		# Registering a fresh camera at the origin and moving it afterward was a
		# race: water/props could exist while the remote ground was still black.
		if terrain != null and terrain.has_method("set_camera"):
			terrain.call("set_camera", camera)
		if weather != null and weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		if look != null:
			look.call("apply_time", "day")
		if not _assert_live_day_environment(world):
			return
		var image := await _wait_for_capture_preflight(
			terrain, camera, field, view, player, probe_wild
		)
		if image == null:
			_fail("%s did not produce a complete rendered terrain frame within %dms" % [
				view["name"], READY_TIMEOUT_MS,
			])
			return
		if _preflight_only:
			print("[pond-day-readability] preflight passed: %s" % view["name"])
			continue
		var path := "%s/%s.png" % [OUT_DIR, view["name"]]
		if image.save_png(path) != OK:
			_fail("could not save %s" % path)
			return
		print("  %s -> %s" % [view["name"], path])
	print("[pond-day-readability] preflight complete" if _preflight_only else "[pond-day-readability] capture complete")
	quit(0)


## Capture proof has two independent parts. `Terrain3DData.get_height()` is the
## public baked-ground query used by the live world, so matching it to the
## analytical heightfield detects a stale local bake. The sampled framebuffer
## guard then catches a remote region that has not finished presenting yet.
func _wait_for_capture_preflight(
		terrain: Node, camera: Camera3D, field: RefCounted, view: Dictionary,
		player: Node3D, probe_wild: Node3D) -> Image:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	var good_frames := 0
	while Time.get_ticks_msec() < deadline:
		if not _baked_ground_matches(terrain, field, view, camera, player, probe_wild):
			await physics_frame
			continue
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var metrics := _frame_luma_metrics(image)
		print("[pond-day-readability] %s frame luma: p01=%.3f p99=%.3f spread=%.3f" % [
			view["name"], float(metrics.get("p01", 0.0)), float(metrics.get("p99", 0.0)),
			float(metrics.get("spread", 0.0)),
		])
		if float(metrics.get("p99", 0.0)) >= NONBLANK_P99_LUMA \
				and float(metrics.get("spread", 0.0)) >= NONBLANK_SPREAD:
			good_frames += 1
			if good_frames >= CONSECUTIVE_GOOD_FRAMES:
				return image
		else:
			good_frames = 0
		await process_frame
	return null


func _baked_ground_matches(
		terrain: Node, field: RefCounted, view: Dictionary, camera: Camera3D,
		player: Node3D, probe_wild: Node3D) -> bool:
	if terrain == null:
		_fail("capture has no Terrain3D node")
		return false
	var data: Object = terrain.get("data")
	if data == null or not data.has_method("get_height"):
		_fail("capture Terrain3D has no readable baked data")
		return false
	var anchors: Array[Dictionary] = [
		{"name": "camera", "at": Vector2(camera.global_position.x, camera.global_position.z)},
		{"name": "target", "at": view["target"]},
	]
	if player != null:
		anchors.append({"name": "player", "at": Vector2(player.global_position.x, player.global_position.z)})
	if probe_wild != null:
		anchors.append({"name": "wild", "at": Vector2(probe_wild.global_position.x, probe_wild.global_position.z)})
	for anchor: Dictionary in anchors:
		var at: Vector2 = anchor["at"]
		var baked := float(data.call("get_height", Vector3(at.x, 0.0, at.y)))
		var expected := float(field.height_at(at.x, at.y))
		if is_nan(baked) or is_nan(expected) or absf(baked - expected) > BAKE_HEIGHT_TOLERANCE_M:
			_fail("%s baked ground mismatch at (%.1f, %.1f): baked=%s expected=%s tolerance=%.2fm" % [
				anchor["name"], at.x, at.y,
				"NaN" if is_nan(baked) else "%.3f" % baked,
				"NaN" if is_nan(expected) else "%.3f" % expected,
				BAKE_HEIGHT_TOLERANCE_M,
			])
			return false
	return true


func _frame_luma_metrics(image: Image) -> Dictionary:
	if image == null or image.is_empty():
		return {}
	var samples: Array[float] = []
	for row in SAMPLE_ROWS:
		var y := mini(image.get_height() - 1, int((float(row) + 0.5) * image.get_height() / SAMPLE_ROWS))
		for column in SAMPLE_COLUMNS:
			var x := mini(image.get_width() - 1, int((float(column) + 0.5) * image.get_width() / SAMPLE_COLUMNS))
			var pixel := image.get_pixel(x, y)
			samples.append(pixel.r * 0.2126 + pixel.g * 0.7152 + pixel.b * 0.0722)
	samples.sort()
	if samples.is_empty():
		return {}
	var low := samples[int(floor(float(samples.size() - 1) * 0.01))]
	var high := samples[int(floor(float(samples.size() - 1) * 0.99))]
	return {"p01": low, "p99": high, "spread": high - low}


func _wait_for_ready(world: Node) -> bool:
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while Time.get_ticks_msec() < deadline:
		if _find_named(world, "PondSurface") != null and _find_prefix(world, "ranger_station_") != null:
			return true
		await physics_frame
	return false


func _find_named(node: Node, wanted: String) -> Node:
	if str(node.name) == wanted:
		return node
	for child: Node in node.get_children():
		var found := _find_named(child, wanted)
		if found != null:
			return found
	return null


func _find_prefix(node: Node, prefix: String) -> Node:
	if str(node.name).to_lower().begins_with(prefix):
		return node
	for child: Node in node.get_children():
		var found := _find_prefix(child, prefix)
		if found != null:
			return found
	return null


func _pose(camera: Camera3D, field: RefCounted, view: Dictionary, water_level: float) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye_y: float = maxf(float(field.height_at(eye_xz.x, eye_xz.y)) + 1.8, water_level + 1.7)
	camera.global_position = Vector3(eye_xz.x, eye_y, eye_xz.y)
	camera.look_at(Vector3(target_xz.x, float(field.height_at(target_xz.x, target_xz.y)), target_xz.y), Vector3.UP)
	var half := tan(deg_to_rad(FOV) * 0.5)
	camera.rotation = Vector3(-atan((0.5 - float(view["horizon"])) * 2.0 * half), camera.rotation.y, 0.0)


func _place_actor(player: Node3D, field: RefCounted, xz: Vector2, facing: Vector2) -> void:
	if player == null:
		return
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + 0.4, xz.y)
	player.rotation.y = atan2(facing.x, facing.y)


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


## Evidence must name the live renderer state, not merely the JSON a harness
## intended to apply. This catches a future ownership/override regression
## before a misleading screenshot is handed to a visual critic.
func _assert_live_day_environment(world: Node) -> bool:
	var holder: WorldEnvironment = world.get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	var env: Environment = holder.environment if holder != null else null
	if env == null:
		_fail("day capture has no live WorldEnvironment")
		return false
	var expected_colour := Color("#a8bccc")
	var valid := env.tonemap_mode == Environment.TONE_MAPPER_ACES \
		and is_equal_approx(env.tonemap_exposure, 0.6) \
		and env.ambient_light_source == Environment.AMBIENT_SOURCE_SKY \
		and is_equal_approx(env.ambient_light_energy, 1.5) \
		and env.ambient_light_color.is_equal_approx(expected_colour)
	if not valid:
		_fail("day environment readback mismatch: source=%d exposure=%.3f energy=%.3f colour=%s" % [
			env.ambient_light_source, env.tonemap_exposure, env.ambient_light_energy,
			str(env.ambient_light_color),
		])
		return false
	print("[pond-day-readability] day readback: source=SKY exposure=0.600 energy=1.500 colour=#a8bccc")
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
