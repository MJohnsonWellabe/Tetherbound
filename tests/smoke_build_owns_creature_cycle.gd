extends SceneTree

## OP21-03/OP21-06: does Build own the d-pad, or does the world still hear it?
##
##   godot --headless --path . --script tests/smoke_build_owns_creature_cycle.gd
##
## `encounter_director.gd::_read_creature_control_input()` read the party
## cycle action unconditionally whenever no fight/trainer-round/arbiter gate
## applied. It was then bound to gamepad d-pad left/right -- the same physical
## d-pad Godot's built-in `ui_left`/`ui_right` drive Control focus with.
## `build_menu.gd` deliberately does not pause the tree (OW10's Valheim-style
## live build), so the world stayed live behind it and one d-pad press both
## cycled the active creature AND, separately, should have moved the menu's own
## grid focus.
##
## CONTROLLER-MAP moved party cycling to LB, so the d-pad no longer reaches the
## encounter director at all. This test is kept and retargeted rather than
## deleted: what it actually proves is that a press with the build menu open
## reaches the MENU and not the world, and `hotbar_2` is still on d-pad left,
## so the ownership question is unchanged. Its companion
## `smoke_menu_owns_dpad.gd` proves the hotbar half from the other side.
##
## That retarget was only HALF applied when CONTROLLER-MAP landed. The control
## case below still pressed d-pad left and demanded that it cycle the active
## creature -- the exact binding
## `ralph/OWNER_DIRECTIVES_2026-08-22.md` section 1 removed, and whose removal
## is the whole point of the remap ("the d-pad is hotbar 2-5 in every context
## including combat"). So this file failed on `main` from the moment the merge
## landed, asserting the banned map. No CI shard runs it, so nothing said so.
##
## The control case now presses LB, which is where cycling actually lives, and
## the build-menu half checks BOTH buttons: LB must not cycle while the
## catalogue is up (the owner's map gives LB/RB to catalogue category in build
## mode), and the d-pad must move grid focus rather than the world.
##
## A single physical press is sent, not two synthetic actions independently,
## because the whole defect is that ONE press used to fire both. Sending it
## once and checking both outcomes is the only way to prove the fix actually
## routes ownership rather than coincidentally leaving both paths alone.
##
## Real `InputEventJoypadButton` through `Input.parse_input_event`, not
## `Input.action_press` -- `ralph/conventions.md`: a poll-only press cannot
## move Control focus, so a poll-only test would report a working build menu
## while the grid never moved. `smoke_gate_a_map_cycle.gd` establishes this
## same real-pad-through-full-world pattern for the sibling Gate A checks.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
const SETTLE_FRAMES := 300

## project.godot: hotbar_2 is joypad button 13, the same physical d-pad-left
## Godot's built-in ui_left also fires on. One press must reach both actions
## for this test to mean anything -- see the header.
const DPAD_LEFT_BUTTON := 13

## project.godot: `party_cycle` is joypad button 9 (LB). One press cycles, in
## the field and mid-fight alike -- CONTROLLER-MAP retired D32's directional
## pair, which is what freed the d-pad for the hotbar.
const PARTY_CYCLE_BUTTON := 9

var _failures: Array[String] = []
var _world: Node = null
var _game: Node = null
var _party: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_party = _game.get("party") as RefCounted if _game != null else null
	if _game == null or _party == null:
		_fail("real Meadows boot is missing Game/party")
		_report()
		return

	if not _seed_party():
		_report()
		return

	await _check_party_cycle_works_with_no_menu_open()
	await _check_build_menu_owns_the_same_press()
	_report()


## At least two owned creatures so a leaked cycle has somewhere to go --
## a party of one would make "active index unchanged" true for the wrong
## reason (nothing else to cycle to).
func _seed_party() -> bool:
	_party.call("clear")
	for id in ["terrapup", "ripplet"]:
		var creature: RefCounted = SPECIES.spawn(id)
		if creature == null or not bool(_party.call("add", creature)):
			_fail("could not seed two owned creatures needed for the cycle check")
			return false
	if int(_party.call("size")) != 2:
		_fail("party seeding left the wrong size (%d)" % int(_party.call("size")))
		return false
	return true


