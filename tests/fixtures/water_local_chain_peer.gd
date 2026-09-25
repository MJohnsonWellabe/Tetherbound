extends "res://tools/net/peer_runner.gd"

## Test-side orchestration for smoke_net_water_local_chains. Poses are teleport
## fixtures and delivered materials are added to the satchel directly; speech
## runs through the production WaterNPCs/DialoguePanel seam, sites through their
## real Interact prompts, pickups through their production bodies, and every
## chain record through WaterLocalChains -> LedgerRPC -> the host rule.
const CANDY := "water:lantern_cove:pickup:002"
const SETTLE_FRAMES := 150

var _refusals: Array = []


func _world() -> Node3D:
	return root.get_node_or_null("WaterArchipelago") as Node3D


func _pose(at: Vector3) -> void:
	var world := _world()
	var player := world.local_rig() as CharacterBody3D
	player.global_position = Vector3(at.x, float(world.ground_height_at(at.x, at.z)) + 0.1, at.z)
	player.velocity = Vector3.ZERO


## A client's teleport reaches the host's proxy only after the host accepts the
## new pose; wait long enough that host position checks see the real spot.
func _settle() -> void:
	for frame in SETTLE_FRAMES:
		await physics_frame


func _on_refused(kind: String, code: String, reason: String, _detail: Dictionary) -> void:
	_refusals.append({"kind": kind, "code": code, "reason": reason})


func _watch_refusals(game: Node) -> void:
	var ledger: Node = game.get("ledger")
	if not ledger.intent_refused.is_connected(_on_refused):
		ledger.intent_refused.connect(_on_refused)
	_refusals.clear()


## Wait for a world flag or a refusal of the chain intent.
func _await_record(game: Node, flag: String, frames: int = 900) -> Dictionary:
	for frame in frames:
		if game.world.flags.has(flag):
			return {"recorded": true, "refusal": {}}
		for entry: Dictionary in _refusals:
			if str(entry.kind) == "water_dock_action":
				return {"recorded": false, "refusal": entry}
		await physics_frame
	return {"recorded": false, "refusal": {"code": "timeout"}}


