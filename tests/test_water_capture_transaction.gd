extends "res://tests/test_case.gd"

const TX := preload("res://scripts/save/water_capture_transaction.gd")
const PARTY := preload("res://autoload/party.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

class Local extends RefCounted:
	var character_id := "capturer"
	var party := PARTY.new()
	var flags := FLAGS.new()
	var skills := preload("res://scripts/player/player_skills.gd").new()

class World extends RefCounted:
	var world_id := "capture-world"

class Saver extends RefCounted:
	var fail := false
	var snapshots: Array = []
	func save_character(game: Object, id: String) -> bool:
		snapshots.append({"character_id":id, "members":game.local.party.members(), "flags":game.local.flags.save_data(), "skills":game.local.skills.save_data()})
		return not fail

class GameFixture extends RefCounted:
	var local := Local.new()
	var world := World.new()
	var save_system := Saver.new()
	var pending_catch: RefCounted

func claim() -> Dictionary:
	return {"id":"aquaryn-claim-1", "character_id":"capturer", "world_id":"capture-world"}

func fixture(count: int = 0) -> RefCounted:
	var game := GameFixture.new()
	for i in count:
		game.local.party.add(SPECIES.spawn("water_mosshell"))
	game.pending_catch = SPECIES.spawn("water_aquaryn")
	game.local.flags.set_flag("existing")
	return game

func test_receipt_and_party_are_visible_in_one_save_and_replay_is_inert() -> void:
	var game := fixture(2)
	var pending: RefCounted = game.pending_catch
	var result := TX.settle(game, claim(), pending)
	assert_true(result.ok)
	assert_false(result.already)
	assert_eq(game.save_system.snapshots.size(), 1)
	assert_eq(game.save_system.snapshots[0].members.size(), 3)
	assert_true(game.save_system.snapshots[0].members[2] == pending)
	assert_true(game.save_system.snapshots[0].flags.flags.has("water_capture_receipt:aquaryn-claim-1"))
	assert_true(game.pending_catch == pending)
	var revision: int = game.local.party.revision
	var flag_revision: int = game.local.flags.revision
	assert_true(TX.settle(game, claim(), null).already)
	assert_eq(game.local.party.revision, revision)
	assert_eq(game.local.flags.revision, flag_revision)
	assert_eq(game.save_system.snapshots.size(), 1)

func test_failed_save_restores_exact_members_order_selection_and_flags() -> void:
	for count in [2, 5]:
		var game := fixture(count)
		game.local.party.set_active(count - 1)
		game.local.party.set("_best", 1)
		var before: Array = game.local.party.members()
		var party_revision: int = game.local.party.revision
		var flag_revision: int = game.local.flags.revision
		var flags_before: Dictionary = game.local.flags.save_data()
		game.save_system.fail = true
		var result := TX.settle(game, claim(), game.pending_catch, 1)
		assert_false(result.ok)
		assert_eq(game.local.party.members(), before)
		for i in count: assert_true(game.local.party.at(i) == before[i])
		assert_eq(game.local.party.active_index(), count - 1)
		assert_eq(game.local.party.get("_best"), 1)
		assert_eq(game.local.party.revision, party_revision)
		assert_eq(game.local.flags.revision, flag_revision)
		assert_eq(game.local.flags.save_data(), flags_before)
		assert_false(game.local.party.members().has(game.pending_catch))
		game.save_system.fail = false
		assert_true(TX.settle(game, claim(), game.pending_catch, 1).ok)

func test_full_party_replacement_keeps_other_members_in_place_and_decline_is_durable() -> void:
	var game := fixture(5)
	game.local.party.set_active(4)
	game.local.party.set("_best", 3)
	var before: Array = game.local.party.members()
	assert_false(TX.settle(game, claim(), game.pending_catch).ok)
	assert_eq(game.save_system.snapshots.size(), 0)
	var result := TX.settle(game, claim(), game.pending_catch, 1)
	assert_true(result.ok)
	assert_true(result.released == before[1])
	assert_eq(game.local.party.size(), 5)
	for i in 5: assert_true(game.local.party.at(i) == (game.pending_catch if i == 1 else before[i]))
	assert_eq(game.local.party.active_index(), 4)
	assert_eq(game.local.party.get("_best"), 3)
	var declined := fixture(5)
	var original: Array = declined.local.party.members()
	var declined_result := TX.settle(declined, claim(), declined.pending_catch, 5)
	assert_true(declined_result.ok)
	assert_true(declined_result.released == declined.pending_catch)
	assert_eq(declined.local.party.members(), original)
	assert_true(declined.local.flags.has("water_capture_receipt:aquaryn-claim-1"))
	assert_eq(declined.save_system.snapshots.size(), 1)
	assert_true(TX.settle(declined, claim(), declined.pending_catch, 0).already)
	assert_eq(declined.local.party.members(), original)

func test_wrong_identity_invalid_claim_and_owned_pending_never_mutate() -> void:
	var game := fixture(1)
	var before: Array = game.local.party.members()
	for key: String in ["character_id", "world_id", "id"]:
		var wrong := claim()
		wrong[key] = "" if key == "id" else "someone-else"
		assert_false(TX.settle(game, wrong, game.pending_catch).ok)
	assert_false(TX.settle(game, claim(), null).ok)
	assert_false(TX.settle(game, claim(), before[0]).ok)
	assert_eq(game.local.party.members(), before)
	assert_eq(game.save_system.snapshots.size(), 0)
	assert_false(game.local.flags.has("water_capture_receipt:aquaryn-claim-1"))

func test_failed_decline_remains_retryable_and_released_best_loses_title() -> void:
	var game := fixture(5)
	var before: Array = game.local.party.members()
	var revision: int = game.local.flags.revision
	game.save_system.fail = true
	assert_false(TX.settle(game, claim(), game.pending_catch, 5).ok)
	assert_eq(game.local.party.members(), before)
	assert_eq(game.local.flags.revision, revision)
	assert_false(game.local.flags.has("water_capture_receipt:aquaryn-claim-1"))
	assert_false(TX.settle(game, claim(), game.pending_catch, 6).ok)
	assert_eq(game.save_system.snapshots.size(), 1)
	game.save_system.fail = false
	game.local.party.set("_best", 2)
	game.local.party.set_active(2)
	assert_true(TX.settle(game, claim(), game.pending_catch, 2).ok)
	assert_true(game.local.party.active() == game.pending_catch)
	assert_eq(game.local.party.get("_best"), -1)

func test_catching_xp_saves_with_receipt_and_rolls_back_on_failure() -> void:
	var game := fixture(2)
	var before: Dictionary = game.local.skills.save_data()
	var revision: int = game.local.skills.revision
	game.save_system.fail = true
	assert_false(TX.settle(game, claim(), game.pending_catch).ok)
	assert_eq(game.local.skills.save_data(), before)
	assert_eq(game.local.skills.revision, revision)
	game.save_system.fail = false
	assert_true(TX.settle(game, claim(), game.pending_catch).ok)
	var saved: Dictionary = game.save_system.snapshots.back().skills
	assert_true(float(saved.xp.catching) > 0 or int(saved.levels.catching) > 0)
	assert_true(TX.settle(game, claim(), null).already)
	assert_eq(game.local.skills.save_data(), saved, "Claim replay cannot farm Catching XP")
