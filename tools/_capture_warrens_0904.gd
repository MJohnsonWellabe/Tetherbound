extends SceneTree

## W07-WARRENS-0904 (CL-O7 / CL-E8): the Burrow Warrens AS A PLAYER SEES IT.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_capture_warrens_0904.gd -- --label=before
##
## Owner, twice, on hardware: "Burrow warrens looks terrible." Four prior blind
## passes judged the guardian; none judged the room. These five stands are the
## ROOM, on the walked path `tests/smoke_warrens.gd` proves is walkable, at eye
## height, by day, with the trainer three metres ahead of the camera as the
## rubric's 1.80 m ruler and NO torch -- `scripts/player/torch.gd` only lights
## when the world's own `is_dark()` is true, so by day a player in this cave
## sees exactly the authored lights and nothing else. That is the state the
## owner judged, so it is the state this file photographs.
##
## The same five stands are reused, unchanged, for every round (`--label=`
## picks the output subdirectory), so a before/after pair is the same camera
## looking at the same metres. Each stand also samples the RenderingServer's
## own draw-call / primitive / object monitors the way
## `tools/perf_render_stats.gd` does (that tool has no Warrens view and is not
## this lane's file), so the perf order-of-magnitude check rides on the same
## frames rather than a second render.
##
## Frame numbers decided BEFORE the first render (AGENT_WORKFLOW §7):
## luminance p5 / p50 / p95, the dark fraction (Y < 40) and the bright
## fraction (Y > 180) per frame, and for the entry stand the median of the
## mouth crop against the frame median. Printed and written to `stats.txt`
## beside the frames.
##
## Never `--headless` with a rendering driver. Software GL: trust composition,
## silhouette, colour relationships and value structure; not fine lighting.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_ROOT := "res://shots/warrens_0904"

const SETTLE_FRAMES := 240
const STAND_SETTLE_FRAMES := 30
const POSE_FRAMES := 4
const PERF_SAMPLE_FRAMES := 10
const FOV := 70.0
const EYE_H := 1.7
## The trainer stands this far ahead of the camera along the view line -- the
## third-person distance a player actually plays at inside this cave
## (`burrow_warrens.gd::INTERIOR_PROFILE.distance` is 2.6).
const PLAYER_LEAD_M := 3.0

## Cave-local metres: x lateral, +z into the hill. `outside: true` stands on the
## meadow (the world's ground), everything else stands on the cave floor (the
## warrens' own `ground_height_at`). Chambers, for reference: mouth z 1..11,
## hall z 16..28 (x -7..7), den z 33..47 (x -8..8), vault x 11..19 at z 40.
const STANDS := [
	{
		# The approach: the mound and its mouth from the apron, the way the
		# road brings you to it.
		"name": "01-entry-mouth", "outside": true,
		"eye": Vector2(0.0, -15.0), "target": Vector2(0.0, 4.0), "target_h": 1.6,
	},
	{
		# Just inside the mouth, looking down the first passage into the hall.
		"name": "02-first-chamber",
		"eye": Vector2(0.0, 2.0), "target": Vector2(0.0, 21.0), "target_h": 1.2,
	},
	{
		# The hall's far end, looking through the den passage: the approach to
		# the guardian.
		"name": "03-approach-to-guardian",
		"eye": Vector2(0.0, 23.5), "target": Vector2(0.0, 42.0), "target_h": 1.2,
	},
	{
		# Inside the den doorway, aimed at the guardian's own body.
		"name": "04-guardian-chamber", "aim_guardian": true,
		"eye": Vector2(-1.0, 34.5), "target": Vector2(3.0, 44.0), "target_h": 1.2,
	},
	{
		# Back in the mouth chamber, walking out toward daylight.
		"name": "05-exit",
		"eye": Vector2(0.0, 9.5), "target": Vector2(0.0, -14.0), "target_h": 1.4,
	},
]

var _label := "unlabelled"
var _only: Array[String] = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--label="):
			_label = a.substr("--label=".length())
		elif a.begins_with("--stands="):
			for s in a.substr("--stands=".length()).split(",", false):
				_only.append(s.strip_edges())
	_run()


