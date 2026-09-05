extends SceneTree

## W15-NIGHT-0904 (CL-O2, OP-0904-2 "There is no night time").
##
## Every earlier day/night probe ran under the EDITOR binary and instantiated
## `meadows_playground.tscn` directly. The owner plays an EXPORTED build that
## boots `title_screen.tscn`, presses "Start New Game", and reaches the world
## through `change_scene_to_file()`. This probe takes exactly that path, and is
## written to run under BOTH binaries so the two can be compared on the same
## instrument:
##
##   # the shipped path -- the exported binary (tools/verify_export.sh exports it):
##   cd build/linux && xvfb-run -a -s "-screen 0 640x480x24" \
##     ./Tetherbound.x86_64 --rendering-driver opengl3 --resolution 640x480 \
##     --script res://tools/gate_f/probe_daynight_exported.gd -- --out=/abs/dir
##
##   # the harness path -- the editor binary, same script, same arguments:
##   xvfb-run -a -s "-screen 0 640x480x24" godot --path . --rendering-driver opengl3 \
##     --resolution 640x480 --script tools/gate_f/probe_daynight_exported.gd -- --out=/abs/dir
##
## User args (after `--`):
##   --out=<dir>          where the CSV trace and the per-hour PNG frames go
##                        (default user://daynight_probe/)
##   --max-seconds=<n>    wall-clock budget once the world is up (default 720:
##                        one full 600 s day plus margin)
##   --sample-every=<n>   real seconds between trace rows (default 5)
##   --day-seconds=<n>    OPTIONAL: shrink `day_length_seconds` in place after
##                        the world boots, the way probe_daynight_real_frames.gd
##                        does. Off by default -- the default run is the real
##                        600 s day, because the whole point is to measure the
##                        shipped clock, not a harness-shortened one.
##
## Every trace row is also written to stderr through `printerr` (a release
## export keeps stderr) prefixed `DAYNIGHT-TRACE`, so the run is readable even
## if `--out` is unwritable. The rows carry: wall seconds since the world was
## ready, `WorldLook.hour()`, `time_of_day()`, `is_dark()`, the live
## `Sun.light_energy` / pitch, `Environment.ambient_light_energy`,
## `tonemap_exposure`, and the mean luminance of the rendered viewport
## (0..255), so "did the clock move" and "did the picture get dark" are two
## separate columns on the same line.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const FRAME_HOURS: Array[float] = [8.0, 12.0, 16.0, 18.0, 20.0, 22.0, 0.0, 2.0, 4.0, 5.0, 6.5]

var _out_dir: String = "user://daynight_probe/"
var _max_seconds: float = 720.0
var _sample_every: float = 5.0
var _day_seconds: float = 0.0
var _csv: FileAccess = null
var _frames_taken: Dictionary = {}


func _init() -> void:
	_parse_args()
	_run()


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--max-seconds="):
			_max_seconds = float(arg.trim_prefix("--max-seconds="))
		elif arg.begins_with("--sample-every="):
			_sample_every = maxf(0.2, float(arg.trim_prefix("--sample-every=")))
		elif arg.begins_with("--day-seconds="):
			_day_seconds = float(arg.trim_prefix("--day-seconds="))
	if not _out_dir.ends_with("/"):
		_out_dir += "/"


func _say(line: String) -> void:
	printerr("DAYNIGHT-TRACE " + line)
	if _csv != null:
		_csv.store_line(line)
		_csv.flush()


