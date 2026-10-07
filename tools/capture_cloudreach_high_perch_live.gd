extends SceneTree

## F08#2 (current board; formerly Phase1#3): High Perches through live production
## camera, in one continuous flight per time of day. The re-check of the c3
## verdict found its height/crowding PASS rested on a fixed evidence camera and
## on a rig frozen at the exploration arm; this tool never freezes the rig or
## the player and never adds a camera.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1920x1080 --fixed-fps 60 --script tools/capture_cloudreach_high_perch_live.gd \
##     -- --output=res://ralph/reports/CLOUDREACH/f08-3-high-perch-camera/r5
##
## `--fixed-fps 60` makes every rendered frame exactly one 1/60 s physics step,
## so software GL's slow frames do not skip simulation.
##
## Per time of day (day 10:00, night 23:00), one continuous sequence:
##   1. ARRIVAL. The trainer is placed 80 m south of the crown, 14 m above it,
##      and presses Jump in the air, which launches the production glide on
##      the active owned Galecrest. Move forward is held with the
##      camera yaw on the crown, as a player's stick would hold it, until the
##      glide lands. Frames: `arrival-far` (~50 m out), `arrival-lip` (~22 m
##      out), `arrival-landed` (1 s after touchdown).
##   2. ON THE CROWN. From where the glide landed the trainer walks to the
##      south-east rim by held input, then stands; frames `crown-rim-out` (yaw
##      out over the drop, stick tilted down) and `crown-court` (yaw back at the needles).
##   3. DEPARTURE. The trainer walks north across the court, jumps and presses
##      Jump again in the air (the production launch), glides north, then
##      turns the camera back on the perch and holds move back so the glide
##      keeps leaving it. Frame `departure-lookback` ~35 m out.
##
## DISCLOSED FIXTURE: `Game.reset_for_new_game()`, realm cloudreach, the scene
## instantiated directly; progression flags up to Act II (the frame matrix's
## BOOT_FLAGS, which include fly_traversal_unlocked); the existing five-owned
## matrix party, with Galecrest active and summoned; the trainer is teleported to
## the arrival start once per time of day; WorldLook's clock is pinned; HUD
## CanvasLayers are hidden for the frame. Camera yaw is written the way the
## right stick writes it (`camera_rig.gd::yaw`); pitch is left to the rig.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const LANE := preload("res://tools/capture_cloudreach_lane_common.gd")
const MATRIX := preload("res://tools/capture_cloudreach_frame_matrix.gd")

const DEFAULT_OUT := "res://ralph/reports/CLOUDREACH/f08-3-high-perch-camera/r5"
const PARTY := MATRIX.PARTY
const CROWN := Vector3(900.0, 1020.0, 2700.0)
## The south-east rim (an r3 production-rig stand, 18.4 m out) and a point
## east over the drop, where the lowland and cloud floor lie far below.
const RIM := Vector3(913.0, 1020.0, 2687.0)
const OUT_OVER_DROP := Vector3(1010.0, 990.0, 2690.0)
## Looking over an edge the player tilts the stick down (rig pitch range is
## -60..32; rest is -12).
const OVER_EDGE_PITCH_DEG := -32.0
const ARRIVAL_START := Vector3(905.0, 1034.0, 2620.0)
const NORTH_OUT := Vector3(900.0, 1020.0, 2800.0)
const HOURS := {"day": 10.0, "night": 23.0}
## Wall-clock boot budget, not a frame count: on Forward+ Medium a GTX 1060
## draws the booting world at ~0.24 s/frame, so 900 frames (217 s) ran out
## before EncounterDirector appeared (Codex cloudreach-2).
const BOOT_MAX_SECONDS := 600.0
const STEP_LIMIT := 60 * 30
const RENDERED_FRAMES := 4

var OUT := DEFAULT_OUT
var _game: Node
var _world: Node3D
var _player: CharacterBody3D
var _rig: SpringArm3D
var _camera: Camera3D
var _look: Node
var _fly: Node
var _director: Node
var _frames: Array = []
var _records: Array = []
var _failures: Array[String] = []
var _graphics_capture: Dictionary = {}
var _time_name := "day"
## Grounded first presses repeated before a departure launch (evidence).
var _departure_jump_presses := 0
var _departure_launches: Array[Dictionary] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			OUT = arg.trim_prefix("--output=").strip_edges().trim_suffix("/")
	if DisplayServer.get_name() == "headless":
		print("high perch live: needs a rendering display (xvfb-run, opengl3)")
		quit(1)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			_graphics_capture = preload("res://tools/lookdev_capture_bootstrap.gd").prepare(self)
			if _graphics_capture.is_empty():
				quit(1)
				return
			break
	if not await _boot():
		_finish()
		return
	for time_name: String in ["day", "night"]:
		_time_name = time_name
		_pin_hour(float(HOURS[time_name]))
		if not await _arrival():
			continue
		await _crown()
		await _departure()
	_finish()


