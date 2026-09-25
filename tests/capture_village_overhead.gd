extends SceneTree

## F01 / ACCEPTANCE §6.1: "the overhead road graph is no longer the old compact
## circle". An in-engine overhead plan of the village as the shipped build
## renders it: real terrain, painted road bands, houses, props and scatter,
## looked at straight down.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tests/capture_village_overhead.gd -- --capture-dir=/abs/out
##
## Two frames, both at midday with the clock frozen and clear weather:
##   village_overhead_village.png  -- orthographic, the settlement outline
##                                    (village_boundary.json) with margin
##   village_overhead_exit.png     -- orthographic, wider: the through-road
##                                    leaving the settlement toward the South
##                                    Bridge, which is ~1.3 km south (beyond
##                                    this frame; the road's heading is what
##                                    this one shows)
## This is a PLAN view for judging topology, not a gameplay camera: the HUD is
## hidden and distance fog is switched off for these frames only, because from
## 150 m up fog would grey out the very roads being judged. The player stands
## at the village centre so every streamed chunk around it is loaded.
##
## Inert by default (not a test_*.gd). Under --headless it cannot save images
## and exits 2.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BOUNDARY_PATH := "res://data/config/village_boundary.json"
const SETTLE_FRAMES := 600
const RENDER_FRAMES := 30
const CAMERA_HEIGHT_M := 150.0
const VILLAGE_MARGIN_M := 14.0
const EXIT_SIZE_M := 260.0
## The exit frame's centre is pulled this far south of the village centre, so
## the gate and the first stretch of the Lower Meadows spine are in shot.
const EXIT_SHIFT_Z_M := 80.0

var _capture_dir := ""


func _init() -> void:
	_run()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			_capture_dir = arg.trim_prefix("--capture-dir=")
	if _capture_dir.is_empty() or not _capture_dir.is_absolute_path():
		print("[village-overhead] FAIL --capture-dir must be an absolute path")
		quit(2)
		return
	if DisplayServer.get_name() == "headless":
		print("[village-overhead] FAIL needs a rendered run (no --headless)")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_capture_dir)

	var outline: Array = ((_json(BOUNDARY_PATH).get("outline", {}) as Dictionary).get("points", []) as Array)
	if outline.size() < 3:
		print("[village-overhead] FAIL no village outline in %s" % BOUNDARY_PATH)
		quit(1)
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for raw: Variant in outline:
		var p := Vector2(float(raw[0]), float(raw[1]))
		lo = lo.min(p)
		hi = hi.max(p)
	var centre := (lo + hi) * 0.5
	var span := maxf(hi.x - lo.x, hi.y - lo.y) + VILLAGE_MARGIN_M * 2.0

	await process_frame
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	var player := world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var y := float(world.call("ground_height_at", centre.x, centre.y)) + 1.0
		player.global_position = Vector3(centre.x, y, centre.y)
	for _i in SETTLE_FRAMES:
		await physics_frame
	if player != null:
		player.set_physics_process(false)

	var look := world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("set_clock_frozen", true)
		look.call("apply_time", "day")
	var weather := world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
	for child in world.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	var env_node := _find_environment(world)
	if env_node != null and env_node.environment != null:
		env_node.environment.fog_enabled = false
		env_node.environment.volumetric_fog_enabled = false

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = CAMERA_HEIGHT_M + 400.0
	world.add_child(camera)
	camera.current = true

	var shots := [
		{"file": "village_overhead_village.png", "centre": centre, "size": span},
		{"file": "village_overhead_exit.png",
			"centre": centre + Vector2(0.0, EXIT_SHIFT_Z_M), "size": EXIT_SIZE_M},
	]
	for shot: Dictionary in shots:
		var at: Vector2 = shot["centre"]
		camera.size = float(shot["size"])
		# Straight down, with world -Z (north) at the top of the frame.
		camera.global_transform = Transform3D(Basis.from_euler(Vector3(-PI * 0.5, 0.0, 0.0)),
			Vector3(at.x, CAMERA_HEIGHT_M, at.y))
		for _i in RENDER_FRAMES:
			await process_frame
		var image := root.get_viewport().get_texture().get_image()
		var path := _capture_dir.path_join(str(shot["file"]))
		var err := image.save_png(path)
		print("[village-overhead] CAPTURE %s centre=(%.1f,%.1f) size_m=%.1f err=%d" % [
			shot["file"], at.x, at.y, float(shot["size"]), err])
		if err != OK:
			quit(1)
			return
	print("[village-overhead] PASS captures=%d north_up=true" % shots.size())
	quit(0)


func _find_environment(node: Node) -> WorldEnvironment:
	if node is WorldEnvironment:
		return node as WorldEnvironment
	for child in node.get_children():
		var found := _find_environment(child)
		if found != null:
			return found
	return null


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
