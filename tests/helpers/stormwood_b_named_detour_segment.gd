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
const ENGAGE_ROUNDS := 3
const STORMWOOD_CAMPS := preload("res://scripts/world/stormwood_camps.gd")
const STORMWOOD_WORLD_CONFIG := "res://data/config/stormwood_world.json"
const ROOTGATE_RELEASED := "stormwood:rootgate_released"
## Walking pace assumed for the calm-window departure check (m/s, 1x clock)
## and the slack added for road wilds and stance alignment (s).
const DEPARTURE_PACE_MPS := 3.5
const DEPARTURE_SLACK_S := 45.0
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
		var camp_id := str(plan.camp)
		# Recovery only walks to the camp when a party member needs a bed. A
		# healthy party can therefore report zero nights without moving at all;
		# start every attempt with ordinary stick travel to the camp's authored
		# Surge safe-zone centre, then rest there if recovery is needed. This is
		# shelter staging, not a claim that the trainer visited the bed prompt.
		var shelter := _declared_camp_shelter(camp_id)
		if shelter.is_empty():
			_fail("%s has no resolvable authored shelter for camp %s" % [id, camp_id])
			return "camp_unreachable"
		if not await _walk_to_declared_camp_shelter(camp_id, shelter, id):
			_fail("ordinary stick travel did not reach the declared %s shelter for %s" % [camp_id, id])
			return "camp_unreachable"
		if not _at_declared_camp_shelter(shelter):
			_fail("%s did not arrive inside %s's declared camp shelter (player_xz=%s)" % [id, camp_id,
				str(Vector2(_player.global_position.x, _player.global_position.z))])
			return "camp_shelter_unverified"
		_note("CAMP %s shelter staging verified at player xz=(%.1f, %.1f) inside %s; no bed interaction implied" % [
			camp_id, _player.global_position.x, _player.global_position.z,
			str(shelter.get("safe_zone_id", "no-surge camp staging"))])
		if not await _rest_party_at_camp(camp_id):
			return "rest_failed"
		if not _at_declared_camp_shelter(shelter):
			_fail("%s left %s's declared camp shelter during recovery (player_xz=%s)" % [id, camp_id,
				str(Vector2(_player.global_position.x, _player.global_position.z))])
			return "camp_shelter_unverified_after_rest"
		# Leave the camp only when the runtime's own Surge clock leaves enough
		# calm (+ building) time to walk the road before the charged window:
		# run 3 lost the trainer twice to Break strikes on exposed road legs.
		# Wait in the camp's shelter only (run 5 waited on the exposed road
		# between legs and was struck down there), then walk the road out.
		if not await _await_calm_departure(plan.road as Array, id):
			return "no_calm_window"
		for point: Vector2 in plan.road:
			if not await _walk_xz(point, "%s road" % id, 2.5, false):
				return "road_blocked"
		# The named wild may have come to us on the road (it is aggressive):
		# that fight is the named fight, played by the same reader pilot.
		if await _wait_flag(flag, 240):
			return "cleared"
		# A named wild's escort (e.g. Capacitor Alpha's tanglevolts) can stand
		# closer and hold the Engage prompt. A player fights the escort, then
		# the alpha: up to ENGAGE_ROUNDS engages without walking back to camp.
		for round in ENGAGE_ROUNDS:
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
			# The production Engage radius is centre-based. A 1.2 m arrival
			# tolerance left Blackwater Elder at 6.56 m, outside its 6 m offer.
			if not await _walk_xz(at, "%s engage stance" % id, 0.2, false):
				return "stance_blocked"
			if await _wait_flag(flag, 240) or not is_instance_valid(body) or not bool(body.call("is_alive")):
				return "cleared" if _has(flag) else "defeated_without_receipt"
			for _frame in 240:
				if _manager.is_fighting():
					break
				if _named_engage_ready(body) and await _tap_named_engage(body):
					break
				var escort := _director.call("_engageable") as Node3D
				if escort != null and escort != body and _named_engage_ready(escort) \
						and await _tap_named_engage(escort):
					_note("DETOUR %s round %d: engaged the closer %s holding the prompt" % [id, round + 1, str(escort.name)])
					break
				await _tree.physics_frame
			if not _manager.is_fighting():
				_note("DETOUR %s approach %d.%d did not engage: %s" % [id, attempt + 1, round + 1,
					str(_alpha_admission_snapshot(body))])
				break
			if _manager.enemy_body() != body:
				# A road wild or escort engaged first; fight it, then retry the alpha.
				if not await _fight_current("%s road" % id):
					return "road_fight_unresolved"
				continue
			if not await _fight_current(id):
				return "fight_unresolved"
			if await _wait_flag(flag, 180):
				return "cleared"
			_note("DETOUR %s attempt %d.%d ended %s" % [id, attempt + 1, round + 1, _last_combat_outcome])
			break
	return "not_cleared:%s" % _last_combat_outcome


