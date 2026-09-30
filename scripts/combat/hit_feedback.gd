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
	var weight := str(move.get("weight", defaults.get(fallback_slot, "light")))
	return weight if weights.has(weight) else str(defaults.get(fallback_slot, "light"))

static func receipt(action_id: String, move_id: String, move: Dictionary,
		fallback_slot: String, damage: float, type_mult: float, critical: bool,
		direction: Vector3, target_height: float = 0.0,
		profile_scale: float = 1.0, target_uid: String = "") -> Dictionary:
	var cfg := config()
	var weight := weight_for(move, fallback_slot)
	var spec: Dictionary = cfg.get("weights", {}).get(weight, {})
	var giant := target_height >= float(cfg.get("giant_height_m", INF))
	var scale := float(cfg.get("giant_knockback_scale", 1.0)) if giant else 1.0
	var flat := Vector3(direction.x, 0.0, direction.z)
	var result := {"action_id": action_id, "move_id": move_id, "target_uid": target_uid,
		"weight": weight, "damage": maxf(0.0, damage), "type_mult": type_mult,
		"critical": critical, "direction": flat.normalized(),
		"hitstop_seconds": float(cfg.get("critical_hitstop_seconds", 0.0)) if critical else float(spec.get("hitstop_seconds", 0.0)),
		"knockback_m": maxf(0.0, float(spec.get("knockback_m", 0.0)) * scale * clampf(profile_scale, 0.0, 1.0)),
		"recoil_m": float(spec.get("recoil_m", 0.0)),
		"recoil_up_m": float(spec.get("recoil_up_m", 0.0)),
		"recoil_degrees": float(spec.get("recoil_degrees", 0.0)),
		"reaction_out_seconds": float(spec.get("reaction_out_seconds", 0.0)),
		"reaction_back_seconds": float(spec.get("reaction_back_seconds", 0.0))}
	result.make_read_only()
	return result

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
	if sequence <= int(history.get(issuer, 0)): return false
	if not history.has(issuer) and history.size() >= int(config().get("receipt_history_limit", 256)): return false
	if commit: history[issuer] = sequence
	return true

static func number_style(receipt: Dictionary, on_enemy: bool) -> Dictionary:
	var cfg: Dictionary = config().get("numbers", {})
	var key := "ordinary"
	if bool(receipt.get("critical", false)):
		key = "critical"
	elif float(receipt.get("type_mult", 1.0)) > 1.0:
		key = "effective"
	elif float(receipt.get("type_mult", 1.0)) < 1.0:
		key = "resisted"
	var style: Dictionary = cfg.get("styles", {}).get(key, {}).duplicate(true)
	var own_hit := bool(receipt.get("own_hit", true))
	var peer_scale := 1.0 if own_hit else float(cfg.get("peer_size_scale", 1.0))
	style["font_px"] = maxi(int(cfg.get("min_font_px", 22)), int(round(float(cfg.get("font_px", 22)) * float(style.get("size_scale", 1.0)) * peer_scale * (1.0 if on_enemy else float(cfg.get("own_target_scale", 1.0))))))
	style["opacity"] = 1.0 if own_hit else float(cfg.get("peer_opacity", 1.0))
	style["text"] = str(style.get("prefix", "")) + str(int(ceil(float(receipt.get("applied_damage", receipt.get("damage", 0.0))))))
	return style
