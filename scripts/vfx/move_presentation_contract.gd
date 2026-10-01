extends RefCounted

## Value validation is local presentation hygiene. It authenticates no caller
## and never creates a gameplay action, target, receipt, timer or authority.
static func number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) >= low and float(value) <= high

static func whole(value: Variant, low: int, high: int) -> bool:
	return number(value, low, high) and floor(float(value)) == float(value)

static func values_only(value: Variant, depth: int = 0) -> bool:
	if depth > 12 or value is Object: return false
	if value is float: return is_finite(value)
	if value is Vector3: return value.is_finite()
	if value is Dictionary:
		for key: Variant in value:
			if not values_only(key, depth + 1) or not values_only(value[key], depth + 1): return false
	if value is Array:
		for item: Variant in value:
			if not values_only(item, depth + 1): return false
	return true

static func same_actor(binding: Dictionary, current: Dictionary, at_birth: bool = true) -> bool:
	for key: String in ["character_id", "creature_uid", "encounter_id", "generation"]:
		if not binding.has(key) or binding[key] != current.get(key): return false
	for key: String in ["character_id", "creature_uid", "encounter_id"]:
		if not binding[key] is String or str(binding[key]).is_empty(): return false
	if not whole(binding.generation, 1, 2147483647): return false
	if at_birth:
		return whole(binding.get("action"), 1, 2147483647) and binding.action == current.get("action")
	return true

static func visual(spec: Dictionary) -> bool:
	if not spec.get("archetype") is String: return false
	if not whole(spec.get("count"), 1, 12): return false
	for key: String in ["size", "speed", "impact_scale"]:
		if not number(spec.get(key), 0.001, 100.0): return false
	for key: String in ["arc", "spread", "trail"]:
		if not number(spec.get(key), 0.0, 100.0): return false
	return spec.get("colour") is String and Color.html_is_valid(str(spec.colour))

static func birth(spec: Dictionary, context: Dictionary) -> Dictionary:
	if not values_only(spec) or not values_only(context): return {}
	var binding: Variant = spec.get("actor_binding")
	var current: Variant = context.get("current_actor")
	if not binding is Dictionary or not current is Dictionary or not same_actor(binding, current): return {}
	var action: Variant = spec.get("action_id")
	if not action is String or str(action).is_empty() or str(action).length() > 256: return {}
	if not whole(spec.get("mastery_rank"), 1, 5): return {}
	if not number(context.get("travel_seconds"), 0.0, 3.0): return {}
	for key: String in ["source_ground", "target_ground"]:
		if not context.get(key) is Vector3 or not (context[key] as Vector3).is_finite(): return {}
	if not spec.get("vfx") is Dictionary or not visual(spec.vfx): return {}
	# F23 must honor mastery_owner in its effect_tier producer; base parameters
	# remain frozen, then this library applies its authored tier exactly once.
	if str(spec.vfx.get("mastery_owner", "")) != "f25": return {}
	var frozen := context.duplicate(true)
	frozen["actor_binding"] = binding.duplicate(true)
	frozen["action_id"] = action
	frozen["move_id"] = str(spec.get("move_id", ""))
	frozen["encounter_id"] = str(binding.encounter_id)
	frozen["mastery_rank"] = int(spec.mastery_rank)
	frozen["seed"] = str(action).sha256_text().left(8).hex_to_int()
	# Ordinary effects never borrow the separately owned ultimate allowance.
	frozen["ultimate"] = false
	frozen["impact_audio_owner"] = "receipt"
	frozen.erase("current_actor")
	return frozen
