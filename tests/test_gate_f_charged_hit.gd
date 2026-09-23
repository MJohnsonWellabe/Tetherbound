extends TestCase

const DRIVER := preload("res://tools/gate_f/charged_hit_driver.gd")

class Creature extends RefCounted:
	var hp := 100.0
	var energy := 0
	func can_use_charged() -> bool: return energy >= 2

class Manager extends Node:
	signal hit_landed(on_enemy: bool, amount: float)
	var pilot := Creature.new()
	var foe := Creature.new()
	var live := true
	var _pending_move := {}
	func is_fighting() -> bool: return live
	func active_creature() -> RefCounted: return pilot
	func enemy() -> RefCounted: return foe
	func charged_ready() -> bool: return pilot.energy >= 2
	func quick_ready() -> bool: return true


func _run_fixture(manager: Node, physical: Callable, budget: int,
		interrupted: Callable = Callable()) -> Dictionary:
	var clock := {"frame": 0}
	return await DRIVER.execute(null, manager, physical, budget, interrupted,
		func() -> int: return int(clock.frame),
		func() -> void: clock.frame += 1)


func test_empty_energy_uses_real_quick_callbacks_then_observes_charged_hit() -> void:
	var manager := Manager.new()
	var presses: Array = []
	var physical := func(control: String, hold: int) -> Dictionary:
		presses.append([control, hold])
		manager._pending_move = {"is_quick": control == "combat_quick"}
		if control == "combat_quick":
			manager.pilot.energy += 1
		else:
			manager.pilot.energy -= 2
		manager.hit_landed.emit(true, 5.0)
		return {"ok": true}
	var result := await _run_fixture(manager, physical, 180)
	assert_true(result.ok)
	assert_eq(presses, [["combat_quick", 1], ["combat_quick", 1], ["combat_charged", 60]])
	assert_eq(result.charged_damage, 5.0)
	assert_eq(manager.get_signal_connection_list("hit_landed").size(), 0)
	manager.free()


func test_successful_input_without_charged_impact_is_not_evidence() -> void:
	var manager := Manager.new()
	manager.pilot.energy = 2
	var physical := func(_control: String, _hold: int) -> Dictionary:
		manager._pending_move = {"is_quick": true}
		manager.hit_landed.emit(true, 10.0)
		manager._pending_move = {"is_quick": false}
		manager.hit_landed.emit(false, 10.0)
		manager.hit_landed.emit(true, 0.0)
		manager.live = false
		return {"ok": true}
	var result := await _run_fixture(manager, physical, 10)
	assert_false(result.ok)
	assert_eq(result.charged_damage, 0.0)
	assert_true(str(result.why).contains("ended"))
	manager.free()


func test_killing_charged_hit_is_proven_before_fight_ends() -> void:
	var manager := Manager.new()
	manager.pilot.energy = 2
	var physical := func(_control: String, _hold: int) -> Dictionary:
		manager._pending_move = {"is_quick": false}
		manager.hit_landed.emit(true, 100.0)
		manager.foe.hp = 0.0
		manager.live = false
		return {"ok": true}
	var result := await _run_fixture(manager, physical, 10)
	assert_true(result.ok)
	assert_eq(result.charged_damage, 100.0)
	manager.free()


func test_budget_and_cost_refusal_remain_fail_closed() -> void:
	var manager := Manager.new()
	var physical := func(_control: String, _hold: int) -> Dictionary: return {"ok": true}
	var result := await _run_fixture(manager, physical, 2)
	assert_false(result.ok)
	assert_eq(result.charged_damage, 0.0)
	result = await _run_fixture(manager, physical, 10, func() -> bool: return true)
	assert_false(result.ok)
	assert_true(str(result.why).contains("cost gate"))
	manager.free()
