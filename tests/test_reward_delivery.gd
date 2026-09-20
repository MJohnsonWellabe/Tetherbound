extends "res://tests/test_case.gd"

const ITEM_DB := preload("res://autoload/item_db.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const REWARD_DELIVERY := preload("res://scripts/net/reward_delivery.gd")
const SATCHEL_ESCROW := preload("res://scripts/net/satchel_escrow.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")

const WORLD_ID := "reward-world"
const WORLD_NAMESPACE := "0123456789abcdef0123456789abcdef"
const CHARACTER_ID := "reward-character"


func _player() -> RefCounted:
	var player: RefCounted = PLAYER_STATE.new()
	player.call("configure", ITEM_DB.new())
	player.set("character_id", CHARACTER_ID)
	return player


func test_delivery_identity_is_stable_and_character_scoped() -> void:
	var first := REWARD_DELIVERY.delivery_id(WORLD_NAMESPACE, "trainer:warden:item:coin", CHARACTER_ID)
	assert_eq(first, REWARD_DELIVERY.delivery_id(WORLD_NAMESPACE, "trainer:warden:item:coin", CHARACTER_ID))
	assert_ne(first, REWARD_DELIVERY.delivery_id(WORLD_NAMESPACE, "trainer:warden:item:coin", "other"))
	assert_ne(first, REWARD_DELIVERY.delivery_id("fedcba9876543210fedcba9876543210",
		"trainer:warden:item:coin", CHARACTER_ID))


func test_full_bag_keeps_reward_pending_then_settles_exactly_once() -> void:
	var player := _player()
	var inventory: RefCounted = player.get("inventory")
	var maximum: int = ITEM_DB.new().call("stack_size", "wood")
	for i in inventory.call("slot_count"):
		inventory.call("set_slot", i, {"id": "wood", "n": maximum})
	var delivery := REWARD_DELIVERY.make_record(WORLD_ID, WORLD_NAMESPACE, "trainer:warden:item:coin",
		CHARACTER_ID, "coin", 3, "tam_tools_given")
	var pending: Dictionary = REWARD_DELIVERY.apply(player, delivery)
	assert_true(bool(pending.get("ok")))
	assert_false(bool(pending.get("settled")))
	assert_eq(str((player.satchel_escrow[delivery.delivery_id] as Dictionary).status), "grant_due")
	assert_eq(int(inventory.call("count", "coin")), 0)
	assert_false(bool(player.flags.call("has", "tam_tools_given")),
		"the personal completion flag waits for the items")

	inventory.call("set_slot", 0, null)
	var settled: Dictionary = REWARD_DELIVERY.apply(player, delivery)
	assert_true(bool(settled.get("settled")))
	assert_eq(int(inventory.call("count", "coin")), 3)
	assert_true(bool(player.flags.call("has", "tam_tools_given")))
	REWARD_DELIVERY.apply(player, delivery)
	assert_eq(int(inventory.call("count", "coin")), 3, "a replay cannot grant twice")


func test_death_satchel_reconciliation_skips_reward_rows() -> void:
	var player := _player()
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", WORLD_ID)
	var delivery := REWARD_DELIVERY.make_record(WORLD_ID, WORLD_NAMESPACE, "source", CHARACTER_ID, "coin", 1)
	REWARD_DELIVERY.apply(player, delivery)
	var before: Dictionary = player.satchel_escrow.duplicate(true)
	assert_false(SATCHEL_ESCROW.reconcile(player, world))
	assert_eq(player.satchel_escrow, before)


func test_ledger_journals_stable_deliveries_and_replay_adds_nothing() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", WORLD_ID)
	var ledger: RefCounted = WORLD_LEDGER.new(world)
	var intent := {"kind": "reward_grant", "realm": "meadows", "source": "source",
		"item": "coin", "count": 2, "peers": [7],
		"_reward_recipients": [{"peer": 7, "character_id": CHARACTER_ID}]}
	var first: Dictionary = ledger.call("commit", intent, 7)
	assert_true(bool(first.get("ok")))
	assert_eq(world.reward_deliveries.size(), 1)
	assert_false(str(world.reward_delivery_namespace).is_empty())
	var ops: Array = WORLD_LEDGER.player_ops_for(first.delta, 7)
	assert_eq(ops.size(), 1)
	assert_eq(str((ops[0] as Dictionary).get("op", "")), "reward_delivery")
	var replay: Dictionary = ledger.call("commit", intent, 7)
	assert_false(bool(replay.get("ok")))
	assert_eq(str(replay.get("code", "")), "already_taken")
	assert_eq(world.reward_deliveries.size(), 1)


func test_two_hosts_using_slot_zero_get_distinct_delivery_identities() -> void:
	var ids: Array = []
	for _host in 2:
		var world: RefCounted = WORLD_STATE.new()
		world.set("world_id", "slot-0")
		var ledger: RefCounted = WORLD_LEDGER.new(world)
		var verdict: Dictionary = ledger.call("commit", {"kind": "reward_grant",
			"realm": "meadows", "source": "same-source", "item": "coin", "count": 1,
			"_reward_recipients": [{"peer": 1, "character_id": CHARACTER_ID}]}, 1)
		assert_true(bool(verdict.get("ok")))
		ids.append(world.reward_deliveries.keys()[0])
	assert_ne(ids[0], ids[1], "slot names are file locators, not world identity")


func test_world_snapshot_round_trips_namespace_and_pending_journal() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", WORLD_ID)
	var ledger: RefCounted = WORLD_LEDGER.new(world)
	assert_true(bool((ledger.call("commit", {"kind": "reward_grant", "realm": "meadows",
		"source": "roundtrip", "item": "coin", "count": 1,
		"_reward_recipients": [{"peer": 1, "character_id": CHARACTER_ID}]}, 1) as Dictionary).get("ok")))
	var restored: RefCounted = WORLD_STATE.new()
	restored.call("load_data", world.call("save_data"))
	assert_eq(str(restored.reward_delivery_namespace), str(world.reward_delivery_namespace))
	assert_eq(restored.reward_deliveries, world.reward_deliveries)


func test_reward_delta_replay_applies_the_same_namespace_and_journal() -> void:
	var host: RefCounted = WORLD_STATE.new()
	host.set("world_id", WORLD_ID)
	var ledger: RefCounted = WORLD_LEDGER.new(host)
	var verdict: Dictionary = ledger.call("commit", {"kind": "reward_grant", "realm": "meadows",
		"source": "delta-replay", "item": "coin", "count": 1,
		"_reward_recipients": [{"peer": 1, "character_id": CHARACTER_ID}]}, 1)
	var replica: RefCounted = WORLD_STATE.new()
	replica.set("world_id", WORLD_ID)
	replica.call("apply_delta", verdict.delta)
	assert_eq(str(replica.reward_delivery_namespace), str(host.reward_delivery_namespace))
	assert_eq(replica.reward_deliveries, host.reward_deliveries)


func test_accepted_delta_keeps_recipient_and_observer_worlds_equal_to_host() -> void:
	var host: RefCounted = WORLD_STATE.new()
	host.world_id = WORLD_ID
	var ledger: RefCounted = WORLD_LEDGER.new(host)
	var journal: Dictionary = ledger.commit({"kind": "reward_grant", "realm": "meadows",
		"source": "accepted-replay", "item": "coin", "count": 1,
		"_reward_recipients": [{"peer": 2, "character_id": CHARACTER_ID}]}, 2)
	var recipient: RefCounted = WORLD_STATE.new()
	var observer: RefCounted = WORLD_STATE.new()
	for replica: RefCounted in [recipient, observer]:
		replica.world_id = WORLD_ID
		replica.apply_delta(journal.delta)
	var delivery_id := str(host.reward_deliveries.keys()[0])
	var accepted: Dictionary = ledger.call("accept_reward_delivery", delivery_id, CHARACTER_ID, 2)
	assert_true(bool(accepted.get("ok")))
	for replica: RefCounted in [recipient, observer]:
		replica.apply_delta(accepted.delta)
		assert_eq(replica.save_data(), host.save_data())
		assert_eq(int(replica.revision), int(host.revision))
	var replay: Dictionary = ledger.call("accept_reward_delivery", delivery_id, CHARACTER_ID, 2)
	assert_true(bool(replay.get("ok")))
	assert_eq(str(replay.get("code", "")), "noop")
	assert_true((replay.delta.ops as Array).is_empty())


func test_only_the_source_with_a_legacy_peer_receipt_is_unresolved() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", WORLD_ID)
	world.flags.call("set_flag", "reward:old-source:77", true)
	var ledger: RefCounted = WORLD_LEDGER.new(world)
	var old_intent := {"kind": "reward_grant", "realm": "meadows", "source": "old-source",
		"item": "coin", "count": 1,
		"_reward_recipients": [{"peer": 1, "character_id": CHARACTER_ID}]}
	var refused: Dictionary = ledger.call("commit", old_intent, 1)
	assert_eq(str(refused.get("code", "")), "legacy_unresolved")
	var fresh := old_intent.duplicate(true)
	fresh["source"] = "fresh-source"
	assert_true(bool((ledger.call("commit", fresh, 1) as Dictionary).get("ok")),
		"a legacy receipt for one source cannot block new authored rewards")


func test_legacy_receipt_matching_requires_the_exact_source_and_numeric_peer() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", WORLD_ID)
	world.flags.call("set_flag", "reward:trainer:warden:item:coin:77", true)
	var ledger: RefCounted = WORLD_LEDGER.new(world)
	var intent := {"kind": "reward_grant", "realm": "meadows",
		"source": "trainer:warden", "item": "coin", "count": 1,
		"_reward_recipients": [{"peer": 1, "character_id": CHARACTER_ID}]}
	assert_true(bool((ledger.call("commit", intent, 1) as Dictionary).get("ok")),
		"a longer colon-containing source is not a receipt for its prefix")


func test_nonpositive_item_count_is_malformed_and_journals_nothing() -> void:
	var world: RefCounted = WORLD_STATE.new()
	world.set("world_id", WORLD_ID)
	var ledger: RefCounted = WORLD_LEDGER.new(world)
	var verdict: Dictionary = ledger.call("commit", {"kind": "reward_grant", "realm": "meadows",
		"source": "bad-count", "item": "coin", "count": 0,
		"_reward_recipients": [{"peer": 1, "character_id": CHARACTER_ID}]}, 1)
	assert_false(bool(verdict.get("ok")))
	assert_eq(str(verdict.get("code", "")), "malformed")
	assert_true(world.reward_deliveries.is_empty())
	assert_eq(str(world.reward_delivery_namespace), "")
