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


func _initialize() -> void:
	if OS.get_cmdline_user_args().has("--heal-pulse"):
		# Disclosed candidate scope, before world boot; shipping flags stay OFF.
		var math: Script = preload("res://scripts/combat/combat_math.gd")
		math._config = math.config().duplicate(true)
		math._config.actor_vitals.runtime_enabled = true
	super._initialize()


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
			return await _place(game, float(args.get("away", 20.0)), int(args.get("presses", 1)))
		"camp_loadout_edit":
			return await _edit_loadout(game, args)
		"camp_loadout_view":
			return _loadout_view(game, str(args.get("character_id", "")), str(args.get("uid", "")))
		"camp_heal_deploy":
			for cycle: int in game.party.size():
				if game.party.active().species_id == "meadowhart": break
				var pressed: Dictionary = await _step_press({"action":"party_cycle", "settle":30})
				if pressed.get("verdict") != "PASS": return pressed
			if game.party.active().species_id != "meadowhart": return {"verdict":"FAIL", "detail":"normal LB did not select the owned healer"}
			return await _step_deploy_creature({})
		"camp_heal_target":
			var director: Node = _encounter_director()
			var selected: Node3D = null
			var largest := 0.0
			for wild: Node3D in director.get("_wild_creatures"):
				if not is_instance_valid(wild) or not wild.is_inside_tree() or not wild.visible or not wild.is_alive(): continue
				var creature: RefCounted = wild.get("instance")
				if creature != null and float(creature.hp) > largest:
					selected = wild
					largest = float(creature.hp)
			if selected == null: return {"verdict":"FAIL", "detail":"no actual living wild"}
			var at := selected.global_position + Vector3(2, 0, 0)
			await _step_teleport({"at":[at.x, at.y, at.z], "settle":6})
			var engaged: Dictionary = await _step_engage_wild({})
			var record: Dictionary = director.encounter_record()
			return {"verdict":engaged.get("verdict", "FAIL"), "detail":engaged.get("detail", ""),
				"encounter_id":record.get("encounter_id", ""), "position":[selected.global_position.x, selected.global_position.y, selected.global_position.z]}
		"camp_heal_wounded":
			var manager: Node = _combat_manager()
			var director: Node = _encounter_director()
			var target: Node3D = director.get("_shared_opponent_proxy")
			var body: Node3D = director.ally_body()
			if target == null or body == null: return {"verdict":"FAIL", "detail":"shared combat bodies missing"}
			# The existing proximity fixture supplies position, never HP or an AI hit.
			body.global_position = target.global_position + Vector3(0, 0, 3)
			for wound_frame: int in 600:
				var observed := _heal_view(game, str(game.local.character_id), str(args.get("uid", "")))
				if not manager.is_fighting() or manager.active_creature() == null or manager.active_creature().fainted:
					return {"verdict":"FAIL", "detail":"actual wild fight ended before saved damage", "observation":observed}
				if float(observed.get("hp", 0.0)) > 0.0 and float(observed.get("hp", 0.0)) < float(observed.get("max_hp", 0.0)) \
					and observed.get("marker", {}).get("status") == "settled" and observed.get("disk", {}).get("hp") == observed.get("hp"):
					var clear := target.global_position + Vector3(18, 0, 0)
					clear.y = body.global_position.y
					body.global_position = clear
					for clear_frame: int in 30: await physics_frame
					return {"verdict":"PASS", "detail":"actual enemy damage saved before the Heal tap", "observation":_heal_view(game, str(game.local.character_id), str(args.get("uid", "")))}
				await physics_frame
			return {"verdict":"FAIL", "detail":"actual enemy damage did not settle within the existing 600-frame budget", "observation":_heal_view(game, str(game.local.character_id), str(args.get("uid", "")))}
		"camp_heal_view":
			return {"verdict":"PASS", "detail":"read-only canonical Heal observation", "observation":_heal_view(game, str(args.get("character_id", "")), str(args.get("uid", "")))}
	return {"verdict": "ERROR", "detail": "unknown action " + action}


