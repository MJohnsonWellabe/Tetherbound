extends "res://tests/test_case.gd"

## Committed declared-start proof saves must load at the CURRENT save version.
## A schema bump that leaves one behind fails here instead of every two-peer
## scenario stopping at its `load_save` step. Regenerate a stale one with its
## builder (named in the fixture's README.md); never convert the old file.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")
const CHARACTER_SAVE := preload("res://scripts/save/character_save.gd")
const SAVE_DOCUMENT := preload("res://scripts/save/save_document.gd")
const FORMAT := preload("res://tests/test_save_format.gd")

const SCHEMA_ROOT := "redesign-v28"
const ROUTE_OPEN := "res://tools/net/proof_saves/host_meadows_stormwood_route_open"
const ROUTE_OPEN_CHARACTER := "character-f41f4a49223483d6bfdf56715944bb7b"
const ROUTE_OPEN_WORLD_FLAGS: Array[String] = ["realm_key_stormwood", "realm_gate_stormwood_unlocked"]

var format: RefCounted


func before_each() -> void:
	format = FORMAT.new()
	format.before_each()


func after_each() -> void:
	format.after_each()
	format = null


func test_route_open_fixture_documents_are_current_version() -> void:
	var slot := _read(ROUTE_OPEN.path_join("saves").path_join(SCHEMA_ROOT).path_join("slot_0.json.gz"))
	assert_eq(int(slot.get("version", -1)), SAVE_GAME.VERSION, "slot_0 save version")
	var world := _read(ROUTE_OPEN.path_join("worlds").path_join(SCHEMA_ROOT).path_join("slot-0/world.json.gz"))
	assert_eq(int(world.get("version", -1)), WORLD_SAVE.VERSION, "world document version")
	var character := _read(ROUTE_OPEN.path_join("characters").path_join(SCHEMA_ROOT)
		.path_join(ROUTE_OPEN_CHARACTER).path_join("character.json.gz"))
	assert_eq(int(character.get("version", -1)), CHARACTER_SAVE.VERSION, "character document version")
	assert_eq(str(character.get("character_id", "")), ROUTE_OPEN_CHARACTER)
	var flags: Variant = (world.get("flags", {}) as Dictionary).get("flags", []) if world.get("flags") is Dictionary else []
	for flag: String in ROUTE_OPEN_WORLD_FLAGS:
		assert_true(flag in (flags as Array), "world flag %s" % flag)


func test_route_open_fixture_loads_through_save_game() -> void:
	var saver: RefCounted = format.saver
	var test_dir: String = FORMAT.TEST_DIR
	DirAccess.make_dir_recursive_absolute(test_dir)
	assert_true(_inflate(ROUTE_OPEN.path_join("saves").path_join(SCHEMA_ROOT).path_join("slot_0.json.gz"),
		saver.slot_path(0)), "copy slot")
	assert_true(_copy_tree(ROUTE_OPEN.path_join("worlds").path_join(SCHEMA_ROOT), test_dir.path_join("worlds")) > 0, "copy world")
	assert_true(_copy_tree(ROUTE_OPEN.path_join("characters").path_join(SCHEMA_ROOT), test_dir.path_join("characters")) > 0, "copy character")
	var game: RefCounted = format._game(false)
	assert_true(saver.load_slot(game, 0), "load_slot refused the fixture: %s" % str(saver.get("last_load_result")))
	assert_eq(str(game.get("current_realm")), "meadows")
	for flag: String in ROUTE_OPEN_WORLD_FLAGS:
		assert_true(bool(game.progression.has(flag)), "loaded flag %s" % flag)


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_fail("missing fixture file %s" % path)
		return {}
	var parsed: Variant = SAVE_DOCUMENT.parse(_text(path))
	if not parsed is Dictionary:
		_fail("%s is not a JSON object" % path)
		return {}
	return parsed as Dictionary


## The fixture is stored gzipped, as `proof_steps.gd::load_save` reads it.
func _text(path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".gz"):
		bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	return bytes.get_string_from_utf8()


func _inflate(from: String, to: String) -> bool:
	var out := FileAccess.open(to.trim_suffix(".gz"), FileAccess.WRITE)
	if out == null:
		return false
	out.store_string(_text(from))
	out.close()
	return true


func _copy_tree(from: String, to: String) -> int:
	var dir := DirAccess.open(from)
	if dir == null:
		return 0
	DirAccess.make_dir_recursive_absolute(to)
	var copied := 0
	for file: String in dir.get_files():
		if _inflate(from.path_join(file), to.path_join(file)):
			copied += 1
	for sub: String in dir.get_directories():
		copied += _copy_tree(from.path_join(sub), to.path_join(sub))
	return copied
