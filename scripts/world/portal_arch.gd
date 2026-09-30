extends Node3D

## Personal portal escrow is a typed transaction within the existing portable
## escrow carrier. The host world persists its receipt before the owning peer
## atomically writes its key debit, portable unlock and acknowledgement.
const ORDER := preload("res://scripts/data/biome_order.gd")
const ITEMS := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const CONFIG_PATH := "res://data/config/portals.json"
const KIND := "portal_unlock"
const VERSION := 1
const KEYS := {"tidewake": "tidewake_portal_key", "cloudreach": "cloudreach_portal_key",
	"stormwood": "stormwood_portal_key", "biome5": "fifth_portal_key"}
const ROW_KEYS := ["version", "kind", "status", "biome", "item", "character_id",
	"world_id", "world_instance_id", "receipt", "key_slot"]


static func receipt(biome: String, character_id: String) -> String:
	return "portal_unlock:%s:%s" % [biome, character_id]


static func ack_receipt(biome: String, character_id: String) -> String:
	return "portal_ack:%s:%s" % [biome, character_id]


## ACK is sent only after the owning character's atomic settlement. The host
## rebinds transport identity and refuses a receipt without its own durable
## world transaction. Replayed ACKs carry no item or portable mutation.
static func ack_ops(intent: Dictionary, world: RefCounted, admitted_character: String) -> Dictionary:
	var biome := str(intent.get("biome", ""))
	var instance := str(world.get("reward_delivery_namespace"))
	if not KEYS.has(biome) or admitted_character.is_empty() or admitted_character.contains(":"):
		return _refuse("wrong_actor", "That portal acknowledgement belongs to another character.")
	var id := receipt(biome, admitted_character)
	if instance.is_empty() or intent.get("world_instance_id") != instance:
		return _refuse("wrong_world", "That portal acknowledgement belongs to its original host world.")
	if intent.get("receipt") != id or not bool(world.get("flags").call("has", id)):
		return _refuse("no_receipt", "The host has not saved that portal yet.")
	return {"ok": true, "ops": [{"op": "portal_ack", "scope": "world", "realm": "meadows",
		"biome": biome, "character_id": admitted_character, "world_instance_id": instance, "receipt": id}]}


