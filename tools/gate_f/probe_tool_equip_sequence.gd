extends SceneTree

## T2-BUILDPLACE. Determines the exact live `backpack_assign`/`hotbar_N`
## step recipe S03.json needs to reliably equip axe/pickaxe/knife before
## gathering -- the fix this session's finding
## (`FINDING-T2-BUILDPLACE-2026-08-30.md`) says is missing. Seeded from the
## REAL `S02-exit.json` (this run's own opening-gift inventory: orb_basic,
## potion_small, berries, revive, hotbar `["orb_basic","","","",""]`) so the
## slot arithmetic matches what S03 itself actually starts from, not a
## synthetic inventory that happens to autofill differently.
##
## Also closes the loop end to end: after binding and equipping, actually
## gathers one wood/stone/fiber node each and confirms the satchel receives
## the real amount (not the zero a bare-handed or wrong-tool gather returns,
## per harvest_logic.gd / tests/test_harvest.gd).
##
##   godot --headless --path . --script tools/gate_f/probe_tool_equip_sequence.gd

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const REAL_S02_EXIT := "res://ralph/reports/gate-f-run-20260828T183531Z/S02/saves/S02-exit.json"
const SETTLE_FRAMES := 300

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
	var save := SAVE_GAME.new()
	var slot_dst := save.slot_path(4)
	DirAccess.make_dir_recursive_absolute(slot_dst.get_base_dir())
	var bytes := FileAccess.get_file_as_bytes(REAL_S02_EXIT)
	var out := FileAccess.open(slot_dst, FileAccess.WRITE)
	out.store_buffer(bytes)
	out.close()

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	save.load_slot(_game, 4)
	for i in 60:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	if _game == null or _player == null:
		print("PROBE FAIL: Meadows did not stand up Game and Player")
		quit(1)
		return
	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")

	var inventory: RefCounted = _game.get("inventory")
	print("--- real S02-exit starting state ---")
	print("  inventory: %s" % str(_nonempty_stacks(inventory)))
	print("  hotbar: %s" % str(_game.get("hotbar")))

	# --- Tam's real gift (village.json:181), then Mira's (village.json:29-39) ---
	inventory.call("add", "knife", 1)
	inventory.call("add", "torch", 1)
	inventory.call("add", "axe", 1)
	inventory.call("add", "pickaxe", 1)
	inventory.call("add", "coin", 30)
	for i in 10:
		await physics_frame
	print("")
	print("--- after Tam + Mira's real gifts land ---")
	print("  inventory: %s" % str(_nonempty_stacks(inventory)))
	print("  hotbar (may have auto-filled once already, not again): %s" % str(_game.get("hotbar")))

	# --- open the real Satchel tab through the real pause-shell path,
	# exactly the way S03.json itself opens the shell (deterministic `map`
	# shortcut, then cycle -- S03-121's own recorded observation) ---
	await _tap("map")
	for i in 10:
		await physics_frame
	print("shell opened via map, context=%s" % _probe_input_context())
	for i in 2:
		await _tap("menu_tab_left")
	for i in 10:
		await physics_frame
	print("after 2x menu_tab_left, context=%s" % _probe_input_context())
	if _probe_input_context() != "menu_backpack":
		_fail("expected menu_backpack after map + 2x menu_tab_left, got %s" % _probe_input_context())

	# --- knife -> hotbar_4 (4 presses), pickaxe -> hotbar_3 (3 presses),
	# axe -> hotbar_2 (2 presses), in that order (highest target slot first)
	# so an earlier item's own slot never gets clobbered by a later one's
	# press-1-always-lands-at-slot-0 cycle start. ---
	var knife_slot := int(inventory.call("find_slot", "knife"))
	var pick_slot := int(inventory.call("find_slot", "pickaxe"))
	var axe_slot := int(inventory.call("find_slot", "axe"))
	print("real slots: knife=%d pickaxe=%d axe=%d" % [knife_slot, pick_slot, axe_slot])

	await _focus_to_slot(knife_slot)
	for p in 4:
		await _tap("backpack_assign")
	for i in 10:
		await physics_frame
	print("hotbar after focusing knife + 4x backpack_assign: %s" % str(_game.get("hotbar")))

	await _focus_to_slot(pick_slot)
	for p in 3:
		await _tap("backpack_assign")
	for i in 10:
		await physics_frame
	print("hotbar after focusing pickaxe + 3x backpack_assign: %s" % str(_game.get("hotbar")))

	await _focus_to_slot(axe_slot)
	for p in 2:
		await _tap("backpack_assign")
	for i in 10:
		await physics_frame
	var hotbar: Array = _game.get("hotbar") as Array
	print("FINAL hotbar: %s" % str(hotbar))

	if str(hotbar[1]) != "axe":
		_fail("expected hotbar slot 2 (index 1, hotbar_2) to be 'axe', got '%s'" % str(hotbar[1]))
	if str(hotbar[2]) != "pickaxe":
		_fail("expected hotbar slot 3 (index 2, hotbar_3) to be 'pickaxe', got '%s'" % str(hotbar[2]))
	if str(hotbar[3]) != "knife":
		_fail("expected hotbar slot 4 (index 3, hotbar_4) to be 'knife', got '%s'" % str(hotbar[3]))

	await _tap("menu_cancel")
	for i in 10:
		await physics_frame
	print("context after closing shell: %s" % _probe_input_context())

	# --- equip axe (hotbar_2), gather real wood; equip pickaxe (hotbar_3),
	# gather real stone; equip knife (hotbar_4), gather real fiber ---
	print("")
	print("=== end-to-end: equip + gather each resource for real ===")
	var wood_before := int(inventory.call("count", "wood"))
	await _tap("hotbar_2")
	for i in 10:
		await physics_frame
	print("equipped_tool after hotbar_2: %s" % str(_game.get("equipped_tool")))
	_gather_nearest("wood")
	for i in 20:
		await physics_frame
	await _work_node()
	var wood_after := int(inventory.call("count", "wood"))
	print("wood: %d -> %d" % [wood_before, wood_after])
	if wood_after <= wood_before:
		_fail("equipping axe (hotbar_2) and gathering a wood node still yielded nothing")

	var stone_before := int(inventory.call("count", "stone"))
	await _tap("hotbar_3")
	for i in 10:
		await physics_frame
	print("equipped_tool after hotbar_3: %s" % str(_game.get("equipped_tool")))
	_gather_nearest("stone")
	for i in 20:
		await physics_frame
	await _work_node()
	var stone_after := int(inventory.call("count", "stone"))
	print("stone: %d -> %d" % [stone_before, stone_after])
	if stone_after <= stone_before:
		_fail("equipping pickaxe (hotbar_3) and gathering a stone node still yielded nothing")

	var fiber_before := int(inventory.call("count", "fiber"))
	await _tap("hotbar_4")
	for i in 10:
		await physics_frame
	print("equipped_tool after hotbar_4: %s" % str(_game.get("equipped_tool")))
	_gather_nearest("fiber")
	for i in 20:
		await physics_frame
	await _work_node()
	var fiber_after := int(inventory.call("count", "fiber"))
	print("fiber: %d -> %d" % [fiber_before, fiber_after])
	if fiber_after <= fiber_before:
		_fail("equipping knife (hotbar_4) and gathering a fiber node still yielded nothing")

	print("")
	if _failures.is_empty():
		print("PROBE PASS: from the real S02-exit starting inventory, knife(x4)/pickaxe(x3)/axe(x2) " +
			"backpack_assign presses (in that order, after focusing each item's own satchel slot) " +
			"land axe/pickaxe/knife on hotbar_2/3/4 respectively, and equipping each before gathering " +
			"the matching resource yields the real amount.")
		quit(0)
	else:
		print("PROBE FOUND PROBLEMS (%d):" % _failures.size())
		for line in _failures:
			print("  - %s" % line)
		quit(1)


