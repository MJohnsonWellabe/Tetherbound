extends "res://tests/test_case.gd"

## Detached actual director/arbiter; no portal geometry or arrival proof.
const SESSION := preload("res://scripts/net/session.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")

class HostSession extends SESSION:
	var world_root: Node
	var hosting := true
	func is_host() -> bool: return hosting
	func local_peer_id() -> int: return 1
	func _foundation_realm_roots() -> Array[Node]:
		var roots: Array[Node] = []
		if world_root != null: roots.append(world_root)
		return roots

func test_guest_before_first_fight_uses_real_empty_arbiter_and_retains_live_combat_checks() -> void:
	var session := HostSession.new()
	var world := Node3D.new()
	session.world_root = world
	var director := DIRECTOR.new()
	director.set("_session", session)
	world.add_child(director)
	assert_eq(director.get("_encounter_host"), null)
	assert_false(session._altar_peer_in_combat(2), "idle guest has an actual host authority before first fight")
	var host: RefCounted = director.get("_encounter_host")
	assert_true(host != null)
	if host != null:
		assert_true((host.get("encounters") as Dictionary).is_empty(), "no encounter invented")
		var record: Dictionary = host.call("open", 2, "meadows", "wild", {"hp": 100.0, "hp_max": 100.0,
			"position": [2.0, 0.0, 0.0]}, "actual-owned-fixture", "fixture-character")
		assert_false(record.is_empty())
		assert_true(session._altar_peer_in_combat(2), "real participant still blocked")
		assert_false(session._altar_peer_in_combat(3), "other guest is not this participant")
		assert_eq(director.get("_encounter_host"), host, "query retains same live arbiter")
		host.call("close", record.encounter_id)
		assert_false(session._altar_peer_in_combat(2), "actual completion releases participant")
		(host.get("encounters") as Dictionary)["malformed"] = false
		assert_true(session._altar_peer_in_combat(2), "malformed authority still refuses")
	world.free()
	session.free()

func test_missing_foreign_and_client_authority_still_refuse_without_initialization() -> void:
	var session := HostSession.new()
	assert_true(session._altar_peer_in_combat(2), "no source world")
	var world := Node3D.new()
	session.world_root = world
	assert_true(session._altar_peer_in_combat(2), "no recognized director")
	var director := DIRECTOR.new()
	world.add_child(director)
	assert_true(session._altar_peer_in_combat(2), "unbound director cannot establish host authority")
	assert_eq(director.get("_encounter_host"), null)
	var other := HostSession.new()
	director.set("_session", other)
	assert_true(session._altar_peer_in_combat(2), "another Session owns this director")
	assert_eq(director.get("_encounter_host"), null)
	director.set("_session", session)
	session.hosting = false
	assert_true(session._altar_peer_in_combat(2), "client cannot create host authority")
	assert_eq(director.get("_encounter_host"), null)
	world.free()
	other.free()
	session.free()
