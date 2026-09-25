extends "res://tests/test_case.gd"

## F14 Guardian offers in LEGACY (pre-F14 single-recipient) Tidewake worlds,
## plus the interim multi-peer rule and refusal-path hygiene.
##
## Owner decision (settled): where a legacy world's delivery journal names the
## freeing-fight participants (Nerissa `trainer:water_trainer_nerissa:` rows),
## every named participant gets their own once-only Guardian offer. Where it
## has no journal, the legacy single-recipient outcome stands. The legacy
## recipient never receives a second Guardian: (a) a still-pending legacy
## claim is answered by its own recipient only; (b) an unidentified settled
## recipient is protected by its character-side legacy receipt; (c) a
## character named by a legacy_recipient flag is already resolved.

const REWARD := preload("res://scripts/world/water_guardian_reward.gd")
const TX := preload("res://scripts/save/water_capture_transaction.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const SAVE := preload("res://scripts/save/world_save.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PARTY := preload("res://autoload/party.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")

class Saver extends RefCounted:
	var fail_write := false
	var writes := 0
	var store: RefCounted = SAVE.new("user://guardian_legacy_%d/" % Time.get_ticks_usec())
	func save_world(game: Object, id: String) -> bool:
		writes += 1
		var snapshot: Dictionary = game.world.save_data()
		snapshot.progression = game.world.flags.save_data()
		return false if fail_write else store.write(id, SAVE.partition(snapshot))
	func save_character(_game: Object, _id: String) -> bool:
		return true

class LocalFixture extends RefCounted:
	var character_id := "host-char"
	var party := PARTY.new()
	var flags := FLAGS.new()

class FakeSession extends RefCounted:
	func local_peer_id() -> int: return 1

## A Node game so the same fixture drives REWARD, the claim service and the
## Veilfall view cache.
class FakeGame extends Node:
	var host := true
	var multi := false
	var world: RefCounted = WORLD.new()
	var local: RefCounted = LocalFixture.new()
	var save_system: RefCounted = Saver.new()
	var pending_catch: RefCounted = null
	var current_realm := "water"
	var session: RefCounted = FakeSession.new()
	func is_host() -> bool: return host
	func is_multi_peer() -> bool: return multi

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
	var acknowledged: Array = []
	func _game() -> Node: return fake_game
	func _bridge() -> Node: return fake_bridge
	func _sender() -> int: return sender
	## A joiner's acknowledgement is recorded instead of sent (no transport).
	func _acknowledge(id: String) -> void:
		if fake_game.is_host():
			super(id)
		else:
			acknowledged.append(id)

var _nodes: Array = []

func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()

func _keep(node: Node) -> Node:
	_nodes.append(node)
	return node

static func add_row(world: RefCounted, character: String) -> void:
	var source := "trainer:water_trainer_nerissa:coins"
	var id := ("%s|%s" % [source, character]).sha256_text()
	world.reward_deliveries[id] = {"delivery_id": id, "world_id": world.world_id, "source": source,
		"character_id": character, "status": "accepted"}

func guardian() -> RefCounted:
	return SPECIES.spawn("water_abyssal_guardian")

func freed(participants: Array) -> FakeGame:
	var game := _keep(FakeGame.new()) as FakeGame
	game.world.world_id = "slot-0"
	for flag: String in ["water_captain_nerissa_defeated", "water_tether_disabled", "water_guardian_freed"]:
		game.world.flags.set_flag(flag)
	for character: String in participants:
		add_row(game.world, character)
	return game

## A pre-F14 world whose single offer was already accepted and settled: the
## claim is erased, `water_guardian_claimed` and every settlement flag are set,
## and no per-character marker exists. `recipient` non-empty: this host
## recorded who it was (legacy_recipient flag).
func legacy_settled(participants: Array, recipient: String = "") -> FakeGame:
	var game := freed(participants)
	game.world.reward_delivery_namespace = "legacy-instance"
	for flag: String in [REWARD.CLAIMED] + REWARD.SETTLEMENT:
		game.world.flags.set_flag(flag)
	if not recipient.is_empty():
		game.world.flags.set_flag(REWARD.legacy_recipient_flag(recipient))
	return game

## A pre-F14 world whose single offer to `recipient` is still pending.
func legacy_pending(participants: Array, recipient: String) -> FakeGame:
	var game := freed(participants)
	var legacy := REWARD.legacy_claim_id("slot-0")
	game.world.flags.set_flag(REWARD.CLAIMED)
	game.world.water_capture_claims[legacy] = {"id": legacy, "source": "guardian", "world_id": "slot-0",
		"character_id": recipient, "creature": CODEC.encode(guardian())}
	return game

func settlement_ops(result: Dictionary) -> int:
	var n := 0
	if result.has("delta"):
		for op: Dictionary in result.delta.ops:
			if REWARD.SETTLEMENT.has(str(op.get("id", ""))):
				n += 1
	return n

func settled_count(game: FakeGame) -> int:
	var n := 0
	for flag: String in REWARD.SETTLEMENT:
		if game.world.flags.has(flag):
			n += 1
	return n

func view(game: FakeGame, character: String) -> FakeGame:
	var joiner := _keep(FakeGame.new()) as FakeGame
	joiner.host = false
	joiner.multi = true
	joiner.world = game.world
	joiner.local.character_id = character
	return joiner

## Every call leaves the world, ledger and save file exactly as it was.
func assert_untouched(game: FakeGame, ledger: RefCounted, call: Callable, label: String) -> Dictionary:
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var sequence: int = ledger.seq
	var writes: int = game.save_system.writes
	var result: Dictionary = call.call()
	assert_eq(game.world.save_data(), before, label + ": world unchanged")
	assert_eq(game.world.revision, revision, label + ": revision unchanged")
	assert_eq(ledger.seq, sequence, label + ": ledger unchanged")
	assert_eq(game.save_system.writes, writes, label + ": nothing saved")
	return result

# --- legacy world WITH a delivery journal --------------------------------------

func test_legacy_settled_world_with_journal_offers_each_named_participant_once() -> void:
	var game := legacy_settled(["A", "B", "C"])
	var ledger := LEDGER.new(game.world)
	assert_true(REWARD.is_legacy_world(game.world))
	var b := REWARD.begin(game, ledger, "B", guardian())
	assert_true(b.ok, "a journaled participant of a legacy world gets its own offer")
	assert_eq(b.code, "")
	assert_eq(b.id, REWARD.claim_id("legacy-instance", "B"), "the ordinary per-character claim, not the legacy id")
	assert_eq(settlement_ops(b), 0)
	assert_true(game.world.flags.has(REWARD.LEGACY_FLAG), "the world is journaled as legacy (sticky)")
	assert_true(REWARD.is_legacy_world(game.world), "offer markers never turn a legacy world into a new one")
	var c_refused := REWARD.refuse(game, ledger, "C")
	assert_true(c_refused.ok, "a participant may refuse without inviting")
	assert_eq(settlement_ops(c_refused), 0, "the settled world is never settled again")
	var b_done := REWARD.resolve(game, ledger, b.id, "B", true)
	assert_true(b_done.ok)
	assert_eq(settlement_ops(b_done), 0)
	assert_eq(settled_count(game), 3)
	# Once only, per participant.
	assert_eq(REWARD.begin(game, ledger, "B", guardian()).code, "already_resolved")
	assert_eq(REWARD.begin(game, ledger, "C", guardian()).code, "already_resolved")
	# The unnamed character (the host, a stranger) receives nothing.
	for stranger: String in ["host-char", "D"]:
		var refused: Dictionary = assert_untouched(game, ledger,
			func() -> Dictionary: return REWARD.begin(game, ledger, stranger, guardian()), stranger)
		assert_eq(refused.code, "not_participant")
	assert_true(game.world.water_capture_claims.is_empty())
	# The journal holds the new offers across a reload.
	var reloaded := WORLD.new()
	reloaded.load_data(game.save_system.store.read("slot-0"))
	assert_true(REWARD.has_been_offered(reloaded, "B") and REWARD.has_been_offered(reloaded, "C"))
	assert_true(REWARD.is_legacy_world(reloaded))

func test_legacy_world_offer_marker_before_legacy_flag_still_counts_as_legacy() -> void:
	# The journal must not depend on commit order: after the first new offer
	# the world is legacy by LEGACY_FLAG even though an offer marker exists.
	var game := legacy_settled(["A", "B"])
	var ledger := LEDGER.new(game.world)
	assert_true(REWARD.begin(game, ledger, "A", guardian()).ok)
	game.world.flags.set_flag(REWARD.CLAIMED, false)
	assert_true(REWARD.is_legacy_world(game.world))

# (a) still-pending legacy claim --------------------------------------------------

func test_pending_legacy_recipient_answers_only_its_claim_and_others_get_their_own() -> void:
	var game := legacy_pending(["A", "B", "C"], "A")
	var ledger := LEDGER.new(game.world)
	var legacy := REWARD.legacy_claim_id("slot-0")
	var replay := REWARD.begin(game, ledger, "A", guardian())
	assert_true(replay.ok)
	assert_eq(replay.code, "replay")
	assert_eq(replay.id, legacy, "the legacy recipient answers its original claim, no new mint")
	var b := REWARD.begin(game, ledger, "B", guardian())
	assert_true(b.ok, "the pending legacy claim does not block another named participant")
	assert_eq(game.world.water_capture_claims.size(), 2)
	# B answers first: that first resolution settles the (unsettled) world.
	var b_done := REWARD.resolve(game, ledger, b.id, "B", false)
	assert_true(b_done.ok)
	assert_eq(settlement_ops(b_done), 3, "the first resolution settles the world")
	# A's legacy claim resolves afterwards and settles nothing again.
	var a_done := REWARD.resolve(game, ledger, legacy, "A", true)
	assert_true(a_done.ok)
	assert_eq(settlement_ops(a_done), 0, "settlement exactly once")
	assert_true(game.world.flags.has(REWARD.legacy_recipient_flag("A")))
	assert_eq(REWARD.begin(game, ledger, "A", guardian()).code, "already_resolved", "never a second Guardian")
	# Resolving the legacy claim does not block C either.
	assert_true(REWARD.begin(game, ledger, "C", guardian()).ok)

func test_resolving_the_pending_legacy_claim_first_does_not_block_others() -> void:
	var game := legacy_pending(["A", "B"], "A")
	var ledger := LEDGER.new(game.world)
	var a_done := REWARD.resolve(game, ledger, REWARD.legacy_claim_id("slot-0"), "A", true)
	assert_true(a_done.ok)
	assert_eq(settlement_ops(a_done), 3, "the legacy claim's answer settles the world once")
	var b := REWARD.begin(game, ledger, "B", guardian())
	assert_true(b.ok)
	var b_done := REWARD.resolve(game, ledger, b.id, "B", true)
	assert_eq(settlement_ops(b_done), 0)
	assert_eq(REWARD.begin(game, ledger, "A", guardian()).code, "already_resolved")

# (b) settled legacy recipient the host cannot identify ----------------------------

func test_unidentified_legacy_recipient_new_claim_is_acknowledged_away_with_no_creature() -> void:
	var game := legacy_settled(["A", "B"])
	var bridge := _keep(FakeBridge.new()) as FakeBridge
	bridge.ledger = LEDGER.new(game.world)
	bridge.peers = {1: "host-char", 2: "A", 3: "B"}
	var host_claims := _keep(Claims.new()) as Claims
	host_claims.fake_game = game
	host_claims.fake_bridge = bridge
	# A (a guest) accepted the old single offer: its character holds the
	# pre-F14 receipt and the original Guardian; the host recorded nothing.
	var joiner := view(game, "A")
	var original := guardian()
	joiner.local.party.add(original)
	joiner.local.flags.set_flag(REWARD.RECEIPT_PREFIX + REWARD.legacy_claim_id("slot-0"))
	var joiner_claims := _keep(Claims.new()) as Claims
	joiner_claims.fake_game = joiner
	joiner_claims.fake_bridge = bridge
	# A's view shows no Invite prompt and Edda makes no offer ...
	assert_false(REWARD.local_may_answer(joiner), "the legacy recipient sees no invite")
	assert_ne(REWARD.edda_conversation(joiner, false), REWARD.EDDA_OFFER)
	# ... but even if the host mints A's claim (it cannot tell A received it),
	# A's client acknowledges it away without a creature.
	var minted := REWARD.begin(game, bridge.ledger, "A", guardian())
	assert_true(minted.ok)
	var claim: Dictionary = game.world.water_capture_claims[minted.id]
	joiner_claims.receive_claim(claim)
	assert_eq(joiner_claims.acknowledged, [str(minted.id)], "acknowledged at once")
	assert_eq(joiner_claims.pending_guardian_id(), "", "nothing is presented")
	assert_eq(joiner_claims.presentable(), false)
	assert_true(joiner.pending_catch == null)
	assert_eq(joiner.local.party.size(), 1, "party unchanged")
	assert_true(joiner.local.party.at(0) == original)
	assert_false(joiner.local.flags.has(REWARD.RECEIPT_PREFIX + str(minted.id)), "no new receipt")
	var settled := TX.settle(joiner, claim, guardian(), -1)
	assert_true(settled.ok and settled.already, "the transaction itself refuses a second Guardian")
	assert_eq(joiner.local.party.size(), 1)
	# The host receives A's acknowledgement and closes A's offer.
	host_claims.sender = 2
	host_claims._ack(str(minted.id))
	assert_false(game.world.water_capture_claims.has(minted.id))
	assert_true(REWARD.has_been_offered(game.world, "A"))
	assert_eq(settled_count(game), 3)
	for delta: Dictionary in bridge.published:
		assert_eq(settlement_ops({"delta": delta}), 0, "the settled world is not settled again")
	assert_eq(REWARD.begin(game, bridge.ledger, "A", guardian()).code, "already_resolved")
	# B is untouched and still gets its own.
	assert_true(REWARD.local_may_answer(view(game, "B")))
	assert_true(REWARD.begin(game, bridge.ledger, "B", guardian()).ok)

# (c) recorded legacy recipient -------------------------------------------------------

func test_recorded_legacy_recipient_is_already_resolved() -> void:
	var game := legacy_settled(["A", "B"], "A")
	var ledger := LEDGER.new(game.world)
	assert_false(REWARD.has_been_offered(game.world, "A"), "fixture: only the legacy_recipient flag names A")
	var began: Dictionary = assert_untouched(game, ledger,
		func() -> Dictionary: return REWARD.begin(game, ledger, "A", guardian()), "begin A")
	assert_false(began.ok)
	assert_eq(began.code, "already_resolved")
	var refused: Dictionary = assert_untouched(game, ledger,
		func() -> Dictionary: return REWARD.refuse(game, ledger, "A"), "refuse A")
	assert_eq(refused.code, "already_resolved")
	assert_false(REWARD.local_may_answer(view(game, "A")))
	assert_ne(REWARD.edda_conversation(view(game, "A"), false), REWARD.EDDA_OFFER)
	# B still may.
	assert_true(REWARD.local_may_answer(view(game, "B")))
	assert_eq(REWARD.edda_conversation(view(game, "B"), false), REWARD.EDDA_OFFER)
	assert_true(REWARD.begin(game, ledger, "B", guardian()).ok)

# --- legacy world WITHOUT a journal: unchanged --------------------------------------

func test_legacy_world_without_journal_keeps_the_single_recipient_outcome() -> void:
	for multi: bool in [false, true]:
		var game := legacy_settled([])
		game.multi = multi
		var ledger := LEDGER.new(game.world)
		for character: String in ["host-char", "A"]:
			var began: Dictionary = assert_untouched(game, ledger,
				func() -> Dictionary: return REWARD.begin(game, ledger, character, guardian()), "begin " + character)
			assert_eq(began.code, "legacy_world", "no host-local fallback in a legacy world")
			var refused: Dictionary = assert_untouched(game, ledger,
				func() -> Dictionary: return REWARD.refuse(game, ledger, character), "refuse " + character)
			assert_eq(refused.code, "legacy_world")
		assert_false(REWARD.local_may_answer(game), "the solo host is not offered in a journal-less legacy world")
	# A pending legacy claim without a journal: only its recipient answers.
	var pending := legacy_pending([], "host-char")
	var pending_ledger := LEDGER.new(pending.world)
	assert_true(REWARD.local_may_answer(pending))
	assert_eq(REWARD.begin(pending, pending_ledger, "host-char", guardian()).code, "replay")
	assert_eq(REWARD.begin(pending, pending_ledger, "A", guardian()).code, "legacy_world")

# --- interim multi-peer rule (documented gaps) --------------------------------------

## INTERIM GAP (documented, not fixed here): a lone guest fights Nerissa on its
## own client, which journals no delivery rows today, then leaves. The host,
## now solo with an empty journal, is treated as the solo winner and offered.
## Once ralph/trainer-participants-host lands, the host journals the guest's
## win as delivery rows; the journal is then non-empty and names only the
## guest, so this host is refused `not_participant` -- update this test then.
func test_interim_gap_guest_fights_alone_then_leaves_and_host_is_offered() -> void:
	var game := freed([])
	var ledger := LEDGER.new(game.world)
	game.multi = true
	assert_eq(REWARD.begin(game, ledger, "host-char", guardian()).code, "not_participant",
		"while the guest is connected nobody is presumed")
	game.multi = false # the guest left
	assert_true(REWARD.local_may_answer(game), "INTERIM GAP: the solo host is offered")
	assert_true(REWARD.begin(game, ledger, "host-char", guardian()).ok, "INTERIM GAP: documented, see header")

## Disclosed delay: a SOLO Nerissa win journals no rows either, so a host who
## beat her alone and then invites a guest before answering cannot answer
## while the guest is connected; the offer returns when the session is solo.
func test_solo_win_then_invite_delays_the_answer_until_solo_again() -> void:
	var game := freed([])
	var ledger := LEDGER.new(game.world)
	assert_true(REWARD.local_may_answer(game))
	game.multi = true
	assert_false(REWARD.local_may_answer(game))
	assert_eq(assert_untouched(game, ledger,
		func() -> Dictionary: return REWARD.begin(game, ledger, "host-char", guardian()), "begin").code, "not_participant")
	assert_eq(assert_untouched(game, ledger,
		func() -> Dictionary: return REWARD.refuse(game, ledger, "host-char"), "refuse").code, "not_participant")
	game.multi = false
	assert_true(REWARD.local_may_answer(game))
	assert_true(REWARD.begin(game, ledger, "host-char", guardian()).ok)

## Review: the peer count changes at runtime. The Veilfall view cache
## (_local_may_answer, keyed by _may_answer_key) and the host's begin/refuse
## follow every flip.
func test_view_cache_and_host_rule_follow_the_peer_count_at_runtime() -> void:
	var game := freed([])
	var ledger := LEDGER.new(game.world)
	var cave: Node = _keep(load("res://scripts/world/water_veilfall.gd").new()) as Node
	cave.set("_game", game)
	assert_true(cave.call("_local_may_answer"), "solo: the host may answer")
	var solo_key: Array = cave.call("_may_answer_key")
	game.multi = true
	assert_ne(cave.call("_may_answer_key"), solo_key, "the key sees the peer count")
	assert_false(cave.call("_local_may_answer"), "multi: the cached answer is not reused")
	assert_eq(REWARD.begin(game, ledger, "host-char", guardian()).code, "not_participant")
	assert_eq(REWARD.refuse(game, ledger, "host-char").code, "not_participant")
	game.multi = false
	assert_true(cave.call("_local_may_answer"), "solo again: the prompt returns")
	var began := REWARD.begin(game, ledger, "host-char", guardian())
	assert_true(began.ok)
	assert_false(cave.call("_local_may_answer"), "the offered marker closes the invite")
	game.multi = true
	assert_false(cave.call("_local_may_answer"))
	assert_eq(REWARD.begin(game, ledger, "host-char", guardian()).code, "replay",
		"the offered character's own pending claim replays whatever the peer count")
	game.multi = false
	assert_true(REWARD.refuse(game, ledger, "host-char").ok, "it may still refuse its own pending claim")
	assert_false(cave.call("_local_may_answer"))

## The legacy-receipt presentation rule reads the local character's flags:
## the view cache must see them change.
func test_view_cache_follows_the_local_legacy_receipt() -> void:
	var game := legacy_settled(["host-char", "B"])
	var cave: Node = _keep(load("res://scripts/world/water_veilfall.gd").new()) as Node
	cave.set("_game", game)
	assert_true(cave.call("_local_may_answer"), "a named participant of a journaled legacy world")
	game.local.flags.set_flag(REWARD.RECEIPT_PREFIX + REWARD.legacy_claim_id("slot-0"))
	assert_false(cave.call("_local_may_answer"), "holding the legacy receipt closes the invite")

# --- refusal paths leave the world unchanged ---------------------------------------

func test_refused_begin_and_refuse_leave_the_world_unchanged() -> void:
	# No identity yet: a refusal must not mint one (nor anything else).
	var game := freed(["A", "B"])
	assert_eq(game.world.reward_delivery_namespace, "")
	var ledger := LEDGER.new(game.world)
	var cases := [
		["not_participant", func() -> Dictionary: return REWARD.begin(game, ledger, "D", guardian())],
		["not_participant", func() -> Dictionary: return REWARD.refuse(game, ledger, "D")],
		["not_ready", func() -> Dictionary: return REWARD.begin(game, ledger, "A", SPECIES.spawn("water_mosshell"))],
	]
	for entry: Array in cases:
		var result: Dictionary = assert_untouched(game, ledger, entry[1], str(entry[0]))
		assert_false(result.ok)
		assert_eq(result.code, entry[0])
		assert_eq(game.world.reward_delivery_namespace, "", str(entry[0]) + ": no identity minted")
	var tethered := freed(["A"])
	tethered.world.flags.set_flag("water_guardian_freed", false)
	var tethered_ledger := LEDGER.new(tethered.world)
	assert_eq(assert_untouched(tethered, tethered_ledger,
		func() -> Dictionary: return REWARD.begin(tethered, tethered_ledger, "A", guardian()), "tethered begin").code, "tethered")
	assert_eq(assert_untouched(tethered, tethered_ledger,
		func() -> Dictionary: return REWARD.refuse(tethered, tethered_ledger, "A"), "tethered refuse").code, "tethered")
	var legacy := legacy_settled([])
	legacy.world.reward_delivery_namespace = ""
	var legacy_ledger := LEDGER.new(legacy.world)
	assert_eq(assert_untouched(legacy, legacy_ledger,
		func() -> Dictionary: return REWARD.begin(legacy, legacy_ledger, "A", guardian()), "legacy begin").code, "legacy_world")
	# The accepted path still establishes identity before minting.
	var offer := REWARD.begin(game, ledger, "A", guardian())
	assert_true(offer.ok)
	assert_false(str(game.world.reward_delivery_namespace).is_empty())
	assert_eq(offer.id, REWARD.claim_id(game.world.reward_delivery_namespace, "A"))
	# A later refusal (bad payload) still writes nothing.
	assert_eq(assert_untouched(game, ledger,
		func() -> Dictionary: return REWARD.begin(game, ledger, "B", SPECIES.spawn("water_mosshell")), "bad species").code, "not_ready")

func test_journal_failure_on_a_legacy_offer_restores_everything() -> void:
	var game := legacy_settled(["A", "B"])
	game.world.reward_delivery_namespace = ""
	var ledger := LEDGER.new(game.world)
	var before: Dictionary = game.world.save_data()
	var sequence: int = ledger.seq
	game.save_system.fail_write = true
	assert_eq(REWARD.begin(game, ledger, "B", guardian()).code, "journal_failed")
	assert_eq(REWARD.refuse(game, ledger, "B").code, "journal_failed")
	assert_eq(game.world.save_data(), before, "no marker, legacy flag, claim or identity survives")
	assert_eq(ledger.seq, sequence)
	game.save_system.fail_write = false
	assert_true(REWARD.begin(game, ledger, "B", guardian()).ok)
