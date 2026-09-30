extends "res://tests/test_case.gd"

const ITEMS := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const ESCROW := preload("res://scripts/net/satchel_escrow.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const TRADE := preload("res://scripts/trade/trade_db.gd")
const OFFERS := preload("res://scripts/ui/trade_offer.gd")


func test_real_bound_item_retains_slot_through_drop_sell_trade_and_death() -> void:
	var db: RefCounted = ITEMS.new()
	var bag: RefCounted = INVENTORY.new(db)
	bag.add("home_key", 1)
	bag.add("wood", 4)
	assert_true(db.is_character_bound("home_key"))
	for key: String in ["tidewake_portal_key", "cloudreach_portal_key", "stormwood_portal_key", "fifth_portal_key"]:
		assert_true(db.is_character_bound(key), "WORLD §2.7 protects each personal portal key")
	assert_eq(bag.drop_slot(0), {})
	assert_eq(bag.count("home_key"), 1)
	assert_eq(TRADE.new().sell(bag, "mira", "home_key", 1), TRADE.REFUSED_NOT_BOUGHT)
	var offers: Node = OFFERS.new()
	assert_false(offers.offer(2, "home_key", 1).ok, "sender rejects the key before any network submission")
	assert_true(offers._outgoing.is_empty())
	offers.free()
	assert_eq(bag.drain(), [{"id": "wood", "n": 4}])
	assert_eq(bag.count("home_key"), 1)
	assert_eq(bag.count("wood"), 0)


func test_death_escrow_excludes_key_and_server_rejects_forged_key_operations() -> void:
	var world: RefCounted = WORLD.new()
	world.world_id = "key-world"
	world.reward_delivery_namespace = "key-world-instance"
	var player: RefCounted = PLAYER.new()
	player.configure(ITEMS.new())
	player.character_id = "key-owner"
	player.inventory.add("home_key", 1)
	assert_eq(ESCROW.begin_drop(player, world, Vector3.ZERO, "meadows", true), "")
	assert_true(player.satchel_escrow.is_empty())
	player.inventory.add("wood", 4)
	var txn: String = ESCROW.begin_drop(player, world, Vector3.ZERO, "meadows", true)
	assert_false(txn.is_empty())
	assert_eq(player.inventory.count("home_key"), 1)
	assert_eq(player.inventory.count("wood"), 0)
	assert_true(ESCROW.RULES.valid_death_slots(player.satchel_escrow[txn].stacks))
	var restored: RefCounted = PLAYER.new()
	restored.configure(ITEMS.new())
	restored.load_data(JSON.parse_string(JSON.stringify(player.save_data())))
	assert_eq(restored.inventory.count("home_key"), 1)
	var ledger: RefCounted = LEDGER.new(world)
	var before: Dictionary = world.save_data().duplicate(true)
	for kind: String in ["drop_item", "transfer_item"]:
		var result: Dictionary = ledger.commit({"kind": kind, "realm": "meadows", "item": "home_key", "count": 1,
			"txn_id": "forged-" + kind, "from": 2, "to": 3}, 2)
		assert_false(result.ok)
		assert_eq(result.code, "character_bound")
		assert_eq(world.save_data(), before)
	var forged: Dictionary = player.satchel_escrow[txn].intent.duplicate(true)
	forged.state = [{"id": "home_key", "n": 1}]
	forged._satchel_actor = {"peer": 2, "character_id": player.character_id, "realm": "meadows", "position": Vector3.ZERO}
	assert_false(ledger.commit(forged, 2).ok)
	assert_eq(world.save_data(), before)
	assert_eq(ESCROW.begin_transfer(player, world, "absent", "deposit", "home_key", 1, 0, true), "")
