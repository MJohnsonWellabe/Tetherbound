extends SceneTree

const DRIVE := preload("res://tests/helpers/gate_a_opening_drive.gd")

class CombatState extends Node:
	var aiming := false
	func is_aiming() -> bool:
		return aiming

class WanderDriver extends DRIVE:
	var movement_calls := 0
	var aim_calls := 0

	func _drive_body_toward(_body: Node3D, _point: Vector3, _frames: int) -> void:
		movement_calls += 1

	func _aim_camera_at(_target: Node3D, _seconds: float = AIM_CONVERGE_SECONDS) -> bool:
		aim_calls += 1
		return true

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var failed := false
	for aiming in [false, true]:
		var driver := WanderDriver.new()
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
		var passed := driver.movement_calls == 1 and driver.aim_calls == expected_aims
		print("AIM WANDER PROBE aiming=", aiming, " movement_calls=", driver.movement_calls,
			" aim_calls=", driver.aim_calls, " expected_aim_calls=", expected_aims,
			" passed=", passed)
		failed = failed or not passed
		player.queue_free()
		wild.queue_free()
		combat.queue_free()
	quit(1 if failed else 0)
