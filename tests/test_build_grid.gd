extends "res://tests/test_case.gd"

## `BG1`: the pure grid/rotation/neighbour-snap math, `scripts/build/build_grid.gd`.
##
## `build_placer.gd` is a `Node` reading the player and the terrain, so it is
## out of scope for this headless-only harness (docs/decisions/D02) — this is
## everything about grid placement that IS pure logic: where a ghost lands,
## which way it faces, and whether it locks onto a neighbour. The running
## placer is exercised end to end by `tests/smoke_free_build.gd` instead.

const BUILD_GRID := preload("res://scripts/build/build_grid.gd")


# --- grid snap ----------------------------------------------------------------


func test_snap_to_grid_rounds_onto_the_module_grid() -> void:
	var snapped := BUILD_GRID.snap_to_grid(Vector3(4.9, 1.0, -3.1), 1.0)
	assert_almost_eq(snapped.x, 4.0)
	assert_almost_eq(snapped.z, -4.0)


func test_snap_to_grid_leaves_y_alone() -> void:
	var snapped := BUILD_GRID.snap_to_grid(Vector3(1.0, 99.0, 1.0), 5.5)
	assert_almost_eq(snapped.y, 5.5, 0.0001, "ground height should pass straight through")


func test_two_independently_snapped_points_land_on_the_same_lines() -> void:
	# The whole reason grid snap works without any neighbour bookkeeping: any
	# two raw points anywhere near the same grid cell converge on identical
	# X/Z once snapped, so two pieces placed near each other are flush.
	var a := BUILD_GRID.snap_to_grid(Vector3(4.2, 0.0, 6.1), 0.0)
	var b := BUILD_GRID.snap_to_grid(Vector3(3.8, 0.0, 5.7), 0.0)
	assert_eq(a.x, b.x)
	assert_eq(a.z, b.z)


# --- rotation -------------------------------------------------------------


func test_yaw_for_steps_is_ninety_degrees_per_step() -> void:
	assert_almost_eq(BUILD_GRID.yaw_for_steps(0), 0.0)
	assert_almost_eq(BUILD_GRID.yaw_for_steps(1), 90.0)
	assert_almost_eq(BUILD_GRID.yaw_for_steps(2), 180.0)
	assert_almost_eq(BUILD_GRID.yaw_for_steps(3), 270.0)


func test_a_full_turn_is_four_steps() -> void:
	assert_almost_eq(BUILD_GRID.yaw_for_steps(4), 0.0, 0.0001, "four steps should be back to 0")


func test_next_rotation_steps_wraps_after_the_fourth_orientation() -> void:
	var steps := 0
	for i in 3:
		steps = BUILD_GRID.next_rotation_steps(steps)
	assert_eq(steps, 3)
	steps = BUILD_GRID.next_rotation_steps(steps)
	assert_eq(steps, 0, "a fifth press should be back to the first orientation, not step 4")


# --- neighbour snap ---------------------------------------------------------


func test_with_no_neighbours_it_falls_back_to_a_plain_grid_snap() -> void:
	var result := BUILD_GRID.resolve_position(Vector3(5.2, 0.0, 1.1), 3.0, [])
	assert_false(result.snapped_to_neighbour)
	assert_almost_eq(result.position.x, 6.0)
	assert_almost_eq(result.position.y, 3.0)


func test_a_close_neighbour_pulls_the_position_flush_against_it() -> void:
	var neighbour := Vector3(10.0, 2.0, 10.0)
	# Aimed a little past the neighbour's east edge -- close enough that a
	# hand-placed spot should not have to be pixel-perfect.
	var result := BUILD_GRID.resolve_position(Vector3(11.4, 0.0, 10.3), 0.0, [neighbour])
	assert_true(result.snapped_to_neighbour)
	assert_almost_eq(result.position.x, 12.0, 0.0001, "should land exactly one grid cell east")
	assert_almost_eq(result.position.z, 10.0, 0.0001)


func test_a_neighbour_snap_takes_the_neighbours_own_height() -> void:
	# The point of neighbour snap: a wall run stays flush over uneven ground
	# instead of stair-stepping to whatever the raw terrain sample under each
	# new piece happens to be.
	var neighbour := Vector3(0.0, 4.25, 0.0)
	var result := BUILD_GRID.resolve_position(Vector3(1.6, 0.0, 0.4), 0.0, [neighbour])
	assert_almost_eq(result.position.y, 4.25)


func test_a_distant_candidate_does_not_trigger_neighbour_snap() -> void:
	var far_away := Vector3(500.0, 0.0, 500.0)
	var result := BUILD_GRID.resolve_position(Vector3(2.0, 0.0, 2.0), 1.5, [far_away])
	assert_false(result.snapped_to_neighbour)


func test_the_nearest_of_several_neighbours_is_used() -> void:
	var near := Vector3(2.0, 1.0, 0.0)
	var far := Vector3(50.0, 9.0, 50.0)
	var result := BUILD_GRID.resolve_position(Vector3(1.7, 0.0, 0.2), 0.0, [far, near])
	assert_true(result.snapped_to_neighbour)
	assert_almost_eq(result.position.y, 1.0, 0.0001, "should have locked onto the near one, not the far one")


func test_landing_exactly_on_a_neighbours_own_cell_is_pushed_out_one_cell() -> void:
	# Aiming almost exactly at an existing piece must not return that piece's
	# own position back -- that is full overlap, not a continuation of the run.
	var neighbour := Vector3(6.0, 0.0, 6.0)
	var result := BUILD_GRID.resolve_position(Vector3(6.05, 0.0, 5.95), 0.0, [neighbour])
	assert_true(result.snapped_to_neighbour)
	var moved: Vector3 = result.position
	var offset := Vector2(moved.x - neighbour.x, moved.z - neighbour.z)
	assert_true(offset.length() > 0.0, "landed exactly on the neighbour's own cell")
	# And it should still be a whole grid step, not some arbitrary nudge.
	assert_true(is_equal_approx(absf(offset.x), BUILD_GRID.GRID_SIZE) or is_equal_approx(absf(offset.y), BUILD_GRID.GRID_SIZE))
