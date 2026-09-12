extends SceneTree

## OWNER-0912: production runtime receipt for the First Ironwood story thread.
##
##   godot --headless --path . --script tests/smoke_ironwood_story_0912.gd
##
## One production Meadows boot drives the real placed Juno and Halder prompts:
## Interactable -> trainer_npc -> DialoguePanel/DialogueRunner -> the production
## trainer battle -> encounter_director's first-time defeat flag and payout.
## The real quest_log reader must reveal the First Ironwood objective after
## Juno, complete it after Halder, and keep it completed after Game save/load.
## Both prompts must then remain retired to their defeated conversations without
## reopening a battle or paying either reward twice.
##
## Deliberate evidence boundary: this is story/wiring acceptance, not route or
## balance acceptance. The real player is repositioned beside each real trainer,
## and each live opponent's HP is lowered to the same smoke-test floor used by
## smoke_local_requests.gd and smoke_trainer_battle.gd. Every conversation line,
## combat send-out/faint, flag, payout, objective transition and save operation
## still runs through production code. This does not prove the long approach,
## First Ironwood visuals, ordinary-difficulty combat, or multiplayer catch-up.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

const SETTLE_FRAMES := 300
const BATTLE_FRAME_LIMIT := 3000
const CONSECUTIVE_MISS_LIMIT := 25
const SAVE_DIR := "user://smoke_ironwood_story_0912/"
const SAVE_SLOT := 0
const APPROACH_OFFSET := Vector3(0.0, 0.0, 1.35)

const OPENING_BYPASS_FLAG := "trainer_defeated_practice"
const OBJECTIVE_ID := "band4_first_ironwood"
const OBJECTIVES_PATH := "res://data/progression/objectives.json"

const JUNO_ID := "pasture_drover_juno"
const JUNO_FLAG := "defeated_pasture_drover_juno"
const JUNO_CHALLENGE := "pasture_drover_juno_challenge"
const JUNO_DEFEATED := "pasture_drover_juno_defeated"

const HALDER_ID := "captain_field"
const HALDER_FLAG := "defeated_captain_field"
const HALDER_CHALLENGE := "captain_field_challenge"
const HALDER_DEFEATED := "captain_field_defeated"

var _failures: Array[String] = []
var _game: Node = null
var _world: Node3D = null
var _player: CharacterBody3D = null
var _trainers: Node = null
var _director: Node = null
var _manager: Node = null
var _panel: CanvasLayer = null
var _rig: Node3D = null
var _log := QUEST_LOG.new()
var _objective_label := ""
var _last_finished := ""
var _consecutive_misses := 0


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	if not _prepare_game() or not await _boot_meadows():
		_report()
		return

	_panel.connect("finished", _on_dialogue_finished)
	_objective_label = _read_objective_label()
	if _objective_label.is_empty():
		_fail("objectives.json has no local objective '%s'" % OBJECTIVE_ID)
		_report()
		return

	var juno := TRAINERS.trainer(JUNO_ID)
	var halder := TRAINERS.trainer(HALDER_ID)
	if juno.is_empty() or halder.is_empty():
		if juno.is_empty():
			_fail("the merged production trainer table has no Juno")
		if halder.is_empty():
			_fail("the merged production trainer table has no Halder")
		_report()
		return

	_reset_story_flags()
	_assert_world_scope(JUNO_FLAG)
	_assert_world_scope(HALDER_FLAG)
	_assert_objective(false, false, "before Juno")

	var baseline := _reward_snapshot([juno, halder])
	if await _challenge_and_win(juno, JUNO_CHALLENGE, JUNO_FLAG):
		_assert_world_flag_landed(JUNO_FLAG)
		_assert_objective(true, false, "after Juno")
		_assert_reward_delta(baseline, _reward_snapshot([juno, halder]), juno, "Juno")
		await _greet_retired(juno, JUNO_DEFEATED)

	var after_juno := _reward_snapshot([juno, halder])
	if await _challenge_and_win(halder, HALDER_CHALLENGE, HALDER_FLAG):
		_assert_world_flag_landed(HALDER_FLAG)
		_assert_objective(true, true, "after Halder")
		_assert_reward_delta(after_juno, _reward_snapshot([juno, halder]), halder, "Halder")
		await _greet_retired(halder, HALDER_DEFEATED)

	if _has(JUNO_FLAG) and _has(HALDER_FLAG):
		await _exercise_save_load(juno, halder)
	_report()


func _prepare_game() -> bool:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("no /root/Game autoload; there is no production state to drive")
		return false
	_game.call("reset_for_new_game")
	_remove_tree(ProjectSettings.globalize_path(SAVE_DIR))
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_game.set("save_system", SAVE_GAME.new(SAVE_DIR))
	_progression().call("set_flag", OPENING_BYPASS_FLAG)
	return true


