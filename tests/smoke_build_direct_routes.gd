extends SceneTree

## Does EACH direct door into the build catalogue actually let you place?
##
##   godot --headless --path . --script tests/smoke_build_direct_routes.gd
##
## OP-0905-02 (owner playtest 2026-09-05): "When you go directly to the build
## screen from playing rather than going through the menu, you can't place
## pieces." `tests/smoke_post_modal_control.gd` already drives the pause-menu
## door (Build tab -> Open) AND the hammer+interact door on a GAMEPAD and both
## pass — so this file exists to drive the doors and input DEVICES that smoke
## did not: a real keyboard `build_open` press, a real gamepad `build_shortcut`
## (LT) press, and the hammer+interact door again with a keyboard `interact`.
## Every real InputEvent is either cloned straight off the live InputMap (so a
## rebind moves this test with the game) or built to match one exactly.
##
## `build_place` (mouse-1 / joypad button 2) and `use_tool` (mouse-1 only) SHARE
## a physical mouse button with each other, and `build_open`/`build_shortcut`
## SHARE a physical keyboard key (both are "B") — the two collisions this file
## exists to catch a regression in, per the task brief's own suspects list.
##
## KNOWN HEADLESS LIMITATION: a real on-screen mouse click that hits a Control
## by SCREEN POSITION could not be produced here. Probed directly against a
## bare `Button`: `Input.parse_input_event(InputEventMouseButton)` at a
## position squarely inside the button's own `get_global_rect()` never fires
## its `pressed` signal, headless, regardless of viewport size — the headless
## `DisplayServer` has no window for the event to be hit-tested against, so
## `parse_input_event` only ever updates the raw `Input` action-state
## singleton (which is why every raw-button test in this file still works),
## never the GUI dispatch path a screen-position click needs. This is a
## silent no-op, not a hang — an earlier attempt at this same probe APPEARED
## to hang for minutes, but that was this sandbox's own `~/godot-bin/godot`
## wrapper (a 3-slot concurrency throttle shared with every other session on
## the box, `flock`-queuing behind other agents' world boots) rather than
## anything engine- or code-side; waiting it out found the real answer above.
## Every pick below goes through `ui_accept`/`menu_confirm`'s real keyboard or
## gamepad keys instead — the exact route `tests/smoke_build_menu_pad_pick.gd`
## already established as legitimate (a Godot Button activates on it once
## focused, and `build_menu.gd::open()`/`_select_category()` land focus on
## the first cell).
## What IS exercised with the real physical mouse button is the shared-button
## risk that does not need on-screen hit-testing at all: `Input.parse_input_event`
## updates global action state the moment the event lands, which is exactly the
## thing `build_placer.gd`'s own header names as the hazard ("Input.is_action_
## just_pressed is GLOBAL polling: it knows nothing about the Button that
## consumed the click") — so `build_place` is pressed as a bare mouse-1 event,
## not through any Control.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
const SETTLE_FRAMES := 240

var _failures: Array[String] = []
var _game: Node
var _menu: CanvasLayer
var _world: Node
var _player: CharacterBody3D
var _arbiter: Node
var _spot_index := 0


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	_menu = _game.call("menu") if _game != null else null
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_arbiter = get_first_node_in_group("interaction_arbiter")
	if _game == null or _menu == null or _player == null or _arbiter == null:
		_fail("world did not stand up Game/menu/Player/InteractionArbiter")
		_report()
		return

	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")
	var party: RefCounted = _game.get("party")
	while party != null and int(party.call("size")) < 1:
		var creature: RefCounted = _game.call("make_creature", "terrapup")
		if creature == null or not bool(party.call("add", creature)):
			break
	_game.set("free_build", true)
	for i in 12:
		await physics_frame

	await _door_build_shortcut_joypad()
	await _door_build_open_keyboard()
	await _door_hammer_interact_keyboard()

	_report()


# --- the three direct doors ------------------------------------------------


