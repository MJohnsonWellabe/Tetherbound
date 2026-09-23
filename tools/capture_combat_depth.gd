extends "res://tests/smoke_combat.gd"

## Run only after acquiring the shared render lock, with a fresh user-data dir:
## godot --path . --resolution 1280x720 --script tools/capture_combat_depth.gd -- --out=D:/captures/combat-depth
## Uses only the base smoke's startup/adoption/walk/engage helpers, not its
## assertions or staged combat tests. Never edits fighter resources or stats.
## Optional --timeout-seconds=900 (30..3600), --max-frames=2400 (60..7200).
## The in-engine watchdog cannot interrupt synchronous asset loading; the
## launcher should also enforce an external process deadline for a stalled load.
const LOCK_PATH := "D:/tetherbound/RENDER_LOCK.json"
var _out := ""
var _capture_frame := 0
var _limit := 2400
var _timeout_seconds := 900.0
var _pressed_attack := ""
var _done := false
var _labels: Array[String] = []
var _trace: Array[Dictionary] = []
var _images: Array[Dictionary] = []
var _observed := {"telegraph": false, "stagger": false, "charged_impact": false}
var _seen_images := {"telegraph": false, "stagger": false, "charged_impact": false}
var _motion_left := 0
var _last_nudge := 0.0
var _strip: Image
var _strip_count := 0


func _run() -> void:
	# The inherited constructor dispatches here. Yield until derived fields exist.
	await process_frame
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): _out = arg.trim_prefix("--out=")
		if arg.begins_with("--max-frames="): _limit = clampi(int(arg.trim_prefix("--max-frames=")), 60, 7200)
		if arg.begins_with("--timeout-seconds="): _timeout_seconds = clampf(float(arg.trim_prefix("--timeout-seconds=")), 30.0, 3600.0)
	if _out.is_empty():
		push_error("capture_combat_depth requires --out=<directory>")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(_out) != OK:
		push_error("cannot create capture output directory")
		quit(1)
		return
	if not _owns_lock():
		_fail("shared render lock is not held_by combat; no scene boot or capture attempted")
		_finish()
		return
	create_timer(_timeout_seconds, true, false, true).timeout.connect(func() -> void:
		if not _done:
			_fail("%.0f-second wall-clock capture deadline exceeded" % _timeout_seconds)
			_finish())
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	# HUD priority resolves CombatManager through current_scene, as normal
	# scene startup does. add_child alone leaves exploration layers visible.
	current_scene = _world
	for i in SETTLE_FRAMES: await physics_frame
	await _ensure_ally()
	_leave_the_farmhouse()
	if not _collect_capture_nodes():
		_finish()
		return
	await _walk_to_the_wild_creature()
	if not _failures.is_empty():
		_finish()
		return
	_manager.staggered.connect(func(on_enemy: bool) -> void:
		_observed.stagger = true
		_queue_label("stagger")
		_trace.append({"frame": _capture_frame, "event": "stagger", "on_enemy": on_enemy}))
	_wild.telegraph_started.connect(func(seconds: float) -> void:
		_observed.telegraph = true
		_queue_label("telegraph")
		_trace.append({"frame": _capture_frame, "event": "telegraph", "seconds": seconds}))
	_manager.hit_landed.connect(func(on_enemy: bool, damage: float) -> void:
		_trace.append({"frame": _capture_frame, "event": "hit", "on_enemy": on_enemy,
			"damage": damage, "quick": bool((_manager.get("_pending_move") as Dictionary).get("is_quick", true))}))
	await _engage()
	if not _manager.is_fighting():
		_fail("real interact input did not enter combat")
		_finish()
		return
	_ally = _director.call("ally_body")
	_queue_label("combat_open")
	while _capture_frame < _limit and not _done:
		if not _owns_lock():
			_fail("shared render lock lost during capture run")
			break
		_release_inputs()
		if _manager.is_fighting(): _drive_capture_input()
		await physics_frame
		_capture_frame += 1
		var nudge := float(_rig.get("_impact_nudge_left"))
		if nudge > 0.0 and _last_nudge <= 0.0:
			_observed.charged_impact = true
			_queue_label("charged_impact")
		_last_nudge = nudge
		_trace.append(_snapshot())
		if not _labels.is_empty() or (_motion_left > 0 and _capture_frame % 3 == 0):
			await _capture()
		_motion_left = maxi(0, _motion_left - 1)
		if not _manager.is_fighting() and _motion_left <= 0: break
	_release_inputs()
	for event in _observed:
		if not bool(_observed[event]): _fail("required real event not observed: %s" % event)
		elif not bool(_seen_images[event]): _fail("event observed but no state-confirmed viewport frame: %s" % event)
	if _capture_frame >= _limit: _fail("bounded combat capture reached frame limit")
	_finish()


func _owns_lock() -> bool:
	var file := FileAccess.open(LOCK_PATH, FileAccess.READ)
	if file == null: return false
	var value: Variant = JSON.parse_string(file.get_as_text())
	return value is Dictionary and str(value.get("held_by", "")).to_lower() == "combat"


func _collect_capture_nodes() -> bool:
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _manager == null or _director == null:
		_fail("production Meadows scene is missing required combat nodes")
		return false
	_wild = _director.call("wild_creature") as Node3D
	if _wild == null or _director.call("ally_instance") == null:
		_fail("production starter or practice wild is unavailable")
		return false
	return true


