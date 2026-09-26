extends "res://tests/test_case.gd"

## F04#7: `camera_rig.gd::clear_orbit_offset_deg()` -- the fight camera's way
## out of a wall. The occlusion sweep is replaced through the rig's own
## `set_occlusion_probe_for_tests` hook (see test_conversation_camera.gd for why
## the rig is driven by hand); the probe answers by the arm's horizontal
## bearing, so "clear" and "blocked" are angles here, not scenery.

const RIG := preload("res://scripts/player/camera_rig.gd")
const ARM := 9.0

var _rig: SpringArm3D = null
var _player: Node3D = null
## Bearings (degrees, same convention as the rig's yaw) with room for the arm.
var _clear: Array = []
## Room reported at every other bearing, and per-bearing overrides.
var _blocked_room := 1.0
var _room_at: Dictionary = {}


func before_each() -> void:
	_player = Node3D.new()
	_rig = SpringArm3D.new()
	_rig.set_script(RIG)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	_rig.add_child(camera)
	_rig.notification(Node.NOTIFICATION_READY)
	_rig.set_target(_player)
	_rig.set("yaw", 0.0)
	_rig.set("pitch", deg_to_rad(-25.0))
	_rig.set_occlusion_probe_for_tests(_probe)
	_clear = []
	_blocked_room = 1.0
	_room_at = {}


func after_each() -> void:
	for node: Node in [_rig, _player]:
		if node != null and is_instance_valid(node):
			node.free()


func _probe(_pivot: Vector3, dir: Vector3, limit: float) -> float:
	var bearing := int(roundf(rad_to_deg(atan2(dir.x, dir.z))))
	if _room_at.has(bearing):
		return minf(float(_room_at[bearing]), limit)
	for raw: Variant in _clear:
		if absi(bearing - int(raw)) <= 1:
			return limit
	return _blocked_room


func _solve() -> float:
	return float(_rig.clear_orbit_offset_deg(ARM, [25.0, 50.0, 75.0], 0.75))


func test_a_clear_view_is_left_alone() -> void:
	_clear = [0]
	assert_eq(_solve(), 0.0)


func test_a_wall_behind_swings_to_the_nearest_clear_angle() -> void:
	_clear = [50, -75]
	assert_eq(_solve(), 50.0, "the smallest swing with room wins")


func test_the_answer_is_stable_once_the_rig_has_swung() -> void:
	_clear = [25]
	assert_eq(_solve(), 25.0)
	# The tracker has carried the rig there; asking again must not release it
	# back into the wall just because the CURRENT view is now clear.
	_rig.set_clearance_extra(25.0)
	_rig.set("yaw", deg_to_rad(25.0))
	assert_eq(_solve(), 25.0)


func test_ties_keep_the_side_already_in_use() -> void:
	_clear = [50, -50]
	_rig.set_clearance_extra(-10.0)
	_rig.set("yaw", deg_to_rad(-10.0))
	assert_eq(_solve(), -50.0)


func test_nowhere_clear_takes_the_roomiest_angle() -> void:
	_blocked_room = 1.0
	_room_at = {-75: 4.0, 50: 3.0}
	assert_eq(_solve(), -75.0, "a longer arm is still better than the wall")


func test_set_target_clears_the_swing() -> void:
	_rig.set_clearance_extra(50.0)
	_rig.set_target(_player)
	assert_eq(float(_rig.clearance_extra()), 0.0)
