extends RefCounted

## F27#4 peer steps for tests/smoke_net_f27_essence_no_dup.gd. Each step runs
## inside one real peer process and drives the shipping Session/LedgerRpc/
## AltarService path. Fixtures are named as fixtures; nothing here grants a
## level, debits essence, writes a receipt or ACKs a transaction. The loss cuts
## hang off LedgerRpc's own `transaction_boundary` observation signal, which
## fires at the exact production writer edges:
##   host  "after_host_write_before_delivery": the host has journaled the row;
##         the guest link is dropped before the delivery leaves this process.
##   owner "after_owner_write_before_ack": the guest's owner file is saved; the
##         guest process is hard-killed before it can ACK.
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const WORLD := preload("res://autoload/world_state.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const TYPES := ["ground", "water", "air", "electric", "fire", "dark", "ice", "psychic"]


static func run(runner: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"f27_place_altar": return await _place_altar(runner)
		"f27_dismiss_modals": return await _dismiss_modals(runner)
		"f27_snapshot": return _snapshot(runner)
		"f27_host_view": return _host_view(runner, str(args.get("character_id", "")))
		"f27_arm_host_cut": return _arm_host_cut(runner, str(args.get("character_id", "")))
		"f27_altar_spend": return await _altar_spend(runner, args)
		"f27_altar_replay": return await _altar_replay(runner, args)
		"f27_title_rejoin": return await _title_rejoin(runner, args)
		"f27_passive_state": return _passive_state(runner, str(args.get("character_id", "")))
	return {"verdict": "ERROR", "detail": "unknown F27 action '%s'" % action}


static func _game(runner: SceneTree) -> Node:
	return runner.root.get_node_or_null(^"Game")


static func _ok(detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "PASS", "detail": detail, "data": data}


static func _fail(detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "FAIL", "detail": detail, "data": data}


## Host only. Disclosed fixture: grants exactly the Altar recipe, then places
## it through the host build placer's own `_place` (paid Foundation journal).
static func _place_altar(runner: SceneTree) -> Dictionary:
	var game := _game(runner)
	if game == null or game.call("is_host") != true: return _fail("the Altar is placed by the host")
	var world := runner.current_scene
	var placer: Node = null
	for node: Node in runner.get_nodes_in_group("build_placer"):
		if world != null and world.is_ancestor_of(node): placer = node
	if placer == null: return _fail("no build placer in the host scene")
	for need: Dictionary in WORLD.altar_recipe(): game.get("inventory").call("add", str(need.id), int(need.n))
	var cfg: Dictionary = placer.call("_altar_config", game)
	if cfg.is_empty(): return _fail("Altar config unavailable")
	var plot: Dictionary = cfg.homestead_plot
	var centre := Vector2(float(plot.centre[0]), float(plot.centre[1]))
	var half := Vector2(float(plot.size_m[0]), float(plot.size_m[1])) * 0.5
	var pose := Vector3.INF
	var x := centre.x - half.x
	while x <= centre.x + half.x and pose == Vector3.INF:
		var z := centre.y - half.y
		while z <= centre.y + half.y:
			var at := Vector3(x, float(world.call("ground_height_at", x, z)), z)
			var preview: Dictionary = placer.call("preview_placement", game, "altar", at)
			if preview.get("ok") == true and preview.get("position") is Vector3:
				pose = preview.position
				break
			z += 1.0
		x += 1.0
	if pose == Vector3.INF: return _fail("no valid Altar pose on the home plot")
	var player := game.call("_find_player") as Node3D
	var stand := pose + Vector3(3.0, 0.0, 0.0)
	stand.y = float(world.call("ground_height_at", stand.x, stand.z)) + 1.0
	player.global_position = stand
	for i in 20: await runner.physics_frame
	placer.call("_show_ghost", game, "altar")
	(placer.get("_ghost") as Node3D).global_position = pose
	placer.set("_yaw_deg", 0.0)
	placer.call("_place", game, "altar")
	for i in 900:
		await runner.physics_frame
		for node: Node in runner.get_nodes_in_group("placed_building"):
			if node.get_meta("building_id", "") == "altar" and node.get_node_or_null(^"AltarInteraction") != null:
				var key := "altar:meadows:" + str(node.get_meta("building_uid", ""))
				var p: Vector3 = (node as Node3D).global_position
				return _ok("paid Altar %s at %s" % [key, str(p)], {"station_key": key, "position": [p.x, p.y, p.z]})
	return _fail("the paid Altar transaction never mounted", {"message": str(game.call("take_pending_world_message"))})


static func _dismiss_modals(runner: SceneTree) -> Dictionary:
	for attempt in 40:
		if INPUT_OWNER.current(runner) == null: return _ok("no modal owns input (%d confirms)" % attempt)
		for pressed: bool in [true, false]:
			var event := InputEventAction.new()
			event.action = "ui_accept"
			event.pressed = pressed
			Input.parse_input_event(event)
			for i in 6: await runner.physics_frame
	return _fail("a modal still owns input: %s" % str(INPUT_OWNER.current(runner)))


static func _counts(inventory_rows: Variant) -> Dictionary:
	var inventory := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(inventory_rows)
	var out := {"tether_candy": inventory.count("tether_candy")}
	for type_id: String in TYPES: out["essence_" + type_id] = inventory.count("essence_" + type_id)
	return out


static func _summary(record: Dictionary) -> Dictionary:
	var party: Array = []
	for row: Variant in record.get("party", []):
		if row is Dictionary: party.append({"uid": row.get("uid"), "species_id": row.get("species_id"),
			"level": int(row.get("level", 0)), "xp": int(row.get("xp", 0))})
	var personal: Dictionary = record.get("redesign_character", {})
	var receipts: Array = personal.get("transaction_receipts", [])
	return {"party": party, "items": _counts(record.get("inventory", [])),
		"spend_receipts": receipts.filter(func(r: Variant) -> bool: return str(r).begins_with("essence_spend:")),
		"release_receipts": personal.get("release_receipts", []).duplicate(),
		"receipt_count": receipts.size()}


## The owner's own live portable record (what its next save and ACK carry).
static func _snapshot(runner: SceneTree) -> Dictionary:
	var game := _game(runner)
	if game == null or game.get("local") == null: return _fail("no local owner")
	var record := preload("res://scripts/net/character_record_rules.gd").portable_projection(game.get("local").call("save_data"))
	var data := _summary(record)
	data["character_id"] = str(game.get("local").get("character_id"))
	var session: Node = game.get("session")
	data["active"] = session != null and session.call("is_active") == true
	return _ok("owner %s" % data.character_id, data)


## Host only: the host's admitted authority view of one character and its
## single latest training row, both of which reconnect/reload replay from.
static func _host_view(runner: SceneTree, character_id: String) -> Dictionary:
	var game := _game(runner)
	if game == null or game.call("is_host") != true: return _fail("host view requires the host")
	var session: Node = game.get("session")
	var authority: Object = session.get("_character_authority")
	var state: Variant = authority.call("state", character_id) if authority != null else {}
	var world: RefCounted = game.get("world")
	var row: Variant = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character_id))
	var data := _summary(state) if state is Dictionary and not state.is_empty() else {}
	data["row"] = {"status": row.get("status"), "action": row.get("action"), "action_id": row.get("action_id"),
		"receipt": row.get("receipt")} if row is Dictionary else {}
	data["cut"] = runner.get_meta("f27_host_cut", {})
	return _ok("host view of %s" % character_id, data)


