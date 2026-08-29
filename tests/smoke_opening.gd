extends SceneTree

## Does the first fifteen minutes actually play?
##
##   godot --headless --path . --script tests/smoke_opening.gd
##
## **Headless, never under xvfb.** docs/HANDOFF.md §10: xvfb plus software GL
## runs the scene-booting tests around 25× slower and flakes under CPU load, and
## this one drives a long sequence of timed presses.
##
## docs/OPENING_SEQUENCE.md beats 1–5, driven the way a player drives them:
## walk, press the interact button the prompt is offering, read what appears on
## screen, name the creature on the on-screen grid. Nothing here calls a beat
## method directly. Calling the method would prove the method works and nothing
## about whether the button reaches it, and every beat below is a button
## reaching something.
##
## What only this test can see:
##
##   - **the chosen creature reaching the real party.** `scripts/story/party_seam.gd`
##     shipped looking up `/root/GameState` and calling `add_creature()`, when the
##     autoload is `Game` and the call is `Game.party.add()`. Both wrong, so the
##     seam sat on its own fallback list forever: a phantom party beside the real
##     one, with the starter in the wrong one. `tests/test_party_seam.gd` now
##     covers that against a stand-in; THIS is the test that proves the name in
##     project.godot's `[autoload]` block and the name the seam looks for are the
##     same string, because it is the only one that boots the real autoload.
##   - **the naming grid being drivable.** docs/HANDOFF.md §10: UI navigation
##     cannot be tested with `Input.action_press` alone. The prompt is the
##     project's first text entry and ships to a handheld with no keyboard; a
##     poll-only test reports a working grid while the stick moves nothing.
##   - **the prompt arbitration.** Grandpa and a wild creature both want the one
##     interact line. Which one wins is decided by distance, and a screenshot
##     cannot show that the wrong one won.
##   - **the orb picker actually opening on its own.** `SA0-orbs` moved beat 4
##     off a walk-up interactable and onto a picker the director opens once
##     Grandpa's briefing closes; the only way to know that link still fires is
##     to close his conversation for real and watch for the picker, not to call
##     `open()` directly.
##
## ## Expected state before agents D1 and D2 land
##
## RED, LOUDLY, in preflight, on two counts and possibly three:
##
##   - `scripts/story/sequence_director.gd` (D1) does not exist.
##   - the opening's components are not in `scenes/world/meadows_playground.tscn`
##     (D2) — reported after the scene boots, because the director script
##     existing and the director being IN the scene are different failures with
##     different owners.
##   - `scripts/ui/name_prompt.gd` does not parse. That one is nobody's
##     new work: it is already broken on this branch and no existing test loads
##     it, which is why nothing has said so. Beat 5 cannot happen until it is
##     fixed.
##
## This file deliberately does NOT skip when any of that is missing. A smoke test
## that passes because the feature is absent is worse than no smoke test: it
## turns green exactly when nobody is looking and stays green when the feature
## arrives broken. It names what is missing, says who it is waiting on, and
## exits 1.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const DIRECTOR_SCRIPT := "res://scripts/story/sequence_director.gd"
const INTERACTABLE_SCRIPT := "res://scripts/world/interactable.gd"
const NAME_PROMPT_SCRIPT := "res://scripts/ui/name_prompt.gd"
const STARTER_PICKER_SCRIPT := "res://scripts/ui/starter_picker.gd"

const SEAM := preload("res://scripts/story/party_seam.gd")
const ENTRY := preload("res://scripts/ui/name_entry.gd")
const PARTY := preload("res://autoload/party.gd")

## Long enough for the terrain to build and the player to land on it. Matches
## smoke_catching, which boots the same scene.
const SETTLE_FRAMES := 300

## The name the test types on the grid, letter by letter. Mixed case on purpose:
## the grid lays out both rather than hiding one behind a shift cell, and a test
## that only ever types capitals would never walk into the lower half.
const CHOSEN_NAME := "Bud"

## Physics frames to spend walking toward something before giving up. At walk
## speed this is far more than crossing the opening's clearing takes; running out
## means the way is blocked or the target is somewhere unreachable.
const WALK_FRAMES := 1200

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _player: CharacterBody3D = null
var _model: Node3D = null
var _rig: Node3D = null
var _director: Node = null
var _arbiter: Node = null
var _dialogue: CanvasLayer = null
var _name_prompt: CanvasLayer = null
var _starter_picker: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	if not _preflight_scripts():
		_report()
		return

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		_report()
		return

	_the_trainer_starts_lying_in_bed()
	_the_way_down_is_marked()
	await _the_trainer_can_walk()
	await _the_trainer_gets_up_from_the_bed()
	await _the_door_is_gated_until_grandpa_is_heard()
	await _grandpa_says_his_piece()
	await _a_starter_can_be_chosen()
	await _the_creature_is_named_on_the_grid()
	_grandpa_handed_over_the_orbs()
	_the_named_creature_is_in_the_real_party()
	_the_party_still_holds_at_most_five()
	await _the_road_gate_stops_until_the_key_is_found()
	_report()


# --- preflight --------------------------------------------------------------
#
# Everything here fails with the name of the missing thing and who owns it,
# because "opening smoke test failed" on its own sends somebody reading a
# 400-line file to find out that a script has not been written yet.


