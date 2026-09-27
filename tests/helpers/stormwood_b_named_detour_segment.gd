extends "res://tests/helpers/stormwood_earned_rootgate_segment.gd"

## F10#2: the Stormwood named wilds the main earned route does not itself
## fight, reached the way a player detours to an optional fight: rest at the
## nearest authored camp (bed + night, the same `_rest_party_at_camp` the route
## uses before Capacitor Alpha), walk the authored road points with the stick,
## stand at the ordinary engage reach, press Engage once, and fight with the
## same controller pilot the route uses. No teleport, flag, item, party or
## weather fixture. A lost fight is recorded, not retried by any fixture: a
## player who wipes walks back, rests and tries again (up to `ATTEMPTS`).
##
## The recorder (`stormwood_b_named_fight_recorder.gd`) on the tree root is
## what turns each of these fights into evidence; this segment only plays.

const ATTEMPTS := 2
## Per named wild: the camp to rest at before setting out and the road points
## from that camp to the fight (the last leg is the engage stance itself).
const PLAN := {
	"hollows_alpha": {"camp": "lantern_pools_camp",
		"road": [Vector2(-430.0, 1500.0), Vector2(-480.0, 1600.0)]},
	"blackwater_elder": {"camp": "lantern_hollow_waycamp",
		"road": [Vector2(-330.0, 4100.0), Vector2(-200.0, 4350.0)]},
	"old_rodfolk_hall_guardian": {"camp": "lantern_hollow_waycamp",
		"road": [Vector2(-800.0, 4050.0), Vector2(-1200.0, 4250.0), Vector2(-1500.0, 4350.0)]},
	"glass_field_alpha": {"camp": "lantern_hollow_waycamp",
		"road": [Vector2(-330.0, 4300.0), Vector2(-250.0, 4800.0), Vector2(-250.0, 5000.0)]},
}

var outcomes: Dictionary = {}
## The detour fights a named wild as a READER: the same approach-and-quick
## cadence as the route pilot, plus, from 25% of each tell until half a second
## after the strike, the move stick steps sideways out of the shown lane or
## cone (no dodge verb exists). Road wilds keep the route's own pilot.
var reader_named := true
var _named_tell_until_ms := -1
var _named_tell_from_ms := -1
var _named_side := 1.0


func run_named(tree: SceneTree, world: Node3D, game: Node, ids: Array) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = world.get_node_or_null(^"Player") as CharacterBody3D if world != null else null
	_camera = world.get_node_or_null(^"CameraRig") as Node3D if world != null else null
	_arbiter = tree.get_first_node_in_group(&"interaction_arbiter") if tree != null else null
	_manager = world.get_node_or_null(^"CombatManager") if world != null else null
	_director = world.get_node_or_null(^"EncounterDirector") if world != null else null
	if _player == null or _camera == null or _manager == null or _director == null or _arbiter == null \
			or str(game.get("current_realm")) != "stormwood":
		_fail("named detours need the retained live Stormwood scene")
		return detour_result()
	_navigator = NAVIGATOR.new(_tree, _player, _camera, _drive_stick)
	_walk_real_clock = true
	if not _manager.exited.is_connected(_on_combat_exited):
		_manager.exited.connect(_on_combat_exited)
	for id: String in ids:
		outcomes[id] = await _detour(id)
		_note("DETOUR %s -> %s" % [id, str(outcomes[id])])
	if _manager.exited.is_connected(_on_combat_exited):
		_manager.exited.disconnect(_on_combat_exited)
	return detour_result()


func _detour(id: String) -> String:
	var flag := "stormwood:named:%s:cleared" % id
	if _has(flag):
		return "already_cleared"
	if not PLAN.has(id):
		return "no_plan"
	var plan: Dictionary = PLAN[id]
	for attempt in ATTEMPTS:
		if not await _rest_party_at_camp(str(plan.camp)):
			return "rest_failed"
		for point: Vector2 in plan.road:
			if not await _walk_xz(point, "%s road" % id, 2.5, false):
				return "road_blocked"
		if not await _ensure_usable_ally(id):
			return "no_usable_ally"
		var body := _named_wild(id)
		if body == null:
			return "absent"
		var collision := _player.get_node_or_null("Collision") as CollisionShape3D
		var radius := (collision.shape as CapsuleShape3D).radius \
			if collision != null and collision.shape is CapsuleShape3D else 0.4
		var at := guardian_stance(body.global_position, _player.global_position,
			float(body.call("body_radius")), radius)
		if not await _walk_xz(at, "%s engage stance" % id, 1.2, false):
			return "stance_blocked"
		for _frame in 240:
			if _manager.is_fighting():
				break
			if _named_engage_ready(body) and await _tap_named_engage(body):
				break
			await _tree.physics_frame
		if not _manager.is_fighting():
			_note("DETOUR %s approach %d did not engage: %s" % [id, attempt + 1,
				str(_alpha_admission_snapshot(body))])
			continue
		if _manager.enemy_body() != body:
			# A road wild reached us first; fight it like the route does, then retry.
			if not await _fight_current("%s road" % id):
				return "road_fight_unresolved"
			continue
		if not await _fight_current(id):
			return "fight_unresolved"
		if await _wait_flag(flag, 180):
			return "cleared"
		_note("DETOUR %s attempt %d ended %s" % [id, attempt + 1, _last_combat_outcome])
	return "not_cleared:%s" % _last_combat_outcome


