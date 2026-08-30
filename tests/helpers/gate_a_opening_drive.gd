extends RefCounted

## The opening, title through the natural first catch, as a reusable drive.
##
## Extracted from `smoke_gate_a_opening_segment.gd` on 2026-08-23 because Gate B
## needed to PLAY the opening rather than grant it, and granting was measurably
## wrong. `smoke_gate_b_continuous.gd` set the road-beat flag and stood the
## player at a hand-picked coordinate; five runs then failed at five DIFFERENT
## beats -- the axe swing, Mira's door twice, Tam, Oskar -- because
## `_step_toward()` walks a straight line, the village has buildings in it, and
## from any hand-chosen start SOME target sits behind geometry. Which one
## depends on where you started, so the failures looked random and were not.
##
## Two principled alternatives were tried and measured before this: starting at
## the village centroid computed from the villagers' own data (Tam went from 20m
## to 11m away and it still failed), and sidestepping when something else held
## the interact line (the player never gets close enough to sidestep). Both are
## recorded in `ralph/BACKLOG.md` under CONTINUOUS-CORE so they are not retried.
##
## The opening leaves the player standing on the authored path, where
## straight-line walking works. No computed coordinate reproduces that, which is
## why this had to become a segment rather than a better number.
##
## It also retires the second definition of the opening path that granting
## created. This branch spent a night fixing twelve harnesses that had drifted
## from the game; two definitions of the same beat is how the thirteenth starts.
##
## Contract matches the sibling segments (`gate_a_material_route.gd`,
## `gate_a_build_segment.gd`): `run()` returns
## `{passed, failures, transcript}` plus the live handles the caller needs to
## carry on in the SAME world -- `world`, `game`, `player`, `rig`.
##
## Deliberately does not boot or finish a SceneTree. The caller owns that.

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const WORLD_SCENE := "res://scenes/world/meadows_playground.tscn"
const DIRECTOR_SCRIPT := "res://scripts/story/sequence_director.gd"
const INTERACTABLE_SCRIPT := "res://scripts/world/interactable.gd"
const STARTER_PICKER_SCRIPT := "res://scripts/ui/starter_picker.gd"
const NAME_ENTRY := preload("res://scripts/ui/name_entry.gd")
const NPC_GATHER_SEGMENT := preload("res://tests/helpers/gate_a_npc_gather_segment.gd")
const MATERIAL_ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const BUILD_SEGMENT := preload("res://tests/helpers/gate_a_build_segment.gd")
## CONTROLLER-MAP (ralph/OWNER_DIRECTIVES_2026-08-22.md section 1) took the pad
## binding off `combat_throw`: the orb is a hotbar item now and X throws it, so
## `interact` IS the pad's throw button. combat_manager.gd::_throw_pressed and
## throw_aim.gd both read it beside `combat_throw`'s surviving keyboard F. This
## harness may only press what a pad can press, so it presses that.
const THROW_ACTION := &"interact"
const CHOSEN_NAME := "Bud"
## Inside this the aim is on the creature and the loop stops. Per axis, because
## that is how the rig splits the two sticks.
const AIM_WINDOW_DEGREES := 1.0
## How long the aim controller may spend converging before it reports that it
## could not.
##
## T2-FLAKE: this was a FRAME COUNT (360, and 240 for the re-aims), and a frame
## count is the wrong unit for it. What the loop is waiting for is the camera
## physically turning, and `camera_rig.gd::_apply_look()` turns it in degrees
## per SECOND. A physics frame here measures 16.6ms unloaded and was measured at
## 300ms under CI-like load, so "360 frames" is a budget that silently changes
## by 18x on the machine that needs it most. Seconds of real time do not.
const AIM_CONVERGE_SECONDS := 12.0
## The same ceiling for the re-aims that follow a step aside, which start from a
## much smaller error and should not be given the full slew budget.
const AIM_REAIM_SECONDS := 8.0
## Below this a sample bought no camera movement at all: the deflection is under
## a deadzone. See `_calibrated_deflection()`.
const AIM_STILL_DEGREES := 0.02
## How far, and how many times, the aim steps back from a creature it cannot
## look down at. See `_aim_at_wild()`.
const AIM_BACKOFF_METRES := 2.0
const AIM_BACKOFF_TRIES := 3
## Inside this the aim camera's own pitch clamp stops it finding the creature;
## past this the orb cannot reach it. Both are answered by walking.
const AIM_TOO_CLOSE_METRES := 5.0
const AIM_THROWABLE_METRES := 12.0
const CONTINUOUS_CORE_FLAG := "--gate-a-continuous-core"

var _failures: Array[String] = []
var _transcript: Array[String] = []
var _tree: SceneTree = null
var _started_ms := 0
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _sequence: Node = null
var _encounter: Node = null
var _combat: Node = null
var _arbiter: Node = null
var _dialogue: CanvasLayer = null
var _name_prompt: CanvasLayer = null
var _starter_picker: CanvasLayer = null
var _wild: Node3D = null
var _catch_results: Array[bool] = []
## The HP the natural fight left the Bramblebun on, held there while catching.
var _weakened_hp := -1.0
var _throw_strikes := 0
var _throw_misses := 0
## The aim controller's calibration. Carried BETWEEN calls on purpose: it is a
## measurement of how fast this machine is turning the camera, and that does not
## reset because the loop was re-entered. See `_calibrated_deflection()`.
var _aim_deflection := 1.0
var _aim_forward_before := Vector3.ZERO
var _aim_sampled_usec := 0
var _aim_has_history := false
## What one sample actually bought, kept for the failure message: a run that
## could not converge should say what the machine was giving it.
var _aim_sample_turn := 0.0
var _aim_sample_seconds := 0.0


