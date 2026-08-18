extends SceneTree

## RG6 (owner: "Menus don't read every input still."). Third report of this
## class (`OW10`, `UI-PAD1`, now this) -- the backlog's own instruction was
## "instrument every menu to log which action it saw and reproduce from
## that" absent the owner's exact screen and button. Every literal
## `Input.is_action_...` binding in the project already carries a real
## joypad event (audited against `project.godot`'s `[input]` block and
## Godot's own `ui_*` engine defaults while investigating this) -- so this
## file does not chase a missing binding. It chases the other way a menu can
## "not read" a press: nothing is FOCUSED to receive it. A Godot `Button`
## only answers `ui_up`/`ui_down`/`ui_accept` through focus, and this
## project already has ONE proven-correct reference for keeping that focus
## alive across a rebuild -- `shop_panel.gd::_refresh()`'s own
## `_focused_row_index()` / restore-after-rebuild pattern, with its own
## comment naming exactly this failure ("drops you back to nowhere after
## every single purchase"). Three other panels never had that: opening
## `storage_panel.gd` or `creature_bed_panel.gd` left NOTHING focused at
## all (a controller could not act on either screen, ever), and backing out
## of a pending pick on `swap_panel.gd` lost focus the same way shop_panel's
## own comment already warned about.
##
##   godot --headless --path . --script tests/smoke_menu_focus.gd
##
## Input is injected the same way `smoke_menu.gd`/`smoke_free_build.gd`
## drive Control focus navigation: `Input.action_press` plus a parsed
## `InputEventAction`, which is what a Godot `Control`'s own focus-nav reads
## regardless of device -- a raw `InputEventJoypadButton` is only needed
## where the CODE reads the device event itself (build_menu.gd's shared-
## button checks), not for stock focus navigation.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

var _failures: Array[String] = []
var _game: Node = null
var _menu: CanvasLayer = null
var _world: Node = null
var _player: CharacterBody3D = null


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
	if _game == null or _menu == null or _player == null:
		print("FAIL: world did not stand up Game/menu/Player; nothing to test")
		quit(1)
		return

	if bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 10:
			await physics_frame
	_game.set("free_build", true)

	await _check_storage_panel_can_be_navigated()
	await _check_creature_bed_panel_can_be_navigated()
	await _check_swap_panel_keeps_focus_after_backing_out_of_a_pick()

	_cleanup()
	print("")
	if _failures.is_empty():
		print("menu focus smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


func _cleanup() -> void:
	if _world != null and is_instance_valid(_world):
		_world.queue_free()


## --- shared helpers, same shape as smoke_menu.gd / smoke_free_build.gd -------

func _press(action: String) -> void:
	Input.action_press(action)
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await physics_frame
	await physics_frame
	Input.action_release(action)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for i in 6:
		await physics_frame


func _focused() -> Control:
	var viewport := root.get_viewport()
	return viewport.gui_get_focus_owner() if viewport != null else null


func _forward(player: Node3D) -> Vector3:
	var camera_rig := _world.get_node_or_null(^"CameraRig")
	if camera_rig != null and camera_rig.has_method("planar_basis"):
		return -(camera_rig.call("planar_basis") as Basis).z
	return -player.global_transform.basis.z


## Builds `id` right ahead of the player and plants it -- the same
## arm/ghost/`build_place` path `smoke_free_build.gd` already proves works.
func _build_and_place(id: String) -> Node3D:
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 100)
	inventory.call("add", "stone", 100)
	inventory.call("add", "fiber", 100)
	_game.set("pending_build", id)
	for i in 15:
		await physics_frame
	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 20:
		await physics_frame
	_game.set("pending_build", "")
	var node_name := "Storage" if id == "storage" else ("CreatureBed" if id == "creature_bed" else "")
	return _world.get_node_or_null(NodePath(node_name)) if not node_name.is_empty() else null


## Walks the player to `prompt`'s own position and presses `interact` for
## real, same as `smoke_free_build.gd::_check_the_first_day_arc` already does
## for the camp/workbench prompts.
func _walk_and_interact(prompt: Node3D) -> void:
	_player.global_position = prompt.global_position + Vector3(0.5, 0.5, 0.0)
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 15:
		await physics_frame


## --- storage --------------------------------------------------------------

