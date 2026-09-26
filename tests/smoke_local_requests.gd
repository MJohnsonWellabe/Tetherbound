extends SceneTree

## T3-ACTIVITIES. Does each of the five new Local Requests (spec sec6) actually
## play, in the real world scene, through the real systems?
##
##   godot --headless --path . --script tests/smoke_local_requests.gd
##
## `tests/test_trainers_data.gd`/`test_dialogue_runner.gd`/`test_quest_log.gd`
## already prove the DATA -- real species, real flags, conversations that
## resolve, ids that exist. What only exists once somebody is standing on
## Terrain3D is the WIRING this file drives, for all five activities in one
## boot (each activity's own footprint is small; five separate world boots
## would be five times the CI cost for no more coverage):
##
##   - each trainer/NPC is placed for real, on real ground
##   - talking to them reaches the real `battle:`/`give:`/`flag:` effects
##     through the real dialogue panel and sequence_director drain, the same
##     path `smoke_village_smith.gd` proved for Tam's tool handover
##   - for the two combat activities (Night Watch, Lost Creature), the fight
##     actually RUNS through the real encounter_director/combat_manager
##     pipeline and can be WON (the same HP-floor allowance
##     `smoke_boss.gd`/`smoke_trainer_battle.gd` make for the same reason:
##     this is about wiring, not balance); River Nest and Broken Cart drive
##     the real `item_gate.gd` contract instead (empty-handed refusal, then a
##     paid hand-over), the same shape `test_item_cache_pickup.gd` proves for
##     the mechanism in isolation
##   - beating/finishing each one sets the real defeat/completion flag and
##     pays the real reward
##   - and `scripts/world/quest_log.gd` -- the actual HUD/log reader, not a
##     restatement of its rules -- reports each Local Request as done once
##     its own flag is set, having been invisible before that
##
## CI-TRAINER-CENSUS, 2026-08-30: River Nest was originally a third combat
## activity (`_play_local_trainer` on `river_nest_doss`, the same shape Night
## Watch and Lost Creature still use). It moved to the item_gate shape when
## `river_nest_doss` was pulled out of trainers.json entirely -- see
## `scripts/world/river_nest_clear.gd`'s own header for why.
##
## The focused activity selectors additionally prove ordinary-input approach
## for the herd and parsed-input acknowledgement at Juno. Other legacy rows
## retain their direct conversation start because their seam is the activity.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

const SETTLE_FRAMES := 300
const BATTLE_FRAME_LIMIT := 3000
const CONSECUTIVE_MISS_LIMIT := 25

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _manager: Node = null
var _director: Node = null
var _panel: Node = null
## Diagnostic: every conversation that finished, with its physics frame.
var _conversation_log: Array[String] = []
var _log := QUEST_LOG.new()

var _quick_hits := 0
var _quick_misses := 0
var _consecutive_misses := 0
var _selected_activities: Array[String] = []
var _capture_dir := ""


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_selected_activities = _activity_selection()
	_capture_dir = _capture_directory()
	# This script bypasses the title screen in every mode. Mint the portable
	# character identity durable reward delivery requires through the real fresh
	# game/save path, rather than leaving the default all-activities path with an
	# identity-less fixture.
	var fresh_game := root.get_node_or_null(^"Game")
	if fresh_game == null:
		_fail("activity fixture: Game autoload is missing")
		_report()
		return
	fresh_game.call("reset_for_new_game")
	fresh_game.set("save_system", SAVE_GAME.new("user://smoke_local_requests_activities/"))
	if not bool(fresh_game.call("save_game", 4)):
		_fail("activity fixture: fresh character identity could not be saved")
		_report()
		return
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return

	if not _selected_activities.is_empty():
		for activity in _selected_activities:
			# A preceding production disk load replaces party instances. Give the
			# director its normal reconciliation frames before the next activity
			# reads the deployed body.
			for _frame in 2:
				await physics_frame
				await process_frame
			match activity:
				"herd": await _meadowhart_herd()
				"bram": await _old_bram()
				"juno": await _lost_creature()
				"doss": await _river_nest_activity()
				_: _fail("unknown scoped activity '%s'" % activity)
	else:
		await _night_watch()
		await _river_nest()
		await _lost_creature()
		await _meadowhart_herd()
		await _broken_cart()

	_report()


func _activity_selection() -> Array[String]:
	var selected: Array[String] = []
	for argument in OS.get_cmdline_user_args():
		var value := ""
		if argument == "--herd-only":
			value = "herd"
		elif argument.begins_with("--activities="):
			value = argument.trim_prefix("--activities=")
		elif argument.begins_with("--only="):
			value = argument.trim_prefix("--only=")
		for raw in value.split(",", false):
			var activity := raw.strip_edges().to_lower()
			if not activity.is_empty() and not selected.has(activity):
				selected.append(activity)
	return selected


func _capture_directory() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			return argument.trim_prefix("--capture-dir=").strip_edges()
	return ""


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	var game := root.get_node_or_null(^"Game")
	if director == null or game == null:
		return
	var party := game.get("party") as RefCounted
	if party == null:
		_fail("fixture: Game.party is missing")
		return
	if director.call("ally_instance") != null:
		if not (party.call("members") as Array).has(director.call("ally_instance")):
			_fail("fixture: deployed ally is not an owned party member")
		return
	# Fixture-only owned roster: one starter plus four ordinary Meadows species.
	for species_id: String in ["terrapup", "trailpup", "bramblebun", "burrowback", "meadowhart"]:
		var creature := game.call("make_creature", species_id) as RefCounted
		if creature == null or not bool(party.call("add", creature)):
			_fail("fixture: could not add owned %s" % species_id)
			return
	if not bool(await director.call("summon_active_creature")):
		_fail("fixture: could not deploy the owned active creature")


func _collect_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
	if _panel != null and _panel.has_signal("finished"):
		_panel.connect("finished", func(id: String) -> void:
			_conversation_log.append("%s@%d" % [id, Engine.get_physics_frames()]))
	if _game == null or _player == null or _manager == null or _director == null or _panel == null:
		_fail("the scene is missing the Game autoload, the player, the manager, the director or the panel")
		return false
	if _director.call("ally_instance") == null:
		_fail("no ally creature; nothing can fight")
		return false
	return true


func _progression() -> RefCounted:
	return _game.get("progression") as RefCounted


func _inventory() -> RefCounted:
	return _game.get("inventory") as RefCounted


## --- the three combat activities --------------------------------------------

func _night_watch() -> void:
	await _play_local_trainer(
		"night_watch_farro", "night_watch_farro_challenge",
		"defeated_night_watch_farro", "night_watch_farro_met", "band2_night_watch")


func _old_bram() -> void:
	await _play_local_trainer(
		"old_champion_bram", "old_champion_challenge",
		"defeated_old_bram", "old_champion_met", "band1_old_champion",
		{"coin": 60, "orb_greater": 5, "potion_small": 3})
	if not bool(_progression().call("has", "defeated_old_bram")):
		return
	# The helper drives Bram's authored two-creature team through the real battle.
	# His post-win line is the visible acknowledgement and lure toward the elder.
	await _play("old_champion_beaten")
	await _verify_bram_disk_round_trip()
	await _capture_activity("bram")


