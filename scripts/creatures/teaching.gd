extends RefCounted

## R4.4: whether a creature may learn a found TM's move, and applying it.
##
## Deliberately not a method on creature_instance.gd or tm_db.gd -- it reads
## both a TM definition and a move definition to decide the slot, which
## neither of those files knows about the other to do alone. Same reason
## progression.gd sits apart from creature_instance.gd's own progression
## calls: the rule is data-shaped, so it is easiest to read and test as a
## pure function over the data, not a method on either side of it.

## True if `creature_type` (a data/creatures/species.json `type` value) is on
## the TM's own compatibility list. GAME_DESIGN.md 13: "Species have
## compatibility lists" -- there is no other rule.
static func can_learn(creature_type: String, tm_id: String, tms: RefCounted) -> bool:
	if not bool(tms.call("has", tm_id)):
		return false
	return bool(tms.call("is_compatible", tm_id, creature_type))


## Writes the TM's move onto `creature` in whatever slot moves.json says that
## move actually occupies -- reading the slot from the move's own data rather
## than trusting the TM entry to get it right means a mis-tagged TM cannot
## silently overwrite the wrong move. Returns false and changes nothing on
## any failure (unknown TM, incompatible species, unknown or unslotted move)
## so a caller never has to check "did this half-apply".
static func teach(creature: RefCounted, tm_id: String, tms: RefCounted, moves: RefCounted) -> bool:
	var creature_type := str(creature.get("creature_type"))
	if not can_learn(creature_type, tm_id, tms):
		return false

	var move: String = str(tms.call("move_id", tm_id))
	if not bool(moves.call("has", move)):
		return false

	var slot: String = str(moves.call("slot", move))
	if slot == "quick":
		creature.set("move_quick", move)
		_remember_taught_move(creature,move)
		return true
	if slot == "charged":
		creature.set("move_charged", move)
		_remember_taught_move(creature,move)
		return true
	return false

static func _remember_taught_move(creature: RefCounted, move: String) -> void:
	# Retired helper callers use small doubles without canonical fields.
	for property: Dictionary in creature.get_property_list():
		if str(property.get("name","")) == "known_moves":
			var known: Array = creature.get("known_moves")
			if not known.has(move): known.append(move)
			creature.set("known_moves",known)
			return

## F23 knowledge-only TM staging. The existing teach() remains the retired
## auto-equip helper for its callers/tests. The real transaction must first
## validate the owned whole party, then atomically debit one TM, publish this
## detached known list and persist; refusal never equips or spends anything.
static func stage_tm_knowledge(creature: RefCounted, tm_id: String, tms: RefCounted, moves: RefCounted) -> Dictionary:
	if creature == null or tms == null or moves == null: return {"ok": false, "reason": "unavailable"}
	var fields := {}
	for property: Dictionary in creature.get_property_list(): fields[str(property.name)] = true
	for field: String in ["creature_type", "known_moves", "move_mastery_uses", "move_mastery_receipts"]:
		if not fields.has(field): return {"ok": false, "reason": "canonical_knowledge_required"}
	if not can_learn(str(creature.get("creature_type")), tm_id, tms): return {"ok": false, "reason": "incompatible"}
	var move := str(tms.call("move_id", tm_id))
	if move.is_empty() or not bool(moves.call("has", move)): return {"ok": false, "reason": "unknown_move"}
	var slot := str(moves.call("slot", move))
	if not ["quick", "charged", "utility"].has(slot): return {"ok": false, "reason": "signature_not_teachable"}
	var known: Variant = creature.get("known_moves")
	if not known is Array: return {"ok": false, "reason": "invalid_knowledge"}
	var uses: Variant = creature.get("move_mastery_uses")
	var receipts: Variant = creature.get("move_mastery_receipts")
	if not MASTERY.valid_document(known, uses, receipts, known): return {"ok": false, "reason": "invalid_knowledge"}
	if known.has(move): return {"ok": true, "replayed": true, "move_id": move, "known_moves": known.duplicate()}
	var next: Array[String] = []
	for id: String in known: next.append(id)
	next.append(move)
	if not MASTERY.valid_document(next, uses, receipts, next): return {"ok": false, "reason": "knowledge_full"}
	return {"ok": true, "replayed": false, "move_id": move, "known_moves": next}

