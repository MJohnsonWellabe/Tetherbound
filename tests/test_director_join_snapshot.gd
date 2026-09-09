extends "res://tests/test_case.gd"

const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

class SessionStub extends Node:
	var applied := false
	func is_active() -> bool:
		return true
	func is_host() -> bool:
		return false
	func is_multi_peer() -> bool:
		return true
	func snapshot_ready() -> bool:
		return applied
	func local_peer_id() -> int:
		return 20

class DirectorProbe extends "res://scripts/combat/encounter_director.gd":
	var sent: Array[String] = []
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