## F23: same camp and granted creature; press the production panel's equip
## callback. No direct mutation of moves or admitted character state.
func _edit_loadout(game: Node, args: Dictionary = {}) -> Dictionary:
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
	if not str(args.get("species", "")).is_empty():
		for member: RefCounted in game.party.members():
			if member.species_id == str(args.species):
				panel.call("_select_owned", str(member.uid))
				break
	var uid: String = panel.get("_uid")
	var before := _loadout_view(game, "", uid)
	var move_id: String = str(args.get("move_id", "quake_ring"))
	if before.card.get("move_utility") == move_id:
		panel.call("close")
		return {"verdict": "FAIL", "detail": "utility must actually change", "card": before.card}
	panel.call("_choose_slot", "utility")
	for frame: int in 600:
		if panel.get("_pending_edit") == "" and int(_loadout_view(game, "", uid).card.get("loadout_revision", -1)) == int(before.card.get("loadout_revision", -1)):
			panel.call("_equip", move_id)
		elif frame % 30 == 0: panel.call("_reconcile_loadout")
		await physics_frame
		var current := _loadout_view(game, "", uid)
		if current.card.get("move_utility") == move_id and not current.card.get("loadout_last_edit", {}).is_empty() and int(current.card.get("loadout_revision", -1)) == int(before.card.get("loadout_revision", -1)) + 1 and panel.get("_pending_edit") == "":
			panel.call("close")
			return current
	return {"verdict": "FAIL", "detail": "loadout original did not settle", "card": _loadout_view(game, "", uid).card}


func _heal_view(game: Node, character: String, uid: String) -> Dictionary:
	var session: Node = game.get("session")
	var row := {}
	for delivery: Dictionary in game.world.reward_deliveries.values():
		if delivery.get("kind") == "actor_vitals" and delivery.get("character_id") == character and delivery.get("creature_uid") == uid:
			row = delivery.duplicate(true)
	var out := {"row":row, "originals":[]}
	var director: Node = _encounter_director()
	for original: Dictionary in director.get("_ordinary_actor_vitals_proposals").values():
		if original.has("heal_bundle") and original.get("proposal", {}).get("creature_uid") == uid:
			out.originals.append(original.duplicate(true))
	if character != str(game.local.character_id): return out
	var creature: RefCounted = null
	for member: RefCounted in game.party.members():
		if str(member.uid) == uid: creature = member
	if creature == null: return out
	var saved: Dictionary = game.save_system.characters().read(character)
	var disk := {}
	for card: Dictionary in saved.get("party", []):
		if card.get("uid") == uid: disk = card.duplicate(true)
	var manager: Node = _combat_manager()
	var receipt: String = str(row.get("receipt", {}).get("receipt_id", ""))
	var hash: String = preload("res://scripts/net/research_passive_preparation.gd").fingerprint(row.get("receipt", {}))
	var seen: Dictionary = session._owner_passive_service().get("local").get("vitals_seen", {})
	out.merge({"hp":creature.hp, "max_hp":creature.max_hp, "disk":disk,
		"disk_marker":saved.get("satchel_escrow", {}).get(row.get("delivery_id", ""), {}).duplicate(true),
		"marker":game.local.satchel_escrow.get(row.get("delivery_id", ""), {}).duplicate(true),
		"saved_bool_seen":seen.has("actor_vitals_saved:" + hash + ":" + str(row.get("journal_revision", -1))),
		"feedback_seen":not receipt.is_empty() and manager.get("_seen_impact_actions").has(receipt),
		"uses":creature.move_mastery_uses.duplicate(true), "receipts":creature.move_mastery_receipts.duplicate(true),
		"active_uid":str(manager.active_creature().uid) if manager.active_creature() != null else "",
		"awaiting":manager.get("_move_awaiting_host")}, true)
	return out


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
	# The runner's own teleport (teleport_body + owner-passive catch-up), so the
	# host's view of this trainer follows it.
	var stood := spot + Vector3(0.0, 0.5, 3.0)
	await _step_teleport({"at": [stood.x, stood.y, stood.z], "settle": 30})
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
