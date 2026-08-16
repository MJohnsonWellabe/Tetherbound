extends SceneTree

## Can free build be switched on with a pad, and does the Build tab admit it?
##
##   godot --headless --path . --script tests/smoke_free_build.gd
##
## tests/test_free_build.gd proves the cost rule and the settings file. None of
## that can see the things that decide whether this toggle is usable or honest:
##
##   - reaching it. It ships on a handheld, so the toggle has to be walkable to
##     from where the settings screen puts the cursor, with nothing but a stick.
##   - the state on the button. A toggle that does not say which way it is set
##     is a coin flip.
##   - the Build tab saying so. This changes what everything costs; hidden, the
##     first bug report is a costing bug that is not one.
##   - a piece with an empty satchel behind it actually being buildable, through
##     the real menu, which is the only proof the screen and the accessor agree.
##
## Input is injected with `Input.parse_input_event` rather than
## `Input.action_press`. Actions set state but never enter the tree, so they
## cannot move focus — a poll-only test would report a working screen while the
## stick moved nothing. Learned on tests/smoke_menu.gd.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")
## BG1: read directly rather than duplicated as a literal, so this test cannot
## quietly drift from the placer's own constants the way a hand-copied "3.0"
## or "placed_building" string could.
const BUILD_PLACER := preload("res://scripts/build/build_placer.gd")
const BUILD_GRID := preload("res://scripts/build/build_grid.gd")
const SETTLE_FRAMES := 240

## How far up from where the settings screen starts the toggle may be. Three
## controls' worth of slack; more than that and it is buried.
const REACH_STEPS := 6

var _failures: Array[String] = []
var _game: Node = null
var _menu: CanvasLayer = null
var _settings: Node = null
var _build: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_menu = _game.call("menu") if _game != null else null
	if _menu == null:
		print("FAIL: the autoload did not stand up the menu")
		quit(1)
		return
	if bool(_game.get("free_build")):
		_fail("free build was already on before anything was pressed")
		_game.set("free_build", false)

	await _check_the_toggle_is_reachable_with_a_pad()
	if _settings == null:
		_cleanup()
		_report()
		return

	await _check_it_can_be_switched_on()
	await _check_the_choice_reached_the_settings_file()
	await _check_the_build_tab_says_materials_are_free()
	await _check_a_piece_can_be_built_out_of_an_empty_satchel()
	await _check_it_can_be_switched_off_again()
	await _check_the_first_day_arc(world)
	await _check_bg1_grid_rotation_and_snap(world)
	await _check_an_unaffordable_pick_shows_the_shortfall_and_refuses()
	await _check_b_closes_only_the_build_menu()

	_cleanup()
	_report()


