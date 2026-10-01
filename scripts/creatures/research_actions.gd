extends RefCounted

## Host-only adapter over the actual Session admission registry and prepared
## LedgerRpc writer. No second event queue, balance, journal or save system.
const LOG := preload("res://scripts/creatures/research_log.gd")
const ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")

static func commit(session: Node, peer: int, action: String, intent: Dictionary, event: Dictionary = {}, admission_guard: Callable = Callable()) -> Dictionary:
	if session == null or not session.call("is_host") or LOG.config().get("runtime_enabled") != true:
		return ACTIONS.deny("Research rewards are unavailable.")
	if action not in LOG.ACTIONS: return ACTIONS.deny("invalid_research_action")
	var game: Node = session.call("_game")
	if game == null or game.get("session") != session: return ACTIONS.deny("research_session_changed")
	var saver: RefCounted = game.get("save_system")
	if saver == null: return ACTIONS.deny("research_writer_unavailable")
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true: return ACTIONS.deny("fallback_busy")
	if admission_guard.is_valid() and admission_guard.call() != true: return ACTIONS.deny("research_generation_changed")
	game = session.call("_game")
	if game == null or game.get("session") != session or game.get("save_system") != saver: return ACTIONS.deny("research_session_changed")
	var character := str(session.call("_authority_character", peer))
	var admitted: Dictionary = session.call("admitted_character_state", peer)
	var registry: RefCounted = session.get("_character_authority")
	var writer := session.get_node_or_null(^"LedgerRpc")
	if character.is_empty() or admitted.is_empty() or registry == null or writer == null: return ACTIONS.deny("research_admission_unavailable")
	var current: Dictionary = registry.call("state", character)
	var revision := int(registry.call("revision", character))
	var context := {"character_id": character, "expected_revision": revision, "in_range": true,
		"source_key": "research_journal"}
	if action == "research_event":
		# Only the host-internal validated producer calls this arm. No event RPC.
		context.merge(event, true)
		context.character_id = character
		context.expected_revision = revision
		context.in_range = true
	var proposal := LOG.stage(current, revision, action, intent, context)
	if proposal.get("ok") != true:
		if proposal.get("code") != "reconcile_original_decision": return proposal
		# A personal receipt is earned, but cannot stand in for an owner ACK.
		var world: RefCounted = game.get("world")
		var row: Variant = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character))
		var codec: Script = load("res://autoload/world_state.gd")
		if not row is Dictionary or codec.call("training_row_valid", row, world.reward_delivery_namespace, world.world_id) != true \
			or row.get("character_id") != character \
			or not row.get("after", {}).get("redesign_character", {}).get("transaction_receipts", []).has(_receipt(character, action, intent, event)):
			return ACTIONS.deny("research_decision_not_retained")
		if row.get("status") == "pending": writer.call("_process_creature_training", row)
		return {"ok": true, "durable": true, "resolved": row.get("status") == "accepted"}
	return ACTIONS.commit_host_action(registry, writer, peer, character, revision, action, intent, context)

static func _receipt(character: String, action: String, intent: Dictionary, event: Dictionary) -> String:
	if action == "research_claim": return "research:%s:%s:%s" % [intent.get("species_id", ""), intent.get("task_id", ""), character]
	var digest := JSON.stringify([event.get("world_namespace"), event.get("session_id"), event.get("event_id"), event.get("species_id"), event.get("kind")]).sha256_text()
	return "research:event_%s:%s" % [digest, character]

static func defeated_source(session: Node, frozen: Dictionary) -> Dictionary:
	if LOG.config().get("runtime_enabled") != true: return {"ok": true, "durable": true, "resolved": true, "disabled": true}
	if session == null or session.call("is_host") != true: return ACTIONS.deny("host_research_required")
	var retained: Dictionary = session.call("_retained_host_wild_source", frozen)
	if retained.is_empty() or frozen.get("accepted", {}).get("delta", {}).get("killed") != true \
		or not frozen.get("record", {}).get("participants") is Dictionary \
		or frozen.get("enemy_record", {}).get("fainted") != true: return ACTIONS.deny("actual_retained_defeat_required")
	var participants: Array[String] = []
	var peers: Array[int] = []
	for peer: int in frozen.record.participants:
		var character := str(session.call("_authority_character", peer))
		if character.is_empty() or frozen.record.participants[peer].get("character_id") != character: return ACTIONS.deny("research_participant_departed")
		participants.append(character)
		peers.append(peer)
	var event := {"source_key": "encounter:" + str(frozen.record.encounter_id), "event_confirmed": true,
		"world_namespace": frozen.world_namespace, "session_id": frozen.session_id, "event_id": frozen.source_id,
		"participants": participants, "species_id": frozen.enemy_record.species_id,
		"kind": "defeat", "opponent_defeated": true}
	var resolved := true
	for peer: int in peers:
		var outcome := commit(session, peer, "research_event", {}, event)
		# A saturated species requires no new transaction. It is not a payout.
		if outcome.get("code") == "research_no_progress": continue
		if outcome.get("ok") != true: return outcome
		if outcome.get("resolved") != true: resolved = false
	return {"ok": true, "durable": true, "resolved": resolved}
