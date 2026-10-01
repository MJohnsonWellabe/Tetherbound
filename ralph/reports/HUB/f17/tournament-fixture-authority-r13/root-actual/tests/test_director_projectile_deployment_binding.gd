extends "res://tests/test_case.gd"

## Real CombatManager request_switch / trainer auto-faint, real Director
## signal connector, announcement, lifetime and arrival guard. Only scene,
## presentation/card arithmetic and the admitted Session boundary are fixtures.
## No direct calls to the switch handler or deployment-generation writer.
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const DEFINITION := {"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0}


class BodyFixture extends Node3D:
	var species_id := "terrapup"
	var shiny := false
	var setup_calls := 0
	func setup(species: String, is_shiny: bool) -> void:
		species_id = species
		shiny = is_shiny
		setup_calls += 1


class SessionFixture extends Node:
	var owners := {1: "character-local", 2: "character-guest"}
	func _authority_character(peer_id: int) -> String:
		return str(owners.get(peer_id, ""))


class HostFixture extends RefCounted:
	func record(_encounter_id: String) -> Dictionary:
		return {"participants": {1: {"actor_generation": 0}, 2: {"actor_generation": 0}}}


class DirectorFixture extends "res://scripts/combat/encounter_director.gd":
	var proxy_spawns := 0
	func _local_peer_id() -> int:
		return 1
	func _local_character_id() -> String:
		return "character-local"
	func _is_multi_peer() -> bool:
		return false
	func _is_best_creature(_creature: RefCounted) -> bool:
		return false
	func _creature_card(creature: RefCounted) -> Dictionary:
		return {"creature_uid": str(creature.get("uid"))}
	func _spawn_creature_proxy(_peer_id: int) -> void:
		proxy_spawns += 1
	func _despawn_creature_proxy(_peer_id: int) -> void:
		pass


func _fixture(with_session: bool = true) -> Dictionary:
	var a: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	var b: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	a.set("uid", "owned-a")
	b.set("uid", "owned-b")
	var body := BodyFixture.new()
	var manager: Node = MANAGER.new()
	manager.set("_party", [a, b] as Array[RefCounted])
	manager.set("_active_index", 0)
	manager.set("_ally_body", body)
	manager.set("state", MANAGER.State.ACTIVE)
	var host := HostFixture.new()
	var session := SessionFixture.new()
	var director := DirectorFixture.new()
	director.set("_manager", manager)
	director.set("_ally", a)
	director.set("_ally_body", body)
	director.set("_encounter_host", host)
	if with_session:
		director.set("_session", session)
	# This is the connector called by production _ready, not a test-only wire.
	director.call("_connect_combat_manager_signals")
	director.call("_announce_deployment", a)
	return {"director": director, "manager": manager, "body": body,
		"host": host, "session": session, "a": a, "b": b}


func _dispose(fixture: Dictionary) -> void:
	(fixture.director as Node).free()
	(fixture.manager as Node).free()
	(fixture.body as Node).free()
	(fixture.session as Node).free()


func _binding(fixture: Dictionary, peer_id: int = 1) -> Dictionary:
	return fixture.director.call("_strike_actor_binding", "encounter-1", peer_id, fixture.body)


func _arrival_matches(fixture: Dictionary, binding: Dictionary, peer_id: int = 1) -> bool:
	return bool(fixture.director.call("_strike_actor_binding_matches", "encounter-1", peer_id, fixture.body, binding))


func test_actual_switch_away_and_back_invalidates_old_projectile_on_same_body() -> void:
	var fixture := _fixture()
	var before := _binding(fixture)
	assert_false(before.is_empty(), "a launched legacy actor must have a usable binding")
	assert_eq(int(before.get("actor_generation", -1)), 0, "exercise the flag-off legacy case")
	assert_true(bool(fixture.manager.call("request_switch", 1)))
	assert_eq(str(_binding(fixture).get("creature_uid", "")), "owned-b", "the actual signal updates the director immediately")
	assert_false(_arrival_matches(fixture, before))
	assert_false(bool(fixture.manager.call("request_switch", 0)), "the real voluntary lockout remains in force")
	# Model elapsed lockout; do not bypass request_switch or its signal.
	fixture.manager.set("_switch_lockout", 0.0)
	assert_true(bool(fixture.manager.call("request_switch", 0)))
	var after := _binding(fixture)
	assert_eq(after.get("creature_uid"), before.get("creature_uid"))
	assert_eq(after.get("body_instance_id"), before.get("body_instance_id"))
	assert_eq(int(fixture.body.get("setup_calls")), 0, "same-species switching does not reskin or replace the body")
	assert_true(int(after.get("deployment_generation", 0)) > int(before.get("deployment_generation", 0)))
	assert_false(_arrival_matches(fixture, before), "returning to the same UID cannot revive its older projectile")
	_dispose(fixture)


func test_actual_trainer_auto_faint_signal_invalidates_old_projectile() -> void:
	var fixture := _fixture()
	var before := _binding(fixture)
	fixture.a.set("fainted", true)
	fixture.a.set("hp", 0.0)
	fixture.manager.set("_enemy_owned", true)
	fixture.manager.call("_handle_active_faint")
	assert_eq(int(fixture.manager.get("_active_index")), 1)
	assert_eq(str(_binding(fixture).get("creature_uid", "")), "owned-b")
	assert_false(_arrival_matches(fixture, before), "auto-faint uses the same production signal hook")
	_dispose(fixture)


func test_local_solo_without_session_preserves_refresh_and_fences_recall() -> void:
	var fixture := _fixture(false)
	var before := _binding(fixture)
	assert_false(before.is_empty(), "legacy local solo uses Game's local character when Session is absent")
	fixture.director.call("_announce_deployment", fixture.a)
	assert_true(_arrival_matches(fixture, before), "same-creature card refresh preserves its lifetime")
	fixture.director.call("_announce_recall")
	assert_false(_arrival_matches(fixture, before), "solo recall invalidates before the multiplayer early return")
	fixture.director.call("_announce_deployment", fixture.a)
	assert_false(_arrival_matches(fixture, before), "redeploying the same UID on the same fixture body stays fenced")
	assert_true(bool(fixture.manager.call("request_switch", 1)), "the real switch also works without Session")
	assert_eq(str(_binding(fixture).get("creature_uid", "")), "owned-b")
	_dispose(fixture)


func test_guest_claim_is_normalized_and_arrival_rechecks_session_owner() -> void:
	var fixture := _fixture()
	var row := {"character_id": "forged-owner", "creature_uid": "guest-a",
		"species_id": "terrapup", "shiny": false, "card": {"creature_uid": "guest-a"}}
	fixture.director.call("_host_set_deployed", 2, row)
	var before := _binding(fixture, 2)
	assert_eq(before.get("character_id"), "character-guest", "host identity comes from the admitted Session")
	assert_eq(row.get("character_id"), "forged-owner", "normalization does not mutate the caller's packet")
	var deployed: Dictionary = fixture.director.get("_deployed_by")
	assert_eq((deployed.get(2, {}) as Dictionary).get("character_id"), "character-guest")
	var refreshed := row.duplicate(true)
	refreshed["character_id"] = "another-forged-owner"
	(refreshed.card as Dictionary)["active_relic_id"] = "livewire"
	fixture.director.call("_host_set_deployed", 2, refreshed)
	assert_true(_arrival_matches(fixture, before, 2), "a claim-only/card refresh cannot change the authoritative lifetime")
	assert_eq(int(fixture.director.get("proxy_spawns")), 1, "refresh preserves the existing same-species proxy")
	var owners: Dictionary = fixture.session.get("owners")
	owners[2] = "replacement-character"
	assert_false(_arrival_matches(fixture, before, 2), "arrival consults Session again even without another deployment packet")
	owners.erase(2)
	assert_false(_arrival_matches(fixture, before, 2), "withdrawn owner cannot finish the old projectile")
	fixture.director.call("_host_set_deployed", 3, row)
	deployed = fixture.director.get("_deployed_by")
	assert_false(deployed.has(3), "unadmitted guests cannot install a deployment")
	_dispose(fixture)
