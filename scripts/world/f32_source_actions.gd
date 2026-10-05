extends RefCounted

## F32 typed staging inside Foundation's EXISTING character/world transaction.
## All context comes from registered live host placements and admitted records.
## This never promotes state, writes a save, grants items, or creates a journal.
const INVENTORY := preload("res://autoload/inventory.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const HARVEST := preload("res://scripts/world/harvest_logic.gd")
const SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const FARM := preload("res://scripts/world/farm_logic.gd")
const FORGE := preload("res://scripts/world/homestead_refining.gd")
const SHED := preload("res://scripts/world/shed_drop_rules.gd")
const FIELDS := {
	"node": ["site_id", "expected_stock_revision", "action_id"],
	"farm": ["plot_id", "action", "crop_id", "expected_stock_revision", "action_id"],
	"refine": ["recipe_id", "action_id"],
	"groom": ["creature_uid", "action_id"],
}


static func stage(current: Dictionary, revision: int, op: String, intent: Dictionary,
		context: Dictionary, care_stage: Callable = Callable()) -> Dictionary:
	# Runtime admission happens at the host adapter. A saved, frozen decision
	# must still replay if the production gate is subsequently disabled.
	if context.get("resource_runtime_authorized") != true and _read("res://data/config/f32_runtime.json").get("runtime_enabled") != true:
		return _deny("disabled")
	if not FIELDS.has(op) or intent.size() != FIELDS[op].size():
		return _deny("invalid_intent")
	for key: String in FIELDS[op]:
		if not intent.has(key): return _deny("invalid_intent")
		if key == "expected_stock_revision":
			if not _integer(intent[key], 0): return _deny("invalid_stock_revision")
		elif not intent[key] is String: return _deny("invalid_intent")
	if not _identity(current.get("character_id")) or current.get("character_id") != context.get("character_id") \
			or context.get("expected_revision") != revision or revision < 0 \
			or context.get("registered_live_source") != true or context.get("in_range") != true \
			or context.get("in_combat") != false or context.get("modal_open") != false \
			or not _identity(context.get("world_id")) \
			or not ["meadows", "water", "cloudreach", "stormwood"].has(context.get("realm")) \
			or context.get("actor_realm") != context.get("realm") \
			or not _integer(context.get("host_day"), 1) or not _identity(context.get("source_generation")) \
			or not _identity(context.get("source_id")) or not _action_id(intent.get("action_id")):
		return _deny("canonical_live_source_required")
	if not current.get("inventory") is Array or current.inventory.size() != INVENTORY.SLOT_COUNT \
			or not current.get("redesign_character") is Dictionary \
			or not current.redesign_character.get("transaction_receipts") is Array:
		return _deny("invalid_admitted_record")
	# Foundation resolves replays against its original intent/before/state first.
	# A receipt by itself is deliberately never reported as durable settlement.
	var receipt := "craft:%s:f32:%s" % [current.character_id, str(intent.action_id).sha256_text()]
	if current.redesign_character.transaction_receipts.has(receipt):
		return _deny("existing_transaction_replay_required")
	var plan: Dictionary
	match op:
		"node": plan = _node(intent, context)
		"farm": plan = _farm(intent, context)
		"refine": plan = _refine(current, intent, context)
		"groom": plan = _groom(current, revision, intent, context, care_stage)
	if plan.get("ok") != true: return plan
	var next: Dictionary = plan.get("state", current).duplicate(true)
	var db := ITEM_DB.new()
	var inventory := INVENTORY.new(db)
	for index: int in next.inventory.size():
		inventory.set_slot(index, next.inventory[index])
	for cost: Dictionary in plan.get("cost", []):
		if not db.has(str(cost.id)) or not inventory.remove(str(cost.id), int(cost.n)):
			return _deny("insufficient_items")
	for item: String in plan.get("outputs", {}):
		if not db.has(item): return _deny("unregistered_output")
		if inventory.add(item, int(plan.outputs[item])) != 0: return _deny("inventory_full")
	var tool := str(plan.get("required_tool", ""))
	if not tool.is_empty():
		var slot := HARVEST.tool_slot(tool, inventory)
		if slot < 0: return _deny("working_tool_required")
		inventory.damage_tool(slot)
	next.inventory = []
	for index: int in inventory.slot_count():
		var stack := inventory.stack_at(index)
		next.inventory.append(null if stack.is_empty() else stack)
	var limit := int(_read("res://data/config/f32_runtime.json").get("maximum_transaction_receipts", 0))
	if limit < 1 or next.redesign_character.transaction_receipts.size() >= limit:
		return _deny("receipt_budget")
	next.redesign_character.transaction_receipts.append(receipt)
	return {"ok": true, "before": current.duplicate(true), "state": next,
		"expected_character_revision": revision, "original_revision": revision,
		"original_intent": intent.duplicate(true), "character_id": current.character_id,
		"receipt": receipt, "world_mutation": plan.get("world_mutation", {}).duplicate(true),
		"source_identity": {"world_id": context.world_id, "realm": context.realm,
			"source_id": context.source_id, "generation": context.source_generation},
		"outputs": plan.get("outputs", {}).duplicate(true)}


static func _node(intent: Dictionary, host: Dictionary) -> Dictionary:
	if intent.site_id != host.get("source_id"): return _deny("wrong_source")
	var site := SITES.by_id(str(host.realm), str(intent.site_id))
	if site.is_empty() or not preload("res://scripts/creatures/essence.gd")._equivalent(host.get("source_definition"), site):
		return _deny("unregistered_placement")
	var stock: Variant = host.get("stock")
	if not stock is Dictionary or not _integer(stock.get("revision"), 0) \
			or not _integer(stock.get("next_ready_day"), 1) \
			or not _integer(stock.get("generation"), 1) or str(int(stock.generation)) != host.source_generation \
			or int(stock.revision) != int(intent.expected_stock_revision): return _deny("stale_stock")
	if int(host.host_day) < int(stock.next_ready_day): return _deny("regrowing")
	if host.get("source_available") != true: return _deny("source_unavailable")
	var outputs: Dictionary = site.outputs.duplicate(true)
	var seed: Dictionary = site.get("seed_drop", {})
	if not seed.is_empty():
		var roll: Variant = host.get("retained_seed_roll")
		if not _number(roll) or float(roll) < 0 or float(roll) >= 1: return _deny("host_seed_roll_required")
		if float(roll) < float(seed.chance): outputs[str(seed.item)] = int(seed.amount)
	var next_stock: Dictionary = stock.duplicate(true)
	next_stock.revision = int(stock.revision) + 1
	next_stock.generation = int(stock.generation) + 1
	next_stock.next_ready_day = int(host.host_day) + int(site.respawn_days)
	var db := ITEM_DB.new()
	var required_tool := str(db.gathered_with(str(site.get("item", ""))))
	if not required_tool.is_empty() and host.get("equipped_tool") != required_tool:
		return _deny("equipped_tool_required")
	return {"ok": true, "outputs": outputs, "required_tool": required_tool,
		"world_mutation": {"kind": "node", "realm": host.realm, "source_id": intent.site_id,
			"before": stock.duplicate(true), "after": next_stock}}


static func _farm(intent: Dictionary, host: Dictionary) -> Dictionary:
	if host.realm != "meadows" or intent.plot_id != host.get("source_id"):
		return _deny("wrong_plot")
	var config := _read("res://data/config/farm.json")
	var plot: Variant = host.get("plot")
	if not plot is Dictionary or not _integer(plot.get("revision"), 0) \
			or int(plot.revision) != int(intent.expected_stock_revision): return _deny("stale_plot")
	var state := FARM.state_of(plot, int(host.host_day))
	var candidate: Dictionary
	var costs: Array = []
	var outputs: Dictionary = {}
	var tool := ""
	match intent.action:
		"till":
			if state != FARM.FALLOW or intent.crop_id != "": return _deny("plot_not_fallow")
			candidate = FARM.tilled(plot)
			tool = FARM.TILL_TOOL
		"sow":
			# Host resolver derives this only from paid world greenhouse records.
			if not host.get("greenhouse_built") is bool: return _deny("greenhouse_context_required")
			candidate = FARM.planted_crop(plot, int(host.host_day), intent.crop_id, config, host.greenhouse_built)
			if candidate.is_empty(): return _deny("crop_locked_or_plot_busy")
			costs.append({"id": FARM.crop_definition(config, intent.crop_id).seed_item, "n": 1})
		"harvest":
			if intent.crop_id != "": return _deny("client_crop_not_authority")
			var harvest := FARM.harvest_candidate(plot, int(host.host_day), config)
			if harvest.is_empty(): return _deny("crop_not_ripe")
			candidate = harvest.plot
			outputs = harvest.outputs
		_: return _deny("invalid_farm_action")
	candidate.revision = int(plot.revision) + 1
	return {"ok": true, "cost": costs, "outputs": outputs, "required_tool": tool,
		"world_mutation": {"kind": "farm", "realm": host.realm, "source_id": intent.plot_id,
			"before": plot.duplicate(true), "after": candidate}}


static func _refine(current: Dictionary, intent: Dictionary, host: Dictionary) -> Dictionary:
	if host.get("completed_present_channel") != true or host.get("completed_action_id") != intent.action_id:
		return _deny("complete_present_channel_required")
	var plan := FORGE.unit_plan(_read("res://data/recipes/recipes_forge.json"), intent.recipe_id,
		str(host.source_id), str(host.realm), host.get("world", {}), current)
	if plan.get("ok") != true: return plan
	return {"ok": true, "cost": plan.cost, "outputs": {str(plan.output.id): int(plan.output.n)}}


static func _groom(current: Dictionary, revision: int, intent: Dictionary,
		host: Dictionary, care_stage: Callable) -> Dictionary:
	if host.realm != "meadows" or host.get("paid_den") != true \
		or not _identity(host.get("world_namespace")) or not care_stage.is_valid():
		return _deny("actual_den_care_producer_required")
	var roster: Array = []
	for row: Variant in current.get("party", []):
		if not row is Dictionary: return _deny("invalid_party")
		roster.append({"uid": row.get("uid", ""), "species": row.get("species_id", "")})
	var receipts: Dictionary = {}
	for receipt: Variant in current.redesign_character.transaction_receipts:
		receipts[str(receipt)] = true
	var shed := SHED.den_groom_candidate(str(current.character_id), roster, intent.creature_uid,
		int(host.host_day), str(host.world_namespace), receipts, SHED.read())
	if shed.get("ok") != true: return shed
	# F27 stages its existing once-per-UID/day care receipt in this same candidate.
	var care: Variant = care_stage.call(current, str(current.character_id), intent.creature_uid,
		int(host.host_day), revision)
	if not care is Dictionary: return _deny("care_stage_refused")
	if care.get("ok") != true: return _deny(str(care.get("code", "care_stage_refused")))
	if care.get("duplicate") == true: return _deny("already_groomed")
	var next: Dictionary = care.state.duplicate(true)
	next.redesign_character.transaction_receipts.append(shed.receipt_id)
	return {"ok": true, "state": next, "outputs": shed.outputs}


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _identity(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()


static func _action_id(value: Variant) -> bool:
	if not value is String or value.length() != 32: return false
	for character: String in value:
		if not character in "0123456789abcdef": return false
	return true


static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))