## Called only with host-resolved actor/arch positions and admitted identity.
## Owned inventory comes from the host admitted record and saved award journal;
## the request cannot supply identity, ownership, position or destination. The
## existing ledger owns persistence.
static func host_ops(intent: Dictionary, actor: Dictionary, world: RefCounted,
		peer_id: int, admitted_character: String) -> Dictionary:
	var biome := str(intent.get("biome", ""))
	if not KEYS.has(biome):
		return _refuse("unknown_arch", "That arch is still sealed.")
	var instance := str(world.get("reward_delivery_namespace"))
	if instance.is_empty() or intent.get("world_instance_id") != instance:
		return _refuse("wrong_world", "That pending portal key belongs to its original host world.")
	if admitted_character.is_empty() or admitted_character.contains(":") \
			or int(actor.get("peer", 0)) != peer_id or str(actor.get("character_id", "")) != admitted_character:
		return _refuse("wrong_actor", "Your admitted character is not ready at this arch.")
	var id := receipt(biome, admitted_character)
	if str(intent.get("txn_id", "")) != id:
		return _refuse("wrong_actor", "That portal receipt belongs to another character.")
	if str(intent.get("realm", "")) != "meadows" or str(actor.get("realm", "")) != "meadows":
		return _refuse("wrong_realm", "Use the portal key at its Crossing Hall arch.")
	var at: Variant = actor.get("position")
	var arch: Variant = actor.get("arch_position")
	if not at is Vector3 or not arch is Vector3 or not at.is_finite() or not arch.is_finite():
		return _refuse("not_ready", "The host cannot locate that arch yet.")
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var radius: Variant = config.get("arch_interaction_radius_m") if config is Dictionary else null
	if not (radius is float or radius is int) or not is_finite(float(radius)) or float(radius) <= 0:
		return _refuse("not_ready", "The arch is not ready to accept a key.")
	if at.distance_to(arch) > float(radius):
		return _refuse("too_far", "Move closer to the portal arch.")
	if actor.get("combat", true) != false:
		return _refuse("combat", "Finish the fight before using a portal key.")
	# A durable receipt already spent this character's key. Recovery can
	# publish only its own personal settlement, never another world debit.
	if bool(world.get("flags").call("has", id)):
		return {"ok": true, "ops": [{"op": "portal_settle", "scope": "player", "realm": "meadows",
			"peers": [peer_id], "world_instance_id": instance, "receipt": id}]}
	# The transport supplies a once-admitted owned baseline or the actual host
	# inventory. Per-request slot arrays cannot create an entitlement.
	var slots: Variant = actor.get("owned_inventory")
	if not RULES.valid_slots(slots):
		return _refuse("malformed", "Your owned portal key could not be checked.")
	var key_count := 0
	var db := ITEMS.new()
	for stack: Variant in slots:
		if stack == null:
			continue
		if not db.has(str(stack.id)):
			return _refuse("malformed", "Your owned portal key could not be checked.")
		if str(stack.id) == KEYS[biome] and int(stack.n) == 1:
			key_count += 1
	# Protected later grants are derived from saved/accepted host reward rows,
	# not a per-request inventory refresh. The transport owns this dictionary.
	var entitlements: Variant = actor.get("owned_portal_keys")
	if entitlements is Dictionary:
		var owned: Variant = entitlements.get(KEYS[biome])
		if not (owned is int or owned is float) or not is_finite(float(owned)) \
				or float(owned) < 0 or float(owned) != floor(float(owned)):
			return _refuse("malformed", "Your owned portal key could not be checked.")
		key_count = int(owned)
	if key_count != 1:
		return _refuse("missing_key", "Needs the %s." % db.item_name(KEYS[biome]))
	return {"ok": true, "ops": [{"op": KIND, "scope": "world", "realm": "meadows",
		"biome": biome, "character_id": admitted_character, "world_instance_id": instance, "receipt": id},
		{"op": "portal_settle", "scope": "player", "realm": "meadows", "peers": [peer_id],
			"world_instance_id": instance, "receipt": id}]}


static func valid_world_op(op: Dictionary, world_instance: String) -> bool:
	var biome := str(op.get("biome", ""))
	var character := str(op.get("character_id", ""))
	return op.get("op") in [KIND, "portal_ack"] and op.get("scope") == "world" \
		and op.get("realm") == "meadows" and KEYS.has(biome) \
		and not character.is_empty() and not character.contains(":") \
		and not world_instance.is_empty() and op.get("world_instance_id") == world_instance \
		and op.get("receipt") == receipt(biome, character)


static func valid_row(raw: Variant, character_id: String) -> bool:
	if not raw is Dictionary or character_id.is_empty() or character_id.contains(":"):
		return false
	var row: Dictionary = raw
	if row.size() != ROW_KEYS.size():
		return false
	for key: String in ROW_KEYS:
		if not row.has(key):
			return false
	for field: String in ["version", "key_slot"]:
		var value: Variant = row[field]
		if not (value is int or value is float) or not is_finite(float(value)) or floorf(float(value)) != float(value):
			return false
	for field: String in ["kind", "status", "biome", "item", "character_id", "world_id", "world_instance_id", "receipt"]:
		if not row[field] is String or str(row[field]).is_empty():
			return false
	return int(row.version) == VERSION and row.kind == KIND and row.status in ["pending", "settled"] \
		and KEYS.has(str(row.biome)) and row.item == KEYS[str(row.biome)] \
		and row.character_id == character_id and row.receipt == receipt(str(row.biome), character_id) \
		and int(row.key_slot) >= 0 and int(row.key_slot) < INVENTORY.SLOT_COUNT


## Other established escrow kinds keep their own validators and semantics.
## Portal entries cannot conceal a malformed kind behind their receipt prefix.
static func escrow_errors(raw: Variant, character_id: String) -> Array[String]:
	var errors: Array[String] = []
	if not raw is Dictionary:
		return ["personal escrow must be an object"]
	for key: Variant in raw:
		var value: Variant = raw[key]
		var portal_key := str(key).begins_with(KIND + ":")
		var portal_kind: bool = value is Dictionary and value.get("kind") == KIND
		if portal_key or portal_kind:
			if not valid_row(value, character_id) or str(key) != str(value.get("receipt", "")):
				errors.append("malformed portal escrow %s" % str(key))
	return errors


