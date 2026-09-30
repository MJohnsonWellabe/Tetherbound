extends RefCounted

## F23 encounter-only utility state. All inputs to staging are detached values
## constructed by the host after participant/owned loadout/resource/geometry
## checks. This helper cannot establish those facts from a client dictionary.
## No Nodes, character saves, HP damage, poise, invulnerability or VFX authority.
const KINDS := {
	"root": "target", "slow_field": "target_point", "push": "target",
	"dash_strike": "target", "movement_buff": "self", "heal": "self",
	"trap": "target_point", "next_hit_buff": "self",
	"damage_taken_debuff": "target", "quake_ring": "self_ring",
}

static func empty_state(encounter_id: String, generation: int) -> Dictionary:
	return {"encounter_id": encounter_id, "generation": generation,
		"revision": 0, "receipts": {}, "statuses": {}, "fields": {}}

static func _number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) >= minimum and float(value) <= maximum

static func _identity(value: Variant, maximum: int = 160) -> bool:
	return value is String and not value.is_empty() and value.length() <= maximum

static func _point(value: Variant) -> bool:
	return value is Vector3 and value.is_finite()

static func valid_definition(row: Variant) -> bool:
	if not row is Dictionary or str(row.get("slot", "")) != "utility" \
		or not row.get("utility") is Dictionary: return false
	var effect: Dictionary = row.utility
	var kind := str(effect.get("kind", ""))
	if not KINDS.has(kind) or str(effect.get("scope", "")) != KINDS[kind] \
		or str(effect.get("duration_policy", "")) != "refresh_remaining_maximum": return false
	for key: String in ["range", "wind_cost", "cooldown", "base_power"]:
		if not _number(row.get(key), 0.0, 1000.0): return false
	if not _number(row.get("energy_gain"), 0.0, 0.0) \
		or not _number(row.get("energy_cost"), 0.0, 0.0): return false
	# Utility rows never introduce hidden defensive states or held channels.
	if bool(effect.get("invulnerable", false)) or bool(effect.get("revive", false)) \
		or not _number(effect.get("damage_reduction", 0.0), 0.0, 0.0): return false
	if kind in ["root", "slow_field", "movement_buff", "trap", "next_hit_buff", "damage_taken_debuff"] \
		and not _number(effect.get("duration"), 0.001, 60.0): return false
	match kind:
		"root":
			return _number(effect.get("boss_duration"), 0.0, float(effect.duration)) \
				and effect.get("interrupt_protected") == false
		"slow_field":
			return _number(effect.get("radius"), 0.001, 100.0) \
				and _number(effect.get("movement_multiplier"), 0.001, 1.0)
		"push":
			return effect.get("swept") == true and _number(effect.get("push_metres"), 0.0, 100.0) \
				and _number(effect.get("heavy_boss_push_metres"), 0.0, float(effect.push_metres))
		"dash_strike":
			return effect.get("swept") == true and effect.get("maximum_hits_per_action") == 1 \
				and _number(effect.get("advance_metres"), 0.001, 100.0)
		"movement_buff": return _number(effect.get("movement_multiplier"), 1.0, 4.0)
		"heal": return _number(effect.get("max_hp_fraction"), 0.001, 1.0)
		"trap":
			return effect.get("maximum_per_source") == 1 and effect.get("maximum_triggers") == 1 \
				and _number(effect.get("arming_seconds"), 0.0, float(effect.duration)) \
				and _number(effect.get("root_seconds"), 0.001, 60.0) \
				and _number(effect.get("trigger_radius"), 0.001, 100.0) \
				and _number(effect.get("boss_root_seconds"), 0.0, float(effect.root_seconds))
		"next_hit_buff":
			return effect.get("maximum_landed_hits") == 1 and _number(effect.get("power_multiplier"), 1.0, 4.0)
		"damage_taken_debuff": return _number(effect.get("damage_multiplier"), 1.0, 4.0)
		"quake_ring":
			return effect.get("swept") == true and effect.get("maximum_hits_per_action") == 1 \
				and _number(effect.get("radius"), 0.001, 100.0) \
				and _number(effect.get("push_metres"), 0.0, 100.0)
	return false

