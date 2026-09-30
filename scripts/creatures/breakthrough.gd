extends RefCounted

## F28 host-side content proposals and pure craft staging. No live cap/item/save mutation. The station
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
	if cfg.get("schema_version") != 1 or not cfg.get("enabled") is bool \
			or not _integer(cfg.get("maximum_transaction_receipts"), 1, 2147483647):
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
					or not RULES.db().has("attuned_" + type_id) or not _output_valid(variant.get("output"), outputs) \
					or variant.output.id != str(definition.id) + "_" + type_id:
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
					or not _cost_valid(variant.get("additional_cost")) or not _output_valid(variant.get("output"), outputs) \
					or variant.output.id != "feast_t2_ground_" + str(stone):
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


static func _registered_feast(item: String, recipe_id: String, type_id: String,
		evolution_variant: String, row: Dictionary) -> bool:
	if not RULES.db().has(item): return false
	var definition: Dictionary = RULES.db().definition(item)
	return definition.get("kind") == "training" and definition.get("feast_recipe_id") == recipe_id \
		and definition.get("feast_type") == type_id and definition.get("evolution_variant") == evolution_variant \
		and definition.get("breaks_level") == row.breaks_level and definition.get("next_cap") == row.next_cap \
		and not definition.has("level_up")


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
	if not _registered_feast(str(output.id), recipe_id, attuned_type, evolution_variant, row):
		return _refuse("output_not_registered")
	var inventory := RULES.inventory_from(admitted.inventory)
	for stack: Dictionary in cost:
		if not inventory.remove(str(stack.id), int(stack.n)): return _refuse("ingredients_needed")
	if inventory.add(str(output.id), 1) != 0: return _refuse("inventory_full")
	return {"ok": true, "ready_to_commit": false, "recipe_id": recipe_id, "cost": cost, "output": output,
		"attuned_type": attuned_type, "expected_character_revision": character_revision,
		"requires": ["actual_home_Kitchen_reach", "guest_personal_recipe", "host_attachment_tier",
			"same_record_craft_receipt_debit_output_CAS", "owner_save_ACK"]}


static func _receipt_component(value: String) -> bool:
	return not value.is_empty() and value.length() <= 128 and value == value.strip_edges() \
		and not value.contains(":") and not value.contains("\n") and not value.contains("\r")


## The caller supplies its admitted host record and observed Kitchen tier.
## Client requests contain only craft_id, recipe_id, attuned_type, stone variant
## and expected revision. No caller-supplied cost, output or candidate is used.
## This clone must pass actual station/reach/CAS and owner-save settlement before
## promotion. A returned candidate is never an ACK or a durable grant.
static func stage_cook(admitted: Dictionary, character_id: String, craft_id: String,
		recipe_id: String, attuned_type: String, evolution_variant: String,
		character_revision: int, host_kitchen_tier: int, cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _receipt_component(character_id) or not _receipt_component(craft_id) \
			or not _admitted_valid(admitted, character_id) or not configuration_errors(cfg).is_empty():
		return _refuse("invalid_cook")
	if not bool(cfg.enabled): return _refuse("feature_unavailable")
	var row: Variant = cfg.recipes.get(recipe_id)
	if not row is Dictionary or not row.variants.has(attuned_type): return _refuse("unknown_recipe_variant")
	if not evolution_variant.is_empty() and not row.get("optional_evolution_variants", {}).has(evolution_variant):
		return _refuse("wrong_evolution_variant")
	var intent_hash := JSON.stringify([recipe_id, attuned_type, evolution_variant]).sha256_text()
	var prefix := "craft:%s:%s:" % [character_id, craft_id]
	var receipt := prefix + intent_hash
	var duplicate := false
	for previous: String in admitted.redesign_character.transaction_receipts:
		if not previous.begins_with(prefix): continue
		if previous != receipt or duplicate: return _refuse("receipt_conflict")
		duplicate = true
	if duplicate:
		return {"ok": true, "duplicate": true, "ready_to_commit": false, "receipt": receipt,
			"expected_character_revision": character_revision,
			"requires": ["reconcile_existing_character_decision", "owner_save_ACK"]}
	var plan := cook_plan(admitted, character_id, recipe_id, attuned_type, evolution_variant,
		character_revision, host_kitchen_tier, cfg)
	if not bool(plan.get("ok", false)): return plan
	if admitted.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts):
		return _refuse("receipt_budget")
	var inventory := RULES.inventory_from(admitted.inventory)
	for stack: Dictionary in plan.cost:
		if not inventory.remove(str(stack.id), int(stack.n)): return _refuse("ingredients_needed")
	if inventory.add(str(plan.output.id), int(plan.output.n)) != 0: return _refuse("inventory_full")
	var next := admitted.duplicate(true)
	next.inventory = RULES.slots(inventory)
	next.redesign_character.transaction_receipts.append(receipt)
	if not _admitted_valid(next, character_id): return _refuse("invalid_candidate")
	return {"ok": true, "duplicate": false, "ready_to_commit": false,
		"expected_character_revision": character_revision, "receipt": receipt,
		"cost": plan.cost.duplicate(true), "output": plan.output.duplicate(true),
		"state": next, "before": admitted.duplicate(true),
		"requires": plan.requires.duplicate()}


