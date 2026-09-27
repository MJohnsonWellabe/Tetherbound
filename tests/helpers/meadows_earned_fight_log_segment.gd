extends Node

## F04#4 / F04#6 observer for the continuous Meadows run (ACCEPTANCE §6.1 F04:
## "... three captains and Warden each have ... a real hit/avoidance witness,
## the specified tell/recovery and a distinct aftermath").
##
## PASSIVE, like the route ledger: it never presses, moves, heals, writes a
## flag or touches a save. The smoke adds it to the SceneTree root with
## `--fight-log`; without that flag this file is never loaded. It follows scene
## changes (title Loads, the Rift) by re-reading `current_scene` every frame.
##
## Every trainer battle the production EncounterDirector runs is one FIGHT:
## from `trainer_battle_id()` turning non-empty to it turning empty (or
## changing). For each fight it records, from the production CombatManager
## and the enemy body's own signals:
##   - `hit_landed(on_enemy, amount)`: a hit dealt (true) or taken (false);
##   - `attack_missed(by_player)`: the player's creature missing (true), or an
##     enemy swing connecting with nobody (false) -- AVOIDANCE: COMBAT has no
##     dodge button, "movement is the dodge", so an enemy miss is the dodge;
##   - `staggered(on_enemy)`;
##   - the enemy body's `telegraph_started(seconds)` (a tell) and its
##     `lunge_started` / `strike_ready` (the strike after it); each tell is then
##     resolved as `hit` (a hit taken), `avoided` (an enemy miss) or `none`;
##   - rounds (`entered` / `exited(outcome)`), duration and the trainer's
##     defeat flag afterwards.
## Each event carries the ally-to-enemy distance and the ally's speed at that
## moment, so an avoidance can be read as movement rather than luck.
##
## One `FIGHT LOG {json}` line per fight; `summary()` gives the per-target
## table (the three Sigil captains and the Warden) the smoke prints at the end.
##
## `--aftermath-capture` (F04#6): for a TARGET fight only, when the display is
## not headless, one viewport PNG AFTERMATH_DELAY_S after the fight resolves to
## `user://aftermath/<fight>.png`, with `<fight>.json` beside it saying what the
## frame was taken with (positions, camera, which bodies were in the frustum).
## Headless it records `"capture": "skipped_headless"` and draws nothing.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const CLIMAX_CONFIG := "res://data/config/stronghold_climax.json"
const CAPTAIN_IDS := ["captain_riverwatch", "captain_field", "captain_ridge"]
const AFTERMATH_DIR := "user://aftermath"
const AFTERMATH_DELAY_S := 0.75
## An enemy tell counts as resolved by the first hit/miss this long after it.
const TELL_WINDOW_S := 3.0

var capture_aftermath := false
var rows: Array = []
var targets: Array = []

var _render := false
var _phys := 0
var _row: Dictionary = {}
var _id := ""
var _fight_phys0 := 0
var _manager: Node = null
var _director: Node = null
var _enemy: Node3D = null
var _enemy_callables: Array = []
var _open_tells: Array = []
var _pending_capture: Array = []
var _capturing := false


func _init(capture: bool = false) -> void:
	capture_aftermath = capture
	name = "MeadowsFightLog"
	process_mode = Node.PROCESS_MODE_ALWAYS
	targets = CAPTAIN_IDS.duplicate()
	var climax: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLIMAX_CONFIG))
	var warden := str(((climax as Dictionary).get("warden", {}) as Dictionary).get("trainer", "")) \
		if climax is Dictionary else ""
	targets.append(warden if not warden.is_empty() else "warden_aldis")


func _ready() -> void:
	_render = DisplayServer.get_name() != "headless"
	if capture_aftermath and _render:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AFTERMATH_DIR))
	print("FIGHT LOG observer attached targets=%s aftermath_capture=%s render=%s" % [
		JSON.stringify(targets), str(capture_aftermath), str(_render)])


func _physics_process(_delta: float) -> void:
	_phys += 1
	var scene := get_tree().current_scene
	var director: Node = scene.get_node_or_null(^"EncounterDirector") if scene != null else null
	var manager: Node = scene.get_node_or_null(^"CombatManager") if scene != null else null
	if director != null and not director.has_method("trainer_battle_id"):
		director = null
	var id := str(director.call("trainer_battle_id")) if director != null else ""
	if not _row.is_empty() and (id != _id or director != _director):
		_end_fight("resolved" if id.is_empty() else "changed")
	if _row.is_empty() and not id.is_empty():
		_begin_fight(id, director, manager)
	if _row.is_empty():
		return
	if manager != _manager:
		_bind_manager(manager)
	var enemy: Node3D = null
	if _manager != null and bool(_manager.call("is_fighting")):
		enemy = _manager.call("enemy_body") as Node3D
	if enemy != _enemy:
		_bind_enemy(enemy)
	# Tells older than the window resolve as `none` (the swing never came).
	for tell: Dictionary in _open_tells.duplicate():
		if _t() - float(tell["at_s"]) > TELL_WINDOW_S:
			tell["resolved"] = "none"
			_open_tells.erase(tell)


