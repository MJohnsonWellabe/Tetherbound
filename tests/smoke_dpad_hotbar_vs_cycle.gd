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
##
## RETARGETED for CONTROLLER-MAP. `ralph/OWNER_DIRECTIVES_2026-08-22.md` section
## 1 bans hold-to-modify chords outright ("don't make a user hold a button down
## for any action") and REVERTS the hold-LB chord this file was written around.
## Under the owner's authored map the d-pad is hotbar 2-5 in EVERY context and
## one LB press is the whole party-cycle verb, so the three checks below were
## demanding the retired scheme: that a plain d-pad press cycle the party (it
## must not), that it leave the hotbar alone (the hotbar is now its entire job),
## and that a held-LB chord reach the bar (there is no chord any more). All
## three failed on `main` from the merge onward, and no CI shard runs this file,
## so nothing said so.
##
## The SUBJECT survives intact and is still worth having: one physical press
## must fire exactly one world verb. That is what is asserted now, in both
## directions -- the d-pad reaches the hotbar and never the party, LB reaches
## the party and never the hotbar.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SETTLE_FRAMES := 300

## project.godot: `hotbar_2` and `hotbar_4`'s physical buttons. The
## `combat_switch_left`/`combat_switch_right` actions that used to share them
## no longer exist -- CONTROLLER-MAP replaced the pair with one `party_cycle`.
const DPAD_LEFT_BUTTON := 13
const DPAD_RIGHT_BUTTON := 14
## `party_cycle`'s own physical button (project.godot). It was the hold
## modifier for the retired chord; it is the whole cycle verb now.
const LB_BUTTON := 9

## A tool slot equips on press ("press slot, tool in hand") with a state
## change that either happened or did not -- same reasoning
## `smoke_menu_owns_dpad.gd` already documents for using an equippable rather
## than a potion (which auto-targets and can silently no-op either way).
const TOOL_ID := "axe"
## A second tool, so the d-pad RIGHT check has something real to reach for.
## Without it that press correctly equips nothing (the slot is empty) and the
## assertion cannot tell "the d-pad does not reach slot 4" from "slot 4 holds
## nothing", which is the shape of test this file exists to not be.
const SECOND_TOOL_ID := "pickaxe"
const HOTBAR2_INDEX := 1 ## hotbar_2, zero-based into Game.hotbar / HOTBAR_ACTIONS
## hotbar_4 is d-pad RIGHT under the owner's map (project.godot, joypad 14).
## The old file called this slot 3 because d-pad right used to be `hotbar_3`.
const HOTBAR4_INDEX := 3

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

	await _check_plain_dpad_left_uses_hotbar_and_does_not_cycle()
	await _check_plain_dpad_right_uses_hotbar_and_does_not_cycle()
	await _check_lb_cycles_and_does_not_reach_the_hotbar()

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

	inventory.call("add", SECOND_TOOL_ID, 1)
	if int(inventory.call("count", SECOND_TOOL_ID)) < 1:
		_fail("could not put a %s in the satchel" % SECOND_TOOL_ID)
		return false
	if assignments.size() <= HOTBAR4_INDEX:
		_fail("the hotbar has no slot %d to assign" % HOTBAR4_INDEX)
		return false
	assignments[HOTBAR4_INDEX] = SECOND_TOOL_ID

	_game.set("hotbar", assignments)
	return true


## THE regression, in the owner's map. Nothing is open -- no build menu, no
## pause shell -- exactly the state the owner played in. A single plain
## d-pad-left press must equip the tool on `hotbar_2` and must NOT also cycle
## the party. Before DPAD-COLLISION both fired off the one press; the map that
## retired that defect did it by removing the directional switch actions
## entirely, not by gating them, so this is the same guarantee stated the new
## way round.
func _check_plain_dpad_left_uses_hotbar_and_does_not_cycle() -> void:
	_game.set("equipped_tool", "")
	var before := int(_party.call("active_index"))
	await _press_button(DPAD_LEFT_BUTTON)
	var after := int(_party.call("active_index"))
	var equipped := str(_game.get("equipped_tool"))

	if equipped.is_empty():
		_fail("plain d-pad left did not equip %s from hotbar_2 -- the d-pad is hotbar 2-5 in every context now, so slot 2 is unreachable on a pad" % TOOL_ID)
	if after != before:
		_fail("plain d-pad left ALSO cycled the active creature (%d -> %d) -- one press fired two world verbs" % [before, after])
	if after == before and not equipped.is_empty():
		print("  ok    plain d-pad left: equipped %s from hotbar_2 and did not cycle the party" % equipped)


func _check_plain_dpad_right_uses_hotbar_and_does_not_cycle() -> void:
	_game.set("equipped_tool", "")
	var before := int(_party.call("active_index"))
	await _press_button(DPAD_RIGHT_BUTTON)
	var after := int(_party.call("active_index"))
	var equipped := str(_game.get("equipped_tool"))

	if equipped != SECOND_TOOL_ID:
		_fail("plain d-pad right did not equip %s from hotbar_4 (equipped '%s') -- slot 4 is unreachable on a pad" % [SECOND_TOOL_ID, equipped])
	if after != before:
		_fail("plain d-pad right ALSO cycled the active creature (%d -> %d) -- one press fired two world verbs" % [before, after])
	if after == before and equipped == SECOND_TOOL_ID:
		print("  ok    plain d-pad right: equipped %s from hotbar_4 and did not cycle the party" % equipped)


## The other side of the same coin, and the half the owner's map moved. Party
## cycling must still be REACHABLE on a pad -- one LB press, no chord -- and
## that press must not spend a hotbar slot. This is where the old file demanded
## a held-LB chord; the directive removed the chord, so what is checked is the
## single press that replaced it.
func _check_lb_cycles_and_does_not_reach_the_hotbar() -> void:
	_game.set("equipped_tool", "")
	var before := int(_party.call("active_index"))
	await _press_button(LB_BUTTON)
	var after := int(_party.call("active_index"))
	var equipped := str(_game.get("equipped_tool"))

	if after == before:
		_fail("one LB press did not cycle the active creature (still %d) -- party cycling is unreachable on a pad" % before)
	if not equipped.is_empty():
		_fail("LB ALSO equipped %s -- one press fired two world verbs" % equipped)
	if after != before and equipped.is_empty():
		print("  ok    LB: cycled the party (%d -> %d) and did not touch the hotbar" % [before, after])


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
