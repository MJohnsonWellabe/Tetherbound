extends SceneTree

## In-engine receipt for two HUD work orders, through the production Tidewake
## world (`water_archipelago.tscn`), its real Player, SwimController, CameraRig
## and PlaygroundHUD at the production camera:
##
##   * toast hold -- a world message is posted through `Game.push_world_message`
##     (the same queue every world refusal uses) and the frame is shot after
##     TOAST_SHOT_AT_S seconds of GAME time (summed physics steps). On a slow
##     software-GL run a wall-clock hold has already expired by then; a
##     game-time hold has not.
##   * drowning cue -- the human is placed in deep water with stamina forced to
##     0, so `swim_state.drowning` turns true and health falls. One still.
##   * `--sequence=1` additionally records a >= 30 s, 1 fps, 640x360 sequence:
##     swim out from the lesson beach with low stamina, run dry, drown for a
##     while, swim back and land.
##
## Disclosed staging (see the evidence README): stamina is written directly
## (0 for the still; for the sequence, cut to SEQUENCE_STAMINA on the first
## physics step in the water), health is restored to max
## before the sequence, the time of day is frozen at "day", and movement is
## driven by synthetic `move_forward` action events steered by camera yaw.
##
## Composition only (no rendering, headless is fine): side-by-side before/after
## sheets from the stills this tool wrote, plus a 1 fps sequence contact sheet:
##   godot --headless --path . --script tools/capture_hud_drowning.gd -- \
##     --compose=1 --out=<dir>
##
##   flock /tmp/claude-0/godot-render.lock xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
##     --script tools/capture_hud_drowning.gd -- --out=<dir> --tag=<before|after> [--sequence=1]

const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const MODES := ["LAND", "HUMAN", "MOUNTED", "PAUSED"]
const TOAST_TEXT := "Toast hold check: posted 1.8 s ago"
const TOAST_SHOT_AT_S := 1.8
const SEQUENCE_STAMINA := 12.0

var world: Node3D
var player: CharacterBody3D
var camera: Node3D
var hud: Node
var game: Node
var out_dir := ""
var tag := "run"
var game_time := 0.0
var log_lines: Array[String] = []
var seq_frames := 0
var next_seq_shot := 0.0
var seq_recording := false
var seq_started_at := 0.0
## Set once the sequence starts; cleared the first physics step the swimmer is
## in the water, when stamina is (STAGED) cut to SEQUENCE_STAMINA. Cutting it on
## land does nothing: dry-land regeneration refills it before the shoreline.
var stage_stamina_on_entry := false


func _init() -> void:
	_run.call_deferred()


func _arg(name: String, fallback: String = "") -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--%s=" % name):
			return argument.trim_prefix("--%s=" % name)
	return fallback


func _run() -> void:
	if _arg("compose", "") != "":
		_compose()
		return
	if DisplayServer.get_name() == "headless":
		push_error("capture_hud_drowning requires a rendering display")
		quit(1)
		return
	out_dir = _arg("out", "res://ralph/reports/SHARED-UI/hud-drowning-toast")
	if not out_dir.begins_with("/"):
		out_dir = ProjectSettings.globalize_path(out_dir)
	tag = _arg("tag", "run")
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = root.get_node(^"Game")
	game.call("reset_for_new_game")
	game.set("current_realm", "water")
	world = WORLD.instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var look := world.get_node_or_null(^"WorldLook")
	if look != null:
		look.call("apply_time", "day")
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
	player = world.get_node(^"Player") as CharacterBody3D
	camera = world.get_node(^"CameraRig") as Node3D
	hud = world.get_node(^"PlaygroundHUD")
	var shore := _shore()
	player.global_position = shore
	await _wait(1.0)

	# --- toast hold ------------------------------------------------------------
	game.call("push_world_message", TOAST_TEXT)
	var wall_start := Time.get_ticks_msec()
	await _wait(TOAST_SHOT_AT_S)
	await _shoot("%s_toast.png" % tag, false)
	var message: Label = hud.get("_hotbar_message")
	_log("toast: game_time_since_post=%.2fs wall_since_post=%.2fs visible=%s text='%s'" % [
		TOAST_SHOT_AT_S, (Time.get_ticks_msec() - wall_start) / 1000.0,
		str(message != null and message.visible), message.text if message != null else ""])

	# --- drowning still ----------------------------------------------------------
	var deep := _spot_with_depth(4.0)
	deep.y = float(world.get("field").call("water_level"))
	player.global_position = deep
	player.velocity = Vector3.ZERO
	await _wait(0.5)
	var vitals: RefCounted = player.get("vitals")
	vitals.set("stamina", 0.0)  # STAGED: stamina forced to 0 in deep water.
	await _wait(2.0)
	await _shoot("%s_drowning.png" % tag, false)
	_log("drowning still: %s" % _state_line())

	if _arg("sequence", "0") == "1":
		await _sequence(shore, deep)

	var log_file := FileAccess.open("%s/%s_log.txt" % [out_dir, tag], FileAccess.WRITE)
	if log_file != null:
		log_file.store_string("\n".join(log_lines) + "\n")
	print("HUD DROWNING CAPTURE OK tag=%s" % tag)
	quit(0)