static func _integer(value: Variant, minimum: int) -> bool:
	return _number(value) and float(value) == float(int(value)) and int(value) >= minimum and float(value) < 2147483647.0


static func _deny(code: String) -> Dictionary:
	return {"ok": false, "code": code}


## Player-facing sentence for a resource refusal. Host and session refusals
## carry the bare code as their reason; the HUD never shows a code.
static func refusal_text(code: String) -> String:
	# stale_stock means the node's stock moved since this view (a teammate, or
	# a lagging view of one's own gather); it is gathered, not lost.
	var messages := {"stale_stock": "This was just gathered. It will grow back in a few days.",
		# The host's generic "context unavailable" (range, held tool, gate, phase,
		# a changed record): never claim a competitor when none may exist.
		"source_or_revision_changed": "That can't be gathered right now. Try again in a moment.",
		"regrowing": "This has been gathered. It will grow back in a few days.",
		"equipped_tool_required": "You need the right tool in hand to gather this.",
		"working_tool_required": "You need a working tool to gather this.",
		"inventory_full": "Your satchel is full.",
		"source_unavailable": "This can't be gathered right now.",
		"transaction_busy": "Your last action is still being saved.",
		"resource_busy": "Wait for the current gathering to finish.",
		"training_journal_failed": "That couldn't be saved. Try again.",
		"world_save_failed": "That couldn't be saved. Try again.",
		"world_not_prepared": "The world is still saving. Try again."}
	return str(messages.get(code, "That resource is unavailable right now."))


## A refusal's reason when it is already a sentence, else its code's sentence.
static func refusal_reason(verdict: Dictionary, fallback: String) -> String:
	var reason := str(verdict.get("reason", ""))
	var code := str(verdict.get("code", ""))
	if reason.is_empty() and code.is_empty(): return fallback
	if reason.is_empty() or reason == code or not reason.contains(" "): return refusal_text(code if not code.is_empty() else reason)
	return reason
