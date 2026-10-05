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
	PICKUP_SPECS.register("harvest_node:oak@1", "wood", 3, 5)
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


func _mark(mark: String, seq: int) -> Dictionary:
	return ledger.call("commit", {"kind": "gather_mark", "realm": "meadows", "character_id": CHARACTER, "mark": mark, "seq": seq}, HOST)


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


func test_a_forged_harvest_amount_becomes_a_host_legal_yield() -> void:
	_harvest("harvest_node:oak@1", 99)
	assert_eq(_batch().open, {"wood": 3}, "anything but a registered yield pays the base yield")
	before_each()
	_harvest("harvest_node:oak@1", 5)
	assert_eq(_batch().open, {"wood": 5}, "the right-tool yield is legal")


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


func test_rows_prune_only_below_both_the_ack_and_the_replay() -> void:
	_pile(0)
	_flush()
	var id := str(world.reward_deliveries.keys()[0])
	world.reward_deliveries[id].status = "accepted"
	assert_true(_mark("acked", 1).get("ok"))
	assert_true(world.reward_deliveries.has(id), "the replay still needs the row after the ACK")
	assert_true(_mark("replayed", 1).get("ok"))
	assert_false(world.reward_deliveries.has(id), "acked and replayed: pruned")
	assert_false(_mark("acked", 5).get("ok"), "a mark cannot pass an unflushed seq")
	assert_true(_mark("acked", 1).get("ok"), "re-marking is idempotent")
	assert_eq(int(_batch().acked), 1)


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