func _sequence(shore: Vector3, deep: Vector3) -> void:
	# Back to dry land, whole again. On entering the water stamina is cut to
	# a low (STAGED) reserve so the swim runs dry within a few seconds instead
	# of ~36 s from full.
	player.global_position = shore
	player.velocity = Vector3.ZERO
	await _wait(1.5)
	var vitals: RefCounted = player.get("vitals")
	vitals.set("health", float(vitals.get("max_health")))
	stage_stamina_on_entry = true
	DirAccess.make_dir_recursive_absolute("%s/sequence" % out_dir)
	seq_recording = true
	seq_started_at = game_time
	next_seq_shot = game_time
	_log("sequence start: %s" % _state_line())
	await _hold(2.0)                  # on land, full health
	await _steer(deep, 12.0)          # swim out; staged low stamina runs dry
	await _hold(8.0)                  # tread water in deep water, drowning
	await _steer(shore, 14.0)         # swim back and land
	await _hold(3.0)                  # dry land; cue must be gone
	seq_recording = false
	_log("sequence end: frames=%d seconds=%.1f %s" % [seq_frames, game_time - seq_started_at, _state_line()])


func _shore() -> Vector3:
	var config: Dictionary = world.get("config")
	var lesson: Dictionary = config.swim_lesson
	var start: Array = config.anchors.filter(func(row: Dictionary) -> bool:
		return str(row.id) == str(lesson.start_anchor))[0].safe_position
	var shore := Vector3(float(start[0]), 0.0, float(start[2]))
	shore.y = float(world.call("ground_height_at", shore.x, shore.z)) + 0.2
	return shore


func _spot_with_depth(target: float) -> Vector3:
	var lesson: Dictionary = world.get("config").swim_lesson
	var start: Array = lesson.surface_polyline[0]
	var from := Vector3(float(start[0]), 0.0, float(start[2]))
	var seaward := Vector3(from.x, 0.0, from.z).normalized()
	for step in 4000:
		var at := from + seaward * (float(step) * 0.05 - 40.0)
		if absf(float(world.call("water_depth_at", at)) - target) < 0.03:
			return at
	return from


func _state_line() -> String:
	var swim: Node = player.get("swim_controller")
	var state: RefCounted = swim.get("state") if swim != null else null
	var vitals: RefCounted = player.get("vitals")
	var cue: Control = hud.get("_drowning_cue") if &"_drowning_cue" in hud else null
	return "mode=%s drowning=%s stamina=%.1f health=%.1f cue=%s" % [
		MODES[int(state.get("mode"))] if state != null else "?",
		str(state.get("drowning")) if state != null else "?",
		float(vitals.get("stamina")), float(vitals.get("health")),
		("visible" if cue.is_visible_in_tree() else "hidden") if cue != null else "absent"]


func _wait(seconds: float) -> void:
	var spent := 0.0
	while spent < seconds:
		await physics_frame
		var step := 1.0 / float(Engine.physics_ticks_per_second)
		spent += step
		game_time += step
		await _maybe_sequence_frame()


func _hold(seconds: float) -> void:
	_action(false)
	await _wait(seconds)


func _steer(target: Vector3, seconds: float) -> void:
	var spent := 0.0
	while spent < seconds:
		var offset: Vector3 = target - player.global_position
		offset.y = 0.0
		if offset.length() <= 0.8:
			_action(false)
		else:
			camera.set("yaw", atan2(-offset.x, -offset.z))
			_action(true)
		await physics_frame
		var step := 1.0 / float(Engine.physics_ticks_per_second)
		spent += step
		game_time += step
		await _maybe_sequence_frame()
	_action(false)


