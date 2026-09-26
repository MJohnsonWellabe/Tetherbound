extends "res://tests/test_case.gd"

## F14 / CLAUDE.md freed-legendary rule for the Abyssal Guardian: every
## participant in the fight that freed it (every journaled Nerissa reward
## delivery row, whatever its status; with no such row, the host's own character
## only in a SOLO session and nobody in a multi-peer one) receives their own
## once-only offer per WORLD INSTANCE;
## non-participants receive nothing; world restoration settles exactly once on
## the first participant resolution.

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
	var multi := false
	var world: RefCounted = WORLD.new()
	var save_system: RefCounted = Saver.new()
	var local: RefCounted = LocalFixture.new()
	func is_host() -> bool: return host
	func is_multi_peer() -> bool: return multi

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

func test_participants_are_every_journaled_nerissa_row_whatever_its_status() -> void:
	var game := fixture(["A", "B"])
	add_row(game.world, "A", "accepted", "trainer:water_trainer_nerissa:item:revive")
	add_row(game.world, "P", "pending")
	add_row(game.world, "V", "accepted", "trainer:water_trainer_venn:coins")
	add_row(game.world, "N", "accepted", "trainer:water_trainer_nerissa_rematch:coins")
	var found: Array = REWARD.participants(game.world)
	found.sort()
	assert_eq(found, ["A", "B", "P"], "deduplicated, any status (host decided when it journaled), exact Nerissa prefix")

func test_pending_only_guest_row_admits_the_guest_and_refuses_the_non_fighting_host() -> void:
	var game := fixture([])
	add_row(game.world, "guest", "pending")
	var ledger := LEDGER.new(game.world)
	var host := REWARD.begin(game, ledger, "host-char", guardian())
	assert_false(host.ok, "a Nerissa row exists, so the host-only fallback does not apply")
	assert_eq(host.code, "not_participant")
	assert_true(REWARD.begin(game, ledger, "guest", guardian()).ok, "a not-yet-saved payout still marks a participant")
	assert_false(REWARD.refuse(game, ledger, "host-char").ok, "a non-participant host cannot settle by refusing either")

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

func test_multi_peer_empty_journal_offers_nobody() -> void:
	# Client-run and solo Nerissa wins now journal rows, so an empty journal
	# means a journal-less (pre-row) world, which cannot say who fought: in a
	# multi-peer session it identifies NO participant -- never the host who may
	# not have fought.
	assert_false(REWARD.may_receive("host", [], "host", false, true),
		"multi-peer, no rows: the host is not presumed a participant")
	assert_true(REWARD.may_receive("host", [], "host", false, false), "solo is unchanged")
	assert_true(REWARD.may_receive("A", ["A"], "host", false, true), "journaled participants still qualify in co-op")
	var game := fixture([])
	game.multi = true
	var ledger := LEDGER.new(game.world)
	var refused := REWARD.begin(game, ledger, "host-char", guardian())
	assert_false(refused.ok, "the non-fighting host is not offered")
	assert_eq(refused.code, "not_participant")
	assert_false(REWARD.begin(game, ledger, "guest", guardian()).ok, "nor is an unidentified guest")
	assert_false(REWARD.refuse(game, ledger, "host-char").ok, "and no refusal settles the world for a non-participant")
	assert_false(REWARD.local_may_answer(game), "the host's view offers nothing")

# --- per-character ids and independence ----------------------------------------

func test_each_participant_has_an_independent_claim_id() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	assert_ne(REWARD.claim_id(game.world.world_id, "A"), REWARD.claim_id(game.world.world_id, "B"))
	assert_ne(REWARD.claim_id(game.world.world_id, "A"), REWARD.legacy_claim_id(game.world.world_id))
	assert_ne(REWARD.claim_id("other-world", "A"), REWARD.claim_id(game.world.world_id, "A"))
	var a := REWARD.begin(game, ledger, "A", guardian())
	var b := REWARD.begin(game, ledger, "B", guardian())
	# begin() establishes the world instance first (live hosts never fall back
	# to the slot locator), so ids hash that instance.
	assert_ne(REWARD.world_instance(game.world), game.world.world_id)
	assert_eq(a.id, REWARD.claim_id(REWARD.world_instance(game.world), "A"))
	assert_eq(b.id, REWARD.claim_id(REWARD.world_instance(game.world), "B"))
	# B refusing does not touch A's pending claim.
	assert_true(REWARD.decline(game, ledger, "B").ok)
	assert_true(game.world.water_capture_claims.has(a.id))
	assert_false(game.world.water_capture_claims.has(b.id))

# --- world instance vs save-slot locator ------------------------------------

func instance_fixture(instance_ns: String, participants: Array = ["C"]) -> RefCounted:
	var game := fixture(participants)
	game.world.world_id = "slot-0"
	game.world.reward_delivery_namespace = instance_ns
	return game

func test_claim_ids_key_on_world_instance_and_fall_back_to_world_id_only_when_empty() -> void:
	var game := instance_fixture("instance-one")
	assert_eq(REWARD.world_instance(game.world), "instance-one")
	assert_eq(REWARD.claim_id(REWARD.world_instance(game.world), "C"), "instance-one:guardian:C".sha256_text())
	game.world.reward_delivery_namespace = ""
	assert_eq(REWARD.world_instance(game.world), "slot-0", "documented fallback for a world with no identity yet")

