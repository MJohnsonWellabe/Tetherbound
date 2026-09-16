extends TestCase

const DRIVER := preload("res://tools/gate_f/catch_survival_driver.gd")

class Creature extends RefCounted:
	var hp := 100.0
	var max_hp := 100.0
	func _init(value: float = 100.0) -> void: hp = value

class Fixture extends RefCounted:
	var party: Array = [Creature.new(20), Creature.new(10), Creature.new(90)]
	var foe := Creature.new()
	var active := 0
	var frame := 0
	var cooldown := 0
	var presses: Array = []
	var live := true
	var context := "combat"
	var ignore_press := false
	var lose_on_press := false
	var change_foe := false
	var auto_replace := false
	var locked := false
	var allowed: Array = [0, 1, 2]
	func read() -> Dictionary:
		var eligible: Array = []
		for i in allowed:
			if i != active and party[i].hp > 0.0: eligible.append(i)
		return {"fighting": live, "context": context, "pilot": party[active], "foe": foe,
			"party": party, "active_index": active, "eligible_indices": eligible,
			"aiming": context == "combat_aim", "catch_resolving": false,
			"can_switch": cooldown == 0 and not locked}
	func press(control: String, hold: int) -> Dictionary:
		presses.append([control, hold, frame])
		if auto_replace:
			party[active].hp = 0.0
			active = 1
			return {"ok": true}
		if lose_on_press:
			party[active].hp = 0.0
			live = false
			return {"ok": true}
		if change_foe: foe = Creature.new()
		if not ignore_press:
			for offset in range(1, party.size()):
				var index := (active + offset) % party.size()
				if allowed.has(index) and party[index].hp > 0.0:
					active = index
					break
		cooldown = 90
		return {"ok": true}
	func tick() -> void:
		frame += 1
		cooldown = maxi(0, cooldown - 1)


func run_fixture(fixture: Fixture, budget: int = 600) -> Dictionary:
	return await DRIVER.execute(null, fixture.read, fixture.press, 0.5, budget,
		Callable(), func() -> int: return fixture.frame, fixture.tick)


func test_forward_physical_handoffs_wait_cooldown_and_preserve_foe() -> void:
	var fixture := Fixture.new()
	var original_foe := fixture.foe
	var result := await run_fixture(fixture)
	assert_true(result.ok)
	assert_eq(result.presses, 2)
	assert_eq(result.switches, 2)
	assert_eq(fixture.presses, [["party_cycle", 1, 0], ["party_cycle", 1, 90]])
	assert_eq(fixture.active, 2)
	assert_eq(fixture.foe, original_foe)
	assert_eq(result.final_hp, 90.0)


func test_healthy_pilot_or_no_eligible_improvement_does_not_press() -> void:
	var fixture := Fixture.new()
	fixture.party[0].hp = 60.0
	assert_true((await run_fixture(fixture)).ok)
	assert_eq(fixture.presses.size(), 0)
	fixture.party[0].hp = 20.0
	fixture.allowed = [0, 1] # Healthy third member is unavailable (e.g. resting).
	var result := await run_fixture(fixture)
	assert_true(result.ok)
	assert_true(str(result.why).contains("no healthier"))
	assert_eq(fixture.presses.size(), 0)


func test_input_success_without_pilot_readback_never_passes() -> void:
	var fixture := Fixture.new()
	fixture.ignore_press = true
	var result := await run_fixture(fixture, 6)
	assert_false(result.ok)
	assert_eq(result.presses, 1)
	assert_eq(result.switches, 0)
	assert_eq(fixture.frame, 6)


func test_faint_or_foe_change_cannot_be_treated_as_recovery() -> void:
	var fixture := Fixture.new()
	fixture.lose_on_press = true
	var loss := await run_fixture(fixture)
	assert_false(loss.ok)
	assert_eq(loss.switches, 0)
	fixture = Fixture.new()
	fixture.party[1].hp = 90.0
	fixture.auto_replace = true
	var automatic := await run_fixture(fixture)
	assert_false(automatic.ok)
	assert_true(str(automatic.why).contains("automatic replacement"))
	fixture = Fixture.new()
	fixture.change_foe = true
	var changed := await run_fixture(fixture)
	assert_false(changed.ok)
	assert_true(str(changed.why).contains("foe identity"))


func test_aim_context_refuses_before_any_lb_and_lockout_is_bounded() -> void:
	var fixture := Fixture.new()
	fixture.context = "combat_aim"
	assert_false((await run_fixture(fixture)).ok)
	assert_eq(fixture.presses.size(), 0)
	fixture.context = "combat"
	fixture.locked = true
	assert_false((await run_fixture(fixture, 900)).ok)
	assert_eq(fixture.frame, 600)
	assert_eq(fixture.presses.size(), 0)


func test_wrapped_forward_eligible_selection_skips_unavailable_members() -> void:
	var fixture := Fixture.new()
	fixture.active = 1
	fixture.allowed = [0, 1] # Next forward legal member wraps to index zero.
	fixture.party[0].hp = 80.0
	var result := await run_fixture(fixture)
	assert_true(result.ok)
	assert_eq(result.switches, 1)
	assert_eq(fixture.active, 0)
