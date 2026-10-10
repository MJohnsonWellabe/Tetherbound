extends SceneTree

const DRIVE := preload("res://tests/helpers/gate_a_opening_drive.gd")

class CombatState extends Node:
	var aiming := false
	func is_aiming() -> bool:
		return aiming

class WanderDriver extends DRIVE:
	var movement_calls := 0
	var aim_calls := 0
	var walled := false

	func _drive_body_toward(body: Node3D, point: Vector3, _frames: int) -> void:
		movement_calls += 1
		if not walled:
			body.global_position = point

	func _aim_camera_at(_target: Node3D, _seconds: float = AIM_CONVERGE_SECONDS) -> bool:
		aim_calls += 1
		return true

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var failed := false
	for scenario in [[false, false], [true, false], [true, true]]:
		var aiming: bool = scenario[0]
		var driver := WanderDriver.new()
		driver.walled = scenario[1]
		var player := CharacterBody3D.new()
		var wild := Node3D.new()
		var combat := CombatState.new()
		combat.aiming = aiming
		root.add_child(player)
		root.add_child(wild)
		root.add_child(combat)
		player.global_position = Vector3(2, 0, 0)
		wild.global_position = Vector3.ZERO
		driver._tree = self
		driver._player = player
		driver._wild = wild
		driver._combat = combat
		await driver._wander_for_a_new_angle()
		var expected_aims := 1 if aiming else 0
		# A walk that goes nowhere tries the other side once, then gives up.
		var expected_moves := 2 if driver.walled else 1
		var passed := driver.movement_calls == expected_moves and driver.aim_calls == expected_aims
		print("AIM WANDER PROBE aiming=", aiming, " walled=", driver.walled,
			" movement_calls=", driver.movement_calls,
			" aim_calls=", driver.aim_calls, " expected_aim_calls=", expected_aims,
			" passed=", passed)
		failed = failed or not passed
		player.queue_free()
		wild.queue_free()
		combat.queue_free()
	quit(1 if failed else 0)
