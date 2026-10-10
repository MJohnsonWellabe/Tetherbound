extends RefCounted

## Encounter-scoped resolved-hit data. No RNG, HP, authority or input here.
## A receipt is flat and read-only; the transport remains responsible for
## admitting host messages and deduplicating committed action identities.
const MATH := preload("res://scripts/combat/combat_math.gd")

static func config() -> Dictionary:
	return MATH.config().get("impact", {}).get("feedback", {})

static func weight_for(move: Dictionary, fallback_slot: String) -> String:
	var cfg := config()
	var weights: Dictionary = cfg.get("weights", {})
	var defaults: Dictionary = cfg.get("slot_weights", {})
	var authored_slot := str(move.get("slot", fallback_slot))
	var weight := str(move.get("weight", defaults.get(authored_slot, "light")))
	return weight if weights.has(weight) else str(defaults.get(fallback_slot, "light"))

static func receipt(action_id: String, move_id: String, move: Dictionary,
		fallback_slot: String, damage: float, type_mult: float, critical: bool,
		direction: Vector3, target_height: float = 0.0,
		profile_scale: float = 1.0, target_uid: String = "", sound_position: Vector3 = Vector3.INF) -> Dictionary:
	var cfg := config()
	var weight := weight_for(move, fallback_slot)
	var spec: Dictionary = cfg.get("weights", {}).get(weight, {})
	var giant := target_height >= float(cfg.get("giant_height_m", INF))
	var scale := float(cfg.get("giant_knockback_scale", 1.0)) if giant else 1.0
	var flat := Vector3(direction.x, 0.0, direction.z)
	# A critical adds emphasis; it must not shorten a heavier move's contact.
	var hitstop := float(spec.get("hitstop_seconds", 0.0))
	if critical:
		hitstop = maxf(hitstop, float(cfg.get("critical_hitstop_seconds", 0.0)))
	var result := {"action_id": action_id, "move_id": move_id, "target_uid": target_uid, "slot": fallback_slot,
		"weight": weight, "damage": maxf(0.0, damage), "type_mult": type_mult,
		"critical": critical, "direction": flat.normalized(),
		"impact_audio_owner": "receipt", "mastery_rank": 1,
		"hitstop_seconds": hitstop,
		"knockback_m": maxf(0.0, float(spec.get("knockback_m", 0.0)) * scale * clampf(profile_scale, 0.0, 1.0)),
		"recoil_m": float(spec.get("recoil_m", 0.0)),
		"recoil_up_m": float(spec.get("recoil_up_m", 0.0)),
		"recoil_degrees": float(spec.get("recoil_degrees", 0.0)),
		"reaction_out_seconds": float(spec.get("reaction_out_seconds", 0.0)),
		"reaction_back_seconds": float(spec.get("reaction_back_seconds", 0.0))}
	if sound_position.is_finite(): result["sound_position"] = sound_position
	result.make_read_only()
	return result

## Flat host schedule. No client aim, callbacks, HP or RNG is accepted here.
static func launch(action_id: String, encounter_id: String, attacker_uid: String,
		target_uid: String, move_id: String, slot: String, from: Vector3,
		to: Vector3, travel_seconds: float, body_generation: int = 0,
		target_ground: Vector3 = Vector3.INF, target_visual_bounds: AABB = AABB()) -> Dictionary:
	var value := {"action_id": action_id, "encounter_id": encounter_id,
		"attacker_uid": attacker_uid, "target_uid": target_uid, "move_id": move_id,
		"slot": slot, "from": from, "to": to, "travel_seconds": maxf(0.0, travel_seconds),
		"body_generation": body_generation, "mastery_rank": 1, "seed": action_id.hash(),
		"impact_audio_owner": "receipt"}
	if target_ground.is_finite(): value["target_ground"] = target_ground
	if target_visual_bounds.size.x > 0.0 and target_visual_bounds.size.y > 0.0 and target_visual_bounds.size.z > 0.0 \
			and target_visual_bounds.position.is_finite() and target_visual_bounds.size.is_finite():
		var bounds := {"position": target_visual_bounds.position, "size": target_visual_bounds.size}
		bounds.make_read_only()
		value["target_visual_bounds"] = bounds
	value.make_read_only()
	return value

