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


# --- Coordinator strike ruling (WO-F11-04): wiring through the production `_process` / `_resolve` path -------------
#
# The cases above call only the pure helpers. These drive the shipping
# `_process` loop (which chooses a warning and then resolves it at impact)
# with its real `_trainer_in_fight` read of the world's CombatManager, so
# deleting the spare call from either the aim or the impact fails them.
# Replaced: live discovery (`_ready`), actor listing and the roof query.

class WiringSession extends Node:
	var published: Array[Dictionary] = []
	func is_host() -> bool: return true
	func local_peer_id() -> int: return 1
	func realm_of(_peer: int) -> String: return "stormwood"
	func publish_stormwood_strike(event: Dictionary) -> void: published.append(event.duplicate(true))

class WiringSurge extends Node:
	func region_at(_at: Vector3) -> String: return "deepwood"
	func phase_at_position(_at: Vector3) -> String: return "break"

class WiringManager extends Node:
	var fighting := false
	func is_fighting() -> bool: return fighting

class WiringDirector extends Node:
	var creature: Node3D
	func trainer_battle_active() -> bool: return false
	func deployed_body_for(_peer: int) -> Variant: return creature

class WiringWorld extends Node3D:
	var simulation_only := false
	func ground_height_near(_at: Vector3) -> float: return 0.0

class WiringLightning extends LIGHTNING:
	var trainer: Node3D
	func _ready() -> void: pass
	func _actors() -> Dictionary: return {1: trainer}
	func exposed(_at: Vector3, _body: Node3D = null) -> bool: return true


const SPARE_TRAINER := Vector3(10, 0, 20)


func _wiring(spare: bool) -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var world := WiringWorld.new()
	tree.root.add_child(world)
	var manager := WiringManager.new()
	manager.name = "CombatManager"
	world.add_child(manager)
	var director := WiringDirector.new()
	director.name = "EncounterDirector"
	world.add_child(director)
	var trainer := Node3D.new()
	world.add_child(trainer)
	trainer.global_position = SPARE_TRAINER
	# Inside the 3 m strike radius of the trainer, so an impact aimed at the
	# creature would still hit the trainer if the impact check were missing.
	var creature := Node3D.new()
	world.add_child(creature)
	creature.global_position = SPARE_TRAINER + Vector3(2.0, 0.0, 0.0)
	director.creature = creature
	var lightning := WiringLightning.new()
	lightning.world = world
	lightning.session = WiringSession.new()
	lightning.surge = WiringSurge.new()
	lightning.trainer = trainer
	lightning.rules.config.strike["spare_trainer_in_fight"] = spare
	world.add_child(lightning)
	var game := tree.root.get_node_or_null(^"Game")
	return {"world": world, "manager": manager, "creature": creature, "lightning": lightning,
		"game": game, "environment": (game.get("realm_environment") as Dictionary).duplicate(true) if game != null else {}}


func _wiring_free(fixture: Dictionary) -> void:
	var lightning: Node = fixture.lightning
	(lightning.get("session") as Node).free()
	(lightning.get("surge") as Node).free()
	(fixture.world as Node).free()
	if fixture.game != null:
		(fixture.game as Node).set("realm_environment", fixture.environment)


## `_next` elapsed: the real loop chooses and publishes one warning.
func _warn(fixture: Dictionary) -> Dictionary:
	var lightning: Node = fixture.lightning
	lightning.set("_next", 0.0)
	lightning.call("_process", 0.0)
	var published: Array = (lightning.get("session") as Node).get("published")
	assert_eq(published.size(), 1, "the real _process published one warning")
	return published[0] if published.size() == 1 else {}


## The telegraph runs out: the real loop resolves the pending impact.
func _impact(fixture: Dictionary) -> Dictionary:
	var lightning: Node = fixture.lightning
	lightning.set("_next", 99.0)
	lightning.call("_process", 1.3)
	var published: Array = (lightning.get("session") as Node).get("published")
	assert_eq(published.size(), 2, "the real _process resolved the pending warning")
	return published[1] if published.size() == 2 else {}


func test_process_aims_a_fighting_trainers_strike_at_the_creature() -> void:
	var fixture := _wiring(true)
	(fixture.manager as Node).set("fighting", true)
	var warning := _warn(fixture)
	var at: Vector3 = warning.get("at", Vector3.INF)
	var creature_at: Vector3 = (fixture.creature as Node3D).global_position
	assert_almost_eq(at.x, creature_at.x, 0.001, "the warning is on the piloted creature, not the trainer")
	assert_almost_eq(at.z, creature_at.z, 0.001)
	var impact := _impact(fixture)
	assert_false((impact.get("hits", {}) as Dictionary).has(1),
		"the fighting trainer standing 2 m from the impact is not hit")
	_wiring_free(fixture)


## Fight state is read at impact, not at the warning: a trainer warned while
## walking who is in a fight when the strike lands is spared.
func test_impact_rechecks_fight_state_after_the_warning() -> void:
	var fixture := _wiring(true)
	var warning := _warn(fixture)
	var at: Vector3 = warning.get("at", Vector3.INF)
	assert_almost_eq(at.x, SPARE_TRAINER.x, 0.001, "a walking trainer is aimed at")
	(fixture.manager as Node).set("fighting", true)
	var impact := _impact(fixture)
	assert_false((impact.get("hits", {}) as Dictionary).has(1),
		"the fight began before the impact, so the trainer is not hit")
	_wiring_free(fixture)


## Control: the same path does hit a trainer who is not fighting at impact
## (a fight that ended before the strike landed).
func test_impact_hits_a_trainer_whose_fight_ended_before_it_landed() -> void:
	var fixture := _wiring(true)
	(fixture.manager as Node).set("fighting", true)
	_warn(fixture)
	(fixture.manager as Node).set("fighting", false)
	var impact := _impact(fixture)
	assert_true((impact.get("hits", {}) as Dictionary).has(1),
		"with the fight over, the trainer 2 m from the impact is hit")
	_wiring_free(fixture)


## Negative control: with the ruling's flag off, the same fighting trainer is
## aimed at and hit through the same path.
func test_process_negative_control_flag_off_hits_the_fighting_trainer() -> void:
	var fixture := _wiring(false)
	(fixture.manager as Node).set("fighting", true)
	var warning := _warn(fixture)
	var at: Vector3 = warning.get("at", Vector3.INF)
	assert_almost_eq(at.x, SPARE_TRAINER.x, 0.001, "flag off: the fighting trainer is aimed at")
	var impact := _impact(fixture)
	assert_true((impact.get("hits", {}) as Dictionary).has(1), "flag off: the fighting trainer is hit")
	_wiring_free(fixture)
