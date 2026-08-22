extends SceneTree

## Does the menu actually open over the real game, and give the game back?
##
##   godot --headless --path . --script tests/smoke_menu.gd
##
## Unit tests can prove the satchel's arithmetic and the five-creature cap. They
## cannot see any of the things that make a menu usable or unusable, and every
## one of those is a way this ships broken:
##
##   - the mouse. scripts/world/playground_world.gd captures it unconditionally
##     and never gives it back. A menu that does not release it is a menu you
##     cannot click, and one that does not RESTORE it leaves the camera dead
##     after closing — which looks like a camera bug, not a menu bug.
##   - the pause. If the tree keeps running, the player is walking off a cliff
##     while reading their inventory.
##   - focus. This ships on a handheld. If nothing holds focus when the menu
##     opens, or the focus neighbours are not wired, the stick moves nothing and
##     the menu is decoration. Nothing about that shows up in a screenshot.
##   - the fight. `menu_cancel` and `combat_run` share a binding, so the menu
##     must yield mid-fight or the flee button opens a menu instead.
##   - the button legend. It shipped hand-typed and gamepad-only for two of its
##     four entries, so it told keyboard players to press a key that is bound to
##     something else entirely. See
##     `_check_the_footer_names_keys_a_keyboard_player_can_press`.
##
## Boots the real main scene with the real autoload, and drives it with injected
## input rather than by calling open() directly — calling the method would prove
## the method works and nothing about whether the button reaches it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const GLYPH := preload("res://scripts/ui/input_glyph.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const CONTROLLER_SAVE_DIR := "user://controller_ui_smoke_saves/"