static func launch_matches(value: Dictionary, encounter_id: String,
		attacker_uid: String, target_uid: String, body_generation: int = 0) -> bool:
	var seconds := float(value.get("travel_seconds", -1.0))
	return is_finite(seconds) and seconds >= 0.0 \
		and str(value.get("encounter_id", "")) == encounter_id \
		and str(value.get("attacker_uid", "")) == attacker_uid \
		and str(value.get("target_uid", "")) == target_uid \
		and int(value.get("body_generation", -1)) == body_generation

static func impulse_for(receipt: Dictionary) -> float:
	# CreatureBody damps proportionally to current speed; total unobstructed
	# travel is approximately v/damping. Collision and arena bounds still win.
	var damping := maxf(0.0, float(MATH.config().get("creature_movement", {}).get("impulse_damping", 0.0)))
	return damping * maxf(0.0, float(receipt.get("knockback_m", 0.0)))

static func admit(history: Dictionary, receipt: Dictionary, commit: bool = true) -> bool:
	var action_id := str(receipt.get("action_id", ""))
	if receipt.get("tag_combo") == true:
		# Trusted host feedback keeps the accepted child hash. Derive only the
		# existing bounded sequence ledger key; arbitrary opaque IDs still fail.
		for key: String in ["encounter_id", "character_id", "attacker_uid", "target_uid"]:
			if not receipt.get(key) is String or str(receipt[key]).is_empty() or str(receipt[key]).length() > 256: return false
		for key: String in ["command_generation", "command_sequence", "generation", "target_generation"]:
			var value: Variant = receipt.get(key)
			if not (value is int or value is float) or not is_finite(float(value)) \
				or floor(float(value)) != float(value) or float(value) < 1.0 or float(value) > 2147483647.0: return false
		var part := str(receipt.get("part", ""))
		if part not in ["outgoing", "incoming"] or receipt.get("source_kind") != "creature" or receipt.get("slot") != "quick": return false
		var generation := int(receipt.generation)
		var command_generation := int(receipt.command_generation)
		var sequence := int(receipt.command_sequence)
		if generation != command_generation + (1 if part == "incoming" else 0): return false
		var parent_prefix := "command:%s:%s:%d" % [receipt.encounter_id, receipt.character_id, command_generation]
		var parent := "%s:%d" % [parent_prefix, sequence]
		if receipt.get("parent_action_id") != parent \
			or action_id != JSON.stringify([parent, part, str(receipt.attacker_uid), generation]).sha256_text(): return false
		action_id = "%s:%s:%s:%d:%d" % [parent_prefix, part, receipt.attacker_uid, generation, sequence]
	var split := action_id.rfind(":")
	if split <= 0: return false
	var suffix := action_id.substr(split + 1)
	if not suffix.is_valid_int(): return false
	var sequence := int(suffix)
	var issuer := action_id.substr(0, split)
	if sequence <= 0: return false
	var row: Dictionary = history.get(issuer, {})
	var newest := int(row.get("newest", 0))
	var seen: Dictionary = row.get("seen", {})
	var window := maxi(1, int(config().get("receipt_sequence_window", 256)))
	# Launch sequence and impact order differ: a later contact move can land
	# before an earlier projectile. Accept unseen arrivals within the bounded
	# window, while old evicted identities can never become valid again.
	if sequence <= newest - window or seen.has(sequence): return false
	if not history.has(issuer) and history.size() >= int(config().get("receipt_history_limit", 256)): return false
	if commit:
		newest = maxi(newest, sequence)
		seen = seen.duplicate()
		seen[sequence] = true
		for previous: int in seen.keys():
			if previous <= newest - window: seen.erase(previous)
		history[issuer] = {"newest": newest, "seen": seen}
	return true

