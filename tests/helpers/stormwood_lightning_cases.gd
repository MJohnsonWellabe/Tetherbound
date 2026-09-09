extends "res://tests/test_case.gd"

## Deferred scene-smoke cases. It drives the shipping resolver/receiver while only
## replacing actor discovery and the physics roof query.
const LIGHTNING := preload("res://scripts/world/stormwood_lightning.gd")
const SESSION := preload("res://scripts/net/session.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const PLAYER_EQUIPMENT := preload("res://scripts/player/player_equipment.gd")

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
	# Production _ready discovers the live world/session/surge. This initialized
	# fixture injects those collaborators before entering the tree.
	func _ready() -> void: pass
	func _actors() -> Dictionary: return fixture_actors
	func exposed(_at: Vector3, _body: Node3D = null) -> bool: return true

var session: FakeSession
var lightning: FixtureLightning
var player: FakePlayer
var remote: FakePlayer
var surge: FakeSurge
var receive_world: FakeWorld
var game: Node
var previous_equipment: RefCounted
var equipment: RefCounted

func before_each() -> void:
	session = FakeSession.new()
	player = FakePlayer.new()
	remote = FakePlayer.new()
	receive_world = FakeWorld.new()
	game = (Engine.get_main_loop() as SceneTree).root.get_node("Game")
	previous_equipment = game.get("player_equipment")
	equipment = PLAYER_EQUIPMENT.new()
	equipment.call("configure", ITEM_DB.new())
	game.set("player_equipment", equipment)
	(Engine.get_main_loop() as SceneTree).root.add_child(receive_world)
	receive_world.add_child(player)
	player.name = "Player"
	receive_world.add_child(remote)
	lightning = FixtureLightning.new()
	lightning.session = session
	surge = FakeSurge.new()
	lightning.surge = surge
	lightning.fixture_actors = {1: player, 2: remote}
	receive_world.add_child(lightning)

func after_each() -> void:
	if lightning != null: lightning.free()
	if player != null and is_instance_valid(player): player.free()
	if remote != null and is_instance_valid(remote): remote.free()
	if surge != null: surge.free()
	if session != null: session.free()
	if receive_world != null: receive_world.free()
	if game != null: game.set("player_equipment", previous_equipment)

func test_host_resolver_only_hits_actors_still_inside_three_metres() -> void:
	player.global_position = Vector3(2.9, 0, 0)
	remote.global_position = Vector3(3.01, 0, 0)
	lightning._resolve({"id": 7, "at": Vector3.ZERO, "peers": [1, 2]})
	assert_eq(session.published.size(), 1)
	assert_eq(str(session.published[0].kind), "impact")
	assert_true(session.published[0].hits.has(1), "the actor still inside receives a host hit")
	assert_false(session.published[0].hits.has(2), "the actor outside avoids the host hit")
	assert_true(float(session.published[0].hits[1].damage) > 0.0,
		"host verdict remains the unmitigated regional effect")
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


func test_real_worn_vest_reduces_damage_and_static_duration() -> void:
	lightning.world = receive_world
	assert_true(bool(equipment.call("equip", "insulated_vest").get("ok", false)),
		"real insulated vest equips in its authored slot")
	lightning._receive({"id": 10, "kind": "impact", "at": Vector3.ZERO,
		"hits": {1: {"damage": 20.0, "static_seconds": 8.0}}})
	assert_almost_eq(player.vitals.health, 84.0, 0.001,
		"worn vest applies its authored 20 percent strike reduction")
	assert_almost_eq(float(player.vitals.buffs[0].duration_s), 6.4, 0.001,
		"worn vest applies its authored 0.8 Static duration scale")


func test_full_worn_set_keeps_stagger_but_adds_no_damage_or_static() -> void:
	lightning.world = receive_world
	for id: String in ["insulated_helm", "insulated_vest", "insulated_leggings", "insulated_boots"]:
		equipment.call("equip", id)
	player.vitals.buffs.append({"id": "stormwood_static", "duration_s": 2.0})
	player.velocity = Vector3(8.0, 0.0, 4.0)
	lightning._receive({"id": 11, "kind": "impact", "at": Vector3.ZERO,
		"hits": {1: {"damage": 20.0, "static_seconds": 8.0}}})
	assert_eq(player.vitals.health, 100.0, "full worn set makes strike damage zero")
	assert_true(player.vitals.buffs.size() == 1 and str(player.vitals.buffs[0].id) == "stormwood_static",
		"full worn set adds no Static buff and does not clear an existing one")
	assert_eq(player.velocity, Vector3(2.0, 0.0, 1.0), "full worn set still staggers")


func test_unequipping_one_piece_removes_full_set_immunity() -> void:
	lightning.world = receive_world
	for id: String in ["insulated_helm", "insulated_vest", "insulated_leggings", "insulated_boots"]:
		equipment.call("equip", id)
	assert_eq(str(equipment.call("unequip", "boots")), "insulated_boots")
	lightning._receive({"id": 12, "kind": "impact", "at": Vector3.ZERO,
		"hits": {1: {"damage": 20.0, "static_seconds": 8.0}}})
	assert_true(player.vitals.health < 100.0, "three worn pieces still take damage")
	assert_true(player.vitals.buffs.size() == 1 and float(player.vitals.buffs[0].duration_s) > 0.0,
		"three worn pieces still receive shortened Static")


func test_remote_addressed_impact_does_not_use_local_gear_or_vitals() -> void:
	lightning.world = receive_world
	equipment.call("equip", "insulated_vest")
	lightning._receive({"id": 13, "kind": "impact", "at": Vector3.ZERO,
		"hits": {2: {"damage": 20.0, "static_seconds": 8.0}}})
	assert_eq(player.vitals.health, 100.0, "impact for a remote peer does not touch local vitals")
	assert_eq(player.vitals.buffs.size(), 0, "remote peer hit adds no local Static")


func test_mitigation_applies_after_low_max_health_damage_cap() -> void:
	lightning.world = receive_world
	equipment.call("equip", "insulated_vest")
	player.vitals.max_health = 40.0
	player.vitals.health = 40.0
	lightning._receive({"id": 14, "kind": "impact", "at": Vector3.ZERO,
		"hits": {1: {"damage": 20.0, "static_seconds": 8.0}}})
	assert_almost_eq(player.vitals.health, 32.0, 0.001,
		"worn reduction applies to the already capped unarmoured hit")
