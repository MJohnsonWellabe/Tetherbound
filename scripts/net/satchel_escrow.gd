extends RefCounted
## Durable per-character transaction escrow. It is inaccessible to gameplay;
## only the host receipt or explicit refusal settles it. Never refund on exit.
const RULES := preload("res://scripts/world/death_satchel_rules.gd")

static func begin_drop(player: RefCounted, world: RefCounted, at: Vector3, realm: String, origin_host: bool) -> String:
	var slots := RULES.slots(player.inventory)
	if player.inventory.used_slots() == 0:
		return ""
	var txn := Crypto.new().generate_random_bytes(16).hex_encode()
	player.satchel_escrow[txn] = {"status": "pending", "kind": "death_satchel_create", "world_id": str(world.world_id),
		"character_id": str(player.character_id), "origin_host": origin_host, "stacks": slots,
		"intent": {"kind": "death_satchel_create", "realm": realm, "txn_id": txn, "state": slots, "position": [at.x, at.y, at.z]}}
	player.inventory.drain()
	return txn

static func begin_transfer(player: RefCounted, world: RefCounted, uid: String, direction: String, item: String, count: int, expected: int, origin_host: bool) -> String:
	var index: int = world.death_satchel_index_of(uid)
	if index < 0:
		return ""
	var record: Dictionary = world.death_satchels[index]
	if str(record.get("realm", "meadows")) != str(player.realm) or (not str(record.get("owner", "")).is_empty() and str(record.owner) != str(player.character_id)):
		return ""
	for row: Variant in player.satchel_escrow.values():
		if row is Dictionary and str(row.get("world_id", "")) == str(world.world_id) and str(row.get("uid", "")) == uid and str(row.get("status", "")) != "settled":
			return ""
	var personal := RULES.slots(player.inventory)
	var preview := RULES.preview(record.get("state", []), personal, direction, item, count)
	if preview.is_empty():
		return ""
	var txn := Crypto.new().generate_random_bytes(16).hex_encode()
	player.satchel_escrow[txn] = {"status": "pending", "kind": "death_satchel_transfer", "uid": uid,
		"world_id": str(world.world_id), "character_id": str(player.character_id), "origin_host": origin_host,
		"direction": direction, "stacks": preview.stacks,
		"intent": {"kind": "death_satchel_transfer", "realm": str(record.get("realm", "meadows")), "uid": uid,
			"txn_id": txn, "direction": direction, "item": item, "count": count, "expected_revision": expected, "personal": personal}}
	if direction == "deposit":
		_apply_slots(player.inventory, preview.personal)
	return txn

static func reconcile(player: RefCounted, world: RefCounted) -> bool:
	var changed := false
	for key: Variant in player.satchel_escrow.keys():
		var raw: Variant = player.satchel_escrow[key]
		if not raw is Dictionary:
			continue
		var row: Dictionary = raw
		if not belongs(row, player, world) or str(row.get("status", "")) == "settled":
			continue
		var txn := str(key)
		var uid := "death_" + txn if str(row.get("kind", "")) == "death_satchel_create" else str(row.get("uid", ""))
		var index: int = world.death_satchel_index_of(uid)
		if str(row.get("status", "")) == "pending" and index >= 0:
			var record: Dictionary = world.death_satchels[index]
			var owns := str(record.get("owner", "")).is_empty() or str(record.owner) == str(player.character_id)
			var committed := str(row.get("kind", "")) == "death_satchel_create" or (record.get("transactions", []) as Array).has(txn)
			if owns and committed:
				row.status = "grant_due" if str(row.get("direction", "")) == "withdraw" else "settled"
				changed = true
		if str(row.get("status", "")) in ["grant_due", "refund_due"]:
			if _give_all(player.inventory, row.get("stacks", [])):
				row.status = "settled"
				changed = true
		if str(row.get("status", "")) == "settled":
			row.erase("stacks")
			row.erase("intent")
	return changed

static func refuse(player: RefCounted, world: RefCounted, txn: String) -> bool:
	if not player.satchel_escrow.has(txn):
		return false
	if not player.satchel_escrow[txn] is Dictionary:
		return false
	var row: Dictionary = player.satchel_escrow[txn]
	if not belongs(row, player, world) or str(row.get("status", "")) != "pending":
		return false
	# A late refusal cannot undo a commit already visible in the world receipt.
	reconcile(player, world)
	if str(row.get("status", "")) != "pending":
		return false
	row.status = "settled" if str(row.get("direction", "")) == "withdraw" else "refund_due"
	if str(row.status) == "settled":
		row.erase("stacks")
		row.erase("intent")
	reconcile(player, world)
	return true

static func belongs(row: Dictionary, player: RefCounted, world: RefCounted) -> bool:
	return str(row.get("world_id", "")) == str(world.world_id) and str(row.get("character_id", "")) == str(player.character_id)

static func _give_all(inventory: RefCounted, stacks: Variant) -> bool:
	if not RULES.valid_slots(stacks):
		return false
	var copy := RULES.inventory_from(RULES.slots(inventory))
	for stack: Variant in stacks:
		if stack is Dictionary and not RULES.give_stack(copy, stack):
			return false
	_apply_slots(inventory, RULES.slots(copy))
	return true

static func _apply_slots(inventory: RefCounted, slots: Array) -> void:
	for i in inventory.slot_count():
		inventory.set_slot(i, slots[i] if i < slots.size() else null)
