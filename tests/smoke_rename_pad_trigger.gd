extends SceneTree

## PT-17-test. Does a REAL controller trigger the rename flow: H/R3 opens a
## prompt prefilled with the creature's CURRENT name, and confirming reaches
## `party_seam.gd::set_nickname`?
##
##   godot --headless --path . --script tests/smoke_rename_pad_trigger.gd
##
## PT-17 shipped the verb (`tab_creatures.gd::_read_rename` /
## `_on_rename_confirmed`). `tests/test_creature_nickname.gd` already covers
## the nickname MECHANISM generically (`creature.nickname = "x"`), and
## nothing else in `tests/` names the rename trigger itself — the H-key/R3
## press, through the pause menu's Creatures tab, into `name_prompt.gd`, back
## out through `party_seam.set_nickname`. This is that chain.
##
## Real `InputEventJoypadButton` events only, button indices read live off
## the `InputMap` (the `_pad_button_for`/`_pad` pattern `smoke_backpack_pad_
## target.gd` and `smoke_name_prompt_keyboard.gd` already establish) —
## `InputEventAction` never travels the InputMap (OW4/UI-PAD1), so a test
## driving this with `Input.action_press`/`InputEventAction` would keep
## passing on a project.godot with the binding deleted, which is exactly the
## blind spot this project keeps re-discovering. Two different consumers read
## the input here — `tab_creatures.gd::poll()` from `game_menu.gd`'s idle
## `_process`, `name_prompt.gd`'s grid from its own `_physics_process` — so
## `_pad()` below settles on BOTH `physics_frame` and `process_frame` rather
## than picking the one pattern that happens to fit a single caller.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

const RENAME_ACTION := "backpack_split"  # H / gamepad R3 (tab_creatures.gd)
const DOWN_ACTION := "ui_down"
const RIGHT_ACTION := "ui_right"
const CONFIRM_ACTION := "menu_confirm"

