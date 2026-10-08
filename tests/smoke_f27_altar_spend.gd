extends "res://tests/smoke_combat.gd"

## F27#3 actual-path witness: a paid Altar placed through the host build
## placer's own `_place` transaction, reached on foot, opened with the real
## `interact` action, and paid with controller navigation (ui_* actions) on
## the shipping Altar panel. The level, the essence debit, the receipt and the
## accepted saved training row all come from Session's typed transaction.
##
##   godot --headless --path . --script tests/smoke_f27_altar_spend.gd
##
## Disclosed fixtures, none of which is the transaction under test:
##   - the starter is owned the way the opening owns it (party.add);
##   - Altar materials and Water Essence are granted to the inventory before
##     any transaction starts (no earned-route claim);
##   - the build ghost is positioned on the first valid home-plot pose found
##     by the placer's own preview_placement instead of being steered there.
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const WORLD := preload("res://autoload/world_state.gd")
const ESSENCE_GRANT := 120
const BUDGET_FRAMES := 900
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

var _game: Node = null


func _run() -> void:
	var masters_witness := OS.get_cmdline_user_args().has("--lesson-masters-witness")
	if masters_witness and (not OS.get_cmdline_user_args().has("--lesson-controller-witness") \
			or not OS.get_cmdline_user_args().has("--lesson-replay-witness")):
		_fail("Masters witness requires the existing controller and Help replay options")
		_report()
		return
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	await _ensure_ally()
	_game = root.get_node(^"Game")
	var party: RefCounted = _game.get("party")
	var director := _world.get_node(^"EncounterDirector")
	if party.size() == 0: party.call("add", director.call("ally_instance"))
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	var inventory: RefCounted = _game.get("inventory")
	for need: Dictionary in WORLD.altar_recipe(): inventory.call("add", str(need.id), int(need.n))
	inventory.call("add", "essence_water", ESSENCE_GRANT)
	if OS.get_cmdline_user_args().has("--lesson-controller-witness") and not masters_witness:
		if not await _witness_altar_lesson():
			_report()
			return
	for i in 30: await physics_frame

	var altar := await _place_paid_altar()
	if altar == null:
		_report()
		return
	await _dismiss_modals()
	var creature: RefCounted = party.call("at", 0)
	var level_before := int(creature.level)
	var cost := ESSENCE.level_cost(level_before, ESSENCE.config(), PROGRESSION.config())
	var water_before := int(inventory.call("count", "essence_water"))
	var local: RefCounted = _game.get("local")
	var receipts_before: int = local.redesign_character.transaction_receipts.size()
	print("before spend: %s L%d, water essence %d, cost %d" % [creature.species_id, level_before, water_before, cost])

	# Approach on foot from whichever side of the yard is open (the plot sits
	# against the farmhouse). Each start is a disclosed reposition; the last
	# metres are walked with move_forward.
	var key := "altar:meadows:" + str(altar.get_meta("building_uid", ""))
	var session: Node = _game.get("session")
	for side: Vector3 in [Vector3(0, 0, 4), Vector3(0, 0, -4), Vector3(-4, 0, 0), Vector3(4, 0, 0)]:
		var start := altar.global_position + side
		start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
		_player.global_position = start
		_player.velocity = Vector3.ZERO
		for i in 20: await physics_frame
		await _dismiss_modals()
		await _walk_to(altar.global_position, 1.0)
		if session.call("altar_station_available", key) == true: break
	var panel := await _open_altar()
	if panel == null:
		_report()
		return
	if not await _pay_with("Water Essence", panel):
		_report()
		return
	var settled := false
	for i in BUDGET_FRAMES:
		await physics_frame
		if int(creature.level) == level_before + 1 and _accepted_training_row(local):
			settled = true
			break
	print("panel status '%s', pending '%s', message '%s'" % [str(panel.get("_status")), str(panel.get("_pending_id")),
		str(_game.call("take_pending_world_message"))])
	var water_after := int(inventory.call("count", "essence_water"))
	var new_receipts: Array = local.redesign_character.transaction_receipts.slice(receipts_before)
	print("after spend: L%d, water essence %d, new receipts %s" % [int(creature.level), water_after, str(new_receipts)])
	if not settled: _fail("the Altar spend never reached an accepted saved training row with the new level")
	if int(creature.level) != level_before + 1: _fail("level %d -> %d, expected exactly +1" % [level_before, int(creature.level)])
	if water_before - water_after != cost: _fail("debited %d Water Essence, expected %d" % [water_before - water_after, cost])
	var spends := new_receipts.filter(func(r: String) -> bool: return r.begins_with("essence_spend:"))
	if spends.size() != 1: _fail("expected one essence_spend receipt, saw %s" % str(new_receipts))
	# The same panel must not let a second press mint a second level from one quote.
	if _failures.is_empty():
		print("F27_ALTAR_SPEND: PASS controller-path Altar level-up L%d->L%d for %d Water Essence" % [level_before, level_before + 1, cost])
		if masters_witness: await _witness_masters_lesson(creature, panel)
	_report()