## The Foundation transaction supplies its admitted WHOLE character candidate,
## frozen immutable intent and expected revision. This planner adds no receipt
## store: the existing writer/journal owns save failure, ACK and replay identity.
## Inventory debit and learned option are staged together; no slot auto-equip.
static func stage_tm_candidate(admitted: Dictionary, creature_uid: String, tm_id: String,
		tms: RefCounted, moves: RefCounted) -> Dictionary:
	if not admitted_party_errors(admitted.get("party"), admitted.get("redesign_character")).is_empty() \
			or not admitted.get("inventory") is Array:
		return {"ok": false, "code": "invalid_character"}
	var candidate := admitted.duplicate(true)
	var selected: Dictionary = {}
	for row: Dictionary in candidate.party:
		if row.uid == creature_uid: selected = row
	if selected.is_empty(): return {"ok": false, "code": "not_owner"}
	var species := preload("res://scripts/creatures/creature_species.gd")
	var primary := str(species.definition(str(selected.species_id)).get("type", ""))
	if primary.is_empty() or selected.get("creature_type") != primary:
		return {"ok": false, "code": "invalid_primary_type"}
	var record := MASTERY.owned_record(selected)
	# OwnedRecord holds canonical mastery only; use a detached full instance
	# for this typed rule rather than changing the registry's live creature.
	var instance := load("res://scripts/creatures/creature_instance.gd") as GDScript
	var learned: RefCounted = instance.new()
	learned.creature_type = primary
	learned.known_moves = record.known_moves
	learned.move_mastery_uses = record.move_mastery_uses
	learned.move_mastery_receipts = record.move_mastery_receipts
	var staged := stage_tm_knowledge(learned, tm_id, tms, moves)
	if not bool(staged.get("ok", false)): return {"ok": false, "code": staged.get("reason", "invalid_tm")}
	if bool(staged.get("replayed", false)): return {"ok": false, "code": "already_known"}
	var found := -1
	for index: int in candidate.inventory.size():
		var stack: Variant = candidate.inventory[index]
		if stack is Dictionary and stack.get("id") == tm_id:
			if not MASTERY._whole_nonnegative(stack.get("n")) or int(stack.n) < 1:
				return {"ok": false, "code": "invalid_inventory"}
			found = index
			break
	if found < 0: return {"ok": false, "code": "missing_tm"}
	var stack: Dictionary = candidate.inventory[found]
	if int(stack.n) == 1:
		candidate.inventory[found] = null
	else:
		stack.n = int(stack.n) - 1
	selected.known_moves = staged.known_moves
	candidate.redesign_character = character_loadout_mirror(candidate.party, candidate.redesign_character)
	return {"ok": true, "state": candidate, "move_id": staged.move_id}


const LEARNSETS_PATH := "res://data/moves/learnsets.json"
const MOVE_DB := preload("res://scripts/creatures/move_db.gd")
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")
static var _learnsets: Dictionary = {}
static var _learnsets_loaded := false

static func learnsets() -> Dictionary:
	if not _learnsets_loaded:
		_learnsets_loaded = true
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(LEARNSETS_PATH))
		var errors := learnset_errors(raw, MOVE_DB.load_default())
		if errors.is_empty():
			_learnsets = raw.species
		else:
			push_error("Creature learnsets refused: %s" % "; ".join(errors))
	return _learnsets