## The whole reason the camp exists: gather along the path, arm the camp, plant
## it, rest, wake up on day two healed. Driven through the REAL pieces — the
## harvest nodes' interactables, GameState's costs, the placer's ghost — with
## only the menu-driving shortcut of arming `pending_build` directly (the
## build-tab half of that press is proven above).
func _check_the_first_day_arc(world: Node) -> void:
	# The toggle checks above end with the menu OPEN, the tree paused and the
	# interact arbiter asleep. The first day happens in the world.
	if bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 20:
			await physics_frame

	var inventory: RefCounted = _game.get("inventory")
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var placer := world.get_node_or_null(^"BuildPlacer")
	if player == null or placer == null:
		_fail("no player or no build placer in the world; the first day cannot be played")
		return

	# Gather: activate a real harvest node's interactable at point-blank.
	var before_wood := int(inventory.call("count", "wood"))
	var node := _nearest_harvest(world, player.global_position)
	if node == null:
		_fail("no harvest nodes in the world; there is nothing to gather")
		return
	player.global_position = node.global_position + Vector3(0.5, 0.5, 0.0)
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame
	var arbiter: Node = get_first_node_in_group("interaction_arbiter")
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 10:
		await physics_frame
	var gathered := int(inventory.call("count", "wood")) > before_wood \
		or int(inventory.call("count", "stone")) > 0 \
		or int(inventory.call("count", "fiber")) > 0 \
		or int(inventory.call("count", "berries")) > 0
	if not gathered:
		_fail("standing on a harvest node and pressing interact gathered nothing (arbiter offers '%s')"
			% (str(arbiter.call("prompt")) if arbiter != null else "no arbiter"))
		return
	print("gathered from a harvest node")

	# Fund and arm the camp, then plant it through the placer's own press.
	inventory.call("add", "wood", 12)
	inventory.call("add", "stone", 8)
	inventory.call("add", "fiber", 10)

	# Arming must never plant, even with the place button already held down.
	#
	# The owner's report was "you go to build, select the thing you want to
	# build and it just places. there is no decision for you, you don't place
	# it, you don't rotate, there's no grid." `build_place` is LMB, and
	# `build_menu.gd::_pick()` arms `pending_build` and closes on that same
	# click -- so the click that CHOSE the piece also satisfied the placer's
	# `is_action_just_pressed(build_place)` in the very same physics frame, and
	# the piece went into the ground `PLACE_AHEAD` metres away before a ghost
	# was ever drawn.
	#
	# Every other press in this file arms with the button up and then waits,
	# which is exactly why the whole suite stayed green through the entire bug.
	# This block holds the button across the arming frame, the way a real mouse
	# click does.
	Input.action_press("build_place")
	_game.set("pending_build", "camp")
	for i in 12:
		await physics_frame
	if world.get_node_or_null(^"Camp") != null:
		_fail("arming a piece with the place button held planted it instantly -- "
				+ "the player never sees a ghost, and never gets to rotate or position it")
		return
	if str(_game.get("pending_build")) != "camp":
		_fail("arming with the place button held disarmed the piece instead of holding the ghost")
		return
	Input.action_release("build_place")
	for i in 5:
		await physics_frame
	print("arming with place held planted nothing -- the ghost gets its frames")

	_game.set("pending_build", "camp")
	var wood_before_build := int(inventory.call("count", "wood"))
	for i in 30:
		await physics_frame
	# D34 retired build_placer.gd's read of `interact` in favour of its own
	# `build_place` action — see docs/decisions/D34's "double-read" section.
	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 20:
		await physics_frame

	var camp := world.get_node_or_null(^"Camp")
	if camp == null:
		_fail("pressing build_place on a legal ghost planted no camp")
		return
	if int(inventory.call("count", "wood")) >= wood_before_build:
		_fail("the camp was planted and cost no wood")
	if str(_game.get("pending_build")) != "":
		_fail("planting the camp left the build armed; every press would plant another")
	print("camp planted, costs spent")

	# Rest. The camp's own prompt, through the arbiter.
	var day_before := int(_game.get("day"))
	var vitals: RefCounted = player.get("vitals")
	vitals.set("health", 40.0)
	player.global_position = camp.global_position + Vector3(1.6, 0.5, 0.0)
	for i in 30:
		await physics_frame
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 140:
		await physics_frame

	if int(_game.get("day")) != day_before + 1:
		_fail("resting did not advance the day (still %d)" % int(_game.get("day")))
	elif float(vitals.get("health")) < float(vitals.get("max_health")):
		_fail("resting left the trainer at %.0f health" % float(vitals.get("health")))
	else:
		print("rested: day %d, trainer healed" % int(_game.get("day")))


