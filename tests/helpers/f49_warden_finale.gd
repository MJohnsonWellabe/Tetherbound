extends "res://tests/helpers/meadows_earned_warden_segment.gd"

## Retain the original fight, contact, room budgets and ceremony guards. Only
## the retired Rift dependency is removed: this helper never crosses it.
func _bind_ending(tree: SceneTree, world: Node3D, game: Node, after: bool) -> bool:
	_tree = tree
	_world = world
	_game = game
	if tree == null or not is_instance_valid(world) or not is_instance_valid(game):
		return _fail("Earned Warden needs the retained tree, world and Game")
	if tree.current_scene != world or str(game.get("current_realm")) != "meadows" or INPUT_OWNER.current(tree) != null:
		return _fail("The ending needs ordinary input in the retained Meadows")
	_source_world_id = world.get_instance_id()
	_player = world.get_node_or_null("Player") as CharacterBody3D
	_rig = world.get_node_or_null("CameraRig") as Node3D
	_hold = world.get_node_or_null("Stronghold") as Node3D
	_climax = world.get_node_or_null("StrongholdClimax") as Node3D
	_rift = world.get_node_or_null("RiftCrossing") as Node3D
	_panel = world.get_node_or_null("DialoguePanel")
	_director = world.get_node_or_null("EncounterDirector")
	_combat = world.get_node_or_null("CombatManager")
	_arbiter = tree.get_first_node_in_group("interaction_arbiter")
	if _player == null or _rig == null or _hold == null or _climax == null \
			or _panel == null or _director == null or _combat == null or _arbiter == null:
		return _fail("The live Hall, climax, Rift or input dependencies are missing")
	_initial_ids = _party_ids()
	if not retained_five(_initial_ids, _initial_ids) or _fighting() or game.get("pending_catch") != null \
			or not _has("hall_approach_open") or not _has("defeated_stronghold_elite") or _has("meadows_acknowledged"):
		return _fail("The ending must retain the earned five after Hall, before acknowledgement")
	_hall_config = _read(HALL_CONFIG)
	_ending_config = _read(CLIMAX_CONFIG)
	if after:
		if not _ending_ready() or str(_climax.get("_stage")) != "done":
			return _fail("The acknowledgement tail needs the actually settled completed machine sequence")
	else:
		for flag: String in ["defeated_warden", "legendary_freed", "legendary_settled", "legendary_joined", "learned_legendary_is_the_source", "realm_key_cloudreach", "realm_heart_meadows_earned"]:
			if _has(flag):
				return _fail("A next Warden reward or ending beat was already present: " + flag)
		if not bool(_hold.call("has_marker", "warden_arena")) \
				or _player.global_position.distance_to(_hold.call("marker", "warden_arena")) > 0.6 \
				or not shutter_receipt(_hold, "defeated_warden", false):
			return _fail("The actual player has not reached the preceding earned Hall arena boundary")
	_supported_y = (_hold.call("marker", "warden_arena") as Vector3).y
	_input = INPUTS.new()
	_input._tree = tree
	_gui = CEREMONY.new()
	_gui._tree = tree
	_nav = NAV.new(tree, _player, _rig, _stick)
	_watch(_combat, "entered", _on_entered)
	_watch(_combat, "hit_landed", _on_hit)
	_watch(_combat, "exited", _on_exit)
	_watch(_panel, "finished", _on_dialogue_finished)
	_watch(_arbiter, "activated", _on_activated)
	_watch(tree, "process_frame", _observe_retained_party)
	return true


func _ending_ready() -> bool:
	return _has("defeated_warden") and _has("legendary_freed") and _has("legendary_settled") \
		and _has("realm_heart_meadows_earned") and _has("legendary_refused") and not _has("legendary_joined") \
		and _game.get("pending_catch") == null


## The production volunteer now asks at two physical prompts before any
## pending catch exists. Read all four conversations, then walk to Refuse.
func _drive_machine_to_ceremony(expected: Array[String], first: int) -> bool:
	var sequence: Array[String] = expected.duplicate()
	sequence.append(str((_ending_config.get("choice", {}) as Dictionary).get("conversation", "")))
	var start := Engine.get_physics_frames()
	while Engine.get_physics_frames() - start < SEQUENCE_FRAMES:
		var observed: Array = _finished_dialogues.slice(first)
		if not _failures.is_empty() or not dialogue_prefix(observed, sequence):
			return _fail("The machine's chamber/free/join/choice conversations diverged")
		if _game.get("pending_catch") != null:
			return _fail("The legendary became pending before the retained-five refusal")
		if bool(_climax.call("choice_open")) and not bool(_panel.call("is_open")) and observed == sequence:
			return _has("legendary_freed") or _fail("The choice opened before the actual freeing")
		if bool(_panel.call("is_open")):
			if observed.size() >= sequence.size() or _current_conversation() != sequence[observed.size()]:
				return _fail("An unexpected dialogue interrupted the actual legendary choice")
			await _input._tap("interact")
		else:
			await _tree.physics_frame
	return _fail("The machine never reached its actual Refuse choice within the story budget")


func _keep_the_earned_five() -> bool:
	var refuse := _climax.get("_refuse_prompt") as Node3D
	if not bool(_climax.call("choice_open")) or refuse == null or _game.get("pending_catch") != null:
		return _fail("The retained-five ending has no actual voluntary Refuse prompt")
	if not await _press_prompt(refuse):
		return false
	return (not bool(_climax.call("choice_open")) and _has("legendary_refused") \
		and not _has("legendary_joined") and _game.get("pending_catch") == null \
		and retained_five(_initial_ids, _party_ids())) \
		or _fail("Physical Refuse did not settle this character with the same five")


func _receipt(beat: String, detail: Dictionary) -> void:
	if beat == "meadows_ending_settled":
		detail["choice"] = "physical_refuse_keep_earned_five"
		detail.erase("released_pending_id")
		detail["legendary_refused"] = _has("legendary_refused")
	super._receipt(beat, detail)