func test_two_worlds_sharing_slot_zero_have_independent_claims_and_no_erasure() -> void:
	# C accepts the Guardian in its OWN slot-0 world...
	var own := instance_fixture("own-world-instance")
	own.local.character_id = "C"
	var own_ledger := LEDGER.new(own.world)
	var first := REWARD.begin(own, own_ledger, "C", guardian())
	var own_claim: Dictionary = own.world.water_capture_claims[first.id]
	assert_eq(own_claim.world_instance, "own-world-instance")
	var accepted := TX.settle(own, own_claim, guardian(), -1)
	assert_true(accepted.ok)
	assert_false(accepted.already)
	assert_true(REWARD.resolve(own, own_ledger, first.id, "C", true).ok)
	assert_eq(own.local.party.size(), 1)
	# ...then joins ANOTHER host's slot-0 world carrying the same character.
	var other := instance_fixture("other-host-instance")
	other.local = own.local
	var other_ledger := LEDGER.new(other.world)
	var second := REWARD.begin(other, other_ledger, "C", guardian())
	assert_true(second.ok)
	assert_ne(second.id, first.id, "same slot locator, different world instance, different claim")
	var other_claim: Dictionary = other.world.water_capture_claims[second.id]
	assert_false(REWARD.already_received(other.local.flags, other_claim),
		"the receipt from C's own world must not acknowledge this world's offer away")
	assert_false(REWARD.claim_matches_world(own_claim, other.world), "a claim from the other slot-0 world is foreign here")
	assert_true(REWARD.claim_matches_world(other_claim, other.world))
	var granted := TX.settle(other, other_claim, guardian(), -1)
	assert_true(granted.ok)
	assert_false(granted.already, "C really receives this world's Guardian instead of a silent ack")
	assert_eq(other.local.party.size(), 2)
	# Within one instance the once-only rule still holds.
	assert_true(REWARD.resolve(other, other_ledger, second.id, "C", true).ok)
	assert_eq(REWARD.begin(other, other_ledger, "C", guardian()).code, "already_resolved")

func test_legacy_receipt_for_the_same_slot_is_treated_as_received_conservatively() -> void:
	var game := instance_fixture("fresh-instance")
	game.local.character_id = "C"
	# C holds a pre-F14 receipt for a "slot-0" Guardian. The bare receipt cannot
	# say which slot-0 world issued it, so it may be THIS world's: never risk a
	# second Guardian (open owner question whether it should block elsewhere).
	game.local.flags.set_flag("water_capture_receipt:" + REWARD.legacy_claim_id("slot-0"))
	var ledger := LEDGER.new(game.world)
	assert_false(REWARD.is_legacy_world(game.world))
	var offer := REWARD.begin(game, ledger, "C", guardian())
	var claim: Dictionary = game.world.water_capture_claims[offer.id]
	assert_false(claim.has("legacy_world"))
	assert_true(REWARD.already_received(game.local.flags, claim), "a legacy receipt holder is already received")
	var granted := TX.settle(game, claim, guardian(), -1)
	assert_true(granted.ok)
	assert_true(granted.already, "no creature is granted over a legacy receipt")
	assert_eq(game.local.party.size(), 0)
	# The acknowledgement still answers the offer and restores the world once.
	assert_true(REWARD.resolve(game, ledger, offer.id, "C", true).ok)
	assert_eq(settled_count(game), 3)
	assert_eq(REWARD.begin(game, ledger, "C", guardian()).code, "already_resolved")
	# Control: a receipt for a different slot locator does not match.
	var other := instance_fixture("other-instance")
	other.world.world_id = "slot-3"
	other.local.character_id = "C"
	other.local.flags.set_flag("water_capture_receipt:" + REWARD.legacy_claim_id("slot-0"))
	var other_offer := REWARD.begin(other, LEDGER.new(other.world), "C", guardian())
	assert_false(REWARD.already_received(other.local.flags, other.world.water_capture_claims[other_offer.id]))

# --- refuse path -------------------------------------------------------------

func test_chamber_refusal_without_a_claim_settles_once_and_grants_nothing() -> void:
	var game := fixture(["A", "B"])
	var ledger := LEDGER.new(game.world)
	var refused := REWARD.refuse(game, ledger, "A")
	assert_true(refused.ok)
	assert_false(refused.accepted)
	assert_true(game.world.water_capture_claims.is_empty(), "nothing to deliver after a refusal")
	assert_true(REWARD.has_been_offered(game.world, "A"))
	assert_eq(settled_count(game), 3, "refusal settles the world (BOSSES §4.12)")
	assert_eq(REWARD.begin(game, ledger, "A", guardian()).code, "already_resolved")
	var writes: int = game.save_system.writes
	assert_eq(REWARD.refuse(game, ledger, "A").code, "already_resolved")
	assert_eq(game.save_system.writes, writes, "a repeated refusal writes nothing")
	assert_eq(REWARD.refuse(game, ledger, "C").code, "not_participant")
	# B still gets its own offer; refusing it with a claim pending declines it.
	var b := REWARD.begin(game, ledger, "B", guardian())
	var b_refused := REWARD.refuse(game, ledger, "B")
	assert_true(b_refused.ok)
	assert_false(game.world.water_capture_claims.has(b.id))
	for op: Dictionary in b_refused.delta.ops:
		assert_false(REWARD.SETTLEMENT.has(str(op.get("id", ""))), "settlement is never written twice")

func test_refusal_journal_failure_restores_everything() -> void:
	var game := fixture()
	var ledger := LEDGER.new(game.world)
	var before: Dictionary = game.world.save_data()
	var sequence: int = ledger.seq
	game.save_system.fail_write = true
	assert_false(REWARD.refuse(game, ledger, "A").ok)
	assert_eq(game.world.save_data(), before)
	assert_eq(ledger.seq, sequence)