## Reserved species are authored and checked even while acquisition is off.
static func learnset_errors(raw: Variant, moves: RefCounted) -> Array[String]:
	var errors: Array[String] = []
	if not raw is Dictionary or not raw.get("species") is Dictionary or moves == null:
		return ["learnsets require a species object and move registry"]
	for species_id: String in raw.species:
		var row: Variant = raw.species[species_id]
		if not row is Dictionary or not row.get("unlocks") is Array \
				or not ["WALL", "CHARGER", "DIVER", "CURRENT"].has(row.get("role_family")):
			errors.append("%s: invalid learnset" % species_id)
			continue
		var base_slots := {}
		var utility_levels := {}
		for unlock: Variant in row.unlocks:
			if not unlock is Dictionary or not unlock.get("move_id") is String \
					or not moves.has(str(unlock.get("move_id", ""))):
				errors.append("%s: unknown move" % species_id)
				continue
			if unlock.has("level") == unlock.has("breakthrough_tier"):
				errors.append("%s: exactly one unlock gate required" % species_id)
				continue
			var gate: Variant = unlock.get("level", unlock.get("breakthrough_tier"))
			var maximum := 100 if unlock.has("level") else 5
			if not MASTERY._whole_nonnegative(gate) or int(gate) < 1 or int(gate) > maximum:
				errors.append("%s: invalid unlock gate" % species_id)
				continue
			var slot := str(moves.slot(unlock.move_id))
			if unlock.get("level", 0) == 1: base_slots[slot] = true
			if slot == "utility" and unlock.has("level"): utility_levels[int(gate)] = true
		for slot: String in ["quick", "charged", "ultimate"]:
			if not base_slots.has(slot): errors.append("%s: missing L1 %s" % [species_id, slot])
		if not utility_levels.has(5) or not utility_levels.has(15):
			errors.append("%s: missing L5/L15 utility options" % species_id)
		if not moves.has(str(row.get("ultimate", ""))) \
				or str(moves.slot(str(row.get("ultimate", "")))) != "ultimate":
			errors.append("%s: missing signature" % species_id)
	return errors

## The host supplies actual completed tiers from F28; requesting a level or
## tier in an edit payload is never a substitute for that earned character state.
static func available_moves(species_id: String, level: int, completed_tiers: Array) -> Array[String]:
	var result: Array[String] = []
	var row: Dictionary = learnsets().get(species_id,{})
	if bool(row.get("reserved",false)): return result
	for raw: Variant in row.get("unlocks",[]):
		if not raw is Dictionary: continue
		var unlock: Dictionary = raw
		var id := str(unlock.get("move_id",""))
		var level_gate := unlock.has("level") and level >= int(unlock.level)
		var tier_gate := unlock.has("breakthrough_tier") and completed_tiers.has(int(unlock.breakthrough_tier))
		if (level_gate or tier_gate) and not id.is_empty() and not result.has(id): result.append(id)
	return result

## Import eligibility comes from authored records, not the saved known list.
## Follow only authored ancestor links so evolution keeps its earlier moves.
static func allowed_saved_moves(saved: Dictionary, character: Dictionary) -> Array[String]:
	var allowed: Array[String] = []
	var species_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures/species.json"))
	var species: Dictionary = species_raw.get("species",{}) if species_raw is Dictionary else {}
	var water := preload("res://scripts/creatures/water_species_catalog.gd").merge_catalogue(species)
	if bool(water.get("ok",false)): species = water.catalogue
	var id := str(saved.get("species_id",""))
	var records: Variant = character.get("creatures",{})
	var raw_record: Variant = records.get(str(saved.get("uid","")),{}) if records is Dictionary else {}
	var record: Dictionary = raw_record if raw_record is Dictionary else {}
	var raw_tiers: Variant = record.get("breakthroughs",[])
	var tiers: Array = raw_tiers if raw_tiers is Array else []
	var ancestry: Array[String] = [id]
	# Repeated backward closure supports lines with more than one evolution.
	for _step: int in species.size():
		var changed := false
		for candidate: String in species:
			var target: Variant = species[candidate].get("evolves_into","")
			var targets: Array = target.duplicate() if target is Array else [target]
			var variants: Variant = species[candidate].get("evolves_into_variants", {})
			if variants is Dictionary:
				for variant: Variant in variants.values():
					if not targets.has(variant): targets.append(variant)
			for descendant: Variant in targets:
				if ancestry.has(str(descendant)) and not ancestry.has(candidate):
					ancestry.append(candidate)
					changed = true
		if not changed: break
	var raw_level: Variant = saved.get("level",1)
	var level := int(raw_level) if (raw_level is int or raw_level is float) and is_finite(float(raw_level)) else 1
	for ancestor: String in ancestry:
		for move: String in available_moves(ancestor,level,tiers):
			if not allowed.has(move): allowed.append(move)
		var defaults: Dictionary = species.get(ancestor,{}).get("moves",{})
		for slot: String in defaults:
			var move := str(defaults[slot])
			if not move.is_empty() and not allowed.has(move): allowed.append(move)
	var tms := preload("res://scripts/creatures/tm_db.gd").load_default()
	for tm: String in tms.tm_ids():
		for ancestor: String in ancestry:
			var primary := str(species.get(ancestor,{}).get("type",saved.get("creature_type","")))
			if tms.is_compatible(tm,primary):
				var move: String = tms.move_id(tm)
				if not allowed.has(move): allowed.append(move)
	return allowed

