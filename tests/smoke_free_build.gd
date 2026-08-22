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
const BUILD_SNAP := preload("res://scripts/build/build_snap_contract.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
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
	await _check_op21_07_rotate_wins_over_structural_anchor(world)
	await _check_a_specific_piece_is_chosen_through_real_pad_navigation(world)
	await _check_build_actions_are_gated_behind_a_reopened_menu(world)
	await _check_interact_is_gated_behind_an_open_build_menu()
	await _check_movement_and_jump_are_gated_behind_an_open_build_menu(world)
	await _check_an_unaffordable_pick_shows_the_shortfall_and_refuses()
	await _check_b_closes_only_the_build_menu()
	await _check_build_place_is_gated_behind_a_story_dialogue_and_recovers(world)

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

	# Gather: activate a real harvest node's interactable at point-blank. The
	# nearest authored node is currently stone, so this route must draw its
	# pickaxe first rather than relying on the retired "carrying is enough"
	# rule. Assign and press the real hotbar action: writing equipped_tool
	# directly would let this smoke pass without proving the visible player
	# route that harvest_node.gd now requires.
	var node := _nearest_harvest(world, player.global_position)
	if node == null:
		_fail("no harvest nodes in the world; there is nothing to gather")
		return
	var item_id := str(node.get("_item_id"))
	var items: RefCounted = _game.get("items")
	var required_tool := str(items.call("gathered_with", item_id)) if items != null else ""
	if not required_tool.is_empty():
		if int(inventory.call("find_slot", required_tool)) < 0:
			inventory.call("add", required_tool, 1)
		if not bool(_game.call("assign_hotbar", 0, required_tool)):
			_fail("could not assign the %s required by the nearest %s node to the hotbar"
				% [required_tool, item_id])
			return
		await _press("hotbar_1")
		var hold: Node = player.get("tool_hold")
		if str(_game.get("equipped_tool")) != required_tool \
				or hold == null or str(hold.call("equipped")) != required_tool \
				or hold.call("prop_node") == null:
			_fail("hotbar_1 did not visibly equip the %s required by the nearest %s node"
				% [required_tool, item_id])
			return
	var amount_before := int(inventory.call("count", item_id))
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
	var gathered := int(inventory.call("count", item_id)) > amount_before
	if not gathered:
		_fail("standing on a %s node with %s visibly equipped and pressing interact gathered nothing (arbiter offers '%s')"
			% [item_id, required_tool if not required_tool.is_empty() else "no tool required",
				str(arbiter.call("prompt")) if arbiter != null else "no arbiter"])
		return
	print("gathered %s from a harvest node with %s visibly equipped" % [
		item_id, required_tool if not required_tool.is_empty() else "no tool required"])
	if not required_tool.is_empty():
		await _press("hotbar_1")
		if not str(_game.get("equipped_tool")).is_empty():
			_fail("pressing the equipped %s's hotbar slot again did not stow it" % required_tool)
			return
		_game.call("assign_hotbar", 0, "")

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
	if str(_game.get("pending_build")) != "camp":
		_fail("persistent placement lost the selected camp after one placement")
	print("camp planted, costs spent, and a fresh camp ghost remains active")

	# The workbench: place one, and CRAFT AT IT. Owner brief: "use the
	# workbench to craft capture orbs, knives, axes, pickaxes" -- it used to be
	# plain geometry with no interaction, so this block is the loop's proof:
	# fund it, plant it through the same ghost path the camp just used, then
	# find its Craft prompt and craft a knife standing at the bench.
	inventory.call("add", "wood", 12)
	inventory.call("add", "stone", 8)
	inventory.call("add", "fiber", 6)
	_game.set("pending_build", "workbench")
	for i in 30:
		await physics_frame
	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 20:
		await physics_frame
	var bench: Node3D = null
	for child in world.get_children():
		if str(child.name).begins_with("Piece_workbench"):
			bench = child
			break
	if bench == null:
		_fail("pressing build_place on a legal workbench ghost planted no workbench")
		return
	var bench_prompt := bench.get_node_or_null(^"CraftInteractable")
	if bench_prompt == null:
		_fail("the placed workbench has no Craft prompt; it is scenery again")
		return
	player.global_position = bench.global_position + Vector3(0.0, 0.5, 1.2)
	for i in 30:
		await physics_frame
	var wood_before_craft := int(inventory.call("count", "wood"))
	if not bool(_game.call("can_craft", "knife")):
		_fail("standing at the bench with materials in hand, can_craft('knife') still refuses")
		return
	if not bool(_game.call("craft", "knife")):
		_fail("craft('knife') failed with materials in hand")
		return
	if int(inventory.call("count", "knife")) < 1:
		_fail("crafting a knife granted no knife")
		return
	if int(inventory.call("count", "wood")) >= wood_before_craft:
		_fail("crafting a knife spent no wood")
		return
	print("workbench planted, Craft prompt present, knife crafted at the bench")

	# Persistent mode must be left explicitly before the camp's Interactable
	# can own X. Use the production cancel action and verify the ghost clears.
	Input.action_press("build_cancel")
	await physics_frame
	await physics_frame
	Input.action_release("build_cancel")
	for i in 6:
		await physics_frame
	if not str(_game.get("pending_build")).is_empty():
		_fail("build_cancel did not leave persistent workbench placement")
		return

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

	if not is_equal_approx(wrapf(wall2.rotation.y, -PI, PI), wrapf(expected_yaw, -PI, PI)):
		_fail("persistent placement should retain orientation; wall #2 sits at %.1f degrees"
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
		if yaws.count(180.0) != 2:
			_fail("placed_buildings did not retain both walls' 180-degree yaw (got %s)" % [yaws])
		else:
			print("GameState.placed_buildings retained both walls' rotation: %s" % [yaws])

	if int(inventory.call("count", "wood")) >= wood_before:
		_fail("two walls were planted and spent no wood")

	_game.set("pending_build", "")


## OP21-07 regression. `_check_bg1_grid_rotation_and_snap` above never places a
## `floor` piece anywhere in this file, so both walls it plants only ever go
## through `build_snap_contract.gd`'s free/no-neighbour fallback (`yaw_deg`
## stays NAN, the structural override in `build_placer.gd::_show_ghost` never
## runs) -- it is a false positive against the actual owner report, which is
## specifically that rotate breaks down near a floor edge or existing wall,
## i.e. during real house-building. This places a floor first so a real
## structural anchor exists, rotates a wall a full 90 degrees off that
## anchor's own suggested axis, and asserts the placed wall actually turned --
## not the old behaviour, where the anchor's suggested yaw silently won back
## as soon as the rotation crossed onto a different 180-degree axis.
func _check_op21_07_rotate_wins_over_structural_anchor(world: Node) -> void:
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		_fail("no player to place from")
		return
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 100)
	inventory.call("add", "stone", 100)

	# A patch of ground right beside `_check_bg1_grid_rotation_and_snap`'s own
	# two walls, not an arbitrary distant offset -- that ground is already
	# proven flat and reachable (those two walls stand on it), where a fresh
	# guess elsewhere in this large open world risks slope/water/village
	# geometry the test has no way to know about in advance.
	var earlier_walls := _wall_nodes(world)
	var base_spot: Vector3 = earlier_walls[0].global_position if not earlier_walls.is_empty() else player.global_position
	var floor_spot := base_spot + Vector3(6.0, 0.0, 0.0)

	var forward := _forward(world, player)
	_game.set("pending_build", "floor")
	for i in 10:
		await physics_frame
	player.global_position = floor_spot - forward * BUILD_PLACER.PLACE_AHEAD
	player.velocity = Vector3.ZERO
	for i in 15:
		await physics_frame
	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 20:
		await physics_frame

	var floors: Array = []
	for node: Node in world.get_tree().get_nodes_in_group(BUILD_PLACER.PLACED_GROUP):
		if str(node.get_meta(BUILD_PLACER.BUILDING_ID_META, "")) == "floor":
			floors.append(node)
	if floors.size() != 1:
		_fail("op21-07 setup: expected 1 fresh floor, got %d" % floors.size())
		_game.set("pending_build", "")
		return
	var floor_node := floors[0] as Node3D
	var floor_pos: Vector3 = floor_node.global_position

	# The floor's own front edge (build_snap_contract.gd's HALF = MODULE/2):
	# a wall aimed here resolves against a REAL structural anchor whose own
	# suggested yaw is 0 -- the exact situation the owner reproduction names
	# ("near a floor edge ... essentially always during real house-building").
	var half: float = BUILD_SNAP.HALF
	var anchor_spot := floor_pos + Vector3(0.0, 0.0, half)

	_game.set("pending_build", "wall")
	for i in 10:
		await physics_frame
	player.global_position = anchor_spot - forward * BUILD_PLACER.PLACE_AHEAD
	player.velocity = Vector3.ZERO
	for i in 15:
		await physics_frame

	# Confirm the ghost really did pick up the anchor's own suggested yaw
	# before the player touches rotate at all -- otherwise a "it turned"
	# result below would prove nothing (nothing to override in the first
	# place).
	var placer := world.get_tree().get_first_node_in_group(BUILD_PLACER.BUILD_PLACER_GROUP)
	if placer == null:
		_fail("no BuildPlacer in the scene")
		_game.set("pending_build", "")
		return
	var pre_yaw := float(placer.get("_yaw_deg"))
	if not is_equal_approx(fposmod(pre_yaw, 360.0), 0.0):
		_fail("setup: wall ghost near the floor's front edge should default to the anchor's 0-degree suggestion before any rotate press, got %.1f" % pre_yaw)

	Input.action_press("build_rotate")
	await physics_frame
	await physics_frame
	Input.action_release("build_rotate")
	for i in 15:
		await physics_frame

	Input.action_press("build_place")
	await physics_frame
	await physics_frame
	Input.action_release("build_place")
	for i in 20:
		await physics_frame
	_game.set("pending_build", "")

	var walls := _wall_nodes(world)
	var new_wall: Node3D = null
	for node: Node3D in walls:
		if node.global_position.distance_to(anchor_spot) < BUILD_GRID.GRID_SIZE:
			new_wall = node
	if new_wall == null:
		_fail("op21-07: rotating a wall against a structural anchor did not place anything near it")
		return

	var placed_yaw := wrapf(new_wall.rotation.y, -PI, PI)
	var ninety := deg_to_rad(90.0)
	if is_equal_approx(placed_yaw, wrapf(0.0, -PI, PI)) or is_equal_approx(placed_yaw, wrapf(deg_to_rad(180.0), -PI, PI)):
		_fail("op21-07: one build_rotate press near a floor edge should turn the wall 90 degrees; it planted at %.1f degrees, unchanged from the anchor's own 0/180 axis"
			% rad_to_deg(new_wall.rotation.y))
	elif not (is_equal_approx(placed_yaw, wrapf(ninety, -PI, PI)) or is_equal_approx(placed_yaw, wrapf(-ninety, -PI, PI))):
		_fail("op21-07: expected the wall to plant at +-90 degrees off the anchor's axis, got %.1f degrees"
			% rad_to_deg(new_wall.rotation.y))
	else:
		print("op21-07: rotate turned a wall 90 degrees off a real structural anchor, and it placed")


## TEST2. Nothing in this suite had ever chosen a SPECIFIC build piece by
## navigating the menu the way a controller does. `smoke_build_menu_pad_pick.gd`
## (UI-PAD1) proved a pad can press a focused cell -- real progress, but it
## confirms whatever the menu already opened on, which cannot tell "the press
## works" apart from "the player chose this one on purpose". And
## `smoke_build_menu_footprint.gd` calls `_select_category` directly;
## `_check_the_first_day_arc` above arms `pending_build` directly too.
## Neither drives a category switch or grid navigation through input at all.
##
## So this presses real `InputEventJoypadButton` events for `tool_cycle`
## (switch category), `ui_right`/`ui_left` (move focus across the grid) and
## `ui_accept` (confirm) -- reading every button index from the live InputMap,
## same discipline as `smoke_backpack_pad_target.gd` -- to land on Structures'
## Doorway specifically (index 2 of 5, category index 2 of 4): neither the
## first category nor the first cell in it, so a test that only proves
## "pressing confirm arms whatever was already focused" cannot pass this by
## accident. Then it places the ghost for real and checks a Doorway, not
## some other piece, is what is standing in the world afterward -- closing
## the loop from stick input to world state.
func _check_a_specific_piece_is_chosen_through_real_pad_navigation(world: Node) -> void:
	const TARGET_CATEGORY := "structures"
	const TARGET_PIECE := "door"

	var inventory: RefCounted = _game.get("inventory")
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null or inventory == null:
		_fail("no player to place from")
		return

	# Clear of the two walls the rotation/snap check above planted.
	player.global_position += _forward(world, player) * 25.0
	player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame

	# Free build so this check is about whether real navigation reaches the
	# right cell, not about affordability -- already proven elsewhere in this
	# file.
	_game.set("free_build", true)
	if not bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 10:
			await physics_frame

	var menu := await _open_build_menu_from_pause()
	if menu == null:
		_game.set("free_build", false)
		return

	var tool_cycle_button := _pad_button_for("tool_cycle")
	var right_button := _pad_button_for("ui_right")
	var left_button := _pad_button_for("ui_left")
	var accept_button := _pad_button_for("ui_accept")
	if tool_cycle_button < 0 or right_button < 0 or left_button < 0 or accept_button < 0:
		_fail("tool_cycle, ui_right, ui_left or ui_accept has no joypad binding -- a controller cannot navigate this menu")
		await _close_build_menu_and_restore_pause(menu)
		_game.set("free_build", false)
		return

	# --- switch category with real tool_cycle presses, not `_select_category` --
	var categories: Array = menu.get("_categories")
	var target_category_index := categories.find(TARGET_CATEGORY)
	if target_category_index < 0:
		_fail("no '%s' category to navigate to" % TARGET_CATEGORY)
		await _close_build_menu_and_restore_pause(menu)
		_game.set("free_build", false)
		return
	var steps := posmod(target_category_index - int(menu.get("_category_index")), categories.size())
	for i in steps:
		await _tap_pad(tool_cycle_button)
	if int(menu.get("_category_index")) != target_category_index:
		_fail("%d real tool_cycle presses landed on category %d, not %s (%d)" % [
			steps, int(menu.get("_category_index")), TARGET_CATEGORY, target_category_index,
		])
		await _close_build_menu_and_restore_pause(menu)
		_game.set("free_build", false)
		return
	print("  ok    %d real tool_cycle presses switched to the %s category" % [steps, TARGET_CATEGORY])

	# --- navigate the grid with real ui_right/ui_left presses to a SPECIFIC, --
	# --- non-default piece -----------------------------------------------------
	var pieces: Array = menu.call("_current_pieces")
	var cells: Array = menu.get("_cell_buttons")
	var target_piece_index := -1
	for i in pieces.size():
		if str((pieces[i] as Dictionary).get("id", "")) == TARGET_PIECE:
			target_piece_index = i
	if target_piece_index < 0 or cells.size() != pieces.size():
		_fail("could not find '%s' among the %s cells" % [TARGET_PIECE, TARGET_CATEGORY])
		await _close_build_menu_and_restore_pause(menu)
		_game.set("free_build", false)
		return

	var focused := root.gui_get_focus_owner()
	var focused_index: int = cells.find(focused)
	if focused_index < 0:
		_fail("nothing has focus after switching category -- a stick would drive nothing")
		await _close_build_menu_and_restore_pause(menu)
		_game.set("free_build", false)
		return
	if focused_index == target_piece_index:
		_fail("the menu opened with focus already on the Doorway cell -- this run proves nothing about navigation, pick a different TARGET_PIECE")
		await _close_build_menu_and_restore_pause(menu)
		_game.set("free_build", false)
		return

	var nav_steps := target_piece_index - focused_index
	var nav_button := right_button if nav_steps > 0 else left_button
	for i in absi(nav_steps):
		await _tap_pad(nav_button)

	focused = root.gui_get_focus_owner()
	var landed_index: int = cells.find(focused)
	if landed_index != target_piece_index:
		_fail("%d real %s presses landed focus on cell %d, not the Doorway cell (%d)" % [
			absi(nav_steps), "ui_right" if nav_steps > 0 else "ui_left", landed_index, target_piece_index,
		])
		await _close_build_menu_and_restore_pause(menu)
		_game.set("free_build", false)
		return
	print("  ok    %d real d-pad presses moved focus from cell %d to the Doorway cell" % [absi(nav_steps), focused_index])

	# --- confirm with a real A press, and check it armed the RIGHT piece ------
	_game.set("pending_build", "")
	await _tap_pad(accept_button)

	var armed := str(_game.get("pending_build"))
	if armed != TARGET_PIECE:
		_fail("navigating to and pressing A on the Doorway cell armed '%s', not '%s'" % [armed, TARGET_PIECE])
		_game.set("free_build", false)
		return
	if bool(menu.call("is_open")):
		_fail("the menu stayed open after a real pad pick")
	else:
		print("  ok    real navigation plus a real A press armed exactly '%s'" % armed)

	# --- and it is what actually lands in the world ----------------------------
	Input.action_press(BUILD_PLACER.PLACE_ACTION)
	await physics_frame
	await physics_frame
	Input.action_release(BUILD_PLACER.PLACE_ACTION)
	for i in 20:
		await physics_frame

	var placed: Node3D = null
	for node: Node in world.get_tree().get_nodes_in_group(BUILD_PLACER.PLACED_GROUP):
		if str(node.get_meta(BUILD_PLACER.BUILDING_ID_META, "")) == TARGET_PIECE:
			placed = node
	if placed == null:
		_fail("pressing build_place did not plant a %s after it was chosen through real navigation" % TARGET_PIECE)
	else:
		print("  ok    the piece chosen through real category-switch and grid navigation is what landed in the world: %s" % placed.name)

	_game.set("free_build", false)
	_game.set("pending_build", "")

	# `_category_index` is a `static var` on build_menu.gd -- a within-session
	# "land back on what I last used" convenience -- so leaving it on Structures
	# would silently change which category `_check_an_unaffordable_pick_shows_
	# the_shortfall_and_refuses` below opens on; that check assumes Survival/Camp
	# by name in its own comment. The menu is already closed by the pick above
	# (asserted a few lines up), so there is no grid left to navigate with real
	# input; this sets the remembered index back directly rather than reopening
	# the menu solely to drive four more throwaway button presses that assert
	# nothing. `open()` itself always calls `_select_category` on whatever index
	# it finds, real player or not, so this is restoring state, not faking a pick.
	menu.set("_category_index", 0)


## The joypad button an action is actually bound to, or -1. Read from the live
## InputMap so this test describes the shipped bindings rather than a copy of
## them, same discipline `smoke_backpack_pad_target.gd` established.
func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## UI-PAD2. `build_placer.gd` is `PROCESS_MODE_PAUSABLE` like everything
## else, but `build_menu.gd` deliberately does not pause the tree -- so an
## armed ghost kept reading `build_place` out from under a REOPENED menu
## (`grep -n "input_owner" scripts/build/build_placer.gd` used to return
## nothing). Arms a wall directly (the arming path itself is proven above),
## reopens the build menu the real way a player would (the pause menu's
## Build tab), and presses `build_place` for real while the menu sits on top
## of the still-armed ghost: nothing should happen. Then closes the menu,
## moves off the two walls the earlier check in this file planted (so a
## legal, unoccupied spot is not left to chance), and presses `build_place`
## again -- proving this is a gate that releases, not a break that ate the
## feature.
##
## Deliberately does NOT drive this with `build_cancel`: that action is
## ALSO how `build_menu.gd::_process` itself closes on a shared button (OF23,
## "menu_cancel and build_cancel share gamepad B") -- a real ambiguity this
## check has no reason to referee, and doing so only couples this test to
## `_process`/`_physics_process` ordering that has nothing to do with the
## `input_owner.gd` gate it exists to prove.
func _check_build_actions_are_gated_behind_a_reopened_menu(world: Node) -> void:
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 100)
	inventory.call("add", "stone", 100)
	var walls_before := _wall_nodes(world).size()

	# `menu_cancel` is both `open_action` and `close_action` (menu.json) --
	# opens the pause menu when it is shut, same idiom every other check in
	# this file uses before calling `_open_build_menu_from_pause()`.
	if not bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 10:
			await physics_frame

	_game.set("pending_build", "wall")
	for i in 15:
		await physics_frame

	var menu := await _open_build_menu_from_pause()
	if menu == null:
		return
	if not bool(menu.call("is_open")):
		_fail("reopening the build tab with a piece already armed did not open the build menu")
		return
	if str(_game.get("pending_build")) != "wall":
		_fail("reopening the build menu disarmed the piece that was already up -- this check proves nothing")
		return

	Input.action_press(BUILD_PLACER.PLACE_ACTION)
	await physics_frame
	await physics_frame
	Input.action_release(BUILD_PLACER.PLACE_ACTION)
	for i in 10:
		await physics_frame
	if _wall_nodes(world).size() != walls_before:
		_fail("build_place planted a wall while the build menu was open on top of the armed ghost")
	elif str(_game.get("pending_build")) != "wall":
		_fail("build_place behind an open menu changed pending_build instead of doing nothing")
	else:
		print("build_place did nothing while the build menu was reopened over an armed ghost")

	# `_close_build_menu_and_restore_pause` reopens the PAUSE menu on purpose
	# (its own comment: other checks in this file assume it stays open) --
	# which pauses the tree and would stop `build_placer.gd` running at all,
	# a false "the gate never releases" if left that way. Close it too.
	await _close_build_menu_and_restore_pause(menu)
	if bool(_menu.call("is_open")):
		await _press("menu_cancel")
	for i in 10:
		await physics_frame

	# Off the two walls the rotation/snap check above planted, onto open
	# meadow, so a legal spot for the ghost is not left to chance.
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player != null:
		player.global_position += _forward(world, player) * 15.0
		player.velocity = Vector3.ZERO
		for i in 20:
			await physics_frame

	Input.action_press(BUILD_PLACER.PLACE_ACTION)
	await physics_frame
	await physics_frame
	Input.action_release(BUILD_PLACER.PLACE_ACTION)
	for i in 20:
		await physics_frame
	if _wall_nodes(world).size() != walls_before + 1:
		_fail("build_place still did nothing once the build menu closed -- the gate never releases")
	else:
		print("build_place works again once the build menu is closed")
	_game.set("pending_build", "")


