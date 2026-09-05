extends "res://tests/test_case.gd"

const GAME := preload("res://autoload/game_state.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const MINIMAP := preload("res://scripts/ui/minimap.gd")
const TAB := preload("res://scripts/ui/tab_map.gd")
const DIR := "user://test_realm_map_persistence/"
const MEADOWS_AT := Vector3(120, 0, 140)
const CLOUDREACH_AT := Vector3(1400, 1000, 5500)

var _games: Array[Node] = []
var _save: RefCounted


func before_each() -> void:
	_save = SAVE.new(DIR)


func after_each() -> void:
	for game: Node in _games:
		game.free()
	_games.clear()
	for slot in SAVE.SLOT_COUNT:
		var path: String = _save.slot_path(slot)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _game() -> Node:
	var game := GAME.new()
	game.reset_for_new_game()
	_games.append(game)
	return game


func _write(slot: int, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var file := FileAccess.open(_save.slot_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


func _switch(game: Node, realm_id: String) -> RefCounted:
	game.current_realm = realm_id # Scene authorization belongs to enter_realm.
	return game.bind_realm_map()


func _assert_payload(actual: Dictionary, expected: Dictionary, message: String = "") -> void:
	# Compare fields individually so a failure never prints a megabyte fog blob.
	assert_eq(actual.keys().size(), expected.keys().size(), message)
	for key: String in expected:
		if key == "visited_b64":
			assert_eq(str(actual.get(key, "")).sha256_text(), str(expected[key]).sha256_text(), "fog hash: " + message)
		else:
			assert_eq(actual.get(key), expected[key], key + ": " + message)


func test_transition_there_and_back_preserves_exact_meadows_fog_and_instances() -> void:
	var game := _game()
	var meadows: RefCounted = game.map
	meadows.mark_visited(MEADOWS_AT)
	meadows.add_dynamic_marker("home", "home", MEADOWS_AT)
	var original: Dictionary = meadows.save_data()
	var cloud := _switch(game, "cloudreach")
	assert_ne(cloud, meadows)
	assert_false(cloud.is_discovered(MEADOWS_AT))
	cloud.mark_visited(CLOUDREACH_AT)
	assert_true(cloud.is_discovered(CLOUDREACH_AT))
	assert_eq(_switch(game, "meadows"), meadows)
	_assert_payload(game.map.save_data(), original, "Meadows fog and markers remain byte-for-byte unchanged")
	assert_eq(_switch(game, "cloudreach"), cloud)
	assert_true(game.map.is_discovered(CLOUDREACH_AT))
	assert_eq(game.bind_realm_map("waterward"), null)
	assert_eq(game.map, cloud, "unsupported realm cannot replace the active map")


func test_save_reload_in_either_realm_retains_both_payloads_and_ui_contract() -> void:
	for realm_id: String in ["meadows", "cloudreach"]:
		var written := _game()
		written.map.mark_visited(MEADOWS_AT)
		var meadows_data: Dictionary = written.map.save_data()
		_switch(written, "cloudreach").mark_visited(CLOUDREACH_AT)
		written.progression.set_flag("fly_traversal_unlocked")
		written.bind_realm_map("cloudreach", Vector3(0, 160, 300))
		_switch(written, realm_id)
		assert_true(_save.save(written, 0))
		var file_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_save.slot_path(0)))
		assert_eq(file_data.version, SAVE.VERSION)
		assert_eq(file_data.realm_maps.keys().size(), 2)
		_assert_payload(file_data.realm_maps.meadows, meadows_data)
		var restored := _game()
		var existing_meadows: RefCounted = restored.map
		assert_true(_save.load_slot(restored, 0))
		assert_eq(restored.current_realm, realm_id)
		assert_eq(restored.map, restored.bind_realm_map(), "load binds the selected realm before UI mounts")
		assert_eq(_switch(restored, "meadows"), existing_meadows, "live consumers retain map identity")
		_assert_payload(restored.map.save_data(), meadows_data)
		assert_eq(TAB.bounds_for_map(restored.map), TAB.bounds_for_map(null))
		var cloud := _switch(restored, "cloudreach")
		assert_true(cloud.is_discovered(CLOUDREACH_AT))
		assert_true(cloud.is_landmark_discovered("sky_shrine_heartstone"))
		assert_true(restored.progression.has("fly_traversal_unlocked"))
		assert_eq(cloud.map_display_name(), "Cloudreach Cliffs")
		assert_eq(MINIMAP.bounds_for_map(cloud), cloud.world_bounds())
		assert_eq(TAB.bounds_for_map(cloud), cloud.world_bounds())
		assert_ne(TAB.bounds_for_map(cloud), TAB.bounds_for_map(existing_meadows))


func test_legacy_single_map_migration_preserves_meadows_even_in_cloudreach_save() -> void:
	var written := _game()
	written.map.mark_visited(MEADOWS_AT)
	var original: Dictionary = written.map.save_data()
	assert_true(_save.save(written, 0))
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_save.slot_path(0)))
	old.version = 18
	old.current_realm = "cloudreach"
	old.erase("realm_maps")
	_write(0, old)
	var restored := _game()
	assert_true(_save.load_slot(restored, 0))
	assert_eq(restored.map.map_display_name(), "Cloudreach Cliffs")
	assert_eq(restored.map.discovered_fraction(), 0.0)
	_assert_payload(_switch(restored, "meadows").save_data(), original)
	assert_true(restored.map.is_discovered(MEADOWS_AT))
	assert_true(_save.save(restored, 1))
	var second := _game()
	assert_true(_save.load_slot(second, 1))
	_assert_payload(second.map.save_data(), original, "migration followed by another save loses no Meadows fog")


