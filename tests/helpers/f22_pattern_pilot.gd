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
var _escape_dir := Vector3.ZERO
var _last_shape: Array = []
var _fields: Array[Dictionary] = []
var _pending_field: Dictionary = {}



func _act(policy: String) -> void:
	if policy == "SWITCH_READER" and _combo_hooked_manager != _manager.get_instance_id():
		_combo_hooked_manager = _manager.get_instance_id()
		# F24's joint attack is observed when it exists; until then the
		# switching reader still has COMBAT §12.3's other two sources (type
		# matchup, per-identity resources) through the D32 switch.
		_tally["tag_combo_available"] = _manager.has_signal("tag_combo_resolved")
		if bool(_tally.tag_combo_available):
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
			"role": str(context.get("role", AI.species_role(str(enemy.get("species_id")), patterns))),
			"trainer_owned": bool(_wild.get("trainer_owned")),
			"move_quick": str(enemy.get("move_quick")),
			"move_charged": str(enemy.get("move_charged"))}, true)
		current["sendout_index"] = int(_tally.get("f22_sendouts", 0))
		_tally["f22_sendouts"] = int(current.sendout_index) + 1
		_wild.call("configure_patterns", patterns, current, _visible_observation)
	if policy == "MASHER":
		super._act("MASHER")
		return
	if policy == "SWITCH_READER" and _manager.can_switch():
		_switch_for_matchup()
	_read(policy)


## COMBAT §7 reader: presses in neutral while keeping a wind reserve for one
## escape, reacts to a tell only after it has been visible for the declared
## observation delay, leaves the DISPLAYED strike geometry (walking when time
## allows, bursting when it does not) and spends its charged on recoveries.
## It reads the displayed committed shape and the recovery/stagger state, and
## times tells as a player who knows each pattern's authored length would
## (exact, via the body's beat clock; the base C2 pilot does the same). It
## never reads RNG or future input.
func _read(_policy: String) -> void:
	var telling := bool(_manager.enemy_is_winding_up())
	if not telling:
		_tell_seen_frame = -1
	elif _tell_seen_frame < 0:
		_tell_seen_frame = _frames
	if _manager.player_is_committed() or float(_manager.get("_hitstop_left")) > 0.0:
		return
	var delta := _wild.global_position - _ally.global_position
	delta.y = 0.0
	var distance := delta.length()
	var toward := delta.normalized()
	var reach: float = _manager.combat_move_reach("quick")
	var reserve: float = _manager.wind_cost("burst") + _manager.wind_cost("quick")
	var observed := float(MATH.config().get("patterns", {}).get("reactions", {}).get("observation_s", 0.25))
	var seen := float(_frames - _tell_seen_frame) / Engine.physics_ticks_per_second if telling else 0.0
	_note_fields(telling)
	if telling and seen >= observed:
		var escape := _escape_from_tell()
		if not escape.is_empty():
			# A tracking marker or heading follows whoever moves: spending the
			# burst before it visibly stops is wasted. Walk the chosen exit
			# and keep it while it still leads out, so the stick does not
			# jitter between equal exits.
			var locked := _shape_locked()
			if _escape_dir != Vector3.ZERO and float(escape.get("own_distance", INF)) <= float(escape.distance) + 0.75:
				escape.direction = _escape_dir
				escape.distance = escape.own_distance
				escape.walk_s = float(escape.distance) / maxf(0.1, _speed())
			_escape_dir = escape.direction
			_walk(_escape_dir)
			# The burst is a fixed hop that nothing follows up: walk first and
			# spend it to finish the exit, or as the last chance before release.
			var hop := float(MATH.config().get("burst", {}).get("distance", 3.0)) - 0.2
			var finishes := float(escape.distance) <= hop and float(escape.walk_s) > float(escape.time_left) - 0.05
			var last_chance := float(escape.time_left) <= 0.35 and float(escape.walk_s) > float(escape.time_left) - 0.05
			if locked and (finishes or last_chance) \
					and _manager.wind_value() >= _manager.wind_cost("burst"):
				_press("jump")
				_tally.burst_uses += 1
			_tally["read_escapes"] = int(_tally.get("read_escapes", 0)) + 1
			return
		# Outside the shown shape: strike if a quick lands first, else hold,
		# never spending the burst the next exit may need.
		if distance <= reach - 0.25 and _manager.quick_ready() \
				and _manager.wind_value() >= reserve:
			_press("combat_quick")
		return
	if telling:
		# The tell is visible but not yet read: keep moving as before and
		# start no new commitment; the reaction itself waits the full delay.
		if not _manager.player_is_committed() and distance > reach - 0.25: _walk(_around_fields(toward))
		return
	_escape_dir = Vector3.ZERO
	var field_exit := _field_exit()
	if field_exit != Vector3.ZERO:
		_walk(field_exit)
		# A released fan is still in the air: finish the exit with the burst.
		if _fan_in_flight() and _manager.wind_value() >= _manager.wind_cost("burst"):
			_press("jump")
			_tally.burst_uses += 1
		return
	var opening: bool = _manager.enemy_is_staggered() or int(_wild.intent()) == AI.Intent.RECOVER
	if opening:
		var charged: Dictionary = _manager.call("_move_profile", "player_charged", str(_manager.active_creature().move_charged))
		var window := float(_wild.get("_beat_left"))
		if distance > reach - 0.25:
			_walk(_around_fields(toward))
			return
		if _manager.charged_ready() and distance < _manager.combat_move_reach("charged") - 0.15 \
				and window > float(charged.get("windup", 0.55)) * float(MATH.config().get("player_pace", {}).get("windup_scale", 1.0)) + 0.1 \
				and _manager.wind_value() >= _manager.wind_cost("charged") + _manager.wind_cost("burst"):
			_press("combat_charged")
		elif _manager.quick_ready() and (_manager.enemy_is_staggered() or _manager.wind_value() >= reserve):
			_press("combat_quick")
		return
	if _manager.wind_value() < reserve:
		# Keep the escape affordable: hold just outside the opponent's reach.
		var enemy_reach := float(_wild.combat_config().get("range", 2.6))
		if distance < enemy_reach + 0.5: _retreat(toward)
		return
	if distance > reach - 0.25:
		_walk(_around_fields(toward))
	elif _manager.quick_ready():
		_press("combat_quick")


