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
const ACTION_KIND := "owner_action_passive_preparation"
const RECOVERY_KIND := "owner_portal_recovery"
const RECOVERY_FIELDS := ["version", "kind", "original", "baseline", "stream_id", "preparation_id", "before", "after", "discoveries", "input_prefix_hash", "final_sequence", "hash"]
const ACTION_FIELDS := ["version", "kind", "character_id", "world_id", "world_namespace", "session_epoch", "source_kind", "request", "request_hash", "host_context", "preparation_id", "revision", "before", "after", "discoveries", "input_prefix_hash", "final_sequence", "hash"]
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
	if duty.get("action") == "combat_round_reward":
		prepared.after = preload("res://scripts/net/combat_round_reward.gd").settled_before(prepared.after, duty.intent, duty.context)
	elif duty.get("action") == "wild_defeat_share":
		prepared.after = preload("res://scripts/net/wild_actor_scope.gd").settled_before(prepared.after, duty.context)
	prepared.hash = preparation_hash(prepared)
	return prepared if valid_host(prepared, retained, cursor) else {}

static func fingerprint(value: Dictionary) -> String:
	return BASE.fingerprint(value)

## A real authenticated player request is a different source from a retained
## FoundationEvent. Context is host-derived; packet validation cannot prove it.
static func make_action(request: Dictionary, host_context: Dictionary, before: Dictionary,
		revision: int, epoch: String, world_id: String, cursor: Dictionary,
		preparation_id: String, source_kind: String = "foundation_request") -> Dictionary:
	if not cursor.get("state") is Dictionary or not cursor.get("discovered") is Dictionary: return {}
	var prepared := {"version": 1, "kind": ACTION_KIND, "character_id": before.get("character_id"),
		"world_id": world_id, "world_namespace": request.get("world_namespace"), "session_epoch": epoch,
		"source_kind": source_kind, "request": request.duplicate(true), "request_hash": fingerprint(request),
		"host_context": host_context.duplicate(true), "preparation_id": preparation_id, "revision": revision,
		"before": before.duplicate(true), "after": cursor.state.duplicate(true),
		"discoveries": cursor.discovered.duplicate(true), "input_prefix_hash": cursor.get("prefix_hash", ""),
		"final_sequence": cursor.get("sequence", -1)}
	prepared.hash = preparation_hash(prepared)
	return prepared if valid_action_host(prepared, cursor) else {}

static func valid_action(raw: Variant) -> bool:
	if not raw is Dictionary or not _fields(raw, ACTION_FIELDS): return false
	if not E._integer(raw.version, 1, 1) or raw.kind != ACTION_KIND: return false
	for field: String in ["character_id", "world_id", "world_namespace", "session_epoch"]:
		if not E._opaque_id(raw[field]): return false
	if not BASE._hex(raw.preparation_id, 32) or not BASE._hex(raw.hash, 64) \
		or not BASE._hex(raw.request_hash, 64) or not BASE._hex(raw.input_prefix_hash, 64) \
		or not E._integer(raw.revision, 0, 2147483645) or not E._integer(raw.final_sequence, 0, 2147483647) \
		or not raw.before is Dictionary or not raw.after is Dictionary \
		or not raw.request is Dictionary or not raw.host_context is Dictionary \
		or not BASE._passive_shape(raw.before) or not BASE._passive_shape(raw.after) \
		or not PASSIVE.discovery_shape(raw.discoveries): return false
	if not RECORD.errors(raw.before, raw.character_id).is_empty() \
		or not RECORD.errors(raw.after, raw.character_id).is_empty() \
		or not _action_request_valid(raw) or fingerprint(raw.request) != raw.request_hash: return false
	return preparation_hash(raw) == raw.hash \
		and exact(PASSIVE.unchanged_core(raw.before), PASSIVE.unchanged_core(raw.after))

