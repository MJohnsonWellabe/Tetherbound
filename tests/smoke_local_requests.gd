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
## Deliberately does NOT walk the player to any of these five: the button-to-
## prompt half is smoke_opening.gd's job and is unrelated to what these five
## activities add. Each one starts its own conversation the way its own
## trainer/villager placer starts it, which is the seam actually in question.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

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
var _log := QUEST_LOG.new()

var _quick_hits := 0
var _quick_misses := 0
var _consecutive_misses := 0


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	if not _collect_nodes():
		_report()
		return

	await _night_watch()
	await _river_nest()
	await _lost_creature()
	await _meadowhart_herd()
	await _broken_cart()

	_report()


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup")


func _collect_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_panel = _world.get_node_or_null(^"DialoguePanel")
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


func _lost_creature() -> void:
	await _play_local_trainer(
		"lost_creature_rue", "lost_creature_rue_challenge",
		"defeated_lost_creature_rue", "lost_creature_rue_met", "band4_lost_creature")


## Shared drive for all three: find the real placed body, walk the real
## challenge conversation to its `battle:` line on the real panel, fight the
## real trainer battle to the end, then check the real flag/reward/quest-log
## consequences.
func _play_local_trainer(trainer_id: String, challenge_conversation: String,
		defeat_flag: String, met_flag: String, objective_id: String) -> void:
	var trainers := _world.get_node_or_null(^"Trainers")
	if trainers == null:
		_fail("%s: no 'Trainers' node in the world" % trainer_id)
		return
	var body: Node3D = trainers.call("body_for", trainer_id)
	if body == null or not is_instance_valid(body):
		_fail("%s: not placed anywhere in the real world" % trainer_id)
		return

	var progression := _progression()
	if bool(progression.call("has", defeat_flag)):
		_fail("%s: already beaten before this test touched it -- a stale save leaked in" % trainer_id)
		return
	var before_local := _local_entry(objective_id, progression)
	if before_local.get("present", false):
		_fail("%s: the Local Request is visible in the log before the trainer was ever met" % trainer_id)

	await _play(challenge_conversation)

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

	var after_local := _local_entry(objective_id, progression)
	if not after_local.get("present", false):
		_fail("%s: beaten, but the Local Request '%s' never appeared in quest_log's local list" % [
			trainer_id, objective_id])
	elif not bool(after_local.get("done", false)):
		_fail("%s: the Local Request '%s' is in the log but does not read done" % [trainer_id, objective_id])


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


## --- Meadowhart Herd: a real villager, a real one-time gift ------------------

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
	if bool(progression.call("has", "band1_meadowhart_herd_found")):
		_fail("meadowhart_herd: already found before this test touched it")
		return
	var before_local := _local_entry("band1_meadowhart_herd", progression)
	if before_local.get("present", false):
		_fail("meadowhart_herd: visible in the log before Rae was ever met")

	var orbs_before := int(inventory.call("count", "orb_basic"))
	await _play("meadowhart_herd_sighting")

	if not bool(progression.call("has", "band1_meadowhart_herd_met")):
		_fail("meadowhart_herd: talking to Rae did not set 'band1_meadowhart_herd_met'")
	if not bool(progression.call("has", "band1_meadowhart_herd_found")):
		_fail("meadowhart_herd: the sighting conversation did not set the completion flag")
	var orbs_after := int(inventory.call("count", "orb_basic"))
	if orbs_after != orbs_before + 3:
		_fail("meadowhart_herd: expected +3 orb_basic, got %d -> %d" % [orbs_before, orbs_after])

	var after_local := _local_entry("band1_meadowhart_herd", progression)
	if not after_local.get("present", false) or not bool(after_local.get("done", false)):
		_fail("meadowhart_herd: the Local Request never reads done in quest_log after the sighting")


## --- River Nest: the real item_gate contract, on a gather-and-give NPC -------

func _river_nest() -> void:
	var doss := _world.get_node_or_null(^"RiverNestClear")
	if doss == null or not is_instance_valid(doss):
		_fail("river_nest: not placed anywhere in the real world")
		return

	var progression := _progression()
	var inventory := _inventory()
	if bool(progression.call("has", "river_nest_doss_cleared")):
		_fail("river_nest: already cleared before this test touched it")
		return

	# Empty-handed: the real gate must refuse, but the meeting must still be
	# recorded so the Local Request is revealed in the log.
	doss.call("_on_greeted")
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

	doss.call("_on_greeted")

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

	var after_repair := _local_entry("band1_broken_cart", progression)
	if not after_repair.get("present", false) or not bool(after_repair.get("done", false)):
		_fail("broken_cart: the Local Request never reads done in quest_log after the repair")


## --- shared -------------------------------------------------------------------

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


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("local requests smoke test passed")
		quit(0)
	else:
		for line in _failures:
			print("smoke FAIL: %s" % line)
		quit(1)
