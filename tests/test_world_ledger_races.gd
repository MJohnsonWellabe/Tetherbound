extends "res://tests/test_case.gd"

## Stage B Wave 3 lane 3.A. THE RACES, deterministically.
##
## D103: first committed claim wins, the loser is refused with a reason a player
## can be shown, and a stale storage write is refused rather than silently
## overwriting somebody's deposit. This file is where that is actually PROVEN --
## the net smokes only ever prove "no duplication regardless of the order the
## packets happened to arrive in this run", which is a weaker claim and a
## flakier one.
##
## No networking, no scene tree, no `Game`. Two peers here are two integers
## calling `commit()` on one `WorldLedger` in an order this file chooses, which
## is exactly the interleaving a real race produces once the host has serialised
## it -- and the host serialising it is the whole design.

const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")

const PEER_A := 1
const PEER_B := 771_240_190
const PEER_C := 42

var world: RefCounted = null
var ledger: RefCounted = null


func before_each() -> void:
	world = WORLD_STATE.new()
	ledger = WORLD_LEDGER.new(world)


# --- two claims on one pickup --------------------------------------------------

func test_two_claims_on_one_pickup_leave_exactly_one_winner() -> void:
	var intent := {"kind": "claim_pickup", "realm": "meadows", "flag": "cache:elder_hollow",
		"item": "elixir", "count": 1}
	var first: Dictionary = ledger.call("commit", intent, PEER_A)
	var second: Dictionary = ledger.call("commit", intent, PEER_B)

	assert_true(first.get("ok"), "the first claim to reach the host commits")
	assert_false(second.get("ok"), "the second claim on the same find must not commit")
	assert_eq(str(second.get("code")), "already_taken")
	assert_false(str(second.get("reason")).is_empty(),
		"a refused claim carries a sentence the loser can be shown, not a silent drop")
	assert_true((second.get("delta") as Dictionary).get("ops", []).is_empty(),
		"a refusal commits nothing")

	# The find went to exactly one satchel: one grant op, addressed to the winner.
	assert_eq(WORLD_LEDGER.player_ops_for(first.get("delta"), PEER_A).size(), 1)
	assert_eq(WORLD_LEDGER.player_ops_for(first.get("delta"), PEER_B).size(), 0,
		"the loser is never handed the item")
	assert_true(world.flags.call("has", "cache:elder_hollow"),
		"the world remembers the find is gone")


func test_the_winner_is_whoever_committed_first_not_whoever_is_the_host() -> void:
	# The order the intents reach the ledger is the only thing that decides it.
	var intent := {"kind": "claim_pickup", "realm": "meadows", "flag": "pickup:ridge_tm",
		"item": "tm_gust", "count": 1}
	var first: Dictionary = ledger.call("commit", intent, PEER_B)
	var second: Dictionary = ledger.call("commit", intent, PEER_A)
	assert_true(first.get("ok"), "the joiner asked first, so the joiner gets it")
	assert_false(second.get("ok"), "the host asking second loses like anybody else")
	assert_eq(WORLD_LEDGER.player_ops_for(first.get("delta"), PEER_B).size(), 1)


func test_the_same_flag_in_two_realms_is_two_different_finds() -> void:
	# D97: realm is explicit on every intent, and a Cloudreach cache must not be
	# closed out by somebody taking the Meadows one.
	var meadows: Dictionary = ledger.call("commit", {"kind": "claim_pickup", "realm": "meadows",
		"flag": "cache:spring", "item": "elixir", "count": 1}, PEER_A)
	var cloudreach: Dictionary = ledger.call("commit", {"kind": "claim_pickup", "realm": "cloudreach",
		"flag": "cache:cloudreach:spring", "item": "elixir", "count": 1}, PEER_B)
	assert_true(meadows.get("ok"))
	assert_true(cloudreach.get("ok"))
	assert_eq(str((cloudreach.get("delta") as Dictionary).get("realm")), "cloudreach",
		"the delta carries the realm the intent named, never a global current realm")


func test_an_intent_with_no_realm_is_refused_rather_than_guessed_at() -> void:
	var verdict: Dictionary = ledger.call("commit", {"kind": "claim_pickup",
		"flag": "cache:elder_hollow"}, PEER_A)
	assert_false(verdict.get("ok"))
	assert_eq(str(verdict.get("code")), "malformed")


# --- a double gather -----------------------------------------------------------