func run(tree: SceneTree) -> Dictionary:
	_tree = tree
	_started_ms = Time.get_ticks_msec()
	if str(ProjectSettings.get_setting("application/run/main_scene", "")) != TITLE_SCENE:
		_fail("configured main scene is not the production title")
		return _result()
	if not _required_pad_actions_exist():
		return _result()

	var title := (load(TITLE_SCENE) as PackedScene).instantiate()
	_tree.root.add_child(title)
	_tree.current_scene = title
	await _tree.process_frame
	_checkpoint("title interactive")
	var focused := _tree.root.get_viewport().gui_get_focus_owner() as Button
	if focused == null or focused.text != "Start New Game":
		_fail("title focus is not on Start New Game")
		return _result()
	await _tap_action("ui_accept")
	# title_screen.gd::_on_new_pressed() interposes a "Start a fresh game?"
	# confirmation whenever ANY save slot is occupied, with "Start Fresh Game"
	# already focused. A harness that only ever ran against an empty user://
	# never met it and reported the stall as "never reached the Meadows world" --
	# which is the one screen a returning player meets EVERY time, so answering
	# it here is the production path, not a test convenience.
	var confirm := _tree.root.get_viewport().gui_get_focus_owner() as Button
	if confirm != null and confirm.text == "Start Fresh Game":
		_checkpoint("answered the returning-player fresh-game confirmation")
		await _tap_action("ui_accept")
	for _i in 2400:
		if _tree.current_scene != null and _tree.current_scene.scene_file_path == WORLD_SCENE:
			_world = _tree.current_scene
			break
		await _tree.process_frame
	if _world == null:
		_fail("Start New Game never reached the configured Meadows world")
		return _result()
	_checkpoint("new game world entered")
	for _i in 300:
		await _tree.physics_frame
	if not _collect_world_nodes():
		return _result()

	var get_up := _find_interactable(["get up"])
	if get_up == null or not await _walk_to_and_activate(get_up, 600):
		_fail("the real wake-up prompt could not be reached and activated")
		return _result()
	if str(_sequence.call("beat")) == "wake":
		_fail("Get Up did not advance the opening")
		return _result()
	_checkpoint("wake/Get Up complete")

	var house := _world.get_node_or_null(^"GrandpaHouse")
	if house == null:
		_fail("production world has no GrandpaHouse")
		return _result()
	if not await _walk_toward(house.call("marker", "stairs_top"), 500):
		_fail("could not naturally reach the stair head")
	if _failures.is_empty() and not await _walk_toward(house.call("marker", "stairs_bottom"), 500):
		_fail("could not naturally descend Grandpa's stairs")
	if not _failures.is_empty():
		return _result()
	var grandpa := _find_interactable(["grandpa", "talk"])
	if grandpa == null or not await _walk_to_and_activate(grandpa, 700):
		_fail("Grandpa's real interaction could not be completed")
		return _result()
	if not await _close_dialogue(50):
		_fail("Grandpa's briefing did not close through physical Interact presses")
		return _result()
	_checkpoint("Grandpa briefing and pack complete")

	for _i in 120:
		if bool(_starter_picker.call("is_open")):
			break
		await _tree.physics_frame
	if not bool(_starter_picker.call("is_open")):
		_fail("starter picker did not open after the real briefing")
		return _result()
	await _tap_action("ui_right")
	await _tap_action("menu_confirm")
	for _i in 60:
		if bool(_name_prompt.call("is_open")):
			break
		await _tree.physics_frame
	if not bool(_name_prompt.call("is_open")):
		_fail("physical starter selection did not open naming")
		return _result()
	await _type_name_with_pad(CHOSEN_NAME)
	if not _failures.is_empty():
		return _result()
	for _i in 600:
		if _game.party.size() == 1:
			break
		await _tree.physics_frame
	if _game.party.size() != 1 or str(_game.party.at(0).nickname) != CHOSEN_NAME:
		_fail("named starter did not reach the real one-creature party")
		return _result()
	_checkpoint("starter selected and named")

	if not await _walk_toward(house.call("marker", "grandpa"), 500):
		_fail("could not cross the ground floor after naming")
	# Naming deliberately leaves the player with one purpose: return to Grandpa.
	# Do the real follow-up interaction before attempting the tutorial catch;
	# this is where the live dialogue grants its 10–15 Basic Orbs.
	if grandpa == null or not await _walk_to_and_activate(grandpa, 700):
		_fail("Grandpa's required first-catch interaction could not be completed")
		return _result()
	if not await _close_dialogue(20):
		_fail("Grandpa's first-catch conversation did not return control")
		return _result()
	var opening_orbs := int(_game.inventory.count("orb_basic"))
	if opening_orbs < 10 or opening_orbs > 15:
		_fail("Grandpa's first-catch conversation left %d Basic Orbs; expected 10–15" % opening_orbs)
		return _result()
	_checkpoint("Grandpa's first-catch supplies received (%d Basic Orbs)" % opening_orbs)
	if _failures.is_empty() and not await _walk_toward(house.call("marker", "door"), 700):
		_fail("could not leave the now-unlocked front doorway")
	if not _failures.is_empty():
		return _result()
	_checkpoint("usable house/front doorway exited")

	_wild = _encounter.call("wild_creature") as Node3D
	if _wild == null:
		_fail("opening has no naturally spawned tutorial Bramblebun")
		return _result()
	if str(_wild.get("species_id")) != "bramblebun":
		_fail("opening's natural tutorial creature is '%s', not Bramblebun" % str(_wild.get("species_id")))
		return _result()
	if not await _walk_to_and_engage_wild(_wild, 2600):
		_fail("natural travel did not reach and engage the tutorial Bramblebun")
		return _result()
	for _i in 180:
		if bool(_combat.call("is_fighting")):
			break
		await _tree.physics_frame
	if not bool(_combat.call("is_fighting")):
		_fail("Interact at the natural Bramblebun did not enter real combat")
		return _result()
	_checkpoint("tutorial Bramblebun combat entered")

	if not await _fight_until_catchable():
		return _result()
	if not await _catch_with_real_throws():
		return _result()
	for _i in 900:
		if not bool(_combat.call("is_fighting")):
			break
		await _tree.physics_frame
	if bool(_combat.call("is_fighting")) or str(_combat.call("outcome")) != "caught":
		_fail("successful catch did not return to exploration")
	elif _game.party.size() != 2:
		_fail("catch returned to exploration with %d party members, expected two" % _game.party.size())
	elif not bool(_player.call("locomotion_enabled")):
		_fail("trainer locomotion was not restored after the catch")
	else:
		_checkpoint("catch complete; exploration resumed with two-creature party")
	return _result()


func _collect_world_nodes() -> bool:
	_game = _tree.root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_encounter = _world.get_node_or_null(^"EncounterDirector")
	_combat = _world.get_node_or_null(^"CombatManager")
	_arbiter = _tree.get_first_node_in_group(&"interaction_arbiter")
	_sequence = _find_by_script(_world, DIRECTOR_SCRIPT)
	_dialogue = _find_by_method(_world, "drain_effects") as CanvasLayer
	_name_prompt = _find_by_method(_world, "current_text") as CanvasLayer
	_starter_picker = _find_by_script(_world, STARTER_PICKER_SCRIPT) as CanvasLayer
	if (_game == null or _player == null or _rig == null or _encounter == null
			or _arbiter == null
			or _combat == null or _sequence == null or _dialogue == null
			or _name_prompt == null or _starter_picker == null):
		_fail("production world is missing an opening/combat/UI dependency")
		return false
	_combat.connect("catch_resolved", func(success: bool, _shakes: int) -> void: _catch_results.append(success))
	var throw: Node = _combat.call("throw_aim")
	throw.connect("orb_struck", func(_target: Node3D, _offset: float) -> void: _throw_strikes += 1)
	# `orb_missed` carries the sentence the player is shown ("so close -- 0.2m
	# wide", "the orb hit the ground -- 18.0m wide"). Printed rather than
	# dropped: a run that misses is exactly the run whose reason matters.
	throw.connect("orb_missed", func(message: String) -> void:
		_throw_misses += 1
		print("throw missed: %s" % message))
	return true


