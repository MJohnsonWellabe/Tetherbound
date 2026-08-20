extends "res://tests/test_case.gd"

const WORLD_EXTENT := preload("res://scripts/world/world_extent.gd")
const BUILD_SNAP := preload("res://scripts/build/build_snap_contract.gd")


func test_current_nested_world_bounds_win_over_legacy_world_size() -> void:
	var cfg := {
		"world_size": 512,
		"world_bounds": {"min_x": -1024, "max_x": 1024, "min_z": -512, "max_z": 7680},
	}
	var bounds := WORLD_EXTENT.bounds(cfg)
	assert_almost_eq(float(bounds.min_x), -1024.0)
	assert_almost_eq(float(bounds.max_x), 1024.0)
	assert_almost_eq(float(bounds.min_z), -512.0)
	assert_almost_eq(float(bounds.max_z), 7680.0)


func test_legacy_square_extent_still_works_without_authored_bounds() -> void:
	var bounds := WORLD_EXTENT.bounds({"world_size": 600})
	assert_almost_eq(float(bounds.min_x), -300.0)
	assert_almost_eq(float(bounds.max_x), 300.0)
	assert_almost_eq(float(bounds.min_z), -300.0)
	assert_almost_eq(float(bounds.max_z), 300.0)


func test_wall_snaps_to_floor_edge_not_floor_centre() -> void:
	var placed := [{"id": "floor", "position": [0.0, 0.0, 0.0], "yaw_deg": 0.0}]
	var resolved := BUILD_SNAP.resolve(Vector3(0.1, 0.0, 1.2), 0.0, "wall", placed)
	assert_true(bool(resolved.structural))
	assert_almost_eq(float(resolved.position.x), 0.0)
	assert_almost_eq(float(resolved.position.z), 1.0, 0.0001, "wall belongs on the 1m half-cell floor edge")
	assert_almost_eq(float(resolved.yaw_deg), 0.0)


func test_door_and_wall_share_the_same_edge_occupancy_slot() -> void:
	var placed := [{"id": "wall", "position": [0.0, 0.0, 1.0], "yaw_deg": 0.0}]
	assert_true(BUILD_SNAP.occupied("door", Vector3(0.0, 0.0, 1.0), placed))


func test_roof_anchor_is_above_a_supported_floor() -> void:
	var placed := [
		{"id": "floor", "position": [0.0, 0.0, 0.0], "yaw_deg": 0.0},
		{"id": "wall", "position": [0.0, 0.0, 1.0], "yaw_deg": 0.0},
	]
	var resolved := BUILD_SNAP.resolve(Vector3(0.2, 0.0, 0.2), 0.0, "roof", placed)
	assert_true(bool(resolved.structural))
	assert_almost_eq(float(resolved.position.x), 0.0)
	assert_almost_eq(float(resolved.position.z), 0.0)
	assert_almost_eq(float(resolved.position.y), BUILD_SNAP.ROOF_Y, 0.0001, "roof must sit at wall-top, not terrain height")