# --- per-character view (prompt state) ----------------------------------------

func test_two_characters_have_separate_prompt_state() -> void:
	var game := fixture(["A", "B"])
	var ledger := LEDGER.new(game.world)
	var view_a := GameFixture.new()
	view_a.host = false
	view_a.world = game.world
	view_a.local.character_id = "A"
	var view_b := GameFixture.new()
	view_b.host = false
	view_b.world = game.world
	view_b.local.character_id = "B"
	var view_c := GameFixture.new()
	view_c.host = false
	view_c.world = game.world
	view_c.local.character_id = "C"
	assert_true(REWARD.local_may_answer(view_a))
	assert_true(REWARD.local_may_answer(view_b))
	assert_false(REWARD.local_may_answer(view_c), "a non-participant sees no always-failing prompt")
	REWARD.begin(game, ledger, "A", guardian())
	assert_false(REWARD.local_may_answer(view_a), "A holds its offer; its prompt closes")
	assert_true(REWARD.local_may_answer(view_b), "B's prompt is untouched by A's answer")
	REWARD.refuse(game, ledger, "A")
	assert_eq(settled_count(game), 3)
	assert_true(REWARD.local_may_answer(view_b), "world settlement does not close B's own offer")

func test_solo_view_only_the_host_may_answer() -> void:
	var game := fixture([])
	assert_true(REWARD.local_may_answer(game))
	var joiner := GameFixture.new()
	joiner.host = false
	joiner.world = game.world
	joiner.local.character_id = "guest"
	assert_false(REWARD.local_may_answer(joiner))

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
	# Owner decision: the journal names B, so B gets its own offer; the legacy
	# recipient A is only ever replayed its original claim.
	var b := REWARD.begin(game, ledger, "B", guardian())
	assert_true(b.ok, "a journaled participant of a legacy world gets its own offer")
	assert_ne(b.id, legacy)
	assert_eq(game.world.water_capture_claims.size(), 2, "A's legacy claim plus B's own; nothing for A")
	assert_true(REWARD.resolve(game, ledger, legacy, "A", true).ok)
	assert_true(REWARD.has_been_offered(game.world, "A"), "legacy resolution writes the per-character marker")
	assert_true(game.world.flags.has(REWARD.LEGACY_FLAG), "the world stays legacy after its claim resolves")
	assert_false(REWARD.begin(game, ledger, "A", guardian()).ok)
	assert_eq(REWARD.begin(game, ledger, "B", guardian()).code, "replay", "B's own claim survives A's answer")
	assert_true(REWARD.resolve(game, ledger, b.id, "B", true).ok)
	assert_eq(REWARD.begin(game, ledger, "B", guardian()).code, "already_resolved")
	assert_true(game.world.water_capture_claims.is_empty())

## A world exactly as origin/main (pre-F14) leaves it after the legacy
## recipient accepted: its begin() set `water_guardian_claimed` and a claim with
## the slot-locator id; TX.settle saved the receipt with the creature; the ack
## erased the claim and set the settlement flags. No offered marker, no legacy
## recipient marker, no delivery rows (solo), and the recipient is the host.
func old_model_settled_world(instance_ns: String) -> RefCounted:
	var game := fixture([])
	game.world.world_id = "slot-0"
	game.world.reward_delivery_namespace = instance_ns
	game.local.character_id = "A"
	var legacy := REWARD.legacy_claim_id("slot-0")
	var claim := {"id": legacy, "source": "guardian", "world_id": "slot-0", "character_id": "A",
		"creature": preload("res://scripts/save/water_capture_codec.gd").encode(guardian())}
	game.world.flags.set_flag("water_guardian_claimed")
	game.world.water_capture_claims[legacy] = claim
	var accepted := TX.settle(game, claim, guardian(), -1)
	assert_true(accepted.ok and not accepted.already, "fixture: the old model really delivered one Guardian")
	for flag: String in REWARD.SETTLEMENT:
		game.world.flags.set_flag(flag)
	game.world.water_capture_claims.erase(legacy)
	return game

func assert_no_new_guardian_offer(game: RefCounted, characters: Array) -> void:
	var ledger := LEDGER.new(game.world)
	var before: Dictionary = game.world.save_data()
	var sequence: int = ledger.seq
	var writes: int = game.save_system.writes
	for character: String in characters:
		var began := REWARD.begin(game, ledger, character, guardian())
		assert_false(began.ok, "no new Guardian offer for %s in a legacy-settled world" % character)
		assert_eq(began.code, "legacy_world")
		var refused := REWARD.refuse(game, ledger, character)
		assert_false(refused.ok)
		assert_eq(refused.code, "legacy_world", "and nothing to refuse")
	assert_true(game.world.water_capture_claims.is_empty(), "no claim is minted")
	assert_eq(game.world.save_data(), before, "nothing is written to the world")
	assert_eq(ledger.seq, sequence)
	assert_eq(game.save_system.writes, writes)

