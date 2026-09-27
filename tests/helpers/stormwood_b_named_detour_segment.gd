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
	# The earned Crown segment's own conductor road (stormwood_crown_build_segment.gd).
	"capacitor_alpha": {"camp": "still_grove_shelter",
		"road": [Vector2(-630.0, 2930.0), Vector2(-1080.0, 3020.0)]},
	"hollows_alpha": {"camp": "lantern_pools_camp",
		"road": [Vector2(-430.0, 1500.0), Vector2(-480.0, 1600.0)]},
	# Deepwood legs follow the earned Dynamo segment's own walk from Lantern
	# Hollow (Deepwood station, then east along the Deepwood road).
	"blackwater_elder": {"camp": "lantern_hollow_waycamp",
		"road": [Vector2(-890.0, 4490.0), Vector2(-150.0, 4460.0)]},
	"old_rodfolk_hall_guardian": {"camp": "lantern_hollow_waycamp",
		"road": [Vector2(-890.0, 4490.0), Vector2(-1250.0, 4440.0), Vector2(-1500.0, 4400.0)]},
	"glass_field_alpha": {"camp": "lantern_hollow_waycamp",
		"road": [Vector2(-890.0, 4490.0), Vector2(-150.0, 4460.0), Vector2(-310.0, 5050.0)]},
}
## Named wilds whose plans start in Deepwood: reached through the released
## Rootgate road (the earned Dynamo segment's walk) when the player stands on
## the Crown island.
const DEEPWOOD := ["blackwater_elder", "old_rodfolk_hall_guardian", "glass_field_alpha"]

var outcomes: Dictionary = {}
## The detour fights a named wild as a READER: the same approach-and-quick
## cadence as the route pilot, plus, from 25% of each tell until half a second
## after the strike, the move stick steps sideways out of the shown lane or
## cone (no dodge verb exists). Road wilds keep the route's own pilot.
var reader_named := true
var _named_tell_until_ms := -1
var _named_tell_from_ms := -1
var _named_side := 1.0
## Game milliseconds elapsed in the current detour fight (physics ticks).
var _game_ms := 0


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
		if DEEPWOOD.has(id) and not await _leave_crown_if_there():
			outcomes[id] = "crown_return_failed"
			continue
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
		if await _wait_flag(flag, 240):
			return "cleared"
		if not await _rest_party_at_camp(str(plan.camp)):
			return "rest_failed"
		for point: Vector2 in plan.road:
			if not await _walk_xz(point, "%s road" % id, 2.5, false):
				return "road_blocked"
		# The named wild may have come to us on the road (it is aggressive):
		# that fight is the named fight, played by the same reader pilot.
		if await _wait_flag(flag, 240):
			return "cleared"
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
		if await _wait_flag(flag, 240) or not is_instance_valid(body) or not bool(body.call("is_alive")):
			return "cleared" if _has(flag) else "defeated_without_receipt"
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


## Every fight in a detour (road wilds included) is played by the reader on a
## GAME clock: the inherited pilot times its presses and its 180 s cap on the
## wall clock, which a slow rendering process stretches until a road fight
## times out unresolved (render DRY RUN, road_blocked).
func _fight_current(label: String) -> bool:
	var enemy := _manager.call("enemy_body") as Node3D
	if not reader_named or enemy == null:
		return await super._fight_current(label)
	return await _fight_named_as_reader(label, enemy)


func _fight_named_as_reader(label: String, enemy: Node3D) -> bool:
	_fights_seen += 1
	_last_combat_outcome = ""
	_game_ms = 0
	var previous_scale := Engine.time_scale
	var previous_hz := Engine.physics_ticks_per_second
	var on_tell := func(seconds: float) -> void:
		var now := _game_ms
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
	while bool(_manager.call("is_fighting")) and _game_ms < 300000:
		var foe := _manager.call("enemy_body") as Node3D
		var ally := _director.call("ally_body") as Node3D
		var now := _game_ms
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
		_game_ms += int(1000.0 / float(Engine.physics_ticks_per_second))
	_set_action(&"combat_quick", false)
	_drive_stick.call(0.0, 0.0)
	if is_instance_valid(enemy) and enemy.is_connected("telegraph_started", on_tell):
		enemy.disconnect("telegraph_started", on_tell)
	_named_tell_from_ms = -1
	_named_tell_until_ms = -1
	await _tree.process_frame
	Engine.time_scale = previous_scale
	Engine.physics_ticks_per_second = previous_hz
	_note("FIGHT end %s (reader) outcome=%s game_ms=%d" % [label, _last_combat_outcome, _game_ms])
	if bool(_manager.call("is_fighting")) or _last_combat_outcome.is_empty():
		return _fail("combat during %s did not resolve and publish an outcome" % label)
	return true


## On the Crown island after the Rootgate: walk back through the actual paid
## arch and down the released Rootgate road to Lantern Hollow, as the earned
## Dynamo segment does (`_return_paid_arch` + its first two road points).
func _leave_crown_if_there() -> bool:
	if not _has(CROWN_REACHED) or _player.global_position.x < 400.0 or _player.global_position.z > 2950.0:
		return true
	var arches := _world.get_node_or_null("StormglassArches")
	var rows: Dictionary = arches.get("_arches") if arches != null else {}
	var record := paid_crown_record(_game.get("placed_buildings"))
	var origin: Node3D = (rows.get("e_crown", {}) as Dictionary).get("node")
	var destination: Node3D = (rows.get(str(record.get("uid", "")), {}) as Dictionary).get("node")
	if not is_instance_valid(origin) or not is_instance_valid(destination):
		return _fail("Crown return requires both actual paid passage bodies")
	for point in [Vector2(805, 2545), Vector2(590, 2540)]:
		if not await _walk_xz(point, "Crown return ring"):
			return false
	var outside := origin.to_global(Vector3(0, 0, -5))
	if not await _walk_xz(Vector2(outside.x, outside.z), "outside Crown return passage"):
		return false
	_navigator.reset()
	var through := false
	for _frame in 1800:
		if _player.global_position.distance_to(destination.global_position) < 12.0:
			through = true
			break
		if _manager.is_fighting():
			if not await _fight_current("Crown return passage"):
				return false
		elif _navigator.can_walk():
			await _navigator.step(origin.to_global(Vector3(0, 0, 3.5)))
		else:
			await _tree.physics_frame
	_drive_stick(0, 0)
	if not through:
		return _fail("ordinary Crown passage did not return to the actual paid twin")
	for point in [Vector2(-650, 3550), Vector2(-450, 3960)]:
		if not await _walk_xz(point, "released Rootgate road to Lantern Hollow"):
			return false
	_note("RETURNED from the Crown through the paid arch and the released Rootgate road")
	return true


func detour_result() -> Dictionary:
	return {"passed": failures.is_empty(), "failures": failures.duplicate(),
		"transcript": transcript.duplicate(), "outcomes": outcomes.duplicate()}
