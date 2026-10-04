extends RefCounted

## Detached ordinary-craft stage for Foundation's EXISTING admitted character
## journal. It is not transport or a save. Feast recipes always use F28.
const RULES := preload("res://scripts/build/station_rules.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const CAMP := preload("res://scripts/build/forward_camp_rules.gd")

static func stage_craft(current: Dictionary, revision: int, intent: Dictionary,
		context: Dictionary, canonical_recipe: Dictionary, frozen_authorization: bool = false) -> Dictionary:
	if intent.size() != 2 or not intent.get("recipe_id") is String \
			or not transaction_id(intent.get("craft_id")): return RULES.deny("invalid_craft_intent")
	if canonical_recipe.get("requires_manual_refine") == true \
		and (context.get("completed_manual_refine") != true or context.get("manual_unit_ticket") != intent.craft_id):
		return RULES.deny("present_completed_refining_required")
	if current.get("character_id", "") == "" or current.get("character_id") != context.get("character_id") \
			or context.get("expected_revision") != revision: return RULES.deny("character_revision_mismatch")
	for key: String in ["homestead", "in_range", "in_combat", "recipe_known"]:
		if not context.get(key) is bool: return RULES.deny("station_context_invalid")
	var field: bool = context.get("station_kind") == CAMP.ID and context.get("forward_camp") is bool and context.forward_camp == true
	if (context.homestead != true and not field) or context.in_range != true or context.in_combat != false \
			or context.recipe_known != true: return RULES.deny("craft_not_available")
	if not context.get("source_key") is String or context.source_key.is_empty(): return RULES.deny("station_context_invalid")
	var cfg := RULES.config()
	if frozen_authorization and context.get("foundation_runtime_authorized") == true:
		cfg.runtime_enabled = true
		cfg.craft_runtime_enabled = true
	if cfg.get("runtime_enabled") != true or cfg.get("craft_runtime_enabled") != true: return RULES.deny("station_disabled")
	var route := CAMP.recipe(intent.recipe_id,canonical_recipe,str(context.get("part",""))) if field else RULES.recipe_route(cfg,intent.recipe_id,canonical_recipe)
	if route.get("ok") != true: return route
	if context.get("station_id") != route.station_id or not RULES.number(context.get("effective_tier")) \
			or float(context.effective_tier) != floor(float(context.effective_tier)) \
			or context.effective_tier < route.required_tier or context.effective_tier > 4: return RULES.deny("attachment_required")
	if not current.get("redesign_character") is Dictionary \
			or not STATE.validate("character",current.redesign_character,STATE.uids(current.get("party"))).is_empty() \
			or not BAG.valid_slots(current.get("inventory")): return RULES.deny("character_state_invalid")
	var receipt := "craft:%s:%s" % [current.character_id,intent.craft_id]
	if current.redesign_character.transaction_receipts.has(receipt):
		return {"ok":false,"code":"already_applied_reconcile_original"}
	if not RULES.valid_cost(canonical_recipe.get("cost")): return RULES.deny("recipe_cost_invalid")
	var output: Variant = canonical_recipe.get("output")
	var reinforcement: Variant = canonical_recipe.get("reinforce")
	if reinforcement != null:
		if output != null or not reinforcement is Dictionary or reinforcement.size() != 2 \
				or not reinforcement.get("tool") is String or not RULES.number(reinforcement.get("bonus")) \
				or float(reinforcement.bonus) != floor(float(reinforcement.bonus)) or reinforcement.bonus <= 0:
			return RULES.deny("recipe_output_invalid")
	elif not output is Dictionary or not RULES.valid_cost([output]) or not BAG.db().call("has",output.id):
		return RULES.deny("recipe_output_invalid")
	var bag := BAG.inventory_from(current.inventory)
	for need: Dictionary in canonical_recipe.cost:
		if not bag.call("remove",need.id,int(need.n)): return RULES.deny("ingredients_missing")
	if reinforcement is Dictionary:
		var slot: int = int(bag.call("find_slot",reinforcement.tool))
		if slot < 0: return RULES.deny("tool_upgrade_unavailable")
		bag.call("reinforce_tool",slot,int(reinforcement.bonus))
	elif int(bag.call("add",output.id,int(output.n))) != 0: return RULES.deny("satchel_full")
	var next := current.duplicate(true)
	next.inventory = BAG.slots(bag)
	next.redesign_character.transaction_receipts.append(receipt)
	if not STATE.validate("character",next.redesign_character,STATE.uids(next.get("party"))).is_empty(): return RULES.deny("receipt_budget")
	return {"ok":true,"state":next,"before":current.duplicate(true),"receipt":receipt,"character_id":current.character_id,
		"original_intent":intent.duplicate(true),"original_revision":revision,
		"source_key":context.source_key}

static func transaction_id(raw: Variant) -> bool:
	if not raw is String or raw.length() != 32: return false
	for c: String in raw:
		if not "0123456789abcdef".contains(c): return false
	return true

## Den uses the existing portable resting/rested/rest_bed_index fields and
## ordinary sleep completion. No instant XP, second rest credit or care payout.
static func stage_den_rest(current: Dictionary, revision: int, intent: Dictionary,
		context: Dictionary, frozen_authorization: bool = false) -> Dictionary:
	if intent.size() != 3 or not intent.get("creature_uid") is String \
			or intent.get("action") not in ["rest","wake"] or not transaction_id(intent.get("action_id")):
		return RULES.deny("invalid_den_intent")
	var cfg := RULES.config()
	if frozen_authorization and context.get("foundation_runtime_authorized") == true:
		cfg.runtime_enabled = true
		cfg.den_runtime_enabled = true
	if cfg.get("runtime_enabled") != true or cfg.get("den_runtime_enabled") != true: return RULES.deny("station_disabled")
	if current.get("character_id","") == "" or current.get("character_id") != context.get("character_id") \
			or context.get("expected_revision") != revision or context.get("station_id") != "den" \
			or context.get("in_range") != true or context.get("in_combat") != false \
			or context.get("homestead") != true or not context.get("in_range") is bool \
			or not context.get("in_combat") is bool or not context.get("homestead") is bool \
			or not context.get("source_key") is String or context.source_key.is_empty() \
			or not preload("res://scripts/creatures/essence.gd")._integer(context.get("den_index"), 0, 2147483646): return RULES.deny("den_context_invalid")
	if not current.get("party") is Array or current.party.is_empty() or current.party.size() > 5 \
			or not current.get("redesign_character") is Dictionary \
			or not STATE.validate("character",current.redesign_character,STATE.uids(current.party)).is_empty(): return RULES.deny("character_state_invalid")
	var index := -1
	for i: int in current.party.size():
		var row: Variant = current.party[i]
		if not row is Dictionary or not row.get("uid") is String or not row.get("resting") is bool \
				or not row.get("rested") is bool: return RULES.deny("party_rest_state_invalid")
		if row.uid == intent.creature_uid:
			if index >= 0: return RULES.deny("duplicate_creature_uid")
			index=i
	if index < 0: return RULES.deny("unowned_creature")
	var card: Dictionary = current.party[index]
	if intent.action == "rest" and card.resting: return RULES.deny("already_resting")
	if intent.action == "wake" and (not card.resting or card.get("rest_bed_index") != context.den_index): return RULES.deny("resting_elsewhere")
	var receipt := "craft:%s:den:%s" % [current.character_id,intent.action_id]
	if current.redesign_character.transaction_receipts.has(receipt): return RULES.deny("reconcile_original_delivery")
	var next := current.duplicate(true)
	next.party[index].resting=intent.action == "rest"
	next.party[index].rested=false
	next.party[index].rest_bed_index=int(context.den_index) if intent.action == "rest" else -1
	next.redesign_character.transaction_receipts.append(receipt)
	if not STATE.validate("character",next.redesign_character,STATE.uids(next.party)).is_empty(): return RULES.deny("receipt_budget")
	return {"ok":true,"state":next,"before":current.duplicate(true),"receipt":receipt,
		"original_intent":intent.duplicate(true),"original_revision":revision,"character_id":current.character_id,
		"source_key":context.source_key}