func _check_storage_panel_can_be_navigated() -> void:
	_player.global_position += _forward(_player) * 20.0
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame

	var chest := await _build_and_place("storage")
	if chest == null:
		_fail("storage: build_place did not plant a chest; cannot reproduce RG6 this way")
		return
	var prompt := chest.get_node_or_null(^"Interactable")
	if prompt == null:
		_fail("storage: the placed chest has no Interactable prompt")
		return

	await _walk_and_interact(prompt)
	var panel: Node = null
	var storage_open := false
	for node: Node in _world.get_tree().get_nodes_in_group("input_owner"):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("storage_panel.gd"):
			panel = node
			storage_open = bool(node.call("is_open"))
			break
	if not storage_open:
		_fail("storage: interacting with the chest did not open storage_panel.gd (or it never joined input_owner.gd's group)")
		return

	if _focused() == null:
		_fail("storage: opening the chest left nothing focused -- a controller could not act on this screen at all")
		await _press("menu_cancel")
		return
	print("storage: opening the chest focuses a row")

	# `_process` rebuilds every row on both sides EVERY FRAME regardless of
	# whether anything actually changed (this file's own comment on
	# `_refresh()` names why) -- so comparing focused Control OBJECTS across
	# an `await` is meaningless, they are never the same object twice. Index
	# WITHIN the live `_deposit_rows` array is the thing that is stable
	# frame to frame absent a real change, so navigation is checked against
	# that instead.
	var deposit_rows: Array = panel.get("_deposit_rows")
	var first_index: int = deposit_rows.find(_focused())
	await _press("ui_down")
	deposit_rows = panel.get("_deposit_rows")
	var after_down_index: int = deposit_rows.find(_focused())
	if first_index < 0 or after_down_index < 0 or after_down_index == first_index:
		_fail("storage: ui_down did not move focus to a different row (index %d -> %d)" % [first_index, after_down_index])
	else:
		print("storage: ui_down moves focus (row %d -> %d)" % [first_index, after_down_index])

	# Press the focused row for real -- Godot's `Button.pressed` fires on
	# `ui_accept` specifically, not `menu_confirm` (they share a physical
	# button per UI-PAD3, but they are different actions; only `ui_accept`
	# activates a focused Control). This deposits a whole stack and rebuilds
	# BOTH columns (`_refresh()`), which is exactly the moment the bug
	# destroyed focus -- checked here against a REAL state change (a row
	# actually moved columns), not merely "something is still focused",
	# which would pass even if the press did nothing at all.
	var deposit_before: int = (panel.get("_deposit_rows") as Array).size()
	var withdraw_before: int = (panel.get("_withdraw_rows") as Array).size()
	await _press("ui_accept")
	var deposit_after: int = (panel.get("_deposit_rows") as Array).size()
	var withdraw_after: int = (panel.get("_withdraw_rows") as Array).size()
	if withdraw_after != withdraw_before + 1 or deposit_after != deposit_before - 1:
		_fail("storage: pressing ui_accept on a focused row did not move an item (deposit %d->%d, withdraw %d->%d)"
			% [deposit_before, deposit_after, withdraw_before, withdraw_after])
	elif _focused() == null:
		_fail("storage: depositing an item rebuilt the screen and left nothing focused")
	else:
		print("storage: a real deposit moved an item and focus survives the rebuild")

	await _press("menu_cancel")
	if panel != null and bool(panel.call("is_open")):
		_fail("storage: menu_cancel did not close the panel")
	else:
		print("storage: menu_cancel closes the panel")


## --- creature bed -----------------------------------------------------------

func _check_creature_bed_panel_can_be_navigated() -> void:
	_player.global_position += _forward(_player) * 20.0
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame

	var bed := await _build_and_place("creature_bed")
	if bed == null:
		_fail("creature bed: build_place did not plant a bed; cannot reproduce RG6 this way")
		return
	var prompt := bed.get_node_or_null(^"Interactable")
	if prompt == null:
		_fail("creature bed: the placed bed has no Interactable prompt")
		return

	await _walk_and_interact(prompt)
	var panel: Node = null
	for node: Node in _world.get_tree().get_nodes_in_group("input_owner"):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("creature_bed_panel.gd"):
			panel = node
			break
	if panel == null or not bool(panel.call("is_open")):
		_fail("creature bed: interacting with the bed did not open creature_bed_panel.gd (or it never joined input_owner.gd's group)")
		return

	if _focused() == null:
		_fail("creature bed: opening the bed left nothing focused -- a controller could not act on this screen at all")
		await _press("menu_cancel")
		return
	print("creature bed: opening the bed focuses a row")

	await _press("menu_cancel")
	if bool(panel.call("is_open")):
		_fail("creature bed: menu_cancel did not close the panel")
	else:
		print("creature bed: menu_cancel closes the panel")