## Both checks run before either can return, so a first run reports everything
## that is missing at once instead of one thing per attempt.
func _preflight_scripts() -> bool:
	if not ResourceLoader.exists(DIRECTOR_SCRIPT):
		_fail(
			"%s does not exist. The opening has no director, so beats 1-5 cannot be driven " % DIRECTOR_SCRIPT
			+ "and nothing below this line ran. This is the expected state until agent D1 merges."
		)

	# A script with a parse error loads as an object that cannot be instantiated,
	# so the scene silently comes up without the node and the failure reads as
	# "there is no naming prompt" three hundred lines further down. The runner
	# (tests/run_tests.gd) learned the same lesson; this is that check, aimed at
	# the one script beat 5 cannot happen without.
	var prompt: GDScript = load(NAME_PROMPT_SCRIPT)
	if prompt == null or not prompt.can_instantiate():
		_fail(
			"%s does not parse — see the SCRIPT ERROR above. " % NAME_PROMPT_SCRIPT
			+ "Beat 5 is naming the creature, so nothing past beat 4 can run, and no test in the suite "
			+ "loads this file: the unit tests cover scripts/ui/name_entry.gd, which is the grid's "
			+ "arithmetic, not the panel around it."
		)

	return _failures.is_empty()


func _collect_nodes() -> bool:
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("the Game autoload is not in the tree; project.godot's [autoload] block is the thing to look at")
		return false

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		_fail("the scene has no Player or no CameraRig; this is not the meadows playground")
		return false
	_model = _player.get_node_or_null(^"Model") as Node3D
	if _model == null or not _model.has_method("is_lying"):
		_fail("the player's Model node is missing or does not answer is_lying(); OF8's lying pose is not wired")
		return false

	# By script rather than by node path. The director is placed by agent D2 and
	# a path this file guessed would be a path that breaks on a rename, reported
	# as "the opening is broken" rather than as "the node moved".
	_director = _find_by_script(root, DIRECTOR_SCRIPT)
	if _director == null:
		_fail(
			"%s exists but nothing in %s is running it. " % [DIRECTOR_SCRIPT, SCENE]
			+ "The opening's components have not been placed in the scene yet; "
			+ "this is the expected state until agent D2 merges."
		)
		return false
	print("director: %s" % _director.get_path())

	_arbiter = get_first_node_in_group("interaction_arbiter")
	if _arbiter == null:
		_fail("no interaction arbiter in the scene; there is no interact prompt for any beat to use")
		return false

	_dialogue = _find_by_method(root, "drain_effects") as CanvasLayer
	_name_prompt = _find_by_method(root, "current_text") as CanvasLayer
	_starter_picker = _find_by_script(root, STARTER_PICKER_SCRIPT) as CanvasLayer
	if _dialogue == null:
		_fail("no dialogue panel in the tree; beat 3 has nothing to draw Grandpa's lines in")
	if _name_prompt == null:
		_fail("no naming prompt in the tree; beat 5 is the beat the whole opening is for")
	if _starter_picker == null:
		_fail("no starter picker in the tree; beat 4 has nothing to preview the orbs in")
	return _dialogue != null and _name_prompt != null and _starter_picker != null


# --- the beats --------------------------------------------------------------


## Beats 1–2. Before anything else, the trainer has to be able to leave the
## house. A director that gates locomotion at boot and forgets to hand it back
## is an opening that never starts, and it looks like a frozen game.
## Patient on purpose: beat 1 opens on a fade-in (OPENING_SEQUENCE.md, "no
## interior"), and locomotion being held for the length of a fade is correct
## rather than broken. What is not correct is it never coming back, so this
## keeps walking into it for several seconds before calling it stuck.
func _the_trainer_can_walk() -> void:
	var moved := 0.0
	for attempt in 6:
		var before := _player.global_position
		Input.action_press("move_forward")
		for i in 60:
			await physics_frame
		Input.action_release("move_forward")
		for i in 10:
			await physics_frame
		moved = before.distance_to(_player.global_position)
		if moved >= 0.5:
			print("beat 1-2: the trainer walks (%.1fm)" % moved)
			return

	_fail("the trainer never got control; six seconds of holding forward moved them %.2fm" % moved)


## OF8. The opening used to place the trainer standing on TOP of the bed —
## visible the instant the fade cleared, before any prompt is ever pressed —
## so this is checked as early as possible, right after boot and before
## `_the_trainer_can_walk()` gets a chance to move (and clear) it.
func _the_trainer_starts_lying_in_bed() -> void:
	if not bool(_model.call("is_lying")):
		_fail("the trainer is not lying down at the start of the wake beat; OF8's bed pose never applied")
		return
	print("wake: the trainer starts lying in bed")