static func number_style(receipt: Dictionary, on_enemy: bool) -> Dictionary:
	var cfg: Dictionary = config().get("numbers", {})
	var key := style_key(receipt)
	var style: Dictionary = cfg.get("styles", {}).get(key, {}).duplicate(true)
	var own_hit := bool(receipt.get("own_hit", true))
	var peer_scale := 1.0 if own_hit else float(cfg.get("peer_size_scale", 1.0))
	style["font_px"] = maxi(int(cfg.get("min_font_px", 22)), int(round(float(cfg.get("font_px", 22)) * float(style.get("size_scale", 1.0)) * peer_scale * (1.0 if on_enemy else float(cfg.get("own_target_scale", 1.0))))))
	style["opacity"] = 1.0 if own_hit else float(cfg.get("peer_opacity", 1.0))
	style["text"] = str(style.get("prefix", "")) + str(int(ceil(float(receipt.get("applied_damage", receipt.get("damage", 0.0))))))
	return style


static func style_key(receipt: Dictionary) -> String:
	var key := "ordinary"
	if bool(receipt.get("critical", false)):
		key = "critical"
	elif float(receipt.get("type_mult", 1.0)) > 1.0:
		key = "effective"
	elif float(receipt.get("type_mult", 1.0)) < 1.0:
		key = "resisted"
	return key


## Camera-shake multiplier on the built charged nudge; "" (light/medium) = none.
static func shake_scale(impact: Dictionary) -> float:
	var key := feel_key(impact)
	return 0.0 if key.is_empty() else float(config().get("shake_scale", {}).get(key, 1.0))


static func flash_style(receipt: Dictionary) -> Dictionary:
	return (config().get("flashes", {}) as Dictionary).get(style_key(receipt), {}).duplicate(true)


## Freeze the scheduled contact position and audio owner alongside a host hit.
## This copies presentation metadata only; damage/poise facts remain untouched.
static func with_launch(receipt: Dictionary, launch: Dictionary, vfx: Dictionary) -> Dictionary:
	var frozen := receipt.duplicate()
	frozen["mastery_rank"] = int(launch.get("mastery_rank", receipt.get("mastery_rank", 1)))
	frozen["impact_audio_owner"] = str(launch.get("impact_audio_owner", "receipt"))
	var contact: Vector3 = launch.get("target_ground", launch.get("to", Vector3.INF)) if str(vfx.get("archetype", "")) == "root_stone_spikes" else launch.get("to", Vector3.INF)
	if contact.is_finite(): frozen["sound_position"] = contact
	frozen.make_read_only()
	return frozen

## Device-local tactile amplitude never changes the frozen gameplay receipt.
## COMBAT §11: heavy, stagger-crit and ultimate impacts rumble; crit is sharp.
static func feel_key(impact: Dictionary) -> String:
	var weight := str(impact.get("weight", "light"))
	if weight == "ultimate": return weight
	if bool(impact.get("critical", false)): return "critical"
	return weight if weight == "heavy" else ""

static func rumble_spec(impact: Dictionary, scale: float) -> Dictionary:
	var key := feel_key(impact)
	if key.is_empty() or scale <= 0.0: return {}
	var spec: Dictionary = config().get("rumble", {}).get(key, {})
	if spec.is_empty(): return {}
	return {"weak": clampf(float(spec.get("weak", 0.0)) * scale, 0.0, 1.0),
		"strong": clampf(float(spec.get("strong", 0.0)) * scale, 0.0, 1.0),
		"seconds": maxf(0.0, float(spec.get("seconds", 0.0)))}

## Host-only private ledger: encounter + peer + current deployed UID.
## Time, pool, regen and critical window are resolved from host config.
static func defence_state(target_uid: String, now_ms: int, cfg: Dictionary) -> Dictionary:
	return {"target_uid": target_uid, "poise": maxf(1.0, float(cfg.get("max", 40.0))),
		"last_ms": now_ms, "quiet_until_ms": now_ms, "stagger_until_ms": now_ms,
		"pause_until_ms": now_ms, "stagger_active": false, "critical_ready": false, "actions": {}}

