extends "res://tests/test_case.gd"

## Disclosed typed pending/settled portal-state fixture. Real SaveGame,
## WorldSave and CharacterSave disk writers/loaders; no world/input claim.
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const DOCUMENT := preload("res://scripts/save/save_document.gd")
const PORTAL := preload("res://scripts/net/portal_delivery.gd")
const PLAYER := preload("res://autoload/player_state.gd")
const WORLD := preload("res://autoload/world_state.gd")
const DB := preload("res://autoload/item_db.gd")
const DIRECTORY := "user://test_f20_portal_save_identity/"
const OWNER := "f20-portal-owner"

var database: RefCounted
var saver: RefCounted

func before_each() -> void:
	FIXTURE.wipe(DIRECTORY)
	database = DB.new()
	saver = SAVE.new(DIRECTORY)

func after_each() -> void:
	FIXTURE.wipe(DIRECTORY)

func _game() -> RefCounted:
	var game := FIXTURE.game(database, false)
	game.local = PLAYER.new()
	game.local.configure(database)
	game.local.character_id = OWNER
	game.party = game.local.party
	game.inventory = game.local.inventory
	game.world = WORLD.new()
	game.world.world_id = "slot-0"
	game.world.reward_delivery_namespace = "f20-portal-world"
	return game

func _install_pending(game: RefCounted) -> Dictionary:
	game.inventory.add("fifth_portal_key", 1)
	var row := PORTAL.row(game.world, OWNER, "biome5", 0)
	game.world.reward_deliveries[row.receipt] = row.duplicate(true)
	game.world.redesign_world.fifth_arch_stirred = true
	return row

func _install_settled_owner(game: RefCounted, row: Dictionary) -> void:
	game.inventory.set_slot(0, null)
	var settled := row.duplicate(true)
	settled.status = "settled"
	game.local.satchel_escrow[row.receipt] = settled
	game.local.redesign_character.transaction_receipts.append(row.receipt)

func test_pending_world_owner_bool_save_and_merged_slot_reload_use_actual_locator() -> void:
	var game := _game()
	assert_true(saver.save(game, 0))
	var row := _install_pending(game)
	assert_true(PORTAL.valid(row, OWNER, game.world.reward_delivery_namespace))
	assert_true(saver.save_world_prepared(game, "slot-0"), "host persists its original pending portal journal")
	var world_path: String = saver.worlds().path_for("slot-0")
	var world_bytes := FileAccess.get_file_as_bytes(world_path)
	_install_settled_owner(game, row)
	game.host = false
	assert_true(saver.save_character_prepared(game, OWNER), "real owner BOOL writer accepts the matching pending host journal")
	assert_eq(FileAccess.get_file_as_bytes(world_path), world_bytes, "personal save never writes or settles the host journal")
	assert_eq(game.world.reward_deliveries[row.receipt], row)
	var owner_disk: Dictionary = saver.characters().read(OWNER)
	assert_true(owner_disk.get("satchel_escrow", {}).get(row.receipt, {}).get("status") == "settled")
	game.host = true
	assert_true(saver.save(game, 0), "ordinary merged save retains the same portal identities")
	var flat := DOCUMENT.parse(FileAccess.get_file_as_string(saver.slot_path(0)))
	assert_false(flat.has("world_id"), "validation projection must not alter the merged slot schema")
	assert_eq(flat.get(SAVE.SPLIT_LOCATOR_KEY, {}).get("world_id"), "slot-0")
	var loaded := _game()
	loaded.world.world_id = "unrelated-live-world"
	loaded.world.reward_delivery_namespace = "unrelated-live-instance"
	assert_true(SAVE.new(DIRECTORY).load_slot(loaded, 0), "load validates the selected disk world, not unrelated live state")
	assert_eq(loaded.world.world_id, "slot-0")
	assert_eq(loaded.world.reward_delivery_namespace, "f20-portal-world")
	assert_eq(loaded.world.reward_deliveries[row.receipt], row)
	assert_eq(loaded.inventory.count("fifth_portal_key"), 0)
	assert_true(loaded.local.redesign_character.transaction_receipts.has(row.receipt))
	assert_eq(loaded.local.satchel_escrow[row.receipt].status, "settled")
	assert_true(loaded.world.redesign_world.fifth_arch_stirred)
	assert_false(loaded.local.redesign_character.portal_unlocks.has("biome5"))

func test_pending_portal_journal_cross_slot_refusal_preserves_original_disk_and_identity() -> void:
	var game := _game()
	var row := _install_pending(game)
	assert_true(saver.save(game, 0))
	var slot_bytes := FileAccess.get_file_as_bytes(saver.slot_path(0))
	var world_path: String = saver.worlds().path_for("slot-0")
	var world_bytes := FileAccess.get_file_as_bytes(world_path)
	var owner_path: String = saver.characters().path_for(OWNER)
	var owner_bytes := FileAccess.get_file_as_bytes(owner_path)
	assert_false(saver.save(game, 1), "a different slot cannot rebind the retained portal journal")
	assert_eq(game.world.world_id, "slot-0")
	assert_eq(game.world.reward_delivery_namespace, "f20-portal-world")
	assert_eq(game.local.character_id, OWNER)
	assert_eq(game.world.reward_deliveries[row.receipt], row)
	assert_eq(game.inventory.count("fifth_portal_key"), 1)
	assert_eq(FileAccess.get_file_as_bytes(saver.slot_path(0)), slot_bytes)
	assert_eq(FileAccess.get_file_as_bytes(world_path), world_bytes)
	assert_eq(FileAccess.get_file_as_bytes(owner_path), owner_bytes)
	assert_false(saver.has_slot(1))
	assert_false(saver.worlds().has("slot-1"))
	assert_true(saver.save(game, 0), "original matching locator remains saveable after refused copy")

func test_corrupt_disk_locator_cannot_authorize_another_world_portal_journal() -> void:
	var game := _game()
	var row := _install_pending(game)
	assert_true(saver.save(game, 0))
	var owner_path: String = saver.characters().path_for(OWNER)
	var owner_bytes := FileAccess.get_file_as_bytes(owner_path)
	var world_path: String = saver.worlds().path_for("slot-0")
	var world_bytes := FileAccess.get_file_as_bytes(world_path)
	var flat := DOCUMENT.parse(FileAccess.get_file_as_string(saver.slot_path(0)))
	flat[SAVE.SPLIT_LOCATOR_KEY].world_id = "another-world"
	var file := FileAccess.open(saver.slot_path(0), FileAccess.WRITE)
	assert_true(file != null)
	if file == null: return
	file.store_string(DOCUMENT.stringify(flat))
	file.close()
	var loaded := _game()
	loaded.world.world_id = "untouched-world"
	var reader := SAVE.new(DIRECTORY)
	assert_false(reader.load_slot(loaded, 0))
	assert_eq(reader.last_load_result.get("code"), "invalid_schema")
	assert_true(reader.last_load_result.get("errors", []).has("invalid portal world receipt " + row.receipt))
	assert_eq(loaded.world.world_id, "untouched-world")
	assert_eq(FileAccess.get_file_as_bytes(owner_path), owner_bytes)
	assert_eq(FileAccess.get_file_as_bytes(world_path), world_bytes)
