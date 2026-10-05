extends RefCounted

## F27 pure proposals over the existing host-admitted portable record. This
## helper does not establish transport identity, station reach, ownership of a
## pending catch, encounter participation, or durable acceptance. Session's
## same-record CAS must recompute a proposal from its own record, commit the
## inventory/party/receipt together, then settle the portable owner's save.
## No balance bag, second receipt ledger, scene mutation or optimistic debit.
const DATA := preload("res://scripts/data/redesign_data.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")
const CONFIG_PATH := "res://data/config/essence.json"
static var _configuration: Dictionary = {}
static var _species: Dictionary = {}


static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floorf(float(value)) and float(value) >= minimum and float(value) <= maximum


static func _component(value: Variant) -> bool:
	return value is String and not value.is_empty() and value.length() <= 128 \
		and value == value.strip_edges() and not value.contains(":") \
		and not value.contains("\n") and not value.contains("\r")


## Host event/session identities may contain separators. They remain opaque
## and are hashed before becoming receipt components; do not narrow the
## neutral core's existing 160-character identity contract to UUID-only IDs.
static func _opaque_id(value: Variant) -> bool:
	return value is String and not value.is_empty() and value.length() <= 160 \
		and value == value.strip_edges() and not value.contains("\n") and not value.contains("\r")


static func _defeat_action_component(world_namespace: String, event_id: String) -> String:
	return JSON.stringify([world_namespace, event_id]).sha256_text()


static func config() -> Dictionary:
	if _configuration.is_empty():
		var raw: Variant = DATA.json(CONFIG_PATH)
		if not raw is Dictionary or not configuration_errors(raw).is_empty():
			push_error("F27 essence configuration is missing or invalid")
			return {}
		_configuration = raw
	return _configuration.duplicate(true)


static func configuration_errors(cfg: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if cfg.get("schema_version") != 1:
		errors.append("unsupported essence configuration version")
	if cfg.has("wild_victory_xp_mode") and not cfg.wild_victory_xp_mode in ["ordinary", "hybrid"]:
		errors.append("invalid wild victory XP mode")
	for field: String in ["essence_xp_value", "defeat_bonus_level_interval", "tether_candy_cost", "maximum_transaction_receipts", "maximum_release_receipts"]:
		if not _integer(cfg.get(field), 1, 2147483647): errors.append("invalid " + field)
	for field: String in ["defeat_essence_base", "release_essence_base", "care_per_grooming", "care_daily_character_cap", "crop_essence_yield", "crop_attuned_yield"]:
		if not _integer(cfg.get(field), 0, 2147483647): errors.append("invalid " + field)
	for field: String in ["auto_xp_scale", "release_essence_per_level", "altar_interaction_radius_m"]:
		var value: Variant = cfg.get(field)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) <= 0.0:
			errors.append("invalid " + field)
	if errors.is_empty() and float(cfg.auto_xp_scale) >= 1.0: errors.append("automatic combat XP must be positive and reduced")
	if cfg.get("tether_candy_item") != "tether_candy" or cfg.get("tether_candy_cost") != 1:
		errors.append("one canonical Tether Candy pays one level")
	if cfg.has("altar_result_retry_seconds") and not _integer(cfg.altar_result_retry_seconds, 1, 30):
		errors.append("invalid Altar result retry interval")
	var node_yield: Variant = cfg.get("attuned_node_yield")
	if not node_yield is Array or node_yield.size() != 2 \
			or not _integer(node_yield[0], 1, 2147483647) or not _integer(node_yield[1], 1, 2147483647):
		errors.append("invalid attuned node yield range")
	elif int(node_yield[0]) > int(node_yield[1]):
		errors.append("attuned node yield range is reversed")
	if cfg.get("release_rounding") != "floor" or cfg.get("dual_type_payout") != "split_remainder_to_primary" \
			or cfg.get("level_spend_xp_policy") != "preserve_until_cap_then_discard" \
			or cfg.get("legacy_above_cap_policy") != "refuse_until_typed_cap_admitted":
		errors.append("unsupported essence transaction policy")
	var bands: Variant = cfg.get("level_cost_bands")
	if not bands is Array or bands.is_empty():
		errors.append("level cost bands are required")
	else:
		var next_level := 1
		for raw: Variant in bands:
			if not raw is Dictionary or not _integer(raw.get("minimum_level"), 1, 60) \
					or not _integer(raw.get("maximum_level"), 1, 60):
				errors.append("invalid level cost band")
				continue
			var multiplier: Variant = raw.get("multiplier")
			if int(raw.minimum_level) != next_level or int(raw.maximum_level) < int(raw.minimum_level) \
					or not (multiplier is int or multiplier is float) \
					or not is_finite(float(multiplier)) or float(multiplier) <= 0.0:
				errors.append("level bands must be contiguous and positive")
			next_level = int(raw.maximum_level) + 1
		if next_level != 61: errors.append("level bands must cover the live level ceiling")
	return errors


static func essence_item(type_id: String) -> String:
	var rows: Variant = DATA.json("res://data/schema/essences.json")
	if rows is Array:
		for row: Variant in rows:
			if row is Dictionary and row.get("type") == type_id:
				return str(row.get("id", ""))
	return ""


static func _species_types(row: Dictionary) -> Array[String]:
	if _species.is_empty():
		var raw: Variant = DATA.json("res://data/creatures/species.json")
		if raw is Dictionary and raw.get("species") is Dictionary:
			var merged := preload("res://scripts/creatures/water_species_catalog.gd").merge_catalogue(raw.species)
			if bool(merged.get("ok", false)): _species = merged.catalogue
			else: return [] # Never invent type identity on a conflicting roster.
	var definition: Variant = _species.get(row.get("species_id"))
	var result: Array[String] = []
	if not definition is Dictionary or row.get("creature_type") != definition.get("type") \
			or row.get("secondary_type", "") != definition.get("type_secondary", ""):
		return result
	for value: Variant in [definition.get("type"), definition.get("type_secondary", "")]:
		if value is String and not value.is_empty():
			if essence_item(value).is_empty() or result.has(value): return []
			result.append(value)
	return result


## Typed F16 cap only. A caught-above-cap legacy row is not assigned invented
## breakthrough history; its spend stays closed until an actual cap is admitted.
static func creature_cap(personal: Dictionary, uid: String) -> int:
	var records: Variant = personal.get("creatures")
	if not records is Dictionary or not records.has(uid): return -1
	var mirror: Variant = records[uid]
	var cap: Variant = mirror.get("cap_level") if mirror is Dictionary else null
	var rows: Variant = DATA.json("res://data/schema/level_caps.json")
	if not _integer(cap, 1, 60) or not rows is Array: return -1
	for row: Variant in rows:
		if row is Dictionary and row.get("status") == "live" and row.get("level") == cap:
			return int(cap)
	return -1


static func level_cost(level: int, cfg: Dictionary, progression_cfg: Dictionary) -> int:
	if not configuration_errors(cfg).is_empty(): return -1
	for band: Dictionary in cfg.level_cost_bands:
		if level >= int(band.minimum_level) and level <= int(band.maximum_level):
			var xp := PROGRESSION.xp_to_next(level, progression_cfg)
			var amount := ceilf(float(xp) / float(cfg.essence_xp_value) * float(band.multiplier))
			return int(amount) if xp > 0 and is_finite(amount) and amount > 0.0 and amount <= 2147483647 else -1
	return -1


static func _owned_index(admitted: Dictionary, uid: String) -> int:
	var rows: Variant = admitted.get("party")
	if not rows is Array or rows.size() > PARTY.MAX_CREATURES: return -1
	var seen: Dictionary = {}
	var found := -1
	for index: int in rows.size():
		var row: Variant = rows[index]
		if not row is Dictionary or not _component(row.get("uid")) or seen.has(row.uid): return -1
		seen[row.uid] = true
		if row.uid == uid: found = index
	return found