## Detached whole-party preflight shared by all save/import paths. Existing
## v28 rows without the additive fields remain valid; a partial new document
## refuses before a caller can mutate appearance, inventory or one party row.
static func party_loadout_errors(entries: Variant, character: Variant = {}, compare_carrier: bool = false) -> Array[String]:
	var errors: Array[String] = []
	if not entries is Array or not character is Dictionary:
		errors.append("party loadout payload must be an array and character an object")
		return errors
	if entries.size()>5:
		errors.append("portable party exceeds five owned creatures")
		return errors
	if not character.get("creatures",{}) is Dictionary:
		errors.append("character creatures must be an object")
		return errors
	var moves := MOVE_DB.load_default()
	var identities := {}
	for raw: Variant in entries:
		if raw is Dictionary and raw.get("uid") is String:
			identities[raw.uid] = int(identities.get(raw.uid,0))+1
	var instances := load("res://scripts/creatures/creature_instance.gd") as GDScript
	for index: int in entries.size():
		var saved: Variant = entries[index]
		# Existing row tolerance is unchanged for pre-F23 v28 documents.
		if not saved is Dictionary: continue
		var has_new := false
		for field: String in ["known_moves","move_mastery_uses","move_mastery_receipts","move_utility","move_ultimate","loadout_revision","loadout_last_edit"]:
			if saved.has(field): has_new = true
		if not has_new:
			var old_record: Variant = character.get("creatures",{}).get(str(saved.get("uid","")),{})
			if compare_carrier and old_record is Dictionary and (old_record.has("mastery_receipts") or old_record.has("loadout_revision") or old_record.has("loadout_last_edit")):
				errors.append("party[%d]: missing canonical fields for existing move carrier" % index)
			continue
		if not saved.get("uid") is String or not instances.valid_uid(str(saved.get("uid",""))) or int(identities.get(str(saved.get("uid","")),0))!=1:
			errors.append("party[%d]: invalid or repeated canonical move identity" % index)
			continue
		var raw_level: Variant = saved.get("level",1)
		if not (raw_level is int or raw_level is float) or not is_finite(float(raw_level)) or floor(float(raw_level))!=float(raw_level) or float(raw_level)<1.0 or float(raw_level)>100.0:
			errors.append("party[%d]: invalid loadout level" % index)
			continue
		var staged := stage_saved_loadout(saved,allowed_saved_moves(saved,character),moves)
		if not bool(staged.get("ok",false)):
			errors.append("party[%d]: %s" % [index,str(staged.get("reason","invalid_loadout"))])
			continue
		var record: Variant = character.get("creatures",{}).get(str(saved.get("uid","")),{})
		if compare_carrier and record is Dictionary and not record.is_empty():
			var expected: Dictionary = character_loadout_mirror([saved],character).creatures.get(str(saved.get("uid","")),{})
			for field: String in ["known_moves","loadout","mastery_receipts"]:
				if record.get(field)!=expected.get(field): errors.append("party[%d]: divergent move carrier %s" % [index,field])
			if not record.get("loadout_revision") is int and not record.get("loadout_revision") is float:
				errors.append("party[%d]: invalid mirrored revision" % index)
			elif float(record.loadout_revision)!=float(expected.loadout_revision):
				errors.append("party[%d]: divergent mirrored revision" % index)
			if not _same_edit_receipt(record.get("loadout_last_edit"),expected.get("loadout_last_edit")):
				errors.append("party[%d]: divergent mirrored edit receipt" % index)
			var actual_mastery: Variant = record.get("mastery",{})
			if not actual_mastery is Dictionary or actual_mastery.size()!=expected.mastery.size():
				errors.append("party[%d]: divergent mirrored mastery" % index)
			else:
				for move: String in expected.mastery:
					var actual: Variant = actual_mastery.get(move,{})
					if not actual is Dictionary or not MASTERY._whole_nonnegative(actual.get("uses")) or not MASTERY._whole_nonnegative(actual.get("rank")):
						errors.append("party[%d]: invalid mirrored mastery" % index)
					elif int(actual.uses)!=int(expected.mastery[move].uses) or int(actual.rank)!=int(expected.mastery[move].rank):
						errors.append("party[%d]: divergent mirrored mastery" % index)
	return errors