func test_legacy_settled_recipient_is_never_granted_a_duplicate() -> void:
	# (a) A world exactly as origin/main leaves it: no legacy_recipient flag.
	for instance_ns: String in ["", "old-model-instance"]:
		var game := old_model_settled_world(instance_ns)
		var original: RefCounted = game.local.party.at(0)
		assert_eq(game.local.party.size(), 1)
		assert_true(REWARD.is_legacy_world(game.world))
		assert_false(REWARD.local_may_answer(game), "the original recipient sees no Invite prompt")
		assert_ne(REWARD.edda_conversation(game, false), REWARD.EDDA_OFFER, "Edda does not offer it again")
		assert_no_new_guardian_offer(game, ["A", "B", "host-char"])
		# Even a Guardian claim for this world_id could never deliver a second
		# creature to the holder of the legacy receipt.
		var hypothetical := {"id": REWARD.claim_id(REWARD.world_instance(game.world), "A"), "source": "guardian",
			"world_id": "slot-0", "world_instance": REWARD.world_instance(game.world), "character_id": "A",
			"creature": preload("res://scripts/save/water_capture_codec.gd").encode(guardian())}
		assert_true(REWARD.already_received(game.local.flags, hypothetical))
		var settled := TX.settle(game, hypothetical, guardian(), -1)
		assert_true(settled.ok and settled.already, "the legacy recipient keeps its original creature only")
		assert_eq(game.local.party.size(), 1)
		assert_true(game.local.party.at(0) == original)
		# The same world reloaded from its own journal stays closed.
		var reloaded := GameFixture.new()
		reloaded.save_system = game.save_system
		reloaded.local = game.local
		assert_true(game.save_system.save_world(game, "slot-0"))
		reloaded.world.load_data(game.save_system.store.read("slot-0"))
		assert_no_new_guardian_offer(reloaded, ["A"])
	# (b) Only the settlement flags survived (no `water_guardian_claimed`).
	var settled_only := old_model_settled_world("settled-only")
	settled_only.world.flags.set_flag("water_guardian_claimed", false)
	assert_true(REWARD.is_legacy_world(settled_only.world))
	assert_no_new_guardian_offer(settled_only, ["A", "B"])
	# (c) A legacy world whose recipient this host recorded (A): A is already
	# resolved and nothing is written (B, a journaled participant, gets its
	# own offer: test_water_guardian_legacy.gd).
	var recorded := legacy_world_fixture("A")
	recorded.local.character_id = "A"
	recorded.local.flags.set_flag("water_capture_receipt:" + REWARD.legacy_claim_id("slot-0"))
	assert_false(REWARD.local_may_answer(recorded))
	var recorded_ledger := LEDGER.new(recorded.world)
	var recorded_before: Dictionary = recorded.world.save_data()
	assert_eq(REWARD.begin(recorded, recorded_ledger, "A", guardian()).code, "already_resolved")
	assert_eq(REWARD.refuse(recorded, recorded_ledger, "A").code, "already_resolved")
	assert_eq(recorded.world.save_data(), recorded_before, "nothing is written for the recorded recipient")
	assert_eq(recorded.local.party.size(), 0)
	# already_received honours the legacy receipt for any Guardian claim naming
	# that world_id, with or without host stamps; never another world_id or a
	# non-Guardian claim.
	var unstamped := {"id": REWARD.claim_id("another-instance", "A"), "source": "guardian", "world_id": "slot-0"}
	assert_true(REWARD.already_received(recorded.local.flags, unstamped))
	var other_slot := unstamped.duplicate()
	other_slot["world_id"] = "slot-1"
	assert_false(REWARD.already_received(recorded.local.flags, other_slot))
	var capture := unstamped.duplicate()
	capture["source"] = "wild"
	assert_false(REWARD.already_received(recorded.local.flags, capture))

# --- WaterCaptureClaims sender -> character mapping (fake peers) --------------

class FakeGame extends Node:
	var host := true
	var world: RefCounted
	var local: RefCounted
	var save_system: RefCounted
	var pending_catch: RefCounted = null
	var current_realm := "water"
	var session: RefCounted = FakeSession.new()
	func is_host() -> bool: return host

class FakeSession extends RefCounted:
	func local_peer_id() -> int: return 1

## The host bridge (ledger_rpc in production): resolves a peer to its actor.
class FakeBridge extends Node:
	var ledger: RefCounted
	var peers := {}
	var published: Array = []
	func _water_actor_context(peer: int, _intent: Dictionary) -> Dictionary:
		return {"character_id": peers[peer]} if peers.has(peer) else {}
	func publish_journaled_delta(delta: Dictionary) -> void:
		published.append(delta)

class Claims extends "res://scripts/net/water_capture_claims.gd":
	var fake_game: Node
	var fake_bridge: Node
	var sender := 0
	func _game() -> Node: return fake_game
	func _bridge() -> Node: return fake_bridge
	func _sender() -> int: return sender

## Records refusals instead of sending them (no transport in unit tests).
class SpyClaims extends Claims:
	var sent_declines: Array = []
	func _send_decline(id: String) -> void: sent_declines.append(id)

func claims_fixture(game: RefCounted, spy: bool = false) -> Claims:
	var fake := FakeGame.new()
	fake.world = game.world
	fake.local = game.local
	fake.save_system = game.save_system
	var bridge := FakeBridge.new()
	bridge.ledger = LEDGER.new(game.world)
	bridge.peers = {1: "host-char", 2: "A", 3: "B"}
	var claims: Claims = SpyClaims.new() if spy else Claims.new()
	claims.fake_game = fake
	claims.fake_bridge = bridge
	return claims

func free_claims(claims: Claims) -> void:
	claims.fake_game.free()
	claims.fake_bridge.free()
	claims.free()