func _lost_creature() -> void:
	# F03 distinct action. Beating the patrol only FREES the Meadowhart (and pays
	# the patrol's once-only battle reward). The activity completes when the
	# player taps "Lead the Meadowhart home" and walks her to Juno with real
	# stick input; the host then commits `lost_creature_rue_returned`.
	var reunion := _world.get_node_or_null("LostCompanionReunion")
	if reunion == null:
		_fail("lost_creature: missing physical companion presentation")
		return
	var rescued: Node3D = reunion.get_node_or_null("RescuedMeadowhart")
	var trainers := _world.get_node("Trainers")
	var patrol: Node3D = trainers.call("body_for", "lost_creature_rue")
	var owner_body: Node3D = trainers.call("body_for", "pasture_drover_juno")
	if rescued == null or patrol == null or owner_body == null:
		_fail("lost_creature: missing rescued creature, patrol or existing Juno")
		return
	var prompt := rescued.get_node_or_null(^"Interactable")
	if prompt == null:
		_fail("lost_creature: the Meadowhart offers no escort prompt")
		return
	if bool(reunion.call("is_reunited")) or rescued.global_position.distance_to(patrol.global_position) > 10.0:
		_fail("lost_creature: missing companion is not beside the unbeaten patrol")
	if bool(prompt.get("enabled")):
		_fail("lost_creature: the escort is offered while the patrol still holds her")
	var instance_id := rescued.get_instance_id()
	var party_before: Array = (_game.get("party") as RefCounted).call("members")
	if party_before.size() != 5 or not party_before.has(_director.call("ally_instance")):
		_fail("lost_creature: fixture did not begin with five owned companions including the deployed ally")
		return
	await _play_local_trainer(
		"lost_creature_rue", "lost_creature_rue_challenge",
		"defeated_lost_creature_rue", "lost_creature_rue_met", "band4_lost_creature",
		{"coin": 50, "revive": 1}, false)
	await _close_parsed_acknowledgement("lost_creature patrol")
	for _frame in 2:
		await physics_frame
		await process_frame
	if bool(_progression().call("has", RETURN_FLAG)) or bool(reunion.call("is_reunited")):
		_fail("lost_creature: beating the patrol completed the return by itself")
	if rescued.global_position.distance_to(patrol.global_position) > 10.0:
		_fail("lost_creature: the freed Meadowhart left the patrol before anyone led her")
	if not bool(prompt.get("enabled")):
		_fail("lost_creature: the freed Meadowhart does not offer 'Lead the Meadowhart home'")
	var coins := int(_inventory().call("count", "coin"))
	var revives := int(_inventory().call("count", "revive"))
	var waiting_at := rescued.global_position

	# Leash: start an escort with a real press, then leave her far behind.
	if not await _start_escort(reunion, prompt, rescued):
		return
	var far := rescued.global_position + Vector3(0.0, 0.0, -70.0)
	await _seat_remote_fixture(far, _director.call("ally_body") as Node3D)
	for _frame in 6:
		await physics_frame
		await process_frame
	if int(reunion.call("escort_peer")) != 0:
		_fail("lost_creature: outrunning the 40 m leash did not end the escort")
	# "Back to wait by the patrol": lost_companion_reunion.gd anchors her waiting
	# pose to the patrol's LIVE body (it turns and settles after its fight), so
	# compare with the patrol -- the same 10 m this section's opening check uses
	# -- not with the frozen spot she stood on right after the battle.
	if rescued.global_position.distance_to(patrol.global_position) > 10.0 or not bool(prompt.get("enabled")):
		_fail("lost_creature: a broken leash did not send her back to wait with the prompt (%.2f m from the patrol, prompt enabled=%s)" % [
			rescued.global_position.distance_to(patrol.global_position), str(prompt.get("enabled"))])
	if bool(_progression().call("has", RETURN_FLAG)):
		_fail("lost_creature: a broken leash completed the return")

	# The real walk home.
	if not await _start_escort(reunion, prompt, rescued):
		return
	if not await _lead_home(reunion, rescued, owner_body):
		return
	for _frame in 4:
		await physics_frame
		await process_frame
	if not bool(_progression().call("has", RETURN_FLAG)) or not bool(reunion.call("is_reunited")):
		_fail("lost_creature: arriving at Juno did not set the return flag")
	var entry := _local_entry("band4_lost_creature", _progression())
	if not entry.get("present", false) or not bool(entry.get("done", false)):
		_fail("lost_creature: the return does not read done in quest_log")
	if rescued.global_position.distance_to(owner_body.global_position) > 10.0:
		_fail("lost_creature: the returned Meadowhart is not beside Juno")
	var runner: RefCounted = _panel.call("runner") as RefCounted
	if not bool(_panel.call("is_open")) or runner == null \
			or str(runner.call("conversation_id")) != "lost_creature_rue_returned":
		_fail("lost_creature: Juno did not acknowledge the return (open=%s conversation=%s)" % [
			str(_panel.call("is_open")), str(runner.call("conversation_id")) if runner != null else "?"])
	await _close_parsed_acknowledgement("lost_creature return")
	if int(_inventory().call("count", "coin")) != coins or int(_inventory().call("count", "revive")) != revives:
		_fail("lost_creature: the return paid a second reward on top of the patrol's")

	# Once-only: the prompt is gone, a direct second activation and a second
	# arrival change nothing.
	if bool(prompt.get("enabled")):
		_fail("lost_creature: the returned Meadowhart still offers the escort")
	var log_before := _conversation_log.size()
	prompt.call("interaction_activate")
	reunion.call("_host_complete_return")
	for _frame in 6:
		await physics_frame
		await process_frame
	if int(reunion.call("escort_peer")) != 0:
		_fail("lost_creature: a second press started another escort")
	if int(_inventory().call("count", "coin")) != coins or int(_inventory().call("count", "revive")) != revives:
		_fail("lost_creature: a second press or arrival paid again")
	if bool(_panel.call("is_open")) or _conversation_log.size() != log_before:
		_fail("lost_creature: a second arrival acknowledged the return again")

	if rescued.get_instance_id() != instance_id or not rescued.visible:
		_fail("lost_creature: reunion replaced or hid the visible companion")
	if int(rescued.get("collision_layer")) != 0 or int(rescued.get("collision_mask")) != 0:
		_fail("lost_creature: the display creature blocks ordinary movement")
	# Battle XP/condition legitimately change; compare membership identities only.
	var party_after: Array = (_game.get("party") as RefCounted).call("members")
	if party_after.size() != 5 or party_before != party_after:
		_fail("lost_creature: the rescue changed the player's owned companions")
	var terminal: Vector3 = rescued.global_position
	reunion.global_position = Vector3.ZERO
	reunion.call("restore_progression_from_game", _game)
	if rescued.global_position.distance_to(terminal) > 0.01:
		_fail("lost_creature: restored world flag did not reconstruct the reunion")
	# Legacy shape: the patrol beaten, the return never made. She waits by the
	# patrol with the prompt; nothing is completed retroactively.
	_progression().call("set_flag", RETURN_FLAG, false)
	reunion.call("restore_progression_from_game", _game)
	if rescued.global_position.distance_to(patrol.global_position) > 10.0 or not bool(prompt.get("enabled")) \
			or bool(reunion.call("is_reunited")):
		_fail("lost_creature: a legacy beaten-but-not-returned state does not wait by the patrol (%.2f m from the patrol, prompt enabled=%s, reunited=%s)" % [
			rescued.global_position.distance_to(patrol.global_position),
			str(prompt.get("enabled")), str(reunion.call("is_reunited"))])
	_progression().call("set_flag", RETURN_FLAG, true)
	reunion.call("restore_progression_from_game", _game)
	if TRAINERS.conversation_for(TRAINERS.trainer("pasture_drover_juno"), _progression()) != "pasture_drover_juno_reunited_challenge":
		_fail("lost_creature: Juno did not acknowledge rescue before her own optional battle")
		return
	# Juno is a trainer: with every companion fainted (the full run fights the
	# Night Watch and the patrol before this) her greeting answers with
	# `trainer_no_usable_creature` instead of the reunion line. A player rests
	# before talking to a trainer; this fixture heals between beats the way it
	# seats between them, outside the activity under test.
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		member.call("heal_fully")
	if not await _activate_trainer_prompt(owner_body, "lost_creature"):
		return
	# The prompt's opening press may be buffered by DialoguePanel and advance its
	# first line. Follow the runner's live confirmation state instead of assuming
	# a fixed number of presses, then explicitly choose Later.
	var acknowledgement_guard := 0
	while bool(_panel.call("is_open")) and not _panel_awaiting_confirmation() \
			and acknowledgement_guard < 8:
		await _press("interact")
		acknowledgement_guard += 1
	if not bool(_panel.call("is_open")) or not _panel_awaiting_confirmation():
		var ack_runner: RefCounted = _panel.call("runner") as RefCounted
		_fail("lost_creature: Juno's acknowledgement never reached its friendly-bout choice (open=%s conversation=%s presses=%d log_tail=%s)" % [
			str(_panel.call("is_open")),
			str(ack_runner.call("conversation_id")) if ack_runner != null else "?",
			acknowledgement_guard, str(_conversation_log.slice(-3))])
		return
	await _capture_activity("juno")
	await _press("menu_cancel")
	if bool(_panel.call("is_open")):
		_fail("lost_creature: choosing Later did not close Juno's acknowledgement")
	if bool(_director.call("trainer_battle_active")):
		_fail("lost_creature: choosing Later from Juno's acknowledgement started her optional battle")
	await _verify_juno_disk_round_trip(reunion)


