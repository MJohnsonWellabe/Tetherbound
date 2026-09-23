extends TestCase

const DRIVER := preload("res://tools/gate_f/one_bed_team_rest.gd")

## These callbacks model UI outcomes to test fail-closed orchestration. They
## are not campaign evidence; the production adapter must inject mapped input.
class Creature extends RefCounted:
	var rested := false
	var resting := false
	var rest_bed_index := -1
	var fainted := false

class Party extends RefCounted:
	var members: Array = []
	func size() -> int: return members.size()
	func at(index: int) -> RefCounted: return members[index]

class CareGame extends Node:
	var party := Party.new()
	var day := 1

class Bed extends Node:
	var index := 7
	var occupant := -1
	func build_index() -> int: return index
	func occupant_index() -> int: return occupant

class CarePanel extends Node:
	var _bed: Node
	var opened := false
	func is_open() -> bool: return opened

class Fixture extends RefCounted:
	var game := CareGame.new()
	var bed := Bed.new()
	var panel := CarePanel.new()
	var row := 0
	var assignments: Array = []
	var presses: Array = []
	var walks := 0
	var stuck_focus := false
	var wrong_panel := false
	var wrong_assignment := false
	var omit_day := false
	var omit_rested := false
	var retain_bed := false
	var refuse_input := false
	func _init() -> void:
		game.add_child(bed)
		game.add_child(panel)
		for index in 5:
			game.party.members.append(Creature.new())
	func callbacks() -> Dictionary:
		return {"walk_to_bed": walk, "open_bed": open,
			"press": press, "sleep_at_bedroll": sleep,
			"read_focus": focus, "settle": settle}
	func walk() -> Dictionary:
		walks += 1
		return {"ok": true}
	func open() -> Dictionary:
		panel.opened = true
		panel._bed = game if wrong_panel else bed
		row = 0
		return {"ok": true, "panel": panel}
	func focus() -> String: return "  %d.  Bramblebun  HP 50 / 100" % (row + 1)
	func settle() -> void: pass
	func press(control: String) -> Dictionary:
		presses.append(control)
		if refuse_input:
			return {"ok": false}
		if control == "ui_down" and not stuck_focus:
			row = (row + 1) % 5
		elif control == "ui_accept":
			var selected := (row + 1) % 5 if wrong_assignment else row
			var creature: Creature = game.party.at(selected)
			creature.resting = true
			creature.rest_bed_index = bed.index
			bed.occupant = selected
			assignments.append(selected)
		elif control == "menu_cancel":
			panel.opened = false
		return {"ok": true}
	func sleep() -> Dictionary:
		if not omit_day:
			game.day += 1
		var creature: Creature = game.party.at(bed.occupant)
		creature.rested = not omit_rested
		if not retain_bed:
			creature.resting = false
			creature.rest_bed_index = -1
			bed.occupant = -1
		return {"ok": true}
	func dispose() -> void: game.free()


func test_reuses_same_bed_for_four_tired_rows_and_skips_first_rested_member() -> void:
	var f := Fixture.new()
	f.game.party.at(0).rested = true
	var result := await DRIVER.execute(f.game, f.bed, f.callbacks())
	assert_true(result.ok, str(result.why))
	assert_eq(result.nights, 4)
	assert_eq(result.skipped, [0])
	assert_eq(result.rested_rows, [1, 2, 3, 4])
	assert_eq(f.assignments, [1, 2, 3, 4])
	assert_eq(f.game.day, 5)
	assert_eq(f.bed.occupant, -1)
	f.dispose()


func test_already_rested_team_uses_no_input_or_nights() -> void:
	var f := Fixture.new()
	for member in f.game.party.members:
		member.rested = true
	var result := await DRIVER.execute(f.game, f.bed, f.callbacks())
	assert_true(result.ok)
	assert_eq(result.nights, 0)
	assert_eq(f.presses.size(), 0)
	assert_eq(f.walks, 0)
	f.dispose()


func test_wrong_panel_or_wrong_row_assignment_never_claims_a_night() -> void:
	for fault: String in ["wrong_panel", "wrong_assignment", "refuse_input"]:
		var f := Fixture.new()
		f.set(fault, true)
		var result := await DRIVER.execute(f.game, f.bed, f.callbacks())
		assert_false(result.ok, fault)
		assert_eq(result.nights, 0)
		assert_eq(f.game.day, 1)
		f.dispose()


func test_focus_navigation_is_bounded_and_does_not_accept_wrong_member() -> void:
	var f := Fixture.new()
	f.game.party.at(0).rested = true
	f.stuck_focus = true
	var result := await DRIVER.execute(f.game, f.bed, f.callbacks())
	assert_false(result.ok)
	assert_eq(f.presses.size(), 5)
	assert_eq(f.assignments.size(), 0)
	f.dispose()


func test_sleep_callback_success_requires_day_rest_and_bed_release_evidence() -> void:
	for fault: String in ["omit_day", "omit_rested", "retain_bed"]:
		var f := Fixture.new()
		f.set(fault, true)
		var result := await DRIVER.execute(f.game, f.bed, f.callbacks())
		assert_false(result.ok, fault)
		assert_eq(result.nights, 0)
		assert_eq(f.assignments, [0])
		f.dispose()


func test_occupied_bed_is_not_emptied_by_early_wake() -> void:
	var f := Fixture.new()
	f.bed.occupant = 3
	var result := await DRIVER.execute(f.game, f.bed, f.callbacks())
	assert_false(result.ok)
	assert_eq(f.bed.occupant, 3)
	assert_eq(f.presses.size(), 0)
	f.dispose()


func test_cost_interruption_and_nonplaced_bed_refuse_before_input() -> void:
	var f := Fixture.new()
	var result := await DRIVER.execute(f.game, f.bed, f.callbacks(), func() -> bool: return true)
	assert_false(result.ok)
	assert_eq(f.presses.size(), 0)
	f.bed.index = -1
	result = await DRIVER.execute(f.game, f.bed, f.callbacks())
	assert_false(result.ok)
	assert_eq(f.walks, 0)
	f.dispose()
