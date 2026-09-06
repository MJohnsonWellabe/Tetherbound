extends SceneTree

## Does keyboard/mouse input actually work in the FIRST minutes of a new game?
##
##   godot --headless --path . --script tests/smoke_early_input.gd
##
## OP-0905-01 (owner playtest 2026-09-05): "Inputs and keyboard are not working
## well again at the beginning." Three separate things this file can prove
## headlessly, in the order a fresh player hits them:
##
##  1. A real keyboard `move_forward` press, right after the opening WAKE fade
##     clears (the earliest moment the player has free control at all), moves
##     the body — booted the way `title_screen.gd::_start_new_game()` boots a
##     new game (`Game.reset_for_new_game()`, then the Meadows scene), not by
##     loading an already-settled world the way most other smokes do.
##  2. No CLOSED panel anywhere under the root is left visible and swallowing
##     the mouse (`MOUSE_FILTER_STOP` over its full rect) — the general shape
##     of the bug `smoke_mouse_look.gd` found once in `PlaygroundHUD`, checked
##     here against EVERY node in the tree with an `is_open()` that currently
##     reads false, not only the exploration HUD.
##  3. `name_prompt.gd`'s first real keystroke lands in the field the instant a
##     physical keyboard is used, even when `_last_input_was_gamepad` seeded
##     true (a joypad connected) — see that file's own `_input()` for the fix
##     this asserts.
##
## WHAT THIS CANNOT PROVE, headlessly, same finding `smoke_mouse_look.gd`
## already documents: `Input.mouse_mode` never reads back MOUSE_MODE_CAPTURED
## under the headless DisplayServer, so `camera_rig.gd`'s own mouse-look gate
## (`_unhandled_input`: "only if MOUSE_MODE_CAPTURED") can never fire here. A
## real look-direction assertion would pass or fail identically whether mouse
## look worked or not, so this does not attempt one — it proves the OTHER
## early-input claims that ARE answerable without a real window.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAME_PROMPT_SCENE := "res://scenes/ui/name_prompt.tscn"
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SETTLE_FRAMES := 240
const WAKE_WAIT_FRAMES := 400

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	await _check_forward_move_after_wake()
	await _check_no_closed_panel_eats_the_mouse()
	await _check_name_prompt_first_keystroke()
	_report()


# --- 1: real keyboard movement, right after the opening fade -------------


func _check_forward_move_after_wake() -> void:
	# `Game` is a project autoload and is always present once the engine's own
	# tree bootstrap has run -- but that bootstrap has not necessarily
	# happened yet on the very first synchronous line of `_init()`, before
	# this SceneTree has iterated even once. A couple of real frames first
	# is the same margin every other smoke in this repo gives it implicitly
	# by loading a whole world scene (which itself takes several frames)
	# before ever looking `Game` up.
	for i in 4:
		await process_frame
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("early-move: no Game autoload in the tree")
		return
	game.call("reset_for_new_game")
	var packed: PackedScene = load(SCENE)
	if packed == null:
		_fail("early-move: could not load %s" % SCENE)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var director := world.find_child("SequenceDirector", true, false)
	if player == null or director == null:
		_fail("early-move: world did not stand up Player/SequenceDirector")
		world.queue_free()
		await process_frame
		return

	# The earliest moment a fresh player has free control at all: the wake
	# fade cleared and nothing modal (a dialogue, the name prompt, the fade
	# itself) still owns the screen.
	var settled := false
	for i in WAKE_WAIT_FRAMES:
		await physics_frame
		if not bool(director.call("is_fading")) and INPUT_OWNER.current(self) == null:
			settled = true
			break
	if not settled:
		_fail("early-move: the WAKE fade/modal never cleared in %d frames (%s)" % [
			WAKE_WAIT_FRAMES, _early_state(director),
		])
		world.queue_free()
		await process_frame
		return

	var before := player.global_position
	await _key_hold("move_forward", 40)
	var after := player.global_position
	var moved := Vector2(after.x - before.x, after.z - before.z).length()
	if moved < 0.2:
		_fail("early-move: a real keyboard move_forward press moved the player %.3fm (%s)" % [
			moved, _early_state(director),
		])
	else:
		print("early-move: keyboard move_forward moved the player %.2fm right after WAKE cleared" % moved)

	world.queue_free()
	await process_frame


func _early_state(director: Node) -> String:
	var owner := INPUT_OWNER.current(self)
	return "is_fading=%s owner=%s" % [
		bool(director.call("is_fading")) if director != null else "?",
		str(owner.get_path()) if owner != null else "none",
	]


# --- 2: nothing CLOSED is left eating the mouse ---------------------------


func _check_no_closed_panel_eats_the_mouse() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		_fail("closed-panel scan: could not load %s" % SCENE)
		return
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var offenders: Array[String] = []
	_scan_closed_owners(world, offenders)
	for message in offenders:
		_fail("closed-panel scan: %s" % message)
	if offenders.is_empty():
		print("closed-panel scan: no closed panel is left visible + MOUSE_FILTER_STOP")

	world.queue_free()
	await process_frame