## RG4 (owner: "The builds even with free build on won't place. Except a
## workbench."). Real placement (grid/slope/cost/mesh) turned out to be fine
## end to end -- proven at nine different points in the world, every
## `buildables.json` id, all landing clean, in the investigation this check
## comes from. The one way `build_place` silently does nothing with a fully
## legal (green) ghost and zero explanation is exactly the shape the check
## above already covers for a REOPENED build menu -- but `input_owner.gd`'s
## group holds more than that one panel. A real story conversation (nothing
## to do with building at all) owns input the same way, and until this fix
## a press swallowed there gave no signal whatsoever: no cue, no message,
## nothing -- which is indistinguishable from "the build system is broken",
## the owner's exact words. This proves both halves: the press is genuinely
## refused while ANY input-owning panel is up, not just the build menu, and
## placement recovers completely once it closes -- nothing about this class
## of gate is one-way.
func _check_build_place_is_gated_behind_a_story_dialogue_and_recovers(world: Node) -> void:
	var inventory: RefCounted = _game.get("inventory")
	inventory.call("add", "wood", 100)
	inventory.call("add", "stone", 100)
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		_fail("no player to place from")
		return

	if bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 10:
			await physics_frame

	var placer := world.get_node_or_null(^"BuildPlacer")
	var walls_before := _wall_nodes(world).size()
	_game.set("pending_build", "wall")
	for i in 15:
		await physics_frame
	if str(_game.get("pending_build")) != "wall":
		_fail("arming a wall failed before the dialogue was even involved")
		return

	# Every earlier check in this file has already littered camp/walls/door/
	# workbench around spawn, and `world_perimeter_corridor` can reset the
	# player back to spawn if a previous check's own movement carried them
	# off the corridor -- so "clear ground" is not a fixed offset here. Walk
	# forward until the ghost itself says the spot is legal, the same signal
	# the player has (green vs red), rather than assuming any one distance
	# is clear.
	var found_clear := false
	for step in 12:
		player.velocity = Vector3.ZERO
		for i in 10:
			await physics_frame
		if placer != null and bool(placer.get("_ghost_ok")):
			found_clear = true
			break
		player.global_position += _forward(world, player) * 8.0
		for i in 10:
			await physics_frame
	if not found_clear:
		_fail("story dialogue: could not find clear ground to place a wall on after 12 steps outward")
		_game.set("pending_build", "")
		return

	var panel: Node = world.get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		_fail("story dialogue: no dialogue_panel in the world; cannot reproduce RG4 this way")
		_game.set("pending_build", "")
		return
	if not bool(panel.call("start", "village_mira_shop_intro")):
		_fail("story dialogue: 'village_mira_shop_intro' would not start; data/dialogue/village.json may have moved")
		_game.set("pending_build", "")
		return
	for i in 5:
		await physics_frame
	if not bool(panel.call("is_open")):
		_fail("story dialogue: starting a real conversation did not open the dialogue panel")
		_game.set("pending_build", "")
		return

	# The ghost still tracks the aim point (build_placer.gd's own contract --
	# the world must not visibly freeze just because a panel sits on top of
	# it), so this reads the SAME legal ghost the owner would have seen: green,
	# no refusal reason, and yet the press below plants nothing.
	if placer != null and not bool(placer.get("_ghost_ok")):
		_fail("story dialogue: the ghost reads illegal on clear, affordable ground -- this check proves nothing about the gate")

	Input.action_press(BUILD_PLACER.PLACE_ACTION)
	await physics_frame
	await physics_frame
	Input.action_release(BUILD_PLACER.PLACE_ACTION)
	for i in 10:
		await physics_frame
	if _wall_nodes(world).size() != walls_before:
		_fail("build_place planted a wall while a real story conversation owned input")
	elif str(_game.get("pending_build")) != "wall":
		_fail("build_place behind an open story dialogue changed pending_build instead of doing nothing")
	else:
		print("build_place did nothing while a real story conversation owned input, ghost stayed legal throughout")

	# Advance through every line with a real `interact` press, same as a
	# player would, until the box closes on its own.
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
		_fail("story dialogue: pressing interact %d times never closed it" % guard)
		_game.set("pending_build", "")
		return
	for i in 10:
		await physics_frame

	# `village_mira_shop_intro`'s last line carries a real `shop:goods:mira`
	# effect (data/dialogue/village.json) -- closing the dialogue box hands
	# straight off to her shop panel, `sequence_director.gd::_maybe_open_shop`.
	# That is correct, ordinary game behaviour, not a second bug, but this
	# check is about the GATE, not about Mira's shop specifically -- so close
	# whatever `input_owner.gd` says owns input now, the same way a player
	# would leave the shop before going back to building.
	var chained: Node = INPUT_OWNER.current(world.get_tree())
	if chained != null and chained.has_method("close"):
		chained.call("close")
		for i in 10:
			await physics_frame
	if INPUT_OWNER.current(world.get_tree()) != null:
		_fail("story dialogue: '%s' still owns input after closing the dialogue and the panel it chained into"
			% INPUT_OWNER.current(world.get_tree()).name)
		_game.set("pending_build", "")
		return
	if world.get_tree().paused:
		_fail("story dialogue: the tree is still paused after closing the dialogue and the panel it chained into")
		_game.set("pending_build", "")
		return
	if placer != null and not bool(placer.get("_ghost_ok")):
		_fail("story dialogue: ghost reads illegal for the retry ('%s') -- not the gate, the spot moved under it"
			% str(placer.get("_ghost_reason")))
		_game.set("pending_build", "")
		return

	Input.action_press(BUILD_PLACER.PLACE_ACTION)
	await physics_frame
	await physics_frame
	Input.action_release(BUILD_PLACER.PLACE_ACTION)
	for i in 20:
		await physics_frame
	if _wall_nodes(world).size() != walls_before + 1:
		_fail("build_place still did nothing once the story dialogue closed -- the gate never releases")
	else:
		print("build_place works again once the story dialogue closed -- the gate is not one-way")
	_game.set("pending_build", "")


