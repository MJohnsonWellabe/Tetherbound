extends "res://tests/test_case.gd"

const REWARD := preload("res://scripts/world/water_alpha_rewards.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")

class Saver extends RefCounted:
	var fail_write := false
	var writes := 0
	var store: RefCounted
	func _init() -> void:
		store = WORLD_SAVE.new("user://alpha_rewards_%d/" % Time.get_ticks_usec())
	func save_world(game: Object, id: String) -> bool:
		writes += 1
		# Exercise the production v22 scope partition as SaveGame.save_world
		# does, not just a hand-written flags file that bypasses scope routing.
		var snapshot: Dictionary = game.world.save_data()
		snapshot.progression = game.world.flags.save_data()
		return false if fail_write else store.write(id, WORLD_SAVE.partition(snapshot))

class GameFixture extends RefCounted:
	var host := true
	var world: RefCounted = WORLD.new()
	var save_system: RefCounted = Saver.new()
	func is_host() -> bool:
		return host

func fixture() -> RefCounted:
	var game := GameFixture.new()
	game.world.world_id = "alpha-reward-world"
	return game

func test_result_and_stable_entitlements_round_trip_real_world_file() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var capture := REWARD.capture_claim(game.world.world_id, "character-A", {"species_id": "water_aquaryn", "level": 49})
	var result := REWARD.resolve(game, ledger, "caught", ["character-A", "character-B", "character-A"], capture)
	assert_true(result.ok)
	assert_eq(result.delta.ops.size(), 4)
	assert_eq(game.save_system.writes, 1)
	var restored := WORLD.new()
	restored.load_data(game.save_system.store.read(game.world.world_id))
	assert_true(restored.flags.has(REWARD.RESOLVED))
	assert_eq(restored.water_capture_claims.get(capture.id), JSON.parse_string(JSON.stringify(capture)), "Capture and entitlement survive the same actual world file")
	assert_true(restored.flags.has(REWARD.outcome_flag("caught")))
	assert_true(REWARD.entitled(restored, "character-A"))
	assert_true(REWARD.entitled(restored, "character-B"))
	assert_false(REWARD.entitled(restored, "bystander"))
	assert_eq(FLAGS.scope_of(REWARD.entitlement("character-A")), "world")
	assert_eq(FLAGS.scope_of(REWARD.outcome_flag("caught")), "world")
	assert_eq(FLAGS.scope_of(REWARD.STONE), "player")
	var reconnected := fixture()
	reconnected.world = restored
	var new_ledger := LEDGER.new(restored)
	assert_true(REWARD.grant(reconnected, new_ledger, "character-A", 19281).ok)
	assert_false(REWARD.grant(fixture(), LEDGER.new(WORLD.new()), "character-A", 19281).ok)
	var repeated := REWARD.resolve(game, ledger, "won", ["bystander"])
	assert_true(repeated.ok)
	assert_true(repeated.delta.ops.is_empty())
	assert_false(REWARD.entitled(game.world, "bystander"))
	assert_false(game.world.flags.has(REWARD.outcome_flag("won")))
	assert_eq(game.save_system.writes, 1)

func test_journal_failure_rolls_back_before_grant_and_can_retry() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	game.world.flags.set_flag("existing_world_fact", true)
	var before: Dictionary = game.world.save_data()
	game.save_system.fail_write = true
	var refused := REWARD.resolve(game, ledger, "won", ["character-A"])
	assert_false(refused.ok)
	assert_eq(refused.code, "journal_failed")
	assert_true(refused.delta.ops.is_empty())
	assert_eq(game.world.save_data(), before)
	assert_eq(ledger.seq, 0)
	assert_false(REWARD.grant(game, ledger, "character-A", 1).ok)
	game.save_system.fail_write = false
	assert_true(REWARD.resolve(game, ledger, "won", ["character-A"]).ok)
	assert_true(REWARD.grant(game, ledger, "character-A", 1).ok)

func test_reconnect_reissues_only_the_entitled_characters_idempotent_flag() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	assert_true(REWARD.resolve(game, ledger, "won", ["character-A"]).ok)
	var flags := FLAGS.new()
	for peer in [1, 8821, 9923]:
		var grant := REWARD.grant(game, ledger, "character-A", peer)
		assert_true(grant.ok)
		assert_eq(grant.delta.ops.size(), 1)
		var op: Dictionary = grant.delta.ops[0]
		assert_eq(op.peers, [peer])
		assert_eq(op.id, REWARD.STONE)
		assert_eq(op.scope, "player")
		assert_eq(op.op, "flag")
		flags.set_flag(op.id, op.value)
	assert_eq(flags.save_data().flags, [REWARD.STONE])
	assert_false(REWARD.grant(game, ledger, "character-B", 8821).ok)
	assert_false(REWARD.grant(game, ledger, "character-A", 0).ok)
	assert_eq(game.save_system.writes, 1)

func test_rejects_nonhost_nonvictory_missing_identity_and_wrong_world_ledger() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	for outcome in ["lost", "fled", "", "resolving"]:
		assert_false(REWARD.resolve(game, ledger, outcome, ["character-A"]).ok)
	for ids in [[], [""], [1], [" character-A"], ["character-A", null]]:
		assert_false(REWARD.resolve(game, ledger, "won", ids).ok)
	game.host = false
	assert_false(REWARD.resolve(game, ledger, "won", ["character-A"]).ok)
	assert_false(REWARD.grant(game, ledger, "character-A", 1).ok)
	game.host = true
	assert_false(REWARD.resolve(game, LEDGER.new(WORLD.new()), "won", ["character-A"]).ok)
	assert_eq(game.save_system.writes, 0)
	assert_false(game.world.flags.has(REWARD.RESOLVED))