## PT-03. Two testers — one of them the owner, twice — could not find the way
## out of the opening loft, and both eventually jumped off the mezzanine
## instead. Whether a stranger SEES a staircase is not something a headless
## run can decide, so this asserts the two facts whose absence the blind
## playtest root-caused, and nothing more.
##
## The geometry is the whole story. The loft floor's own east edge occludes
## everything below it from anywhere on the loft, and every tread of this
## flight sits below that edge — so the stair can only announce itself with
## something that rises ABOVE the loft floor inside the stair's own footprint.
## `grandpa_house.gd::_build_stair_rail()` is that something.
##
##   1. some piece of the house stands inside the stair footprint and clears
##      the loft floor plane, so there is anything at all to see;
##   2. a light stands at the head of the flight rather than only in the
##      middle of the room, so what is there is not a dark shape on a dark
##      wall.
##
## Both go red if the affordance is deleted: before PT-03 the tallest thing in
## the footprint was the top tread at FLOOR_H (below the loft floor), and the
## nearest light was the ground-floor omni two and a half metres away and a
## storey down.
func _the_way_down_is_marked() -> void:
	var house: Node3D = _world.get_node_or_null(^"GrandpaHouse") as Node3D
	if house == null:
		# grandpa_house.gd documents a houseless world as a legal one; the bare
		# smoke scene boots that way and has no loft to leave.
		return
	var consts: Dictionary = house.get_script().get_script_constant_map()
	var stair_x0: float = -float(consts["INNER_W"]) * 0.5 + float(consts["LOFT_W"])
	var stair_x1: float = stair_x0 + float(consts["STAIR_RUN"])
	var stair_z: float = -float(consts["INNER_D"]) * 0.5 + 0.6
	var half_w: float = float(consts["STAIR_WIDTH"]) * 0.5
	var loft_top: float = float(consts["FLOOR_H"]) + 0.25
	var to_local := house.global_transform.affine_inverse()

	var tallest := -INF
	var lit := false
	for node in _descendants(house):
		# Hidden subtrees do not count. `_build_kit_shell()` parks the prefab
		# composer's un-parented template trees under an invisible holder so
		# they cannot leak render resources at shutdown, and a template that
		# happened to land in this footprint would pass the test with geometry
		# no player will ever see.
		if node is Node3D and not (node as Node3D).is_visible_in_tree():
			continue
		if node is MeshInstance3D:
			var mesh := node as MeshInstance3D
			if mesh.mesh == null:
				continue
			var box: AABB = (to_local * mesh.global_transform) * mesh.mesh.get_aabb()
			# Contained in the footprint, not merely overlapping it: the walls,
			# the loft slab and the roof all cross this z band and would each
			# satisfy an overlap test while telling the player nothing.
			if box.position.x < stair_x0 - 0.4 or box.end.x > stair_x1 + 0.4:
				continue
			if box.position.z < stair_z - half_w - 0.2 or box.end.z > stair_z + half_w + 0.2:
				continue
			tallest = maxf(tallest, box.end.y)
		elif node is OmniLight3D:
			var at: Vector3 = to_local * (node as Node3D).global_position
			if at.y <= float(consts["FLOOR_H"]):
				continue
			if at.x < stair_x0 - 0.4 or at.x > stair_x1 + 0.4:
				continue
			if absf(at.z - stair_z) > half_w + 0.4:
				continue
			lit = true

	if tallest < loft_top + 0.4:
		_fail("nothing in the stair footprint rises above the loft floor (tallest %.2fm vs loft %.2fm); the flight is invisible from the loft it leaves" % [tallest, loft_top])
	else:
		print("stairs: the flight is marked %.2fm above the loft floor" % (tallest - loft_top))
	if not lit:
		_fail("no light at the head of the stairs; the way out is a dark shape against a dark wall")
	else:
		print("stairs: a light stands at the head of the flight")


## The wake beat: the opening starts in the loft bedroom of Grandpa's
## farmhouse, and the first gate is the bed's own "Get up" prompt. If the
## prompt is not offered, either the house never built or the bed prompt was
## never wired; either way the opening is a player stuck upstairs forever.
func _the_trainer_gets_up_from_the_bed() -> void:
	var bed := _find_interactable_matching(["get up"])
	if bed == null:
		_fail("nothing offers a 'Get up' prompt; the wake beat has no gate and the opening cannot start")
		return
	if not await _walk_to_and_activate(bed):
		return
	for i in 10:
		await physics_frame
	if str(_director.call("beat")) == "wake":
		_fail("getting up did not advance the wake beat")
		return
	# OF8: the whole point of the button — lying flips back to standing
	# through this exact interaction, not just eventually via movement.
	if bool(_model.call("is_lying")):
		_fail("beat advanced past 'wake' but the trainer is still posed lying down")
		return
	print("wake: got up from the bed, beat is now '%s', standing again" % str(_director.call("beat")))


## Grandpa gives the catch-up supply after the starter is named, not during the
## first briefing. The new opening deliberately promises only generous Basic
## Orbs here; potions and revives are no longer part of this handover.
func _grandpa_handed_over_the_orbs() -> void:
	var inventory: RefCounted = _game.get("inventory")
	var orbs := int(inventory.call("count", "orb_basic"))
	if orbs < 10 or orbs > 15:
		_fail("naming the starter left %d Basic Orbs in the satchel; the opening catch supply must be 10-15" % orbs)
	else:
		print("the opening catch supply: %d Basic Orbs" % orbs)


## SA2 (spec sec1D): "the player cannot leave Grandpa's house until the
## required Grandpa opening interaction is complete." Walks the player
## straight at the exterior doorway, skipping Grandpa entirely — proving the
## gate fires from an approach at the door, not only from pressing interact
## on him, and that the sequence starts the briefing itself rather than
## printing a sterile "talk to Grandpa first" error (which spec sec1D rules
## out by name). `_grandpa_says_his_piece()` below already knows how to
## advance a conversation that is open on arrival, so this leaves the box
## open for it rather than closing it here.
func _the_door_is_gated_until_grandpa_is_heard() -> void:
	var house := _world.get_node_or_null(^"GrandpaHouse")
	if house == null:
		# No house in this world: SA2 has nothing to gate. grandpa_house.gd
		# documents a houseless world as a legal one (the bare smoke boots).
		return

	await _walk_toward_point(house.call("marker", "stairs_top"), 300)
	await _walk_toward_point(house.call("marker", "stairs_bottom"), 300)
	# Via the open floor in front of Grandpa (stops 0.8m short of him, same as
	# any `_walk_toward_point` target — never close enough to touch his own
	# collider), not a straight line from the stairs' foot: that line clips
	# the corner where the stairs and a piece of furniture meet the north
	# wall, and a homing walk wedged into a corner makes no progress at all,
	# door gate or not.
	await _walk_toward_point(house.call("marker", "grandpa"), 300)
	await _walk_toward_point(house.call("marker", "door"), 400)

	if not bool(_dialogue.call("is_open")):
		_fail("walking straight at the exterior door opened no conversation with Grandpa still unheard")
		return
	print("door gate: heading for the door opened '%s' with no interact press" % str(_dialogue.call("runner").call("conversation_id")))

	var door: Vector3 = house.call("marker", "door")
	var short_by := _player.global_position.distance_to(door)
	if short_by < 0.8:
		_fail("the player reached %.1fm from the exterior door marker while beat is still '%s'; the doorway did not physically stop them" % [short_by, str(_director.call("beat"))])
		return
	print("door gate: stopped %.1fm short of the door while beat is '%s'" % [short_by, str(_director.call("beat"))])


