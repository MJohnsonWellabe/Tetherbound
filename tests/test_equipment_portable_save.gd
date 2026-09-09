extends "res://tests/test_case.gd"

## Worn equipment is character state. These cases exercise the real portable
## character file and split merge instead of only round-tripping the equipment
## dictionary in memory.

const ITEM_DB := preload("res://autoload/item_db.gd")
const PLAYER_STATE := preload("res://autoload/player_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const CHARACTER_SAVE := preload("res://scripts/save/character_save.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")
const SPLIT_FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const TEST_DIR := "user://test_equipment_portable_save/"


class PortableGame:
	extends RefCounted
	var local: RefCounted = null


var db: RefCounted
var saver: RefCounted
var characters: RefCounted
var worlds: RefCounted


func before_each() -> void:
	SPLIT_FIXTURE.wipe(TEST_DIR)
	db = ITEM_DB.new()
	saver = SAVE_GAME.new(TEST_DIR)
	characters = saver.call("characters")
	worlds = saver.call("worlds")


func after_each() -> void:
	SPLIT_FIXTURE.wipe(TEST_DIR)


func _player(character_id: String, item_id: String = "") -> RefCounted:
	var player: RefCounted = PLAYER_STATE.new()
	player.call("configure", db)
	player.set("character_id", character_id)
	player.set("display_name", character_id.capitalize())
	if not item_id.is_empty():
		var inventory: RefCounted = player.get("inventory")
		inventory.call("add", item_id, 1)
		assert_true(bool((player.get("equipment") as RefCounted).call(
			"equip_from_inventory", item_id, inventory)), "fixture equips " + item_id)
	return player


func _flat(player: RefCounted, day: int = 1, world_seed: int = 0) -> Dictionary:
	var data: Dictionary = player.call("save_data")
	data["current_realm"] = str(data.get("realm", "meadows"))
	data.erase("realm")
	data["progression"] = data.get("flags", {"flags": []})
	data.erase("flags")
	data["day"] = day
	data["clock_elapsed_seconds"] = 0.0
	data["world_seed"] = world_seed
	data["placed_buildings"] = []
	data["farm_plots"] = []
	data["death_satchels"] = []
	data["harvested_vegetation"] = {}
	data["felled_vegetation"] = {}
	data["realm_environment"] = {}
	data["water_capture_claims"] = {}
	return data


func _write_v1_without_equipment(character_id: String, player: RefCounted) -> void:
	var payload := CHARACTER_SAVE.partition(_flat(player))
	payload.erase("equipment")
	payload["version"] = 1
	payload["character_id"] = character_id
	payload["display_name"] = str(player.get("display_name"))
	payload["created_at"] = "2026-09-09T00:00:00Z"
	payload["last_played"] = "2026-09-09T00:00:00Z"
	payload["last_world_id"] = "legacy-world"
	payload["migrated_from"] = ""
	var path := str(characters.call("path_for", character_id))
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null, "legacy portable character fixture opens on disk")
	if file != null:
		file.store_string(JSON.stringify(payload, "\t"))
		file.close()


func test_v1_portable_character_without_equipment_loads_as_empty_worn_state() -> void:
	var legacy := _player("legacy")
	_write_v1_without_equipment("legacy", legacy)
	var raw: Dictionary = characters.call("read", "legacy")
	assert_eq(int(raw.get("version", 0)), 1)
	assert_false(raw.has("equipment"), "the real legacy file has no equipment field")

	var arriving := _player("arriving", "insulated_boots")
	var game := PortableGame.new()
	game.local = arriving
	assert_true(bool(characters.call("apply", game, "legacy")))
	assert_eq(str((arriving.get("equipment") as RefCounted).call("equipped_in", "boots")), "",
		"missing legacy equipment clears worn state instead of leaking the prior character")
	assert_eq(str(arriving.get("character_id")), "legacy")


