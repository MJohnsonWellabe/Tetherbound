extends SceneTree
## INVARIANT test, NOT a regression test. Read the note below before trusting it.
##
## Asserts two properties a controller player depends on:
##   1. Tapping Start to open the pause shell does not raise the backpack's
##      "Drop it?" confirmation on a stocked satchel.
##   2. The Save tab is reachable from the backpack tab in five
##      `menu_tab_right` presses -- i.e. the game can be saved.
##
## Both matter because `game_menu` and `backpack_drop` are the SAME physical
## button (gamepad Start, button 6 in project.godot), and because the drop
## confirmation calls `menu.hold_input(true)`, which swallows tab navigation.
## `tab_backpack.gd` guards the collision with `_ignore_drop_until_release`.
##
## ## Honesty note, so nobody mistakes what this test proved
##
## During the Gate F run on a3f61b60 the pause shell WAS observed opening with
## the drop confirmation focused, twice (S02 attempts 5 and 6), which made the
## Save tab unreachable and left the segment unable to write its handoff save.
## This test was written to reproduce that and **it does not**. It passes on
## unmodified code, and it also passed against a candidate fix, so it
## discriminates nothing about that failure.
##
## A probe that loads the run's OWN S02 exit save
## (`tools/opening_fix/probe_drop_confirm.gd` on ralph/OPENING-STARTER-FOCUS)
## also fails to reproduce it: from that exact state a Start tap gives
## `_confirming = -1` and five tab presses land on `save`. So the trigger is
## something in the run's input sequence rather than the Start binding itself,
## and it is still unexplained.
##
## What this test is therefore worth: it pins the two properties so they cannot
## silently regress. It is not evidence that the observed failure is fixed,
## because nothing has fixed it.
##
## The tap is deliberate. A held press exercises a different guard path.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return
	var menu: Node = game.call("menu")
	if menu == null:
		print("FAIL: the autoload did not stand up the menu")
		quit(1)
		return

	# The guard only has anything to guard when the satchel holds something --
	# `_read_drop` says "Nothing there to drop." on an empty slot and never
	# raises the confirmation. Stock it the way the opening does.
	if not _stock_the_satchel(game):
		print("FAIL: could not put anything in the satchel; the test would pass vacuously")
		quit(1)
		return

	await _check_tapping_start_does_not_raise_the_drop_confirmation(menu)
	await _check_the_save_tab_is_reachable_after_that_tap(menu)

	print("")
	if _failures.is_empty():
		print("pause-tap drop-guard smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


func _stock_the_satchel(game: Node) -> bool:
	# A property on the autoload, not a method -- the same handle
	# `sequence_director.gd` uses to pay out Grandpa's `give:orb_basic:15`.
	var inventory: Variant = game.get("inventory")
	if inventory == null or not (inventory as Object).has_method("add"):
		return false
	var leftover := int((inventory as Object).call("add", "orb_basic", 15))
	return leftover < 15


## The tab must be visible for `poll()` to run its reads, which means the shell
## has to be on the backpack tab -- which is where it opens by default.
func _check_tapping_start_does_not_raise_the_drop_confirmation(menu: Node) -> void:
	await _tap("game_menu")
	for i in 30:
		await physics_frame

	if not bool(menu.call("is_open")):
		_fail("tapping Start did not open the pause shell at all")
		return

	var tab := _backpack_tab(menu)
	if tab == null:
		_fail("could not find the backpack tab to inspect")
		return
	# `_confirming` is the focused slot index while a confirmation is up, and -1
	# otherwise. Read directly rather than inferred from the shell's deaf flag:
	# tools/_probe_pause.gd showed the deaf flag is the less specific signal.
	var confirming := int(tab.get("_confirming"))
	if confirming >= 0:
		_fail("tapping Start raised the drop confirmation on slot %d -- one A press from deleting an item the player never selected" % confirming)


## The consequence check. Even if the confirmation is somehow benign, the shell
## must still be able to reach the Save tab, because a game that cannot be saved
## cannot be played.
func _check_the_save_tab_is_reachable_after_that_tap(menu: Node) -> void:
	if not bool(menu.call("is_open")):
		return
	for i in 5:
		await _tap("menu_tab_right")
	var tab_id := str(menu.call("current_tab_id"))
	if tab_id != "save":
		_fail("five menu_tab_right presses from the backpack tab landed on '%s', not 'save' -- the game cannot be saved" % tab_id)


func _backpack_tab(menu: Node) -> Node:
	for node in _walk(menu):
		if node.get_script() != null \
				and str(node.get_script().resource_path).ends_with("tab_backpack.gd"):
			return node
	return null


func _walk(from: Node) -> Array[Node]:
	var out: Array[Node] = [from]
	for child in from.get_children():
		out.append_array(_walk(child))
	return out


## A TAP: down edge, one frame, up edge. Deliberately not a hold -- the bug this
## guards only appears when the button comes back up quickly.
func _tap(action: String) -> void:
	var pad: InputEvent = null
	for event in InputMap.action_get_events(StringName(action)):
		if event is InputEventJoypadButton:
			pad = event
			break
	if pad == null:
		_fail("'%s' has no physical joypad button binding" % action)
		return
	var down := InputEventJoypadButton.new()
	down.button_index = (pad as InputEventJoypadButton).button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = down.button_index
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	for i in 20:
		await physics_frame
