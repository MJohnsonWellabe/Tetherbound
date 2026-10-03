extends "res://tests/test_case.gd"

const PLAYER := preload("res://autoload/player_state.gd")
const DB := preload("res://autoload/item_db.gd")
const RULES := preload("res://scripts/world/death_satchel_rules.gd")
const TRADE := preload("res://scripts/trade/trade_db.gd")

func test_actual_backpack_drop_remove_trade_container_and_death_paths_keep_personal_key() -> void:
	var player := PLAYER.new()
	player.configure(DB.new())
	player.character_id = "key-protection-owner"
	assert_eq(player.inventory.add("home_key", 1), 0)
	assert_eq(player.inventory.add("wood", 3), 0)
	var slot: int = player.inventory.find_slot("home_key")
	assert_eq(player.inventory.drop_slot(slot), {})
	assert_false(player.inventory.remove("home_key", 1))
	assert_eq(player.inventory.count("home_key"), 1)
	var personal := RULES.slots(player.inventory)
	assert_true(RULES.preview([], personal, "deposit", "home_key", 1).is_empty())
	var trade := TRADE.new()
	for vendor: String in trade.vendor_ids():
		assert_eq(trade.sell_price(vendor, "home_key"), 0, vendor)
		assert_false(trade.sell(player.inventory, vendor, "home_key").is_empty(), "sell refuses")
	assert_eq(player.inventory.count("home_key"), 1)
	assert_eq(RULES.death_slots(player.inventory)[slot], null)
	var drained: Array = player.inventory.drain()
	assert_eq(drained, [{"id": "wood", "n": 3}])
	assert_eq(player.inventory.count("home_key"), 1)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(player.save_data()))
	var restored := PLAYER.new()
	restored.configure(DB.new())
	restored.load_data(saved)
	assert_eq(restored.inventory.count("home_key"), 1)

func test_host_transfer_and_drop_intents_refuse_key_without_any_world_or_recipient_operations() -> void:
	var world := preload("res://autoload/world_state.gd").new()
	world.world_id = "protected-key-world"
	var ledger := preload("res://scripts/net/world_ledger.gd").new(world)
	var before: Dictionary = world.save_data()
	for operation: String in ["transfer_item", "drop_item"]:
		var intent := {"kind": operation, "realm": "meadows", "txn_id": "home-key-refusal-" + operation,
			"item": "home_key", "count": 1, "from": 1, "to": 2, "position": [0, 0, 0]}
		var result: Dictionary = ledger.commit(intent, 1)
		assert_false(result.get("ok"))
		assert_eq(result.get("code"), "protected_key")
		assert_false(str(result.get("reason", "")).is_empty())
		assert_eq(result.get("delta", {}).get("ops", []), [])
		assert_eq(world.save_data(), before)
		assert_eq(ledger.seq, 0)