## No mutation occurs here. Geometry must come from the existing host hit
## resolver; a field point is additionally bounded against the frozen caster.
static func stage_application(state: Dictionary, move_id: String, row: Dictionary,
		host: Dictionary, now_ms: int, receipt_limit: int) -> Dictionary:
	if not valid_definition(row) or not _identity(move_id) or now_ms < 0 \
		or receipt_limit < 1 or receipt_limit > 65536: return {"ok": false, "code": "invalid_definition"}
	if not _number(state.get("revision"), 0.0, 2147483647.0) or float(state.revision) != floorf(float(state.revision)) \
		or not _number(state.get("generation"), 0.0, 2147483647.0) or float(state.generation) != floorf(float(state.generation)) \
		or not _number(host.get("generation"), 0.0, 2147483647.0) or float(host.generation) != floorf(float(host.generation)) \
		or str(state.get("encounter_id", "")) != str(host.get("encounter_id", "")) \
		or int(state.get("generation", -1)) != int(host.get("generation", -2)) \
		or not _identity(state.get("encounter_id")) or not state.get("receipts") is Dictionary \
		or not state.get("statuses") is Dictionary or not state.get("fields") is Dictionary:
		return {"ok": false, "code": "stale_encounter"}
	if not _identity(host.get("action_id")) or not _identity(host.get("source_uid")) \
		or not _identity(host.get("target_uid")) or not _point(host.get("source_position")) \
		or not _point(host.get("target_position")) or not _number(host.get("source_hp"), 0.001, INF) \
		or not _number(host.get("source_max_hp"), float(host.source_hp), INF):
		return {"ok": false, "code": "invalid_actor"}
	if state.receipts.has(host.action_id): return {"ok": false, "code": "duplicate_action"}
	if state.receipts.size() >= receipt_limit: return {"ok": false, "code": "receipt_budget"}
	var effect: Dictionary = row.utility
	var kind := str(effect.kind)
	var self_effect := str(effect.scope) == "self"
	if self_effect:
		if str(host.target_uid) != str(host.source_uid): return {"ok": false, "code": "wrong_target"}
	else:
		if str(host.target_uid) == str(host.source_uid) or not _number(host.get("target_hp"), 0.001, INF) \
			or host.get("hostile") != true: return {"ok": false, "code": "wrong_target"}
		if host.get("geometry_connected") != true: return {"ok": false, "code": "miss"}
	var next := state.duplicate(true)
	var receipt := {"action_id": str(host.action_id), "encounter_id": str(state.encounter_id),
		"generation": int(state.generation), "move_id": move_id, "kind": kind,
		"source_uid": str(host.source_uid), "target_uid": str(host.target_uid),
		"accepted_at_ms": now_ms, "damaging": float(row.base_power) > 0.0,
		"requested_push_metres": 0.0, "requested_advance_metres": 0.0,
		"hp_before": float(host.source_hp), "hp_after": float(host.source_hp)}
	match kind:
		"heal":
			receipt.hp_after = minf(float(host.source_max_hp), float(host.source_hp) + float(host.source_max_hp) * float(effect.max_hp_fraction))
			if float(receipt.hp_after) <= float(receipt.hp_before): return {"ok": false, "code": "already_full"}
		"root":
			var duration := float(effect.boss_duration) if bool(host.get("target_is_boss", false)) else float(effect.duration)
			if duration <= 0.0: return {"ok": false, "code": "immune"}
			_refresh(next, host, kind, now_ms, duration, 0.0)
		"movement_buff", "next_hit_buff", "damage_taken_debuff":
			var value := float(effect.get("movement_multiplier", effect.get("power_multiplier", effect.get("damage_multiplier", 1.0))))
			_refresh(next, host, kind, now_ms, float(effect.duration), value)
		"slow_field", "trap":
			if not _point(host.get("target_point")): return {"ok": false, "code": "invalid_point"}
			var offset: Vector3 = host.target_point - host.source_position
			offset.y = 0.0
			if offset.length() > float(row.range): return {"ok": false, "code": "out_of_range"}
			var fields: Dictionary = next.fields.get(host.source_uid, {})
			# One field of each authored family per source; recasting replaces it.
			fields[kind] = {"source_uid": str(host.source_uid), "target_uid": str(host.target_uid), "action_id": str(host.action_id),
				"kind": kind, "position": host.target_point, "effect": effect.duplicate(true),
				"created_at_ms": now_ms, "expires_at_ms": now_ms + int(float(effect.duration) * 1000.0),
				"armed_at_ms": now_ms + int(float(effect.get("arming_seconds", 0.0)) * 1000.0), "triggered": false}
			next.fields[host.source_uid] = fields
		"push":
			receipt.requested_push_metres = float(effect.heavy_boss_push_metres) if bool(host.get("target_is_heavy_boss", false)) else float(effect.push_metres)
		"dash_strike": receipt.requested_advance_metres = float(effect.advance_metres)
		"quake_ring": receipt.requested_push_metres = float(effect.push_metres)
	next.revision = int(state.get("revision", 0)) + 1
	next.receipts[host.action_id] = receipt.duplicate(true)
	receipt.make_read_only()
	return {"ok": true, "expected_revision": int(state.get("revision", 0)), "state": next, "receipt": receipt}

