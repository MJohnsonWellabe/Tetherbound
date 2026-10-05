extends RefCounted

## Detached arithmetic for one actual terminal shared trainer/boss round.
## The Session producer authenticates the source; no packet party is imported.
## The existing Foundation carrier owns the journal, CAS and owner-save ACK.
const E := preload("res://scripts/creatures/essence.gd")
const P := preload("res://scripts/creatures/progression.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const INTENT_FIELDS := ["trainer_id", "encounter_id", "round", "enemy_uid", "phase"]
const SCOPE_FIELDS := ["world_namespace", "session_id", "realm", "trainer_id", "encounter_id"]
const PARTICIPANT_FIELDS := ["peer_id", "character_id"]
const BINDING_FIELDS := ["peer_id", "character_id", "active_uid", "actor_generation"]
const VITAL_FIELDS := ["uid", "hp", "max_hp", "fainted", "actor_generation"]
const ENEMY_FIELDS := ["uid", "species_id", "creature_type", "secondary_type", "level", "hp", "fainted"]

static func scope(namespace_id: String, epoch: String, realm: String,
		trainer_id: String, encounter_id: String) -> Dictionary:
	var result := {"world_namespace": namespace_id, "session_id": epoch,
		"realm": realm, "trainer_id": trainer_id, "encounter_id": encounter_id}
	return result if scope_valid(result) else {}

static func scope_valid(value: Variant) -> bool:
	if not value is Dictionary or not _fields(value, SCOPE_FIELDS): return false
	for field: String in SCOPE_FIELDS:
		if not E._opaque_id(value[field]): return false
	return preload("res://scripts/data/biome_order.gd").ids(false).has(value.realm)

## Caller freezes these values from its actual arbiter BEFORE terminal publish.
## Bench generation zero means an unchanged canonical never-deployed member.
static func make_duty(namespace_id: String, epoch: String, realm: String,
		trainer_id: String, encounter_id: String, round_number: int,
		enemy_record: Dictionary, participant: Dictionary, participants: Array, phase: String = "round") -> Dictionary:
	var ownership := scope(namespace_id, epoch, realm, trainer_id, encounter_id)
	if ownership.is_empty(): return {}
	var enemy := {}
	for field: String in ENEMY_FIELDS:
		if not enemy_record.has(field): return {}
		enemy[field] = enemy_record[field]
	var binding := {}
	for field: String in BINDING_FIELDS:
		if not participant.has(field): return {}
		binding[field] = participant[field]
	var intent := {"trainer_id": trainer_id, "encounter_id": encounter_id,
		"round": round_number, "enemy_uid": enemy.get("uid"), "phase": phase}
	var vitals: Variant = participant.get("settled_vitals")
	if not vitals is Array: return {}
	var context := {"reward_scope": ownership, "enemy_record": enemy,
		"binding": binding, "participants": participants.duplicate(true),
		"settled_vitals": vitals.duplicate(true),
		"validated_host_outcome": "win", "event_confirmed": true,
		"world_namespace": namespace_id, "session_id": epoch, "realm": realm}
	if phase == "completion": context.actual_host_trainer_won = true
	context.source_key = source_id(intent, context)
	var duty := {"character_id": binding.get("character_id"), "action": "combat_round_reward",
		"intent": intent, "context": context}
	return duty if source_valid(intent, context, str(duty.character_id)) else {}

static func source_id(intent: Dictionary, context: Dictionary) -> String:
	return "combat_round:" + _digest({"scope": context.get("reward_scope"), "intent": intent,
		"enemy": context.get("enemy_record"), "participants": context.get("participants")})

static func receipt(character: String, intent: Dictionary, context: Dictionary) -> String:
	return "defeat:trainer_round_%s:%s" % [_digest({"source": source_id(intent, context),
		"binding": context.get("binding"), "vitals": context.get("settled_vitals")}), character]

static func _digest(value: Dictionary) -> String:
	# Lazy loading avoids the event/preparation codec's compile-time cycle.
	var codec: Script = load("res://scripts/net/research_passive_preparation.gd")
	return str(codec.call("fingerprint", value))

static func source_valid(intent: Dictionary, context: Dictionary, character: String) -> bool:
	if not _fields(intent, INTENT_FIELDS) or not scope_valid(context.get("reward_scope")) \
		or intent.get("phase") not in ["round", "completion"] \
		or not E._integer(intent.get("round"), 1, 100) or not E._opaque_id(intent.get("enemy_uid")) \
		or context.get("validated_host_outcome") != "win" or not context.get("event_confirmed") is bool or context.event_confirmed != true \
		or context.get("source_key") != source_id(intent, context): return false
	var ownership: Dictionary = context.reward_scope
	for field: String in ["trainer_id", "encounter_id"]:
		if intent.get(field) != ownership[field]: return false
	for field: String in ["world_namespace", "session_id", "realm"]:
		if context.get(field) != ownership[field]: return false
	var enemy: Variant = context.get("enemy_record")
	if not enemy is Dictionary or not _fields(enemy, ENEMY_FIELDS) or enemy.get("uid") != intent.enemy_uid \
		or not E._component(enemy.get("species_id")) or not E._integer(enemy.get("level"), 1, 100) \
		or not _number(enemy.get("hp")) or float(enemy.hp) != 0.0 or not enemy.get("fainted") is bool or enemy.fainted != true \
		or E._species_types(enemy).is_empty(): return false
	if intent.phase == "completion" and (not context.get("actual_host_trainer_won") is bool or context.actual_host_trainer_won != true \
		or not _completion_valid(intent, enemy)): return false
	var binding: Variant = context.get("binding")
	if not binding is Dictionary or not _fields(binding, BINDING_FIELDS) \
		or binding.get("character_id") != character or not E._opaque_id(character) \
		or not E._integer(binding.get("peer_id"), 1, 2147483647) \
		or not E._integer(binding.get("actor_generation"), 1, 2147483647) \
		or not E._component(binding.get("active_uid")): return false
	var participants: Variant = context.get("participants")
	if not participants is Array or participants.is_empty() or participants.size() > 4: return false
	var peers := {}
	var characters := {}
	var matched := false
	for raw: Variant in participants:
		if not raw is Dictionary or not _fields(raw, PARTICIPANT_FIELDS) \
			or not E._integer(raw.get("peer_id"), 1, 2147483647) or not E._opaque_id(raw.get("character_id")) \
			or peers.has(int(raw.peer_id)) or characters.has(raw.character_id): return false
		peers[int(raw.peer_id)] = true
		characters[raw.character_id] = true
		if raw.peer_id == binding.peer_id and raw.character_id == character: matched = true
	if not matched: return false
	var vitals: Variant = context.get("settled_vitals")
	if not vitals is Array or vitals.is_empty() or vitals.size() > 5: return false
	var seen := {}
	var active := false
	for raw: Variant in vitals:
		if not raw is Dictionary or not _fields(raw, VITAL_FIELDS) or not E._component(raw.get("uid")) \
			or seen.has(raw.uid) or not _number(raw.get("hp")) or not _number(raw.get("max_hp")) \
			or float(raw.max_hp) <= 0.0 or float(raw.hp) < 0.0 or float(raw.hp) > float(raw.max_hp) \
			or not raw.get("fainted") is bool or raw.fainted != (float(raw.hp) == 0.0) \
			or not E._integer(raw.get("actor_generation"), 0, 2147483647): return false
		seen[raw.uid] = true
		if raw.uid == binding.active_uid:
			if raw.actor_generation != binding.actor_generation: return false
			active = true
	return active

static func _trainer_spec(id: String) -> Dictionary:
	var trainers: Script = load("res://scripts/world/trainer_npc.gd")
	var spec: Dictionary = trainers.call("trainer", id)
	return spec

static func _completion_valid(intent: Dictionary, enemy: Dictionary) -> bool:
	var spec := _trainer_spec(str(intent.trainer_id))
	var team: Variant = spec.get("team")
	if not team is Array or team.is_empty() or intent.round != team.size(): return false
	var final_member: Variant = team.back()
	return final_member is Dictionary and final_member.get("species") == enemy.species_id \
		and E._equivalent(final_member.get("level"), enemy.level)

static func _completion_amount(id: String) -> int:
	var spec := _trainer_spec(id)
	var amount: Variant = spec.get("reward", {}).get("xp_bonus", 0)
	return int(amount) if E._integer(amount, 0, 2147483647) else -1

## This is an explicit host-proven HP transition, never an ignored core field.
## Its original alive-to-fainted condition effect composes here as well.
## Every unrelated complete-card field stays in the original before.
static func settled_before(current: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	if not source_valid(intent, context, str(current.get("character_id", ""))) \
		or not current.get("party") is Array or current.party.size() != context.settled_vitals.size(): return {}
	var next := current.duplicate(true)
	for index: int in next.party.size():
		var card: Dictionary = next.party[index]
		var found := false
		for vital: Dictionary in context.settled_vitals:
			if vital.uid != card.get("uid"): continue
			if not E._equivalent(vital.max_hp, card.get("max_hp")): return {}
			if int(vital.actor_generation) == 0 and (not E._equivalent(vital.hp, card.get("hp")) \
				or vital.fainted != card.get("fainted")): return {}
			var settled := preload("res://scripts/net/actor_vitals_delivery.gd").settled_card(card, float(vital.hp), vital.fainted)
			if settled.is_empty(): return {}
			next.party[index] = settled
			found = true
			break
		if not found: return {}
	return next

static func stage(current: Dictionary, intent: Dictionary, context: Dictionary) -> Dictionary:
	var settled := settled_before(current, intent, context)
	if settled.is_empty(): return _deny("actual_terminal_round_required")
	var decision := receipt(str(current.character_id), intent, context)
	if current.redesign_character.transaction_receipts.has(decision): return _deny("reconcile_original_decision")
	if current.redesign_character.transaction_receipts.size() >= int(E.config().maximum_transaction_receipts): return _deny("receipt_budget")
	var eligible: Array[String] = []
	var caps := {}
	for card: Dictionary in settled.party:
		if card.fainted: continue
		eligible.append(card.uid)
		caps[card.uid] = E.creature_cap(settled.redesign_character, card.uid)
	var next := settled.duplicate(true)
	var awards := {}
	if intent.phase == "completion":
		var amount := _completion_amount(str(intent.trainer_id))
		if amount < 0: return _deny("invalid_authored_completion_XP")
		if amount > 0:
			for index: int in next.party.size():
				var card: Dictionary = settled.party[index]
				if card.fainted: continue
				var changed := P.staged_xp(card, int(caps[card.uid]), amount, P.config(),
					E._canonical_trait_maximum.bind(settled.redesign_character.creatures))
				if changed.is_empty(): return _deny("invalid_completion_XP_or_cap")
				var gained := int(changed.level) - int(card.level)
				changed = P.staged_training_condition(changed, gained, false)
				if changed.is_empty(): return _deny("invalid_completion_condition")
				next.party[index] = changed
				awards[card.uid] = amount
	elif not eligible.is_empty():
		var xp := P.staged_combat_party_xp(settled.party, context.binding.active_uid, eligible,
			caps, int(context.enemy_record.level), P.config(), E.config(), "hybrid",
			E._canonical_trait_maximum.bind(settled.redesign_character.creatures))
		if xp.is_empty(): return _deny("invalid_round_XP_or_cap")
		next.party = xp.party.duplicate(true)
		awards = xp.awards.duplicate(true)
	next.redesign_character.transaction_receipts.append(decision)
	next = E.refresh_training_moves(next, TEACHING.available_moves, TEACHING.character_loadout_mirror)
	if next.is_empty(): return _deny("canonical_power_refresh_unavailable")
	return {"ok": true, "state": next, "receipt": decision, "settled_before": settled, "awards": awards}

static func owner_plan(current: Dictionary, row: Dictionary) -> Dictionary:
	if E.owner_matches_after(current, row.after):
		return {"ok": true, "duplicate": true, "requires_owner_save": true, "state": current.duplicate(true), "receipt": row.receipt}
	var settled := settled_before(row.before, row.intent, row.host_context)
	if settled.is_empty() or not E.owner_matches_after(current, settled): return _deny("owner_action_baseline_conflict")
	if row.status != "pending": return _deny("accepted_history_is_not_a_new_award")
	return {"ok": true, "duplicate": false, "requires_owner_save": true,
		"before": current.duplicate(true), "state": row.after.duplicate(true), "receipt": row.receipt}

static func _fields(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size(): return false
	for field: String in fields:
		if not value.has(field): return false
	return true

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "code": code, "durable": false, "resolved": false}
