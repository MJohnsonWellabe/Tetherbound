extends SceneTree

## W03-S08-FREEZE-0904. Differential reproduction of CL-H14: S08-22 (crossing ->
## Ironwood Grove) pinning at (-164.12, -9.13, 4334.56) for its whole budget.
##
## Two modes, one walker, one per-frame log format, so the two logs can be
## diffed column for column:
##
##   --mode=loaded     the S08 path: boot the title, seed slot 4 from
##                     `--save=<S07-exit.json>`, `Game.load_game(4)`, change
##                     scene to the Meadows (exactly what title_screen.gd's
##                     Load does), settle `--settle` physics frames, optionally
##                     tap `creature_recall` (S08-09a), then walk S08-22's leg.
##   --mode=isolated   probe_ironwood_approach.gd's path: fresh world, teleport
##                     body+rig to the seed's settle point, walk the same leg.
##
## Per frame, the log records: position, velocity, is_on_floor, terrain height
## under the body, the camera rig's position and its distance from the body,
## the stick the navigator asked for, the navigator's own private state, the
## slide collisions (collider name + normal) from the previous move_and_slide,
## who owns input, locomotion_enabled/carried, and the unstick counter.
##
## When the body has not moved 1 cm in `FREEZE_FRAMES` frames with the stick
## held, the probe dumps a one-shot spatial diagnosis (8-direction test_move,
## a sphere query for every physics body within 6 m, downward rays and the
## heightmap answer) and, with --stop-on-freeze, stops there.
##
##   godot --headless --path . --script tools/gate_f/probe_s08_freeze_repro.gd -- \
##       --mode=loaded --save=<dir>/S07-exit.json --log=<dir>/loaded.csv [--deploy] \
##       [--settle=10800] [--budget=45000] [--stop-on-freeze]
##       [--navigator=res://tools/gate_f/probe_s08_freeze_legacy_navigator.gd]
##       [--start=x,y,z]   isolated mode only: where to stand the body first
##
## `--navigator` swaps in a different walker script for the SAME leg -- the
## controlled A/B this lane's root cause rests on. Default is the live
## `tests/helpers/stick_navigator.gd`.

const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const PROBE := preload("res://scripts/debug/gate_f_probe.gd")

## probe_ironwood_approach.gd's own hard-coded start. NOT where the entry save
## actually settles today -- `--start=x,y,z` overrides it, and the difference
## between these two heights is what decides whether the leg walks into the
## thicket at (-164.12, -9.13, 4334.56) or west of it.
const ISOLATED_START := Vector3(-152.0, -2.15, 4238.0)
const TARGET := Vector2(-345.0, 5060.0)
const CLOSE_ENOUGH := 5.0
const FREEZE_FRAMES := 600
const SLOT := 4

var _mode := "loaded"
var _save := ""
var _log_path := ""
var _deploy := false
var _settle := 10800
var _budget := 45000
var _stop_on_freeze := false
var _summary_every := 300

var _player: CharacterBody3D = null
var _rig: Node3D = null
var _world: Node = null
var _stick := Vector2.ZERO
var _log: FileAccess = null
var _probe: RefCounted = null
var _start := ISOLATED_START
var _navigator_path := ""
var _navigator_script: GDScript = null


func _init() -> void:
	_run()


func _arg(name: String, default: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % name):
			return a.substr(name.length() + 3)
	return default


func _flag(name: String) -> bool:
	return OS.get_cmdline_user_args().has("--%s" % name)


