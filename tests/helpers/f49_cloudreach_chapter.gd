extends "res://tests/helpers/cloudreach_live_segment.gd"

var _solmane_dialogues: Array[String] = []

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
	if initial_party_ids.size() != 5:
		_fail("Cloudreach campaign requires the unchanged earned five creatures")
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


func _run_route() -> void:
	await super._run_route()
	if not completed_route: return
	completed_route = false
	stage = "solmane_settlement"
	var climax := world.get_node_or_null("CloudreachSolmaneClimax") as Node3D
	var panel := world.get_node("DialoguePanel")
	if climax == null:
		_fail("Earned Cloudreach lacks its actual Solmane machine")
		return
	if _has("cloudreach:legendary_freed") or _has("cloudreach:legendary_settled"):
		_fail("Solmane was already freed or settled before the actual machine input")
		return
	var machine := climax.get_node_or_null("MachineControl/MachinePrompt") as Node3D
	if machine == null:
		_fail("Solmane machine has no production interaction provider")
		return
	# Return over the authored summit approach and enter the circular deck by
	# its central corridor, just as the original route leaves it after Veyra.
	if not await _navigate(Vector3(100.0,1160.0,5350.0)): return
	var origin := _vec(runtime.finale.config.get("arena_origin", [100.0,1160.0,5450.0]))
	for entry: Vector3 in [origin-Vector3(0.0,0.0,50.0), origin-Vector3(0.0,0.0,30.0), origin]:
		if not await _walk(entry): return
	_solmane_dialogues.clear()
	_connect(panel.finished, _solmane_finished)
	if not await _interact(machine): return
	var config: Dictionary = climax.get("_config")
	var authored: Dictionary = config.get("machine", {})
	var choice: Dictionary = config.get("choice", {})
	var expected: Array[String] = [str(authored.get("chamber_conversation", "")),
		str(authored.get("free_conversation", "")), str(authored.get("join_conversation", "")),
		str(choice.get("conversation", ""))]
	if not await _read_solmane_sequence(climax, panel, expected, "choice"): return
	var refuse := climax.get("_refuse_prompt") as Node3D
	if refuse == null or game.pending_catch != null:
		_fail("Solmane offer did not expose its actual Refuse prompt before any pending creature")
		return
	if not await _walk((refuse.get_parent() as Node3D).global_position, 0.35) \
		or not await _interact(refuse, "cloudreach:legendary_refused", false): return
	var refused_conversation := str(choice.get("refused_conversation", ""))
	if not refused_conversation.is_empty(): expected.append(refused_conversation)
	expected.append(str(authored.get("failure_conversation", "")))
	if not await _read_solmane_sequence(climax, panel, expected, "done"): return
	if not _require(_has("cloudreach:legendary_freed") and _has("cloudreach:legendary_settled") \
		and _has("cloudreach:legendary_refused") and not _has("cloudreach:legendary_joined") \
		and game.pending_catch == null and party_preserved(initial_party_ids, _party_ids()),
		"Actual Solmane refusal settled with the same five"): return
	if not _require(game.local.redesign_character.relics_held.has("cloudreach") \
		or game.local.redesign_character.relics_hung.has("cloudreach"), "Personal Cloudreach relic earned"): return
	if not _require(game.inventory.count("stormwood_portal_key") == 1, "Personal Stormwood portal key earned once"): return
	_log("solmane_settled", {"choice":"physical_refuse_keep_earned_five", "dialogues":_solmane_dialogues.duplicate(),
		"team":_team_snapshot(), "flags":_flag_snapshot()})
	completed_route = true
	stage = "complete"


func _solmane_finished(id: String) -> void:
	_solmane_dialogues.append(id)


func _read_solmane_sequence(climax: Node, panel: Node, expected: Array[String], terminal: String) -> bool:
	var start := Engine.get_physics_frames()
	while Engine.get_physics_frames() - start < 900:
		if not failures.is_empty(): return false
		if _solmane_dialogues.size() > expected.size() \
			or _solmane_dialogues != expected.slice(0, _solmane_dialogues.size()):
			return _fail("Solmane's actual authored conversation order diverged")
		if str(climax.get("_stage")) == terminal and not bool(panel.call("is_open")) and _solmane_dialogues == expected:
			return true
		if bool(panel.call("is_open")):
			var current := str((panel.get("_runner") as RefCounted).call("conversation_id"))
			if _solmane_dialogues.size() >= expected.size() or current != expected[_solmane_dialogues.size()]:
				return _fail("Unexpected live dialogue interrupted Solmane settlement")
			await _tap("interact")
		else:
			await _tree.physics_frame
	return _fail("Actual Solmane sequence did not reach " + terminal + " within the story budget")
