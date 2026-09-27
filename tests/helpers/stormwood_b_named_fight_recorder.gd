extends Node

## F10#2 ordinary-route footage: a PASSIVE observer for whatever run it rides.
## It never moves, presses, heals, teleports, pins weather or hides anything.
## Each physics frame it looks at the current scene's production
## CombatManager; when that manager is fighting a Stormwood named wild (the
## body carries `stormwood_named_encounter` meta from the production
## catalogue), it records that fight:
##   - one row per fight: named id, engagement time, every tell (authored and
##     measured tell seconds, strike kind), every hit/miss, outcome, duration;
##   - with a rendering display, production-camera frames: `00-engaged`, one
##     every `interval` seconds (capped), and tell-start/mid/late/strike/impact/
##     recovery for the first four tells, plus `99-over`.
## Headless it records rows only. Rows go to `<out>/named_route.json` after
## every change so a run killed later still leaves its evidence.
##
## Add it once to the SceneTree root before the run starts; it follows scene
## changes (realm travel) by re-reading `current_scene` every frame.
##
## `gate_rendering` (display runs only): the render loop is switched off while
## no named fight is being recorded, so an hours-long earned route under xvfb
## is not throttled by drawing frames nobody keeps. It changes wall time only;
## headless runs never draw at all, and every game rule is untouched.

const MAX_INTERVAL_FRAMES := 40
const TELL_FRAMES := 4

var out_dir := ""
var interval_s := 1.0
var gate_rendering := false
var rows: Array = []

var _render := false
var _manager: Node = null
var _enemy: Node3D = null
var _row: Dictionary = {}
var _phys := 0
var _fight_phys0 := 0
var _next_interval := 0.0
var _interval_frames := 0
var _tell_open: Dictionary = {}
var _tell_index := 0
var _pending: Array[Dictionary] = []
var _saving := false
var _on_lunge := Callable()
var _on_strike := Callable()


func _init(out: String = "", interval: float = 1.0, gate: bool = false) -> void:
	out_dir = out
	interval_s = maxf(0.1, interval)
	gate_rendering = gate
	name = "StormwoodBNamedFightRecorder"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_render = DisplayServer.get_name() != "headless"
	if not out_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	print("NAMED_ROUTE recorder attached out=%s render=%s" % [out_dir, str(_render)])


func _physics_process(_delta: float) -> void:
	_phys += 1
	var manager := _current_manager()
	if manager != _manager:
		_detach_manager()
		_manager = manager
		if _manager != null:
			_manager.connect("hit_landed", _on_hit)
			_manager.connect("attack_missed", _on_miss)
	if _manager == null:
		return
	var fighting := bool(_manager.call("is_fighting"))
	var enemy: Node3D = _manager.call("enemy_body") as Node3D if fighting else null
	if not _row.is_empty() and (not fighting or enemy != _enemy):
		_end_fight("resolved" if not fighting else "enemy_changed")
	if _row.is_empty() and fighting and enemy != null and is_instance_valid(enemy):
		var id := str(enemy.get_meta("stormwood_named_encounter", ""))
		if not id.is_empty():
			_begin_fight(id, enemy)
	if _row.is_empty():
		return
	var ticks := Engine.physics_ticks_per_second
	var t := float(_phys - _fight_phys0) / float(ticks)
	if _render and t >= _next_interval and _interval_frames < MAX_INTERVAL_FRAMES:
		_pending.append({"tag": "i%02d" % _interval_frames, "at": _phys})
		_interval_frames += 1
		_next_interval += interval_s


func _process(_delta: float) -> void:
	if _render and gate_rendering:
		RenderingServer.render_loop_enabled = not _row.is_empty() or not _pending.is_empty() or _saving
	if not _render or _saving or _pending.is_empty():
		return
	var due: Dictionary = {}
	for p: Dictionary in _pending:
		if _phys >= int(p.at):
			due = p
			break
	if due.is_empty():
		return
	_pending.erase(due)
	_save(str(due.tag))


func _current_manager() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var manager := scene.get_node_or_null(^"CombatManager")
	return manager if manager != null and manager.has_method("enemy_body") else null


func _detach_manager() -> void:
	if _manager == null or not is_instance_valid(_manager):
		_manager = null
		return
	if _manager.is_connected("hit_landed", _on_hit):
		_manager.disconnect("hit_landed", _on_hit)
	if _manager.is_connected("attack_missed", _on_miss):
		_manager.disconnect("attack_missed", _on_miss)
	_manager = null


func _begin_fight(id: String, enemy: Node3D) -> void:
	_enemy = enemy
	_fight_phys0 = _phys
	_next_interval = 0.0
	_interval_frames = 0
	_tell_open = {}
	_tell_index = 0
	_pending.clear()
	var ordinal := 1
	for row: Dictionary in rows:
		if str(row.id) == id:
			ordinal += 1
	var game := get_tree().root.get_node_or_null(^"Game")
	_row = {
		"id": id, "attempt": ordinal, "prefix": "%s-a%d" % [id, ordinal],
		"engaged_msec": Time.get_ticks_msec(),
		"realm": str(game.get("current_realm")) if game != null else "",
		"time_scale": Engine.time_scale, "physics_hz": Engine.physics_ticks_per_second,
		"enemy_level": int(enemy.get("instance").get("level")) if enemy.get("instance") != null else -1,
		"party": _party_summary(game),
		"tells": [], "hits": [], "frames": [], "outcome": "",
	}
	enemy.connect("telegraph_started", _on_telegraph)
	_on_lunge = func(_h: Vector3, _d: float) -> void: _on_strike_begin("lunge_started")
	_on_strike = func() -> void: _on_strike_begin("strike_ready")
	enemy.connect("lunge_started", _on_lunge)
	enemy.connect("strike_ready", _on_strike)
	print("NAMED_ROUTE fight begin %s" % JSON.stringify(_row))
	if _render:
		_pending.append({"tag": "00-engaged", "at": _phys})
	rows.append(_row)
	_flush()


