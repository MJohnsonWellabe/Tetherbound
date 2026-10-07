extends RefCounted
## F28 detached plans. Only Foundation's admitted-character producer may commit
## these candidates through the existing creature_training delivery transaction.
## No save, RPC, reward journal or client-supplied balance lives in this library.
const DATA := preload("res://scripts/data/redesign_data.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const MASTERS_PATH := "res://data/config/masters.json"
const FEASTS_PATH := "res://data/recipes/feasts.json"

static func masters() -> Dictionary:
	var raw: Variant = DATA.json(MASTERS_PATH)
	return raw if raw is Dictionary else {}

static func feasts() -> Dictionary:
	var raw: Variant = DATA.json(FEASTS_PATH)
	return raw if raw is Dictionary else {}

static func master(id: String) -> Dictionary:
	for row: Dictionary in masters().get("masters", []):
		if row.id == id:
			var result := row.duplicate(true)
			if row.get("species_gate") == "storm_bear_ready":
				var evolution: Variant = load("res://scripts/creatures/evolution.gd")
				if evolution is Script and evolution.has_method("storm_bear_ready") and bool(evolution.call("storm_bear_ready")):
					result.species_id = str(row.ready_species_id)
			return result
	return {}

static func caught_tiers(level: int) -> Array[int]:
	var result: Array[int] = []
	for row: Dictionary in masters().get("masters", []):
		if int(row.cap_level) < level: result.append(int(row.tier))
	return result

static func level_cap(tiers: Array) -> int:
	var cfg := masters()
	if tiers.size() > cfg.get("masters", []).size(): return -1
	for index: int in tiers.size():
		var value: Variant = tiers[index]
		if not (value is int or value is float) or not is_finite(float(value)) \
				or float(value) != float(index + 1): return -1
	var cap := int(cfg.get("initial_cap", 10))
	for row: Dictionary in cfg.get("masters", []):
		# The exact sequential prefix was validated above. JSON restores its
		# integral numbers as floats; Array.has(int) would lose completed tiers.
		if int(row.tier) > tiers.size(): break
		cap = int(row.next_cap)
	return mini(cap, int(cfg.get("ceiling", 60)))

static func status(card: Dictionary, mirror: Dictionary) -> String:
	var cap := level_cap(mirror.get("breakthroughs", []))
	if cap < 0: return "Progression reconciliation required"
	if int(card.get("level", 1)) < cap: return "Level cap %d" % cap
	return "Ceiling reached" if cap == int(masters().get("ceiling", 60)) else "Breakthrough needed"

## Catch producer runs this only on its canonical caught card AFTER the five
## owned-slot admission and teaching mirror are validated. It is never a
## rejoin/legacy-import inference. No missed evolution offer is recreated.
static func initialize_caught(personal: Dictionary, card: Dictionary) -> Dictionary:
	var uid := str(card.get("uid", ""))
	var level := int(card.get("level", 0))
	if uid.is_empty() or level < 1 or level > int(masters().get("ceiling", 60)) \
			or not personal.get("creatures", {}).has(uid): return {}
	var next := personal.duplicate(true)
	var record: Dictionary = next.creatures[uid]
	record.breakthroughs = caught_tiers(level)
	record.cap_level = level_cap(record.breakthroughs)
	record.evolution_choices = {}
	return next

## Only the live ordinary catch admission calls this, after Party.add made
## the actual instance one of at most five owned creatures. It initializes
## that new creature's local mirror, never a loaded/rejoined row or the host's
## admitted record. An ordinary guest newcomer remains unpaid if unadmitted.
static func initialize_owned_catch(party: RefCounted, personal: Dictionary, creature: RefCounted) -> Dictionary:
	if party == null or creature == null: return {}
	var members: Array = party.call("members")
	if members.size() > 5 or not members.has(creature): return {}
	var uid := str(creature.get("uid"))
	if personal.get("creatures", {}).has(uid): return personal.duplicate(true)
	var entries: Array = load("res://scripts/save/save_game.gd").new().call("_party_to_array", party)
	for card: Dictionary in entries:
		if card.get("uid") != uid: continue
		var candidate := initialize_caught(TEACHING.character_loadout_mirror([card], personal), card)
		if candidate.is_empty() or not TEACHING.party_loadout_errors([card], candidate, true).is_empty(): return {}
		if bool(creature.get("traits_initialized")):
			var traits := {"traits_initialized": true, "rolled_traits": creature.get("rolled_traits"),
				"taught_traits": creature.get("taught_traits")}
			if not preload("res://scripts/creatures/traits.gd").trait_state_errors(traits).is_empty(): return {}
			for field: String in traits: candidate.creatures[uid][field] = traits[field].duplicate(true) if traits[field] is Array or traits[field] is Dictionary else traits[field]
			var packet: Variant = creature.get_meta("ordinary_trait_packet", {})
			if not packet is Dictionary: return {}
			if not packet.is_empty():
				var codec: Script = load("res://scripts/save/water_capture_codec.gd")
				if codec == null or codec.call("valid_capture_traits", packet) != true: return {}
				for field: String in traits:
					if packet.get(field) != traits[field]: return {}
				candidate.creatures[uid].captured_from = packet.captured_from.duplicate(true)
		return candidate
	return {}

## Union unlocks without replacing any equipped slot, ancestor knowledge or
## mastery history. The result stays in the same candidate as the cap/choice.
static func refresh_feast_moves(party: Array, personal: Dictionary) -> Dictionary:
	for card: Dictionary in party:
		var record: Dictionary = personal.creatures.get(str(card.uid), {})
		if record.is_empty(): return {}
		var known: Array = card.get("known_moves", []).duplicate()
		for move: String in TEACHING.available_moves(str(card.species_id), int(card.level), record.breakthroughs):
			if not known.has(move): known.append(move)
		card.known_moves = known
	return TEACHING.character_loadout_mirror(party, personal)

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "code": code}