func _boot() -> bool:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		return _fail("Game autoload is missing")
	_game.call("reset_for_new_game")
	_game.set("save_system", SAVE.new("user://capture_cloudreach_high_perch_live/"))
	_game.set("current_realm", "cloudreach")
	var party: RefCounted = _game.get("party")
	for species: String in PARTY:
		party.call("add", SPECIES.spawn(species))
	if (party.call("members") as Array).size() != 5:
		return _fail("visual fixture must contain exactly five owned companions")
	var flags: RefCounted = _game.get("progression")
	for flag: String in MATRIX.BOOT_FLAGS:
		flags.call("set_flag", flag)
	_world = SCENE.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as SpringArm3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	_look = _world.get_node_or_null(^"WorldLook")
	if _player == null or _rig == null or _camera == null:
		return _fail("production Player/CameraRig/Camera3D missing")
	var booted := false
	var boot_start := Time.get_ticks_msec()
	var boot_i := -1
	while Time.get_ticks_msec() - boot_start < int(BOOT_MAX_SECONDS * 1000.0):
		boot_i += 1
		await process_frame
		_director = _world.get_node_or_null(^"EncounterDirector")
		var runtime := _world.get_node_or_null(^"CloudreachRuntime")
		if _director != null and (runtime == null or bool(runtime.get("_mounted"))) and boot_i >= 20:
			booted = true
			break
	if not booted:
		return _fail("EncounterDirector never appeared")
	# Render only after boot: under Forward+ the world's shell build awaits drawn
	# frames, so a loop switched off before this point never reaches EncounterDirector.
	_set_render(false)
	for i in 10:
		await physics_frame
	_fly = _player.get("fly_controller")
	if _fly == null:
		return _fail("player has no fly_controller")
	var carrier: RefCounted = _fly.call("eligible_creature")
	if carrier == null or carrier != party.call("active") or not (party.call("members") as Array).has(carrier):
		return _fail("active owned Fly carrier is not eligible")
	_director.call("summon_active_creature")
	for i in 120:
		if _director.call("ally_body") != null:
			break
		await physics_frame
	if _director.call("ally_body") == null:
		return _fail("owned carrier did not appear in the production world")
	_camera.make_current()
	return true


## --- 1. arrival -------------------------------------------------------------

func _arrival() -> bool:
	_set_render(false)
	_release_all()
	_player.global_position = ARRIVAL_START
	_player.velocity = Vector3.ZERO
	_player.reset_physics_interpolation()
	await physics_frame
	await _tap("jump")
	for i in 20:
		if bool(_fly.call("is_flying")):
			break
		await physics_frame
	if not bool(_fly.call("is_flying")):
		return _fail("%s arrival: Jump in the air did not launch the glide (%s)" % [_time_name, str(_fly.call("launch_blockers"))])
	Input.action_press("move_forward", 1.0)
	var took_far := false
	var took_lip := false
	for step in STEP_LIMIT:
		_steer(CROWN)
		await physics_frame
		var flat := _flat(_player.global_position, CROWN)
		if not took_far and flat <= 50.0:
			took_far = true
			await _capture("arrival-far", CROWN)
		elif not took_lip and flat <= 22.0:
			took_lip = true
			await _capture("arrival-lip", CROWN)
		if not bool(_fly.call("is_flying")) and _player.is_on_floor():
			break
	Input.action_release("move_forward")
	if bool(_fly.call("is_flying")):
		return _fail("%s arrival: glide never landed (at %s)" % [_time_name, _player.global_position])
	if _flat(_player.global_position, CROWN) > 40.0:
		return _fail("%s arrival: landed off the crown at %s" % [_time_name, _player.global_position])
	# After touchdown the stick stays where the flight pointed (the player
	# does not spin the camera back onto the landing spot they just crossed).
	var heading := _player.global_position + (_player.global_position - ARRIVAL_START) * Vector3(1, 0, 1)
	for i in 60:
		_steer(heading)
		await physics_frame
	await _capture("arrival-landed", heading)
	return true


## --- 2. on the crown ----------------------------------------------------------

func _crown() -> void:
	Input.action_press("move_forward", 1.0)
	for step in 60 * 8:
		_steer(RIM)
		await physics_frame
		if _flat(_player.global_position, RIM) < 1.5:
			break
	Input.action_release("move_forward")
	for i in 30:
		await physics_frame
	for i in 30:
		_steer(OUT_OVER_DROP)
		_rig.set("pitch", deg_to_rad(OVER_EDGE_PITCH_DEG))
		await physics_frame
	await _capture("crown-rim-out", OUT_OVER_DROP)
	_rig.set("pitch", deg_to_rad(-12.0))
	for i in 45:
		_steer(CROWN + Vector3(0.0, 8.0, 0.0))
		await physics_frame
	await _capture("crown-court", CROWN)


