extends "res://tests/test_case.gd"

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const TEST_DIR := "user://test_authoritative_split_load/"

class WorldHolder:
	extends RefCounted
	var world_id := ""
	var reward_deliveries := {}
	var reward_delivery_namespace := ""
	var water_capture_claims := {}

class LocalHolder:
	extends RefCounted
	var character_id := ""
	var display_name := ""
	var chosen_character := "trainer"
	var satchel_escrow := {}

var db: RefCounted
var saver: RefCounted

func before_each() -> void:
	FIXTURE.wipe(TEST_DIR)
	db = ITEM_DB.new()
	saver = SAVE_GAME.new(TEST_DIR)

func after_each() -> void:
	FIXTURE.wipe(TEST_DIR)

func _game() -> RefCounted:
	var game: RefCounted = FIXTURE.populated_game(db)
	game.world = WorldHolder.new()
	game.local = LocalHolder.new()
	game.local.chosen_character = "sera"
	return game

func _split_world(id: String) -> Dictionary:
	return (saver.call("worlds") as RefCounted).call("read", id)

func _split_character(id: String) -> Dictionary:
	return (saver.call("characters") as RefCounted).call("read", id)

func _rewrite_flat(mutator: Callable) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saver.slot_path(1)))
	mutator.call(data)
	var file := FileAccess.open(saver.slot_path(1), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func test_locator_loads_newer_split_journals_not_stale_merged_slot() -> void:
	var original := _game()
	assert_true(saver.save(original, 1))
	var flat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saver.slot_path(1)))
	assert_eq((flat.get("split_locator", {}) as Dictionary).get("world_id"), "slot-1")
	var world := _split_world("slot-1")
	world["reward_delivery_namespace"] = "reward-world-uuid"
	world["reward_deliveries"] = {"reward:warden:2": {"state": "pending", "item": "sigil_shard", "count": 1}}
	assert_true((saver.call("worlds") as RefCounted).call("write", "slot-1", world))
	var character := _split_character("slot-1")
	character["inventory"] = [{"id": "potion_small", "n": 1}]
	character["satchel_escrow"] = {"reward:warden:2": {"status": "grant_due", "stacks": [{"id": "sigil_shard", "n": 1}]}}
	assert_true((saver.call("characters") as RefCounted).call("write", "slot-1", character,
		{"last_world_id": "slot-1"}))
	# A new saver proves a restarted title process follows the on-disk locator,
	# rather than seeing this instance's split saver caches.
	var fresh_saver: RefCounted = SAVE_GAME.new(TEST_DIR)
	var loaded := _game()
	assert_true(fresh_saver.load_slot(loaded, 1))
	assert_eq(loaded.world.world_id, "slot-1")
	assert_eq(loaded.local.character_id, "slot-1")
	assert_eq(loaded.world.reward_delivery_namespace, "reward-world-uuid")
	assert_true(loaded.world.reward_deliveries.has("reward:warden:2"))
	assert_eq(loaded.inventory.count("potion_small"), 1)
	assert_true(loaded.local.satchel_escrow.has("reward:warden:2"))

func test_locator_prefers_its_pair_when_both_deterministic_pairs_exist() -> void:
	var original := _game()
	assert_true(saver.save(original, 1))
	var world := _split_world("slot-1")
	world["day"] = 44
	assert_true((saver.call("worlds") as RefCounted).call("write", "legacy-slot-1", world))
	var character := _split_character("slot-1")
	assert_true((saver.call("characters") as RefCounted).call("write", "legacy-slot-1", character,
		{"last_world_id": "legacy-slot-1"}))
	var loaded := _game()
	assert_true(saver.load_slot(loaded, 1))
	assert_eq(loaded.world.world_id, "slot-1")
	assert_ne(loaded.day, 44)

func test_corrupt_or_newer_locator_half_refuses_without_mutating_live_state() -> void:
	var original := _game()
	assert_true(saver.save(original, 1))
	var character_path := str((saver.call("characters") as RefCounted).call("path_for", "slot-1"))
	var file := FileAccess.open(character_path, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	var loaded := _game()
	loaded.day = 91
	loaded.inventory.add("wood", 3)
	assert_false(saver.load_slot(loaded, 1))
	assert_eq(loaded.day, 91)
	assert_eq(loaded.inventory.count("wood"), 15)

func test_newer_locator_half_refuses_without_mutating_live_state() -> void:
	var original := _game()
	assert_true(saver.save(original, 1))
	var character_path := str((saver.call("characters") as RefCounted).call("path_for", "slot-1"))
	var character: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(character_path))
	character["version"] = 999999
	var file := FileAccess.open(character_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(character))
	file.close()
	var loaded := _game()
	loaded.day = 88
	assert_false(saver.load_slot(loaded, 1))
	assert_eq(loaded.day, 88)

func test_missing_and_traversal_locator_refuse_without_mutating_live_state() -> void:
	var original := _game()
	assert_true(saver.save(original, 1))
	_rewrite_flat(func(data: Dictionary) -> void:
		data["split_locator"] = {"world_id": "missing-world", "character_id": "missing-character"})
	var loaded := _game()
	loaded.day = 77
	assert_false(saver.load_slot(loaded, 1))
	assert_eq(loaded.day, 77)
	assert_true(saver.save(original, 1))
	_rewrite_flat(func(data: Dictionary) -> void:
		data["split_locator"] = {"world_id": "../outside", "character_id": "slot-1"})
	assert_false(saver.load_slot(loaded, 1))
	assert_eq(loaded.day, 77)

func test_portable_character_from_a_friend_world_reseats_safely_on_home_load() -> void:
	var original := _game()
	assert_true(saver.save(original, 1))
	var character := _split_character("slot-1")
	character["last_world_id"] = "friend-world"
	character["realm"] = "cloudreach"
	character["pending_realm_entry"] = "friend_gate"
	character["player_pose"] = {"realm": "cloudreach", "position": [99.0, 2.0, 99.0]}
	character["realm_maps"] = {
		"meadows": {"alpha_pins": [{"order": 101, "species": "terrapup",
			"display_name": "Home pin", "position": [1.0, 2.0], "icon": "alpha"}]},
		"cloudreach": {"alpha_pins": [{"order": 202, "species": "galecrest",
			"display_name": "Friend pin", "position": [3.0, 4.0], "icon": "alpha"}]},
	}
	character["inventory"] = [{"id": "potion_small", "n": 1}]
	character["satchel_escrow"] = {"reward:friend:2": {"status": "grant_due", "stacks": [{"id": "sigil_shard", "n": 1}]}}
	assert_true((saver.call("characters") as RefCounted).call("write", "slot-1", character,
		{"last_world_id": "friend-world"}))
	var loaded := _game()
	assert_true(SAVE_GAME.new(TEST_DIR).load_slot(loaded, 1))
	assert_eq(loaded.world.world_id, "slot-1")
	assert_eq(loaded.local.character_id, "slot-1")
	assert_eq(loaded.current_realm, "meadows")
	assert_eq(loaded.pending_realm_entry, "")
	assert_true((loaded.saved_player_pose as Dictionary).is_empty())
	var pins: Array = loaded.map.call("alpha_pins")
	assert_eq(pins.size(), 1)
	assert_eq(int((pins[0] as Dictionary).get("order", 0)), 101,
		"home map restores its own pin, not the friend realm's active pin")
	assert_eq(loaded.inventory.count("potion_small"), 1)
	assert_true(loaded.local.satchel_escrow.has("reward:friend:2"))
