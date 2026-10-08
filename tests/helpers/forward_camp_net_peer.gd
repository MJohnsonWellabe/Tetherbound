extends "res://tools/net/peer_runner.gd"

## Peer for tests/smoke_net_forward_camp.gd (F34#4). The ordinary
## tools/net/peer_runner.gd plus camp_* actions. DISCLOSED FIXTURES:
##   * `camp_grant_kit`: adds forward-camp kits straight to this peer's satchel
##     (before join for a guest, so the host's admitted inventory holds them).
##   * `camp_place`: finds valid ground with the placer's own preview (grid
##     snap + camp ground check), at least `away` metres from any existing
##     camp, teleports this peer's Player 3 m from it (the runner's own
##     teleport), aims the ghost there and
##     presses Place through the PRODUCTION BuildPlacer._place (-> Session
##     forward_camp_submit_build -> host Foundation camp_build).
##     `presses: 2` presses twice (the pack-up offer, then its acceptance).
##   * `camp_records`: this peer's forward-camp records and planted nodes.

const KIT := "forward_camp_kit"
const CAMP_SCRIPT := preload("res://scripts/build/forward_camp.gd")
const LOADOUT_PANEL := preload("res://scripts/ui/companion_details_panel.gd")

var _camp_answers: Array = []


func _on_action_completed(op: String, _intent: Dictionary, result: Dictionary) -> void:
	if op == "camp_build": _camp_answers.append(result.duplicate(true))


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if not action.begins_with("camp_"):
		return await super._execute_step(msg)
	# The runner forwards only verdict/detail/data: every other key rides in data.
	var raw: Dictionary = await _camp_dispatch(action, msg.get("args", {}))
	var data: Dictionary = raw.get("data", {}).duplicate(true)
	for key: Variant in raw:
		if not str(key) in ["verdict", "detail", "data"]: data[key] = raw[key]
	return {"verdict": raw.get("verdict", "ERROR"), "detail": raw.get("detail", ""), "data": data}


func _camp_dispatch(action: String, args: Dictionary) -> Dictionary:
	var game: Node = root.get_node_or_null(^"Game")
	if game == null: return {"verdict": "ERROR", "detail": "no Game"}
	var inventory: RefCounted = game.get("local").get("inventory")
	match action:
		"camp_grant_kit":
			inventory.call("add", KIT, int(args.get("n", 1)))
			return {"verdict": "PASS", "detail": "%d kit(s) held" % int(inventory.call("count", KIT)), "kits": int(inventory.call("count", KIT))}
		"camp_records":
			return _records(game)
		"camp_place":
			return await _place(game, float(args.get("away", 20.0)), int(args.get("presses", 1)))
		"camp_loadout_edit":
			return await _edit_loadout(game)
		"camp_loadout_view":
			return _loadout_view(game, str(args.get("character_id", "")), str(args.get("uid", "")))
	return {"verdict": "ERROR", "detail": "unknown action " + action}


