extends RefCounted
const DATA := "res://data/config/water_dock_actions.json"
const FIELD := preload("res://scripts/world/water_heightfield.gd")
## F13 local-chain steps ride the same host-resolved, durably saved intent.
const LOCAL_CHAINS := preload("res://scripts/world/water_local_chain_rules.gd")
const DEBIT := preload("res://scripts/net/water_dock_debit.gd")
## F15 durable dock receipt: one WORLD flag per paid action, written in the same
## commit (and so the same durable world save) as the action flag:
##   water_claim:dock_paid:<action_id>:<payer character>:<txn id>
## Under the already declared world prefix `water_claim:`. The payer is the
## host's actor resolution, never the packet. Guests learn receipts through the
## ordinary delta/snapshot replica, so a retry after a lost delta settles.
const RECEIPT_PREFIX := "water_claim:dock_paid:"

static func load_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(DATA))

static func action_position(action: Dictionary, world_config: Dictionary, ground: Callable) -> Vector3:
	for anchor: Dictionary in world_config.anchors:
		if str(anchor.id) != str(action.anchor):
			continue
		var x := float(anchor.safe_position[0]) + float(action.offset_xz[0])
		var z := float(anchor.safe_position[2]) + float(action.offset_xz[1])
		return Vector3(x, float(ground.call(x, z)), z)
	return Vector3.INF

static func evaluate(intent: Dictionary, context: Dictionary, flags: RefCounted) -> Dictionary:
	if LOCAL_CHAINS.has_step(str(intent.get("action_id", ""))):
		return LOCAL_CHAINS.evaluate(intent, context, flags)
	var data := load_data()
	var action: Dictionary = {}
	for row: Dictionary in data.actions:
		if str(row.id) == str(intent.get("action_id", "")):
			action = row
	if action.is_empty():
		return _refuse("unknown_action", "That dock action is not available.")
	# Escrowed (F15): the guest already debited and saved its character before
	# sending, so the host commits a receipt instead of an item_take. An intent
	# without `txn_id` is the legacy shape and keeps its item_take ops.
	var escrowed := intent.has("txn_id")
	var payer := _payer(intent, context)
	if escrowed:
		# P3: this txn's own receipt answers before any other check, so a
		# resubmit of a committed txn is idempotent whatever else changed.
		if not receipt_for_txn(flags, str(intent.get("txn_id", ""))).is_empty():
			return _refuse("already_done", "This dock task is already complete.")
		var attempt: Variant = intent.get("attempt")
		var instance: Variant = intent.get("world_instance_id")
		if not (attempt is int or attempt is float) or float(attempt) != floor(float(attempt)) or int(attempt) < 1 \
				or typeof(instance) != TYPE_STRING or payer.is_empty() \
				or str(intent.get("txn_id", "")) != DEBIT.txn_id(str(instance), str(action.id), payer, int(attempt)):
			return _refuse("malformed", "That dock payment could not be checked.")
		# The host world instance is supplied by the host's actor context when
		# available; a stale intent for another world is never committed here.
		if context.has("world_instance_id") and str(context.world_instance_id) != str(instance):
			return _refuse("wrong_world", "That dock payment belongs to a different world.")
	if str(context.get("realm", "")) != "water" or str(intent.get("realm", "")) != "water":
		return _refuse("wrong_realm", "Reach this Water dock first.")
	var actor := int(context.get("peer", 0))
	if actor <= 0 or str(context.get("character_id", "")).is_empty():
		return _refuse("unknown_character", "Your character is not connected.")
	var position: Variant = context.get("position")
	var field := FIELD.new()
	var target := action_position(action, FIELD.load_config(), field.height_at)
	if not position is Vector3 or not position.is_finite() or not target.is_finite() or position.distance_to(target) > float(data.interaction_distance_m):
		return _refuse("too_far", "Move closer to the dock equipment.")
	if flags.has(str(action.flag)):
		return _refuse("already_done", "This dock task is already complete.")
	for flag: String in action.requires_flags:
		if not flags.has(flag):
			return _refuse("prerequisite", str(action.get("refusal", "Resolve the dock's challenge first.")))
	var bag: Variant = context.get("inventory", {})
	if not bag is Dictionary:
		return _refuse("malformed", "The repair materials could not be checked.")
	for item: String in action.cost:
		var amount: Variant = bag.get(item, 0)
		if not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount) < float(action.cost[item]):
			return _refuse("materials", "Bring 6 reed fiber and 4 driftwood to repair the dock.")
	var ops: Array = []
	if not escrowed:
		for item: String in action.cost:
			ops.append({"op":"item_take", "scope":"player", "peers":[actor], "item":item, "count":int(action.cost[item])})
	ops.append({"op":"flag", "scope":"world", "realm":"water", "id":str(action.flag), "value":true})
	if escrowed:
		ops.append({"op":"flag", "scope":"world", "realm":"water",
			"id":receipt_flag(str(action.id), payer, str(intent.txn_id)), "value":true})
	return {"ok":true, "code":"", "reason":"", "ops":ops}

## The world flag that durably records `txn` paying for `action_id`.
static func receipt_flag(action_id: String, payer: String, txn: String) -> String:
	return RECEIPT_PREFIX + action_id + ":" + payer + ":" + txn

## Parse a receipt flag into water_dock_debit's receipt shape, or {}.
static func parse_receipt(id: String, world_instance_id: String) -> Dictionary:
	if not id.begins_with(RECEIPT_PREFIX):
		return {}
	var parts := id.trim_prefix(RECEIPT_PREFIX).split(":")
	if parts.size() != 3 or parts[0].is_empty() or parts[1].is_empty() or parts[2].is_empty():
		return {}
	return {"action_id": parts[0], "world_instance_id": world_instance_id,
		"txn_id": parts[2], "payer_character_id": parts[1]}

## The receipt naming `txn` in these world flags, or {}.
static func receipt_for_txn(flags: RefCounted, txn: String) -> Dictionary:
	if txn.is_empty() or flags == null:
		return {}
	for id: Variant in flags.call("all_set"):
		var receipt := parse_receipt(str(id), "")
		if not receipt.is_empty() and str(receipt.txn_id) == txn:
			return receipt
	return {}

## water_dock_debit `world_facts` for one world: action_id -> receipt. A paid
## action whose flag is set with no receipt (it predates receipts, or was
## written by some other path) answers the P4 legacy receipt, so an open row
## for it refunds as paid_by_other instead of waiting forever. Absent actions
## are simply absent: never a refund reason.
static func world_facts(flags: RefCounted, world_instance_id: String, actions: Array = []) -> Dictionary:
	var facts: Dictionary = {}
	if flags == null:
		return facts
	for id: Variant in flags.call("all_set"):
		var receipt := parse_receipt(str(id), world_instance_id)
		if not receipt.is_empty() and not facts.has(receipt.action_id):
			facts[str(receipt.action_id)] = receipt
	for action: Dictionary in (actions if not actions.is_empty() else load_data().actions):
		if not facts.has(str(action.id)) and bool(flags.call("has", str(action.flag))):
			facts[str(action.id)] = DEBIT.legacy_receipt(world_instance_id, str(action.id))
	return facts

static func _payer(intent: Dictionary, context: Dictionary) -> String:
	var host_resolved := str(intent.get("_actor_character_id", ""))
	return host_resolved if not host_resolved.is_empty() else str(context.get("character_id", ""))

static func _refuse(code: String, reason: String) -> Dictionary:
	return {"ok":false, "code":code, "reason":reason, "ops":[]}
