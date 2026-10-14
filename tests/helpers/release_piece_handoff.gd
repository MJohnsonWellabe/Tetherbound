extends RefCounted
## Read-only handoff witness; the peer runner calls this after production load,
## before guests join or the next earned helper starts. Never repairs a save.
const FIELDS := ["uids", "flags", "items", "realm", "training"]

static func snapshot(game: Node) -> Dictionary:
	var uids: Array = []
	for member: RefCounted in game.get("party").call("members"):
		uids.append(str(member.get("uid")))
	var flags: Array = game.get("progression").call("all_set").duplicate()
	flags.sort()
	var items := {}
	var inventory: RefCounted = game.get("inventory")
	for index in int(inventory.call("slot_count")):
		var stack: Dictionary = inventory.call("stack_at", index)
		if not stack.is_empty():
			var id := str(stack.get("id", ""))
			items[id] = int(items.get(id, 0)) + int(stack.get("n", 0))
	return {"uids": uids, "flags": flags, "items": items, "realm": str(game.get("current_realm")),
		"training": preload("res://tools/earned_saves/training_handoff.gd").snapshot(game)}

static func error(receipt: Variant, predecessor: String, loaded: Dictionary) -> String:
	var invalid := preload("res://tests/helpers/four_biome_checkpoints.gd").piece_receipt_error(receipt, predecessor, FIELDS)
	if not invalid.is_empty(): return invalid
	var expected: Dictionary = JSON.parse_string(JSON.stringify(receipt.after))
	var actual: Dictionary = JSON.parse_string(JSON.stringify(loaded))
	for key: String in FIELDS:
		if not actual.has(key) or actual[key] != expected[key]:
			return "Production-loaded handoff differs from predecessor: " + key
	return ""