## Beat 3. Walk to Grandpa and press the button the prompt is offering.
##
## The conversation may already be running — the director is free to open it on
## arrival rather than on a press — so this advances whatever is open and only
## goes looking for him when nothing is.
func _grandpa_says_his_piece() -> void:
	if not bool(_dialogue.call("is_open")):
		# Down the stairs first. The straight line from the loft to Grandpa
		# goes through the floor; a real player takes the stairs and so does
		# this, on the house's own waypoints.
		var house := _world.get_node_or_null(^"GrandpaHouse")
		if house != null:
			await _walk_toward_point(house.call("marker", "stairs_top"), 300)
			await _walk_toward_point(house.call("marker", "stairs_bottom"), 300)
		var grandpa := _find_interactable_matching(["grandpa", "talk"])
		if grandpa == null:
			_fail("nothing in the meadow offers a prompt about Grandpa; beat 3 cannot start")
			return
		if not await _walk_to_and_activate(grandpa):
			return

	if not bool(_dialogue.call("is_open")):
		_fail("talking to Grandpa opened no dialogue; beat 3 does not happen")
		return
	print("beat 3: conversation '%s' opened" % str(_dialogue.call("runner").call("conversation_id")))

	# Advance it with the real button rather than by calling `advance()`. The
	# panel is deaf for two frames after opening on purpose — the press that
	# started the conversation is the same press it would read as "next" — and a
	# test that called the method would never notice that guard going wrong in
	# either direction.
	#
	# `_press_pad`, not `_press_polled` — OW2. The owner's report ("the initial
	# scene didn't move every time I hit x") is about this exact loop, and
	# `_press_polled`'s `Input.action_press` sets the action state directly —
	# it never travels the InputMap, so it cannot tell a real binding from a
	# broken one (the same gap `UI-PAD1`/`TEST2` named for `smoke_menu.gd`).
	# `_press_pad` sends a genuine `InputEventJoypadButton` on `interact`'s own
	# live-InputMap button index, the way the owner's X actually reaches this
	# code, across every line of a real multi-line conversation rather than one
	# isolated press.
	var lines := 0
	for i in 40:
		if not bool(_dialogue.call("is_open")):
			break
		await _press_pad("interact")
		lines += 1
	if bool(_dialogue.call("is_open")):
		_fail("the conversation would not end after %d presses of `interact`; the panel is not advancing" % lines)
		return
	if lines <= 1:
		_fail("the whole conversation closed on one press; either it has one line or the guard frames are wrong")
	print("beat 3: closed after %d presses" % lines)


## Beat 4. `SA0-orbs`, owner directive 2026-08-11: the choice is previewed in
## orbs while still indoors with Grandpa, not made by walking up to a body in
## the meadow — docs/OPENING_SEQUENCE.md records the reversal from the earlier
## staging this test used to drive. The director opens the picker on its own,
## the frame after Grandpa's conversation closes (`_grandpa_says_his_piece`
## above already drove that close for real), so this only has to prove the
## picker actually appears and that the real buttons reach it.
func _a_starter_can_be_chosen() -> void:
	var opened := false
	for i in 60:
		if bool(_starter_picker.call("is_open")):
			opened = true
			break
		await physics_frame
	if not opened:
		_fail("the starter picker never opened after Grandpa's briefing closed; beat 4 cannot happen")
		return
	print("beat 4: the starter picker opened on its own")

	# Move the selection with the real stick/d-pad action before confirming, the
	# same reason beat 5 below sends `ui_right` before typing: a poll-only test
	# would report a working picker while the stick moved nothing.
	#
	# `_press_polled`, not `_press` — SA2-flake. `starter_picker.gd` reads BOTH
	# `ui_right`/`ui_left` and `menu_confirm` the same way: a plain
	# `Input.is_action_just_pressed` poll in one `_physics_process` if/elif
	# chain, never Control focus (no `_gui_input`, no `grab_focus`). `_press`'s
	# belt-and-braces parsed event is for readers that need a real Control
	# event to move focus (docs/HANDOFF.md §10); this reader doesn't have one,
	# so the parsed event is pure redundancy here — and under load it can
	# register "just pressed" a physics frame later than the action-state
	# path (the same two-signals-different-frames race `_press_polled`'s own
	# docstring names for LP2's `interact` fix).
	#
	# That late `ui_right` registration landing on the SAME frame as the next
	# `menu_confirm` press USED to swallow the confirm: `starter_picker.gd`
	# checked `ui_right` first in its if/elif chain, and a dropped
	# `is_action_just_pressed` is gone rather than deferred. That was the real
	# defect behind the 2026-08-15 blind playtest's PT-01, and the paragraph
	# that used to sit here described it accurately — as expected behaviour,
	# stepping around it rather than failing on it, which is how a known bug
	# stayed encoded in a green suite.
	#
	# The picker now tests `menu_confirm` BEFORE the directions, so a
	# same-frame tie resolves in the player's favour. This sequence is kept
	# exactly as it was: it is the ordering that used to provoke the bug, so
	# it is the ordering most worth keeping green.
	await _press_polled("ui_right")

	# The same-frame collision itself, made deterministic. Both actions go down
	# together and are read by the SAME `_physics_process` pass, so both are
	# "just pressed" on the one frame either was ever going to be. Against the
	# old `ui_right`-first chain this is the exact input that dropped the
	# confirm and left the picker open forever; against the fixed order the
	# confirm wins and the picker closes.
	#
	# Provoking it by racing two sequential presses (what this used to rely on)
	# only reproduced under load, which is why the bug survived a green suite.
	Input.action_press("ui_right")
	Input.action_press("menu_confirm")
	for i in 3:
		await physics_frame
	Input.action_release("ui_right")
	Input.action_release("menu_confirm")
	for i in 20:
		await physics_frame

	if bool(_starter_picker.call("is_open")):
		_fail("confirming an orb with `menu_confirm` did not close the picker; beat 4 does not advance")
		return
	print("beat 4: chose an orb with the pad, the picker closed")