func test_explicit_cloudreach_legacy_tag_is_never_loaded_as_meadows_grid() -> void:
	var written := _game()
	_switch(written, "cloudreach").mark_visited(CLOUDREACH_AT)
	assert_true(_save.save(written, 0))
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_save.slot_path(0)))
	old.version = 18
	old.erase("realm_maps")
	_write(0, old)
	var restored := _game()
	assert_true(_save.load_slot(restored, 0))
	assert_true(restored.map.is_discovered(CLOUDREACH_AT))
	assert_eq(_switch(restored, "meadows").discovered_fraction(), 0.0)


func test_authoritative_payloads_override_alias_and_reset_new_game_clears_both() -> void:
	var game := _game()
	game.map.mark_visited(MEADOWS_AT)
	_switch(game, "cloudreach").mark_visited(CLOUDREACH_AT)
	var payloads: Dictionary = game.save_realm_maps()
	var migrated: Dictionary = _save._migrate_v18({"version": 18, "realm_maps": payloads, "map": {"visited_b64": "wrong"}})
	assert_eq(migrated.realm_maps, payloads)
	assert_eq(migrated.version, 19, "individual migration advances exactly one version")
	game.reset_for_new_game()
	assert_eq(game.current_realm, "meadows")
	assert_false(game.map.is_discovered(MEADOWS_AT))
	assert_false(_switch(game, "cloudreach").is_discovered(CLOUDREACH_AT))


func test_version_one_chain_retains_pre_cloudreach_fields_and_produces_two_maps() -> void:
	var old := {"version": 1, "day": 9, "party": [], "inventory": [], "placed_buildings": []}
	var migrated: Dictionary = _save._migrate_to_current(old, 1, 0)
	assert_eq(migrated.version, SAVE.VERSION)
	assert_eq(migrated.current_realm, "meadows")
	assert_eq(migrated.day, 9)
	assert_true(migrated.has("realm_hearts"))
	assert_eq(migrated.realm_maps.keys().size(), 2)
	assert_eq(migrated.realm_maps.meadows, migrated.map)
