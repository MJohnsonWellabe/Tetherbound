extends RefCounted

## Durable, player-inaccessible delivery receipts for authored reward_grant
## items. Rows live in PlayerState.satchel_escrow only because it is already the
## portable transaction journal; they are never death satchels or bag slots.

const VERSION := 1
const INVENTORY := preload("res://autoload/inventory.gd")
const SATCHEL_ESCROW := preload("res://scripts/net/satchel_escrow.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")


static func delivery_id(world_namespace: String, source: String, character_id: String) -> String:
	if world_namespace.is_empty() or source.is_empty() or character_id.is_empty():
		return ""
	return ("reward-delivery-v1\n%s\n%s\n%s" % [world_namespace, source, character_id]).sha256_text()


static func make_record(world_id: String, world_namespace: String, source: String, character_id: String,
		item: String, count: int, completion_flag: String = "") -> Dictionary:
	var id := delivery_id(world_namespace, source, character_id)
	if id.is_empty() or (not item.is_empty() and count <= 0):
		return {}
	var stacks: Array = []
	if not item.is_empty():
		var remaining := count
		var stack_size: int = maxi(1, int(RULES.db().call("stack_size", item)))
		while remaining > 0 and stacks.size() < INVENTORY.SLOT_COUNT:
			var portion := mini(remaining, stack_size)
			stacks.append({"id": item, "n": portion})
			remaining -= portion
		if remaining > 0:
			return {}
	if not RULES.valid_slots(stacks):
		return {}
	return {
		"version": VERSION,
		"delivery_id": id,
		"world_id": world_id,
		"world_namespace": world_namespace,
		"source": source,
		"character_id": character_id,
		"stacks": stacks,
		"completion_flag": completion_flag,
		"status": "pending",
	}


## Idempotently stage and, when all stacks fit, settle one delivery. The caller
## owns the character save and scoped rollback around this mutation.
static func apply(player: RefCounted, delivery: Dictionary) -> Dictionary:
	var id := str(delivery.get("delivery_id", ""))
	var expected_id := delivery_id(str(delivery.get("world_namespace", "")),
		str(delivery.get("source", "")), str(delivery.get("character_id", "")))
	if int(delivery.get("version", 0)) != VERSION or id.is_empty() \
			or id != expected_id \
			or str(delivery.get("character_id", "")) != str(player.get("character_id")) \
			or not RULES.valid_slots(delivery.get("stacks", [])):
		return {"ok": false, "changed": false, "settled": false}
	var changed := false
	if not player.satchel_escrow.has(id):
		var row := delivery.duplicate(true)
		row["kind"] = "reward_delivery"
		row["status"] = "grant_due"
		player.satchel_escrow[id] = row
		changed = true
	var raw: Variant = player.satchel_escrow.get(id)
	if not raw is Dictionary:
		return {"ok": false, "changed": changed, "settled": false}
	var row: Dictionary = raw
	if str(row.get("kind", "")) != "reward_delivery" \
			or str(row.get("character_id", "")) != str(player.get("character_id")) \
			or str(row.get("delivery_id", "")) != id \
			or delivery_id(str(row.get("world_namespace", "")), str(row.get("source", "")),
				str(row.get("character_id", ""))) != id:
		return {"ok": false, "changed": changed, "settled": false}
	if str(row.get("status", "")) == "settled":
		return {"ok": true, "changed": changed, "settled": true}
	if str(row.get("status", "")) != "grant_due":
		return {"ok": false, "changed": changed, "settled": false}
	if not SATCHEL_ESCROW.give_all(player.get("inventory"), row.get("stacks", [])):
		return {"ok": true, "changed": changed, "settled": false}
	var flag := str(row.get("completion_flag", ""))
	var flags: Variant = player.get("flags")
	if not flag.is_empty() and flags != null:
		(flags as RefCounted).call("set_flag", flag, true)
	row["status"] = "settled"
	row.erase("stacks")
	row.erase("completion_flag")
	return {"ok": true, "changed": true, "settled": true}


static func pending_for_character(world: RefCounted, character_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var deliveries: Variant = world.get("reward_deliveries")
	if not deliveries is Dictionary:
		return out
	for raw: Variant in (deliveries as Dictionary).values():
		if raw is Dictionary and str(raw.get("status", "")) == "pending" \
				and str(raw.get("character_id", "")) == character_id:
			out.append((raw as Dictionary).duplicate(true))
	return out
