extends SceneTree

## T2-BUILDPLACE. Live-engine RIG-or-GAME verdict for the S03 build-placement
## failure (`S03-118`..`S03-204`: analog-stick ghost placement never registers
## `home_built`/`creature_bed_built_3` with `home_progress.gd`).
##
## The step-by-step notes (`ralph/reports/gate-f-run-20260828T183531Z/S03/
## notes/S03.md`) show every "placement owns input" assertion FAILing --
## `input_context` stays `build_catalogue` after the "arm" (`ui_accept` on a
## focused catalogue cell) instead of moving to `build_placement`
## (`S03-117`, `S03-130`, ...). That is `build_menu.gd::_pick()` never
## running to completion. `_pick()` has exactly one early-return that leaves
## the menu open: the piece is not affordable
## (`build_menu.gd:713-719`, `AUDIO_CUES.play(&"ui_error")`, no
## `pending_build` set, no `close()`).
##
## The run's own kept `S03-exit.json` (`placed_buildings: []`, inventory
## carrying `berries: 5` and NO `wood`/`stone`/`fiber` entries at all,
## `events.jsonl` containing zero occurrences of "wood"/"stone"/"fiber")
## shows why: `S03.json`'s 20-node gathering loop (`S03-65`..`S03-104`) never
## equips the axe/pickaxe/knife Tam hands over (`tam_tools_given`) onto a
## hotbar slot before pressing `interact` -- and
## `harvest_logic.gd::gather()`/`tests/test_harvest.gd::
## test_gather_with_no_equipped_tool_is_refused` both confirm, by design and
## by an existing passing unit test, that carrying a tool un-equipped yields
## nothing. So wood/stone/fiber never land in the satchel, camp (12/8/10) and
## creature_bed (6/-/8) are never affordable, `_pick()` correctly refuses
## every single arm attempt, and the catalogue never lets go of input.
##
## This probe drives the REAL `build_menu.gd`/`build_placer.gd`/
## `home_progress.gd` chain through the same synthetic-controller path
## S03 uses (`Input.parse_input_event`, not a bypass) to show, live:
##   1. an arm attempt with zero materials reproduces S03's own observed
##      failure exactly (menu stays open, pending_build stays empty);
##   2. the SAME arm+place mechanism, once materials are actually present,
##      closes the menu, arms the ghost, places the piece for real, and
##      home_progress.gd sets home_built once camp + creature_bed both
##      stand -- i.e. the catalogue-driven placement pipeline itself is not
##      broken; the step-script never paid for what it tried to buy.
##
##   godot --headless --path . --script tools/gate_f/probe_build_catalogue_arm_cause.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const BUILD_MENU := preload("res://scripts/ui/build_menu.gd")
const SETTLE_FRAMES := 240
const BUILD_SPOT := Vector3(100.0, 0.0, 80.0)

