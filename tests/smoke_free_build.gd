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
	_game.set("pending_build", "camp")
	var wood_before_build := int(inventory.call("count", "wood"))
	for i in 30:
		await physics_frame
	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 20:
		await physics_frame

	var camp := world.get_node_or_null(^"Camp")
	if camp == null:
		_fail("pressing interact on a legal ghost planted no camp")
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
	var rows: Array = _build.get("_rows")
	if rows.is_empty():
		_fail("the build tab drew no rows")
		return
	(rows[0] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")

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
	var rows: Array = _build.get("_rows")
	(rows[0] as Button).grab_focus()
	await process_frame
	await _press("ui_accept")
	if not str(_game.get("pending_build")).is_empty():
		_fail("a piece was still buildable with an empty satchel after free build was turned off")
	print("switched back off, and the empty satchel is short again: '%s'" % _status())