func _speed() -> float:
	return float(MATH.config().get("creature_movement", {}).get("speed", 5.6))


## The visible shape has stopped following: marker and heading unchanged
## since the previous physics frame.
func _shape_locked() -> bool:
	var geometry: Dictionary = _wild.call("pattern_geometry") if _wild.has_method("pattern_geometry") else {}
	var now := [geometry.get("marker", Vector3.ZERO), geometry.get("heading", Vector3.ZERO)]
	# Only a shape that stayed put while this body moved has visibly locked;
	# standing still would make a still-tracking shape look locked.
	var here: Vector3 = _ally.global_position
	var moved := _last_shape.size() == 3 and Vector2(here.x - (_last_shape[2] as Vector3).x,
		here.z - (_last_shape[2] as Vector3).z).length() > 0.03
	var locked := moved and (now[0] as Vector3).is_equal_approx(_last_shape[0]) \
		and (now[1] as Vector3).is_equal_approx(_last_shape[1])
	now.append(here)
	_last_shape = now
	if geometry.is_empty():
		return bool(_wild.get("_selected_heading_locked"))
	return locked


## Released fans stay dangerous for their visible flight and fields for
## their drawn lifetime. Remember each shape this reader saw committed, with
## its frozen geometry, and stay out of it until it expires.
func _note_fields(telling: bool) -> void:
	if telling and _wild.has_method("pattern_geometry"):
		var geometry: Dictionary = _wild.call("pattern_geometry")
		var profile: Dictionary = geometry.get("profile", {})
		var shape := str(profile.get("telegraph_shape", ""))
		var after := 0.0
		if shape == "field": after = float(profile.get("field_duration_s", 3.0))
		elif shape == "fan": after = float(MATH.config().get("patterns", {}).get("casts", {}).get("fan_travel_s", 0.3)) + 0.05
		_pending_field = {} if after <= 0.0 else {"profile": profile, "origin": geometry.origin,
			"heading": geometry.heading, "marker": geometry.marker,
			"until": _frames + int((float(_wild.get("_beat_left")) + after) * Engine.physics_ticks_per_second)}
	elif not _pending_field.is_empty():
		_fields.append(_pending_field)
		_pending_field = {}
	var live: Array[Dictionary] = []
	for row: Dictionary in _fields:
		if int(row.until) > _frames: live.append(row)
	_fields = live


func _in_field(point: Vector3, margin: float) -> Dictionary:
	for row: Dictionary in _fields:
		if AI.pattern_contains(row.profile, row.origin, row.heading, row.marker, point, margin):
			return row
	return {}


func _fan_in_flight() -> bool:
	var radius := float(_ally.call("body_radius")) + 0.2
	var row := _in_field(_ally.global_position, radius)
	return not row.is_empty() and str((row.profile as Dictionary).get("telegraph_shape", "")) == "fan"


func _field_exit() -> Vector3:
	var radius := float(_ally.call("body_radius")) + 0.2
	if _in_field(_ally.global_position, radius).is_empty(): return Vector3.ZERO
	var best := Vector3.ZERO
	var best_step := INF
	for index: int in 8:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * index / 8.0)
		var step := 0.25
		while step <= 6.0 and step < best_step:
			if _in_field(_ally.global_position + direction * step, radius).is_empty():
				best = direction
				best_step = step
				break
			step += 0.25
	return best if best != Vector3.ZERO else Vector3.RIGHT


func _around_fields(toward: Vector3) -> Vector3:
	var margin := float(_ally.call("body_radius")) + 0.3
	if _in_field(_ally.global_position + toward * 0.6, margin).is_empty(): return toward
	var tangent := toward.cross(Vector3.UP)
	for side: Vector3 in [tangent, -tangent]:
		if _in_field(_ally.global_position + side * 0.6, margin).is_empty(): return side
	return Vector3.ZERO


