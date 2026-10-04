extends RefCounted

## F31 paid Homestead stations and attachments on the EXISTING Altar building
## journal. A version-2 row keeps the Altar's discriminator (`altar_building`),
## delivery id, host world BOOL, owner BOOL, typed ACK and paid-provenance
## refund; only its canonical building record grows the stable F31 placement
## identity (`parent_uid`, `slot`). Version-1 Altar rows keep their six-field
## record and their codec in world_state.gd unchanged; the Altar itself never
## takes this codec.
##
## Pure static policy: no node registry, inventory write, save or RPC. The
## host Session stages, LedgerRpc journals and WorldLedger commits; every one
## of them and every saved-world reader re-derives the same row through
## `row_valid` before trusting it.
const E := preload("res://scripts/creatures/essence.gd")
const STATION_RULES := preload("res://scripts/build/station_rules.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const CATALOGUE := "res://data/items/buildables.json"
const VERSION := 2
const KIND := "altar_building"
const RECORD_FIELDS := ["id", "realm", "uid", "position", "yaw_deg", "paid", "parent_uid", "slot"]
const PLACE_REQUEST_FIELDS := ["kind", "realm", "id", "position", "yaw_deg", "paid", "txn_id", "parent_uid"]
const DISMANTLE_REQUEST_FIELDS := ["kind", "realm", "uid", "txn_id"]


## Every authored homestead station/attachment/auxiliary id except the Altar.
static func journaled_id(id: Variant) -> bool:
	return id is String and id != "altar" and STATION_RULES.homestead_id(id)


## Mirrors BuildPlacer._station_path: the pre-F31 Workbench keeps its legacy
## route only while the whole station runtime is switched off.
static func requires_journal(id: Variant) -> bool:
	return journaled_id(id) and (id != "workbench" or STATION_RULES.config().get("runtime_enabled") == true)


## Same formula as WorldState.altar_build_id: one immutable per-action id in
## the existing journal namespace (and its existing `altar_building:` guards).
static func delivery_id(world_namespace: String, character: String, txn: String) -> String:
	return "altar_building:" + JSON.stringify([world_namespace, character, txn]).sha256_text() \
		if E._opaque_id(world_namespace) and E._component(character) and E._opaque_id(txn) else ""


static func txn_valid(raw: Variant) -> bool:
	if not raw is String or raw.length() != 32: return false
	for code: int in raw.to_utf8_buffer():
		if not (code >= 48 and code <= 57) and not (code >= 97 and code <= 102): return false
	return true


static func uid_valid(raw: Variant) -> bool:
	if not raw is String or not raw.begins_with("b") or not raw.substr(1).is_valid_int(): return false
	var n := int(raw.substr(1))
	return n >= 1 and n <= 2147483646 and raw == "b%d" % n


## The settled price: exactly one `homestead_buildables` row. A legacy table
## row with the same id (the Workbench) must carry the same price, and a live
## attachment's stations.json cost must agree, or nothing is priced at all.
static func cost(id: String) -> Array:
	if not journaled_id(id): return []
	# Authored data is immutable at runtime; the ghost asks every frame.
	if not _catalogue_loaded:
		_catalogue_loaded = true
		_catalogue = DATA.json(CATALOGUE)
	return cost_from(_catalogue, STATION_RULES.config(), id)

static var _catalogue: Variant = null
static var _catalogue_loaded := false


static func cost_from(catalogue: Variant, cfg: Dictionary, id: String) -> Array:
	if not journaled_id(id) or cfg.is_empty() or not catalogue is Dictionary \
		or not catalogue.get("homestead_buildables") is Array or not catalogue.get("buildables") is Array: return []
	var found: Variant = null
	for raw: Variant in catalogue.homestead_buildables:
		if raw is Dictionary and raw.get("id") == id:
			if found != null: return [] # Duplicates never pick a price by order.
			found = raw
	if not found is Dictionary or not STATION_RULES.valid_cost(found.get("cost")): return []
	var price := _canonical_cost(found.cost)
	for raw: Variant in catalogue.buildables:
		if raw is Dictionary and raw.get("id") == id and not E._equivalent(_canonical_cost(raw.get("cost")), price): return []
	var def := STATION_RULES.attachment(cfg, id)
	if not def.is_empty():
		if def.get("status") != "live" or def.get("registered") != true \
			or not E._equivalent(_canonical_cost(def.get("cost")), price): return []
	elif not STATION_RULES.station(cfg, id) and not cfg.get("auxiliary_buildables", []).has(id): return []
	return price


static func _canonical_cost(raw: Variant) -> Array:
	if not STATION_RULES.valid_cost(raw): return []
	var out: Array = []
	for row: Dictionary in raw: out.append({"id": str(row.id), "n": int(row.n)})
	return out


## Canonical version-2 placed-building record (WorldState.placed_buildings
## entry and journal intent.record). A base station has parent_uid "" and
## slot 0; an attachment names its parent station's UID and its biome slot.
static func record_valid(record: Variant) -> bool:
	if not record is Dictionary or record.size() != RECORD_FIELDS.size(): return false
	for field: String in RECORD_FIELDS:
		if not record.has(field): return false
	if not journaled_id(record.id) or record.realm != "meadows" or not record.paid is bool or record.paid != true \
		or not uid_valid(record.uid) or not record.position is Array or record.position.size() != 3 \
		or not STATION_RULES.number(record.yaw_deg) or not record.parent_uid is String: return false
	for cell: Variant in record.position:
		if not STATION_RULES.number(cell): return false
	var def := STATION_RULES.attachment(STATION_RULES.config(), record.id)
	if record.parent_uid.is_empty():
		return def.is_empty() and E._integer(record.slot, 0, 0)
	return not def.is_empty() and def.get("status") == "live" and def.get("registered") == true \
		and uid_valid(record.parent_uid) and record.parent_uid != record.uid \
		and E._integer(record.slot, 1, 8) and int(record.slot) == int(def.tier)


static func request_valid(request: Variant, action: String, txn: String, record: Dictionary) -> bool:
	if not request is Dictionary or request.get("txn_id") != txn or request.get("kind") != action \
		or request.get("realm") != "meadows": return false
	var fields: Array = PLACE_REQUEST_FIELDS if action == "place_building" else DISMANTLE_REQUEST_FIELDS
	if request.size() != fields.size(): return false
	for field: String in fields:
		if not request.has(field): return false
	if action == "dismantle": return request.uid == record.get("uid")
	return request.id == record.get("id") and request.paid is bool and request.paid == true \
		and request.parent_uid is String and request.parent_uid == record.get("parent_uid") \
		and E._equivalent(request.position, record.get("position")) \
		and E._equivalent(request.yaw_deg, record.get("yaw_deg"))


## The only permitted personal mutation for one paid placement (debit) or one
## proven dismantle (refund of the same settled price). Same baseline and
## receipt-budget rules as the version-1 Altar transition.
static func transition(full: Dictionary, character: String, revision: int,
		action: String, txn: String, record: Dictionary, world_namespace: String) -> Dictionary:
	const RULES = preload("res://scripts/world/death_satchel_rules.gd")
	if not txn_valid(txn) or not action in ["place_building", "dismantle"] or revision < 0 or revision >= 2147483647 \
		or not record_valid(record) or delivery_id(world_namespace, character, txn).is_empty() \
		or not E._baseline_errors(full, character).is_empty(): return {}
	if not preload("res://scripts/creatures/teaching.gd").admitted_party_errors(full.party, full.redesign_character).is_empty(): return {}
	var price := cost(record.id)
	if price.is_empty(): return {}
	var receipt := "craft:%s:homestead_build:%s:%s:%s:%s" % [character, world_namespace.sha256_text(), txn, action, record.uid]
	var cfg: Dictionary = E.config()
	if not E._integer(cfg.get("maximum_transaction_receipts"), 1, 65536) \
		or full.redesign_character.transaction_receipts.size() >= int(cfg.maximum_transaction_receipts) \
		or full.redesign_character.transaction_receipts.has(receipt): return {}
	var inv := RULES.inventory_from(full.inventory)
	for need: Dictionary in price:
		if action == "place_building":
			if inv.count(need.id) < int(need.n) or not inv.remove(need.id, int(need.n)): return {}
		elif inv.add(need.id, int(need.n)) != 0: return {}
	var next := full.duplicate(true)
	next.inventory = RULES.slots(inv)
	next.redesign_character.transaction_receipts.append(receipt)
	if not E._baseline_errors(next, character).is_empty(): return {}
	return {"ok": true, "character_id": character, "action": action, "action_id": txn,
		"character_revision": revision + 1, "receipt": receipt, "before": full.duplicate(true),
		"state": next, "record": record.duplicate(true), "cost": price}


## Version-2 journal row. Same sixteen fields and three-field portable
## projection as version 1; the transition is recomputed, never trusted.
static func row_valid(raw: Variant, world_namespace: String, world_id: String = "") -> bool:
	if not raw is Dictionary or raw.size() != E.TRAINING_ROW_FIELDS.size(): return false
	for field: String in E.TRAINING_ROW_FIELDS:
		if not raw.has(field): return false
	if raw.kind != KIND or not E._integer(raw.version, VERSION, VERSION) \
		or not E._integer(raw.journal_revision, 1, 1) or not E._integer(raw.character_revision, 1, 2147483647) \
		or not raw.status in ["pending", "accepted"] or not raw.action in ["place_building", "dismantle"] \
		or raw.world_namespace != world_namespace or not E._opaque_id(raw.world_id) \
		or not E._opaque_id(raw.session_id) or (not world_id.is_empty() and raw.world_id != world_id) \
		or not raw.character_id is String or not raw.action_id is String \
		or raw.delivery_id != delivery_id(world_namespace, raw.character_id, raw.action_id) \
		or not raw.intent is Dictionary or raw.intent.size() != 3 \
		or not raw.intent.get("request") is Dictionary or not record_valid(raw.intent.get("record")) \
		or not raw.intent.get("cost") is Array or not raw.before is Dictionary or not raw.after is Dictionary \
		or raw.before.size() != 3 or raw.after.size() != 3: return false
	if not request_valid(raw.intent.request, raw.action, raw.action_id, raw.intent.record): return false
	var full: Dictionary = raw.before.duplicate(true)
	full.character_id = raw.character_id
	var proposal := transition(full, raw.character_id, int(raw.character_revision) - 1,
		raw.action, raw.action_id, _integral_record(raw.intent.record), world_namespace)
	return proposal.get("ok") == true and proposal.receipt == raw.receipt \
		and E._equivalent(proposal.cost, raw.intent.cost) \
		and E._equivalent(E.training_projection(proposal.state), raw.after)


## JSON reloads integral numbers as floats; the receipt and recomputation use
## the exact integral slot, never a coerced fraction (record_valid refused one).
static func _integral_record(record: Dictionary) -> Dictionary:
	var out := record.duplicate(true)
	out.slot = int(record.slot)
	return out


## The world placed-building record a committed version-2 op must produce.
static func placed_record(op: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for field: String in RECORD_FIELDS:
		if not op.has(field): return {}
		out[field] = op[field].duplicate(true) if op[field] is Array else op[field]
	return out if record_valid(out) else {}
