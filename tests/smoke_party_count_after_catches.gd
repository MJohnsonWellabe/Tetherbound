extends SceneTree

## OP21-14 regression. `tests/test_hud_widgets.gd`'s party-strip coverage
## hand-builds an entries array and calls `party_strip.gd::update_from_party`
## directly -- it proves the widget can format a number, never that three real
## catches (`EncounterDirector._resolve_catch` -> `Party.add` -> the revision
## bump `playground_hud.gd::_update_party_strip` gates on) actually produce
## that number on screen. This performs three REAL catches through the real
## throw/resolve minigame -- the same production creature and approach
## `smoke_catching.gd` proves reliable, caught three times over as it respawns
## -- and reads the on-screen TEAM counter and the party strip's own
## visible-portrait count straight off the real `PlaygroundHUD` node in the
## real world scene, not a hand-called widget method. Then it saves and
## reloads through `Game` and checks the count survives that round trip too.
##
##   godot --headless --path . --script tests/smoke_party_count_after_catches.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const MATH := preload("res://scripts/combat/combat_math.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")

const SETTLE_FRAMES := 300
const MAX_ATTEMPTS := 25
const TEST_DIR := "user://party_count_smoke_saves/"
const TEST_SLOT := 2
## Real spawns.json respawn delay plus headroom, the same budget
## `smoke_catching.gd::_a_fainted_creature_cannot_be_caught` waits.
const RESPAWN_FRAME_BUDGET := 4500

var _failures: Array[String] = []
## Where the approach walk began and how many frames it spent, so a failing
## engage can say whether the body was blocked or merely fell short.
var _walk_started_at: Vector3 = Vector3.ZERO
var _walk_frames_spent: int = 0
var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _manager: Node = null
var _director: Node = null
var _game: Node = null
var _hud: Node = null
var _resolutions: Array[bool] = []


func _init() -> void:
	_run()


func _run() -> void:
	_wipe_test_dir()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	await _ensure_ally()
	_seed_orbs()
	if not _collect_nodes():
		_report()
		return
	_leave_the_farmhouse()
	_game.set("save_system", SAVE_GAME.new(TEST_DIR))

	# Three DIFFERENT already-live wild bodies rather than the same one three
	# times over: each real catch costs one throw-fight regardless, and
	# waiting out the respawn timer twice between them (spawns.json,
	# ~45s each) added nothing this regression needs to prove.
	var targets := (_director.call("wild_creatures") as Array).duplicate()
	if targets.size() < 3:
		_fail("fewer than 3 live wild creatures exist to catch (%d)" % targets.size())
		targets = []
	for i in 3:
		var target: Node3D = (targets[i] as Node3D) if i < targets.size() else null
		if target == null or not is_instance_valid(target):
			_fail("catch %d: no live wild creature to catch" % (i + 1))
			break
		await _catch_real_creature(target)
		for f in 20:
			await physics_frame
		var party: RefCounted = _game.get("party")
		if int(party.call("size")) != i + 1:
			_fail("after catch %d, Game.party.size() is %d, expected %d" % [i + 1, int(party.call("size")), i + 1])

	_check_hud_reads(3, "after three real catches")

	if not bool(_game.call("save_game", TEST_SLOT)):
		_fail("could not save after three real catches")
	else:
		if not bool(_game.call("load_game", TEST_SLOT)):
			_fail("could not reload the just-written save")
		# `load_game()` restores the party synchronously, but the strip redraws
		# from it on its own signal, so a FIXED frame budget races that redraw
		# on a loaded host rather than testing anything.
		#
		# Measured, CI run 2476: this job went red on the two HUD assertions
		# while `Game.party.size()` was 3 -- that check sits above them and
		# accumulates rather than returning, so its silence is positive
		# evidence the save round-trip itself was correct and only the on-screen
		# count lagged. Ten frames was simply not enough on that runner.
		#
		# Waiting for the redraw with a ceiling keeps the assertion exactly as
		# strong: a HUD that never catches up still fails, just not by a race.
		await _await_hud_reads(3, 240)
		var party: RefCounted = _game.get("party")
		if int(party.call("size")) != 3:
			_fail("party size after reload is %d, expected 3" % int(party.call("size")))
		_check_hud_reads(3, "after save/reload")

	_wipe_test_dir()
	_report()