const RETURN_FLAG := "lost_creature_rue_returned"
const STICK_NAV := preload("res://tests/helpers/stick_navigator.gd")


## One left-stick sample through the live InputMap, the navigator's drive.
func _stick(x: float, z: float) -> void:
	for pair: Array in [[JOY_AXIS_LEFT_X, x], [JOY_AXIS_LEFT_Y, z]]:
		var event := InputEventJoypadMotion.new()
		event.device = 0
		event.axis = int(pair[0])
		event.axis_value = float(pair[1])
		Input.parse_input_event(event)


## Stand beside the waiting Meadowhart and press the real interact action on
## her own prompt. One tap; nothing is held.
func _start_escort(reunion: Node, prompt: Node, rescued: Node3D) -> bool:
	var arbiter := _world.get_node_or_null(^"InteractionArbiter")
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	for offset: Vector3 in [Vector3(2.0, 0.0, 0.0), Vector3(-2.0, 0.0, 0.0),
			Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, -2.0)]:
		var at: Vector3 = rescued.global_position + offset
		await _seat_remote_fixture(at, _director.call("ally_body") as Node3D)
		if rig != null:
			rig.set("yaw", atan2(offset.x, offset.z))
		for _frame in 90:
			await physics_frame
			await process_frame
			if arbiter.call("winning_provider") == prompt and INPUT_OWNER.current(self) == null:
				await _press("interact")
				if int(reunion.call("escort_peer")) != 0:
					if bool(prompt.get("enabled")):
						_fail("lost_creature: the leader still has an escort prompt at their heels")
					return true
	var winner: Variant = arbiter.call("winning_provider")
	_fail("lost_creature: pressing interact at the Meadowhart did not start an escort (winner=%s)" % [
		str((winner as Node).get_path()) if winner is Node else str(winner)])
	return false


## Walk to Juno with ordinary left-stick input through the shared
## stick_navigator (it steps round walls and banks as the earned routes do; a
## straight line from the patrol stalled ~400 m out against the terrain). No
## completion may land before the Meadowhart is within the arrival radius.
func _lead_home(reunion: Node, rescued: Node3D, owner_body: Node3D) -> bool:
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	var config: Dictionary = reunion.get("_config")
	var radius := float(config.get("arrival_radius_m", 6.0))
	var moving := true
	var arrived := false
	var started := Engine.get_physics_frames()
	var nav: RefCounted = STICK_NAV.new(self, _player, rig, _stick)
	for frame in 12000:
		var to := owner_body.global_position - _player.global_position
		to.y = 0.0
		if moving and to.length() <= 2.5:
			_stick(0.0, 0.0)
			moving = false
		elif moving:
			nav.call("step", owner_body.global_position)
		await physics_frame
		await process_frame
		var gap := Vector2(rescued.global_position.x - owner_body.global_position.x,
			rescued.global_position.z - owner_body.global_position.z).length()
		if bool(_progression().call("has", RETURN_FLAG)):
			if gap > radius + 0.5 and not bool(reunion.call("is_reunited")):
				_fail("lost_creature: completed %.1f m from Juno, outside the %.1f m arrival" % [gap, radius])
			arrived = true
			break
		if int(reunion.call("escort_peer")) == 0:
			_fail("lost_creature: the escort ended on the walk home at player=%s creature=%s (frame %d)" % [
				str(_player.global_position), str(rescued.global_position), frame])
			break
		if bool(_panel.call("is_open")):
			_fail("lost_creature: a conversation interrupted the walk home before arrival")
			break
		if frame % 600 == 0:
			print("lost_creature walk: frame %d player=%s creature gap to Juno %.1f m" % [
				frame, str(_player.global_position), gap])
	_stick(0.0, 0.0)
	print("lost_creature walk: %s after %d physics frames" % [
		"arrived" if arrived else "did not arrive", Engine.get_physics_frames() - started])
	if not arrived:
		_fail("lost_creature: walking to Juno never completed the return (player=%s, creature=%s)" % [
			str(_player.global_position), str(rescued.global_position)])
	return arrived


## Shared drive for all three: find the real placed body, walk the real
## challenge conversation to its `battle:` line on the real panel, fight the
## real trainer battle to the end, then check the real flag/reward/quest-log
## consequences.
func _play_local_trainer(trainer_id: String, challenge_conversation: String,
		defeat_flag: String, met_flag: String, objective_id: String,
		expected_reward: Dictionary = {}, completes_objective: bool = true) -> void:
	var trainers := _world.get_node_or_null(^"Trainers")
	if trainers == null:
		_fail("%s: no 'Trainers' node in the world" % trainer_id)
		return
	var body: Node3D = trainers.call("body_for", trainer_id)
	if body == null or not is_instance_valid(body):
		_fail("%s: not placed anywhere in the real world" % trainer_id)
		return

	var progression := _progression()
	var reward_before: Dictionary = {}
	for item_id: String in expected_reward:
		reward_before[item_id] = int(_inventory().call("count", item_id))
	if bool(progression.call("has", defeat_flag)):
		_fail("%s: already beaten before this test touched it -- a stale save leaked in" % trainer_id)
		return
	var before_local := _local_entry(objective_id, progression)
	if before_local.get("present", false):
		_fail("%s: the Local Request is visible in the log before the trainer was ever met" % trainer_id)

	if _selected_activities.is_empty():
		await _play(challenge_conversation)
	else:
		if not await _activate_trainer_prompt(body, trainer_id):
			return
		var challenge_guard := 0
		while bool(_panel.call("is_open")) \
				and not bool(_director.call("trainer_battle_active")) \
				and challenge_guard < 24:
			await _press("interact")
			challenge_guard += 1
		if challenge_guard >= 24:
			_fail("%s: parsed challenge did not reach its battle effect" % trainer_id)
			return

	if not bool(progression.call("has", met_flag)):
		_fail("%s: talking to them did not set '%s'" % [trainer_id, met_flag])

	for i in 6:
		await physics_frame
	if not bool(_director.call("trainer_battle_active")):
		_fail("%s: the challenge conversation's battle: line did not start a real fight" % trainer_id)
		return

	await _fight(trainer_id)

	if not bool(progression.call("has", defeat_flag)):
		_fail("%s: fought to the end but '%s' was never set" % [trainer_id, defeat_flag])
		return
	for item_id: String in expected_reward:
		var expected_delta := int(expected_reward[item_id])
		var actual_delta := int(_inventory().call("count", item_id)) - int(reward_before[item_id])
		if actual_delta != expected_delta:
			_fail("%s: expected reward %s +%d, got %+d" % [
				trainer_id, item_id, expected_delta, actual_delta])

	var after_local := _local_entry(objective_id, progression)
	if not after_local.get("present", false):
		_fail("%s: beaten, but the Local Request '%s' never appeared in quest_log's local list" % [
			trainer_id, objective_id])
	elif completes_objective and not bool(after_local.get("done", false)):
		_fail("%s: the Local Request '%s' is in the log but does not read done" % [trainer_id, objective_id])
	elif not completes_objective and bool(after_local.get("done", false)):
		_fail("%s: the win alone completed '%s', which needs a further step" % [trainer_id, objective_id])


## Same HP-floor allowance smoke_boss.gd/smoke_trainer_battle.gd make: this is
## about wiring, not balance, so the opponent's HP is pulled low and the ally's
## is kept topped up. Every send-out, faint and payout still runs through the
## real code.
func _fight(trainer_id: String) -> void:
	var frames := 0
	_manager.connect("attack_missed", _on_fight_attack_missed)
	_manager.connect("hit_landed", _on_fight_hit_landed)
	while bool(_director.call("trainer_battle_active")) and frames < BATTLE_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			await physics_frame
			continue

		var mine: RefCounted = _manager.call("active_creature")
		if mine != null:
			mine.hp = mine.max_hp

		var opponent := _world.find_child("TrainerCreature_%s_*" % trainer_id, true, false) as Node3D
		var ally: Node3D = _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			await physics_frame
			continue
		var theirs: RefCounted = opponent.get("instance")
		if theirs != null and theirs.hp > 6.0:
			theirs.hp = 6.0

		var to := opponent.global_position - ally.global_position
		to.y = 0.0
		var rig := _world.get_node_or_null(^"CameraRig") as Node3D
		if rig != null:
			rig.set("yaw", atan2(-to.x, -to.z))

		var reach := _floored_quick_range(ally, opponent)
		if to.length() > reach:
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
			if _consecutive_misses >= CONSECUTIVE_MISS_LIMIT:
				_fail("%s: the player's quick attack whiffed %d times in a row" % [
					trainer_id, _consecutive_misses])
				return
		else:
			await physics_frame

	if _manager.is_connected("attack_missed", _on_fight_attack_missed):
		_manager.disconnect("attack_missed", _on_fight_attack_missed)
	if _manager.is_connected("hit_landed", _on_fight_hit_landed):
		_manager.disconnect("hit_landed", _on_fight_hit_landed)

	if bool(_director.call("trainer_battle_active")):
		_fail("%s: the fight never resolved inside %d frames (%d landed, %d missed)" % [
			trainer_id, BATTLE_FRAME_LIMIT, _quick_hits, _quick_misses])


