extends RefCounted

## Home Key debt and physical settlement are full-character CAS actions on
## the existing Foundation delivery carrier. The existing portal_escrow view
## also carries these strictly typed finite reward rows; it is not a new save.
const REWARD := preload("res://scripts/net/reward_delivery.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const ACTIONS := ["home_key_owe", "home_key_deliver"]


static func candidate(raw: Variant) -> bool:
	return raw is Dictionary and raw.get("kind") == "reward_delivery" \
		and str(raw.get("source", "")).begins_with("home_key:grant:")


static func valid_escrow(raw: Variant, character: String) -> bool:
	if not candidate(raw) or character.is_empty() or raw.get("character_id") != character \
		or raw.get("source") != "home_key:grant:" + character or raw.get("status") not in ["grant_due", "settled"]:
		return false
	for field: String in ["world_id", "world_namespace", "delivery_id"]:
		if not raw.get(field) is String or raw[field].is_empty() or raw[field].length() > 192: return false
	var expected := REWARD.make_record(raw.world_id, raw.world_namespace, raw.source, character, "home_key", 1, "home_key_given")
	if expected.is_empty(): return false
	expected.kind = "reward_delivery"
	expected.status = raw.status
	if raw.status == "settled":
		expected.erase("stacks")
		expected.erase("completion_flag")
	if raw.has("room_message_shown"):
		if not raw.room_message_shown is bool: return false
		expected.room_message_shown = raw.room_message_shown
	# JSON preserves the same bounded numeric value as a float. The existing
	# exact recursive comparison keeps fields, strings, booleans and hash strict.
	return ESSENCE._equivalent(raw, expected)


## The older ordinary RewardDelivery producer saved these aliases after
## suppressing another world's duplicate. Preserve them in the portable save,
## but they are never independent debt or physical-possession authority.
static func is_settled_alias(raw: Variant, character: String) -> bool:
	if not candidate(raw) or raw.get("status") != "settled" or not raw.get("finite_duplicate_of") is String:
		return false
	var marker: String = raw.finite_duplicate_of
	if marker != "home_key_given" and (marker.length() != 64 or not marker.is_valid_hex_number(false) \
		or marker.to_lower() != marker or marker == raw.get("delivery_id")): return false
	var original_shape: Dictionary = raw.duplicate(true)
	original_shape.erase("finite_duplicate_of")
	return valid_escrow(original_shape, character)


static func due(world_record: Dictionary, character: String) -> Dictionary:
	if world_record.get("status") not in ["pending", "accepted"]: return {}
	var row := world_record.duplicate(true)
	row.kind = "reward_delivery"
	row.status = "grant_due"
	return row if valid_escrow(row, character) else {}


static func key_count(personal: Dictionary) -> int:
	var slots: Variant = personal.get("inventory")
	if not slots is Array or slots.size() != INVENTORY.SLOT_COUNT or not BAG.valid_slots(slots): return -1
	var count := 0
	for stack: Variant in slots:
		if stack is Dictionary and stack.get("id") == "home_key": count += int(stack.n)
	return count


static func stage(current: Dictionary, action: String, intent: Dictionary, context: Dictionary) -> Dictionary:
	var character: String = str(current.get("character_id", ""))
	var source: Variant = context.get("home_key_record")
	if action not in ACTIONS or intent.size() != 2 or not intent.get("delivery_id") is String \
		or not intent.get("origin_namespace") is String or context.get("home_key_authorized") != true \
		or not valid_escrow(source, character) or source.delivery_id != intent.delivery_id \
		or source.world_namespace != intent.origin_namespace \
		or context.get("source_key") != "opening_home_key:" + intent.delivery_id:
		return _deny("finite_home_key_source_required")
	var carriers: Variant = current.get("portal_escrow")
	if not carriers is Dictionary: return _deny("invalid_home_key_carrier")
	var prior: Variant = carriers.get(intent.delivery_id)
	var next := current.duplicate(true)
	if action == "home_key_owe":
		if prior != null or source.status != "grant_due": return _deny("home_key_already_owed")
		next.portal_escrow[intent.delivery_id] = source.duplicate(true)
	else:
		# A packet cannot manufacture a debt. The exact original finite row is
		# already held by admission or by the saved host-authored owe action.
		if not valid_escrow(prior, character) or not ESSENCE._equivalent(prior, source) or prior.status != "grant_due":
			return _deny("admitted_home_key_debt_required")
		var count := key_count(current)
		if count < 0 or count > 1: return _deny("invalid_protected_key_count")
		if count == 0:
			var bag := BAG.inventory_from(current.inventory)
			if not BAG.give_stack(bag, {"id": "home_key", "n": 1}): return _deny("home_key_bag_full")
			next.inventory = BAG.slots(bag)
		var settled: Dictionary = source.duplicate(true)
		settled.status = "settled"
		settled.erase("stacks")
		settled.erase("completion_flag")
		next.portal_escrow[intent.delivery_id] = settled
	var receipt := "craft:%s_%s:%s" % [action, intent.delivery_id, character]
	var receipts: Variant = next.get("redesign_character", {}).get("transaction_receipts")
	var limit: Variant = preload("res://scripts/data/redesign_data.gd").json("res://data/config/essence.json").get("maximum_transaction_receipts")
	if not receipts is Array or not (limit is int or limit is float) or not is_finite(float(limit)) \
		or float(limit) != floor(float(limit)) or float(limit) < 1.0 or float(limit) > 65536.0 \
		or receipts.size() >= int(limit): return _deny("transaction_receipt_limit")
	if receipts.has(receipt): return _deny("reconcile_original_decision")
	receipts.append(receipt)
	return {"ok": true, "state": next, "receipt": receipt}


## Called within CharacterActionOwner's existing exact-install/BOOL-save
## fence. Inventory was already installed from the host-authored row.after.
static func install_owner(player: RefCounted, row: Dictionary) -> bool:
	if row.get("action") not in ACTIONS: return true
	var after: Dictionary = row.after
	var id: String = row.intent.delivery_id
	var escrow: Variant = after.portal_escrow.get(id)
	if not valid_escrow(escrow, player.character_id): return false
	if row.action == "home_key_deliver" and (key_count(after) != 1 or escrow.status != "settled"): return false
	player.satchel_escrow[id] = escrow.duplicate(true)
	if row.action == "home_key_deliver": player.flags.call("set_flag", "home_key_given", true)
	return true


static func _deny(code: String) -> Dictionary:
	return {"ok": false, "durable": false, "code": code}