## Beat 5, and the reason docs/HANDOFF.md §10 has a rule in it.
##
## The grid is walked with `ui_*` and fired with `menu_confirm`, both sent as
## real events as well as pressed actions. The first move is checked on its own:
## if the cursor does not move, everything after it would still "pass" by typing
## nothing and the beat would look fine from a screenshot while being impossible
## to complete on a pad.
func _the_creature_is_named_on_the_grid() -> void:
	if not bool(_name_prompt.call("is_open")):
		_fail("choosing a starter did not open the naming prompt; beat 5 is missing")
		return

	# OF25 split the prompt into two live surfaces: a LineEdit for keyboard
	# players and the letter grid for gamepad players, switched on the
	# device of the LAST REAL INPUT EVENT (Game.last_input_was_gamepad).
	# Headless CI has no pad connected, so the tracker boots in keyboard
	# mode and the grid this test drives is hidden — inject one real joypad
	# press first, exactly what a controller player's first button does, so
	# the prompt shows the grid this smoke exists to prove. The keyboard
	# surface has its own smoke (tests/smoke_name_prompt_keyboard.gd).
	#
	# OW2: guarded on the tracker's CURRENT state, not fired unconditionally.
	# This press's button (A / `menu_confirm`) is only safe because the panel's
	# own device-switch detection sets `_mode_guard` and swallows it for two
	# frames — that guard fires only on an actual keyboard-to-gamepad
	# transition. Beat 3 now drives `interact` with real `InputEventJoypadButton`
	# presses too (OW2, `_press_pad`), so by the time this beat runs the
	# tracker is ALREADY in gamepad mode; sending this "priming" press again
	# then finds no transition to guard, and lands as a genuine, unguarded
	# `menu_confirm` on whatever cell the cursor already sits on ('A', the
	# grid's first cell) — a stray letter typed before the test types anything
	# itself. Skipping the press when already in gamepad mode removes the
	# only thing it was ever for.
	if not bool(_name_prompt.get("_using_gamepad")):
		var pad := InputEventJoypadButton.new()
		pad.button_index = JOY_BUTTON_A
		pad.pressed = true
		Input.parse_input_event(pad)
		var pad_up := InputEventJoypadButton.new()
		pad_up.button_index = JOY_BUTTON_A
		pad_up.pressed = false
		Input.parse_input_event(pad_up)
	# One frame for the tracker to see it, plus the prompt's own mode-switch
	# guard frames before the grid answers ui_* polling.
	for i in 8:
		await process_frame

	var entry: RefCounted = _name_prompt.call("entry")
	print("beat 5: naming prompt open, cursor on '%s'" % str(entry.selected()))

	var before := Vector2i(int(entry.row), int(entry.column))
	await _press("ui_right")
	if Vector2i(int(entry.row), int(entry.column)) == before:
		_fail("`ui_right` moved nothing on the naming grid; it cannot be driven with a stick or a d-pad")
		return
	await _press("ui_left")

	for character in CHOSEN_NAME:
		if not await _select_cell(entry, character):
			return
		var typed_before: String = str(entry.text)
		await _press_polled("menu_confirm")
		if str(entry.text) == typed_before:
			_fail("`menu_confirm` on '%s' typed nothing; the grid draws but does not enter" % character)
			return

	if str(_name_prompt.call("current_text")) != CHOSEN_NAME:
		_fail("typed '%s' on the grid and the buffer reads '%s'" % [
			CHOSEN_NAME, str(_name_prompt.call("current_text"))
		])
		return

	if not await _select_cell(entry, ENTRY.DONE):
		return
	await _press_polled("menu_confirm")
	for i in 20:
		await physics_frame

	if bool(_name_prompt.call("is_open")):
		_fail("Done did not close the naming prompt; the player is stuck on the keyboard")
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		# Headless reports VISIBLE whatever was asked for, so this is a note and
		# not a failure — smoke_menu.gd explains why the dummy DisplayServer
		# cannot see capture at all.
		print("note: mouse reads %d after the prompt closed; headless cannot capture" % Input.mouse_mode)
	print("beat 5: named '%s' on the grid, with the pad" % CHOSEN_NAME)


