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
##   * `camp_records`: this peer's forward-camp records and planted nodes.

const KIT := "forward_camp_kit"
const CAMP_SCRIPT := preload("res://scripts/build/forward_camp.gd")

var _camp_answers: Array = []


func _on_action_completed(op: String, _intent: Dictionary, result: Dictionary) -> void:
	if op == "camp_build": _camp_answers.append(result.duplicate(true))


func _execute_step(msg: Dictionary) -> Dictionary:
	var action := str(msg.get("action", ""))
	if not action.begins_with("camp_"):
		return await super._execute_step(msg)
	# The runner forwards only verdict/detail/data: every other key rides in data.
	var raw: Dictionary = await _camp_dispatch(action, msg.get("args", {}))
	var data: Dictionary = {}
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
			return await _place(game, float(args.get("away", 20.0)))
	return {"verdict": "ERROR", "detail": "unknown action " + action}


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


func _place(game: Node, away: float) -> Dictionary:
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
	if spot == Vector3.INF: return {"verdict": "FAIL", "detail": "no valid camp ground"}
	# The runner's own teleport (teleport_body + owner-passive catch-up), so the
	# host's view of this trainer follows it.
	var stood := spot + Vector3(0.0, 0.5, 3.0)
	await _step_teleport({"at": [stood.x, stood.y, stood.z], "settle": 30})
	game.set("pending_build", "forward_camp")
	for _frame in 30:
		await physics_frame
	placer.set("_yaw_deg", 0.0)
	(placer.get("_ghost") as Node3D).global_position = spot
	placer.call("_place", game, "forward_camp")
	var settled := false
	for _frame in 240:
		await physics_frame
		var mine: Array = (_records(game).records as Array).filter(func(r: Dictionary) -> bool:
			return r.character_id == str(game.get("local").get("character_id")))
		if not mine.is_empty():
			settled = true
			break
	game.set("pending_build", "")
	var pending: Variant = session.get("_foundation_camp_pending") if session != null else {}
	var out := _records(game)
	out.verdict = "PASS" if settled else "FAIL"
	out.detail = "placed at %s: %s; pending %s; answers %s" % [str(spot), str(out.detail), JSON.stringify(pending), JSON.stringify(_camp_answers)]
	out.spot = [spot.x, spot.y, spot.z]
	return out
