extends "res://tests/test_case.gd"

const TRAINER_SPAWN := preload("res://scripts/net/trainer_spawn.gd")

class FakeSession:
	extends Node

	func peers() -> Array:
		return [{"peer_id": 42, "appearance_id": "sera"}]


class FakeTransition:
	extends Node
	var pending := true
	func departure_cleanup_pending(peer_id: int, realm: String) -> bool:
		return pending and peer_id == 42 and realm == "meadows"


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


func test_remote_spawn_data_uses_the_selected_body_not_the_viewers_body() -> void:
	var spawner := TRAINER_SPAWN.new()
	var session := FakeSession.new()
	spawner.set("_session", session)
	assert_eq(str(spawner.call("_appearance_id_for", 42)), "sera")
	assert_eq(str(spawner.call("_appearance_id_for", 99)), "trainer")
	session.free()
	spawner.free()


func test_source_realm_defers_only_the_coordinated_departing_body() -> void:
	var spawner := TRAINER_SPAWN.new()
	var transition := FakeTransition.new()
	spawner.set("_realm", "meadows")
	spawner.set("_transition", transition)
	assert_true(spawner.call("_departure_cleanup_pending", 42, "meadows"))
	assert_false(spawner.call("_departure_cleanup_pending", 99, "meadows"))
	assert_false(spawner.call("_departure_cleanup_pending", 42, "water"))
	transition.pending = false
	assert_false(spawner.call("_departure_cleanup_pending", 42, "meadows"),
		"receiver-ready settlement permits the host-side free")
	transition.free()
	spawner.free()
