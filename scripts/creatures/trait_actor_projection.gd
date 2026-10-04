extends RefCounted

## Detached actor reconstruction from Foundation's SAME current admitted
## portable record. No client deployment/card stat or private roster cache.
const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const BONDS := preload("res://scripts/creatures/bond_milestones.gd")
const FIELDS := ["uid","species_id","display_name","nickname","creature_type","secondary_type",
	"level","base_hp","base_attack","base_defence","iv_hp","iv_attack","iv_defence",
	"boost_hp","boost_attack","boost_defence","hp","max_hp","attack","defence",
	"fainted","resting","nourishment","happiness","trait_primary","trait_secondary",
	"move_quick","move_charged","move_utility","move_ultimate","loadout_initialized",
	"move_mastery_uses","move_mastery_receipts"]

static func creature(admitted: Dictionary, uid: String) -> RefCounted:
	if not admitted.get("party") is Array or admitted.party.size() > 5 \
		or not admitted.get("redesign_character") is Dictionary: return null
	var found: Dictionary = {}
	for row: Variant in admitted.party:
		if not row is Dictionary: return null
		if row.get("uid") == uid:
			if not found.is_empty(): return null
			found = row
	if found.is_empty(): return null
	var record: Variant = admitted.redesign_character.get("creatures",{}).get(uid)
	if not record is Dictionary: return null
	var instance := INSTANCE.new()
	for field: String in FIELDS:
		if found.has(field):
			var value: Variant = found[field]
			instance.set(field,value.duplicate(true) if value is Dictionary or value is Array else value)
	var known: Array[String] = []
	if found.get("known_moves") is Array:
		for id: Variant in found.known_moves:
			if not id is String: return null
			known.append(id)
	instance.set("known_moves",known)
	for milestone: Dictionary in BONDS.config().get("milestones",[]):
		var field: String = milestone.get("task","")
		if found.has(field): instance.set(field,found[field])
	var normalized := TRAITS.initialize_legacy_record(found,record)
	if not TRAITS.project_instance(instance,normalized): return null
	instance.recompute_stats_from_base(PROGRESSION.config())
	return instance

## Own canonical trait row with only real bond counters. Used by host healing
## and source adapters that operate on the admitted payload instead of nodes.
static func trait_row(admitted: Dictionary, uid: String) -> Dictionary:
	var instance := creature(admitted,uid)
	if instance == null: return {}
	var row := {"traits_initialized":instance.get("traits_initialized"),
		"rolled_traits":instance.get("rolled_traits"),"taught_traits":instance.get("taught_traits"),
		"trait_primary":instance.get("trait_primary"),"trait_secondary":instance.get("trait_secondary")}
	for milestone: Dictionary in BONDS.config().get("milestones",[]):
		var field: String = milestone.get("task","")
		row[field] = instance.get(field)
	return row
