extends RefCounted

## F30 pure rules. Foundation admits identity and commits proposals through
## its existing journal. Neither this helper nor UI grants or saves anything.
const DATA := preload("res://scripts/data/redesign_data.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CONFIG_PATH := "res://data/config/traits.json"
const EFFECTS := ["charged_power", "wind_regen", "defence", "combat_speed", "healing",
	"poise", "cooldown", "burst_cost", "max_hp", "quick_power", "ultimate_power",
	"ride_speed", "swim_speed", "fly_speed"]
static var _config: Dictionary = {}

static func config() -> Dictionary:
	if _config.is_empty():
		var raw: Variant = DATA.json(CONFIG_PATH)
		if raw is Dictionary and configuration_errors(raw).is_empty(): _config = raw
		else: push_error("F30 trait configuration is invalid")
	return _config.duplicate(true)

static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floorf(float(value)) and value >= minimum and value <= maximum

static func component(value: Variant) -> bool:
	return value is String and not value.is_empty() and value.length() <= 128 \
		and value == value.strip_edges() and not value.contains(":") \
		and not value.contains("\n") and not value.contains("\r")

static func configuration_errors(cfg: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not cfg.get("traits") is Dictionary or cfg.traits.size() != 30: return ["expected 30 traits"]
	if not cfg.get("profiles") is Dictionary: return ["expected roll profiles"]
	if not cfg.get("runtime_enabled") is bool: errors.append("invalid runtime activation gate")
	var slots: Variant = cfg.get("slot_breakthrough_tiers")
	var slots_valid: bool = slots is Array and slots.size() == 3
	if slots_valid:
		for index: int in 3:
			# JSON integers arrive as floats. Validate before numeric conversion;
			# Array equality would distinguish the JSON and authored element types.
			if not integer(slots[index],1,5) or int(slots[index]) != 1 + 2 * index:
				slots_valid = false
	if not integer(cfg.get("maximum_rolled"),3,3) or not slots_valid \
		or not integer(cfg.get("bond_reveal_nodes"),5,5): errors.append("invalid roll/bond/slot gates")
	if not integer(cfg.get("essence_cost_per_slot"),1,1000) \
		or not integer(cfg.get("maximum_transaction_receipts"),1,100000): errors.append("invalid costs or receipt budget")
	if not cfg.get("aggregate_effect_limit") is float \
		or not is_finite(cfg.aggregate_effect_limit) or cfg.aggregate_effect_limit <= 0.0 \
		or cfg.aggregate_effect_limit > 0.5: errors.append("invalid aggregate cap")
	for id: Variant in cfg.traits:
		var row: Variant = cfg.traits[id]
		if not component(id) or not row is Dictionary:
			errors.append("invalid trait row")
			continue
		var cap: float = {"common":0.05,"rare":0.08,"epic":0.12}.get(row.get("rarity"),0.0)
		if cap == 0.0 or not row.get("effect") in EFFECTS \
			or not (row.get("magnitude") is float or row.get("magnitude") is int) \
			or not is_finite(float(row.get("magnitude",INF))) \
			or absf(float(row.get("magnitude",INF))) > cap or row.get("magnitude") == 0 \
			or row.get("seed_item") != "trait_seed_" + str(id) \
			or not row.get("description") is String: errors.append("invalid effect %s" % id)
		elif (row.effect in ["cooldown","burst_cost"]) != (float(row.magnitude) < 0.0):
			errors.append("wrong effect direction %s" % id)
	for profile: String in ["ordinary","unusual","alpha","alpha_unusual"]:
		var row: Variant = cfg.get("profiles",{}).get(profile)
		if not row is Dictionary: errors.append("missing roll profile"); continue
		for key: String in ["count_weights","rarity_weights"]:
			var weights: Variant = row.get(key)
			if not weights is Array or weights.size() != (4 if key == "count_weights" else 3):
				errors.append("invalid roll weights"); continue
			var sum := 0.0
			for weight: Variant in weights:
				if not (weight is int or weight is float) or not is_finite(float(weight)) or weight < 0:
					errors.append("invalid roll weight")
				else: sum += float(weight)
			if sum <= 0.0: errors.append("empty roll weights")
	return errors

## Product activation is distinct from durable traits_initialized adoption.
## Pure roll/effect/staging helpers remain usable while live doors are off.
static func runtime_enabled(cfg: Dictionary = {}) -> bool:
	var rules: Dictionary = config() if cfg.is_empty() else cfg
	return rules.get("runtime_enabled") is bool and rules.runtime_enabled == true \
		and configuration_errors(rules).is_empty()

static func definition(id: String, cfg: Dictionary = {}) -> Dictionary:
	var rules := config() if cfg.is_empty() else cfg
	return rules.get("traits",{}).get(id,{}).duplicate(true)

static func _pick(weights: Array, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for value: Variant in weights: total += float(value)
	var ticket := rng.randf() * total
	for index: int in weights.size():
		ticket -= float(weights[index])
		if ticket < 0.0: return index
	return weights.size()-1

## Seed contains the HOST namespace, actual spawn identity and generation.
## Sorting IDs fixes roll order independently of JSON dictionary insertion.
static func roll_spawn(world_namespace: String, spawn_id: String, generation: int,
		alpha: bool, night: bool, weather: bool, cfg: Dictionary = {}) -> Dictionary:
	var rules := config() if cfg.is_empty() else cfg
	if world_namespace.is_empty() or spawn_id.is_empty() or generation < 1 \
		or not configuration_errors(rules).is_empty(): return {}
	var seed_text := JSON.stringify(["F30v1",world_namespace,spawn_id,generation])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_text.sha256_text().substr(0,15).hex_to_int()
	var unusual := night or weather
	var profile := "alpha_unusual" if alpha and unusual else ("alpha" if alpha else ("unusual" if unusual else "ordinary"))
	var weights: Dictionary = rules.profiles[profile]
	var count := _pick(weights.count_weights,rng)
	var candidates: Array = rules.traits.keys()
	candidates.sort()
	var selected: Array[String] = []
	for index: int in count:
		var rarity: String = ["common","rare","epic"][_pick(weights.rarity_weights,rng)]
		var pool: Array[String] = []
		for id: String in candidates:
			if not selected.has(id) and rules.traits[id].rarity == rarity: pool.append(id)
		if pool.is_empty(): return {}
		selected.append(pool[rng.randi_range(0,pool.size()-1)])
	return {"traits_initialized":true,"rolled_traits":selected,"taught_traits":{},
		"captured_from":{"kind":"wild","world_namespace":world_namespace,
			"spawn_id":spawn_id,"spawn_generation":generation}}

static func trait_state_errors(value: Variant, cfg: Dictionary = {}) -> Array[String]:
	var rules := config() if cfg.is_empty() else cfg
	if not value is Dictionary or not value.get("traits_initialized") is bool \
		or not value.get("rolled_traits") is Array or value.rolled_traits.size() > 3 \
		or not value.get("taught_traits") is Dictionary: return ["invalid trait state"]
	var seen: Dictionary = {}
	for id: Variant in value.rolled_traits:
		if not id is String or not rules.get("traits",{}).has(id) or seen.has(id): return ["unknown or duplicate rolled trait"]
		seen[id] = true
	for slot: Variant in value.taught_traits:
		var id: Variant = value.taught_traits[slot]
		if not slot is String or not slot in ["1","2","3"] \
			or not id is String or not rules.get("traits",{}).has(id) or seen.has(id): return ["unknown or duplicate taught trait"]
		seen[id] = true
		if value.has("breakthroughs") and not unlocked_slots(value,rules).has(int(slot)):
			return ["taught trait in locked breakthrough slot"]
	return []

## Legacy primary is adopted once when Foundation materializes an old v28
## creature row. A lawful initialized zero-roll stays empty. Secondary is a
## bond reward, not an additional wild roll, and uses the SAME effect pool.
static func effective_ids(creature: Variant, cfg: Dictionary = {}) -> Array[String]:
	var rules := config() if cfg.is_empty() else cfg
	var result: Array[String] = []
	if creature == null: return result
	var initialized: bool = creature.get("traits_initialized") == true
	if initialized:
		var rolled: Variant = creature.get("rolled_traits")
		var taught: Variant = creature.get("taught_traits")
		if not trait_state_errors({"traits_initialized":true,"rolled_traits":rolled,"taught_traits":taught},rules).is_empty(): return result
		for id: String in rolled: result.append(id)
		for slot: String in ["1","2","3"]:
			if taught.has(slot): result.append(taught[slot])
	else:
		var primary: Variant = creature.get("trait_primary")
		if primary is String and rules.get("traits",{}).has(primary): result.append(primary)
	var secondary := ""
	if creature is Object and creature.has_method("revealed_trait_secondary"):
		secondary = str(creature.call("revealed_trait_secondary",PROGRESSION.config()))
	elif creature is Dictionary:
		var completed := 0
		var bond_rules: Dictionary = preload("res://scripts/creatures/bond_milestones.gd").config()
		for milestone: Dictionary in bond_rules.get("milestones",[]):
			if float(creature.get(str(milestone.get("task","")),0)) >= float(milestone.get("target",INF)):
				completed += 1
		if completed >= int(rules.get("bond_reveal_nodes",5)): secondary = str(creature.get("trait_secondary",""))
	if rules.get("traits",{}).has(secondary) and not result.has(secondary): result.append(secondary)
	return result

## One additive sum per effect, applied once to the already IV/bond-scaled
## baseline. Repeated trait IDs never multiply twice. Caps are configured.
static func multiplier(creature: Variant, effect: String, cfg: Dictionary = {}) -> float:
	var rules := config() if cfg.is_empty() else cfg
	var amount := 0.0
	for id: String in effective_ids(creature,rules):
		var row: Dictionary = rules.traits[id]
		if row.effect == effect: amount += float(row.magnitude)
	var limit := float(rules.get("aggregate_effect_limit",0.30))
	return 1.0 + clampf(amount,-limit,limit)

static func apply_value(creature: Variant, effect: String, baseline: float, cfg: Dictionary = {}) -> float:
	if not is_finite(baseline) or baseline < 0.0: return baseline
	return baseline * multiplier(creature,effect,cfg)

static func unlocked_slots(record: Dictionary, cfg: Dictionary = {}) -> Array[int]:
	var rules := config() if cfg.is_empty() else cfg
	var output: Array[int] = []
	var tiers: Variant = record.get("breakthroughs",[])
	if not tiers is Array or not configuration_errors(rules).is_empty(): return output
	var normalized: Array[int] = []
	for tier: Variant in tiers:
		if not integer(tier,1,9): return output
		normalized.append(int(tier))
	for index: int in 3:
		if normalized.has(int(rules.slot_breakthrough_tiers[index])): output.append(index+1)
	return output

static func _refuse(code: String) -> Dictionary:
	return {"ok":false,"code":code}

static func intent_valid(raw: Variant) -> bool:
	var fields := ["action_id","action","creature_uid","trait_id","slot","payment_item","expected_character_revision"]
	if not raw is Dictionary or raw.size() != fields.size(): return false
	for field: String in fields:
		if not raw.has(field): return false
	if not component(raw.action_id) or not component(raw.creature_uid) \
		or not raw.action in ["teach","release"] \
		or not raw.trait_id is String or (raw.trait_id != "" and not component(raw.trait_id)) \
		or not raw.payment_item is String \
		or not integer(raw.expected_character_revision,0,2147483646): return false
	if raw.action == "release": return raw.slot == -1 and raw.payment_item == ""
	return integer(raw.slot,1,3) and component(raw.payment_item) and component(raw.trait_id)

static func _owned_index(admitted: Dictionary, character_id: String, uid: String) -> int:
	if admitted.get("character_id") != character_id or not component(character_id) \
		or not admitted.get("party") is Array or admitted.party.size() < 1 or admitted.party.size() > 5 \
		or not admitted.get("redesign_character") is Dictionary \
		or not RULES.valid_slots(admitted.get("inventory")) or admitted.inventory.size() != 24: return -1
	var seen: Dictionary = {}
	var found := -1
	for index: int in admitted.party.size():
		var row: Variant = admitted.party[index]
		if not row is Dictionary or not component(row.get("uid")) or seen.has(row.uid): return -1
		seen[row.uid] = true
		if row.uid == uid: found = index
	if not STATE.validate("character",admitted.redesign_character,STATE.uids(admitted.party)).is_empty(): return -1
	return found

static func quote_action(admitted: Dictionary, character_id: String, uid: String,
		character_revision: int, cfg: Dictionary = {}) -> Dictionary:
	var rules := config() if cfg.is_empty() else cfg
	var index := _owned_index(admitted,character_id,uid)
	if index < 0 or character_revision < 0 or not configuration_errors(rules).is_empty(): return _refuse("not_owned")
	var record: Variant = admitted.redesign_character.creatures.get(uid)
	if not trait_state_errors(record,rules).is_empty(): return _refuse("invalid_traits")
	var row: Dictionary = admitted.party[index].duplicate(true)
	row.merge(record,true)
	var bag := RULES.inventory_from(admitted.inventory)
	var seeds: Array[Dictionary] = []
	for id: String in rules.traits:
		var item: String = rules.traits[id].seed_item
		if bag.count(item) > 0 and not effective_ids(row,rules).has(id):
			var seed := definition(id,rules)
			seed["id"] = id
			seed["available"] = bag.count(item)
			seeds.append(seed)
	var payments: Array[String] = []
	var essence: GDScript = load("res://scripts/creatures/essence.gd")
	if essence == null: return _refuse("producer_missing")
	for type_id: String in essence._species_types(row): payments.append("essence_"+type_id)
	return {"ok":true,"creature_uid":uid,"expected_character_revision":character_revision,
		"traits":rows(row,rules),"rolled_traits":record.rolled_traits.duplicate(),
		"taught_traits":record.taught_traits.duplicate(),"unlocked_slots":unlocked_slots(record,rules),
		"seeds":seeds,"payment_items":payments,"essence_cost_per_slot":rules.essence_cost_per_slot,
		"release_allowed":_release_eligible(row,record) and admitted.party.size() > 1}

static func _release_eligible(owned: Dictionary, record: Dictionary) -> bool:
	var source: Variant = record.get("captured_from")
	var species: Dictionary = DATA.json("res://data/creatures/species.json").get("species",{}).get(owned.get("species_id"),{})
	# Canonical provenance is mandatory; species name never proves a catch.
	return source is Dictionary and source.get("kind") == "wild" \
		and source.get("world_namespace") is String and not source.world_namespace.is_empty() \
		and source.get("spawn_id") is String and not source.spawn_id.is_empty() \
		and integer(source.get("spawn_generation"),1,2147483647) \
		and not species.is_empty() and not bool(species.get("starter",false)) \
		and not bool(species.get("legendary",false)) \
		and not owned.get("species_id") in ["terrapup","ripplet","galewisp"]

## Foundation calls after host station + sender/current-generation admission.
## The proposal is immutable baseline -> after, never applied locally. Its
## exact seven-field intent is frozen in the EXISTING journal before commit.
## release is F27 essence payout + chosen seed in ONE UID-keyed transaction.
static func stage_action(admitted: Dictionary, character_id: String, intent: Dictionary,
		character_revision: int, essence_cfg: Dictionary, cfg: Dictionary = {}) -> Dictionary:
	var rules := config() if cfg.is_empty() else cfg
	if not intent_valid(intent) or intent.expected_character_revision != character_revision \
		or not configuration_errors(rules).is_empty(): return _refuse("stale_or_invalid_intent")
	var index := _owned_index(admitted,character_id,intent.creature_uid)
	if index < 0: return _refuse("not_owned")
	var record: Variant = admitted.redesign_character.creatures.get(intent.creature_uid)
	if not trait_state_errors(record,rules).is_empty(): return _refuse("invalid_traits")
	var row: Dictionary = admitted.party[index].duplicate(true)
	row.merge(record,true)
	if intent.trait_id != "" and not rules.traits.has(intent.trait_id): return _refuse("unknown_trait")
	var receipts: Array = admitted.redesign_character.transaction_receipts
	var release_receipt := "release:" + str(intent.creature_uid)
	var teach_prefix := "trait_teach:%s:%s:" % [character_id,intent.action_id]
	# Retried decisions must reconcile the existing journal, including owner
	# bool-save/ACK. A receipt alone never returns success or a fresh award.
	for receipt: String in receipts:
		if (intent.action == "release" and receipt == release_receipt) \
			or (intent.action == "teach" and receipt.begins_with(teach_prefix)):
			return _refuse("reconcile_existing_decision")
	if receipts.size() >= int(rules.maximum_transaction_receipts): return _refuse("receipt_budget")
	var next := admitted.duplicate(true)
	var bag := RULES.inventory_from(admitted.inventory)
	var seed_item := "" if intent.trait_id == "" else str(rules.traits[intent.trait_id].seed_item)
	var receipt := ""
	if intent.action == "teach":
		if not unlocked_slots(record,rules).has(int(intent.slot)): return _refuse("breakthrough_needed")
		if effective_ids(row,rules).has(intent.trait_id): return _refuse("duplicate_trait")
		var essence: GDScript = load("res://scripts/creatures/essence.gd")
		if essence == null: return _refuse("producer_missing")
		var types: Array[String] = essence._species_types(row)
		if not intent.payment_item.begins_with("essence_") \
			or not types.has(intent.payment_item.trim_prefix("essence_")): return _refuse("wrong_essence")
		var cost := int(rules.essence_cost_per_slot) * int(intent.slot)
		if not RULES.db().has(seed_item) or not bag.remove(seed_item,1) \
			or not bag.remove(intent.payment_item,cost): return _refuse("seed_or_essence_missing")
		next.redesign_character.creatures[intent.creature_uid].taught_traits[str(int(intent.slot))] = intent.trait_id
		if not _refresh_max_hp(next.party[index],next.redesign_character.creatures[intent.creature_uid],rules):
			return _refuse("invalid_derived_stats")
		receipt = teach_prefix + "%s:%s:%s:%s:%s" % [intent.creature_uid,intent.slot,intent.trait_id,intent.payment_item,cost]
	else:
		if admitted.party.size() <= 1: return _refuse("last_creature")
		if not _release_eligible(row,record): return _refuse("caught_creature_required")
		if intent.trait_id != "" and not effective_ids(row,rules).has(intent.trait_id): return _refuse("trait_not_revealed")
		var essence: GDScript = load("res://scripts/creatures/essence.gd")
		if essence == null: return _refuse("producer_missing")
		# Use F27's ONE UID receipt/removal/payout proposal. Chosen seed is
		# appended before durable acceptance; never a second release action.
		var release: Dictionary = essence.stage_release(admitted,character_id,intent.creature_uid,character_revision,essence_cfg)
		if release.get("ok") != true: return release
		if release.get("duplicate") == true: return _refuse("reconcile_existing_decision")
		if release.get("before") != admitted or release.get("receipt") != release_receipt \
			or release.get("creature_uid") != intent.creature_uid: return _refuse("release_producer_conflict")
		next = release.state.duplicate(true)
		bag = RULES.inventory_from(next.inventory)
		if seed_item != "" and (not RULES.db().has(seed_item) or bag.add(seed_item,1) != 0): return _refuse("inventory_full")
		receipt = release_receipt
	next.inventory = RULES.slots(bag)
	if intent.action == "teach": next.redesign_character.transaction_receipts.append(receipt)
	return {"ok":true,"duplicate":false,"action":intent.action,"action_id":intent.action_id,
		"character_id":character_id,"expected_character_revision":character_revision,
		"intent":intent.duplicate(true),"before":admitted.duplicate(true),"state":next,"receipt":receipt}

static func _refresh_max_hp(owned: Dictionary, record: Dictionary, cfg: Dictionary) -> bool:
	for field: String in ["base_hp","iv_hp","boost_hp","max_hp","hp"]:
		var raw: Variant = owned.get(field)
		if not (raw is int or raw is float) or not is_finite(float(raw)): return false
	if float(owned.max_hp) <= 0.0 or float(owned.base_hp) <= 0.0: return false
	var progression := PROGRESSION.config()
	var base := PROGRESSION.stat_at_level(float(owned.base_hp),int(owned.level),
		float(progression.get("level",{}).get("growth_per_level",{}).get("hp",0.0))) \
		* PROGRESSION.individuality_multiplier(float(owned.iv_hp),progression) + float(owned.boost_hp)
	var creature := owned.duplicate(true)
	creature.merge(record,true)
	var maximum := apply_value(creature,"max_hp",base,cfg)
	if not is_finite(maximum) or maximum <= 0.0: return false
	var fraction := clampf(float(owned.hp)/float(owned.max_hp),0.0,1.0)
	owned.max_hp = maximum
	owned.hp = maximum*fraction
	return true

static func rows(creature: Variant, cfg: Dictionary = {}) -> Array[Dictionary]:
	var rules := config() if cfg.is_empty() else cfg
	var output: Array[Dictionary] = []
	for id: String in effective_ids(creature,rules):
		var row := definition(id,rules)
		row["id"] = id
		output.append(row)
	return output

## Additive v28 missing-field adoption, executed only in Foundation's
## canonical admission/codec normalization. Never re-roll existing identity.
static func initialize_legacy_record(owned: Dictionary, existing: Dictionary,
		cfg: Dictionary = {}) -> Dictionary:
	var rules := config() if cfg.is_empty() else cfg
	var result := existing.duplicate(true)
	if result.has("traits_initialized"): return result
	if result.has("rolled_traits") and not result.rolled_traits is Array: return result
	var rolled: Array = result.get("rolled_traits",[]).duplicate()
	var primary: Variant = owned.get("trait_primary","")
	if rolled.is_empty() and primary is String and rules.get("traits",{}).has(primary): rolled.append(primary)
	result["traits_initialized"] = true
	result["rolled_traits"] = rolled
	if not result.has("taught_traits"): result["taught_traits"] = {}
	return result

static func normalize_admitted(admitted: Dictionary, cfg: Dictionary = {}) -> Dictionary:
	var output := admitted.duplicate(true)
	if not output.get("party") is Array or not output.get("redesign_character") is Dictionary \
		or not output.redesign_character.get("creatures") is Dictionary: return output
	for owned: Variant in output.party:
		if not owned is Dictionary: continue
		var uid: Variant = owned.get("uid")
		var record: Variant = output.redesign_character.creatures.get(uid)
		if record is Dictionary:
			output.redesign_character.creatures[uid] = initialize_legacy_record(owned,record,cfg)
	return output

## Runtime fields are projections from the single durable per-UID row.
## No repeated max-HP multiplier, no second persisted trait list.
static func project_instance(creature: RefCounted, record: Dictionary) -> bool:
	if creature == null or not trait_state_errors(record).is_empty(): return false
	creature.set("traits_initialized",record.traits_initialized)
	creature.set("rolled_traits",record.rolled_traits.duplicate())
	creature.set("taught_traits",record.taught_traits.duplicate(true))
	return true