## BG1: rotate a ghost, place it, and prove a second piece of the same type
## placed nearby snaps flush against the first rather than needing pixel-
## perfect aim. Runs after the camp/rest arc above, in the same world, with
## free build already back off — so this also proves rotated/snapped pieces
## are paid for through the real `GameState.build_cost_for`, not a shortcut.
func _check_bg1_grid_rotation_and_snap(world: Node) -> void:
	var inventory: RefCounted = _game.get("inventory")
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null or inventory == null:
		_fail("no player to place from")
		return
	# Comfortably more than two walls cost (buildables.json: wood 6, stone 2
	# each) — this arc is about placement, not affordability, which the free
	# build checks above already cover.
	inventory.call("add", "wood", 100)
	inventory.call("add", "stone", 100)
	var wood_before := int(inventory.call("count", "wood"))

	# --- piece one: rotate it before planting -------------------------------
	_game.set("pending_build", "wall")
	for i in 10:
		await physics_frame
	Input.action_press("build_rotate")
	await physics_frame
	await physics_frame
	Input.action_release("build_rotate")
	for i in 5:
		await physics_frame
	Input.action_press("build_rotate")
	await physics_frame
	await physics_frame
	Input.action_release("build_rotate")
	for i in 10:
		await physics_frame

	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 20:
		await physics_frame

	var walls := _wall_nodes(world)
	if walls.size() != 1:
		_fail("rotating and planting a wall left %d walls standing, expected 1" % walls.size())
		return
	var wall1 := walls[0] as Node3D
	var expected_yaw := deg_to_rad(BUILD_GRID.yaw_for_steps(2))  # two presses = 180 degrees
	if not is_equal_approx(wrapf(wall1.rotation.y, -PI, PI), wrapf(expected_yaw, -PI, PI)):
		_fail("two rotate presses should read 180 degrees, wall sits at %.1f degrees"
			% rad_to_deg(wall1.rotation.y))
	else:
		print("wall #1 planted rotated 180 degrees, as pressed")

	# --- piece two: aim close to piece one and let it snap flush -----------
	# Solve for a player position whose ghost lands within build_grid.gd's
	# SNAP_RADIUS of wall #1 but NOT already grid-aligned to it — proving this
	# is the neighbour-snap path, not a coincidental plain grid snap.
	var offset := Vector3(1.3, 0.0, 0.3)
	var target_raw_spot := wall1.global_position + offset
	var forward := _forward(world, player)
	player.global_position = target_raw_spot - forward * BUILD_PLACER.PLACE_AHEAD
	player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame

	_game.set("pending_build", "wall")
	for i in 15:
		await physics_frame
	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 20:
		await physics_frame

	walls = _wall_nodes(world)
	if walls.size() != 2:
		_fail("placing a second wall near the first left %d walls standing, expected 2" % walls.size())
		return
	var wall2: Node3D = walls[0] if walls[0] != wall1 else walls[1]

	if not is_equal_approx(wall2.rotation.y, 0.0):
		_fail("a freshly armed ghost should start unrotated, wall #2 sits at %.1f degrees"
			% rad_to_deg(wall2.rotation.y))

	var moved := Vector3(
		wall2.global_position.x - wall1.global_position.x,
		0.0,
		wall2.global_position.z - wall1.global_position.z
	)
	if not is_equal_approx(moved.length(), BUILD_GRID.GRID_SIZE):
		_fail("wall #2 should sit exactly one grid cell from wall #1 (neighbour snap), moved %.2fm"
			% moved.length())
	elif not is_equal_approx(wall2.global_position.y, wall1.global_position.y):
		_fail("neighbour-snapped wall #2 should share wall #1's height, %.2f vs %.2f"
			% [wall2.global_position.y, wall1.global_position.y])
	else:
		print("wall #2 snapped flush against wall #1, %.1fm away, same height" % moved.length())

	# --- the registry agrees with what is standing --------------------------
	var recorded: Array = []
	for entry: Variant in (_game.get("placed_buildings") as Array):
		var record := entry as Dictionary
		if str(record.get("id", "")) == "wall":
			recorded.append(record)
	if recorded.size() < 2:
		_fail("GameState.placed_buildings only recorded %d walls" % recorded.size())
	else:
		var last_two := recorded.slice(recorded.size() - 2, recorded.size())
		var yaws: Array = []
		for record: Dictionary in last_two:
			yaws.append(float(record.get("yaw_deg", -1.0)))
		if not (yaws.has(180.0) and yaws.has(0.0)):
			_fail("placed_buildings did not record both walls' yaw (got %s)" % [yaws])
		else:
			print("GameState.placed_buildings recorded both walls' rotation: %s" % [yaws])

	if int(inventory.call("count", "wood")) >= wood_before:
		_fail("two walls were planted and spent no wood")

	_game.set("pending_build", "")


## The same forward-direction math `build_placer.gd::_show_ghost` uses, so
## this test can aim a placement at an exact world-space point rather than
## depending on wherever the camera happens to be facing.
func _forward(world: Node, player: Node3D) -> Vector3:
	var camera_rig := world.get_node_or_null(^"CameraRig")
	if camera_rig != null and camera_rig.has_method("planar_basis"):
		return -(camera_rig.call("planar_basis") as Basis).z
	return -player.global_transform.basis.z


func _wall_nodes(world: Node) -> Array:
	var out: Array = []
	for node: Node in world.get_tree().get_nodes_in_group(BUILD_PLACER.PLACED_GROUP):
		if str(node.get_meta(BUILD_PLACER.BUILDING_ID_META, "")) == "wall":
			out.append(node)
	return out


