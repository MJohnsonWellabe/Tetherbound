extends RefCounted

## Detached atomic candidates for the EXISTING Foundation journal. No save,
## grant, RPC, ledger or local debit here. A host re-stages under its fence,
## journals BOTH candidates, then publishes/ACKs via the admitted carrier.
const RULES := preload("res://scripts/build/forward_camp_rules.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const CRAFT := preload("res://scripts/build/station_actions.gd")

static func stage_build(current: Dictionary, revision: int, records: Array,
		next_uid: int, intent: Dictionary, context: Dictionary) -> Dictionary:
	return _stage_build(RULES.config(),current,revision,records,next_uid,intent,context)

## Detached fixture entry; production always reads the canonical OFF gate.
static func _stage_build(cfg: Dictionary, current: Dictionary, revision: int, records: Array,
		next_uid: int, intent: Dictionary, context: Dictionary) -> Dictionary:
	if intent.get("action") not in ["place","pack"] or not RULES.transaction_id(intent.get("action_id")):
		return RULES.deny("camp_intent_invalid")
	if not _context(current,revision,context,cfg) or context.get("host_ground_valid") != true \
			or not context.get("host_ground_valid") is bool: return RULES.deny("camp_ground")
	var receipt := "craft:%s:camp:%s" % [current.character_id,intent.action_id]
	if current.redesign_character.transaction_receipts.has(receipt): return RULES.deny("reconcile_original_delivery")
	var bag := BAG.inventory_from(current.inventory)
	var next_records := records.duplicate(true)
	var row: Dictionary
	if intent.action == "place":
		if intent.size() != 5 or not RULES.STATIONS.PLOT.numbers(intent.get("position"),3) \
				or not RULES.STATIONS.number(intent.get("yaw_deg")) or next_uid < 1 or next_uid >= 2147483647:
			return RULES.deny("camp_intent_invalid")
		var p: Array = intent.position
		var at := Vector3(p[0],p[1],p[2])
		if intent.get("realm") != context.get("realm"): return RULES.deny("camp_ground")
		var legal := RULES.placement(cfg,records,current.character_id,intent.realm,at,intent.yaw_deg)
		if legal.get("ok") != true: return legal
		for existing: Variant in records:
			if existing is Dictionary and existing.get("uid") == "b%d" % next_uid: return RULES.deny("camp_uid_conflict")
		if not bag.call("remove",RULES.KIT,1): return RULES.deny("camp_kit_missing")
		row={"id":RULES.ID,"uid":"b%d" % next_uid,"realm":intent.realm,"position":p.duplicate(),
			"yaw_deg":intent.yaw_deg,"paid":true,"character_id":current.character_id,"txn_id":intent.action_id}
		next_records.append(row)
	else:
		if intent.size() != 3 or not intent.get("uid") is String: return RULES.deny("camp_intent_invalid")
		var target := RULES.record(records,intent.uid)
		if target.get("ok") != true: return target
		row=target.record
		if row.character_id != current.character_id: return RULES.deny("camp_owner")
		if context.get("camp_uid") != row.uid or context.get("all_parties_awake") != true \
				or not context.get("all_parties_awake") is bool: return RULES.deny("camp_occupied")
		if int(bag.call("add",RULES.KIT,1)) != 0: return RULES.deny("satchel_full")
		next_records[target.index].removed=true
	var next := current.duplicate(true)
	next.inventory=BAG.slots(bag)
	next.redesign_character.transaction_receipts.append(receipt)
	if not STATE.validate("character",next.redesign_character,STATE.uids(next.party)).is_empty(): return RULES.deny("receipt_budget")
	return {"ok":true,"before":current.duplicate(true),"state":next,"world_before":records.duplicate(true),
		"placed_buildings":next_records,"next_building_uid":next_uid+1 if intent.action == "place" else next_uid,
		"record":row,"receipt":receipt,"character_id":current.character_id,"original_revision":revision,
		"original_intent":intent.duplicate(true),"durable":false,"resolved":false}

static func _context(current: Dictionary, revision: int, context: Dictionary, cfg: Dictionary = {}) -> bool:
	if cfg.is_empty(): cfg=RULES.config()
	return cfg.get("runtime_enabled") == true and current.get("character_id","") != "" \
		and revision >= 0 and revision < 2147483647 \
		and context.get("character_id") == current.character_id and context.get("expected_revision") == revision \
		and context.get("in_range") is bool and context.in_range == true \
		and context.get("in_combat") is bool and context.in_combat == false \
		and current.get("redesign_character") is Dictionary and current.get("party") is Array and current.party.size() <= 5 \
		and STATE.validate("character",current.redesign_character,STATE.uids(current.party)).is_empty() \
		and BAG.valid_slots(current.get("inventory"))

static func stage_craft(current: Dictionary, revision: int, intent: Dictionary,
		context: Dictionary, canonical_recipe: Dictionary) -> Dictionary:
	if not _context(current,revision,context) or context.get("station_kind") != RULES.ID:
		return RULES.deny("camp_unavailable")
	var legal := RULES.recipe(str(intent.get("recipe_id","")),canonical_recipe,str(context.get("part","")))
	if legal.get("ok") != true: return legal
	return CRAFT.stage_craft(current,revision,intent,context,canonical_recipe)

## Prepare all five at this bed, then the existing SleepVote/NightRest path
## completes recovery, rest bonus and autosave. No instant second rest reward.
static func stage_team_bed(current: Dictionary, revision: int, intent: Dictionary,
		context: Dictionary, frozen_authorization: bool = false) -> Dictionary:
	var cfg := RULES.config()
	if frozen_authorization and context.get("foundation_runtime_authorized") == true: cfg.runtime_enabled = true
	if intent.size() != 1 or not RULES.transaction_id(intent.get("action_id")) \
			or not _context(current,revision,context,cfg) or context.get("station_kind") != RULES.ID \
			or context.get("part") != "bed" or not context.get("camp_index") is int or context.camp_index < 0 \
			or not context.get("source_key") is String or context.source_key.is_empty():
		return RULES.deny("camp_unavailable")
	var receipt := "craft:%s:camp_bed:%s" % [current.character_id,intent.action_id]
	if current.redesign_character.transaction_receipts.has(receipt): return RULES.deny("reconcile_original_delivery")
	if current.party.is_empty() or current.party.size() > 5: return RULES.deny("party_invalid")
	var next := current.duplicate(true)
	var seen := {}
	for row: Variant in next.party:
		if not row is Dictionary or not row.get("uid") is String or row.uid.is_empty() or seen.has(row.uid) \
				or not row.get("resting") is bool or not row.get("rested") is bool: return RULES.deny("party_invalid")
		if row.resting and row.get("rest_bed_index") != context.camp_index: return RULES.deny("resting_elsewhere")
		seen[row.uid]=true
		row.resting=true
		row.rested=false
		row.rest_bed_index=context.camp_index
	next.redesign_character.transaction_receipts.append(receipt)
	if not STATE.validate("character",next.redesign_character,STATE.uids(next.party)).is_empty(): return RULES.deny("receipt_budget")
	return {"ok":true,"state":next,"before":current.duplicate(true),"receipt":receipt,
		"original_intent":intent.duplicate(true),"original_revision":revision,"character_id":current.character_id,
		"source_key":context.source_key,"durable":false,"resolved":false}