func test_decline_rpc_maps_the_sender_to_its_own_character_only() -> void:
	var game := fixture(["A", "B"])
	var claims := claims_fixture(game)
	var ledger: RefCounted = claims.fake_bridge.ledger
	var a := REWARD.begin(game, ledger, "A", guardian())
	var b := REWARD.begin(game, ledger, "B", guardian())
	# Peer 3 (B) tries to refuse A's claim: the sender maps to B, so nothing.
	claims.sender = 3
	claims._decline(a.id)
	assert_true(game.world.water_capture_claims.has(a.id), "a peer cannot refuse another character's offer")
	assert_eq(settled_count(game), 0)
	# An unknown peer maps to no character at all.
	claims.sender = 9
	claims._decline(b.id)
	assert_true(game.world.water_capture_claims.has(b.id))
	# Peer 2 (A) refuses its own.
	claims.sender = 2
	claims._decline(a.id)
	assert_false(game.world.water_capture_claims.has(a.id))
	assert_true(game.world.water_capture_claims.has(b.id))
	assert_eq(settled_count(game), 3)
	assert_eq(claims.fake_bridge.published.size(), 1, "the refusal delta is published once")
	# A client (non-host) never settles from an RPC.
	claims.fake_game.host = false
	claims.sender = 3
	claims._decline(b.id)
	assert_true(game.world.water_capture_claims.has(b.id))
	free_claims(claims)

func test_ack_rpc_guardian_branch_resolves_only_the_senders_claim() -> void:
	var game := fixture(["A", "B"])
	var claims := claims_fixture(game)
	var ledger: RefCounted = claims.fake_bridge.ledger
	var a := REWARD.begin(game, ledger, "A", guardian())
	var b := REWARD.begin(game, ledger, "B", guardian())
	claims.sender = 2
	claims._ack(b.id)
	assert_true(game.world.water_capture_claims.has(b.id), "A's ack cannot settle B's offer")
	claims.sender = 3
	claims._ack(b.id)
	assert_false(game.world.water_capture_claims.has(b.id), "guardian branch settles B's own offer")
	assert_true(game.world.water_capture_claims.has(a.id))
	assert_true(REWARD.has_been_offered(game.world, "B"))
	assert_eq(settled_count(game), 3, "the first acceptance restores the world once")
	assert_eq(claims.fake_bridge.published.size(), 1)
	# A replayed ack is harmless and publishes nothing new.
	claims._ack(b.id)
	assert_eq(claims.fake_bridge.published.size(), 1)
	free_claims(claims)

func test_receive_claim_keeps_separate_characters_and_world_instances_apart() -> void:
	var game := instance_fixture("joined-instance", ["A", "C"])
	var ledger := LEDGER.new(game.world)
	var for_a: Dictionary = game.world.water_capture_claims[REWARD.begin(game, ledger, "A", guardian()).id]
	var for_c: Dictionary = game.world.water_capture_claims[REWARD.begin(game, ledger, "C", guardian()).id]
	var claims := claims_fixture(game)
	claims.fake_game.host = false
	game.local.character_id = "C"
	# C already accepted in its own slot-0 world: that receipt is not this one.
	game.local.flags.set_flag("water_capture_receipt:" + REWARD.claim_id("own-slot-zero-instance", "C"))
	claims.receive_claim(for_a)
	assert_eq(claims.pending_guardian_id(), "", "another character's claim is never presented here")
	var foreign := for_c.duplicate(true)
	foreign["world_instance"] = "own-slot-zero-instance"
	foreign["id"] = REWARD.claim_id("own-slot-zero-instance", "C")
	claims.receive_claim(foreign)
	assert_eq(claims.pending_guardian_id(), "", "a claim from a different slot-0 instance is ignored")
	claims.receive_claim(for_c)
	assert_eq(claims.pending_guardian_id(), str(for_c.id), "C's offer in this instance is presented, not acked away")
	free_claims(claims)

# --- review fixes: decline confirmation, stale claims, legacy recipient ------

func test_chamber_decline_refused_by_host_leaves_the_next_invite_presentable() -> void:
	var game := instance_fixture("decline-refused-instance", ["C"])
	game.local.character_id = "C"
	var claims := claims_fixture(game, true)
	claims.fake_game.host = false
	var ledger: RefCounted = claims.fake_bridge.ledger
	var id := REWARD.claim_id(REWARD.world_instance(game.world), "C")
	# The chamber decline intent is in flight: only a provisional hold.
	claims.hold_for_decline(id)
	assert_true(claims.held_for_decline(id))
	assert_false(claims.is_declined(id), "nothing is recorded as declined before the host answers")
	# The host refuses the decline (journal failure) and says so.
	game.save_system.fail_write = true
	assert_false(REWARD.refuse(game, ledger, "C").ok)
	game.save_system.fail_write = false
	claims.release_decline(id)
	assert_false(claims.held_for_decline(id))
	assert_false(claims.is_declined(id))
	# A later Invite: the same id is minted, reaches this peer and is presented.
	var offer := REWARD.begin(game, ledger, "C", guardian())
	assert_true(offer.ok)
	assert_eq(offer.id, id)
	var claim: Dictionary = game.world.water_capture_claims[id]
	claims.receive_claim(claim)
	assert_eq(claims.pending_guardian_id(), id, "the invite's claim is presented")
	assert_true((claims.get("sent_declines") as Array).is_empty(), "no silent automatic refusal")
	var granted := TX.settle(game, claim, guardian(), -1)
	assert_true(granted.ok, "and it can be accepted")
	assert_false(granted.already)
	assert_eq(game.local.party.size(), 1)
	free_claims(claims)

