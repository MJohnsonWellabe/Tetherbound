extends "res://tests/test_case.gd"

## Coordinator ruling (b): a guest's frequent gathers (felled piles, harvest
## nodes, Stormwood sites) pay into the host's character authority through one
## reward delivery per batch, compacted by per-character acked/replayed marks.
## The host and solo keep their immediate grant.

const ITEM_DB := preload("res://autoload/item_db.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const GATHER := preload("res://scripts/net/gather_batches.gd")
const PICKUP_SPECS := preload("res://scripts/net/pickup_spec_registry.gd")
const REDESIGN_STATE := preload("res://scripts/data/redesign_state.gd")

const HOST := WORLD_LEDGER.HOST_PEER
const GUEST := 771_240_190
const CHARACTER := "character-0123456789abcdef0123456789abcdef"

var world: RefCounted = null
var ledger: RefCounted = null


func before_each() -> void:
	world = WORLD_STATE.new()
	world.world_id = "slot-0"
	world.reward_delivery_namespace = "0123456789abcdef0123456789abcdef"
	ledger = WORLD_LEDGER.new(world)
	PICKUP_SPECS.clear()
	PICKUP_SPECS.register("harvest_node:oak@1", "wood", 3)
	for i in 12:
		PICKUP_SPECS.register("felled:meadows:pile%d" % i, "wood", 2)


func after_each() -> void:
	PICKUP_SPECS.clear()


func _harvest(flag: String, amount: int, peer: int = GUEST) -> Dictionary:
	return ledger.call("commit", {"kind": "harvest", "realm": "meadows", "flag": flag, "item": "wood",
		"amount": amount, "_actor_character_id": CHARACTER if peer != HOST else "character-host"}, peer)


func _pile(i: int) -> Dictionary:
	return ledger.call("commit", {"kind": "claim_pickup", "realm": "meadows", "flag": "felled:meadows:pile%d" % i,
		"item": "wood", "count": 2, "_actor_character_id": CHARACTER}, GUEST)


func _flush(target: int = GUEST) -> Dictionary:
	return ledger.call("commit", {"kind": "gather_flush", "realm": "meadows", "character_id": CHARACTER, "target_peer": target}, HOST)


func _replayed(seq: int) -> Dictionary:
	return ledger.call("commit", {"kind": "gather_replayed", "realm": "meadows", "character_id": CHARACTER, "seq": seq}, HOST)


func _accept(seq: int) -> Dictionary:
	var id := GATHER.row_id(world.reward_deliveries, CHARACTER, seq)
	return ledger.call("accept_reward_delivery", id, CHARACTER, GUEST)


func _batch() -> Dictionary:
	return GATHER.batch(world.redesign_world, CHARACTER)


func _player() -> RefCounted:
	var player: RefCounted = PLAYER_STATE.new()
	player.call("configure", ITEM_DB.new())
	player.set("character_id", CHARACTER)
	return player


func test_a_guest_harvest_accrues_into_its_batch_and_grants_nothing_yet() -> void:
	var verdict := _harvest("harvest_node:oak@1", 3)
	assert_true(verdict.get("ok"), str(verdict))
	assert_true(WORLD_LEDGER.player_ops_for(verdict.delta, GUEST).is_empty(), "no satchel op at the hit")
	assert_true(world.flags.call("has", "harvest_node:oak@1"), "the node is gone for everyone")
	assert_eq(_batch().open, {"wood": 3})
	assert_eq(int(_batch().hits), 1)
	assert_true(world.reward_deliveries.is_empty(), "no per-hit delivery row")


func test_the_host_and_solo_keep_the_immediate_grant() -> void:
	var verdict := _harvest("harvest_node:oak@1", 3, HOST)
	assert_eq(str(WORLD_LEDGER.player_ops_for(verdict.delta, HOST)[0].op), "item_grant")
	assert_eq(_batch().hits, 0)


func test_a_forged_harvest_amount_becomes_the_host_yield() -> void:
	_harvest("harvest_node:oak@1", 99)
	assert_eq(_batch().open, {"wood": 3}, "an ungated node pays its base yield, never the request's amount")


func test_felled_piles_accrue_instead_of_one_delivery_per_pile() -> void:
	for i in 5: assert_true(_pile(i).get("ok"))
	assert_eq(_batch().open, {"wood": 10})
	assert_eq(int(_batch().hits), 5)
	assert_true(world.reward_deliveries.is_empty(), "five piles, zero delivery rows until the flush")


func test_one_flush_journals_one_delivery_for_the_whole_batch() -> void:
	for i in 4: _pile(i)
	_harvest("harvest_node:oak@1", 3)
	var verdict := _flush()
	assert_true(verdict.get("ok"), str(verdict))
	assert_eq(world.reward_deliveries.size(), 1, "one row for five gathers")
	var ops := WORLD_LEDGER.player_ops_for(verdict.delta, GUEST)
	assert_eq(str(ops[0].op), "reward_delivery")
	assert_eq(str(ops[0].delivery.source), "gather_batch:1")
	assert_eq(ops[0].delivery.stacks, [{"id": "wood", "n": 11}])
	assert_eq(int(_batch().next_seq), 2)
	assert_true(_batch().open.is_empty())
	assert_false(_flush().get("ok"), "an empty batch flushes nothing")


func test_a_row_prunes_only_once_it_is_both_accepted_and_replayed() -> void:
	_pile(0)
	_flush()
	var id := GATHER.row_id(world.reward_deliveries, CHARACTER, 1)
	assert_true(_accept(1).get("ok"))
	assert_true(world.reward_deliveries.has(id), "the replay still needs the row after the ACK")
	assert_true(_replayed(1).get("ok"))
	assert_false(world.reward_deliveries.has(id), "accepted and replayed: pruned")
	assert_true(_batch().replayed.is_empty(), "nothing left to wait for")
	_pile(1)
	_flush()
	var id2 := GATHER.row_id(world.reward_deliveries, CHARACTER, 2)
	assert_true(_replayed(2).get("ok"), "the replay can land before the ACK")
	assert_true(world.reward_deliveries.has(id2))
	assert_true(_accept(2).get("ok"))
	assert_false(world.reward_deliveries.has(id2), "and the ACK then prunes it")
	assert_false(_replayed(9).get("ok"), "an unflushed seq cannot be marked")


func test_an_unsettled_earlier_batch_is_never_swept_by_a_later_one() -> void:
	# Review B1: batch 1 waits in a full bag (not settled, so never replayed)
	# while batch 2 is accepted and replayed.
	_pile(0)
	_flush()
	_pile(1)
	_flush()
	var first := GATHER.row_id(world.reward_deliveries, CHARACTER, 1)
	assert_true(_accept(1).get("ok"), "the guest ACKs batch 1 although it is still grant_due")
	assert_true(_accept(2).get("ok"))
	assert_true(_replayed(2).get("ok"))
	assert_true(world.reward_deliveries.has(first), "batch 1 survives until its own replay")
	assert_true(_replayed(1).get("ok"), "so the later replay still finds its row")
	assert_false(world.reward_deliveries.has(first))


func test_the_guest_prunes_escrow_only_for_this_worlds_gone_rows() -> void:
	# Review B2.
	var ns := str(world.reward_delivery_namespace)
	var escrow := {
		"gone_here": {"status": "settled", "character_id": CHARACTER, "source": "gather_batch:1", "world_namespace": ns},
		"pending_here": {"status": "settled", "character_id": CHARACTER, "source": "gather_batch:2", "world_namespace": ns},
		"other_world": {"status": "settled", "character_id": CHARACTER, "source": "gather_batch:1", "world_namespace": "ffffffffffffffffffffffffffffffff"},
		"due_here": {"status": "grant_due", "character_id": CHARACTER, "source": "gather_batch:3", "world_namespace": ns},
		"not_a_batch": {"status": "settled", "character_id": CHARACTER, "source": "trainer:warden:coin", "world_namespace": ns}}
	var host_rows := {"pending_here": {"status": "pending"}}
	assert_eq(GATHER.guest_prunable(escrow, host_rows, ns, CHARACTER), ["gone_here"],
		"only a settled batch row from this world whose host row is gone")


func test_a_corrupt_batch_row_refuses_gathers_instead_of_resetting() -> void:
	world.redesign_world[GATHER.FIELD] = {CHARACTER: {"next_seq": 0, "hits": 0, "open": {}, "replayed": []}}
	var verdict := _pile(0)
	assert_false(verdict.get("ok"), "a corrupt carrier never restarts at seq 1 (delivery id reuse)")


func test_a_batch_cannot_grow_past_one_delivery() -> void:
	# Review S4: when the flush keeps failing, gathers are refused (not taken
	# and left unpaid) once the batch is far past its flush size.
	var refused := false
	for i in 12:
		if not _pile(i).get("ok"): refused = true
	for i in 40:
		PICKUP_SPECS.register("harvest_node:extra%d" % i, "wood", 3)
		if not _harvest("harvest_node:extra%d" % i, 3).get("ok"): refused = true
	assert_true(refused, "the open batch stops accepting before it becomes unflushable")
	assert_true(int(_batch().hits) <= GATHER.max_hits() * 4)
	assert_false(GATHER.flush_delivery(_batch(), world.world_id, world.reward_delivery_namespace, CHARACTER).is_empty(),
		"and it still flushes as one delivery")


func test_a_tool_gated_harvest_needs_the_tool_in_the_admitted_record() -> void:
	# Review S5.
	PICKUP_SPECS.register("harvest_node:rock@1", "stone", 1, 3, "pickaxe")
	var bare: Dictionary = ledger.call("commit", {"kind": "harvest", "realm": "meadows", "flag": "harvest_node:rock@1",
		"item": "stone", "amount": 3, "_actor_character_id": CHARACTER, "_actor_item_ids": ["wood"]}, GUEST)
	assert_false(bare.get("ok"), "no pickaxe in the admitted record: refused")
	assert_eq(str(bare.get("code")), "tool_required")
	var tooled: Dictionary = ledger.call("commit", {"kind": "harvest", "realm": "meadows", "flag": "harvest_node:rock@1",
		"item": "stone", "amount": 99, "_actor_character_id": CHARACTER, "_actor_item_ids": ["pickaxe"]}, GUEST)
	assert_true(tooled.get("ok"))
	assert_eq(_batch().open, {"stone": 3}, "the right-tool yield, never the request's amount")


func test_a_reconnect_mid_batch_delivers_exactly_once() -> void:
	for i in 3: _pile(i)
	# The guest drops before the flush: the departure flush addresses nobody.
	var verdict := _flush(0)
	assert_true(verdict.get("ok"), "departure flush: %s" % str(verdict))
	assert_true(WORLD_LEDGER.player_ops_for(verdict.delta, GUEST).is_empty())
	var pending := REWARD_DELIVERY.pending_for_character(world, CHARACTER)
	assert_eq(pending.size(), 1, "the row waits for the rejoin's reconciliation")
	var player := _player()
	var first := REWARD_DELIVERY.apply(player, pending[0])
	var again := REWARD_DELIVERY.apply(player, pending[0])
	assert_true(first.get("settled"), "first application: %s" % str(first))
	assert_false(again.get("changed"), "a resent delivery changes nothing")
	assert_eq(int(player.get("inventory").call("count", "wood")), 6, "exactly the three piles, once")
	# The same piles cannot be claimed again, and the batch reopens empty.
	assert_false(_pile(0).get("ok"))
	assert_true(_batch().open.is_empty())


func test_a_v28_world_without_the_field_loads_and_a_mid_batch_save_survives_reload() -> void:
	var legacy: Dictionary = world.save_data()
	var redesign: Dictionary = legacy.redesign_world.duplicate(true)
	redesign.erase(GATHER.FIELD)
	legacy.redesign_world = redesign
	assert_true(REDESIGN_STATE.validate("world", redesign, [], world.reward_delivery_namespace).is_empty(),
		"a v28 world without gather_batches validates")
	var loaded: RefCounted = WORLD_STATE.new()
	loaded.load_data(legacy)
	assert_eq(GATHER.batch(loaded.redesign_world, CHARACTER), GATHER.empty_batch(), "and reads as no open batch")
	for i in 2: _pile(i)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(world.save_data()))
	assert_true(REDESIGN_STATE.validate("world", saved.redesign_world, [], world.reward_delivery_namespace).is_empty(),
		"a mid-batch world validates")
	var reloaded: RefCounted = WORLD_STATE.new()
	reloaded.load_data(saved)
	assert_eq(GATHER.batch(reloaded.redesign_world, CHARACTER).open, {"wood": 4}, "the open batch survives a reload")
	assert_eq(int(GATHER.batch(reloaded.redesign_world, CHARACTER).hits), 2)


func test_the_tunables_live_in_config() -> void:
	assert_eq(GATHER.max_hits(), 8)
	assert_almost_eq(GATHER.flush_seconds(), 1.5, 0.001)
