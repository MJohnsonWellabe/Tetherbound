extends "res://tests/test_case.gd"

const ATOMIC := preload("res://scripts/save/atomic_save_file.gd")
const WORLD := preload("res://scripts/save/world_save.gd")
const CHARACTER := preload("res://scripts/save/character_save.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const SPLIT_FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
var _dir: String
var _path: String

class ShortWrite:
	extends "res://scripts/save/atomic_save_file.gd"
	func _store(file: FileAccess, bytes: PackedByteArray) -> bool:
		file.store_buffer(bytes.slice(0, bytes.size() / 2))
		return true # Model the old backend's incorrectly reported success.

class FlushFailure:
	extends "res://scripts/save/atomic_save_file.gd"
	func _flush(file: FileAccess) -> Error:
		file.flush()
		return ERR_FILE_CANT_WRITE

class RenameFailure:
	extends "res://scripts/save/atomic_save_file.gd"
	var calls := 0
	var refuse: Array[int] = []
	func _rename(from: String, to: String) -> Error:
		calls += 1
		if calls in refuse:
			return ERR_FILE_CANT_WRITE
		return super._rename(from, to)

class FailingCharacterStore:
	extends RefCounted
	var inner: RefCounted
	func _init(real_store: RefCounted) -> void:
		inner = real_store
	func path_for(character_id: String) -> String:
		return str(inner.call("path_for", character_id))
	func write(_character_id: String, _payload: Dictionary, _envelope: Dictionary = {},
			_retain_previous: bool = false) -> bool:
		return false

class LocalReceiver:
	extends RefCounted
	var applied: Dictionary = {}
	func load_data(data: Dictionary) -> void:
		applied = data.duplicate(true)

class CharacterGame:
	extends RefCounted
	var local: RefCounted = LocalReceiver.new()

func before_each() -> void:
	_dir = "user://test_atomic_save_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	DirAccess.make_dir_recursive_absolute(_dir)
	_path = _dir + "save.json"

func after_each() -> void:
	# Only this test's random fixture tree; split-save cases create child dirs.
	SPLIT_FIXTURE.wipe(_dir)

func _seed() -> void:
	assert_true(ATOMIC.new().write(_path, '{"value":"previous"}'))

func _assert_previous() -> void:
	assert_eq(FileAccess.get_file_as_string(ATOMIC.readable_path(_path)), '{"value":"previous"}')

func test_create_and_replace_unicode_document() -> void:
	_seed()
	var next := '{"value":"é 水 🌊"}'
	assert_true(ATOMIC.new().write(_path, next))
	assert_eq(FileAccess.get_file_as_string(_path), next)
	assert_eq(DirAccess.get_files_at(_dir).size(), 1, "no pending/previous file after commit")

func test_short_write_preserves_previous_and_reports_failure() -> void:
	_seed()
	assert_false(ShortWrite.new().write(_path, '{"value":"replacement"}'))
	_assert_previous()
	assert_eq(DirAccess.get_files_at(_dir).size(), 1)

func test_short_first_write_does_not_publish_partial_save() -> void:
	assert_false(ShortWrite.new().write(_path, '{"value":"replacement"}'))
	assert_false(FileAccess.file_exists(_path))
	assert_eq(DirAccess.get_files_at(_dir).size(), 0)

func test_flush_failure_preserves_previous() -> void:
	_seed()
	assert_false(FlushFailure.new().write(_path, '{"value":"replacement"}'))
	_assert_previous()

func test_backup_rename_refusal_leaves_canonical_untouched() -> void:
	_seed()
	var writer := RenameFailure.new()
	writer.refuse = [1]
	assert_false(writer.write(_path, '{"value":"replacement"}'))
	_assert_previous()
	assert_true(FileAccess.file_exists(_path))

func test_commit_refusal_rolls_back_original_bytes() -> void:
	_seed()
	var writer := RenameFailure.new()
	writer.refuse = [2]
	assert_false(writer.write(_path, '{"value":"replacement"}'))
	_assert_previous()
	assert_true(FileAccess.file_exists(_path))
	assert_eq(DirAccess.get_files_at(_dir).size(), 1)

func test_rollback_refusal_retains_readable_previous_and_next_write_recovers() -> void:
	_seed()
	var writer := RenameFailure.new()
	writer.refuse = [2, 3]
	assert_false(writer.write(_path, '{"value":"replacement"}'))
	assert_false(FileAccess.file_exists(_path))
	_assert_previous()
	assert_true(ATOMIC.new().write(_path, '{"value":"recovered"}'))
	assert_eq(FileAccess.get_file_as_string(_path), '{"value":"recovered"}')
	assert_eq(DirAccess.get_files_at(_dir).size(), 1)

func test_real_directory_collision_refuses_commit_without_deleting_directory() -> void:
	DirAccess.make_dir_absolute(_path)
	assert_false(ATOMIC.new().write(_path, '{"value":1}'))
	assert_true(DirAccess.dir_exists_absolute(_path))
	DirAccess.remove_absolute(_path)

func test_interrupted_replacement_reloads_through_all_save_readers() -> void:
	# A crash after old->previous and before pending->canonical has exactly
	# this layout. Use fresh saver instances, not an in-memory cached payload.
	for pair: Array in [[WORLD, "world.json"], [CHARACTER, "character.json"]]:
		var name: String = pair[1]
		var original := _dir + name
		assert_true(ATOMIC.new().write(original, '{"version":1,"day":7}'))
		assert_eq(DirAccess.rename_absolute(original, original + ".previous"), OK)
		var saver: RefCounted = pair[0].new(_dir)
		# Empty prefix plus '.' identifies this flat, dedicated fixture folder.
		assert_true(saver.has("."))
		assert_eq(saver.read(".").get("day"), 7)
	var slots := SAVE.new(_dir)
	var slot_path: String = slots.slot_path(0)
	assert_true(ATOMIC.new().write(slot_path, '{"version":23,"day":9}'))
	assert_eq(DirAccess.rename_absolute(slot_path, slot_path + ".previous"), OK)
	assert_true(SAVE.new(_dir).has_slot(0))
	assert_eq(SAVE.new(_dir)._read(0).get("day"), 9)

func test_canonical_wins_over_leftover_previous() -> void:
	_seed()
	assert_true(ATOMIC.new().write(_path + ".previous", '{"value":"older"}'))
	_assert_previous()
	assert_true(ATOMIC.new().write(_path, '{"value":"next"}'))
	assert_eq(FileAccess.get_file_as_string(_path), '{"value":"next"}')

func test_pre_rewrite_slot_without_previous_loads_through_production_loader() -> void:
	var saver := SAVE.new(_dir)
	var written := SPLIT_FIXTURE.populated_game(ITEM_DB.new())
	var legacy := saver.snapshot(written)
	legacy["version"] = 22
	legacy.erase("realm_environment")
	var file := FileAccess.open(saver.slot_path(2), FileAccess.WRITE)
	assert_true(file != null)
	file.store_string(JSON.stringify(legacy, "\t"))
	file.close()
	assert_false(FileAccess.file_exists(saver.slot_path(2) + ".previous"))
	var loaded := SPLIT_FIXTURE.game(ITEM_DB.new(), false)
	assert_true(saver.load_slot(loaded, 2))
	assert_eq(int(loaded.get("day")), 7)
	assert_eq(str(loaded.get("current_realm")), "meadows")
	assert_eq((loaded.get("party") as RefCounted).call("size"), 1)

func test_corrupt_canonical_falls_back_for_slot_listing_loading_and_existence() -> void:
	var saver := SAVE.new(_dir)
	var path := saver.slot_path(1)
	assert_true(ATOMIC.new().write(path, '{"version":23,"day":11,"party":[],"current_realm":"water"}'))
	assert_eq(DirAccess.rename_absolute(path, path + ".previous"), OK)
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string('{"version":23,"day":')
	corrupt.close()
	assert_true(saver.has_slot(1), "a valid recovery copy is still a save")
	assert_eq(int(saver.slot_info(1).get("day", 0)), 11, "slot list reads recovery copy")
	assert_eq(int(saver._read(1).get("day", 0)), 11, "loader reads recovery copy")
	assert_false(SAVE.new(_dir).slot_info(1).is_empty(), "fresh title-screen saver sees recovery copy")

func test_corrupt_canonical_falls_back_for_world_and_multiplayer_character_readers() -> void:
	var worlds := WORLD.new(_dir + "worlds/")
	assert_true(worlds.write("w1", {"day": 13}))
	var world_path := worlds.path_for("w1")
	assert_eq(DirAccess.rename_absolute(world_path, world_path + ".previous"), OK)
	var corrupt_world := FileAccess.open(world_path, FileAccess.WRITE)
	corrupt_world.store_string("{truncated")
	corrupt_world.close()
	assert_true(worlds.has("w1"))
	assert_true("w1" in worlds.list_ids())
	assert_eq(int(worlds.read("w1").get("day", 0)), 13)

	var characters := CHARACTER.new(_dir + "characters/")
	assert_true(characters.write("c1", {"realm": "stormwood", "party": []}))
	var character_path := characters.path_for("c1")
	assert_eq(DirAccess.rename_absolute(character_path, character_path + ".previous"), OK)
	var corrupt_character := FileAccess.open(character_path, FileAccess.WRITE)
	corrupt_character.store_string('{"version":1')
	corrupt_character.close()
	assert_true(characters.has("c1"))
	assert_true("c1" in characters.list_ids())
	assert_eq(str(characters.read("c1").get("realm", "")), "stormwood")
	var game := CharacterGame.new()
	assert_true(characters.apply(game, "c1"), "multiplayer character apply uses recovery copy")
	assert_eq(str((game.local as LocalReceiver).applied.get("realm", "")), "stormwood")

func test_corrupt_canonical_without_valid_backup_is_not_listed_as_a_save() -> void:
	var saver := SAVE.new(_dir)
	var file := FileAccess.open(saver.slot_path(0), FileAccess.WRITE)
	file.store_string("not json")
	file.close()
	assert_false(saver.has_slot(0))
	assert_true(saver.slot_info(0).is_empty())

func test_delete_removes_canonical_and_backup_for_every_save_store() -> void:
	var saver := SAVE.new(_dir)
	var slot_path := saver.slot_path(0)
	assert_true(ATOMIC.new().write(slot_path, '{"version":23}'))
	assert_true(ATOMIC.new().write(slot_path + ".previous", '{"version":22}'))
	assert_true(saver.delete_slot(0))
	assert_false(saver.has_slot(0))
	assert_false(FileAccess.file_exists(slot_path + ".previous"))
	var backup_only := saver.slot_path(1)
	assert_true(ATOMIC.new().write(backup_only, '{"version":23}'))
	assert_eq(DirAccess.rename_absolute(backup_only, backup_only + ".previous"), OK)
	assert_true(saver.delete_slot(1), "backup-only interrupted save can be deleted")
	assert_false(FileAccess.file_exists(backup_only + ".previous"))

	var worlds := WORLD.new(_dir + "worlds/")
	assert_true(worlds.write("w1", {"day": 1}))
	assert_true(ATOMIC.new().write(worlds.path_for("w1") + ".previous", '{"version":1}'))
	assert_true(worlds.delete("w1"))
	assert_false(worlds.has("w1"))

	var characters := CHARACTER.new(_dir + "characters/")
	assert_true(characters.write("c1", {"realm": "meadows"}))
	assert_true(ATOMIC.new().write(characters.path_for("c1") + ".previous", '{"version":1}'))
	assert_true(characters.delete("c1"))
	assert_false(characters.has("c1"))

func test_failed_commit_over_corrupt_canonical_preserves_valid_previous() -> void:
	assert_true(ATOMIC.new().write(_path, '{"value":"safe"}'))
	assert_eq(DirAccess.rename_absolute(_path, _path + ".previous"), OK)
	var corrupt := FileAccess.open(_path, FileAccess.WRITE)
	corrupt.store_string('{"value":')
	corrupt.close()
	var writer := RenameFailure.new()
	writer.refuse = [1]
	assert_false(writer.write(_path, '{"value":"next"}'))
	assert_eq(FileAccess.get_file_as_string(ATOMIC.readable_path(_path)), '{"value":"safe"}')

func test_character_half_failure_rolls_slot_and_world_back_to_same_generation() -> void:
	var saver := SAVE.new(_dir)
	var game := SPLIT_FIXTURE.populated_game(ITEM_DB.new())
	assert_true(saver.save(game, 3))
	var worlds: RefCounted = saver.worlds()
	var characters: RefCounted = saver.characters()
	assert_eq(int(saver._read(3).get("day", 0)), 7)
	assert_eq(int(worlds.call("read", "slot-3").get("day", 0)), 7)
	assert_eq(str(characters.call("read", "slot-3").get("realm", "")), "meadows")

	game.set("day", 12)
	game.set_realm("cloudreach")
	saver.set("_characters", FailingCharacterStore.new(characters))
	assert_false(saver.save(game, 3), "split failure propagates to the production save call")
	assert_eq(int(saver._read(3).get("day", 0)), 7, "slot rolled back")
	assert_eq(int(worlds.call("read", "slot-3").get("day", 0)), 7, "world rolled back")
	assert_eq(str(characters.call("read", "slot-3").get("realm", "")), "meadows", "character stayed old")
	assert_false(FileAccess.file_exists(saver.slot_path(3) + ".previous"))
	assert_false(FileAccess.file_exists(str(worlds.call("path_for", "slot-3")) + ".previous"))
	assert_false(FileAccess.file_exists(str(characters.call("path_for", "slot-3")) + ".previous"))

func test_successful_split_commit_finishes_all_retained_backups() -> void:
	var saver := SAVE.new(_dir)
	var game := SPLIT_FIXTURE.populated_game(ITEM_DB.new())
	assert_true(saver.save(game, 4))
	game.set("day", 8)
	assert_true(saver.save(game, 4))
	var paths: Array[String] = [
		saver.slot_path(4),
		str(saver.worlds().call("path_for", "slot-4")),
		str(saver.characters().call("path_for", "slot-4")),
	]
	for path: String in paths:
		assert_false(FileAccess.file_exists(path + ".previous"), "%s retained a finished backup" % path)
	assert_eq(int(saver._read(4).get("day", 0)), 8)
	assert_eq(int(saver.worlds().call("read", "slot-4").get("day", 0)), 8)
