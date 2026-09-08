extends "res://tests/test_case.gd"

## Focused contract for the saved-suffix diagnostic's call into the real
## RidingController. This catches an argument-count error without rebuilding a
## Terrain3D world or replaying Calder.
const CONTINUOUS := preload("res://tests/smoke_water_continuous.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")

class MountBody extends Node3D:
	func body_radius() -> float:
		return 2.0


class RidingProbe extends RIDING:
	func _mount_surface_distance(from: Vector3, body: Node3D) -> float:
		return RIDING.mount_surface_distance(from, body.position, body.body_radius())


func test_diagnostic_calls_real_mount_surface_helper_with_player_and_body() -> void:
	var riding := RidingProbe.new()
	var body := MountBody.new()
	body.position = Vector3(7, 0, 0)
	assert_almost_eq(CONTINUOUS.mount_surface_distance_for_diagnostic(
		riding, Vector3.ZERO, body), 5.0, 0.001)
	body.free()
	riding.free()
