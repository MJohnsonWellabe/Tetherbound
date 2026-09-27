extends "res://tools/art_pipeline/capture_named_fight.gd"

## F04#4 "real hit/avoidance witness per fight", headless, for the three
## captains and the Warden. Each fight is the production one: Meadows
## playground, player stood in front of the trainer, challenge through the
## interact prompt and dialogue (capture_named_fight.gd's path), the trainer's
## own AI swinging, combat_manager deciding every outcome. Only pad input is
## injected:
##
## - HIT: `combat_quick` taps between the opponent's tells; a
##   `hit_landed(on_enemy=true)` is the player's hit landing.
## - STAND: on alternate tells the stick is left at rest; a
##   `hit_landed(on_enemy=false)` is the opponent's strike landing.
## - DODGE: on the other tells the left stick drives the creature out of the
##   strike (movement is the dodge -- combat_manager.gd `_drive_player_creature`,
##   there is no dodge button), from DODGE_REACTION_S into the tell until
##   WITNESS_DODGE_TAIL_S after it; an `attack_missed(by_player=false)` is the strike
##   avoided.
##
## Every tell is logged as a row: trainer, strike number, move id, tell
## seconds, policy, outcome, damage. A fight passes with at least one landed
## player hit, one landed STAND strike and one missed DODGE strike.
##
## Disclosed harness help: the player's active creature is healed to full
## after every strike so a starter survives a level 11-19 trainer for the
## sample; the stand spot is a fixture teleport (capture_named_fight.gd).
##
##   godot --headless --path . --script tests/smoke_named_fight_hit_avoid.gd \
##     [-- --trainer=captain_riverwatch,captain_field,captain_ridge,warden_aldis]

const DEFAULT_TRAINERS := ["captain_riverwatch", "captain_field", "captain_ridge", "warden_aldis"]
const STRIKES_PER_FIGHT := 8
const FIGHT_FRAME_LIMIT := 60 * 120
## A player reacting to the tell they can see: ~0.2 s, not a frame-perfect input.
const DODGE_REACTION_S := 0.2
const WITNESS_DODGE_TAIL_S := 0.25
const POLICIES := ["stand", "dodge", "stand", "dodge_side"]
const WITNESS_ATTACK_EVERY_FRAMES := 20

var _rows: Array[Dictionary] = []
var _strikes: Array[Dictionary] = []
var _player_hits := 0
var _body: Node = null
var _results: Array[String] = []


func _run() -> void:
	var ids: Array = DEFAULT_TRAINERS.duplicate()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trainer="):
			ids = Array(arg.trim_prefix("--trainer=").split(",", false))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	await _ensure_ally()
	var failed := 0
	for id: String in ids:
		_tid = id
		_spec = TRAINERS.trainer(_tid)
		if _spec.is_empty():
			_results.append("FAIL %s: no such trainer" % _tid)
			failed += 1
			continue
		if not await _witness_one():
			failed += 1
	print("")
	for line in _results:
		print(line)
	if failed == 0:
		print("PASS: named-fight hit/avoidance witness -- every fight logged a landed player hit, a landed strike held still, and a strike avoided by moving")
	else:
		print("FAIL: %d of %d named fights lack a full hit/avoidance witness" % [failed, ids.size()])
	quit(1 if failed > 0 else 0)


func _witness_one() -> bool:
	if not _collect_nodes():
		_results.append("FAIL %s: scene nodes or trainer missing" % _tid)
		return false
	var ally: Variant = _director.call("ally_instance")
	if ally != null:
		ally.call("heal_fully")
	_stand_in_front_of_the_trainer()
	if not await _settle_on_ground():
		_results.append("FAIL %s: no ground at the stand spot" % _tid)
		return false
	for i in 30:
		await physics_frame
	await _challenge()
	if not bool(_manager.call("is_fighting")):
		_results.append("FAIL %s: the challenge did not start a fight" % _tid)
		return false
	print("fight live vs %s" % _tid)

	_strikes.clear()
	_player_hits = 0
	_body = null
	var on_hit := func(on_enemy: bool, amount: float) -> void:
		if on_enemy:
			_player_hits += 1
		else:
			_settle_outcome("hit", amount)
	var on_miss := func(by_player: bool) -> void:
		if not by_player:
			_settle_outcome("miss", 0.0)
	_manager.connect("hit_landed", on_hit)
	_manager.connect("attack_missed", on_miss)

	var physics_hz := float(Engine.physics_ticks_per_second)
	var frames := 0
	while frames < FIGHT_FRAME_LIMIT and bool(_manager.call("is_fighting")) \
			and _settled_count() < STRIKES_PER_FIGHT:
		_follow_body()
		var stick := Vector2.ZERO
		var in_tell := false
		if not _strikes.is_empty():
			var s: Dictionary = _strikes.back()
			var since := float(Engine.get_physics_frames() - int(s.frame)) / physics_hz
			in_tell = not s.has("outcome") or since < float(s.seconds) + WITNESS_DODGE_TAIL_S
			if str(s.policy).begins_with("dodge") and in_tell \
					and since >= DODGE_REACTION_S:
				stick = _stick_away_from_opponent(str(s.policy) == "dodge_side")
		_left_stick(stick)
		# A player who means to step out of the next swing is watching for
		# it, not mashing: a quick roots the creature through its wind-up and
		# recovery (combat_manager.gd `_drive_player_creature`). So attacks
		# are only thrown ahead of a STAND strike.
		var next_policy: String = POLICIES[_strikes.size() % POLICIES.size()]
		if not in_tell and next_policy == "stand" and frames % WITNESS_ATTACK_EVERY_FRAMES == 0:
			await _pad_tap("combat_quick")
			frames += 4
		await physics_frame
		frames += 1
	_left_stick(Vector2.ZERO)
	_manager.disconnect("hit_landed", on_hit)
	_manager.disconnect("attack_missed", on_miss)
	if bool(_manager.call("is_fighting")):
		_manager.call("_begin_resolve", "lost")
		for i in 240:
			if not bool(_manager.call("is_fighting")) and not bool(_panel.call("is_open")):
				break
			if bool(_panel.call("is_open")):
				await _press("interact")
			await physics_frame

	var stand_hit := 0
	var dodge_miss := 0
	var dodged := 0
	for s in _strikes:
		print("row %s strike=%d move=%s tell=%.2fs policy=%s outcome=%s damage=%.1f gap_tell=%.2f gap_strike=%.2f moved=%.2f reach=%.2f cone=%.0f action=%d arena_off=%.2f" % [
			_tid, int(s.n), str(s.move), float(s.seconds), str(s.policy),
			str(s.get("outcome", "none")), float(s.get("damage", 0.0)),
			float(s.get("gap_at_tell", -1.0)), float(s.get("gap_at_strike", -1.0)),
			float(s.get("moved", -1.0)), float(s.reach), float(s.cone), int(s.action),
			float(s.arena_off)])
		if str(s.policy) == "stand" and str(s.get("outcome", "")) == "hit":
			stand_hit += 1
		if str(s.policy).begins_with("dodge"):
			dodged += 1
			if str(s.get("outcome", "")) == "miss":
				dodge_miss += 1
	var ok := _player_hits > 0 and stand_hit > 0 and dodge_miss > 0
	_results.append("%s %s: player_hits=%d stand_strikes_landed=%d dodges_avoided=%d/%d strikes=%d" % [
		"PASS" if ok else "FAIL", _tid, _player_hits, stand_hit, dodge_miss, dodged, _strikes.size()])
	return ok