## Host only. One-shot: when the host journals this character's Altar spend,
## drop that guest's link before the delivery leaves this process (deferred
## to the end of this frame, so the queued delivery is discarded unsent).
static func _arm_host_cut(runner: SceneTree, character_id: String) -> Dictionary:
	var game := _game(runner)
	var writer: Node = runner.root.get_node_or_null(^"Game/Session/LedgerRpc")
	if game == null or game.call("is_host") != true or writer == null or character_id.is_empty():
		return _fail("host writer and guest character required")
	runner.set_meta("f27_host_cut", {})
	var holder := {"callable": Callable()}
	holder.callable = func(observation: Dictionary) -> void:
		if observation.get("phase") != "after_host_write_before_delivery" or observation.get("action") != "altar_spend" \
				or observation.get("character_id") != character_id: return
		writer.disconnect("transaction_boundary", holder.callable)
		var session: Node = game.get("session")
		var target := -1
		for peer: int in runner.root.multiplayer.get_peers():
			if session.call("_authority_character", peer) == character_id: target = peer
		runner.set_meta("f27_host_cut", {"observation": observation.duplicate(true), "peer": target})
		var transport: MultiplayerPeer = runner.root.multiplayer.multiplayer_peer
		if target > 0 and transport != null:
			# A forced ENet drop discards the queued delivery but emits no
			# peer_disconnected, so also deliver the transport's own signal:
			# the host must see the link die exactly as a pulled cable does.
			var drop := func() -> void:
				transport.disconnect_peer(target, true)
				transport.peer_disconnected.emit(target)
			drop.call_deferred()
	writer.connect("transaction_boundary", holder.callable)
	return _ok("armed host cut for %s" % character_id)