## The leak this is about is a real, working cycle firing at the wrong time.
## A dead binding would make the build-menu check below pass for entirely the
## wrong reason, so prove the press actually cycles first, with no menu up --
## on LB, which is where CONTROLLER-MAP put cycling.
func _check_party_cycle_works_with_no_menu_open() -> void:
	var before := int(_party.call("active_index"))
	await _press_button(PARTY_CYCLE_BUTTON)
	var after := int(_party.call("active_index"))
	if after == before:
		_fail("with no menu up, LB did not cycle the active creature (still %d) -- the build-menu check below would prove nothing" % before)
		return
	print("  ok    no menu: LB cycled the active creature (%d -> %d)" % [before, after])


func _check_build_menu_owns_the_same_press() -> void:
	var menu: CanvasLayer = BUILD_MENU.get_or_make(self)
	menu.call("open")
	for i in SETTLE_FRAMES:
		await process_frame
	if not bool(menu.call("is_open")):
		_fail("the build menu would not open -- nothing was tested")
		return

	# data/items/buildables.json's "survival" category (index 0, whatever
	# opens by default) holds exactly one piece -- too few to move focus
	# sideways within. "structures" (index 2 of CATEGORY_ORDER) holds five;
	# selected directly rather than through input since which category is
	# open is setup, not the thing being proven.
	menu.call("_select_category", 2)
	for i in SETTLE_FRAMES:
		await process_frame

	var active_before := int(_party.call("active_index"))
	var cells: Array = menu.get("_cell_buttons")
	if cells.size() < 2:
		_fail("build menu open: fewer than 2 pieces in the grid -- cannot test moving off the left edge")
		menu.call("close")
		return

	# Seated on cell 1, not cell 0, directly (not through input -- this is
	# setup, not the thing being proven). Cell 0 sits at the grid's left
	# edge and may have no focus_neighbor_left at all, which would make
	# "focus did not move" true for the wrong reason -- the same edge case
	# `smoke_satchel_owns_hotbar.gd` seats past for the Satchel grid.
	(cells[1] as Button).grab_focus()
	for i in SETTLE_FRAMES:
		await process_frame
	var focus_before := root.gui_get_focus_owner()
	if focus_before != cells[1]:
		_fail("build menu open: could not seat focus on cell 1 to set up the check")
		menu.call("close")
		return
	var cell_index_before: int = 1

	await _press_dpad_left()

	var active_after := int(_party.call("active_index"))
	if active_after != active_before:
		_fail("build menu open: d-pad left still cycled the active creature (%d -> %d) -- Build does not own the d-pad" % [
			active_before, active_after,
		])
	else:
		print("  ok    build menu open: d-pad left did not cycle the active creature")

	var focus_after := root.gui_get_focus_owner()
	if focus_after == null:
		_fail("build menu open: focus was lost entirely after a d-pad press")
	elif not cells.has(focus_after):
		_fail("build menu open: focus left the grid, landing on %s" % focus_after)
	elif cells.find(focus_after) == cell_index_before:
		_fail("build menu open: d-pad left reached the menu but did not move its grid focus")
	else:
		print("  ok    build menu open: d-pad left moved grid focus (%d -> %d)" % [cell_index_before, cells.find(focus_after)])

	# The other half of the same ownership question. The owner's map gives
	# LB/RB to catalogue CATEGORY while building, so the one button that does
	# cycle creatures in the field must not cycle them here either.
	var cycle_before := int(_party.call("active_index"))
	await _press_button(PARTY_CYCLE_BUTTON)
	var cycle_after := int(_party.call("active_index"))
	if cycle_after != cycle_before:
		_fail("build menu open: LB still cycled the active creature (%d -> %d) -- Build does not own the shoulder buttons" % [
			cycle_before, cycle_after,
		])
	else:
		print("  ok    build menu open: LB did not cycle the active creature")

	menu.call("close")
	for i in SETTLE_FRAMES:
		await process_frame


## One physical button, sent once. Real `InputEventJoypadButton` through the
## live InputMap, per `ralph/conventions.md` -- this is what lets the same
## press resolve to `hotbar_2` (project.godot override) AND the built-in
## `ui_left` Control focus reads, exactly as it does on the ROG Ally.
func _press_dpad_left() -> void:
	await _press_button(DPAD_LEFT_BUTTON)


func _press_button(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	for i in 4:
		await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 8:
		await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("build menu owns the shared d-pad: OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