static func _refresh(state: Dictionary, host: Dictionary, kind: String,
		now_ms: int, duration: float, value: float) -> void:
	var statuses: Dictionary = state.statuses.get(host.target_uid, {})
	var previous: Dictionary = statuses.get(kind, {})
	statuses[kind] = {"source_uid": str(host.source_uid), "target_uid": str(host.target_uid),
		"kind": kind, "value": value, "expires_at_ms": maxi(int(previous.get("expires_at_ms", 0)), now_ms + int(duration * 1000.0))}
	state.statuses[host.target_uid] = statuses

## Pure reads apply the strongest active modifier once, never multiply fields.
## Hitstop callers pass their host encounter clock, rather than wall time.
static func movement_multiplier(state: Dictionary, uid: String, position: Vector3, now_ms: int) -> float:
	var result := 1.0
	var statuses: Dictionary = state.get("statuses", {}).get(uid, {})
	var root: Dictionary = statuses.get("root", {})
	if int(root.get("expires_at_ms", 0)) > now_ms: return 0.0
	var buff: Dictionary = statuses.get("movement_buff", {})
	if int(buff.get("expires_at_ms", 0)) > now_ms: result = float(buff.value)
	var slow := 1.0
	for fields: Dictionary in state.get("fields", {}).values():
		var field: Dictionary = fields.get("slow_field", {})
		if field.is_empty() or int(field.expires_at_ms) <= now_ms or str(field.target_uid) != uid: continue
		var offset: Vector3 = position - (field.position as Vector3)
		offset.y = 0.0
		if offset.length() <= float(field.effect.radius): slow = minf(slow, float(field.effect.movement_multiplier))
	return result * slow

static func power_multiplier(state: Dictionary, uid: String, now_ms: int) -> float:
	var status: Dictionary = state.get("statuses", {}).get(uid, {}).get("next_hit_buff", {})
	return float(status.get("value", 1.0)) if int(status.get("expires_at_ms", 0)) > now_ms else 1.0

static func damage_taken_multiplier(state: Dictionary, uid: String, now_ms: int) -> float:
	var status: Dictionary = state.get("statuses", {}).get(uid, {}).get("damage_taken_debuff", {})
	return float(status.get("value", 1.0)) if int(status.get("expires_at_ms", 0)) > now_ms else 1.0

## Call only after the source's actual HP debit committed. A miss/rollback never
## consumes Hearten; damage mastery remains its own separate receipt domain.
static func stage_consume_next_hit(state: Dictionary, source_uid: String, now_ms: int) -> Dictionary:
	var status: Dictionary = state.get("statuses", {}).get(source_uid, {}).get("next_hit_buff", {})
	if int(status.get("expires_at_ms", 0)) <= now_ms: return {"ok": false, "code": "no_buff"}
	var next := state.duplicate(true)
	(next.statuses[source_uid] as Dictionary).erase("next_hit_buff")
	next.revision = int(state.get("revision", 0)) + 1
	return {"ok": true, "expected_revision": int(state.get("revision", 0)), "state": next}

## Host caller establishes hostility and live target UID before invoking this.
## The first entering foe consumes the trap; later polling cannot root again.
static func stage_trap_trigger(state: Dictionary, source_uid: String, target_uid: String,
		position: Vector3, hostile: bool, target_hp: float, boss: bool, now_ms: int) -> Dictionary:
	var field: Dictionary = state.get("fields", {}).get(source_uid, {}).get("trap", {})
	if field.is_empty() or bool(field.triggered) or not hostile or source_uid == target_uid \
		or str(field.target_uid) != target_uid \
		or not _identity(target_uid) or not position.is_finite() or not is_finite(target_hp) or target_hp <= 0.0 \
		or now_ms < int(field.armed_at_ms) or now_ms >= int(field.expires_at_ms): return {"ok": false, "code": "no_trigger"}
	var offset: Vector3 = position - (field.position as Vector3)
	offset.y = 0.0
	if offset.length() > float(field.effect.trigger_radius): return {"ok": false, "code": "outside"}
	var duration := float(field.effect.boss_root_seconds) if boss else float(field.effect.root_seconds)
	if duration <= 0.0: return {"ok": false, "code": "immune"}
	var next := state.duplicate(true)
	next.fields[source_uid].trap.triggered = true
	_refresh(next, {"source_uid": source_uid, "target_uid": target_uid}, "root", now_ms, duration, 0.0)
	next.revision = int(state.get("revision", 0)) + 1
	return {"ok": true, "expected_revision": int(state.get("revision", 0)), "state": next,
		"action_id": str(field.action_id), "source_uid": source_uid, "target_uid": target_uid}