func _run() -> void:
	_mode = _arg("mode", "loaded")
	_save = _arg("save", "")
	_log_path = _arg("log", "")
	_deploy = _flag("deploy")
	_settle = int(_arg("settle", "10800"))
	_budget = int(_arg("budget", "45000"))
	_stop_on_freeze = _flag("stop-on-freeze")
	var start_raw := _arg("start", "")
	if not start_raw.is_empty():
		var parts := start_raw.split(",")
		if parts.size() == 3:
			_start = Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	_navigator_path = _arg("navigator", "")
	_navigator_script = NAVIGATOR
	if not _navigator_path.is_empty():
		var loaded_script := load(_navigator_path) as GDScript
		if loaded_script == null:
			print("PROBE FAIL: could not load navigator %s" % _navigator_path)
			quit(2)
			return
		_navigator_script = loaded_script
	if _log_path.is_empty():
		print("PROBE FAIL: --log=<csv path> is required")
		quit(2)
		return
	_log = FileAccess.open(_log_path, FileAccess.WRITE)
	if _log == null:
		print("PROBE FAIL: cannot write %s" % _log_path)
		quit(2)
		return
	_probe = PROBE.new(self)
	_log.store_line("frame,walked,px,py,pz,vx,vy,vz,on_floor,ground_h,rig_x,rig_y,rig_z,rig_dist,rig_yaw,"
		+ "stick_x,stick_y,nav_gap,nav_stall,nav_detour_left,nav_side,nav_side_detours,nav_recovering,"
		+ "slides,colliders,input_owner,locomotion,carried,unstick,input_ctx")

	if _mode == "loaded":
		if not await _boot_loaded():
			quit(1)
			return
	else:
		if not await _boot_isolated():
			quit(1)
			return

	print("=== S08 freeze repro: mode=%s deploy=%s settle=%d budget=%d ===" % [_mode, str(_deploy), _settle, _budget])
	print("body at %s; rig at %s; ground_h %.2f" % [str(_player.global_position), str(_rig.global_position),
		_ground_h(_player.global_position)])

	print("walker: %s" % (_navigator_path if not _navigator_path.is_empty() else "res://tests/helpers/stick_navigator.gd"))
	var nav: RefCounted = _navigator_script.new(self, _player, _rig,
		func(x: float, y: float) -> void: _stick = Vector2(x, y); _drive_sticks())
	nav.call("reset")
	var walked := 0
	var held := 0
	var frame := 0
	var arrived := false
	var last_pos := _player.global_position
	var still := 0
	var froze_at := -1
	var frozen_dumped := false
	while walked < _budget:
		var target := Vector3(TARGET.x, _player.global_position.y, TARGET.y)
		var gh := _ground_h(target)
		if not is_nan(gh):
			target.y = gh
		var to := target - _player.global_position
		to.y = 0.0
		if to.length() <= CLOSE_ENOUGH:
			arrived = true
			break
		var can_walk: bool = bool(nav.call("can_walk"))
		if not can_walk:
			held += 1
			_stick = Vector2.ZERO
			_drive_sticks()
			nav.call("reset")
			await physics_frame
			frame += 1
			_log_row(frame, walked, nav)
			if held > 10800:
				print("PROBE: held budget exhausted")
				break
			continue
		walked += 1
		await nav.call("step", target)
		frame += 1
		_log_row(frame, walked, nav)
		var moved := _player.global_position.distance_to(last_pos)
		last_pos = _player.global_position
		if moved < 0.01 and _stick.length() > 0.05:
			still += 1
		else:
			still = 0
		if still == FREEZE_FRAMES and not frozen_dumped:
			frozen_dumped = true
			froze_at = frame
			print("PROBE: FROZEN for %d frames at %s (walked %d)" % [FREEZE_FRAMES, str(_player.global_position), walked])
			_dump_spatial()
			if _stop_on_freeze:
				break
		if frame % _summary_every == 0:
			var p := _player.global_position
			print("[t=%6.1fs walked=%5d] pos (%.2f, %.2f, %.2f) vel %.2f on_floor=%s gh=%.2f rig_dist=%.1f stick=(%.2f,%.2f) slides=%d %s" % [
				float(frame) / 60.0, walked, p.x, p.y, p.z, _player.velocity.length(), str(_player.is_on_floor()),
				_ground_h(p), _rig.global_position.distance_to(p), _stick.x, _stick.y,
				_player.get_slide_collision_count(), _collider_names()])
	_stick = Vector2.ZERO
	_drive_sticks()
	await physics_frame
	_log.close()
	var p := _player.global_position
	var remaining := Vector2(p.x - TARGET.x, p.z - TARGET.y).length()
	print("RESULT mode=%s arrived=%s walked=%d held=%d frames=%d froze_at=%d final (%.2f, %.2f, %.2f) %.1f m short" % [
		_mode, str(arrived), walked, held, frame, froze_at, p.x, p.y, p.z, remaining])
	quit(0)


