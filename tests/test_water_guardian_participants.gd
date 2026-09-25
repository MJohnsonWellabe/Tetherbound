extends "res://tests/test_case.gd"

## F14 / CLAUDE.md freed-legendary rule for the Abyssal Guardian: every
## participant in the fight that freed it (every journaled Nerissa reward
## delivery row, whatever its status, or the host's own character only when no
## such row exists) receives their own once-only offer per WORLD INSTANCE;
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

func test_legacy_receipt_from_another_slot_zero_instance_does_not_block() -> void:
	var game := instance_fixture("fresh-instance")
	game.local.character_id = "C"
	# C holds a pre-F14 receipt that some OTHER slot-0 world issued.
	game.local.flags.set_flag("water_capture_receipt:" + REWARD.legacy_claim_id("slot-0"))
	var ledger := LEDGER.new(game.world)
	assert_false(REWARD.is_legacy_world(game.world))
	var offer := REWARD.begin(game, ledger, "C", guardian())
	var claim: Dictionary = game.world.water_capture_claims[offer.id]
	assert_false(claim.has("legacy_world"))
	assert_false(REWARD.already_received(game.local.flags, claim))
	var granted := TX.settle(game, claim, guardian(), -1)
	assert_true(granted.ok)
	assert_false(granted.already)
	assert_eq(game.local.party.size(), 1)

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
	assert_true(claim.get("legacy_world", false), "the legacy instance stamps its own claims")
	# The same receipt does not count for an unstamped claim naming the SAME
	# slot locator: only the world instance that made the legacy offer may
	# honour it (another slot-0 world's claim is never legacy-stamped).
	var unstamped := claim.duplicate()
	unstamped.erase("legacy_world")
	unstamped["id"] = REWARD.claim_id("another-instance", "A")
	assert_false(REWARD.already_received(game.local.flags, unstamped))
	unstamped["legacy_world"] = true
	assert_true(REWARD.already_received(game.local.flags, unstamped), "control: stamping is what enables the legacy match")

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

func claims_fixture(game: RefCounted) -> Claims:
	var fake := FakeGame.new()
	fake.world = game.world
	fake.local = game.local
	fake.save_system = game.save_system
	var bridge := FakeBridge.new()
	bridge.ledger = LEDGER.new(game.world)
	bridge.peers = {1: "host-char", 2: "A", 3: "B"}
	var claims := Claims.new()
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
