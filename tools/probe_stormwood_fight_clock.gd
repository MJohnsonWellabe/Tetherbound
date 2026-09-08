extends SceneTree

## Synthetic harness control only: verifies clocks and observed strike counters,
## not production combat victory or campaign progression.
const CROWN := preload("res://tests/helpers/stormwood_crown_build_segment.gd")

class QuietCrown extends CROWN:
	func _drive_stick(_x: float, _y: float) -> void:
		pass
	func _fail(message: String) -> bool:
		failures.append(message)
		return false

class Manager extends Node:
	signal hit_landed(on_enemy: bool, amount: float)
	signal attack_missed(by_player: bool)
	var fighting := true
	func is_fighting() -> bool:
		return fighting
	func enemy() -> RefCounted:
		return null
	func enemy_body() -> Node3D:
		return null

class Director extends Node:
	func ally_instance() -> RefCounted:
		return null
	func ally_body() -> Node3D:
		return null

var errors: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for publish_outcome in [true, false]:
		Engine.time_scale = 8.0
		Engine.physics_ticks_per_second = 480
		var segment := QuietCrown.new()
		var manager := Manager.new()
		var director := Director.new()
		root.add_child(manager)
		root.add_child(director)
		segment._tree = self
		segment._manager = manager
		segment._director = director
		_finish_control.call_deferred(segment, manager, publish_outcome)
		var passed := await segment._fight_current("synthetic clock control")
		_check(passed == publish_outcome, "outcome acceptance")
		_check(Engine.time_scale == 8.0 and Engine.physics_ticks_per_second == 480,
			"prior clocks restored on success and missing-outcome failure")
		_check(manager.get_signal_connection_list("hit_landed").is_empty()
			and manager.get_signal_connection_list("attack_missed").is_empty(), "observers disconnected")
		var report := "\n".join(segment.transcript)
		_check(report.contains('"player_hits": 1') and report.contains('"enemy_hits": 1')
			and report.contains('"player_misses": 1') and report.contains('"enemy_misses": 1'),
			"actual emitted hit and miss counters retained")
		manager.free()
		director.free()
	print("SYNTHETIC FIGHT CLOCK: 2 cases, failures=", errors)
	quit(0 if errors.is_empty() else 1)

func _finish_control(segment: RefCounted, manager: Node, publish_outcome: bool) -> void:
	for frame in 5:
		await process_frame
	_check(Engine.time_scale == 1.0 and Engine.physics_ticks_per_second == 60,
		"fight runs at normal production clock")
	manager.hit_landed.emit(true, 12.0)
	manager.hit_landed.emit(false, 7.0)
	manager.attack_missed.emit(true)
	manager.attack_missed.emit(false)
	manager.fighting = false
	if publish_outcome:
		segment._on_combat_exited("won")

func _check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)