func _process(_delta: float) -> void:
	if _capturing or _pending_capture.is_empty():
		return
	var due: Dictionary = _pending_capture[0]
	if _phys < int(due["at"]):
		return
	_pending_capture.pop_front()
	_capture(due)


## --- fight lifecycle ----------------------------------------------------------------

func _begin_fight(id: String, director: Node, manager: Node) -> void:
	_id = id
	_director = director
	_fight_phys0 = _phys
	_open_tells.clear()
	var game := get_tree().root.get_node_or_null(^"Game")
	var attempt := 1
	for row: Dictionary in rows:
		if str(row["id"]) == id:
			attempt += 1
	_row = {"id": id, "attempt": attempt, "target": targets.has(id),
		"realm": str(game.get("current_realm")) if game != null else "",
		"physics_hz": Engine.physics_ticks_per_second, "time_scale": Engine.time_scale,
		"start_game_frame": Engine.get_physics_frames(), "party": _party(game),
		"rounds": [], "events": [], "tells": []}
	_bind_manager(manager)
	# A round the manager entered before this frame saw the battle id.
	if _manager != null and bool(_manager.call("is_fighting")):
		(_row["rounds"] as Array).append({"start_s": 0.0, "enemy": "", "entered_before_bind": true})
	print("FIGHT LOG begin %s" % JSON.stringify({"id": id, "attempt": attempt, "target": targets.has(id)}))