func _fail(line: String) -> void:
	printerr("DAYNIGHT-PROBE FAIL " + line)
	quit(1)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	_csv = FileAccess.open(_out_dir + "trace.csv", FileAccess.WRITE)
	_say("binary=%s debug_build=%s editor_feature=%s template=%s" % [
		OS.get_executable_path().get_file(), str(OS.is_debug_build()),
		str(OS.has_feature("editor")), str(OS.has_feature("template"))])
	_say("cmdline=%s user_args=%s" % [str(OS.get_cmdline_args()), str(OS.get_cmdline_user_args())])

	# 1. The real main scene, exactly as the export boots it.
	var title_packed: PackedScene = load(TITLE_SCENE)
	if title_packed == null:
		_fail("cannot load %s" % TITLE_SCENE)
		return
	var title: Node = title_packed.instantiate()
	root.add_child(title)
	current_scene = title
	for i in 10:
		await process_frame
	var new_button: Button = title.get("_new_button") as Button
	if new_button == null:
		_fail("title screen has no _new_button; the shipped path cannot be pressed")
		return
	_say("title screen up; pressing '%s'" % new_button.text)
	var t_press := Time.get_ticks_msec()
	# The same signal the owner's controller fires. `_on_new_pressed` starts a
	# fresh game when no save exists, or shows a confirmation when one does.
	new_button.emit_signal("pressed")
	for i in 5:
		await process_frame
	# change_scene_to_file() frees the title the moment it lands, so only ask
	# it about its confirmation box while it still exists.
	if is_instance_valid(title):
		var confirm: Node = title.get("_confirm_box") as Node
		if confirm != null and confirm.visible:
			for child: Node in confirm.get_children():
				if child is Button and (child as Button).text.begins_with("Start Fresh"):
					_say("a save exists; pressing '%s'" % (child as Button).text)
					(child as Button).emit_signal("pressed")
					break

	# 2. Wait for change_scene_to_file() to land the world.
	var world: Node = null
	for i in 6000:
		await process_frame
		var scene := current_scene
		if scene != null and scene.get_node_or_null(^"WorldLook") != null:
			world = scene
			break
	if world == null:
		_fail("the world never became current_scene after pressing New Game")
		return
	var look: Node = world.get_node_or_null(^"WorldLook")
	var t_world := Time.get_ticks_msec()
	_say("world scene current %.1fs after the press; WorldLook hour=%.2f preset=%s cycle=%s" % [
		(t_world - t_press) / 1000.0, float(look.call("hour")), str(look.call("time_of_day")),
		"ok" if look.get("_cycle") != null else "NULL (art.json did not load)"])
	if look.get("_cycle") == null:
		_fail("WorldLook._cycle is null on this binary -- art.json failed to load, the clock never runs")
		return

	# 3. Wait for the world to finish standing up (terrain, player on ground),
	#    logging the clock as it goes -- the build takes real time and the clock
	#    is supposed to be running through it.
	var player: Node = world.get_node_or_null(^"Player")
	var ready_frames := 0
	var last_log := Time.get_ticks_msec()
	for i in 20000:
		await process_frame
		if Time.get_ticks_msec() - last_log >= 5000:
			last_log = Time.get_ticks_msec()
			_say("booting t=%.1fs hour=%.2f preset=%s" % [
				(last_log - t_world) / 1000.0, float(look.call("hour")), str(look.call("time_of_day"))])
		if player != null and player is Node3D and (player as Node3D).global_position.y > -50.0 \
				and world.has_method("ground_height_at"):
			var h: float = float(world.call("ground_height_at",
				(player as Node3D).global_position.x, (player as Node3D).global_position.z))
			if not is_nan(h) and absf((player as Node3D).global_position.y - h) < 3.0:
				ready_frames += 1
				if ready_frames >= 30:
					break
	var t_ready := Time.get_ticks_msec()
	_say("world ready %.1fs after the press (%.1fs after scene change); hour=%.2f preset=%s dark=%s" % [
		(t_ready - t_press) / 1000.0, (t_ready - t_world) / 1000.0,
		float(look.call("hour")), str(look.call("time_of_day")), str(look.call("is_dark"))])

	var cycle: RefCounted = look.get("_cycle")
	_say("day_length_seconds=%.1f dark_from=%.1f dark_to=%.1f keyframes=%s" % [
		float(cycle.get("day_length_seconds")), float(cycle.get("dark_from_hour")),
		float(cycle.get("dark_to_hour")), str(cycle.call("keyframe_names"))])
	if _day_seconds > 0.0:
		var old_len: float = float(cycle.get("day_length_seconds"))
		var frac: float = float(look.get("_elapsed_seconds")) / old_len
		cycle.set("day_length_seconds", _day_seconds)
		look.set("_elapsed_seconds", frac * _day_seconds)
		_say("day shrunk in place to %.1fs for this run (harness-style; NOT the shipped clock)" % _day_seconds)

	# 4. Real engine frames only from here. No manual _process() calls.
	var sun: DirectionalLight3D = look.get_node_or_null(look.get("sun_path")) as DirectionalLight3D
	var env_holder: WorldEnvironment = look.get_node_or_null(look.get("environment_path")) as WorldEnvironment
	_say("csv: wall_s,hour,preset,dark,sun_energy,sun_pitch_deg,ambient_energy,exposure,mean_luma,frames")
	var start := Time.get_ticks_msec()
	var next_sample := 0.0
	var frames := 0
	var min_luma := 255.0
	var min_luma_hour := -1.0
	var max_luma := 0.0
	var max_luma_hour := -1.0
	var saw_dark := false
	var first_hour: float = float(look.call("hour"))
	var last_hour: float = first_hour
	var hours_advanced := 0.0
	while true:
		await process_frame
		frames += 1
		var wall := (Time.get_ticks_msec() - start) / 1000.0
		var hour: float = float(look.call("hour"))
		var step := fposmod(hour - last_hour, 24.0)
		if step < 12.0:
			hours_advanced += step
		last_hour = hour
		if bool(look.call("is_dark")):
			saw_dark = true
		_maybe_capture(hour)
		if wall >= next_sample:
			next_sample = wall + _sample_every
			var luma := _mean_luma()
			if luma < min_luma:
				min_luma = luma
				min_luma_hour = hour
			if luma > max_luma:
				max_luma = luma
				max_luma_hour = hour
			var env: Environment = env_holder.environment if env_holder != null else null
			_say("%.1f,%.3f,%s,%s,%.3f,%.1f,%.3f,%.3f,%.1f,%d" % [
				wall, hour, str(look.call("time_of_day")), "1" if bool(look.call("is_dark")) else "0",
				sun.light_energy if sun != null else -1.0,
				rad_to_deg(sun.rotation.x) if sun != null else 0.0,
				env.ambient_light_energy if env != null else -1.0,
				env.tonemap_exposure if env != null else -1.0,
				luma, frames])
		if wall >= _max_seconds:
			break
		if hours_advanced >= 24.5:
			break

	_say("SUMMARY hours_advanced=%.2f over %.1fs (%d frames, %.2f s/frame) saw_dark=%s" % [
		hours_advanced, (Time.get_ticks_msec() - start) / 1000.0, frames,
		(Time.get_ticks_msec() - start) / 1000.0 / maxf(1.0, float(frames)), str(saw_dark)])
	_say("SUMMARY luma min=%.1f at hour %.2f, max=%.1f at hour %.2f, night/day ratio=%.3f" % [
		min_luma, min_luma_hour, max_luma, max_luma_hour, min_luma / maxf(1.0, max_luma)])
	_say("SUMMARY frames written: %s" % str(_frames_taken.keys()))
	if _csv != null:
		_csv.close()
	quit(0)


func _mean_luma() -> float:
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		return -1.0
	img.resize(64, 36, Image.INTERPOLATE_BILINEAR)
	var total := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			total += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
	return total / float(img.get_width() * img.get_height()) * 255.0


func _maybe_capture(hour: float) -> void:
	for target: float in FRAME_HOURS:
		var key := "%04.1f" % target
		if _frames_taken.has(key):
			continue
		# Within a quarter hour after the target (never before it), so a slow
		# software-GL frame that overshoots still takes the picture once.
		var d := fposmod(hour - target, 24.0)
		if d >= 0.0 and d < 0.5:
			var img: Image = root.get_viewport().get_texture().get_image()
			if img != null:
				var path := _out_dir + "hour_%s.png" % key
				img.save_png(path)
				_frames_taken[key] = path
				_say("frame hour=%.2f -> %s" % [hour, path])