## --- 3. departure ---------------------------------------------------------------

func _departure() -> void:
	Input.action_press("move_forward", 1.0)
	for step in 60 * 4:
		_steer(CROWN)
		await physics_frame
		if _flat(_player.global_position, CROWN) < 3.0:
			break
	for step in 60 * 5:
		_steer(NORTH_OUT)
		await physics_frame
		# Launch beside the north lip, rather than seven metres inside the
		# 34 m crown. The first owned-carrier run touched down at z+15.9:
		# its normal descending glide reached the floor before clearing it.
		# This remains the same input-driven walk/jump, with no reposition,
		# velocity override or change to production flight/landing behavior.
		if _player.global_position.z - CROWN.z > 15.0:
			break
	# A player whose first press did not leave the ground presses again. The
	# night run stepped onto the low roost rack on the jump frame, so the press
	# was a grounded no-op and the "second" Jump came from the floor (F08#3
	# re-proof). Up to three presses, each confirmed airborne, before the
	# in-air Jump that deploys Fly.
	var airborne := false
	for attempt in 3:
		await _tap("jump")
		for i in 14:
			_steer(NORTH_OUT)
			await physics_frame
			if not _player.is_on_floor():
				airborne = true
		if airborne and not _player.is_on_floor():
			break
		airborne = false
		_departure_jump_presses += 1
	await _tap("jump")
	var launched := false
	for i in 30:
		_steer(NORTH_OUT)
		await physics_frame
		if bool(_fly.call("is_flying")):
			launched = true
			break
	if not launched:
		Input.action_release("move_forward")
		_fail("%s departure: second Jump did not launch (%s) at %s, overhead: %s" % [_time_name,
			str(_fly.call("launch_blockers")), _player.global_position, _overhead_colliders()])
		return
	_departure_launches.append({"time":_time_name, "player_position":_v(_player.global_position),
		"velocity":_v(_player.velocity), "flying":bool(_fly.call("is_flying")),
		"crown_flat_distance_m":_flat(_player.global_position, CROWN)})
	for i in 60:
		_steer(NORTH_OUT)
		await physics_frame
	# Turn the camera back on the perch and keep leaving it: with the camera
	# facing the crown, "back" on the stick flies away from it.
	Input.action_release("move_forward")
	Input.action_press("move_back", 1.0)
	for step in STEP_LIMIT:
		_steer(CROWN)
		await physics_frame
		if _flat(_player.global_position, CROWN) >= 35.0 or not bool(_fly.call("is_flying")):
			break
	if bool(_fly.call("is_flying")):
		await _capture("departure-lookback", CROWN)
	else:
		_fail("%s departure: the glide ended before 35 m, at %s (%.1f m out) on %s" % [_time_name,
			_player.global_position, _flat(_player.global_position, CROWN), _floor_collider()])
	_release_all()


## --- helpers ------------------------------------------------------------------------

## The collider straight under the trainer (evidence for an early touchdown).
func _floor_collider() -> String:
	var query := PhysicsRayQueryParameters3D.create(_player.global_position + Vector3.UP * 0.5,
		_player.global_position + Vector3.DOWN * 3.0, _player.collision_mask, [_player.get_rid()])
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return "nothing within 3 m"
	var collider := hit.get("collider") as Node
	return "%s at y %.2f" % [str(collider.get_path()) if collider != null else "?", float((hit.position as Vector3).y)]


## What the launch's room-overhead query (fly_controller.gd `launch_blockers`)
## meets at the trainer, by node path: evidence for a refused launch.
func _overhead_colliders() -> Array:
	var shape := CapsuleShape3D.new()
	shape.radius = float(_fly.get("config").get("collision_radius_m", 0.7))
	shape.height = float(_fly.get("config").get("collision_height_m", 4.5))
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = _player.global_transform.translated(Vector3.UP * shape.height * 0.5)
	query.collision_mask = _player.collision_mask
	query.exclude = [_player.get_rid()]
	var names: Array = []
	for hit: Dictionary in _player.get_world_3d().direct_space_state.intersect_shape(query, 8):
		var collider := hit.get("collider") as Node
		names.append(str(collider.get_path()) if collider != null else "?")
	return names


## The right stick: point the rig's yaw at `target`. Pitch stays the rig's own.
func _steer(target: Vector3) -> void:
	_rig.set("yaw", LANE.yaw_towards(_player.global_position, target))


func _tap(action: String) -> void:
	Input.action_press(action, 1.0)
	await physics_frame
	await physics_frame
	Input.action_release(action)