func test_two_gathers_of_one_harvest_node_yield_one_lot_of_wood() -> void:
	var intent := {"kind": "harvest", "realm": "meadows", "flag": "harvest_node:order:12",
		"item": "wood", "amount": 3}
	var first: Dictionary = ledger.call("commit", intent, PEER_A)
	var second: Dictionary = ledger.call("commit", intent, PEER_B)
	assert_true(first.get("ok"))
	assert_false(second.get("ok"), "a node that is gone is gone for the second gatherer too")
	assert_eq(str(second.get("code")), "already_taken")
	assert_eq(_granted(first.get("delta"), PEER_A, "wood"), 3)
	assert_eq(_granted(second.get("delta"), PEER_B, "wood"), 0,
		"the refused gather mints nothing -- this is the duplication the whole lane exists to stop")


func test_two_peers_chopping_the_same_bush_duplicate_nothing() -> void:
	var intent := {"kind": "deplete_vegetation", "realm": "meadows", "layer": "bushes",
		"index": 417, "item": "fiber", "amount": 2}
	var first: Dictionary = ledger.call("commit", intent, PEER_A)
	var second: Dictionary = ledger.call("commit", intent, PEER_B)
	assert_true(first.get("ok"))
	assert_false(second.get("ok"))
	assert_eq(_granted(first.get("delta"), PEER_A, "fiber"), 2)
	assert_eq(_granted(second.get("delta"), PEER_B, "fiber"), 0)

	# The durable half is a world flag; the live bitset is a scene op, because
	# only `vegetation.gd` knows how long that layer's bitset is.
	assert_true(world.flags.call("has", WORLD_LEDGER.vegetation_flag("meadows", "bushes", 417)))
	var scene_ops: Array = WORLD_LEDGER.scene_ops(first.get("delta"))
	assert_eq(scene_ops.size(), 1, "one node for lane 3.B to take down, not two")
	assert_eq(int((scene_ops[0] as Dictionary).get("index")), 417)


# --- two withdrawals of one stack, and a stale revision ------------------------

func test_two_withdrawals_of_one_stack_cannot_both_commit() -> void:
	# Both peers opened the chest when it held one stack, so both quote revision
	# 0. The second write is refused: it was based on a chest that no longer
	# exists, and applying it would put the stack back for its friend to take
	# again.
	var read_revision: int = ledger.call("storage_revision", "chest:home:0")
	assert_eq(read_revision, 0, "a chest nobody has written this session reads as revision 0")
	var take := {"kind": "storage_txn", "realm": "meadows", "container": "chest:home:0",
		"index": -1, "expected_revision": read_revision, "state": []}

	var first: Dictionary = ledger.call("commit", take, PEER_A)
	var second: Dictionary = ledger.call("commit", take, PEER_B)
	assert_true(first.get("ok"))
	assert_false(second.get("ok"), "the loser's withdrawal is refused, not applied over the winner's")
	assert_eq(str(second.get("code")), "stale_revision")
	assert_false(str(second.get("reason")).is_empty(),
		"the loser is told to look again rather than silently losing their click")
	assert_eq(int(ledger.call("storage_revision", "chest:home:0")), 1,
		"exactly one write moved the revision")


func test_a_storage_write_against_a_revision_two_behind_is_refused() -> void:
	var container := "chest:camp:2"
	for i in 2:
		var ok: Dictionary = ledger.call("commit", {"kind": "storage_txn", "realm": "meadows",
			"container": container, "index": -1,
			"expected_revision": ledger.call("storage_revision", container), "state": []}, PEER_A)
		assert_true(ok.get("ok"))
	var stale: Dictionary = ledger.call("commit", {"kind": "storage_txn", "realm": "meadows",
		"container": container, "index": -1, "expected_revision": 0, "state": []}, PEER_B)
	assert_false(stale.get("ok"))
	assert_eq(str(stale.get("code")), "stale_revision")
	assert_eq(int(ledger.call("storage_revision", container)), 2, "a refused write moves nothing")


func test_a_storage_write_that_quotes_the_current_revision_lands_in_the_record() -> void:
	world.call("register_building", "storage_chest", Vector3.ZERO, 0.0, true, "meadows")
	var verdict: Dictionary = ledger.call("commit", {"kind": "storage_txn", "realm": "meadows",
		"container": "chest:home:0", "index": 0, "expected_revision": 0,
		"state": [{"id": "wood", "n": 4}]}, PEER_A)
	assert_true(verdict.get("ok"))
	var record: Dictionary = world.placed_buildings[0]
	assert_eq((record.get("state") as Array).size(), 1,
		"apply_delta wrote the chest's contents into the record a save persists")


# --- grant_player_flag reaching two peers ---------------------------------------

