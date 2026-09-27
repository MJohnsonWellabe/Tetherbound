extends "res://tests/test_case.gd"

## F04 (Keeper Hald's room): the rig's pivot rises `_height` above its target,
## and that vertical leg is now swept like the shoulder leg, so a lift toward a
## low ceiling stops under it instead of entering the slab. The occlusion sweep
## is replaced through `set_occlusion_probe_for_tests` (as in
## test_combat_camera_clear_orbit.gd): straight up has `_room_up` metres.

const RIG := preload("res://scripts/player/camera_rig.gd")

var _rig: SpringArm3D = null
var _player: Node3D = null
var _room_up := 100.0
var _asked_up := false


func before_each() -> void:
	_player = Node3D.new()
	_player.position = Vector3(3.0, 1.0, -2.0)
	_rig = SpringArm3D.new()
	_rig.set_script(RIG)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	_rig.add_child(camera)
	_rig.notification(Node.NOTIFICATION_READY)
	_rig.set_target(_player)
	_rig.set_occlusion_probe_for_tests(_probe)
	_room_up = 100.0
	_asked_up = false


func after_each() -> void:
	for node: Node in [_rig, _player]:
		if node != null and is_instance_valid(node):
			node.free()


func _probe(_pivot: Vector3, dir: Vector3, limit: float) -> float:
	if dir.is_equal_approx(Vector3.UP):
		_asked_up = true
		return minf(_room_up, limit)
	return limit


func _anchor_height() -> float:
	return (_rig.call("_pivot_anchor") as Vector3).y - _player.position.y


func test_open_sky_keeps_the_full_height() -> void:
	_rig.set("_height", 6.0)
	assert_almost_eq(_anchor_height(), 6.0, 0.001, "nothing overhead: the pivot rises the whole lift")
	assert_true(_asked_up, "the vertical leg is swept")


func test_a_low_ceiling_stops_the_pivot_under_it() -> void:
	_rig.set("_height", 6.0)
	_room_up = 3.5
	assert_almost_eq(_anchor_height(), 1.0 + 3.5, 0.001,
		"the pivot stops where the sweep from 1 m up found the ceiling, not inside it")


func test_an_ordinary_height_below_the_sweep_start_is_untouched() -> void:
	_rig.set("_height", 0.8)
	_room_up = 0.0
	assert_almost_eq(_anchor_height(), 0.8, 0.001, "a pivot lower than the sweep start is never swept")
	assert_false(_asked_up, "no sweep below VERTICAL_SWEEP_FROM_M")
