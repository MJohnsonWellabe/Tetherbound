extends RefCounted

const TRAITS := preload("res://scripts/creatures/traits.gd")

## Ordinary encounter IDs are the host's existing peer:record counter.
## Preserve authored site IDs without accepting arbitrary colon payloads.
static func valid_spawn_id(value: Variant) -> bool:
	if TRAITS.component(value): return true
	if not value is String: return false
	var parts: PackedStringArray = value.split(":")
	if parts.size() != 2: return false
	for part: String in parts:
		if not part.is_valid_int() or str(part.to_int()) != part \
			or part.to_int() < 1 or part.to_int() > 2147483647: return false
	return true

## Called ONLY by host spawn registration before announcement. The caller
## supplies its actual registered namespace/id/generation, not client flags.
static func prepare_host_spawn(host_identity: Dictionary, cfg: Dictionary = {}) -> Dictionary:
	var fields := ["world_namespace","spawn_id","spawn_generation","alpha","night","weather"]
	if host_identity.size() != fields.size(): return {}
	for field: String in fields:
		if not host_identity.has(field): return {}
	if not host_identity.world_namespace is String or not host_identity.spawn_id is String \
		or not TRAITS.integer(host_identity.spawn_generation,1,2147483647): return {}
	for field: String in ["alpha","night","weather"]:
		if not host_identity[field] is bool: return {}
	return TRAITS.roll_spawn(host_identity.world_namespace,host_identity.spawn_id,
		int(host_identity.spawn_generation),host_identity.alpha,host_identity.night,host_identity.weather,cfg)

## Catch producer copies the HOST retained packet; inspect requests and
## catch clients carry no trait rolls. Identity equality guards reused spawns.
static func prepare_catch(host_identity: Dictionary, retained: Dictionary,
		canonical_creature: Dictionary, cfg: Dictionary = {}) -> Dictionary:
	if not TRAITS.trait_state_errors(retained,cfg).is_empty(): return {}
	var source: Variant = retained.get("captured_from")
	if not source is Dictionary or source.get("kind") != "wild": return {}
	for field: String in ["world_namespace","spawn_id","spawn_generation"]:
		if not host_identity.has(field) or source.get(field) != host_identity[field]: return {}
	var output := canonical_creature.duplicate(true)
	for field: String in ["traits_initialized","rolled_traits","taught_traits","captured_from"]:
		output[field] = retained[field].duplicate(true) if retained[field] is Array or retained[field] is Dictionary else retained[field]
	return output
