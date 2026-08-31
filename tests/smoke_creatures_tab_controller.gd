extends SceneTree

## BACKLOG-I7-CREATURES-TAB-TEST. Is the Creatures tab reachable and usable by
## a controller ALONE — opened, navigated, acted on, and closed — with no
## keyboard or mouse event anywhere in the chain?
##
##   godot --headless --path . --script tests/smoke_creatures_tab_controller.gd
##
## Audit I7 (`ralph/reports/audit/I-2026-08-31.md`) named this the one
## residual gap in an otherwise-passing controller-first audit: existing tests
## prove the Creatures tab is REACHABLE (`smoke_rename_pad_trigger.gd`,
## `smoke_evolution.gd`) or prove the pause-shell isolation MECHANISM
## generally, on six other panels (`smoke_menu_focus.gd`,
## `smoke_craft_panel_controller.gd`, `smoke_name_prompt_controller.gd`,
## `smoke_controller_catching.gd`, the two above) — but nothing drives this
## specific panel end to end, open to close, on synthetic controller input
## alone. This is that test, shaped like `smoke_menu_owns_dpad.gd` per the
## audit's own closing-cost note but scoped to `tab_creatures.gd`.
##
## Real `InputEventJoypadButton` events only, button indices read live off the
## `InputMap` (the `_pad_button_for`/`_pad` pattern `smoke_rename_pad_trigger.gd`
## already established) — `InputEventAction` never travels the InputMap
## (OW4/UI-PAD1), so a test driving this with `Input.action_press` would keep
## passing on a project.godot with the binding deleted. Godot's built-in
## `ui_down`/`ui_up` grid-navigation actions are read the same way, off the
## live map, rather than assumed.
##
## The chain proven here, all four steps by real joypad press:
##   1. OPEN   — `game_menu` (Start) opens the pause shell.
##   2. REACH  — `menu_tab_right` (RB) steps from the default Satchel tab onto
##      Creatures; `current_tab_id()` and real Control focus both confirm it.
##   3. USE    — `ui_down` moves row focus (navigating the tab's contents),
##      then `interact` (X), `tab_creatures.gd`'s borrowed ACTIVATE_ACTION,
##      sets the newly-focused row's creature active in `party.gd` — a real
##      gameplay effect, not just a focus ring moving.
##   4. CLOSE  — `menu_cancel` (B) closes the shell.
##
## Isolation, the half the audit named as missing: while the shell is open,
## `get_tree().paused` is true (`game_menu.gd:349`) — the actual mechanism
## that keeps the world from also reading these same action strings — and the
## Satchel tab, `tab_creatures.gd`'s neighbour and the other reader of the
## same three borrowed backpack_* actions, is not the visible body, so its own
## `poll()` never runs to react to any of them. Both are asserted directly
## rather than trusted from the mechanism's description.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

const OPEN_ACTION := "game_menu"        # Start (project.godot)
const NEXT_TAB_ACTION := "menu_tab_right"  # RB
const CLOSE_ACTION := "menu_cancel"     # B
const DOWN_ACTION := "ui_down"          # d-pad down, Godot built-in
const ACTIVATE_ACTION := "interact"     # X — tab_creatures.gd's ACTIVATE_ACTION

var _failures: Array[String] = []
var _game: Node = null
var _menu: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	# Real boot reaches this scene through the engine's own main-scene load,
	# which sets `current_scene` as a side effect — smoke_menu.gd's own note
	# on why a harness that adds the scene by hand has to do this too.
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
		print("FAIL: the autoload did not stand up the pause menu")
		quit(1)
		return

	if not _stock_two_creatures():
		_report()
		return

	await _check_open_reach_use_close()

	_report()


## Two distinct, healthy creatures in slots 0 and 1, cleared and rebuilt
## rather than trusted from boot state — a starter save carrying only one
## creature (or none) would make the USE step below untestable, and a stale
## `active_index` from a previous run would let it pass by accident.
func _stock_two_creatures() -> bool:
	var party: RefCounted = _game.get("party")
	if party == null:
		_fail("Game has no party — nothing to activate")
		return false
	party.call("clear")
	var first: RefCounted = _game.call("make_creature", "terrapup", "First")
	var second: RefCounted = _game.call("make_creature", "ripplet", "Second")
	if first == null or second == null or not bool(party.call("add", first)) or not bool(party.call("add", second)):
		_fail("could not stand up two party members to navigate between")
		return false
	if not bool(party.call("set_active", 0)):
		_fail("could not set slot 0 active as the test's starting state")
		return false
	return true


