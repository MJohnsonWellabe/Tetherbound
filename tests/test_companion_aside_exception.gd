extends "res://tests/test_case.gd"

## F38#5 (LANE-MESHY, 8 Nov 2026): the P2-113 companion-aside hop ignores the
## companion's OWN trainer capsule for the duration of the hop only, so a wider
## contact spacing (a larger opponent) cannot stall the hop against the trainer.
## Proves the exception is held during the hop and gone on every exit path, and
## that another trainer's body is never excepted (co-op).

const MANAGER := preload("res://scripts/combat/combat_manager.gd")


class AimThrow extends Node:
	var aiming := true
	func is_aiming() -> bool:
		return aiming
	func is_busy() -> bool:
		return aiming


class Rig extends Node3D:
	var yaw := 0.0


class HopBody extends CharacterBody3D:
	var bursting := false
	var bursts := 0
	func begin_combat_burst(_direction: Vector3, _distance: float, _duration: float,
			_action: int = 0) -> bool:
		bursting = true
		bursts += 1
		return true
	func combat_burst_active() -> bool:
		return bursting
	func cancel_combat_burst() -> void:
		bursting = false


var _nodes: Array[Node] = []


func _add(node: Node) -> Node:
	# Off-tree on purpose: this runner executes before the SceneTree exists.
	# Collision exceptions work on the bodies' physics RIDs either way.
	_nodes.append(node)
	return node


func after_each() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _fixture() -> Dictionary:
	var manager := MANAGER.new()
	var ally := HopBody.new()
	var trainer := CharacterBody3D.new()
	var other := CharacterBody3D.new()
	var rig := Rig.new()
	var throw := AimThrow.new()
	for node: Node in [ally, trainer, other, rig, throw]:
		_add(node)
	manager.set("_player", trainer)
	manager.set("_ally_body", ally)
	manager.set("_camera_rig", rig)
	manager.set("_throw", throw)
	manager.set("state", MANAGER.State.ACTIVE)
	return {"manager": manager, "ally": ally, "trainer": trainer, "other": other, "throw": throw}


func _held(f: Dictionary) -> bool:
	return (f.ally as PhysicsBody3D).get_collision_exceptions().has(f.trainer)


## What `_step_companion_aside` does when it starts the hop: take the exception,
## then begin the burst (the position maths needs a live scene, covered by
## tests/smoke_catching.gd).
func _start_hop(f: Dictionary) -> void:
	f.manager.call("_set_companion_aside_trainer_exception", true)
	(f.ally as HopBody).begin_combat_burst(Vector3.LEFT, 3.2, 0.3)
	assert_true(_held(f), "the companion ignores its own trainer while the hop runs")
	assert_true(bool(f.manager.call("companion_aside_exception_held")), "the manager reports the held exception")
	assert_false((f.ally as PhysicsBody3D).get_collision_exceptions().has(f.other),
		"another player's trainer is never excepted")


func test_exception_is_gone_after_the_hop_ends() -> void:
	var f := _fixture()
	_start_hop(f)
	f.manager.call("_maintain_companion_aside_exception")
	assert_true(_held(f), "still held while the burst is active and the aim is open")
	(f.ally as HopBody).bursting = false
	f.manager.call("_maintain_companion_aside_exception")
	assert_false(_held(f), "the exception is dropped once the hop's burst ends")
	(f.manager as Node).free()


func test_exception_is_gone_after_an_aim_cancel_mid_hop() -> void:
	var f := _fixture()
	_start_hop(f)
	(f.throw as AimThrow).aiming = false
	assert_true((f.ally as HopBody).bursting, "the burst is still running (mid-hop)")
	f.manager.call("_maintain_companion_aside_exception")
	assert_false(_held(f), "cancelling the aim mid-hop drops the exception")
	(f.manager as Node).free()


func test_exception_is_gone_when_the_fight_leaves_active() -> void:
	var f := _fixture()
	_start_hop(f)
	f.manager.set("state", MANAGER.State.RESOLVING)
	f.manager.call("_maintain_companion_aside_exception")
	assert_false(_held(f), "a resolved fight drops the exception")
	(f.manager as Node).free()


func test_exception_is_gone_when_the_companion_changes() -> void:
	var f := _fixture()
	_start_hop(f)
	var replacement := _add(HopBody.new()) as HopBody
	f.manager.set("_ally_body", replacement)
	f.manager.call("_maintain_companion_aside_exception")
	assert_false(_held(f), "a recalled or swapped companion keeps no exception")
	(f.manager as Node).free()


func test_exception_is_gone_on_exit_tree() -> void:
	var f := _fixture()
	_start_hop(f)
	f.manager.call("_exit_tree")
	assert_false(_held(f), "leaving the tree (scene change) drops the exception")
	(f.manager as Node).free()