func _boot_loaded() -> bool:
	if _save.is_empty() or not FileAccess.file_exists(_save):
		print("PROBE FAIL: --save=<S07-exit.json> missing (%s)" % _save)
		return false
	var title: Node = (load(TITLE_SCENE) as PackedScene).instantiate()
	root.add_child(title)
	current_scene = title
	for i in 30:
		await physics_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("PROBE FAIL: no Game autoload")
		return false
	var system: Variant = game.get("save_system")
	var dst := ProjectSettings.globalize_path(str(system.call("slot_path", SLOT)))
	DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
	var out := FileAccess.open(dst, FileAccess.WRITE)
	out.store_buffer(FileAccess.get_file_as_bytes(_save))
	out.close()
	if not bool(game.call("load_game", SLOT)):
		print("PROBE FAIL: load_game(%d) refused" % SLOT)
		return false
	print("PROBE: load_game ok; changing scene to the Meadows (title_screen.gd's own path)")
	change_scene_to_file(WORLD_SCENE)
	var waited := 0
	while waited < 600:
		await physics_frame
		waited += 1
		if current_scene != null and current_scene.scene_file_path == WORLD_SCENE \
				and current_scene.get_node_or_null(^"Player") != null:
			break
	_world = current_scene
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("PROBE FAIL: world came up without Player/CameraRig")
		return false
	print("PROBE: world up after %d frames; body at %s rig at %s" % [waited, str(_player.global_position), str(_rig.global_position)])
	for i in _settle:
		await physics_frame
		if i % 1800 == 0:
			print("  settle %d/%d body %s rig_dist %.1f" % [i, _settle, str(_player.global_position),
				_rig.global_position.distance_to(_player.global_position)])
	if _deploy:
		print("PROBE: tapping creature_recall (S08-09a)")
		await _tap("creature_recall")
		for i in 120:
			await physics_frame
		print("PROBE: after deploy: ally=%s" % _ally_desc())
	return true