## The shortest exit from the committed tell, searched over eight headings in
## the actual arena. Empty when the reader is already outside the shape.
func _escape_from_tell() -> Dictionary:
	var profile := {}
	var origin := _wild.global_position
	var heading: Vector3 = _wild.call("facing") if _wild.has_method("facing") else Vector3.FORWARD
	var marker := origin
	if _wild.has_method("pattern_geometry"):
		var geometry: Dictionary = _wild.call("pattern_geometry")
		if not (geometry.get("profile", {}) as Dictionary).is_empty():
			profile = geometry.profile
			origin = geometry.origin
			heading = geometry.heading
			marker = geometry.marker
	if profile.is_empty():
		var cfg: Dictionary = _wild.combat_config()
		if _wild.has_method("lunge_travels") and bool(_wild.call("lunge_travels")):
			var scale := float(MATH.config().get("charger_lunge", {}).get("contact_scale", 1.2))
			profile = {"telegraph_shape": "lane", "lunge": float(cfg.get("lunge", 0.0)),
				"lane_half_width_m": (_ally.body_radius() + _wild.body_radius()) * scale}
		else:
			profile = {"telegraph_shape": "cone", "range": float(cfg.get("range", 2.6)) + 0.35,
				"cone_degrees": float(cfg.get("cone_degrees", 90.0))}
	var radius := float(_ally.call("body_radius")) + 0.3
	var here: Vector3 = _ally.global_position
	if not AI.pattern_contains(profile, origin, heading, marker, here, radius):
		return {}
	var arena: Node3D = _manager.arena()
	var limit := float(arena.get("radius")) - radius - 0.5
	var speed := float(MATH.config().get("creature_movement", {}).get("speed", 5.6))
	var outward := here - arena.global_position
	outward.y = 0.0
	outward = outward.normalized() if outward.length() > 0.05 else Vector3.ZERO
	var best := {}
	var best_cost := INF
	for index: int in 16:
		var direction := Vector3.FORWARD.rotated(Vector3.UP, TAU * index / 16.0)
		var step := 0.25
		while step <= 6.0:
			var point := here + direction * step
			var flat := Vector2(point.x - arena.global_position.x, point.z - arena.global_position.z)
			if flat.length() > limit: break
			if not AI.pattern_contains(profile, origin, heading, marker, point, radius):
				# Prefer exits that do not run toward the arena edge, where the
				# body slides and the next tell has no room.
				var cost := step + maxf(0.0, direction.dot(outward)) * 0.75
				if cost < best_cost:
					best_cost = cost
					best = {"direction": direction, "distance": step}
				break
			step += 0.25
	if best.is_empty():
		best = {"direction": -(_wild.global_position - here).normalized(), "distance": 6.0}
	if _escape_dir != Vector3.ZERO:
		var step := 0.25
		while step <= 6.0:
			if not AI.pattern_contains(profile, origin, heading, marker, here + _escape_dir * step, radius):
				best["own_distance"] = step
				break
			step += 0.25
	best["walk_s"] = float(best.distance) / maxf(0.1, speed)
	var travel := float(MATH.config().get("patterns", {}).get("casts", {}).get("fan_travel_s", 0.3)) \
		if str(profile.get("telegraph_shape", "")) == "fan" else 0.0
	best["time_left"] = float(_wild.get("_beat_left")) + travel
	return best


func _visible_observation() -> Dictionary:
	var action := int(_manager.get("_action"))
	var move: Dictionary = _manager.get("_pending_move") as Dictionary
	var label := "ready"
	if action == MANAGER.Action.WINDUP:
		label = "quick_windup" if bool(move.get("is_quick", true)) else "charged_windup"
	elif action == MANAGER.Action.RECOVERY:
		label = "recovery"
	var towards := _ally.global_position - _wild.global_position
	towards.y = 0.0
	var step := towards.normalized().cross(Vector3.UP) * 3.0
	var end := _wild.global_position + step
	var arena: Node3D = _wild.get("arena") as Node3D
	var safe: bool = arena != null and Vector2(end.x - arena.global_position.x,
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
	# A benched creature keeps its own health (COMBAT §12.3, per-identity
	# resources): a reader pulls a nearly spent lead before it falls, and
	# among healthy candidates chooses by visible type matchup.
	var spent: bool = float((party[active] as RefCounted).call("hp_fraction")) < 0.3
	for index: int in candidates:
		var creature: RefCounted = party[index]
		if index != active and float(creature.call("hp_fraction")) < (0.6 if spent else 0.3): continue
		var outgoing := TYPE_GRAPH.multiplier_dual(_moves.call("type_of", str(creature.get("move_quick"))),
			str(enemy.get("creature_type")), str(enemy.get("secondary_type")))
		var incoming := TYPE_GRAPH.multiplier_dual(_moves.call("type_of", str(enemy.get("move_quick"))),
			str(creature.get("creature_type")), str(creature.get("secondary_type")))
		var value := outgoing / maxf(0.01, incoming)
		if spent and index == active: value = -1.0
		if value > best_value:
			best_value = value
			best = index
	if best == active:
		return
	var caller := "request_tag_switch" if _manager.has_method("request_tag_switch") else "request_switch"
	if bool(_manager.call(caller, best)):
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
