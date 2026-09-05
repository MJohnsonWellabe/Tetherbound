extends SceneTree

## N13-NIGHT-RESUME (CL-O2, OP-0904-2 "There is no night time").
##
## The one comparison this project had never made: the SAME viewpoint at
## several hours of the SAME day, lit the way the running game lights it.
##
## Every existing capture and survey tool pins a preset by name with
## `world_look.gd::apply_time()`. The running game never does that -- its
## passive clock calls `_apply_blended(hour)`, a continuous lerp between the two
## keyframes bracketing the current hour. So the night frames NIGHT-LIGHT and
## NIGHT-LEGIBILITY were judged on are frames the game only ever draws at the
## single instant the clock crosses `night`'s own hour, and every one of them
## was judged on its own, never against a day frame from the same camera. This
## drives `_apply_blended()` directly, with the clock frozen so nothing drifts
## between the pose and the shutter (R6-CLOCK-FREEZE), and shoots the whole day
## from one tripod.
##
##   xvfb-run -a -s "-screen 0 960x540x24" ~/godot-bin/godot --path . \
##     --rendering-driver opengl3 --resolution 960x540 \
##     --script tools/gate_f/probe_daynight_contrast.gd -- --out=/abs/dir
##
##   --hours=8,12,18,20,22,0,3   in-game hours to shoot (default: those)
##   --out=<dir>                 where the PNGs and stats.csv go
##
## Prints one row per hour: mean luma, the darkest 1% and brightest 1% of the
## frame, and the ratio of each frame's mean to the brightest frame shot. That
## last column is the whole question -- if night's row is not far below 1.0,
## there is no night time.
##
## HONEST LIMITS: Compatibility renderer, software rendering (D06/D01) -- the
## same instrument every previous night judgement in this project used, so the
## numbers are comparable to theirs.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const SETTLE_AFTER_TIME := 12
const FOV := 70.0

## Open meadow near the home-band mudsnout spawn. Taken from
## `tools/_capture_night_legibility.gd`, which confirmed this coordinate renders
## open, unobstructed ground -- deliberately reusing a viewpoint an earlier
## night pass already validated rather than picking a fresh one whose framing
## would be one more thing to argue about.
const EYE := Vector2(-70.0, 22.0)
const LOOK_AT := Vector2(-30.0, -18.0)

var _out_dir: String = "user://daynight_contrast/"
var _hours: Array[float] = [8.0, 12.0, 18.0, 20.0, 22.0, 0.0, 3.0]
var _field: RefCounted = null


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--hours="):
			_hours.clear()
			for piece: String in arg.trim_prefix("--hours=").split(",", false):
				_hours.append(float(piece))
	if not _out_dir.ends_with("/"):
		_out_dir += "/"
	_run()


func _say(line: String) -> void:
	printerr("DAYNIGHT-CONTRAST " + line)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	_field = HEIGHTFIELD.new()

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var look: Node = world.get_node_or_null(^"WorldLook")
	if look == null or look.get("_cycle") == null:
		_say("FAIL no WorldLook, or art.json did not load")
		quit(1)
		return

	# Same freezing the night-legibility capture does, same reasons: the rig
	# would walk the camera, the player would free-fall where Terrain3D has no
	# collision yet, and the HUD would sit in every luma measurement.
	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		player.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var combat_hud: CanvasLayer = world.get_node_or_null(^"CombatHUD") as CanvasLayer
	if combat_hud != null:
		combat_hud.visible = false

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	var eye_ground: float = _field.height_at(EYE.x, EYE.y)
	var target_ground: float = _field.height_at(LOOK_AT.x, LOOK_AT.y)
	camera.global_position = Vector3(EYE.x, eye_ground + 1.7, EYE.y)
	camera.look_at(Vector3(LOOK_AT.x, target_ground + 1.2, LOOK_AT.y), Vector3.UP)

	# R6-CLOCK-FREEZE: without this every settle frame is ~1 real second, i.e.
	# most of an in-game hour, and `_process` would re-derive the look from the
	# drifted hour before the shutter -- the exact bug that comment records.
	look.call("set_clock_frozen", true)
	var cycle: RefCounted = look.get("_cycle")

	var rows: Array[Dictionary] = []
	for hour: float in _hours:
		# Both, so `is_dark()` and anything else reading the clock agree with
		# the look actually installed.
		look.set("_elapsed_seconds", float(cycle.call("elapsed_for_hour", hour)))
		look.call("_apply_blended", hour)
		for i in SETTLE_AFTER_TIME:
			await process_frame
		var img: Image = root.get_viewport().get_texture().get_image()
		if img == null:
			_say("FAIL no viewport image at hour %.1f" % hour)
			quit(1)
			return
		var path := _out_dir + "hour_%04.1f.png" % hour
		img.save_png(path)
		var stats := _luma_stats(img)
		stats["hour"] = hour
		stats["path"] = path
		var budget: Dictionary = look.call("light_budget_at", look.get("_config"), cycle, hour)
		stats["asked"] = float(budget.total)
		stats["blend"] = "%s->%s@%.2f" % [budget.from, budget.to, float(budget.t)]
		rows.append(stats)
		_say("hour %04.1f  %-18s asked=%.3f  mean=%.1f  p01=%.1f  p99=%.1f  -> %s" % [
			hour, stats.blend, float(stats.asked), float(stats.mean),
			float(stats.p01), float(stats.p99), path])

	var brightest := 0.0
	for row: Dictionary in rows:
		brightest = maxf(brightest, float(row.mean))
	_say("")
	_say("hour,blend,asked_light,mean_luma,p01,p99,mean_over_brightest")
	var csv := FileAccess.open(_out_dir + "stats.csv", FileAccess.WRITE)
	if csv != null:
		csv.store_line("hour,blend,asked_light,mean_luma,p01,p99,mean_over_brightest")
	for row: Dictionary in rows:
		var line := "%.1f,%s,%.3f,%.2f,%.2f,%.2f,%.3f" % [
			float(row.hour), row.blend, float(row.asked), float(row.mean),
			float(row.p01), float(row.p99), float(row.mean) / maxf(0.01, brightest)]
		_say(line)
		if csv != null:
			csv.store_line(line)
	if csv != null:
		csv.close()
	quit(0)


## Mean, 1st and 99th percentile Rec.709 luma over the frame, 0..255. Same
## weighting `tools/frame_stats.py` uses, so these numbers sit on the same scale
## as every earlier night measurement in this project.
func _luma_stats(source: Image) -> Dictionary:
	var img := Image.new()
	img.copy_from(source)
	img.resize(160, 90, Image.INTERPOLATE_BILINEAR)
	var values: Array[float] = []
	var total := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var luma := (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) * 255.0
			values.append(luma)
			total += luma
	values.sort()
	var n := values.size()
	return {
		"mean": total / float(n),
		"p01": values[int(floor(n * 0.01))],
		"p99": values[mini(n - 1, int(floor(n * 0.99)))],
	}