## LT (build_shortcut). A real InputEventJoypadMotion on axis 4 (LT), matching
## project.godot's own binding — build_shortcut's gamepad half is a trigger
## axis, not a button, so a joypad BUTTON event would never actually arm the
## action through the live InputMap.
func _door_build_shortcut_joypad() -> void:
	const CONTEXT := "build_shortcut (LT, joypad)"
	await _teleport_to(_next_spot())
	var before := _placed_total()
	await _axis_tap("build_shortcut", 4)
	var menu := await _wait_open_group("build_menu")
	if menu == null:
		_fail("%s: LT opened nothing (%s)" % [CONTEXT, _refusal_reasons()])
		return
	await _pick_focused_piece()
	await _finish_placement(CONTEXT, before, "joypad")


## Keyboard B (build_open). A real InputEventKey cloned from the live
## InputMap, picked with keyboard ui_accept, placed with a bare physical
## mouse-1 event (build_place's OTHER binding, shared with use_tool) — the
## keyboard+mouse combination the owner was actually playing with.
func _door_build_open_keyboard() -> void:
	const CONTEXT := "build_open (keyboard B)"
	await _teleport_to(_next_spot())
	var before := _placed_total()
	await _key_tap("build_open")
	var menu := await _wait_open_group("build_menu")
	if menu == null:
		_fail("%s: B opened nothing (%s)" % [CONTEXT, _refusal_reasons()])
		return
	await _pick_focused_piece()
	await _finish_placement(CONTEXT, before, "mouse")


## Hammer equipped + keyboard E (interact). The gamepad half of this door
## already passes in `smoke_post_modal_control.gd`; this is the keyboard half.
func _door_hammer_interact_keyboard() -> void:
	const CONTEXT := "hammer + interact (keyboard E)"
	await _teleport_to(_next_spot())
	var before := _placed_total()
	_game.set("equipped_tool", "hammer")
	for i in 4:
		await process_frame
	await _key_tap("interact")
	var menu := await _wait_open_group("build_menu")
	var refusal := "" if menu != null else _refusal_reasons()
	_game.set("equipped_tool", "")
	if menu == null:
		_fail("%s: E opened nothing (%s)" % [CONTEXT, refusal])
		return
	await _pick_focused_piece()
	await _finish_placement(CONTEXT, before, "joypad")


# --- shared steps ------------------------------------------------------


## Whatever cell `build_menu.gd::open()`/`_select_category()` already focused
## — the same real route `smoke_build_menu_pad_pick.gd` verified a controller
## can reach. Confirms focus landed on a cell before trusting the pick (a
## keyboard door that opened the menu but left focus nowhere would otherwise
## fail lower down for an unrelated reason).
func _pick_focused_piece() -> void:
	var focused := root.gui_get_focus_owner()
	if focused == null:
		_fail("catalogue opened but nothing has UI focus — a keyboard/gamepad pick has no target")
		return
	await _key_tap("ui_accept")


## `where` is "joypad" (button 2) or "mouse" (bare mouse-1 event, not routed
## through any Control) — build_place's own two bindings.
func _finish_placement(context: String, before: int, where: String) -> void:
	if str(_game.get("pending_build")).is_empty():
		_fail("%s: pick armed no piece (%s)" % [context, _diagnostics()])
		return
	for i in 15:
		await physics_frame
	if where == "mouse":
		await _mouse_tap(MOUSE_BUTTON_LEFT)
	else:
		await _pad_button_tap(2)
	for i in 20:
		await physics_frame
	if _placed_total() != before + 1:
		_fail("%s: build_place placed nothing (%s)" % [context, _diagnostics()])
		return
	print("%s: placed OK" % context)
	# Leave no ghost armed and no owner held for the next door.
	if not str(_game.get("pending_build")).is_empty():
		_game.set("pending_build", "")
	for i in 5:
		await physics_frame
	if INPUT_OWNER.current(self) != null:
		_fail("%s: INPUT_OWNER still held by %s after the catalogue closed" % [
			context, str(INPUT_OWNER.current(self).get_path()),
		])


# --- real input helpers --------------------------------------------------


func _key_tap(action: String) -> void:
	var template := _first_event(action, "InputEventKey")
	if template == null:
		_fail("InputMap action '%s' has no keyboard event" % action)
		return
	var down := (template as InputEventKey).duplicate()
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := (template as InputEventKey).duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	for i in 5:
		await process_frame