func _on_fight_attack_missed(by_player: bool) -> void:
	if not by_player:
		return
	_quick_misses += 1
	_consecutive_misses += 1


func _on_fight_hit_landed(on_enemy: bool, _amount: float) -> void:
	if not on_enemy:
		return
	_quick_hits += 1
	_consecutive_misses = 0


func _floored_quick_range(ally: Node3D, opponent: Node3D) -> float:
	var base := float(MATH.config().get("player_quick", {}).get("range", 2.6))
	var mine := 0.5
	var theirs := 0.5
	if ally != null and ally.has_method("body_radius"):
		mine = float(ally.call("body_radius"))
	if opponent != null and opponent.has_method("body_radius"):
		theirs = float(opponent.call("body_radius"))
	var clearance := float(MATH.config().get("enemy", {}).get("body_clearance", 1.8))
	return maxf(base, (mine + theirs) * clearance + 0.5)


## --- Meadowhart Herd: reveal, physical companion visit, durable reward -------

func _meadowhart_herd() -> void:
	var villagers := _world.get_node_or_null(^"VillageNPCs")
	if villagers == null:
		_fail("meadowhart_herd: no 'VillageNPCs' node in the world")
		return
	var rae := villagers.get_node_or_null(NodePath("Rae")) as Node3D
	if rae == null or not is_instance_valid(rae):
		_fail("meadowhart_herd: Rae is not placed anywhere in the real world")
		return

	var progression := _progression()
	var inventory := _inventory()
	var party: RefCounted = _game.get("party")
	var map: RefCounted = _game.get("map")
	var visit := _world.get_node_or_null(^"MeadowhartHerdVisit") as Node3D
	if visit == null or not is_instance_valid(visit):
		_fail("meadowhart_herd: the physical herd visit is not mounted in the real world")
		return
	if bool(progression.call("has", "band1_meadowhart_herd_found")):
		_fail("meadowhart_herd: already found before this test touched it")
		return
	var before_local := _local_entry("band1_meadowhart_herd", progression)
	if before_local.get("present", false):
		_fail("meadowhart_herd: visible in the log before Rae was ever met")

	var orbs_before := int(inventory.call("count", "orb_basic"))
	var landmark_id := "meadowhart_grazing_ground"
	if map == null or bool(map.call("is_landmark_discovered", landmark_id)):
		_fail("meadowhart_herd: personal grazing-ground landmark began discovered")
		return
	var counters_before: Array[int] = []
	for member: RefCounted in party.call("members"):
		counters_before.append(int(member.get("landmarks_visited_together")))
	var ally := _director.call("ally_body") as Node3D
	if ally == null:
		_fail("meadowhart_herd: no active companion can make the visit")
		return
	_player.global_position = visit.global_position + Vector3(2.0, 1.0, 0.0)
	ally.global_position = visit.global_position + Vector3(20.0, 1.0, 0.0)
	visit.call("_on_activated")
	if bool(progression.call("has", "band1_meadowhart_herd_found")):
		_fail("meadowhart_herd: the visit completed while the companion was outside 12m")
	if bool(progression.call("has", "band1_meadowhart_herd_met")):
		_fail("meadowhart_herd: reaching the site alone revealed a companion visit")
	if bool(map.call("is_landmark_discovered", landmark_id)):
		_fail("meadowhart_herd: reaching the site without the companion discovered the landmark")

	# Rae supplies directions and the saddle lead, but only the physical visit
	# may discover the landmark or move a bond counter.
	await _play("meadowhart_herd_sighting")
	ally = _director.call("ally_body") as Node3D
	if ally == null or not is_instance_valid(ally):
		_fail("meadowhart_herd: deployed companion did not reconcile after Rae's dialogue")
		return
	if bool(progression.call("has", "band1_meadowhart_herd_found")):
		_fail("meadowhart_herd: Rae's greeting still completes the herd visit")
	if bool(map.call("is_landmark_discovered", landmark_id)):
		_fail("meadowhart_herd: Rae's directions discovered the grazing ground")
	for i in counters_before.size():
		if int((party.call("members") as Array)[i].get("landmarks_visited_together")) != counters_before[i]:
			_fail("meadowhart_herd: Rae's directions granted bond progress")
	if int(inventory.call("count", "orb_basic")) != orbs_before:
		_fail("meadowhart_herd: Rae's greeting still pays the herd reward")

	# A full satchel cannot suppress the personal landmark or whole-party bond
	# payoff. It leaves only the independent Orb claim pending.
	var saved_slots: Array = []
	for index in int(inventory.call("slot_count")):
		saved_slots.append(inventory.call("stack_at", index))
		inventory.call("set_slot", index, {"id": "wood", "n": 50})
	var fullbag_orbs := int(inventory.call("count", "orb_basic"))
	ally.global_position = visit.global_position + Vector3(3.0, 1.0, 0.0)
	visit.call("_on_activated")
	if not bool(map.call("is_landmark_discovered", landmark_id)):
		_fail("meadowhart_herd: full-satchel visit did not discover the landmark")
	for i in counters_before.size():
		if int((party.call("members") as Array)[i].get("landmarks_visited_together")) != counters_before[i] + 1:
			_fail("meadowhart_herd: full-satchel discovery did not credit party member %d" % i)
	if bool(progression.call("has", "band1_meadowhart_herd_found")) \
			or int(inventory.call("count", "orb_basic")) != fullbag_orbs:
		_fail("meadowhart_herd: a full satchel consumed completion or reward")
	visit.call("_on_activated")
	for i in counters_before.size():
		if int((party.call("members") as Array)[i].get("landmarks_visited_together")) != counters_before[i] + 1:
			_fail("meadowhart_herd: repeat full-satchel visit double-credited party member %d" % i)
	for index in saved_slots.size():
		var stack: Dictionary = saved_slots[index]
		inventory.call("set_slot", index, null if stack.is_empty() else stack)
	var discovered := _local_entry("band1_meadowhart_herd", progression)
	if not discovered.get("present", false) or bool(discovered.get("done", false)):
		_fail("meadowhart_herd: the unpaid visit should remain an unfinished request")

	# Stage the shape of an old save: completion exists, while the new landmark
	# and its counters do not. Loading that fact grants nothing; revisiting does.
	var legacy_map: Dictionary = map.call("save_data")
	var legacy_landmarks: Array = legacy_map.get("landmarks", []) as Array
	legacy_landmarks.erase(landmark_id)
	legacy_map["landmarks"] = legacy_landmarks
	map.call("load_data", legacy_map)
	for i in counters_before.size():
		(party.call("members") as Array)[i].set("landmarks_visited_together", counters_before[i])
	progression.call("set_flag", "band1_meadowhart_herd_found")
	for i in counters_before.size():
		if int((party.call("members") as Array)[i].get("landmarks_visited_together")) != counters_before[i]:
			_fail("meadowhart_herd: legacy completion granted bond progress on load")
	visit.call("restore_progression_from_game", _game)
	visit.call("_on_activated")
	if not bool(map.call("is_landmark_discovered", landmark_id)):
		_fail("meadowhart_herd: legacy-completed revisit did not discover the landmark")
	for i in counters_before.size():
		if int((party.call("members") as Array)[i].get("landmarks_visited_together")) != counters_before[i] + 1:
			_fail("meadowhart_herd: legacy revisit did not credit party member %d once" % i)
	if int(inventory.call("count", "orb_basic")) != orbs_before:
		_fail("meadowhart_herd: legacy-completed revisit repaid the Orb claim")

	# Clear only the staged old completion fact. The earned discovery and bond
	# remain; the normal prompt can now settle the pending Orb claim.
	progression.call("set_flag", "band1_meadowhart_herd_found", false)
	visit.call("restore_progression_from_game", _game)

	# The successful claim uses the production provider -> arbiter -> parsed
	# interact path, proving the prompt is reachable at its terrain site.
	ally = _director.call("ally_body") as Node3D
	if ally == null or not is_instance_valid(ally):
		_fail("meadowhart_herd: no reconciled companion remained for the ordinary approach")
		return
	if not await _stand_at_herd_prompt(visit, ally):
		return
	await _press("interact")
	for _frame in 12:
		await physics_frame
	if not bool(progression.call("has", "band1_meadowhart_herd_found")):
		_fail("meadowhart_herd: visiting the real herd with a companion did not complete")
	var orbs_after := int(inventory.call("count", "orb_basic"))
	if orbs_after != orbs_before + 3:
		_fail("meadowhart_herd: expected +3 orb_basic, got %d -> %d" % [orbs_before, orbs_after])
	var after_local := _local_entry("band1_meadowhart_herd", progression)
	if not after_local.get("present", false) or not bool(after_local.get("done", false)):
		_fail("meadowhart_herd: the physical visit never reads done in quest_log")

	# Duplicate activation and restoration from an already-complete progression
	# state must not repay.
	visit.call("_on_activated")
	visit.call("restore_progression_from_game", _game)
	if int(inventory.call("count", "orb_basic")) != orbs_after:
		_fail("meadowhart_herd: completed restoration or duplicate activation repaid the reward")
	for i in counters_before.size():
		if int((party.call("members") as Array)[i].get("landmarks_visited_together")) != counters_before[i] + 1:
			_fail("meadowhart_herd: Orb completion double-credited party member %d" % i)

	var ack_guard := 0
	while bool(_panel.call("is_open")) and ack_guard < 16:
		_panel.call("advance")
		await process_frame
		ack_guard += 1
	if bool(_panel.call("is_open")):
		_fail("meadowhart_herd: acknowledgement did not close before the next Local Request")
	if _selected_activities.has("herd"):
		_verify_herd_disk_round_trip(visit, landmark_id)
	await _capture_activity("herd")


