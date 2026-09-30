extends SceneTree

## Bounded F23/F25 player-path witness, not an earned-creature/campaign proof.
## Initial fixture: one existing primary-fire Cindercub; teleport to the real
## authored pickup, then back to the practice approach. No item grants, damage,
## teaching, equipment or accepted-impact callbacks are injected by this driver.
## After two contact-witness failures, use actual zero-duration target-body
## geometry/fresh flash instead of projectile callbacks or the HUD-number anchor.
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const FLASH := preload("res://scripts/combat/impact_flash.gd")
const FEEDBACK := preload("res://scripts/combat/hit_feedback.gd")
const PICKUP_ID := "b5_tm_fireball_scorched_pocket"
var _world: Node
var _game: Node
var _player: CharacterBody3D
var _director: Node
var _manager: Node
var _rig: Node3D
var _learner: RefCounted
var _failures: Array[String] = []
var _launches: Dictionary = {}
var _accepted_fireball := false
var _incoming := 0

func _init() -> void:
	_run()

func _run() -> void:
	await process_frame
	create_timer(900.0).timeout.connect(func() -> void: _fail("bounded Fireball witness exceeded900s"); _finish())
	print("SCOPE: isolated fresh world; direct one-Cindercub roster fixture; pickup/practice teleports; physical InputMap taps; no inventory grants; no earned-campaign claim")
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in 240: await physics_frame
	_game = root.get_node_or_null("Game")
	_player = _world.get_node_or_null("Player") as CharacterBody3D
	_director = _world.get_node_or_null("EncounterDirector")
	_manager = _world.get_node_or_null("CombatManager")
	_rig = _world.get_node_or_null("CameraRig") as Node3D
	if _game == null or _player == null or _director == null or _manager == null or _rig == null:
		_fail("production world did not create its required components")
		_finish()
		return
	var party: RefCounted = _game.get("party")
	if int(party.call("size")) != 0:
		_fail("fresh fixture unexpectedly contains a creature; never add a hidden sixth")
		_finish()
		return
	_learner = SPECIES.spawn("cindercub")
	if _learner == null or not bool(party.call("add", _learner)):
		_fail("could not establish disclosed primary-fire learner fixture")
		_finish()
		return
	var original_quick := str(_learner.get("move_quick"))
	var inventory: RefCounted = _game.get("inventory")
	if int(inventory.call("count", "tm_fireball")) != 0:
		_fail("fresh world already owns Fireball; pickup transaction would be unproved")
		_finish()
		return
	var pickup: Node3D = null
	for node: Node in get_nodes_in_group("progression_restore"):
		if node.get_script() == CACHE and str(node.get("_placement_id")) == PICKUP_ID:
			pickup = node as Node3D
			break
	if pickup == null:
		_fail("authored Fireball pickup was never instantiated by production band loader")
		_finish()
		return
	var prompt := pickup.get_node_or_null("Interactable")
	_teleport(pickup.global_position + Vector3(1.5, 0, 0))
	for i in 12: await physics_frame
	if prompt == null or (prompt.call("interaction_offer", _player.global_position) as Dictionary).is_empty():
		_fail("real authored pickup has no reachable unobstructed offer")
		_finish()
		return
	await _tap_action("interact")
	for i in 12: await physics_frame
	var progression: RefCounted = _game.get("progression")
	if int(inventory.call("count", "tm_fireball")) != 1 or not bool(progression.call("has", "cache:" + PICKUP_ID)):
		_fail("physical pickup did not commit one disc and its exact shared placement flag")
		_finish()
		return
	print("PICKUP: physical interaction committed authored %s, disc=1, exact cache flag=true" % PICKUP_ID)
	await _tap_action("inventory")
	var menu: Node = _game.call("menu")
	if menu == null or not bool(menu.call("is_open")):
		_fail("physical inventory button did not open production Satchel")
		_finish()
		return
	var tabs: Array = menu.get("_tabs")
	var tab: Node = null
	for index: int in tabs.size():
		if str((tabs[index] as Dictionary).get("id", "")) == "backpack":
			tab = menu.get("_bodies")[index]
			if int(menu.get("_index")) != index: _fail("inventory shortcut did not select Satchel")
			break
	if tab == null:
		_fail("production Satchel tab missing")
		_finish()
		return
	var slot := -1
	for index: int in int(inventory.call("slot_count")):
		if str((inventory.call("stack_at", index) as Dictionary).get("id", "")) == "tm_fireball": slot = index
	# Navigate native focus from the actual first slot; never call _read_use or
	# _on_target_row. Fresh inventory puts this single authored find in a slot.
	var buttons: Array = tab.get("_buttons")
	if slot < 0 or slot >= buttons.size():
		_fail("claimed Fireball stack has no actual Satchel slot")
		_finish()
		return
	for i in buttons.size() + 1:
		if root.gui_get_focus_owner() == buttons[slot]: break
		await _tap_button(JOY_BUTTON_DPAD_RIGHT)
	if slot < 0 or int(tab.get("_focused")) != slot or root.gui_get_focus_owner() != buttons[slot]:
		_fail("native Satchel focus could not reach actual Fireball stack")
		_finish()
		return
	await _tap_action("interact")
	if str(tab.get("_targeting_tm")) != "tm_fireball":
		_fail("physical Use did not open real TM learner picker")
		_finish()
		return
	var rows: Array = tab.get("_target_rows")
	if rows.is_empty() or root.gui_get_focus_owner() != rows[0] or (rows[0] as Button).disabled:
		_fail("primary-fire learner is not the eligible native picker focus")
		_finish()
		return
	await _tap_button(JOY_BUTTON_A)
	if str(_learner.get("move_charged")) != "fireball" or str(_learner.get("move_quick")) != original_quick or int(inventory.call("count", "tm_fireball")) != 0:
		_fail("real backpack teaching did not consume exactly the claimed disc and preserve quick move")
		_finish()
		return
	print("TEACH: actual eligible picker confirmation consumed disc once; Cindercub charged=fireball; quick unchanged")
	await _tap_action("menu_cancel")
	if bool(menu.call("is_open")):
		_fail("native cancel did not close Satchel after teaching")
		_finish()
		return
	_teleport(Vector3(48, 0, -58))
	if not bool(await _director.call("summon_active_creature")):
		_fail("real summon could not deploy taught owned learner")
		_finish()
		return
	for i in 20: await physics_frame
	var wild := _director.call("wild_creature") as Node3D
	if wild == null:
		_fail("production wild encounter missing")
		_finish()
		return
	for i in 1800:
		var direction := wild.global_position - _player.global_position
		direction.y = 0
		if direction.length() < 3.4: break
		_rig.set("yaw", atan2(-direction.x, -direction.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 10: await physics_frame
	await _tap_action("interact")
	for i in 30: await physics_frame
	if not bool(_manager.call("is_fighting")):
		_fail("ordinary engage did not enter a wild fight")
		_finish()
		return
	_manager.connect("attack_launched", _observe_launch)
	_manager.connect("impact_confirmed", _observe_impact)
	var ally := _director.call("ally_body") as Node3D
	for i in 900:
		if _accepted_fireball and _incoming > 0: break
		if not bool(_manager.call("is_fighting")): break
		var direction := wild.global_position - ally.global_position
		direction.y = 0
		_rig.set("yaw", atan2(-direction.x, -direction.z))
		var move_slot := "charged" if bool(_manager.call("charged_ready")) else "quick"
		var reach := float(_manager.call("combat_move_reach", move_slot))
		if direction.length() > reach - 0.15:
			Input.action_press("move_forward")
		else:
			Input.action_release("move_forward")
			if not _accepted_fireball and bool(_manager.call("charged_ready")):
				await _tap_action("combat_charged")
			elif not _accepted_fireball and bool(_manager.call("quick_ready")):
				# Earn the meter through real connecting quick hits, never inject energy.
				await _tap_action("combat_quick")
		await physics_frame
	Input.action_release("move_forward")
	if not _accepted_fireball: _fail("physical charged tap never produced an accepted Fireball with real contact/HP/number")
	if _incoming == 0: _fail("real wild opponent never delivered incoming feedback in the same player-path fixture")
	_finish()

func _teleport(position: Vector3) -> void:
	position.y = float(_world.call("ground_height_at", position.x, position.z)) + 1.0
	_player.global_position = position
	_player.velocity = Vector3.ZERO
	print("FIXTURE teleport xz=(%.2f,%.2f); journey unproved" % [position.x, position.z])

func _observe_launch(outgoing: bool, launch: Dictionary, presentation: Node3D) -> void:
	var target: RefCounted = _manager.call("enemy") if outgoing else _manager.call("active_creature")
	var sample := {"arrived": false, "instant": float(launch.get("travel_seconds", 0.0)) <= 0.0, "hp": float(target.get("hp")), "move_id": str(launch.move_id), "process_frame": Engine.get_process_frames()}
	_launches[str(launch.action_id)] = sample
	if presentation != null:
		presentation.connect("arrived", func() -> void: sample.arrived = true)
	print("LAUNCH %s move=%s outgoing=%s target_hp=%.3f" % [launch.action_id, launch.move_id, outgoing, sample.hp])

func _observe_impact(outgoing: bool, receipt: Dictionary, _where: Vector3) -> void:
	var id := str(receipt.get("action_id", ""))
	if not receipt.is_read_only() or not _launches.has(id):
		_fail("accepted hit lacks immutable host-style launch/receipt")
		return
	var sample: Dictionary = _launches[id]
	if not bool(sample.instant) and not bool(sample.arrived):
		_fail("travelling accepted hit precedes actual informational presentation contact")
	if bool(sample.instant):
		# Zero-duration contact moves deliberately have no projectile-arrived
		# callback. Observe the actual fresh production flash at this contact.
		var arena: Node3D = _manager.call("arena")
		var fresh_flash := false
		var struck: Node3D = _manager.call("enemy_body") if outgoing else _manager.get("_ally_body")
		var contact: Vector3 = struck.call("centre") if is_instance_valid(struck) else Vector3.INF
		if arena != null:
			for node: Node in arena.get_children():
				if node.get_script() == FLASH and is_zero_approx(float(node.get("_life"))) and (node as Node3D).global_position.distance_to(contact) < 0.01:
					fresh_flash = true
		if not fresh_flash: _fail("instant contact did not construct its actual fresh receipt flash")
	var target: RefCounted = _manager.call("enemy") if outgoing else _manager.call("active_creature")
	if target == null or not float(target.get("hp")) < float(sample.hp): _fail("accepted impact did not debit actual target HP")
	var hud := _world.get_node_or_null("CombatHUD")
	var style := FEEDBACK.number_style(receipt, outgoing)
	var number_found := false
	if hud != null:
		for label: Label in hud.get("_damage_numbers"):
			if is_instance_valid(label) and label.text == str(style.text): number_found = true
	if not number_found: _fail("accepted hit did not create its real HUD number")
	if outgoing and str(receipt.get("move_id", "")) == "fireball": _accepted_fireball = true
	if not outgoing: _incoming += 1
	print("IMPACT %s move=%s outgoing=%s contact=%s instant=%s hp_before=%.3f hp_after=%.3f damage=%.3f number=%s crit=%s" % [id, receipt.get("move_id", ""), outgoing, sample.arrived, sample.instant, sample.hp, target.get("hp") if target != null else -1, receipt.damage, number_found, receipt.critical])

func _tap_button(index: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = true
	Input.parse_input_event(event)
	for i in 3: await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	for i in 3: await process_frame

func _tap_action(action: String) -> void:
	for mapped: InputEvent in InputMap.action_get_events(action):
		if mapped is InputEventJoypadButton:
			await _tap_button((mapped as InputEventJoypadButton).button_index)
			return
		if mapped is InputEventJoypadMotion:
			var event := mapped.duplicate() as InputEventJoypadMotion
			event.device = 0
			Input.parse_input_event(event)
			for i in 3: await process_frame
			event = event.duplicate()
			event.axis_value = 0.0
			Input.parse_input_event(event)
			for i in 3: await process_frame
			return
	_fail("required action has no actual gamepad binding: " + action)

func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: " + message)

func _finish() -> void:
	if _game != null:
		var menu: Node = _game.call("menu")
		if menu != null and bool(menu.call("is_open")): menu.call("close")
	if _failures.is_empty(): print("FIREBALL PLAYER PATH PASS: real authored pickup/flag, native Satchel teaching/spend, physical charged cast, actual contact/HP/number; fixture scope retained")
	quit(0 if _failures.is_empty() else 1)
