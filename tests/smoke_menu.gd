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
##
## Boots the real main scene with the real autoload, and drives it with injected
## input rather than by calling open() directly — calling the method would prove
## the method works and nothing about whether the button reaches it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

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
	await _check_focus_can_be_driven()
	await _check_tabs_can_be_cycled()
	await _check_the_party_screen_holds_five()
	await _check_party_reorder_button()
	await _check_backpack_target_picker()
	await _check_backpack_food_eat()
	await _check_backpack_drop_and_split()
	await _check_closes_and_gives_the_game_back(world)
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


## Press an action down both paths, because the menu uses both.
##
## `Input.action_press` sets the action state, which is what the menu's own
## polling reads. It does NOT put an event through the tree, so on its own it
## cannot move Control focus — and focus navigation is the half of a controller
## menu that a poll cannot do. `parse_input_event` supplies that half.
##
## A test that only did the first would have reported a working menu while the
## stick moved nothing, which is precisely the bug this file exists to catch.
func _press(action: String) -> void:
	Input.action_press(action)
	_send(action, true)
	await process_frame
	await process_frame
	Input.action_release(action)
	_send(action, false)
	for i in 4:
		await process_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


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


func _check_focus_can_be_driven() -> void:
	var focused := _focused_control()
	if focused == null:
		_fail("nothing holds focus when the menu opens; a stick would move nothing")
		return
	print("focus starts on: %s" % focused.name)

	# Move the cursor the way a d-pad does, through Godot's own ui_* actions.
	# If focus neighbours are not resolvable this simply does not move, which is
	# exactly the failure a screenshot cannot show.
	await _press("ui_right")
	var after_right := _focused_control()
	if after_right == focused:
		_fail("ui_right moved nothing; the grid cannot be driven with a stick")
	await _press("ui_down")
	if _focused_control() == after_right:
		_fail("ui_down moved nothing; the grid cannot be driven with a stick")
	print("focus moves on ui_right and ui_down")


func _check_tabs_can_be_cycled() -> void:
	var before := str(_menu.get("_index"))
	await _press("tool_cycle")
	if str(_menu.get("_index")) == before:
		_fail("`tool_cycle` did not change tab")
		return
	if _focused_control() == null:
		_fail("changing tab left nothing focused; the menu becomes undrivable")
	print("tab cycles on `tool_cycle`, focus follows")

	# Owner playtest report: "LB = tab left, RB = tab right". `tool_cycle` (Q /
	# LB) must step BACKWARD and `menu_tab_right` (Tab / RB) must step
	# FORWARD -- opposite directions, checked directly against `_index`
	# rather than just "changed", so a future regression that makes both
	# buttons cycle the same way fails loudly instead of passing on "it moved".
	var tab_count := int(_menu.get("_tabs").size())
	var mid := int(_menu.get("_index"))
	var both_ok := true
	await _press("tool_cycle")
	var after_lb := int(_menu.get("_index"))
	if after_lb != posmod(mid - 1, tab_count):
		_fail("`tool_cycle` (LB) should step to the PREVIOUS tab; went from %d to %d" % [mid, after_lb])
		both_ok = false
	await _press("menu_tab_right")
	var after_rb := int(_menu.get("_index"))
	if after_rb != posmod(after_lb + 1, tab_count):
		_fail("`menu_tab_right` (RB) should step to the NEXT tab; went from %d to %d" % [after_lb, after_rb])
		both_ok = false
	if both_ok:
		print("LB steps to the previous tab, RB steps to the next -- opposite directions, as reported")


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
func _check_backpack_target_picker() -> void:
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
	await _press("interact")

	if int(body.get("_targeting")) != slot:
		_fail("pressing Use on a heal item did not open the target picker")
		return
	if int(inventory.call("count", "potion_small")) != count_before:
		_fail("opening the target picker already spent the item, before any target was chosen")
	if float(target.get("hp")) != hp_before:
		_fail("opening the target picker already healed a creature, before any target was chosen")
	print("target picker opens on Use instead of applying immediately")

	await _press("menu_cancel")
	if int(body.get("_targeting")) != -1:
		_fail("`menu_cancel` did not back out of the target picker")
	if int(inventory.call("count", "potion_small")) != count_before:
		_fail("cancelling the target picker spent the item anyway")
	print("target picker cancels on `menu_cancel` without spending the item")

	(body.get("_buttons")[slot] as Button).grab_focus()
	await process_frame
	await _press("interact")
	if int(body.get("_targeting")) != slot:
		_fail("could not reopen the target picker for the confirm half of the check")
		return

	var target_rows: Array = body.get("_target_rows")
	(target_rows[1] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")

	if int(body.get("_targeting")) != -1:
		_fail("confirming a target did not close the picker")
	if int(inventory.call("count", "potion_small")) != count_before - 1:
		_fail("confirming a target did not spend the item")
	if float(target.get("hp")) <= hp_before:
		_fail("confirming slot 1 as the target did not heal the creature in slot 1")
	else:
		print("target picker heals the CHOSEN creature (slot 1) and spends the item on confirm")


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