## Reach Lantern Hollow through the configured roads. South of Deepwood, start
## at the nearest authored mainline waypoint and follow Ash -> Conductor ->
## Deepwood in route order; this preserves the Mainlander approach without
## cutting diagonally across the conductor-ridge spur. A player already in
## Deepwood takes only the local road back to Lantern Hollow, never the whole
## Conductor route in reverse.
func _walk_to_declared_camp_shelter(camp_id: String, shelter: Dictionary, id: String) -> bool:
	if camp_id != "lantern_hollow_waycamp":
		return await _walk_xz(shelter.center, "%s camp shelter" % id, 0.75)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STORMWOOD_WORLD_CONFIG))
	if not parsed is Dictionary:
		return _fail("cannot load authored Stormwood road config for Lantern Hollow approach")
	var config: Dictionary = parsed
	var deepwood_min_z := INF
	for region: Dictionary in config.get("regions", []):
		if str(region.get("id", "")) == "deepwood":
			var bounds: Variant = region.get("bounds")
			if bounds is Dictionary and (bounds.get("min_z") is int or bounds.get("min_z") is float):
				deepwood_min_z = float(bounds.get("min_z"))
			break
	if not is_finite(deepwood_min_z):
		return _fail("authored Deepwood boundary is missing from Stormwood world config")
	var route_by_id: Dictionary = {}
	for route: Dictionary in config.get("routes", []):
		route_by_id[str(route.get("id", ""))] = route
	var deepwood_route: Dictionary = route_by_id.get("deepwood_road", {})
	if deepwood_route.is_empty():
		return _fail("authored deepwood_road is missing from Stormwood world config")
	var gate_flag := str(deepwood_route.get("requires_unlock", ""))
	if gate_flag.is_empty() or not _has(gate_flag) or gate_flag != ROOTGATE_RELEASED:
		return _fail("Lantern Hollow approach requires its authored Rootgate unlock (%s)" % gate_flag)
	var authored_deepwood: Array = deepwood_route.get("points", [])
	var deepwood_points: Array[Vector2] = []
	for raw_point: Array in authored_deepwood:
		if raw_point.size() < 2:
			return _fail("authored deepwood_road contains an invalid route point")
		deepwood_points.append(Vector2(float(raw_point[0]), float(raw_point[1])))
	if deepwood_points.size() != authored_deepwood.size() or deepwood_points.size() <= 2:
		return _fail("authored deepwood_road is incomplete before its Lantern Hollow waypoint")

	var route_points: Array[Vector2] = []
	var player_z := _player.global_position.z
	if player_z < deepwood_min_z:
		for route_id: String in ["ash_road", "conductor_road"]:
			var route: Dictionary = route_by_id.get(route_id, {})
			if route.is_empty():
				return _fail("authored %s is missing from Stormwood world config" % route_id)
			var required: String = str(route.get("requires_unlock", ""))
			if not required.is_empty() and not _has(required):
				return _fail("authored %s requires unmet route flag %s" % [route_id, required])
			for raw_point: Array in route.get("points", []):
				if raw_point.size() < 2:
					return _fail("authored %s contains an invalid route point" % route_id)
				var point := Vector2(float(raw_point[0]), float(raw_point[1]))
				if route_points.is_empty() or route_points.back().distance_to(point) > 0.01:
					route_points.append(point)
		# Mainland approaches stop at Deepwood road point 2, Lantern Hollow's
		# authored approach. Do not continue the route into the Dynamo.
		for index in 3:
			var point := deepwood_points[index]
			if route_points.is_empty() or route_points.back().distance_to(point) > 0.01:
				route_points.append(point)
	else:
		# Keep every Deepwood point for D4/D5 locations after Lantern Hollow.
		# Nearest-point routing below walks back along this road to point 2.
		for point: Vector2 in deepwood_points:
			route_points.append(point)
	if route_points.is_empty():
		return _fail("authored route to Lantern Hollow has no usable points")

	var nearest := 0
	var here := Vector2(_player.global_position.x, _player.global_position.z)
	var nearest_distance := INF
	for index in route_points.size():
		var distance := here.distance_squared_to(route_points[index])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = index
	var walk_indices: Array[int] = []
	if player_z < deepwood_min_z:
		for index in range(nearest, route_points.size()):
			walk_indices.append(index)
	else:
		# Lantern Hollow is authored at Deepwood route point 2. Walk along the
		# local road in the direction of that point; do not backtrack to the gate.
		const CAMP_ROUTE_INDEX := 2
		var step := 1 if nearest < CAMP_ROUTE_INDEX else -1
		var index := nearest
		while true:
			walk_indices.append(index)
			if index == CAMP_ROUTE_INDEX:
				break
			index += step
			if index < 0 or index >= route_points.size():
				return _fail("cannot find authored Deepwood road from current position to Lantern Hollow")
	for index: int in walk_indices:
		if not await _walk_xz(route_points[index], "%s authored route waypoint %d" % [id, index], 2.5):
			return false
	return await _walk_xz(shelter.center, "%s camp shelter" % id, 0.75)


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