static func _service(runner: SceneTree) -> Node:
	return preload("res://scripts/ui/altar_service.gd").attach(_game(runner))


## The guest's AltarService quote then submit, the same calls the panel makes
## (the panel's controller path is proven by smoke_f27_altar_spend.gd).
## cut "owner_before_ack" hard-kills this process at the owner save edge.
static func _altar_spend(runner: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(runner)
	var key := str(args.get("station_key", ""))
	var payment := str(args.get("payment_item", ""))
	var service := _service(runner)
	var party: RefCounted = game.get("party") if game != null else null
	if service == null or party == null or party.call("size") < 1: return _fail("service and an owned creature required")
	var uid := str((party.call("at", 0) as RefCounted).get("uid"))
	for i in 600:
		if service.call("station_available", key) == true: break
		await runner.physics_frame
	if service.call("station_available", key) != true:
		return _fail("the Altar is not available to this owner (reach/registration)")
	var quote: Dictionary = service.call("quote_essence_spend", key, uid)
	if quote.get("pending") == true:
		var box := {"quote": {}}
		var listener := func(station: String, owned: String, result: Dictionary) -> void:
			if station == key and owned == uid: box.quote = result
		service.connect("essence_quote_completed", listener)
		for i in 600:
			await runner.physics_frame
			if not (box.quote as Dictionary).is_empty(): break
		service.disconnect("essence_quote_completed", listener)
		quote = box.quote
	if quote.get("ok") != true: return _fail("quote refused: %s" % str(quote))
	var request := {"spend_id": Crypto.new().generate_random_bytes(16).hex_encode(), "creature_uid": uid,
		"expected_level": int(quote.level), "payment_item": payment,
		"expected_character_revision": int(quote.expected_character_revision)}
	var cut := str(args.get("cut", ""))
	var writer: Node = runner.root.get_node_or_null(^"Game/Session/LedgerRpc")
	if cut == "owner_before_ack":
		writer.connect("transaction_boundary", func(observation: Dictionary) -> void:
			if observation.get("phase") == "after_owner_write_before_ack" and observation.get("action") == "altar_spend":
				print("F27 OWNER CUT: hard kill after owner write, before ACK: %s" % str(observation.get("receipt")))
				OS.kill(OS.get_process_id()))
	var box := {"result": {}}
	var completed := func(spend_id: String, result: Dictionary) -> void:
		if spend_id == request.spend_id: box.result = result
	service.connect("essence_spend_completed", completed)
	service.call("submit_essence_spend", key, request)
	var session: Node = game.get("session")
	for i in 1200:
		await runner.physics_frame
		if (box.result as Dictionary).get("resolved") == true: break
		if cut == "host_before_delivery" and session.call("is_active") != true: break
	service.disconnect("essence_spend_completed", completed)
	return _ok("spend %s -> %s" % [request.spend_id, str(box.result)],
		{"request": request, "result": box.result, "quote_cost": _cost(quote, payment), "active": session.call("is_active") == true})


static func _cost(quote: Dictionary, payment: String) -> int:
	for row: Variant in quote.get("payments", []):
		if row is Dictionary and row.get("id") == payment: return int(row.get("cost", -1))
	return -1


## Resend one ORIGINAL request through Session exactly as a stale client or a
## restarted panel would. The host must answer from its retained decision.
static func _altar_replay(runner: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(runner)
	var session: Node = game.get("session") if game != null else null
	var request: Dictionary = args.get("request", {})
	if session == null or request.is_empty(): return _fail("session and original request required")
	var key := str(args.get("station_key", ""))
	for i in 600:
		if session.call("altar_station_available", key) == true: break
		await runner.physics_frame
	var box := {"result": {}}
	var completed := func(station: String, spend_id: String, result: Dictionary) -> void:
		if station == key and spend_id == request.spend_id: box.result = result
	session.connect("altar_essence_spend_completed", completed)
	var sync: Variant = session.call("submit_altar_essence_spend", key, request.duplicate(true))
	if sync is Dictionary and sync.get("resolved") == true: box.result = sync
	for i in 600:
		if (box.result as Dictionary).get("resolved") == true: break
		await runner.physics_frame
	session.disconnect("altar_essence_spend_completed", completed)
	return _ok("replayed %s -> %s" % [request.spend_id, str(box.result)], {"result": box.result})


## A restarted guest process rejoins exactly as a returning player does: the
## real title's direct join (`_join_via`), which loads this home's own slot-0
## save before joining. No live identity is preselected; the joined id must be
## the original character or the step fails.
static func _title_rejoin(runner: SceneTree, args: Dictionary) -> Dictionary:
	var game := _game(runner)
	var wanted := str(args.get("character_id", ""))
	if game == null or wanted.is_empty(): return _fail("Game and the original character id required")
	var session: Node = game.get("session")
	var budget := int(args.get("budget_frames", 6000))
	var used := 0
	var attempts := 0
	while used < budget:
		attempts += 1
		if runner.current_scene == null or not runner.current_scene.is_in_group(&"title_screen"):
			if runner.change_scene_to_file("res://scenes/ui/title_screen.tscn") != OK: return _fail("could not enter the title")
		var title: Node = null
		for i in 240:
			await runner.physics_frame
			used += 1
			if runner.current_scene != null and runner.current_scene.is_in_group(&"title_screen"):
				title = runner.current_scene
				break
		if title == null: return _fail("the title did not become current")
		title.call("_join_via", str(args.get("host", "127.0.0.1")), int(args.get("port", 0)))
		var started := false
		while used < budget:
			await runner.physics_frame
			used += 1
			var driver := game.get_node_or_null(^"JoinDriver")
			if driver != null and bool(driver.call("is_running")): started = true
			if (driver == null or not bool(driver.call("is_running"))) and session.call("is_active") == true \
					and session.call("snapshot_ready") == true:
				var joined := str(game.get("local").get("character_id"))
				if joined != wanted: return _fail("title rejoin joined as '%s', expected '%s'" % [joined, wanted])
				return _ok("title rejoin as %s after %d frames, %d attempt(s)" % [joined, used, attempts])
			# Refused (e.g. character_in_use while the host still holds the
			# dead link): the driver stops and the game returns to the title.
			if started and (driver == null or not bool(driver.call("is_running"))) and session.call("is_active") != true \
					and runner.current_scene != null and runner.current_scene.is_in_group(&"title_screen"):
				break
		for i in 600:
			await runner.physics_frame
			used += 1
	return _fail("title rejoin did not complete in %d frames (%d attempts)" % [budget, attempts])


## Diagnostic only: the owner-passive stream both sides hold for a character.
static func _passive_state(runner: SceneTree, character_id: String) -> Dictionary:
	var game := _game(runner)
	var session: Node = game.get("session") if game != null else null
	var service: Variant = session.get("_owner_passive") if session != null else null
	if service == null: return _ok("no owner passive service", {})
	var local: Dictionary = service.get("local")
	var data := {"is_host": session.call("is_host"), "recording_active": service.call("recording_active"),
		"local": {"error": local.get("error"), "admission_pending": local.get("admission_pending"),
			"sequence": local.get("sequence"), "acked": local.get("acked"), "inputs": (local.get("inputs", []) as Array).size(),
			"rebase": not (local.get("rebase", {}) as Dictionary).is_empty()},
		"pending": (service.get("pending") as Dictionary).keys(), "committing": not (service.get("committing") as Dictionary).is_empty(),
		"saving": service.get("saving"), "altar_original": not (session.get("_owner_passive_altar_original") as Dictionary).is_empty()}
	var hosts: Dictionary = service.get("hosts")
	if hosts.has(character_id):
		var stream: Dictionary = hosts[character_id]
		var checkpoint: Dictionary = stream.get("checkpoint", {})
		data["host_stream"] = {"error": stream.get("error"), "checkpoint": checkpoint.get("source_kind", ""),
			"checkpoint_keys": checkpoint.keys(), "cursor_sequence": (stream.get("cursor", {}) as Dictionary).get("sequence"),
			"keys": stream.keys()}
	return _ok("owner passive state", data)
