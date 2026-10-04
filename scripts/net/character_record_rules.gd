extends RefCounted

## The same pure admission/projection contract formerly inside Authority.
## Shared by world/owner codecs to avoid a WorldState/Authority preload cycle.
## No mutable state, second registry, or new admission fields are introduced.
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const REDESIGN := preload("res://scripts/data/redesign_state.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const PORTAL := preload("res://scripts/net/portal_escrow_validation.gd")
const HOME_KEY := preload("res://scripts/net/home_key_action.gd")
const EQUIPMENT := preload("res://scripts/player/player_equipment.gd")
const BIOMES := preload("res://scripts/data/biome_order.gd")
const FIELDS := ["character_id", "party", "redesign_character", "inventory", "portal_escrow", "vitals_escrow", "equipment", "realm_hearts"]

static func portable_projection(personal: Dictionary) -> Dictionary:
	var rows: Dictionary = {}
	var vitals: Dictionary = {}
	var escrow: Variant = personal.get("satchel_escrow", {})
	if escrow is Dictionary:
		for key: Variant in escrow:
			var row: Variant = escrow[key]
			if HOME_KEY.candidate(row):
				# Older reward delivery saved duplicate aliases as settled metadata.
				# Keep the original save intact; aliases are no independent gift debt.
				if key == row.get("delivery_id") and HOME_KEY.is_settled_alias(row, str(personal.get("character_id", ""))):
					continue
				rows[key] = row.duplicate(true)
			if str(key).begins_with(PORTAL.KIND + ":") or (row is Dictionary and row.get("kind") == PORTAL.KIND):
				rows[key] = row.duplicate(true) if row is Dictionary else row
			if str(key).begins_with("actor_vitals:") or (row is Dictionary and row.get("kind") == "actor_vitals"):
				vitals[key] = row.duplicate(true) if row is Dictionary else row
	# A creature's energy is the in-fight move meter. The host tracks it per
	# encounter (encounter_host move_resources) and never reads it from the
	# admitted record, and a guest's own fights change it without telling the
	# host, so it stays out of the portable authority that both sides compare.
	var party: Variant = personal.get("party")
	if party is Array:
		var cards: Array = []
		for card: Variant in party:
			if card is Dictionary and card.has("energy"):
				var trimmed: Dictionary = card.duplicate(true)
				trimmed.erase("energy")
				cards.append(trimmed)
			else:
				cards.append(card)
		party = cards
	return {"character_id": personal.get("character_id"), "party": party,
		"redesign_character": personal.get("redesign_character"), "inventory": personal.get("inventory"),
		"portal_escrow": rows, "vitals_escrow": vitals,
		"equipment": personal.get("equipment", empty_equipment()),
		"realm_hearts": personal.get("realm_hearts", {"active_id": ""})}


## Only the portable codec's legitimate absent-field defaults. A received
## hello must carry both fields explicitly; malformed present values never
## become empty gear or an inactive selection through this projection.
static func empty_equipment() -> Dictionary:
	var slots: Dictionary = {}
	for slot: String in EQUIPMENT.SLOTS:
		slots[slot] = ""
	return slots


static func equipment_errors(raw: Variant) -> Array[String]:
	if not raw is Dictionary or raw.size() != EQUIPMENT.SLOTS.size():
		return ["admitted equipment requires exactly the five personal slots"]
	for slot: String in EQUIPMENT.SLOTS:
		if not raw.has(slot) or not raw[slot] is String:
			return ["invalid admitted equipment slot " + slot]
		var id: String = raw[slot]
		if id.is_empty():
			continue
		var items := RULES.db()
		if not bool(items.call("has", id)):
			return ["unknown admitted equipment " + id]
		var definition: Dictionary = items.call("definition", id)
		if definition.get("kind") != "armor" or definition.get("armor_slot") != slot:
			return ["admitted equipment belongs to another slot"]
		if definition.has("command_pouch_tier"):
			var tier: Variant = definition.command_pouch_tier
			if slot != "backpack" or not (tier is int or tier is float) \
					or not is_finite(float(tier)) or float(tier) != floor(float(tier)) \
					or float(tier) < 1.0 or float(tier) > 4.0:
				return ["invalid authored admitted pouch tier"]
	return []


static func heart_selection_errors(raw: Variant) -> Array[String]:
	if not raw is Dictionary or raw.size() != 1 or not raw.get("active_id") is String:
		return ["admitted realm hearts require only the personal active_id"]
	var id: String = raw.active_id
	if not id.is_empty() and not BIOMES.runtime_ids(false).has(id):
		return ["unknown admitted realm heart selection"]
	return []


static func errors(raw: Variant, expected_character: String) -> Array[String]:
	if not raw is Dictionary or not (raw.size() == FIELDS.size() or (raw.size() == FIELDS.size() - 1 and not raw.has("vitals_escrow"))):
		return ["admission requires the exact portable authority fields"]
	for key: String in FIELDS:
		if key == "vitals_escrow" and not raw.has(key):
			continue # Additive v28 projection; the saved carrier already existed.
		if not raw.has(key):
			return ["missing portable authority field " + key]
	if expected_character.is_empty() or raw.character_id != expected_character:
		return ["portable authority belongs to another character"]
	var failures := TEACHING.admitted_party_errors(raw.party, raw.redesign_character)
	failures.append_array(REDESIGN.validate("character", raw.redesign_character, REDESIGN.uids(raw.party)))
	var normalized := preload("res://scripts/creatures/traits.gd").normalize_admitted(raw)
	if normalized.get("redesign_character") is Dictionary and normalized.redesign_character.get("creatures") is Dictionary:
		for uid: Variant in normalized.redesign_character.creatures:
			failures.append_array(preload("res://scripts/creatures/traits.gd").trait_state_errors(normalized.redesign_character.creatures[uid]))
	failures.append_array(equipment_errors(raw.equipment))
	failures.append_array(heart_selection_errors(raw.realm_hearts))
	if raw.party is Array:
		for row: Variant in raw.party:
			if not row is Dictionary:
				continue # Teaching supplies the row-shape refusal.
			var hp: Variant = row.get("hp")
			var maximum: Variant = row.get("max_hp")
			if not (hp is int or hp is float) or not (maximum is int or maximum is float) \
					or not is_finite(float(hp)) or not is_finite(float(maximum)) or float(maximum) <= 0.0 \
					or float(hp) < 0.0 or float(hp) > float(maximum) or not row.get("fainted") is bool \
					or row.fainted != (float(hp) == 0.0):
				failures.append("invalid admitted creature vitals")
	if not RULES.valid_slots(raw.inventory):
		failures.append("invalid admitted inventory")
	elif raw.inventory.size() != preload("res://autoload/inventory.gd").SLOT_COUNT:
		failures.append("admitted inventory must retain every slot")
	else:
		for stack: Variant in raw.inventory:
			if stack != null and not bool(RULES.db().call("has", str(stack.id))):
				failures.append("unknown admitted item " + str(stack.id))
	if not raw.portal_escrow is Dictionary:
		failures.append("portal escrow must be a typed object")
	else:
		for key: Variant in raw.portal_escrow:
			var row: Variant = raw.portal_escrow[key]
			if HOME_KEY.candidate(row):
				if not HOME_KEY.valid_escrow(row, expected_character) or key != row.get("delivery_id"): failures.append("invalid admitted finite Home Key journal")
				continue
			if not PORTAL.valid_row(row, expected_character) or str(key) != str(row.get("receipt", "")):
				failures.append("invalid admitted portal journal")
	failures.append_array(preload("res://scripts/net/actor_vitals_delivery.gd").escrow_errors(raw.get("vitals_escrow", {}), expected_character))
	return failures




## Preserve the original v1 projection by calling the caller's existing
## canonical function. V2 uses exactly the existing full admission fields.
## Injecting a pure callable here avoids an Essence/record-codec preload cycle.
static func training_version(row: Variant) -> int:
	if not row is Dictionary or row.get("kind") != "creature_training": return 0
	var version: Variant = row.get("version")
	# JSON retains valid integral versions as floats. Array membership is type
	# sensitive, so dispatch by exact numeric value without coercing bad input.
	if not (version is int or version is float) or not is_finite(float(version)) \
			or float(version) != floor(float(version)) or float(version) < 1.0 or float(version) > 3.0: return 0
	return int(version)


static func training_projection(raw: Dictionary, row: Dictionary, legacy: Callable) -> Dictionary:
	if training_version(row) in [2, 3]:
		if raw.size() == FIELDS.size() and raw.has("portal_escrow") and raw.has("vitals_escrow"):
			return raw.duplicate(true)
		return portable_projection(raw)
	return legacy.call(raw) if legacy.is_valid() else {}