func _end_fight(reason: String) -> void:
	_bind_enemy(null)
	_bind_manager(null)
	for tell: Dictionary in _open_tells:
		tell["resolved"] = "none"
	_open_tells.clear()
	var spec := TRAINERS.trainer(_id)
	var flag := str(spec.get("defeat_flag", ""))
	var game := get_tree().root.get_node_or_null(^"Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	var won := progression != null and not flag.is_empty() and bool(progression.call("has", flag))
	_row["end_reason"] = reason
	_row["duration_s"] = _t()
	_row["defeat_flag"] = flag
	_row["outcome"] = "won" if won else "not_won"
	_row["totals"] = totals(_row)
	var fight := "%s-a%d" % [_id, int(_row["attempt"])]
	if bool(_row["target"]) and capture_aftermath:
		if _render:
			_row["capture"] = "%s/%s.png" % [AFTERMATH_DIR, fight]
			_pending_capture.append({"at": _phys + int(AFTERMATH_DELAY_S * Engine.physics_ticks_per_second),
				"fight": fight, "id": _id})
		else:
			_row["capture"] = "skipped_headless"
	rows.append(_row)
	print("FIGHT LOG %s" % JSON.stringify(_row))
	_row = {}
	_id = ""
	_director = null


## Pure: per-fight counts from a row's events and tells.
static func totals(row: Dictionary) -> Dictionary:
	var out := {"hits_dealt": 0, "damage_dealt": 0.0, "hits_taken": 0, "damage_taken": 0.0,
		"player_misses": 0, "avoided": 0, "staggers_dealt": 0, "staggers_taken": 0,
		"tells": 0, "tells_hit": 0, "tells_avoided": 0, "tells_unresolved": 0,
		"rounds": (row.get("rounds", []) as Array).size(), "rounds_won": 0}
	for raw: Variant in row.get("events", []):
		var ev := raw as Dictionary
		match str(ev.get("ev", "")):
			"hit_dealt":
				out["hits_dealt"] += 1
				out["damage_dealt"] += float(ev.get("amount", 0.0))
			"hit_taken":
				out["hits_taken"] += 1
				out["damage_taken"] += float(ev.get("amount", 0.0))
			"player_miss":
				out["player_misses"] += 1
			"avoided":
				out["avoided"] += 1
			"stagger_dealt":
				out["staggers_dealt"] += 1
			"stagger_taken":
				out["staggers_taken"] += 1
	for raw: Variant in row.get("tells", []):
		out["tells"] += 1
		match str((raw as Dictionary).get("resolved", "none")):
			"hit":
				out["tells_hit"] += 1
			"avoided":
				out["tells_avoided"] += 1
			_:
				out["tells_unresolved"] += 1
	for raw: Variant in row.get("rounds", []):
		if str((raw as Dictionary).get("outcome", "")) == "won":
			out["rounds_won"] += 1
	out["damage_dealt"] = snappedf(float(out["damage_dealt"]), 0.1)
	out["damage_taken"] = snappedf(float(out["damage_taken"]), 0.1)
	out["witness"] = int(out["hits_dealt"]) > 0 and int(out["hits_taken"]) + int(out["avoided"]) > 0
	return out


## Per-target table (three captains and the Warden) plus every other logged
## trainer fight by id. `f04_4_witnessed`: every target has a won fight with at
## least one hit dealt and at least one hit taken or avoided.
func summary() -> Dictionary:
	var per: Dictionary = {}
	for row: Dictionary in rows:
		var id := str(row["id"])
		var t: Dictionary = row["totals"]
		per[id] = {"attempts": int((per.get(id, {}) as Dictionary).get("attempts", 0)) + 1,
			"outcome": row["outcome"], "duration_s": row["duration_s"], "target": row["target"],
			"hits_dealt": t["hits_dealt"], "hits_taken": t["hits_taken"], "avoided": t["avoided"],
			"player_misses": t["player_misses"], "tells": t["tells"], "tells_hit": t["tells_hit"],
			"tells_avoided": t["tells_avoided"], "rounds": t["rounds"], "witness": t["witness"],
			"capture": row.get("capture", "")}
	var missing: Array = []
	for id: String in targets:
		var entry: Dictionary = per.get(id, {})
		if entry.is_empty() or str(entry["outcome"]) != "won" or not bool(entry["witness"]):
			missing.append(id)
	var out := {"targets": targets, "fights": rows.size(), "per_fight": per,
		"f04_4_witnessed": missing.is_empty(), "missing_or_unwitnessed": missing}
	# A fight still running when the run stopped (a failed stage): its counts
	# so far, so an abort still shows what the fight did.
	if not _row.is_empty():
		out["open_fight"] = {"id": _id, "seconds_so_far": _t(), "rounds": _row["rounds"],
			"totals": totals(_row)}
	return out


## --- signal binding ------------------------------------------------------------------

func _bind_manager(manager: Node) -> void:
	if _manager != null and is_instance_valid(_manager):
		for pair: Array in _manager_callables():
			if _manager.is_connected(pair[0], pair[1]):
				_manager.disconnect(pair[0], pair[1])
	_manager = manager if manager != null and manager.has_method("enemy_body") else null
	if _manager != null:
		for pair: Array in _manager_callables():
			if _manager.has_signal(pair[0]) and not _manager.is_connected(pair[0], pair[1]):
				_manager.connect(pair[0], pair[1])


func _manager_callables() -> Array:
	return [["hit_landed", _on_hit], ["attack_missed", _on_miss], ["staggered", _on_stagger],
		["entered", _on_entered], ["exited", _on_exited]]


func _bind_enemy(enemy: Node3D) -> void:
	if _enemy != null and is_instance_valid(_enemy):
		for pair: Array in _enemy_callables:
			if _enemy.is_connected(pair[0], pair[1]):
				_enemy.disconnect(pair[0], pair[1])
	_enemy_callables.clear()
	_enemy = enemy if enemy != null and is_instance_valid(enemy) else null
	if _enemy == null:
		return
	var tell := func(seconds: float) -> void: _on_tell(seconds)
	var lunge := func(_h: Vector3, _d: float) -> void: _on_strike("lunge_started")
	var strike := func() -> void: _on_strike("strike_ready")
	for pair: Array in [["telegraph_started", tell], ["lunge_started", lunge], ["strike_ready", strike]]:
		if _enemy.has_signal(pair[0]):
			_enemy.connect(pair[0], pair[1])
			_enemy_callables.append(pair)


func _on_entered() -> void:
	if _row.is_empty():
		return
	(_row["rounds"] as Array).append({"start_s": _t(), "enemy": _enemy_label()})


func _on_exited(outcome: String) -> void:
	if _row.is_empty() or (_row["rounds"] as Array).is_empty():
		return
	var last: Dictionary = (_row["rounds"] as Array).back()
	last["end_s"] = _t()
	last["outcome"] = outcome


func _on_hit(on_enemy: bool, amount: float) -> void:
	if _row.is_empty():
		return
	_event("hit_dealt" if on_enemy else "hit_taken", snappedf(amount, 0.1))
	if not on_enemy:
		_resolve_tell("hit")


func _on_miss(by_player: bool) -> void:
	if _row.is_empty():
		return
	_event("player_miss" if by_player else "avoided")
	if not by_player:
		_resolve_tell("avoided")


func _on_stagger(on_enemy: bool) -> void:
	if not _row.is_empty():
		_event("stagger_dealt" if on_enemy else "stagger_taken")


func _on_tell(seconds: float) -> void:
	if _row.is_empty():
		return
	var tell := {"at_s": _t(), "authored_s": snappedf(seconds, 0.001), "strike_s": -1.0,
		"strike_kind": "", "resolved": "", "enemy": _enemy_label()}
	(_row["tells"] as Array).append(tell)
	_open_tells.append(tell)


func _on_strike(kind: String) -> void:
	for tell: Dictionary in _open_tells:
		if float(tell["strike_s"]) < 0.0:
			tell["strike_s"] = _t()
			tell["strike_kind"] = kind
			tell["measured_tell_s"] = snappedf(_t() - float(tell["at_s"]), 0.01)
			return


func _resolve_tell(how: String) -> void:
	if _open_tells.is_empty():
		return
	var tell: Dictionary = _open_tells.pop_front()
	tell["resolved"] = how
	tell["resolved_s"] = _t()


func _event(kind: String, amount: float = 0.0) -> void:
	var ev := {"t": _t(), "ev": kind}
	if amount != 0.0:
		ev["amount"] = amount
	var ally := _director.call("ally_body") as Node3D \
		if _director != null and is_instance_valid(_director) and _director.has_method("ally_body") else null
	if ally != null and is_instance_valid(ally):
		if _enemy != null and is_instance_valid(_enemy):
			ev["dist_m"] = snappedf(ally.global_position.distance_to(_enemy.global_position), 0.01)
		if ally is CharacterBody3D:
			var v := (ally as CharacterBody3D).velocity
			ev["ally_speed"] = snappedf(Vector2(v.x, v.z).length(), 0.01)
	(_row["events"] as Array).append(ev)


func _enemy_label() -> String:
	if _enemy == null or not is_instance_valid(_enemy):
		return ""
	var species: Variant = _enemy.get("species_id")
	return str(species) if species != null else str(_enemy.name)


func _t() -> float:
	return snappedf(float(_phys - _fight_phys0) / float(Engine.physics_ticks_per_second), 0.01)


func _party(game: Node) -> Array:
	var out: Array = []
	var party: RefCounted = game.get("party") if game != null else null
	if party == null:
		return out
	for i in int(party.call("size")):
		var c: Variant = party.call("at", i)
		if c != null:
			out.append("%s L%d" % [str(c.get("species_id")), int(c.get("level"))])
	return out


## --- F04#6 aftermath frame ----------------------------------------------------------

func _capture(due: Dictionary) -> void:
	_capturing = true
	await RenderingServer.frame_post_draw
	var fight := str(due["fight"])
	var path := "%s/%s.png" % [AFTERMATH_DIR, fight]
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(path) if image != null else ERR_CANT_CREATE
	var context := _frame_context(str(due["id"]))
	context["png"] = path
	context["saved"] = err == OK
	var file := FileAccess.open("%s/%s.json" % [AFTERMATH_DIR, fight], FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(context, "  "))
		file.close()
	print("AFTERMATH CAPTURE %s" % JSON.stringify(context))
	_capturing = false


func _frame_context(id: String) -> Dictionary:
	var scene := get_tree().current_scene
	var camera := get_viewport().get_camera_3d()
	var out := {"fight": id, "game_frame": Engine.get_physics_frames(),
		"size": [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y]}
	var bodies := {}
	var player := scene.get_node_or_null(^"Player") as Node3D if scene != null else null
	if player != null:
		bodies["player"] = player
	var director := scene.get_node_or_null(^"EncounterDirector") if scene != null else null
	if director != null and director.has_method("ally_body"):
		var ally := director.call("ally_body") as Node3D
		if ally != null and is_instance_valid(ally):
			bodies["ally"] = ally
	var trainer := _trainer_node(scene, id)
	if trainer != null:
		bodies["trainer"] = trainer
	for key: String in bodies:
		var body := bodies[key] as Node3D
		var p := body.global_position
		var row := {"pos": [snappedf(p.x, 0.1), snappedf(p.y, 0.1), snappedf(p.z, 0.1)], "visible": body.is_visible_in_tree()}
		if camera != null:
			row["in_frustum"] = camera.is_position_in_frustum(p + Vector3.UP)
			row["camera_m"] = snappedf(camera.global_position.distance_to(p), 0.1)
		out[key] = row
	if camera != null:
		var c := camera.global_position
		out["camera"] = [snappedf(c.x, 0.1), snappedf(c.y, 0.1), snappedf(c.z, 0.1)]
	return out


func _trainer_node(scene: Node, id: String) -> Node3D:
	if scene == null:
		return null
	for node: Node in scene.find_children("*", "Node3D", true, false):
		if str(node.get_meta("trainer_id", "")) == id:
			return node as Node3D
	return null