func _type_name_with_pad(chosen: String) -> void:
	for _i in 20:
		if bool(_name_prompt.get("_using_gamepad")):
			break
		await _tree.physics_frame
	if not bool(_name_prompt.get("_using_gamepad")):
		_fail("naming prompt did not remain in gamepad mode after real pad input")
		return
	var entry: RefCounted = _name_prompt.call("entry")
	for character in chosen:
		if not await _select_name_cell(entry, character):
			return
		await _tap_action("menu_confirm")
	if str(_name_prompt.call("current_text")) != chosen:
		_fail("controller typed '%s', expected '%s'" % [str(_name_prompt.call("current_text")), chosen])
		return
	if not await _select_name_cell(entry, NAME_ENTRY.DONE):
		return
	await _tap_action("menu_confirm")
	for _i in 120:
		if not bool(_name_prompt.call("is_open")):
			return
		await _tree.physics_frame
	_fail("controller Done did not close naming")


func _select_name_cell(entry: RefCounted, cell: String) -> bool:
	var target := Vector2i(-1, -1)
	for row_index in NAME_ENTRY.ROWS.size():
		var row: Array = NAME_ENTRY.ROWS[row_index]
		for column_index in row.size():
			if str(row[column_index]) == cell:
				target = Vector2i(row_index, column_index)
	if target.x < 0:
		_fail("naming grid has no '%s' cell" % cell)
		return false
	for _i in 16:
		if int(entry.row) == target.x:
			break
		await _tap_action("ui_down")
	for _i in 20:
		if int(entry.column) == target.y:
			break
		await _tap_action("ui_right")
	if str(entry.selected()) != cell:
		_fail("controller stopped on '%s' instead of '%s'" % [str(entry.selected()), cell])
		return false
	return true


func _fight_until_catchable() -> bool:
	var ally := _encounter.call("ally_body") as Node3D
	var foe: RefCounted = _combat.call("enemy")
	var own: RefCounted = _combat.call("active_creature")
	if ally == null or foe == null or own == null:
		_fail("combat started without both real creature instances/bodies")
		return false
	for _i in 1800:
		if not bool(_combat.call("is_fighting")):
			_fail("fight ended before the Bramblebun became catchable")
			return false
		if own.fainted:
			_fail("starter fainted before naturally weakening the tutorial Bramblebun")
			return false
		if float(foe.hp) <= float(foe.max_hp) * 0.28:
			# Remembered so the catch loop can HOLD the fight here. Captured
			# from the natural fight rather than assigned, so "naturally
			# weakened" stays a true statement about how it got there.
			_weakened_hp = float(foe.hp)
			_checkpoint("Bramblebun naturally weakened to %.0f/%d HP" % [foe.hp, foe.max_hp])
			return true
		await _drive_body_toward(ally, _wild.global_position, 1)
		if ally.global_position.distance_to(_wild.global_position) < 4.0 and _i % 35 == 0:
			await _tap_action("combat_quick")
	_stop_left_stick()
	_fail("real piloted attacks did not weaken Bramblebun within the bounded fight")
	return false


