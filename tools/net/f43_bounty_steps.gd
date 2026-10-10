extends RefCounted

## F43 peer steps for tests/smoke_net_f43_bounties.gd. Each step drives the
## shipping Halda board path (FoundationComposition -> BountyInteraction ->
## Session foundation RPC -> BountyHost -> character_action journal -> owner
## save/ACK). Nothing here writes a board, a receipt or a reward; the morning
## step calls the host's own Game.advance_day, the lifecycle a rest uses.
const BOARD := preload("res://scripts/world/bounty_board.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const ITEMS := ["wood", "stone", "essence_ground", "tether_candy"]


static func run(runner: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"f43_view": return _view(runner)
		"f43_host_view": return _host_view(runner, str(args.get("character_id", "")))
		"f43_board_stand": return _board_stand(runner)
		"f43_claim": return await _claim(runner, args)
		"f43_replay": return await _replay(runner, args)
		"f43_morning": return await _morning(runner, args)
		"f43_arm_owner_cut": return _arm_owner_cut(runner)
		"f43_hold_clock": return _hold_clock(runner)
		"f43_disk_view": return _disk_view(runner, str(args.get("character_id", "")))
	return {"verdict": "ERROR", "detail": "unknown F43 action '%s'" % action}


static func _game(runner: SceneTree) -> Node:
	return runner.root.get_node_or_null(^"Game")


static func _composition(runner: SceneTree) -> Node:
	var game := _game(runner)
	var session: Node = game.get("session") if game != null else null
	return session.get_node_or_null(^"FoundationComposition") if session != null else null


static func _ok(detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "PASS", "detail": detail, "data": data}


static func _fail(detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "FAIL", "detail": detail, "data": data}


## Board, paid receipts and reward-item counts of one portable record.
static func _summary(record: Dictionary) -> Dictionary:
	var personal: Dictionary = record.get("redesign_character", {})
	var inventory := RULES.inventory_from(record.get("inventory", []))
	var items := {}
	for id: String in ITEMS: items[id] = inventory.count(id)
	var board: Dictionary = personal.get("bounties", BOARD.empty_board())
	var templates: Array = []
	for slot: Dictionary in board.get("slots", []): templates.append(slot.template)
	return {"board": board.duplicate(true), "templates": templates, "items": items,
		"bounty_receipts": (personal.get("bounty_receipts", []) as Array).filter(
			func(r: Variant) -> bool: return str(r).begins_with("bounty:") and not str(r).begins_with("bounty:storage")),
		"portal_unlocks": (personal.get("portal_unlocks", []) as Array).duplicate()}


static func _view(runner: SceneTree) -> Dictionary:
	var game := _game(runner)
	if game == null or game.get("local") == null: return _fail("no local owner")
	var data := _summary(RECORD.portable_projection(game.get("local").call("save_data")))
	data["character_id"] = str(game.get("local").get("character_id"))
	var session: Node = game.get("session")
	data["active"] = session != null and session.call("is_active") == true
	data["host_day"] = int(game.get("world").redesign_world.get("bounty_day", 0))
	return _ok("owner %s board cycle %d" % [data.character_id, int(data.board.get("cycle", 0))], data)


## Host only: the admitted authority record and its latest journal row.
static func _host_view(runner: SceneTree, character_id: String) -> Dictionary:
	var game := _game(runner)
	if game == null or game.call("is_host") != true: return _fail("host view requires the host")
	var authority: Object = game.get("session").get("_character_authority")
	var state: Variant = authority.call("state", character_id) if authority != null else {}
	if not state is Dictionary or state.is_empty(): return _fail("host holds no record for %s" % character_id)
	var data := _summary(state)
	var world: RefCounted = game.get("world")
	var row: Variant = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character_id))
	data["row"] = {"status": row.get("status"), "action": row.get("action"), "receipt": row.get("receipt")} if row is Dictionary else {}
	return _ok("host view of %s" % character_id, data)


## Where to stand: beside Halda's actual mounted board, inside its radius.
static func _board_stand(runner: SceneTree) -> Dictionary:
	var composition := _composition(runner)
	if composition == null: return _fail("no FoundationComposition")
	var ref: Variant = composition.get("_board")
	var board: Node3D = ref.get_ref() as Node3D if ref is WeakRef else null
	if board == null: return _fail("Halda's board is not mounted in this process")
	var at := board.global_position + board.global_transform.basis.z.normalized() * 1.6
	return _ok("board at %s" % str(board.global_position), {"at": [at.x, at.y + 1.0, at.z],
		"board": [board.global_position.x, board.global_position.y, board.global_position.z]})