static func _party_index(state: Dictionary, uid: String) -> int:
	for index: int in state.get("party", []).size():
		if str(state.party[index].get("uid", "")) == uid: return index
	return -1

static func _duplicate(state: Dictionary, receipt: String) -> Dictionary:
	if state.get("redesign_character", {}).get("transaction_receipts", []).has(receipt):
		# A receipt alone cannot authenticate a replay's original SKU/choice or
		# ACK. Foundation compares its immutable retained delivery intent first.
		return {"ok": false, "duplicate": true, "receipt": receipt,
			"code": "reconcile_original_delivery"}
	return {}

static func _result(state: Dictionary, receipt: String, op: String) -> Dictionary:
	state.redesign_character.transaction_receipts.append(receipt)
	return {"ok": true, "duplicate": false, "receipt": receipt, "operation": op, "state": state}

## All item changes are made on a detached Inventory using the real catalogue.
## A missing item, insufficient input, or full output bag discards the whole plan.
static func _inventory(state: Dictionary, debit: Dictionary, credit: Dictionary) -> bool:
	if not BAG.valid_slots(state.get("inventory")): return false
	var bag := BAG.inventory_from(state.inventory)
	for id: String in debit:
		if not BAG.db().has(id) or int(debit[id]) <= 0 or bag.count(id) < int(debit[id]): return false
	for id: String in debit:
		if not bag.remove(id, int(debit[id])): return false
	for id: String in credit:
		if not BAG.db().has(id) or not BAG.give_stack(bag, {"id": id, "n": int(credit[id])}): return false
	state.inventory = BAG.slots(bag)
	return true

## Called from a host-owned duel result, never from a client victory packet.
## Durable win first; claiming a full chest later remains possible after reload.
static func prepare_win(current: Dictionary, master_id: String, character_id: String) -> Dictionary:
	var row := master(master_id)
	if row.is_empty() or current.get("character_id") != character_id: return _deny("invalid_winner")
	var receipt := "master_recipe:%s:%s:win" % [master_id, character_id]
	var replay := _duplicate(current, receipt)
	if not replay.is_empty(): return replay
	var next := current.duplicate(true)
	if not next.redesign_character.master_wins.has(master_id): next.redesign_character.master_wins.append(master_id)
	var result := _result(next, receipt, "master_win")
	result.intent = {"master_id": master_id, "character_id": character_id}
	return result

static func prepare_chest(current: Dictionary, master_id: String, character_id: String) -> Dictionary:
	var row := master(master_id)
	if row.is_empty() or current.get("character_id") != character_id: return _deny("invalid_character")
	var receipt := "master_recipe:%s:%s" % [master_id, character_id]
	var replay := _duplicate(current, receipt)
	if not replay.is_empty(): return replay
	if not current.redesign_character.master_wins.has(master_id): return _deny("win_your_own_duel_first")
	var next := current.duplicate(true)
	if not _inventory(next, {}, {"tether_candy": int(row.candy)}): return _deny("chest_pending_make_satchel_room")
	if not next.redesign_character.feast_recipes.has(row.feast_id): next.redesign_character.feast_recipes.append(row.feast_id)
	var result := _result(next, receipt, "master_chest")
	result.intent = {"master_id": master_id, "character_id": character_id}
	return result

## Compatibility refusal only. F32 owns renewable node/crop staging, stock,
## host-day generations and outputs through the existing world_harvest carrier.
static func prepare_gather(_current: Dictionary, _source_id: String, _context: Dictionary) -> Dictionary:
	return _deny("attuned_sources_owned_by_f32")