var _failures: Array[String] = []
var _menu: CanvasLayer = null
var _game: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	# Real boot reaches this scene through the engine's own main-scene load, which
	# sets `current_scene` as a side effect. This harness adds the scene by hand
	# instead, so without this line `current_scene` stays null and anything that
	# walks it — `game_menu.gd::_fight_in_progress()` included — silently finds
	# nothing, whatever the real state of the game is.
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return
	_menu = _game.call("menu")
	if _menu == null:
		print("FAIL: the autoload did not stand up the menu")
		quit(1)
		return

	_check_the_fight_guard_can_see_the_fight(world)
	await _check_refusal_shows_an_on_screen_reason(world)
	await _check_opens_on_the_inventory_button(world)
	_check_the_footer_names_keys_a_keyboard_player_can_press()
	await _check_focus_can_be_driven()
	await _check_tabs_can_be_cycled()
	await _check_the_party_screen_holds_five()
	await _check_party_reorder_button()
	await _check_backpack_target_picker()
	await _check_backpack_target_picker_full_party()
	await _check_backpack_food_eat()
	await _check_backpack_tm_teach()
	await _check_backpack_tm_refuses_when_nobody_can_learn()
	await _check_backpack_drop_and_split()
	await _check_backpack_move_and_quick_bar()
	await _check_quest_log_tab()
	await _check_save_tab_controller_actions()
	await _check_closes_and_gives_the_game_back(world)
	await _check_objective_line_updates_without_reload(world)
	await _check_opens_on_the_menu_button()
	_check_focus_recapture_respects_open_ui(world)

	print("")
	if _failures.is_empty():
		print("menu smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


## Controller actions in this smoke start as their physical joypad binding.
## Naming an action directly can make both polling and Control focus pass while
## the live InputMap has no route from the button printed in the footer.
func _press(action: String) -> void:
	var button_index := _pad_button_for(action)
	if button_index < 0:
		_fail("'%s' has no physical joypad button binding" % action)
		return
	await _pad(button_index)


## Resolve the actual button from the live InputMap so rebinds move the test
## with the game. `smoke_backpack_pad_target.gd` (OW4) first exposed why an
## InputEventAction is insufficient for this contract.
func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## A real controller button, the way hardware delivers it. Deliberately NOT an
## `InputEventAction` — see `_pad_button_for`'s comment.
func _pad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await process_frame


# --- opening ----------------------------------------------------------------


## The menu yields the Escape/B button while a fight is running, because
## `menu_cancel` and `combat_run` share a binding. That guard finds the fight by
## looking for a node that answers `is_fighting()` rather than by node path — so
## if combat is ever moved or renamed, the guard would quietly find nothing and
## the flee button would start opening a menu instead. This checks the lookup
## still lands, which is the half that can rot.
func _check_the_fight_guard_can_see_the_fight(world: Node) -> void:
	var found: Node = _menu.call("_find_combat", world)
	if found == null:
		_fail("the menu cannot find the fight; `menu_cancel` would open a menu instead of fleeing")
		return
	if bool(found.call("is_fighting")):
		_fail("a fight is somehow already running before the test starts")
	print("fight guard sees: %s" % found.name)


## `open()` refusing mid-fight used to be silent — the button just did nothing,
## which reads as broken rather than rules-respecting. Forces the real combat
## manager's `state` to ACTIVE (the same thing `begin()` sets, without needing
## a full encounter) so `is_fighting()` is genuinely true, presses the same
## button a player would, and checks BOTH that the menu stayed shut AND that a
## visible reason appeared — a passing test that only checked the first half
## would keep shipping the silent refusal this exists to catch.
func _check_refusal_shows_an_on_screen_reason(world: Node) -> void:
	var combat: Node = _menu.call("_find_combat", world)
	if combat == null:
		_fail("cannot force a fight for the refusal check; combat was not found")
		return

	combat.set("state", 1)  # State.ACTIVE
	if not bool(combat.call("is_fighting")):
		_fail("setting combat state to ACTIVE did not make is_fighting() true")
		combat.set("state", 0)
		return

	await _press("inventory")

	if bool(_menu.call("is_open")):
		_fail("the menu opened mid-fight; `menu_cancel` would open a menu instead of fleeing")

	var hint: Label = _menu.get_node_or_null(^"RefusalHint") as Label
	if hint == null:
		_fail("no on-screen reason appeared when the menu refused to open mid-fight")
	elif not hint.visible or hint.text.is_empty():
		_fail("the refusal hint exists but is not showing a message")
	else:
		print("refusal hint shown: \"%s\"" % hint.text)

	combat.set("state", 0)  # State.INACTIVE, so later checks see a clean fight
	if bool(combat.call("is_fighting")):
		_fail("could not reset combat state after the refusal check")


## What the mouse was doing before the menu opened, so closing can be checked
## against it rather than against a guess.
##
## HEADLESS CANNOT SEE CAPTURE. The dummy DisplayServer reports MOUSE_MODE_VISIBLE
## whatever the world asked for, so this test cannot prove the mouse was freed on
## a real machine — only that the menu recorded the mode it found and put that
## same mode back. The capture itself is checked by the owner opening the menu on
## the Ally and finding the camera still works afterwards, and there is no way
## around that from here.
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE


func _check_opens_on_the_inventory_button(world: Node) -> void:
	_mouse_before = Input.mouse_mode
	if _mouse_before != Input.MOUSE_MODE_CAPTURED:
		print("note: mouse reads %d, not CAPTURED — headless cannot capture" % _mouse_before)

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var position_before := player.global_position if player != null else Vector3.ZERO

	await _press("inventory")

	if not bool(_menu.call("is_open")):
		_fail("pressing `inventory` did not open the menu")
		return

	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		_fail("the menu opened without releasing the mouse (mode %d)" % Input.mouse_mode)
	if int(_menu.get("_mouse_before")) != _mouse_before:
		_fail("the menu recorded mouse mode %d but the world was in %d; closing will restore the wrong one" % [
			int(_menu.get("_mouse_before")), _mouse_before
		])

	if not paused:
		_fail("the menu opened without pausing the tree; the player keeps walking")

	# Prove the pause actually holds rather than merely being set. The player is
	# under gravity on a hillside, so 60 frames of unpaused physics move it.
	if player != null:
		Input.action_press("move_forward")
		for i in 60:
			await physics_frame
		Input.action_release("move_forward")
		var drift := player.global_position.distance_to(position_before)
		if drift > 0.05:
			_fail("the player moved %.2fm while the menu was open" % drift)

	print("opened on `inventory`: mouse released, tree paused, player still")


## Does the legend along the bottom name keys that exist on a keyboard?
##
## It shipped hand-typed: "A  Select        B  Close        Q / LB  Prev tab
## Tab / RB  Next tab". Two entries named both devices and two named only the
## pad — and the literal keyboard B is bound to `build_open` (project.godot),
## so a blind playtest obeying the legend pressed B, opened the Build tab, and
## spent the rest of the session unable to leave the screen the way it came in.
##
## Asserted against the InputMap rather than against a expected string, because
## the Settings tab lets the player move every one of these and a legend pinned
## to today's bindings would be the same defect with a longer fuse.
##
## What deliberately is NOT asserted: that the legend avoids naming a key bound
## to something else. The pad face button and the keyboard key that caused this
## are both called "B", so no substring test can tell "the pad's B" from "the
## key build_open owns" — which is most of why the original legend read as
## plausible.
func _check_the_footer_names_keys_a_keyboard_player_can_press() -> void:
	var footer := _menu.get_node_or_null(^"Root/Frame/Panel/Body/Footer") as Label
	if footer == null:
		_fail("the pause menu has no Footer label; there is no button legend to check")
		return
	var text := str(footer.text)
	if text.is_empty():
		_fail("the pause menu draws an empty button legend")
		return

	# Verb -> the action the legend's entry for it must name a key for. The verbs
	# are read off the drawn text, so a renamed verb fails here loudly rather
	# than passing by matching nothing.
	var verbs := {
		"Select": "menu_confirm",
		"Close": "menu_cancel",
		"Prev tab": "tool_cycle",
		"Next tab": "menu_tab_right",
	}
	for verb: String in verbs.keys():
		var action := str(verbs[verb])
		var key := GLYPH.key_name_for_action(action)
		if key == action:
			# `key_name_for_action` hands back the action id when nothing on a
			# keyboard is bound to it at all.
			_fail("`%s` has no keyboard binding, so the legend's '%s' entry cannot name one" % [action, verb])
			continue
		var entry := _legend_entry_for(text, verb)
		if entry.is_empty():
			_fail("the button legend has no '%s' entry at all: '%s'" % [verb, text])
		elif not entry.contains(key):
			_fail("the legend's '%s' entry reads '%s' and never names '%s', the key `%s` is bound to; "
				% [verb, entry, key, action]
				+ "a keyboard player is being told to press a gamepad button")
	print("footer legend: '%s'" % text)


## The one entry of the legend that ends in `verb`. Entries are separated by a
## run of spaces and the key names inside one are separated by " / ", so a split
## on a four-space run keeps "Escape / B  Close" whole.
func _legend_entry_for(text: String, verb: String) -> String:
	for chunk: String in text.split("    ", false):
		var entry := chunk.strip_edges()
		if entry.ends_with(verb):
			return entry
	return ""


func _check_focus_can_be_driven() -> void:
	var focused := _focused_control()
	if focused == null:
		_fail("nothing holds focus when the menu opens; a stick would move nothing")
		return
	print("focus starts on: %s" % focused.name)

	# Physical d-pad events must reach Godot's ui_* map and then its Control
	# focus machinery. Naming the action directly would skip both bindings.
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	var after_right := _focused_control()
	if after_right == focused:
		_fail("raw D-pad Right moved nothing; the grid cannot be driven with a controller")
	await _pad(JOY_BUTTON_DPAD_DOWN)
	if _focused_control() == after_right:
		_fail("raw D-pad Down moved nothing; the grid cannot be driven with a controller")
	print("focus moves on physical D-pad Right and Down")


func _check_tabs_can_be_cycled() -> void:
	# Owner playtest report: "LB = tab left, RB = tab right". `tool_cycle` (Q /
	# LB) must step BACKWARD and `menu_tab_right` (Tab / RB) must step
	# FORWARD. Drive the physical bindings and visit every registered tab; a
	# two-tab spot check could leave a newly added tab unreachable or unfocused.
	var tab_count := int(_menu.get("_tabs").size())
	var rb := _pad_button_for("menu_tab_right")
	var lb := _pad_button_for("tool_cycle")
	if rb < 0 or lb < 0:
		_fail("LB/RB tab actions do not both have physical joypad bindings")
		return
	var start := int(_menu.get("_index"))
	var visited: Dictionary = {start: true}
	var both_ok := true
	for step in tab_count:
		var before := int(_menu.get("_index"))
		await _pad(rb)
		var after := int(_menu.get("_index"))
		if after != posmod(before + 1, tab_count):
			_fail("physical RB should step to the next tab; went from %d to %d" % [before, after])
			both_ok = false
			break
		visited[after] = true
		if _focused_control() == null:
			_fail("physical RB reached tab %d but left it with no actionable focus" % after)
			both_ok = false
	if visited.size() != tab_count:
		_fail("physical RB reached %d of %d pause tabs" % [visited.size(), tab_count])
		both_ok = false

	var mid := int(_menu.get("_index"))
	await _pad(lb)
	var after_lb := int(_menu.get("_index"))
	if after_lb != posmod(mid - 1, tab_count):
		_fail("physical LB should step to the previous tab; went from %d to %d" % [mid, after_lb])
		both_ok = false
	await _pad(rb)
	var after_rb := int(_menu.get("_index"))
	if after_rb != posmod(after_lb + 1, tab_count):
		_fail("physical RB should step to the next tab; went from %d to %d" % [after_lb, after_rb])
		both_ok = false
	if both_ok:
		print("physical RB reaches all %d tabs with focus; LB and RB move in opposite directions" % tab_count)


## The five-creature cap, seen from the screen rather than from the unit test.
##
## CLAUDE.md forbids storage beyond five. This fills the party through the real
## GameState, asks for a sixth, and checks the screen still shows five rows.
func _check_the_party_screen_holds_five() -> void:
	var party: RefCounted = _game.get("party")
	while not bool(party.call("is_full")):
		var creature: RefCounted = _game.call("make_creature", "terrapup")
		if creature == null:
			_fail("could not build a creature from species.json")
			return
		party.call("add", creature)

	var sixth: RefCounted = _game.call("make_creature", "bramblebun")
	if bool(party.call("add", sixth)):
		_fail("the party accepted a sixth creature")
	if int(party.call("size")) != 5:
		_fail("the party holds %d creatures" % int(party.call("size")))

	# Land on the creature tab and let it draw at least one frame.
	_menu.call("select", 1)
	for i in 4:
		await process_frame

	var rows: int = (_menu.get("_bodies")[1] as Node).get("_rows").size()
	if rows != 5:
		_fail("the party screen draws %d rows, not 5" % rows)
	print("party screen holds five, refuses a sixth")


## OF2: reordering was believed missing but turned out to already be built
## (`autoload/party.gd::move()` and `tab_creatures.gd::_on_row()`, pick-up-then-
## place like the backpack's own stack move) — this proves the WIRING, not
## just the model layer `tests/test_party.gd` already covers: that pressing
## the row button on a controller-focused row actually reaches `party.move()`,
## not just that `move()` itself is correct in isolation.
func _check_party_reorder_button() -> void:
	_menu.call("select", 1)  # Creatures
	for i in 4:
		await process_frame

	var party: RefCounted = _game.get("party")
	var body: Node = _menu.get("_bodies")[1]
	var rows: Array = body.get("_rows")
	if rows.size() < 2:
		_fail("reorder check needs at least two party rows; only %d drawn" % rows.size())
		return

	var first: RefCounted = party.call("at", 0)
	var second: RefCounted = party.call("at", 1)
	if first == null or second == null:
		_fail("reorder check needs slots 0 and 1 both filled; the five-creature check should have done that")
		return

	(rows[0] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")
	if int(body.get("_held")) != 0:
		_fail("pressing the focused row's confirm button did not pick up slot 0 (_held=%d)" % int(body.get("_held")))
		return

	await _press("ui_down")
	if _focused_control() != rows[1]:
		_fail("ui_down did not move focus from row 0 to row 1 while a creature was held")
	await _press("ui_accept")

	if int(body.get("_held")) != -1:
		_fail("placing on row 1 did not release the held slot")
	if not (party.call("at", 0) == second and party.call("at", 1) == first):
		_fail("swapping rows 0 and 1 through the UI did not reach party.move() -- the two creatures were not exchanged")
	else:
		print("party reorder: pressing row 0 then row 1 swapped them via party.move()")


## OF2: using a heal item used to apply itself to whichever creature was most hurt
## with no way to choose. Drives the real input path end to end -- open the
## picker, cancel it (nothing spent), reopen it, confirm a specific target
## with the SAME button the grid's pick-up-then-place uses, and check the
## item was spent and the CHOSEN creature (not just "the worst one") was healed.
## TEST2: driven with real `InputEventJoypadButton` presses (via `_pad`), not
## `_press`'s `InputEventAction` — an action event names the action directly
## and never travels the InputMap, so this used to prove the code heals a
## creature once an action fires without proving a real controller press ever
## reaches it. Button indices come from the live InputMap, same discipline
## `smoke_backpack_pad_target.gd` established when it found the confirm half
## of this exact picker unreachable from a pad (OW4).
func _check_backpack_target_picker() -> void:
	var use_button := _pad_button_for("interact")
	var cancel_button := _pad_button_for("menu_cancel")
	var accept_button := _pad_button_for("ui_accept")
	if use_button < 0 or cancel_button < 0 or accept_button < 0:
		_fail("interact, menu_cancel or ui_accept has no joypad binding — a controller cannot drive this picker")
		return

	_menu.call("select", 0)  # Backpack
	for i in 4:
		await process_frame

	var party: RefCounted = _game.get("party")
	var inventory: RefCounted = _game.get("inventory")
	var body: Node = _menu.get("_bodies")[0]

	var target: RefCounted = party.call("at", 1)
	if target == null:
		_fail("target-picker check needs slot 1 filled; the five-creature check should have done that")
		return
	target.set("hp", 1.0)
	if float(target.call("hp_fraction")) >= 1.0:
		_fail("could not injure the slot-1 creature to set up the target-picker check")
		return

	inventory.call("add", "potion_small", 3)
	var slot: int = int(inventory.call("find_slot", "potion_small"))
	if slot < 0:
		_fail("could not find the potion slot after adding one")
		return
	var count_before: int = int(inventory.call("count", "potion_small"))
	var hp_before: float = float(target.get("hp"))

	(body.get("_buttons")[slot] as Button).grab_focus()
	await process_frame
	await _pad(use_button)

	if int(body.get("_targeting")) != slot:
		_fail("a real pad press of Use (joypad %d) did not open the target picker" % use_button)
		return
	if int(inventory.call("count", "potion_small")) != count_before:
		_fail("opening the target picker already spent the item, before any target was chosen")
	if float(target.get("hp")) != hp_before:
		_fail("opening the target picker already healed a creature, before any target was chosen")

	# OF22: the picker must focus the first ELIGIBLE row on its own -- slot 0
	# is at full health (ineligible, greyed) and slot 1 is the only creature
	# below max HP, so an unassisted `_read_use()` has to land here. This is
	# deliberately NOT preceded by a `grab_focus()` call of the test's own --
	# that was the exact thing masking the "you can't choose" bug the owner
	# reported (OF22's brief). If this assertion ever needs a manual
	# grab_focus to pass, the bug is back.
	var target_rows: Array = body.get("_target_rows")
	if _focused_control() != target_rows[1]:
		_fail("opening the target picker did not focus the first eligible row (slot 1, the only injured creature) on its own")
		return
	print("target picker opens on a real pad Use press instead of applying immediately, and focuses the first eligible row unassisted")

	await _pad(cancel_button)
	if int(body.get("_targeting")) != -1:
		_fail("a real pad press of Cancel (joypad %d) did not back out of the target picker" % cancel_button)
	if int(inventory.call("count", "potion_small")) != count_before:
		_fail("cancelling the target picker spent the item anyway")
	print("target picker cancels on a real pad Cancel press without spending the item")

	(body.get("_buttons")[slot] as Button).grab_focus()
	await process_frame
	await _pad(use_button)
	if int(body.get("_targeting")) != slot:
		_fail("could not reopen the target picker for the confirm half of the check")
		return
	if _focused_control() != target_rows[1]:
		_fail("reopening the target picker did not refocus the first eligible row on its own")
		return

	await _pad(accept_button)

	if int(body.get("_targeting")) != -1:
		_fail("a real pad press of Confirm (joypad %d) did not close the picker" % accept_button)
	if int(inventory.call("count", "potion_small")) != count_before - 1:
		_fail("a real pad Confirm press did not spend the item")
	if float(target.get("hp")) <= hp_before:
		_fail("a real pad Confirm press on slot 1 as the target did not heal the creature in slot 1")
	else:
		print("target picker heals the CHOSEN creature (slot 1) and spends the item on a real pad Confirm press (joypad %d)" % accept_button)


## OF22 owner report: "you choose the creature to use it on but it doesn't do
## anything. You can't choose." Root cause included `_first_target_row()`
## returning null whenever nothing was eligible (a full-HP party makes every
## row ineligible under this task's own rule), which used to open the picker
## anyway with focus landing on nothing. The fix refuses to open at all in
## that case. Runs against a party healed back to full by the previous check.
func _check_backpack_target_picker_full_party() -> void:
	_menu.call("select", 0)  # Backpack
	for i in 4:
		await process_frame

	var party: RefCounted = _game.get("party")
	var inventory: RefCounted = _game.get("inventory")
	var body: Node = _menu.get("_bodies")[0]

	for i in int(party.call("size")):
		var creature: RefCounted = party.call("at", i)
		if creature != null:
			creature.call("heal_fully")
			if float(creature.call("hp_fraction")) < 1.0:
				_fail("heal_fully() did not bring slot %d back to full health" % i)
				return

	inventory.call("add", "potion_small", 1)
	var slot: int = int(inventory.call("find_slot", "potion_small"))
	if slot < 0:
		_fail("could not find a potion slot for the full-HP-party check")
		return
	var count_before: int = int(inventory.call("count", "potion_small"))

	var item_button: Button = body.get("_buttons")[slot] as Button
	item_button.grab_focus()
	await process_frame
	await _press("interact")

	if int(body.get("_targeting")) != -1:
		_fail("Use opened the target picker even though the whole party is at full health")
		return
	if int(inventory.call("count", "potion_small")) != count_before:
		_fail("refusing to open the picker for a full-HP party still spent the item")
	if _focused_control() != item_button:
		_fail("refusing the full-HP-party Use did not leave focus on the item grid")
	var status: Label = _menu.get("_status") as Label
	if status == null or not status.text.to_lower().contains("full health"):
		_fail("refusing the full-HP-party Use showed no on-screen reason")
	else:
		print("Use on a heal item refuses to open the picker when the whole party is at full health, and says so: \"%s\"" % status.text)


## Owner playtest report: "berries cannot properly be fed to creatures from the
## menu." Root cause turned out narrower than the report -- D29 puts satiety
## on the PLAYER (`player_vitals.gd`), never on a creature, so `berries` was never
## going to open the creature target picker at all. The real bug was that
## `tab_backpack.gd::_read_use()` had no branch for a `food`-kind item's
## `satiety` field whatsoever: pressing Use on a berry said "is not something
## you can use here" unconditionally. This drives the same real input path
## the potion check above does and checks the player actually gets fed.
func _check_backpack_food_eat() -> void:
	_menu.call("select", 0)  # Backpack
	for i in 4:
		await process_frame

	var inventory: RefCounted = _game.get("inventory")
	var db: RefCounted = _game.get("items")
	var body: Node = _menu.get("_bodies")[0]
	var player: Node = current_scene.get_node_or_null(^"Player")
	if player == null:
		_fail("food-eat check needs a Player node in the scene")
		return
	var vitals: RefCounted = player.get("vitals")
	if vitals == null:
		_fail("food-eat check needs the Player to carry vitals")
		return

	vitals.set("satiety", 10.0)

	inventory.call("add", "berries", 3)
	var slot: int = int(inventory.call("find_slot", "berries"))
	if slot < 0:
		_fail("could not find the berries slot after adding some")
		return
	var count_before: int = int(inventory.call("count", "berries"))
	var satiety_before: float = float(vitals.get("satiety"))
	var restore: float = float((db.call("definition", "berries") as Dictionary).get("satiety", 0.0))
	if restore <= 0.0:
		_fail("berries' own item definition carries no satiety value; cannot verify the fix meaningfully")
		return

	(body.get("_buttons")[slot] as Button).grab_focus()
	await process_frame
	await _press("interact")

	if int(inventory.call("count", "berries")) != count_before - 1:
		_fail("pressing Use on berries did not spend one from the stack")
	if float(vitals.get("satiety")) <= satiety_before:
		_fail("pressing Use on berries did not restore the player's satiety")
	else:
		print("Use on berries restores the player's satiety and spends the item, no target picker")


## OF29 owner report: "I can pick up a TM but it needs to go in my inventory
## and then I see it's stats and choose who to teach it to." The old build
## made a TM a progression flag and let the Team screen silently auto-teach
## whichever creature was focused, so none of this path existed. Drives the
## whole of it through real input: a TM item in the satchel, Use, the target
## picker with per-row eligibility, confirm, and the disc actually spent.
##
## The smoke party is five terrapups (`_check_the_party_screen_holds_five`),
## a ground species whose quick move is `pebble_toss` — so `tm_burrow_strike`
## (quick, ground) is teachable to every one of them, and teaching slot 0
## makes THAT SAME creature ineligible on the next open, which is how the
## "already knows it" reason gets exercised without disturbing the party.
func _check_backpack_tm_teach() -> void:
	_menu.call("select", 0)  # Backpack
	for i in 4:
		await process_frame

	var party: RefCounted = _game.get("party")
	var inventory: RefCounted = _game.get("inventory")
	var body: Node = _menu.get("_bodies")[0]

	var student: RefCounted = party.call("at", 0)
	if student == null:
		_fail("TM check needs slot 0 filled; the five-creature check should have done that")
		return
	if str(student.get("move_quick")) == "burrow_strike":
		_fail("TM check fixture already knew burrow_strike; the check would prove nothing")
		return

	inventory.call("add", "tm_burrow_strike", 1)
	var slot: int = int(inventory.call("find_slot", "tm_burrow_strike"))
	if slot < 0:
		_fail("could not find the TM slot after adding one -- did the pickup ever reach the satchel?")
		return

	# "I see it's stats": the detail panel has to name the move and its
	# numbers before any of the choosing happens.
	(body.get("_buttons")[slot] as Button).grab_focus()
	for i in 4:
		await process_frame
	var effect: Label = body.get("_detail_effect") as Label
	var detail: String = effect.text if effect != null else ""
	if not (detail.contains("Burrow Strike") and detail.to_lower().contains("quick")
			and detail.to_lower().contains("ground")):
		_fail("the TM's detail panel did not show the move, its slot and its compatibility (showed \"%s\")"
			% detail.replace("\n", " / "))
	else:
		print("TM detail panel reads: \"%s\"" % detail.replace("\n", " / "))

	await _press("interact")

	if int(body.get("_targeting")) != slot:
		_fail("pressing Use on a TM did not open the target picker")
		return
	if str(body.get("_targeting_tm")) != "tm_burrow_strike":
		_fail("the picker opened without recording which TM it was opened for")
	if int(inventory.call("count", "tm_burrow_strike")) != 1:
		_fail("opening the TM picker already spent the disc, before any creature was chosen")
	var header: Label = body.get("_target_header") as Label
	if header == null or not header.text.contains("Burrow Strike"):
		_fail("the TM picker's header did not name the move being taught")

	var target_rows: Array = body.get("_target_rows")
	if _focused_control() != target_rows[0]:
		_fail("opening the TM picker did not focus the first eligible row on its own")
		return

	await _press("ui_accept")

	if int(body.get("_targeting")) != -1:
		_fail("confirming a TM target did not close the picker")
	if str(student.get("move_quick")) != "burrow_strike":
		_fail("confirming slot 0 did not teach it the TM's move (move_quick is '%s')"
			% str(student.get("move_quick")))
	if int(inventory.call("count", "tm_burrow_strike")) != 0:
		_fail("teaching did not consume the TM (OF29: one disc teaches one creature)")
	else:
		print("TM taught to the CHOSEN creature and the disc was consumed")

	# Second copy: slot 0 now already knows the move, so its row must grey out
	# with the reason showing, and focus must skip past it to slot 1.
	inventory.call("add", "tm_burrow_strike", 1)
	var slot_two: int = int(inventory.call("find_slot", "tm_burrow_strike"))
	if slot_two < 0:
		_fail("could not find the second TM disc after adding it")
		return
	(body.get("_buttons")[slot_two] as Button).grab_focus()
	await process_frame
	await _press("interact")

	if int(body.get("_targeting")) != slot_two:
		_fail("could not reopen the TM picker for the eligibility half of the check")
		return
	target_rows = body.get("_target_rows")
	var taught_row: Button = target_rows[0] as Button
	if not taught_row.disabled or not taught_row.text.contains("already knows it"):
		_fail("the row for the creature that just learned the move was not greyed out with a reason (row reads \"%s\")"
			% taught_row.text)
	else:
		print("TM picker greys the creature that already knows the move: \"%s\"" % taught_row.text.strip_edges())
	if _focused_control() != target_rows[1]:
		_fail("the TM picker focused an ineligible row instead of skipping to the next eligible creature")

	await _press("menu_cancel")
	if int(body.get("_targeting")) != -1:
		_fail("`menu_cancel` did not back out of the TM picker")
	if int(inventory.call("count", "tm_burrow_strike")) != 1:
		_fail("cancelling the TM picker spent the disc anyway")
	else:
		print("TM picker cancels without spending the disc")


## The same "never open a picker nobody can use" rule OF22 put on potions,
## for TMs: every smoke-party terrapup already knows `stone_rush` (it is their
## species' own charged move), so a Stone Rush disc must refuse to open at all
## and say why, rather than showing five greyed rows with nowhere for focus.
func _check_backpack_tm_refuses_when_nobody_can_learn() -> void:
	_menu.call("select", 0)  # Backpack
	for i in 4:
		await process_frame

	var inventory: RefCounted = _game.get("inventory")
	var body: Node = _menu.get("_bodies")[0]

	inventory.call("add", "tm_stone_rush", 1)
	var slot: int = int(inventory.call("find_slot", "tm_stone_rush"))
	if slot < 0:
		_fail("could not find the Stone Rush disc after adding it")
		return

	var item_button: Button = body.get("_buttons")[slot] as Button
	item_button.grab_focus()
	await process_frame
	await _press("interact")

	if int(body.get("_targeting")) != -1:
		_fail("Use opened the TM picker even though every creature already knows the move")
		return
	if int(inventory.call("count", "tm_stone_rush")) != 1:
		_fail("refusing to open the TM picker still spent the disc")
	if _focused_control() != item_button:
		_fail("refusing the TM Use did not leave focus on the item grid")
	var status: Label = _menu.get("_status") as Label
	if status == null or not status.text.contains("Stone Rush"):
		_fail("refusing the TM Use showed no on-screen reason")
	else:
		print("Use on a TM nobody can learn refuses to open the picker, and says so: \"%s\"" % status.text)


## Drop discards a stack after a confirm; split halves a stack into an empty
## slot on the same press. Both are new backpack verbs on dedicated buttons
## (`backpack_drop`, `backpack_split`), so this drives the real input path the
## way the Use target-picker check above does, rather than only proving
## inventory.gd's own split_slot()/drop_slot() are correct in isolation --
## tests/test_inventory.gd already covers that layer.
func _check_backpack_drop_and_split() -> void:
	_menu.call("select", 0)  # Backpack
	for i in 4:
		await process_frame

	var inventory: RefCounted = _game.get("inventory")
	var body: Node = _menu.get("_bodies")[0]

	# --- split: one press, no confirm, both halves stay in the satchel -----
	inventory.call("add", "wood", 10)
	var wood_slot: int = int(inventory.call("find_slot", "wood"))
	if wood_slot < 0:
		_fail("could not find the wood slot after adding some")
		return
	var wood_before: int = int(inventory.call("count", "wood"))

	(body.get("_buttons")[wood_slot] as Button).grab_focus()
	await process_frame
	await _press("backpack_split")

	if int(inventory.call("count", "wood")) != wood_before:
		_fail("splitting changed the total amount of wood held")
	var half_slot: int = -1
	for i in int(inventory.call("slot_count")):
		if i == wood_slot:
			continue
		if str((inventory.call("stack_at", i) as Dictionary).get("id", "")) == "wood":
			half_slot = i
			break
	if half_slot < 0:
		_fail("`backpack_split` did not open a second wood stack in an empty slot")
	else:
		print("backpack_split halves a stack (%d at the source, %d split into slot %d)" % [
			int((inventory.call("stack_at", wood_slot) as Dictionary).get("n", 0)),
			int((inventory.call("stack_at", half_slot) as Dictionary).get("n", 0)), half_slot
		])

	# --- drop: confirm-gated, cancels clean, confirm deletes for good ------
	inventory.call("add", "berries", 5)
	var berry_slot: int = int(inventory.call("find_slot", "berries"))
	if berry_slot < 0:
		_fail("could not find the berries slot after adding some")
		return
	var berries_before: int = int(inventory.call("count", "berries"))

	(body.get("_buttons")[berry_slot] as Button).grab_focus()
	await process_frame
	await _press("backpack_drop")

	if int(body.get("_confirming")) != berry_slot:
		_fail("pressing Drop on a stack did not open the drop confirmation")
		return
	if int(inventory.call("count", "berries")) != berries_before:
		_fail("opening the drop confirmation already removed the item, before any confirm")

	await _press("menu_cancel")
	if int(body.get("_confirming")) != -1:
		_fail("`menu_cancel` did not back out of the drop confirmation")
	if int(inventory.call("count", "berries")) != berries_before:
		_fail("cancelling the drop confirmation removed the item anyway")
	print("drop confirmation cancels on `menu_cancel` without removing the item")

	(body.get("_buttons")[berry_slot] as Button).grab_focus()
	await process_frame
	await _press("backpack_drop")
	if int(body.get("_confirming")) != berry_slot:
		_fail("could not reopen the drop confirmation for the confirm half of the check")
		return

	var confirm_rows: Array = body.get("_confirm_rows")
	(confirm_rows[0] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")

	if int(body.get("_confirming")) != -1:
		_fail("confirming a drop did not close the confirmation panel")
	if int(inventory.call("count", "berries")) != 0:
		_fail("confirming Drop did not remove the item from the satchel")
	else:
		print("backpack_drop removes the stack for good once confirmed")


## OW1 owner report: "I can't move things in my inventory. There's no separate
## hot bar section. I can't move anything into it."
##
## Both halves were discoverability, not mechanism, so this checks the things a
## player can actually PERCEIVE, not only that the model changed underneath:
##
##   - the quick bar has a home in this screen at all (five real, pressable
##     chips), which is the half that simply did not exist;
##   - a pick-up ANNOUNCES itself. The old code set `_held` and said nothing;
##     the 2026-08-15 blind playtest picked up an orb stack by accident and had
##     no way to tell. Asserting `_held` alone would have passed on that build;
##   - a place announces itself and actually moves the stack;
##   - a held stack can be put onto a quick slot with the same press, and the
##     binding lands in `Game.hotbar` where the field HUD reads it;
##   - `menu_cancel` while holding puts the stack back instead of closing the
##     whole menu out from under a player who is mid-move;
##   - the detail column NAMES the move verb. It never did, which is the
##     literal content of "I can't move things in my inventory."
func _check_backpack_move_and_quick_bar() -> void:
	_menu.call("select", 0)  # Backpack
	for i in 4:
		await process_frame

	var game := _game
	var inventory: RefCounted = game.get("inventory")
	var body: Node = _menu.get("_bodies")[0]
	var status: Label = _menu.get("_status") as Label

	# --- the bar has a section on this screen ------------------------------
	var bar_buttons: Array = body.get("_bar_buttons") if body.get("_bar_buttons") != null else []
	if bar_buttons.size() != 5:
		_fail("the backpack tab draws %d quick-bar slots, not 5 -- the hotbar still has no home in the UI" % bar_buttons.size())
	else:
		print("backpack draws a %d-slot quick bar section" % bar_buttons.size())

	# --- pick up: it must say so -------------------------------------------
	inventory.call("add", "orb_basic", 4)
	var source: int = int(inventory.call("find_slot", "orb_basic"))
	if source < 0:
		_fail("could not find the orb slot after adding some")
		return
	var empty := -1
	for i in int(inventory.call("slot_count")):
		if bool(inventory.call("is_slot_empty", i)):
			empty = i
			break
	if empty < 0:
		_fail("the move check needs one empty satchel slot and the bag is full")
		return

	(body.get("_buttons")[source] as Button).grab_focus()
	await process_frame
	_menu.call("say", "")
	await _press("ui_accept")

	if int(body.get("_held")) != source:
		_fail("pressing confirm on a full slot did not pick the stack up (_held=%d)" % int(body.get("_held")))
		return
	if status == null or status.text.is_empty():
		_fail("picking a stack up said nothing on screen; a player cannot tell it happened")
	elif not status.text.contains("Orb"):
		_fail("the pick-up message does not name what was picked up: \"%s\"" % status.text)
	else:
		print("pick-up announces itself: \"%s\"" % status.text)

	var banner: RichTextLabel = body.get("_held_banner") as RichTextLabel
	if banner == null or not banner.visible:
		_fail("nothing on the backpack screen shows that a stack is in hand")
	elif not banner.text.contains("HOLDING"):
		_fail("the held-stack banner is visible but does not say a stack is held: \"%s\"" % banner.text)

	# --- cancel: put it back, and do NOT close the menu ---------------------
	await _press("menu_cancel")
	if not bool(_menu.call("is_open")):
		_fail("`menu_cancel` while holding a stack closed the whole menu instead of putting the stack back")
		return
	if int(body.get("_held")) != -1:
		_fail("`menu_cancel` while holding a stack did not put it back down")
	else:
		print("`menu_cancel` while holding puts the stack back and keeps the menu open")

	# --- place into a chosen empty slot ------------------------------------
	(body.get("_buttons")[source] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")
	if int(body.get("_held")) != source:
		_fail("could not pick the stack up again for the place half of the check")
		return

	(body.get("_buttons")[empty] as Button).grab_focus()
	await process_frame
	_menu.call("say", "")
	await _press("ui_accept")

	if int(body.get("_held")) != -1:
		_fail("placing onto an empty slot did not release the held stack")
	if str((inventory.call("stack_at", empty) as Dictionary).get("id", "")) != "orb_basic":
		_fail("placing onto slot %d did not move the orbs there" % (empty + 1))
	elif status == null or not status.text.contains("Orb"):
		_fail("placing a stack said nothing that names it: \"%s\"" % (status.text if status != null else ""))
	else:
		print("a stack moves to the CHOSEN slot and says so: \"%s\"" % status.text)

	# --- place onto a quick slot -------------------------------------------
	var moved: int = int(inventory.call("find_slot", "orb_basic"))
	if moved < 0:
		_fail("lost the orbs somewhere between the move and the bind check")
		return
	if bar_buttons.size() != 5:
		# Already failed above. Everything past here presses a chip that does
		# not exist, so stop rather than crash on an empty array -- the
		# assertions before this point still ran against the real build.
		return
	game.call("assign_hotbar", 3, "")
	(body.get("_buttons")[moved] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")
	if int(body.get("_held")) != moved:
		_fail("could not pick the stack up for the quick-bar half of the check")
		return

	(bar_buttons[3] as Button).grab_focus()
	await process_frame
	_menu.call("say", "")
	await _press("ui_accept")

	var bar: Array = game.get("hotbar") as Array
	if str(bar[3]) != "orb_basic":
		_fail("placing a held stack onto quick slot 4 did not bind it (slot 4 holds '%s')" % str(bar[3]))
	elif int(body.get("_held")) != -1:
		_fail("binding to a quick slot did not release the held stack")
	elif status == null or not status.text.contains("quick slot"):
		_fail("binding to a quick slot said nothing about it: \"%s\"" % (status.text if status != null else ""))
	else:
		print("a held stack binds to the chosen quick slot: \"%s\"" % status.text)

	# The satchel must be UNCHANGED by a bind -- the bar holds item ids, and a
	# player who thought his orbs had left the bag would be right to panic.
	if str((inventory.call("stack_at", moved) as Dictionary).get("id", "")) != "orb_basic":
		_fail("binding an item to the quick bar removed it from the satchel")

	# --- a raw material is refused, out loud, without dropping the stack ----
	var wood_slot: int = int(inventory.call("find_slot", "wood"))
	if wood_slot >= 0:
		(body.get("_buttons")[wood_slot] as Button).grab_focus()
		await process_frame
		await _press("ui_accept")
		(bar_buttons[4] as Button).grab_focus()
		await process_frame
		_menu.call("say", "")
		await _press("ui_accept")
		bar = game.get("hotbar") as Array
		if str(bar[4]) == "wood":
			_fail("a raw material was allowed onto the quick bar")
		if int(body.get("_held")) != wood_slot:
			_fail("refusing a raw material dropped the held stack; the player is left with nowhere to put it")
		if status == null or status.text.is_empty():
			_fail("refusing a raw material on the quick bar said nothing")
		else:
			print("a raw material is refused out loud and stays in hand: \"%s\"" % status.text)
		await _press("menu_cancel")

	# --- the screen names the move verb ------------------------------------
	(body.get("_buttons")[moved] as Button).grab_focus()
	for i in 4:
		await process_frame
	var hint: RichTextLabel = body.get("_detail_hint") as RichTextLabel
	if hint == null:
		_fail("the backpack's verb legend is not a RichTextLabel and cannot draw button glyphs")
	elif not hint.text.to_lower().contains("pick up"):
		_fail("the backpack's verb legend never names the move verb: \"%s\"" % hint.text.replace("\n", " / "))
	else:
		print("the verb legend names the move verb")

	# --- and stops claiming satchel slot N is hotbar slot N -----------------
	(body.get("_buttons")[0] as Button).grab_focus()
	for i in 4:
		await process_frame
	var kind: Label = body.get("_detail_kind") as Label
	var blurb: Label = body.get("_detail_blurb") as Label
	var claim := "%s %s" % [kind.text if kind != null else "", blurb.text if blurb != null else ""]
	if claim.to_lower().contains("hotbar 1") or claim.to_lower().contains("also hotbar"):
		_fail("the detail column still claims satchel slot 1 is a hotbar slot: \"%s\"" % claim.strip_edges())
	else:
		print("the detail column no longer claims satchel slot N is hotbar slot N")


## SB11: the quest log tab reads the same flag store the HUD's tracked line
## does, and shows the one authored Main Story objective as OPEN before its
## flag is set.
func _check_quest_log_tab() -> void:
	var tabs: Array = _menu.get("_tabs")
	var index := -1
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == "quest_log":
			index = i
			break
	if index < 0:
		_fail("no quest_log tab is registered in menu.json")
		return

	_menu.call("select", index)
	for i in 4:
		await process_frame

	var body: Node = _menu.get("_bodies")[index]
	var main_list: VBoxContainer = body.get("_main_list")
	if main_list == null or main_list.get_child_count() == 0:
		_fail("quest log's Main Story list drew no rows")
		return

	# GATE B grew the main chain from two entries to twelve, and the road gate
	# is no longer the first of them. This check was never about position --
	# it is about the tab actually rendering the authored chain and reading a
	# flag's real state -- so it finds the row by its own text rather than
	# assuming it is row 0, which the next inserted beat would break again.
	var road_gate_row: Label = null
	for child: Node in main_list.get_children():
		var row: Label = child as Label
		if row != null and row.text.find("gate") != -1:
			road_gate_row = row
			break
	if road_gate_row == null:
		_fail("quest log's Main Story list does not show the road-gate objective")
	elif road_gate_row.text.begins_with("✓"):
		_fail("the road-gate objective reads done before its flag is set")
	else:
		print("quest log tab shows the road-gate objective, correctly open (row %d of %d)" % [
			road_gate_row.get_index(), main_list.get_child_count()
		])


## Save is the only tab whose advertised A action writes outside the running
## state. Swap in a dedicated save-system directory so the physical-button
## proof cannot overwrite a player's slot, then restore the real object and
## remove only the isolated file this check created.
func _check_save_tab_controller_actions() -> void:
	var tabs: Array = _menu.get("_tabs")
	var index := -1
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == "save":
			index = i
			break
	if index < 0:
		_fail("no Save tab is registered in menu.json")
		return

	_cleanup_controller_save_dir()
	var original: RefCounted = _game.get("save_system")
	var isolated: RefCounted = SAVE_GAME.new(CONTROLLER_SAVE_DIR)
	_game.set("save_system", isolated)
	_menu.call("select", index)
	for i in 6:
		await process_frame

	var body: Node = _menu.get("_bodies")[index]
	var rows: Array = body.get("_rows")
	if rows.is_empty():
		_fail("Save tab drew no slot rows")
		_game.set("save_system", original)
		_cleanup_controller_save_dir()
		return
	var save_button: Button = (rows[0] as Dictionary)["save"]
	var load_button: Button = (rows[0] as Dictionary)["load"]
	if _focused_control() != save_button:
		_fail("Save tab did not focus slot 1 Save on entry")

	var saved_day := int(_game.get("day"))
	await _press("ui_accept")
	if not bool(isolated.call("has_slot", 0)):
		_fail("physical A on slot 1 Save wrote no isolated save")
	if _focused_control() != save_button:
		_fail("Save tab lost focus after writing the slot")

	await _press("ui_right")
	if _focused_control() != load_button or load_button.disabled:
		_fail("physical D-pad Right could not reach the newly enabled Load action")
	else:
		_game.set("day", saved_day + 1)
		await _press("ui_accept")
		if int(_game.get("day")) != saved_day:
			_fail("physical A on Load did not restore the isolated slot")

	_game.set("save_system", original)
	_cleanup_controller_save_dir()
	print("Save tab: physical A saves, D-pad reaches Load, and physical A restores the isolated slot")


func _cleanup_controller_save_dir() -> void:
	for slot in 5:
		var uri := "%sslot_%d.json" % [CONTROLLER_SAVE_DIR, slot]
		if FileAccess.file_exists(uri):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(uri))
	var absolute_dir := ProjectSettings.globalize_path(CONTROLLER_SAVE_DIR.trim_suffix("/"))
	if DirAccess.dir_exists_absolute(absolute_dir):
		DirAccess.remove_absolute(absolute_dir)


## SB11's own done-when: completing an objective changes the HUD line without
## a scene reload. Sets the real progression flag the way road_gate.gd does,
## waits a few frames for `Game._process()` to notice `progression.revision`
## moved, and checks BOTH the source of truth (`Game.objective_text`) and the
## actual on-screen Label -- a passing check against the field alone would not
## prove the HUD itself redrew. Run with the menu CLOSED: the tree is paused
## while it is open, so the HUD's own `_process()` would never run and this
## would falsely pass for the wrong reason.
func _check_objective_line_updates_without_reload(world: Node) -> void:
	var progression: RefCounted = _game.get("progression")
	if progression == null:
		_fail("Game has no progression state; cannot check the objective line")
		return
	# Originally this flipped `road_gate_open` by name, which silently assumed
	# the road gate was the objective the HUD was tracking. GATE B put nine
	# more beats into the chain ahead of it, so setting that one flag stopped
	# changing the tracked line at all and the check failed for a reason that
	# had nothing to do with what it exists to prove. Ask the chain which
	# objective is actually being tracked instead; that is the flag whose
	# completion must move the line, whatever the chain looks like later.
	var tracked_flag := _first_undone_main_flag(progression)
	if tracked_flag.is_empty():
		_fail("every main objective is already done; this check needs one to flip")
		return

	var text_before: String = str(_game.get("objective_text"))
	var hud: Node = world.get_node_or_null(^"PlaygroundHUD")
	var hud_label: Label = hud.get("_objective_text_label") if hud != null else null
	var label_before := hud_label.text if hud_label != null else ""

	progression.call("set_flag", tracked_flag)
	for i in 6:
		await process_frame

	var text_after: String = str(_game.get("objective_text"))
	if text_after == text_before:
		_fail("Game.objective_text did not change after completing %s" % tracked_flag)
	elif hud_label != null and hud_label.text == label_before:
		_fail("the HUD's on-screen objective line did not redraw after the flag changed")
	else:
		print("objective line updates live, no scene reload: \"%s\" -> \"%s\"" % [
			label_before, hud_label.text if hud_label != null else text_after
		])

	# Reset so this run's own state does not leak into anything checked after it.
	progression.call("set_flag", tracked_flag, false)


## The first main objective whose flag is not yet set -- exactly what
## quest_log.gd's `tracked_text()` reports on, read from the same authored
## file rather than restated here, so inserting a beat cannot desynchronise
## this check from the thing it is checking.
func _first_undone_main_flag(progression: RefCounted) -> String:
	var raw := FileAccess.get_file_as_string("res://data/progression/objectives.json")
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	for item: Variant in ((parsed as Dictionary).get("main", []) as Array):
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var flag := str((item as Dictionary).get("flag_id", ""))
		if not flag.is_empty() and not bool(progression.call("has", flag)):
			return flag
	return ""


# --- closing ----------------------------------------------------------------


func _check_closes_and_gives_the_game_back(world: Node) -> void:
	await _press("menu_cancel")

	if bool(_menu.call("is_open")):
		_fail("`menu_cancel` did not close the menu")
		return
	if Input.mouse_mode != _mouse_before:
		_fail("closing left the mouse at %d, not the %d it found; the camera is dead" % [
			Input.mouse_mode, _mouse_before
		])
	if paused:
		_fail("closing left the tree paused; the game is frozen with no menu on it")

	# And the world moves again.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var before := player.global_position
		Input.action_press("move_forward")
		for i in 60:
			await physics_frame
		Input.action_release("move_forward")
		if player.global_position.distance_to(before) < 0.5:
			_fail("the player still cannot move after the menu closed")
	print("closed on `menu_cancel`: mouse recaptured, tree running, player free")


func _check_opens_on_the_menu_button() -> void:
	await _press("menu_cancel")
	if not bool(_menu.call("is_open")):
		_fail("pressing `menu_cancel` in the world did not open the menu")
		return
	await _press("menu_cancel")
	if bool(_menu.call("is_open")):
		_fail("the same button that opened the menu did not close it")
	print("`menu_cancel` opens and closes")


func _focused_control() -> Control:
	var viewport := root.get_viewport()
	return viewport.gui_get_focus_owner() if viewport != null else null


## Is a window focus regain actually wired to re-capture the mouse, and does
## the gate that stops it stealing the mouse from an open menu work?
##
## Exercises scripts/world/playground_world.gd's `_capture_mouse_if_free()`,
## connected to `Window.focus_entered` as the RB1 fix: on a real Windows
## launch, a MOUSE_MODE_CAPTURED request made before the native window has OS
## focus can be silently dropped — `Input.mouse_mode` still reads back
## CAPTURED, so nothing downstream can tell, but the cursor was never
## actually confined and the camera never turns.
##
## HEADLESS CANNOT SEE REAL CAPTURE, confirmed by this file's own long-
## standing note above (`_mouse_before`): the dummy DisplayServer reports
## `Input.mouse_mode` as VISIBLE no matter what is requested, so reading it
## back after a `focus_entered.emit()` proves nothing here — a `Input.mode !=
## CAPTURED` check would fail on this build even with the fix wired
## correctly. What CAN be proven without touching that getter: the signal is
## actually connected, and `_mouse_wanted_elsewhere()` — the gate that stops a
## focus regain from stealing the mouse out from under an open menu — reports
## true exactly while the menu is open and false once it closes. Real
## on-device confirmation that focus regain actually re-captures is still
## required and is not claimed here.
func _check_focus_recapture_respects_open_ui(world: Node) -> void:
	if not world.has_method("_mouse_wanted_elsewhere") or not world.has_method("_capture_mouse_if_free"):
		_fail("playground_world is missing the RB1 mouse-recapture methods")
		return

	var handler := Callable(world, "_capture_mouse_if_free")
	if not world.get_window().focus_entered.is_connected(handler):
		_fail("Window.focus_entered is not wired to re-capture the mouse; a focus regain after a dropped boot-time capture will never retry it")

	if bool(world.call("_mouse_wanted_elsewhere")):
		_fail("_mouse_wanted_elsewhere is true with nothing open")

	_menu.call("open")
	if not bool(world.call("_mouse_wanted_elsewhere")):
		_fail("_mouse_wanted_elsewhere is false while the menu is open; a focus regain would steal the mouse from an open menu")
	_menu.call("close")

	if bool(world.call("_mouse_wanted_elsewhere")):
		_fail("_mouse_wanted_elsewhere is true after the menu closed")

	print("focus_entered is wired to recapture, and the gate correctly tracks the menu's open state")
