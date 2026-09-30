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
		if raw is Dictionary and raw.get("species") is Dictionary: _species = raw.species
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
	var mirror: Variant = personal.get("creatures", {}).get(uid, {})
	var cap: Variant = mirror.get("cap_level", 10) if mirror is Dictionary else null
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
		if parts.size() != 7 or parts[3] != uid or parts[4] != str(expected_level) \
				or parts[5] != payment_item or not parts[6].is_valid_int() or int(parts[6]) < 1:
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
	var next_row := PROGRESSION.staged_next_level(owned, cap, progression_cfg)
	if next_row.is_empty(): return _refuse("invalid_creature")
	var next := admitted.duplicate(true)
	next.party[index] = next_row
	next.inventory = RULES.slots(inventory)
	var receipt := prefix + "%s:%d:%s:%d" % [uid, expected_level, payment_item, cost]
	next.redesign_character.transaction_receipts.append(receipt)
	if not _baseline_errors(next, character_id).is_empty(): return _refuse("invalid_candidate")
	return {"ok": true, "duplicate": false, "expected_character_revision": character_revision,
		"creature_uid": uid, "receipt": receipt, "payment": {"id": payment_item, "n": cost},
		"state": next, "before": admitted.duplicate(true), "old_level": expected_level, "new_level": expected_level + 1}


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
	next.inventory = RULES.slots(inventory)
	next.redesign_character.creatures.erase(uid)
	next.redesign_character.release_receipts.append(receipt)
	next.redesign_character.transaction_receipts.append(receipt)
	if not _baseline_errors(next, character_id).is_empty(): return _refuse("invalid_candidate")
	return {"ok": true, "duplicate": false, "expected_character_revision": character_revision,
		"creature_uid": uid, "receipt": receipt, "payout": payout,
		"state": next, "before": admitted.duplicate(true), "released": admitted.party[index].duplicate(true)}


static func _refuse(code: String) -> Dictionary:
	return {"ok": false, "code": code}
