extends SceneTree

## DPAD-COLLISION. `hotbar_2`/`hotbar_3` and `combat_switch_left`/
## `combat_switch_right` both used to bind gamepad d-pad left/right
## (project.godot: joypad buttons 13/14). Unlike every other shared button in
## the input map, BOTH readers were live at once during plain exploration --
## no fight, no build ghost, no panel open, nothing gating either one apart
## from the other. One d-pad press fired a hotbar slot AND cycled the active
## creature; `smoke_menu_owns_dpad.gd` and `smoke_build_owns_creature_cycle.gd`
## each prove one half of the ownership story (a panel owning input) but
## neither one exercises this pair against EACH OTHER with nothing else open,
## which is exactly the state the owner reported and the one no existing test
## covered -- `test_no_two_same_context_actions_share_a_joypad_button`
## (`tests/test_world_verb_input_owner_enforcement.gd`) proves the same fact
## statically; this is its real-input behavioural twin.
##
##   godot --headless --path . --script tests/smoke_dpad_hotbar_vs_cycle.gd
##
## Real `InputEventJoypadButton` through `Input.parse_input_event`, not
## `Input.action_press` -- `ralph/conventions.md`. A single physical press is
## sent for each check, because the defect was one press doing two things; the
## only way to prove the fix actually resolves ownership rather than
## coincidentally leaving both paths alone is to send it once and read both
## outcomes.
##
## `smoke_gate_a_map_cycle.gd` establishes the same real-pad-through-full-world
## pattern this borrows.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SETTLE_FRAMES := 300

## project.godot: `combat_switch_left`/`combat_switch_right`'s physical
## buttons -- the same ones `hotbar_2`/`hotbar_3` used to also bind.
const DPAD_LEFT_BUTTON := 13
const DPAD_RIGHT_BUTTON := 14
## `hotbar_5`'s own physical button (project.godot), reused as the hold
## modifier for `hotbar_2`/`hotbar_3` post-fix -- see
## `scripts/ui/playground_hud.gd::HOTBAR5_CHORD_WINDOW`'s header.
const LB_BUTTON := 9

## A tool slot equips on press ("press slot, tool in hand") with a state
## change that either happened or did not -- same reasoning
## `smoke_menu_owns_dpad.gd` already documents for using an equippable rather
## than a potion (which auto-targets and can silently no-op either way).
const TOOL_ID := "axe"
const HOTBAR2_INDEX := 1 ## hotbar_2, zero-based into Game.hotbar / HOTBAR_ACTIONS

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
	if not _stock_the_satchel():
		_report()
		return

	await _check_plain_dpad_left_cycles_and_does_not_use_hotbar()
	await _check_plain_dpad_right_cycles_and_does_not_use_hotbar()
	await _check_lb_chord_reaches_hotbar_and_does_not_cycle()

	_report()


## Two owned creatures so a leaked/legitimate cycle has somewhere to go.
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


func _stock_the_satchel() -> bool:
	var inventory: RefCounted = _game.get("inventory")
	if inventory == null:
		_fail("Game has no inventory -- nothing to reach for")
		return false
	inventory.call("add", TOOL_ID, 1)
	if int(inventory.call("count", TOOL_ID)) < 1:
		_fail("could not put a %s in the satchel" % TOOL_ID)
		return false
	var assignments: Array = _game.get("hotbar") as Array
	if assignments.size() <= HOTBAR2_INDEX:
		_fail("the hotbar has no slot %d to assign" % HOTBAR2_INDEX)
		return false
	assignments[HOTBAR2_INDEX] = TOOL_ID
	_game.set("hotbar", assignments)
	return true


## THE regression. Nothing is open -- no build menu, no pause shell, no LB
## held -- exactly the state the owner played in. A single plain d-pad-left
## press must cycle the party and must NOT also equip the tool sitting on
## hotbar_2. Before the fix this failed: both fired off the one press.
func _check_plain_dpad_left_cycles_and_does_not_use_hotbar() -> void:
	_game.set("equipped_tool", "")
	var before := int(_party.call("active_index"))
	await _press_button(DPAD_LEFT_BUTTON)
	var after := int(_party.call("active_index"))
	var equipped := str(_game.get("equipped_tool"))

	if after == before:
		_fail("plain d-pad left did not cycle the active creature (still %d) -- party cycling is not live, so this check proves nothing" % before)
	if not equipped.is_empty():
		_fail("plain d-pad left ALSO equipped %s from hotbar_2 -- one press fired two world verbs (the exact DPAD-COLLISION defect)" % equipped)
	if after != before and equipped.is_empty():
		print("  ok    plain d-pad left: cycled the party (%d -> %d) and did not touch the hotbar" % [before, after])


func _check_plain_dpad_right_cycles_and_does_not_use_hotbar() -> void:
	_game.set("equipped_tool", "")
	var before := int(_party.call("active_index"))
	await _press_button(DPAD_RIGHT_BUTTON)
	var after := int(_party.call("active_index"))
	var equipped := str(_game.get("equipped_tool"))

	if after == before:
		_fail("plain d-pad right did not cycle the active creature (still %d)" % before)
	if not equipped.is_empty():
		_fail("plain d-pad right ALSO equipped %s from hotbar_3 -- one press fired two world verbs" % equipped)
	if after != before and equipped.is_empty():
		print("  ok    plain d-pad right: cycled the party (%d -> %d) and did not touch the hotbar" % [before, after])


## The other side of the same coin: `hotbar_2` must still be REACHABLE on
## gamepad, not merely silenced. Holding LB (hotbar_5's own button) and then
## pressing d-pad-left must equip the tool and must NOT cycle the party on
## that same press.
func _check_lb_chord_reaches_hotbar_and_does_not_cycle() -> void:
	_game.set("equipped_tool", "")
	var before := int(_party.call("active_index"))

	var lb_down := InputEventJoypadButton.new()
	lb_down.button_index = LB_BUTTON
	lb_down.pressed = true
	Input.parse_input_event(lb_down)
	for i in 2:
		await physics_frame

	var left_down := InputEventJoypadButton.new()
	left_down.button_index = DPAD_LEFT_BUTTON
	left_down.pressed = true
	Input.parse_input_event(left_down)
	for i in 4:
		await physics_frame
	var left_up := InputEventJoypadButton.new()
	left_up.button_index = DPAD_LEFT_BUTTON
	left_up.pressed = false
	Input.parse_input_event(left_up)
	for i in 4:
		await physics_frame

	var lb_up := InputEventJoypadButton.new()
	lb_up.button_index = LB_BUTTON
	lb_up.pressed = false
	Input.parse_input_event(lb_up)
	for i in 8:
		await physics_frame

	var after := int(_party.call("active_index"))
	var equipped := str(_game.get("equipped_tool"))

	if equipped != TOOL_ID:
		_fail("holding LB and pressing d-pad-left did not equip %s from hotbar_2 (equipped_tool %s) -- the gamepad chord does not reach the hotbar, slots 2/3 are unreachable on a pad" % [
			TOOL_ID, "empty" if equipped.is_empty() else equipped,
		])
	if after != before:
		_fail("holding LB and pressing d-pad-left ALSO cycled the active creature (%d -> %d) -- the chord press still fires two world verbs" % [before, after])
	if equipped == TOOL_ID and after == before:
		print("  ok    LB held + d-pad left: equipped %s from hotbar_2 and did not cycle the party" % TOOL_ID)


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
		print("d-pad hotbar/cycle collision: OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
