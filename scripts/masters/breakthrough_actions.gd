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

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "code": code}