var _failures: Array[String] = []
var _game: Node = null
var _menu: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	# Real boot reaches this scene through the engine's own main-scene load,
	# which sets `current_scene` as a side effect -- smoke_menu.gd's own note
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

	# `game_state.gd::_input` (the tree-wide "was that a pad?" watch behind
	# `input_glyph.gd::using_gamepad()`) is on `Game`'s default PROCESS_MODE_
	# INHERIT, so it goes quiet the instant the pause menu pauses the tree --
	# a real controller player never notices because their own locomotion
	# input already set the flag long before they ever opened a menu. This
	# harness has sent no input yet, so without priming it here, `open()`
	# reads gamepad=false and the prompt draws its keyboard `LineEdit`
	# instead of the pad grid -- silently proving nothing about the
	# controller path this whole file exists to check. One real press, while
	# the world is still unpaused, is what a controller player's own idle
	# movement already did for them.
	var prime_button := _pad_button_for(DOWN_ACTION)
	if prime_button >= 0:
		await _pad(prime_button)
	if not bool(_game.call("last_input_was_gamepad")):
		_fail("could not prime gamepad detection before opening the menu -- the pad path below would be untested")
	else:
		await _check_pad_trigger_opens_a_prefilled_prompt_and_renames()

	print("")
	if _failures.is_empty():
		print("rename pad trigger: OK")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _check_pad_trigger_opens_a_prefilled_prompt_and_renames() -> void:
	var party: RefCounted = _game.get("party")
	if party.call("at", 0) == null:
		var made: RefCounted = _game.call("make_creature", "terrapup")
		if made == null or not bool(party.call("add", made)):
			_fail("could not stand up a party member to rename")
			return
	var creature: RefCounted = party.call("at", 0)
	# An existing nickname, not a fresh capture's blank one -- proves the
	# prompt prefills what is actually THERE, not merely "shows up non-empty".
	creature.set("nickname", "Buddy")

	_menu.call("open")
	for i in 6:
		await physics_frame
	_menu.call("select", 1)  # Creatures (data/config/menu.json)
	for i in 6:
		await physics_frame

	var body: Node = _menu.get("_bodies")[1]
	var rows: Array = body.get("_rows")
	if rows.is_empty():
		_fail("the Creatures tab drew no rows")
		return
	(rows[0] as Button).grab_focus()
	for i in 4:
		await physics_frame
	if root.get_viewport().gui_get_focus_owner() != rows[0]:
		_fail("row 0 does not hold real UI focus after grab_focus -- cannot isolate the rename press to it")
		return

	var rename_button := _pad_button_for(RENAME_ACTION)
	if rename_button < 0:
		_fail("%s has no joypad binding at all -- a controller cannot reach the rename verb" % RENAME_ACTION)
		return

	await _pad(rename_button)

	var renaming: RefCounted = body.get("_renaming")
	var panel: CanvasLayer = body.get("_rename_panel")
	if renaming == null or panel == null:
		_fail("a real joypad press of %s (button %d) did not open the rename prompt" % [
			RENAME_ACTION, rename_button,
		])
		return
	print("  ok    pad press of %s (button %d) opened the rename prompt" % [RENAME_ACTION, rename_button])

	if not bool(panel.call("is_open")):
		_fail("the rename prompt reports itself closed right after opening")
		return

	var prefill := str(panel.call("current_text"))
	if prefill != "Buddy":
		_fail("the prompt prefilled '%s', not the creature's current nickname 'Buddy'" % prefill)
		return
	print("  ok    prompt prefilled with the creature's current name ('Buddy')")

	# Confirm the UNEDITED prefill through the real on-screen grid -- the
	# surface a controller player actually gets (`INPUT_GLYPH.using_gamepad()`
	# flips true the moment a real joypad event passes through
	# `game_state.gd::_input`, so the pad grid, not the keyboard `LineEdit`,
	# is what `open()` chose). Proves the confirm half of the chain, not just
	# that the buffer starts right.
	var down_button := _pad_button_for(DOWN_ACTION)
	var right_button := _pad_button_for(RIGHT_ACTION)
	var confirm_button := _pad_button_for(CONFIRM_ACTION)
	if down_button < 0 or right_button < 0 or confirm_button < 0:
		_fail("ui_down/ui_right/menu_confirm are missing a joypad binding -- cannot reach Done on a pad")
		return

	# The grid opens at (row 0, col 0); Done sits at the last cell of the last
	# row. The counts are DERIVED from `scripts/ui/name_entry.gd::ROWS` rather
	# than written out, because they were written out -- "six downs, six
	# rights" against a 7-row grid whose last row was 7 wide -- and went stale
	# the moment that grid changed shape, failing this test on the confirm
	# assertion while the navigation was what had actually moved. The route
	# still deliberately never touches a letter cell, so the buffer stays
	# exactly "Buddy" and the assertions below are about the CONFIRM path
	# rather than a second edit.
	var entry_rows: Array = load("res://scripts/ui/name_entry.gd").ROWS
	var last_row: int = entry_rows.size() - 1
	var last_column: int = (entry_rows[last_row] as Array).size() - 1
	for i in last_row:
		await _pad(down_button)
	for i in last_column:
		await _pad(right_button)

	await _pad(confirm_button)
	for i in 6:
		await physics_frame

	if body.get("_renaming") != null:
		_fail("_renaming was not cleared after the pad confirmed the rename")
	if body.get("_rename_panel") != null:
		_fail("_rename_panel was not cleared after the pad confirmed the rename")

	var nickname_after := str(creature.get("nickname"))
	if nickname_after != "Buddy":
		_fail(
			"confirming through the pad did not reach party_seam.set_nickname -- "
			+ "nickname reads '%s', expected the unedited prefill 'Buddy'" % nickname_after
		)
		return
	print("  ok    pad confirm reached party_seam.set_nickname (nickname: '%s')" % nickname_after)


## The joypad button an action is actually bound to, or -1. Read from the
## live InputMap so this test describes the shipped bindings rather than a
## copy of them.
func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## A real controller button, the way hardware delivers it -- deliberately NOT
## an `InputEventAction`, since routing through the InputMap is the entire
## point. Ticks BOTH `physics_frame` and `process_frame`: `tab_creatures.gd`
## polls from an idle `_process`, `name_prompt.gd`'s grid from its own
## `_physics_process`, and this file drives both consumers with one helper.
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
