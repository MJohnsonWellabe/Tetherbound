extends RefCounted

## F28#2/#4 peer steps for tests/smoke_net_f28_masters.gd. Challenges and chest
## opens go through the shipping BreakthroughService -> Session foundation
## path; the fight itself is driven by peer_runner's win_trainer_battle (real
## host-arbitrated swings). Nothing here grants a win, recipe, candy or receipt.
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")


static func run(runner: SceneTree, action: String, args: Dictionary) -> Dictionary:
	match action:
		"f28_site": return _site_view(runner, str(args.get("master_id", "")))
		"f28_challenge": return await _challenge(runner, args)
		"f28_chest": return await _chest(runner, args)
		"f28_view": return _view(runner, str(args.get("character_id", "")), str(args.get("master_id", "")))
		"f28_await_fight_end": return await _await_fight_end(runner, int(args.get("budget_frames", 3600)))
		"f28_stand": return await _stand(runner, args)
		"f28_host_duels": return _host_duels(runner)
		"f28_feast_seed": return _feast_seed(runner, args)
		"f28_cook": return await _feast_press(runner, args, "cook")
		"f28_feed": return await _feast_press(runner, args, "feed")
		"f28_feast_view": return _feast_view(runner, str(args.get("character_id", "")))
		"f28_station_at": return await _station_at(runner, str(args.get("kitchen_uid", "")))
	return {"verdict": "ERROR", "detail": "unknown F28 action '%s'" % action}


static func _ok(detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "PASS", "detail": detail, "data": data}


static func _fail(detail: String, data: Dictionary = {}) -> Dictionary:
	return {"verdict": "FAIL", "detail": detail, "data": data}


static func _service(runner: SceneTree) -> Node:
	return runner.root.get_node_or_null(^"Game/Session/FoundationComposition/BreakthroughService")


static func _site(runner: SceneTree, master_id: String) -> Node3D:
	for node: Node in runner.root.find_children("*", "Node3D", true, false):
		if node.get_script() == preload("res://scripts/masters/master_site.gd") and node.get("master_id") == master_id and node.get("_mounted") == true:
			return node as Node3D
	return null


## Where the Master and its chest stand in this process (once mounted).
static func _site_view(runner: SceneTree, master_id: String) -> Dictionary:
	var site := _site(runner, master_id)
	if site == null: return _fail("%s is not mounted here" % master_id)
	var npc := site.get_node(^"Master") as Node3D
	var chest := site.get_node(^"RecipeChest") as Node3D
	return _ok("%s mounted" % master_id, {"master": [npc.global_position.x, npc.global_position.y, npc.global_position.z],
		"chest": [chest.global_position.x, chest.global_position.y, chest.global_position.z]})


static func _uid(runner: SceneTree, species: String) -> String:
	var party: RefCounted = runner.root.get_node(^"Game").get("party")
	for member: RefCounted in party.call("members"):
		if str(member.get("species_id")) == species: return str(member.get("uid"))
	return ""


## Choose the owned creature of `species` and challenge through the service.
static func _challenge(runner: SceneTree, args: Dictionary) -> Dictionary:
	var master_id := str(args.get("master_id", ""))
	var service := _service(runner)
	var site := _site(runner, master_id)
	var uid := _uid(runner, str(args.get("species", "")))
	if service == null or site == null or uid.is_empty(): return _fail("needs the service, a mounted %s and an owned %s" % [master_id, str(args.get("species", ""))])
	var session: Node = runner.root.get_node(^"Game/Session")
	var answers: Array = []
	var record := func(envelope: Dictionary, result: Dictionary) -> void:
		if envelope.get("op") == "master_duel": answers.append(result)
	session.connect("foundation_reply_received", record)
	# The site's own prompt opens the shipping chooser; picking a creature is
	# that chooser's button handler (the same call the controller makes).
	service.call("_challenge", site)
	var panel: Node = service.get("_panel")
	if panel == null or panel.call("is_open") != true:
		session.disconnect("foundation_reply_received", record)
		return _fail("the Master chooser did not open")
	panel.call("_duel", uid)
	var manager: Node = null
	var retried := false
	for f in 900:
		await runner.physics_frame
		manager = runner.call("_combat_manager")
		if manager != null and manager.call("is_fighting") == true: break
		# A player whose challenge was refused presses the creature again; one
		# retry, after the redeployed companion has had time to reach the host.
		if not retried and not answers.is_empty() and answers.back().get("ok") == false and f > 30:
			retried = true
			for w in 180: await runner.physics_frame
			panel = service.get("_panel")
			if panel == null or panel.call("is_open") != true:
				service.call("_challenge", site)
				panel = service.get("_panel")
			panel.call("_duel", uid)
	session.disconnect("foundation_reply_received", record)
	var fighting: bool = manager != null and manager.call("is_fighting") == true
	var message := str(panel.get("_message").get("text")) if panel != null and panel.get("_message") != null else ""
	return _ok("challenged %s with %s (fighting %s)" % [master_id, uid, str(fighting)], {"answers": answers, "fighting": fighting, "uid": uid, "retried": retried}) \
		if fighting else _fail("the duel never started: panel says '%s'; answers %s" % [message, str(answers)])