static func begin(game: Node, biome: String) -> Dictionary:
	if not KEYS.has(biome):
		return _refuse("unknown_arch", "That arch is still sealed.")
	var player: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var character := str(player.get("character_id"))
	var instance := str(world.get("reward_delivery_namespace"))
	var world_id := str(world.get("world_id"))
	if character.is_empty() or character.contains(":") or instance.is_empty() or world_id.is_empty():
		return _refuse("not_ready", "Your character and this world must be ready before using a portal key.")
	var id := receipt(biome, character)
	var escrow: Dictionary = player.get("satchel_escrow")
	if escrow.has(id):
		var old: Variant = escrow[id]
		if not valid_row(old, character):
			return _refuse("malformed", "That pending portal key could not be checked.")
		if old.status == "settled":
			return {"ok": true, "already_settled": true, "receipt": id}
		if old.world_instance_id != instance or old.world_id != world_id:
			return _refuse("wrong_world", "That pending portal key belongs to its original host world.")
		return {"ok": true, "receipt": id, "pending": true}
	var inventory: RefCounted = player.get("inventory")
	var key_slot := -1
	for index in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", index)
		if str(stack.get("id", "")) == KEYS[biome] and int(stack.get("n", 0)) == 1:
			key_slot = index
			break
	if key_slot < 0:
		return _refuse("missing_key", "Needs the %s." % ITEMS.new().item_name(KEYS[biome]))
	var before: Dictionary = player.call("save_data").duplicate(true)
	escrow[id] = {"version": VERSION, "kind": KIND, "status": "pending", "biome": biome,
		"item": KEYS[biome], "character_id": character, "world_id": world_id,
		"world_instance_id": instance, "receipt": id, "key_slot": key_slot}
	if not _save_personal(game, character):
		player.call("load_data", before)
		return _refuse("journal_failed", "Your portal key could not be recorded. Nothing was spent.")
	return {"ok": true, "receipt": id, "pending": true}


static func settle(game: Node, id: String) -> Dictionary:
	var player: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var character := str(player.get("character_id"))
	var raw: Variant = player.get("satchel_escrow").get(id)
	if not valid_row(raw, character) or str(raw.receipt) != id:
		return _refuse("malformed", "That portal receipt could not be checked.")
	var row: Dictionary = raw
	if row.status == "settled":
		return {"ok": true, "already_settled": true, "receipt": id}
	if row.world_id != str(world.get("world_id")) or row.world_instance_id != str(world.get("reward_delivery_namespace")):
		return _refuse("wrong_world", "That pending portal key belongs to its original host world.")
	var flags: RefCounted = world.get("flags")
	if flags == null or not bool(flags.call("has", id)):
		return _refuse("no_receipt", "The host has not saved that portal yet. Your key remains safe.")
	var before: Dictionary = player.call("save_data").duplicate(true)
	var inventory: RefCounted = player.get("inventory")
	if not bool(inventory.call("remove", str(row.item), 1)):
		return _refuse("missing_key", "Your portal key remains pending until its owned item is available.")
	var redesign: Dictionary = player.get("redesign_character")
	var unlocks: Array = redesign.portal_unlocks
	if str(row.biome) != "biome5" and not unlocks.has(str(row.biome)):
		unlocks.append(str(row.biome))
	var receipts: Array = redesign.transaction_receipts
	if not receipts.has(id):
		receipts.append(id)
	row.status = "settled"
	if not _save_personal(game, character):
		player.call("load_data", before)
		return _refuse("journal_failed", "The host saved the portal, but your character could not save. Your key remains safe for retry.")
	return {"ok": true, "receipt": id}


static func _save_personal(game: Node, character_id: String) -> bool:
	var saver: RefCounted = game.get("save_system")
	return saver != null and bool(saver.call("save_character", game, character_id))


static func _refuse(code: String, reason: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": reason}