func _run() -> void:
	var out_dir := "%s/%s" % [OUT_ROOT, _label]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var warrens: Node3D = world.get_node_or_null(^"BurrowWarrens") as Node3D
	if warrens == null:
		push_error("no BurrowWarrens in the scene")
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

	# Day, clear, frozen -- the same discipline capture_warrens_63.gd learned
	# the hard way (its header records the dusk/sunset/red-vignette rounds).
	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})
		look.call("apply_time", "day")

	# The trainer is the ruler and stays IN frame, frozen where a player would
	# be standing, so streaming (which follows the player) and scale agreement
	# are both honest.
	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player != null:
		player.set_physics_process(false)
		player.set_process(false)
		player.velocity = Vector3.ZERO

	var stats_lines: Array[String] = []
	stats_lines.append("W07-WARRENS-0904 capture '%s'  driver=%s adapter=%s" % [
		_label, DisplayServer.get_name(), RenderingServer.get_video_adapter_name()])
	stats_lines.append("%-26s %5s %5s %5s %7s %7s %10s %12s %8s" % [
		"stand", "p5", "p50", "p95", "dark%", "bright%", "draws", "prims", "objects"])

	var written: Array[String] = []
	var failures: Array[String] = []
	for entry: Variant in STANDS:
		var stand: Dictionary = entry
		var name_value := str(stand["name"])
		if not _only.is_empty() and not _only.has(name_value):
			continue
		var outside := bool(stand.get("outside", false))
		var eye := _point(world, warrens, stand["eye"] as Vector2, EYE_H, outside)
		var target := _point(world, warrens, stand["target"] as Vector2,
			float(stand.get("target_h", 1.2)), outside)
		if bool(stand.get("aim_guardian", false)):
			var guardian: Node3D = warrens.call("guardian") as Node3D
			if guardian != null and is_instance_valid(guardian):
				target = guardian.global_position + Vector3.UP * 0.6

		if player != null:
			var flat := target - eye
			flat.y = 0.0
			var dir := flat.normalized() if flat.length() > 0.01 else Vector3.FORWARD
			var stand_at := eye + dir * PLAYER_LEAD_M
			var floor_y: float = float(world.call("ground_height_at", stand_at.x, stand_at.z)) \
				if outside else float(warrens.call("ground_height_at", stand_at.x, stand_at.z))
			player.global_position = Vector3(stand_at.x, floor_y + 0.05, stand_at.z)
			player.visible = true
			var model: Node3D = player.get("_model") as Node3D
			if model != null:
				# `player_controller.gd::_face()`: yaw = atan2(dir.x, dir.z).
				model.rotation.y = atan2(dir.x, dir.z)

		camera.global_position = eye
		camera.look_at(target, Vector3.UP)
		for i in STAND_SETTLE_FRAMES:
			await physics_frame
		if look != null:
			if look.has_method("set_weather"):
				look.call("set_weather", {})
			look.call("apply_time", "day")
		for i in POSE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			failures.append("%s: viewport returned no image" % name_value)
			continue
		var path := "%s/%s.png" % [out_dir, name_value]
		var error := image.save_png(path)
		if error != OK:
			failures.append("%s: save_png failed (%d)" % [name_value, error])
			continue
		written.append(path)

		var draws := 0.0
		var prims := 0.0
		var objs := 0.0
		for i in PERF_SAMPLE_FRAMES:
			await RenderingServer.frame_post_draw
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			objs += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		var n := float(PERF_SAMPLE_FRAMES)

		var lum := _luminance_stats(image)
		var line := "%-26s %5d %5d %5d %6.1f%% %6.1f%% %10.0f %12.0f %8.0f" % [
			name_value, lum["p5"], lum["p50"], lum["p95"], lum["dark"] * 100.0,
			lum["bright"] * 100.0, draws / n, prims / n, objs / n]
		if name_value == "01-entry-mouth":
			line += "   mouth-crop median %d vs frame %d" % [_crop_median(image), lum["p50"]]
		stats_lines.append(line)
		print("  %-26s -> %s" % [name_value, path])
		print("  " + line)

	var stats_path := "%s/stats.txt" % out_dir
	var f := FileAccess.open(stats_path, FileAccess.WRITE)
	if f != null:
		for line in stats_lines:
			f.store_line(line)
		f.close()
	print("")
	for line in stats_lines:
		print(line)
	print("")
	print("%d frames -> %s" % [written.size(), out_dir])
	print("Software rendering. These are for an independent critic, not for this file's author.")
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


## A stand point. Interior points stand on the cave floor (the warrens' own
## `ground_height_at`, which answers the floor anywhere in the footprint);
## exterior points stand on the meadow (the world's).
func _point(world: Node, warrens: Node3D, flat: Vector2, height: float, outside: bool) -> Vector3:
	var at: Vector3 = warrens.to_global(Vector3(flat.x, 0.0, flat.y))
	var floor_y: float = float(world.call("ground_height_at", at.x, at.z)) \
		if outside else float(warrens.call("ground_height_at", at.x, at.z))
	return Vector3(at.x, floor_y + height, at.z)


## Rec.601 luminance percentiles and tails on a 4x downscaled copy -- the
## histogram shape is what is being measured, not any one pixel.
func _luminance_stats(source: Image) -> Dictionary:
	var image := source.duplicate() as Image
	image.resize(source.get_width() / 4, source.get_height() / 4, Image.INTERPOLATE_BILINEAR)
	var values := PackedInt32Array()
	var dark := 0
	var bright := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			var l := int(round((0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * 255.0))
			values.append(l)
			if l < 40:
				dark += 1
			if l > 180:
				bright += 1
	values.sort()
	var n := values.size()
	return {
		"p5": values[int(n * 0.05)], "p50": values[int(n * 0.5)], "p95": values[int(n * 0.95)],
		"dark": float(dark) / float(n), "bright": float(bright) / float(n),
	}


## The median luminance of the central 20% x 20% of the frame -- at the entry
## stand the camera is aimed at the mouth, so this is the hole itself.
func _crop_median(source: Image) -> int:
	var w := source.get_width()
	var h := source.get_height()
	var values := PackedInt32Array()
	for y in range(int(h * 0.4), int(h * 0.6), 2):
		for x in range(int(w * 0.4), int(w * 0.6), 2):
			var c := source.get_pixel(x, y)
			values.append(int(round((0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * 255.0)))
	values.sort()
	return values[values.size() / 2] if values.size() > 0 else 0