func _settled_count() -> int:
	var n := 0
	for s in _strikes:
		if s.has("outcome"):
			n += 1
	return n


## The trainer sends a new body per creature, so re-attach the tell hook.
func _follow_body() -> void:
	var body: Node = _director.get("_trainer_body") as Node
	if body == _body or body == null or not is_instance_valid(body):
		return
	_body = body
	if body.has_signal("telegraph_started"):
		body.connect("telegraph_started", _on_witness_tell)


func _on_witness_tell(seconds: float) -> void:
	var cfg: Dictionary = _body.call("combat_config") if _body != null and _body.has_method("combat_config") else {}
	# Alternate: odd strikes held still, even strikes dodged.
	var policy: String = POLICIES[_strikes.size() % POLICIES.size()]
	_strikes.append({
		"n": _strikes.size() + 1,
		"seconds": seconds,
		"move": str(cfg.get("move_id", "quick")),
		"policy": policy,
		"frame": Engine.get_physics_frames(),
		"ally_at_tell": _ally_pos(),
		"gap_at_tell": _gap(),
		"reach": float(cfg.get("range", -1.0)),
		"cone": float(cfg.get("cone_degrees", -1.0)),
		"action": int(_manager.get("_action")),
		"arena_off": _arena_offset(),
	})


func _settle_outcome(outcome: String, amount: float) -> void:
	for i in range(_strikes.size() - 1, -1, -1):
		var s: Dictionary = _strikes[i]
		if s.has("outcome"):
			break
		s["outcome"] = outcome
		s["damage"] = amount
		s["gap_at_strike"] = _gap()
		s["moved"] = _ally_pos().distance_to(s.get("ally_at_tell", _ally_pos()))
		break
	var own: RefCounted = _manager.call("active_creature")
	if own != null:
		own.call("heal_fully")


## Camera-space stick that drives the creature straight away from the
## opponent's body, the way a player backs out of a swing they can see coming.
func _stick_away_from_opponent(sideways := false) -> Vector2:
	var ally := _director.call("ally_body") as Node3D
	if ally == null or _body == null or not is_instance_valid(_body) or _camera == null:
		return Vector2.ZERO
	var away := ally.global_position - (_body as Node3D).global_position
	away.y = 0.0
	if away.length() < 0.01:
		return Vector2.ZERO
	away = away.normalized()
	if sideways:
		away = Vector3(-away.z, 0.0, away.x)
	var right := _camera.global_transform.basis.x
	right.y = 0.0
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	return Vector2(away.dot(right.normalized()), -away.dot(forward.normalized())).normalized()


func _ally_pos() -> Vector3:
	var ally := _director.call("ally_body") as Node3D
	return ally.global_position if ally != null else Vector3.ZERO


func _arena_offset() -> float:
	var arena := _manager.get("_arena") as Node3D
	if arena == null or not is_instance_valid(arena):
		return -1.0
	var d := _ally_pos() - arena.global_position
	d.y = 0.0
	return d.length()


func _gap() -> float:
	if _body == null or not is_instance_valid(_body):
		return -1.0
	var d := _ally_pos() - (_body as Node3D).global_position
	d.y = 0.0
	return d.length()


func _left_stick(v: Vector2) -> void:
	for axis_value in [[JOY_AXIS_LEFT_X, v.x], [JOY_AXIS_LEFT_Y, v.y]]:
		var m := InputEventJoypadMotion.new()
		m.axis = axis_value[0]
		m.axis_value = axis_value[1]
		Input.parse_input_event(m)
