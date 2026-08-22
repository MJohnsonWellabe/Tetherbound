extends SceneTree

## PERF-2. Before/after evidence for Terrain3DMeshAsset LOD configuration
## (`vegetation.gd::_make_mesh_asset()`). Two views, matching the composition
## constraints named in `ralph/ACTIVE_GAME_PLAN.md` and OP21-01:
##
##   1. the approved lush pond-side pocket (dense trees/plants close in)
##   2. an open-field stretch with a long sightline (tests LOD pop/thinning
##      at distance, which a close-in pond shot cannot)
##
## Run once on unmodified `vegetation.gd` (BEFORE), then again after the LOD
## config lands (AFTER), with `--out=<dir>` picking the output folder so the
## two runs do not overwrite each other.
##
##   godot --headless --path . --script tools/capture_lod_before_after.gd -- --out=res://shots/perf2/before
##   godot --headless --path . --script tools/capture_lod_before_after.gd -- --out=res://shots/perf2/after
##
## Reuses `capture_pond_day_readability.gd`'s posing/preflight pattern
## (baked-ground + framebuffer-luma gating) rather than a fixed frame count,
## so a capture is never taken while Terrain3D is still streaming in the
## region under the camera.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const READY_TIMEOUT_MS := 300_000
const FOV := 70.0
const BAKE_HEIGHT_TOLERANCE_M := 0.35
const SAMPLE_COLUMNS := 32
const SAMPLE_ROWS := 18
const NONBLANK_P99_LUMA := 0.15
const NONBLANK_SPREAD := 0.10
const CONSECUTIVE_GOOD_FRAMES := 2

var _out_dir := "res://shots/perf2/before"


func _init() -> void:
	_run()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	_clear_pngs(_out_dir)

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
		_fail("world did not finish standing up within %dms" % READY_TIMEOUT_MS)
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

	var field: RefCounted = HEIGHTFIELD.new()

	var views: Array[Dictionary] = [
		{
			"name": "pond-lush-pocket",
			"eye": pond + Vector2(20.0, 14.0),
			"target": pond + Vector2(-4.0, -6.0),
			"horizon": 0.30,
		},
		{
			"name": "open-field-long-sightline",
			"eye": pond + Vector2(5.0, -85.0),
			"target": pond + Vector2(0.0, -220.0),
			"horizon": 0.40,
		},
	]
	for view: Dictionary in views:
		_pose(camera, field, view, water_level)
		if terrain != null and terrain.has_method("set_camera"):
			terrain.call("set_camera", camera)
		var image := await _wait_for_capture_preflight(terrain, camera, field, view)
		if image == null:
			_fail("%s did not produce a complete rendered terrain frame within %dms" % [
				view["name"], READY_TIMEOUT_MS,
			])
			return
		var path := "%s/%s.png" % [_out_dir, view["name"]]
		if image.save_png(path) != OK:
			_fail("could not save %s" % path)
			return
		print("  %s -> %s" % [view["name"], path])
	print("[lod-before-after] capture complete: %s" % _out_dir)
	quit(0)


## PERF-2: a fixed generous settle (not the stricter "N consecutive good
## frames" spin `capture_pond_day_readability.gd` uses) -- this box runs
## several concurrent Ralph lanes' Godot processes, and under that
## contention the stricter loop stretched a two-view capture past 15
## minutes with nothing to show for it. Still asserts the baked-ground and
## non-blank-frame checks once at the end, so a capture that genuinely never
## finished streaming still fails loudly instead of silently saving a black
## frame.
const SETTLE_FRAMES := 240


func _wait_for_capture_preflight(terrain: Node, camera: Camera3D, field: RefCounted, view: Dictionary) -> Image:
	for i in SETTLE_FRAMES:
		await physics_frame
	if not _baked_ground_matches(terrain, field, view, camera):
		return null
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var metrics := _frame_luma_metrics(image)
	if float(metrics.get("p99", 0.0)) < NONBLANK_P99_LUMA \
			or float(metrics.get("spread", 0.0)) < NONBLANK_SPREAD:
		return null
	return image


func _baked_ground_matches(terrain: Node, field: RefCounted, view: Dictionary, camera: Camera3D) -> bool:
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
	for anchor: Dictionary in anchors:
		var at: Vector2 = anchor["at"]
		var baked := float(data.call("get_height", Vector3(at.x, 0.0, at.y)))
		var expected := float(field.height_at(at.x, at.y))
		if is_nan(baked) or is_nan(expected) or absf(baked - expected) > BAKE_HEIGHT_TOLERANCE_M:
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
		if _find_named(world, "PondSurface") != null:
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


func _pose(camera: Camera3D, field: RefCounted, view: Dictionary, water_level: float) -> void:
	var eye_xz: Vector2 = view["eye"]
	var target_xz: Vector2 = view["target"]
	var eye_y: float = maxf(float(field.height_at(eye_xz.x, eye_xz.y)) + 1.8, water_level + 1.7)
	camera.global_position = Vector3(eye_xz.x, eye_y, eye_xz.y)
	camera.look_at(Vector3(target_xz.x, float(field.height_at(target_xz.x, target_xz.y)), target_xz.y), Vector3.UP)
	var half := tan(deg_to_rad(FOV) * 0.5)
	camera.rotation = Vector3(-atan((0.5 - float(view["horizon"])) * 2.0 * half), camera.rotation.y, 0.0)


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


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