## Wait until no fight is running on this peer (a loss or a win settled).
static func _await_fight_end(runner: SceneTree, budget: int) -> Dictionary:
	for f in budget:
		await runner.physics_frame
		var manager: Node = runner.call("_combat_manager")
		if manager == null or manager.call("is_fighting") != true: return _ok("fight ended after %d frames" % f)
	return _fail("fight still running after %d frames" % budget)


## Open the chest through the service; wait for the host's answer.
static func _chest(runner: SceneTree, args: Dictionary) -> Dictionary:
	var master_id := str(args.get("master_id", ""))
	var service := _service(runner)
	var site := _site(runner, master_id)
	if service == null or site == null: return _fail("needs the service and a mounted %s" % master_id)
	var session: Node = runner.root.get_node(^"Game/Session")
	var answers: Array = []
	var record := func(envelope: Dictionary, result: Dictionary) -> void:
		if envelope.get("op") == "master_chest": answers.append(result)
	var completed: Array = []
	var done := func(action: String, _intent: Dictionary, result: Dictionary) -> void:
		if action == "master_chest": completed.append(result)
	session.connect("foundation_reply_received", record)
	session.connect("homestead_action_completed", done)
	var first: Dictionary = service.call("submit", "master_chest", {"master_id": master_id}, site)
	for f in int(args.get("budget_frames", 900)):
		await runner.physics_frame
		if session.call("is_host") == true and f > 120: break
		if not completed.is_empty() or (not answers.is_empty() and answers.back().get("resolved") == true): break
	session.disconnect("foundation_reply_received", record)
	session.disconnect("homestead_action_completed", done)
	return _ok("chest submitted", {"first": first, "answers": answers, "completed": completed})


## A character's Master progress: local owner record, or (host, with
## character_id) the host's admitted authority record.
static func _view(runner: SceneTree, character_id: String, master_id: String) -> Dictionary:
	var game := runner.root.get_node(^"Game")
	var record: Dictionary
	if character_id.is_empty():
		record = preload("res://scripts/net/character_record_rules.gd").portable_projection(game.get("local").call("save_data"))
		character_id = str(game.get("local").get("character_id"))
	else:
		if game.call("is_host") != true: return _fail("host view requires the host")
		record = game.get("session").get("_character_authority").call("state", character_id)
	var personal: Dictionary = record.get("redesign_character", {})
	var candy: int = preload("res://scripts/world/death_satchel_rules.gd").inventory_from(record.get("inventory", [])).count("tether_candy")
	var feast := str(BREAKTHROUGH.master(master_id).get("feast_id", ""))
	return _ok("%s master progress" % character_id, {"character_id": character_id,
		"master_wins": (personal.get("master_wins", []) as Array).duplicate(),
		"feast_recipes": (personal.get("feast_recipes", []) as Array).duplicate(),
		"has_feast": (personal.get("feast_recipes", []) as Array).count(feast),
		"recipe_receipts": (personal.get("transaction_receipts", []) as Array).filter(func(r: Variant) -> bool: return str(r).begins_with("master_recipe:")),
		"candy": candy,
		"party": (record.get("party", []) as Array).map(func(m: Variant) -> Dictionary: return {"uid": str(m.get("uid", "")),
			"battles_fought": int(m.get("battles_fought", 0)), "xp": int(m.get("xp", 0)), "level": int(m.get("level", 0))} if m is Dictionary else {})})