## The catch, with the satchel deliberately down to its last orb.
##
## Grandpa gives fifteen, and a run that starts with fifteen almost never
## reaches zero inside this harness's budget -- so the dead-end that zero causes
## went unseen until it was reasoned out rather than observed. Draining to one
## first makes every run exercise it: the next miss empties the satchel,
## `throw_aim.gd::try_begin_aim()` refuses with "no orbs left", and the opening
## either restocks (opening.json's `catch_orb_floor`) or is unwinnable from here
## with no way out but a new game. `_orbs_held()` is asserted below zero-floor
## rather than trusted, because a harness that simply kept throwing would report
## a healthy opening either way.
func _catch_with_real_throws() -> bool:
	var drained := _drain_satchel_to_last_orb()
	if drained < 0:
		return false
	_checkpoint("satchel drained to %d orb(s) so the empty case is on the real path" % drained)
	var launches := 0
	var blocked_lines := 0
	var restocked := false
	var refusals := 0
	var re_engages := 0
	# Generous, not unbounded: with the floor in place the opening never refuses
	# a throw, so the only honest reason to stop is that catching is broken.
	while launches < 40:
		# Hold the fight where the natural one left it.
		#
		# THE root cause behind four separate failures in this file: your own
		# creature keeps fighting the thing you are throwing at. Over a long
		# catch that produced, in turn, a target knocked out cold (the aim is
		# refused), a target killed outright (the fight ends), and a fainted
		# starter (engagement is refused). Each was patched as it surfaced;
		# this is the one line that removes the class.
		#
		# `smoke_catching.gd` and `smoke_party_count_after_catches.gd` both
		# already pin HP on every attempt for exactly this reason -- this file
		# was the only catch harness that did not, which is why it was the only
		# one finding new ways for the fight to end. Held at the level the
		# NATURAL fight reached, not pushed lower, so the odds under test are
		# the ones a player meets and the run's own "naturally weakened"
		# checkpoint stays honest.
		#
		# The knockout/re-engage handling below stays as a backstop for a death
		# that lands between frames; with this in place it should never fire.
		_hold_the_fight_where_it_was()
		if not bool(_combat.call("is_fighting")):
			# The fight ENDED, which over a long catch usually means your own
			# creature finished the Bramblebun off -- the launch log shows it
			# intercepting orbs (`first_hit=AllyCreature`) throughout. The
			# design expects this: `sequence_director.gd::_on_combat_exited`
			# says so in as many words -- "They won it instead of catching it,
			# or ran... the beat stays where it is and they get another go",
			# and species.json gives this creature the highest catch rate in
			# the game precisely so the tutorial catch need not land first
			# time. The encounter director stands it back up.
			#
			# So a player walks back and engages again, and giving up here
			# reported a broken game for a beat working as written.
			if re_engages >= 3:
				_fail("the fight ended %d times without a catch; the tutorial creature "
					% re_engages + "is being killed faster than it can be caught")
				return false
			re_engages += 1
			var revived := await _wait_for_the_bramblebun_back_on_its_feet()
			if revived == null:
				_fail("the fight ended after launch %d and no Bramblebun came back"
					% launches)
				return false
			_wild = revived
			# Put your own creature back on its feet first.
			#
			# The run that exposed this reported `prompt='Ripplet is out of the
			# fight.'` -- `encounter_director.gd::interaction_offer()` refuses
			# engagement outright while the ally is fainted, and says why: "with
			# no creature on its feet there is nothing to fight with". After a
			# long attrition catch that is the normal end state, and a player
			# would rest or use a potion before walking back.
			#
			# Assigning hp directly is the shortcut the sibling harnesses
			# already take (`smoke_catching.gd`, `smoke_party_count_after_catches.gd`
			# both set `creature.hp` outright): this file's subject is the CATCH
			# path, not the healing path, and `smoke_gate_a_rest_torch.gd` owns
			# resting.
			var own: RefCounted = _combat.call("active_creature")
			if own == null:
				var party: RefCounted = _game.get("party")
				own = party.call("active") if party != null else null
			if own != null:
				own.set("fainted", false)
				own.set("hp", own.get("max_hp"))
			_checkpoint("the Bramblebun was knocked out; healing up and re-engaging it (%d)"
				% re_engages)
			if not await _walk_to_and_engage_wild(_wild, 1800):
				_fail("could not re-engage the respawned Bramblebun")
				return false
			if not await _fight_until_catchable():
				return false
			continue
		# A resolved throw has a production 0.9s cooldown. One press during that
		# window is deliberately ignored, so retry until a real aim opens instead
		# of counting the ignored press as one of this evidence run's launches.
		# The old loop therefore launched only on iterations 2/4/6/8 after a miss,
		# exactly matching the alternating outcomes in the continuous-run log.
		if not await _open_throw_aim():
			# The fight can end DURING those attempts -- the ally is still
			# swinging while the aim is being asked for -- and that is the same
			# "they won it instead" case the top of this loop already handles.
			# Route back there rather than reporting a broken aim: the previous
			# version checked only at the loop top, so a knockout that landed a
			# few frames later failed the run for a beat working as designed.
			if not bool(_combat.call("is_fighting")):
				continue
			_fail("catch aim did not reopen after launch %d (%s)" % [
				launches, _why_the_aim_would_not_open(),
			])
			return false
		if not await _aim_at_wild():
			_fail("right-stick aim could not line up the real throw reticle")
			return false
		# Do not throw into a rock.
		#
		# Holding the fight put an end to it ending -- and left the player
		# standing in ONE spot for every launch. A 40-launch run from a bad spot
		# came back 1 strike / 39 misses, and the tally says why: `first_hit`
		# was `Rock_Medium_2_Collision` on 27 of them, with six explicit
		# `line_of_sight_blocked`. A boulder was in the line the whole time.
		#
		# `throw_aim.gd::launch_assist_diagnostics()` reports this BEFORE the
		# orb is committed, so the player-true move is available: see that the
		# shot is blocked, step somewhere it is not, look again. Throwing anyway
		# spends an orb into a rock, which no player does twice.
		# A blocked line is not a failed run.
		#
		# GATEB-COORD: this was the dominant flake in Gate B's continuous
		# evidence -- two thirty-minute runs died here, on the opening's first
		# and second launch, because a search for a clear shot ran out while
		# the Bramblebun wandered. A player who cannot see the thing does not
		# put the controller down; they walk somewhere else and look again.
		# So does this. The loop's own launch bound is what ends the beat, and
		# `_fight_until_catchable()` at the top keeps the creature catchable
		# while it goes on.
		if not await _step_until_the_shot_is_clear():
			blocked_lines += 1
			print("no clear line after launch %d (%d so far); moving and looking again"
				% [launches, blocked_lines])
			if blocked_lines > BLOCKED_LINES_ALLOWED:
				_fail(("could not find a spot with a clear line to the Bramblebun %d times "
					+ "running after launch %d; the shot is not being blocked by one rock")
					% [blocked_lines, launches])
				return false
			await _wander_for_a_new_angle()
			continue
		blocked_lines = 0
		# Re-aim AFTER moving, and this is not optional.
		#
		# `_step_until_the_shot_is_clear()` strafes to get a rock out of the
		# line, which moves the player -- and the aim taken above was for where
		# the player used to stand. Throwing on a stale aim is a guaranteed
		# `reticle_outside_body`, and it is exactly what the first version of
		# this did: strike rates fell from a measured 22% to 1-2 strikes per
		# 30-40 launches once the step-aside landed, which is the signature of
		# aiming and then walking away from the aim.
		if not await _aim_at_wild():
			_fail("right-stick aim could not line up after stepping clear on "
				+ "launch %d" % launches)
			return false
		var results_before := _catch_results.size()
		var strikes_before := _throw_strikes
		var misses_before := _throw_misses
		var orbs_before := _orbs_held()
		await _tap_action(THROW_ACTION)
		launches += 1
		# A launch is not a landed throw. Wait first for the projectile's physical
		# outcome, so a miss advances the retry immediately instead of spending the
		# full catch-resolution budget waiting for a signal that only a strike can
		# emit. This distinction exposed the old false inference: eight committed
		# orbs were reported as eight catch attempts even when none had landed.
		for _i in 360:
			if (_throw_strikes > strikes_before or _throw_misses > misses_before
					or not bool(_combat.call("is_fighting"))):
				break
			await _tree.physics_frame
		if _orbs_held() <= 0:
			_fail("launch %d left the satchel empty during the tutorial catch; the opening is now a dead end (opening.json catch_orb_floor did not apply)" % launches)
			return false
		if not restocked and _orbs_held() > 1:
			restocked = true
			_checkpoint("running dry restocked the tutorial satchel to %d orb(s)" % _orbs_held())
		if _throw_misses > misses_before:
			print("physical launch %d went wide; retrying after a real miss" % launches)
			continue
		if _throw_strikes <= strikes_before:
			# A REFUSED throw is not a broken launch.
			#
			# `throw_aim.gd::_release()` now declines a locked-on throw the orb
			# cannot physically reach (past v^2/g, about 20m) rather than
			# spending the orb on it. The refusal costs nothing, so the satchel
			# is the tell: no orb left the bag, so no orb was thrown, and there
			# is no strike or miss coming to wait for. The player's answer to
			# "too far to throw" is to close the distance, so that is what this
			# does -- reporting it as a broken launch is how this read before
			# the game learned to refuse.
			if _orbs_held() == orbs_before:
				print("launch %d refused (nothing spent); closing the distance" % launches)
				launches -= 1
				refusals += 1
				if refusals > 8:
					# Parenthesised. `%` binds tighter than `+`, so this used to
					# format the SECOND fragment -- which has no placeholder --
					# and the run's own failure line came out containing a
					# literal "%d" beside a "not all arguments converted" engine
					# error. The message a failing run prints is the evidence;
					# it does not get to be broken too.
					_fail(("the throw was refused %d times; the trainer never got "
						+ "within the orb's range of the Bramblebun") % refusals)
					return false
				# Chase the LIVE body, not where it was when the throw was
				# refused. See `_close_to_wild()`.
				await _close_to_wild(AIM_THROWABLE_METRES, 900)
				for _i in 6:
					await _tree.physics_frame
				continue
			_fail("physical launch %d produced no strike or miss outcome" % launches)
			return false
		for _i in 900:
			if _catch_results.size() > results_before or not bool(_combat.call("is_fighting")):
				break
			await _tree.physics_frame
		if _catch_results.size() > results_before and _catch_results[-1]:
			_checkpoint("physical landed throw caught Bramblebun on launch %d (%d strike(s), %d miss(es))" % [
				launches, _throw_strikes, _throw_misses,
			])
			return true
	_fail("forty natural weakened-target launches produced %d strike(s), %d miss(es), and no catch" % [
		_throw_strikes, _throw_misses,
	])
	return false


## How many orbs of any tier the player is actually carrying, read off the real
## satchel rather than off `throw_aim.stock()` -- the point is to check the
## inventory the floor writes to, not the accessor that reads it.
func _orbs_held() -> int:
	var total := 0
	for id: String in ["orb_basic", "orb_greater", "orb_prime"]:
		total += int(_game.inventory.count(id))
	return total


