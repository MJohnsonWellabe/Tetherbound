extends "res://tests/test_case.gd"

const FLY := preload("res://scripts/player/fly_controller.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const SAVE_FIXTURE := preload("res://tests/test_save_format.gd")

class FlyGame extends Node:
	var party: RefCounted = PARTY.new()
	var progression: RefCounted = PROGRESSION.new()
	var current_realm := "cloudreach"

var fly: Node
var game: Node


func before_each() -> void:
	fly = FLY.new()
	game = FlyGame.new()
	fly._game = game
	fly.config = JSON.parse_string(FileAccess.get_file_as_string(FLY.CONFIG_PATH))


func after_each() -> void:
	fly.free()
	game.free()


func test_owned_active_healthy_carrier_is_preferred_without_sixth_slot() -> void:
	assert_eq(fly.eligible_creature(), null)
	for i in 4:
		assert_true(game.party.add(SPECIES.spawn("bramblebun")))
	var bird: RefCounted = SPECIES.spawn("galecrest")
	assert_true(game.party.add(bird))
	assert_eq(fly.eligible_creature(), null, "owned but inactive bird is ineligible")
	assert_true(game.party.set_active(4))
	assert_eq(fly.eligible_creature(), bird)
	assert_eq(game.party.size(), 5)
	assert_false(game.party.add(SPECIES.spawn("galecrest")), "no hidden sixth slot")
	bird.fainted = true
	game.progression.set_flag("fly_traversal_unlocked")
	assert_ne(fly.eligible_creature(), bird, "a fainted owned carrier is never used")
	assert_false((game.party.members() as Array).has(fly.eligible_creature()), "mentor loaner is not secretly owned")
	bird.fainted = false
	bird.resting = true
	assert_ne(fly.eligible_creature(), bird, "a resting owned carrier is never used")


func test_full_non_fly_party_gets_transient_maela_carrier_for_trial_and_unlock() -> void:
	for species: String in ["bramblebun", "mudsnout", "terrapup", "brooktail", "sparkit"]:
		assert_true(game.party.add(SPECIES.spawn(species)))
	assert_eq(game.party.size(), 5)
	assert_eq(fly.eligible_creature(), null, "loaner is unavailable before Maela's trial")
	fly.set_trial_authorization(AABB(Vector3(-10, 0, -10), Vector3(20, 40, 20)))
	var trial_carrier: RefCounted = fly.eligible_creature()
	assert_ne(trial_carrier, null)
	assert_eq(str(trial_carrier.species_id), "galecrest")
	assert_false((game.party.members() as Array).has(trial_carrier))
	assert_eq(game.party.size(), 5)
	fly.set_trial_authorization(AABB())
	game.progression.set_flag("fly_traversal_unlocked")
	assert_eq(fly.eligible_creature(), trial_carrier, "same transient carrier remains available after unlock")
	game.current_realm = "meadows"
	assert_eq(fly.eligible_creature(), null, "Cloudreach loaner cannot cross realms")


func test_restrictions_are_swept_and_three_dimensional() -> void:
	game.progression.set_flag("fly_traversal_unlocked")
	fly.register_restriction("upper", AABB(Vector3(10, 0, -5), Vector3(2, 50, 10)), "upper_open")
	assert_false(fly._restricted_reason(Vector3(0, 20, 0), Vector3(30, 20, 0)).is_empty(), "fast flight must not tunnel through a gate")
	assert_true(fly._restricted_reason(Vector3(0, 60, 0), Vector3(30, 60, 0)).is_empty(), "finite authored volumes have explicit extents")
	game.progression.set_flag("upper_open")
	assert_true(fly._restricted_reason(Vector3(0, 20, 0), Vector3(30, 20, 0)).is_empty())


func test_trial_authorization_does_not_unlock_fly_or_allow_leaving_trial() -> void:
	fly.set_trial_authorization(AABB(Vector3(-10, 0, -10), Vector3(20, 50, 20)))
	assert_false(fly._unlocked())
	assert_true(fly._restricted_reason(Vector3(0, 5, 0), Vector3(1, 6, 0)).is_empty())
	assert_false(fly._restricted_reason(Vector3(0, 5, 0), Vector3(30, 6, 0)).is_empty())
	assert_false(game.progression.has("fly_traversal_unlocked"))


func test_airborne_save_load_uses_ground_anchor_and_preserves_stamina_and_active_slot() -> void:
	var fixture: RefCounted = SAVE_FIXTURE.new()
	fixture.before_each()
	var written: RefCounted = fixture._game(false)
	written.current_realm = "cloudreach"
	written.party.add(SPECIES.spawn("bramblebun"))
	written.party.add(SPECIES.spawn("galecrest"))
	written.saved_player_pose = {"realm": "cloudreach", "position": [0, 120, 0], "model_yaw": 0, "camera_yaw": 0, "camera_pitch": 0, "traversal": {"version": 1, "mode": "climb", "realm": "cloudreach", "safe_anchor": [2, 4, 6], "velocity": [0, 18, 0], "stamina_fraction": 0.34, "active_index": 1}}
	assert_true(fixture.saver.save(written, 1))
	var restored: RefCounted = fixture._game(false)
	assert_true(fixture.saver.load_slot(restored, 1))
	assert_almost_eq(float(restored.saved_player_pose.position[1]), 4.08, 0.001)
	assert_eq(restored.party.active_index(), 1)
	assert_almost_eq(float(restored.get_meta("pending_fly_load").stamina_fraction), 0.34, 0.001)
	assert_true(fixture.saver.load_slot(written, 1), "same-object reload also restores safely")
	assert_almost_eq(float(written.saved_player_pose.position[1]), 4.08, 0.001)
	fixture.after_each()


func test_invalid_airborne_anchor_rejects_pose_and_v17_migration_preserves_rewards() -> void:
	var fixture: RefCounted = SAVE_FIXTURE.new()
	fixture.before_each()
	var pose := {"position": [0, 100, 0], "model_yaw": 0, "camera_yaw": 0, "camera_pitch": 0, "traversal": {"version": 1, "mode": "glide", "realm": "meadows", "safe_anchor": [], "velocity": [0, 0, 0], "stamina_fraction": 0.5}}
	assert_true(fixture.saver._sanitise_player_pose(pose).is_empty())
	var migrated: Dictionary = fixture.saver._migrate_v17({"version": 17, "progression": {"fly_traversal_unlocked": true}, "realm_hearts": {"active": "meadows"}})
	assert_eq(migrated.version, 18)
	assert_eq(migrated.progression, {"fly_traversal_unlocked": true})
	assert_eq(migrated.realm_hearts, {"active": "meadows"})
	fixture.after_each()
