extends SceneTree

## What does a SECOND Start press do while the pause shell is open?
##
##   godot --headless --path . --script tools/opening_fix/probe_second_start.gd
##
## The Gate F run's §4 leaves the S02 drop-confirmation unexplained: the shell
## was twice observed opening with a "Drop it?" confirmation focused, which calls
## `menu.hold_input(true)` and so swallows tab navigation and left the segment
## unable to reach the Save tab.
##
## Everything tried so far presses Start ONCE. `tests/smoke_pause_tap_no_drop.gd`
## stocks the satchel, taps Start once, and passes -- `tab_backpack.gd`'s
## `_ignore_drop_until_release` correctly suppresses the drop on the opening
## press. `tools/opening_fix/probe_drop_confirm.gd` loads the run's own S02 exit
## save and taps Start once, and reports `confirming = -1`.
##
## Nobody has pressed it TWICE, and the guard by its own definition cannot cover
## that: it clears as soon as the opening press is released (`poll()`:
## `if _ignore_drop_until_release and not Input.is_action_pressed(DROP_ACTION)`).
## From that moment the backpack tab is visible, the shell is open, and
## `backpack_drop` and `game_menu` are the same physical button -- and
## `game_menu.gd` deliberately does not let Menu CLOSE the shell. So the second
## press has nothing left to do except be read as Drop.
##
## That is the shape of a defect a PLAYER reaches without a harness: open the
## menu, press the same button again expecting it to close, get a destructive
## prompt on a slot you never selected.
##
## This probe does not assert. It stocks the satchel the way the opening does,
## presses Start, reports, presses Start again, and reports. If the second press
## raises the confirmation, the reproduction the run has been missing is here and
## a real test can be written against it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240


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
		print("no Game autoload")
		quit(1)
		return
	var menu: Node = game.call("menu")
	if menu == null:
		print("no menu")
		quit(1)
		return

	var inventory: Variant = game.get("inventory")
	if inventory == null or not (inventory as Object).has_method("add"):
		print("no inventory to stock; the probe would prove nothing")
		quit(1)
		return
	var leftover := int((inventory as Object).call("add", "orb_basic", 15))
	print("satchel stocked: 15 orb_basic, %d left over" % leftover)

	var tab := _backpack_tab(menu)
	if tab == null:
		print("no backpack tab")
		quit(1)
		return

	_report(menu, tab, "before any press")
	await _tap("game_menu")
	for i in 30:
		await physics_frame
	_report(menu, tab, "after Start #1")

	await _tap("game_menu")
	for i in 30:
		await physics_frame
	_report(menu, tab, "after Start #2")

	# The consequence the run actually paid: with a confirmation up, hold_input
	# is on and tab navigation is swallowed, so the game cannot be saved.
	for i in 5:
		await _tap("menu_tab_right")
	print("after 5x menu_tab_right: tab=%s  (the run needed 'save')" % str(menu.call("current_tab_id")))
	quit(0)


func _report(menu: Node, tab: Node, when: String) -> void:
	var focus := root.get_viewport().gui_get_focus_owner()
	print("%-20s open=%-5s tab=%-10s confirming=%-3s guard=%-5s focus=%s" % [
		when, str(menu.call("is_open")), str(menu.call("current_tab_id")),
		str(tab.get("_confirming")), str(tab.get("_ignore_drop_until_release")),
		str(focus.text) if focus != null and "text" in focus else "-"])


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


func _tap(action: String) -> void:
	var pad: InputEvent = null
	for event in InputMap.action_get_events(StringName(action)):
		if event is InputEventJoypadButton:
			pad = event
			break
	if pad == null:
		print("'%s' has no joypad binding" % action)
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