static func _baseline_errors(admitted: Dictionary, character_id: String) -> Array[String]:
	if not _component(character_id) or admitted.get("character_id") != character_id \
			or not admitted.get("party") is Array or admitted.party.size() > PARTY.MAX_CREATURES:
		return ["wrong admitted character or roster"]
	var errors := STATE.validate("character", admitted.get("redesign_character"), STATE.uids(admitted.party))
	if not RULES.valid_slots(admitted.get("inventory")) or admitted.inventory.size() != INVENTORY.SLOT_COUNT:
		errors.append("invalid admitted slot inventory")
	else:
		for stack: Variant in admitted.inventory:
			if stack is Dictionary and not RULES.db().has(str(stack.id)):
				errors.append("unknown admitted inventory item")
	return errors


## Read-only display proposal for the Altar. The station service must validate
## its actual registered Altar first, and must recompute costs during submit.
## None of these balances/caps/costs are authority inputs to stage_spend.
static func quote_spend(admitted: Dictionary, character_id: String, uid: String,
		character_revision: int, cfg: Dictionary, progression_cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _component(uid) or not _baseline_errors(admitted, character_id).is_empty() \
			or not configuration_errors(cfg).is_empty(): return _refuse("invalid_quote")
	var index := _owned_index(admitted, uid)
	if index < 0: return _refuse("not_owned")
	var owned: Dictionary = admitted.party[index]
	var cap := creature_cap(admitted.redesign_character, uid)
	if not _integer(owned.get("level"), 1, 60) or cap < 0 or int(owned.level) > cap:
		return _refuse("cap_not_admitted")
	var types := _species_types(owned)
	if types.is_empty(): return _refuse("invalid_species_type")
	var payments: Array[Dictionary] = []
	if int(owned.level) < cap:
		var cost := level_cost(int(owned.level), cfg, progression_cfg)
		if cost < 1 or PROGRESSION.staged_next_level(owned, cap, progression_cfg, _canonical_trait_maximum.bind(admitted.redesign_character.creatures)).is_empty():
			return _refuse("invalid_creature")
		if admitted.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts):
			return _refuse("receipt_budget")
		var inventory := RULES.inventory_from(admitted.inventory)
		for type_id: String in types:
			var item := essence_item(type_id)
			if not RULES.db().has(item): return _refuse("unknown_payment_item")
			payments.append({"id": item, "name": RULES.db().item_name(item),
				"cost": cost, "available": inventory.count(item)})
		var candy := str(cfg.tether_candy_item)
		if not RULES.db().has(candy): return _refuse("unknown_payment_item")
		payments.append({"id": candy, "name": RULES.db().item_name(candy),
			"cost": int(cfg.tether_candy_cost), "available": inventory.count(candy)})
	return {"ok": true, "creature_uid": uid, "level": int(owned.level), "cap": cap,
		"expected_character_revision": character_revision, "payments": payments}


## Caller must already have validated actual registered Altar reach and
## cooldown against this host character revision. The request carries neither
## a cost nor a proposed balance/cap/party. Its expected level detects stale UI.
static func stage_spend(admitted: Dictionary, character_id: String, uid: String,
		spend_id: String, expected_level: int, payment_item: String, character_revision: int,
		cfg: Dictionary, progression_cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _component(uid) or not _component(spend_id) \
			or not _integer(expected_level, 1, 60) or not _component(payment_item) \
			or not _baseline_errors(admitted, character_id).is_empty() or not configuration_errors(cfg).is_empty():
		return _refuse("invalid_spend")
	var prefix := "essence_spend:%s:%s:" % [character_id, spend_id]
	var duplicate_receipt := ""
	for previous: String in admitted.redesign_character.transaction_receipts:
		if not previous.begins_with(prefix): continue
		var parts := previous.split(":")
		if parts.size() != 8 or parts[3] != uid or parts[4] != str(expected_level) \
				or parts[5] != payment_item or not parts[6].is_valid_int() or int(parts[6]) < 1 \
				or not parts[7].is_valid_int() or int(parts[7]) != character_revision:
			return _refuse("receipt_conflict")
		if not duplicate_receipt.is_empty(): return _refuse("receipt_conflict")
		duplicate_receipt = previous
	if not duplicate_receipt.is_empty():
		return {"ok": true, "duplicate": true, "receipt": duplicate_receipt, "expected_character_revision": character_revision}
	var index := _owned_index(admitted, uid)
	if index < 0: return _refuse("not_owned")
	var owned: Dictionary = admitted.party[index]
	if not _integer(owned.get("level"), 1, 60) or int(owned.level) != expected_level:
		return _refuse("stale_level")
	var cap := creature_cap(admitted.redesign_character, uid)
	if cap < 0 or int(owned.level) > cap: return _refuse("cap_not_admitted")
	if int(owned.level) == cap: return _refuse("breakthrough_needed")
	var types := _species_types(owned)
	if types.is_empty(): return _refuse("invalid_species_type")
	var candy := payment_item == str(cfg.tether_candy_item)
	var permitted := candy
	for type_id: String in types:
		if payment_item == essence_item(type_id): permitted = true
	if not permitted or not RULES.db().has(payment_item): return _refuse("wrong_payment_type")
	var cost := int(cfg.tether_candy_cost) if candy else level_cost(expected_level, cfg, progression_cfg)
	if cost < 1: return _refuse("invalid_cost")
	if admitted.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts):
		return _refuse("receipt_budget")
	var inventory := RULES.inventory_from(admitted.inventory)
	if not inventory.remove(payment_item, cost): return _refuse("insufficient_items")
	var next_row := PROGRESSION.staged_next_level(owned, cap, progression_cfg, _canonical_trait_maximum.bind(admitted.redesign_character.creatures))
	if next_row.is_empty(): return _refuse("invalid_creature")
	next_row = PROGRESSION.staged_training_condition(next_row, 1, false)
	if next_row.is_empty(): return _refuse("invalid_creature_condition")
	var next := admitted.duplicate(true)
	next.party[index] = next_row
	next.inventory = RULES.slots(inventory).duplicate(true)
	var receipt := prefix + "%s:%d:%s:%d:%d" % [uid, expected_level, payment_item, cost, character_revision]
	next.redesign_character.transaction_receipts.append(receipt)
	if not _baseline_errors(next, character_id).is_empty(): return _refuse("invalid_candidate")
	return {"ok": true, "duplicate": false, "expected_character_revision": character_revision,
		"creature_uid": uid, "receipt": receipt, "payment": {"id": payment_item, "n": cost},
		"state": next, "before": admitted.duplicate(true), "old_level": expected_level, "new_level": expected_level + 1}


## Exact detached character fields affected by training. Portal/vitals carrier
## and every unrelated portable field remain on the original admitted record.
static func training_projection(record: Dictionary) -> Dictionary:
	if not record.get("party") is Array or not record.get("inventory") is Array \
			or not record.get("redesign_character") is Dictionary: return {}
	# Energy is the in-fight move meter, never owner authority; see
	# character_record_rules.gd portable_projection.
	var party: Array = record.get("party", []).duplicate(true)
	for card: Variant in party:
		if card is Dictionary: card.erase("energy")
	return {"party": party,
		"inventory": record.get("inventory", []).duplicate(true),
		"redesign_character": record.get("redesign_character", {}).duplicate(true)}


