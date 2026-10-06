extends RefCounted
## Good/Great/Rare Candy use the same admitted-character transaction as other
## training. This detached stage never spends or levels a live owner object.
const E := preload("res://scripts/creatures/essence.gd")
const P := preload("res://scripts/creatures/progression.gd")
const B := preload("res://scripts/creatures/breakthrough.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")

static func stage(current: Dictionary, revision: int, intent: Dictionary, context: Dictionary) -> Dictionary:
	if intent.size() != 3 or not E._component(intent.get("creature_uid")) \
			or not E._component(intent.get("candy_item")) or not E._opaque_id(intent.get("action_id")) \
			or context.get("character_id") != current.get("character_id") \
			or context.get("expected_revision") != revision or context.get("owns_character") != true \
			or context.get("in_combat") != false or context.get("source_key") != "personal_candy_feed":
		return E._refuse("invalid_candy_intent")
	if intent.candy_item not in ["good_candy", "great_candy", "rare_candy"]:
		return E._refuse("not_a_level_candy")
	var index := E._owned_index(current, intent.creature_uid)
	if index < 0: return E._refuse("not_owned")
	var card: Dictionary = current.party[index]
	var cap := E.creature_cap(current.redesign_character, intent.creature_uid)
	if cap < 0 or not E._integer(card.get("level"), 1, cap): return E._refuse("cap_not_admitted")
	if card.get("fainted") != false or float(card.get("hp", 0.0)) <= 0.0: return E._refuse("fainted")
	if int(card.level) == cap: return E._refuse("breakthrough_needed")
	var receipt := "candy_feed:%s:%s" % [str(current.character_id), str(intent.action_id)]
	if current.redesign_character.transaction_receipts.has(receipt):
		return E._refuse("reconcile_original_decision")
	if current.redesign_character.transaction_receipts.size() >= int(E.config().maximum_transaction_receipts):
		return E._refuse("receipt_budget")
	var count: Variant = BAG.db().definition(intent.candy_item).get("level_up")
	if not E._integer(count, 1, 3): return E._refuse("invalid_candy_definition")
	var inventory := BAG.inventory_from(current.inventory)
	if not inventory.remove(intent.candy_item, 1): return E._refuse("insufficient_items")
	var next := current.duplicate(true)
	var gained := mini(int(count), cap - int(card.level))
	var changed := card.duplicate(true)
	for _step: int in gained:
		changed = P.staged_next_level(changed, cap, P.config(), E._canonical_trait_maximum.bind(current.redesign_character.creatures))
		if changed.is_empty(): return E._refuse("invalid_creature")
	changed = P.staged_training_condition(changed, gained, false)
	if changed.is_empty(): return E._refuse("invalid_creature_condition")
	next.party[index] = changed
	next.inventory = BAG.slots(inventory)
	next.redesign_character = B.refresh_feast_moves(next.party, next.redesign_character)
	if next.redesign_character.is_empty(): return E._refuse("training_moves_unavailable")
	next.redesign_character.transaction_receipts.append(receipt)
	return {"ok": true, "state": next, "before": current.duplicate(true), "receipt": receipt,
		"original_intent": intent.duplicate(true), "original_revision": revision,
		"old_level": int(card.level), "new_level": int(changed.level), "levels_gained": gained,
		"durable": false, "resolved": false}
