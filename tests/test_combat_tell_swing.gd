extends "res://tests/test_case.gd"

## F14#0 C3: an opted-in opponent's strike tell starts the fight camera's wider
## occlusion swing (`combat_manager.gd::_wild_tell_swing`), so a strike that
## carries it to contact is already seen from the side.

const MANAGER := preload("res://scripts/combat/combat_manager.gd")


class FakeFoe extends Node3D:
	var tell_swing := false
	var winding := false

	func tell_camera_swing() -> bool:
		return tell_swing

	func is_winding_up() -> bool:
		return winding


var _foe: FakeFoe = null
var _ally: Node3D = null
var _manager: Node = null


func before_each() -> void:
	_foe = FakeFoe.new()
	_ally = Node3D.new()
	_manager = Node.new()
	_manager.set_script(MANAGER)
	_manager.set("_wild", _foe)
	_manager.set("_ally_body", _ally)


func after_each() -> void:
	for node: Node in [_manager, _foe, _ally]:
		if node != null and is_instance_valid(node):
			node.free()


func test_an_opted_in_tell_starts_the_wider_swing_only_while_it_winds_up() -> void:
	_foe.winding = true
	assert_false(bool(_manager.call("_wild_tell_swing")), "no opt-in, no swing")
	_foe.tell_swing = true
	assert_true(bool(_manager.call("_wild_tell_swing")))
	_foe.winding = false
	assert_false(bool(_manager.call("_wild_tell_swing")), "outside the tell the hidden test decides")


func test_an_opponent_camera_block_can_opt_in_too() -> void:
	_foe.winding = true
	_foe.set_meta("combat_camera", {"framing": {"tell_swing": true}})
	assert_true(bool(_manager.call("_wild_tell_swing")))


func test_a_far_opponent_does_not_start_the_swing() -> void:
	_foe.winding = true
	_foe.tell_swing = true
	_foe.position = Vector3(0.0, 0.0, -6.0)
	assert_true(bool(_manager.call("_wild_tell_swing", 7.0)), "within reach of contact")
	_foe.position = Vector3(0.0, 0.0, -10.0)
	assert_false(bool(_manager.call("_wild_tell_swing", 7.0)), "a far opponent would leave the frame")