func _nearest_harvest(world: Node, from: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance := INF
	for child in world.get_children():
		if child.get_script() == preload("res://scripts/world/harvest_node.gd"):
			var d := (child as Node3D).global_position.distance_to(from)
			if d < best_distance:
				best_distance = d
				best = child
	return best


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("free build smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)


func _fail(message: String) -> void:
	_failures.append(message)


## Leave nothing behind. This test writes the REAL settings file, and a cheat
## left switched on there would follow every later CI step — and the owner.
func _cleanup() -> void:
	if _game != null:
		_game.set("free_build", false)
	var bindings: RefCounted = _menu.get("bindings")
	if bindings != null:
		bindings.set("gameplay", {})
		bindings.call("reset_all")
		var path := str(bindings.call("path"))
		if not path.is_empty() and FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# --- input ------------------------------------------------------------------


## An action, sent both ways: as state for whatever polls, and as an event for
## the Control tree. See the note at the top.
func _press(action: String) -> void:
	Input.action_press(action)
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	Input.action_release(action)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await process_frame


func _focused() -> Control:
	var viewport := root.get_viewport()
	return viewport.gui_get_focus_owner() if viewport != null else null


func _status() -> String:
	return str(_menu.get("_status").text)


## Step to a tab the way the player does, with the button that changes tab.
func _go_to(tab_id: String) -> Node:
	var tabs: Array = _menu.get("_tabs")
	var wanted := -1
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == tab_id:
			wanted = i
	if wanted < 0:
		_fail("there is no %s tab" % tab_id)
		return null
	for step in tabs.size() + 1:
		if int(_menu.get("_index")) == wanted:
			break
		await _press("tool_cycle")
	if int(_menu.get("_index")) != wanted:
		_fail("`tool_cycle` never reached the %s tab" % tab_id)
		return null
	return _menu.get("_bodies")[wanted]


# --- the checks -------------------------------------------------------------


## Walkable to from where the settings screen puts the cursor. A toggle that
## needs a mouse, or twenty presses through a scrolling list, is not shipped.
func _check_the_toggle_is_reachable_with_a_pad() -> void:
	await _press("inventory")
	if not bool(_menu.call("is_open")):
		_fail("the menu did not open")
		return

	_settings = await _go_to("settings")
	if _settings == null:
		return

	var button: Button = _settings.get("_free_build_button")
	if button == null:
		_fail("the settings screen has no free build toggle")
		_settings = null
		return

	if _focused() == null:
		_fail("nothing holds focus on the settings tab; a stick would move nothing")
		return
	var steps := 0
	while _focused() != button and steps < REACH_STEPS:
		await _press("ui_up")
		steps += 1
	if _focused() != button:
		_fail("the toggle is more than %d presses from the cursor; it is buried" % REACH_STEPS)
		return
	print("the free build toggle is %d presses up from where the screen opens" % steps)


func _check_it_can_be_switched_on() -> void:
	var button: Button = _settings.get("_free_build_button")
	if not button.text.contains("Off"):
		_fail("the toggle does not say it is off: '%s'" % button.text)

	await _press("ui_accept")
	if not bool(_game.get("free_build")):
		_fail("confirm on the toggle did not switch free build on")
		return
	if not button.text.contains("On"):
		_fail("the toggle is on but does not say so: '%s'" % button.text)
	if _status().is_empty():
		_fail("switching a cheat on said nothing at all")
	print("the toggle switched on: '%s' — '%s'" % [button.text.strip_edges(), _status()])


## It has to survive the next launch, in the one file the controls already use.
func _check_the_choice_reached_the_settings_file() -> void:
	var bindings: RefCounted = _menu.get("bindings")
	var path := str(bindings.call("path"))
	if not FileAccess.file_exists(path):
		_fail("nothing was written to %s" % path)
		return
	var reloaded: RefCounted = KEY_BINDINGS.new(path)
	var status: int = int(reloaded.call("load_overrides"))
	if status != KEY_BINDINGS.LOAD_OK:
		_fail("the settings file did not reload (status %d)" % status)
		return
	var stored: Dictionary = reloaded.get("gameplay")
	if not bool(stored.get("free_build", false)):
		_fail("free build did not survive a reload of %s" % path)
	reloaded.call("reset_all")

	# And the game picks it back up, which is the half a file round-trip cannot
	# see: `GameState._adopt_preferences` is what runs on the next launch, right
	# after the menu shell has read the file.
	_game.set("free_build", false)
	bindings.call("load_overrides")
	_game.call("_adopt_preferences")
	if not bool(_game.get("free_build")):
		_fail("the game did not pick the toggle back up the way it does at boot")
	print("the choice is in %s, survives a reload, and comes back on at boot" % path)


func _check_the_build_tab_says_materials_are_free() -> void:
	_build = await _go_to("build")
	if _build == null:
		return
	var note: Label = _build.get("_free_note")
	if note == null:
		_fail("the build tab has no free build banner")
		return
	if not note.visible:
		_fail("free build is on and the build tab does not say so")
	if not note.text.to_lower().contains("free"):
		_fail("the banner does not say what it is about: '%s'" % note.text)
	print("the build tab says: '%s'" % note.text)


## The proof that the screen and `GameState.build_cost_for` agree: nothing has
## been gathered in this run, so the only reason this can succeed is the toggle.
func _check_a_piece_can_be_built_out_of_an_empty_satchel() -> void:
	var inventory: RefCounted = _game.get("inventory")
	if inventory != null and int(inventory.call("used_slots")) > 0:
		_fail("the satchel is not empty, so this proves nothing")
		return

	_game.set("pending_build", "")
	var menu := await _open_build_menu_and_pick_first()
	if menu == null:
		return

	if str(_game.get("pending_build")).is_empty():
		_fail("a piece could not be built with an empty satchel while free build was on")
		return
	print("'%s' was armed out of an empty satchel: '%s'" % [_game.get("pending_build"), _status()])


## A cheat that cannot be turned off is not a toggle. Turning it off must put
## the cost back on the same screen, in the same session.
func _check_it_can_be_switched_off_again() -> void:
	_settings = await _go_to("settings")
	if _settings == null:
		return
	var button: Button = _settings.get("_free_build_button")
	button.grab_focus()
	await process_frame
	await _press("ui_accept")
	if bool(_game.get("free_build")):
		_fail("the toggle would not switch back off")
		return

	_build = await _go_to("build")
	if _build == null:
		return
	var note: Label = _build.get("_free_note")
	if note != null and note.visible:
		_fail("free build is off and the build tab still says it is free")

	_game.set("pending_build", "")
	var menu := await _open_build_menu_and_pick_first()
	if menu == null:
		return
	if not str(_game.get("pending_build")).is_empty():
		_fail("a piece was still buildable with an empty satchel after free build was turned off")
	# A refused pick leaves the build menu open (it only closes on success) —
	# put it away so the run ends with the world in a normal state.
	if bool(menu.call("is_open")):
		menu.call("close")
		await process_frame
	print("switched back off, and the empty satchel is short again: '%s'" % _status())


## The hand-off half of the arming path: the Build tab's one button closes
## the pause menu and opens `build_menu.gd`. Assumes the pause menu is
## already open (every caller below opens it first). Returns the live build
## menu node, or null after failing.
func _open_build_menu_from_pause() -> Node:
	_build = await _go_to("build")
	if _build == null:
		return null
	var open_button: Button = _build.get("_open_button")
	if open_button == null:
		_fail("the build tab has no open button")
		return null
	open_button.grab_focus()
	await process_frame
	await _press("ui_accept")
	# The tab closes the pause menu and defers the build menu's open by a
	# frame so the two hand-offs don't fight over the mouse mode.
	for i in 6:
		await process_frame
	var menu: Node = null
	for child in root.get_children():
		if child.has_method("is_open") and bool(child.call("is_open")):
			menu = child
			break
	if menu == null:
		_fail("pressing the build tab's button did not open the build menu")
	return menu


## The arming path since the Valheim-style build menu replaced the flat tab
## list: picking a grid cell is what arms `pending_build` now. Returns the
## build menu node, or null after failing.
func _open_build_menu_and_pick_first() -> Node:
	var menu := await _open_build_menu_from_pause()
	if menu == null:
		return null
	var cells: Array = menu.get("_cell_buttons")
	if cells == null or cells.is_empty():
		_fail("the build menu drew no piece cells")
		return null
	(cells[0] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")
	for i in 3:
		await process_frame
	await _close_build_menu_and_restore_pause(menu)
	return menu


## The launcher closed the pause menu on the way in. The checks around this
## helper still talk to pause-menu tabs through `_go_to`, which cycles an
## OPEN menu — so put the world back the way the old flat-tab flow left it:
## pause menu open. (A successful pick closes the build menu itself; a
## refused one leaves it up, so this only reopens the build menu's OWN close
## when needed.)
func _close_build_menu_and_restore_pause(menu: Node) -> void:
	if menu != null and bool(menu.call("is_open")):
		menu.call("close")
		await process_frame
	if not bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 3:
			await process_frame


## OF23. `build_menu.gd::_pick` used to refuse an unaffordable piece with
## nothing but a `ui_error` beep — the owner's exact complaint ("the build
## menu doesn't work at all"). Proves, through the real menu with an emptied
## satchel: the grid greys the unaffordable cell, the pick still refuses (the
## menu stays open), and the refusal names what's short rather than staying
## silent.
func _check_an_unaffordable_pick_shows_the_shortfall_and_refuses() -> void:
	_game.set("free_build", false)
	_game.set("pending_build", "")
	if not bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 10:
			await physics_frame

	var inventory: RefCounted = _game.get("inventory")
	for id in ["wood", "stone", "fiber"]:
		inventory.call("remove", id, int(inventory.call("count", id)))

	var menu := await _open_build_menu_from_pause()
	if menu == null:
		return
	var cells: Array = menu.get("_cell_buttons")
	if cells == null or cells.is_empty():
		_fail("the build menu drew no piece cells with an empty satchel")
		await _close_build_menu_and_restore_pause(menu)
		return

	# Camp — survival, the first tab and first cell — costs wood/stone/fiber,
	# all zeroed above, so it is guaranteed unaffordable here.
	var cell := cells[0] as Button
	if cell.modulate.a >= 0.999:
		_fail("an unaffordable piece's grid cell is not greyed (alpha %.2f)" % cell.modulate.a)
	else:
		print("unaffordable cell greyed: alpha %.2f" % cell.modulate.a)

	cell.grab_focus()
	await process_frame
	await _press("ui_accept")
	for i in 3:
		await process_frame

	if not str(_game.get("pending_build")).is_empty():
		_fail("an unaffordable piece armed anyway: '%s'" % _game.get("pending_build"))
	elif not bool(menu.call("is_open")):
		_fail("a refused pick closed the build menu -- it should stay open so the player can pick something they can afford")
	else:
		print("an unaffordable piece refused to arm")

	var message_label: Label = menu.get("_message")
	var message := str(message_label.text) if message_label != null else ""
	if not message.to_lower().contains("need"):
		_fail("picking an unaffordable piece said nothing about what's short: '%s'" % message)
	elif not message.contains("Wood"):
		_fail("the shortfall message did not name the missing resource: '%s'" % message)
	else:
		print("build menu shortfall message: '%s'" % message)

	await _close_build_menu_and_restore_pause(menu)


## OF23. `menu_cancel` and `build_cancel` are both bound to gamepad button 1
## (project.godot) — the owner-reported bug is that closing the build menu
## on B reopens the pause menu the same frame. Driven with a raw joypad
## button press (not two separate actions) so this proves the actual shared
## button is fixed, not just that two independently-pressed actions behave.
func _check_b_closes_only_the_build_menu() -> void:
	_game.set("pending_build", "")
	if not bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 10:
			await physics_frame

	var menu := await _open_build_menu_from_pause()
	if menu == null:
		return
	if bool(_menu.call("is_open")):
		_fail("the pause menu is still open after the build tab handed off to the build menu")

	await _tap_pad(JOY_BUTTON_B)
	for i in 10:
		await process_frame

	var build_menu_closed := not bool(menu.call("is_open"))
	var pause_menu_stayed_shut := not bool(_menu.call("is_open"))
	if not build_menu_closed:
		_fail("pressing B did not close the build menu")
	if not pause_menu_stayed_shut:
		_fail("pressing B to leave the build menu reopened the pause menu the same frame")
	if build_menu_closed and pause_menu_stayed_shut:
		print("B closed the build menu without reopening the pause menu")


## Same shape as `smoke_settings.gd::_tap_pad` — a raw device event, not an
## action, so a shared physical button (this file's whole point for this
## check) is exercised honestly.
func _tap_pad(index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 3:
		await process_frame
