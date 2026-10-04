extends SceneTree

## Synthetic flat support checks lifecycle wiring, not authored terrain or play.
const MOUNTS := preload("res://scripts/net/waystone_mounts.gd")
var failures: Array[String] = []

class FlatWorld extends Node3D:
	var simulation_only := true
	var ready_world := false
	func world_realm() -> String: return "meadows"
	func shell_build_complete() -> bool: return ready_world
	func ground_height_at(_x: float, _z: float) -> float: return 0.0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _run() -> void:
	var world := FlatWorld.new()
	_check(not MOUNTS.mount(world, "meadows"), "detached worlds never mount")
	root.add_child(world)
	_check(not MOUNTS.mount(world, "meadows"), "sliced terrain must finish first")
	world.ready_world = true
	_check(not MOUNTS.mount(world, "water"), "wrong realm cannot mount")
	_check(MOUNTS.mount(world, "meadows"), "ready world mounts")
	_check(world.has_node(^"Waystones"), "collection mounted")
	if world.has_node(^"Waystones"):
		_check(world.get_node(^"Waystones").get_child_count() == 5, "five stones")
		_check(MOUNTS.mount(world, "meadows"), "repeat mount succeeds")
		_check(world.get_node(^"Waystones").get_child_count() == 5, "no duplicates")
	world.free()
	await process_frame
	print("F18_MOUNT_LIFECYCLE " + JSON.stringify({"failures": failures, "synthetic_geometry": true}))
	quit(0 if failures.is_empty() else 1)
