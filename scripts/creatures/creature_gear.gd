extends RefCounted

## F33. Stateless gear rules over the admitted personal record. Session owns
## transport, station identity, revisions, the journal and save/ACK recovery.
## No method here publishes a candidate or mutates a caller's live inventory.
const DATA := preload("res://scripts/data/redesign_data.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const EQUIPMENT := preload("res://scripts/player/player_equipment.gd")
const SLOTS := ["harness", "charm"]

static func config() -> Dictionary:
	var raw: Variant = DATA.json("res://data/config/gear.json")
	return raw if raw is Dictionary else {}

static func empty_slots() -> Dictionary:
	return {"harness": "", "charm": ""}

## Workbench has no attachments. Its regional travel/pouch recipes use the
## personal relic unlock; Forge/Altar also require their paid world attachment.
## The real station producer derives recipe_known from this canonical record.
static func recipe_known(record: Dictionary, recipe: Dictionary, cfg: Dictionary) -> bool:
	if not record.get("redesign_character") is Dictionary:
		return false
	var tier: Variant = recipe.get("personal_gear_tier", recipe.get("station_tier", 0))
	if not _integer(tier, 0, 4):
		return false
	if int(tier) <= 1:
		return true
	var tiers: Array = cfg.get("tiers", [])
	if tiers.size() < int(tier):
		return false
	var required: String = str(tiers[int(tier) - 1].get("unlock_relic", ""))
	return not required.is_empty() and record.get("redesign_character", {}).get("relics_hung", []).has(required)

static func slots_errors(raw: Variant, cfg: Dictionary) -> Array[String]:
	if not raw is Dictionary or raw.size() != SLOTS.size():
		return ["Creature gear requires Harness and Charm slots."]
	for slot: String in SLOTS:
		if not raw.get(slot) is String:
			return ["Invalid creature gear slot."]
		var id: String = raw[slot]
		if id.is_empty():
			continue
		var item: Dictionary = cfg.get("items", {}).get(id, {})
		if item.get("kind") != "creature_gear" or item.get("gear_slot") != slot \
				or not _integer(item.get("gear_tier"), 1, 4) \
				or not _integer(item.get("gear_upgrade"), 0, int(cfg.get("max_upgrade", 3))):
			return ["Unknown or mismatched creature gear."]
	return []

static func personal_errors(record: Dictionary, cfg: Dictionary) -> Array[String]:
	if not record.get("redesign_character") is Dictionary or not record.get("party") is Array:
		return ["Missing canonical creature state."]
	var creatures: Variant = record.get("redesign_character", {}).get("creatures", {})
	if not creatures is Dictionary:
		return ["Missing canonical creature state."]
	var owned: Array[String] = []
	for row: Variant in record.get("party", []):
		if row is Dictionary:
			owned.append(str(row.get("uid", "")))
	var failures: Array[String] = []
	for uid: Variant in creatures:
		if not uid is String or not owned.has(uid) or not creatures[uid] is Dictionary:
			failures.append("Gear belongs to an unowned creature.")
			continue
		# Absence is the additive v28 default; malformed present gear is refused.
		if creatures[uid].has("gear"):
			failures.append_array(slots_errors(creatures[uid].gear, cfg))
	return failures

static func gear_for(record: Dictionary, uid: String) -> Dictionary:
	var personal: Variant = record.get("redesign_character")
	if not personal is Dictionary or not personal.get("creatures") is Dictionary:
		return {}
	var row: Variant = personal.creatures.get(uid, {})
	if not row is Dictionary:
		return {}
	var gear: Variant = row.get("gear", empty_slots())
	return gear.duplicate(true) if gear is Dictionary else {}

## Effective stats receive these once, at host prepare. Charm's move power
## goes into P once at accepted action creation, never attack AND P. Trainer
## equipment is intentionally absent. Missing/invalid gear yields no bonus.
static func modifiers(gear: Variant, cfg: Dictionary) -> Dictionary:
	var result := {"max_hp": 1.0, "defence": 1.0, "move_power": 1.0, "ultimate_gain": 1.0}
	if not slots_errors(gear, cfg).is_empty():
		return result
	for slot: String in SLOTS:
		var item: Dictionary = cfg.get("items", {}).get(gear[slot], {})
		if item.is_empty():
			continue
		var tier: Dictionary = cfg.tiers[int(item.gear_tier) - 1]
		if tier.get("status") != "live":
			continue
		var upgrade_scale := 1.0 + int(item.gear_upgrade) * float(cfg.get("upgrade_bonus_step", 0.0))
		var fields: Array = ["max_hp", "defence"] if slot == "harness" else ["move_power", "ultimate_gain"]
		for field: String in fields:
			var bonus: Variant = tier.get("bonuses", {}).get(field, 0.0)
			if (bonus is int or bonus is float) and is_finite(float(bonus)):
				result[field] = 1.0 + clampf(float(bonus), 0.0, 1.0) * upgrade_scale
	return result

## Base must be freshly prepared from species/level/individuality/bond/traits,
## never a previously geared profile. Preserve HP fraction during gear changes;
## equipping/unequipping cannot heal, revive or compound maximum HP.
static func prepared_stats(base: Dictionary, gear: Dictionary, cfg: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	if not _runtime_enabled(cfg):
		return result
	var mods := modifiers(gear, cfg)
	var maximum := float(base.get("max_hp", 0.0))
	if maximum > 0.0:
		result.max_hp = maximum * float(mods.max_hp)
		result.hp = clampf(float(base.get("hp", 0.0)) / maximum, 0.0, 1.0) * float(result.max_hp)
	if base.has("defence"):
		result.defence = float(base.defence) * float(mods.defence)
	result["gear_move_power_multiplier"] = mods.move_power
	result["gear_ultimate_gain_multiplier"] = mods.ultimate_gain
	return result

## Host invokes once after F23 freezes mastery/breakthroughs for the accepted
## action. Support-only moves keep zero damaging power; no trainer damage.
static func freeze_move_profile(profile: Dictionary, gear: Dictionary, cfg: Dictionary) -> Dictionary:
	var result := profile.duplicate(true)
	if not _runtime_enabled(cfg):
		return result
	var mods := modifiers(gear, cfg)
	result["power_multiplier"] = float(profile.get("power_multiplier", 1.0)) * float(mods.move_power)
	result["gear_ultimate_gain_multiplier"] = mods.ultimate_gain
	return result

## Host prepare adapter over the SAME canonical full record. Portable HP/max
## remain intrinsic. Fresh base must come from the existing host species/level/
## IV/traits facade; an already geared facade is refused to prevent doubling.
static func prepared_actor_inputs(record: Dictionary, character: String, uid: String,
		fresh_base: Dictionary, combat: Dictionary, cfg: Dictionary) -> Dictionary:
	if record.get("character_id") != character or not _owns(record, uid) \
			or not personal_errors(record, cfg).is_empty():
		return _refuse("ownership")
	if fresh_base.has("gear_move_power_multiplier") or fresh_base.has("gear_ultimate_gain_multiplier"):
		return _refuse("already_prepared")
	var intrinsic: Dictionary = {}
	for row: Variant in record.party:
		if row is Dictionary and row.get("uid") == uid:
			intrinsic = row
			break
	if not _finite_number(intrinsic.get("max_hp"), 0.001, INF) \
			or not _finite_number(intrinsic.get("hp"), 0.0, float(intrinsic.max_hp)) \
			or not _finite_number(fresh_base.get("max_hp"), 0.001, INF) \
			or not _finite_number(fresh_base.get("defence"), 0.001, INF) \
			or not is_equal_approx(float(fresh_base.max_hp), float(intrinsic.max_hp)):
		return _refuse("intrinsic_baseline_mismatch")
	var base := fresh_base.duplicate(true)
	base["hp"] = intrinsic.hp
	var gear := gear_for(record, uid)
	var profile := prepared_stats(base, gear, cfg)
	var tuning := combat.duplicate(true)
	if _runtime_enabled(cfg):
		var cap: Variant = cfg.get("limits", {}).get("ultimate_gain_multiplier_cap")
		if not _finite_number(cap, 1.0, INF) or not tuning.get("ultimate") is Dictionary \
				or float(profile.get("gear_ultimate_gain_multiplier", 1.0)) > float(cap):
			return _refuse("invalid_gear_gain")
		tuning.ultimate["gear_gain_multiplier_cap"] = cap
	return {"ok": true, "stats": profile, "gear": gear, "combat_config": tuning,
		"intrinsic_max_hp": intrinsic.max_hp}

## Existing actor-vitals producer uses this within its SAME atomic candidate
## before persisting party HP. Never write geared maxHP into the portable row.
## No storage, receipt or authority is created by this arithmetic conversion.
static func intrinsic_vitals(actor_hp: Variant, prepared_max_hp: Variant,
		intrinsic_max_hp: Variant) -> Dictionary:
	if not _finite_number(prepared_max_hp, 0.001, INF) \
			or not _finite_number(intrinsic_max_hp, 0.001, INF) \
			or not _finite_number(actor_hp, 0.0, float(prepared_max_hp)):
		return _refuse("invalid_actor_vitals")
	var hp := float(actor_hp) / float(prepared_max_hp) * float(intrinsic_max_hp)
	return {"ok": true, "hp": hp, "max_hp": intrinsic_max_hp, "fainted": hp == 0.0}

## COMBAT §3 encounter-time bonus product, including Rally/stagger. Gear is
## already applied to prepared P; it must never also enter this product.
static func encounter_bonus_product(values: Array, combat: Dictionary) -> float:
	var cap := float(combat.get("damage", {}).get("max_bonus_product", 1.6))
	if not is_finite(cap) or cap < 1.0:
		cap = 1.0
	var product := 1.0
	for value: Variant in values:
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0.0:
			return 1.0
		product *= float(value)
	return clampf(product, 0.0, cap)

## Exact packet: {action, action_id, creature_uid, slot, item_id}. Even trainer
## actions carry creature_uid="". IDs do not carry stats, costs or inventories.
## Host context comes from BuildPlacer.station_context(actual paid node), not
## this packet. Replay belongs to Session's immutable journal before restage.
static func stage_core(record: Dictionary, character: String, revision: int,
		intent: Dictionary, context: Dictionary, items: RefCounted,
		cfg: Dictionary) -> Dictionary:
	if not _runtime_enabled(cfg):
		return _refuse("disabled")
	if not record.get("party") is Array or not record.get("redesign_character") is Dictionary \
			or not record.get("inventory") is Array or not record.get("equipment") is Dictionary \
			or not record.redesign_character.get("transaction_receipts") is Array:
		return _refuse("invalid_baseline")
	if record.get("character_id") != character or context.get("character_id") != character:
		return _refuse("ownership")
	if not _integer(revision, 0, 2147483646) or context.get("expected_revision") != revision:
		return _refuse("stale_revision")
	if intent.size() != 5:
		return _refuse("invalid_intent")
	for key: String in ["action", "action_id", "creature_uid", "slot", "item_id"]:
		if not intent.get(key) is String:
			return _refuse("invalid_intent")
	if not _action_id(intent.action_id):
		return _refuse("invalid_intent")
	if context.get("homestead") != true or context.get("in_range") != true \
			or context.get("in_combat") != false or str(context.get("source_key", "")).is_empty():
		return _refuse("needs_home_station_outside_combat")
	if not personal_errors(record, cfg).is_empty() or items == null:
		return _refuse("invalid_baseline")
	var before := record.duplicate(true)
	var receipt := "craft:%s:gear_%s" % [character, intent.action_id]
	var receipts: Array = record.redesign_character.get("transaction_receipts", [])
	if receipts.has(receipt):
		return _refuse("replayed")
	var fields := intent.duplicate(true)
	fields.erase("action_id")
	var plan := _plan_core(record, fields, context, items, cfg)
	if plan.get("ok") != true:
		return plan
	var next: Dictionary = plan.state
	next.redesign_character.transaction_receipts.append(receipt)
	return {"ok": true, "before": before, "state": next, "receipt": receipt,
		"intent": intent.duplicate(true), "expected_revision": revision,
		"original_intent": intent.duplicate(true), "original_revision": revision,
		"character_id": character, "source_key": context.source_key}

## Durable V2-row validator only: Session saved this authorization in trusted
## host context when its actual live producer admitted the action. Turning the
## feature OFF later must not invalidate or refund an already durable row.
## The authority owner validates saved context and the exact original intent;
## client fields must never select this entry point or supply this marker.
static func stage_frozen_core(record: Dictionary, character: String, revision: int,
		intent: Dictionary, context: Dictionary, items: RefCounted,
		cfg: Dictionary) -> Dictionary:
	var authorized: Variant = context.get("gear_runtime_authorized")
	if not authorized is bool or authorized != true:
		return _refuse("frozen_authorization_required")
	var frozen_cfg := cfg.duplicate(true)
	if not frozen_cfg.get("feature_flags") is Dictionary:
		return _refuse("invalid_baseline")
	frozen_cfg.feature_flags["runtime_enabled"] = true
	return stage_core(record, character, revision, intent, context, items, frozen_cfg)

## F31 menu hint, never a transaction or authority decision. Uses the SAME
## detached swap/cost/return-room planner as stage_core, without an action ID,
## receipt or write. Session must restage after authenticating the real source.
static func preflight(record: Dictionary, fields: Dictionary, context: Dictionary,
		items: RefCounted, cfg: Dictionary) -> Dictionary:
	var hint := {"available": false, "reason": "invalid_intent", "label": "Gear",
		"cost": [], "output_id": "", "required_tier": 0, "personal_known": true}
	if not _fields_valid(fields) or items == null or not record.get("redesign_character") is Dictionary \
			or not record.get("equipment") is Dictionary:
		return hint
	var action: String = fields.action
	var id: String = fields.item_id
	var upgrade: Dictionary = cfg.get("upgrades", {}).get(id, {}) if action == "upgrade" else {}
	hint.output_id = str(upgrade.get("output", id)) if action not in ["unequip", "trainer_unequip"] else ""
	hint.required_tier = int(upgrade.get("station_tier", 0))
	if action == "upgrade":
		hint.personal_known = recipe_known(record, upgrade, cfg) if not upgrade.is_empty() else false
		for cost_id: String in upgrade.get("inputs", {}):
			hint.cost.append({"id": cost_id, "n": upgrade.inputs[cost_id]})
	var old_id := id
	if action in ["unequip", "trainer_unequip"]:
		old_id = str(record.get("equipment", {}).get(fields.slot, "")) if action == "trainer_unequip" \
			else str(gear_for(record, fields.creature_uid).get(fields.slot, ""))
	var old_name := str(items.call("item_name", old_id))
	var next_name := str(items.call("item_name", hint.output_id))
	hint.label = "Upgrade %s to %s" % [old_name, next_name] if action == "upgrade" \
		else ("Remove " + old_name if action in ["unequip", "trainer_unequip"] else "Equip " + next_name)
	var plan := _plan_core(record, fields, context, items, cfg)
	var enabled := _runtime_enabled(cfg)
	hint.available = plan.get("ok") == true and enabled
	if hint.available:
		hint.reason = ""
	elif not enabled:
		hint.reason = "disabled"
	else:
		hint.reason = str(plan.get("reason", "invalid_baseline"))
	return hint

static func refusal_text(reason: String, cfg: Dictionary) -> String:
	return str(cfg.get("refusals", {}).get(reason, reason.replace("_", " ").capitalize()))

static func _fields_valid(fields: Dictionary) -> bool:
	if fields.size() != 4:
		return false
	for key: String in ["action", "creature_uid", "slot", "item_id"]:
		if not fields.get(key) is String:
			return false
	return true

static func _plan_core(record: Dictionary, intent: Dictionary, context: Dictionary,
		items: RefCounted, cfg: Dictionary) -> Dictionary:
	if not _fields_valid(intent) or items == null:
		return _refuse("invalid_intent")
	if not record.get("redesign_character") is Dictionary or not record.get("party") is Array \
			or not record.get("equipment") is Dictionary or not record.get("inventory") is Array \
			or record.get("character_id", "") == "" or record.get("character_id") != context.get("character_id"):
		return _refuse("invalid_baseline")
	if context.get("homestead") != true or context.get("in_range") != true \
			or context.get("in_combat") != false or not context.get("source_key") is String \
			or context.source_key.is_empty():
		return _refuse("needs_home_station_outside_combat")
	if not personal_errors(record, cfg).is_empty() or not _equipment_valid(record.equipment, items):
		return _refuse("invalid_baseline")
	var next := record.duplicate(true)
	var bag := _inventory(next.get("inventory"), items)
	if bag == null:
		return _refuse("invalid_inventory")
	var action: String = intent.action
	var slot: String = intent.slot
	var id: String = intent.item_id
	var current := ""
	var gear: Dictionary = {}
	var trainer := action in ["trainer_equip", "trainer_unequip"]
	if trainer:
		if not intent.creature_uid.is_empty() or not EQUIPMENT.SLOTS.has(slot) \
				or context.get("station_id") != "workbench":
			return _refuse("invalid_slot_or_station")
		if not next.get("equipment") is Dictionary or not next.equipment.get(slot) is String:
			return _refuse("invalid_baseline")
		current = next.equipment[slot]
	else:
		if action not in ["equip", "unequip", "upgrade"] or not SLOTS.has(slot) \
				or not _owns(next, intent.creature_uid):
			return _refuse("ownership")
		gear = gear_for(next, intent.creature_uid)
		current = gear[slot]
		if action != "upgrade" and context.get("station_id") != "den":
			return _refuse("needs_den")
	var output := id
	if action in ["unequip", "trainer_unequip"]:
		if not id.is_empty() or current.is_empty():
			return _refuse("empty_slot")
		output = ""
	elif action == "upgrade":
		if id != current or current.is_empty():
			return _refuse("stale_piece")
		var recipe: Dictionary = cfg.get("upgrades", {}).get(current, {})
		if recipe.is_empty():
			return _refuse("maximum_upgrade")
		if not _station_allows(recipe, context):
			return _refuse("station_tier")
		if not recipe_known(next, recipe, cfg):
			return _refuse("personal_recipe_locked")
		if not _pay(bag, recipe.get("inputs", {})):
			return _refuse("materials")
		output = str(recipe.output)
		var output_row: Dictionary = cfg.get("items", {}).get(output, {})
		if not bool(items.call("has", output)) or int(items.call("stack_size", output)) != 1 \
				or output_row.get("gear_slot") != slot:
			return _refuse("invalid_piece")
	else:
		var definition: Dictionary = items.call("definition", id)
		if trainer:
			if not bool(items.call("has", id)) or definition.get("kind") != "armor" \
					or definition.get("armor_slot") != slot or int(items.call("stack_size", id)) != 1:
				return _refuse("invalid_piece")
		else:
			var probe := empty_slots()
			probe[slot] = id
			if id.is_empty() or not slots_errors(probe, cfg).is_empty() \
					or not bool(items.call("has", id)) or int(items.call("stack_size", id)) != 1:
				return _refuse("invalid_piece")
		if not bool(bag.call("remove", id, 1)):
			return _refuse("missing_piece")
	if action != "upgrade" and not current.is_empty():
		if not bool(bag.call("has_room_for", current, 1)) or int(bag.call("add", current, 1)) != 0:
			return _refuse("satchel_full")
	if trainer:
		next.equipment[slot] = output
		var equipment := EQUIPMENT.new()
		equipment.configure(items)
		equipment.load_data(next.equipment)
		next.redesign_character.pouch_tier = equipment.command_pouch_tier()
	else:
		gear[slot] = output
		next.redesign_character.creatures[intent.creature_uid]["gear"] = gear
	next.inventory = _slots(bag)
	return {"ok": true, "state": next, "output_id": output}

static func _equipment_valid(raw: Dictionary, items: RefCounted) -> bool:
	if raw.size() != EQUIPMENT.SLOTS.size():
		return false
	for slot: String in EQUIPMENT.SLOTS:
		if not raw.get(slot) is String:
			return false
		var id: String = raw[slot]
		if id.is_empty():
			continue
		var row: Dictionary = items.call("definition", id)
		if not bool(items.call("has", id)) or row.get("kind") != "armor" \
				or row.get("armor_slot") != slot or int(items.call("stack_size", id)) != 1:
			return false
	return true

## Called within the existing release producer BEFORE removing the UID or
## paying essence. Refusal preserves the whole release. Not a new release API.
static func return_for_release(record: Dictionary, uid: String, items: RefCounted,
		cfg: Dictionary) -> Dictionary:
	if not _owns(record, uid) or not personal_errors(record, cfg).is_empty():
		return _refuse("ownership")
	var next := record.duplicate(true)
	var bag := _inventory(next.get("inventory"), items)
	if bag == null:
		return _refuse("invalid_inventory")
	for id: String in gear_for(next, uid).values():
		if not id.is_empty() and (not bool(bag.call("has_room_for", id, 1)) \
				or int(bag.call("add", id, 1)) != 0):
			return _refuse("satchel_full")
	next.inventory = _slots(bag)
	next.redesign_character.creatures[uid]["gear"] = empty_slots()
	return {"ok": true, "before": record.duplicate(true), "state": next}

static func _owns(record: Dictionary, uid: String) -> bool:
	var personal: Variant = record.get("redesign_character")
	if uid.is_empty() or not personal is Dictionary or not personal.get("creatures") is Dictionary \
			or not personal.creatures.has(uid) or not record.get("party") is Array:
		return false
	for row: Variant in record.get("party", []):
		if row is Dictionary and row.get("uid") == uid:
			return true
	return false

static func _integer(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floorf(float(value)) and float(value) >= low and float(value) <= high

static func _finite_number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) >= low and float(value) <= high

static func _runtime_enabled(cfg: Dictionary) -> bool:
	var enabled: Variant = cfg.get("feature_flags", {}).get("runtime_enabled")
	return enabled is bool and enabled == true

static func _action_id(value: String) -> bool:
	if value.length() != 32:
		return false
	for index in value.length():
		if not value[index] in "0123456789abcdef":
			return false
	return true

static func _refuse(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}

static func _station_allows(recipe: Dictionary, context: Dictionary) -> bool:
	return context.get("station_id") == recipe.get("station_id") \
		and _integer(context.get("effective_tier"), 0, 4) \
		and int(context.effective_tier) >= int(recipe.get("station_tier", 1))

static func _pay(bag: RefCounted, costs: Dictionary) -> bool:
	if costs.is_empty():
		return false
	for id: String in costs:
		if not _integer(costs[id], 1, 2147483647) or int(bag.call("count", id)) < int(costs[id]):
			return false
	for id: String in costs:
		if not bool(bag.call("remove", id, int(costs[id]))):
			return false
	return true

static func _inventory(raw: Variant, items: RefCounted) -> RefCounted:
	if not raw is Array or raw.size() > INVENTORY.SLOT_COUNT or items == null:
		return null
	var bag := INVENTORY.new(items)
	for index in raw.size():
		var stack: Variant = raw[index]
		if stack != null:
			if not stack is Dictionary or not stack.get("id") is String \
					or not bool(items.call("has", stack.id)) \
					or not _integer(stack.get("n"), 1, int(items.call("stack_size", stack.id))):
				return null
		bag.call("set_slot", index, stack.duplicate(true) if stack is Dictionary else null)
	return bag

static func _slots(bag: RefCounted) -> Array:
	var result: Array = []
	for index in int(bag.call("slot_count")):
		var row: Dictionary = bag.call("stack_at", index)
		result.append(null if row.is_empty() else row.duplicate(true))
	return result
