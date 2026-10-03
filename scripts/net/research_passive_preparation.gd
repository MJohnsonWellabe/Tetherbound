extends RefCounted

## Pure preparation codec. The caller must supply the actual retained world
## event, reserve the admitted revision, and authenticate an owner's BOOL-save
## ACK. A valid packet alone never grants any of those capabilities.
const E := preload("res://scripts/creatures/essence.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const PASSIVE := preload("res://scripts/net/groom_passive_sync.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const KIND := "research_passive_preparation"
const FIELDS := ["version", "kind", "character_id", "world_id", "world_namespace", "session_epoch", "retained_event", "duty", "duty_hash", "preparation_id", "revision", "before", "after", "elapsed", "distance", "landmarks", "discoveries", "hash"]

static func make(retained: Dictionary, duty: Dictionary, before: Dictionary, revision: int,
		epoch: String, elapsed: float, distance: float, landmarks: int,
		discoveries: Dictionary, preparation_id: String) -> Dictionary:
	if not _passive_shape(before): return {}
	var prepared := {"version": 1, "kind": KIND, "character_id": before.get("character_id"),
		"world_id": retained.get("world_id"), "world_namespace": retained.get("world_namespace"),
		"session_epoch": epoch, "retained_event": retained.get("delivery_id"),
		"duty": duty.duplicate(true), "duty_hash": fingerprint(duty),
		"preparation_id": preparation_id, "revision": revision, "before": before.duplicate(true),
		"after": PASSIVE.derive(before, elapsed, distance, landmarks), "elapsed": elapsed,
		"distance": distance, "landmarks": landmarks, "discoveries": discoveries.duplicate(true)}
	prepared.hash = preparation_hash(prepared)
	return prepared if valid(prepared, retained) else {}

static func fingerprint(value: Dictionary) -> String:
	# Keep exact floating-point bits while treating integral numeric values and
	# Dictionary order as the existing authority equality does.
	var canonical: Dictionary = _canonical(value)
	var encoded := DOCUMENT.stringify(canonical)
	return encoded.sha256_text() if not encoded.is_empty() else ""

static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var next := {}
		var keys: Array = value.keys()
		keys.sort()
		for key: Variant in keys: next[key] = _canonical(value[key])
		return next
	if value is Array:
		var next: Array = []
		for item: Variant in value: next.append(_canonical(item))
		return next
	# Larger integral floats still carry meaningful float64 bits. Keep them
	# for the lossless document codec instead of overflowing an int64 cast.
	if value is float and is_finite(value) and absf(value) <= 9007199254740991.0 \
		and value == floorf(value): return int(value)
	return value

static func preparation_hash(prepared: Dictionary) -> String:
	var bound := prepared.duplicate(true)
	bound.erase("hash")
	return fingerprint(bound)

static func valid(raw: Variant, retained: Variant) -> bool:
	if not raw is Dictionary or raw.size() != FIELDS.size(): return false
	for field: String in FIELDS:
		if not raw.has(field): return false
	if not E._integer(raw.version, 1, 1) or raw.kind != KIND: return false
	for field: String in ["character_id", "world_id", "world_namespace", "session_epoch", "retained_event"]:
		if not E._opaque_id(raw[field]): return false
	if not _hex(raw.preparation_id, 32) or not _hex(raw.hash, 64) or not _hex(raw.duty_hash, 64) \
		or not E._integer(raw.revision, 0, 2147483645) \
		or not raw.before is Dictionary or not raw.after is Dictionary or not raw.duty is Dictionary \
		or not _passive_shape(raw.before) or not _passive_shape(raw.after) \
		or not _number(raw.elapsed) or not _number(raw.distance) or not E._integer(raw.landmarks, 0, PASSIVE.MAX_DISCOVERIES) \
		or not PASSIVE.discovery_shape(raw.discoveries): return false
	if not EVENT.valid(retained, raw.world_namespace, raw.world_id) \
		or retained.delivery_id != raw.retained_event or raw.duty.get("action") != "research_event" \
		or raw.duty.get("character_id") != raw.character_id or fingerprint(raw.duty) != raw.duty_hash: return false
	var matches := 0
	for duty: Dictionary in retained.duties:
		if E._equivalent(duty, raw.duty): matches += 1
	if matches != 1: return false
	var discoveries := 0
	for ids: Array in raw.discoveries.values(): discoveries += ids.size()
	if raw.landmarks > discoveries or not RECORD.errors(raw.before, raw.character_id).is_empty(): return false
	var derived := PASSIVE.derive(raw.before, float(raw.elapsed), float(raw.distance), int(raw.landmarks))
	return not derived.is_empty() and E._equivalent(derived, raw.after) \
		and E._equivalent(PASSIVE.unchanged_core(raw.before), PASSIVE.unchanged_core(raw.after)) \
		and preparation_hash(raw) == raw.hash

static func owner_plan(current: Dictionary, prepared: Dictionary, retained: Dictionary,
		current_discoveries: Dictionary) -> Dictionary:
	if not _passive_shape(current) or not valid(prepared, retained) \
		or not RECORD.errors(current, str(prepared.get("character_id", ""))).is_empty() \
		or not PASSIVE.discovery_shape(current_discoveries) \
		or not E._equivalent(PASSIVE.unchanged_core(current), PASSIVE.unchanged_core(prepared.after)):
		return {"ok": false, "code": "research_passive_baseline_conflict"}
	for index: int in current.party.size():
		for field: String in PASSIVE.COUNTERS:
			var ahead := int(current.party[index][field]) > int(prepared.after.party[index][field]) \
				if field == "landmarks_visited_together" else float(current.party[index][field]) > float(prepared.after.party[index][field])
			if ahead:
				return {"ok": false, "code": "research_passive_unobserved_progress"}
	var merged := current_discoveries.duplicate(true)
	for realm: String in prepared.discoveries:
		if not merged.has(realm): merged[realm] = []
		for id: String in prepared.discoveries[realm]:
			if not merged[realm].has(id): merged[realm].append(id)
	if not PASSIVE.discovery_shape(merged): return {"ok": false, "code": "research_passive_discovery_budget"}
	return {"ok": true, "state": prepared.after.duplicate(true), "discoveries": merged}

static func _passive_shape(record: Variant) -> bool:
	if not record is Dictionary or not record.get("party") is Array: return false
	for card: Variant in record.party:
		if not card is Dictionary: return false
		for field: String in ["rested", "resting"]:
			if not card.get(field) is bool: return false
		for field: String in ["nourishment", "happiness", "rested_seconds_left", "distance_m_together"]:
			if not _number(card.get(field)) or float(card[field]) < 0.0: return false
		var landmarks: Variant = card.get("landmarks_visited_together")
		if landmarks is int:
			if landmarks < 0: return false
		elif landmarks is float:
			# Legacy JSON may carry an integral float. The lifetime counter is an
			# int64, so reject only values its existing storage cannot represent.
			if not is_finite(landmarks) or landmarks < 0.0 or landmarks >= 9223372036854775808.0 \
				or landmarks != floorf(landmarks): return false
		else: return false
	return true

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _hex(value: Variant, length: int) -> bool:
	return value is String and value.length() == length and value.is_valid_hex_number(false) and value.to_lower() == value
