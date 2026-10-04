extends RefCounted

## Proposed typed discriminator in WorldState.reward_deliveries. ROOT must
## extend world/save/escrow validators and dispatch before mounting this codec.
## This is NOT an item producer or remotely callable authority doorway.
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const SATCHEL := preload("res://scripts/net/satchel_escrow.gd")
const KEYS := {"tidewake": "tidewake_portal_key", "cloudreach": "cloudreach_portal_key",
	"stormwood": "stormwood_portal_key", "biome5": "fifth_portal_key"}
const KIND := "portal_unlock"
const VERSION := 2
const FIELDS := ["version", "kind", "status", "biome", "item", "character_id",
	"world_id", "world_instance_id", "receipt", "key_slot"]


static func receipt(world_instance: String, biome: String, character: String) -> String:
	if world_instance.is_empty() or character.is_empty() or not KEYS.has(biome): return ""
	# A character can spend a newly earned key in a different host world without
	# a former host's receipt refusing it forever. World locator is not identity.
	return KIND + ":" + ("%s\n%s\n%s" % [world_instance, biome, character]).sha256_text()


static func row(world: RefCounted, character: String, biome: String, slot: int) -> Dictionary:
	var instance := SATCHEL.world_instance(world)
	var id := receipt(instance, biome, character)
	if id.is_empty() or str(world.world_id).is_empty() or slot < 0 or slot >= 24: return {}
	return {"version": VERSION, "kind": KIND, "status": "pending", "biome": biome,
		"item": KEYS[biome], "character_id": character, "world_id": str(world.world_id),
		"world_instance_id": instance, "receipt": id, "key_slot": slot}


static func valid(raw: Variant, character: String = "", world_instance: String = "") -> bool:
	if not raw is Dictionary or raw.size() != FIELDS.size(): return false
	for field: String in FIELDS:
		if not raw.has(field): return false
	for field: String in ["kind", "status", "biome", "item", "character_id", "world_id", "world_instance_id", "receipt"]:
		if not raw[field] is String or str(raw[field]).is_empty(): return false
	return _integer(raw.version, VERSION, VERSION) and raw.kind == KIND \
		and raw.status in ["pending", "accepted", "settled"] and KEYS.has(raw.biome) \
		and raw.item == KEYS[raw.biome] and _integer(raw.key_slot, 0, 23) \
		and raw.receipt == receipt(raw.world_instance_id, raw.biome, raw.character_id) \
		and (character.is_empty() or raw.character_id == character) \
		and (world_instance.is_empty() or raw.world_instance_id == world_instance)


## Actual owner receipt delivery. Only a validated committed host journal row
## may reach this call. Client intent/ACK cannot supply or replace this row.
## No ACK or successful portal result until this exact bool save succeeds.
static func settle_owner(game: Node, committed: Dictionary) -> Dictionary:
	var player: RefCounted = game.get("local")
	if player == null or not valid(committed, str(player.character_id)):
		return {"ok": false, "reason": "The portal receipt is invalid."}
	var world: RefCounted = game.get("world")
	if world == null or not valid(committed, str(player.character_id), str(world.reward_delivery_namespace)) or committed.world_id != world.world_id:
		return {"ok": false, "reason": "The portal belongs to another world."}
	var session: Node = game.get("session")
	if session == null or session.call("_owner_portal_conflicting_transaction", player) == true:
		return {"ok": false, "pending": true, "reason": "Your character transaction is still being saved."}
	var saver: RefCounted = game.get("save_system")
	if saver == null or bool(saver.call("fallback_busy")):
		return {"ok": false, "pending": true, "reason": "The portal is waiting for your character save."}
	var id: String = committed.receipt
	var prior: Variant = player.satchel_escrow.get(id)
	if prior is Dictionary and prior.get("status") == "settled":
		var expected := committed.duplicate(true)
		expected.status = "settled"
		if not equivalent(prior, expected): return {"ok": false, "reason": "The portal receipt changed."}
		# Read-only durable settlement reuse: the caller can resend exact ACK.
		return {"ok": true, "duplicate": true, "receipt": id}
	var before_slots := RULES.slots(player.inventory)
	var before_personal: Dictionary = player.redesign_character.duplicate(true)
	var before_escrow: Dictionary = player.satchel_escrow.duplicate(true)
	var before_revision: int = player.inventory.revision
	# The key may have moved to a different backpack slot between request and
	# commit. The host's slot is evidence of its admitted snapshot, not a command
	# to destroy a later occupant. Find the same canonical protected key once.
	var slot := -1
	for index: int in before_slots.size():
		var stack: Variant = before_slots[index]
		if stack is Dictionary and stack.get("id") == committed.item:
			if slot >= 0 or stack.get("n") != 1:
				return {"ok": false, "pending": true, "reason": "Your protected portal key is not ready."}
			slot = index
	if slot < 0:
		return {"ok": false, "pending": true, "reason": "Your earned portal key is still being delivered."}
	if session.call("_begin_owner_portal_install", player, world, committed, slot) != true:
		return {"ok": false, "pending": true, "reason": "The portal owner transaction could not be prepared."}
	player.inventory.set_slot(slot, null)
	if not player.inventory.stack_at(slot).is_empty():
		session.call("_end_owner_portal_install")
		return {"ok": false, "pending": true, "reason": "Your key is waiting for your character transaction."}
	if committed.biome != "biome5" and not player.redesign_character.portal_unlocks.has(committed.biome):
		player.redesign_character.portal_unlocks.append(committed.biome)
	# The fifth arch is presentation only. Its personal receipt is the canonical
	# character stir fact; do not add biome5 to portal_unlocks or a realm permit.
	if not player.redesign_character.transaction_receipts.has(id):
		player.redesign_character.transaction_receipts.append(id)
	var settled := committed.duplicate(true)
	settled.status = "settled"
	player.satchel_escrow[id] = settled
	if not bool(saver.call("save_character_prepared", game, str(player.character_id))):
		session.get("_owner_portal_install")["rollback"] = true
		SATCHEL.apply_slots(player.inventory, before_slots)
		player.inventory.revision = before_revision
		player.redesign_character = before_personal
		player.satchel_escrow = before_escrow
		session.call("_end_owner_portal_install")
		return {"ok": false, "pending": true, "reason": "The portal is waiting for your character save. Your key is safe."}
	session.call("_end_owner_portal_install")
	return {"ok": true, "duplicate": false, "receipt": id}


static func world_errors(raw: Variant, world_instance: String, world_id: String) -> Array[String]:
	var errors: Array[String] = []
	if not raw is Dictionary: return ["portal delivery carrier must be an object"]
	for id: Variant in raw:
		var value: Variant = raw[id]
		if str(id).begins_with(KIND + ":") or (value is Dictionary and value.get("kind") == KIND):
			if not valid(value, "", world_instance) or value.get("world_id") != world_id \
					or str(id) != str(value.get("receipt")) or value.get("status") == "settled":
				errors.append("invalid portal world receipt " + str(id))
	return errors


static func equivalent(left: Variant, right: Variant) -> bool:
	if left is Dictionary and right is Dictionary:
		if left.size() != right.size(): return false
		for key: Variant in left:
			if not right.has(key) or not equivalent(left[key], right[key]): return false
		return true
	return typeof(left) == typeof(right) and left == right


static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) \
		and float(value) == floor(float(value)) and float(value) >= minimum and float(value) <= maximum
