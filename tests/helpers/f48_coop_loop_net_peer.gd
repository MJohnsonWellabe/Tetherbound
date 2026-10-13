extends "res://tests/helpers/hall_agreement_net_peer.gd"

## F48#0 peer for tests/smoke_net_f48_coop_loop.gd. Thin: the Hall-agreement
## peer's craft/pedestal steps and peer_runner's f28_/boss steps unchanged,
## plus the F49 portal-travel input helpers (tests/helpers/f49_portal_travel.gd)
## as steps, and one read-only receipts view. Nothing here grants anything.
const LOOP_TRAVEL := preload("res://tests/helpers/f49_portal_travel.gd")
const LOOP_RECORD := preload("res://scripts/net/character_record_rules.gd")
const LOOP_STOCK := preload("res://scripts/world/death_satchel_rules.gd")
const LOOP_ITEMS := ["potion_small", "berries", "fiber", "rootstone", "attuned_ground",
	"feast_t1_ground", "tidewake_portal_key", "home_key", "tether_candy"]

func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	var args: Dictionary = msg.get("args", {})
	match action:
		"loop_home_key": return await _loop_travel("home_key", args)
		"loop_arch_enter": return await _loop_arch_enter(args)
		"loop_hang_relic": return await _loop_travel("hang_relic", args)
		"loop_receipts": return _loop_receipts(str(args.get("character_id", "")))
	return await super._execute_step(msg)

## Ordinary Satchel Home Key, or the Shrine Room pedestal hang (which closes
## the relic power chooser by deferring it), as f49_portal_travel plays them.
func _loop_travel(kind: String, args: Dictionary) -> Dictionary:
	var game := root.get_node("Game")
	await _loop_input_free()
	var travel := LOOP_TRAVEL.new(self, game)
	var ok: bool = await travel.home_key() if kind == "home_key" else await travel.hang_relic(str(args.get("biome", "meadows")))
	return {"verdict": "PASS" if ok else "FAIL", "detail": kind + (" done" if ok else ": " + str(travel.failures)),
		"data": {"realm": str(game.get("current_realm"))}}

## The Crossing Hall arch's own controller prompt (Enter), then the ready realm.
func _loop_arch_enter(args: Dictionary) -> Dictionary:
	var game := root.get_node("Game")
	var id := str(args.get("arch", "home"))
	var realm := str(args.get("realm", "meadows"))
	var arch: Node3D = null
	for candidate: Node in get_nodes_in_group("portal_arches"):
		if current_scene != null and current_scene.is_ancestor_of(candidate) and candidate.get("arch_id") == id:
			arch = candidate as Node3D
	if arch == null: return {"verdict": "FAIL", "detail": "no live %s arch" % id}
	await _loop_input_free()
	var replies: Array = []
	var note := func(result: Dictionary) -> void:
		if result.get("kind") == "portal_enter": replies.append(result.duplicate(true))
	game.connect("portal_action_result", note)
	var travel := LOOP_TRAVEL.new(self, game)
	var ok: bool = await travel.activate(arch.get_node_or_null(^"Interactable") as Node3D)
	for frame in 7200:
		if not ok or (not replies.is_empty() and replies.back().get("ok") != true): break
		if not replies.is_empty() and travel.call("_ready_world", realm): break
		await process_frame
	game.disconnect("portal_action_result", note)
	var reply: Dictionary = replies.back() if not replies.is_empty() else {}
	ok = ok and reply.get("ok") == true and travel.call("_ready_world", realm)
	return {"verdict": "PASS" if ok else "FAIL", "detail": "%s arch Enter to %s" % [id, realm] + ("" if ok else ": %s %s" % [str(travel.failures), str(reply)]),
		"data": {"reply": reply, "realm": str(game.get("current_realm"))}}

## A player waits for any saved decision holding its input (Session.owns_input).
func _loop_input_free() -> void:
	var deadline := Time.get_ticks_msec() + 30000
	while bool(_session().call("owns_input")) and Time.get_ticks_msec() < deadline:
		await physics_frame

## Read-only: the owner's own portable record, or (host, character_id) the
## host's admitted record of that character.
func _loop_receipts(character_id: String) -> Dictionary:
	var game := root.get_node("Game")
	var record: Dictionary
	if character_id.is_empty():
		record = LOOP_RECORD.portable_projection(game.get("local").call("save_data"))
		character_id = str(game.get("local").get("character_id"))
	else:
		if game.call("is_host") != true: return {"verdict": "FAIL", "detail": "admitted view requires the host"}
		record = game.get("session").get("_character_authority").call("state", character_id)
	var personal: Dictionary = record.get("redesign_character", {})
	var stock := LOOP_STOCK.inventory_from(record.get("inventory", []))
	var items := {}
	for id: String in LOOP_ITEMS: items[id] = stock.count(id)
	var caps := {}
	for uid: String in personal.get("creatures", {}):
		caps[uid] = int(personal.creatures[uid].get("cap_level", -1))
	return {"verdict": "PASS", "detail": "%s receipts" % character_id, "data": {"character_id": character_id,
		"items": items, "caps": caps,
		"master_wins": (personal.get("master_wins", []) as Array).duplicate(),
		"feast_recipes": (personal.get("feast_recipes", []) as Array).duplicate(),
		"relics_held": (personal.get("relics_held", []) as Array).duplicate(),
		"relics_hung": (personal.get("relics_hung", []) as Array).duplicate(),
		"receipts": (personal.get("transaction_receipts", []) as Array).duplicate()}}
