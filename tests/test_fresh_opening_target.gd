extends "res://tests/test_case.gd"

const OPENING := preload("res://tests/helpers/fresh_opening_segment.gd")

class Body extends Node3D:
	var species_id := "bramblebun"

class Combat extends Node:
	var admitted: Node3D
	func enemy_body() -> Node3D:
		return admitted

class Arbiter extends Node:
	var provider: Node3D
	var actionable := true
	var available := true
	func enabled() -> bool:
		return available
	func winning_provider() -> Node3D:
		return provider
	func winner() -> Dictionary:
		return {"actionable": actionable}

class Probe extends OPENING:
	func _fail(message: String) -> void:
		_failures.append(message)


func test_offered_creature_cannot_be_replaced_by_another_body_of_the_same_species() -> void:
	var expected := Body.new()
	var neighbour := Body.new()
	var combat := Combat.new()
	var opening := Probe.new()
	opening._combat = combat
	combat.admitted = neighbour
	assert_false(opening._engaged_expected_body(expected))
	assert_eq(opening._failures.size(), 1)
	assert_eq(combat.admitted, neighbour, "rejection cannot change the admitted fight")
	combat.free()
	neighbour.free()
	expected.free()


func test_earned_key_walk_requires_the_exact_actionable_prompt() -> void:
	var key := Node3D.new()
	var nearby := Node3D.new()
	var arbiter := Arbiter.new()
	var opening := Probe.new()
	opening._arbiter = arbiter
	arbiter.provider = nearby
	assert_false(opening._earned_prompt_ready(key))
	arbiter.provider = key
	assert_true(opening._earned_prompt_ready(key))
	arbiter.actionable = false
	assert_false(opening._earned_prompt_ready(key))
	arbiter.actionable = true
	arbiter.available = false
	assert_false(opening._earned_prompt_ready(key), "a held stale offer is not usable while world interaction is disabled")
	arbiter.free()
	nearby.free()
	key.free()


func test_exact_admitted_body_is_accepted_and_absent_body_is_rejected() -> void:
	var expected := Body.new()
	var combat := Combat.new()
	var opening := Probe.new()
	opening._combat = combat
	combat.admitted = expected
	assert_true(opening._engaged_expected_body(expected))
	assert_true(opening._failures.is_empty())
	combat.admitted = null
	assert_false(opening._engaged_expected_body(expected))
	combat.free()
	expected.free()


class ThrowVerdict extends Node:
	var current := {"eligible": false, "reason": "reticle_outside_body"}
	var preview := {"eligible": true, "trajectory_blocked": false}
	func launch_assist_diagnostics() -> Dictionary:
		return current
	func aim_report() -> Dictionary:
		return preview

class AimingCombat extends Node:
	var aim: Node
	var aiming := true
	func throw_aim() -> Node:
		return aim
	func is_aiming() -> bool:
		return aiming

func test_final_throw_rejects_stale_eligible_preview_and_actual_obstruction() -> void:
	var throw := ThrowVerdict.new()
	var combat := AimingCombat.new()
	combat.aim = throw
	var opening := Probe.new()
	opening._combat = combat
	assert_false(opening._final_throw_verdict_ready(), "cached eligible preview cannot override current off-body reticle")
	assert_true("reticle_outside_body" in opening._failures[-1])
	throw.current = {"eligible": true, "reason": "eligible"}
	throw.preview["trajectory_blocked"] = true
	assert_false(opening._final_throw_verdict_ready(), "current camera eligibility does not override a blocked physical arc")
	throw.preview["trajectory_blocked"] = false
	assert_true(opening._final_throw_verdict_ready())
	throw.preview = {}
	assert_false(opening._final_throw_verdict_ready(), "missing physics preview fails closed")
	combat.aiming = false
	assert_false(opening._final_throw_verdict_ready(), "ended aim cannot launch")
	combat.free()
	throw.free()
