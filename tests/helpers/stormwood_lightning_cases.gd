extends "res://tests/test_case.gd"

## Deferred scene-smoke cases. It drives the shipping resolver/receiver while only
## replacing actor discovery and the physics roof query.
const LIGHTNING := preload("res://scripts/world/stormwood_lightning.gd")
const SESSION := preload("res://scripts/net/session.gd")

class FakeSession extends Node:
	var host := true
	var local_id := 1
	var published: Array[Dictionary] = []
	func is_host() -> bool: return host
	func is_active() -> bool: return false
	func local_peer_id() -> int: return local_id
	func realm_of(_peer: int) -> String: return "stormwood"
	func publish_stormwood_strike(event: Dictionary) -> void:
		if host: published.append(event.duplicate(true))

class FakeSurge extends Node:
	func region_at(_at: Vector3) -> String: return "deepwood"

class FakeVitals extends RefCounted:
	var health := 100.0
	var max_health := 100.0
	var buffs: Array = []
	func is_dead() -> bool: return health <= 0.0
	func _apply_buff(buff: Dictionary) -> void: buffs.append(buff.duplicate(true))

class FakePlayer extends CharacterBody3D:
	signal died
	var vitals := FakeVitals.new()

class FakeWorld extends Node3D:
	var simulation_only := false

class FixtureLightning extends LIGHTNING:
	var fixture_actors := {}
	func _actors() -> Dictionary: return fixture_actors
	func exposed(_at: Vector3, _body: Node3D = null) -> bool: return true

var session: FakeSession
var lightning: FixtureLightning
var player: FakePlayer
var remote: FakePlayer
var surge: FakeSurge
var receive_world: FakeWorld

func before_each() -> void:
	session = FakeSession.new()
	player = FakePlayer.new()
	remote = FakePlayer.new()
	receive_world = FakeWorld.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(receive_world)
	receive_world.add_child(player)
	player.name = "Player"
	receive_world.add_child(remote)
	lightning = FixtureLightning.new()
	lightning.session = session
	surge = FakeSurge.new()
	lightning.surge = surge
	lightning.fixture_actors = {1: player, 2: remote}

func after_each() -> void:
	if lightning != null: lightning.free()
	if player != null and is_instance_valid(player): player.free()
	if remote != null and is_instance_valid(remote): remote.free()
	if surge != null: surge.free()
	if session != null: session.free()
	if receive_world != null: receive_world.free()

func test_host_resolver_only_hits_actors_still_inside_three_metres() -> void:
	player.global_position = Vector3(2.9, 0, 0)
	remote.global_position = Vector3(3.01, 0, 0)
	lightning._resolve({"id": 7, "at": Vector3.ZERO, "peers": [1, 2]})
	assert_eq(session.published.size(), 1)
	assert_eq(str(session.published[0].kind), "impact")
	assert_true(session.published[0].hits.has(1), "the actor still inside receives a host hit")
	assert_false(session.published[0].hits.has(2), "the actor outside avoids the host hit")
	player.global_position = Vector3(4, 0, 0)
	lightning._resolve({"id": 8, "at": Vector3.ZERO, "peers": [1, 2]})
	assert_true(session.published[1].hits.is_empty(), "both warned actors have now moved clear")

func test_safe_ground_policy_refuses_ashfoot_and_accepts_open_deepwood() -> void:
	assert_false(lightning.rules.eligible_ground(Vector3(-350, 0, 450), "deepwood", false), "Ashfoot is a safe zone")
	assert_true(lightning.rules.eligible_ground(Vector3(100, 0, 100), "deepwood", false), "open Deepwood remains eligible")

func test_session_refuses_client_publication() -> void:
	var real_session: Node = SESSION.new()
	var received: Array = []
	real_session.stormwood_strike_received.connect(func(event: Dictionary) -> void: received.append(event))
	real_session._mode = "client"
	real_session.publish_stormwood_strike({"id": 3, "kind": "warning"})
	assert_eq(received.size(), 0, "client publication cannot even emit a local hazard")
	real_session._mode = ""
	real_session.publish_stormwood_strike({"id": 4, "kind": "warning"})
	assert_eq(received.size(), 1, "the offline host can publish a hazard")
	real_session.free()

func test_duplicate_impact_id_does_not_damage_twice() -> void:
	lightning.world = receive_world
	lightning._receive({"id": 9, "kind": "impact", "at": Vector3.ZERO,
		"hits": {1: {"damage": 20.0, "static_seconds": 8.0}}})
	var after_first := player.vitals.health
	lightning._receive({"id": 9, "kind": "impact", "at": Vector3.ZERO,
		"hits": {1: {"damage": 20.0, "static_seconds": 8.0}}})
	assert_eq(after_first, 80.0)
	assert_eq(player.vitals.health, after_first, "replayed impact ID is ignored")
