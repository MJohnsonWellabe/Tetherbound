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
	var result := {"action_id": action_id, "move_id": move_id, "target_uid": target_uid, "slot": fallback_slot,
		"weight": weight, "damage": maxf(0.0, damage), "type_mult": type_mult,
		"critical": critical, "direction": flat.normalized(),
		"impact_audio_owner": "receipt", "mastery_rank": 1,
		"hitstop_seconds": float(cfg.get("critical_hitstop_seconds", 0.0)) if critical else float(spec.get("hitstop_seconds", 0.0)),
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
		target_ground: Vector3 = Vector3.INF) -> Dictionary:
	var value := {"action_id": action_id, "encounter_id": encounter_id,
		"attacker_uid": attacker_uid, "target_uid": target_uid, "move_id": move_id,
		"slot": slot, "from": from, "to": to, "travel_seconds": maxf(0.0, travel_seconds),
		"body_generation": body_generation, "mastery_rank": 1, "seed": action_id.hash(),
		"impact_audio_owner": "receipt"}
	if target_ground.is_finite(): value["target_ground"] = target_ground
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
static func rumble_spec(impact: Dictionary, scale: float) -> Dictionary:
	if str(impact.get("weight", "light")) not in ["heavy", "ultimate"] or scale <= 0.0: return {}
	var spec: Dictionary = config().get("rumble", {}).get(str(impact.get("weight", "light")), {})
	if spec.is_empty(): return {}
	return {"weak": clampf(float(spec.get("weak", 0.0)) * scale, 0.0, 1.0),
		"strong": clampf(float(spec.get("strong", 0.0)) * scale, 0.0, 1.0),
		"seconds": maxf(0.0, float(spec.get("seconds", 0.0)))}