## --- swap (Oskar) -----------------------------------------------------------

## `swap_panel.gd::open()` already focuses its first row correctly -- the gap
## is the "back out of a pending pick" path (`_process`'s own `menu_cancel`
## handler calling `_refresh()` -> `_draw_party()` with nothing to grab focus
## afterward), which needs a real pick to reach at all.
func _check_swap_panel_keeps_focus_after_backing_out_of_a_pick() -> void:
	var party: RefCounted = _game.get("party")
	if party == null:
		_fail("swap: no party to test with")
		return
	# `_draw_party()` disables the only row when the party is down to one --
	# two real creatures keep this check about focus, not eligibility. This
	# world never drove the opening (unlike `smoke_free_build.gd`), so the
	# party can start at zero, not one.
	while int(party.call("size")) < 2:
		var extra: RefCounted = _game.call("make_creature", "terrapup")
		if extra == null or not bool(party.call("add", extra)):
			break
	if int(party.call("size")) < 2:
		_fail("swap: could not get two party creatures to test with")
		return

	var panel: Node = _world.get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		_fail("swap: no dialogue_panel in the world; cannot reach Oskar's trade this way")
		return
	if not bool(panel.call("start", "village_oskar_trade_intro")):
		_fail("swap: 'village_oskar_trade_intro' would not start; data/dialogue/village.json may have moved")
		return
	var guard := 0
	while bool(panel.call("is_open")) and guard < 20:
		Input.action_press("interact")
		await physics_frame
		await physics_frame
		Input.action_release("interact")
		for i in 6:
			await physics_frame
		guard += 1
	if bool(panel.call("is_open")):
		_fail("swap: pressing interact %d times never closed Oskar's dialogue" % guard)
		return
	for i in 10:
		await physics_frame

	var swap: Node = null
	for node: Node in _world.get_tree().get_nodes_in_group("input_owner"):
		if node.get_script() != null and str(node.get_script().resource_path).ends_with("swap_panel.gd"):
			swap = node
			break
	if swap == null or not bool(swap.call("is_open")):
		_fail("swap: Oskar's dialogue did not chain into swap_panel.gd (or it never joined input_owner.gd's group)")
		return

	if _focused() == null:
		_fail("swap: opening the trade screen left nothing focused")
		swap.call("close")
		return
	print("swap: opening the trade screen focuses a row")

	# Pick a creature for real -- Godot's `Button.pressed` fires on
	# `ui_accept`, not `menu_confirm` (see storage's own note above). This is
	# the confirm sub-screen, whose own `_draw_confirm()` already grabs focus
	# correctly (call_deferred).
	await _press("ui_accept")
	if int(swap.get("_pending_index")) < 0:
		_fail("swap: pressing ui_accept on a focused party row did not arm a pick")
		swap.call("close")
		return
	if _focused() == null:
		_fail("swap: the confirm screen left nothing focused")
	else:
		print("swap: the confirm screen focuses its own button")

	# Back out -- the real gap. `_draw_party()` used to leave nothing
	# focused here.
	await _press("menu_cancel")
	if int(swap.get("_pending_index")) >= 0:
		_fail("swap: menu_cancel did not back out of the pending pick")
		swap.call("close")
		return
	if not bool(swap.call("is_open")):
		_fail("swap: menu_cancel closed the whole screen instead of just backing out of the pick")
		return
	if _focused() == null:
		_fail("swap: backing out of a pending pick left nothing focused -- the stick and d-pad do nothing from here")
	else:
		print("swap: backing out of a pending pick keeps a row focused")

	await _press("menu_cancel")
	if bool(swap.call("is_open")):
		_fail("swap: a second menu_cancel did not close the trade screen")
	else:
		print("swap: menu_cancel closes the trade screen")