func _nonempty_stacks(inventory: RefCounted) -> Array:
	var out: Array = []
	for i in int(inventory.get("SLOT_COUNT")):
		var stack: Dictionary = inventory.call("stack_at", i)
		if not stack.is_empty():
			out.append("%d:%s x%d" % [i, str(stack.get("id", "")), int(stack.get("n", 0))])
	return out


## Drives the REAL production path: walk to the nearest live node of
## `item_id`, then press `interact` the way a controller player does --
## repeatedly, with settle frames, matching X02.json's own proven
## "swing the axe at a tree... times: 6, settle_frames: 30" shape. A tool
## equipped via the hotbar makes the prompt press start a real swing
## (harvest_logic.gd::swing_answers_the_prompt), which resolves later
## through tool_hold.gd, not on the pressing frame -- calling `gather()`
## directly (as this probe's first pass did) skips that animation and
## reports a false zero.
func _gather_nearest(item_id: String) -> void:
	var best: Node3D = null
	var best_d := INF
	for node in get_nodes_in_group("harvestable"):
		if not node.has_method("resource_item") or str(node.call("resource_item")) != item_id:
			continue
		if node is Node3D and _player != null:
			var d: float = _player.global_position.distance_to((node as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = node as Node3D
	if best == null:
		_fail("no live harvestable node for '%s' found anywhere" % item_id)
		return
	_player.global_position = best.global_position + Vector3(0.0, 0.2, 1.5)
	_player.velocity = Vector3.ZERO


func _work_node() -> void:
	for i in 6:
		await _tap("interact")
		for j in 30:
			await physics_frame


var _focus_slot := 0


func _focus_to_slot(target_slot: int) -> void:
	# The grid opens focused on slot 0; walk in raster order (6 columns,
	# data/config/menu.json), the same navigation a controller player uses.
	# Relative to whatever slot focus is ACTUALLY on right now, not always
	# from slot 0 -- focus does not reset between calls.
	var cur_row := _focus_slot / 6
	var cur_col := _focus_slot % 6
	var row := target_slot / 6
	var col := target_slot % 6
	while cur_col < col:
		await _tap("ui_right")
		cur_col += 1
	while cur_col > col:
		await _tap("ui_left")
		cur_col -= 1
	while cur_row < row:
		await _tap("ui_down")
		cur_row += 1
	while cur_row > row:
		await _tap("ui_up")
		cur_row -= 1
	_focus_slot = target_slot
	for i in 5:
		await physics_frame


const GATE_F_PROBE := preload("res://scripts/debug/gate_f_probe.gd")
var _ctx_probe: RefCounted = null


func _probe_input_context() -> String:
	if _ctx_probe == null:
		_ctx_probe = GATE_F_PROBE.new(self)
	return str(_ctx_probe.call("input_context"))


func _tap(action: String) -> void:
	var down := _joy_event_for(action, true)
	if down == null:
		_fail("InputMap action '%s' has no joypad button or axis" % action)
		return
	Input.parse_input_event(down)
	for i in 2:
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
