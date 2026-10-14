extends RefCounted
## Read-only checks over the owner's portable save projection. These checks
## never manufacture a recipe, inventory delta, choice or receipt.
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")

static func inventory_totals(state: Dictionary) -> Dictionary:
	var result := {}
	for stack: Variant in state.get("inventory", []):
		if stack is Dictionary and int(stack.get("n", 0)) > 0:
			var id := str(stack.get("id", ""))
			result[id] = int(result.get(id, 0)) + int(stack.n)
	return result

static func inventory_matches(before: Dictionary, after: Dictionary, cost: Dictionary, output: Dictionary) -> bool:
	var expected := inventory_totals(before)
	for id: String in cost:
		var remaining := int(expected.get(id, 0)) - int(cost[id])
		if int(cost[id]) < 0 or remaining < 0: return false
		if remaining == 0: expected.erase(id)
		else: expected[id] = remaining
	for id: String in output:
		if int(output[id]) <= 0: return false
		expected[id] = int(expected.get(id, 0)) + int(output[id])
	return expected == inventory_totals(after)

static func party_errors(before: Dictionary, after: Dictionary, uid: String = "", species: String = "") -> Array[String]:
	var errors: Array[String] = []
	if str(before.get("character_id", "")).is_empty() or before.get("character_id") != after.get("character_id"):
		errors.append("Feast changed or omitted the character identity")
	var old: Array = before.get("party", [])
	var next: Array = after.get("party", [])
	if old.is_empty() or old.size() != next.size():
		return ["Feast changed the party size or lost its snapshot"]
	for index in old.size():
		var a: Dictionary = old[index]
		var b: Dictionary = next[index]
		for key: String in ["uid", "level", "xp"]:
			if not a.has(key) or a.get(key) != b.get(key): errors.append("Feast changed or omitted " + key)
		var expected := species if str(a.uid) == uid else str(a.get("species_id", ""))
		if str(b.get("species_id", "")) != expected: errors.append("Feast changed an unexpected species")
	return errors

static func mirror_errors(before: Dictionary, after: Dictionary, selected: String = "") -> Array[String]:
	var errors: Array[String] = []
	var old: Dictionary = before.get("redesign_character", {}).get("creatures", {})
	var next: Dictionary = after.get("redesign_character", {}).get("creatures", {})
	# Feed refreshes every party member's authored move union and serializes its
	# loadout/mastery from the pre-action card. Compute that exact projection;
	# no field is ignored. Cooking has no refresh and must preserve every byte
	# of each dictionary's values, including future progression fields.
	if not selected.is_empty():
		var bystanders: Array = []
		for card: Dictionary in before.get("party", []):
			if str(card.get("uid", "")) != selected: bystanders.append(card.duplicate(true))
		var refreshed := BREAKTHROUGH.refresh_feast_moves(bystanders, before.get("redesign_character", {}).duplicate(true))
		if refreshed.is_empty(): return ["Cannot derive the authored bystander mirror refresh"]
		old = refreshed.get("creatures", {})
	if old.size() != next.size(): errors.append("Action changed the creature mirror count")
	for uid: String in old:
		if not next.has(uid):
			errors.append("Action lost a creature mirror")
			continue
		if uid == selected: continue
		if old[uid] != next[uid]: errors.append("Action changed another creature mirror outside the authored refresh: " + uid)
	return errors

static func cook_errors(before: Dictionary, after: Dictionary, recipe: Dictionary) -> Array[String]:
	var errors := party_errors(before, after)
	errors.append_array(mirror_errors(before, after))
	if not inventory_matches(before, after, recipe.get("cost", {}), recipe.get("output", {})):
		errors.append("Cook did not pay the exact ingredient bill and produce the exact feast")
	var prior: Array = before.get("redesign_character", {}).get("transaction_receipts", [])
	var current: Array = after.get("redesign_character", {}).get("transaction_receipts", [])
	var added: Array = current.filter(func(id: Variant) -> bool: return not prior.has(id))
	var prefix := "craft:%s:" % str(before.get("character_id", ""))
	var suffix := str(added[0]).trim_prefix(prefix) if added.size() == 1 else ""
	var valid_suffix := suffix.length() == 32 and suffix.is_valid_hex_number(false)
	if added.size() != 1 or not str(added[0]).begins_with(prefix) or not valid_suffix or current.size() != prior.size() + 1:
		errors.append("Cook lacks one new character-bound craft receipt")
	for id: Variant in prior:
		if not current.has(id): errors.append("Cook lost an existing transaction receipt")
	return errors

static func feed_errors(before: Dictionary, after: Dictionary, row: Dictionary) -> Array[String]:
	var uid := str(row.uid)
	var definition: Dictionary = BREAKTHROUGH.feasts().items.get(str(row.item), {})
	var tier := int(definition.get("tier", -1))
	var old_card := {}
	for card: Dictionary in before.get("party", []):
		if str(card.get("uid", "")) == uid: old_card = card
	var species := str(row.target) if str(row.choice) == "evolve" else str(old_card.get("species_id", ""))
	var errors := party_errors(before, after, uid, species)
	errors.append_array(mirror_errors(before, after, uid))
	if int(old_card.get("level", -1)) != int(definition.get("breaks_level", -2)):
		errors.append("Feed did not begin at the authored locked level")
	if old_card.is_empty() or tier < 1: errors.append("Feed lacks an owned creature or authored feast tier")
	if not inventory_matches(before, after, {str(row.item): 1}, {}):
		errors.append("Feed did not consume exactly one feast without another debit")
	var old: Dictionary = before.get("redesign_character", {}).get("creatures", {}).get(uid, {})
	var next: Dictionary = after.get("redesign_character", {}).get("creatures", {}).get(uid, {})
	if int(old.get("cap_level", -1)) != int(definition.get("breaks_level", -2)):
		errors.append("Feed did not begin at the authored locked cap")
	var tiers: Array = old.get("breakthroughs", []).duplicate()
	if tiers.has(tier): errors.append("Feed was already completed before this action")
	tiers.append(tier)
	if next.get("breakthroughs", []) != tiers or int(next.get("cap_level", -1)) != BREAKTHROUGH.level_cap(tiers):
		errors.append("Feed did not append the exact tier and open the authored next cap")
	var choices: Dictionary = old.get("evolution_choices", {}).duplicate(true)
	if bool(row.choice_required):
		choices[str(tier)] = EVOLUTION._authored_source(species) if str(row.choice) == "evolve" else "stay"
	if next.get("evolution_choices", {}) != choices:
		errors.append("Feed lacks the exact permanent Evolve/Stay record")
	var receipt := "feast_feed:%s:%d" % [uid, tier]
	var prior: Array = before.get("redesign_character", {}).get("transaction_receipts", [])
	var current: Array = after.get("redesign_character", {}).get("transaction_receipts", [])
	var expected_receipts := prior.duplicate()
	expected_receipts.append(receipt)
	if prior.has(receipt) or current != expected_receipts:
		errors.append("Feed lacks exactly one new creature/tier receipt")
	return errors
