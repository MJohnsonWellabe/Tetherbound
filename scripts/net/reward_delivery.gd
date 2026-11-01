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
	# A finite Home Key entitlement is global to this portable character.
	# An older world's owed row may arrive after another host delivered it.
	# Reuse the existing saved flag/original escrow row before adding a key.
	if row.get("source") == "home_key:grant:" + str(player.character_id):
		if row.get("stacks") != [{"id": "home_key", "n": 1}] or row.get("completion_flag") != "home_key_given":
			return {"ok": false, "changed": changed, "settled": false}
		var original := _existing_home_key_entitlement(player, id)
		if not original.is_empty():
			row.status = "settled"
			row.finite_duplicate_of = original
			row.erase("stacks")
			row.erase("completion_flag")
			return {"ok": true, "changed": true, "settled": true}
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


## F49#0 (Cloudreach 07, coordinator-approved, 1 Nov): a held boss hand-off
## (relic + next portal key, a boss_relic foundation duty refused with
## boss_handoff_make_satchel_room) must not lose its slot to item grants that
## were waiting for room too. A grant that fits but would leave fewer free
## slots than the held hand-off needs stays held (no escrow change, no ACK)
## and retries once the hand-off has landed or more room appears. A grant that
## does not fit consumes nothing anyway (give_all is all-or-nothing).
static func yields_to_hand_off(inventory: RefCounted, stacks: Array, world_deliveries: Dictionary,
		redesign_character: Dictionary, character_id: String, world_namespace: String) -> bool:
	var need := held_hand_off_slots(inventory, world_deliveries, redesign_character, character_id, world_namespace)
	if need <= 0: return false
	var after := free_slots_after(_bag_slots(inventory), stacks)
	return after >= 0 and after < need


## Free slots left after `stacks` were added to `slots` (partial stacks first,
## then empty slots, as Inventory.add does), or -1 when they would not fit.
static func free_slots_after(slots: Array, stacks: Array) -> int:
	var bag: Array = slots.duplicate(true)
	for raw: Variant in stacks:
		if not raw is Dictionary: return -1
		var id := str(raw.get("id", ""))
		var left := int(raw.get("n", 0))
		var maximum: int = maxi(1, int(RULES.db().call("stack_size", id)))
		for i in bag.size():
			if left <= 0: break
			var held: Variant = bag[i]
			if held is Dictionary and str(held.get("id", "")) == id and int(held.get("n", 0)) < maximum:
				var put := mini(maximum - int(held.get("n", 0)), left)
				held["n"] = int(held.get("n", 0)) + put
				left -= put
		for i in bag.size():
			if left <= 0: break
			if bag[i] == null:
				var put := mini(maximum, left)
				bag[i] = {"id": id, "n": put}
				left -= put
		if left > 0: return -1
	var free := 0
	for held: Variant in bag:
		if held == null: free += 1
	return free


## New Satchel slots this character's held boss hand-offs still need: one per
## undelivered portal key that has no carried stack to join. A hand-off is
## delivered once its relic is held/hung or its boss receipt is recorded.
static func held_hand_off_slots(inventory: RefCounted, world_deliveries: Dictionary,
		redesign_character: Dictionary, character_id: String, world_namespace: String) -> int:
	var receipts: Array = redesign_character.get("transaction_receipts", [])
	var relics: Array = (redesign_character.get("relics_held", []) as Array) + (redesign_character.get("relics_hung", []) as Array)
	var keys := {}
	for raw: Variant in world_deliveries.values():
		if not raw is Dictionary or raw.get("kind") != "foundation_event" or raw.get("status") != "retained": continue
		for duty: Variant in raw.get("duties", []):
			if not duty is Dictionary or duty.get("action") != "boss_relic" or duty.get("character_id") != character_id: continue
			var intent: Dictionary = duty.get("intent", {})
			var trainer := str(intent.get("trainer_id", ""))
			if relics.has(intent.get("biome")) or receipts.has("defeat:boss_%s:%s" % [trainer, character_id]) \
					or receipts.has(preload("res://scripts/net/foundation_actions.gd").boss_receipt(world_namespace, trainer, character_id)):
				continue
			var grant := preload("res://scripts/net/encounter_rewards.gd").chapter_hand_off(trainer, str(duty.get("context", {}).get("realm", "")))
			var key := str(grant.get("portal_key_item", ""))
			if not key.is_empty(): keys[key] = true
	var need := 0
	for key: String in keys:
		var maximum: int = maxi(1, int(RULES.db().call("stack_size", key)))
		var joins := false
		for held: Variant in _bag_slots(inventory):
			if held is Dictionary and str(held.get("id", "")) == key and int(held.get("n", 0)) < maximum: joins = true
		if not joins: need += 1
	return need


static func _bag_slots(inventory: RefCounted) -> Array:
	return RULES.slots(inventory)


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


static func _existing_home_key_entitlement(player: RefCounted, incoming: String) -> String:
	if player.flags.call("has", "home_key_given") == true: return "home_key_given"
	for key: Variant in player.satchel_escrow:
		if key == incoming: continue
		var row: Variant = player.satchel_escrow[key]
		if not row is Dictionary or row.get("kind") != "reward_delivery" or row.get("source") != "home_key:grant:" + str(player.character_id) or row.get("character_id") != player.character_id or row.has("finite_duplicate_of"): continue
		if key != row.get("delivery_id") or delivery_id(str(row.get("world_namespace", "")), str(row.get("source", "")), str(row.get("character_id", ""))) != key: continue
		if row.get("status") == "settled": return str(key)
		if row.get("status") == "grant_due" and row.get("stacks") == [{"id": "home_key", "n": 1}] and row.get("completion_flag") == "home_key_given": return str(key)
	return ""