## Leave exactly one orb in the satchel. Returns what is left, or -1 if the
## opening never handed any over -- which is its own failure and is reported as
## one rather than silently passing an emptied-satchel test.
func _drain_satchel_to_last_orb() -> int:
	var held := _orbs_held()
	if held <= 0:
		_fail("the opening reached the tutorial catch with no orbs at all; Grandpa's gift never landed")
		return -1
	if held > 1:
		_game.inventory.remove("orb_basic", held - 1)
	return _orbs_held()


## Open a fresh physical aim after any preceding throw's lockout.
##
## `try_begin_aim()` intentionally ignores input during its cooldown and emits
## no refusal. A single press cannot distinguish that expected lockout from a
## dropped controller input, so use the same bounded retry pattern as the
## focused controller-catching smoke.
func _open_throw_aim() -> bool:
	for _attempt in 18:
		# A fainted target refuses the aim outright -- combat_manager.gd's
		# `_catch_refusal()`, "<name> is out cold, too late to catch it". That
		# is not a stuck cooldown and pressing harder will not fix it: your OWN
		# creature is fighting the Bramblebun while you throw at it (the launch
		# log shows `first_hit=AllyCreature` for the orbs it intercepts), and
		# over a long catch it can knock the thing out before you land one. The
		# encounter director stands it back up after a few seconds, so a player
		# waits -- and so does this, rather than reporting a cooldown fault for
		# something that is not one.
		if _target_is_out_cold():
			for _i in 240:
				await _tree.physics_frame
				if not _target_is_out_cold() or not bool(_combat.call("is_fighting")):
					break
			continue
		await _tap_action(THROW_ACTION)
		for _i in 6:
			if bool(_combat.call("is_aiming")):
				return true
			await _tree.physics_frame
	return false


## Is the creature we are throwing at currently fainted?
##
## Read off the fight's own enemy record rather than the body, because that is
## what `combat_manager.gd` consults before it will open an aim.
func _target_is_out_cold() -> bool:
	if _combat == null or not bool(_combat.call("is_fighting")):
		return false
	var foe: RefCounted = _combat.call("enemy") as RefCounted
	return foe != null and bool(foe.get("fainted"))


## Drive the right stick until the CAMERA IS ACTUALLY LOOKING AT `target`.
##
## The error minimised here is the angle between the aim camera's own forward
## vector and the direction from that camera to the body -- which is precisely
## the quantity `throw_aim.gd::launch_assist_diagnostics()` reports as
## `reticle`, and precisely what decides whether a throw gets launch assist.
##
## The previous version compared an angle computed FROM THE CAMERA'S POSITION
## against `_rig.yaw`, the rig PIVOT's yaw. Those are the same number only when
## the camera sits on the pivot. It does not: `try_begin_aim()` swaps the rig
## to `catching.json`'s over-the-shoulder aim config, which offsets the camera
## sideways from the pivot. So the loop drove a systematically wrong error to
## zero, declared itself aimed within 2 degrees, and the game then measured the
## reticle 1.4 body-radii off the creature and refused the assist
## (`reason=reticle_outside_body`). That is the whole of the "eight launches, 1
## strike, 7 misses" signature the Gate B evidence doc filed as a catching
## defect: the throws were aimed at nothing, by the harness, not by the player.
##
## T2-FLAKE rewrote how it DRIVES that error to zero. See
## `_calibrated_deflection()` for the measurement that forced it; the short of
## it is that this loop samples once per frame and the plant it is steering
## integrates real seconds, so its step size was a function of machine load and
## the loop could not stop on a busy runner. It is now sampled on the frame the
## camera actually turns on, and its step is measured rather than assumed.
func _aim_camera_at(target: Node3D, seconds: float = AIM_CONVERGE_SECONDS) -> bool:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return false
	_aim_has_history = false
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	var last_error := 0.0
	while Time.get_ticks_msec() < deadline:
		# Re-read the live camera transform every frame: moving the stick moves
		# the camera, so an error computed once is stale immediately.
		var to := (target.call("centre") as Vector3) - camera.global_position
		if to.length() < 0.01:
			_stop_right_stick()
			return true
		var forward := -camera.global_transform.basis.z
		var wanted := to.normalized()
		# Split the one angular error into the two axes the sticks drive, in
		# CAMERA space, so each stick is corrected by its own component.
		var right := camera.global_transform.basis.x
		var up := camera.global_transform.basis.y
		var yaw_error := atan2(wanted.dot(right), wanted.dot(forward))
		var pitch_error := atan2(wanted.dot(up), wanted.dot(forward))
		last_error = rad_to_deg(forward.angle_to(wanted))
		if absf(yaw_error) < deg_to_rad(AIM_WINDOW_DEGREES) \
				and absf(pitch_error) < deg_to_rad(AIM_WINDOW_DEGREES):
			_stop_right_stick()
			return true
		# One deflection, split across the two axes by the direction of the
		# error rather than per-axis. `camera_rig.gd::_apply_look()` bends the
		# stick by its LENGTH (`response_exponent`) and scales it by the same
		# length again (`aim_assist_scale`), so the two axes are already coupled
		# through it; correcting them independently meant neither one was the
		# quantity the rig actually responds to.
		var deflection := _calibrated_deflection(forward, last_error)
		var direction := Vector2(yaw_error, pitch_error).normalized()
		_send_axis(JOY_AXIS_RIGHT_X, direction.x * deflection)
		_send_axis(JOY_AXIS_RIGHT_Y, -direction.y * deflection)
		# The camera turns in `_process`, so that is the frame this samples on.
		# Sampling on `physics_frame` meant every process frame in between
		# applied the same stale stick, and the loop only ever saw the sum.
		await _tree.process_frame
	_stop_right_stick()
	var camera_pitch := rad_to_deg(camera.global_rotation.x)
	print(("aim convergence stopped %.2f° off the body after %.0fs "
		+ "(camera pitch %.1f°, target %.2fm away and %.2fm below the lens; "
		+ "one sample = %.2f° in %.0fms at deflection %.2f)") % [
		last_error, seconds, camera_pitch,
		_player.global_position.distance_to(target.global_position),
		camera.global_position.y - (target.call("centre") as Vector3).y,
		_aim_sample_turn, _aim_sample_seconds * 1000.0, _aim_deflection])
	return false


