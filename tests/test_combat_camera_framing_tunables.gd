extends "res://tests/test_case.gd"

## F04#7: the fight camera's size-adaptive framing, as the pure arithmetic
## `combat_manager.gd` runs every tick (`framing_extra_for`,
## `ally_floor_distance`, `follow_height_for`) and the shipped tunables in
## `combat.json camera.framing`. The occluder half (clear orbit) is in
## test_combat_camera_clear_orbit.gd.

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const BASE := 9.5


func test_a_small_pair_is_pushed_in_below_the_base_distance() -> void:
	assert_almost_eq(MANAGER.framing_extra_for(7.5, BASE, -3.0, 30.0, 2.0), -2.0, 0.001)


func test_the_push_in_stops_at_min_extra() -> void:
	assert_almost_eq(MANAGER.framing_extra_for(3.0, BASE, -3.0, 30.0, 2.0), -3.0, 0.001)


func test_a_large_pair_widens_the_frame() -> void:
	assert_almost_eq(MANAGER.framing_extra_for(15.0, BASE, -3.0, 30.0, 2.0), 5.5, 0.001)
	assert_almost_eq(MANAGER.framing_extra_for(80.0, BASE, -3.0, 30.0, 2.0), 30.0, 0.001,
		"never past max_extra_distance")


func test_the_ally_floor_beats_the_push_in() -> void:
	# The pair would fit at 3m, but the ally needs 8m of arm: the lens stays out.
	assert_almost_eq(MANAGER.framing_extra_for(3.0, BASE, -3.0, 30.0, 8.0), -1.5, 0.001)


func test_min_extra_zero_is_the_old_widen_only_behaviour() -> void:
	assert_almost_eq(MANAGER.framing_extra_for(3.0, BASE, 0.0, 30.0, 2.0), 0.0, 0.001)
	assert_almost_eq(MANAGER.framing_extra_for(3.0, BASE, 2.0, 30.0, 2.0), 0.0, 0.001,
		"a positive min_extra is not a hidden base-distance change")


func test_ally_floor_is_measured_along_the_arm() -> void:
	assert_almost_eq(MANAGER.ally_floor_distance(2.0, 1.5, deg_to_rad(-25.0)),
		3.5 / cos(deg_to_rad(25.0)), 0.001)
	assert_true(is_finite(MANAGER.ally_floor_distance(2.0, 1.5, deg_to_rad(-89.9))),
		"a near-vertical arm cannot divide by zero")


func test_pivot_height_follows_the_tallest_fighter_within_bounds() -> void:
	assert_almost_eq(MANAGER.follow_height_for(2.0, 0.55, 2.3, 6.0), 2.3, 0.001,
		"never below the base height")
	assert_almost_eq(MANAGER.follow_height_for(9.0, 0.55, 2.3, 6.0), 4.95, 0.001)
	assert_almost_eq(MANAGER.follow_height_for(20.0, 0.55, 2.3, 6.0), 6.0, 0.001,
		"never above max_height")


func test_the_shipped_tunables_are_on_and_sane() -> void:
	var cfg: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/combat.json")) as Dictionary).get("camera", {})
	var framing: Dictionary = cfg.get("framing", {})
	assert_true(float(framing.get("min_extra_distance", 0.0)) < 0.0, "push-in is enabled")
	assert_true(float(cfg.get("distance", 0.0)) + float(framing.get("min_extra_distance", 0.0)) >= 4.0,
		"the push-in cannot take the arm under 4m")
	assert_true(float(framing.get("min_ally_clearance_m", 0.0)) >= 1.0)
	assert_true(bool((framing.get("height_follow", {}) as Dictionary).get("enabled", false)))
	var orbit: Dictionary = framing.get("clear_orbit", {})
	assert_true(bool(orbit.get("enabled", false)))
	assert_true((orbit.get("samples_deg", []) as Array).size() >= 3)
	assert_true(float(orbit.get("interval_s", 0.0)) > 0.0, "the solver is throttled")
	assert_true(bool((cfg.get("aftermath", {}) as Dictionary).get("enabled", false)))


## Hard rule: relative scale fixes grow the smaller side, never shrink a
## creature to fit a camera. The framing code must frame, not rescale.
func test_the_framing_code_never_rescales_a_creature() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/combat/combat_manager.gd")
	var start := source.find("func _update_combat_camera_framing(")
	var finish := source.find("func _body_render_bounds(")
	assert_true(start >= 0 and finish > start, "framing block located")
	var block := source.substr(start, finish - start)
	for forbidden: String in [".scale =", "set_scale(", "scale_object_local(",
			"apply_size_multiplier(", "\"scale\""]:
		assert_false(block.contains(forbidden), "framing code touches creature scale via %s" % forbidden)