static func advance_defence(state: Dictionary, now_ms: int, cfg: Dictionary) -> void:
	now_ms = maxi(now_ms, int(state.last_ms))
	if bool(state.get("stagger_active", false)) and now_ms >= int(state.stagger_until_ms):
		# Match CombatManager._reset_player_poise at actual stagger recovery.
		state.poise = maxf(1.0, float(cfg.get("max", 40.0)))
		state.quiet_until_ms = now_ms
		state.critical_ready = false
		state.stagger_active = false
	var regen_start := maxi(int(state.last_ms), maxi(int(state.quiet_until_ms),
		maxi(int(state.stagger_until_ms), int(state.pause_until_ms))))
	if now_ms > regen_start:
		state.poise = minf(maxf(1.0, float(cfg.get("max", 40.0))),
			float(state.poise) + float(cfg.get("regen_per_second", 20.0)) * (now_ms - regen_start) / 1000.0)
	state.last_ms = now_ms

## Local action/poise clocks pause for the union of accepted hitstop leases.
## Only an independently accepted host receipt may call this; observer feedback
## never extends the observer's defensive state.
static func pause_defence(state: Dictionary, now_ms: int, seconds: float, cfg: Dictionary) -> void:
	advance_defence(state, now_ms, cfg)
	var previous_end := maxi(now_ms, int(state.pause_until_ms))
	var next_end := maxi(previous_end, now_ms + int(round(maxf(0.0, seconds) * 1000.0)))
	var uncovered := next_end - previous_end
	if int(state.stagger_until_ms) > now_ms: state.stagger_until_ms += uncovered
	if int(state.quiet_until_ms) > now_ms: state.quiet_until_ms += uncovered
	state.pause_until_ms = next_end

static func resolve_defence_hit(state: Dictionary, base_damage: float, multiplier: float,
		now_ms: int, hitstop_seconds: float, cfg: Dictionary) -> Dictionary:
	advance_defence(state, now_ms, cfg)
	var critical := bool(state.critical_ready) and now_ms < int(state.stagger_until_ms)
	if critical: state.critical_ready = false
	var damage := maxf(0.0, base_damage) * clampf(multiplier, 0.0, 1.0)
	if critical: damage *= maxf(1.0, float(cfg.get("crit_scale", 1.5)))
	state.poise = maxf(0.0, float(state.poise) - damage)
	var freeze_ms := int(round(maxf(0.0, hitstop_seconds) * 1000.0))
	pause_defence(state, now_ms, hitstop_seconds, cfg)
	freeze_ms = maxi(0, int(state.pause_until_ms) - now_ms)
	state.quiet_until_ms = now_ms + int(round(maxf(0.0, float(cfg.get("regen_delay", 2.0))) * 1000.0)) + freeze_ms
	var staggered := float(state.poise) <= 0.0
	if staggered:
		state.stagger_active = true
		state.critical_ready = true
		state.stagger_until_ms = now_ms + int(round(maxf(0.0, float(cfg.get("stagger_seconds", 0.6))) * 1000.0)) + freeze_ms
		# Existing local regen waits through the stagger before its quiet beat.
		state.quiet_until_ms += int(round(maxf(0.0, float(cfg.get("stagger_seconds", 0.6))) * 1000.0))
	var result := {"damage": damage, "critical": critical, "poise": float(state.poise),
		"staggered": staggered, "critical_ready": bool(state.critical_ready),
		"stagger_left": maxf(0.0, float(int(state.stagger_until_ms) - now_ms - freeze_ms) / 1000.0),
		"quiet_left": maxf(0.0, float(int(state.quiet_until_ms) - now_ms - freeze_ms) / 1000.0 - (float(cfg.get("stagger_seconds", 0.6)) if staggered else 0.0))}
	result.make_read_only()
	return result

static func with_defence(impact: Dictionary, defence: Dictionary) -> Dictionary:
	var resolved := impact.duplicate()
	resolved.damage = float(defence.damage)
	resolved.critical = bool(defence.critical)
	resolved.hitstop_seconds = float(config().get("critical_hitstop_seconds", 0.0)) if resolved.critical else float(impact.get("hitstop_seconds", 0.0))
	resolved.host_resolved_defence = true
	resolved.host_poise = float(defence.poise)
	resolved.host_staggered = bool(defence.staggered)
	resolved.host_critical_ready = bool(defence.critical_ready)
	resolved.make_read_only()
	return resolved
