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
##   - **the chosen pal reaching the real party.** `scripts/story/party_seam.gd`
##     shipped looking up `/root/GameState` and calling `add_pal()`, when the
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
##   - **the prompt arbitration.** Grandpa, three starters and a wild pal all
##     want the one interact line. Which one wins is decided by distance, and a
##     screenshot cannot show that the wrong one won.
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
var _rig: Node3D = null
var _director: Node = null
var _arbiter: Node = null
var _dialogue: CanvasLayer = null
var _name_prompt: CanvasLayer = null


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

	await _the_trainer_can_walk()
	await _grandpa_says_his_piece()
	await _a_starter_can_be_chosen()
	await _the_pal_is_named_on_the_grid()
	_the_named_pal_is_in_the_real_party()
	_the_party_still_holds_at_most_five()
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
			+ "Beat 5 is naming the pal, so nothing past beat 4 can run, and no test in the suite "
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
	if _dialogue == null:
		_fail("no dialogue panel in the tree; beat 3 has nothing to draw Grandpa's lines in")
	if _name_prompt == null:
		_fail("no naming prompt in the tree; beat 5 is the beat the whole opening is for")
	return _dialogue != null and _name_prompt != null


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


## Beat 3. Walk to Grandpa and press the button the prompt is offering.
##
## The conversation may already be running — the director is free to open it on
## arrival rather than on a press — so this advances whatever is open and only
## goes looking for him when nothing is.
func _grandpa_says_his_piece() -> void:
	if not bool(_dialogue.call("is_open")):
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
	var lines := 0
	for i in 40:
		if not bool(_dialogue.call("is_open")):
			break
		await _press("interact")
		lines += 1
	if bool(_dialogue.call("is_open")):
		_fail("the conversation would not end after %d presses of `interact`; the panel is not advancing" % lines)
		return
	if lines <= 1:
		_fail("the whole conversation closed on one press; either it has one line or the guard frames are wrong")
	print("beat 3: closed after %d presses" % lines)


## Beat 4. The starter choice is physical, not a menu (OPENING_SEQUENCE.md), so
## it is made by walking to one — which is also the only way to find out whether
## the arbiter hands the prompt to the right creature.
func _a_starter_can_be_chosen() -> void:
	var starter := _find_interactable_matching(["choose"])
	if starter == null:
		_fail("no starter offers a 'Choose ...' prompt; beat 4 cannot happen")
		return
	print("beat 4: walking to '%s'" % str(starter.get("label")))

	# The other two must still be standing there afterwards. The cost of the
	# choice remaining visible in the world is a decision the design document
	# takes deliberately, and a director that despawns them undoes it silently.
	var starters_before := _count_interactables_matching(["choose"])
	if starters_before < 3:
		_fail("only %d starters offer a choice; the opening puts three in front of the player" % starters_before)

	if not await _walk_to_and_activate(starter):
		return
	for i in 30:
		await physics_frame


## Beat 5, and the reason docs/HANDOFF.md §10 has a rule in it.
##
## The grid is walked with `ui_*` and fired with `menu_confirm`, both sent as
## real events as well as pressed actions. The first move is checked on its own:
## if the cursor does not move, everything after it would still "pass" by typing
## nothing and the beat would look fine from a screenshot while being impossible
## to complete on a pad.
func _the_pal_is_named_on_the_grid() -> void:
	if not bool(_name_prompt.call("is_open")):
		_fail("choosing a starter did not open the naming prompt; beat 5 is missing")
		return
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
		await _press("menu_confirm")
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
	await _press("menu_confirm")
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
## cheerfully reports one pal, so asking the seam would agree with the bug.
func _the_named_pal_is_in_the_real_party() -> void:
	var party: RefCounted = _game.get("party")
	if party == null:
		_fail("the Game autoload has no party")
		return

	var members: Array = party.members()
	if members.is_empty():
		_fail(
			"the chosen pal never reached Game.party. If scripts/story/party_seam.gd reports a pal "
			+ "while this is empty, the seam is on its fallback list again — check the node name "
			+ "(`Game`) and the calls (`add`/`members`/`is_full`)."
		)
		return
	if members.size() != 1:
		_fail("the party holds %d pals after choosing one starter" % members.size())
		return

	var pal: RefCounted = members[0]
	if str(pal.label()) != CHOSEN_NAME:
		_fail("the pal in the party is called '%s', not the '%s' that was typed" % [str(pal.label()), CHOSEN_NAME])
	if str(pal.nickname) != CHOSEN_NAME:
		_fail("the name was not stored as a nickname; it reads '%s'" % str(pal.nickname))
	if str(pal.display_name) == CHOSEN_NAME:
		_fail("naming the pal overwrote its species name; a Terrapup nobody renamed is now indistinguishable")

	if not SEAM.has_game_state():
		_fail("the seam cannot see the real party even with the autoload running; it is on its fallback")
	if SEAM.party().size() != members.size():
		_fail("the seam reports %d pals and Game.party holds %d; there are two parties" % [
			SEAM.party().size(), members.size()
		])
	print("the party holds one pal, called '%s', and the seam and the autoload agree" % str(pal.label()))


## CLAUDE.md's first hard rule, seen at the end of the sequence that creates the
## project's first two pals.
func _the_party_still_holds_at_most_five() -> void:
	var party: RefCounted = _game.get("party")
	if party == null:
		return
	if int(party.size()) > PARTY.MAX_PALS:
		_fail("the opening left %d pals in the party; the cap is %d" % [int(party.size()), PARTY.MAX_PALS])
	if bool(party.is_full()):
		_fail("the opening filled the party; the player is supposed to leave it with room")


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


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


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


## Walk at something until it is the offer on screen, then press interact.
##
## Deliberately does NOT press until the arbiter is actually offering this one:
## walking into range of two providers and pressing blind is how a test "chooses
## a starter" by talking to Grandpa again and then reports the wrong failure.
func _walk_to_and_activate(target: Node3D) -> bool:
	for i in WALK_FRAMES:
		var to := target.global_position - _player.global_position
		to.y = 0.0
		if to.length() <= 2.0:
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
		return false

	# Whose offer is on screen, not just whether there is one. The arbiter keeps
	# the winning provider itself, and for an interactable that provider IS the
	# node — so this is an identity check rather than a string match, and it
	# cannot be fooled by two creatures with the same label.
	var winning: Object = _arbiter.get("_winning_provider")
	if winning != target:
		_fail("walked to '%s' but the prompt on screen is '%s'; the arbiter picked something else" % [
			str(target.get("label")), offered
		])
		return false

	await _press("interact")
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


func _count_interactables_matching(words: Array) -> int:
	var count := 0
	for candidate in _all_interactables(_world):
		var label := str(candidate.get("label")).to_lower()
		for word in words:
			if label.contains(str(word)):
				count += 1
				break
	return count


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
		print("opening: OK — talked, chose, named, and the pal is in the party.")
		quit(0)
		return
	for line in _failures:
		print("opening FAIL: %s" % line)
	quit(1)