static func _equivalent(a: Variant, b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):
		return is_finite(float(a)) and is_finite(float(b)) and float(a) == float(b)
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equivalent(a[key], b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for index: int in a.size():
			if not _equivalent(a[index], b[index]): return false
		return true
	return typeof(a) == typeof(b) and a == b


## Canonical F23 providers are supplied by the actual host adapter. Missing
## providers refuse; known/mastery/loadout history is never invented or reset.
static func refresh_training_moves(candidate: Dictionary, available_moves: Callable,
		mirror_provider: Callable) -> Dictionary:
	if not available_moves.is_valid() or not mirror_provider.is_valid(): return {}
	var next := candidate.duplicate(true)
	for raw: Variant in next.get("party", []):
		if not raw is Dictionary or not raw.get("known_moves") is Array: return {}
		var uid := str(raw.get("uid", ""))
		var personal: Variant = next.redesign_character.creatures.get(uid, {})
		if not personal is Dictionary: return {}
		var tiers: Variant = personal.get("breakthroughs", [])
		if not tiers is Array: return {}
		var additions: Variant = available_moves.call(str(raw.get("species_id", "")), int(raw.get("level", 0)), tiers)
		if not additions is Array: return {}
		for move: Variant in additions:
			if not move is String or str(move).is_empty(): return {}
			if not raw.known_moves.has(move): raw.known_moves.append(move)
	var mirror: Variant = mirror_provider.call(next.party, next.redesign_character)
	if not mirror is Dictionary: return {}
	next.redesign_character = mirror
	return next


## Session has already bound the transport sender, validated the actual Altar
## and finished fallback before capturing these admitted values. The packet
## contains exactly the established UI intent fields, never a state or cost.
static func stage_core_spend(admitted: Dictionary, character_id: String, host_revision: int,
		request: Dictionary, cfg: Dictionary, progression_cfg: Dictionary,
		available_moves: Callable, mirror_provider: Callable) -> Dictionary:
	var keys := ["spend_id", "creature_uid", "expected_level", "payment_item", "expected_character_revision"]
	if request.size() != keys.size(): return _refuse("invalid_spend_intent")
	for key: String in keys:
		if not request.has(key): return _refuse("invalid_spend_intent")
	for key: String in ["spend_id", "creature_uid", "payment_item"]:
		if not _component(request[key]): return _refuse("invalid_spend_intent")
	if not _integer(request.expected_level, 1, 60) \
			or not _integer(request.expected_character_revision, 0, 2147483646) or host_revision < 0:
		return _refuse("invalid_spend_revision")
	var proposal := stage_spend(admitted, character_id, request.creature_uid, request.spend_id,
		int(request.expected_level), request.payment_item, int(request.expected_character_revision), cfg, progression_cfg)
	if not bool(proposal.get("ok", false)) or bool(proposal.get("duplicate", false)): return proposal
	if int(request.expected_character_revision) != host_revision: return _refuse("stale_revision")
	var refreshed := refresh_training_moves(proposal.state, available_moves, mirror_provider)
	if refreshed.is_empty() or not _baseline_errors(refreshed, character_id).is_empty():
		return _refuse("canonical_power_refresh_unavailable")
	proposal.state = refreshed
	return proposal


## Construct a host-only nine-field intent (original eight plus frozen XP mode) at
## the accepted killing-hit hook, BEFORE terminal publication/legacy awards.
## The caller proves actual EncounterHost/world/body/deployment residency and
## sender admission. None of these inputs is a remotely callable reward claim.
## Session supplies its current runtime epoch; no minted fallback ids/rosters.
static func host_wild_defeat_event(admitted: Dictionary, character_id: String,
		host_peer_id: int, world_namespace: String, session_epoch: String,
		host_record: Dictionary, actual_dead_enemy: Dictionary,
		host_active_uid: String, cfg: Dictionary) -> Dictionary:
	if not cfg.get("wild_victory_xp_mode") in ["ordinary", "hybrid"]: return _refuse("invalid_defeat_XP_policy")
	if host_peer_id < 1 or not _component(character_id) or not _component(host_active_uid) \
			or not _opaque_id(world_namespace) or not _opaque_id(session_epoch) \
			or not _baseline_errors(admitted, character_id).is_empty(): return _refuse("invalid_host_defeat_context")
	if host_record.get("kind") != "wild" or not host_record.get("phase") in ["active", "resolving", "done"] \
			or not _opaque_id(host_record.get("encounter_id")) \
			or not host_record.get("realm") is String or not BIOMES.runtime_ids(false).has(host_record.realm) \
			or not _integer(host_record.get("seq"), 1, 2147483647) \
			or not host_record.get("participants") is Dictionary: return _refuse("actual_host_wild_record_required")
	var participants: Dictionary = host_record.participants
	var participant: Variant = participants.get(host_peer_id)
	if not participant is Dictionary or participant.get("character_id") != character_id \
			or not _integer(participant.get("joined_seq"), 1, int(host_record.seq)): return _refuse("not_actual_defeat_participant")
	var opponent: Variant = host_record.get("opponent")
	if not opponent is Dictionary or not opponent.get("owner_npc") is String or opponent.owner_npc != "" \
			or not _integer(opponent.get("hp"), 0, 0) or not _integer(opponent.get("level"), 1, 100) \
			or not _integer(opponent.get("body_generation"), 1, 2147483647): return _refuse("actual_dead_wild_required")
	if not _component(actual_dead_enemy.get("uid")) or not _integer(actual_dead_enemy.get("hp"), 0, 0) \
			or not actual_dead_enemy.get("fainted") is bool or actual_dead_enemy.fainted != true \
			or not _component(actual_dead_enemy.get("species_id")) \
			or actual_dead_enemy.species_id != opponent.get("species_id") \
			or not _equivalent(actual_dead_enemy.get("level"), opponent.level): return _refuse("host_enemy_identity_mismatch")
	var hp_max: Variant = actual_dead_enemy.get("max_hp")
	if not (hp_max is int or hp_max is float) or not is_finite(float(hp_max)) or float(hp_max) <= 0.0 \
			or not _equivalent(hp_max, opponent.get("hp_max")): return _refuse("host_enemy_identity_mismatch")
	var card: Variant = opponent.get("card")
	if not card is Dictionary or card.get("uid") != actual_dead_enemy.uid \
			or card.get("species_id") != actual_dead_enemy.species_id \
			or not _equivalent(card.get("level"), actual_dead_enemy.level): return _refuse("host_enemy_identity_mismatch")
	if _owned_index(admitted, actual_dead_enemy.uid) >= 0 or _owned_index(admitted, host_active_uid) < 0:
		return _refuse("invalid_defeat_roster")
	# Same legacy victory eligibility: all living owned members, up to five.
	# Active UID comes from CURRENT authenticated deployed body/card, not the
	# participant row's potentially stale opening UID after a tag switch.
	var eligible: Array[String] = []
	for row: Variant in admitted.party:
		if not row is Dictionary or not _component(row.get("uid")) \
				or not row.get("fainted") is bool: return _refuse("invalid_defeat_roster")
		var hp: Variant = row.get("hp")
		if not (hp is int or hp is float) or not is_finite(float(hp)) or float(hp) < 0.0 \
				or row.fainted != (float(hp) == 0.0): return _refuse("invalid_defeat_roster")
		if not row.fainted: eligible.append(row.uid)
	if eligible.is_empty(): return _refuse("no_living_defeat_recipient")
	eligible.sort()
	var identity := [world_namespace, session_epoch, host_record.realm,
		host_record.encounter_id, int(opponent.body_generation), actual_dead_enemy.uid]
	var event := {"event_id": "wild_defeat:" + JSON.stringify(identity).sha256_text(),
		"world_namespace": world_namespace, "encounter_id": host_record.encounter_id,
		"enemy_uid": actual_dead_enemy.uid, "enemy_record": actual_dead_enemy.duplicate(true),
		"active_uid": host_active_uid, "eligible_uids": eligible, "kind": "wild_defeat",
		"xp_mode": cfg.wild_victory_xp_mode, "realm": host_record.realm, "shed": {}}
	# F32#4: the shed is decided ONCE here from host config and frozen in the
	# event, so a later flag/table change never invalidates the journaled row.
	event.shed = defeat_shed(event, character_id)
	return {"ok": true, "intent": event, "source_identity": identity}


## Pure bridge for the same admitted registry transaction used by the Altar.
## Do not call legacy gain_xp or item.add alongside this. Stage/journal/owner
## bool-save/accepted ACK remain Foundation's existing typed transaction.
static func stage_host_wild_victory(admitted: Dictionary, character_id: String,
		host_revision: int, host_peer_id: int, world_namespace: String, session_epoch: String,
		host_record: Dictionary, actual_dead_enemy: Dictionary, host_active_uid: String,
		cfg: Dictionary, progression_cfg: Dictionary, available_moves: Callable,
		mirror_provider: Callable) -> Dictionary:
	var source := host_wild_defeat_event(admitted, character_id, host_peer_id,
		world_namespace, session_epoch, host_record, actual_dead_enemy, host_active_uid, cfg)
	if source.get("ok") != true: return source
	var event: Dictionary = source.intent
	var proposal := stage_core_defeat(admitted, character_id, event, host_revision,
		cfg, progression_cfg, available_moves, mirror_provider)
	if proposal.get("ok") != true: return proposal
	proposal["action"] = "wild_defeat"
	proposal["action_id"] = event.event_id
	proposal["intent"] = event.duplicate(true)
	return proposal

## Actual accepted damage outcome copied by the director after its live HP
## commit. This is host-internal only: no reward-intent RPC, debug receipt,
## client verdict or independently synthesized dead-card entitlement.
static func stage_accepted_host_wild_victory(admitted: Dictionary, character_id: String,
		host_revision: int, recipient_peer_id: int, world_namespace: String, session_epoch: String,
		host_record: Dictionary, actual_dead_enemy: Dictionary, host_active_uid: String,
		accepted: Dictionary, cfg: Dictionary, progression_cfg: Dictionary,
		available_moves: Callable, mirror_provider: Callable) -> Dictionary:
	if not accepted.get("ok") is bool or accepted.ok != true or accepted.get("kind") != "strike_intent" \
			or not _integer(accepted.get("peer"), 1, 2147483647) or not accepted.get("delta") is Dictionary:
		return _refuse("actual_accepted_killing_hit_required")
	var delta: Dictionary = accepted.delta
	if not delta.get("hit") is bool or delta.hit != true or not delta.get("killed") is bool \
			or delta.killed != true or delta.get("encounter_id") != host_record.get("encounter_id") \
			or not host_record.get("participants") is Dictionary \
			or not host_record.participants.has(int(accepted.peer)):
		return _refuse("actual_accepted_killing_hit_required")
	var damage: Variant = delta.get("damage")
	if not (damage is int or damage is float) or not is_finite(float(damage)) or float(damage) <= 0.0 \
			or not _integer(delta.get("hp"), 0, 0) \
			or not _equivalent(delta.get("hp_max"), actual_dead_enemy.get("max_hp")):
		return _refuse("actual_accepted_killing_hit_required")
	return stage_host_wild_victory(admitted, character_id, host_revision, recipient_peer_id,
		world_namespace, session_epoch, host_record, actual_dead_enemy, host_active_uid,
		cfg, progression_cfg, available_moves, mirror_provider)

## Replayable host capture, never a wire-level owner reward claim. Its mode
## was frozen when the director committed the real killing hit. A config
## activation later cannot turn the same event into a new or repriced award.
static func stage_captured_host_victory(admitted: Dictionary, character_id: String,
		host_revision: int, recipient_peer_id: int, frozen: Dictionary,
		cfg: Dictionary, progression_cfg: Dictionary, available_moves: Callable,
		mirror_provider: Callable) -> Dictionary:
	if not frozen.get("ok") is bool or frozen.ok != true or not frozen.get("record") is Dictionary \
			or not frozen.get("enemy_record") is Dictionary or not frozen.get("accepted") is Dictionary \
			or not frozen.get("deployments") is Array or not frozen.get("xp_mode") in ["ordinary", "hybrid"] \
			or not _opaque_id(frozen.get("world_namespace")) or not _opaque_id(frozen.get("session_id")):
		return _refuse("invalid_frozen_host_defeat")
	var active_uid := ""
	var seen := {}
	for row: Variant in frozen.deployments:
		if not row is Dictionary or row.size() != 2 or not _integer(row.get("peer_id"), 1, 2147483647) \
				or seen.has(int(row.peer_id)) or not _component(row.get("active_uid")):
			return _refuse("invalid_frozen_host_defeat")
		seen[int(row.peer_id)] = true
		if int(row.peer_id) == recipient_peer_id: active_uid = row.active_uid
	if active_uid.is_empty(): return _refuse("not_actual_defeat_participant")
	var original_cfg := cfg.duplicate(true)
	original_cfg["wild_victory_xp_mode"] = frozen.xp_mode
	var source := host_wild_defeat_event(admitted, character_id, recipient_peer_id,
		frozen.world_namespace, frozen.session_id, frozen.record, frozen.enemy_record, active_uid, original_cfg)
	if source.get("ok") != true: return source
	if source.intent.event_id != frozen.get("source_id"): return _refuse("invalid_frozen_host_defeat")
	return stage_accepted_host_wild_victory(admitted, character_id, host_revision, recipient_peer_id,
		frozen.world_namespace, frozen.session_id, frozen.record, frozen.enemy_record, active_uid,
		frozen.accepted, original_cfg, progression_cfg, available_moves, mirror_provider)




## Host event is frozen by actual wild defeat authority, never an RPC packet.
## XP, essence, typed caps and receipt are one candidate. No inventory payout
## can occur if any XP recipient/cap/slot/journal validation refuses.
static func stage_defeat(admitted: Dictionary, character_id: String, host_event: Dictionary,
		character_revision: int, cfg: Dictionary, progression_cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or character_revision > 2147483646 \
			or not _baseline_errors(admitted, character_id).is_empty() \
			or not configuration_errors(cfg).is_empty(): return _refuse("invalid_defeat")
	var keys := ["event_id", "world_namespace", "encounter_id", "enemy_uid", "enemy_record", "active_uid", "eligible_uids", "kind", "xp_mode"]
	# F32#4 adds "realm" and the host-frozen "shed" outputs. A nine-key legacy
	# row still validates, pays no shed and keeps its receipt signature.
	var has_shed := host_event.size() == keys.size() + 2 and host_event.has("realm") and host_event.has("shed")
	if host_event.size() != keys.size() and not has_shed: return _refuse("invalid_defeat_event")
	for key: String in keys:
		if not host_event.has(key): return _refuse("invalid_defeat_event")
	if has_shed and (not host_event.realm is String or not _shed_outputs_valid(host_event.shed)):
		return _refuse("invalid_defeat_event")
	for key: String in ["event_id", "world_namespace", "encounter_id"]:
		if not _opaque_id(host_event[key]): return _refuse("invalid_defeat_identity")
	for key: String in ["enemy_uid", "active_uid"]:
		if not _component(host_event[key]): return _refuse("invalid_defeat_identity")
	if host_event.kind != "wild_defeat" or not host_event.xp_mode in ["ordinary", "hybrid"] \
			or not host_event.enemy_record is Dictionary \
			or host_event.enemy_record.get("uid") != host_event.enemy_uid \
			or not host_event.enemy_record.get("fainted") is bool \
			or host_event.enemy_record.get("fainted") != true \
			or not _integer(host_event.enemy_record.get("hp"), 0, 0) \
			or not _integer(host_event.enemy_record.get("level"), 1, 100) \
			or not host_event.eligible_uids is Array: return _refuse("not_actual_wild_defeat")
	var eligible: Array[String] = []
	var seen: Dictionary = {}
	for uid: Variant in host_event.eligible_uids:
		if not _component(uid) or seen.has(uid):
			return _refuse("invalid_defeat_participants")
		seen[uid] = true
		eligible.append(uid)
	eligible.sort() # Stable same-event signature despite caller array order.
	var types := _species_types(host_event.enemy_record)
	if types.is_empty() or eligible.is_empty():
		return _refuse("invalid_defeat_participants")
	var prefix := "defeat:%s:%s:" % [character_id, _defeat_action_component(host_event.world_namespace, host_event.event_id)]
	var receipt := defeat_receipt(character_id, host_event)
	var duplicate := false
	for old: String in admitted.redesign_character.transaction_receipts:
		if not old.begins_with(prefix): continue
		if duplicate or old != receipt: return _refuse("receipt_conflict")
		duplicate = true
	if duplicate:
		return {"ok": true, "duplicate": true, "receipt": receipt, "expected_character_revision": character_revision}
	if _owned_index(admitted, host_event.enemy_uid) >= 0: return _refuse("owned_enemy_refused")
	if _owned_index(admitted, host_event.active_uid) < 0: return _refuse("invalid_defeat_active_uid")
	for uid: String in eligible:
		if _owned_index(admitted, uid) < 0: return _refuse("invalid_defeat_participants")
	if admitted.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts):
		return _refuse("receipt_budget")
	var caps: Dictionary = {}
	for uid: String in eligible:
		caps[uid] = creature_cap(admitted.redesign_character, uid)
	var xp := PROGRESSION.staged_combat_party_xp(admitted.party, host_event.active_uid,
		eligible, caps, int(host_event.enemy_record.level), progression_cfg, cfg, host_event.xp_mode, _canonical_trait_maximum.bind(admitted.redesign_character.creatures))
	if xp.is_empty(): return _refuse("invalid_defeat_XP_or_cap")
	var payout := defeat_payout(host_event.enemy_record, cfg)
	if payout.is_empty(): return _refuse("invalid_defeat_payout")
	var inventory := RULES.inventory_from(admitted.inventory)
	for stack: Dictionary in payout:
		if not RULES.db().has(str(stack.id)) or inventory.add(str(stack.id), int(stack.n)) != 0:
			return _refuse("inventory_full")
	var shed_outputs: Dictionary = (host_event.shed as Dictionary).duplicate(true) if has_shed else {}
	if not shed_outputs.is_empty():
		var with_shed := RULES.inventory_from(RULES.slots(inventory))
		for item: String in shed_outputs:
			if not RULES.db().has(item) or with_shed.add(item, int(shed_outputs[item])) != 0:
				shed_outputs = {} # Never refuse the victory XP/essence for a full bag.
				break
		if not shed_outputs.is_empty(): inventory = with_shed
	var next := admitted.duplicate(true)
	next.party = xp.party.duplicate(true)
	next.inventory = RULES.slots(inventory).duplicate(true)
	next.redesign_character.transaction_receipts.append(receipt)
	# The foundation owner must admit the explicit defeat namespace; never
	# disguise defeat XP as an Altar spend or bypass REDESIGN validation.
	if not _baseline_errors(next, character_id).is_empty(): return _refuse("defeat_schema_or_candidate_unavailable")
	return {"ok": true, "duplicate": false, "before": admitted.duplicate(true), "state": next,
		"expected_character_revision": character_revision, "receipt": receipt,
		"payout": payout, "xp_awards": xp.awards.duplicate(true), "shed_outputs": shed_outputs.duplicate(true)}


## The one personal receipt a validated host wild defeat event earns this
## character (stage_defeat). Retained guest duties use it to recognise an
## already-applied event without restaging.
static func defeat_receipt(character_id: String, host_event: Dictionary) -> String:
	var eligible: Array = (host_event.get("eligible_uids", []) as Array).duplicate()
	eligible.sort()
	var signature := JSON.stringify([host_event.world_namespace, host_event.encounter_id,
		host_event.enemy_uid, host_event.enemy_record.species_id, host_event.enemy_record.level,
		_species_types(host_event.enemy_record), host_event.active_uid, eligible, host_event.xp_mode]).sha256_text()
	return "defeat:%s:%s:" % [character_id, _defeat_action_component(host_event.world_namespace, host_event.event_id)] + signature


## F32#4 win shed for one participant of one host wild defeat. The roll is
## derived from host identity only, so retries and row recompute reproduce
## it; the defeat receipt above makes the whole candidate once-only.
static func _shed_outputs_valid(raw: Variant) -> bool:
	if not raw is Dictionary or raw.size() > 8: return false
	for item: Variant in raw:
		if not _component(item) or not RULES.db().has(str(item)) or not _integer(raw[item], 1, 99): return false
	return true


static func defeat_shed(host_event: Dictionary, character_id: String) -> Dictionary:
	var shed := preload("res://scripts/world/shed_drop_rules.gd")
	var runtime: Variant = DATA.json("res://data/config/f32_runtime.json")
	if not runtime is Dictionary or runtime.get("runtime_enabled") != true: return {}
	var digest := JSON.stringify([host_event.world_namespace, host_event.event_id, host_event.enemy_uid, character_id]).sha256_text()
	var roll := float(("0x" + digest.substr(0, 8)).hex_to_int()) / 4294967296.0
	var outcome := {"world_instance_id": host_event.world_namespace, "encounter_id": host_event.encounter_id,
		"realm": str(host_event.get("realm", "")), "kind": "wild", "won": true, "settled": true, "participants": [character_id],
		"defeated": [{"uid": host_event.enemy_uid, "species": host_event.enemy_record.species_id}]}
	var candidate: Dictionary = shed.wild_win_candidate(outcome, character_id, {}, {host_event.enemy_uid: roll}, shed.read())
	return (candidate.outputs as Dictionary).duplicate(true) if candidate.get("ok") == true else {}


static func stage_core_defeat(admitted: Dictionary, character_id: String, host_event: Dictionary,
		host_revision: int, cfg: Dictionary, progression_cfg: Dictionary,
		available_moves: Callable, mirror_provider: Callable) -> Dictionary:
	var proposal := stage_defeat(admitted, character_id, host_event, host_revision, cfg, progression_cfg)
	if not bool(proposal.get("ok", false)) or bool(proposal.get("duplicate", false)): return proposal
	var refreshed := refresh_training_moves(proposal.state, available_moves, mirror_provider)
	if refreshed.is_empty() or not _baseline_errors(refreshed, character_id).is_empty():
		return _refuse("canonical_power_refresh_unavailable")
	proposal.state = refreshed
	return proposal


const TRAINING_KIND := "creature_training"
const TRAINING_ROW_FIELDS := ["version", "kind", "delivery_id", "world_id", "world_namespace",
	"session_id", "character_id", "action", "action_id", "intent", "before", "after",
	"receipt", "character_revision", "journal_revision", "status"]


## Latest absolute settlement per character, using the EXISTING world reward
## carrier. Old action receipts stay in the canonical character journal.
static func training_delivery_id(world_namespace: String, character_id: String) -> String:
	if not _opaque_id(world_namespace) or not _component(character_id): return ""
	return TRAINING_KIND + ":" + JSON.stringify([world_namespace, character_id]).sha256_text()


static func training_row_valid(raw: Variant, character_id: String = "", world_namespace: String = "") -> bool:
	if not raw is Dictionary or raw.size() != TRAINING_ROW_FIELDS.size(): return false
	for field: String in TRAINING_ROW_FIELDS:
		if not raw.has(field): return false
	if raw.kind != TRAINING_KIND or not _integer(raw.version, 1, 1) \
			or not raw.action in ["altar_spend", "wild_defeat"] or not raw.status in ["pending", "accepted"] \
			or not _integer(raw.character_revision, 1, 2147483647) \
			or not _integer(raw.journal_revision, 1, 2147483647): return false
	for field: String in ["world_id", "world_namespace", "session_id"]:
		if not _opaque_id(raw[field]): return false
	if not _component(raw.character_id): return false
	if raw.action == "altar_spend":
		if not _component(raw.action_id): return false
	elif not _opaque_id(raw.action_id): return false
	if not character_id.is_empty() and raw.character_id != character_id: return false
	if not world_namespace.is_empty() and raw.world_namespace != world_namespace: return false
	if raw.delivery_id != training_delivery_id(raw.world_namespace, raw.character_id) \
			or not raw.intent is Dictionary or not raw.receipt is String: return false
	var component: String = raw.action_id if raw.action == "altar_spend" else _defeat_action_component(raw.world_namespace, raw.action_id)
	var prefix := ("essence_spend" if raw.action == "altar_spend" else "defeat") + ":%s:%s:" % [raw.character_id, component]
	if not raw.receipt.begins_with(prefix): return false
	for field: String in ["before", "after"]:
		var projection: Variant = raw[field]
		if not projection is Dictionary or projection.size() != 3 \
				or not projection.get("party") is Array or not projection.get("inventory") is Array \
				or not projection.get("redesign_character") is Dictionary: return false
		var candidate: Dictionary = projection.duplicate(true)
		candidate["character_id"] = raw.character_id
		if not _baseline_errors(candidate, raw.character_id).is_empty(): return false
	return STATE.uids(raw.before.party) == STATE.uids(raw.after.party) \
		and not raw.before.redesign_character.transaction_receipts.has(raw.receipt) \
		and raw.after.redesign_character.transaction_receipts.has(raw.receipt)


## Owner/world validators reconstruct the typed operation, including exact
## ingredients, level math, caps and known moves; they never import a packet's
## numerical balance or arbitrary roster replacement as an accepted delta.
static func training_transition_valid(raw: Variant, cfg: Dictionary, progression_cfg: Dictionary,
		available_moves: Callable, mirror_provider: Callable) -> bool:
	if not training_row_valid(raw): return false
	var baseline: Dictionary = raw.before.duplicate(true)
	baseline["character_id"] = raw.character_id
	var proposal: Dictionary = {}
	if raw.action == "altar_spend":
		if raw.intent.get("spend_id") != raw.action_id \
				or not _equivalent(raw.intent.get("expected_character_revision"), int(raw.character_revision) - 1): return false
		proposal = stage_core_spend(baseline, raw.character_id, int(raw.character_revision) - 1,
			raw.intent, cfg, progression_cfg, available_moves, mirror_provider)
	else:
		if raw.intent.get("event_id") != raw.action_id or raw.intent.get("world_namespace") != raw.world_namespace: return false
		proposal = stage_core_defeat(baseline, raw.character_id, raw.intent, int(raw.character_revision) - 1,
			cfg, progression_cfg, available_moves, mirror_provider)
	return proposal.get("ok") == true and proposal.get("duplicate") == false \
		and proposal.get("receipt") == raw.receipt and proposal.get("state") is Dictionary \
		and _equivalent(training_projection(proposal.state), raw.after)


## Frozen registry output only, fetched by its private stage token. Never
## call this with a client's proposed snapshot. The prepared ledger writer
## owns matching host world identity and bool SaveWorld; this constructs data.
static func next_training_delivery(world_id: String, world_namespace: String, session_id: String,
		accepted: Dictionary, previous: Variant, cfg: Dictionary, progression_cfg: Dictionary,
		available_moves: Callable, mirror_provider: Callable) -> Dictionary:
	var character: Variant = accepted.get("character_id")
	if not _component(character) or not _integer(accepted.get("character_revision"), 1, 2147483647) \
			or not accepted.get("before") is Dictionary or not accepted.get("state") is Dictionary \
			or not accepted.get("intent") is Dictionary: return {}
	var journal_revision := 1
	if previous != null:
		# The latest row may be any version (a v2/v3 action, e.g. this host's
		# own research duty); it only orders this one. Validate it as its own kind.
		if not load("res://autoload/world_state.gd").call("training_row_valid", previous, world_namespace, world_id) \
				or previous.get("character_id") != character \
				or previous.status != "accepted" or int(previous.character_revision) >= int(accepted.character_revision): return {}
		journal_revision = int(previous.journal_revision) + 1
	var row := {"version": 1, "kind": TRAINING_KIND, "delivery_id": training_delivery_id(world_namespace, character),
		"world_id": world_id, "world_namespace": world_namespace, "session_id": session_id,
		"character_id": character, "action": accepted.get("action"), "action_id": accepted.get("action_id"),
		"intent": accepted.intent.duplicate(true), "before": training_projection(accepted.before),
		"after": training_projection(accepted.state), "receipt": accepted.get("receipt"),
		"character_revision": int(accepted.character_revision), "journal_revision": journal_revision, "status": "pending"}
	return row if training_transition_valid(row, cfg, progression_cfg, available_moves, mirror_provider) else {}


## Prepared owner candidate. The caller first validates the host sender/world,
## finishes fallback, freezes actual owner state and later uses bool SaveCharacter.
## The already canonical action receipt is the atomic application marker; no
## parallel balance/roster/seed escrow is added. An applied marker still needs
## a real successful owner save before any ACK, including duplicate delivery.
static func stage_training_owner(actual_owner: Dictionary, incoming: Dictionary,
		cfg: Dictionary, progression_cfg: Dictionary, available_moves: Callable,
		mirror_provider: Callable) -> Dictionary:
	var character: Variant = actual_owner.get("character_id")
	if not _component(character) or not training_row_valid(incoming, character) \
			or not training_transition_valid(incoming, cfg, progression_cfg, available_moves, mirror_provider):
		return _refuse("invalid_training_delivery")
	if not _baseline_errors(actual_owner, character).is_empty(): return _refuse("invalid_owner_baseline")
	var current := training_projection(actual_owner)
	var applied: bool = actual_owner.redesign_character.transaction_receipts.has(incoming.receipt)
	# The owner's five keep accruing passive care (owner_passive_replay
	# PASSIVE_FIELDS) between the host's stage, the owner save and a reload
	# or rejoin. That drift is not a conflicting transaction; comparing it
	# exactly stalled every reconnecting guest with a pending/saved row.
	if applied:
		if not _equivalent(_without_passive(current), _without_passive(incoming.after)):
			return _refuse("training_marker_state_conflict")
		return {"ok": true, "duplicate": true, "state": actual_owner.duplicate(true),
			"requires_owner_save": true, "receipt": incoming.receipt, "journal_revision": incoming.journal_revision}
	if incoming.status != "pending": return _refuse("accepted_training_history_is_not_a_new_award")
	if not _equivalent(_without_passive(current), _without_passive(incoming.before)):
		return _refuse("training_owner_baseline_conflict")
	var next := actual_owner.duplicate(true)
	for field: String in ["party", "inventory", "redesign_character"]:
		next[field] = incoming.after[field].duplicate(true)
	return {"ok": true, "duplicate": false, "state": next, "before": actual_owner.duplicate(true),
		"requires_owner_save": true, "receipt": incoming.receipt, "journal_revision": incoming.journal_revision}


## Mirrors owner_passive_replay.PASSIVE_FIELDS (which preloads this file, so
## it cannot be preloaded here); test_f27_essence_rules pins the two equal.
const PASSIVE_CARE_FIELDS := ["nourishment", "happiness", "rested_seconds_left", "rested", "distance_m_together", "landmarks_visited_together"]

## Owner record vs an accepted training row, ignoring only passive care that
## keeps accruing between the host's stage, the owner save and a rejoin.
static func owner_matches_after(projection: Variant, after: Variant) -> bool:
	return projection is Dictionary and after is Dictionary \
		and _equivalent(_without_passive(projection), _without_passive(after))


## Training projection with each party card's passive-care fields removed.
static func _without_passive(projection: Dictionary) -> Dictionary:
	var stripped := projection.duplicate(true)
	if stripped.get("party") is Array:
		for card: Variant in stripped.party:
			if card is Dictionary:
				for field: String in PASSIVE_CARE_FIELDS: card.erase(field)
	return stripped


## Production owner path built on neutral c023's prepared bool writer. Shared
## Session retry/snapshot guards must exist before activation; missing doors
## refuse before any live mutation. Existing creature instances survive the
## update, so active bodies and UI references are never replaced by a new party.
static func apply_training_owner(game: Node, incoming: Dictionary,
		available_moves: Callable, mirror_provider: Callable) -> Dictionary:
	if game == null: return _refuse("owner_game_unavailable")
	var saver: Variant = game.get("save_system")
	if not saver is Object or not saver.has_method("finish_fallback") \
			or not saver.has_method("fallback_busy") or not saver.has_method("save_character_prepared"):
		return _refuse("prepared_owner_writer_missing")
	saver.call("finish_fallback") # Reentrant completion comes BEFORE freezing.
	if saver.call("fallback_busy") == true: return _refuse("fallback_busy")
	var player: Variant = game.get("local")
	var world: Variant = game.get("world")
	var session: Variant = game.get("session")
	if not player is RefCounted or not world is RefCounted or not session is Node:
		return _refuse("owner_context_missing")
	for method: String in ["_retain_owner_training_retry", "_mark_owner_training_saved", "_begin_owner_training_install", "_end_owner_training_install"]:
		if not session.has_method(method): return _refuse("owner_training_retry_unavailable")
	if not player.has_method("save_data"): return _refuse("owner_snapshot_unavailable")
	var deliveries: Variant = world.get("reward_deliveries")
	if not deliveries is Dictionary: return _refuse("owner_world_journal_unavailable")
	var character := str(player.get("character_id"))
	var world_namespace := str(world.get("reward_delivery_namespace"))
	if not training_row_valid(incoming, character, world_namespace) \
			or incoming.world_id != world.get("world_id") \
			or not _equivalent(deliveries.get(incoming.delivery_id), incoming):
		return _refuse("foreign_or_superseded_training")
	var snapshot: Variant = player.call("save_data")
	if not snapshot is Dictionary: return _refuse("owner_snapshot_unavailable")
	var proposal := stage_training_owner(snapshot, incoming, config(), PROGRESSION.config(),
		available_moves, mirror_provider)
	if proposal.get("ok") != true: return proposal
	var party: Variant = player.get("party")
	var inventory: Variant = player.get("inventory")
	if not party is RefCounted or not party.has_method("members") \
			or not inventory is RefCounted or not inventory.has_method("set_slot"):
		return _refuse("owner_transients_unavailable")
	var members: Variant = party.call("members")
	if not members is Array or members.size() != incoming.after.party.size(): return _refuse("owner_party_changed")
	for index: int in members.size():
		if not members[index] is RefCounted or members[index].get("uid") != incoming.after.party[index].uid:
			return _refuse("owner_party_changed")
	if session.call("_retain_owner_training_retry", player, world, incoming) != true:
		return _refuse("owner_training_retry_refused")
	if session.call("_begin_owner_training_install", player, world, incoming) != true:
		return _refuse("owner_training_install_refused")
	if proposal.get("duplicate") != true:
		# No yield, signal or snapshot replacement between these scalar updates.
		# The retained retry guard rejects any half-installed ordinary autosave.
		for index: int in members.size():
			var creature: RefCounted = members[index]
			var row: Dictionary = incoming.after.party[index]
			for field: String in ["level", "xp", "levels_gained_with_you", "battles_fought"]:
				creature.set(field, int(row[field]))
			for field: String in ["max_hp", "hp", "attack", "defence", "happiness"]:
				creature.set(field, float(row[field]))
			var known: Array[String] = []
			for move: String in row.known_moves: known.append(move)
			creature.set("known_moves", known)
		for slot: int in incoming.after.inventory.size():
			var stack: Variant = incoming.after.inventory[slot]
			if not _equivalent(snapshot.inventory[slot], stack):
				inventory.call("set_slot", slot, stack.duplicate(true) if stack is Dictionary else null)
		player.set("redesign_character", incoming.after.redesign_character.duplicate(true))
	session.call("_end_owner_training_install")
	var installed: Variant = player.call("save_data")
	# The owner keeps its own passive care (owner_passive_replay is its
	# authority); everything else must equal the accepted row exactly.
	if not installed is Dictionary or not owner_matches_after(training_projection(installed), incoming.after):
		return {"ok": false, "code": "owner_training_install_conflict", "pending": true}
	if saver.call("save_character_prepared", game, character) != true:
		# World acceptance stays earned; keep the exact in-memory state/receipt
		# locked for a real bool-write retry instead of refunding durable rewards.
		return {"ok": false, "code": "owner_training_save_failed", "pending": true,
			"delivery_id": incoming.delivery_id, "journal_revision": incoming.journal_revision}
	# This marks the real writer complete, but MUST retain the mutation/readiness
	# guard until the host confirms its durable accepted row. Losing an ACK
	# cannot let a care tick or a second action destroy the frozen retry baseline.
	if game.get("local") != player or game.get("world") != world \
			or not _equivalent(world.get("reward_deliveries").get(incoming.delivery_id), incoming) \
			or session.call("_mark_owner_training_saved", player, world, incoming) != true:
		return {"ok": false, "code": "owner_training_context_changed", "saved": true, "pending": true}
	return {"ok": true, "duplicate": proposal.get("duplicate") == true, "saved": true,
		"character_revision": incoming.character_revision, "journal_revision": incoming.journal_revision,
		"action": incoming.action, "action_id": incoming.action_id, "receipt": incoming.receipt,
		"delivery_id": incoming.delivery_id}


## Typed immutable stage identity for the foundation-owned registry extension.
## This method never receives a proposed client state or numeric item cost.
## Fallback must finish before the Session owner enters this synchronous arm.
static func commit_host_training(registry: RefCounted, prepared_writer: Node, peer_id: int,
		character_id: String, action: String, action_id: String, intent: Dictionary, proposal: Dictionary) -> Dictionary:
	if registry == null or prepared_writer == null or peer_id < 1 or not _component(character_id) \
			or not _opaque_id(action_id) or not action in ["altar_spend", "wild_defeat"]:
		return _refuse("invalid_training_commit")
	for method: String in ["stage_creature_training", "staged_creature_training", "finish_creature_training"]:
		if not registry.has_method(method): return _refuse("training_registry_unavailable")
	if not prepared_writer.has_method("journal_creature_training_prepared"):
		return _refuse("training_writer_unavailable")
	if not bool(proposal.get("ok", false)): return proposal.duplicate(true)
	if bool(proposal.get("duplicate", false)):
		# An admitted receipt alone is not an owner-save ACK. Reconcile the
		# existing durable world decision, never acknowledge optimistically.
		return {"ok": true, "duplicate": true, "resolved": false, "pending_owner_save": true,
			"receipt": proposal.get("receipt", ""), "code": "reconcile_training_decision"}
	if not proposal.get("before") is Dictionary or not proposal.get("state") is Dictionary \
			or not proposal.get("receipt") is String \
			or not _integer(proposal.get("expected_character_revision"), 0, 2147483646):
		return _refuse("invalid_training_proposal")
	var stage: Dictionary = registry.call("stage_creature_training", character_id, action, action_id,
		int(proposal.expected_character_revision), intent, proposal.before, proposal.state, proposal.receipt)
	if not bool(stage.get("ok", false)): return stage
	if bool(stage.get("duplicate", false)):
		stage["resolved"] = false
		stage["pending_owner_save"] = true
		return stage
	var accepted: Variant = registry.call("staged_creature_training", stage)
	if not accepted is Dictionary or accepted.is_empty():
		registry.call("finish_creature_training", stage, false)
		return _refuse("training_stage_unavailable")
	var journal: Variant = prepared_writer.call("journal_creature_training_prepared", peer_id, character_id, accepted)
	var saved: Variant = journal is Dictionary and journal.get("ok") == true and journal.get("durable") == true
	if not bool(registry.call("finish_creature_training", stage, saved)):
		return {"ok": false, "code": "training_stage_changed", "durable": saved, "resolved": false}
	if not saved:
		return journal if journal is Dictionary else _refuse("training_journal_failed")
	stage.erase("token")
	stage["durable"] = true
	stage["resolved"] = false
	stage["pending_owner_save"] = true
	stage["delivery_id"] = journal.get("delivery_id", "")
	return stage


## Amount only; the encounter owner proves wild defeat, participants and the
## existing defeat event id, then stages payout with that event's XP once.
static func defeat_payout(defeated: Dictionary, cfg: Dictionary) -> Array[Dictionary]:
	if not configuration_errors(cfg).is_empty() or not _integer(defeated.get("level"), 1, 100): return []
	var types := _species_types(defeated)
	if types.is_empty(): return []
	var bonus := int(floorf(float(defeated.level) / float(cfg.defeat_bonus_level_interval)))
	var amount := int(cfg.defeat_essence_base) + bonus
	return _split_payout(types, amount)


static func _split_payout(types: Array[String], total: int) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if types.is_empty() or types.size() > 2 or total < 1 or total > 2147483647: return output
	var half := int(floorf(float(total) / 2.0))
	for index: int in types.size():
		var amount := total if types.size() == 1 else (total - half if index == 0 else half)
		if amount > 0: output.append({"id": essence_item(types[index]), "n": amount})
	return output


static func release_payout(owned: Dictionary, cfg: Dictionary) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if not configuration_errors(cfg).is_empty() or not _integer(owned.get("level"), 1, 100): return output
	var types := _species_types(owned)
	if types.is_empty(): return output
	var raw_total := float(cfg.release_essence_base) + float(cfg.release_essence_per_level) * float(owned.level)
	if not is_finite(raw_total) or raw_total < 1.0 or raw_total > 2147483647: return output
	return _split_payout(types, int(floorf(raw_total)))


## The Den owner proves the actual grooming action and supplies the host's
## in-game day. No client day/event/care entitlement is accepted by this helper.
## Promote with the existing grooming receipt in the SAME character transaction.
static func stage_care(admitted: Dictionary, character_id: String, uid: String,
		host_day: int, character_revision: int, cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _integer(host_day, 0, 2147483647) or not _component(uid) \
			or not _baseline_errors(admitted, character_id).is_empty() or not configuration_errors(cfg).is_empty():
		return _refuse("invalid_care")
	var day_prefix := "care:%s:%d:" % [character_id, host_day]
	var already_awarded := 0
	var duplicate_receipt := ""
	var seen_uids: Dictionary = {}
	for previous: String in admitted.redesign_character.transaction_receipts:
		if not previous.begins_with(day_prefix): continue
		var parts := previous.split(":")
		if parts.size() != 5 or not _component(parts[3]) or not parts[4].is_valid_int() \
				or not _integer(int(parts[4]), 1, 2147483647) or seen_uids.has(parts[3]):
			return _refuse("receipt_conflict")
		seen_uids[parts[3]] = true
		already_awarded += int(parts[4])
		if parts[3] == uid: duplicate_receipt = previous
	if not duplicate_receipt.is_empty():
		return {"ok": true, "duplicate": true, "receipt": duplicate_receipt, "expected_character_revision": character_revision}
	var index := _owned_index(admitted, uid)
	if index < 0: return _refuse("not_owned")
	var amount := mini(int(cfg.care_per_grooming), int(cfg.care_daily_character_cap) - already_awarded)
	if amount <= 0: return _refuse("daily_care_cap")
	if admitted.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts):
		return _refuse("receipt_budget")
	var types := _species_types(admitted.party[index])
	var payout := _split_payout(types, amount)
	if payout.is_empty(): return _refuse("invalid_payout")
	var inventory := RULES.inventory_from(admitted.inventory)
	for stack: Dictionary in payout:
		if int(inventory.add(str(stack.id), int(stack.n))) != 0: return _refuse("inventory_full")
	var next := admitted.duplicate(true)
	next.inventory = RULES.slots(inventory).duplicate(true)
	var receipt := day_prefix + "%s:%d" % [uid, amount]
	next.redesign_character.transaction_receipts.append(receipt)
	if not _baseline_errors(next, character_id).is_empty(): return _refuse("invalid_candidate")
	return {"ok": true, "duplicate": false, "expected_character_revision": character_revision,
		"creature_uid": uid, "receipt": receipt, "payout": payout, "host_day": host_day,
		"state": next, "before": admitted.duplicate(true), "daily_care_awarded": already_awarded + amount}


## Only host-held owned UIDs qualify here; the host ceremony also validates
## actual release eligibility. Declining a volunteer or a pending sixth is not
## a release entitlement. The host capture/ceremony transaction
## must perform any accepted replacement with this same staged record before
## promotion; this function never manufactures that replacement or a sixth.
static func stage_release(admitted: Dictionary, character_id: String, uid: String,
		character_revision: int, cfg: Dictionary) -> Dictionary:
	if character_revision < 0 or not _component(uid) or not _baseline_errors(admitted, character_id).is_empty() \
			or not configuration_errors(cfg).is_empty(): return _refuse("invalid_release")
	var receipt := "release:" + uid
	if admitted.redesign_character.release_receipts.has(receipt):
		return {"ok": true, "duplicate": true, "receipt": receipt, "expected_character_revision": character_revision}
	var index := _owned_index(admitted, uid)
	if index < 0: return _refuse("not_owned")
	var payout := release_payout(admitted.party[index], cfg)
	if payout.is_empty(): return _refuse("invalid_payout")
	if admitted.redesign_character.release_receipts.size() >= int(cfg.maximum_release_receipts) \
			or admitted.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts):
		return _refuse("receipt_budget")
	var inventory := RULES.inventory_from(admitted.inventory)
	for stack: Dictionary in payout:
		if int(inventory.add(str(stack.id), int(stack.n))) != 0: return _refuse("inventory_full")
	var next := admitted.duplicate(true)
	next.party.remove_at(index)
	next.inventory = RULES.slots(inventory).duplicate(true)
	next.redesign_character.creatures.erase(uid)
	next.redesign_character.release_receipts.append(receipt)
	next.redesign_character.transaction_receipts.append(receipt)
	if not _baseline_errors(next, character_id).is_empty(): return _refuse("invalid_candidate")
	return {"ok": true, "duplicate": false, "expected_character_revision": character_revision,
		"creature_uid": uid, "receipt": receipt, "payout": payout,
		"state": next, "before": admitted.duplicate(true), "released": admitted.party[index].duplicate(true)}


static func _refuse(code: String) -> Dictionary:
	return {"ok": false, "code": code}


## Only an explicitly initialized canonical UID mirror activates new stat
## math. Old V1 rows keep their original arithmetic and exact saved HP.
static func _canonical_trait_maximum(card: Dictionary, base: float, records: Dictionary) -> float:
	var record: Variant = records.get(str(card.get("uid", "")))
	if not record is Dictionary or record.get("traits_initialized") != true: return base
	var traits := preload("res://scripts/creatures/traits.gd")
	if not traits.trait_state_errors(record).is_empty(): return -1.0
	var snapshot := card.duplicate(true)
	snapshot.merge(record, true)
	return traits.apply_value(snapshot, "max_hp", base)