func _stand_at_herd_prompt(visit: Node3D, ally: Node3D) -> bool:
	var arbiter := _world.get_node_or_null(^"InteractionArbiter")
	var prompt := visit.get_node_or_null(^"Interactable")
	if arbiter == null or prompt == null:
		_fail("meadowhart_herd: visit has no interaction arbiter/provider")
		return false
	# Fixture staging begins on the authored trail near the herd, rather than at
	# its prompt. From there the production player controller must cover the
	# remaining approach from ordinary movement input, with the companion along.
	var trail := Vector3(-40.0, 0.0, 1310.0)
	await _seat_remote_fixture(trail, ally)
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	var reached := false
	var moving := true
	Input.action_press("move_forward")
	_send("move_forward", true)
	# 900, not 360: the companion follows at its own pace and, seated beside
	# the player after a long preceding leg, was still 12.7 m out at 360.
	for _frame in 900:
		var to := visit.global_position - _player.global_position
		to.y = 0.0
		if rig != null and to.length_squared() > 0.01:
			rig.set("yaw", atan2(-to.x, -to.z))
		await physics_frame
		await process_frame
		# Keep walking in to 6 m even once the prompt wins (~11 m out): the
		# companion trails the player by ~1.5 m and must also be within 12 m.
		if moving and to.length() <= 6.0:
			Input.action_release("move_forward")
			_send("move_forward", false)
			moving = false
		var live_ally := _director.call("ally_body") as Node3D
		if live_ally != null and is_instance_valid(live_ally) \
				and _player.global_position.distance_to(visit.global_position) <= 12.0 \
				and live_ally.global_position.distance_to(visit.global_position) <= 12.0 \
				and arbiter.call("winning_provider") == prompt:
			reached = true
			ally = live_ally
			break
	Input.action_release("move_forward")
	_send("move_forward", false)
	if not reached:
		var live_ally := _director.call("ally_body") as Node3D
		_fail("meadowhart_herd: trail approach did not gather player+companion at prompt (player %.1fm, ally %.1fm)" % [
			_player.global_position.distance_to(visit.global_position),
			live_ally.global_position.distance_to(visit.global_position) \
				if live_ally != null and is_instance_valid(live_ally) else -1.0])
		return false
	if rig != null:
		# Leave the optional witness on a normal three-quarter shoulder instead
		# of directly behind the companion that just caught up to the player.
		rig.set("yaw", float(rig.get("yaw")) + deg_to_rad(30.0))
	var owner := INPUT_OWNER.current(self)
	var original_winner: Variant = arbiter.call("winning_provider")
	print("meadowhart_herd original stance: paused=%s arbiter_enabled=%s input_owner=%s winner=%s herd_prompt=%s prompt_enabled=%s" % [
		str(paused), str(arbiter.call("enabled")),
		str(owner.get_path()) if owner != null else "none",
		str((original_winner as Node).get_path()) if original_winner is Node else str(original_winner),
		str(prompt.get_path()), str(prompt.get("enabled"))])
	if owner != null:
		_fail("meadowhart_herd: parsed interact is blocked by input owner %s" % owner.get_path())
		return false
	if paused or not bool(arbiter.call("enabled")) or original_winner != prompt:
		_fail("meadowhart_herd: the real herd prompt is not eligible for parsed interact")
		return false
	return true


func _activate_trainer_prompt(body: Node3D, label: String) -> bool:
	var arbiter := _world.get_node_or_null(^"InteractionArbiter")
	var prompt := body.get_node_or_null(^"Interactable")
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	if arbiter == null or prompt == null:
		_fail("%s: trainer has no interaction arbiter/provider" % label)
		return false
	var offsets: Array[Vector3] = [Vector3(0.0, 0.0, 2.4), Vector3(2.4, 0.0, 0.0),
		Vector3(0.0, 0.0, -2.4), Vector3(-2.4, 0.0, 0.0)]
	for offset: Vector3 in offsets:
		var at: Vector3 = body.global_position + offset
		await _seat_remote_fixture(at, _director.call("ally_body") as Node3D)
		var to: Vector3 = body.global_position - at
		to.y = 0.0
		if rig != null and to.length_squared() > 0.01:
			rig.set("yaw", atan2(-to.x, -to.z))
		for _frame in 120:
			await physics_frame
			await process_frame
			if arbiter.call("winning_provider") == prompt and INPUT_OWNER.current(self) == null:
				await _press("interact")
				if bool(_panel.call("is_open")):
					return true
	var winner: Variant = arbiter.call("winning_provider")
	var owner := INPUT_OWNER.current(self)
	if label.begins_with("river_nest"):
		await _capture_activity("doss-prompt-failed")
	var runner: RefCounted = _panel.call("runner") as RefCounted if _panel != null else null
	_fail("%s: exact prompt never became actionable at player=%s winner=%s input_owner=%s open=%s conversation=%s line=%s started=%s" % [
		label, str(_player.global_position),
		str((winner as Node).get_path()) if winner is Node else str(winner),
		str(owner.get_path()) if owner != null else "none",
		str(_panel.call("is_open")) if _panel != null else "?",
		str(runner.call("conversation_id")) if runner != null else "?",
		str(runner.call("line")) if runner != null else "?",
		str(_conversation_log)])
	return false


func _seat_remote_fixture(at_xz: Vector3, ally: Node3D) -> void:
	var player_at := at_xz
	player_at.y = float(_world.call("ground_height_at", player_at.x, player_at.z)) + 1.0
	var ally_at := player_at + Vector3(1.5, 0.0, 0.0)
	ally_at.y = float(_world.call("ground_height_at", ally_at.x, ally_at.z)) + 1.0
	var rig := _world.get_node_or_null(^"CameraRig") as Node3D
	var player_processing := _player.is_physics_processing()
	var ally_body := ally as CharacterBody3D
	var ally_processing := ally_body.is_physics_processing() if ally_body != null else false
	_player.set_physics_process(false)
	_player.velocity = Vector3.ZERO
	_player.global_position = player_at
	_player.reset_physics_interpolation()
	if ally_body != null:
		ally_body.set_physics_process(false)
		ally_body.velocity = Vector3.ZERO
		ally_body.global_position = ally_at
		ally_body.reset_physics_interpolation()
	if rig != null:
		rig.global_position = player_at
		rig.reset_physics_interpolation()
	for _frame in 40:
		await physics_frame
	# Do not let go until there is GROUND under the seat. A fixed 40 frames was
	# a guess about terrain collision streaming, and anything that delays
	# streaming -- measured: two reward-delivery character saves earlier in the
	# run -- let the player drop straight through at exactly this seat,
	# "fell below the world at -40, -133, 1310 -- returning to spawn". A real
	# player walks here continuously, so collision streams ahead of them; only
	# a teleport can arrive before it. Bounded, and reported if it never lands.
	await _wait_for_ground_under(player_at, 600)
	_player.set_physics_process(player_processing)
	if ally_body != null:
		ally_body.set_physics_process(ally_processing)
	for _frame in 40:
		await physics_frame