func _check_open_reach_use_close() -> void:
	# --- 1. OPEN, by real controller press -----------------------------------
	var open_button := _pad_button_for(OPEN_ACTION)
	if open_button < 0:
		_fail("%s has no joypad binding — a controller cannot open the menu at all" % OPEN_ACTION)
		return
	await _pad(open_button)
	if not bool(_menu.call("is_open")):
		_fail("a real joypad press of %s (button %d) did not open the pause shell" % [OPEN_ACTION, open_button])
		return
	print("  ok    pad press of %s opened the pause shell" % OPEN_ACTION)

	if not paused:
		_fail("the shell reports open but the tree is not paused — the isolation mechanism I7 cites (game_menu.gd:349) is not engaged")

	# --- 2. REACH the Creatures tab, by real controller press ----------------
	var next_tab_button := _pad_button_for(NEXT_TAB_ACTION)
	if next_tab_button < 0:
		_fail("%s has no joypad binding — a controller cannot switch tabs" % NEXT_TAB_ACTION)
		_close_and_report_only()
		return
	await _pad(next_tab_button)
	if str(_menu.call("current_tab_id")) != "creatures":
		_fail("pad press of %s did not land on the Creatures tab (landed on '%s')" % [
			NEXT_TAB_ACTION, str(_menu.call("current_tab_id")),
		])
		_close_and_report_only()
		return
	print("  ok    pad press of %s reached the Creatures tab" % NEXT_TAB_ACTION)

	var body: Node = _menu.get("_bodies")[_menu.get("_index")]
	var rows: Array = body.get("_rows")
	if rows.size() < 2:
		_fail("the Creatures tab did not draw at least two rows — cannot prove row navigation")
		_close_and_report_only()
		return
	if root.get_viewport().gui_get_focus_owner() != rows[0]:
		_fail("row 0 does not hold real UI focus on arrival — the tab is not actually controller-reachable, whatever current_tab_id() says")
		_close_and_report_only()
		return
	print("  ok    row 0 holds real UI focus on arrival, unaided by mouse or keyboard")

	var backpack_body: Node = _menu.get("_bodies")[0]
	if backpack_body.visible:
		_fail("the Satchel tab, the other reader of the borrowed backpack_* actions, is still visible while Creatures is showing — its poll() could still react to the same presses")

	# --- 3. USE: navigate rows, then fire the borrowed ACTIVATE_ACTION -------
	var down_button := _pad_button_for(DOWN_ACTION)
	if down_button < 0:
		_fail("%s has no joypad binding — a controller cannot move focus inside the tab" % DOWN_ACTION)
		_close_and_report_only()
		return
	await _pad(down_button)
	if root.get_viewport().gui_get_focus_owner() != rows[1]:
		_fail("pad press of %s did not move focus from row 0 to row 1" % DOWN_ACTION)
		_close_and_report_only()
		return
	print("  ok    pad press of %s moved row focus (row 0 -> row 1)" % DOWN_ACTION)

	var party: RefCounted = _game.get("party")
	if int(party.call("active_index")) != 0:
		_fail("test setup drifted: active_index is %d, expected 0 before the activate press" % int(party.call("active_index")))
		_close_and_report_only()
		return

	var activate_button := _pad_button_for(ACTIVATE_ACTION)
	if activate_button < 0:
		_fail("%s has no joypad binding — a controller cannot reach tab_creatures.gd's ACTIVATE_ACTION" % ACTIVATE_ACTION)
		_close_and_report_only()
		return
	await _pad(activate_button)
	if int(party.call("active_index")) != 1:
		_fail("a real joypad press of %s (button %d) on the focused row did not set slot 1 active (active_index is %d)" % [
			ACTIVATE_ACTION, activate_button, int(party.call("active_index")),
		])
		_close_and_report_only()
		return
	print("  ok    pad press of %s on the focused row set slot 1 active — a real gameplay effect, not just a focus ring" % ACTIVATE_ACTION)

	# --- 4. CLOSE, by real controller press -----------------------------------
	await _close_by_pad()


func _close_and_report_only() -> void:
	await _close_by_pad()


func _close_by_pad() -> void:
	var close_button := _pad_button_for(CLOSE_ACTION)
	if close_button < 0:
		_fail("%s has no joypad binding — a controller cannot close the menu it opened" % CLOSE_ACTION)
		return
	await _pad(close_button)
	if bool(_menu.call("is_open")):
		_fail("a real joypad press of %s (button %d) did not close the pause shell" % [CLOSE_ACTION, close_button])
		return
	print("  ok    pad press of %s closed the pause shell" % CLOSE_ACTION)


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


## A real controller button, the way hardware delivers it — deliberately NOT an
## `InputEventAction`, since routing through the InputMap is the entire point.
## Ticks BOTH `physics_frame` and `process_frame`: `game_menu.gd` polls
## actions from its own idle `_process`, `tab_creatures.gd`'s row focus moves
## through Godot's Control/ui_* machinery, and this file drives both with one
## helper — the same reasoning `smoke_rename_pad_trigger.gd::_pad` already
## sets out for this exact pairing.
func _pad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await _tick()
	await _tick()
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await _tick()


func _tick() -> void:
	await physics_frame
	await process_frame


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("Creatures tab controller isolation: OK")
		quit(0)
		return
	print("%d failure(s)" % _failures.size())
	quit(1)