func _execute_step(msg: Dictionary) -> Dictionary:
	var name := str(msg.get("action", ""))
	if not name.begins_with("chain_"):
		return await super._execute_step(msg)
	var world := _world()
	if world == null or not bool(world.call("shell_build_complete")):
		return {"verdict": "FAIL", "detail": "Production Water world unavailable"}
	var game := root.get_node("Game")
	var args: Dictionary = msg.get("args", {})
	var chains: Node = world.get_node("WaterLocalChains")
	match name:
		"chain_hear":
			# Greet through the speaker's production prompt; deliver every line.
			var npc := str(args.get("npc", ""))
			var body: Node3D = world.get_node("WaterChapter").npc_bodies.get(npc)
			var panel: Node = world.get_node("DialoguePanel")
			if body == null:
				return {"verdict": "FAIL", "detail": "No NPC " + npc}
			var player := world.local_rig() as CharacterBody3D
			player.global_position = body.global_position + Vector3(1.0, 0.1, 0.0)
			player.velocity = Vector3.ZERO
			await _settle()
			_watch_refusals(game)
			body.call("prompt_node").emit_signal("activated")
			if not bool(panel.call("is_open")):
				return {"verdict": "FAIL", "detail": "Conversation did not open"}
			var conversation := str(world.get_node("WaterNPCs").get("_active_conversation"))
			for guard in 12:
				if not bool(panel.call("is_open")):
					break
				panel.call("advance")
				await process_frame
			var flag := str(args.get("expect_flag", ""))
			var record := await _await_record(game, flag) if not flag.is_empty() else {"recorded": true, "refusal": {}}
			var ok: bool = conversation == str(args.get("expect", conversation)) and bool(record.recorded)
			return {"verdict": "PASS" if ok else "FAIL", "detail": "%s heard %s; record %s" % [npc, conversation, str(record)],
				"data": {"conversation": conversation}}
		"chain_site":
			var root_node: Node3D = chains.call("site_root", str(args.get("step", "")))
			if root_node == null:
				return {"verdict": "FAIL", "detail": "No site " + str(args.get("step", ""))}
			var gift: Dictionary = args.get("give", {})
			for item: String in gift:
				game.inventory.add(item, int(gift[item]))
			_pose(root_node.global_position + Vector3(0.0, 0.0, -1.5))
			await _settle()
			_watch_refusals(game)
			root_node.get_node("Prompt").call("interaction_activate")
			var record := await _await_record(game, str(args.get("flag", "")))
			var ok: bool = bool(record.recorded) == bool(args.get("expect_recorded", true))
			if not bool(record.recorded):
				ok = ok and str(record.refusal.get("code", "")) == str(args.get("expect_code", ""))
			return {"verdict": "PASS" if ok else "FAIL", "detail": "site %s: %s" % [args.get("step", ""), str(record)]}
		"chain_request":
			# A speech step's host request, sent from beside its speaker.
			var npc := str(args.get("npc", ""))
			var body: Node3D = world.get_node("WaterChapter").npc_bodies.get(npc)
			var player := world.local_rig() as CharacterBody3D
			player.global_position = body.global_position + Vector3(1.0, 0.1, 0.0)
			player.velocity = Vector3.ZERO
			await _settle()
			_watch_refusals(game)
			var verdict: Dictionary = chains.call("request_step", str(args.get("step", "")))
			# The host (and solo) hears its own refusal as the verdict; a client's
			# arrives later on intent_refused.
			if not verdict.is_empty() and not bool(verdict.get("ok", false)) and not bool(verdict.get("pending", false)):
				_refusals.append({"kind": "water_dock_action", "code": str(verdict.get("code", "")), "reason": str(verdict.get("reason", ""))})
			var record := await _await_record(game, str(args.get("flag", "")))
			var ok: bool = bool(record.recorded) == bool(args.get("expect_recorded", true))
			if not bool(record.recorded):
				ok = ok and str(record.refusal.get("code", "")) == str(args.get("expect_code", ""))
			return {"verdict": "PASS" if ok else "FAIL", "detail": "request %s: %s" % [args.get("step", ""), str(record)]}
		"chain_world_flag":
			# Upstream fixture: one world fact through the ordinary host intent.
			var verdict: Dictionary = game.ledger.submit({"kind": "set_world_flag", "realm": "water",
				"id": str(args.get("flag", "")), "value": true})
			var ok := bool(verdict.get("ok", false)) or bool(verdict.get("pending", false))
			return {"verdict": "PASS" if ok else "FAIL", "detail": "set_world_flag %s: %s" % [args.get("flag", ""), str(verdict.get("code", ""))]}
		"chain_claim":
			var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
			var at := Vector3.INF
			for row: Dictionary in data.pickups:
				if str(row.id) == CANDY:
					at = Vector3(float(row.position[0]), 0.0, float(row.position[2]))
			_pose(at + Vector3(1.0, 0.0, 0.0))
			var pickups: Node = world.get_node("WaterPickups")
			var body: Node = null
			for frame in 300:
				await physics_frame
				body = pickups.call("node_for", CANDY)
				if body != null:
					break
			if body == null:
				return {"verdict": "FAIL", "detail": "Lantern cache never streamed in"}
			for frame in 30:
				await physics_frame
			body.call("_on_picked_up")
			for frame in 900:
				await physics_frame
				if game.local.flags.has("water_candy:" + CANDY):
					return {"verdict": "PASS", "detail": "Own Candy I claimed through the host"}
			return {"verdict": "FAIL", "detail": "Claim did not complete"}
	return {"verdict": "ERROR", "detail": "Unknown chain action"}


func _execute_probe(msg: Dictionary) -> Variant:
	if str(msg.get("what", "")) != "chain":
		return super._execute_probe(msg)
	var game := root.get_node("Game")
	var records: Array = []
	var receipts := 0
	for flag: Variant in game.world.flags.all_set():
		if str(flag).begins_with("water_claim:local:"):
			records.append(str(flag))
		elif str(flag).begins_with("water_claim:") and str(flag).ends_with(":" + CANDY):
			receipts += 1
	records.sort()
	var built := false
	var world := _world()
	if world != null:
		var site: Node3D = world.get_node("WaterLocalChains").call("site_root", "lastlight_shelter_supply")
		var piece: Node3D = site.get_node_or_null("Built") if site != null else null
		built = piece != null and piece.visible and site.visible
	return {"records": records, "candy_receipts": receipts, "host": bool(game.is_host()),
		"lesson": bool(game.world.flags.has("water_swim_lesson_complete")),
		"driftwood": int(game.inventory.count("driftwood")), "reed_fiber": int(game.inventory.count("reed_fiber")),
		"candy_i": int(game.inventory.count("skill_candy_i")), "shelter_built": built}
