extends RefCounted
## Durable per-character transaction escrow. It is inaccessible to gameplay;
## only the host receipt or explicit refusal settles it. Never refund on exit.
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const WORLD_INSTANCE_KEY := "world_instance_id"


static func world_instance(world: RefCounted) -> String:
	if world == null:
		return ""
	var raw: Variant = world.get("reward_delivery_namespace")
	return raw as String if typeof(raw) == TYPE_STRING else ""


static func row_instance(row: Dictionary) -> String:
	var raw: Variant = row.get(WORLD_INSTANCE_KEY, null)
	return raw as String if typeof(raw) == TYPE_STRING else ""


static func intent_matches(row: Dictionary, player: RefCounted, world: RefCounted) -> bool:
	if not belongs(row, player, world):
		return false
	var intent: Variant = row.get("intent")
	return intent is Dictionary and row_instance(intent as Dictionary) == row_instance(row)


static func is_legacy_unresolved(row: Dictionary, player: RefCounted) -> bool:
	return _belongs_character(row, player) and row_instance(row).is_empty() \
		and str(row.get("kind", "")) in ["death_satchel_create", "death_satchel_transfer"] \
		and str(row.get("status", "")) == "pending"


static func is_personal_outcome(row: Dictionary, player: RefCounted) -> bool:
	return _belongs_character(row, player) \
		and str(row.get("kind", "")) in ["death_satchel_create", "death_satchel_transfer"] \
		and str(row.get("status", "")) in ["grant_due", "refund_due"] \
		and RULES.valid_slots(row.get("stacks"))

static func begin_drop(player: RefCounted, world: RefCounted, at: Vector3, realm: String, origin_host: bool) -> String:
	var instance := world_instance(world)
	if instance.is_empty() or str(player.character_id).is_empty():
		return ""
	var slots := RULES.slots(player.inventory)
	if player.inventory.used_slots() == 0:
		return ""
	var txn := Crypto.new().generate_random_bytes(16).hex_encode()
	player.satchel_escrow[txn] = {"status": "pending", "kind": "death_satchel_create", "world_id": str(world.world_id),
		"world_instance_id": instance,
		"character_id": str(player.character_id), "origin_host": origin_host, "stacks": slots,
		"intent": {"kind": "death_satchel_create", "realm": realm, "txn_id": txn,
			"world_instance_id": instance, "state": slots, "position": [at.x, at.y, at.z]}}
	player.inventory.drain()
	return txn

static func begin_transfer(player: RefCounted, world: RefCounted, uid: String, direction: String, item: String, count: int, expected: int, origin_host: bool) -> String:
	var instance := world_instance(world)
	if instance.is_empty() or str(player.character_id).is_empty():
		return ""
	var index: int = world.death_satchel_index_of(uid)
	if index < 0:
		return ""
	var record: Dictionary = world.death_satchels[index]
	if str(record.get("realm", "meadows")) != str(player.realm) or (not str(record.get("owner", "")).is_empty() and str(record.owner) != str(player.character_id)):
		return ""
	for row: Variant in player.satchel_escrow.values():
		if row is Dictionary and belongs(row, player, world) \
				and str(row.get("uid", "")) == uid and str(row.get("status", "")) != "settled":
			return ""
	var personal := RULES.slots(player.inventory)
	var preview := RULES.preview(record.get("state", []), personal, direction, item, count)
	if preview.is_empty():
		return ""
	var txn := Crypto.new().generate_random_bytes(16).hex_encode()
	player.satchel_escrow[txn] = {"status": "pending", "kind": "death_satchel_transfer", "uid": uid,
		"world_id": str(world.world_id), "world_instance_id": instance,
		"character_id": str(player.character_id), "origin_host": origin_host,
		"direction": direction, "stacks": preview.stacks,
		"intent": {"kind": "death_satchel_transfer", "realm": str(record.get("realm", "meadows")), "uid": uid,
			"world_instance_id": instance,
			"txn_id": txn, "direction": direction, "item": item, "count": count, "expected_revision": expected, "personal": personal}}
	if direction == "deposit":
		apply_slots(player.inventory, preview.personal)
	return txn

static func reconcile(player: RefCounted, world: RefCounted) -> bool:
	var changed := false
	for key: Variant in player.satchel_escrow.keys():
		var raw: Variant = player.satchel_escrow[key]
		if not raw is Dictionary:
			continue
		var row: Dictionary = raw
		if str(row.get("kind", "")) not in ["death_satchel_create", "death_satchel_transfer"]:
			continue
		if not _belongs_character(row, player) or str(row.get("status", "")) == "settled":
			continue
		var txn := str(key)
		var uid := "death_" + txn if str(row.get("kind", "")) == "death_satchel_create" else str(row.get("uid", ""))
		var exact_world := belongs(row, player, world)
		var legacy_unknown := row_instance(row).is_empty()
		var index: int = world.death_satchel_index_of(uid) if exact_world or legacy_unknown else -1
		if str(row.get("status", "")) == "pending" and index >= 0:
			var record: Dictionary = world.death_satchels[index]
			var owner := str(record.get("owner", ""))
			# New rows already proved the exact world. Legacy rows have no such
			# proof, so only a persisted, explicitly-owned receipt can resolve one.
			var owns := owner == str(player.character_id) \
				or (exact_world and owner.is_empty())
			var committed := str(row.get("kind", "")) == "death_satchel_create" or (record.get("transactions", []) as Array).has(txn)
			if owns and committed:
				row.status = "grant_due" if str(row.get("direction", "")) == "withdraw" else "settled"
				changed = true
		if is_personal_outcome(row, player):
			if give_all(player.inventory, row.get("stacks", [])):
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
	if str(row.get("kind", "")) not in ["death_satchel_create", "death_satchel_transfer"]:
		return false
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
	var instance := row_instance(row)
	return not instance.is_empty() and instance == world_instance(world) \
		and str(row.get("world_id", "")) == str(world.world_id) \
		and _belongs_character(row, player)


static func _belongs_character(row: Dictionary, player: RefCounted) -> bool:
	return player != null and not str(player.character_id).is_empty() \
		and str(row.get("character_id", "")) == str(player.character_id)

static func give_all(inventory: RefCounted, stacks: Variant) -> bool:
	if not RULES.valid_slots(stacks):
		return false
	var copy := RULES.inventory_from(RULES.slots(inventory))
	for stack: Variant in stacks:
		if stack is Dictionary and not RULES.give_stack(copy, stack):
			return false
	apply_slots(inventory, RULES.slots(copy))
	return true

static func apply_slots(inventory: RefCounted, slots: Array) -> void:
	for i in inventory.slot_count():
		inventory.set_slot(i, slots[i] if i < slots.size() else null)
