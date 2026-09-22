extends TestCase

const GUARD := preload("res://tools/gate_f/catch_launch_guard.gd")

class Creature extends RefCounted:
	var hp := 100.0

class Thrower extends Node:
	signal aim_exited()
	signal throw_refused(reason: String)
	var orb: Node3D
	var launch := {"launch_point": [1, 2, 3], "direction": [0, 0, -1], "orb_id": "orb_basic"}
	func resting_orb() -> Node3D: return orb
	func last_launch() -> Dictionary: return launch.duplicate()
	func release() -> void:
		orb = Node3D.new()
		add_child(orb)
		aim_exited.emit()

class Manager extends Node:
	signal exited(outcome: String)
	var pilot := Creature.new()
	var foe := Creature.new()
	var live := true
	var aiming := true
	var thrower := Thrower.new()
	func _init() -> void: add_child(thrower)
	func active_creature() -> RefCounted: return pilot
	func enemy() -> RefCounted: return foe
	func is_fighting() -> bool: return live
	func is_aiming() -> bool: return aiming
	func throw_aim() -> Node: return thrower


func run_fixture(manager: Manager, physical: Callable, tick: Callable = Callable(),
		context: String = "combat_aim") -> Dictionary:
	var clock := {"frame": 0}
	return await GUARD.execute(null, manager, func() -> String: return context,
		physical, manager.pilot, manager.foe, 4, Callable(),
		func() -> int: return int(clock.frame),
		func() -> void:
			clock.frame += 1
			if tick.is_valid(): tick.call())


func test_faint_or_world_context_never_sends_physical_throw() -> void:
	var manager := Manager.new()
	var count := {"presses": 0}
	var press := func() -> Dictionary:
		count.presses += 1
		return {"ok": true}
	manager.pilot.hp = 0.0
	var fainted := await run_fixture(manager, press)
	assert_false(fainted.ok)
	assert_eq(fainted.launches, 0)
	manager.pilot.hp = 100.0
	var world := await run_fixture(manager, press, Callable(), "world")
	assert_false(world.ok)
	assert_eq(count.presses, 0)
	manager.free()


func test_successful_press_and_cancel_signal_are_not_launch_evidence() -> void:
	var manager := Manager.new()
	var result := await run_fixture(manager, func() -> Dictionary:
		manager.thrower.aim_exited.emit()
		return {"ok": true})
	assert_false(result.ok)
	assert_eq(result.launches, 0)
	assert_eq(manager.thrower.get_signal_connection_list("aim_exited").size(), 0)
	manager.free()


func test_new_orb_counts_even_when_launch_parameters_repeat() -> void:
	var manager := Manager.new()
	manager.thrower.release() # Previous successful throw with identical parameters.
	var result := await run_fixture(manager, func() -> Dictionary:
		manager.thrower.release()
		manager.thrower.aim_exited.emit() # Duplicate notification is not another throw.
		return {"ok": true})
	assert_true(result.ok)
	assert_eq(result.launches, 1)
	assert_true(str(result.why).contains("catch not yet proven"))
	assert_eq(manager.get_signal_connection_list("exited").size(), 0)
	manager.free()


func test_stale_orb_and_refusal_never_count_as_launch() -> void:
	var manager := Manager.new()
	manager.thrower.release()
	var result := await run_fixture(manager, func() -> Dictionary:
		manager.thrower.throw_refused.emit("no orbs left")
		manager.thrower.aim_exited.emit()
		return {"ok": true})
	assert_false(result.ok)
	assert_eq(result.launches, 0)
	assert_eq(result.refusal, "no orbs left")
	manager.free()


func test_delayed_real_release_and_loss_during_windup() -> void:
	var manager := Manager.new()
	var sent := func() -> Dictionary: return {"ok": true}
	var launch := await run_fixture(manager, sent, func() -> void: manager.thrower.release())
	assert_true(launch.ok)
	assert_eq(launch.launches, 1)
	var loss := await run_fixture(manager, sent, func() -> void:
		manager.pilot.hp = 0.0
		manager.live = false
		manager.exited.emit("lost"))
	assert_false(loss.ok)
	assert_eq(loss.launches, 0)
	assert_eq(loss.outcome, "lost")
	assert_eq(manager.thrower.get_signal_connection_list("throw_refused").size(), 0)
	manager.free()


func test_original_pilot_and_foe_identity_are_required() -> void:
	var manager := Manager.new()
	var original := manager.pilot
	manager.pilot = Creature.new()
	var why := GUARD.boundary(manager, func() -> String: return "combat_aim", original, manager.foe)
	assert_true(why.contains("changed"))
	manager.free()
