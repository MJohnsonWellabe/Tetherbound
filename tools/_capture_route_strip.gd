extends SceneTree
## KICKOFF (docs/acceptance/KICKOFF_RUN.md). The route strip: one frame every
## `--step` metres along the authored trail spine, at a walking player's eye
## height, looking the way the road goes. Every band, start to finish.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_capture_route_strip.gd -- --step=40 --bands=1,2,3,4,5
##
## NEVER with `--headless` and a real rendering driver (it hangs forever).
##
## Why this exists beside tools/survey.gd and the composition stands: every
## visual verdict to date was made from a handful of fixed stands, chosen by
## whoever was fixing something. The two bar questions ask about the game the
## player walks through, and the player walks the road. This is the road, at
## the player's own eye, at a fixed cadence nobody picked to flatter a fix.
## The blind judge answers the bars on these sheets (D73).
##
## Camera maths copied from tools/_capture_band1_composition.gd (itself from
## tools/survey.gd). The player is parked a few metres behind the eye on the
## same road so Terrain3D's player-following streaming bubble covers the shot,
## and the trainer is in frame as the 1.80 m ruler the rubric asks for.
##
## Flags: `--step=<m>` (default 40), `--bands=1,3` (default all five),
## `--time=day|golden|night` (default day), `--out=res://shots_route`,
## `--max=<n>` (stop after n frames, for a smoke), `--fast` (halve settles).
## A `manifest.json` in the output directory maps every frame to its band,
## arc metre and world XZ so a judge's "frame 0840" can be walked to.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"

const SETTLE_FRAMES := 240
const POSE_FRAMES := 4
const SETTLE_AFTER_MOVE := 30
const ACTOR_CLEARANCE := 0.4
const ACTOR_BEHIND_M := 5.0
const EYE_H := 2.2
const TARGET_H := 1.6
const LOOK_AHEAD_M := 60.0
const FOV := 70.0
const HORIZON := 0.30

var _step := 40.0
var _bands: Array[int] = [1, 2, 3, 4, 5]
var _time := "day"
var _out_dir := "res://shots_route"
var _max := 0
var _fast := false


func _frames(n: int) -> int:
	return maxi(2, n / 2) if _fast else n


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--step="):
			_step = maxf(5.0, float(a.substr("--step=".length())))
		elif a.begins_with("--bands="):
			_bands.clear()
			for b in a.substr("--bands=".length()).split(",", false):
				_bands.append(int(b.strip_edges()))
		elif a.begins_with("--time="):
			_time = a.substr("--time=".length())
		elif a.begins_with("--out="):
			_out_dir = a.substr("--out=".length())
			if not _out_dir.begins_with("res://"):
				_out_dir = "res://" + _out_dir
			_out_dir = _out_dir.trim_suffix("/")
		elif a.begins_with("--max="):
			_max = int(a.substr("--max=".length()))
		elif a == "--fast":
			_fast = true
	_fast = _fast or OS.get_environment("VP_FAST") == "1"