func test_decline_in_flight_holds_a_crossing_claim_until_the_host_answers() -> void:
	var game := instance_fixture("decline-crossing-instance", ["C"])
	game.local.character_id = "C"
	var claims := claims_fixture(game, true)
	claims.fake_game.host = false
	var ledger: RefCounted = claims.fake_bridge.ledger
	var offer := REWARD.begin(game, ledger, "C", guardian())
	var claim: Dictionary = game.world.water_capture_claims[offer.id]
	claims.hold_for_decline(offer.id)
	claims.receive_claim(claim)
	assert_true(claims.held_for_decline(offer.id), "a claim crossing the decline is held, not presented")
	assert_false(claims.presentable(), "held claims never open the roster choice")
	assert_true((claims.get("sent_declines") as Array).is_empty(), "and it is not refused before the host confirms")
	# Host confirms: the held claim is dropped and later resends are refused.
	assert_true(REWARD.refuse(game, ledger, "C").ok)
	claims.confirm_declined(offer.id)
	assert_true(claims.is_declined(offer.id))
	assert_eq(claims.pending_guardian_id(), "")
	claims.receive_claim(claim)
	assert_eq(claims.get("sent_declines"), [offer.id], "a stale resend after the confirmed refusal is refused")
	# Control: a released hold presents the claim again.
	var other := claims_fixture(game, true)
	other.fake_game.host = false
	other.hold_for_decline(offer.id)
	other.receive_claim(claim)
	other.release_decline(offer.id)
	assert_true(other.presentable())
	free_claims(other)
	free_claims(claims)

func test_stale_queued_claim_from_another_world_or_character_cannot_drive_a_decline() -> void:
	var game := instance_fixture("stale-queue-instance", ["C"])
	game.local.character_id = "C"
	var claims := claims_fixture(game, true)
	claims.fake_game.host = false
	var ledger: RefCounted = claims.fake_bridge.ledger
	var claim: Dictionary = game.world.water_capture_claims[REWARD.begin(game, ledger, "C", guardian()).id]
	claims.receive_claim(claim)
	assert_eq(claims.pending_guardian_id(), str(claim.id), "control: queued while it matched")
	# The peer moves to another world instance (same slot locator).
	var elsewhere := instance_fixture("another-host-instance", ["C"])
	claims.fake_game.world = elsewhere.world
	assert_eq(claims.pending_guardian_id(), "", "a queued claim from another world is not this peer's Guardian claim")
	assert_false(claims.decline_pending().ok, "and cannot drive a phantom decline")
	assert_true((claims.get("sent_declines") as Array).is_empty())
	claims._process(2.0)
	assert_eq(claims.get("_pending"), {}, "_process drops the mismatched queued claim")
	# Same world, but the local character changed.
	claims.fake_game.world = game.world
	claims.receive_claim(claim)
	assert_eq(claims.pending_guardian_id(), str(claim.id))
	game.local.character_id = "D"
	assert_eq(claims.pending_guardian_id(), "", "another character's queued claim is not ours")
	assert_false(claims.decline_pending().ok)
	assert_true((claims.get("sent_declines") as Array).is_empty())
	claims._process(2.0)
	assert_eq(claims.get("_pending"), {})
	free_claims(claims)

## Records host -> peer decline confirmations (no transport in unit tests).
class ConfirmSpyClaims extends Claims:
	var confirmed: Array = []
	func _confirm_decline_to(peer: int, id: String) -> void:
		confirmed.append([peer, id])
		super(peer, id)

func test_held_claim_decline_is_confirmed_only_after_the_host_journals_it() -> void:
	# Host-local character: decline_pending() reaches the host synchronously.
	var game := fixture(["host-char", "A"])
	var claims: Claims = ConfirmSpyClaims.new()
	var fake := FakeGame.new()
	fake.world = game.world
	fake.local = game.local
	fake.save_system = game.save_system
	var bridge := FakeBridge.new()
	bridge.ledger = LEDGER.new(game.world)
	bridge.peers = {1: "host-char", 2: "A", 3: "B"}
	claims.fake_game = fake
	claims.fake_bridge = bridge
	var offer := REWARD.begin(game, bridge.ledger, "host-char", guardian())
	var claim: Dictionary = game.world.water_capture_claims[offer.id]
	claims.receive_claim(claim)
	assert_eq(claims.pending_guardian_id(), str(offer.id))
	game.save_system.fail_write = true
	assert_true(claims.decline_pending().ok, "the refusal is sent")
	assert_true(game.world.water_capture_claims.has(offer.id), "the host could not journal it")
	assert_false(claims.decline_settled(str(offer.id)), "an unjournaled refusal is not confirmed")
	assert_eq(claims.get("confirmed"), [])
	# The host's next resend of the claim retries the refusal, which now lands.
	game.save_system.fail_write = false
	claims.receive_claim(claim)
	assert_false(game.world.water_capture_claims.has(offer.id))
	assert_true(claims.decline_settled(str(offer.id)), "confirmed once journaled")
	# A remote participant: confirmed to ITS peer only after its own journal.
	var a := REWARD.begin(game, bridge.ledger, "A", guardian())
	game.save_system.fail_write = true
	claims.sender = 2
	claims._decline(a.id)
	assert_eq(claims.get("confirmed"), [[1, str(offer.id)]], "a failed journal confirms nothing")
	game.save_system.fail_write = false
	claims.sender = 3
	claims._decline(a.id)
	assert_eq(claims.get("confirmed"), [[1, str(offer.id)]], "another peer cannot get A's refusal confirmed")
	claims.sender = 2
	claims._decline(a.id)
	assert_eq(claims.get("confirmed"), [[1, str(offer.id)], [2, str(a.id)]])
	# The joiner side records the host's confirmation.
	var joiner := claims_fixture(game)
	joiner.fake_game.host = false
	assert_false(joiner.decline_settled(str(a.id)))
	joiner._decline_done(str(a.id))
	assert_true(joiner.decline_settled(str(a.id)))
	free_claims(joiner)
	free_claims(claims)

