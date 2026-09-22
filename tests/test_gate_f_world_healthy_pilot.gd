extends TestCase

const DRIVER := preload("res://tools/gate_f/world_healthy_pilot.gd")
const PARTY := preload("res://autoload/party.gd")

class Member extends RefCounted:
	var hp := 10.0
	var fainted := false
	var resting := false

class Fixture extends RefCounted:
	var party: RefCounted = PARTY.new()
	var companion: RefCounted
	var ready := true
	var context := "world"
	var allowed := true
	var mode := "normal"
	var pending_frames := 0
	var presses := 0
	func _init(health: Array) -> void:
		for hp in health:
			var member := Member.new()
			member.hp = hp
			party.add(member)
		companion = party.active()
	func read() -> Dictionary:
		return {"party": party, "active_index": party.active_index(), "context": context,
			"input_allowed": allowed, "companion": companion, "companion_ready": ready}
	func press(control: String) -> Dictionary:
		presses += 1
		if mode == "refused" or control != "party_cycle": return {"ok": false}
		if mode == "ignored": return {"ok": true}
		party.cycle_active(1)
		ready = false
		pending_frames = 3
		if mode == "reorder": party.move(0, 1)
		if mode == "modal": context = "menu_backpack"
		return {"ok": true}
	func next() -> void:
		pending_frames -= 1
		if pending_frames <= 0:
			ready = true
			companion = party.active()


func test_selects_most_live_hp_with_physical_cycle_and_real_companion_settle() -> void:
	var fixture := Fixture.new([15.0, 58.0, 79.0, 20.0])
	var before: Array = fixture.party.members()
	var result := await DRIVER.execute(fixture.read, fixture.press, fixture.next, 60)
	assert_true(result.ok)
	assert_eq(result.selected_index, 2)
	assert_eq(result.presses, 2)
	assert_eq(result.physics_frames, 10) # Two taps(4) + two actual spawn waits(6).
	assert_eq(result.process_frames, 4)
	assert_eq(fixture.companion, before[2])
	assert_eq(fixture.party.members(), before)
	assert_eq(before[0].hp, 15.0)


func test_already_best_single_member_and_ties_issue_no_input() -> void:
	for health in [[79.0, 58.0], [79.0], [79.0, 79.0]]:
		var fixture := Fixture.new(health)
		var result := await DRIVER.execute(fixture.read, fixture.press, fixture.next)
		assert_true(result.ok)
		assert_true(result.no_input)
		assert_eq(result.presses, 0)


func test_forward_selection_skips_fainted_and_resting_members() -> void:
	var fixture := Fixture.new([15.0, 100.0, 120.0, 79.0])
	fixture.party.at(1).fainted = true
	fixture.party.at(2).resting = true
	var result := await DRIVER.execute(fixture.read, fixture.press, fixture.next)
	assert_true(result.ok)
	assert_eq(result.selected_index, 3)
	assert_eq(result.presses, 1)


func test_ignored_input_refusal_context_and_roster_changes_fail_bounded() -> void:
	for mode in ["ignored", "refused", "modal", "reorder"]:
		var fixture := Fixture.new([15.0, 79.0, 58.0])
		fixture.mode = mode
		var result := await DRIVER.execute(fixture.read, fixture.press, fixture.next, 12)
		assert_false(result.ok, mode)
		assert_true(result.physics_frames <= 12, mode)
		assert_true(result.presses <= 2, mode)


func test_no_world_or_no_live_member_never_presses() -> void:
	for mode in ["modal", "denied", "fainted", "cost"]:
		var fixture := Fixture.new([15.0, 79.0])
		if mode == "modal": fixture.context = "combat"
		if mode == "denied": fixture.allowed = false
		if mode == "fainted":
			fixture.party.at(0).fainted = true
			fixture.party.at(1).fainted = true
		var result := await DRIVER.execute(fixture.read, fixture.press, fixture.next, 60,
			func() -> bool: return mode == "cost")
		assert_false(result.ok, mode)
		assert_eq(fixture.presses, 0, mode)