## Admission is stricter than the tolerant local v28 reader: a remote host
## must bind existing canonical UIDs and never mint replacements for a packet.
## Call only after the portable envelope and typed character carrier validate.
static func admitted_party_errors(entries: Variant, character: Variant) -> Array[String]:
	var errors := party_loadout_errors(entries,character,true)
	if not errors.is_empty(): return errors
	if entries.size()>5:
		return ["admitted party exceeds five owned creatures"]
	var instances := load("res://scripts/creatures/creature_instance.gd") as GDScript
	var species := load("res://scripts/creatures/creature_species.gd") as GDScript
	var seen := {}
	for index: int in entries.size():
		var saved: Variant = entries[index]
		if not saved is Dictionary or not saved.get("uid") is String:
			errors.append("admitted party[%d] has no canonical identity" % index)
			continue
		var uid: String = saved.uid
		if not instances.valid_uid(uid) or seen.has(uid):
			errors.append("admitted party[%d] has invalid or repeated identity" % index)
		seen[uid] = true
		if not saved.get("species_id") is String or not species.has(str(saved.species_id)):
			errors.append("admitted party[%d] has unknown species" % index)
		# Detached construction and tolerant old local rows may be incomplete;
		# a canonical owned admission may never remove its required verbs.
		for slot: String in ["quick", "charged", "ultimate"]:
			if not saved.get("move_" + slot) is String or str(saved.get("move_" + slot, "")).is_empty():
				errors.append("admitted party[%d] has no %s move" % [index, slot])
	return errors

## Typed carrier projection at a serialization boundary. The live instance is
## canonical; unrelated cap/breakthrough/trait/evolution records are preserved.
## A snapshot never calls the credit helper and cannot invent a landed use.
static func character_loadout_mirror(entries: Array, character: Dictionary) -> Dictionary:
	var result := character.duplicate(true)
	var records: Dictionary = result.get("creatures",{}).duplicate(true)
	for raw: Variant in entries:
		if not raw is Dictionary or not raw.has("known_moves"): continue
		var uid := str(raw.get("uid",""))
		if uid.is_empty(): continue
		var existing: Variant = records.get(uid,{"cap_level":10,"breakthroughs":[],"evolution_choices":{},
			"rolled_traits":[],"taught_traits":{},"known_moves":[],"loadout":{"quick":"","charged":"","utility":"","ultimate":""},"mastery":{},"best":false})
		if not existing is Dictionary: return result
		var record: Dictionary = existing.duplicate(true)
		record.known_moves = raw.known_moves.duplicate()
		record.loadout = {"quick":raw.get("move_quick",""),"charged":raw.get("move_charged",""),"utility":raw.get("move_utility",""),"ultimate":raw.get("move_ultimate","")}
		var mastery := {}
		for move: String in raw.get("move_mastery_uses",{}):
			var uses := int(raw.move_mastery_uses[move])
			mastery[move] = {"uses":uses,"rank":MASTERY.rank_from_uses(uses)}
		record.mastery = mastery
		record.mastery_receipts = raw.get("move_mastery_receipts",{}).duplicate(true)
		record.loadout_revision = int(raw.get("loadout_revision",0))
		record.loadout_last_edit = raw.get("loadout_last_edit",{}).duplicate(true)
		records[uid] = record
	result.creatures = records
	return result

static func _same_edit_receipt(a: Variant, b: Variant) -> bool:
	if not a is Dictionary or not b is Dictionary or a.size()!=b.size(): return false
	for key: Variant in b:
		if key=="expected_revision":
			if not MASTERY._whole_nonnegative(a.get(key)) or not MASTERY._whole_nonnegative(b.get(key)) or int(a[key])!=int(b[key]): return false
		elif a.get(key)!=b[key]: return false
	return true

static func refresh_known_moves(creature: RefCounted, completed_tiers: Array = []) -> void:
	if not bool(creature.get("loadout_initialized")): return
	var known: Array[String] = []
	for old: String in creature.get("known_moves"): known.append(old)
	for id: String in available_moves(str(creature.get("species_id")),int(creature.get("level")),completed_tiers):
		if not known.has(id): known.append(id)
	creature.set("known_moves",known)

