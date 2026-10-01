extends "res://tests/helpers/cloudreach_live_segment.gd"

## New-order portal arrival; retains the original route, flight and combat guards.
func run(tree: SceneTree, live_world: Node3D, live_game: Node) -> Dictionary:
	_tree = tree
	world = live_world
	game = live_game
	start_usec = Time.get_ticks_usec()
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		_fail("Cloudreach continuation needs the existing tree, world and Game")
		return result()
	if str(game.get("current_realm")) != "cloudreach" or tree.current_scene != world:
		_fail("Cloudreach continuation must receive the production current scene after ordinary travel")
		return result()
	if not str(game.get("pending_realm_entry")).is_empty():
		_fail("Cloudreach arrival has not settled")
		return result()
	if not _has("water_currents_restored") or game.call("portal_view", "cloudreach").get("character_open") != true:
		_fail("F49 Cloudreach requires earned Tidewake restoration and the actual personal Cloudreach portal unlock")
		return result()
	initial_party_ids = _party_ids()
	if initial_party_ids.is_empty() or initial_party_ids.size() > 5:
		_fail("Cloudreach requires an earned party of one to five creatures")
		return result()
	if game.inventory.count("knife") < 1 or int(game.call("hotbar_slot_of", "knife")) < 0:
		_fail("Cloudreach requires the carried knife assigned through ordinary inventory input")
		return result()
	for path: String in ["Player", "CameraRig", "CloudreachChapter", "CloudreachRuntime", "InteractionArbiter", "DialoguePanel"]:
		if world.get_node_or_null(NodePath(path)) == null:
			_fail("Cloudreach continuation lacks production node " + path)
			return result()
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	combat_pilot = CampaignPilot.new(tree, manager, director, world.get_node("CameraRig"))
	combat_pilot.pilot = PILOT.Pilot.SPACER
	combat_pilot.switch_input = true
	combat_pilot.use_switching = false
	_connect(tree.physics_frame, _record_frame)
	_connect(world.get_node("InteractionArbiter").activated, func(provider: Object) -> void:
		interaction_activations += 1
		last_activated_path = str(provider.get_path())
		_log("offer_activated", {"path":last_activated_path}))
	_connect(director.trainer_started, func(id: String) -> void:
		battle_starts.append(id)
		_log("battle_started", {"id":id}))
	_connect(director.trainer_victory, func(id: String) -> void:
		battle_wins.append(id)
		_log("battle_victory", {"id":id}))
	_connect(director.trainer_lost, func(id: String) -> void:
		battle_losses.append(id)
		_log("battle_loss", {"id":id}))
	_connect(fly.recovered, func(reason: String) -> void:
		_fail("Unexpected recovery interrupts continuous route: " + reason))
	_connect(manager.hit_landed, func(on_enemy: bool, amount: float) -> void:
		if on_enemy:
			combat_pilot.hits_dealt += 1
			combat_pilot.damage_dealt += amount
		else:
			combat_pilot.hits_taken += 1
			combat_pilot.damage_taken += amount)
	_log("entry", {"source":"earned live Tidewake portal", "team":_team_snapshot(), "inventory":_inventory_snapshot()})
	await _run_route()
	_release()
	for connection: Dictionary in _connections:
		var source: Signal = connection.signal
		var callback: Callable = connection.callback
		if not source.is_null() and source.is_connected(callback):
			source.disconnect(callback)
	_connections.clear()
	return result()