func test_a_player_flag_granted_to_two_peers_reaches_both_and_only_them() -> void:
	# D99: a home flag is per-player state granted to everyone in the session.
	# One commit, one delta, and each peer filters the ops addressed to it --
	# through the same static filter `ledger_rpc.gd` uses, so this is a claim
	# about shipping behaviour rather than about the test's own arithmetic.
	var verdict: Dictionary = ledger.call("commit", {"kind": "grant_player_flag",
		"realm": "meadows", "id": "home_materials_gathered", "peers": [PEER_A, PEER_B]}, PEER_A)
	assert_true(verdict.get("ok"))
	var delta: Dictionary = verdict.get("delta")

	for peer: int in [PEER_A, PEER_B]:
		var ops: Array = WORLD_LEDGER.player_ops_for(delta, peer)
		assert_eq(ops.size(), 1, "peer %d is addressed exactly once" % peer)
		assert_eq(str((ops[0] as Dictionary).get("id")), "home_materials_gathered")
	assert_eq(WORLD_LEDGER.player_ops_for(delta, PEER_C).size(), 0,
		"a peer who was not named gets nothing")
	assert_eq(world.call("apply_delta", delta), 0,
		"a per-player flag is not a world fact and never touches WorldState")


func test_a_reward_pays_each_participant_once_and_refuses_a_replay() -> void:
	# D106: a shared victory pays everyone who was there, once each.
	var intent := {"kind": "reward_grant", "realm": "meadows", "source": "warden",
		"peers": [PEER_A, PEER_B], "item": "sigil_shard", "count": 1}
	var first: Dictionary = ledger.call("commit", intent, PEER_A)
	assert_true(first.get("ok"))
	assert_eq((first.get("paid") as Array).size(), 2)
	assert_eq(_granted(first.get("delta"), PEER_A, "sigil_shard"), 1)
	assert_eq(_granted(first.get("delta"), PEER_B, "sigil_shard"), 1)

	var replay: Dictionary = ledger.call("commit", intent, PEER_B)
	assert_false(replay.get("ok"), "the same victory reported twice pays nobody twice")
	assert_eq(str(replay.get("code")), "already_taken")

	var latecomer: Dictionary = ledger.call("commit", {"kind": "reward_grant", "realm": "meadows",
		"source": "warden", "peers": [PEER_A, PEER_C], "item": "sigil_shard", "count": 1}, PEER_C)
	assert_true(latecomer.get("ok"), "a participant who has not been paid still is")
	assert_eq((latecomer.get("paid") as Array), [PEER_C])


# --- a replayed trade or drop ----------------------------------------------------

func test_a_replayed_transfer_moves_the_stack_exactly_once() -> void:
	var intent := {"kind": "transfer_item", "realm": "meadows", "txn_id": "trade-9",
		"from": PEER_A, "to": PEER_B, "item": "wood", "count": 5}
	var first: Dictionary = ledger.call("commit", intent, PEER_A)
	var replay: Dictionary = ledger.call("commit", intent, PEER_A)
	assert_true(first.get("ok"))
	assert_false(replay.get("ok"), "a retried trade must not mint a second stack")
	assert_eq(str(replay.get("code")), "duplicate")
	assert_eq(_granted(first.get("delta"), PEER_B, "wood"), 5)
	assert_eq(_taken(first.get("delta"), PEER_A, "wood"), 5,
		"what one satchel gains the other loses, in the same delta")


func test_a_replayed_drop_leaves_one_stack_on_the_ground() -> void:
	var intent := {"kind": "drop_item", "realm": "meadows", "txn_id": "drop-3",
		"item": "stone", "count": 2, "position": Vector3(4.0, 0.0, -2.0)}
	var first: Dictionary = ledger.call("commit", intent, PEER_A)
	var replay: Dictionary = ledger.call("commit", intent, PEER_A)
	assert_true(first.get("ok"))
	assert_false(replay.get("ok"))
	assert_eq(WORLD_LEDGER.scene_ops(first.get("delta")).size(), 1)
	assert_eq(WORLD_LEDGER.scene_ops(replay.get("delta")).size(), 0)


# --- buildings -------------------------------------------------------------------

func test_a_placement_and_a_dismantle_go_through_the_ledger_into_the_world() -> void:
	var placed: Dictionary = ledger.call("commit", {"kind": "place_building", "realm": "meadows",
		"id": "fence", "position": Vector3(1.0, 2.0, 3.0), "yaw_deg": 90.0}, PEER_A)
	assert_true(placed.get("ok"))
	assert_eq(world.placed_buildings.size(), 1)
	var record: Dictionary = world.placed_buildings[0]
	assert_eq(record.get("position"), [1.0, 2.0, 3.0],
		"the record is built by register_building(), so it cannot drift from a solo placement")
	assert_eq(str(record.get("realm")), "meadows")

	var gone: Dictionary = ledger.call("commit", {"kind": "dismantle", "realm": "meadows",
		"index": 0}, PEER_B)
	assert_true(gone.get("ok"))
	assert_true(world.placed_buildings.is_empty())

	var again: Dictionary = ledger.call("commit", {"kind": "dismantle", "realm": "meadows",
		"index": 0}, PEER_A)
	assert_false(again.get("ok"), "two peers swinging at one fence dismantle it once")
	assert_eq(str(again.get("code")), "gone")