## The whole reason the seam exists, checked against the party the rest of the
## game reads rather than against the seam's own answer.
##
## `Game.party` is asked directly. If the seam is back on its fallback list — the
## bug it shipped with — the party here is EMPTY while `party_seam.party()`
## cheerfully reports one creature, so asking the seam would agree with the bug.
func _the_named_creature_is_in_the_real_party() -> void:
	var party: RefCounted = _game.get("party")
	if party == null:
		_fail("the Game autoload has no party")
		return

	var members: Array = party.members()
	if members.is_empty():
		_fail(
			"the chosen creature never reached Game.party. If scripts/story/party_seam.gd reports a creature "
			+ "while this is empty, the seam is on its fallback list again — check the node name "
			+ "(`Game`) and the calls (`add`/`members`/`is_full`)."
		)
		return
	if members.size() != 1:
		_fail("the party holds %d creatures after choosing one starter" % members.size())
		return

	var creature: RefCounted = members[0]
	if str(creature.label()) != CHOSEN_NAME:
		_fail("the creature in the party is called '%s', not the '%s' that was typed" % [str(creature.label()), CHOSEN_NAME])
	if str(creature.nickname) != CHOSEN_NAME:
		_fail("the name was not stored as a nickname; it reads '%s'" % str(creature.nickname))
	if str(creature.display_name) == CHOSEN_NAME:
		_fail("naming the creature overwrote its species name; a Terrapup nobody renamed is now indistinguishable")

	if not SEAM.has_game_state():
		_fail("the seam cannot see the real party even with the autoload running; it is on its fallback")
	if SEAM.party().size() != members.size():
		_fail("the seam reports %d creatures and Game.party holds %d; there are two parties" % [
			SEAM.party().size(), members.size()
		])
	print("the party holds one creature, called '%s', and the seam and the autoload agree" % str(creature.label()))


## CLAUDE.md's first hard rule, seen at the end of the sequence that creates the
## project's first two creatures.
func _the_party_still_holds_at_most_five() -> void:
	var party: RefCounted = _game.get("party")
	if party == null:
		return
	if int(party.size()) > PARTY.MAX_CREATURES:
		_fail("the opening left %d creatures in the party; the cap is %d" % [int(party.size()), PARTY.MAX_CREATURES])
	if bool(party.is_full()):
		_fail("the opening filled the party; the player is supposed to leave it with room")


## SA7: the road toward the stronghold is gated, and the gate does not explain
## itself with UI text (spec §19) — the player has to try it, be told a key is
## nearby, find it, and come back. Exercises the whole loop for real: walk,
## press, read, walk again, press again, same as beat 3 exercises Grandpa's
## conversation for real rather than calling `start()` directly.
func _the_road_gate_stops_until_the_key_is_found() -> void:
	# Beat 5 leaves Grandpa's own reply ("$name. Good.") open — its last line
	# carries the `beat:first_encounter` effect that moves the director off
	# `NAMED` and hands locomotion/the arbiter back (`_refresh_lockout`), and
	# nothing before this beat ever needed the arbiter again to notice it was
	# still sitting there. Advance it for real, same button as beat 3.
	if bool(_dialogue.call("is_open")):
		var closed := 0
		for i in 40:
			if not bool(_dialogue.call("is_open")):
				break
			await _press_polled("interact")
			closed += 1
		if bool(_dialogue.call("is_open")):
			_fail("Grandpa's reply after naming would not close after %d presses; the opening never hands back control" % closed)
			return

	var gate := _world.get_node_or_null(^"RoadGate") as Node3D
	if gate == null:
		_fail("no RoadGate in the world; SA7's gate was never built")
		return

	# A straight line from wherever beat 5 leaves the player clips either the
	# yard fence (`village.json`, `[3,-18]`, yaw 100° — measured directly: a
	# 5m wall whose long axis runs roughly north-south, spanning z -15.5 to
	# -20.5 at x~3, not just a point) or the ChickenCoop (`[21,-14]`, a small
	# ~1.5m-radius footprint but sitting almost on `paths.routes`' own
	# "toward the rocky rise" leg). A real player rounds a fence and a coop
	# without thinking about it; this homing walk does not, so it goes north
	# of both — over the fence's tip, well clear of the coop — before
	# dropping back down to the gate.
	await _walk_toward_point(Vector3(14.0, 0.0, -13.0), 900)
	await _walk_toward_point(Vector3(18.0, 0.0, -10.0), 900)
	await _walk_toward_point(Vector3(26.0, 0.0, -10.0), 900)

	# Physically stopped, not just told: from here, walk straight at a point
	# well past the gate before ever pressing anything, and confirm the
	# collider — not this test — is what ends the approach.
	var to_gate: Vector3 = gate.global_position - _player.global_position
	to_gate.y = 0.0
	if to_gate.length() < 1.0:
		_fail("the player is standing on the gate's own position; no approach direction to test")
		return
	# CROSSING THE GATE'S PLANE, not proximity to a point.
	#
	# This measured "did the player get within 8m of `beyond`", where `beyond`
	# is 15m further along the player-to-gate ray. That is only "past the gate"
	# when the approach is head-on down the road. Approach obliquely -- which a
	# controller walk does -- and the ray runs mostly PARALLEL to the gate's
	# fence line, so `beyond` lands beside the gate rather than behind it, and
	# walking along the near side of the fence gets close enough to fail the
	# check without ever passing anything.
	#
	# Measured on the failing CI run: the player ended 0.7m past the gate's own
	# plane and 14.9m sideways along it -- they never crossed, and the test said
	# the road was not blocked.
	#
	# So ask the actual question: which side of the barrier are they on? The
	# gate's local X is the fence line, so its perpendicular is the direction of
	# travel through it, and the sign of that projection is the side.
	var across := Vector2(gate.global_transform.basis.x.x, gate.global_transform.basis.x.z).normalized()
	var through := Vector2(-across.y, across.x)
	var gate_xz := Vector2(gate.global_position.x, gate.global_position.z)
	var side_before: float = through.dot(
		Vector2(_player.global_position.x, _player.global_position.z) - gate_xz)
	var beyond: Vector3 = gate.global_position + to_gate.normalized() * 15.0
	await _walk_toward_point(beyond, 1800)
	var side_after: float = through.dot(
		Vector2(_player.global_position.x, _player.global_position.z) - gate_xz)
	# A metre of tolerance: standing ON the line is not crossing it.
	if signf(side_after) != signf(side_before) and absf(side_after) > 1.0:
		_fail("crossed to the far side of the locked gate (%.1fm past its plane); the road is not physically blocked" % absf(side_after))
		return
	print("gate: physically blocked, still %.1fm on the approach side of its plane" % absf(side_after))

	var gate_prompt := _find_interactable_matching(["gate"])
	if gate_prompt == null:
		_fail("nothing offers a prompt about the gate; the road out is not actually gated")
		return
	if not await _walk_to_and_activate(gate_prompt):
		return

	if not bool(_dialogue.call("is_open")):
		_fail("trying the locked gate opened no dialogue; the player is stopped with no explanation")
		return
	print("gate: locked, conversation '%s' opened" % str(_dialogue.call("runner").call("conversation_id")))
	var lines := 0
	for i in 10:
		if not bool(_dialogue.call("is_open")):
			break
		await _press_polled("interact")
		lines += 1
	if bool(_dialogue.call("is_open")):
		_fail("the locked-gate message would not close after %d presses" % lines)
		return
	if bool(gate.call("is_open")):
		_fail("the gate reports open before the player ever held the key")
		return

	var key := _find_interactable_matching(["key"])
	if key == null:
		_fail("no key offered anywhere; the gate is locked with no way through")
		return
	if not await _walk_to_and_activate(key):
		return
	var inventory: RefCounted = _game.get("inventory")
	if int(inventory.call("count", "castle_gate_key")) < 1:
		_fail("activating the key prompt did not put a key in the satchel")
		return
	print("gate: key found, satchel now holds %d" % int(inventory.call("count", "castle_gate_key")))

	if not await _walk_to_and_activate(gate_prompt):
		return
	if not bool(gate.call("is_open")):
		_fail("trying the gate with the key in hand did not open it")
		return
	print("gate: unlocked with the key, beat complete")


