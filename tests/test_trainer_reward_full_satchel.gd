extends "res://tests/test_case.gd"

## A trainer's reward never vanishes into a full satchel (routes-west F19#5:
## the Ridge captain's elixir_guard was lost at 23/24). What fits lands now;
## the leftover is journaled as this character's own durable reward delivery
## (the shared reward_grant escrow): exactly once, saved on the character,
## delivered when there is room, and still owed after a reload.
const SOLO := preload("res://tests/test_water_guardian_solo_win.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const DELIVERY := preload("res://scripts/net/reward_delivery.gd")

class PayGame extends "res://tests/test_water_guardian_solo_win.gd".GameFixture:
	var inventory: RefCounted
	var items: RefCounted

class PayingDirector extends "res://scripts/combat/encounter_director.gd":
	var ledger_rpc: Node
	var game_node: Node
	var progression_store: RefCounted = preload("res://autoload/progression_state.gd").new()
	func _ensure_encounter_arbiters() -> void: pass
	func _is_host() -> bool: return true
	func _is_multi_peer() -> bool: return false
	func _local_peer_id() -> int: return 1
	func _encounter_realm() -> String: return "meadows"
	func _progression() -> RefCounted: return progression_store
	func _reward_game() -> Node: return game_node
	func _submit_reward_intent(intent: Dictionary) -> Dictionary:
		return ledger_rpc.call("submit", intent)

var _game: Node
var _rpc: Node
var _director: PayingDirector


func before_each() -> void:
	_game = PayGame.new()
	_game.world.world_id = "slot-0"
	_game.local.configure(ITEM_DB.new())
	_game.local.character_id = "host-a"
	_game.set("inventory", _game.local.inventory)
	_game.set("items", ITEM_DB.new())
	_rpc = SOLO.RpcFixture.new()
	_rpc.set("fixture_game", _game)
	_rpc.set("ledger", WORLD_LEDGER.new(_game.world))
	_director = PayingDirector.new()
	_director.set("_session", _game.session)
	_director.ledger_rpc = _rpc
	_director.game_node = _game


func after_each() -> void:
	for node: Node in [_director, _rpc, _game]:
		if is_instance_valid(node): node.free()


func _spec() -> Dictionary:
	return {"id": "ridge_captain_test", "name": "Captain Ridge", "rank": "captain",
		"defeat_flag": "defeated_ridge_captain_test", "rechallenge": false,
		"reward": {"coins": 0, "items": [{"id": "elixir_guard", "count": 1}]}}


func _fill_satchel() -> void:
	var inventory: RefCounted = _game.local.inventory
	var ids: Array = (ITEM_DB.new().call("ids") as Array) if ITEM_DB.new().has_method("ids") else []
	var filler := ["wood", "stone", "fiber", "berries", "rootstone", "ironwood", "potion_small", "revive",
		"good_candy", "great_candy", "rare_candy", "potion_large", "stamina_mushroom", "speed_mushroom",
		"cliffglass_ore", "skyplume", "gale_fiber", "cloudberry", "sparkfur", "windworn_heartwood",
		"rootiron_ingot", "attuned_ground", "attuned_water", "attuned_air"]
	for id: String in filler:
		inventory.call("add", id, 1)
	assert_true(int(inventory.call("add", "elixir_guard", 1)) == 1, "fixture: the satchel is full")


func _owed_rows() -> Array:
	return _game.world.reward_deliveries.values().filter(func(r: Variant) -> bool:
		return r is Dictionary and str(r.get("source", "")) == "trainer:ridge_captain_test:owed:item:elixir_guard")


func test_a_full_satchel_owes_the_reward_and_delivers_it_once_after_room_and_reload() -> void:
	_fill_satchel()
	_director.call("_record_trainer_defeat", _spec())
	assert_eq(_owed_rows().size(), 1, "the leftover is journaled once, not dropped")
	assert_eq(int(_game.local.inventory.call("count", "elixir_guard")), 0, "nothing fit yet")
	var escrow: Array = _game.local.satchel_escrow.values().filter(func(r: Variant) -> bool:
		return r is Dictionary and r.get("kind") == "reward_delivery" and r.get("status") == "grant_due")
	assert_eq(escrow.size(), 1, "owed on the character's own record")
	assert_true(_game.messages.any(func(m: String) -> bool: return m.contains("Satchel full") and m.contains("holding")),
		"the line tells the truth: %s" % str(_game.messages))
	# A repeat defeat of the same trainer owes nothing twice.
	_director.call("_record_trainer_defeat", _spec())
	assert_eq(_owed_rows().size(), 1, "exactly once")
	# Reload the character from its own record: still owed.
	var saved: Dictionary = _game.local.save_data()
	var reloaded: RefCounted = PLAYER_STATE.new()
	reloaded.configure(ITEM_DB.new())
	reloaded.load_data(saved)
	assert_eq(reloaded.satchel_escrow.values().filter(func(r: Variant) -> bool:
		return r is Dictionary and r.get("status") == "grant_due").size(), 1, "still owed after reload")
	# Make room; the existing retry delivers it once.
	_game.local.inventory.call("remove", "wood", 1)
	_rpc.call("reconcile_reward_deliveries")
	_rpc.call("reconcile_reward_deliveries")
	assert_eq(int(_game.local.inventory.call("count", "elixir_guard")), 1, "granted once after room")


func test_a_reward_that_fits_journals_nothing() -> void:
	_director.call("_record_trainer_defeat", _spec())
	assert_eq(int(_game.local.inventory.call("count", "elixir_guard")), 1, "paid now")
	assert_true(_owed_rows().is_empty(), "nothing owed")