## Context is supplied by the registered live Kitchen producer: never a request
## field. The host's actual building/attachment tier is the effective tier.
static func prepare_cook(current: Dictionary, recipe_id: String, craft_id: String, context: Dictionary) -> Dictionary:
	var recipe: Dictionary = feasts().get("recipes", {}).get(recipe_id, {})
	if recipe.is_empty() or craft_id.length() != 32 or not craft_id.is_valid_hex_number(false): return _deny("invalid_recipe_or_id")
	var receipt := "craft:%s:%s" % [str(current.get("character_id", "")), craft_id]
	var replay := _duplicate(current, receipt)
	if not replay.is_empty(): return replay
	if context.get("station_id") != "kitchen" or context.get("homestead") != true \
			or context.get("in_range") != true or context.get("in_combat", true) != false:
		return _deny("ascension_feasts_require_homestead_kitchen")
	if int(context.get("effective_tier", 0)) < int(recipe.station_tier): return _deny("upgrade_the_host_kitchen")
	if not current.redesign_character.feast_recipes.has(recipe.feast_id): return _deny("learn_recipe_from_master_chest")
	var next := current.duplicate(true)
	if not _inventory(next, recipe.cost, recipe.output): return _deny("ingredients_or_satchel_room")
	var result := _result(next, receipt, "feast_cook")
	result.intent = {"recipe_id": recipe_id, "craft_id": craft_id, "character_id": str(current.character_id)}
	return result

## The SKU is immutable authored data: type/catalyst cannot be changed by a
## packet or mutable item metadata. F29 transforms the clone before ONE commit.
static func prepare_feed(current: Dictionary, uid: String, feast_item: String, choice: String,
		context: Dictionary, species_types: Callable, evolve: Callable, refresh_moves: Callable) -> Dictionary:
	var definition: Dictionary = feasts().get("items", {}).get(feast_item, {})
	if definition.get("kind") != "ascension_feast": return _deny("not_an_ascension_feast")
	var tier := int(definition.tier)
	var receipt := "feast_feed:%s:%d" % [uid, tier]
	var replay := _duplicate(current, receipt)
	if not replay.is_empty(): return replay
	if context.get("in_combat", true) != false or context.get("owns_character") != true: return _deny("cannot_feed_now")
	var index := _party_index(current, uid)
	if index < 0: return _deny("creature_not_owned")
	var next := current.duplicate(true)
	var card: Dictionary = next.party[index]
	var mirror: Dictionary = next.redesign_character.creatures.get(uid, {})
	if mirror.is_empty(): return _deny("typed_creature_progression_required")
	var tiers: Array = mirror.get("breakthroughs", [])
	var cap := level_cap(tiers)
	if int(mirror.get("cap_level", -1)) != cap or int(card.level) != cap \
			or cap != int(definition.breaks_level) or tiers.has(tier): return _deny("feast_must_match_current_cap")
	if not species_types.is_valid() or not evolve.is_valid() or not refresh_moves.is_valid(): return _deny("training_dependencies_unavailable")
	var types: Variant = species_types.call(str(card.species_id))
	if not types is Array or not types.has(str(definition.attuned_type)): return _deny("attuned_ingredient_must_match_creature")
	var planner_card := card.duplicate(true)
	planner_card.evolution_choices = mirror.evolution_choices.duplicate(true)
	var evolution: Variant = evolve.call(planner_card, tier, choice, str(definition.get("catalyst", "")))
	if not evolution is Dictionary or evolution.get("ok") != true: return _deny(str(evolution.get("code", "evolution_choice_refused")) if evolution is Dictionary else "invalid_evolution_plan")
	# Catalyst was paid while cooking. Any second debit is a contract violation.
	if not evolution.get("debit", {}).is_empty(): return _deny("evolution_must_not_charge_cooked_catalyst_twice")
	var evolved: Variant = evolution.get("creature")
	if not evolved is Dictionary or evolved.get("uid") != uid: return _deny("evolution_identity_changed")
	evolved.erase("evolution_choices")
	next.party[index] = evolved
	var record: Dictionary = evolution.get("choice_record", {})
	if not record.is_empty(): mirror.evolution_choices[str(record.tier)] = str(record.value)
	tiers.append(tier)
	mirror.cap_level = level_cap(tiers)
	# No level/XP bonus: the newly opened range still needs earned training.
	if not _inventory(next, {feast_item: 1}, {}): return _deny("cooked_feast_missing")
	var refreshed: Variant = refresh_moves.call(next.party, next.redesign_character)
	if not refreshed is Dictionary or refreshed.is_empty(): return _deny("learnset_refresh_failed")
	next.redesign_character = refreshed
	var result := _result(next, receipt, "feast_feed")
	result.intent = {"creature_uid": uid, "feast_item": feast_item, "choice": choice,
		"character_id": str(current.character_id)}
	return result
