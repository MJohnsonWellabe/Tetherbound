extends "res://tests/test_case.gd"

const TRAINER_SPAWN := preload("res://scripts/net/trainer_spawn.gd")


func test_host_receives_remote_pose_across_realm_boundary() -> void:
	assert_true(TRAINER_SPAWN.observer_may_receive(1, "meadows", "stormwood", true),
		"the listen server must receive pose updates for its Stormwood shell")


func test_non_host_observers_remain_realm_scoped() -> void:
	assert_true(TRAINER_SPAWN.observer_may_receive(42, "stormwood", "stormwood", true))
	assert_false(TRAINER_SPAWN.observer_may_receive(42, "meadows", "stormwood", true),
		"another client must not draw a trainer from a different realm")


func test_pre_handshake_and_offline_visibility_still_allow_the_spawn() -> void:
	assert_true(TRAINER_SPAWN.observer_may_receive(42, "", "stormwood", true))
	assert_true(TRAINER_SPAWN.observer_may_receive(42, "meadows", "stormwood", false))