static func _fields(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size(): return false
	for field: String in fields:
		if not value.has(field): return false
	return true

static func _action_request_valid(raw: Dictionary) -> bool:
	var request: Dictionary = raw.request
	if raw.source_kind == "portal_arrival": return _portal_request_valid(raw)
	if raw.source_kind == "waystone_touch": return _waystone_request_valid(raw)
	if raw.source_kind == "home_key": return _home_key_request_valid(raw)
	var fields := ["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent"]
	if raw.source_kind in ["foundation_request", "manual_refine", "tether_item"]: fields.append("revision")
	if not _fields(request, fields) or not request.intent is Dictionary \
		or request.session_epoch != raw.session_epoch or request.world_namespace != raw.world_namespace \
		or request.character_id != raw.character_id or not E._opaque_id(request.station_key) \
		or raw.host_context.get("character_id") != raw.character_id \
		or raw.host_context.get("expected_revision") != raw.revision \
		or raw.host_context.get("in_range") != true or raw.host_context.get("in_combat") != (raw.source_kind == "tether_item") \
		or raw.host_context.get("foundation_runtime_authorized") != true: return false
	var expected_source: String = request.station_key
	if raw.source_kind == "foundation_request" and request.op == "master_chest":
		if not E._component(request.intent.get("master_id")) \
			or request.station_key != "master:" + str(request.intent.master_id) \
			or raw.host_context.get("master_id") != request.intent.master_id: return false
		expected_source = "master_chest:" + str(request.intent.master_id)
	if raw.host_context.get("source_key") != expected_source: return false
	if raw.source_kind == "tether_item":
		if request.op != "tether_item" or not E._integer(request.revision, 0, 2147483645) \
			or request.revision != raw.revision or raw.host_context.get("world_namespace") != raw.world_namespace:
			return false
		# This only checks the typed frozen source and the replayed care state.
		# Session separately proves the actual retained Director/body original.
		return preload("res://scripts/net/foundation_actions.gd").stage(raw.after, int(raw.revision),
			"tether_item", request.intent, raw.host_context, RECORD.errors).get("ok") == true
	if raw.source_kind == "foundation_request" and request.op == "tether_pouch":
		return request.station_key == "personal_pouch:" + str(raw.character_id) \
			and raw.host_context.get("station_kind") == "personal_pouch" and raw.host_context.get("owns_character") == true \
			and E._integer(request.revision, 0, 2147483645) and request.revision == raw.revision \
			and _fields(request.intent, ["assignment_id", "index", "item_id"]) \
			and E._component(request.intent.assignment_id) and E._integer(request.intent.index, 0, 2) \
			and request.intent.item_id is String
	match raw.source_kind:
		"foundation_request":
			return request.op in ["station_craft", "feast_cook", "feast_feed", "candy_feed", "relic_hang", "relic_power", "master_chest", "essence_release"] \
				and E._integer(request.revision, 0, 2147483645) and request.revision == raw.revision
		"altar_spend":
			return request.op == "altar_spend" \
				and raw.host_context.get("actual_altar") == true and raw.host_context.get("station_id") == "altar" \
				and _fields(request.intent, ["spend_id", "creature_uid", "expected_level", "payment_item", "expected_character_revision"]) \
				and request.intent.expected_character_revision == raw.revision
		"altar_traits":
			return request.op == "altar_trait" \
				and _fields(request.intent, ["action_id", "action", "creature_uid", "trait_id", "slot", "payment_item", "expected_character_revision"]) \
				and request.intent.action in ["teach", "release"] and request.intent.expected_character_revision == raw.revision
		"manual_refine":
			return request.op == "refine_start" and request.revision == -1 \
				and _fields(request.intent, ["recipe_id", "amount"]) \
				and E._opaque_id(request.intent.recipe_id) and E._integer(request.intent.amount, 1, 2147483647) \
				and raw.host_context.get("completed_manual_refine") == true \
				and BASE._hex(raw.host_context.get("manual_unit_ticket"), 32) \
				and raw.host_context.get("manual_unit_plan") is Dictionary \
				and raw.host_context.manual_unit_plan.get("recipe_id") == request.intent.recipe_id
	return false

## This source is a retained consumed permit, not a claim that departure is
## already grounded. Session/PortalArrival prove actual ground at final stage.
static func portal_request(envelope: Dictionary, permit: Dictionary) -> Dictionary:
	return {"op": "portal_arrival", "session_epoch": envelope.get("session_epoch"),
		"world_namespace": envelope.get("world_instance_id"), "character_id": envelope.get("character_id"),
		"envelope": envelope.duplicate(true), "permit": permit.duplicate(true)}

static func _portal_request_valid(raw: Dictionary) -> bool:
	var request: Dictionary = raw.request
	if not _fields(request, ["op", "session_epoch", "world_namespace", "character_id", "envelope", "permit"]) \
		or request.op != "portal_arrival" or request.session_epoch != raw.session_epoch \
		or request.world_namespace != raw.world_namespace or request.character_id != raw.character_id \
		or not request.envelope is Dictionary or not request.permit is Dictionary: return false
	var envelope: Dictionary = request.envelope
	var permit: Dictionary = request.permit
	if not _fields(envelope, ["request_id", "session_epoch", "world_instance_id", "character_id", "payload"]) \
		or not _fields(permit, ["peer_id", "character_id", "world_instance_id", "request_id", "origin_realm", "realm", "entry_id"]) \
		or envelope.session_epoch != raw.session_epoch or envelope.world_instance_id != raw.world_namespace \
		or envelope.character_id != raw.character_id or not E._opaque_id(envelope.request_id) \
		or not envelope.request_id.begins_with(raw.session_epoch + ":") \
		or not envelope.payload is Dictionary or envelope.payload.get("kind") not in ["home_key_finish", "portal_enter"] \
		or not preload("res://scripts/net/portal_action_policy.gd").valid_payload(envelope.payload) \
		or not E._integer(permit.peer_id, 1, 2147483647) or permit.character_id != raw.character_id \
		or permit.world_instance_id != raw.world_namespace or not E._opaque_id(permit.request_id) \
		or permit.origin_realm not in ["meadows", "water", "cloudreach", "stormwood"] \
		or permit.realm not in ["meadows", "water", "cloudreach", "stormwood"] or not E._opaque_id(permit.entry_id): return false
	var context: Dictionary = raw.host_context
	return _fields(context, ["character_id", "expected_revision", "source_key", "consumed_portal_permit"]) \
		and context.character_id == raw.character_id and context.expected_revision == raw.revision \
		and context.source_key == "arrival:" + permit.request_id and context.consumed_portal_permit == true

## F18 waystone touch: the owner's own frozen portal envelope, plus the exact
## host context _commit_waystone_touch stages. The host validated proximity
## against its mounted stone before asking; this checks shape and binding only.
static func waystone_request(envelope: Dictionary) -> Dictionary:
	return {"op": "waystone_touch", "session_epoch": envelope.get("session_epoch"),
		"world_namespace": envelope.get("world_instance_id"), "character_id": envelope.get("character_id"),
		"envelope": envelope.duplicate(true)}

static func _waystone_request_valid(raw: Dictionary) -> bool:
	var request: Dictionary = raw.request
	if not _fields(request, ["op", "session_epoch", "world_namespace", "character_id", "envelope"]) \
		or request.op != "waystone_touch" or request.session_epoch != raw.session_epoch \
		or request.world_namespace != raw.world_namespace or request.character_id != raw.character_id \
		or not request.envelope is Dictionary: return false
	var envelope: Dictionary = request.envelope
	if not _fields(envelope, ["request_id", "session_epoch", "world_instance_id", "character_id", "payload"]) \
		or envelope.session_epoch != raw.session_epoch or envelope.world_instance_id != raw.world_namespace \
		or envelope.character_id != raw.character_id or not E._opaque_id(envelope.request_id) \
		or not envelope.request_id.begins_with(raw.session_epoch + ":") \
		or not envelope.payload is Dictionary or envelope.payload.get("kind") != "waystone_touch" \
		or not preload("res://scripts/net/portal_action_policy.gd").valid_payload(envelope.payload): return false
	var context: Dictionary = raw.host_context
	return _fields(context, ["character_id", "expected_revision", "in_range", "in_combat",
			"foundation_runtime_authorized", "validated_touch", "source_key", "touch_id", "realm", "world_namespace"]) \
		and context.character_id == raw.character_id and context.expected_revision == raw.revision \
		and context.in_range == true and context.in_combat == false \
		and context.foundation_runtime_authorized == true and context.validated_touch == true \
		and context.source_key == "waystone:" + str(envelope.payload.waystone_id) \
		and BASE._hex(context.touch_id, 32) and context.realm is String and not str(context.realm).is_empty() \
		and context.world_namespace == raw.world_namespace

## F18 Home Key owe/deliver: the owner's own reconcile request (its identity
## fences plus the gift's delivery ID) and the exact host context
## opening_home_key.commit_reconcile stages.
static func home_key_request(request: Dictionary) -> Dictionary:
	return {"op": "home_key_reconcile", "session_epoch": request.get("session_epoch"),
		"world_namespace": request.get("world_instance_id"), "character_id": request.get("character_id"),
		"envelope": request.duplicate(true)}

static func _home_key_request_valid(raw: Dictionary) -> bool:
	var request: Dictionary = raw.request
	if not _fields(request, ["op", "session_epoch", "world_namespace", "character_id", "envelope"]) \
		or request.op != "home_key_reconcile" or request.session_epoch != raw.session_epoch \
		or request.world_namespace != raw.world_namespace or request.character_id != raw.character_id \
		or not request.envelope is Dictionary: return false
	var envelope: Dictionary = request.envelope
	if not _fields(envelope, ["character_id", "world_instance_id", "session_epoch", "delivery_id", "origin_namespace"]) \
		or envelope.session_epoch != raw.session_epoch or envelope.world_instance_id != raw.world_namespace \
		or envelope.character_id != raw.character_id or not BASE._hex(envelope.delivery_id, 64) \
		or not envelope.origin_namespace is String or envelope.origin_namespace.is_empty(): return false
	var context: Dictionary = raw.host_context
	var HOME: Script = preload("res://scripts/net/home_key_action.gd")
	return _fields(context, ["character_id", "expected_revision", "in_range", "in_combat",
			"foundation_runtime_authorized", "home_key_authorized", "home_key_record", "source_key"]) \
		and context.character_id == raw.character_id and context.expected_revision == raw.revision \
		and context.in_range == true and context.in_combat == false \
		and context.foundation_runtime_authorized == true and context.home_key_authorized == true \
		and HOME.valid_escrow(context.home_key_record, raw.character_id) \
		and context.home_key_record.delivery_id == envelope.delivery_id \
		and context.home_key_record.world_namespace == envelope.origin_namespace \
		and context.source_key == "opening_home_key:" + envelope.delivery_id

static func valid_action_host(raw: Variant, cursor: Variant) -> bool:
	return valid_action(raw) and cursor is Dictionary \
		and exact(raw.before, cursor.get("base")) and exact(raw.after, cursor.get("state")) \
		and exact(raw.discoveries, cursor.get("discovered")) \
		and raw.final_sequence == cursor.get("sequence", -1) \
		and raw.input_prefix_hash == cursor.get("prefix_hash", "")

static func preparation_hash(prepared: Dictionary) -> String:
	return BASE.preparation_hash(prepared)

## A reconnect saves its own replayed state, while the original reservation
## still owns the old CAS. No departed permit authorizes a second journey.
static func make_recovery(original: Dictionary, baseline: Dictionary, stream_id: String, cursor: Dictionary, id: String) -> Dictionary:
	var prepared := {"version": 1, "kind": RECOVERY_KIND, "original": original.duplicate(true),
		"baseline": baseline.duplicate(true), "stream_id": stream_id, "preparation_id": id, "before": cursor.base.duplicate(true),
		"after": cursor.state.duplicate(true), "discoveries": cursor.discovered.duplicate(true),
		"input_prefix_hash": cursor.prefix_hash, "final_sequence": cursor.sequence}
	prepared.hash = preparation_hash(prepared)
	return prepared if valid_recovery(prepared) else {}

static func valid_recovery(raw: Variant) -> bool:
	if not raw is Dictionary or not _fields(raw, RECOVERY_FIELDS) or not E._integer(raw.version, 1, 1) or raw.kind != RECOVERY_KIND \
		or not valid_action(raw.original) or raw.original.source_kind != "portal_arrival" \
		or not valid_action(raw.baseline) or raw.baseline.source_kind != "portal_arrival" \
		or raw.baseline.world_id != raw.original.world_id \
		or not exact(raw.baseline.request, raw.original.request) or not exact(raw.baseline.host_context, raw.original.host_context) \
		or (not exact(raw.baseline.before, raw.original.before) and not exact(raw.baseline.before, raw.original.after)) \
		or not BASE._hex(raw.stream_id, 32) or not BASE._hex(raw.preparation_id, 32) \
		or not BASE._hex(raw.hash, 64) or not BASE._hex(raw.input_prefix_hash, 64) \
		or not E._integer(raw.final_sequence, 0, 2147483647) \
		or not raw.before is Dictionary or not raw.after is Dictionary \
		or not BASE._passive_shape(raw.before) or not BASE._passive_shape(raw.after) \
		or not PASSIVE.discovery_shape(raw.discoveries): return false
	return exact(raw.before, raw.baseline.after) \
		and RECORD.errors(raw.after, raw.original.character_id).is_empty() \
		and exact(PASSIVE.unchanged_core(raw.before), PASSIVE.unchanged_core(raw.after)) \
		and preparation_hash(raw) == raw.hash

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
		or retained.delivery_id != raw.retained_event or raw.duty.get("action") not in ["research_event", "capture_offer", "master_win", "boss_relic", "combat_mastery", "combat_round_reward", "wild_defeat_share"] \
		or raw.duty.get("character_id") != raw.character_id or fingerprint(raw.duty) != raw.duty_hash:
		return false
	var matches := 0
	for duty: Dictionary in retained.duties:
		if exact(duty, raw.duty): matches += 1
	var core_before: Dictionary = raw.before
	if raw.duty.action == "combat_round_reward":
		core_before = preload("res://scripts/net/combat_round_reward.gd").settled_before(raw.before, raw.duty.intent, raw.duty.context)
		if core_before.is_empty(): return false
	elif raw.duty.action == "wild_defeat_share":
		core_before = preload("res://scripts/net/wild_actor_scope.gd").settled_before(raw.before, raw.duty.context)
		if core_before.is_empty(): return false
	return matches == 1 and preparation_hash(raw) == raw.hash \
		and exact(PASSIVE.unchanged_core(core_before), PASSIVE.unchanged_core(raw.after))

static func valid_host(raw: Variant, retained: Variant, cursor: Variant) -> bool:
	if not valid(raw, retained) or not cursor is Dictionary: return false
	var expected: Variant = cursor.get("state")
	if raw.duty.action in ["combat_round_reward", "wild_defeat_share"]:
		if not expected is Dictionary: return false
		var replay: Script = load("res://scripts/net/owner_passive_replay.gd")
		if replay.call("_cursor_valid", cursor) != true: return false
		if raw.duty.action == "wild_defeat_share": expected = preload("res://scripts/net/wild_actor_scope.gd").settled_before(expected, raw.duty.context)
		else: expected = preload("res://scripts/net/combat_round_reward.gd").settled_before(expected, raw.duty.intent, raw.duty.context)
	return exact(raw.before, cursor.get("base")) \
		and exact(raw.after, expected) \
		and exact(raw.discoveries, cursor.get("discovered")) \
		and raw.final_sequence == cursor.get("sequence", -1) \
		and raw.input_prefix_hash == cursor.get("prefix_hash", "")

static func owner_plan(current: Dictionary, prepared: Dictionary, retained: Dictionary,
		current_discoveries: Dictionary) -> Dictionary:
	var source_valid: bool = valid_recovery(prepared) if prepared.get("kind") == RECOVERY_KIND else (valid_action(prepared) if prepared.get("kind") == ACTION_KIND else valid(prepared, retained))
	if not source_valid or not exact(current, prepared.after) \
		or not exact(current_discoveries, prepared.discoveries):
		return {"ok": false, "code": "owner_passive_checkpoint_conflict"}
	return {"ok": true, "state": current.duplicate(true), "discoveries": current_discoveries.duplicate(true)}