func _queue_label(label: String) -> void:
	if not _labels.has(label): _labels.append(label)
	_motion_left = 30


func _release_inputs() -> void:
	if not _pressed_attack.is_empty():
		var event := InputEventAction.new()
		event.action = _pressed_attack
		event.pressed = false
		Input.parse_input_event(event)
		_pressed_attack = ""
	for action in ["move_forward", "move_back", "move_left", "move_right"]:
		Input.action_release(action)


func _drive_capture_input() -> void:
	if _manager.player_is_committed() or _manager.get("_hitstop_left") > 0.0: return
	var enemy: Node3D = _manager.enemy_body()
	if not is_instance_valid(enemy): return
	var toward := enemy.global_position - _ally.global_position
	toward.y = 0.0
	_aim_camera_along(toward)
	var reach := float(_manager.combat_move_reach("quick"))
	if toward.length() > reach - 0.2:
		Input.action_press("move_forward")
		return
	var action := ""
	if _manager.charged_ready():
		if _manager.enemy_is_winding_up() or _manager.enemy_is_staggered(): action = "combat_charged"
	elif _manager.quick_ready():
		action = "combat_quick"
	if not action.is_empty():
		var event := InputEventAction.new()
		event.action = action
		event.pressed = true
		Input.parse_input_event(event)
		_pressed_attack = action


func _snapshot() -> Dictionary:
	var creature: RefCounted = _manager.active_creature()
	var enemy := _manager.enemy_body() as Node3D
	return {"frame": _capture_frame, "ticks_usec": Time.get_ticks_usec(),
		"physics_frame": Engine.get_physics_frames(), "hitstop_left": float(_manager.get("_hitstop_left")),
		"ally_physics_enabled": _ally.is_physics_processing(),
		"enemy_physics_enabled": enemy.is_physics_processing() if is_instance_valid(enemy) else false,
		"enemy_position": [enemy.global_position.x, enemy.global_position.y, enemy.global_position.z] if is_instance_valid(enemy) else [],
		"fighting": _manager.is_fighting(), "telegraph": _manager.enemy_is_winding_up(),
		"enemy_staggered": _manager.enemy_is_staggered(), "player_staggered": _manager.player_is_staggered(),
		"player_action": int(_manager.get("_action")), "wind": _manager.wind_value(),
		"hp": float(creature.hp) if creature != null else -1.0,
		"camera_roll": _rig.rotation.z, "charged_nudge_left": float(_rig.get("_impact_nudge_left")),
		"ally_position": [_ally.global_position.x, _ally.global_position.y, _ally.global_position.z]}


func _capture() -> void:
	if _images.size() >= 120:
		_fail("capture safety ceiling reached (120 native frames)")
		_done = true
		return
	await RenderingServer.frame_post_draw
	# This is deliberately immediately adjacent to EVERY viewport readback.
	if not _owns_lock():
		_fail("lock lost immediately before viewport readback; capture refused")
		_done = true
		return
	var frame_image := root.get_texture().get_image()
	var path := _out.path_join("frame-%04d.png" % _images.size())
	if frame_image.save_png(path) != OK:
		_fail("could not save native viewport image")
		_done = true
		return
	var state := _snapshot()
	state["path"] = path
	state["requested_events"] = _labels.duplicate()
	_images.append(state)
	_seen_images.telegraph = bool(_seen_images.telegraph) or bool(state.telegraph)
	_seen_images.stagger = bool(_seen_images.stagger) or bool(state.enemy_staggered) or bool(state.player_staggered)
	_seen_images.charged_impact = bool(_seen_images.charged_impact) or float(state.charged_nudge_left) > 0.0
	_labels.clear()
	# A numbered contact sheet is secondary evidence; native frames are retained.
	if _strip_count < 24:
		var thumb: Image = frame_image.duplicate()
		thumb.resize(320, 180, Image.INTERPOLATE_LANCZOS)
		if _strip == null: _strip = Image.create(1280, 1080, false, Image.FORMAT_RGBA8)
		thumb.convert(Image.FORMAT_RGBA8)
		_strip.blit_rect(thumb, Rect2i(0, 0, 320, 180), Vector2i((_strip_count % 4) * 320, (_strip_count / 4) * 180))
		_strip_count += 1


func _finish() -> void:
	_release_inputs()
	_done = true
	if _strip != null: _strip.save_png(_out.path_join("motion-contact-sheet.png"))
	var file := FileAccess.open(_out.path_join("capture-report.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scope": "production Meadows native HUD capture; not visual approval",
			"timeout_seconds": _timeout_seconds, "max_frames": _limit,
			"setup": "existing smoke starter adoption and outdoor spawn staging; then actual walk/interact/combat input",
			"accepted": false, "capture_complete": _failures.is_empty(), "failures": _failures,
			"observed": _observed, "state_confirmed_images": _seen_images,
			"images": _images, "trace": _trace, "strip_order": "first 24 images, left to right, top to bottom"}, "  "))
	else:
		push_error("could not write capture report")
		quit(1)
		return
	print("Combat depth capture: %d frames, %d failures; %s" % [_images.size(), _failures.size(), _out])
	quit(0 if _failures.is_empty() else 1)
