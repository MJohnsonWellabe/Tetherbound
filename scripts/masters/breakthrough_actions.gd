extends RefCounted
## Typed producer called INSIDE the existing Foundation registry stage. This
## accepts only intent fields; context is derived by the authenticated host
## from registered live sources and retained admitted state, never from RPC.
const RULES := preload("res://scripts/creatures/breakthrough.gd")
const FIELDS := {
	"master_win": ["master_id", "encounter_id", "creature_uid"],
	"master_chest": ["master_id"],
	"feast_cook": ["recipe_id", "craft_id"],
	"feast_feed": ["creature_uid", "feast_item", "choice"],
	"attuned_gather": ["source_id"],
}

static func stage(current: Dictionary, revision: int, op: String, intent: Dictionary,
		context: Dictionary, species_types: Callable, evolve: Callable, refresh_moves: Callable) -> Dictionary:
	if not FIELDS.has(op) or intent.size() != FIELDS[op].size(): return _deny("invalid_intent")
	for key: String in FIELDS[op]:
		if not intent.get(key) is String: return _deny("invalid_intent")
	if current.get("character_id", "") == "" or current.get("character_id") != context.get("character_id") \
			or context.get("expected_revision") != revision or context.get("in_range") != true:
		return _deny("character_revision_or_source_mismatch")
	var result: Dictionary
	match op:
		"master_win":
			if context.get("validated_host_outcome") != "win" or context.get("participant_count") != 1 \
					or context.get("encounter_id") != intent.encounter_id or context.get("creature_uid") != intent.creature_uid \
					or context.get("master_id") != intent.master_id:
				return _deny("canonical_duel_win_required")
			if context.get("settled_vitals") is Array:
				result = _hosted_win(current, intent)
			else:
				result = RULES.prepare_win(current, intent.master_id, str(current.character_id))
		"master_chest":
			if context.get("master_id") != intent.master_id: return _deny("wrong_chest")
			result = RULES.prepare_chest(current, intent.master_id, str(current.character_id))
		"feast_cook": result = RULES.prepare_cook(current, intent.recipe_id, intent.craft_id, context)
		"feast_feed": result = RULES.prepare_feed(current, intent.creature_uid, intent.feast_item,
			intent.choice, context, species_types, evolve, refresh_moves)
		"attuned_gather":
			if context.get("source_id") != intent.source_id: return _deny("wrong_herb_source")
			result = RULES.prepare_gather(current, intent.source_id, context)
	if result.get("ok") == true:
		# Foundation writes this exact immutable identity into its EXISTING
		# creature_training row with before/after, epoch/world, registry revision.
		# Any replay checks it before receipt lookup; receipt presence isn't ACK.
		result.original_intent = intent.duplicate(true)
		result.original_revision = revision
		result.character_id = str(current.character_id)
	return result

## F28: a guest's host-arbitrated Master win pays its victory as a co-op
## trainer round does (combat_round_reward): XP to the duelist and a share to
## the living bench, each with its battle credit and victory mood. The record
## already holds the duel's owner-saved vitals; the guest's own combat manager
## pays nothing (host_owns_xp), so this is the only award.
static func hosted_win_receipt(master_id: String, character_id: String, encounter_id: String) -> String:
	return "master_recipe:%s:%s:win:%s" % [master_id, character_id, encounter_id.sha256_text()]


## F28: one hosted duel's win, once per duel: the award, and the Master win
## itself the first time (a later win over the same Master pays only its award).
static func _hosted_win(current: Dictionary, intent: Dictionary) -> Dictionary:
	var character := str(current.character_id)
	if RULES.master(intent.master_id).is_empty(): return _deny("invalid_winner")
	var receipt := hosted_win_receipt(intent.master_id, character, intent.encounter_id)
	var replay := RULES._duplicate(current, receipt)
	if not replay.is_empty(): return replay
	var next := _hosted_duel_award(current, intent.master_id, intent.creature_uid)
	if next.is_empty(): return _deny("hosted_duel_award_unavailable")
	if not next.redesign_character.master_wins.has(intent.master_id): next.redesign_character.master_wins.append(intent.master_id)
	var result := RULES._result(next, receipt, "master_win")
	result.intent = {"master_id": intent.master_id, "character_id": character}
	return result


static func _hosted_duel_award(current: Dictionary, master_id: String, duelist: String) -> Dictionary:
	const E := preload("res://scripts/creatures/essence.gd")
	const P := preload("res://scripts/creatures/progression.gd")
	const TEACHING := preload("res://scripts/creatures/teaching.gd")
	var definition: Dictionary = RULES.master(master_id)
	if definition.is_empty() or not current.get("party") is Array: return {}
	var eligible: Array[String] = []
	var caps := {}
	var found := false
	for card: Variant in current.party:
		if not card is Dictionary: return {}
		if card.get("uid") == duelist: found = true
		if card.get("fainted") != false: continue # A fainted member (the duelist on a trade KO too) earns nothing.
		eligible.append(str(card.uid))
		caps[card.uid] = E.creature_cap(current.redesign_character, str(card.uid))
	if not found: return {}
	if eligible.is_empty(): return current.duplicate(true)
	var xp := P.staged_combat_party_xp(current.party, duelist, eligible, caps, int(definition.get("cap_level", 0)),
		P.config(), E.config(), "hybrid", E._canonical_trait_maximum.bind(current.redesign_character.creatures))
	if xp.is_empty(): return {}
	var next := current.duplicate(true)
	next.party = xp.party.duplicate(true)
	return E.refresh_training_moves(next, TEACHING.available_moves, TEACHING.character_loadout_mirror)


static func _deny(code: String) -> Dictionary:
	return {"ok": false, "code": code}
