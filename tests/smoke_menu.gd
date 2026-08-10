extends SceneTree

## Does the menu actually open over the real game, and give the game back?
##
##   godot --headless --path . --script tests/smoke_menu.gd
##
## Unit tests can prove the satchel's arithmetic and the five-pal cap. They
## cannot see any of the things that make a menu usable or unusable, and every
## one of those is a way this ships broken:
##
##   - the mouse. scripts/world/playground_world.gd captures it unconditionally
##     and never gives it back. A menu that does not release it is a menu you
##     cannot click, and one that does not RESTORE it leaves the camera dead
##     after closing — which looks like a camera bug, not a menu bug.
##   - the pause. If the tree keeps running, the player is walking off a cliff
##     while reading their inventory.
##   - focus. This ships on a handheld. If nothing holds focus when the menu
##     opens, or the focus neighbours are not wired, the stick moves nothing and
##     the menu is decoration. Nothing about that shows up in a screenshot.
##   - the fight. `menu_cancel` and `combat_run` share a binding, so the menu
##     must yield mid-fight or the flee button opens a menu instead.
##
## Boots the real main scene with the real autoload, and drives it with injected
## input rather than by calling open() directly — calling the method would prove
## the method works and nothing about whether the button reaches it.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

var _failures: Array[String] = []
var _menu: CanvasLayer = null
var _game: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return
	_menu = _game.call("menu")
	if _menu == null:
		print("FAIL: the autoload did not stand up the menu")
		quit(1)
		return

	_check_the_fight_guard_can_see_the_fight(world)
	await _check_opens_on_the_inventory_button(world)
	await _check_focus_can_be_driven()
	await _check_tabs_can_be_cycled()
	await _check_the_party_screen_holds_five()
	await _check_closes_and_gives_the_game_back(world)
	await _check_opens_on_the_menu_button()
	_check_focus_recapture_respects_open_ui(world)

	print("")
	if _failures.is_empty():
		print("menu smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


## Press an action down both paths, because the menu uses both.
##
## `Input.action_press` sets the action state, which is what the menu's own
## polling reads. It does NOT put an event through the tree, so on its own it
## cannot move Control focus — and focus navigation is the half of a controller
## menu that a poll cannot do. `parse_input_event` supplies that half.
##
## A test that only did the first would have reported a working menu while the
## stick moved nothing, which is precisely the bug this file exists to catch.
func _press(action: String) -> void:
	Input.action_press(action)
	_send(action, true)
	await process_frame
	await process_frame
	Input.action_release(action)
	_send(action, false)
	for i in 4:
		await process_frame


func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


# --- opening ----------------------------------------------------------------


## The menu yields the Escape/B button while a fight is running, because
## `menu_cancel` and `combat_run` share a binding. That guard finds the fight by
## looking for a node that answers `is_fighting()` rather than by node path — so
## if combat is ever moved or renamed, the guard would quietly find nothing and
## the flee button would start opening a menu instead. This checks the lookup
## still lands, which is the half that can rot.
func _check_the_fight_guard_can_see_the_fight(world: Node) -> void:
	var found: Node = _menu.call("_find_combat", world)
	if found == null:
		_fail("the menu cannot find the fight; `menu_cancel` would open a menu instead of fleeing")
		return
	if bool(found.call("is_fighting")):
		_fail("a fight is somehow already running before the test starts")
	print("fight guard sees: %s" % found.name)


## What the mouse was doing before the menu opened, so closing can be checked
## against it rather than against a guess.
##
## HEADLESS CANNOT SEE CAPTURE. The dummy DisplayServer reports MOUSE_MODE_VISIBLE
## whatever the world asked for, so this test cannot prove the mouse was freed on
## a real machine — only that the menu recorded the mode it found and put that
## same mode back. The capture itself is checked by the owner opening the menu on
## the Ally and finding the camera still works afterwards, and there is no way
## around that from here.
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE


func _check_opens_on_the_inventory_button(world: Node) -> void:
	_mouse_before = Input.mouse_mode
	if _mouse_before != Input.MOUSE_MODE_CAPTURED:
		print("note: mouse reads %d, not CAPTURED — headless cannot capture" % _mouse_before)

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var position_before := player.global_position if player != null else Vector3.ZERO

	await _press("inventory")

	if not bool(_menu.call("is_open")):
		_fail("pressing `inventory` did not open the menu")
		return

	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		_fail("the menu opened without releasing the mouse (mode %d)" % Input.mouse_mode)
	if int(_menu.get("_mouse_before")) != _mouse_before:
		_fail("the menu recorded mouse mode %d but the world was in %d; closing will restore the wrong one" % [
			int(_menu.get("_mouse_before")), _mouse_before
		])

	if not paused:
		_fail("the menu opened without pausing the tree; the player keeps walking")

	# Prove the pause actually holds rather than merely being set. The player is
	# under gravity on a hillside, so 60 frames of unpaused physics move it.
	if player != null:
		Input.action_press("move_forward")
		for i in 60:
			await physics_frame
		Input.action_release("move_forward")
		var drift := player.global_position.distance_to(position_before)
		if drift > 0.05:
			_fail("the player moved %.2fm while the menu was open" % drift)

	print("opened on `inventory`: mouse released, tree paused, player still")


func _check_focus_can_be_driven() -> void:
	var focused := _focused_control()
	if focused == null:
		_fail("nothing holds focus when the menu opens; a stick would move nothing")
		return
	print("focus starts on: %s" % focused.name)

	# Move the cursor the way a d-pad does, through Godot's own ui_* actions.
	# If focus neighbours are not resolvable this simply does not move, which is
	# exactly the failure a screenshot cannot show.
	await _press("ui_right")
	var after_right := _focused_control()
	if after_right == focused:
		_fail("ui_right moved nothing; the grid cannot be driven with a stick")
	await _press("ui_down")
	if _focused_control() == after_right:
		_fail("ui_down moved nothing; the grid cannot be driven with a stick")
	print("focus moves on ui_right and ui_down")


func _check_tabs_can_be_cycled() -> void:
	var before := str(_menu.get("_index"))
	await _press("tool_cycle")
	if str(_menu.get("_index")) == before:
		_fail("`tool_cycle` did not change tab")
		return
	if _focused_control() == null:
		_fail("changing tab left nothing focused; the menu becomes undrivable")
	print("tab cycles on `tool_cycle`, focus follows")


## The five-pal cap, seen from the screen rather than from the unit test.
##
## CLAUDE.md forbids storage beyond five. This fills the party through the real
## GameState, asks for a sixth, and checks the screen still shows five rows.
func _check_the_party_screen_holds_five() -> void:
	var party: RefCounted = _game.get("party")
	while not bool(party.call("is_full")):
		var pal: RefCounted = _game.call("make_pal", "terrapup")
		if pal == null:
			_fail("could not build a pal from species.json")
			return
		party.call("add", pal)

	var sixth: RefCounted = _game.call("make_pal", "bramblebun")
	if bool(party.call("add", sixth)):
		_fail("the party accepted a sixth pal")
	if int(party.call("size")) != 5:
		_fail("the party holds %d pals" % int(party.call("size")))

	# Land on the pal tab and let it draw at least one frame.
	_menu.call("select", 1)
	for i in 4:
		await process_frame

	var rows: int = (_menu.get("_bodies")[1] as Node).get("_rows").size()
	if rows != 5:
		_fail("the party screen draws %d rows, not 5" % rows)
	print("party screen holds five, refuses a sixth")


# --- closing ----------------------------------------------------------------


func _check_closes_and_gives_the_game_back(world: Node) -> void:
	await _press("menu_cancel")

	if bool(_menu.call("is_open")):
		_fail("`menu_cancel` did not close the menu")
		return
	if Input.mouse_mode != _mouse_before:
		_fail("closing left the mouse at %d, not the %d it found; the camera is dead" % [
			Input.mouse_mode, _mouse_before
		])
	if paused:
		_fail("closing left the tree paused; the game is frozen with no menu on it")

	# And the world moves again.
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if player != null:
		var before := player.global_position
		Input.action_press("move_forward")
		for i in 60:
			await physics_frame
		Input.action_release("move_forward")
		if player.global_position.distance_to(before) < 0.5:
			_fail("the player still cannot move after the menu closed")
	print("closed on `menu_cancel`: mouse recaptured, tree running, player free")


func _check_opens_on_the_menu_button() -> void:
	await _press("menu_cancel")
	if not bool(_menu.call("is_open")):
		_fail("pressing `menu_cancel` in the world did not open the menu")
		return
	await _press("menu_cancel")
	if bool(_menu.call("is_open")):
		_fail("the same button that opened the menu did not close it")
	print("`menu_cancel` opens and closes")


func _focused_control() -> Control:
	var viewport := root.get_viewport()
	return viewport.gui_get_focus_owner() if viewport != null else null


## Is a window focus regain actually wired to re-capture the mouse, and does
## the gate that stops it stealing the mouse from an open menu work?
##
## Exercises scripts/world/playground_world.gd's `_capture_mouse_if_free()`,
## connected to `Window.focus_entered` as the RB1 fix: on a real Windows
## launch, a MOUSE_MODE_CAPTURED request made before the native window has OS
## focus can be silently dropped — `Input.mouse_mode` still reads back
## CAPTURED, so nothing downstream can tell, but the cursor was never
## actually confined and the camera never turns.
##
## HEADLESS CANNOT SEE REAL CAPTURE, confirmed by this file's own long-
## standing note above (`_mouse_before`): the dummy DisplayServer reports
## `Input.mouse_mode` as VISIBLE no matter what is requested, so reading it
## back after a `focus_entered.emit()` proves nothing here — a `Input.mode !=
## CAPTURED` check would fail on this build even with the fix wired
## correctly. What CAN be proven without touching that getter: the signal is
## actually connected, and `_mouse_wanted_elsewhere()` — the gate that stops a
## focus regain from stealing the mouse out from under an open menu — reports
## true exactly while the menu is open and false once it closes. Real
## on-device confirmation that focus regain actually re-captures is still
## required and is not claimed here.
func _check_focus_recapture_respects_open_ui(world: Node) -> void:
	if not world.has_method("_mouse_wanted_elsewhere") or not world.has_method("_capture_mouse_if_free"):
		_fail("playground_world is missing the RB1 mouse-recapture methods")
		return

	var handler := Callable(world, "_capture_mouse_if_free")
	if not world.get_window().focus_entered.is_connected(handler):
		_fail("Window.focus_entered is not wired to re-capture the mouse; a focus regain after a dropped boot-time capture will never retry it")

	if bool(world.call("_mouse_wanted_elsewhere")):
		_fail("_mouse_wanted_elsewhere is true with nothing open")

	_menu.call("open")
	if not bool(world.call("_mouse_wanted_elsewhere")):
		_fail("_mouse_wanted_elsewhere is false while the menu is open; a focus regain would steal the mouse from an open menu")
	_menu.call("close")

	if bool(world.call("_mouse_wanted_elsewhere")):
		_fail("_mouse_wanted_elsewhere is true after the menu closed")

	print("focus_entered is wired to recapture, and the gate correctly tracks the menu's open state")