## Wait until the party strip's own TEAM label agrees with `expected`, or
## `max_frames` physics frames elapse, whichever comes first. Deliberately
## silent about the outcome: the caller still runs `_check_hud_reads()` and
## still fails if the HUD never caught up. This only removes the race.
func _await_hud_reads(expected: int, max_frames: int) -> void:
	var expected_text := "TEAM  %d / 5" % expected
	for f in max_frames:
		var strip: Control = _hud.get("_party_strip") as Control
		if strip != null:
			var label: Label = strip.get("_count_label") as Label
			if label != null and label.text == expected_text:
				return
		await physics_frame


func _check_hud_reads(expected: int, context: String) -> void:
	var strip: Control = _hud.get("_party_strip") as Control
	if strip == null:
		_fail("%s: PlaygroundHUD has no party strip" % context)
		return
	var label: Label = strip.get("_count_label") as Label
	if label == null:
		_fail("%s: party strip has no TEAM count label" % context)
		return
	var expected_text := "TEAM  %d / 5" % expected
	if label.text != expected_text:
		_fail("%s: on-screen TEAM count reads '%s', expected '%s'" % [context, label.text, expected_text])
	else:
		print("%s: TEAM counter correctly reads '%s'" % [context, label.text])

	# A vacant slot hides its HP bar and shows the bare slot-number label
	# instead (`party_strip.gd::_update_row`); rows themselves stay visible
	# for all 5 slots always, so occupancy has to be read off those two
	# per-row fields rather than `Control.visible` on the row itself.
	var hp_bars: Array = strip.get("_hp_bars") as Array
	var slot_labels: Array = strip.get("_slot_labels") as Array
	if hp_bars == null or hp_bars.is_empty() or slot_labels == null or slot_labels.is_empty():
		_fail("%s: party strip built no rows to check" % context)
		return
	var occupied := 0
	for i in hp_bars.size():
		var occupied_row: bool = bool((hp_bars[i] as ProgressBar).visible) \
			and not bool((slot_labels[i] as Label).visible)
		if occupied_row:
			occupied += 1
	if occupied != expected:
		_fail("%s: party strip shows %d occupied portrait row(s), expected %d" % [context, occupied, expected])
	else:
		print("%s: party strip shows %d occupied portrait(s), agreeing with the counter" % [context, occupied])


func _ensure_ally() -> void:
	var director := _world.get_node_or_null(^"EncounterDirector")
	if director == null or director.call("ally_instance") != null:
		return
	await director.call("adopt_starter", "terrapup", "Counter")


## Same escape `smoke_catching.gd::_leave_the_farmhouse()` uses: the opening
## wakes the trainer inside Grandpa's house, and this test is not the opening
## -- it needs open meadow between the trainer and the practice cluster, not
## a farmhouse wall.
func _leave_the_farmhouse() -> void:
	if _player == null:
		return
	var start := Vector3(48.0, 0.0, -58.0)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO


func _wait_for_the_practice_creature_to_respawn() -> bool:
	for i in RESPAWN_FRAME_BUDGET:
		await physics_frame
		var candidate := _director.call("wild_creature") as Node3D
		if candidate != null and candidate.visible and bool(candidate.call("is_alive")):
			return true
	return false


func _seed_orbs(count: int = 30) -> void:
	var game := root.get_node_or_null(^"/root/Game")
	if game == null:
		_fail("no Game autoload; nowhere to put orbs")
		return
	var inventory: RefCounted = game.get("inventory")
	var short: int = count - int(inventory.call("count", "orb_basic"))
	if short > 0:
		inventory.call("add", "orb_basic", short)