## F23: same camp and granted creature; press the production panel's equip
## callback. No direct mutation of moves or admitted character state.
func _edit_loadout(game: Node) -> Dictionary:
	var camp: Node3D = null
	var camp_uid := ""
	for row: Dictionary in game.get("placed_buildings"):
		if row.get("id") == "forward_camp" and row.get("removed") != true and row.get("character_id") == game.get("local").get("character_id"):
			camp_uid = str(row.get("uid", ""))
	for node: Node in get_nodes_in_group("placed_building"):
		if not camp_uid.is_empty() and node.get_script() == CAMP_SCRIPT and node.get_meta("building_uid", "") == camp_uid:
			camp = node
			break
	if camp == null: return {"verdict": "FAIL", "detail": "guest camp unavailable"}
	var at := camp.global_position + Vector3(0, 0.5, 2)
	await _step_teleport({"at": [at.x, at.y, at.z], "settle": 30})
	camp.call("open_loadouts")
	var panel: Node = null
	for node: Node in game.get_children():
		if node.get_script() == LOADOUT_PANEL: panel = node
	if panel == null or panel.get("_shown") != true: return {"verdict": "FAIL", "detail": "camp loadout panel did not open"}
	var uid: String = panel.get("_uid")
	var before := _loadout_view(game, "", uid)
	if before.card.get("move_utility") == "quake_ring":
		panel.call("close")
		return {"verdict": "FAIL", "detail": "utility must actually change", "card": before.card}
	panel.call("_choose_slot", "utility")
	for frame: int in 600:
		if panel.get("_pending_edit") == "" and int(_loadout_view(game, "", uid).card.get("loadout_revision", -1)) == int(before.card.get("loadout_revision", -1)):
			panel.call("_equip", "quake_ring")
		elif frame % 30 == 0: panel.call("_reconcile_loadout")
		await physics_frame
		var current := _loadout_view(game, "", uid)
		if current.card.get("move_utility") == "quake_ring" and not current.card.get("loadout_last_edit", {}).is_empty() and int(current.card.get("loadout_revision", -1)) == int(before.card.get("loadout_revision", -1)) + 1 and panel.get("_pending_edit") == "":
			panel.call("close")
			return current
	return {"verdict": "FAIL", "detail": "loadout original did not settle", "card": _loadout_view(game, "", uid).card}


func _loadout_view(game: Node, character: String, uid: String) -> Dictionary:
	var party: Array = []
	var local: RefCounted = game.get("local")
	if character.is_empty() or character == local.get("character_id"):
		party = local.call("save_data").get("party", [])
	else:
		var session: Node = game.get("session")
		var registry: RefCounted = session.get("_registry")
		var peer := int(registry.call("peer_for_character", character))
		party = session.call("admitted_character_state", peer).get("party", [])
	for raw: Dictionary in party:
		if uid.is_empty() or raw.get("uid") == uid:
			var card := {}
			for field: String in ["uid", "move_quick", "move_charged", "move_utility", "move_ultimate", "loadout_revision", "loadout_last_edit"]:
				card[field] = raw.get(field)
			return {"verdict": "PASS", "detail": "saved loadout projection", "card": card}
	return {"verdict": "FAIL", "detail": "owned loadout absent", "card": {}}


func _records(game: Node) -> Dictionary:
	var rows: Array = []
	for row: Dictionary in game.get("placed_buildings"):
		if row.get("id") == "forward_camp" and row.get("removed") != true:
			rows.append({"uid": str(row.get("uid")), "character_id": str(row.get("character_id", "")),
				"realm": str(row.get("realm", "")), "position": row.get("position")})
	var nodes := 0
	for node: Node in get_nodes_in_group("placed_building"):
		if node.get_script() == CAMP_SCRIPT: nodes += 1
	var session: Node = game.get("session") as Node
	var pending: bool = session != null and not (session.get("_foundation_camp_pending") as Dictionary).is_empty()
	return {"verdict": "PASS", "detail": "%d record(s), %d node(s)" % [rows.size(), nodes], "records": rows, "pending": pending,
		"nodes": nodes, "kits": int(game.get("local").get("inventory").call("count", KIT)),
		"character_id": str(game.get("local").get("character_id"))}