## How far to push the stick this sample, measured rather than assumed.
##
## T2-FLAKE. This replaces a fixed response curve -- full deflection above six
## degrees of error, proportional below it, floored at 0.18 -- and that curve is
## the whole of the opening segment's flake. The reason it is not a tuning
## mistake but a category one:
##
## `camera_rig.gd::_apply_look()` turns the camera by `f(|stick|) * sensitivity
## * delta` degrees, where `delta` is REAL SECONDS. This loop reads the error
## once per frame, so the turn it gets per sample is proportional to how long a
## frame took -- 16.6ms on an idle machine here, measured at 300ms under
## CI-like load. The old curve's step at error `e` was therefore `104.5 *
## (e/6)^2 * delta` degrees, which shrinks the error only while
## `e < 0.689 / delta`. Unloaded that bound is 41 degrees and everything
## converges. At a 157ms frame it is 4.4 degrees, and the loop limit-cycles
## there forever -- which is exactly, to two decimal places, what the failing
## runs printed: "aim convergence stopped 4.44° off the body", four times over,
## before failing with "right-stick aim could not line up the real throw
## reticle". The game was fine; the harness's controller was tuned to a frame
## rate.
##
## So this measures the plant instead of assuming it: `turned` is how far the
## camera actually moved for the deflection commanded last sample, and the
## correction is the ratio of what is left to what that bought. Nothing here
## knows the rig's sensitivity, its response exponent, its assist curve or its
## two deadzones, and it does not need to -- it observes their product, which is
## also the only form in which they can change underneath it.
##
## The correction is the SQUARE ROOT of that ratio, not the ratio. The rig's
## response is convex (`catching.json`'s aim profile squares the deflection), so
## a linear correction overshoots whenever it asks for more turn and the loop
## rings; the root is exact for that profile and under-corrective for any
## gentler one, which converges from above instead of oscillating.
func _calibrated_deflection(forward: Vector3, error_degrees: float) -> float:
	var turned := 0.0
	var seconds := 0.0
	if _aim_has_history:
		turned = rad_to_deg(_aim_forward_before.angle_to(forward))
		seconds = float(Time.get_ticks_usec() - _aim_sampled_usec) / 1000000.0
	_aim_forward_before = forward
	_aim_sampled_usec = Time.get_ticks_usec()
	_aim_has_history = true
	if turned <= AIM_STILL_DEGREES:
		# The stick bought nothing. Either this is the first sample of the call
		# and there is no history to calibrate against, or the deflection has
		# fallen under a deadzone -- the `look_*` actions carry their own (0.2
		# in project.godot, rescaling what survives) and `camera_rig.gd` applies
		# a second one on top. Open the stick up rather than sit at a value the
		# rig discards.
		_aim_deflection = clampf(_aim_deflection * 2.0, _smallest_live_deflection(), 1.0)
		return _aim_deflection
	_aim_sample_turn = turned
	_aim_sample_seconds = seconds
	_aim_deflection = clampf(_aim_deflection * sqrt(error_degrees / turned),
		_smallest_live_deflection(), 1.0)
	return _aim_deflection


## The smallest stick deflection that is an input at all.
##
## Read off the two deadzones in force rather than written down: the `look_*`
## InputMap actions drop anything shorter than their own deadzone and rescale
## the remainder, and `camera_rig.gd` then drops anything shorter than the
## profile's `stick_deadzone`. A constant here would be a third copy of two
## tunables and would go stale the first time either moved.
func _smallest_live_deflection() -> float:
	var action := 0.2
	if InputMap.has_action(&"look_right"):
		action = InputMap.action_get_deadzone(&"look_right")
	var rig := 0.18
	if _rig != null and _rig.get("_deadzone") != null:
		rig = float(_rig.get("_deadzone"))
	# Undo `Input.get_vector()`'s rescale, then leave a little over the edge.
	return minf(0.99, action + rig * (1.0 - action) + 0.01)


## Aim at the wild creature, and MOVE if standing still cannot line the shot up.
##
## `_aim_camera_at()` alone was the whole of this, and it fails in two ways that
## are not the harness driving the stick wrongly, both measured on this branch:
##
## - **Too close to look down at.** `catching.json`'s aim profile clamps the aim
##   camera to `pitch_min_deg: -35` and puts the lens `height: 1.78` above the
##   trainer, so a Bramblebun that has circled inside about two metres is more
##   than 35 degrees below the camera and cannot be centred however long the
##   stick is held. One run reported "aim convergence stopped 37.06° off the
##   body", which is that clamp and nothing else.
## - **Too far to throw at.** `throw_aim.gd` refuses a locked-on throw past the
##   orb's own reach (~20.6m). A creature that has drifted to 25-30m during the
##   fight leaves the loop centring a target it could never have thrown at, and
##   a run then spends its whole refusal budget standing there.
##
## A player answers both by walking -- back for the first, forward for the
## second -- so that is what this does, tracking the LIVE body rather than a
## captured coordinate. It also defers to the game's own pre-launch verdict:
## `launch_assist_diagnostics().eligible` is what actually decides whether the
## throw gets its assist, and when the game says the reticle is on the creature
## this loop's tighter one-degree window has no standing to disagree.
func _aim_at_wild(seconds: float = AIM_CONVERGE_SECONDS) -> bool:
	if await _aim_camera_at(_wild, seconds):
		return true
	if _shot_is_eligible():
		return true
	for _attempt in AIM_BACKOFF_TRIES:
		if not is_instance_valid(_wild) or not bool(_combat.call("is_fighting")):
			return false
		var gap := _player.global_position.distance_to(_wild.global_position)
		if gap > AIM_THROWABLE_METRES:
			print("aim: %.1fm is past the orb's reach; closing in" % gap)
			await _close_to_wild(AIM_THROWABLE_METRES, 900)
		elif gap < AIM_TOO_CLOSE_METRES:
			var away := _player.global_position - _wild.global_position
			away.y = 0.0
			if away.length() < 0.05:
				away = Vector3.FORWARD
			print("aim: %.1fm is too steep to centre; backing off %.1fm" % [
				gap, AIM_BACKOFF_METRES])
			await _drive_body_toward(_player,
				_player.global_position + away.normalized() * AIM_BACKOFF_METRES, 30)
			_stop_left_stick()
			for _i in 6:
				await _tree.physics_frame
		if await _aim_camera_at(_wild, seconds):
			return true
		if _shot_is_eligible():
			return true
	return false


## Walk at the live creature until it is inside `within` metres.
##
## Re-aimed EVERY frame (`_drive_body_toward` with a one-frame hold), which the
## static 220-frame chase it replaces was not: that one pushed the stick at
## where the Bramblebun had been and arrived at empty grass, which is how a run
## sat at 21-30m through eight refusals while "closing the distance" every time.
func _close_to_wild(within: float, budget: int) -> bool:
	for _i in budget:
		if not is_instance_valid(_wild) or not bool(_combat.call("is_fighting")):
			_stop_left_stick()
			return false
		if _player.global_position.distance_to(_wild.global_position) <= within:
			_stop_left_stick()
			for _j in 5:
				await _tree.physics_frame
			return true
		await _drive_body_toward(_player, _wild.global_position, 1)
	_stop_left_stick()
	return false


## The game's own answer to "would this throw get its launch assist right now".
func _shot_is_eligible() -> bool:
	if _combat == null or not bool(_combat.call("is_fighting")):
		return false
	var throw: Node = _combat.call("throw_aim")
	if throw == null or not throw.has_method("launch_assist_diagnostics"):
		return false
	return bool((throw.call("launch_assist_diagnostics") as Dictionary).get("eligible", false))


func _walk_to_and_activate(target: Node3D, budget: int) -> bool:
	if not await _walk_toward(target.global_position, budget, 2.0):
		return false
	await _tap_action("interact")
	return true