## Continue the original paid panel to its first cap using only the fixture's
## remaining essence. No extra stock, levels, teacher poses or lesson receipts.
## The default one-spend proof and the separate Altar witness stay unchanged.
func _witness_masters_lesson(creature: RefCounted, panel: Node) -> bool:
	var rules := preload("res://scripts/onboarding/lesson_rules.gd")
	var local: RefCounted = _game.local
	var uid := str(creature.uid)
	var cid := str(local.character_id)
	var retained: Array = _game.party.members().duplicate()
	var mirror: Dictionary = local.redesign_character.creatures.get(uid, {})
	var cap := preload("res://scripts/creatures/breakthrough.gd").level_cap(mirror.get("breakthroughs", []))
	if cap != 10 or int(creature.level) >= cap or rules.available("masters", local) \
			or local.flags.call("has", rules.PREFIX + "masters"):
		_fail("Masters witness must start below its first unacknowledged real L10 cap")
		return false
	for before: int in range(int(creature.level), cap):
		var cost := ESSENCE.level_cost(before, ESSENCE.config(), PROGRESSION.config())
		var stock := int(_game.inventory.count("essence_water"))
		var receipts_before: int = local.redesign_character.transaction_receipts.size()
		if cost < 1 or stock < cost or not await _pay_with("Water Essence", panel):
			_fail("The unchanged essence fixture cannot pay the next actual Master-unlock level")
			return false
		for frame: int in BUDGET_FRAMES:
			if int(creature.level) == before + 1 and _accepted_training_row(local): break
			await physics_frame
		var receipts: Array = local.redesign_character.transaction_receipts.slice(receipts_before)
		if int(creature.level) != before + 1 or not _accepted_training_row(local) \
				or stock - int(_game.inventory.count("essence_water")) != cost \
				or receipts.filter(func(r: String) -> bool: return r.begins_with("essence_spend:")).size() != 1 \
				or str(local.character_id) != cid or str(creature.uid) != uid or _game.party.members() != retained:
			_fail("Master unlock did not retain one paid saved level, exact debit, character and owned party")
			return false
		print("F46 MASTERS PAID UNLOCK " + JSON.stringify({"character_id":cid,"uid":uid,
			"from_level":before,"to_level":int(creature.level),"cost":cost,"receipts":receipts}))
	var reader: RefCounted = preload("res://tests/helpers/f20_portal_travel.gd").new(self, _game)
	reader.set("_lesson_controller_input", true)
	await reader.tap("menu_cancel")
	reader.set("_lesson_controller_input", false)
	var teacher := _world.find_child("Tam", true, false) as Node3D
	if teacher == null or panel.call("is_open") or INPUT_OWNER.current(self) != null \
			or not rules.available("masters", local):
		_fail("The real first cap did not unlock Masters with free input and installed Tam")
		return false
	var nav := preload("res://tests/helpers/stick_navigator.gd").new(self, _player, _rig, Callable(reader, "_stick"))
	var recoveries_before := int(_player.get("_unstick_count"))
	var approach := func() -> bool:
		var arrived: bool = await nav.walk_to(teacher.global_position, 2400, 3.5)
		reader.call("_stick", 0.0, 0.0)
		for frame: int in 180:
			if local.flags.call("has", rules.PREFIX + "masters"): break
			await physics_frame
		return arrived and _player.is_on_floor() and int(_player.get("_unstick_count")) == recoveries_before \
			and _player.global_position.distance_to(teacher.global_position) <= 5.0
	var passed: bool = await reader._with_navigation_lessons(approach)
	if passed and reader.get("_lesson_replay_row").get("id", "") == "masters":
		passed = await reader.replay_observed_lesson()
	else:
		passed = false
	for failure: String in reader.failures: _fail(failure)
	if not passed or not local.flags.call("has", rules.PREFIX + "masters") \
			or INPUT_OWNER.current(self) != null or str(local.character_id) != cid or _game.party.members() != retained:
		_fail("Naturally unlocked Tam Masters lesson lacks controller Skip, Help replay or retained identity")
		return false
	print("F46 MASTERS LESSON: PASS actual paid first cap, grounded Tam walk, mapped Skip and Settings Help; original essence fixture disclosed; disk reload/whole F46 open")
	return true