func _boot_meadows() -> bool:
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_fail("could not load %s" % SCENE)
		return false
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_trainers = _world.get_node_or_null(^"Trainers")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_manager = _world.get_node_or_null(^"CombatManager")
	_panel = _world.get_node_or_null(^"DialoguePanel") as CanvasLayer
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _trainers == null or _director == null \
			or _manager == null or _panel == null:
		_fail("Meadows did not build the player, trainers, encounter director, combat manager and dialogue panel")
		return false
	if _director.call("ally_instance") == null:
		await _director.call("adopt_starter", "terrapup")
	for i in 6:
		await physics_frame
	if _director.call("ally_instance") == null or _director.call("ally_body") == null:
		_fail("the production starter could not be adopted and deployed")
		return false
	return true


func _reset_story_flags() -> void:
	_progression().call("set_flag", JUNO_FLAG, false)
	_progression().call("set_flag", HALDER_FLAG, false)


func _challenge_and_win(spec: Dictionary, expected_conversation: String,
		defeat_flag: String) -> bool:
	var id := str(spec.get("id", ""))
	var body: Node3D = _trainers.call("body_for", id) as Node3D
	if not is_instance_valid(body):
		_fail("%s has no placed production body" % id)
		return false
	if _has(defeat_flag):
		_fail("%s was already beaten before its challenge" % id)
		return false
	if TRAINERS.conversation_for(spec, _progression()) != expected_conversation:
		_fail("%s did not resolve to challenge conversation '%s'" % [id, expected_conversation])
		return false
	if not await _activate_prompt(body, expected_conversation, "Challenge"):
		return false

	for i in 6:
		await physics_frame
	if not bool(_director.call("trainer_battle_active")) \
			or str(_director.call("trainer_battle_id")) != id:
		_fail("%s's completed real dialogue did not start its configured trainer battle" % id)
		return false

	await _fight(id)
	if bool(_director.call("trainer_battle_active")):
		return false
	if not _has(defeat_flag):
		_fail("%s's real trainer victory did not set '%s'" % [id, defeat_flag])
		return false
	_receipt("trainer_story_transition", {
		"trainer": id,
		"conversation": expected_conversation,
		"defeat_flag": defeat_flag,
		"objective": _objective_state(),
	})
	return true


func _greet_retired(spec: Dictionary, expected_conversation: String) -> void:
	var id := str(spec.get("id", ""))
	for i in 3:
		await process_frame
	if TRAINERS.conversation_for(spec, _progression()) != expected_conversation:
		_fail("%s did not retire to defeated conversation '%s'" % [id, expected_conversation])
		return
	if not TRAINERS.prompt_for(spec, _progression()).begins_with("Greet "):
		_fail("%s's completed branch still advertises a challenge" % id)
		return
	var body: Node3D = _trainers.call("body_for", id) as Node3D
	if not await _activate_prompt(body, expected_conversation, "Greet"):
		return
	for i in 4:
		await physics_frame
	if bool(_director.call("trainer_battle_active")):
		_fail("%s's defeated follow-up reopened a trainer battle" % id)


## Use the real nearby offer and activated signal, then drain every authored
## line through DialoguePanel.advance(). Calling panel.start() here would skip
## trainer_npc's branch selection and is intentionally not accepted.
func _activate_prompt(body: Node3D, expected_conversation: String,
		expected_verb: String) -> bool:
	if not is_instance_valid(body):
		_fail("a requested trainer body is missing")
		return false
	var prompt := body.call("prompt_node") as Node3D
	if prompt == null:
		_fail("%s has no production Interactable" % body.name)
		return false
	if bool(_panel.call("is_open")):
		_panel.call("close")
		await process_frame

	_player.global_position = body.global_position + APPROACH_OFFSET
	_player.velocity = Vector3.ZERO
	await physics_frame
	var offer := prompt.call("interaction_offer", _player.global_position) as Dictionary
	if offer.is_empty():
		_fail("%s's real prompt offers nothing to the nearby player" % body.name)
		return false
	var label := str(offer.get("label", ""))
	if not label.begins_with(expected_verb + " "):
		_fail("%s's prompt says '%s', expected the %s branch" % [body.name, label, expected_verb])
		return false

	_last_finished = ""
	prompt.call("interaction_activate")
	await process_frame
	if not bool(_panel.call("is_open")):
		_fail("activating %s's real prompt opened no dialogue" % body.name)
		return false
	var runner := _panel.call("runner") as RefCounted
	var opened := str(runner.call("conversation_id")) if runner != null else ""
	if opened != expected_conversation:
		_fail("%s opened '%s', expected '%s'" % [body.name, opened, expected_conversation])

	var guard := 0
	while bool(_panel.call("is_open")) and guard < 64:
		await process_frame
		_panel.call("advance")
		guard += 1
	await process_frame
	await process_frame
	if guard >= 64:
		_fail("%s's '%s' never closed" % [body.name, expected_conversation])
		return false
	if _last_finished != expected_conversation:
		_fail("%s finished as '%s', expected '%s'" % [body.name, _last_finished, expected_conversation])
		return false
	return true