## Wild creatures wander while the trainer crosses the meadow. Following the
## position captured at the farmhouse door can therefore stop at empty grass,
## unlike a player who keeps the visible creature in view. Reach the live body
## and wait until the production arbiter actually publishes EncounterDirector's
## actionable offer before sending the same physical Interact press a player
## uses. This observes readiness; it does not activate the arbiter directly.
func _walk_to_and_engage_wild(target: Node3D, budget: int) -> bool:
	var closest := INF
	for _i in budget:
		if not is_instance_valid(target):
			print("wild approach: target despawned")
			_stop_left_stick()
			return false
		var distance := _player.global_position.distance_to(target.global_position)
		closest = minf(closest, distance)
		var winner: Object = _arbiter.call("winning_provider")
		var offer := _arbiter.call("winner") as Dictionary
		if winner == _encounter and bool(offer.get("actionable", false)):
			_stop_left_stick()
			for _j in 3:
				await _tree.physics_frame
			# Recheck after releasing movement: the target may have crossed the
			# edge of the interaction radius during those settling frames.
			winner = _arbiter.call("winning_provider")
			offer = _arbiter.call("winner") as Dictionary
			if winner == _encounter and bool(offer.get("actionable", false)):
				print("wild approach: ready at %.2fm with '%s'" % [
					_player.global_position.distance_to(target.global_position),
					str(_arbiter.call("prompt")),
				])
				await _tap_action("interact")
				return true
		await _drive_body_toward(_player, target.global_position, 1)
	_stop_left_stick()
	print("wild approach: exhausted after closest %.2fm; final %.2fm; visible=%s alive=%s prompt='%s' winner=%s" % [
		closest,
		_player.global_position.distance_to(target.global_position),
		target.visible,
		bool(target.call("is_alive")),
		str(_arbiter.call("prompt")),
		str(_arbiter.call("winning_provider")),
	])
	return false


func _walk_toward(point: Vector3, budget: int, close_enough: float = 0.8) -> bool:
	for _i in budget:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= close_enough:
			_stop_left_stick()
			for _j in 5:
				await _tree.physics_frame
			return true
		await _drive_body_toward(_player, point, 1)
	_stop_left_stick()
	return false


func _drive_body_toward(body: Node3D, point: Vector3, frames: int) -> void:
	var direction := point - body.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		_stop_left_stick()
		return
	var basis: Basis = _rig.call("planar_basis")
	var local := basis.inverse() * direction.normalized()
	_send_axis(JOY_AXIS_LEFT_X, local.x)
	_send_axis(JOY_AXIS_LEFT_Y, local.z)
	for _i in frames:
		await _tree.physics_frame


func _close_dialogue(max_presses: int) -> bool:
	for _i in max_presses:
		if not bool(_dialogue.call("is_open")):
			return true
		await _tap_action("interact")
	return not bool(_dialogue.call("is_open"))


func _tap_action(action: StringName) -> void:
	var event := _event_for(action, true)
	if event == null:
		_fail("'%s' has no physical joypad binding" % action)
		return
	Input.parse_input_event(event)
	for _i in 3:
		await _tree.physics_frame
	var released := event.duplicate() as InputEvent
	if released is InputEventJoypadButton:
		(released as InputEventJoypadButton).pressed = false
	elif released is InputEventJoypadMotion:
		(released as InputEventJoypadMotion).axis_value = 0.0
	Input.parse_input_event(released)
	for _i in 5:
		await _tree.physics_frame