## Optional F46 witness reuses the original essence fixture and actual
## Grandpa lesson. The existing reader supplies physical Skip/Help input and
## completed-frame captures; no lesson flag, teacher pose or reward is staged.
func _witness_altar_lesson() -> bool:
	var options := preload("res://tests/helpers/f20_portal_travel.gd").lesson_witness_options()
	if not options.failures.is_empty():
		for failure: String in options.failures: _fail(failure)
		return false
	var rules := preload("res://scripts/onboarding/lesson_rules.gd")
	if not rules.available("altar", _game.local) or _game.local.flags.call("has", rules.PREFIX + "altar"):
		_fail("Altar witness requires the original essence fixture's first unacknowledged lesson")
		return false
	var panel: Node = null
	for frame: int in 180:
		var service := _game.get_node_or_null("OnboardingLessons")
		panel = service.get("_panel") if service != null else null
		if panel != null and panel.call("is_open"): break
		await physics_frame
	if panel == null or not panel.call("is_open") or panel.get("_row").get("id") != "altar":
		_fail("First essence pickup did not naturally open Grandpa's authored Altar lesson")
		return false
	var reader: RefCounted = preload("res://tests/helpers/f20_portal_travel.gd").new(self, _game)
	var passed: bool = await reader._with_navigation_lessons(func() -> bool: return true)
	if passed and options.replay: passed = await reader.replay_observed_lesson()
	for failure: String in reader.failures: _fail(failure)
	if not passed or panel.call("owns_input") or not _game.local.flags.call("has", rules.PREFIX + "altar"):
		_fail("Altar lesson did not retain its personal acknowledgement and release input")
		return false
	print("F46 ALTAR LESSON: PASS actual Altar lesson from disclosed essence fixture; mapped Skip; Help replay=%s; disk reload/whole F46 open" % str(options.replay))
	return true


func _place_paid_altar() -> Node3D:
	var placer: Node = null
	for node: Node in get_nodes_in_group("build_placer"):
		if _world.is_ancestor_of(node): placer = node
	if placer == null:
		_fail("no build placer in the shipping scene")
		return null
	var cfg: Dictionary = placer.call("_altar_config", _game)
	if cfg.is_empty():
		_fail("Altar config/recipe unavailable")
		return null
	var plot: Dictionary = cfg.homestead_plot
	var centre := Vector2(float(plot.centre[0]), float(plot.centre[1]))
	var half := Vector2(float(plot.size_m[0]), float(plot.size_m[1])) * 0.5
	var pose := Vector3.INF
	var x := centre.x - half.x
	while x <= centre.x + half.x and pose == Vector3.INF:
		var z := centre.y - half.y
		while z <= centre.y + half.y:
			var at := Vector3(x, float(_world.call("ground_height_at", x, z)), z)
			var preview: Dictionary = placer.call("preview_placement", _game, "altar", at)
			if preview.get("ok") == true and preview.get("position") is Vector3:
				pose = preview.position
				break
			z += 1.0
		x += 1.0
	if pose == Vector3.INF:
		_fail("no valid Altar pose on the home plot")
		return null
	# Disclosed, as smoke_combat's _leave_the_farmhouse: the opening wakes the
	# trainer indoors; stand them in the yard beside the chosen pose.
	var stand := pose + Vector3(3.0, 0.0, 0.0)
	stand.y = float(_world.call("ground_height_at", stand.x, stand.z)) + 1.0
	_player.global_position = stand
	_player.velocity = Vector3.ZERO
	for i in 30: await physics_frame
	placer.call("_show_ghost", _game, "altar")
	var ghost: Node3D = placer.get("_ghost")
	ghost.global_position = pose
	placer.set("_yaw_deg", 0.0)
	print("altar pose %s; placement available %s" % [str(pose), str(placer.call("_altar_placement_available", _game))])
	placer.call("_place", _game, "altar")
	for i in 5: await physics_frame
	var message := str(_game.call("take_pending_world_message"))
	if not message.is_empty(): print("placer said: %s" % message)
	for i in BUDGET_FRAMES:
		await physics_frame
		for node: Node in get_nodes_in_group("placed_building"):
			if node.get_meta("building_id", "") == "altar" and node.get_node_or_null(^"AltarInteraction") != null:
				placer.call("_drop_ghost") if placer.has_method("_drop_ghost") else null
				print("paid Altar placed at %s as %s" % [str(pose), str(node.get_meta("building_uid", ""))])
				return node as Node3D
	var rows: Array = _game.get("world").placed_buildings
	print("placed_buildings tail: %s" % str(rows.slice(maxi(0, rows.size() - 2))).left(500))
	_fail("the paid Altar transaction never mounted an Altar interaction")
	return null


