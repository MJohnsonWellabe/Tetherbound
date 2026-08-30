extends SceneTree

## T2-GATEF-RUN5: GAME-9 / RIG-24, root cause and fix, in one stand-up.
##
## `probe_tool_equip_sequence.gd` (T2-BUILDPLACE) PASSes the tool-equip recipe
## and `S03.json` running the "same" recipe FAILs. The two are not the same
## recipe, and that is the whole finding: the probe calls
## `inventory.find_slot("knife")` and drives focus to the slot the knife is
## ACTUALLY in, while S03 pressed `ui_right` a hardcoded four times, counting
## cells along the order a FRESH `S02-exit.json` happens to fill the bag in.
##
## Those two agree only while the bag is untouched. By the time S03 binds its
## tools it has spent both Revive draughts on two live revives and two of three
## potions -- run 4's own telemetry
## (`ralph/reports/gate-f-run4-s03-validation-2/S03/telemetry/events.jsonl`,
## the `gather` event before the assign block) records the bag as
## `{axe, berries:5, coin:30, knife, orb_basic:15, pickaxe, potion_small:1,
## torch}`, with `revive` gone. Every count then lands on the wrong cell, in
## silence, every step reporting PASS, and the six real gathers that follow all
## carry the same wrong tool.
##
## This probe rebuilds that exact depleted bag and runs BOTH addressing schemes
## against it:
##
##   A. the counting scheme S03 shipped (4 right, 3 left, 1 left) -- reports
##      which items it actually lands on, and what that leaves on the hotbar;
##   B. `focus_item`'s scheme -- `gate_f_probe.gd::satchel_slot_of()` plus the
##      same one-press-at-a-time convergence `operator_harness.gd::
##      _step_focus_item()` runs, driving the same real ui_* events.
##
## B must leave axe/pickaxe/knife on hotbar 2/3/4. A is expected to fail, and
## is run first and reported rather than assumed, because "the old way was
## broken" is the claim this whole fix rests on.
##
##   godot --headless --path . --script tools/gate_f/probe_tool_equip_depleted_bag.gd

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const GATE_F_PROBE := preload("res://scripts/debug/gate_f_probe.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const REAL_S02_EXIT := "res://ralph/reports/gate-f-run-20260828T183531Z/S02/saves/S02-exit.json"
const SETTLE_FRAMES := 300

var _failures: Array[String] = []
var _world: Node
var _game: Node
var _probe: RefCounted = null


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _run() -> void:
	var save := SAVE_GAME.new()
	var slot_dst := save.slot_path(4)
	DirAccess.make_dir_recursive_absolute(slot_dst.get_base_dir())
	var out := FileAccess.open(slot_dst, FileAccess.WRITE)
	out.store_buffer(FileAccess.get_file_as_bytes(REAL_S02_EXIT))
	out.close()

	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		print("PROBE FAIL: no Game autoload")
		quit(1)
		return
	save.load_slot(_game, 4)
	for i in 60:
		await physics_frame
	_probe = GATE_F_PROBE.new(self)
	var director := _world.find_child("SequenceDirector", true, false)
	if director != null and director.has_method("_set_beat"):
		director.call("_set_beat", "free_play")

	var inventory: RefCounted = _game.get("inventory")
	print("--- real S02-exit starting state ---")
	print("  %s" % str(_stacks(inventory)))

	# Tam's gift (village.json:181), then Mira's (village.json:29-39).
	for gift: Array in [["knife", 1], ["torch", 1], ["axe", 1], ["pickaxe", 1], ["coin", 30]]:
		inventory.call("add", str(gift[0]), int(gift[1]))
	# And the spend a real S03 has already done by this point. Both Revives and
	# two of three potions: run 4's own numbers, not an invented depletion.
	inventory.call("remove", "revive", 2)
	inventory.call("remove", "potion_small", 2)
	for i in 20:
		await physics_frame
	print("")
	print("--- the bag S03 actually meets (run 4's own, rebuilt) ---")
	print("  %s" % str(_stacks(inventory)))
	print("  snapshot: %s" % JSON.stringify(_probe.call("inventory_snapshot")))
	print("  hotbar: %s" % str(_game.get("hotbar")))

	await _open_satchel()

	await _scheme_a_counting()
	await _reset_hotbar()
	await _scheme_b_focus_item()

	print("")
	if _failures.is_empty():
		print("PROBE PASS: on the depleted bag, focus_item's slot-addressed scheme lands "
			+ "axe/pickaxe/knife on hotbar 2/3/4; the counting scheme S03 shipped does not.")
		quit(0)
		return
	print("PROBE FOUND PROBLEMS (%d):" % _failures.size())
	for line in _failures:
		print("  - %s" % line)
	quit(1)


# ------------------------------------------------------------------ scheme A


func _scheme_a_counting() -> void:
	print("")
	print("=== A. the counting scheme S03 shipped: 4 right (knife), 3 left (pickaxe), 1 left (axe) ===")
	await _walk(&"ui_right", 4)
	print("  after 4 x ui_right, cursor is on %s" % _where())
	for p in 4:
		await _tap("backpack_assign")
	await _walk(&"ui_left", 3)
	print("  after 3 x ui_left,  cursor is on %s" % _where())
	for p in 3:
		await _tap("backpack_assign")
	await _walk(&"ui_left", 1)
	print("  after 1 x ui_left,  cursor is on %s" % _where())
	for p in 2:
		await _tap("backpack_assign")
	for i in 10:
		await physics_frame
	var hotbar: Array = _game.get("hotbar") as Array
	print("  hotbar the counting scheme produces: %s" % str(hotbar))
	if _tools_bound(hotbar):
		_fail("the counting scheme bound the tools correctly on the DEPLETED bag, which "
			+ "contradicts run 4's evidence -- re-read this probe's depletion before trusting it")
	else:
		print("  as expected: NOT axe/pickaxe/knife on 2/3/4. This is GAME-9, reproduced.")


# ------------------------------------------------------------------ scheme B


func _scheme_b_focus_item() -> void:
	print("")
	print("=== B. focus_item: address the item, not the cell ===")
	for want: Array in [["knife", 4], ["pickaxe", 3], ["axe", 2]]:
		var item := str(want[0])
		if not await _focus_item(item):
			continue
		print("  cursor on %s" % _where())
		for p in int(want[1]):
			await _tap("backpack_assign")
		for i in 10:
			await physics_frame
	var hotbar: Array = _game.get("hotbar") as Array
	print("  FINAL hotbar: %s" % str(hotbar))
	if str(hotbar[1]) != "axe":
		_fail("hotbar slot 2 should be 'axe', is '%s'" % str(hotbar[1]))
	if str(hotbar[2]) != "pickaxe":
		_fail("hotbar slot 3 should be 'pickaxe', is '%s'" % str(hotbar[2]))
	if str(hotbar[3]) != "knife":
		_fail("hotbar slot 4 should be 'knife', is '%s'" % str(hotbar[3]))


## `operator_harness.gd::_step_focus_item()`'s convergence, driving the same
## real events through this probe's own tap. Kept in step with that function:
## if one changes shape the other has stopped testing it.
func _focus_item(item: String) -> bool:
	var target: int = int(_probe.call("satchel_slot_of", item))
	if target < 0:
		_fail("focus_item '%s': not in the bag at all" % item)
		return false
	var columns: int = int(_probe.call("satchel_columns"))
	if columns <= 0:
		_fail("focus_item '%s': the satchel grid reports no columns" % item)
		return false
	var moves := 0
	while moves < 60:
		var slot := int((_probe.call("satchel_focus") as Dictionary).get("slot", -1))
		if slot == target:
			return true
		var control := &""
		if slot % columns != target % columns:
			control = &"ui_right" if target % columns > slot % columns else &"ui_left"
		else:
			control = &"ui_down" if target / columns > slot / columns else &"ui_up"
		await _tap(control)
		moves += 1
		if int((_probe.call("satchel_focus") as Dictionary).get("slot", -1)) == slot:
			_fail("focus_item '%s': %s did not move the cursor off cell %d (wanted %d)"
				% [item, control, slot, target])
			return false
	_fail("focus_item '%s': 60 moves did not reach cell %d" % [item, target])
	return false


# ----------------------------------------------------------------- machinery


func _tools_bound(hotbar: Array) -> bool:
	return str(hotbar[1]) == "axe" and str(hotbar[2]) == "pickaxe" and str(hotbar[3]) == "knife"


## Unbind everything scheme A left behind, so scheme B is measured on its own.
## Through `game_state.gd`'s own store, not the UI: this is resetting the
## fixture between two experiments, not a gesture either scheme is being
## judged on.
func _reset_hotbar() -> void:
	var hotbar: Array = _game.get("hotbar") as Array
	for i in hotbar.size():
		hotbar[i] = ""
	_game.set("hotbar", hotbar)
	for i in 10:
		await physics_frame
	print("  (hotbar cleared between schemes: %s)" % str(_game.get("hotbar")))


func _where() -> String:
	var f: Dictionary = _probe.call("satchel_focus")
	return "cell %d holding '%s'" % [int(f.get("slot", -1)), str(f.get("item", ""))]


func _walk(control: StringName, times: int) -> void:
	for i in times:
		await _tap(control)


func _open_satchel() -> void:
	await _tap(&"map")
	for i in 10:
		await physics_frame
	for i in 2:
		await _tap(&"menu_tab_left")
	for i in 10:
		await physics_frame
	var context := str(_probe.call("input_context"))
	print("satchel opened, context=%s, cursor on %s" % [context, _where()])
	if context != "menu_backpack":
		_fail("expected menu_backpack after map + 2x menu_tab_left, got %s" % context)


func _stacks(inventory: RefCounted) -> Array:
	var out: Array = []
	for i in int(inventory.get("SLOT_COUNT")):
		var stack: Dictionary = inventory.call("stack_at", i)
		if not stack.is_empty():
			out.append("%d:%s x%d" % [i, str(stack.get("id", "")), int(stack.get("n", 0))])
	return out


func _tap(action: StringName) -> void:
	var down := _joy_event_for(action, true)
	if down != null:
		Input.parse_input_event(down)
	Input.action_press(action)
	await process_frame
	await process_frame
	var up := _joy_event_for(action, false)
	if up != null:
		Input.parse_input_event(up)
	Input.action_release(action)
	for i in 3:
		await process_frame


func _joy_event_for(action: StringName, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			var button := InputEventJoypadButton.new()
			button.button_index = (event as InputEventJoypadButton).button_index
			button.pressed = pressed
			return button
		if event is InputEventJoypadMotion:
			var motion := InputEventJoypadMotion.new()
			motion.axis = (event as InputEventJoypadMotion).axis
			motion.axis_value = (event as InputEventJoypadMotion).axis_value if pressed else 0.0
			return motion
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key := (event as InputEventKey).duplicate() as InputEventKey
			key.pressed = pressed
			return key
	return null
