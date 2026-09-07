extends "res://tests/test_case.gd"

const REWARD := preload("res://scripts/world/water_guardian_reward.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const SAVE := preload("res://scripts/save/world_save.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")

class Saver extends RefCounted:
	var fail_write := false
	var writes := 0
	var store: RefCounted = SAVE.new("user://guardian_reward_%d/" % Time.get_ticks_usec())
	func save_world(game: Object, id: String) -> bool:
		writes += 1
		var snapshot: Dictionary = game.world.save_data()
		snapshot.progression = game.world.flags.save_data()
		return false if fail_write else store.write(id, SAVE.partition(snapshot))

class GameFixture extends RefCounted:
	var host := true
	var world: RefCounted = WORLD.new()
	var save_system: RefCounted = Saver.new()
	func is_host() -> bool: return host

func fixture() -> RefCounted:
	var game := GameFixture.new()
	game.world.world_id = "guardian-reward-world"
	game.world.flags.set_flag("water_guardian_freed")
	return game

func test_exact_guardian_and_only_one_recipient_survive_real_world_file() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var guardian := SPECIES.spawn("water_abyssal_guardian")
	guardian.nickname = "Deep Watcher"
	guardian.swim_stamina_fraction = 0.71
	var expected := CODEC.encode(guardian)
	var result := REWARD.begin(game, ledger, "character-A", guardian)
	assert_true(result.ok)
	assert_eq(game.save_system.writes, 1)
	assert_true(game.world.flags.has("water_guardian_claimed"))
	assert_false(game.world.flags.has("water_guardian_settled"), "Reserving the ceremony is not accepting/releasing the Guardian")
	assert_false(game.world.flags.has("realm_relic_water_earned"))
	assert_eq(game.world.water_capture_claims.size(), 1)
	var id: String = (game.world.world_id + ":guardian").sha256_text()
	var claim: Dictionary = game.world.water_capture_claims[id]
	assert_eq(claim, {"id": id, "source": "guardian", "world_id": game.world.world_id, "character_id": "character-A", "creature": expected})
	var restored := WORLD.new()
	restored.load_data(game.save_system.store.read(game.world.world_id))
	assert_eq(restored.water_capture_claims, JSON.parse_string(JSON.stringify(game.world.water_capture_claims)))
	assert_true(restored.flags.has("water_guardian_claimed"))
	assert_eq(CODEC.encode(CODEC.decode(restored.water_capture_claims[id].creature)), expected)
	var before: Dictionary = game.world.save_data()
	assert_false(REWARD.begin(game, ledger, "character-B", guardian).ok)
	assert_eq(game.world.save_data(), before)
	assert_eq(game.save_system.writes, 1)
	assert_true(REWARD.begin(game, ledger, "character-A", guardian).ok)
	assert_eq(game.world.save_data(), before, "Replay must preserve the exact first reservation")
	assert_eq(game.save_system.writes, 1)

func test_disk_refusal_restores_world_revision_sequence_and_allows_retry() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var guardian := SPECIES.spawn("water_abyssal_guardian")
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	game.save_system.fail_write = true
	assert_false(REWARD.begin(game, ledger, "character-A", guardian).ok)
	assert_eq(game.world.save_data(), before)
	assert_eq(game.world.revision, revision)
	assert_eq(ledger.seq, sequence)
	assert_true(game.world.water_capture_claims.is_empty())
	game.save_system.fail_write = false
	assert_true(REWARD.begin(game, ledger, "character-B", guardian).ok)
	assert_eq(game.world.water_capture_claims.values()[0].character_id, "character-B")

func test_refuses_wrong_species_missing_release_identity_and_host_authority() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var guardian := SPECIES.spawn("water_abyssal_guardian")
	for creature in [null, RefCounted.new(), SPECIES.spawn("water_aquaryn")]:
		assert_false(REWARD.begin(game, ledger, "character-A", creature).ok)
	assert_false(REWARD.begin(game, ledger, "", guardian).ok)
	assert_false(REWARD.begin(null, ledger, "character-A", guardian).ok)
	assert_false(REWARD.begin(game, LEDGER.new(WORLD.new()), "character-A", guardian).ok)
	game.host = false
	assert_false(REWARD.begin(game, ledger, "character-A", guardian).ok)
	game.host = true
	game.world.flags.set_flag("water_guardian_freed", false)
	assert_false(REWARD.begin(game, ledger, "character-A", guardian).ok)
	assert_false(game.world.flags.has("water_guardian_claimed"))
	assert_true(game.world.water_capture_claims.is_empty())
	assert_eq(game.save_system.writes, 0)