## Claim the slot holding `template` through the shipping interaction adapter,
## then wait for the owner-saved receipt (or a refusal).
static func _claim(runner: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(runner)
	var composition := _composition(runner)
	if game == null or composition == null: return _fail("no Game/FoundationComposition")
	var interaction: Node = composition.get_node_or_null(^"BountyInteraction")
	var character := str(game.get("local").get("character_id"))
	var view: Dictionary = {}
	for i in 600:
		composition.call("bounty_view")
		for f in 10: await runner.physics_frame
		view = interaction.call("view")
		if view.get("ready") == true: break
	if view.get("ready") != true: return _fail("board view never became ready: %s" % str(view))
	var instance := ""
	for row: Dictionary in view.rows:
		if row.template == str(args.get("template", "")): instance = row.instance
	if instance.is_empty(): return _fail("no %s slot on the board" % str(args.get("template", "")), {"view": view})
	var result: Dictionary = interaction.call("claim", instance)
	var receipt := "bounty:%s:%s" % [instance, character]
	var budget := int(args.get("budget_frames", 1800))
	for f in budget:
		await runner.physics_frame
		var personal: Dictionary = game.get("local").get("redesign_character")
		if (personal.get("bounty_receipts", []) as Array).has(receipt):
			return _ok("claimed %s after %d frames" % [instance, f], {"instance": instance, "receipt": receipt, "first": result})
	return _fail("claim did not settle in %d frames (first answer %s)" % [budget, str(result)], {"instance": instance, "first": result})


## Re-send the original claim request as a returning client would.
static func _replay(runner: SceneTree, args: Dictionary) -> Dictionary:
	var composition := _composition(runner)
	if composition == null: return _fail("no FoundationComposition")
	var answers: Array = []
	var record := func(envelope: Dictionary, result: Dictionary) -> void:
		if envelope.get("op") == "bounty_claim": answers.append(result)
	var session: Node = composition.get_parent()
	session.connect("foundation_reply_received", record)
	var first: Dictionary = composition.call("bounty_claim", {"instance": str(args.get("instance", ""))})
	for f in 240:
		await runner.physics_frame
		if not answers.is_empty() or session.call("is_host") == true: break
	session.disconnect("foundation_reply_received", record)
	if answers.is_empty(): return _fail("the host never answered the replayed claim (first %s)" % str(first), {"first": first})
	return _ok("replayed original claim", {"first": first, "answers": answers})


## Host only: the real morning (Game.advance_day), then wait until every named
## character's board has rotated to the new host day and its row settled.
static func _morning(runner: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(runner)
	if game == null or game.call("is_host") != true: return _fail("morning is host truth")
	if args.get("wait") == false:
		game.call("advance_day")
		return _ok("morning %d started" % int(game.get("world").redesign_world.bounty_day))
	var authority: Object = game.get("session").get("_character_authority")
	var world: RefCounted = game.get("world")
	var anchors := {}
	for character: Variant in args.get("characters", []):
		anchors[str(character)] = int(authority.call("state", str(character)).get("redesign_character", {}).get("bounties", {}).get("anchor_day", 0))
	game.call("advance_day")
	var day := int(world.redesign_world.bounty_day)
	for f in int(args.get("budget_frames", 1800)):
		await runner.physics_frame
		var done := true
		for character: String in anchors:
			var state: Dictionary = authority.call("state", character)
			var row: Variant = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character))
			if int(state.get("redesign_character", {}).get("bounties", {}).get("anchor_day", 0)) <= int(anchors[character]) \
					or (row is Dictionary and row.get("status") == "pending"):
				done = false
		if done: return _ok("morning %d rotated and settled after %d frames" % [day, f], {"day": day})
	return _fail("morning %d did not rotate/settle every board" % day)


## Guest only. One-shot: hard-kill this process at the real owner-save edge of
## its next morning rotation, so the host keeps that row pending (no ACK).
static func _arm_owner_cut(runner: SceneTree) -> Dictionary:
	var writer: Node = runner.root.get_node_or_null(^"Game/Session/LedgerRpc")
	if writer == null: return _fail("no LedgerRpc")
	writer.connect("transaction_boundary", func(observation: Dictionary) -> void:
		if observation.get("phase") == "after_owner_write_before_ack" and observation.get("action") == "bounty_rotate":
			print("F43 OWNER CUT: hard kill after owner write, before ACK: %s" % str(observation.get("receipt")))
			OS.kill(OS.get_process_id()))
	return _ok("armed the bounty_rotate owner cut")


## The character as saved on this peer's disk (read before any rejoin).
static func _disk_view(runner: SceneTree, character_id: String) -> Dictionary:
	var game := _game(runner)
	var saver: Variant = game.get("save_system") if game != null else null
	var characters: Variant = saver.call("characters") if saver != null else null
	if characters == null or not bool(characters.call("has", character_id)): return _fail("no saved character %s" % character_id)
	var record: Dictionary = characters.call("read", character_id)
	return _ok("disk record of %s" % character_id, _summary(record))


## Host only, disclosed fixture: restart world_look's real-time day roll
## (every day_length_seconds), so the only mornings in a section are the
## smoke's own Game.advance_day calls.
static func _hold_clock(runner: SceneTree) -> Dictionary:
	var held := 0
	for node: Node in runner.root.find_children("*", "Node", true, false):
		var script: Script = node.get_script()
		if script != null and script.resource_path == "res://scripts/world/world_look.gd":
			node.set("_auto_day_accum", 0.0)
			held += 1
	return _ok("restarted %d day-roll clock(s)" % held, {"held": held})
