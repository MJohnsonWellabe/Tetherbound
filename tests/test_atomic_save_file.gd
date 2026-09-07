extends "res://tests/test_case.gd"

const ATOMIC := preload("res://scripts/save/atomic_save_file.gd")
const WORLD := preload("res://scripts/save/world_save.gd")
const CHARACTER := preload("res://scripts/save/character_save.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
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

func before_each() -> void:
	_dir = "user://test_atomic_save_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	DirAccess.make_dir_recursive_absolute(_dir)
	_path = _dir + "save.json"

func after_each() -> void:
	# Only this test's random, flat fixture directory; never recursive cleanup.
	for name: String in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir + name)
	DirAccess.remove_absolute(_dir)

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