# --- driving ----------------------------------------------------------------


## Press an action down both paths, because the opening's screens use both.
##
## `Input.action_press` sets the action state, which is what the dialogue panel
## and the naming grid poll. It does NOT put an event through the tree, so on its
## own it cannot move Control focus — and the pause menu, which the player can
## open at any point during the opening, is entirely focus-driven. Sending both
## is docs/HANDOFF.md §10's rule, and smoke_menu.gd is where it was learned.
##
## Held across physics frames rather than process frames: both screens read input
## in `_physics_process`, deliberately, so that they and the interaction arbiter
## agree about which frame a press landed in.
func _press(action: String) -> void:
	Input.action_press(action)
	_send(action, true)
	for i in 3:
		await physics_frame
	Input.action_release(action)
	_send(action, false)
	for i in 4:
		await physics_frame


## For actions the naming panel POLLS (`menu_confirm`): action state only.
##
## `_press` above sends the action state AND a parsed InputEventAction, belt
## and braces — and under a heavy scene the two can land in DIFFERENT physics
## frames, which a polling reader counts as two presses. Typing "Bud" came out
## "Buudd". Focus navigation genuinely needs the parsed event (see
## docs/HANDOFF.md on `ui_*`); confirming a grid cell does not.
func _press_polled(action: String) -> void:
	Input.action_press(action)
	for i in 3:
		await physics_frame
	Input.action_release(action)
	for i in 4:
		await physics_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


## A REAL joypad button, the way hardware delivers it — deliberately not
## `Input.action_press` or an `InputEventAction`, both of which set the action
## state directly and never travel the InputMap at all. `smoke_backpack_pad_target.gd`
## is where this pattern was written first (OW4/UI-PAD1): a test that only ever
## presses the action can pass on a binding a real pad cannot reach. Button index
## is read from the live InputMap rather than hardcoded, so a rebind moves this
## test with it instead of leaving it testing a button nobody presses.
##
## OW2: the owner's "the initial scene didn't move every time I hit x" report
## is exactly the gap this closes for `interact` — `_press_polled` above proves
## the CODE advances correctly when the action fires, not that a real X press
## reaches that code at all.
func _press_pad(action: String) -> void:
	var button_index := _pad_button_for(action)
	if button_index < 0:
		_fail("'%s' has no joypad binding at all — a controller cannot press it" % action)
		return
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	for i in 3:
		await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await physics_frame


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## Put the naming cursor on a given cell by pressing the same directions a thumb
## would, with the coordinates read out of `name_entry.ROWS` rather than written
## down here — a layout change should move this test, not break it.
##
## Rows first: a vertical move clamps the column, so doing it the other way round
## would land somewhere else on a ragged row.
func _select_cell(entry: RefCounted, cell: String) -> bool:
	var target := _cell_position(cell)
	if target.x < 0:
		_fail("'%s' is not on the naming grid at all" % cell)
		return false

	for i in 12:
		if int(entry.row) == target.x:
			break
		await _press("ui_down")
	for i in 12:
		if int(entry.column) == target.y:
			break
		await _press("ui_right")

	if str(entry.selected()) != cell:
		_fail("could not reach '%s' on the grid; the cursor stopped on '%s'" % [cell, str(entry.selected())])
		return false
	return true