func _boot_isolated() -> bool:
	_world = (load(WORLD_SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in 300:
		await physics_frame
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		return false
	_player.global_position = _start
	_player.velocity = Vector3.ZERO
	_rig.global_position = _start
	for i in 90:
		await physics_frame
	return true


func _tap(action: String) -> void:
	var binding: InputEvent = null
	for event in InputMap.action_get_events(StringName(action)):
		if event is InputEventJoypadButton:
			binding = event
			break
	if binding == null:
		Input.action_press(StringName(action))
	else:
		var b := InputEventJoypadButton.new()
		b.button_index = (binding as InputEventJoypadButton).button_index
		b.pressed = true
		Input.parse_input_event(b)
	await process_frame
	await physics_frame
	if binding == null:
		Input.action_release(StringName(action))
	else:
		var b := InputEventJoypadButton.new()
		b.button_index = (binding as InputEventJoypadButton).button_index
		b.pressed = false
		Input.parse_input_event(b)
	await process_frame
	await physics_frame


## Mirrors operator_harness.gd::_drive_sticks/_press_axis: action strength plus
## the physical joypad motion event, both, so the player reads the same thing
## the harness makes it read.
func _drive_sticks() -> void:
	_press_axis(&"move_right", clampf(_stick.x, 0.0, 1.0))
	_press_axis(&"move_left", clampf(-_stick.x, 0.0, 1.0))
	_press_axis(&"move_back", clampf(_stick.y, 0.0, 1.0))
	_press_axis(&"move_forward", clampf(-_stick.y, 0.0, 1.0))


func _press_axis(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength <= 0.001:
		Input.action_release(action)
	else:
		Input.action_press(action, strength)
	for event in InputMap.action_get_events(action):
		var motion := event as InputEventJoypadMotion
		if motion == null:
			continue
		var m := InputEventJoypadMotion.new()
		m.device = 0
		m.axis = motion.axis
		m.axis_value = signf(motion.axis_value) * strength
		Input.parse_input_event(m)
		return


func _ground_h(at: Vector3) -> float:
	if _world != null and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", at.x, at.z))
	return NAN


func _collider_names() -> String:
	var names: Array[String] = []
	for i in _player.get_slide_collision_count():
		var c := _player.get_slide_collision(i)
		var col := c.get_collider()
		var n := c.get_normal()
		names.append("%s(%.2f;%.2f;%.2f)" % [str(col.name) if col != null else "?", n.x, n.y, n.z])
	return "|".join(names)


func _ally_desc() -> String:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null:
		for n in _world.get_children():
			if str(n.get_script().resource_path if n.get_script() != null else "").ends_with("encounter_director.gd"):
				director = n
				break
	if director == null:
		return "no director"
	var body: Node3D = director.call("ally_body") as Node3D
	if body == null:
		return "none"
	return "%s at %s (%.1f m from body) layer=%s mask=%s" % [str(body.name), str(body.global_position),
		body.global_position.distance_to(_player.global_position), str(body.get("collision_layer")), str(body.get("collision_mask"))]


func _log_row(frame: int, walked: int, nav: RefCounted) -> void:
	var p := _player.global_position
	var v := _player.velocity
	var r := _rig.global_position
	var owner := INPUT_OWNER.current(self)
	var ctx := str(_probe.call("input_context"))
	_log.store_line("%d,%d,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%s,%.3f,%.2f,%.2f,%.2f,%.2f,%.3f,%.3f,%.3f,%.2f,%d,%d,%.0f,%d,%s,%d,%s,%s,%s,%s,%d,%s" % [
		frame, walked, p.x, p.y, p.z, v.x, v.y, v.z, str(_player.is_on_floor()), _ground_h(p),
		r.x, r.y, r.z, r.distance_to(p), float(_rig.get("yaw")),
		_stick.x, _stick.y, float(nav.get("_gap")), int(nav.get("_stall")), int(nav.get("_detour_left")),
		float(nav.get("_side")), int(nav.get("_side_detours")), str(nav.get("_recovering")),
		_player.get_slide_collision_count(), _collider_names(),
		str(owner.name) if owner != null else "-", str(_player.call("locomotion_enabled")),
		str(_player.call("is_carried")), int(_player.call("unstick_count")), ctx])


func _dump_spatial() -> void:
	var p := _player.global_position
	print("--- spatial diagnosis at (%.2f, %.2f, %.2f) ---" % [p.x, p.y, p.z])
	print("  heightmap ground_h = %.2f ; on_floor=%s ; vel=%s" % [_ground_h(p), str(_player.is_on_floor()), str(_player.velocity)])
	print("  input owner=%s locomotion=%s carried=%s unstick=%d" % [
		str(INPUT_OWNER.current(self)), str(_player.call("locomotion_enabled")),
		str(_player.call("is_carried")), int(_player.call("unstick_count"))])
	print("  slide collisions: %s" % _collider_names())
	var space := _player.get_world_3d().direct_space_state
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var dir := Vector3(sin(angle), 0.0, cos(angle))
		var blocked := _player.test_move(_player.global_transform, dir * 0.5)
		var blocked_up := _player.test_move(_player.global_transform.translated(Vector3.UP * 0.4), dir * 0.5)
		print("  test_move %3d deg: blocked=%s raised=%s" % [int(rad_to_deg(angle)), str(blocked), str(blocked_up)])
	var sphere := SphereShape3D.new()
	sphere.radius = 6.0
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sphere
	q.transform = Transform3D(Basis(), p)
	q.collide_with_areas = true
	q.collide_with_bodies = true
	q.exclude = [_player.get_rid()]
	for hit in space.intersect_shape(q, 64):
		var col: Object = hit.get("collider")
		var desc := str(col.name) if col is Node else str(col)
		var pos := str((col as Node3D).global_position) if col is Node3D else "?"
		var layer: Variant = col.get("collision_layer") if col is CollisionObject3D else "-"
		print("  within 6 m: %s at %s layer=%s class=%s" % [desc, pos, str(layer), col.get_class()])
	for dy in [1.0, 3.0]:
		var from: Vector3 = p + Vector3.UP * float(dy)
		var rq := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 12.0)
		rq.exclude = [_player.get_rid()]
		var hit := space.intersect_ray(rq)
		if hit.is_empty():
			print("  ray from +%.0f m down 12 m: NO HIT" % dy)
		else:
			print("  ray from +%.0f m down 12 m: hit %s at y=%.2f" % [dy, str((hit["collider"] as Node).name), (hit["position"] as Vector3).y])
	print("  rig at %s (dist %.1f)" % [str(_rig.global_position), _rig.global_position.distance_to(p)])
	print("  ally: %s" % _ally_desc())
	print("--- end diagnosis ---")