func legacy_world_fixture(legacy_recipient: String) -> RefCounted:
	var game := fixture(["A", "B"])
	game.world.world_id = "slot-0"
	game.world.reward_delivery_namespace = "legacy-instance"
	for flag: String in ["water_guardian_claimed"] + REWARD.SETTLEMENT:
		game.world.flags.set_flag(flag)
	if not legacy_recipient.is_empty():
		game.world.flags.set_flag(REWARD.legacy_recipient_flag(legacy_recipient))
	return game

func test_other_participants_in_a_legacy_world_with_a_journal_get_their_own_offer() -> void:
	# Owner decision: A received this legacy world's single offer; B, whom the
	# delivery journal names, gets its own once-only offer and really receives
	# the Guardian.
	var game := legacy_world_fixture("A")
	game.local.character_id = "B"
	assert_true(REWARD.is_legacy_world(game.world))
	assert_true(REWARD.local_may_answer(game), "B sees the Invite prompt")
	var ledger := LEDGER.new(game.world)
	var offer := REWARD.begin(game, ledger, "B", guardian())
	assert_true(offer.ok)
	var granted := TX.settle(game, game.world.water_capture_claims[offer.id], guardian(), -1)
	assert_true(granted.ok and not granted.already)
	assert_eq(game.local.party.size(), 1)
	var resolved := REWARD.resolve(game, ledger, offer.id, "B", true)
	assert_true(resolved.ok)
	for op: Dictionary in resolved.delta.ops:
		assert_false(REWARD.SETTLEMENT.has(str(op.get("id", ""))), "the legacy world was settled once already")
	assert_eq(REWARD.begin(game, ledger, "B", guardian()).code, "already_resolved")
	assert_true(REWARD.is_legacy_world(game.world))

func test_unknown_legacy_recipient_world_offers_named_participants_and_the_receipt_holder_gets_nothing() -> void:
	# The legacy claim was erased before recipients were recorded. The journal
	# names A and B, so both may be offered; A (the unidentified original
	# recipient, holding the legacy receipt) is never shown the invite and a
	# claim minted for it anyway delivers no creature.
	var game := legacy_world_fixture("")
	game.local.character_id = "A"
	game.local.flags.set_flag("water_capture_receipt:" + REWARD.legacy_claim_id("slot-0"))
	assert_false(REWARD.local_may_answer(game))
	var ledger := LEDGER.new(game.world)
	var a := REWARD.begin(game, ledger, "A", guardian())
	assert_true(a.ok)
	var settled := TX.settle(game, game.world.water_capture_claims[a.id], guardian(), -1)
	assert_true(settled.ok and settled.already, "acknowledged with no creature")
	assert_eq(game.local.party.size(), 0)
	assert_true(REWARD.begin(game, ledger, "B", guardian()).ok)

func test_legacy_recipient_is_recorded_when_the_legacy_claim_is_answered() -> void:
	var game := fixture(["A", "B"])
	game.world.world_id = "slot-0"
	var ledger := LEDGER.new(game.world)
	var legacy := REWARD.legacy_claim_id("slot-0")
	game.world.flags.set_flag("water_guardian_claimed")
	game.world.water_capture_claims[legacy] = {"id": legacy, "source": "guardian", "world_id": "slot-0",
		"character_id": "A", "creature": preload("res://scripts/save/water_capture_codec.gd").encode(guardian())}
	# B, whom the journal names, gets its own offer (owner decision); that is
	# never recorded as the legacy recipient.
	assert_true(REWARD.begin(game, ledger, "B", guardian()).ok)
	assert_false(game.world.flags.has(REWARD.legacy_recipient_flag("B")))
	# The pending legacy claim is presented to its own recipient only.
	var view := GameFixture.new()
	view.host = false
	view.world = game.world
	view.local.character_id = "A"
	assert_true(REWARD.local_may_answer(view), "the pending legacy recipient may still answer")
	view.local.character_id = "B"
	assert_false(REWARD.local_may_answer(view), "B already holds its own offer")
	var legacy_claim: Dictionary = game.world.water_capture_claims[legacy].duplicate(true)
	# Refusing the pending legacy claim records its recipient in the journal.
	assert_true(REWARD.refuse(game, ledger, "A").ok)
	assert_true(game.world.flags.has(REWARD.legacy_recipient_flag("A")))
	var restored := WORLD.new()
	restored.load_data(game.save_system.store.read(game.world.world_id))
	assert_true(restored.flags.has(REWARD.legacy_recipient_flag("A")), "recipient marker is in the world journal")
	# Resolving the legacy claim also records its recipient (fresh world copy).
	var other := fixture(["A"])
	other.world.world_id = "slot-0"
	other.world.flags.set_flag("water_guardian_claimed")
	other.world.water_capture_claims[legacy] = legacy_claim
	var other_ledger := LEDGER.new(other.world)
	assert_true(REWARD.resolve(other, other_ledger, legacy, "A", true).ok)
	assert_true(other.world.flags.has(REWARD.legacy_recipient_flag("A")))