func _verify_juno_disk_round_trip(reunion: Node) -> void:
	var party: RefCounted = _game.get("party")
	var expected_ids: Array[String] = []
	for member: RefCounted in party.call("members"):
		expected_ids.append(str(member.get("uid")))
	if expected_ids.size() != 5 or expected_ids.has(""):
		_fail("lost_creature: disk fixture lacks five durable owned identities")
		return
	var inventory := _inventory()
	var coins := int(inventory.call("count", "coin"))
	var revives := int(inventory.call("count", "revive"))
	var saver := SAVE_GAME.new("user://smoke_local_requests_activities/")
	if not bool(saver.call("save", _game, 4)):
		_fail("lost_creature: production save writer refused the activity slot")
		return
	_progression().call("set_flag", RETURN_FLAG, false)
	if not bool(saver.call("load_slot", _game, 4)):
		_fail("lost_creature: production save reader refused the activity slot")
		return
	var loaded_ids: Array[String] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		loaded_ids.append(str(member.get("uid")))
	if loaded_ids != expected_ids:
		_fail("lost_creature: disk reload did not preserve the five owned identities")
	if not bool(_progression().call("has", RETURN_FLAG)):
		_fail("lost_creature: disk reload lost the completed return")
	if int((_game.get("inventory") as RefCounted).call("count", "coin")) != coins:
		_fail("lost_creature: disk reload repaid or lost the completed rescue reward")
	if int((_game.get("inventory") as RefCounted).call("count", "revive")) != revives:
		_fail("lost_creature: disk reload repaid or lost the completed rescue item")
	reunion.call("restore_progression_from_game", _game)
	if int((_game.get("inventory") as RefCounted).call("count", "coin")) != coins \
			or int((_game.get("inventory") as RefCounted).call("count", "revive")) != revives:
		_fail("lost_creature: reunion restoration after disk reload repaid the reward")
	if not bool(reunion.call("is_reunited")):
		_fail("lost_creature: disk reload did not keep the reunion")


func _verify_bram_disk_round_trip() -> void:
	var expected_ids: Array[String] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		expected_ids.append(str(member.get("uid")))
	if expected_ids.size() != 5 or expected_ids.has(""):
		_fail("old_champion_bram: disk fixture lacks five durable owned identities")
		return
	var expected_reward := {
		"coin": int(_inventory().call("count", "coin")),
		"orb_greater": int(_inventory().call("count", "orb_greater")),
		"potion_small": int(_inventory().call("count", "potion_small")),
	}
	var saver := SAVE_GAME.new("user://smoke_local_requests_activities/")
	if not bool(saver.call("save", _game, 4)):
		_fail("old_champion_bram: production save writer refused the activity slot")
		return
	_progression().call("set_flag", "defeated_old_bram", false)
	if not bool(saver.call("load_slot", _game, 4)):
		_fail("old_champion_bram: production save reader refused the activity slot")
		return
	var loaded_ids: Array[String] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		loaded_ids.append(str(member.get("uid")))
	if loaded_ids != expected_ids:
		_fail("old_champion_bram: disk reload did not preserve the five owned identities")
	if not bool(_progression().call("has", "defeated_old_bram")):
		_fail("old_champion_bram: disk reload lost the completed battle")
	for item_id: String in expected_reward:
		if int((_game.get("inventory") as RefCounted).call("count", item_id)) != int(expected_reward[item_id]):
			_fail("old_champion_bram: disk reload repaid or lost %s" % item_id)


func _verify_herd_disk_round_trip(visit: Node3D, landmark_id: String) -> void:
	var party: RefCounted = _game.get("party")
	var expected: Array[int] = []
	for member: RefCounted in party.call("members"):
		expected.append(int(member.get("landmarks_visited_together")))
	var saver := SAVE_GAME.new("user://smoke_local_requests_herd/")
	if not bool(saver.call("save", _game, 4)):
		_fail("meadowhart_herd: production save writer refused the herd-only slot")
		return

	# Destroy both durable facts in memory so only the disk load can restore them.
	var map: RefCounted = _game.get("map")
	var map_data: Dictionary = map.call("save_data")
	var landmarks: Array = map_data.get("landmarks", []) as Array
	landmarks.erase(landmark_id)
	map_data["landmarks"] = landmarks
	map.call("load_data", map_data)
	for member: RefCounted in party.call("members"):
		member.set("landmarks_visited_together", 0)
	if bool(map.call("is_landmark_discovered", landmark_id)):
		_fail("meadowhart_herd: disk proof did not actually clear the landmark before load")
	for member: RefCounted in party.call("members"):
		if int(member.get("landmarks_visited_together")) != 0:
			_fail("meadowhart_herd: disk proof did not actually clear a bond counter before load")
	if not bool(saver.call("load_slot", _game, 4)):
		_fail("meadowhart_herd: production save reader refused the herd-only slot")
		return
	if not bool((_game.get("map") as RefCounted).call("is_landmark_discovered", landmark_id)):
		_fail("meadowhart_herd: disk reload lost the personal grazing-ground landmark")
	var loaded_members: Array = (_game.get("party") as RefCounted).call("members")
	if loaded_members.size() != expected.size():
		_fail("meadowhart_herd: disk reload changed the owned team size")
		return
	for i in expected.size():
		if int((loaded_members[i] as RefCounted).get("landmarks_visited_together")) != expected[i]:
			_fail("meadowhart_herd: disk reload lost bond counter for party member %d" % i)
	visit.call("restore_progression_from_game", _game)
	visit.call("_on_activated")
	for i in expected.size():
		if int((loaded_members[i] as RefCounted).get("landmarks_visited_together")) != expected[i]:
			_fail("meadowhart_herd: repeat activation after disk reload credited party member %d" % i)


## --- River Nest: the real item_gate contract, on a gather-and-give NPC -------

func _river_nest_activity() -> void:
	var doss := _world.get_node_or_null(^"RiverNestClear")
	if doss == null or not is_instance_valid(doss):
		_fail("river_nest: not placed anywhere in the real world")
		return
	var body := doss.get_node_or_null(^"Doss") as Node3D
	var perch := doss.get_node_or_null(^"BankPerch") as Node3D
	var floor := doss.get_node_or_null(^"BankPerch/RepairedPerchFloor/CollisionShape3D") as CollisionShape3D
	if body == null or perch == null or floor == null:
		_fail("river_nest: missing production nodes body=%s perch=%s floor=%s" % [
			str(body != null), str(perch != null), str(floor != null)])
		return
	var inventory := _inventory()
	var coins_before := int(inventory.call("count", "coin"))
	var potions_before := int(inventory.call("count", "potion_large"))
	var wood_before := int(inventory.call("count", "wood"))
	var fiber_before := int(inventory.call("count", "fiber"))
	inventory.call("add", "wood", 1)
	inventory.call("add", "fiber", 1)
	if not await _activate_trainer_prompt(body, "river_nest"):
		return
	await _close_parsed_acknowledgement("river_nest")
	if not bool(doss.call("is_cleared")):
		var local: Variant = _game.get("local")
		var world: Variant = _game.get("world")
		_fail("river_nest: parsed interaction did not clear the bank perch; actor=%s character=%s realm=%s world=%s" % [
			str(_player.global_position),
			str((local as RefCounted).get("character_id")) if local != null else "",
			str(_game.get("current_realm")),
			str((world as RefCounted).get("world_id")) if world != null else "",
		])
		return
	if int(inventory.call("count", "wood")) != wood_before \
			or int(inventory.call("count", "fiber")) != fiber_before:
		_fail("river_nest: parsed repair did not consume its one wood and fiber")
	if int(inventory.call("count", "coin")) != coins_before + 45 \
			or int(inventory.call("count", "potion_large")) != potions_before + 1:
		_fail("river_nest: parsed repair did not pay its authored reward once")
	if not bool(perch.get_meta("repaired", false)) or floor.disabled:
		_fail("river_nest: cleared state did not install the repaired visible/colliding BankPerch")
	for child in perch.get_children():
		var part := child as Node3D
		if part != null and not part is StaticBody3D and absf(part.rotation.z) > 0.001:
			_fail("river_nest: a repaired BankPerch part retained its broken roll")

	# A second ordinary greeting is acknowledgement only: it stays available,
	# shows the completed conversation and cannot spend or pay again.
	if not await _activate_trainer_prompt(body, "river_nest repeat"):
		return
	await _capture_activity("doss")
	await _close_parsed_acknowledgement("river_nest repeat")
	if int(inventory.call("count", "coin")) != coins_before + 45 \
			or int(inventory.call("count", "potion_large")) != potions_before + 1:
		_fail("river_nest: repeat acknowledgement repaid the reward")
	await _verify_doss_disk_round_trip(doss, perch, floor)


