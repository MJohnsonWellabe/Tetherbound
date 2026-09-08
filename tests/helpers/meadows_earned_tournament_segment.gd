extends "res://tests/helpers/gate_b_tail_segment.gd"

## Enter the actual marshal's ladder and fight with the retained, earned team.
## No arena staging, dialogue calls, heals, grants, or direct party switching.
const LIVE_COMBAT := preload("res://tests/helpers/cloudreach_live_segment.gd")
var _marshal: Node3D
var _dialogue_finished := ""
var _hits := 0
var _round_wins := 0


func run(tree: SceneTree, world: Node3D, game: Node, player: CharacterBody3D,
		rig: Node3D, stage_arena: bool = false, skip_house: bool = false) -> Dictionary:
	_tree = tree
	_world = world
	_game = game
	_player = player
	_rig = rig
	_progression = game.get("progression")
	_party = game.get("party")
	if stage_arena or skip_house or not _collect_nodes():
		_fail("earned tournament does not accept fixture staging")
		return _result()
	if not TOURNAMENT.team_ready(_party) or not TOURNAMENT.training_ready(_party) \
			or not TOURNAMENT.condition_ready(_party):
		_fail("earned tournament team is not ready: " + str(TOURNAMENT.readiness_report(_party)))
		return _result()
	_marshal = world.find_child(TOURNAMENT.marshal_name(), true, false) as Node3D
	if _marshal == null:
		_fail("the live tournament marshal is missing")
		return _result()
	_resolve_move_bindings()
	_panel.connect("finished", _on_dialogue_finished)
	_manager.connect("hit_landed", _on_hit_landed)
	_manager.connect("exited", _on_fight_exited)
	if await _enter_the_tournament() and failures.is_empty():
		if await _fight_the_bracket():
			_the_objective_points_at_the_bridge(false)
	_panel.disconnect("finished", _on_dialogue_finished)
	_manager.disconnect("hit_landed", _on_hit_landed)
	_manager.disconnect("exited", _on_fight_exited)
	return _result()


func _play(conversation_id: String) -> void:
	var chosen := VILLAGE_NPCS.greeting_for(_villager(TOURNAMENT.marshal_name()), _progression)
	if chosen != conversation_id:
		_fail("marshal offers %s, expected %s" % [chosen, conversation_id])
		return
	var prompt := _marshal.get_node_or_null("Interactable") as Node3D
	if prompt == null or not await _walk_to_prompt(prompt, "tournament marshal"):
		_fail("ordinary walk did not reach the marshal's exact prompt")
		return
	_dialogue_finished = ""
	await _tap(&"interact")
	for _frame in 90:
		if bool(_panel.call("is_open")):
			break
		await _tree.physics_frame
	if not bool(_panel.call("is_open")):
		_fail("marshal interaction opened no dialogue")
		return
	for _line in 64:
		if not bool(_panel.call("is_open")):
			break
		await _tap(&"interact")
		await _settle(6)
	if bool(_panel.call("is_open")) or _dialogue_finished != conversation_id:
		_fail("marshal input completed '%s', expected '%s'" % [_dialogue_finished, conversation_id])


func _fight_the_bracket() -> bool:
	# The player already walked to Halda. The arena is reached through the
	# authored conversation and production trainer admission, never a pose write.
	if not await _call_out_a_creature():
		return false
	for spec: Dictionary in TOURNAMENT.rounds():
		if not await _fight_and_win(spec):
			return false
	if not _flag("tournament_won") or not _flag("recipe_saddle") \
			or not bool(_game.call("recipe_known", "saddle")):
		_fail("won bracket did not produce its real victory and saddle recipe receipts")
		return false
	return true


func _fight_and_win(spec: Dictionary) -> bool:
	var trainer_id := str(spec["trainer"])
	await _play(str(spec["conversation"]))
	if not failures.is_empty():
		return false
	if bool(_director.call("trainer_battle_active")) or not _flag(str(spec["at_ring_flag"])):
		_fail("ring-entry dialogue did not wait for the explicit begin-round choice")
		return false
	var start := Engine.get_physics_frames()
	var wins_before := _round_wins
	var hits_before := _hits
	await _play(str(spec["begin_conversation"]))
	if not failures.is_empty():
		return false
	if not bool(_director.call("trainer_battle_active")) \
			or str(_director.call("trainer_battle_id")) != trainer_id:
		_fail("begin-round input did not admit the exact tournament trainer " + trainer_id)
		return false
	var pilot := LIVE_COMBAT.CampaignPilot.new(_tree, _manager, _director, _rig)
	pilot.use_switching = false
	pilot.switch_input = true
	while bool(_director.call("trainer_battle_active")) \
			and Engine.get_physics_frames() - start < ROUND_FRAME_LIMIT:
		if bool(_manager.call("is_fighting")):
			var ally := _director.call("ally_body") as Node3D
			var foe := _manager.call("enemy_body") as Node3D
			if not is_instance_valid(ally) or not is_instance_valid(foe):
				await _tree.physics_frame
				continue
			# One bounded input decision at a time. Waiting for the base
			# pilot's entire fight would hide this round's actual deadline.
			await pilot._act(ally, foe)
			pilot._move_toward(Vector3.ZERO)
		else:
			if str(_manager.call("outcome")) == "lost":
				_fail("earned tournament fight was lost: " + trainer_id)
				return false
			await _tree.physics_frame
	var team_size := TRAINERS.team_of(TRAINERS.trainer(trainer_id)).size()
	if Engine.get_physics_frames() - start >= ROUND_FRAME_LIMIT:
		_fail("earned tournament exceeded its unchanged round budget: " + trainer_id)
		return false
	if bool(_director.call("trainer_battle_active")) or not _flag(str(spec["won_flag"])) \
			or _round_wins - wins_before != team_size or _hits <= hits_before:
		_fail("tournament round lacks its exact team defeats, real hits, or durable victory: " + trainer_id)
		return false
	var receipt := "%s won through %d real opponent defeats and %d landed attacks" % [
		trainer_id, _round_wins - wins_before, _hits - hits_before]
	transcript.append(receipt)
	print("EARNED TOURNAMENT — ", receipt)
	return true


func _on_dialogue_finished(id: String) -> void:
	_dialogue_finished = id


func _on_hit_landed(on_enemy: bool, _amount: float) -> void:
	if on_enemy:
		_hits += 1


func _on_fight_exited(outcome: String) -> void:
	if outcome == "won":
		_round_wins += 1


func _stand_on_the_tournament_ground() -> void:
	_fail("arena teleport is forbidden in the earned tournament")
