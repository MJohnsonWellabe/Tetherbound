extends "res://tests/test_case.gd"

const SAVE := preload("res://scripts/save/save_game.gd")
const CHARACTER := preload("res://scripts/save/character_save.gd")
const WORLD := preload("res://scripts/save/world_save.gd")
const FIXTURE := preload("res://tests/test_save_format.gd")
var fixture: RefCounted

func before_each() -> void:
	fixture = FIXTURE.new()
	fixture.before_each()

func after_each() -> void:
	fixture.after_each()
	fixture = null

func test_v27_fixture_refuses_with_message_without_live_or_disk_mutation() -> void:
	var saver: RefCounted = fixture.saver
	var path: String = saver.slot_path(1)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var original := FileAccess.get_file_as_string("res://data/schema/fixtures/v27_save.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(original)
	file.close()
	var game: RefCounted = fixture._game()
	var before: Dictionary = saver.snapshot(game)
	assert_false(saver.load_slot(game, 1))
	assert_eq(saver.last_load_result.code, "incompatible_old_version")
	assert_true(str(saver.last_load_result.message).contains("older version"))
	assert_true(str(saver.last_load_result.message).contains("new game"))
	assert_eq(saver.snapshot(game), before)
	assert_eq(FileAccess.get_file_as_string(path), original)
	assert_eq(saver.characters().list_ids(), [])
	assert_eq(saver.worlds().list_ids(), [])

func test_all_pre_redesign_versions_refuse_before_applying() -> void:
	var saver: RefCounted = fixture.saver
	DirAccess.make_dir_recursive_absolute(saver.slot_path(1).get_base_dir())
	var game: RefCounted = fixture._game()
	for version in range(0, 28):
		fixture._write_legacy_slot_json(1, {"version": version, "day": 99, "party": [], "inventory": []})
		var path: String = saver.slot_path(1)
		var bytes := FileAccess.get_file_as_bytes(path)
		var before: Dictionary = saver.snapshot(game)
		assert_false(saver.load_slot(game, 1), "old version %d must refuse" % version)
		assert_eq(saver.last_load_result.code, "incompatible_old_version")
		assert_eq(saver.snapshot(game), before)
		assert_eq(FileAccess.get_file_as_bytes(path), bytes)

func test_character_schema_is_new_and_refuses_old_portable_files() -> void:
	assert_true(SAVE.VERSION > 27)
	assert_true(CHARACTER.VERSION > 27)
	var characters: RefCounted = fixture.saver.characters()
	var path: String = characters.path_for("old-character")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	for version in range(1, 28):
		var original := JSON.stringify({"version": version, "character_id": "old-character", "inventory": []})
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(original)
		file.close()
		assert_eq(characters.read("old-character"), {})
		assert_eq(characters.last_load_result.code, "incompatible_old_version")
		assert_eq(FileAccess.get_file_as_string(path), original)

func test_world_schema_is_new_and_refuses_old_authority() -> void:
	assert_true(WORLD.VERSION > 27)
	var worlds: RefCounted = fixture.saver.worlds()
	var path: String = worlds.path_for("old-world")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	for version in range(1, 28):
		var original := JSON.stringify({"version": version, "world_id": "old-world", "day": 99})
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(original)
		file.close()
		assert_eq(worlds.read("old-world"), {})
		assert_eq(worlds.last_load_result.code, "incompatible_old_version")
		assert_eq(FileAccess.get_file_as_string(path), original)

func test_malformed_old_metadata_is_listed_without_casting_payloads() -> void:
	var saver: RefCounted = fixture.saver
	DirAccess.make_dir_recursive_absolute(saver.slot_path(1).get_base_dir())
	for party: Variant in [null, "not an array", {"bad": true}]:
		fixture._write_legacy_slot_json(1, {"version": 27, "day": {"bad": true}, "party": party})
		var info: Dictionary = saver.slot_info(1)
		assert_eq(info.load_result.code, "incompatible_old_version")
		assert_eq(info.party_size, 0)
		assert_eq(info.day, 0)

func test_non_integral_non_finite_or_missing_versions_are_invalid() -> void:
	for version: Variant in [null, "28", 28.9, NAN, INF]:
		assert_eq(SAVE.version_result(version).code, "invalid_version")
	assert_eq(SAVE.version_result(29).code, "incompatible_future_version")
	assert_eq(SAVE.version_result(28).code, "ok")

func test_current_merged_slot_cannot_bypass_old_split_version_barrier() -> void:
	var saver: RefCounted = fixture.saver
	var game: RefCounted = fixture._game()
	assert_true(saver.save(game, 1))
	var slot: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saver.slot_path(1)))
	var world_id := str(slot.split_locator.world_id)
	var worlds: RefCounted = saver.worlds()
	var path: String = worlds.path_for(world_id)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data.version = 2
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var bytes := FileAccess.get_file_as_bytes(path)
	var before: Dictionary = saver.snapshot(game)
	assert_false(saver.load_slot(game, 1))
	assert_eq(saver.last_load_result.code, "incompatible_old_version")
	assert_eq(saver.snapshot(game), before)
	assert_eq(FileAccess.get_file_as_bytes(path), bytes)

func test_old_character_refusal_survives_valid_or_missing_world() -> void:
	var saver: RefCounted = fixture.saver
	var game: RefCounted = fixture._game()
	assert_true(saver.save(game, 1))
	var slot: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saver.slot_path(1)))
	var character_id := str(slot.split_locator.character_id)
	var characters: RefCounted = saver.characters()
	var path: String = characters.path_for(character_id)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data.version = 6
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var bytes := FileAccess.get_file_as_bytes(path)
	var before: Dictionary = saver.snapshot(game)
	assert_false(saver.load_slot(game, 1))
	assert_eq(saver.last_load_result.code, "incompatible_old_version")
	assert_eq(saver.snapshot(game), before)
	assert_eq(FileAccess.get_file_as_bytes(path), bytes)
	saver.worlds().delete(str(slot.split_locator.world_id))
	assert_false(saver.load_slot(game, 1))
	assert_eq(saver.last_load_result.code, "incompatible_old_version")
	assert_eq(saver.snapshot(game), before)
	assert_eq(FileAccess.get_file_as_bytes(path), bytes)

func test_read_only_legacy_portable_discovery_and_new_namespace_writes() -> void:
	var root := FIXTURE.TEST_DIR + "portable_namespaces/"
	var legacy := root + "old/"
	var current := root + "new/"
	var characters := CHARACTER.new(current, legacy)
	var old_path := legacy + "legacy-id/character.json"
	DirAccess.make_dir_recursive_absolute(old_path.get_base_dir())
	var original := JSON.stringify({"version": 6, "character_id": "legacy-id", "party": []})
	var file := FileAccess.open(old_path, FileAccess.WRITE)
	file.store_string(original)
	file.close()
	assert_eq(characters.list_ids(), ["legacy-id"])
	assert_eq(characters.state("legacy-id"), {})
	assert_eq(characters.last_load_result.code, "incompatible_old_version")
	assert_true(characters.write("fresh-id", {"party": []}))
	assert_true(FileAccess.file_exists(current + "fresh-id/character.json"))
	assert_eq(FileAccess.get_file_as_string(old_path), original)
