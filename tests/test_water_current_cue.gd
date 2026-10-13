extends "res://tests/test_case.gd"

const POLICY := preload("res://scripts/ui/water_current_cue_policy.gd")
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")
const FIELD := preload("res://scripts/world/water_current_field.gd")
const TEST_PATH := "user://__test_water_current_cue.json"


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_preference_survives_file_reload_and_preserves_other_accessibility() -> void:
	var first: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	first.set("accessibility", {"reduced_motion": true, "look_sensitivity_percent": 135})
	assert_true(POLICY.preferred(first), "current arrow defaults on when candidate ships")
	assert_true(POLICY.set_preferred(first, false))
	var second: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	assert_eq(int(second.call("load_overrides")), KEY_BINDINGS.LOAD_OK)
	assert_false(POLICY.preferred(second))
	assert_eq(second.get("accessibility").get("look_sensitivity_percent"), 135)
	assert_true(bool(second.get("accessibility").get("reduced_motion")))
	assert_true(POLICY.set_preferred(second, true))
	var third: RefCounted = KEY_BINDINGS.new(TEST_PATH)
	assert_eq(int(third.call("load_overrides")), KEY_BINDINGS.LOAD_OK)
	assert_true(POLICY.preferred(third))


func test_direction_rotates_with_camera_and_ignores_pitch_and_strength() -> void:
	assert_eq(POLICY.direction(Vector3.FORWARD, Basis.IDENTITY), Vector2.UP)
	assert_eq(POLICY.direction(Vector3.RIGHT, Basis.IDENTITY), Vector2.RIGHT)
	var quarter_turn := Basis(Vector3.UP, PI / 2.0)
	assert_true(POLICY.direction(Vector3.FORWARD, quarter_turn).is_equal_approx(Vector2.RIGHT))
	var pitched := quarter_turn * Basis(Vector3.RIGHT, -0.8)
	assert_true(POLICY.direction(Vector3.FORWARD * 0.2, pitched).is_equal_approx(Vector2.RIGHT))
	assert_eq(POLICY.direction(Vector3.ZERO, Basis.IDENTITY), Vector2.ZERO)
	assert_eq(POLICY.direction(Vector3.INF, Basis.IDENTITY), Vector2.ZERO)
	assert_eq(POLICY.direction(Vector3.FORWARD, Basis(Vector3.INF, Vector3.UP, Vector3.BACK)), Vector2.ZERO)


func test_restoration_keeps_flow_direction_without_mutating_the_current_field() -> void:
	var config := {"currents": [{"id": "test", "polyline": [[0, 0, 0], [0, 0, 100]],
		"width_m": 20.0, "flow_direction_xz": [0, -1], "strength_m_s": 0.4,
		"post_liberation_strength_multiplier": 0.25}]}
	var field := FIELD.new(config)
	var live: Vector3 = field.sample(Vector3(0, -0.7, 50)).velocity
	var restored: Vector3 = field.sample(Vector3(0, -0.7, 50), true).velocity
	assert_almost_eq(restored.length(), live.length() * 0.25)
	assert_eq(POLICY.direction(live, Basis.IDENTITY), POLICY.direction(restored, Basis.IDENTITY))
	assert_eq(field.sample(Vector3(0, -0.7, 50)).velocity, live)
