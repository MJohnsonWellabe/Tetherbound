extends "res://tests/test_case.gd"

## F14 / CLAUDE.md freed-legendary rule for the Abyssal Guardian: every
## participant in the fight that freed it (accepted Nerissa reward deliveries,
## or the host's own character in a solo world with none) receives their own
## once-only offer; non-participants receive nothing; world restoration
## settles exactly once on the first participant resolution.

const REWARD := preload("res://scripts/world/water_guardian_reward.gd")
const TX := preload("res://scripts/save/water_capture_transaction.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const SAVE := preload("res://scripts/save/world_save.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const FLAGS := preload("res://autoload/progression_state.gd")

class Saver extends RefCounted:
	var fail_write := false
	var writes := 0
	var character_writes := 0
	var store: RefCounted = SAVE.new("user://guardian_participants_%d/" % Time.get_ticks_usec())
	func save_world(game: Object, id: String) -> bool:
		writes += 1
		var snapshot: Dictionary = game.world.save_data()
		snapshot.progression = game.world.flags.save_data()
		return false if fail_write else store.write(id, SAVE.partition(snapshot))
	func save_character(_game: Object, _id: String) -> bool:
		character_writes += 1
		return true

class LocalFixture extends RefCounted:
	var character_id := "host-char"
	var party := PARTY.new()
	var flags := FLAGS.new()

class GameFixture extends RefCounted:
	var host := true
	var world: RefCounted = WORLD.new()
	var save_system: RefCounted = Saver.new()
	var local: RefCounted = LocalFixture.new()
	func is_host() -> bool: return host

static func add_row(world: RefCounted, character: String, status: String = "accepted",
		source: String = "trainer:water_trainer_nerissa:coins") -> void:
	var id := ("%s|%s" % [source, character]).sha256_text()
	world.reward_deliveries[id] = {"delivery_id": id, "world_id": world.world_id, "source": source,
		"character_id": character, "status": status}

func fixture(participants: Array = ["A", "B"]) -> RefCounted:
	var game := GameFixture.new()
	game.world.world_id = "guardian-participants-world"
	game.world.flags.set_flag("water_captain_nerissa_defeated")
	game.world.flags.set_flag("water_tether_disabled")
	game.world.flags.set_flag("water_guardian_freed")
	for character: String in participants:
		add_row(game.world, character)
	return game

func guardian() -> RefCounted:
	return SPECIES.spawn("water_abyssal_guardian")

func settled_count(game: RefCounted) -> int:
	var n := 0
	for flag: String in REWARD.SETTLEMENT:
		if game.world.flags.has(flag):
			n += 1
	return n

# --- participant derivation -------------------------------------------------

func test_trainer_id_is_the_installed_veilfall_captain() -> void:
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	assert_eq(str(rules.captain_encounter_id), REWARD.TRAINER_ID)

func test_participants_are_accepted_nerissa_deliveries_only() -> void:
	var game := fixture(["A", "B"])
	add_row(game.world, "A", "accepted", "trainer:water_trainer_nerissa:item:revive")
	add_row(game.world, "P", "pending")
	add_row(game.world, "V", "accepted", "trainer:water_trainer_venn:coins")
	add_row(game.world, "N", "accepted", "trainer:water_trainer_nerissa_rematch:coins")
	var found: Array = REWARD.participants(game.world)
	found.sort()
	assert_eq(found, ["A", "B"], "deduplicated, accepted-only, exact Nerissa prefix")

func test_pure_rule_mirrors_meadows_but_empty_set_means_host_local_only() -> void:
	assert_true(REWARD.may_receive("A", ["A", "B"], "host", false))
	assert_true(REWARD.may_receive("B", ["A", "B"], "host", false))
	assert_false(REWARD.may_receive("C", ["A", "B"], "host", false))
	assert_false(REWARD.may_receive("host", ["A", "B"], "host", false), "the host is not a participant by default")
	assert_false(REWARD.may_receive("A", ["A", "B"], "host", true))
	assert_true(REWARD.may_receive("host", [], "host", false), "solo freeing with no rows still grants")
	assert_false(REWARD.may_receive("guest", [], "host", false), "an unidentified co-op guest never qualifies by default")
	assert_false(REWARD.may_receive("", [], "", false))
	assert_false(REWARD.may_receive("", ["A"], "", false))

func test_solo_world_without_rows_offers_only_the_local_character() -> void:
	var game := fixture([])
	var ledger := LEDGER.new(game.world)
	var refused := REWARD.begin(game, ledger, "guest", guardian())
	assert_false(refused.ok)
	assert_eq(refused.code, "not_participant")
	assert_true(REWARD.begin(game, ledger, "host-char", guardian()).ok)

# --- per-character ids and independence ----------------------------------------

func test_each_participant_has_an_independent_claim_id() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	assert_ne(REWARD.claim_id(game.world.world_id, "A"), REWARD.claim_id(game.world.world_id, "B"))
	assert_ne(REWARD.claim_id(game.world.world_id, "A"), REWARD.legacy_claim_id(game.world.world_id))
	assert_ne(REWARD.claim_id("other-world", "A"), REWARD.claim_id(game.world.world_id, "A"))
	var a := REWARD.begin(game, ledger, "A", guardian())
	var b := REWARD.begin(game, ledger, "B", guardian())
	assert_eq(a.id, REWARD.claim_id(game.world.world_id, "A"))
	assert_eq(b.id, REWARD.claim_id(game.world.world_id, "B"))
	# B refusing does not touch A's pending claim.
	assert_true(REWARD.decline(game, ledger, "B").ok)
	assert_true(game.world.water_capture_claims.has(a.id))
	assert_false(game.world.water_capture_claims.has(b.id))

# --- refuse path -------------------------------------------------------------

func test_decline_grants_nothing_settles_offer_and_forbids_a_second() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var a := REWARD.begin(game, ledger, "A", guardian())
	var declined := REWARD.decline(game, ledger, "A")
	assert_true(declined.ok)
	assert_false(declined.accepted)
	assert_false(game.world.water_capture_claims.has(a.id), "a refused claim can never be delivered later")
	assert_eq(settled_count(game), 3, "refusal still settles the world (BOSSES §4.12)")
	var again := REWARD.begin(game, ledger, "A", guardian())
	assert_false(again.ok)
	assert_eq(again.code, "already_resolved")
	# Replayed refusal is harmless and writes nothing.
	var writes: int = game.save_system.writes
	assert_true(REWARD.resolve(game, ledger, a.id, "A", false).ok)
	assert_eq(game.save_system.writes, writes)
	# Nobody else may refuse (or accept) A's claim.
	var b := REWARD.begin(game, ledger, "B", guardian())
	assert_false(REWARD.resolve(game, ledger, b.id, "A", true).ok)
	assert_false(REWARD.decline(game, ledger, "C").ok)
	assert_true(game.world.water_capture_claims.has(b.id))

func test_decline_journal_failure_restores_everything() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	REWARD.begin(game, ledger, "A", guardian())
	var before: Dictionary = game.world.save_data()
	var sequence: int = ledger.seq
	game.save_system.fail_write = true
	assert_false(REWARD.decline(game, ledger, "A").ok)
	assert_eq(game.world.save_data(), before)
	assert_eq(ledger.seq, sequence)
	game.save_system.fail_write = false
	assert_true(REWARD.decline(game, ledger, "A").ok)

# --- world restoration exactly once -------------------------------------------

func test_world_restoration_settles_once_on_first_resolution_whoever_accepts() -> void:
	var game := fixture(["A", "B", "D"])
	var ledger := LEDGER.new(game.world)
	var a := REWARD.begin(game, ledger, "A", guardian())
	var b := REWARD.begin(game, ledger, "B", guardian())
	assert_eq(settled_count(game), 0, "reservations do not restore the world")
	# First resolution is a refusal: nobody has to accept for the world to heal.
	var first := REWARD.resolve(game, ledger, b.id, "B", false)
	assert_true(first.ok)
	assert_eq(settled_count(game), 3)
	var settlement_ops := 0
	for op: Dictionary in first.delta.ops:
		if REWARD.SETTLEMENT.has(str(op.get("id", ""))):
			settlement_ops += 1
	assert_eq(settlement_ops, 3)
	var second := REWARD.resolve(game, ledger, a.id, "A", true)
	assert_true(second.ok)
	for op: Dictionary in second.delta.ops:
		assert_false(REWARD.SETTLEMENT.has(str(op.get("id", ""))), "settlement is never written twice")
	var d := REWARD.begin(game, ledger, "D", guardian())
	var third := REWARD.resolve(game, ledger, d.id, "D", true)
	assert_true(third.ok)
	assert_true((third.delta.ops as Array).is_empty())
	assert_true(game.world.water_capture_claims.is_empty())

# --- reload mid-claim ---------------------------------------------------------

func test_reload_mid_claim_replays_and_resolves_from_disk() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var a := REWARD.begin(game, ledger, "A", guardian())
	# Host restarts: a fresh world and ledger load the journaled file.
	var reloaded := GameFixture.new()
	reloaded.save_system = game.save_system
	reloaded.world.load_data(game.save_system.store.read(game.world.world_id))
	assert_true(reloaded.world.water_capture_claims.has(a.id))
	assert_true(REWARD.has_been_offered(reloaded.world, "A"))
	var fresh_ledger := LEDGER.new(reloaded.world)
	var writes: int = reloaded.save_system.writes
	var replay := REWARD.begin(reloaded, fresh_ledger, "A", guardian())
	assert_true(replay.ok)
	assert_eq(replay.id, a.id)
	assert_eq(reloaded.save_system.writes, writes, "reconnect replay writes nothing and mints no duplicate")
	assert_eq(reloaded.world.water_capture_claims.size(), 1)
	assert_true(REWARD.resolve(reloaded, fresh_ledger, a.id, "A", true).ok)
	assert_false(REWARD.begin(reloaded, fresh_ledger, "A", guardian()).ok)
	assert_true(REWARD.begin(reloaded, fresh_ledger, "B", guardian()).ok)

func test_character_receipt_makes_replayed_claim_inert_and_never_a_sixth() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	game.local.character_id = "A"
	var a := REWARD.begin(game, ledger, "A", guardian())
	var claim: Dictionary = game.world.water_capture_claims[a.id]
	for i in 5:
		game.local.party.add(SPECIES.spawn("water_mosshell"))
	var pending := guardian()
	var refused := TX.settle(game, claim, pending, -1)
	assert_false(refused.ok, "a full belt needs an explicit release or refusal")
	assert_eq(game.local.party.size(), 5)
	assert_true(TX.settle(game, claim, pending, 2).ok)
	assert_eq(game.local.party.size(), 5)
	assert_true(game.local.party.at(2) == pending)
	assert_true(TX.settle(game, claim, guardian(), 1).already)
	assert_eq(game.local.party.size(), 5)

# --- legacy single-recipient worlds -------------------------------------------

func test_legacy_pending_claim_is_replayed_for_its_recipient_and_marked_on_resolve() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var legacy := REWARD.legacy_claim_id(game.world.world_id)
	game.world.flags.set_flag("water_guardian_claimed")
	game.world.water_capture_claims[legacy] = {"id": legacy, "source": "guardian", "world_id": game.world.world_id,
		"character_id": "A", "creature": preload("res://scripts/save/water_capture_codec.gd").encode(guardian())}
	var replay := REWARD.begin(game, ledger, "A", guardian())
	assert_true(replay.ok)
	assert_eq(replay.id, legacy, "the legacy recipient keeps their original claim, no duplicate")
	assert_eq(game.world.water_capture_claims.size(), 1)
	assert_true(REWARD.begin(game, ledger, "B", guardian()).ok, "other participants now receive their own offer")
	assert_true(REWARD.resolve(game, ledger, legacy, "A", true).ok)
	assert_true(REWARD.has_been_offered(game.world, "A"), "legacy resolution writes the per-character marker")
	assert_false(REWARD.begin(game, ledger, "A", guardian()).ok)

func test_legacy_settled_recipient_is_never_granted_a_duplicate() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var legacy := REWARD.legacy_claim_id(game.world.world_id)
	for flag: String in ["water_guardian_claimed"] + REWARD.SETTLEMENT:
		game.world.flags.set_flag(flag)
	# The legacy recipient's own character holds the old receipt.
	game.local.character_id = "A"
	game.local.flags.set_flag("water_capture_receipt:" + legacy)
	var original := guardian()
	game.local.party.add(original)
	var a := REWARD.begin(game, ledger, "A", guardian())
	assert_true(a.ok)
	var claim: Dictionary = game.world.water_capture_claims[a.id]
	assert_true(REWARD.already_received(game.local.flags, claim))
	var settled := TX.settle(game, claim, guardian(), -1)
	assert_true(settled.ok)
	assert_true(settled.already, "the legacy recipient keeps its original creature only")
	assert_eq(game.local.party.size(), 1)
	assert_true(game.local.party.at(0) == original)
	var resolved := REWARD.resolve(game, ledger, a.id, "A", true)
	assert_true(resolved.ok)
	for op: Dictionary in resolved.delta.ops:
		assert_false(REWARD.SETTLEMENT.has(str(op.get("id", ""))), "legacy settlement is not written again")
	# A different world's legacy receipt is not this world's.
	var other := {"id": "x", "source": "guardian", "world_id": "another-world"}
	assert_false(REWARD.already_received(game.local.flags, other))
