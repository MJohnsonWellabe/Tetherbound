extends RefCounted

## Canonical station stages on the existing admitted-character carrier.
## No registry, save file or reward history is owned by this helper.
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const STATION := preload("res://scripts/build/station_actions.gd")
const GEAR := preload("res://scripts/creatures/creature_gear.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const ACTIONS := ["station_craft", "den", "gear", "loadout", "camp_rest", "camp_build", "relic_hang", "boss_relic", "portal_arrival", "regional_ack"]

static func deny(code: String) -> Dictionary:
	return {"ok": false, "code": code, "durable": false, "resolved": false}

static func commit(registry: RefCounted, writer: Node, peer: int, character: String, revision: int, action: String, intent: Dictionary, context: Dictionary) -> Dictionary:
	if action not in ACTIONS or registry == null or writer == null: return deny("action_unavailable")
	var token: Dictionary = registry.call("stage_character_action", character, revision, action, intent, context)
	if token.get("ok") != true: return token
	var accepted: Dictionary = registry.call("staged_creature_training", token)
	var result: Dictionary = writer.call("journal_creature_training_prepared", peer, character, accepted)
	var saved := result.get("ok") == true and result.get("durable") == true
	if registry.call("finish_creature_training", token, saved) != true: return deny("stage_changed")
	if not saved: return result
	writer.call("publish_creature_training", peer, character, accepted.receipt)
	return {"ok": true, "durable": true, "resolved": false, "receipt": accepted.receipt}

static func stage(current: Dictionary, revision: int, action: String,
		intent: Dictionary, context: Dictionary, schema_check: Callable) -> Dictionary:
	if action not in ACTIONS or not schema_check.is_valid() or context.get("character_id") != current.get("character_id") \
		or context.get("expected_revision") != revision or context.get("in_range") != true \
		or context.get("in_combat") != false or str(context.get("source_key", "")).is_empty(): return deny("station_context_changed")
	if not schema_check.call(current, current.character_id).is_empty(): return deny("invalid_admitted_character")
	if context.get("foundation_runtime_authorized") != true: return deny("missing_frozen_authorization")
	var proposal: Dictionary
	match action:
		"station_craft":
			var items := preload("res://scripts/world/death_satchel_rules.gd").db()
			proposal = STATION.stage_craft(current, revision, intent, context, items.call("recipe", str(intent.get("recipe_id", ""))), true)
		"den": proposal = STATION.stage_den_rest(current, revision, intent, context, true)
		"gear": proposal = GEAR.stage_frozen_core(current, current.character_id, revision, intent, context,
			preload("res://scripts/world/death_satchel_rules.gd").db(), GEAR.config())
		"loadout": proposal = _loadout(current, intent, context)
		"camp_rest": proposal = preload("res://scripts/build/forward_camp_actions.gd").stage_team_bed(current, revision, intent, context, true)
		"camp_build": proposal = camp_plan(current, revision, intent, context)
		"relic_hang", "boss_relic": proposal = _relic(current, action, intent, context)
		"portal_arrival", "regional_ack": proposal = _acknowledgement(current, action, intent, context)
	if proposal.get("ok") != true: return proposal
	if not schema_check.call(proposal.state, current.character_id).is_empty(): return deny("invalid_station_candidate")
	return {"ok": true, "action": action, "character_id": current.character_id,
		"before": current.duplicate(true), "state": proposal.state.duplicate(true),
		"receipt": proposal.receipt, "intent": intent.duplicate(true), "host_context": context.duplicate(true),
		"expected_character_revision": revision, "source_key": context.source_key, "durable": false, "resolved": false}

static func _acknowledgement(current: Dictionary, action: String, intent: Dictionary, context: Dictionary) -> Dictionary:
	var receipt: String
	if action == "portal_arrival":
		if intent.size() != 3 or not intent.get("permit_id") is String or not intent.get("realm") is String or not intent.get("entry_id") is String \
			or context.get("grounded_arrival") != true or context.get("permit_id") != intent.permit_id \
			or context.get("realm") != intent.realm or context.get("entry_id") != intent.entry_id: return deny("actual_grounded_permit_required")
		receipt = "craft:portal_arrival_%s:%s" % [intent.permit_id, current.character_id]
	else:
		var ending := preload("res://scripts/story/regional_homecoming.gd")
		if context.get("earned_ending_ack") != true or ending.acknowledgement_intent(intent, str(intent.get("stage", ""))) != intent \
			or intent.get("character_id") != current.character_id: return deny("earned_ending_context_required")
		receipt = "craft:regional_ending_%s:%s" % [intent.stage, current.character_id]
	var next := current.duplicate(true)
	if next.redesign_character.transaction_receipts.has(receipt): return deny("reconcile_original_decision")
	next.redesign_character.transaction_receipts.append(receipt)
	if action == "portal_arrival" and intent.realm == "meadows" and intent.entry_id == "hall_home":
		var home := "craft:home_return_%s:%s" % [intent.permit_id, current.character_id]
		if not next.redesign_character.transaction_receipts.has(home): next.redesign_character.transaction_receipts.append(home)
	return {"ok": true, "state": next, "receipt": receipt}

static func _relic(current: Dictionary, action: String, intent: Dictionary, context: Dictionary) -> Dictionary:
	if not intent.get("biome") is String or not preload("res://scripts/data/biome_order.gd").ids(false).has(intent.biome): return deny("invalid_relic")
	var next := current.duplicate(true)
	var receipt := "relic_hang:%s:%s" % [intent.biome, current.character_id]
	if action == "relic_hang":
		if intent.size() != 1 or context.get("pedestal_biome") != intent.biome or context.get("realm") != "meadows": return deny("actual_shrine_pedestal_required")
		if not next.redesign_character.relics_held.has(intent.biome): return deny("personal_relic_required")
		next.redesign_character.relics_held.erase(intent.biome)
		if not next.redesign_character.relics_hung.has(intent.biome): next.redesign_character.relics_hung.append(intent.biome)
	else:
		var grant := preload("res://scripts/net/encounter_rewards.gd").chapter_hand_off(str(intent.get("trainer_id", "")), str(context.get("realm", "")))
		if intent.size() != 3 or grant.is_empty() or grant.relic_biome != intent.biome \
			or context.get("validated_host_outcome") != "win" or context.get("encounter_id") != intent.get("encounter_id") \
			or not context.get("participants") is Array or not context.participants.has(current.character_id): return deny("actual_boss_participant_required")
		receipt = "defeat:boss_%s:%s" % [intent.trainer_id, current.character_id]
		if next.redesign_character.relics_held.has(intent.biome) or next.redesign_character.relics_hung.has(intent.biome): return deny("reconcile_original_decision")
		var bag_rules := preload("res://scripts/world/death_satchel_rules.gd")
		var bag := bag_rules.inventory_from(current.inventory)
		if not bag_rules.give_stack(bag, {"id": grant.portal_key_item, "n": 1}): return deny("boss_handoff_make_satchel_room")
		next.inventory = bag_rules.slots(bag)
		next.redesign_character.relics_held.append(intent.biome)
	if next.redesign_character.transaction_receipts.has(receipt): return deny("reconcile_original_decision")
	next.redesign_character.transaction_receipts.append(receipt)
	return {"ok": true, "state": next, "receipt": receipt}

static func camp_plan(current: Dictionary, revision: int, intent: Dictionary, context: Dictionary) -> Dictionary:
	if context.get("foundation_runtime_authorized") != true or not context.get("world_before") is Array \
		or not context.get("next_building_uid") is int: return deny("camp_world_baseline_missing")
	var cfg := preload("res://scripts/build/forward_camp_rules.gd").config()
	cfg.runtime_enabled = true
	return preload("res://scripts/build/forward_camp_actions.gd")._stage_build(cfg, current, revision,
		context.world_before, context.next_building_uid, intent, context)

static func _loadout(current: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	var uids: Array = []
	var selected: Dictionary = {}
	for card: Dictionary in current.party:
		uids.append(card.uid)
		if card.uid == intent.get("creature_uid"): selected = card
	if selected.is_empty(): return deny("not_owned")
	# Detached instance copies only the public fields read by Teaching.
	var creature: RefCounted = preload("res://scripts/creatures/creature_instance.gd").new()
	for field: String in ["uid", "loadout_revision", "loadout_last_edit", "known_moves", "move_ultimate"]:
		if field == "known_moves":
			var known: Array[String] = []
			for id: String in selected.get(field, []): known.append(id)
			creature.set(field, known)
		else: creature.set(field, selected.get(field))
	var derived := context.duplicate(true)
	derived.owned_creature_uids = uids
	derived.within_reach = context.in_range
	var plan := TEACHING.stage_loadout_edit(creature, intent, derived,
		preload("res://scripts/creatures/move_db.gd").load_default())
	if plan.get("ok") != true: return plan
	if plan.get("replayed") == true: return deny("reconcile_original_decision")
	var next := current.duplicate(true)
	for card: Dictionary in next.party:
		if card.uid != selected.uid: continue
		for slot: String in ["quick", "charged", "utility"]: card["move_" + slot] = plan.loadout[slot]
		card.loadout_revision = plan.revision
		card.loadout_last_edit = plan.receipt.duplicate(true)
	next.redesign_character = TEACHING.character_loadout_mirror(next.party, next.redesign_character)
	var receipt := "craft:%s:loadout_%s" % [current.character_id, intent.edit_id]
	if next.redesign_character.transaction_receipts.has(receipt): return deny("reconcile_original_decision")
	next.redesign_character.transaction_receipts.append(receipt)
	return {"ok": true, "state": next, "receipt": receipt}