func test_a_dismantle_pointed_at_another_realms_record_is_refused() -> void:
	world.call("register_building", "fence", Vector3.ZERO, 0.0, true, "cloudreach")
	var verdict: Dictionary = ledger.call("commit", {"kind": "dismantle", "realm": "meadows",
		"index": 0}, PEER_A)
	assert_false(verdict.get("ok"), "index 0 means a different thing in each realm")
	assert_eq(world.placed_buildings.size(), 1)


# --- the apply path itself --------------------------------------------------------

func test_a_client_replaying_the_hosts_deltas_ends_up_with_the_hosts_world() -> void:
	# The client's ledger never commits: it only applies what the host committed,
	# through the one `WorldState.apply_delta()` entry point.
	var client_world: RefCounted = WORLD_STATE.new()
	var client: RefCounted = WORLD_LEDGER.new(client_world)

	var deltas: Array = []
	deltas.append((ledger.call("commit", {"kind": "claim_pickup", "realm": "meadows",
		"flag": "cache:elder_hollow", "item": "elixir", "count": 1}, PEER_A) as Dictionary).get("delta"))
	deltas.append((ledger.call("commit", {"kind": "place_building", "realm": "meadows",
		"id": "fence", "position": [5.0, 0.0, 5.0]}, PEER_B) as Dictionary).get("delta"))
	deltas.append((ledger.call("commit", {"kind": "set_world_flag", "realm": "meadows",
		"id": "bridge_unlocked"}, PEER_A) as Dictionary).get("delta"))
	for delta: Variant in deltas:
		client.call("apply", delta)

	assert_true(client_world.flags.call("has", "cache:elder_hollow"))
	assert_true(client_world.flags.call("has", "bridge_unlocked"))
	assert_eq(client_world.placed_buildings.size(), 1)
	assert_eq(client_world.save_data().get("placed_buildings"),
		world.save_data().get("placed_buildings"),
		"replaying the deltas reproduces the host's world, which is what a desync check compares")


func test_apply_delta_ignores_an_op_it_does_not_understand_rather_than_dying() -> void:
	var applied: int = world.call("apply_delta", {"seq": 1, "realm": "meadows", "ops": [
		{"op": "from_a_newer_build", "scope": "world"},
		"not even a dictionary",
		{"op": "flag", "scope": "world", "id": "bridge_unlocked"},
	]})
	assert_eq(applied, 1, "one op it understood; the rest cost themselves, not the world")
	assert_true(world.flags.call("has", "bridge_unlocked"))


func test_setting_a_world_flag_that_is_already_set_is_a_noop_not_a_refusal() -> void:
	var intent := {"kind": "set_world_flag", "realm": "meadows", "id": "bridge_unlocked"}
	assert_true((ledger.call("commit", intent, PEER_A) as Dictionary).get("ok"))
	var again: Dictionary = ledger.call("commit", intent, PEER_B)
	assert_true(again.get("ok"), "a story trigger firing twice is harmless, not an error to show")
	assert_eq(str(again.get("code")), "noop")


func test_an_unknown_intent_is_refused_with_a_reason() -> void:
	var verdict: Dictionary = ledger.call("commit", {"kind": "eat_the_sun", "realm": "meadows"}, PEER_A)
	assert_false(verdict.get("ok"))
	assert_eq(str(verdict.get("code")), "unknown_intent")
	assert_false(str(verdict.get("reason")).is_empty())


# --- helpers -----------------------------------------------------------------------

func _granted(delta: Variant, peer_id: int, item: String) -> int:
	return _moved(delta, peer_id, item, "item_grant")


func _taken(delta: Variant, peer_id: int, item: String) -> int:
	return _moved(delta, peer_id, item, "item_take")


func _moved(delta: Variant, peer_id: int, item: String, op_name: String) -> int:
	var total := 0
	for raw: Variant in WORLD_LEDGER.player_ops_for(delta as Dictionary, peer_id):
		var op := raw as Dictionary
		if str(op.get("op", "")) == op_name and str(op.get("item", "")) == item:
			total += int(op.get("count", 0))
	return total