static func initialize_loadout(creature: RefCounted, definition: Dictionary) -> void:
	if not definition.get("moves") is Dictionary: return
	creature.set("loadout_initialized",true)
	var known: Array[String] = []
	var defaults: Dictionary = definition.get("moves",{})
	for slot: String in ["quick","charged","utility","ultimate"]:
		var id := str(defaults.get(slot,""))
		if not id.is_empty() and not known.has(id): known.append(id)
	creature.set("known_moves",known)
	refresh_known_moves(creature)
	if str(creature.get("move_ultimate")).is_empty():
		var signature_row: Dictionary = learnsets().get(str(creature.get("species_id")), {})
		var signature := str(signature_row.get("ultimate", ""))
		if (creature.get("known_moves") as Array).has(signature): creature.set("move_ultimate", signature)
	if str(creature.get("move_utility")).is_empty():
		var row: Dictionary = learnsets().get(str(creature.get("species_id")),{})
		var first := str(row.get("first_utility",""))
		if (creature.get("known_moves") as Array).has(first): creature.set("move_utility",first)

## Detached learning projection for a level/feast/evolution character candidate.
## Foundation calls before its atomic writer, preserving taught moves/mastery.
## Learning an option never edits an equipped slot in the field.
static func stage_unlocks(saved: Dictionary, completed_tiers: Array) -> Dictionary:
	var known: Variant = saved.get("known_moves")
	if not known is Array or not MASTERY.valid_document(known,
			saved.get("move_mastery_uses"), saved.get("move_mastery_receipts"), known):
		return {"ok": false, "reason": "invalid_knowledge"}
	var next: Array = known.duplicate()
	for move: String in available_moves(str(saved.get("species_id", "")), int(saved.get("level", 1)), completed_tiers):
		if not next.has(move): next.append(move)
	if not MASTERY.valid_document(next, saved.move_mastery_uses, saved.move_mastery_receipts, next):
		return {"ok": false, "reason": "knowledge_full"}
	return {"ok": true, "known_moves": next}

## Pure compare-and-swap staging. The actual host station service must create
## context from live ownership, station ID/geometry and encounter state; this
## helper does NOT authenticate facts from a client-supplied dictionary.
## No application occurs until the host persistence/transaction service commits.
static func stage_loadout_edit(creature: RefCounted, request: Dictionary, host_context: Dictionary,
		moves: RefCounted) -> Dictionary:
	if creature == null or moves == null: return {"ok":false,"reason":"missing_creature"}
	var uid := str(creature.get("uid"))
	var owned: Variant = host_context.get("owned_creature_uids")
	if not owned is Array or owned.size() > 5 or not owned.has(uid): return {"ok":false,"reason":"not_owner"}
	if str(request.get("creature_uid","")) != uid: return {"ok":false,"reason":"wrong_creature"}
	var allowed := ["edit_id","expected_revision","creature_uid","quick","charged","utility"]
	for key: Variant in request:
		if not allowed.has(key): return {"ok":false,"reason":"unsupported_field"}
	var expected: Variant = request.get("expected_revision")
	if not (expected is int or expected is float) or not is_finite(float(expected)) or float(expected) < 0.0 \
			or float(expected) >= 2147483647.0 or floor(float(expected)) != float(expected): return {"ok":false,"reason":"invalid_revision"}
	if not request.get("edit_id") is String: return {"ok":false,"reason":"invalid_edit_id"}
	var edit_id := str(request.get("edit_id",""))
	if edit_id.is_empty() or edit_id.length() > 64: return {"ok":false,"reason":"invalid_edit_id"}
	var canonical := {"edit_id":edit_id,"expected_revision":int(expected),"creature_uid":uid}
	for slot: String in ["quick","charged","utility"]:
		if not request.get(slot) is String: return {"ok":false,"reason":"invalid_slot"}
		canonical[slot] = request[slot]
	var last: Dictionary = creature.get("loadout_last_edit")
	if str(last.get("edit_id","")) == edit_id:
		if not _same_edit_receipt(last,canonical): return {"ok":false,"reason":"edit_id_collision"}
		return {"ok":true,"replayed":true,"revision":int(creature.get("loadout_revision"))}
	if int(expected) != int(creature.get("loadout_revision")): return {"ok":false,"reason":"stale_revision"}
	if not ["altar","forward_camp"].has(str(host_context.get("station_kind",""))): return {"ok":false,"reason":"wrong_station"}
	if not bool(host_context.get("within_reach",false)) or bool(host_context.get("in_combat",true)):
		return {"ok":false,"reason":"station_unavailable"}
	var known: Array = creature.get("known_moves")
	for slot: String in ["quick","charged","utility"]:
		var move := str(canonical[slot])
		if slot == "utility" and move.is_empty(): continue
		if not known.has(move) or not moves.has(move) or str(moves.slot(move)) != slot:
			return {"ok":false,"reason":"unknown_or_wrong_slot"}
	var next := {"quick":canonical.quick,"charged":canonical.charged,"utility":canonical.utility,
		"ultimate":str(creature.get("move_ultimate"))}
	return {"ok":true,"replayed":false,"revision":int(expected)+1,"loadout":next,"receipt":canonical}

