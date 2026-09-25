extends "res://tests/test_case.gd"

const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

class SessionStub extends Node:
	var applied := false
	var multi_peer := true
	func is_active() -> bool:
		return true
	func is_host() -> bool:
		return false
	func is_multi_peer() -> bool:
		return multi_peer
	func snapshot_ready() -> bool:
		return applied
	func local_peer_id() -> int:
		return 20

class DirectorProbe extends "res://scripts/combat/encounter_director.gd":
	var sent: Array[String] = []
	var hosting := false
	var host_rows := 0
	func _is_host() -> bool:
		return hosting
	func _host_set_deployed(_peer_id: int, _row: Dictionary) -> void:
		host_rows += 1
	func _local_character_id() -> String:
		return "fixture"
	func _creature_card(_creature: RefCounted) -> Dictionary:
		return {}
	func _send_realm_rpc(peer: int, method: String, _arguments: Array, completing: bool = false) -> bool:
		if not _realm_rpc_allowed(peer, completing):
			return false
		sent.append(method)
		return true

func test_initial_join_and_reconnect_hold_then_resume_deployed_creature_announcement() -> void:
	var session := SessionStub.new()
	var director := DirectorProbe.new()
	director.set("_session", session)
	var ally := CREATURE.from_species("terrapup", {"display_name": "Partner", "base_hp": 100.0})
	director.set("_ally", ally)
	director._announce_deployment(ally)
	assert_true(director.sent.is_empty())
	assert_true(bool(director.get("_deployment_waiting_for_receiver")))
	session.applied = true
	director.realm_transition_arrived()
	assert_eq(director.sent.size(), 1)
	assert_false(bool(director.get("_deployment_waiting_for_receiver")))
	session.applied = false
	director._announce_deployment(ally)
	assert_eq(director.sent.size(), 1)
	session.applied = true
	director.realm_transition_arrived()
	assert_eq(director.sent.size(), 2)
	assert_false(bool(director.get("_deployment_waiting_for_receiver")))
	director.free()
	session.free()


## Returning route: the Water world restores a mid-water ride (and announces the
## ally) before any session exists. The host must still hear about it once the
## rejoined session is multi-peer, or other players see the rider on nothing.
func test_deployment_announced_before_any_session_is_sent_once_the_session_is_multi_peer() -> void:
	var director := DirectorProbe.new()
	var ally := CREATURE.from_species("terrapup", {"display_name": "Partner", "base_hp": 100.0})
	director.set("_ally", ally)
	director._announce_deployment(ally)
	assert_true(director.sent.is_empty())
	assert_true(bool(director.get("_deployment_waiting_for_receiver")),
		"an ally restored before the session exists must wait for a receiver")
	var session := SessionStub.new()
	session.multi_peer = false
	director.set("_session", session)
	director._announce_deployment(ally)
	assert_true(director.sent.is_empty())
	assert_true(bool(director.get("_deployment_waiting_for_receiver")),
		"a one-peer session is still no receiver")
	session.multi_peer = true
	session.applied = true
	director._resend_waiting_deployment()
	assert_eq(director.sent, ["_rpc_creature_deployed"] as Array[String])
	assert_false(bool(director.get("_deployment_waiting_for_receiver")))
	director.free()
	session.free()


## A player who deployed solo and then hosts must not re-announce every frame
## once a guest joins: the host records its own row once and stops holding.
func test_solo_deployment_that_becomes_a_host_records_once_and_stops_holding() -> void:
	var director := DirectorProbe.new()
	var ally := CREATURE.from_species("terrapup", {"display_name": "Partner", "base_hp": 100.0})
	director.set("_ally", ally)
	director._announce_deployment(ally)
	assert_true(bool(director.get("_deployment_waiting_for_receiver")))
	var session := SessionStub.new()
	session.applied = true
	director.set("_session", session)
	director.hosting = true
	for _frame in 5:
		director._resend_waiting_deployment()
	assert_eq(director.host_rows, 1, "the host records its own deployment once, not every frame")
	assert_false(bool(director.get("_deployment_waiting_for_receiver")))
	assert_true(director.sent.is_empty(), "a host never sends its deployment to itself")
	director.free()
	session.free()