## Wait at the camp until the Surge at the camp leaves calm (+ the building
## that follows it) for at least the walk out: road length at
## DEPARTURE_PACE_MPS plus DEPARTURE_SLACK_S. Bounded by one Surge cycle and
## read from the runtime's own phase policy (`phase_at`), like the route's
## charged-window waits. A Surge-free world (aftermath) departs at once.
func _await_calm_departure(road: Array, id: String) -> bool:
	var surge := _world.get_node_or_null(^"StormwoodSurge")
	if surge == null:
		return true
	var plan: Dictionary = PLAN.get(id, {})
	var camp_id := str(plan.get("camp", ""))
	var shelter := _declared_camp_shelter(camp_id)
	if shelter.is_empty() or not _at_declared_camp_shelter(shelter):
		return _fail("refusing calm wait for %s outside its verified camp shelter" % id)
	var length := 0.0
	var from := Vector2(_player.global_position.x, _player.global_position.z)
	for point: Vector2 in road:
		length += from.distance_to(point)
		from = point
	var need := length / DEPARTURE_PACE_MPS + DEPARTURE_SLACK_S
	var at := Vector2(_player.global_position.x, _player.global_position.z)
	var start := _calm_snapshot(surge, at)
	var until := _surge_clock() + float(start.get("cycle_seconds", 510.0)) + 5.0
	while _surge_clock() < until:
		if not _at_declared_camp_shelter(shelter):
			return _fail("left the verified camp shelter while waiting to depart for %s" % id)
		at = Vector2(_player.global_position.x, _player.global_position.z)
		var state := _calm_snapshot(surge, at)
		# A leg longer than one calm + building window can hold departs at the
		# start of a full window (90% of it), the most shelter the clock allows.
		var enough := minf(need, float(state.max_safe) * 0.9) if float(state.max_safe) > 0.0 else need
		if str(state.phase) == "none" or (str(state.phase) == "calm" and float(state.safe_seconds) >= enough):
			_note("DEPARTED for %s with %.0f s of calm ahead (need %.0f s for %.0f m): %s" % [id,
				float(state.safe_seconds), need, length, str(state)])
			return true
		await _tree.physics_frame
	_fail("no calm window of %.0f s for the %s road within one Surge cycle (last=%s)" % [need, id,
		str(_calm_snapshot(surge, at))])
	return false


