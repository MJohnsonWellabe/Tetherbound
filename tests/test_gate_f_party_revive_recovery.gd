extends TestCase

const DRIVER := preload("res://tools/gate_f/party_revive_recovery.gd")

class Creature extends RefCounted:
	var hp := 0.0
	var fainted := true
	var name := "Same name"

class Roster extends RefCounted:
	var entries: Array = []
	func size() -> int: return entries.size()
	func at(row: int) -> RefCounted: return entries[row]

class Fixture extends RefCounted:
	var party := Roster.new()
	var stock := 5
	var context := "world"
	var grid := ""
	var picker := ""
	var focus: RefCounted
	var calls: Array = []
	var fault := ""
	var stopped := false
	func _init() -> void:
		for row in 5: party.entries.append(Creature.new())
	func read() -> Dictionary:
		return {"party": party, "revives": stock, "context": context,
			"menu_owned": context == "menu_backpack", "grid_item": grid,
			"picker_item": picker, "focused_creature": focus}
	func callbacks() -> Dictionary:
		return {"open_satchel": open, "focus_revive": focus_item, "press": press, "close_satchel": close}
	func open() -> Dictionary:
		calls.append("open")
		context = "menu_backpack"
		return {"ok": true}
	func focus_item() -> Dictionary:
		calls.append("focus")
		grid = "potion" if fault == "wrong_item" else "revive"
		return {"ok": true}
	func press(control: String) -> Dictionary:
		calls.append(control)
		if fault == "refuse": return {"ok": false, "why": "physical guard"}
		if control == "interact":
			picker = "potion" if fault == "wrong_picker" else "revive"
			# Intentionally select LAST eligible identity, testing dpad traversal
			# with indistinguishable names instead of assuming first row focus.
			for member in party.entries:
				if member.fainted: focus = member
		elif control == "ui_down":
			if fault != "stuck_focus":
				var current := party.entries.find(focus)
				for offset in range(1, 6):
					var candidate: RefCounted = party.entries[posmod(current + offset, 5)]
					if candidate.fainted:
						focus = candidate
						break
		elif control == "ui_accept":
			if fault != "no_spend": stock -= 2 if fault == "double_spend" else 1
			if fault != "no_heal":
				focus.hp = 50.0
				focus.fainted = false
			if fault == "other_hp": party.entries[4].hp = 11.0
			if fault == "reorder": party.entries.reverse()
			picker = ""
		return {"ok": true}
	func close() -> Dictionary:
		calls.append("close")
		context = "menu_backpack" if fault == "close_stuck" else "world"
		return {"ok": true}
	func interrupted() -> bool: return stopped
	func run(budget: int = DRIVER.MAX_PHYSICS) -> Dictionary:
		return await DRIVER.execute(read, callbacks(), budget, interrupted)


func test_paid_recovery_uses_actual_identity_despite_duplicate_names() -> void:
	var f := Fixture.new()
	var original := f.party.entries.duplicate()
	var result := await f.run()
	assert_true(result.ok, str(result.why))
	assert_eq(result.revived, 5)
	assert_eq(f.stock, 0)
	assert_eq(f.party.entries, original)
	assert_eq(f.context, "world")
	assert_true(result.reserved_physics_frames <= DRIVER.MAX_PHYSICS)
	assert_true(result.reserved_process_frames <= DRIVER.MAX_PROCESS)
	for member in original:
		assert_false(member.fainted)
		assert_eq(member.hp, 50.0)


func test_healthy_team_uses_no_input_even_without_revives() -> void:
	var f := Fixture.new()
	f.stock = 0
	for member in f.party.entries:
		member.fainted = false
		member.hp = 12.0
	var result := await f.run()
	assert_true(result.ok)
	assert_eq(f.calls, [])
	assert_eq(result.reserved_physics_frames, 0)


func test_insufficient_stock_and_budget_refuse_before_any_input() -> void:
	var f := Fixture.new()
	f.stock = 4
	assert_false((await f.run()).ok)
	assert_eq(f.calls, [])
	f.stock = 5
	assert_false((await f.run(DRIVER.PER_CREATURE_PHYSICS - 1)).ok)
	assert_eq(f.calls, [])


func test_wrong_grid_or_picker_never_confirms() -> void:
	for fault in ["wrong_item", "wrong_picker", "stuck_focus", "refuse"]:
		var f := Fixture.new()
		f.fault = fault
		var result := await f.run()
		assert_false(result.ok, fault)
		assert_false(f.calls.has("ui_accept"), fault)
		assert_eq(f.stock, 5)
		assert_true(f.calls.count("ui_down") <= 4)


func test_requires_exact_payment_recovery_and_unchanged_other_members() -> void:
	for fault in ["no_spend", "double_spend", "no_heal", "other_hp", "reorder", "close_stuck"]:
		var f := Fixture.new()
		f.fault = fault
		assert_false((await f.run()).ok, fault)


func test_cost_gate_and_foreign_modal_refuse_without_input() -> void:
	var f := Fixture.new()
	f.stopped = true
	assert_false((await f.run()).ok)
	assert_eq(f.calls, [])
	f.stopped = false
	f.context = "combat"
	assert_false((await f.run()).ok)
	assert_eq(f.calls, [])