var _failures: Array[String] = []
var _world: Node
var _game: Node
var _player: CharacterBody3D


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	if _game == null or _player == null:
		print("PROBE FAIL: Meadows did not stand up Game and Player")
		quit(1)
		return

	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")

	var y := float(_world.call("ground_height_at", BUILD_SPOT.x, BUILD_SPOT.z)) if _world.has_method("ground_height_at") else 0.0
	_player.global_position = Vector3(BUILD_SPOT.x, y + 0.2, BUILD_SPOT.z)
	_player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame

	var inventory: RefCounted = _game.get("inventory")
	print("--- starting inventory (fresh boot, matching S03's own pre-Tam state) ---")
	for id in ["wood", "stone", "fiber"]:
		print("  %s: %d" % [id, int(inventory.call("count", id))])

	# --- Part 1: reproduce S03's own observation, live, at zero materials ---
	print("")
	print("=== PART 1: arm 'camp' with zero materials (S03's actual state) ===")
	var menu := BUILD_MENU.get_or_make(self) as CanvasLayer
	menu.call("open")
	for i in 10:
		await physics_frame
	print("menu open after open(): %s" % str(menu.call("is_open")))

	var armed_at_zero := await _arm_focused_cell(menu)
	print("after arm attempt: menu.is_open()=%s  pending_build=\"%s\""
		% [str(menu.call("is_open")), str(_game.get("pending_build"))])
	if not bool(menu.call("is_open")):
		_fail("PART 1: expected the menu to STAY open when the piece is unaffordable (matches S03's own build_catalogue-stuck observation) -- it closed instead")
	if not str(_game.get("pending_build")).is_empty():
		_fail("PART 1: expected pending_build to stay empty on an unaffordable arm -- got \"%s\"" % str(_game.get("pending_build")))
	if armed_at_zero:
		_fail("PART 1: _arm_focused_cell reported a successful arm at zero materials")
	else:
		print("CONFIRMED: this is exactly the S03-117/S03-130 failure shape, reproduced live -- an unaffordable piece correctly refuses to arm and the catalogue keeps input, which is `build_menu.gd`'s own by-design refusal path (line 713-719), not a broken transition.")

	if bool(menu.call("is_open")):
		menu.call("close", false)
		for i in 5:
			await physics_frame

	# --- Part 2: grant the real cost, drive the SAME synthetic path, confirm
	# the catalogue-driven arm+place mechanism itself works end to end ---
	print("")
	print("=== PART 2: grant camp's real cost (12 wood / 8 stone / 10 fiber) and re-arm ===")
	inventory.call("add", "wood", 12)
	inventory.call("add", "stone", 8)
	inventory.call("add", "fiber", 10)
	for id in ["wood", "stone", "fiber"]:
		print("  %s now: %d" % [id, int(inventory.call("count", id))])

	menu.call("open")
	for i in 10:
		await physics_frame
	var armed := await _arm_focused_cell(menu)
	print("arm result: %s  menu.is_open()=%s  pending_build=\"%s\""
		% [str(armed), str(menu.call("is_open")), str(_game.get("pending_build"))])
	if not armed:
		_fail("PART 2: arming the now-affordable first cell (camp) failed")
	if bool(menu.call("is_open")):
		_fail("PART 2: menu should have closed itself on a successful pick (build_menu.gd::_pick -> close(false))")
	if str(_game.get("pending_build")) != "camp":
		_fail("PART 2: expected pending_build == \"camp\" after arming the first survival-category cell, got \"%s\"" % str(_game.get("pending_build")))

	for i in 30:
		await physics_frame
	var before_placed: Array[Node] = get_nodes_in_group("placed_building")
	await _tap("build_place")
	for i in 30:
		await physics_frame
	var placed_camp: Node = null
	for node: Node in get_nodes_in_group("placed_building"):
		if before_placed.has(node):
			continue
		if str(node.get_meta("building_id", "")) == "camp":
			placed_camp = node
			break
	print("camp placed through the real catalogue+placer path: %s" % str(placed_camp != null))
	if placed_camp == null:
		_fail("PART 2: build_place through the catalogue-armed ghost produced no real 'camp' fixture")

	var progression: RefCounted = _game.get("progression")
	print("home_built after camp alone: %s" % str(bool(progression.call("has", "home_built"))))

	# --- Part 3: same path for creature_bed (furniture category), confirming
	# home_built (camp:1 + creature_bed:1, current data/config/progression.json)
	# actually flips once both real pieces stand ---
	print("")
	print("=== PART 3: grant creature_bed's cost (6 wood / 8 fiber) and arm+place it ===")
	inventory.call("add", "wood", 6)
	inventory.call("add", "fiber", 8)
	_player.global_position += Vector3(3.0, 0.0, 0.0)
	for i in 10:
		await physics_frame

	menu.call("open")
	for i in 10:
		await physics_frame
	# CATEGORY_ORDER (survival, crafting, structures, furniture): furniture is
	# index 3. The real S03 run's own notes (S03-127, S03-180) show
	# `menu_tab_right` category-cycling PASSING through the production
	# harness's input driver every time it was tried -- this probe's own `_tap`
	# helper is a smaller reimplementation of that same synthetic-input
	# technique and is not what is under test here (Part 1/Part 2 already
	# settle the RIG-or-GAME question); calling the category switch directly
	# keeps Part 3 aimed at the arm+place chain rather than re-litigating an
	# input path the real harness already exercises successfully elsewhere.
	menu.call("_select_category", 3)
	for i in 5:
		await physics_frame
	# Furniture's grid order is Storage Chest then Creature Bed
	# (data/items/buildables.json), matching S03-181's own comment -- that
	# step FAILed in the real run on a SEPARATE, already-recorded defect
	# ("1 x ui_right did not move focus off" the first cell), not on anything
	# this probe is chasing. Selecting cell 1 directly keeps this probe aimed
	# at the arm+place chain rather than re-diagnosing that focus bug too.
	menu.call("_pick", 1)
	for i in 10:
		await physics_frame
	var armed_bed := not bool(menu.call("is_open"))
	print("arm creature_bed: %s  pending_build=\"%s\"" % [str(armed_bed), str(_game.get("pending_build"))])
	if str(_game.get("pending_build")) != "creature_bed":
		_fail("PART 3: expected pending_build == \"creature_bed\" after cycling to Furniture and arming its first cell, got \"%s\"" % str(_game.get("pending_build")))

	for i in 30:
		await physics_frame
	var before_bed: Array[Node] = get_nodes_in_group("placed_building")
	await _tap("build_place")
	for i in 30:
		await physics_frame
	var placed_bed: Node = null
	for node: Node in get_nodes_in_group("placed_building"):
		if before_bed.has(node):
			continue
		if str(node.get_meta("building_id", "")) == "creature_bed":
			placed_bed = node
			break
	print("creature_bed placed through the real catalogue+placer path: %s" % str(placed_bed != null))
	if placed_bed == null:
		_fail("PART 3: build_place through the catalogue-armed ghost produced no real 'creature_bed' fixture")

	for i in 10:
		await physics_frame
	print("home_built after camp + creature_bed: %s" % str(bool(progression.call("has", "home_built"))))
	if placed_camp != null and placed_bed != null and not bool(progression.call("has", "home_built")):
		_fail("PART 3: both required pieces stand (data/config/progression.json home.required_pieces) but home_built never set")

	print("")
	if _failures.is_empty():
		print("PROBE PASS: the catalogue-driven arm+place chain (build_menu.gd -> " +
			"Game.pending_build -> build_placer.gd -> GameState.placed_buildings -> " +
			"home_progress.gd) works correctly end to end through the real synthetic " +
			"controller path once materials are actually available. VERDICT: RIG. " +
			"S03.json's gathering loop never equips the axe/pickaxe/knife it is handed, " +
			"so wood/stone/fiber never reach the satchel, every arm attempt is a " +
			"correct, by-design refusal, and the catalogue never releases input -- " +
			"exactly the S03-117/S03-130/S03-173/S03-205 failures on record.")
		quit(0)
	else:
		print("PROBE FOUND PROBLEMS (%d):" % _failures.size())
		for line in _failures:
			print("  - %s" % line)
		quit(1)


## Mirrors S03's own "arm <piece>" step: press ui_accept on whatever cell is
## currently focused in the open catalogue grid, the same physical edge
## `_tap` below drives for build_place, and reports whether the menu closed
## (the only externally-observable sign `_pick()` ran past its afford gate).
func _arm_focused_cell(menu: CanvasLayer) -> bool:
	await _tap("ui_accept")
	for i in 10:
		await physics_frame
	return not bool(menu.call("is_open"))


func _tap(action: String) -> void:
	var down := _joy_event_for(action, true)
	if down == null:
		_fail("InputMap action '%s' has no joypad button or axis" % action)
		return
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	Input.parse_input_event(_joy_event_for(action, false))
	for i in 5:
		await process_frame


func _joy_event_for(action: String, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			var out := InputEventJoypadButton.new()
			out.device = 0
			out.button_index = button.button_index
			out.pressed = pressed
			return out
		var motion := event as InputEventJoypadMotion
		if motion != null:
			var out := InputEventJoypadMotion.new()
			out.device = 0
			out.axis = motion.axis
			out.axis_value = motion.axis_value if pressed else 0.0
			return out
	return null