## Minimal stand-in for the duck-typed provider contract
## `interaction_arbiter.gd`'s own header documents (`interaction_offer`/
## `interaction_activate`), used below instead of a real harvest node so that
## check does not depend on how much an earlier check in this same run has
## already gathered/depleted. Priority 999 guarantees it wins arbitration
## over anything else genuinely nearby.
class _FakeInteractable:
	var activated_count := 0
	func interaction_offer(_from: Vector3) -> Dictionary:
		return {"label": "Test", "distance": 0.1, "priority": 999, "actionable": true}
	func interaction_activate() -> void:
		activated_count += 1


## UI-PAD2. `interaction_arbiter.gd` already refuses `interact` during a
## conversation/naming/fade (`_enabled`, set by `sequence_director.gd`), but
## that flag has nothing to do with `build_menu.gd` -- the one panel that
## deliberately does not pause the tree. Without the same `input_owner.gd`
## gate `build_placer.gd` above needed, pressing interact while browsing the
## build catalog could still activate whatever real-world interactable the
## player happened to be standing near, invisibly, since the player's
## attention and the screen are both on the menu.
func _check_interact_is_gated_behind_an_open_build_menu() -> void:
	var arbiter: Node = get_first_node_in_group("interaction_arbiter")
	if arbiter == null:
		_fail("no interaction arbiter in the world; cannot test the gate")
		return
	var provider := _FakeInteractable.new()
	arbiter.call("register", provider)

	if not bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 10:
			await physics_frame
	var menu := await _open_build_menu_from_pause()
	if menu == null:
		arbiter.call("unregister", provider)
		return
	for i in 10:
		await physics_frame

	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 10:
		await physics_frame
	if provider.activated_count != 0:
		_fail("pressing interact activated a world interactable while the build menu was open")
	else:
		print("interact did nothing while the build menu was open")

	# Same caveat as the build-actions check above: this reopens the PAUSE
	# menu on purpose (other checks in this file assume it stays open), which
	# would stop `interaction_arbiter.gd` running at all and read as a false
	# "gate never releases". Close it too.
	await _close_build_menu_and_restore_pause(menu)
	if bool(_menu.call("is_open")):
		await _press("menu_cancel")
	for i in 10:
		await physics_frame

	Input.action_press("interact")
	await physics_frame
	await physics_frame
	Input.action_release("interact")
	for i in 10:
		await physics_frame
	if provider.activated_count != 1:
		_fail("interact still did nothing once the build menu closed (count %d) -- the gate never releases"
			% provider.activated_count)
	else:
		print("interact works again once the build menu is closed")

	arbiter.call("unregister", provider)