func _end_fight(reason: String) -> void:
	if is_instance_valid(_enemy):
		if _enemy.is_connected("telegraph_started", _on_telegraph):
			_enemy.disconnect("telegraph_started", _on_telegraph)
		if _enemy.is_connected("lunge_started", _on_lunge):
			_enemy.disconnect("lunge_started", _on_lunge)
		if _enemy.is_connected("strike_ready", _on_strike):
			_enemy.disconnect("strike_ready", _on_strike)
	var ticks := Engine.physics_ticks_per_second
	_row["seconds"] = snappedf(float(_phys - _fight_phys0) / float(ticks), 0.01)
	_row["end_reason"] = reason
	_row["outcome"] = _outcome()
	print("NAMED_ROUTE fight end %s" % JSON.stringify(_row))
	if _render:
		_pending.append({"tag": "99-over", "at": _phys + int(0.5 * ticks)})
	_flush()
	_row = {}
	_enemy = null
	_tell_open = {}


func _outcome() -> String:
	var game := get_tree().root.get_node_or_null(^"Game")
	if game == null or _row.is_empty():
		return "unknown"
	var flags: RefCounted = game.get("progression")
	var cleared := "stormwood:named:%s:cleared" % str(_row.id)
	return "cleared" if flags != null and bool(flags.call("has", cleared)) else "not_cleared"


func _on_telegraph(seconds: float) -> void:
	if _row.is_empty():
		return
	_tell_index += 1
	var ticks := Engine.physics_ticks_per_second
	_tell_open = {"n": _tell_index, "seconds": seconds, "start_phys": _phys}
	if _render and _tell_index <= TELL_FRAMES:
		_pending.append({"tag": "tell%d-a-start" % _tell_index, "at": _phys})
		_pending.append({"tag": "tell%d-b-mid" % _tell_index, "at": _phys + int(seconds * 0.5 * ticks)})
		_pending.append({"tag": "tell%d-c-late" % _tell_index, "at": _phys + int(seconds * 0.85 * ticks)})


func _on_strike_begin(kind: String) -> void:
	if _row.is_empty() or _tell_open.is_empty():
		return
	var n := int(_tell_open.n)
	var ticks := Engine.physics_ticks_per_second
	var measured := float(_phys - int(_tell_open.start_phys)) / float(ticks)
	(_row.tells as Array).append({"n": n, "authored_s": snappedf(float(_tell_open.seconds), 0.001),
		"measured_s": snappedf(measured, 0.001), "kind": kind,
		"at_s": snappedf(float(_phys - _fight_phys0) / float(ticks), 0.01)})
	_tell_open = {}
	if _render and n <= TELL_FRAMES:
		_pending.append({"tag": "tell%d-d-strike" % n, "at": _phys})
		_pending.append({"tag": "tell%d-e-impact" % n, "at": _phys + int(0.2 * ticks)})
		_pending.append({"tag": "tell%d-f-recovery" % n, "at": _phys + int(0.55 * ticks)})
	_flush()


func _on_hit(on_enemy: bool, amount: float) -> void:
	if _row.is_empty():
		return
	(_row.hits as Array).append({"at_s": _t(), "by": "ally" if on_enemy else "enemy",
		"amount": snappedf(amount, 0.1)})


func _on_miss(by_player: bool) -> void:
	if _row.is_empty():
		return
	(_row.hits as Array).append({"at_s": _t(), "by": "ally" if by_player else "enemy", "miss": true})


func _t() -> float:
	return snappedf(float(_phys - _fight_phys0) / float(Engine.physics_ticks_per_second), 0.01)


func _party_summary(game: Node) -> Array:
	var out: Array = []
	if game == null or game.get("party") == null:
		return out
	for creature: RefCounted in game.get("party").call("members"):
		if creature != null:
			out.append("%s L%d" % [str(creature.get("species_id")), int(creature.get("level"))])
	return out


func _save(tag: String) -> void:
	_saving = true
	var prefix := str(_row.get("prefix", "")) if not _row.is_empty() else str(rows.back().prefix) if not rows.is_empty() else "none"
	await RenderingServer.frame_post_draw
	if not out_dir.is_empty():
		var path := out_dir.path_join("%s-%s.png" % [prefix, tag])
		get_viewport().get_texture().get_image().save_png(path)
		for row: Dictionary in rows:
			if str(row.prefix) == prefix:
				(row.frames as Array).append(path.get_file())
	_saving = false


func _flush() -> void:
	if out_dir.is_empty():
		return
	var file := FileAccess.open(out_dir.path_join("named_route.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(rows, "  "))


func _exit_tree() -> void:
	if gate_rendering:
		RenderingServer.render_loop_enabled = true
