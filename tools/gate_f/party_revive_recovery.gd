extends RefCounted

## Callback ceilings follow operator _inject(1), open_menu, focus_item with
## max_moves=12, and close_menu with max_attempts=3/max_settle_frames=12.
## All callbacks return {ok,why}; they inject physical controls, never mutate
## party/inventory. Reserved costs are conservative bounds, not elapsed time.
const OPEN_PHYSICS := 2
const OPEN_PROCESS := 44
const FOCUS_MAX_MOVES := 12
const FOCUS_PHYSICS := 24
const FOCUS_PROCESS := 60
const PRESS_PHYSICS := 2
const PRESS_PROCESS := 2
const CLOSE_PHYSICS := 18
const CLOSE_PROCESS := 18
const MAX_PICKER_MOVES := 4
const PER_CREATURE_PHYSICS := OPEN_PHYSICS + FOCUS_PHYSICS + 6 * PRESS_PHYSICS + CLOSE_PHYSICS
const PER_CREATURE_PROCESS := OPEN_PROCESS + FOCUS_PROCESS + 6 * PRESS_PROCESS + CLOSE_PROCESS
const MAX_PHYSICS := 5 * PER_CREATURE_PHYSICS
const MAX_PROCESS := 5 * PER_CREATURE_PROCESS


## Only observes the actual Satchel controls. Target buttons are bound to
## party.at(row) in production; focus identity comes from that exact button,
## never its label (several earned creatures may have the same name).
static func snapshot(game: Node, tab: Node, context: String, owner: Node) -> Dictionary:
	var party: RefCounted = game.get("party") if is_instance_valid(game) else null
	var inventory: RefCounted = game.get("inventory") if is_instance_valid(game) else null
	var count := 0
	if inventory != null:
		for slot in int(inventory.call("slot_count")):
			var stack: Dictionary = inventory.call("stack_at", slot)
			if str(stack.get("id", "")) == "revive": count += int(stack.get("n", 0))
	var state := {"party": party, "revives": count, "context": context,
		"menu_owned": false, "grid_item": "", "picker_item": "", "focused_creature": null}
	if not is_instance_valid(tab) or not tab is Control or not tab.is_visible_in_tree(): return state
	var menu: Node = tab.get("menu")
	state.menu_owned = menu != null and owner == menu and bool(menu.call("is_open"))
	if not state.menu_owned or inventory == null or party == null: return state
	var focus: Control = tab.get_viewport().gui_get_focus_owner()
	var buttons: Array = tab.get("_buttons")
	var grid_slot := buttons.find(focus)
	if grid_slot >= 0 and int(tab.get("_held")) < 0 and int(tab.get("_confirming")) < 0:
		state.grid_item = str((inventory.call("stack_at", grid_slot) as Dictionary).get("id", ""))
	var targeting := int(tab.get("_targeting"))
	if targeting >= 0 and float(tab.get("_targeting_revive")) > 0.0:
		state.picker_item = str((inventory.call("stack_at", targeting) as Dictionary).get("id", ""))
		var rows: Array = tab.get("_target_rows")
		var row := rows.find(focus)
		if row >= 0 and row < int(party.call("size")) and focus is Button and not focus.disabled:
			state.focused_creature = party.call("at", row)
	return state