func _collect_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_manager = _world.get_node_or_null(^"CombatManager")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_hud = _world.get_node_or_null(^"PlaygroundHUD")
	if _game == null or _player == null or _rig == null or _manager == null \
			or _director == null or _hud == null:
		_fail("scene is missing Game, the player, the camera rig, CombatManager, EncounterDirector or PlaygroundHUD")
		return false
	if not _manager.is_connected("catch_resolved", _on_catch_resolved):
		_manager.connect("catch_resolved", _on_catch_resolved)
	return true


func _on_catch_resolved(success: bool, _shakes: int) -> void:
	_resolutions.append(success)


## Walks over, engages the real wild body, weakens it (the same "test the
## throw wiring, not the grind" shortcut `smoke_catching.gd` uses), and throws
## real orbs at it through the real aim minigame until it is caught.
func _catch_real_creature(target: Node3D) -> void:
	# Walked in, the same way `smoke_catching.gd::_walk_to_the_wild_creature()`
	# /`_engage()` do -- proven reliable against this exact practice creature
	# and cluster, unlike a teleport that can land closer to a neighbouring
	# interactable than to the intended target and lose the real
	# InteractionArbiter's offer to it.
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	# Recorded so a FAILURE can say whether the walk was blocked or simply had
	# nowhere to go. This test fails intermittently on CI with "stopped 23.7m
	# away" against a target that sits ~23m from the run's own start point --
	# i.e. a walk that covered nothing -- and neither the distance alone nor the
	# arbiter winner distinguishes "the body could not move" from "the body
	# arrived somewhere unhelpful". Three separate local investigations failed
	# to reproduce it (all cluster targets are reachable from the start point,
	# and the fight's own stand-aside placement left eight of eight directions
	# clear in three engagements), so the next CI red has to carry its own
	# diagnosis rather than send someone else round the same loop.
	_walk_started_at = _player.global_position
	_walk_frames_spent = 0
	for i in 1500:
		if not is_instance_valid(target):
			break
		var to := target.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= engage_range * 0.6:
			break
		_aim_camera_along(to)
		Input.action_press("move_forward")
		await physics_frame
		_walk_frames_spent = i + 1
	Input.action_release("move_forward")
	for i in 10:
		await physics_frame

	# Press only once the world is actually offering THIS creature.
	#
	# Walking to within 3.6m is not the same as being the arbiter's winner: the
	# Meadows carries ~22,000 harvestable props, the arbiter picks by distance
	# and priority, and one standing a metre nearer than the Bramblebun takes
	# the line. Pressing anyway gathers a bush and reports "could not engage",
	# which is what this harness did -- "stopped 3.3m away (engage range 6.0m);
	# the winning prompt is Interactable, not the target".
	#
	# That is the GAME behaving correctly; a player would read "Gather" instead
	# of "Engage" and take a step. This does the same thing, which is also what
	# this function's own header already claims it does.
	await _close_in_until_offered(target)
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 40:
		await physics_frame
	if not bool(_manager.call("is_fighting")):
		_fail("could not engage the real wild body at %s%s" % [
			str(target.get_path()), _why_the_engage_failed(target),
		])
		return

	var caught := false
	for attempt in MAX_ATTEMPTS:
		if not bool(_manager.call("is_fighting")):
			break
		if int(_manager.call("orbs_left")) <= 1:
			_seed_orbs()
		var foe: RefCounted = _manager.call("enemy")
		foe.hp = foe.max_hp * 0.08
		var creature: RefCounted = _manager.call("active_creature")
		if creature != null:
			creature.hp = creature.max_hp

		var before := _resolutions.size()
		if not await _throw_at_the_target(target):
			continue
		for i in 700:
			await physics_frame
			if _resolutions.size() > before:
				break
		if _resolutions.size() > before and _resolutions[-1]:
			caught = true
			break

	if not caught:
		_fail("could not catch %s in %d throws" % [str(target.get_path()), MAX_ATTEMPTS])
		return
	for i in 300:
		await physics_frame
		if not bool(_manager.call("is_fighting")):
			break
	if bool(_manager.call("is_fighting")):
		_fail("a successful catch did not end the fight for %s" % str(target.get_path()))