func _run() -> void:
	_parse_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))

	var config: Dictionary = HEIGHTFIELD.load_config()
	var bands: Array = (config.get("trail", {}) as Dictionary).get("bands", []) as Array
	if bands.is_empty():
		push_error("terrain_playground.json has no trail.bands; nothing to walk")
		quit(1)
		return

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)

	var failures: Array[String] = []
	var manifest: Array = []

	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if weather != null and weather.has_method("set_weather"):
		weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)

	for i in _frames(SETTLE_FRAMES):
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
	if _fast:
		root.msaa_3d = Viewport.MSAA_DISABLED
		root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

	var look: Node = world.get_node_or_null(^"WorldLook")
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()
	if look != null and look.has_method("set_clock_frozen"):
		look.call("set_clock_frozen", true)
	if look != null and look.has_method("apply_time"):
		look.call("apply_time", _time)
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	else:
		failures.append("no Terrain node with set_camera")

	var written := 0
	var band_index := 0
	for entry: Variant in bands:
		band_index += 1
		if not _bands.has(band_index):
			continue
		var band: Dictionary = entry
		var points: Array = band.get("points", []) as Array
		var line: PackedVector2Array = []
		for p: Variant in points:
			if p is Array and (p as Array).size() >= 2:
				line.append(Vector2(float(p[0]), float(p[1])))
		if line.size() < 2:
			failures.append("band %d (%s) has fewer than two trail points" % [band_index, str(band.get("id", "?"))])
			continue
		var total := _arc_length(line)
		var arc := 0.0
		while arc <= total:
			if _max > 0 and written >= _max:
				break
			var eye_xz := _point_at(line, arc)
			var look_xz := _point_at(line, minf(total, arc + LOOK_AHEAD_M))
			if look_xz.distance_to(eye_xz) < 1.0:
				# The last stand looks back the way it came rather than at itself.
				look_xz = _point_at(line, maxf(0.0, arc - LOOK_AHEAD_M))
			var actor_xz := _point_at(line, maxf(0.0, arc - ACTOR_BEHIND_M))
			_pose(camera, field, eye_xz, look_xz)
			_place_actor(player, field, actor_xz, look_xz)
			for i in _frames(SETTLE_AFTER_MOVE):
				await physics_frame
			for i in _frames(POSE_FRAMES):
				await process_frame
			await RenderingServer.frame_post_draw

			var name := "band%d_%05dm" % [band_index, int(round(arc))]
			var image := root.get_texture().get_image()
			if image == null:
				failures.append("%s: viewport returned no image" % name)
			else:
				var path := "%s/%s.png" % [_out_dir, name]
				var err := image.save_png(path)
				if err != OK:
					failures.append("%s: save_png failed (%d)" % [name, err])
				else:
					written += 1
					manifest.append({
						"frame": name, "band": band_index, "band_id": str(band.get("id", "")),
						"arc_m": snappedf(arc, 0.1), "x": snappedf(eye_xz.x, 0.1), "z": snappedf(eye_xz.y, 0.1),
						"look_x": snappedf(look_xz.x, 0.1), "look_z": snappedf(look_xz.y, 0.1), "time": _time,
					})
					print("  %-16s (%.1f, %.1f) -> %s" % [name, eye_xz.x, eye_xz.y, path])
			arc += _step
		if _max > 0 and written >= _max:
			break

	var mf := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if mf != null:
		mf.store_string(JSON.stringify({"step_m": _step, "time": _time, "frames": manifest}, "  "))
		mf.close()

	print("")
	print("%d route frames -> %s" % [written, _out_dir])
	if not failures.is_empty():
		for line in failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


func _arc_length(line: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, line.size()):
		total += line[i - 1].distance_to(line[i])
	return total


func _point_at(line: PackedVector2Array, arc: float) -> Vector2:
	var remaining := maxf(0.0, arc)
	for i in range(1, line.size()):
		var seg := line[i - 1].distance_to(line[i])
		if remaining <= seg or i == line.size() - 1:
			if seg <= 0.0001:
				return line[i]
			return line[i - 1].lerp(line[i], clampf(remaining / seg, 0.0, 1.0))
		remaining -= seg
	return line[line.size() - 1]


func _pose(camera: Camera3D, field: RefCounted, eye_xz: Vector2, target_xz: Vector2) -> void:
	var eye_ground: float = field.height_at(eye_xz.x, eye_xz.y)
	var target_ground: float = field.height_at(target_xz.x, target_xz.y)
	var eye := Vector3(eye_xz.x, eye_ground + EYE_H, eye_xz.y)
	var target := Vector3(target_xz.x, target_ground + TARGET_H, target_xz.y)
	camera.global_position = eye
	camera.look_at(target, Vector3.UP)
	camera.rotation = Vector3(_pitch_for_horizon(HORIZON), camera.rotation.y, 0.0)


func _place_actor(player: Node3D, field: RefCounted, xz: Vector2, look_xz: Vector2) -> void:
	if player == null:
		return
	player.global_position = Vector3(xz.x, field.height_at(xz.x, xz.y) + ACTOR_CLEARANCE, xz.y)
	var ahead := look_xz - xz
	player.rotation = Vector3(0.0, atan2(ahead.x, ahead.y), 0.0)


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)