## Stand the trainer on the ground at [x, z] (a disclosed fixture position).
static func _stand(runner: SceneTree, args: Dictionary) -> Dictionary:
	var at: Array = args.get("at", [])
	var scene := runner.current_scene
	if at.size() != 2 or scene == null or not scene.has_method("ground_height_at"): return _fail("f28_stand needs args.at = [x, z] in a world")
	var y := float(scene.call("ground_height_at", float(at[0]), float(at[1])))
	if not is_finite(y): return _fail("no ground at %s" % str(at))
	return await runner.call("_step_teleport", {"at": [float(at[0]), y + 1.0, float(at[1])], "settle": int(args.get("settle", 60))})


## Diagnostics only (host): each retained guest Master duel and why its win
## is or is not yet a canonical retained win.
static func _host_duels(runner: SceneTree) -> Dictionary:
	var out: Array = []
	var director: Node = runner.call("_encounter_director")
	if director == null: return _fail("no director")
	var duels: Dictionary = director.get("_guest_master_duels")
	for id: String in duels:
		var duel: Dictionary = duels[id]
		var runtime: Node = director.call("_shared_host_fight", id)
		var opponent: Node3D = runtime.call("body") if runtime != null else null
		var creature: RefCounted = opponent.get("instance") if is_instance_valid(opponent) else null
		var witness: Dictionary = duel.get("terminal_witness", {})
		out.append({"id": id, "won": duel.get("won"), "durable": duel.get("durable"), "dispose": duel.get("dispose_requested"),
			"runtime": runtime != null, "terminal": str(runtime.get("terminal_outcome")) if runtime != null else "",
			"witness_binding_ok": witness.get("binding") == duel.get("binding"), "witness_killed": witness.get("verdict", {}).get("delta", {}).get("killed"),
			"witness_hp": witness.get("verdict", {}).get("delta", {}).get("hp"), "creature_hp": creature.get("hp") if creature != null else null,
			"retained": not (director.call("retained_guest_master_win", id) as Dictionary).is_empty(),
			"outcome": director.get("_session").call("foundation_guest_master_outcome", director, director.call("retained_guest_master_win", id)) if false else {}})
	return _ok("%d guest duel(s)" % out.size(), {"duels": out})


## F28#3 disclosed fixture, on the owner's own home BEFORE networking (as
## party_grant): the tier-1 recipe as a Master chest would teach it, and the
## named ingredients as gathered stock. Nothing here cooks, feeds or saves.
static func _feast_seed(runner: SceneTree, args: Dictionary) -> Dictionary:
	var game := runner.root.get_node(^"Game")
	if game.get("session").call("is_active") == true:
		return _fail("seed the owner's own home before any session")
	var local: RefCounted = game.get("local")
	var personal: Dictionary = (local.get("redesign_character") as Dictionary).duplicate(true)
	var recipes: Array = personal.get("feast_recipes", [])
	for feast: Variant in args.get("recipes", []):
		if not recipes.has(str(feast)): recipes.append(str(feast))
	personal.feast_recipes = recipes
	local.set("redesign_character", personal)
	var items: Dictionary = args.get("items", {})
	for id: String in items:
		if int(game.get("inventory").call("add", id, int(items[id]))) != 0: return _fail("no satchel room for %s" % id)
	return _ok("recipes %s and items %s seeded" % [str(recipes), str(items)])