## Character snapshot preflight only. This returns detached values and never
## edits the live party. SaveGame/CharacterSave must validate EVERY party row
## before applying any row; this cannot turn a refused portable file into a
## partial load. allowed_moves is resolved from host-owned learnsets, compatible
## TM definitions and retained evolutionary ancestry by the save boundary.
static func stage_saved_loadout(saved: Dictionary, allowed_moves: Array,
		moves: RefCounted) -> Dictionary:
	var fields := ["known_moves","move_mastery_uses","move_mastery_receipts",
		"move_utility","move_ultimate","loadout_revision","loadout_last_edit"]
	var present := 0
	for field: String in fields:
		if saved.has(field): present += 1
	# Additive v28 compatibility is a distinct caller path. It derives original
	# equipped defaults without granting mastery, never restamps the schema.
	if present == 0: return {"ok":true,"needs_defaults":true}
	if present != fields.size() or moves == null:
		return {"ok":false,"reason":"incomplete_loadout_document"}
	var known: Variant = saved.known_moves
	var uses: Variant = saved.move_mastery_uses
	var histories: Variant = saved.move_mastery_receipts
	if not MASTERY.valid_document(known,uses,histories,allowed_moves):
		return {"ok":false,"reason":"invalid_mastery_document"}
	var revision: Variant = saved.loadout_revision
	if not (revision is int or revision is float) or not is_finite(float(revision)) \
			or float(revision)<0.0 or floor(float(revision))!=float(revision):
		return {"ok":false,"reason":"invalid_loadout_revision"}
	for slot: String in ["quick","charged","utility","ultimate"]:
		var raw: Variant = saved.get("move_"+slot,null)
		if not raw is String: return {"ok":false,"reason":"invalid_saved_slot"}
		# An unequipped slot is legitimate, including a detached new instance.
		if str(raw).is_empty(): continue
		if not (known as Array).has(raw) or not moves.has(raw) or str(moves.slot(raw))!=slot:
			return {"ok":false,"reason":"unknown_or_wrong_saved_slot"}
	var last: Variant = saved.loadout_last_edit
	if not last is Dictionary: return {"ok":false,"reason":"invalid_last_edit"}
	if int(revision)==0 and not last.is_empty(): return {"ok":false,"reason":"invalid_last_edit"}
	if int(revision)>0:
		var expected_keys := ["edit_id","expected_revision","creature_uid","quick","charged","utility"]
		if last.size()!=expected_keys.size(): return {"ok":false,"reason":"invalid_last_edit"}
		for key: String in expected_keys:
			if not last.has(key): return {"ok":false,"reason":"invalid_last_edit"}
		var previous: Variant = last.expected_revision
		if not (previous is int or previous is float) or not is_finite(float(previous)) \
				or floor(float(previous))!=float(previous) or int(previous)!=int(revision)-1:
			return {"ok":false,"reason":"invalid_last_edit"}
		if not last.edit_id is String or str(last.edit_id).is_empty() or str(last.edit_id).length()>64 \
				or not last.creature_uid is String or str(last.creature_uid)!=str(saved.get("uid","")):
			return {"ok":false,"reason":"invalid_last_edit"}
		for slot: String in ["quick","charged","utility"]:
			if not last[slot] is String or last[slot]!=saved["move_"+slot]:
				return {"ok":false,"reason":"invalid_last_edit"}
	var values := {}
	for field: String in fields:
		var value: Variant = saved[field]
		values[field] = value.duplicate(true) if value is Array or value is Dictionary else value
	return {"ok":true,"needs_defaults":false,"values":values}