func _throw_at_the_target(target: Node3D) -> bool:
	if not bool(_manager.call("is_aiming")):
		if not await _open_aim():
			return false
	for i in 15:
		await physics_frame
	_aim_at_the_target(target)
	for i in 4:
		await physics_frame
	Input.action_press("combat_throw")
	await physics_frame
	await physics_frame
	Input.action_release("combat_throw")
	await physics_frame
	return true


func _open_aim() -> bool:
	var cooldown := float(CATCH.config().get("throw", {}).get("cooldown", 0.9))
	var frame_time := 1.0 / float(Engine.physics_ticks_per_second)
	var budget := int(ceil(cooldown / frame_time)) + 60
	while budget > 0:
		Input.action_press("combat_throw")
		await physics_frame
		await physics_frame
		Input.action_release("combat_throw")
		await physics_frame
		budget -= 4
		for i in 6:
			await physics_frame
			budget -= 1
		if bool(_manager.call("is_aiming")):
			return true
	return false


func _aim_at_the_target(target: Node3D) -> void:
	var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
	if camera == null:
		return
	var eye := camera.global_position
	var velocity := Vector3.ZERO
	if target is CharacterBody3D:
		velocity = (target as CharacterBody3D).velocity
	var release_windup := float(CATCH.config().get("throw", {}).get("release_windup", 0.18))
	var lead_time := 8.0 / float(Engine.physics_ticks_per_second) + release_windup
	var predicted: Vector3 = (target.call("centre") as Vector3) + velocity * lead_time
	var to := predicted - eye
	_aim_camera_along(Vector3(to.x, 0.0, to.z))
	var flat := Vector2(to.x, to.z).length()
	_rig.set("pitch", atan2(to.y, maxf(flat, 0.01)))


func _aim_camera_along(direction: Vector3) -> void:
	_rig.set("yaw", atan2(-direction.x, -direction.z))


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir():
			dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("PASS: three real catches through the real minigame land in Game.party, the on-screen TEAM counter and party strip agree, and the count survives a save/reload")
		quit(0)
		return
	for message: String in _failures:
		print("FAIL: %s" % message)
	quit(1)


## Why the interact press did not start a fight.
##
## "Could not engage" is a symptom with several causes -- out of range, the
## creature already down, the arbiter offering a different interactable, the
## director declining the offer -- and the run that reported it gave no way to
## tell them apart. `docs/AGENT_WORKFLOW.md` asks a failure to say where to look.
func _why_the_engage_failed(target: Node3D) -> String:
	var reasons: Array[String] = []
	if not is_instance_valid(target):
		return " (the target body was freed before the press)"
	var to := target.global_position - _player.global_position
	to.y = 0.0
	var engage_range := float(MATH.config().get("flow", {}).get("engage_range", 6.0))
	reasons.append("stopped %.1fm away (engage range %.1fm)" % [to.length(), engage_range])
	if target.has_method("is_alive") and not bool(target.call("is_alive")):
		reasons.append("the target is not alive")
	if not target.visible:
		reasons.append("the target is not visible")
	var arbiter: Object = _hud.get("_arbiter") if _hud != null else null
	if arbiter != null and is_instance_valid(arbiter):
		if not bool(arbiter.call("enabled")):
			reasons.append("the interaction arbiter is DISABLED")
		else:
			var winner: Variant = arbiter.call("winning_provider")
			if winner == null:
				reasons.append("no prompt provider is winning -- nothing offered the press")
			elif winner is Node and not (winner as Node).is_ancestor_of(target) \
					and winner != target:
				reasons.append("the winning prompt is %s, not the target" % str((winner as Node).name))
	reasons.append("party is %d/5" % int(_game.party.size()))

	# Did the body actually travel? A walk that covered nothing was blocked; a
	# walk that covered its distance and still ended short was chasing.
	var travelled := _walk_started_at.distance_to(_player.global_position)
	reasons.append("walked %.1fm in %d frames from %.1f, %.2f, %.1f" % [
		travelled, _walk_frames_spent,
		_walk_started_at.x, _walk_started_at.y, _walk_started_at.z])
	if _walk_frames_spent > 120 and travelled < 1.0:
		reasons.append("THE BODY DID NOT MOVE -- blocked at the start, not short of the target")

	# And can it move now? Eight sweeps with the body's own shape from
	# STEP_HEIGHT up, the same predicate player_controller.gd::_entombed_at
	# uses. 0/8 is a sealed body; a low count names which way is open.
	var raised := _player.global_transform.translated(Vector3.UP * 0.35)
	var clear := 0
	for i in 8:
		var angle := TAU * float(i) / 8.0
		if not _player.test_move(raised, Vector3(sin(angle), 0.0, cos(angle)) * 0.45):
			clear += 1
	reasons.append("%d/8 directions clear now, on_wall=%s on_floor=%s" % [
		clear, str(_player.is_on_wall()), str(_player.is_on_floor())])
	return " (" + "; ".join(reasons) + ")"