## Placing the first Altar opens an onboarding lesson that owns input, as it
## does for a player; continue it with the confirm button.
func _dismiss_modals() -> void:
	for attempt in 40:
		var owner: Variant = INPUT_OWNER.current(self)
		if owner == null: return
		if attempt == 0: print("dismissing modal %s" % str((owner as Node).get_path()))
		await _ui("ui_accept")
		for i in 10: await physics_frame
	_fail("a modal still owns input after 40 confirm presses: %s" % str(INPUT_OWNER.current(self)))


func _walk_to(target: Vector3, within: float) -> void:
	for i in 2400:
		var to := target - _player.global_position
		to.y = 0.0
		if to.length() <= within: break
		_aim_camera_along(to)
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 20: await physics_frame
	var owner: Variant = INPUT_OWNER.current(self)
	print("walked to %.2fm of the target; input owner %s" % [_player.global_position.distance_to(target),
		str(owner.get_path()) if owner is Node else str(owner)])


func _open_altar() -> Node:
	for attempt in 3:
		await _press("interact")
		for i in 60: await physics_frame
		var service := _game.get_node_or_null(^"AltarService")
		var panel: Node = service.get("_panel") if service != null else null
		if panel != null and bool(panel.call("is_open")):
			return panel
	var placed: Array = get_nodes_in_group("placed_building").filter(func(n: Node) -> bool: return n.get_meta("building_id", "") == "altar")
	if not placed.is_empty():
		var prompt: Node3D = placed[0].get_node_or_null(^"AltarInteraction/TrainingInteractable")
		var session: Node = _game.get("session")
		var key := "altar:meadows:" + str(placed[0].get_meta("building_uid", ""))
		print("diag: prompt enabled %s, offer %s, dist %.2f, producer %s, station %s, realm %s" % [
			str(prompt.get("enabled")), str(prompt.call("interaction_offer", _player.global_position)),
			_player.global_position.distance_to(prompt.global_position),
			str(session.call("altar_canonical_producer_available")), str(session.call("altar_station_available", key)),
			str(_game.get("current_realm"))])
		var ctx: Dictionary = session.get_node(^"LedgerRpc").call("_water_actor_context", 1, {})
		print("diag: player->altar origin %.2f (flat %.2f); context position %s realm %s" % [
			_player.global_position.distance_to(placed[0].global_position),
			Vector2(_player.global_position.x - placed[0].global_position.x, _player.global_position.z - placed[0].global_position.z).length(),
			str(ctx.get("position")), str(ctx.get("realm"))])
	_fail("interact near the paid Altar did not open the Altar panel")
	return null


func _pay_with(label: String, panel: Node) -> bool:
	for i in 240:
		await physics_frame
		var focused := panel.get_viewport().gui_get_focus_owner() if panel.get_viewport() != null else null
		if focused is Button and (focused as Button).text.begins_with(label) and not (focused as Button).disabled:
			print("focused payment: %s" % (focused as Button).text)
			await _ui("ui_accept")
			return true
		if _payment_button(panel, label) != null and i % 6 == 0:
			await _ui("ui_down" if (i / 6) % 4 != 3 else "ui_right")
	_fail("controller navigation never focused an enabled '%s' payment" % label)
	return false


func _payment_button(node: Node, label: String) -> Button:
	if node is Button and (node as Button).is_visible_in_tree() and (node as Button).text.begins_with(label):
		return node
	for child: Node in node.get_children():
		var found := _payment_button(child, label)
		if found != null: return found
	return null


func _ui(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await physics_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4: await physics_frame


func _accepted_training_row(local: RefCounted) -> bool:
	var world: RefCounted = _game.get("world")
	var id := ESSENCE.training_delivery_id(world.reward_delivery_namespace, str(local.character_id))
	var row: Variant = world.reward_deliveries.get(id)
	return row is Dictionary and row.get("status") == "accepted" and row.get("action") == "altar_spend"