func _pad_button_tap(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.device = 0
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.device = 0
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 5:
		await process_frame


## A trigger axis "tap": to zero, matching how a real LT pull and release
## reports through `InputEventJoypadMotion`.
func _axis_tap(action: String, axis: int) -> void:
	var down := InputEventJoypadMotion.new()
	down.device = 0
	down.axis = axis
	down.axis_value = 1.0
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadMotion.new()
	up.device = 0
	up.axis = axis
	up.axis_value = 0.0
	Input.parse_input_event(up)
	for i in 5:
		await process_frame


## A bare mouse-button edge, deliberately not aimed at any Control — see this
## file's header on why an on-screen hit-test is not attempted here. This
## still exercises the real thing `build_placer.gd`'s own comment names as the
## hazard: global `Input.is_action_just_pressed` state for a button ALSO bound
## to `use_tool`.
func _mouse_tap(button_index: int) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 5:
		await process_frame


func _first_event(action: String, class_name_wanted: String) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if event != null and event.get_class() == class_name_wanted:
			return event
	return null


func _teleport_to(at: Vector3) -> void:
	var y := float(_world.call("ground_height_at", at.x, at.z)) if _world.has_method("ground_height_at") else _player.global_position.y
	_player.global_position = Vector3(at.x, y + 0.2, at.z)
	_player.velocity = Vector3.ZERO
	for i in 12:
		await physics_frame


func _next_spot() -> Vector3:
	_spot_index += 1
	return Vector3(140.0 + _spot_index * 20.0, 0.0, 70.0)


func _wait_open_group(group: String) -> Node:
	for i in 60:
		await process_frame
		for node: Node in get_nodes_in_group(group):
			if node.has_method("is_open") and bool(node.call("is_open")):
				return node
	return null


func _placed_total() -> int:
	return get_nodes_in_group("placed_building").size()


func _diagnostics() -> String:
	var owner := INPUT_OWNER.current(self)
	var owners: Array[String] = []
	for node: Node in get_nodes_in_group(INPUT_OWNER.GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			owners.append(str(node.get_path()))
	return "pending='%s' owner=%s open_owners=%s menu_open=%s paused=%s mouse_mode=%d place_blocked=%s" % [
		str(_game.get("pending_build")),
		str(owner.get_path()) if owner != null else "none",
		str(owners),
		bool(_menu.call("is_open")) if _menu != null else "?",
		paused,
		Input.mouse_mode,
		_placer_place_blocked(),
	]


func _placer_place_blocked() -> Variant:
	for node: Node in get_nodes_in_group("build_placer"):
		if node.has_method("get"):
			return node.get("_place_blocked")
	return "no build_placer node found"


## Which of the known refusals is live, when a door opened nothing.
func _refusal_reasons() -> String:
	var reasons: Array[String] = []
	if str(_game.get("equipped_tool")) not in ["", "hammer"]:
		reasons.append("equipped_tool is '%s'" % str(_game.get("equipped_tool")))
	if _arbiter != null and is_instance_valid(_arbiter) and not bool(_arbiter.call("enabled")):
		reasons.append("the interaction arbiter is DISABLED")
	var owner_node: Variant = INPUT_OWNER.current(self)
	if owner_node != null:
		reasons.append("INPUT_OWNER is already held by %s" % str(owner_node))
	if bool(_game.get("pending_build") != ""):
		reasons.append("pending_build is already armed as '%s'" % str(_game.get("pending_build")))
	if paused:
		reasons.append("the tree is paused")
	if reasons.is_empty():
		return "(none of the known refusals is live — the press itself did not land)"
	return "(" + ", ".join(reasons) + ")"


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: %s" % message)


func _report() -> void:
	if _game != null:
		_game.set("free_build", false)
		_game.set("pending_build", "")
		_game.set("equipped_tool", "")
	print("")
	if _failures.is_empty():
		print("build direct-routes smoke passed: build_shortcut/LT, build_open/keyboard, hammer+interact/keyboard all placed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