## Walks every node. For each one whose script exposes `is_open()` and
## currently answers false, walks ITS subtree looking for a visible,
## full-rect, MOUSE_FILTER_STOP Control — a closed panel has no business still
## owning the mouse.
func _scan_closed_owners(node: Node, offenders: Array[String]) -> void:
	if node.has_method("is_open") and not bool(node.call("is_open")):
		_scan_for_mouse_stop(node, node, offenders)
	for child in node.get_children():
		_scan_closed_owners(child, offenders)


func _scan_for_mouse_stop(owner_node: Node, node: Node, offenders: Array[String]) -> void:
	var c := node as Control
	if c != null and c.visible and c.mouse_filter == Control.MOUSE_FILTER_STOP and _is_full_rect(c):
		offenders.append("'%s' (closed owner %s) is visible with MOUSE_FILTER_STOP over the full rect" % [
			str(owner_node.get_path_to(node)) if node != owner_node else ".",
			str(owner_node.get_path()),
		])
	for child in node.get_children():
		_scan_for_mouse_stop(owner_node, child, offenders)


func _is_full_rect(c: Control) -> bool:
	var vp := c.get_viewport_rect().size
	if vp.x <= 1.0 or vp.y <= 1.0:
		return false
	return c.size.x >= vp.x * 0.9 and c.size.y >= vp.y * 0.9


# --- 3: name_prompt's first real keystroke is not swallowed ---------------


func _check_name_prompt_first_keystroke() -> void:
	var scene: PackedScene = load(NAME_PROMPT_SCENE)
	if scene == null:
		_fail("name_prompt: could not load %s" % NAME_PROMPT_SCENE)
		return
	var prompt: CanvasLayer = scene.instantiate()
	root.add_child(prompt)
	for i in 5:
		await physics_frame

	# Seed the same way `game_state.gd` seeds a machine with a pad connected —
	# the exact condition OP-0905-01's report matches (a controller plugged
	# in, keyboard used anyway). `INPUT_GLYPH.using_gamepad()` reads this
	# through `/root/Game`; fall back to writing the prompt's own
	# `_using_gamepad` directly if there is no Game autoload in this bare tree.
	var game := root.get_node_or_null(^"Game")
	if game != null:
		game.set("_last_input_was_gamepad", true)
	prompt.set("_using_gamepad", true)

	prompt.call("open", "Terrapup")
	# Let `open()`'s own OPEN_GUARD_FRAMES lapse (the deliberate "the press
	# that opened this is still this frame's action state" guard,
	# `_physics_process`-ticked) before testing what a LATER keystroke does —
	# that guard is real and correct, and is not what this test is about.
	for i in 6:
		await physics_frame
	if not bool(prompt.call("is_open")):
		_fail("name_prompt: open() did not open")
		root.remove_child(prompt)
		prompt.queue_free()
		return

	var field: LineEdit = prompt.get_node_or_null(^"Root/Box/Margin/Column/Field")
	if field == null:
		_fail("name_prompt: no Field node found to check")
		root.remove_child(prompt)
		prompt.queue_free()
		return

	# The literal first keystroke, on the very frame the gamepad seed is
	# still live — this is the exact race `_input()` exists to close.
	var down := InputEventKey.new()
	down.physical_keycode = KEY_T
	down.keycode = KEY_T
	down.unicode = 84 # 'T'
	down.pressed = true
	Input.parse_input_event(down)
	await physics_frame
	var up := down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	for i in 3:
		await physics_frame

	if bool(prompt.get("_using_gamepad")):
		_fail("name_prompt: a real keyboard key event did not flip the prompt out of gamepad mode")
	elif not field.visible or not field.has_focus():
		_fail("name_prompt: switched to keyboard mode but Field is not visible/focused (visible=%s focus=%s)" % [
			field.visible, field.has_focus(),
		])
	elif str(prompt.call("current_text")) == "":
		_fail("name_prompt: the very first keystroke was swallowed — current_text is empty after typing 'T'")
	else:
		print("name_prompt: first real keystroke landed immediately — current_text='%s'" % str(prompt.call("current_text")))

	root.remove_child(prompt)
	prompt.queue_free()


# --- helpers ---------------------------------------------------------------


func _key_hold(action: String, frames: int) -> void:
	var template: InputEvent = null
	if InputMap.has_action(action):
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				template = event
				break
	if template == null:
		_fail("InputMap action '%s' has no keyboard event" % action)
		return
	var down := (template as InputEventKey).duplicate()
	down.pressed = true
	Input.parse_input_event(down)
	for i in frames:
		await physics_frame
	var up := (template as InputEventKey).duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await physics_frame



func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("early-input smoke passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