## RG5 (owner playtest, 2026-08-18): "when the building menu is up, pressing
## directions and pressing a still controls the character too as the menu."
## `player_controller.gd` polled movement and jump unconditionally -- the one
## world-verb poll that had never asked `input_owner.gd` this question, even
## though `jump` and the build menu's own `ui_accept` (picking a piece) are
## bound to the SAME physical button (project.godot: joypad button 0), so
## confirming a pick also jumped the trainer. Proven with a real jump-height
## measurement (`tests/smoke_input.gd`'s own pattern: hold, then track the
## peak Y over the next several frames), not just a one-frame velocity read,
## since a residual velocity is not what the owner described.
func _check_movement_and_jump_are_gated_behind_an_open_build_menu(world: Node) -> void:
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	if player == null:
		_fail("no player in the world; cannot test the movement/jump gate")
		return
	_game.set("pending_build", "")
	# Open ground, clear of anything an earlier check in this file planted.
	player.global_position += _forward(world, player) * 15.0
	player.velocity = Vector3.ZERO
	for i in 20:
		await physics_frame

	if not bool(_menu.call("is_open")):
		await _press("menu_cancel")
		for i in 10:
			await physics_frame
	var menu := await _open_build_menu_from_pause()
	if menu == null:
		return

	var start := player.global_position
	var height_before := player.global_position.y
	var peak := height_before
	Input.action_press("move_forward")
	Input.action_press("jump")
	for i in 40:
		await physics_frame
		peak = maxf(peak, player.global_position.y)
	Input.action_release("move_forward")
	Input.action_release("jump")
	for i in 5:
		await physics_frame

	var drifted := Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
	if drifted > 0.2:
		_fail("holding move_forward moved the player %.2fm while the build menu was open" % drifted)
	else:
		print("movement did nothing while the build menu was open (%.2fm drift)" % drifted)
	if peak - height_before > 0.15:
		_fail("holding jump rose the player %.2fm while the build menu was open" % (peak - height_before))
	else:
		print("jump did nothing while the build menu was open (%.2fm rise)" % (peak - height_before))

	await _close_build_menu_and_restore_pause(menu)
	if bool(_menu.call("is_open")):
		await _press("menu_cancel")
	for i in 10:
		await physics_frame

	start = player.global_position
	player.velocity = Vector3.ZERO
	Input.action_press("move_forward")
	for i in 20:
		await physics_frame
	Input.action_release("move_forward")
	for i in 5:
		await physics_frame
	drifted = Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
	if drifted < 0.3:
		_fail("movement still does nothing once the build menu closed (%.2fm drift) -- the gate never releases" % drifted)
	else:
		print("movement works again once the build menu is closed (%.2fm drift)" % drifted)


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
	var menu := await _open_build_menu_and_pick_first(false)
	if menu == null:
		return

	if str(_game.get("pending_build")).is_empty():
		_fail("a piece could not be built with an empty satchel while free build was on")
		return
	print("'%s' was armed out of an empty satchel: '%s'" % [_game.get("pending_build"), _status()])
	# The real handoff is now placement mode, where B belongs to build_cancel;
	# the pause shell correctly yields until that ghost is cleared. The old
	# helper tried to reopen pause while still armed, reproducing RG1's severe
	# freeze by construction. Cancel through the shared physical B, then open a
	# fresh pause edge for the following settings check.
	await _tap_pad(_pad_button_for("build_cancel"))
	for i in 8:
		await process_frame
	if not str(_game.get("pending_build")).is_empty() or bool(_menu.call("is_open")):
		_fail("B did not leave placement cleanly before returning to Settings")
		return
	await _press("menu_cancel")
	for i in 4:
		await process_frame


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
func _open_build_menu_and_pick_first(restore_pause: bool = true) -> Node:
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
	if restore_pause:
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