## Quoted feed intent only. Missing canonical creature mirrors refuse, rather
## than manufacturing cap/breakthrough/evolution/traits/learnset history.
static func feed_plan(admitted: Dictionary, character_id: String, uid: String,
		item: String, character_revision: int, cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _admitted_valid(admitted, character_id) \
			or not configuration_errors(cfg).is_empty(): return _refuse("invalid_feed")
	if not bool(cfg.enabled): return _refuse("feature_unavailable")
	var feast := _feast(item, cfg)
	if feast.is_empty(): return _refuse("unknown_feast")
	if not _registered_feast(item, feast.recipe_id, feast.attuned_type, feast.evolution_variant, feast.row):
		return _refuse("unknown_feast")
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


static func master_configuration_errors(cfg: Dictionary) -> Array[String]:
	var catalog := DATA.load_catalog("masters")
	if not bool(catalog.get("ok", false)): return ["canonical Masters unavailable"]
	if cfg.get("schema_version") != 1 or not cfg.get("enabled") is bool \
			or not _integer(cfg.get("maximum_transaction_receipts"), 1, 2147483647):
		return ["invalid Master configuration"]
	var rows: Variant = cfg.get("masters")
	var entry: Variant = cfg.get("entry")
	var reward: Variant = cfg.get("first_win_chest")
	if not rows is Dictionary or rows.size() != catalog.data.size() \
			or not entry is Dictionary or not reward is Dictionary: return ["invalid Master rows/rules"]
	for definition: Dictionary in catalog.data:
		var authored: Variant = rows.get(definition.id)
		if not authored is Dictionary or not authored.get("creature") is Dictionary \
				or not authored.creature.get("species_id") is String or str(authored.creature.species_id).is_empty():
			return ["missing canonical Master/opponent"]
	if entry.get("selected_creatures") != 1 or entry.get("opponents") != 1 \
			or entry.get("maximum_owned_creatures") != PARTY.MAX_CREATURES \
			or entry.get("switching") != false or entry.get("fleeing") != false \
			or entry.get("catching") != false or entry.get("extra_combatants") != false \
			or entry.get("human_damage") != false or entry.get("tag_switch_combo") != false \
			or entry.get("tether_commands") != true or entry.get("opponent_owner_kind") != "trainer":
		return ["Master duel must preserve one owned creature versus one trainer creature"]
	if reward.get("tether_candy_item") != "tether_candy" \
			or not _integer(reward.get("tether_candy_count"), 1, 99) \
			or reward.get("cap_lift_on_win") != false or not RULES.db().has("tether_candy"):
		return ["invalid personal Master reward"]
	return []


static func _master_definition(master_id: String) -> Dictionary:
	var catalog := DATA.load_catalog("masters")
	if not bool(catalog.get("ok", false)): return {}
	for row: Dictionary in catalog.data:
		if row.id == master_id: return row
	return {}


static func _valid_master_win_receipt(receipt: String, character_id: String, master_id: String) -> bool:
	var pieces := receipt.split(":")
	return pieces.size() == 6 and pieces[0] == "master_recipe" and pieces[1] == character_id \
		and pieces[2] == master_id and pieces[3] == "win" \
		and _receipt_component(pieces[4]) and _receipt_component(pieces[5])


## Detached host arena state. The actual arena owner first validates reach,
## world availability, spectator separation and its sequential occupancy.
## No client packet may supply an admitted record, opponent UID or arena UID.
static func begin_master_duel(admitted: Dictionary, character_id: String, chosen_uid: String,
		master_id: String, host_duel_id: String, host_opponent_uid: String,
		host_arena_uid: String, cfg: Dictionary) -> Dictionary:
	if not _receipt_component(character_id) or not _receipt_component(chosen_uid) \
			or not _receipt_component(host_duel_id) or not _receipt_component(host_opponent_uid) \
			or not _receipt_component(host_arena_uid) or not _admitted_valid(admitted, character_id) \
			or not master_configuration_errors(cfg).is_empty(): return _refuse("invalid_duel_entry")
	if not bool(cfg.enabled): return _refuse("feature_unavailable")
	var master := _master_definition(master_id)
	if master.is_empty(): return _refuse("unknown_master")
	var chosen := _owned(admitted, chosen_uid)
	if chosen.is_empty(): return _refuse("not_owned")
	var hp: Variant = chosen.get("hp")
	if not (hp is int or hp is float) or not is_finite(float(hp)) or float(hp) <= 0.0 \
			or chosen.get("fainted") != false: return _refuse("conscious_creature_needed")
	if host_opponent_uid == chosen_uid or not _owned(admitted, host_opponent_uid).is_empty():
		return _refuse("opponent_identity_conflict")
	var state := {"duel_id": host_duel_id, "arena_uid": host_arena_uid,
		"master_id": master_id, "character_id": character_id, "creature_uid": chosen_uid,
		"participant_characters": [character_id], "participant_creature_uids": [chosen_uid],
		"opponent_uid": host_opponent_uid, "opponent_owner_kind": "trainer",
		"opponent_species_id": cfg.masters[master_id].creature.species_id,
		"opponent_level": master.cap_level, "resolved": false, "outcome": "active",
		"rule_violations": [], "event_receipts": {}, "final_event_id": ""}
	return {"ok": true, "ready_to_commit": false, "duel": state,
		"requires": ["actual_host_arena_reach_and_occupancy", "freeze_actual_single_creature_pair",
			"host_disable_switch_flee_snare_tag_combo", "host_separate_spectators",
			"world_owned_arena_state_and_reconnect"]}


static func _duel_valid(duel: Dictionary, cfg: Dictionary) -> bool:
	for field: String in ["duel_id", "arena_uid", "character_id", "creature_uid", "opponent_uid"]:
		if not duel.get(field) is String or not _receipt_component(duel[field]): return false
	var master: Variant = duel.get("master_id")
	if not master is String or not cfg.masters.has(master): return false
	var definition := _master_definition(master)
	if definition.is_empty() or duel.get("opponent_level") != definition.cap_level \
			or duel.get("opponent_owner_kind") != "trainer" \
			or duel.get("opponent_species_id") != cfg.masters[master].creature.species_id \
			or duel.get("participant_characters") != [duel.character_id] \
			or duel.get("participant_creature_uids") != [duel.creature_uid] \
			or duel.opponent_uid == duel.creature_uid or not duel.get("resolved") is bool \
			or not duel.get("event_receipts") is Dictionary or not duel.get("rule_violations") is Array \
			or not duel.get("final_event_id") is String: return false
	if not duel.resolved: return duel.get("outcome") == "active" and duel.final_event_id.is_empty() and duel.rule_violations.is_empty()
	return duel.get("outcome") in ["player_win", "player_loss", "void"] \
		and not duel.final_event_id.is_empty() and duel.event_receipts.has(duel.final_event_id)


## host_event is derived from actual host combat/disconnect state. This helper
## does not listen to network packets or trust a client-declared victory.
## Each terminal event is immutable and replay-safe. Reconnect cannot turn an
## unresolved fight into a win; tie/faint outcomes always refuse a reward.
static func resolve_master_duel(duel: Dictionary, host_event: Dictionary, cfg: Dictionary) -> Dictionary:
	if not master_configuration_errors(cfg).is_empty() or not _duel_valid(duel, cfg):
		return _refuse("invalid_duel_state")
	if not bool(cfg.enabled): return _refuse("feature_unavailable")
	var event_id: Variant = host_event.get("event_id")
	var kind: Variant = host_event.get("kind")
	if not event_id is String or not _receipt_component(event_id) or not kind is String \
			or host_event.get("duel_id") != duel.duel_id \
			or host_event.get("arena_uid") != duel.arena_uid: return _refuse("invalid_duel_event")
	var outcome := ""
	var violations: Array = []
	var intent: Array = [kind]
	match kind:
		"health_resolution":
			if host_event.get("creature_uid") != duel.creature_uid \
					or host_event.get("opponent_uid") != duel.opponent_uid: return _refuse("wrong_duel_combatants")
			var ours: Variant = host_event.get("creature_hp")
			var theirs: Variant = host_event.get("opponent_hp")
			if not (ours is int or ours is float) or not (theirs is int or theirs is float) \
					or not is_finite(float(ours)) or not is_finite(float(theirs)) \
					or float(ours) < 0.0 or float(theirs) < 0.0: return _refuse("invalid_host_health")
			if float(ours) > 0.0 and float(theirs) > 0.0: return _refuse("fight_not_resolved")
			outcome = "player_loss" if float(ours) <= 0.0 else "player_win"
			intent.append_array([duel.creature_uid, duel.opponent_uid, float(ours), float(theirs)])
		"owner_disconnect", "arena_unloaded", "fight_aborted":
			outcome = "void"
		"rule_violation":
			var violation: Variant = host_event.get("violation")
			if not violation is String or not violation in ["switch", "flee", "catch", "extra_combatant", "human_damage", "tag_switch_combo"]:
				return _refuse("unknown_duel_violation")
			outcome = "void"
			violations.append(violation)
			intent.append(violation)
		_: return _refuse("unknown_duel_event")
	var fingerprint := JSON.stringify(intent).sha256_text()
	if duel.event_receipts.has(event_id):
		if duel.event_receipts[event_id] != fingerprint: return _refuse("duel_event_conflict")
		return {"ok": true, "duplicate": true, "ready_to_commit": false, "duel": duel.duplicate(true)}
	if duel.resolved: return _refuse("duel_already_resolved")
	var next := duel.duplicate(true)
	next.resolved = true
	next.outcome = outcome
	next.rule_violations = violations
	next.final_event_id = event_id
	next.event_receipts[event_id] = fingerprint
	if not _duel_valid(next, cfg): return _refuse("invalid_duel_candidate")
	return {"ok": true, "duplicate": false, "ready_to_commit": false, "duel": next,
		"before": duel.duplicate(true), "requires": ["actual_host_combat_event_provenance",
			"world_duel_state_CAS", "personal_win_stage_only_for_player_win", "owner_save_ACK"]}


## host_duel is a frozen host arena result, never accepted from the client.
## The arena owner must prove these values from its actual fight participants,
## rules and opponent. A dictionary alone cannot establish that provenance.
## Persist this win even if the player's bag is full, keeping the chest claim
## recoverable in the SAME character record. No recipe/Candy/cap grant here.
static func stage_master_win(admitted: Dictionary, character_id: String,
		host_duel: Dictionary, character_revision: int, cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _receipt_component(character_id) \
			or not _admitted_valid(admitted, character_id) or not master_configuration_errors(cfg).is_empty():
		return _refuse("invalid_master_win")
	if not bool(cfg.enabled): return _refuse("feature_unavailable")
	var master_id: Variant = host_duel.get("master_id")
	var duel_id: Variant = host_duel.get("duel_id")
	var uid: Variant = host_duel.get("creature_uid")
	if not master_id is String or not duel_id is String or not uid is String \
			or not _receipt_component(duel_id) or not _receipt_component(uid): return _refuse("invalid_duel_identity")
	var master := _master_definition(master_id)
	if master.is_empty(): return _refuse("unknown_master")
	if host_duel.get("resolved") != true or host_duel.get("outcome") != "player_win" \
			or host_duel.get("character_id") != character_id \
			or host_duel.get("participant_characters") != [character_id] \
			or host_duel.get("participant_creature_uids") != [uid] \
			or host_duel.get("rule_violations") != [] or host_duel.get("opponent_owner_kind") != "trainer" \
			or host_duel.get("opponent_level") != master.cap_level \
			or host_duel.get("opponent_species_id") != cfg.masters[master_id].creature.species_id:
		return _refuse("duel_not_eligible")
	if _owned(admitted, uid).is_empty(): return _refuse("not_owned")
	var prefix := "master_recipe:%s:%s:win:" % [character_id, master_id]
	var previous := ""
	for receipt: String in admitted.redesign_character.transaction_receipts:
		if not receipt.begins_with(prefix): continue
		if not previous.is_empty() or not _valid_master_win_receipt(receipt, character_id, master_id):
			return _refuse("receipt_conflict")
		previous = receipt
	if admitted.redesign_character.master_wins.has(master_id):
		if previous.is_empty(): return _refuse("win_receipt_missing")
		return {"ok": true, "duplicate": true, "ready_to_commit": false, "receipt": previous,
			"expected_character_revision": character_revision, "requires": ["reconcile_existing_character_decision"]}
	if not previous.is_empty(): return _refuse("receipt_conflict")
	if admitted.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts):
		return _refuse("receipt_budget")
	var next := admitted.duplicate(true)
	var receipt := prefix + duel_id + ":" + uid
	next.redesign_character.master_wins.append(master_id)
	next.redesign_character.transaction_receipts.append(receipt)
	if not _admitted_valid(next, character_id): return _refuse("invalid_candidate")
	return {"ok": true, "duplicate": false, "ready_to_commit": false, "state": next,
		"before": admitted.duplicate(true), "receipt": receipt, "master_id": master_id,
		"expected_character_revision": character_revision,
		"requires": ["frozen_actual_host_one_v_one_result", "same_record_win_receipt_CAS", "owner_save_ACK"]}


## Chest claims use the already durable personal win. Inventory-full refuses
## the entire candidate; the earlier win remains eligible for a later claim.
## Recipe, two authored Candies and claim receipt stage together, never a cap.
static func stage_master_claim(admitted: Dictionary, character_id: String,
		master_id: String, character_revision: int, cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _receipt_component(character_id) \
			or not _admitted_valid(admitted, character_id) or not master_configuration_errors(cfg).is_empty():
		return _refuse("invalid_master_claim")
	if not bool(cfg.enabled): return _refuse("feature_unavailable")
	var master := _master_definition(master_id)
	if master.is_empty(): return _refuse("unknown_master")
	var receipt := "master_recipe:%s:%s:claim" % [character_id, master_id]
	var won: bool = admitted.redesign_character.master_wins.has(master_id)
	var learned: bool = admitted.redesign_character.feast_recipes.has(master.feast_id)
	if admitted.redesign_character.transaction_receipts.has(receipt):
		if not won or not learned: return _refuse("receipt_conflict")
		return {"ok": true, "duplicate": true, "ready_to_commit": false, "receipt": receipt,
			"expected_character_revision": character_revision, "requires": ["reconcile_existing_character_decision"]}
	if not won: return _refuse("personal_master_win_needed")
	if learned: return _refuse("recipe_receipt_missing")
	var wins := 0
	for previous: String in admitted.redesign_character.transaction_receipts:
		if not previous.begins_with("master_recipe:%s:%s:win:" % [character_id, master_id]): continue
		if not _valid_master_win_receipt(previous, character_id, master_id): return _refuse("receipt_conflict")
		wins += 1
	if wins != 1: return _refuse("win_receipt_missing_or_conflicting")
	if admitted.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts):
		return _refuse("receipt_budget")
	var inventory := RULES.inventory_from(admitted.inventory)
	var amount := int(cfg.first_win_chest.tether_candy_count)
	if inventory.add("tether_candy", amount) != 0: return _refuse("inventory_full_claim_retained")
	var next := admitted.duplicate(true)
	next.inventory = RULES.slots(inventory)
	next.redesign_character.feast_recipes.append(master.feast_id)
	next.redesign_character.transaction_receipts.append(receipt)
	if not _admitted_valid(next, character_id): return _refuse("invalid_candidate")
	return {"ok": true, "duplicate": false, "ready_to_commit": false, "state": next,
		"before": admitted.duplicate(true), "receipt": receipt, "recipe_id": master.feast_id,
		"reward": {"id": "tether_candy", "n": amount}, "expected_character_revision": character_revision,
		"requires": ["actual_Master_chest_reach", "same_record_recipe_Candy_receipt_CAS", "owner_save_ACK"]}


static func _refuse(code: String) -> Dictionary:
	return {"ok": false, "code": code}