## Shuffle around `target` until the interaction arbiter is offering IT.
##
## Bounded and best-effort: if nothing works the press still happens and
## `_why_the_engage_failed()` reports what was winning instead, which is more
## useful than a harness that silently gives up.
func _close_in_until_offered(target: Node3D) -> void:
	if not is_instance_valid(target):
		return
	var arbiter: Object = _hud.get("_arbiter") if _hud != null else null
	if arbiter == null or not is_instance_valid(arbiter):
		return
	for attempt in 40:
		if _arbiter_offers(arbiter, target):
			return
		# Step in a little further. The offer is distance-ranked, so closing the
		# gap is the move that changes the answer -- and the engage range is
		# generous enough that there is room to get well inside it.
		var to := target.global_position - _player.global_position
		to.y = 0.0
		if to.length() > 1.6:
			_aim_camera_along(to)
			Input.action_press("move_forward")
			for i in 8:
				await physics_frame
			Input.action_release("move_forward")
		else:
			# Already on top of it and still losing the line: circle it, so a prop
			# sharing the spot stops being the nearest thing.
			#
			# This alternated direction on EVERY attempt -- right, left, right,
			# left -- which is a net displacement of about zero. Forty attempts
			# of it left the harness oscillating on the spot beside whatever was
			# stealing the line, and it reported "stopped 1.6m away; the winning
			# prompt is Interactable, not the target" having never actually gone
			# anywhere. That is the whole of why this test has been re-diagnosed
			# as a flake instead of fixed.
			#
			# Commit to a direction for a run of attempts so the steps add up and
			# the player genuinely arrives somewhere else, then try the other way
			# in case the first was into a corner.
			var side := "move_right" if (attempt / 6) % 2 == 0 else "move_left"
			Input.action_press(side)
			for i in 10:
				await physics_frame
			Input.action_release(side)
		for i in 4:
			await physics_frame


## Is the arbiter's current winner an offer that would engage THIS creature?
##
## Not the same question as "is the winner this creature's node". The wild
## engage line is published by `encounter_director.gd::interaction_offer()` --
## "Engage Bramblebun" -- so the director is the winning PROVIDER for exactly
## the press this harness wants, and it is neither the target nor an ancestor
## of it. Judging by node identity alone therefore rejected the offer it was
## waiting for, span the sidestep search out to its limit, and reported
## "the winning prompt is EncounterDirector, not the target" -- which is the
## engage prompt, being offered, for the creature in question.
##
## So ask the director which body the press would actually take:
## `interaction_activate()` engages `_engageable()`, so that IS the answer, and
## comparing against it keeps the check honest -- a director offering a
## DIFFERENT creature still correctly reads as "not our target".
func _arbiter_offers(arbiter: Object, target: Node3D) -> bool:
	var winner: Variant = arbiter.call("winning_provider")
	if winner == null or not (winner is Node):
		return false
	var node := winner as Node
	if node == target or target.is_ancestor_of(node) or node.is_ancestor_of(target):
		return true
	if node.has_method("_engageable"):
		var candidate: Variant = node.call("_engageable")
		if candidate is Node3D and is_instance_valid(candidate as Node3D):
			var body := candidate as Node3D
			return body == target or target.is_ancestor_of(body) or body.is_ancestor_of(target)
	return false
