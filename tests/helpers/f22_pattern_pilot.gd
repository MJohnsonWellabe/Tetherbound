extends "res://tests/helpers/combat_depth_pilot.gd"

## Actual manager/body input pilot, extending the established C2 fixture.
## No HP/damage/authority simulator. This sees the displayed committed shape
## and past action state. Flat collider fixture does not prove world C3/co-op.
const TYPE_GRAPH := preload("res://scripts/combat/type_chart.gd")
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
var context: Dictionary = {}
var _prepared_body := 0
var _combo_hooked_manager := 0
var _tell_seen_frame := -1
var _moves: RefCounted = MOVE_DB.new()


func _act(policy: String) -> void:
	if policy == "SWITCH_READER" and _combo_hooked_manager != _manager.get_instance_id():
		_combo_hooked_manager = _manager.get_instance_id()
		if not _manager.has_signal("tag_combo_resolved"):
			_tally["fixture_error"] = "actual accepted F24 combo observation is absent"
			_manager.call("_begin_resolve", "fled")
			return
		_manager.connect("tag_combo_resolved", _on_tag_combo_resolved)
	if is_instance_valid(_wild) and _prepared_body != _wild.get_instance_id():
		_prepared_body = _wild.get_instance_id()
		_tell_seen_frame = -1
		var patterns: Dictionary = MATH.config().get("patterns", {})
		if patterns.get("runtime_enabled") != true or not _wild.has_method("configure_patterns"):
			_tally["fixture_error"] = "actual F22 pattern consumer is disabled or absent"
			_manager.call("_begin_resolve", "fled")
			return
		var enemy: RefCounted = _wild.get("instance")
		var current := context.duplicate(true)
		current.merge({"species_id": str(enemy.get("species_id")),
			"role": AI.species_role(str(enemy.get("species_id")), patterns),
			"trainer_owned": bool(_wild.get("trainer_owned")),
			"move_quick": str(enemy.get("move_quick")),
			"move_charged": str(enemy.get("move_charged"))}, true)
		current["sendout_index"] = int(_tally.get("f22_sendouts", 0))
		_tally["f22_sendouts"] = int(current.sendout_index) + 1
		_wild.call("configure_patterns", patterns, current, _visible_observation)
	var telling := bool(_manager.enemy_is_winding_up())
	if not telling:
		_tell_seen_frame = -1
	elif _tell_seen_frame < 0:
		_tell_seen_frame = _frames
	if policy != "MASHER" and telling \
			and float(_frames - _tell_seen_frame) / Engine.physics_ticks_per_second < 0.25:
		# Continue ordinary approach while noticing a new tell; do not inspect
		# its geometry or select a reaction before the declared reader delay.
		var approach := _wild.global_position - _ally.global_position
		approach.y = 0.0
		if not _manager.player_is_committed(): _walk(approach.normalized())
		return
	if policy == "SWITCH_READER" and _manager.can_switch():
		_switch_for_matchup()
	if policy != "MASHER" and _manager.enemy_is_winding_up() \
			and not _manager.player_is_committed() and _wild.has_method("pattern_geometry"):
		var geometry: Dictionary = _wild.call("pattern_geometry")
		var profile: Dictionary = geometry.get("profile", {})
		if not profile.is_empty():
			var target: Vector3 = _ally.call("centre")
			if AI.pattern_contains(profile, geometry.origin, geometry.heading, geometry.marker,
					target, float(_ally.call("body_radius"))):
				var shape := str(profile.get("telegraph_shape", ""))
				var direction: Vector3
				if shape in ["lane", "cone", "fan"]:
					direction = (geometry.heading as Vector3).cross(Vector3.UP).normalized()
				else:
					var centre: Vector3 = geometry.marker if shape in ["marker", "field"] else geometry.origin
					direction = Vector3(target.x - centre.x, 0.0, target.z - centre.z).normalized()
				_walk(direction)
				return
			return
	super._act("READER" if policy == "SWITCH_READER" else policy)


func _visible_observation() -> Dictionary:
	var action := int(_manager.get("_action"))
	var move: Dictionary = _manager.get("_pending_move") as Dictionary
	var label := "ready"
	if action == MANAGER.Action.WINDUP:
		label = "quick_windup" if bool(move.get("is_quick", true)) else "charged_windup"
	elif action == MANAGER.Action.RECOVER:
		label = "recovery"
	var towards := _ally.global_position - _wild.global_position
	towards.y = 0.0
	var step := towards.normalized().cross(Vector3.UP) * 3.0
	var end := _wild.global_position + step
	var arena: Node3D = _wild.get("arena") as Node3D
	var safe := arena != null and Vector2(end.x - arena.global_position.x,
		end.z - arena.global_position.z).length() + _wild.body_radius() <= float(arena.get("radius")) \
		and not _wild.test_move(_wild.global_transform, step)
	return {"action": label, "creature_uid": str(_manager.active_creature().get("uid")),
		"distance": towards.length(), "quick_range": float(_wild.combat_config().get("range", 0.0)),
		"safe_dodge_lane": safe, "side_sign": 1.0}


func _switch_for_matchup() -> void:
	var party: Array = _manager.get("_party")
	var enemy: RefCounted = _wild.get("instance")
	var active := int(_manager.get("_active_index"))
	var best := active
	var best_value := -INF
	var candidates: Array[int] = [active]
	candidates.append_array(_manager.switchable_indices())
	for index: int in candidates:
		var creature: RefCounted = party[index]
		var outgoing := TYPE_GRAPH.multiplier_dual(_moves.call("type_of", str(creature.get("move_quick"))),
			str(enemy.get("creature_type")), str(enemy.get("secondary_type")))
		var incoming := TYPE_GRAPH.multiplier_dual(_moves.call("type_of", str(enemy.get("move_quick"))),
			str(creature.get("creature_type")), str(creature.get("secondary_type")))
		var value := outgoing / maxf(0.01, incoming)
		if value > best_value:
			best_value = value
			best = index
	if best == active:
		return
	if not _manager.has_method("request_tag_switch"):
		_tally["fixture_error"] = "actual F24 tag-switch caller is absent"
		return
	if bool(_manager.call("request_tag_switch", best)):
		_tally["switches"] = int(_tally.get("switches", 0)) + 1


func _on_tag_combo_resolved(result: Dictionary) -> void:
	var strikes: Array = result.get("strikes", [])
	if strikes.size() != 2 or str(result.get("switched_to_uid", "")).is_empty(): return
	var parts := {}
	for row: Dictionary in strikes:
		if str(row.get("attacker_uid", "")).is_empty() or int(row.get("generation", 0)) < 1 \
				or str(row.get("action_id", "")).is_empty() or row.get("landed") != true \
				or float(row.get("actual_hp_debit", 0.0)) <= 0.0: return
		parts[str(row.get("part", ""))] = row
	if not parts.has("incoming") or not parts.has("outgoing") \
			or parts.incoming.attacker_uid != result.switched_to_uid \
			or parts.outgoing.attacker_uid == parts.incoming.attacker_uid: return
	_tally["tag_combos"] = int(_tally.get("tag_combos", 0)) + 1
	(_tally.events as Array).append({"event": "accepted_tag_combo", "result": result.duplicate(true)})