func test_v2_portable_disk_roundtrip_keeps_worn_item_outside_inventory() -> void:
	var source := _player("marin", "insulated_vest")
	var payload := CHARACTER_SAVE.partition(_flat(source))
	assert_true(bool(characters.call("write", "marin", payload,
		{"display_name": "Marin", "last_world_id": "host-a"})))
	var disk: Dictionary = characters.call("read", "marin")
	assert_eq(int(disk.get("version", 0)), CHARACTER_SAVE.VERSION)
	assert_eq(str((disk.get("equipment", {}) as Dictionary).get("upper_body", "")),
		"insulated_vest")

	var restored := _player("blank")
	var game := PortableGame.new()
	game.local = restored
	assert_true(bool(characters.call("apply", game, "marin")))
	assert_eq(str((restored.get("equipment") as RefCounted).call(
		"equipped_in", "upper_body")), "insulated_vest")
	assert_eq(int((restored.get("inventory") as RefCounted).call("count", "insulated_vest")), 0,
		"a worn item does not also reappear in the portable satchel")
	assert_eq(str(restored.get("character_id")), "marin")


func test_switching_two_portable_characters_and_reset_never_leaks_gear() -> void:
	var alpha := _player("alpha", "insulated_boots")
	var beta := _player("beta", "hide_vest")
	assert_true(bool(characters.call("write", "alpha", CHARACTER_SAVE.partition(_flat(alpha)))))
	assert_true(bool(characters.call("write", "beta", CHARACTER_SAVE.partition(_flat(beta)))))
	var active := _player("blank")
	var game := PortableGame.new()
	game.local = active

	assert_true(bool(characters.call("apply", game, "alpha")))
	assert_eq(str((active.get("equipment") as RefCounted).call("equipped_in", "boots")),
		"insulated_boots")
	assert_true(bool(characters.call("apply", game, "beta")))
	assert_eq(str((active.get("equipment") as RefCounted).call("equipped_in", "boots")), "",
		"switching character clears the first trainer's boots")
	assert_eq(str((active.get("equipment") as RefCounted).call("equipped_in", "upper_body")),
		"hide_vest")
	active.call("reset")
	assert_eq((active.get("equipment") as RefCounted).call("save_data"), {
		"helmet": "", "upper_body": "", "lower_body": "", "boots": "", "backpack": "",
	}, "new-game reset clears every worn slot")


func test_world_partition_merge_keeps_guest_gear_and_host_world_facts() -> void:
	var host := _player("host", "hide_boots")
	var guest := _player("guest", "insulated_helm")
	var host_flat := _flat(host, 8, 111)
	host_flat["placed_buildings"] = [{"realm": "water", "uid": "host-dock", "id": "fence"}]
	var guest_flat := _flat(guest, 3, 999)
	guest_flat["placed_buildings"] = [{"realm": "meadows", "uid": "guest-camp", "id": "tent"}]
	assert_true(bool(worlds.call("write", "host-world", WORLD_SAVE.partition(host_flat))))
	assert_true(bool(characters.call("write", "guest", CHARACTER_SAVE.partition(guest_flat),
		{"last_world_id": "host-world"})))

	var merged := CHARACTER_SAVE.merge(
		worlds.call("state", "host-world"), characters.call("state", "guest"), SAVE_GAME.VERSION)
	assert_eq(int(merged.get("day", 0)), 8)
	assert_eq(int(merged.get("world_seed", 0)), 111)
	assert_eq(str((((merged.get("placed_buildings", []) as Array)[0]) as Dictionary).get("uid", "")),
		"host-dock", "world facts come from the selected host world")
	assert_eq(str((merged.get("equipment", {}) as Dictionary).get("helmet", "")),
		"insulated_helm", "worn gear comes from the guest portable character")
	assert_eq(str((merged.get("equipment", {}) as Dictionary).get("boots", "")), "",
		"host gear does not cross the partition boundary")
	assert_eq(str(merged.get("current_realm", "")), "meadows")