func _declared_camp_shelter(camp_id: String) -> Dictionary:
	var camp_row: Dictionary = {}
	for row: Dictionary in STORMWOOD_CAMPS.load_config().get("camps", []):
		if str(row.get("id", "")) == camp_id:
			camp_row = row
			break
	if camp_row.is_empty():
		return {}
	var surge := _world.get_node_or_null(^"StormwoodSurge")
	if surge == null:
		var camp_at: Array = camp_row.get("at", [])
		if camp_at.size() != 2:
			return {}
		return {"center": Vector2(float(camp_at[0]), float(camp_at[1]))}
	var rules: RefCounted = surge.get("rules") as RefCounted
	if rules == null:
		return {}
	var safe_zone_id := str(camp_row.get("safe_zone_id", ""))
	var config: Dictionary = rules.get("config") as Dictionary
	for zone: Dictionary in config.get("safe_zones", []):
		if str(zone.get("id", "")) == safe_zone_id:
			var at: Array = zone.get("at", [])
			if at.size() != 2:
				return {}
			return {"center": Vector2(float(at[0]), float(at[1])), "radius": float(zone.get("radius", 0.0)),
				"safe_zone_id": safe_zone_id, "rules": rules, "surge": surge}
	return {}


func _at_declared_camp_shelter(shelter: Dictionary) -> bool:
	if shelter.is_empty():
		return false
	var center: Vector2 = shelter.center
	var at := Vector2(_player.global_position.x, _player.global_position.z)
	if not shelter.has("rules"):
		return true
	var radius := float(shelter.get("radius", 0.0))
	if radius <= 0.0 or at.distance_to(center) > radius:
		return false
	var point := Vector3(at.x, float(_world.call("ground_height_at", at.x, at.y)), at.y)
	var surge: Node = shelter.surge
	var region := str(surge.call("region_at", point))
	return bool((shelter.rules as RefCounted).call("sheltered", point, region, false))


func _calm_snapshot(surge: Node, at: Vector2) -> Dictionary:
	var elapsed := _surge_clock()
	var point := Vector3(at.x, float(_world.call("ground_height_at", at.x, at.y)), at.y)
	var region := str(surge.call("region_at", point))
	var rules: RefCounted = surge.get("rules") as RefCounted
	var row: Dictionary = (rules.get("config") as Dictionary).get("regions", {}).get(region, {})
	var rod_flag := str(row.get("rod_flag", ""))
	var rod_disabled := not rod_flag.is_empty() and _has(rod_flag)
	var aftermath := _has("stormwood:long_storm_ended")
	var current: Dictionary = rules.call("phase_at", elapsed, region, rod_disabled, aftermath)
	var phase := str(current.get("phase", "none"))
	var safe := 0.0
	var max_safe := 0.0
	if phase == "calm" or phase == "building":
		safe = float(current.get("remaining", 0.0))
		if phase == "calm":
			var next: Dictionary = rules.call("phase_at", elapsed + safe + 0.001, region, rod_disabled, aftermath)
			if str(next.get("phase", "")) == "building":
				safe += float(next.get("remaining", 0.0))
				max_safe = float(current.get("duration", 0.0)) + float(next.get("duration", 0.0))
	return {"phase": phase, "safe_seconds": snappedf(safe, 0.1), "max_safe": snappedf(max_safe, 0.1), "elapsed": snappedf(elapsed, 0.1),
		"region": region, "cycle_seconds": float(current.get("cycle_seconds", 510.0))}
