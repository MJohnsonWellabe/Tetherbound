extends RefCounted

## F28 host-side content proposals. No live cap/item/save mutation. The station
## and duel owners must validate actual host context, then compose every effect
## with the existing character transaction before promotion. No client snapshot,
## cost, cap, recipe knowledge or claimed Master win is an authority input.
const DATA := preload("res://scripts/data/redesign_data.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const CONFIG_PATH := "res://data/recipes/feasts.json"


static func _integer(raw: Variant, minimum: int, maximum: int) -> bool:
	return (raw is int or raw is float) and is_finite(float(raw)) \
		and float(raw) == floorf(float(raw)) and float(raw) >= minimum and float(raw) <= maximum


## Authoring validation accepts explicitly unregistered output proposals;
## every usable plan additionally requires the actual output in ItemDB.
static func configuration_errors(cfg: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if cfg.get("schema_version") != 1 or not cfg.get("enabled") is bool:
		errors.append("invalid feast configuration version or activation flag")
	var recipes: Variant = cfg.get("recipes")
	var canonical: Variant = DATA.json("res://data/schema/feasts.json")
	if not recipes is Dictionary or not canonical is Array or recipes.size() != canonical.size():
		return ["five canonical feast families are required"]
	var outputs: Dictionary = {}
	for definition: Dictionary in canonical:
		var row: Variant = recipes.get(definition.id)
		if not row is Dictionary:
			errors.append("missing canonical feast " + str(definition.id))
			continue
		if row.get("station") != "kitchen" or row.get("required_recipe_id") != definition.id \
				or row.get("biome") != definition.biome or row.get("breaks_level") != definition.breaks_level \
				or row.get("next_cap") != int(definition.breaks_level) + 10 \
				or row.get("required_attachment_tier") != maxi(1, int(definition.tier) - 1):
			errors.append("feast tier/biome/Kitchen contract mismatch " + str(definition.id))
		if not _cost_valid(row.get("base_cost")): errors.append("invalid base materials " + str(definition.id))
		var variants: Variant = row.get("variants")
		if not variants is Dictionary or variants.size() != definition.attuned_types.size():
			errors.append("eight attuned variants are required " + str(definition.id))
			continue
		for type_id: String in definition.attuned_types:
			var variant: Variant = variants.get(type_id)
			if not variant is Dictionary or variant.get("attuned_input") != {"id": "attuned_" + type_id, "n": 1} \
					or not RULES.db().has("attuned_" + type_id) or not _output_valid(variant.get("output"), outputs):
				errors.append("invalid typed feast output " + str(definition.id) + "/" + type_id)
		var special: Variant = row.get("optional_evolution_variants", {})
		if not special is Dictionary:
			errors.append("invalid evolution ingredient variants")
			continue
		if not special.is_empty() and definition.id != "feast_t2":
			errors.append("stone variants belong only to the L20 feast")
		for stone: Variant in special:
			var variant: Variant = special[stone]
			if not variant is Dictionary or not stone in ["heartstone", "sunstone"] \
					or variant.get("eligible_species_id") != "mudsnout" or variant.get("attuned_type") != "ground" \
					or variant.get("additional_cost") != [{"id": stone, "n": 1}] \
					or variant.get("evolution_candidate") != ("tuskroot" if stone == "heartstone" else "ashtusk") \
					or not _cost_valid(variant.get("additional_cost")) or not _output_valid(variant.get("output"), outputs):
				errors.append("invalid Mudsnout stone variant")
	return errors


static func _cost_valid(raw: Variant) -> bool:
	if not raw is Array or raw.is_empty(): return false
	var seen: Dictionary = {}
	for stack: Variant in raw:
		if not stack is Dictionary or not stack.get("id") is String or seen.has(stack.id) \
				or not RULES.db().has(stack.id) or not _integer(stack.get("n"), 1, 2147483647): return false
		seen[stack.id] = true
	return true


static func _output_valid(raw: Variant, seen: Dictionary) -> bool:
	if not raw is Dictionary or not raw.get("id") is String or str(raw.id).is_empty() \
			or raw.get("n") != 1 or seen.has(raw.id): return false
	seen[raw.id] = true
	return true


static func _admitted_valid(admitted: Dictionary, character_id: String) -> bool:
	if character_id.is_empty() or admitted.get("character_id") != character_id \
			or not admitted.get("party") is Array or admitted.party.size() > PARTY.MAX_CREATURES \
			or not RULES.valid_slots(admitted.get("inventory")) or admitted.inventory.size() != INVENTORY.SLOT_COUNT:
		return false
	var uids := STATE.uids(admitted.party)
	var seen: Dictionary = {}
	for uid: String in uids:
		if uid.is_empty() or seen.has(uid): return false
		seen[uid] = true
	for stack: Variant in admitted.inventory:
		if stack is Dictionary and not RULES.db().has(str(stack.id)): return false
	return STATE.validate("character", admitted.get("redesign_character"), uids).is_empty()


static func _owned(admitted: Dictionary, uid: String) -> Dictionary:
	for row: Variant in admitted.party:
		if row is Dictionary and row.get("uid") == uid: return row
	return {}


static func _feast(item: String, cfg: Dictionary) -> Dictionary:
	for id: String in cfg.recipes:
		var row: Dictionary = cfg.recipes[id]
		for type_id: String in row.variants:
			if row.variants[type_id].output.id == item:
				return {"recipe_id": id, "row": row, "attuned_type": type_id, "evolution_variant": ""}
		for stone: String in row.get("optional_evolution_variants", {}):
			if row.optional_evolution_variants[stone].output.id == item:
				return {"recipe_id": id, "row": row, "attuned_type": "ground", "evolution_variant": stone}
	return {}


## host_kitchen_tier is from an actual registered station, never the packet.
## This validates amounts/capacity only; it supplies NO commit-ready state.
static func cook_plan(admitted: Dictionary, character_id: String, recipe_id: String,
		attuned_type: String, evolution_variant: String, character_revision: int,
		host_kitchen_tier: int, cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _admitted_valid(admitted, character_id) \
			or not configuration_errors(cfg).is_empty(): return _refuse("invalid_cook")
	if not bool(cfg.enabled): return _refuse("feature_unavailable")
	var row: Variant = cfg.recipes.get(recipe_id)
	if not row is Dictionary or not row.variants.has(attuned_type): return _refuse("unknown_recipe_variant")
	if not admitted.redesign_character.feast_recipes.has(recipe_id): return _refuse("master_recipe_needed")
	if host_kitchen_tier < int(row.required_attachment_tier): return _refuse("kitchen_attachment_needed")
	var variant: Dictionary = row.variants[attuned_type]
	var cost: Array = row.base_cost.duplicate(true)
	cost.append(variant.attuned_input.duplicate(true))
	var output: Dictionary = variant.output.duplicate(true)
	if not evolution_variant.is_empty():
		var special: Variant = row.get("optional_evolution_variants", {}).get(evolution_variant)
		if not special is Dictionary or special.attuned_type != attuned_type: return _refuse("wrong_evolution_variant")
		cost.append_array(special.additional_cost.duplicate(true))
		output = special.output.duplicate(true)
	if not RULES.db().has(str(output.id)): return _refuse("output_not_registered")
	var inventory := RULES.inventory_from(admitted.inventory)
	for stack: Dictionary in cost:
		if not inventory.remove(str(stack.id), int(stack.n)): return _refuse("ingredients_needed")
	if inventory.add(str(output.id), 1) != 0: return _refuse("inventory_full")
	return {"ok": true, "ready_to_commit": false, "recipe_id": recipe_id, "cost": cost, "output": output,
		"attuned_type": attuned_type, "expected_character_revision": character_revision,
		"requires": ["actual_home_Kitchen_reach", "guest_personal_recipe", "host_attachment_tier",
			"same_record_craft_receipt_debit_output_CAS", "owner_save_ACK"]}


## Quoted feed intent only. Missing canonical creature mirrors refuse, rather
## than manufacturing cap/breakthrough/evolution/traits/learnset history.
static func feed_plan(admitted: Dictionary, character_id: String, uid: String,
		item: String, character_revision: int, cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _admitted_valid(admitted, character_id) \
			or not configuration_errors(cfg).is_empty(): return _refuse("invalid_feed")
	if not bool(cfg.enabled): return _refuse("feature_unavailable")
	var feast := _feast(item, cfg)
	if feast.is_empty() or not RULES.db().has(item): return _refuse("unknown_feast")
	var creature := _owned(admitted, uid)
	if creature.is_empty(): return _refuse("not_owned")
	var mirror: Variant = admitted.redesign_character.creatures.get(uid)
	if not mirror is Dictionary: return _refuse("cap_not_admitted")
	var cap := ESSENCE.creature_cap(admitted.redesign_character, uid)
	var row: Dictionary = feast.row
	if cap != int(row.breaks_level) or not _integer(creature.get("level"), cap, cap): return _refuse("not_at_matching_cap")
	if not admitted.redesign_character.feast_recipes.has(str(feast.recipe_id)): return _refuse("master_recipe_needed")
	if feast.attuned_type != creature.get("creature_type") and feast.attuned_type != creature.get("secondary_type", ""):
		return _refuse("wrong_attuned_type")
	if not str(feast.evolution_variant).is_empty() and creature.get("species_id") != "mudsnout": return _refuse("wrong_evolution_species")
	var inventory := RULES.inventory_from(admitted.inventory)
	if inventory.count(item) < 1: return _refuse("feast_needed")
	return {"ok": true, "ready_to_commit": false, "creature_uid": uid, "payment": {"id": item, "n": 1},
		"old_cap": cap, "next_cap": int(row.next_cap), "attuned_type": feast.attuned_type,
		"evolution_variant": feast.evolution_variant, "expected_character_revision": character_revision,
		"requires": ["actual_registered_Altar_context", "once_per_uid_tier_feast_feed_receipt",
			"same_record_item_cap_breakthrough_CAS", "ultimate_trait_learnset_updates",
			"applicable_evolution_or_stay_and_Ripplet_Dive", "owner_save_ACK"]}


static func _refuse(code: String) -> Dictionary:
	return {"ok": false, "code": code}
