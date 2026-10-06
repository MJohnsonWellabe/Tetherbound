extends RefCounted

## Detached canonical re-stage adapter for the EXISTING character registry.
## Session alone supplies actual source context and its full schema checker.
## This file has no RPC, storage, save, grant, or mutable authoritative state.
const BREAKTHROUGH := preload("res://scripts/masters/breakthrough_actions.gd")
const FEASTS := preload("res://scripts/creatures/breakthrough.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const CANDY := preload("res://scripts/creatures/candy.gd")
const BOUNTIES := preload("res://scripts/world/bounty_board.gd")
const REMATCH := preload("res://scripts/repeatables/rematch_rules.gd")
const RESEARCH := preload("res://scripts/creatures/research_log.gd")
const RECORD_FIELDS := ["character_id", "party", "redesign_character", "inventory", "portal_escrow", "vitals_escrow", "equipment", "realm_hearts"]
const ACTIONS := ["master_win", "master_chest", "feast_cook", "feast_feed", "candy_feed", "trait_teach", "trait_release", "essence_release", "bounty_rotate", "bounty_event", "bounty_claim", "rematch_win", "research_event", "research_claim"]


static func stage(current: Dictionary, revision: int, action: String,
		intent: Dictionary, context: Dictionary, schema_check: Callable) -> Dictionary:
	if action not in ACTIONS or not schema_check.is_valid() or current.size() != RECORD_FIELDS.size(): return deny("action_unavailable")
	for field: String in RECORD_FIELDS:
		if not current.has(field): return deny("incomplete_admitted_character")
	if not ESSENCE._integer(revision, 0, 2147483646) or not current.character_id is String or current.character_id.is_empty(): return deny("invalid_character_revision")
	if context.get("character_id") != current.character_id or context.get("expected_revision") != revision or context.get("in_range") != true:
		return deny("source_or_revision_changed")
	if not context.get("source_key") is String or context.source_key.is_empty(): return deny("actual_source_required")
	var before_errors: Variant = schema_check.call(current, current.character_id)
	if not before_errors is Array or not before_errors.is_empty(): return deny("invalid_admitted_character")
	var proposal: Dictionary
	var callback_before := current
	if action == "candy_feed":
		proposal = CANDY.stage(current, revision, intent, context)
	elif action in RESEARCH.ACTIONS:
		proposal = RESEARCH.stage(current, revision, action, intent, context)
	elif action in BOUNTIES.ACTIONS:
		proposal = BOUNTIES.stage(current, revision, action, intent, context)
	elif action == "rematch_win":
		proposal = REMATCH.stage(current, revision, intent, context)
	elif action == "essence_release":
		# F27#1: the catch-overflow ceremony releases one of the five owned for
		# its type's essence. The newcomer joins only after this settles, so
		# the five-owned cap and its ceremony are unchanged.
		if context.get("release_ceremony") != true or context.get("in_combat") != false:
			return deny("actual_release_ceremony_required")
		if intent.size() != 2 or not ESSENCE._component(intent.get("creature_uid")) \
				or not ESSENCE._component(intent.get("release_id")): return deny("invalid_release_intent")
		if not current.party is Array or current.party.size() != preload("res://autoload/party.gd").MAX_CREATURES:
			return deny("release_requires_full_party")
		proposal = ESSENCE.stage_release(current, current.character_id, intent.creature_uid, revision, ESSENCE.config())
	elif action in ["trait_teach", "trait_release"]:
		if context.get("station_id") != "altar" or context.get("homestead") != true or context.get("in_combat") != false:
			return deny("actual_altar_required")
		if not TRAITS.intent_valid(intent) or intent.action != ("teach" if action == "trait_teach" else "release"):
			return deny("invalid_trait_intent")
		# The callback owns seed/cost/stats/provenance and the one release payout.
		# Never reconstruct its receipt or apply Essence.release a second time.
		# Adopt only this action's selected mirror. Unrelated legacy cards keep
		# their original marker and stat arithmetic until their own typed action.
		callback_before = current.duplicate(true)
		for owned: Dictionary in callback_before.party:
			if owned.uid == intent.creature_uid:
				callback_before.redesign_character.creatures[owned.uid] = TRAITS.initialize_legacy_record(owned, callback_before.redesign_character.creatures[owned.uid])
				if callback_before.redesign_character.creatures[owned.uid].get("traits_initialized") != true:
					return deny("trait_initialization_required")
		proposal = TRAITS.stage_action(callback_before, current.character_id, intent, revision, ESSENCE.config(), TRAITS.config())
	else:
		# F32 replaced the provisional personal garden producer. It is omitted
		# here; harvesting needs its actual world-stock reservation transaction.
		proposal = BREAKTHROUGH.stage(current, revision, action, intent, context,
			_owned_species_types.bind(current, str(intent.get("creature_uid", ""))), _prepare_feast_choice.bind(current.redesign_character.creatures), FEASTS.refresh_feast_moves)
	if proposal.get("ok") != true: return proposal.duplicate(true)
	if proposal.get("duplicate") == true: return deny("reconcile_original_decision")
	if not proposal.get("state") is Dictionary or not proposal.get("receipt") is String or proposal.receipt.is_empty(): return deny("invalid_action_proposal")
	if proposal.has("before") and not ESSENCE._equivalent(proposal.before, callback_before): return deny("action_baseline_changed")
	if proposal.has("intent") and not proposal.has("original_intent") and not ESSENCE._equivalent(proposal.intent, intent): return deny("action_intent_changed")
	if proposal.has("original_intent") and not ESSENCE._equivalent(proposal.original_intent, intent): return deny("action_intent_changed")
	if proposal.has("original_revision") and proposal.original_revision != revision: return deny("action_revision_changed")
	if proposal.has("expected_character_revision") and proposal.expected_character_revision != revision: return deny("action_revision_changed")
	var next: Dictionary = proposal.state
	var after_errors: Variant = schema_check.call(next, current.character_id)
	if not after_errors is Array or not after_errors.is_empty(): return deny("invalid_action_candidate")
	# Canonical full-state invariants and immutable original intent are checked
	# before a caller may enter the hidden world-save stage. Success here never
	# means owner saved or ACKed; the existing durable journal decides that.
	return {"ok": true, "duplicate": false, "action": action, "character_id": current.character_id,
		"before": current.duplicate(true), "state": next.duplicate(true), "receipt": proposal.receipt,
		"intent": intent.duplicate(true), "host_context": context.duplicate(true),
		"expected_character_revision": revision, "source_key": context.source_key,
		"durable": false, "resolved": false}


static func deny(code: String) -> Dictionary:
	return {"ok": false, "code": code, "durable": false, "resolved": false}


static func _owned_species_types(species_id: String, current: Dictionary, uid: String) -> Array[String]:
	# F28 requests a species ID; Essence validates an admitted creature card.
	# Bind to the actual selected UID, rather than synthesizing type metadata.
	for row: Dictionary in current.party:
		if row.get("uid") == uid and row.get("species_id") == species_id:
			return ESSENCE._species_types(row)
	return []


## Actual Session caller supplies only host-derived context and original
## intent. Hidden promotion, prepared world write, finish/rollback and publish
## are synchronous on the same existing carrier. This never claims owner ACK.
static func commit_host_action(registry: RefCounted, prepared_writer: Node, peer: int,
		character: String, revision: int, action: String,
		original_intent: Dictionary, host_context: Dictionary) -> Dictionary:
	if registry == null or prepared_writer == null or peer < 1 or action not in ACTIONS:
		return deny("invalid_action_commit")
	for method: String in ["stage_character_action", "staged_creature_training", "finish_creature_training"]:
		if not registry.has_method(method): return deny("action_registry_unavailable")
	for method: String in ["journal_creature_training_prepared", "publish_creature_training"]:
		if not prepared_writer.has_method(method): return deny("action_writer_unavailable")
	var stage: Dictionary = registry.call("stage_character_action", character, revision,
		action, original_intent, host_context)
	if stage.get("ok") != true: return stage
	var accepted: Variant = registry.call("staged_creature_training", stage)
	if not accepted is Dictionary or accepted.is_empty():
		registry.call("finish_creature_training", stage, false)
		return deny("action_stage_unavailable")
	var journal: Variant = prepared_writer.call("journal_creature_training_prepared", peer, character, accepted)
	var saved: Variant = journal is Dictionary and journal.get("ok") == true and journal.get("durable") == true
	if registry.call("finish_creature_training", stage, saved) != true:
		return {"ok": false, "code": "action_stage_changed", "durable": saved, "resolved": false}
	if not saved: return journal if journal is Dictionary else deny("action_journal_failed")
	# Publication may cause local owner delivery. It is allowed only AFTER the
	# hidden token has finished and the registry retained its owner-save fence.
	var published: Variant = prepared_writer.call("publish_creature_training", peer, character, accepted.receipt) == true
	return {"ok": true, "durable": true, "resolved": false, "saved": false,
		"pending_owner_save": true, "published": published, "receipt": accepted.receipt,
		"action_id": accepted.action_id, "delivery_id": journal.get("delivery_id", ""),
		"journal_revision": journal.get("journal_revision", 0), "character_revision": accepted.character_revision}


static func _prepare_feast_choice(card: Dictionary, tier: int, choice: String,
		ingredient: String, records: Dictionary) -> Dictionary:
	var staged := EVOLUTION.prepare_feast_choice(card, tier, choice, ingredient)
	if staged.get("ok") != true or staged.get("species_patch", {}).is_empty(): return staged
	var patch: Dictionary = staged.species_patch
	var maximum := ESSENCE._canonical_trait_maximum(staged.creature, float(patch.max_hp), records)
	if not is_finite(maximum) or maximum <= 0.0: return deny("invalid_trait_evolution_stats")
	var fraction := float(card.hp) / float(card.max_hp)
	patch.max_hp = maximum
	patch.hp = maximum * fraction
	staged.creature.merge(patch, true)
	return staged