func _cell_position(cell: String) -> Vector2i:
	var rows: Array = ENTRY.ROWS
	for r in rows.size():
		var row: Array = rows[r]
		for c in row.size():
			if str(row[c]) == cell:
				return Vector2i(r, c)
	return Vector2i(-1, -1)


## Walk toward a world point until close, or the frame budget runs out. No
## activation, no arbitration — pure locomotion, for waypoints like the stairs.
func _walk_toward_point(point: Vector3, frames: int) -> void:
	for i in frames:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= 0.8:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 5:
		await physics_frame
	var remaining := point - _player.global_position
	remaining.y = 0.0
	print("  [walk] toward %s -> at %s (%.1fm short)" % [
		str(point.snapped(Vector3.ONE * 0.1)),
		str(_player.global_position.snapped(Vector3.ONE * 0.1)), remaining.length()])


## Walk at something until it is the offer on screen, then press interact.
##
## Deliberately does NOT press until the arbiter is actually offering this one:
## walking into range of two providers and pressing blind is how a test "chooses
## a starter" by talking to Grandpa again and then reports the wrong failure.
func _walk_to_and_activate(target: Node3D) -> bool:
	for i in WALK_FRAMES:
		var to := target.global_position - _player.global_position
		to.y = 0.0
		# Close AND actually winning, not just close. The starters overlap on
		# purpose — 2.6m radius each, 3.5m apart — and a straight line walked at
		# one from an angle passes inside a neighbour's radius too. Stopping on
		# raw distance alone can land the player somewhere a neighbour is still
		# winning; a real player just takes the one more step that changes which
		# name is on screen, so this keeps walking until the target itself does.
		if to.length() <= 2.0 and _arbiter.get("_winning_provider") == target:
			break
		_rig.set("yaw", atan2(-to.x, -to.z))
		Input.action_press("move_forward")
		await physics_frame
	Input.action_release("move_forward")
	for i in 20:
		await physics_frame

	var offered := str(_arbiter.call("prompt"))
	if offered.is_empty():
		_fail("standing next to '%s' and the interact prompt is blank" % str(target.get("label")))
		print("  [debug] player %s, target %s (%.1fm), director beat '%s', target enabled=%s, arbiter enabled=%s" % [
			str(_player.global_position.snapped(Vector3.ONE * 0.1)),
			str(target.global_position.snapped(Vector3.ONE * 0.1)),
			_player.global_position.distance_to(target.global_position),
			str(_director.call("beat")), str(target.get("enabled")),
			str(_arbiter.get("_enabled"))])
		return false

	# Whose offer is on screen, not just whether there is one. The arbiter keeps
	# the winning provider itself, and for an interactable that provider IS the
	# node — so this is an identity check rather than a string match, and it
	# cannot be fooled by two creatures with the same label.
	var winning: Object = _arbiter.get("_winning_provider")
	if winning != target:
		var target_at: Vector3 = target.global_position
		_fail("walked to '%s' but the prompt on screen is '%s'; the arbiter picked something else" % [
			str(target.get("label")), offered
		])
		print("  [debug] player at %s, target '%s' at %s (%.1fm away)" % [
			str(_player.global_position.snapped(Vector3.ONE * 0.1)),
			str(target.get("label")), str(target_at.snapped(Vector3.ONE * 0.1)),
			_player.global_position.distance_to(target_at)])
		return false

	# `_press_polled`, not `_press` — see the LP2 note in `_grandpa_says_his_piece`.
	# `interaction_arbiter.gd` reads `interact` the same way `dialogue_panel.gd`
	# does, by polling `is_action_just_pressed` in `_physics_process`, so this
	# shares the same double-count risk under a heavy scene.
	await _press_polled("interact")
	for i in 20:
		await physics_frame
	return true


# --- finding things ---------------------------------------------------------


func _find_by_script(node: Node, path: String) -> Node:
	var script: Script = node.get_script() as Script
	if script != null and script.resource_path == path:
		return node
	for child in node.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


## Duck-typed, like the menu's own fight lookup: a node that answers to the
## method is the node that does the job, whatever it has been called or wherever
## agent D2 hung it.
func _find_by_method(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child in node.get_children():
		var found := _find_by_method(child, method)
		if found != null:
			return found
	return null


## Interactables are found by their label, because the label is the only part of
## one that this test can legitimately know: it is what the player reads.
func _find_interactable_matching(words: Array) -> Node3D:
	for candidate in _all_interactables(_world):
		var label := str(candidate.get("label")).to_lower()
		if not bool(candidate.get("enabled")):
			continue
		for word in words:
			if label.contains(str(word)):
				return candidate
	return null


func _descendants(node: Node) -> Array[Node]:
	var out: Array[Node] = [node]
	for child in node.get_children():
		out.append_array(_descendants(child))
	return out


func _all_interactables(node: Node) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var script: Script = node.get_script() as Script
	if script != null and script.resource_path == INTERACTABLE_SCRIPT and node is Node3D:
		out.append(node as Node3D)
	for child in node.get_children():
		out.append_array(_all_interactables(child))
	return out


# --- reporting --------------------------------------------------------------


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("opening: OK — talked, chose, named, and the creature is in the party.")
		quit(0)
		return
	for line in _failures:
		print("opening FAIL: %s" % line)
	quit(1)
