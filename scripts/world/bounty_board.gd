extends RefCounted

## Detached F43 proposals. Only host-derived context enters this function;
## requests contain no progress, day, unlocks, prices or inventory. Foundation's
## character_action registry journals inventory + board + receipt atomically.
const RECEIPT_WINDOWS := preload("res://scripts/creatures/receipt_windows.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const ACTIONS := ["bounty_rotate", "bounty_event", "bounty_claim"]

## Parsed and validated once per file revision (the host poll reads it every
## second per peer); callers get their own deep copy.
static var _cache: Dictionary = {}

static func config() -> Dictionary:
	var path := "res://data/config/bounties.json"
	var stamp := FileAccess.get_modified_time(path)
	if not _cache.has("valid") or _cache.get("stamp") != stamp:
		var raw: Variant = DATA.json(path)
		_cache = {"stamp": stamp, "valid": raw if raw is Dictionary and configuration_errors(raw).is_empty() else {}}
	return (_cache.valid as Dictionary).duplicate(true)

static func configuration_errors(raw: Dictionary) -> Array[String]:
	if raw.get("schema_version") != 1 or raw.get("board_count") != 3 \
		or raw.get("board_key") != "halda_bounty_board" or not raw.get("runtime_enabled") is bool \
		or not ESSENCE._integer(raw.get("maximum_receipts"), 1, 2147483646) \
		or not raw.get("templates") is Array: return ["invalid bounty configuration"]
	var ids: Array[String] = []
	var kinds: Array[String] = []
	for row: Variant in raw.templates:
		if not row is Dictionary or not ESSENCE._component(row.get("id")) or ids.has(row.id) \
			or row.get("biome") not in ["meadows", "tidewake", "cloudreach", "stormwood"] \
			or row.get("kind") not in ["catch_trait", "defeat_alpha", "material_delivery", "rematch"] \
			or not row.get("title") is String or not row.get("rewards") is Array or row.rewards.is_empty():
			return ["invalid bounty template"]
		ids.append(row.id)
		if not kinds.has(row.kind): kinds.append(row.kind)
		if row.kind == "catch_trait":
			var found := false
			for trait_row: Dictionary in DATA.json("res://data/schema/traits.json"):
				if trait_row.id == row.get("trait"): found = true
			if not found: return ["unknown catch trait"]
		if row.kind == "material_delivery" and (not RULES.db().has(str(row.get("item", ""))) \
			or not ESSENCE._integer(row.get("count"), 1, 999)): return ["invalid material delivery"]
		for reward: Variant in row.rewards:
			if not reward is Dictionary or reward.size() != 2 or not reward.get("id") is String \
				or not RULES.db().has(reward.id) or not ESSENCE._integer(reward.get("n"), 1, 999): return ["invalid bounty reward"]
	return [] if kinds.size() == 4 else ["all four bounty kinds required"]

static func template(id: String) -> Dictionary:
	for row: Dictionary in config().get("templates", []):
		if row.id == id: return row.duplicate(true)
	return {}

static func empty_board() -> Dictionary:
	return {"anchor_world": "", "anchor_day": 0, "cycle": 0, "slots": []}

static func board_errors(raw: Variant) -> Array[String]:
	if not raw is Dictionary or raw.size() != 4: return ["invalid bounty carrier"]
	if not raw.get("anchor_world") is String or not ESSENCE._integer(raw.get("anchor_day"), 0, 2147483646) \
		or not ESSENCE._integer(raw.get("cycle"), 0, 2147483646) or not raw.get("slots") is Array:
		return ["invalid bounty clock"]
	if raw.cycle == 0:
		# JSON restores integral numbers as floats. Validate the exact empty
		# carrier by value after the integer/type checks above, so fresh and
		# reloaded characters share the same valid initial state.
		return [] if raw.anchor_world.is_empty() and raw.anchor_day == 0 and raw.slots.is_empty() \
			else ["invalid initial bounty board"]
	if raw.anchor_world.is_empty() or raw.anchor_day < 1 or raw.slots.size() != 3: return ["bounty board requires three slots"]
	var seen: Array[String] = []
	var definitions: Array[String] = []
	for slot: Variant in raw.slots:
		if not slot is Dictionary or slot.size() != 3 or not slot.get("instance") is String \
			or slot.instance.length() != 64 or not slot.instance.is_valid_hex_number(false) \
			or not slot.get("template") is String or template(slot.template).is_empty() \
			or not slot.get("complete") is bool or seen.has(slot.instance) or definitions.has(slot.template):
			return ["invalid bounty slot"]
		seen.append(slot.instance)
		definitions.append(slot.template)
	return []

static func unlocked(personal: Dictionary, host_unlocks: Array) -> Array[String]:
	var result: Array[String] = ["meadows"]
	for biome: String in ["tidewake", "cloudreach", "stormwood"]:
		if personal.get("portal_unlocks", []).has(biome) or host_unlocks.has(biome): result.append(biome)
	return result

static func view(personal: Dictionary, character: String) -> Dictionary:
	var board: Dictionary = personal.get("bounties", empty_board())
	if not board_errors(board).is_empty(): return {"ready": false, "code": "invalid_board"}
	var rows: Array[Dictionary] = []
	for slot: Dictionary in board.slots:
		var row := template(slot.template)
		row.merge(slot, true)
		row["paid"] = personal.get("bounty_receipts", []).has("bounty:%s:%s" % [slot.instance, character])
		row["claimable"] = not row.paid and (row.complete or row.kind == "material_delivery")
		rows.append(row)
	return {"ready": rows.size() == 3, "character_id": character, "cycle": board.cycle, "rows": rows,
		"speaker": config().get("speaker", "Halda"), "introduction": config().get("introduction", "")}

static func stage(current: Dictionary, revision: int, action: String, intent: Dictionary, context: Dictionary) -> Dictionary:
	if action not in ACTIONS or context.get("character_id") != current.get("character_id") \
		or context.get("expected_revision") != revision or context.get("in_range") != true:
		return _deny("invalid_bounty_authority")
	var cfg := config()
	if cfg.is_empty(): return _deny("bounty_configuration_unavailable")
	var personal: Dictionary = current.redesign_character
	var board: Dictionary = personal.get("bounties", empty_board()).duplicate(true)
	if not board_errors(board).is_empty(): return _deny("invalid_board")
	var next := current.duplicate(true)
	var receipt := ""
	if action == "bounty_rotate":
		if not intent.is_empty() or context.get("clock_confirmed") != true \
			or not ESSENCE._opaque_id(context.get("world_namespace")) \
			or not ESSENCE._integer(context.get("host_day"), 1, 2147483646) \
			or not context.get("host_unlocks") is Array: return _deny("host_morning_required")
		var world: String = context.world_namespace
		var day: int = int(context.host_day)
		if board.anchor_world == world and day <= int(board.anchor_day): return _deny("morning_already_seen")
		if board.cycle >= 2147483646: return _deny("cycle_budget")
		# Moving worlds only reanchors the clock: no reroll, no new instances or
		# rewards. Absolute day numbers from another world are never elapsed time.
		var rotate: bool = board.cycle == 0 or board.anchor_world == world
		board.anchor_world = world
		board.anchor_day = day
		if rotate:
			board.cycle += 1
			var eligible: Array[Dictionary] = []
			var biomes := unlocked(personal, context.host_unlocks)
			for row: Dictionary in cfg.templates:
				if biomes.has(row.biome): eligible.append(row)
			var seed_text := JSON.stringify([current.character_id, world, day, board.cycle])
			# Digest sort is deterministic across processes, unlike mutable RNG.
			eligible.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return (seed_text + a.id).sha256_text() < (seed_text + b.id).sha256_text())
			if eligible.size() < 3: return _deny("insufficient_unlocked_bounties")
			board.slots = []
			for index: int in 3:
				board.slots.append({"instance": JSON.stringify([seed_text, index, eligible[index].id]).sha256_text(),
					"template": eligible[index].id, "complete": false})
		receipt = "bounty:clock_%s:%s" % [JSON.stringify([world, day, board.cycle]).sha256_text(), current.character_id]
	elif action == "bounty_event":
		# Never offered through client interaction. The producer freezes an
		# accepted catch/alpha/rematch with actual encounter participants.
		if not intent.is_empty() or context.get("event_confirmed") != true \
			or not ESSENCE._opaque_id(context.get("world_namespace")) \
			or not ESSENCE._opaque_id(context.get("event_id")) \
			or not context.get("participants") is Array \
			or not context.participants.has(current.character_id) \
			or not context.get("issued_instances") is Array:
			return _deny("accepted_host_event_required")
		receipt = "bounty:event_%s:%s" % [JSON.stringify([context.world_namespace, context.event_id]).sha256_text(), current.character_id]
		var changed := false
		for slot: Dictionary in board.slots:
			if not context.issued_instances.has(slot.instance) or slot.complete: continue
			var row := template(slot.template)
			if row.biome != context.get("biome") or row.kind != context.get("kind"): continue
			if row.kind == "catch_trait" and (not context.get("traits") is Array or not context.traits.has(row.get("trait"))): continue
			if row.kind not in ["catch_trait", "defeat_alpha", "rematch"]: continue
			slot.complete = true
			changed = true
		if not changed: return _deny("no_matching_bounty")
	else:
		if intent.size() != 1 or not intent.get("instance") is String \
			or context.get("source_key") != cfg.board_key or context.get("in_combat") != false:
			return _deny("actual_halda_board_required")
		var selected: Dictionary = {}
		for slot: Dictionary in board.slots:
			if slot.instance == intent.instance: selected = slot
		if selected.is_empty(): return _deny("expired_bounty")
		receipt = "bounty:%s:%s" % [selected.instance, current.character_id]
		if personal.bounty_receipts.has(receipt): return _deny("reconcile_original_decision")
		var row := template(selected.template)
		if not selected.complete and row.kind != "material_delivery": return _deny("bounty_incomplete")
		var inventory := RULES.inventory_from(current.inventory)
		if row.kind == "material_delivery" and not inventory.remove(row.item, int(row.count)):
			return _deny("materials_required")
		# Capacity is checked after debit, on a detached bag. A failed reward
		# refuses the entire proposal without consuming the delivery or receipt.
		for reward: Dictionary in row.rewards:
			if not RULES.db().has(reward.id) or not RULES.give_stack(inventory, reward): return _deny("reward_inventory_full")
		next.inventory = RULES.slots(inventory)
		selected.complete = true
		next.redesign_character.bounty_receipts.append(receipt)
	if personal.transaction_receipts.has(receipt): return _deny("reconcile_original_decision")
	if RECEIPT_WINDOWS.compact(personal.transaction_receipts, "bounty_decision", str(current.character_id)).size() >= int(cfg.maximum_receipts) \
		or personal.bounty_receipts.size() >= int(cfg.maximum_receipts): return _deny("receipt_budget")
	next.redesign_character["bounties"] = board
	next.redesign_character.transaction_receipts = RECEIPT_WINDOWS.compact(next.redesign_character.transaction_receipts, "bounty_decision", str(current.character_id))
	next.redesign_character.transaction_receipts.append(receipt)
	return {"ok": true, "before": current.duplicate(true), "state": next, "receipt": receipt,
		"expected_character_revision": revision}

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "code": code, "durable": false, "resolved": false, "terminal": code != "reconcile_original_decision"}