func _verify_doss_disk_round_trip(doss: Node, perch: Node3D, floor: CollisionShape3D) -> void:
	var expected_ids: Array[String] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		expected_ids.append(str(member.get("uid")))
	if expected_ids.size() != 5 or expected_ids.has(""):
		_fail("river_nest: disk fixture lacks five durable owned identities")
		return
	var inventory := _inventory()
	var coins := int(inventory.call("count", "coin"))
	var potions := int(inventory.call("count", "potion_large"))
	var saver := SAVE_GAME.new("user://smoke_local_requests_activities/")
	if not bool(saver.call("save", _game, 4)):
		_fail("river_nest: production save writer refused the activity slot")
		return
	if not bool(saver.call("load_slot", _game, 4)):
		_fail("river_nest: production save reader refused the activity slot")
		return
	var loaded_ids: Array[String] = []
	for member: RefCounted in (_game.get("party") as RefCounted).call("members"):
		loaded_ids.append(str(member.get("uid")))
	if loaded_ids != expected_ids:
		_fail("river_nest: disk reload did not preserve the five owned identities")
	doss.call("restore_progression_from_game", _game)
	if not bool(doss.call("is_cleared")) or not bool(perch.get_meta("repaired", false)) or floor.disabled:
		_fail("river_nest: disk reload did not restore the repaired BankPerch")
	if int((_game.get("inventory") as RefCounted).call("count", "coin")) != coins \
			or int((_game.get("inventory") as RefCounted).call("count", "potion_large")) != potions:
		_fail("river_nest: disk reload or visible restoration repaid the reward")

func _river_nest() -> void:
	var doss := _world.get_node_or_null(^"RiverNestClear")
	if doss == null or not is_instance_valid(doss):
		_fail("river_nest: not placed anywhere in the real world")
		return
	var body := doss.get_node_or_null(^"Doss") as Node3D
	if body == null:
		_fail("river_nest: Doss has no production body")
		return

	var progression := _progression()
	var inventory := _inventory()
	if bool(progression.call("has", "river_nest_doss_cleared")):
		_fail("river_nest: already cleared before this test touched it")
		return

	# Empty-handed: the real gate must refuse, but the meeting must still be
	# recorded so the Local Request is revealed in the log.
	if not await _activate_trainer_prompt(body, "river_nest empty"):
		return
	await _close_parsed_acknowledgement("river_nest empty")
	if not bool(progression.call("has", "river_nest_doss_met")):
		_fail("river_nest: greeting Doss empty-handed did not set 'river_nest_doss_met'")
	if bool(progression.call("has", "river_nest_doss_cleared")):
		_fail("river_nest: the gate opened with no materials handed over at all")
	var after_meeting := _local_entry("band3_river_nest", progression)
	if not after_meeting.get("present", false):
		_fail("river_nest: the Local Request never appeared in the log after the first greeting")
	elif bool(after_meeting.get("done", false)):
		_fail("river_nest: the Local Request reads done before any material was handed over")

	# Now the real gather verb and the real reward payout.
	var coins_before := int(inventory.call("count", "coin"))
	var potions_before := int(inventory.call("count", "potion_large"))
	var wood_before := int(inventory.call("count", "wood"))
	var fiber_before := int(inventory.call("count", "fiber"))
	inventory.call("add", "wood", 1)
	inventory.call("add", "fiber", 1)

	if not await _activate_trainer_prompt(body, "river_nest paid"):
		return
	await _close_parsed_acknowledgement("river_nest paid")

	if not bool(progression.call("has", "river_nest_doss_cleared")):
		_fail("river_nest: handed over wood/fiber and the gate still did not open")
		return
	if int(inventory.call("count", "wood")) != wood_before or \
			int(inventory.call("count", "fiber")) != fiber_before:
		_fail("river_nest: the gate opened but did not consume exactly what was handed over")
	if int(inventory.call("count", "coin")) != coins_before + 45:
		_fail("river_nest: expected +45 coin, got %d -> %d" % [
			coins_before, int(inventory.call("count", "coin"))])
	if int(inventory.call("count", "potion_large")) != potions_before + 1:
		_fail("river_nest: expected +1 potion_large, got %d -> %d" % [
			potions_before, int(inventory.call("count", "potion_large"))])

	var after_clear := _local_entry("band3_river_nest", progression)
	if not after_clear.get("present", false) or not bool(after_clear.get("done", false)):
		_fail("river_nest: the Local Request never reads done in quest_log after clearing it")


## --- Broken Cart: the real item_gate contract, empty-handed then paid -------

func _broken_cart() -> void:
	var cart := _world.get_node_or_null(^"BrokenCart")
	if cart == null or not is_instance_valid(cart):
		_fail("broken_cart: not placed anywhere in the real world")
		return

	var progression := _progression()
	var inventory := _inventory()
	if bool(progression.call("has", "band1_broken_cart_repaired")):
		_fail("broken_cart: already repaired before this test touched it")
		return
	var assembly := cart.get_node_or_null(^"WagonAssembly") as Node3D
	var wagon := cart.get_node_or_null(^"WagonAssembly/Wagon") as Node3D
	var collision := cart.get_node_or_null(^"WagonAssembly/Collision") as StaticBody3D
	if assembly == null or wagon == null or collision == null:
		_fail("broken_cart: visual and collision are not one movable wagon assembly")
		return
	if absf(rad_to_deg(wagon.rotation.z) - 11.0) > 0.1:
		_fail("broken_cart: source wagon does not begin with a readable broken lean")

	# Empty-handed: the real gate must refuse, but the meeting must still be
	# recorded so the Local Request is revealed in the log.
	cart.call("_on_tried")
	if not bool(progression.call("has", "broken_cart_met")):
		_fail("broken_cart: looking at it empty-handed did not set 'broken_cart_met'")
	if bool(progression.call("has", "band1_broken_cart_repaired")):
		_fail("broken_cart: the gate opened with no materials handed over at all")
	var after_meeting := _local_entry("band1_broken_cart", progression)
	if not after_meeting.get("present", false):
		_fail("broken_cart: the Local Request never appeared in the log after the first look")
	elif bool(after_meeting.get("done", false)):
		_fail("broken_cart: the Local Request reads done before any material was handed over")

	# Now the real gather verb: real materials in the real satchel.
	var wood_before := int(inventory.call("count", "wood"))
	var stone_before := int(inventory.call("count", "stone"))
	var fiber_before := int(inventory.call("count", "fiber"))
	var coins_before := int(inventory.call("count", "coin"))
	inventory.call("add", "wood", 1)
	inventory.call("add", "stone", 1)
	inventory.call("add", "fiber", 1)

	cart.call("_on_tried")

	if not bool(progression.call("has", "band1_broken_cart_repaired")):
		_fail("broken_cart: handed over wood/stone/fiber and the gate still did not open")
		return
	if int(inventory.call("count", "wood")) != wood_before or \
			int(inventory.call("count", "stone")) != stone_before or \
			int(inventory.call("count", "fiber")) != fiber_before:
		_fail("broken_cart: the gate opened but did not consume exactly what was handed over")
	# Coll pays back. Through the real reward_grant path, not asserted from a
	# constant alone: the coins must actually be in the satchel.
	var thanks := int(preload("res://scripts/world/cart_repair.gd").REWARD_COINS)
	for i in 30:
		if int(inventory.call("count", "coin")) >= coins_before + thanks:
			break
		await process_frame
	if int(inventory.call("count", "coin")) != coins_before + thanks:
		_fail("broken_cart: repaired, but Coll's %d coins never arrived (had %d, now %d)"
			% [thanks, coins_before, int(inventory.call("count", "coin"))])

	# The committed delta owns the terminal pose. Let the short visible
	# straighten/roll finish, then verify
	# the solid cart moved with its mesh and the installed repair parts appeared.
	if not await _wait_for_cart_pose(assembly, wagon):
		_fail("broken_cart: repair pose did not settle before its bounded timer")
	if assembly.position.distance_to(Vector3(-0.9, assembly.position.y, 2.3)) > 0.08:
		_fail("broken_cart: repaired wagon did not roll to its shoulder parking pose")
	if absf(rad_to_deg(assembly.rotation.y) + 25.0) > 0.1:
		_fail("broken_cart: repaired wagon did not turn to its three-quarter parking pose")
	if absf(wagon.rotation.z) > 0.01 or absf(wagon.position.y) > 0.02:
		_fail("broken_cart: repaired wagon remained tipped or lifted")
	var patch := cart.get_node_or_null(^"WagonAssembly/Wagon/RepairPatch") as Node3D
	var chocks := cart.get_node_or_null(^"RepairChocks") as Node3D
	if patch == null or not patch.visible or chocks == null or not chocks.visible:
		_fail("broken_cart: completed repair has no visible patch/lashing/chock payoff")
	if collision.get_parent() != assembly:
		_fail("broken_cart: collision did not remain attached to the moving wagon assembly")

	# Rebuild the visible state through the public progression-restore seam. It
	# must land directly at the same terminal pose without replaying the local
	# repair animation; broader save/reconnect acceptance lives in net coverage.
	var terminal_position := assembly.position
	var terminal_yaw := assembly.rotation.y
	assembly.position = Vector3.ZERO
	assembly.rotation.y = 0.0
	wagon.position.y = 0.19
	wagon.rotation.z = deg_to_rad(11.0)
	patch.visible = false
	chocks.visible = false
	cart.call("restore_progression_from_game", root.get_node_or_null(^"Game"))
	if assembly.position.distance_to(terminal_position) > 0.01 \
			or absf(assembly.rotation.y - terminal_yaw) > 0.001 \
			or absf(wagon.rotation.z) > 0.001 or absf(wagon.position.y) > 0.001:
		_fail("broken_cart: progression restore did not apply the repaired terminal pose")
	if not patch.visible or not chocks.visible:
		_fail("broken_cart: progression restore lost the visible repair parts")
	var prompt := cart.get_node_or_null(^"Interactable")
	if prompt == null or bool(prompt.get("enabled")):
		_fail("broken_cart: repaired progression restore still offers the repair prompt")

	var after_repair := _local_entry("band1_broken_cart", progression)
	if not after_repair.get("present", false) or not bool(after_repair.get("done", false)):
		_fail("broken_cart: the Local Request never reads done in quest_log after the repair")


