extends TestCase

const HARNESS := preload("res://tools/gate_f/operator_harness.gd")

class Probe extends RefCounted:
	var current_flags: Array = []
	var director: Node
	func flags() -> Array: return current_flags
	func encounter_director() -> Node: return director

class Creature extends RefCounted:
	var hp := 20.0
	var fainted := false

class Party extends RefCounted:
	var creature: RefCounted
	func active() -> RefCounted: return creature
	func active_index() -> int: return 0

func test_harvest_precondition_distinguishes_absent_and_already_claimed_flags() -> void:
	var harness := HARNESS.new()
	var probe := Probe.new()
	harness._probe = probe
	var flag := "harvest_node:order:10.0"
	assert_true(harness._step_assert({"check": "flag_set", "flag": flag, "equals": false}).ok)
	assert_false(harness._step_assert({"check": "flag_set", "flag": flag}).ok)
	probe.current_flags.append("harvest_node:order:11.0")
	assert_false(harness._step_assert({"check": "flag_set", "flag": flag}).ok)
	probe.current_flags.append(flag)
	assert_false(harness._step_assert({"check": "flag_set", "flag": flag, "equals": false}).ok)
	assert_true(harness._step_assert({"check": "flag_set", "flag": flag}).ok)
	harness.free()

func test_companion_requires_visible_body_of_the_living_active_member() -> void:
	var party := Party.new()
	party.creature = Creature.new()
	var state := {"party": party, "companion_ready": false, "companion": null}
	assert_false(HARNESS._companion_is_deployed(state), "Healthy index is not deployment")
	state.companion = party.creature
	assert_false(HARNESS._companion_is_deployed(state), "Unfinished hidden spawn cannot omit Call out")
	state.companion_ready = true
	assert_true(HARNESS._companion_is_deployed(state))
	state.companion = Creature.new()
	assert_false(HARNESS._companion_is_deployed(state), "Another companion is not the active member")
	state.companion = party.creature
	party.creature.hp = 0.0
	assert_false(HARNESS._companion_is_deployed(state))
	party.creature.hp = 20.0
	party.creature.fainted = true
	assert_false(HARNESS._companion_is_deployed(state))