func _place(game: Node, away: float, presses: int = 1) -> Dictionary:
	var placer: Node = null
	for node: Node in get_nodes_in_group("build_placer"):
		placer = node
		break
	var player := game.call("find_player") as CharacterBody3D
	if placer == null or player == null: return {"verdict": "ERROR", "detail": "no placer or player"}
	# A guest's placement opens once its personal view (admitted revision) is
	# here; the ghost reads refused until then, as it would for a player.
	var session: Node = game.get("session") as Node
	if session != null and not session.is_connected("homestead_action_completed", _on_action_completed):
		session.connect("homestead_action_completed", _on_action_completed)
	_camp_answers.clear()
	for _frame in 300:
		if session == null or session.call("forward_camp_placement_available") == true: break
		await physics_frame
	var existing: Array[Vector3] = []
	for row: Dictionary in game.get("placed_buildings"):
		if row.get("id") == "forward_camp" and row.get("removed") != true:
			existing.append(Vector3(float(row.position[0]), float(row.position[1]), float(row.position[2])))
	var spot := Vector3.INF
	var origin := player.global_position
	for ring in range(1, 60):
		for step in 16:
			var angle := TAU * float(step) / 16.0
			var at := origin + Vector3(cos(angle), 0.0, sin(angle)) * float(ring) * 4.0
			var height := float(placer.call("_ground_height", at))
			if not is_finite(height): continue
			at.y = height
			var clear := true
			for other: Vector3 in existing:
				clear = clear and other.distance_to(at) > away
			if not clear: continue
			var preview: Dictionary = placer.call("preview_placement", game, "forward_camp", at)
			if preview.get("ok") == true and preview.get("position") is Vector3:
				spot = preview.position
				break
		if spot != Vector3.INF: break
	if spot == Vector3.INF:
		return {"verdict": "FAIL", "detail": "no valid camp ground (placement available %s, %d kit(s))" % [
			str(session.call("forward_camp_placement_available")), int(game.get("local").get("inventory").call("count", KIT))]}
	# Short guest relocations must be walked: the discovery replay correctly
	# checks their speed. Walk and both prefix fences share the existing 600
	# frames; longer moves retain the runner's disclosed teleport/catch-up.
	var stood := spot + Vector3(0.0, 0.5, 3.0)
	var stood_result: Dictionary
	if session != null and session.call("is_host") == false \
			and player.global_position.distance_to(stood) <= 30.0:
		var began := Engine.get_physics_frames()
		var binding: Dictionary = {}
		stood_result = await _await_owner_passive_caught_up(600, false, binding)
		if stood_result.get("verdict") != "PASS": return stood_result
		stood_result = await _step_move_to({"x": stood.x, "z": stood.z,
			"close_enough": 0.8,
			"budget_frames": maxi(0, 600 - int(Engine.get_physics_frames() - began))})
		if stood_result.get("verdict") != "PASS": return stood_result
		if Engine.get_physics_frames() - began > 600:
			return {"verdict": "FAIL", "detail": "short camp approach exceeded the original 600-frame allowance"}
		stood_result = await _await_owner_passive_caught_up(
			maxi(0, 600 - int(Engine.get_physics_frames() - began)), true, binding)
	else:
		stood_result = await _step_teleport({"at": [stood.x, stood.y, stood.z], "settle": 30})
	if stood_result.get("verdict") != "PASS":
		return stood_result
	game.set("pending_build", "forward_camp")
	for _frame in 30:
		await physics_frame
	var before: Array = (_records(game).records as Array).filter(func(r: Dictionary) -> bool:
		return r.character_id == str(game.get("local").get("character_id"))).map(func(r: Dictionary) -> String: return r.uid)
	var messages: Array = []
	for press in presses:
		# Aimed at the spot for every press: the placer re-aims its ghost from
		# the camera each frame, and a player holds the aim between presses.
		placer.set("_yaw_deg", 0.0)
		(placer.get("_ghost") as Node3D).global_position = spot
		game.set("_pending_world_message", "")
		placer.call("_place", game, "forward_camp")
		messages.append(str(game.get("_pending_world_message")))
		for _frame in 10:
			await physics_frame
	var settled := false
	for _frame in 900:
		await physics_frame
		var mine: Array = (_records(game).records as Array).filter(func(r: Dictionary) -> bool:
			return r.character_id == str(game.get("local").get("character_id")) and not before.has(r.uid))
		if not mine.is_empty():
			settled = true
			break
	game.set("pending_build", "")
	var pending: Variant = session.get("_foundation_camp_pending") if session != null else {}
	var out := _records(game)
	out.verdict = "PASS" if settled else "FAIL"
	out.detail = "placed at %s: %s; pending %s; answers %s" % [str(spot), str(out.detail), JSON.stringify(pending), JSON.stringify(_camp_answers)]
	out.spot = [spot.x, spot.y, spot.z]
	out.messages = messages
	return out