## Balance is deliberately accelerated, but the production combat loop still
## owns every strike, faint, roster advance, final flag and first-time payout.
func _fight(trainer_id: String) -> void:
	var frames := 0
	_consecutive_misses = 0
	_manager.connect("attack_missed", _on_attack_missed)
	_manager.connect("hit_landed", _on_hit_landed)
	while bool(_director.call("trainer_battle_active")) and frames < BATTLE_FRAME_LIMIT:
		frames += 1
		if not bool(_manager.call("is_fighting")):
			await physics_frame
			continue

		var mine := _manager.call("active_creature") as RefCounted
		if mine != null:
			mine.set("hp", mine.get("max_hp"))
		var opponent := _world.find_child("TrainerCreature_%s_*" % trainer_id, true, false) as Node3D
		var ally := _director.call("ally_body") as Node3D
		if opponent == null or ally == null:
			await physics_frame
			continue
		var theirs := opponent.get("instance") as RefCounted
		if theirs != null and float(theirs.get("hp")) > 6.0:
			theirs.set("hp", 6.0)

		var offset := opponent.global_position - ally.global_position
		offset.y = 0.0
		if _rig != null and offset.length_squared() > 0.001:
			_rig.set("yaw", atan2(-offset.x, -offset.z))
		if offset.length() > _floored_quick_range(ally, opponent):
			Input.action_press("move_forward")
			await physics_frame
			Input.action_release("move_forward")
		elif bool(_manager.call("quick_ready")):
			await _press("combat_quick")
			if _consecutive_misses >= CONSECUTIVE_MISS_LIMIT:
				_fail("%s: quick attack missed %d times in a row" % [trainer_id, _consecutive_misses])
				break
		else:
			await physics_frame

	if _manager.is_connected("attack_missed", _on_attack_missed):
		_manager.disconnect("attack_missed", _on_attack_missed)
	if _manager.is_connected("hit_landed", _on_hit_landed):
		_manager.disconnect("hit_landed", _on_hit_landed)
	Input.action_release("move_forward")
	if bool(_director.call("trainer_battle_active")):
		_fail("%s's fight did not resolve within %d frames" % [trainer_id, BATTLE_FRAME_LIMIT])


func _floored_quick_range(ally: Node3D, opponent: Node3D) -> float:
	var base := float(MATH.config().get("player_quick", {}).get("range", 2.6))
	var mine := float(ally.call("body_radius")) if ally.has_method("body_radius") else 0.5
	var theirs := float(opponent.call("body_radius")) if opponent.has_method("body_radius") else 0.5
	var clearance := float(MATH.config().get("enemy", {}).get("body_clearance", 1.8))
	return maxf(base, (mine + theirs) * clearance + 0.5)


func _on_attack_missed(by_player: bool) -> void:
	if by_player:
		_consecutive_misses += 1


func _on_hit_landed(on_enemy: bool, _amount: float) -> void:
	if on_enemy:
		_consecutive_misses = 0


func _exercise_save_load(juno: Dictionary, halder: Dictionary) -> void:
	var saved_rewards := _reward_snapshot([juno, halder])
	if not bool(_game.call("save_game", SAVE_SLOT)):
		_fail("Game.save_game refused the isolated smoke slot")
		return

	# Prove load reconstructed the earned world story, rather than merely
	# observing state that was never abandoned in this process.
	_progression().call("set_flag", JUNO_FLAG, false)
	_progression().call("set_flag", HALDER_FLAG, false)
	_assert_objective(false, false, "after pre-load mutation")
	if not bool(_game.call("load_game", SAVE_SLOT)):
		_fail("Game.load_game refused the isolated smoke slot")
		return
	await process_frame
	await process_frame
	_assert_world_flag_landed(JUNO_FLAG)
	_assert_world_flag_landed(HALDER_FLAG)
	_assert_objective(true, true, "after save/load")
	if _reward_snapshot([juno, halder]) != saved_rewards:
		_fail("save/load did not restore the exact earned Juno/Halder reward snapshot")

	# Revisit both real prompts after load. These are required to stay defeated,
	# effect-free and battle-free; otherwise persistence can still create an XP
	# or payout faucet even though the raw flags happened to deserialize.
	await _greet_retired(juno, JUNO_DEFEATED)
	await _greet_retired(halder, HALDER_DEFEATED)
	if _reward_snapshot([juno, halder]) != saved_rewards:
		_fail("post-load defeated greetings replayed a trainer payout")
	_receipt("save_load_retirement", {
		"juno": _has(JUNO_FLAG),
		"halder": _has(HALDER_FLAG),
		"objective": _objective_state(),
		"rewards": saved_rewards,
	})


