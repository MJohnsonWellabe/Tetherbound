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

class LocalFixture extends RefCounted:
	var character_id := "character-A"

class GameFixture extends RefCounted:
	var host := true
	var world: RefCounted = WORLD.new()
	var save_system: RefCounted = Saver.new()
	var local: RefCounted = LocalFixture.new()
	func is_host() -> bool: return host

## Accepted Nerissa reward deliveries are the durable participant journal.
static func add_participant(world: RefCounted, character: String, status: String = "accepted", trainer: String = "water_trainer_nerissa") -> void:
	var id := ("delivery:%s:%s" % [trainer, character]).sha256_text()
	world.reward_deliveries[id] = {"delivery_id": id, "world_id": world.world_id, "source": "trainer:%s:coins" % trainer,
		"character_id": character, "status": status}

func fixture() -> RefCounted:
	var game := GameFixture.new()
	game.world.world_id = "guardian-reward-world"
	game.world.reward_delivery_namespace = "guardian-reward-instance"
	game.world.flags.set_flag("water_guardian_freed")
	add_participant(game.world, "character-A")
	add_participant(game.world, "character-B")
	return game

func test_release_requires_captain_and_journals_both_flags_or_neither() -> void:
	var game := GameFixture.new()
	game.world.world_id = "guardian-release-world"
	var ledger := LEDGER.new(game.world)
	assert_false(REWARD.release(game, ledger).ok)
	game.world.flags.set_flag("water_captain_nerissa_defeated")
	var before: Dictionary = game.world.save_data()
	var sequence: int = ledger.seq
	game.save_system.fail_write = true
	assert_false(REWARD.release(game, ledger).ok)
	assert_eq(game.world.save_data(), before)
	assert_eq(ledger.seq, sequence)
	game.save_system.fail_write = false
	var result: Dictionary = REWARD.release(game, ledger)
	assert_true(result.ok)
	assert_true(game.world.flags.has("water_tether_disabled"))
	assert_true(game.world.flags.has("water_guardian_freed"))
	assert_eq(result.delta.ops.size(), 2)
	var restored := WORLD.new()
	restored.load_data(game.save_system.store.read(game.world.world_id))
	assert_true(restored.flags.has("water_tether_disabled"))
	assert_true(restored.flags.has("water_guardian_freed"))

# REPLACED: this test formerly asserted the old single-recipient rule
# (character-B refused once character-A reserved the one world offer). The
# owner decision in CLAUDE.md supersedes it: every freeing-fight participant
# gets their own offer; non-participants and second claims are refused.
func test_exact_guardian_per_participant_offers_survive_real_world_file() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var guardian := SPECIES.spawn("water_abyssal_guardian")
	guardian.nickname = "Deep Watcher"
	guardian.swim_stamina_fraction = 0.71
	var expected := CODEC.encode(guardian)
	var result := REWARD.begin(game, ledger, "character-A", guardian)
	assert_true(result.ok)
	assert_eq(game.save_system.writes, 1)
	assert_true(game.world.flags.has(REWARD.offered_flag("character-A")))
	assert_false(game.world.flags.has("water_guardian_settled"), "Reserving the ceremony is not accepting/releasing the Guardian")
	assert_false(game.world.flags.has("realm_relic_water_earned"))
	assert_eq(game.world.water_capture_claims.size(), 1)
	# Keyed by the world INSTANCE (reward_delivery_namespace), not the slot.
	var id: String = ("guardian-reward-instance:guardian:character-A").sha256_text()
	assert_eq(REWARD.world_instance(game.world), "guardian-reward-instance")
	assert_eq(REWARD.claim_id(REWARD.world_instance(game.world), "character-A"), id)
	var claim: Dictionary = game.world.water_capture_claims[id]
	assert_eq(claim, {"id": id, "source": "guardian", "world_id": game.world.world_id,
		"world_instance": "guardian-reward-instance", "character_id": "character-A", "creature": expected})
	var restored := WORLD.new()
	restored.load_data(game.save_system.store.read(game.world.world_id))
	assert_eq(restored.water_capture_claims, JSON.parse_string(JSON.stringify(game.world.water_capture_claims)))
	assert_true(restored.flags.has(REWARD.offered_flag("character-A")))
	assert_eq(CODEC.encode(CODEC.decode(restored.water_capture_claims[id].creature)), expected)
	# Participant B receives their OWN offer; A's reservation is untouched.
	var second := REWARD.begin(game, ledger, "character-B", guardian)
	assert_true(second.ok, "The second participant is not refused because the first already has one")
	var id_b: String = ("guardian-reward-instance:guardian:character-B").sha256_text()
	assert_eq(game.world.water_capture_claims.size(), 2)
	assert_eq(game.world.water_capture_claims[id_b].character_id, "character-B")
	assert_eq(game.world.water_capture_claims[id], claim)
	assert_eq(game.save_system.writes, 2)
	# Non-participant C is refused with a clear reason and nothing changes.
	var before: Dictionary = game.world.save_data()
	var stranger := REWARD.begin(game, ledger, "character-C", guardian)
	assert_false(stranger.ok)
	assert_eq(stranger.code, "not_participant")
	assert_false(str(stranger.reason).is_empty())
	assert_eq(game.world.save_data(), before)
	assert_eq(game.save_system.writes, 2)
	# A's reconnect replay returns the same claim without a write.
	var replay := REWARD.begin(game, ledger, "character-A", guardian)
	assert_true(replay.ok)
	assert_eq(replay.id, id)
	assert_eq(game.world.save_data(), before, "Replay must preserve the exact first reservation")
	assert_eq(game.save_system.writes, 2)
	# Once A resolved their own offer, A is refused a second one.
	assert_true(REWARD.resolve(game, ledger, id, "character-A", true).ok)
	var again := REWARD.begin(game, ledger, "character-A", guardian)
	assert_false(again.ok)
	assert_eq(again.code, "already_resolved")
	assert_false(game.world.water_capture_claims.has(id))

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
	assert_false(game.world.flags.has(REWARD.offered_flag("character-A")), "A failed journal leaves no offered marker")
	game.save_system.fail_write = false
	assert_true(REWARD.begin(game, ledger, "character-B", guardian).ok)
	assert_eq(game.world.water_capture_claims.values()[0].character_id, "character-B")
	assert_true(REWARD.begin(game, ledger, "character-A", guardian).ok, "A may retry after the refused write")

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
	assert_false(game.world.flags.has(REWARD.offered_flag("character-A")))
	assert_true(game.world.water_capture_claims.is_empty())
	assert_eq(game.save_system.writes, 0)