## F28#3: one press of the actual Ascension Feast panel. "cook" opens the
## Kitchen's feast list (the craft panel's Feasts button calls this same
## open_kitchen) and presses the recipe button; "feed" opens its Feed list and
## presses the button for the creature of args.species. The panel submits the
## ordinary typed foundation action; this waits for its saved or refused end.
static func _feast_press(runner: SceneTree, args: Dictionary, mode: String) -> Dictionary:
	var service := _service(runner)
	if service == null: return _fail("no BreakthroughService")
	var kitchen: Node3D = null
	for f in 600:
		kitchen = runner.call("_station_node", str(args.get("kitchen_uid", "")))
		if kitchen != null: break
		await runner.physics_frame
	if kitchen == null: return _fail("the host's Kitchen never replicated here")
	# The smoke walks the trainer here (f28_station_at + move_to): a fixture
	# teleport is a discontinuity the owner-passive stream holds on.
	var player := runner.current_scene.get_node(^"Player") as Node3D
	if player.global_position.distance_to(kitchen.global_position) > 3.5:
		return _fail("walk to the Kitchen first (%.1f m away)" % player.global_position.distance_to(kitchen.global_position))
	# The panel opens only once no saved decision holds this owner's input
	# (Session.owns_input); a player waits for that too.
	var session_node: Node = runner.root.get_node(^"Game/Session")
	for f in int(args.get("settle_frames", 1200)):
		if session_node.call("owns_input") != true: break
		await runner.physics_frame
	service.call("open_kitchen", kitchen)
	await runner.process_frame
	var panel: Node = service.get("_panel")
	if panel == null or panel.call("is_open") != true:
		var owner: Variant = preload("res://scripts/ui/input_owner.gd").current(runner)
		var why := str(session_node.call("_owner_snapshot_block_reason", runner.root.get_node(^"Game").get("local"))) if owner == session_node else ""
		return _fail("the Kitchen feast panel did not open (input owned by %s %s)" % [str(owner.name) if owner is Node else "nobody", why])
	if mode == "feed":
		panel.call("_open_feed_from_kitchen")
		await runner.process_frame
	var want := str(args.get("button", ""))
	var target: Button = null
	var labels: Array = []
	for node: Node in panel.get("_list").get_children():
		if not node is Button: continue
		labels.append((node as Button).text)
		if target == null and not (node as Button).disabled and (node as Button).text.begins_with(want): target = node
	if target == null:
		panel.call("close")
		return _ok("no enabled button starts with '%s'" % want, {"pressed": false, "labels": labels})
	var session: Node = runner.root.get_node(^"Game/Session")
	var op := "feast_cook" if mode == "cook" else "feast_feed"
	var completed: Array = []
	var done := func(action: String, _intent: Dictionary, result: Dictionary) -> void:
		if action == op: completed.append(result)
	session.connect("homestead_action_completed", done)
	target.emit_signal("pressed")
	for f in int(args.get("budget_frames", 1800)):
		await runner.physics_frame
		if str(panel.get("_pending_action")).is_empty(): break
	session.disconnect("homestead_action_completed", done)
	var message := str(panel.get("_message").text) if is_instance_valid(panel.get("_message")) else ""
	var pending := str(panel.get("_pending_action"))
	if panel.call("is_open") == true: panel.call("close")
	return _ok("pressed '%s'" % target.text, {"pressed": true, "labels": labels, "message": message,
		"still_pending": pending, "completed": completed})


## Feast-relevant state: the owner's own record, or (host, character_id) the
## host's admitted record of that character.
static func _feast_view(runner: SceneTree, character_id: String) -> Dictionary:
	var game := runner.root.get_node(^"Game")
	var record: Dictionary
	if character_id.is_empty():
		record = preload("res://scripts/net/character_record_rules.gd").portable_projection(game.get("local").call("save_data"))
		character_id = str(game.get("local").get("character_id"))
	else:
		if game.call("is_host") != true: return _fail("host view requires the host")
		record = game.get("session").get("_character_authority").call("state", character_id)
	var personal: Dictionary = record.get("redesign_character", {})
	var stock := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(record.get("inventory", []))
	var items := {}
	for id: String in ["berries", "rootstone", "attuned_ground", "feast_t1_ground"]: items[id] = stock.count(id)
	var party := {}
	for member: Variant in record.get("party", []):
		if not member is Dictionary: continue
		var mirror: Dictionary = personal.get("creatures", {}).get(str(member.get("uid", "")), {})
		party[str(member.get("species_id", ""))] = {"uid": str(member.get("uid", "")), "level": int(member.get("level", 0)),
			"xp": int(member.get("xp", 0)), "cap_level": int(mirror.get("cap_level", -1)),
			"breakthroughs": (mirror.get("breakthroughs", []) as Array).duplicate()}
	return _ok("%s feast state" % character_id, {"character_id": character_id, "items": items, "party": party,
		"feast_recipes": (personal.get("feast_recipes", []) as Array).duplicate(),
		"receipts": (personal.get("transaction_receipts", []) as Array).filter(func(r: Variant) -> bool:
			return str(r).begins_with("craft:") or str(r).begins_with("feast_feed:"))})


## Where a placed station stands in this process (once replicated).
static func _station_at(runner: SceneTree, uid: String) -> Dictionary:
	for f in 600:
		var node: Node3D = runner.call("_station_node", uid)
		if node != null: return _ok("station %s" % uid, {"at": [node.global_position.x, node.global_position.y, node.global_position.z]})
		await runner.physics_frame
	return _fail("station %s never replicated here" % uid)