func _fight_current(label: String) -> bool:
	var enemy := _manager.call("enemy_body") as Node3D
	if not reader_named or enemy == null or str(enemy.get_meta("stormwood_named_encounter", "")).is_empty():
		return await super._fight_current(label)
	return await _fight_named_as_reader(label, enemy)


func _fight_named_as_reader(label: String, enemy: Node3D) -> bool:
	_fights_seen += 1
	_last_combat_outcome = ""
	var started := Time.get_ticks_msec()
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	var on_tell := func(seconds: float) -> void:
		var now := Time.get_ticks_msec()
		_named_tell_from_ms = now + int(seconds * 250.0)
		_named_tell_until_ms = now + int(seconds * 1000.0) + 500
		_named_side = -_named_side
	enemy.connect("telegraph_started", on_tell)
	_note("FIGHT start %s (reader) ally=%s enemy=%s" % [label,
		_fighter_snapshot(_director.call("ally_instance") as RefCounted),
		_fighter_snapshot(_manager.call("enemy") as RefCounted)])
	await _tree.process_frame
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	await _tree.process_frame
	var next_quick_ms := 0
	var tick := 0
	var release_tick := -1
	while bool(_manager.call("is_fighting")) and Time.get_ticks_msec() - started < 180000:
		var foe := _manager.call("enemy_body") as Node3D
		var ally := _director.call("ally_body") as Node3D
		var now := Time.get_ticks_msec()
		if foe != null and ally != null:
			var offset := foe.global_position - ally.global_position
			offset.y = 0.0
			var basis := (_camera.call("planar_basis") as Basis).inverse()
			if now >= _named_tell_from_ms and now < _named_tell_until_ms:
				# Leave the lane/cone: sideways across the foe's facing, a little back.
				var facing := foe.call("facing") as Vector3
				var side := facing.cross(Vector3.UP).normalized() * _named_side
				var local := basis * (side - offset.normalized() * 0.3).normalized()
				_drive_stick.call(local.x, local.z)
			elif offset.length() > float(_manager.call("combat_move_reach", "quick")) * 0.8:
				var local := basis * offset.normalized()
				_drive_stick.call(local.x, local.z)
			else:
				_drive_stick.call(0.0, 0.0)
			if release_tick >= 0 and tick >= release_tick:
				_set_action(&"combat_quick", false)
				release_tick = -1
			if (now < _named_tell_from_ms or now >= _named_tell_until_ms) \
					and now >= next_quick_ms and bool(_manager.call("quick_ready")):
				_set_action(&"combat_quick", true)
				release_tick = tick + 2
				next_quick_ms = now + 900
		tick += 1
		await _tree.physics_frame
	_set_action(&"combat_quick", false)
	_drive_stick.call(0.0, 0.0)
	if is_instance_valid(enemy) and enemy.is_connected("telegraph_started", on_tell):
		enemy.disconnect("telegraph_started", on_tell)
	_named_tell_from_ms = -1
	_named_tell_until_ms = -1
	await _tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	_note("FIGHT end %s (reader) outcome=%s elapsed_ms=%d" % [label, _last_combat_outcome,
		Time.get_ticks_msec() - started])
	if bool(_manager.call("is_fighting")) or _last_combat_outcome.is_empty():
		return _fail("combat during %s did not resolve and publish an outcome" % label)
	return true


func detour_result() -> Dictionary:
	return {"passed": failures.is_empty(), "failures": failures.duplicate(),
		"transcript": transcript.duplicate(), "outcomes": outcomes.duplicate()}
