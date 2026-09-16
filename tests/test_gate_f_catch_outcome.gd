extends TestCase

const OBSERVER := preload("res://tools/gate_f/catch_outcome.gd")

class Creature extends RefCounted:
	var hp := 10.0

class CatchParty extends RefCounted:
	var members: Array = []
	func size() -> int: return members.size()
	func at(index: int) -> RefCounted: return members[index]

class CatchThrower extends Node:
	signal orb_struck(target: Node3D, offset: float)
	signal orb_missed(reason: String)

class CatchManager extends Node:
	signal catch_resolved(success: bool, shakes: int)
	signal catch_refused(reason: String)
	signal exited(outcome: String)
	var pilot := Creature.new()
	var foe := Creature.new()
	var thrower := CatchThrower.new()
	var fighting := true
	var resolving := false
	func active_creature() -> RefCounted: return pilot
	func enemy() -> RefCounted: return foe
	func throw_aim() -> Node: return thrower
	func is_fighting() -> bool: return fighting
	func is_resolving_catch() -> bool: return resolving


func _fixture(mode: String) -> Dictionary:
	var manager := CatchManager.new()
	var party := CatchParty.new()
	party.members.append(manager.pilot)
	var clock := {"frames": 0}
	var launch := func() -> Dictionary:
		match mode:
			"breakout", "loss":
				manager.catch_resolved.emit(false, 2)
				if mode == "loss": manager.pilot.hp = 0.0
			"miss":
				manager.catch_refused.emit("ground") # Production manager relays first.
				manager.thrower.orb_missed.emit("ground")
			"refused": manager.catch_refused.emit("fainted target")
			"caught", "wrong_foe", "changed_party", "no_growth", "no_exit":
				manager.catch_resolved.emit(true, 3)
			"resolve_timeout":
				manager.thrower.orb_struck.emit(null, 0.0)
				manager.resolving = true
		return {"ok": true, "launches": 1, "orb_instance_id": 42}
	var next := func() -> void:
		clock.frames += 1
		if clock.frames == 3 and mode in ["caught", "wrong_foe", "changed_party", "no_growth", "no_exit"]:
			if mode != "no_growth":
				party.members.append(Creature.new() if mode == "wrong_foe" else manager.foe)
			if mode == "changed_party": party.members[0] = Creature.new()
			if mode != "no_exit":
				manager.fighting = false
				manager.exited.emit("caught")
	var result := await OBSERVER.execute(manager, launch, func() -> RefCounted: return party,
		next, Callable(), 4, 5, 6)
	result.fixture_frames = clock.frames
	result.connections_left = manager.get_signal_connection_list("catch_resolved").size() \
		+ manager.thrower.get_signal_connection_list("orb_missed").size()
	manager.thrower.free()
	manager.free()
	return result


func test_breakout_during_launch_returns_without_extra_idle_frames() -> void:
	var result := await _fixture("breakout")
	assert_true(result.ok)
	assert_eq(result.outcome, "breakout")
	assert_eq(result.shakes, 2)
	assert_eq(result.physics_frames, 0)
	assert_eq(result.connections_left, 0)


func test_no_body_hit_is_miss_not_breakout_despite_relayed_refusal() -> void:
	var result := await _fixture("miss")
	assert_true(result.ok)
	assert_eq(result.outcome, "miss")
	assert_false(result.verdict_seen)
	assert_eq(result.physics_frames, 0)


func test_true_signal_waits_for_exact_foe_growth_and_actual_caught_exit() -> void:
	var result := await _fixture("caught")
	assert_true(result.ok)
	assert_eq(result.outcome, "caught")
	assert_eq(result.physics_frames, 3)
	assert_eq(result.connections_left, 0)


func test_false_growth_changed_baseline_loss_and_refusal_never_pass() -> void:
	for mode in ["wrong_foe", "changed_party", "loss", "refused", "no_growth", "no_exit"]:
		var result := await _fixture(mode)
		assert_false(result.ok, mode)
		assert_eq(result.connections_left, 0, mode)
		assert_true(result.physics_frames <= 15, mode)


func test_silent_flight_or_unresolved_strike_times_out_not_assumed_miss() -> void:
	var flight := await _fixture("silent")
	assert_false(flight.ok)
	assert_eq(flight.physics_frames, 4)
	assert_eq(flight.outcome, "")
	var resolve := await _fixture("resolve_timeout")
	assert_false(resolve.ok)
	assert_eq(resolve.physics_frames, 5)
	assert_eq(resolve.connections_left, 0)