func _release_all() -> void:
	for action: String in ["move_forward", "move_back", "move_left", "move_right", "jump", "fly_descend"]:
		Input.action_release(action)


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _capture(label: String, subject: Vector3) -> void:
	if bool(_fly.call("last_flight_used_mentor_loaner")):
		_fail("owned-carrier camera proof cannot use a mentor loaner")
		return
	_hide_overlays()
	_set_render(true)
	for i in RENDERED_FRAMES:
		_steer(subject)
		await process_frame
	await RenderingServer.frame_post_draw
	var name := "high-perches-%s-%s" % [label, _time_name]
	var path := LANE.save_frame(self, OUT, name, _frames)
	_set_render(false)
	if path.is_empty():
		_fail("%s could not be written" % name)
		return
	_records.append({"frame_id": name, "file": path, "camera": "production_rig_live",
		"rig_processing": _rig.is_processing() or _rig.is_physics_processing(),
		"player_processing": _player.can_process(),
		"flying": bool(_fly.call("is_flying")),
		"carrier_is_mentor_loaner": bool(_fly.call("last_flight_used_mentor_loaner")),
		"player_position": _v(_player.global_position), "camera_position": _v(_camera.global_position),
		"camera_fov": _camera.fov, "rig_spring_length": _rig.spring_length,
		"rig_hit_length": _rig.get_hit_length(), "rig_yaw_deg": rad_to_deg(float(_rig.get("yaw"))),
		"rig_pitch_deg": rad_to_deg(float(_rig.get("pitch"))),
		"crown_flat_distance_m": _flat(_player.global_position, CROWN),
		"height_over_crown_m": _player.global_position.y - CROWN.y,
		"hour": float(_look.call("hour")) if _look != null and _look.has_method("hour") else -1.0})
	print("HIGH PERCH LIVE %s at %s (%.1f m from crown)" % [name, _player.global_position, _flat(_player.global_position, CROWN)])


func _pin_hour(hour: float) -> void:
	if _look == null:
		return
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	var cycle: Variant = _look.get("_cycle")
	if cycle != null and _look.has_method("_apply_blended"):
		_look.set("_elapsed_seconds", float((cycle as Object).call("elapsed_for_hour", hour)))
		_look.call("_apply_blended", hour)


func _set_render(on: bool) -> void:
	RenderingServer.render_loop_enabled = on


func _hide_overlays() -> void:
	for node in root.find_children("*", "CanvasLayer", true, false):
		(node as CanvasLayer).visible = false


func _v(value: Vector3) -> Array:
	return [snappedf(value.x, 0.01), snappedf(value.y, 0.01), snappedf(value.z, 0.01)]


func _fail(message: String) -> bool:
	_failures.append(message)
	push_error("HIGH PERCH LIVE: " + message)
	return false


func _finish() -> void:
	_set_render(true)
	_release_all()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	LANE.contact_sheet(_frames, OUT + "/_sheet.png", 3, 640)
	var expected := 12
	var manifest := {"schema_version": 1, "tool": "tools/capture_cloudreach_high_perch_live.gd",
		"scene": "res://scenes/world/cloudreach_cliffs.tscn", "named_location": "The High Perches",
		"camera": "production CameraRig, processing on throughout; yaw written as the right stick; no evidence camera",
		"graphics_capture": _graphics_capture,
		"fixture_disclosure": "reset_for_new_game; realm cloudreach; scene instantiated directly; Act I-II flags incl. fly_traversal_unlocked (frame matrix BOOT_FLAGS); five-owned matrix party, Galecrest active and summoned, no loaner; trainer teleported to the arrival start in the air once per time of day, then Jump launches the glide; yaw written each physics frame as the stick; pitch -32 deg for the rim-out frame only; clock pinned; HUD hidden for each frame. Visual fixture, not earned unlock/trial/bond/save evidence.",
		"records": _records, "failures": _failures, "departure_repeated_ground_presses": _departure_jump_presses,
		"departure_launches": _departure_launches, "complete": _failures.is_empty() and _records.size() == expected,
		"finished_utc": Time.get_datetime_string_from_system(true)}
	var file := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	if file == null:
		_fail("final camera receipt could not be opened")
	else:
		var text := JSON.stringify(manifest, "\t") + "\n"
		file.store_string(text)
		file.flush()
		if file.get_error() != OK:
			_fail("final camera receipt could not be flushed")
		file.close()
		if FileAccess.get_file_as_string(OUT + "/manifest.json") != text:
			_fail("final camera receipt readback did not match")
	manifest.complete = _failures.is_empty() and _records.size() == expected
	print("HIGH PERCH LIVE %s: %d/%d frames, %d failures" % ["OK" if bool(manifest.complete) else "FAIL", _records.size(), expected, _failures.size()])
	quit(0 if bool(manifest.complete) else 1)
