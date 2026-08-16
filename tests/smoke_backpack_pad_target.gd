extends SceneTree

## Can a CONTROLLER choose a target for a potion?
##
##   godot --headless --path . --script tests/smoke_backpack_pad_target.gd
##
## OW4, the owner's second report: *"When I use a potion I get to the screen to
## choose the creature then you can't choose."* OF22 shipped a fix and the
## report came back, so the half that was left had to be something every
## existing test was blind to.
##
## It was the input device. `tests/smoke_menu.gd` already drives this picker end
## to end and passes -- but it presses with `InputEventAction`, naming the
## action directly. Real hardware sends an `InputEventJoypadButton`, which has
## to travel through the InputMap first, and measured at runtime:
##
##   ui_accept     -> key, key, key      <- no pad binding at all
##   ui_left       -> key, JOY:13, axis:0
##   menu_confirm  -> key, JOY:0
##
## A `Button` activates on `ui_accept`. So on a pad, focus moved between the
## rows and nothing could ever press one: the picker opened, focus landed on
## the right creature, and A did nothing at all.
##
## So this test presses real joypad buttons and nothing else -- X (2) to Use,
## A (0) to choose -- and asserts the creature was actually healed and the
## potion actually spent. An `InputEventAction` anywhere in here would put the
## blind spot straight back.

const SETTLE := 6
## `interact` is USE and is joypad X; `menu_confirm` is joypad A. Both read from
## project.godot rather than hardcoded here, so a rebind moves this test with
## them instead of leaving it testing a button nobody presses.
const USE_ACTION := "interact"
const CONFIRM_ACTION := "menu_confirm"

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	for i in 10:
		await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return
	var menu: CanvasLayer = game.call("menu")
	menu.call("open")
	for i in SETTLE:
		await process_frame
	menu.call("select", 0)
	for i in SETTLE:
		await process_frame

	var body: Node = menu.get("_bodies")[0]
	var party: RefCounted = game.get("party")
	var inventory: RefCounted = game.get("inventory")

	if int(party.call("size")) < 2:
		for entry in [["terrapup", "Biscuit"], ["ripplet", "Pip"]]:
			var made: RefCounted = game.call("make_creature", str(entry[0]), str(entry[1]))
			if made != null:
				party.call("add", made)
	var target: RefCounted = party.call("at", 1)
	if target == null:
		_fail("could not stand up a second party member to heal")
		_report()
		return
	# Slot 1 hurt and slot 0 left at full: that makes exactly one row eligible,
	# so "focus landed on the right one" is a real assertion rather than luck.
	target.set("hp", 1.0)

	inventory.call("add", "potion_small", 3)
	var slot := int(inventory.call("find_slot", "potion_small"))
	if slot < 0:
		_fail("could not put a potion in the satchel")
		_report()
		return

	(body.get("_buttons")[slot] as Button).grab_focus()
	await process_frame

	var use_button := _pad_button_for(USE_ACTION)
	var confirm_button := _pad_button_for(CONFIRM_ACTION)
	if use_button < 0 or confirm_button < 0:
		_fail("%s or %s has no joypad binding at all — a controller cannot reach this screen" % [
			USE_ACTION, CONFIRM_ACTION,
		])
		_report()
		return

	await _pad(use_button)
	if int(body.get("_targeting")) < 0:
		_fail("a pad press of %s (joypad %d) did not open the target picker" % [USE_ACTION, use_button])
		_report()
		return
	print("  ok    pad opened the picker")

	var rows: Array = body.get("_target_rows")
	var focused := root.gui_get_focus_owner()
	var focused_row := rows.find(focused)
	if focused_row != 1:
		_fail("the picker focused row %d, not the one injured creature (row 1)" % focused_row)
	else:
		print("  ok    focus landed on the injured creature (row 1)")

	var hp_before := float(target.get("hp"))
	var potions_before := int(inventory.call("count", "potion_small"))

	await _pad(confirm_button)

	var hp_after := float(target.get("hp"))
	var potions_after := int(inventory.call("count", "potion_small"))
	if int(body.get("_targeting")) != -1:
		_fail("pad confirm (joypad %d) left the picker open — you still cannot choose" % confirm_button)
	if hp_after <= hp_before:
		_fail("pad confirm healed nobody (hp %.1f -> %.1f)" % [hp_before, hp_after])
	if potions_after != potions_before - 1:
		_fail("pad confirm spent %d potions, expected 1 (%d -> %d)" % [
			potions_before - potions_after, potions_before, potions_after,
		])
	if _failures.is_empty():
		print("  ok    pad confirm healed the chosen creature (hp %.1f -> %.1f) and spent one potion (%d -> %d)" % [
			hp_before, hp_after, potions_before, potions_after,
		])

	_report()


## The joypad button an action is actually bound to, or -1. Read from the live
## InputMap so this test describes the shipped bindings rather than a copy of
## them.
func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## A real controller button, the way hardware delivers it. Deliberately NOT an
## InputEventAction: routing through the InputMap is the entire point, and an
## action event would pass against the very bug this file exists to catch.
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


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("backpack target picker answers a controller: OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
