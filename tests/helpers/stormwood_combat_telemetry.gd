extends RefCounted

## Read-only observations. The caller supplies input counts; this helper never
## sends input, changes a body, requests a snapshot, or changes combat state.
var rows: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var _last_impact_key := ""

static func live_body(raw: Variant) -> Node3D:
	return raw as Node3D if is_instance_valid(raw) else null

func capture(label: String, fight: Node, manager: Node, ally: Node3D,
		replica: Node3D, input_counts: Dictionary = {}) -> Dictionary:
	var valid_fight := is_instance_valid(fight)
	var impact: Dictionary = (fight.get("last_strike") as Dictionary).duplicate(true) if valid_fight else {}
	var key := "%s/%s/%s/%s" % [impact.get("encounter_id", ""),
		impact.get("round", -1), impact.get("action", -1), impact.get("host_now_ms", -1)]
	if not impact.is_empty() and key != _last_impact_key:
		impacts.append(impact.duplicate(true))
		_last_impact_key = key
	var record: Dictionary = fight.authority.record(str(fight.record.get("encounter_id", ""))).duplicate(true) if valid_fight else {}
	var row := {"label": label, "wall_ms": Time.get_ticks_msec(),
		"physics_frame": Engine.get_physics_frames(), "time_scale": Engine.time_scale,
		"physics_hz": Engine.physics_ticks_per_second,
		"record": record, "round": fight.get("round_index") if valid_fight else -1,
		"finished": fight.get("finished") if valid_fight else true, "between": fight.get("_between") if valid_fight else 0.0,
		"participants": (fight.get("participants") as Array).duplicate() if valid_fight else [],
		"host_actions": (fight.get("_actions") as Dictionary).duplicate(true) if valid_fight else {},
		"host_cooldowns": (fight.get("_cooldowns") as Dictionary).duplicate(true) if valid_fight else {},
		"last_strike": impact, "ally": _body(ally), "replica": _body(replica),
		"authority_body": _body(fight.get("opponent") as Node3D) if valid_fight else {"valid": false},
		"input_counts": input_counts.duplicate(true), "manager": {}}
	if is_instance_valid(manager):
		var state: Dictionary = row.manager
		for property: String in ["state", "_action", "_action_timer", "_quick_cooldown",
			"_buffered_attack", "_input_guard", "_encounter_id"]:
			state[property] = manager.get(property)
		state["fighting"] = manager.call("is_fighting")
		state["quick_ready"] = manager.call("quick_ready")
		var aim: Node = manager.call("throw_aim")
		state["aiming"] = bool(aim.call("is_aiming")) if is_instance_valid(aim) else false
		var active: RefCounted = manager.call("active_creature")
		state["active_creature"] = _creature(active)
	rows.append(row.duplicate(true))
	return row

func _body(body: Node3D) -> Dictionary:
	if not is_instance_valid(body):
		return {"valid": false}
	var result := {"valid": true, "id": body.get_instance_id(),
		"position": _vector(body.global_position),
		"centre": _vector(body.call("centre")),
		"facing": _vector(body.call("facing")), "radius": body.call("body_radius")}
	if body is CharacterBody3D:
		result["velocity"] = _vector((body as CharacterBody3D).velocity)
	var creature: RefCounted = body.get("instance")
	result.merge(_creature(creature))
	return result

func _creature(creature: RefCounted) -> Dictionary:
	var result := {}
	if creature != null:
		for property: String in ["species_id", "level", "hp", "max_hp", "fainted"]:
			result[property] = creature.get(property)
	return result

func _vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]
