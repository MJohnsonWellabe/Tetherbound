extends RefCounted

## Version 3 of EXISTING creature_training rows, at the same per-character
## delivery ID. Version 1 keeps its old F27 meaning and validates unchanged.
## This codec stages/rechecks a detached action; it has no mutable registry.
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const VERSION := 3
const KIND := "creature_training"
const FIELDS := ["version", "kind", "delivery_id", "world_id", "world_namespace", "session_id", "character_id", "action", "action_id", "intent", "host_context", "source_key", "before", "after", "receipt", "character_revision", "journal_revision", "status"]


static func valid(raw: Variant, schema_check: Callable,
		character: String = "", world_namespace: String = "", world: String = "") -> bool:
	if not raw is Dictionary or raw.size() != FIELDS.size(): return false
	for field: String in FIELDS:
		if not raw.has(field): return false
	if not ESSENCE._integer(raw.version, VERSION, VERSION) or raw.kind != KIND or raw.action not in ACTIONS.ACTIONS or raw.status not in ["pending", "accepted"]: return false
	for field: String in ["delivery_id", "world_id", "world_namespace", "session_id", "character_id", "action_id", "source_key", "receipt"]:
		if not raw[field] is String or raw[field].is_empty() or raw[field].length() > 2048: return false
	if not ESSENCE._integer(raw.character_revision, 1, 2147483647) or not ESSENCE._integer(raw.journal_revision, 1, 2147483647): return false
	if (not character.is_empty() and raw.character_id != character) or (not world_namespace.is_empty() and raw.world_namespace != world_namespace) or (not world.is_empty() and raw.world_id != world): return false
	if raw.delivery_id != ESSENCE.training_delivery_id(raw.world_namespace, raw.character_id) or raw.action_id != raw.receipt.sha256_text(): return false
	if not raw.intent is Dictionary or not raw.host_context is Dictionary or not raw.before is Dictionary or not raw.after is Dictionary: return false
	if raw.host_context.get("source_key") != raw.source_key or raw.before.get("character_id") != raw.character_id or raw.after.get("character_id") != raw.character_id: return false
	if raw.action in ["rematch_win", "combat_mastery", "combat_round_reward"] and (raw.host_context.get("world_namespace") != raw.world_namespace \
		or raw.host_context.get("session_id") != raw.session_id): return false
	if raw.action in ["resource", "groom"] and (raw.host_context.get("world_namespace") != raw.world_namespace \
		or raw.host_context.get("world_id") != raw.world_id): return false
	# Re-run the exact canonical callback against the frozen pre-decision full
	# record. An imported balance, alternative trait seed or changed choice
	# cannot turn a saved row or packet into a different accepted operation.
	var proposal := ACTIONS.stage(raw.before, int(raw.character_revision) - 1,
		raw.action, raw.intent, raw.host_context, schema_check)
	return proposal.get("ok") == true and proposal.receipt == raw.receipt \
		and ESSENCE._equivalent(proposal.state, raw.after) \
		and not raw.before.redesign_character.transaction_receipts.has(raw.receipt) \
		and raw.after.redesign_character.transaction_receipts.has(raw.receipt)


static func make_record(world: String, world_namespace: String, epoch: String,
		accepted: Dictionary, previous: Variant, schema_check: Callable) -> Dictionary:
	if not accepted.get("state") is Dictionary or not accepted.get("before") is Dictionary or not accepted.get("intent") is Dictionary or not accepted.get("host_context") is Dictionary: return {}
	var character: Variant = accepted.get("character_id")
	if not character is String or not ESSENCE._integer(accepted.get("character_revision"), 1, 2147483647): return {}
	var journal_revision := 1
	if previous != null:
		var previous_valid: bool = load("res://autoload/world_state.gd").training_row_valid(previous, world_namespace, world)
		if not previous_valid or previous.world_id != world or previous.status != "accepted" or int(previous.character_revision) >= int(accepted.character_revision): return {}
		journal_revision = int(previous.journal_revision) + 1
	var row := {"version": VERSION, "kind": KIND,
		"delivery_id": ESSENCE.training_delivery_id(world_namespace, character),
		"world_id": world, "world_namespace": world_namespace, "session_id": epoch,
		"character_id": character, "action": accepted.get("action"),
		"action_id": str(accepted.get("receipt", "")).sha256_text(),
		"intent": accepted.intent.duplicate(true), "host_context": accepted.host_context.duplicate(true),
		"source_key": accepted.get("source_key"), "before": accepted.before.duplicate(true),
		"after": accepted.state.duplicate(true), "receipt": accepted.get("receipt"),
		"character_revision": int(accepted.character_revision), "journal_revision": journal_revision, "status": "pending"}
	return row if valid(row, schema_check, character, world_namespace, world) else {}


static func owner_plan(current: Dictionary, row: Dictionary, schema_check: Callable) -> Dictionary:
	if not valid(row, schema_check, str(current.get("character_id", ""))): return ACTIONS.deny("invalid_action_delivery")
	if row.action == "combat_round_reward": return preload("res://scripts/net/combat_round_reward.gd").owner_plan(current, row)
	if not ESSENCE._equivalent(current, row.before):
		if ESSENCE._equivalent(current, row.after):
			return {"ok": true, "duplicate": true, "requires_owner_save": true, "state": current.duplicate(true), "receipt": row.receipt}
		return ACTIONS.deny("owner_action_baseline_conflict")
	if row.status != "pending": return ACTIONS.deny("accepted_history_is_not_a_new_award")
	return {"ok": true, "duplicate": false, "requires_owner_save": true,
		"before": current.duplicate(true), "state": row.after.duplicate(true), "receipt": row.receipt}
