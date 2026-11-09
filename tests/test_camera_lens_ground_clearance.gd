extends "res://tests/test_case.gd"

## F39#21 Venn aftermath: the post-fight lens rested 0.35 m above a dune face.
## movement.json camera.lens_ground_clearance shortens the arm until the ground
## is min_m below the lens. Ground is supplied through the rig's test probe.

const RIG := preload("res://scripts/player/camera_rig.gd")
const CFG := {"enabled": true, "min_m": 1.0, "step_m": 0.25, "min_arm_m": 2.0}

var _rig: SpringArm3D = null
var _ground_y := 0.0
var _slope := false


func _ground_at(lens: Vector3) -> float:
	return 0.45 * lens.z if _slope else _ground_y


func before_each() -> void:
	_rig = SpringArm3D.new()
	_rig.set_script(RIG)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	_rig.add_child(camera)
	_rig.position = Vector3(0.0, 2.0, 0.0)
	_slope = false
	_ground_y = 0.0


func after_each() -> void:
	if _rig != null and is_instance_valid(_rig):
		_rig.free()


func _grounded(lens: Vector3, clearance: float) -> bool:
	return lens.y - _ground_at(lens) < clearance


func test_flat_open_ground_keeps_the_arm() -> void:
	_ground_y = -10.0
	_rig.set_lens_ground_probe_for_tests(_grounded, CFG)
	_rig.spring_length = 6.0
	_rig.call("_keep_lens_off_ground")
	assert_eq(_rig.spring_length, 6.0, "nothing near the lens: arm unchanged")


func test_a_slope_under_the_lens_shortens_the_arm_until_clear() -> void:
	# The Venn case: ground rises behind the player (towards +z, the arm's
	# side), so the far end of a 6 m arm grazes the dune and a shorter arm
	# stands over lower ground.
	_slope = true
	_rig.set_lens_ground_probe_for_tests(_grounded, CFG)
	_rig.spring_length = 6.0
	_rig.call("_keep_lens_off_ground")
	var lens := _rig.position + _rig.global_transform.basis.z * _rig.spring_length
	assert_true(_rig.spring_length < 6.0, "the arm shortened off the dune")
	assert_true(lens.y - _ground_at(lens) >= 1.0, "the lens now clears the ground by min_m")
	assert_true(_rig.spring_length >= 2.0, "never below min_arm_m")


func test_off_flag_never_touches_the_arm() -> void:
	_ground_y = 100.0
	_rig.set_lens_ground_probe_for_tests(_grounded, {})
	_rig.spring_length = 6.0
	_rig.call("_keep_lens_off_ground")
	assert_eq(_rig.spring_length, 6.0)


func test_shipped_config_declares_the_flag_off() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/movement.json"))
	var entry: Dictionary = (parsed as Dictionary).camera.get("lens_ground_clearance", {})
	assert_eq(entry.get("enabled"), false, "ships OFF until judged")
