extends RefCounted

## Exact owner-input checkpoint. Packet validation proves binding, never host
## geometry/time authority. Only valid_host with a locally replayed cursor may
## reserve it. Owners save their matching existing state; nothing is installed.
const BASE := preload("res://scripts/net/research_passive_preparation.gd")
const E := preload("res://scripts/creatures/essence.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const PASSIVE := preload("res://scripts/net/groom_passive_sync.gd")
const KIND := "owner_passive_preparation"
const FIELDS := ["version", "kind", "character_id", "world_id", "world_namespace", "session_epoch", "retained_event", "duty", "duty_hash", "preparation_id", "revision", "before", "after", "discoveries", "input_prefix_hash", "final_sequence", "hash"]

static func make(retained: Dictionary, duty: Dictionary, before: Dictionary, revision: int,
		epoch: String, cursor: Dictionary, preparation_id: String) -> Dictionary:
	if not cursor.get("state") is Dictionary or not cursor.get("discovered") is Dictionary: return {}
	var prepared := {"version": 1, "kind": KIND, "character_id": before.get("character_id"),
		"world_id": retained.get("world_id"), "world_namespace": retained.get("world_namespace"),
		"session_epoch": epoch, "retained_event": retained.get("delivery_id"),
		"duty": duty.duplicate(true), "duty_hash": fingerprint(duty), "preparation_id": preparation_id,
		"revision": revision, "before": before.duplicate(true), "after": cursor.get("state", {}).duplicate(true),
		"discoveries": cursor.get("discovered", {}).duplicate(true),
		"input_prefix_hash": cursor.get("prefix_hash", ""), "final_sequence": cursor.get("sequence", -1)}
	prepared.hash = preparation_hash(prepared)
	return prepared if valid_host(prepared, retained, cursor) else {}

static func fingerprint(value: Dictionary) -> String:
	return BASE.fingerprint(value)

static func preparation_hash(prepared: Dictionary) -> String:
	return BASE.preparation_hash(prepared)

static func exact(left: Variant, right: Variant) -> bool:
	if not left is Dictionary or not right is Dictionary: return false
	var digest := fingerprint(left)
	return not digest.is_empty() and digest == fingerprint(right)

static func valid(raw: Variant, retained: Variant) -> bool:
	if not raw is Dictionary or raw.size() != FIELDS.size(): return false
	for field: String in FIELDS:
		if not raw.has(field): return false
	if not E._integer(raw.version, 1, 1) or raw.kind != KIND: return false
	for field: String in ["character_id", "world_id", "world_namespace", "session_epoch", "retained_event"]:
		if not E._opaque_id(raw[field]): return false
	if not BASE._hex(raw.preparation_id, 32) or not BASE._hex(raw.hash, 64) \
		or not BASE._hex(raw.duty_hash, 64) or not BASE._hex(raw.input_prefix_hash, 64) \
		or not E._integer(raw.revision, 0, 2147483645) \
		or not E._integer(raw.final_sequence, 0, 2147483647) \
		or not raw.before is Dictionary or not raw.after is Dictionary or not raw.duty is Dictionary \
		or not BASE._passive_shape(raw.before) or not BASE._passive_shape(raw.after) \
		or not PASSIVE.discovery_shape(raw.discoveries): return false
	if not RECORD.errors(raw.before, raw.character_id).is_empty() \
		or not RECORD.errors(raw.after, raw.character_id).is_empty() \
		or not EVENT.valid(retained, raw.world_namespace, raw.world_id) \
		or retained.delivery_id != raw.retained_event or raw.duty.get("action") != "research_event" \
		or raw.duty.get("character_id") != raw.character_id or fingerprint(raw.duty) != raw.duty_hash:
		return false
	var matches := 0
	for duty: Dictionary in retained.duties:
		if exact(duty, raw.duty): matches += 1
	return matches == 1 and preparation_hash(raw) == raw.hash \
		and exact(PASSIVE.unchanged_core(raw.before), PASSIVE.unchanged_core(raw.after))

static func valid_host(raw: Variant, retained: Variant, cursor: Variant) -> bool:
	return valid(raw, retained) and cursor is Dictionary \
		and exact(raw.before, cursor.get("base")) \
		and exact(raw.after, cursor.get("state")) \
		and exact(raw.discoveries, cursor.get("discovered")) \
		and raw.final_sequence == cursor.get("sequence", -1) \
		and raw.input_prefix_hash == cursor.get("prefix_hash", "")

static func owner_plan(current: Dictionary, prepared: Dictionary, retained: Dictionary,
		current_discoveries: Dictionary) -> Dictionary:
	if not valid(prepared, retained) or not exact(current, prepared.after) \
		or not exact(current_discoveries, prepared.discoveries):
		return {"ok": false, "code": "owner_passive_checkpoint_conflict"}
	return {"ok": true, "state": current.duplicate(true), "discoveries": current_discoveries.duplicate(true)}