func _event_for(action: StringName, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for configured in InputMap.action_get_events(action):
		if configured is InputEventJoypadButton:
			var button := InputEventJoypadButton.new()
			button.button_index = (configured as InputEventJoypadButton).button_index
			button.pressed = pressed
			return button
		if configured is InputEventJoypadMotion:
			var motion := InputEventJoypadMotion.new()
			motion.axis = (configured as InputEventJoypadMotion).axis
			motion.axis_value = (configured as InputEventJoypadMotion).axis_value if pressed else 0.0
			return motion
	return null


func _required_pad_actions_exist() -> bool:
	# `combat_throw` is deliberately absent: CONTROLLER-MAP left it keyboard-only
	# and requiring a pad binding for it failed this whole run at boot.
	for action in [&"ui_accept", &"ui_right", &"ui_down", &"menu_confirm", &"interact", &"combat_quick"]:
		if _event_for(action, true) == null:
			_fail("required action '%s' has no physical joypad binding" % action)
	return _failures.is_empty()


func _send_axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _stop_left_stick() -> void:
	_send_axis(JOY_AXIS_LEFT_X, 0.0)
	_send_axis(JOY_AXIS_LEFT_Y, 0.0)


func _stop_right_stick() -> void:
	_send_axis(JOY_AXIS_RIGHT_X, 0.0)
	_send_axis(JOY_AXIS_RIGHT_Y, 0.0)


func _find_interactable(words: Array[String]) -> Node3D:
	for node in _descendants(_world):
		if not node is Node3D:
			continue
		var script := node.get_script() as Script
		if script == null or script.resource_path != INTERACTABLE_SCRIPT or not bool(node.get("enabled")):
			continue
		var lowered := str(node.get("label")).to_lower()
		for word in words:
			if lowered.contains(word.to_lower()):
				return node as Node3D
	return null


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


func _find_by_method(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child in node.get_children():
		var found := _find_by_method(child, method)
		if found != null:
			return found
	return null


func _find_by_script(node: Node, path: String) -> Node:
	var script := node.get_script() as Script
	if script != null and script.resource_path == path:
		return node
	for child in node.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


func _checkpoint(label: String) -> void:
	_transcript.append(label)
	print("GATE A OPENING +%.2fs — %s" % [(Time.get_ticks_msec() - _started_ms) / 1000.0, label])


func _fail(message: String) -> void:
	if not _failures.has(message):
		_failures.append(message)
	push_error(message)


func _why_the_aim_would_not_open() -> String:
	if _combat == null:
		return "no CombatManager"
	if not bool(_combat.call("is_fighting")):
		return "the fight had already ended"
	var foe: RefCounted = _combat.call("enemy") as RefCounted
	if foe == null:
		return "the fight has no enemy record"
	if bool(foe.get("fainted")):
		return "%s was still out cold after the respawn wait" % str(foe.get("display_name"))
	if _orbs_held() <= 0:
		return "the satchel was empty and the floor did not refill it"
	return "the aim simply never opened; orbs=%d, target upright" % _orbs_held()


## Wait for the encounter director to put the practice creature back up.
##
## Returns the live body, or null if none came back inside the budget. Asked of
## the director rather than by node name: the respawn is a NEW body, so a cached
## `_wild` from before the knockout is a freed handle.
## The budget is the RESPAWN, not a round number. 900 physics frames is 15
## simulated seconds at Godot's 60Hz fixed step, and
## `encounter_director.gd::_respawn_delay()` reads `respawn_seconds` from
## spawns.json, which is 45.0. So this could never once have seen the creature
## come back: it gave up three times too early, every time, and reported it as
## "no Bramblebun came back" -- a starved wait dressed up as a missing respawn.
##
## It looked intermittent only because it is reached intermittently. A run whose
## catch lands before the fight ends never waits here at all; a run that needs a
## re-engage always failed. Read from the same config the director reads so a
## respawn_seconds edit moves both together, with a margin for the beat between
## the timer firing and the body being up and visible.
func _wait_for_the_bramblebun_back_on_its_feet() -> Node3D:
	var respawn := 45.0
	var file := FileAccess.open("res://data/config/spawns.json", FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			respawn = float((parsed as Dictionary).get("respawn_seconds", 45.0))
	var budget := int((respawn + 15.0) * 60.0)
	for _i in budget:
		var body := _encounter.call("wild_creature") as Node3D
		if body != null and is_instance_valid(body) and body.visible \
				and body.has_method("is_alive") and bool(body.call("is_alive")):
			return body
		await _tree.physics_frame
	return null


## Keep the Bramblebun weakened-but-alive and the starter on its feet.
##
## Neither creature's HP is the subject of this harness -- the subject is
## whether a real controller-driven throw catches the creature -- and letting
## them drift turns every long catch into a race the fight can end on its own.
func _hold_the_fight_where_it_was() -> void:
	if _combat == null or not bool(_combat.call("is_fighting")):
		return
	var foe: RefCounted = _combat.call("enemy") as RefCounted
	if foe != null and _weakened_hp > 0.0 and float(foe.get("hp")) < _weakened_hp:
		foe.set("hp", _weakened_hp)
		foe.set("fainted", false)
	var own: RefCounted = _combat.call("active_creature") as RefCounted
	if own != null:
		own.set("hp", own.get("max_hp"))
		own.set("fainted", false)


## Move until the throw has a clear line, then re-aim. True if it does.
##
## Reads the game's own pre-launch verdict rather than guessing at geometry:
## `eligible` is exactly the condition that decides whether the throw gets its
## launch assist, and `first_hit` names whatever is in the way when it does not.
## Consecutive launches that may find no clear line before the beat is called
## broken. Generous on purpose: one blocked line is ordinary meadow, and the
## creature moves between every attempt.
const BLOCKED_LINES_ALLOWED := 8


## Walk somewhere genuinely different and look again. Not a strafe -- the
## strafing inside `_step_until_the_shot_is_clear()` has already been tried and
## exhausted by the time this runs.
func _wander_for_a_new_angle() -> void:
	if not is_instance_valid(_wild):
		return
	var to := _wild.global_position - _player.global_position
	to.y = 0.0
	if to.length() < 0.05:
		to = Vector3.FORWARD
	# A quarter turn around the creature, at a comfortable throwing radius.
	var around := to.normalized().rotated(Vector3.UP, PI * 0.5) * THROW_RANGE_WANTED
	await _drive_body_toward(_player, _wild.global_position + around, 90)
	_stop_left_stick()
	for _i in 10:
		await _tree.physics_frame
	await _aim_camera_at(_wild, AIM_REAIM_SECONDS)


## How close the trainer wants to be before hunting sideways for a clear line.
##
## Derived from the two bounds this file already has rather than picked: inside
## `AIM_TOO_CLOSE_METRES` the camera cannot centre the reticle at all ("too
## steep to centre"), and past `AIM_THROWABLE_METRES` the orb will not reach.
## Halfway between is the band where both are comfortably true. GATEB-COORD
## first set this to 6.0 and traded one flake for another -- the creature
## wanders, six metres becomes four, and the run failed with "right-stick aim
## could not line up the real throw reticle" instead.
const THROW_RANGE_WANTED := (AIM_TOO_CLOSE_METRES + AIM_THROWABLE_METRES) * 0.5


func _step_until_the_shot_is_clear() -> bool:
	var throw: Node = _combat.call("throw_aim")
	if throw == null or not throw.has_method("launch_assist_diagnostics"):
		return true
	# GATEB-COORD: twenty-four, not twelve, and the sidestep widens as it goes.
	#
	# The wild creature is WANDERING while this looks for a line, so the spot
	# that clears the shot moves too; a fixed twelve identical 3m strafes ran
	# out mid-search often enough to fail whole thirty-minute runs on the
	# opening's second launch. A player keeps circling until they can see the
	# thing, and each step out is a little wider than the last.
	for attempt in 24:
		var report: Dictionary = throw.call("launch_assist_diagnostics")
		if bool(report.get("eligible", false)):
			return true
		var blocked_by := str(report.get("first_hit", "unavailable"))
		var reason := str(report.get("reason", "unavailable"))
		# Nothing is in the way when the thing the ray hits IS the creature: the
		# reticle is simply not on it yet, and the answer to that is to aim
		# again, not to walk. Strafing here made it worse -- a run logged eight
		# consecutive "shot blocked by Wild_bramblebun_0_2 (reticle_outside_body);
		# stepping aside" while the Bramblebun drifted from 21m to 36m, because
		# each sidestep is 3m of travel spent not closing.
		if is_instance_valid(_wild) and blocked_by.begins_with(str(_wild.name)):
			if await _aim_at_wild(AIM_REAIM_SECONDS):
				continue
			print("re-aim on the creature itself failed (%s); stepping aside" % reason)
		# CLOSE FIRST, strafe second.
		#
		# GATEB-COORD: sideways is what clears a line past something standing
		# in it, and that reasoning is right -- but it was being applied from
		# twenty and thirty metres out, where the meadow puts a boulder or a
		# tree in almost every line and one strafe simply swaps which one. The
		# shortest line has the least in it, so distance is closed until the
		# creature is within `THROW_RANGE_WANTED` and only then is the search
		# sideways. This flake cost two whole thirty-minute continuous runs on
		# the opening's second launch.
		var to := _wild.global_position - _player.global_position
		to.y = 0.0
		var step := Vector3.ZERO
		if to.length() > THROW_RANGE_WANTED:
			step = _player.global_position \
				+ to.normalized() * minf(to.length() - THROW_RANGE_WANTED + 1.0, 8.0)
			print("shot blocked by %s (%s) from %.1fm; closing in" % [
				blocked_by, reason, to.length()])
		else:
			var sideways := to.cross(Vector3.UP).normalized()
			if attempt % 2 == 1:
				sideways = -sideways
			step = _player.global_position + sideways * (2.0 + 0.5 * float(attempt / 2))
			print("shot blocked by %s (%s) from %.1fm; stepping aside" % [
				blocked_by, reason, to.length()])
		await _drive_body_toward(_player, step, 26)
		_stop_left_stick()
		for _i in 6:
			await _tree.physics_frame
		if not await _aim_camera_at(_wild, AIM_REAIM_SECONDS):
			continue
	var final: Dictionary = throw.call("launch_assist_diagnostics")
	return bool(final.get("eligible", false))


## The live handles the caller needs to carry on in this same world.
func _result() -> Dictionary:
	_stop_left_stick()
	_stop_right_stick()
	return {
		"passed": _failures.is_empty(),
		"failures": _failures.duplicate(),
		"transcript": _transcript.duplicate(),
		"world": _world,
		"game": _game,
		"player": _player,
		"rig": _rig,
	}