static func execute(read_state: Callable, driver: Dictionary,
		budget_frames: int = MAX_PHYSICS, interrupted: Callable = Callable()) -> Dictionary:
	var result := {"ok": false, "why": "", "revived": 0, "reserved_physics_frames": 0, "reserved_process_frames": 0}
	var initial: Dictionary = read_state.call()
	var party: RefCounted = initial.get("party")
	if party == null or int(party.call("size")) < 1 or int(party.call("size")) > 5:
		return _fail(result, "no valid earned party")
	var members: Array = []
	var targets: Array = []
	for row in int(party.call("size")):
		var member: RefCounted = party.call("at", row)
		if member == null: return _fail(result, "empty party member")
		members.append(member)
		if bool(member.get("fainted")): targets.append(member)
		elif float(member.get("hp")) <= 0.0: return _fail(result, "inconsistent living HP")
	if str(initial.get("context", "")) != "world": return _fail(result, "recovery requires world input")
	if targets.is_empty():
		result.ok = true
		return result
	if int(initial.get("revives", 0)) < targets.size(): return _fail(result, "not enough owned Revives for fainted team")
	for name: String in ["open_satchel", "focus_revive", "press", "close_satchel"]:
		if not driver.get(name, Callable()).is_valid(): return _fail(result, "missing physical callback " + name)
	for target: RefCounted in targets:
		if interrupted.is_valid() and bool(interrupted.call()): return _fail(result, "recovery interrupted by cost gate")
		if result.reserved_physics_frames + PER_CREATURE_PHYSICS > clampi(budget_frames, 0, MAX_PHYSICS):
			return _fail(result, "recovery budget cannot reserve a complete paid revive")
		var state: Dictionary = read_state.call()
		if not _same_party(state, party, members) or not bool(target.get("fainted")):
			return _fail(result, "earned party or fainted target changed")
		var stock := int(state.get("revives", 0))
		var health: Array = []
		for member: RefCounted in members: health.append([member.get("hp"), member.get("fainted")])
		if not await _invoke(driver.open_satchel, [], OPEN_PHYSICS, OPEN_PROCESS, result, interrupted): return result
		if not await _invoke(driver.focus_revive, [], FOCUS_PHYSICS, FOCUS_PROCESS, result, interrupted): return result
		state = read_state.call()
		if not _valid_menu(state, party, members) or state.get("grid_item") != "revive" or int(state.get("revives", -1)) != stock:
			return _fail(result, "owned Revive is not on actual Satchel grid focus")
		if not await _invoke(driver.press, ["interact"], PRESS_PHYSICS, PRESS_PROCESS, result, interrupted): return result
		var found := false
		for move in range(MAX_PICKER_MOVES + 1):
			state = read_state.call()
			if not _valid_menu(state, party, members) or state.get("picker_item") != "revive" or int(state.get("revives", -1)) != stock:
				return _fail(result, "physical Use did not retain the unpaid Revive picker")
			if state.get("focused_creature") == target:
				found = true
				break
			if move < MAX_PICKER_MOVES and not await _invoke(driver.press, ["ui_down"], PRESS_PHYSICS, PRESS_PROCESS, result, interrupted): return result
		if not found: return _fail(result, "Revive picker did not focus the intended creature identity")
		if not await _invoke(driver.press, ["ui_accept"], PRESS_PHYSICS, PRESS_PROCESS, result, interrupted): return result
		state = read_state.call()
		if not _same_party(state, party, members) or int(state.get("revives", -1)) != stock - 1 \
				or bool(target.get("fainted")) or float(target.get("hp")) <= 0.0:
			return _fail(result, "paid revive did not recover the same creature with exactly one item")
		for index in members.size():
			if members[index] != target and [members[index].get("hp"), members[index].get("fainted")] != health[index]:
				return _fail(result, "revive changed another party member")
		result.revived += 1
		if not await _invoke(driver.close_satchel, [], CLOSE_PHYSICS, CLOSE_PROCESS, result, interrupted): return result
		state = read_state.call()
		if str(state.get("context", "")) != "world" or not _same_party(state, party, members):
			return _fail(result, "recovery did not return unchanged party to world input")
	var final: Dictionary = read_state.call()
	if int(final.get("revives", -1)) != int(initial.get("revives", 0)) - targets.size():
		return _fail(result, "final Revive balance differs from the paid recoveries")
	for member: RefCounted in members:
		if bool(member.get("fainted")) or float(member.get("hp")) <= 0.0:
			return _fail(result, "team is not alive after physical recovery")
	result.ok = true
	return result


static func _invoke(callback: Callable, args: Array, physics: int, process: int,
		result: Dictionary, interrupted: Callable) -> bool:
	if interrupted.is_valid() and bool(interrupted.call()):
		result.why = "recovery interrupted by cost gate"
		return false
	result.reserved_physics_frames += physics
	result.reserved_process_frames += process
	var response: Dictionary = await callback.callv(args)
	if not bool(response.get("ok", false)):
		result.why = "physical recovery callback refused: " + str(response.get("why", ""))
		return false
	return true


static func _same_party(state: Dictionary, party: RefCounted, members: Array) -> bool:
	if state.get("party") != party or int(party.call("size")) != members.size(): return false
	for row in members.size():
		if party.call("at", row) != members[row]: return false
	return true


static func _valid_menu(state: Dictionary, party: RefCounted, members: Array) -> bool:
	return _same_party(state, party, members) and bool(state.get("menu_owned", false)) \
		and str(state.get("context", "")) == "menu_backpack"


static func _fail(result: Dictionary, why: String) -> Dictionary:
	result.why = why
	return result