func _wait_for_cart_pose(assembly: Node3D, wagon: Node3D) -> bool:
	var deadline := create_timer(2.5)
	while deadline.time_left > 0.0:
		if Vector2(assembly.position.x, assembly.position.z).distance_to(Vector2(-0.9, 2.3)) <= 0.08 \
				and absf(rad_to_deg(assembly.rotation.y) + 25.0) <= 0.1 \
				and absf(wagon.rotation.z) <= 0.01 and absf(wagon.position.y) <= 0.02:
			return true
		await process_frame
	return false


## --- shared -------------------------------------------------------------------

func _panel_awaiting_confirmation() -> bool:
	var runner: Variant = _panel.get("_runner") if _panel != null else null
	if not runner is Object or not (runner as Object).has_method("line"):
		return false
	var line: Variant = (runner as Object).call("line")
	return line is Dictionary and bool((line as Dictionary).get("confirmation", false))

func _close_parsed_acknowledgement(label: String) -> void:
	var guard := 0
	while bool(_panel.call("is_open")) and guard < 24:
		await _press("interact")
		guard += 1
	if bool(_panel.call("is_open")):
		_fail("%s: parsed-input acknowledgement did not close" % label)


func _capture_activity(label: String) -> void:
	if _capture_dir.is_empty():
		return
	for _frame in 3:
		await process_frame
	var directory := ProjectSettings.globalize_path(_capture_dir)
	var directory_error := DirAccess.make_dir_recursive_absolute(directory)
	if directory_error != OK:
		_fail("%s: could not create capture directory (%s)" % [label, error_string(directory_error)])
		return
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("%s: active viewport produced no screenshot" % label)
		return
	var output := directory.path_join("local-activity-%s.png" % label)
	var error := image.save_png(output)
	if error != OK:
		_fail("%s: could not save active-camera screenshot to %s (%s)" % [
			label, output, error_string(error)])

## Play a conversation to the end on the shared panel, exactly the way
## smoke_village_smith.gd does -- one line per pass, an idle frame between
## each so the director's per-frame drain actually runs.
func _play(conversation_id: String) -> void:
	if not bool(_panel.call("start", conversation_id)):
		_fail("the dialogue panel refused to start '%s'" % conversation_id)
		return
	var guard := 0
	while bool(_panel.call("is_open")) and guard < 64:
		await process_frame
		_panel.call("advance")
		guard += 1
	await process_frame
	await process_frame
	if guard >= 64:
		_fail("'%s' never closed" % conversation_id)


const OBJECTIVES_PATH := "res://data/progression/objectives.json"
var _objective_labels: Dictionary = {}


## `quest_log.gd::local_entries()` returns `{label, done, how}` -- no `id` --
## so this resolves the objective's own authored label once (straight from
## objectives.json, never restated) and matches the real reader's output
## against it, which is the same "id" a test can hold onto without inventing
## a second copy of the label text.
func _objective_label(objective_id: String) -> String:
	if _objective_labels.is_empty():
		var file := FileAccess.open(OBJECTIVES_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				for raw: Variant in ((parsed as Dictionary).get("local", []) as Array):
					var entry := raw as Dictionary
					_objective_labels[str(entry.get("id", ""))] = str(entry.get("label", ""))
	return str(_objective_labels.get(objective_id, ""))


## The Local Request as quest_log.gd's own reader sees it right now -- never a
## restatement of its `revealed_by`/completion rules, the real reader asked.
func _local_entry(objective_id: String, progression: RefCounted) -> Dictionary:
	var label := _objective_label(objective_id)
	if label.is_empty():
		_fail("objectives.json's local array has no entry with id '%s'" % objective_id)
		return {"present": false, "done": false}
	for raw: Variant in _log.local_entries(progression):
		var entry := raw as Dictionary
		if str(entry.get("label", "")) == label:
			return {"present": true, "done": bool(entry.get("done", false))}
	return {"present": false, "done": false}


func _press(action: String) -> void:
	# ONE input path. Pairing Input.action_press() with a parsed
	# InputEventAction produced two "just pressed" edges on different frames
	# for a single press -- the parsed event is flushed a frame or more later.
	# When the first edge dismissed Doss's thanks, the late second edge could
	# land after the release and greet him again (the repeat-greeting flake:
	# the same conversation reopened on line 0 with no press from this smoke).
	_send(action, true)
	await physics_frame
	await physics_frame
	_send(action, false)
	for i in 4:
		await physics_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("selected local activities smoke test passed: %s" % ",".join(_selected_activities) \
			if not _selected_activities.is_empty() else "local requests smoke test passed")
		quit(0)
	else:
		for line in _failures:
			print("smoke FAIL: %s" % line)
		quit(1)


## Wait until a downward ray from above `at` hits physical collision, so a
## seated body has something to stand on before physics resumes. Returns
## whether it did within `max_frames`.
func _wait_for_ground_under(at: Vector3, max_frames: int) -> bool:
	var space := _player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 30.0, at + Vector3.DOWN * 60.0)
	query.exclude = [_player.get_rid()]
	# Any hit is not enough: Terrain3D builds collision only around the camera,
	# and after a long leg (the Juno return ends ~4 km away) a scatter or prop
	# collider can answer the ray while the terrain surface itself is not there
	# yet -- the herd seat then dropped straight through it. Require a hit at
	# the heightmap's own ground height.
	var ground := float(_world.call("ground_height_at", at.x, at.z))
	for _frame in max_frames:
		var hit := space.intersect_ray(query)
		if not hit.is_empty() and (is_nan(ground) or absf((hit.position as Vector3).y - ground) <= 1.0):
			return true
		await physics_frame
	push_warning("seat at %s never had ground collision under it after %d frames" % [str(at), max_frames])
	return false
