extends "res://tools/gate_f/operator_harness.gd"

## Instrument control-flow fixtures, not production combat/input evidence.
class Creature extends RefCounted:
	var hp := 100.0
	func label() -> String:
		return "fixture-%d" % get_instance_id()

class Manager extends Node:
	var pilot := Creature.new()
	var foe := Creature.new()
	var fighting := true
	var switch_ready := true
	func active_creature() -> RefCounted:
		return pilot
	func enemy() -> RefCounted:
		return foe
	func is_fighting() -> bool:
		return fighting
	func can_switch() -> bool:
		return fighting and switch_ready
	func switchable_indices() -> Array:
		return [1]

class FixtureProbe extends RefCounted:
	var manager: Manager
	func combat_manager() -> Node:
		return manager
	func combat_state() -> Dictionary:
		return {"phase": "ready"}
	func input_context() -> String:
		return "combat"

var manager := Manager.new()
var mode := "exchange"
var failures: Array[String] = []


func _run() -> void:
	var fixture := FixtureProbe.new()
	fixture.manager = manager
	_probe = fixture
	var exchange := await _step_combat_checkpoint({"budget_frames": 10}, "fixture")
	_check(exchange.begins_with("live exchange:"), "fresh incoming/outgoing damage reaches checkpoint")
	mode = "outgoing_only"
	manager.pilot.hp = 20.0
	var old_damage := await _step_combat_checkpoint({"budget_frames": 10}, "fixture")
	_check(old_damage.begins_with("FAIL") and old_damage.contains("incoming 0.0"), "pre-existing low HP is not incoming pressure")
	mode = "lose_pilot"
	var lost := await _step_combat_checkpoint({"budget_frames": 10}, "fixture")
	_check(lost.begins_with("FAIL") and lost.contains("lost its live"), "automatic pilot loss cannot satisfy checkpoint")
	mode = "switch"
	var switched := await _step_press({"control": "party_cycle", "verify_switch": true, "settle_frames": 0}, "fixture")
	_check(switched.contains("verified pilot identity handoff"), "physical step verifies changed identity")
	mode = "ignore_switch"
	var ignored := await _step_press({"control": "party_cycle", "verify_switch": true, "settle_frames": 0}, "fixture")
	_check(ignored.begins_with("FAIL"), "injected but ignored switch fails")
	manager.switch_ready = false
	var locked := await _step_press({"control": "party_cycle", "verify_switch": true}, "fixture")
	_check(locked.begins_with("FAIL"), "commitment lock prevents prescribed switch input")
	manager.free()
	for failure in failures:
		push_error(failure)
	print("PASS combat checkpoint/switch readback fixtures" if failures.is_empty() else "FAIL combat checkpoint fixtures")
	quit(0 if failures.is_empty() else 1)


func _inject(control: String, _frames: int, _device: String = "") -> Dictionary:
	if control == "combat_quick":
		manager.foe.hp -= 5.0
		if mode == "exchange":
			manager.pilot.hp -= 5.0
		if mode == "lose_pilot":
			manager.pilot = Creature.new()
	elif control == "party_cycle" and mode == "switch":
		manager.pilot = Creature.new()
	await physics_frame
	return {"ok": true, "raw": "fixture input receipt"}


func _tick(_delta: float) -> void:
	pass


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