func _maybe_sequence_frame() -> void:
	if stage_stamina_on_entry:
		var swim: Node = player.get("swim_controller")
		if swim != null and int(swim.get("state").get("mode")) != 0:
			stage_stamina_on_entry = false
			player.get("vitals").set("stamina", SEQUENCE_STAMINA)  # STAGED
			_log("t=%4.1fs STAGED: entered water, stamina set to %.1f" % [game_time - seq_started_at, SEQUENCE_STAMINA])
	if not seq_recording or game_time < next_seq_shot:
		return
	next_seq_shot += 1.0
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	image.resize(640, 360, Image.INTERPOLATE_LANCZOS)
	var name := "sequence/frame_%02d.jpg" % seq_frames
	image.save_jpg("%s/%s" % [out_dir, name], 0.82)
	_log("t=%4.1fs %s -> %s" % [game_time - seq_started_at, _state_line(), name])
	seq_frames += 1


func _shoot(file_name: String, small: bool) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	if small:
		image.resize(640, 360, Image.INTERPOLATE_LANCZOS)
	image.save_png("%s/%s" % [out_dir, file_name])
	print("  shot -> %s/%s (%dx%d)" % [out_dir, file_name, image.get_width(), image.get_height()])


func _log(line: String) -> void:
	log_lines.append(line)
	print(line)


func _action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


## Builds `<out>/before_after_drowning.png`, `<out>/before_after_toast.png` and
## `<out>/sequence_sheet.jpg` from files this tool already wrote.
func _compose() -> void:
	out_dir = _arg("out", "res://ralph/reports/SHARED-UI/hud-drowning-toast")
	if not out_dir.begins_with("/"):
		out_dir = ProjectSettings.globalize_path(out_dir)
	var ok := true
	for pair: Array in [["drowning", "before_after_drowning.png"], ["toast", "before_after_toast.png"]]:
		var before := Image.load_from_file("%s/before_%s.png" % [out_dir, pair[0]])
		var after := Image.load_from_file("%s/after_%s.png" % [out_dir, pair[0]])
		if before == null or after == null:
			push_error("compose: missing before/after_%s.png" % pair[0])
			ok = false
			continue
		ok = _side_by_side(before, after, "%s/%s" % [out_dir, pair[1]]) and ok
		# Full-resolution JPG copies of each still, to keep evidence small.
		before.save_jpg("%s/before_%s.jpg" % [out_dir, pair[0]], 0.9)
		after.save_jpg("%s/after_%s.jpg" % [out_dir, pair[0]], 0.9)
	var frames: Array[Image] = []
	var index := 0
	while FileAccess.file_exists("%s/sequence/frame_%02d.jpg" % [out_dir, index]):
		frames.append(Image.load_from_file("%s/sequence/frame_%02d.jpg" % [out_dir, index]))
		index += 1
	if not frames.is_empty():
		var cols := 6
		var w := 320
		var h := 180
		var rows := int(ceil(frames.size() / float(cols)))
		var sheet := Image.create(w * cols, h * rows, false, Image.FORMAT_RGB8)
		for i in frames.size():
			var small := frames[i].duplicate() as Image
			small.convert(Image.FORMAT_RGB8)
			small.resize(w, h, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(small, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
		sheet.save_jpg("%s/sequence_sheet.jpg" % out_dir, 0.85)
		print("compose: sequence sheet from %d frames" % frames.size())
	print("HUD DROWNING COMPOSE %s" % ("OK" if ok else "INCOMPLETE"))
	quit(0 if ok else 1)


## Full-resolution before (left) and after (right) with an 8 px divider, so
## HUD text is judged at its real 1280x720 raster. The left/right order is
## stated in the README; no text is burned in.
func _side_by_side(before: Image, after: Image, path: String) -> bool:
	var w := before.get_width()
	var h := before.get_height()
	var sheet := Image.create(w * 2 + 8, h, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.05, 0.05, 0.05))
	for side in 2:
		var img := (before if side == 0 else after).duplicate() as Image
		img.convert(Image.FORMAT_RGB8)
		if img.get_width() != w or img.get_height() != h:
			img.resize(w, h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(img, Rect2i(0, 0, w, h), Vector2i(side * (w + 8), 0))
	var err := sheet.save_png(path)
	print("compose: %s (%d)" % [path, err])
	return err == OK