func _assert_objective(present: bool, done: bool, phase: String) -> void:
	var state := _objective_state()
	if bool(state.get("present", false)) != present:
		_fail("%s: First Ironwood objective present=%s, expected %s" % [
			phase, state.get("present", false), present])
	elif present and bool(state.get("done", false)) != done:
		_fail("%s: First Ironwood objective done=%s, expected %s" % [
			phase, state.get("done", false), done])


## Ask the production quest_log reader. Matching its returned authored label
## avoids reimplementing revealed_by/done rules inside this smoke.
func _objective_state() -> Dictionary:
	for raw: Variant in _log.local_entries(_progression()):
		var entry := raw as Dictionary
		if str(entry.get("label", "")) == _objective_label:
			return {"present": true, "done": bool(entry.get("done", false))}
	return {"present": false, "done": false}


func _read_objective_label() -> String:
	var file := FileAccess.open(OBJECTIVES_PATH, FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ""
	for raw: Variant in ((parsed as Dictionary).get("local", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == OBJECTIVE_ID:
			return str((raw as Dictionary).get("label", ""))
	return ""


func _reward_snapshot(specs: Array) -> Dictionary:
	var ids: Dictionary = {"coin": true}
	for raw: Variant in specs:
		var spec := raw as Dictionary
		for item: Dictionary in TRAINERS.reward_items(spec):
			ids[str(item.get("id", ""))] = true
	var out: Dictionary = {}
	for id: String in ids:
		out[id] = int(_inventory().call("count", id))
	return out


func _assert_reward_delta(before: Dictionary, after: Dictionary,
		spec: Dictionary, who: String) -> void:
	var expected: Dictionary = {"coin": TRAINERS.reward_coins(spec)}
	for item: Dictionary in TRAINERS.reward_items(spec):
		var id := str(item.get("id", ""))
		expected[id] = int(expected.get(id, 0)) + int(item.get("count", 0))
	for id: String in expected:
		var actual := int(after.get(id, 0)) - int(before.get(id, 0))
		if actual != int(expected[id]):
			_fail("%s payout '%s' changed by %d, expected %d" % [who, id, actual, expected[id]])


func _assert_world_scope(flag: String) -> void:
	if str(PROGRESSION_STATE.scope_of(flag)) != "world":
		_fail("'%s' is not declared world scope" % flag)


func _assert_world_flag_landed(flag: String) -> void:
	var world_flags := (_game.get("world") as RefCounted).get("flags") as RefCounted
	var player_flags := (_game.get("local") as RefCounted).get("flags") as RefCounted
	if world_flags == null or not bool(world_flags.call("has", flag)):
		_fail("'%s' did not land in the live world flag store" % flag)
	if player_flags != null and bool(player_flags.call("has", flag)):
		_fail("world flag '%s' leaked into the local player's flag store" % flag)


func _has(flag: String) -> bool:
	return bool(_progression().call("has", flag))


func _progression() -> RefCounted:
	return _game.get("progression") as RefCounted


func _inventory() -> RefCounted:
	return _game.get("inventory") as RefCounted


func _press(action: String) -> void:
	Input.action_press(action)
	_send(action, true)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	_send(action, false)
	for i in 4:
		await physics_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _on_dialogue_finished(conversation_id: String) -> void:
	_last_finished = conversation_id


func _receipt(event: String, detail: Dictionary) -> void:
	print("IRONWOOD_RECEIPT %s %s" % [event, JSON.stringify(detail)])


func _fail(message: String) -> void:
	_failures.append(message)


func _remove_tree(absolute_path: String) -> void:
	var dir := DirAccess.open(absolute_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var child := absolute_path.path_join(name)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute_path)


func _report() -> void:
	_remove_tree(ProjectSettings.globalize_path(SAVE_DIR))
	print("")
	if _failures.is_empty():
		print("First Ironwood story: OK — Juno revealed the objective, Halder completed it, both real dialogue/battle branches retired, and world state plus payouts survived save/load without replay.")
		quit(0)
		return
	for line: String in _failures:
		print("First Ironwood story FAIL: %s" % line)
	quit(1)