func test_begin_and_refuse_establish_world_identity_before_minting() -> void:
	var game := fixture(["A", "B"])
	game.world.world_id = "slot-0"
	assert_eq(game.world.reward_delivery_namespace, "")
	var ledger := LEDGER.new(game.world)
	var offer := REWARD.begin(game, ledger, "A", guardian())
	assert_true(offer.ok)
	var instance: String = game.world.reward_delivery_namespace
	assert_false(instance.is_empty(), "begin() ensures the world identity first")
	var claim: Dictionary = game.world.water_capture_claims[offer.id]
	assert_eq(claim.world_instance, instance, "the claim never falls back to the slot locator on a live host")
	assert_ne(claim.world_instance, "slot-0")
	assert_eq(offer.id, REWARD.claim_id(instance, "A"))
	# A later save (which ensures identity again) does not orphan the claim.
	preload("res://scripts/save/world_identity.gd").ensure(game.world)
	assert_true(REWARD.claim_matches_world(claim, game.world))
	var reloaded := WORLD.new()
	reloaded.load_data(game.save_system.store.read(game.world.world_id))
	assert_eq(reloaded.reward_delivery_namespace, instance, "identity is journaled with the claim")
	assert_true(REWARD.claim_matches_world(claim, reloaded))
	# refuse() likewise ensures identity (no claim, but the same rule).
	var refusing := fixture(["A"])
	assert_true(REWARD.refuse(refusing, LEDGER.new(refusing.world), "A").ok)
	assert_false(str(refusing.world.reward_delivery_namespace).is_empty())

# --- Edda's offer line is gated per character ---------------------------------

func test_edda_offers_only_to_a_character_that_may_still_answer() -> void:
	var game := fixture(["A", "B"])
	var ledger := LEDGER.new(game.world)
	var view := GameFixture.new()
	view.host = false
	view.world = game.world
	view.local.character_id = "A"
	assert_eq(REWARD.edda_conversation(view, false), REWARD.EDDA_OFFER, "participant with no answer yet")
	view.local.character_id = "C"
	assert_eq(REWARD.edda_conversation(view, false), REWARD.EDDA_NEUTRAL, "non-participant hears the neutral line")
	view.local.character_id = "A"
	REWARD.begin(game, ledger, "A", guardian())
	assert_eq(REWARD.edda_conversation(view, false), REWARD.EDDA_NEUTRAL, "an offered/answered character is not re-invited")
	assert_eq(REWARD.edda_conversation(view, true), REWARD.EDDA_OFFER, "a locally pending claim may still be opened")
	REWARD.decline(game, ledger, "A")
	assert_true(game.world.flags.has("water_currents_restored"))
	assert_eq(REWARD.edda_conversation(view, false), REWARD.EDDA_POST, "after restoration: her ordinary post greeting, still no offer")
	view.local.character_id = "B"
	assert_eq(REWARD.edda_conversation(view, false), REWARD.EDDA_OFFER, "B's own offer is unaffected by A's answer")
	var tethered := fixture(["A"])
	tethered.world.flags.set_flag("water_guardian_freed", false)
	assert_eq(REWARD.edda_conversation(tethered, false), "", "before the freeing Edda keeps her ordinary greeting")

func test_edda_fallback_is_authored_speech_without_effects() -> void:
	var dialogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/water.json"))
	var conversations: Dictionary = dialogue.conversations
	assert_true(conversations.has(REWARD.EDDA_OFFER))
	assert_true(conversations.has(REWARD.EDDA_NEUTRAL))
	var neutral: Dictionary = conversations[REWARD.EDDA_NEUTRAL]
	assert_eq(str(neutral.speaker), str(conversations[REWARD.EDDA_OFFER].speaker))
	assert_false((neutral.lines as Array).is_empty())
	for fallback: String in [REWARD.EDDA_NEUTRAL, REWARD.EDDA_POST]:
		assert_eq(str(conversations[fallback].speaker), str(conversations[REWARD.EDDA_OFFER].speaker))
		for line: Variant in conversations[fallback].lines:
			assert_true(line is String, "fallback speech carries no effect or flag")
	var cast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	var guarded: Array = []
	for guard: Dictionary in cast.dialogue_event_guards:
		guarded.append(str(guard.conversation))
	assert_true(guarded.has(REWARD.EDDA_OFFER))
	assert_false(guarded.has(REWARD.EDDA_NEUTRAL), "the fallback requests nothing")
	assert_false(guarded.has(REWARD.EDDA_POST))

class FakePrompt extends Node:
	signal activated()

class FakeBody extends Node:
	var prompt: Node = FakePrompt.new()
	func prompt_node() -> Node: return prompt

class FakeCast extends Node:
	var started: Array = []
	var greeted: Array = []
	func _on_greeted(id: String) -> void: greeted.append(id)
	func start_conversation(id: String, requested: String = "") -> bool:
		started.append([id, requested])
		return true

func test_edda_greeting_is_rerouted_through_the_participant_gate() -> void:
	var game := fixture(["A"])
	game.local.character_id = "C"
	var cast := FakeCast.new()
	var body := FakeBody.new()
	body.prompt.activated.connect(cast._on_greeted.bind(REWARD.EDDA_ID))
	REWARD.gate_edda_offer(cast, {REWARD.EDDA_ID: body}, game)
	body.prompt.activated.emit()
	assert_eq(cast.greeted, [], "the cast's ungated greet handler no longer opens the offer")
	assert_eq(cast.started, [[REWARD.EDDA_ID, REWARD.EDDA_NEUTRAL]])
	game.local.character_id = "A"
	body.prompt.activated.emit()
	assert_eq(cast.started[1], [REWARD.EDDA_ID, REWARD.EDDA_OFFER])
	body.prompt.free()
	body.free()
	cast.free()
