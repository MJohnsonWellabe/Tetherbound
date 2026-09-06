extends "res://tests/test_case.gd"

## D100, the portable half: `user://characters/<character_id>/character.json`
## (`scripts/save/character_save.gd`).
##
## This is directive item 20's second half, and until lane 1.C it did not exist:
## a client left a session having written nothing at all. Every failure here is
## one a player would meet as "my trainer is not my trainer" -- a team that came
## back empty, a satchel that reset, fog that had to be walked off again after
## a reload (lane 5.C's handover), or a character file that had quietly picked
## up somebody else's world.
##
## CLAUDE.md's five-creature rule is not weakened by portability: a character
## file is exactly one party, with no storage, no reserve and no sixth slot.
## `test_a_character_file_is_one_party_and_nothing_more` pins that.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const CHARACTER_SAVE := preload("res://scripts/save/character_save.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const TEST_DIR := "user://test_character_save/"

var db: RefCounted = null
var saver: RefCounted = null
var characters: RefCounted = null


func before_each() -> void:
	FIXTURE.wipe(TEST_DIR)
	db = ITEM_DB.new()
	saver = SAVE_GAME.new(TEST_DIR)
	characters = saver.call("characters")


func after_each() -> void:
	FIXTURE.wipe(TEST_DIR)


# --- the file exists, where D100 says it does ---------------------------------

func test_a_save_writes_a_character_file_at_the_partitioned_path() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	assert_true(bool(characters.call("has", "slot-1")),
		"a slot write must produce a character file; got %s" % str(characters.call("list_ids")))
	assert_eq(str(characters.call("path_for", "slot-1")),
		TEST_DIR + "characters/slot-1/character.json")


func test_the_real_saver_writes_characters_under_the_d100_directory() -> void:
	var shipped: RefCounted = SAVE_GAME.new()
	assert_eq(str((shipped.call("characters") as RefCounted).call("path_for", "c1")),
		"user://characters/c1/character.json")


# --- what is in it ------------------------------------------------------------

func test_the_character_file_carries_the_character_half_and_its_envelope() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	assert_false(data.is_empty(), "the character file must read back")
	for key: String in CHARACTER_SAVE.STATE_KEYS:
		assert_true(data.has(key), "character.json is missing state key '%s'" % key)
	assert_true(data.has("realm"), "character.json carries WHICH REALM this trainer is in")
	assert_true(data.has("flags"), "and its player-scope flag store")
	for key: String in CHARACTER_SAVE.ENVELOPE_KEYS:
		assert_true(data.has(key), "character.json is missing envelope key '%s'" % key)
	assert_eq(int(data.get("version", 0)), CHARACTER_SAVE.VERSION)
	assert_eq(str(data.get("character_id", "")), "slot-1")


func test_the_character_file_carries_no_world_key() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	for key: String in WORLD_SAVE.STATE_KEYS:
		assert_false(data.has(key),
			"character.json must not carry the world key '%s' -- a trainer is not a world" % key)
	assert_false(data.has("world_id"),
		"a portable character names the world it last played, not one it owns")


func test_a_character_names_the_world_it_last_played_without_belonging_to_it() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	assert_eq(str(data.get("last_world_id", "")), "slot-1",
		"the file records where this trainer was, which is what makes a return possible")


func test_the_character_file_values_are_the_ones_the_game_held() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	assert_eq(str(data.get("realm", "")), "meadows",
		"`current_realm` becomes `realm`: which realm a trainer stands in is per player now")
	assert_eq(str(data.get("pending_realm_entry", "")), "south_gate")
	assert_almost_eq(float(data.get("satiety", 0.0)), 63.5)
	assert_eq((data.get("party", []) as Array).size(), 1)
	assert_eq(str(((data["party"] as Array)[0] as Dictionary).get("nickname", "")), "Biscuit")
	assert_eq((data.get("player_pose", {}) as Dictionary).get("position"), [12.0, 1.0, -30.0])


func test_a_character_file_is_one_party_and_nothing_more() -> void:
	# CLAUDE.md: five creatures total, no storage, no reserve box, no hidden
	# sixth slot. A portable file is exactly the place a sixth slot would try to
	# appear, so it is asserted here rather than assumed.
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	for key: String in ["box", "storage", "reserve", "stored_creatures", "party_box", "pc"]:
		assert_false(data.has(key), "a character file must never carry '%s'" % key)
	assert_true((data.get("party", []) as Array).size() <= 5,
		"and its party can never exceed five")


func test_the_fog_a_player_walked_off_is_in_their_character_file() -> void:
	# Lane 5.C's handover: fog is per-player state that did not survive a reload
	# because the file it belongs in did not exist. It exists now, inside
	# `realm_maps`, where the landmarks and the alpha pins already were.
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	var maps: Dictionary = data.get("realm_maps", {}) as Dictionary
	assert_true(maps.has("meadows"), "the realm this trainer walked is in their file")
	var meadows: Dictionary = maps["meadows"] as Dictionary
	assert_true(meadows.has("visited_b64"),
		"and the fog they cleared is in it -- got keys %s" % str(meadows.keys()))
	assert_true(meadows.has("alpha_pins"),
		"with the alpha pins that live beside it, per realm and per player")


func test_only_player_scope_flags_land_in_the_character_file() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	var ids: Array = ((data.get("flags", {}) as Dictionary).get("flags", []) as Array)
	assert_true(ids.has("tam_tools_given"),
		"a player-scope flag travels with the trainer -- got %s" % str(ids))
	assert_false(ids.has("defeated_warden"),
		"a world-scope flag must not: carrying it would let one trainer arrive in a "
		+ "friend's world with their Warden already beaten")
	for id: Variant in ids:
		assert_eq(PROGRESSION_STATE.scope_of(str(id)), PROGRESSION_STATE.SCOPE_PLAYER,
			"'%s' is not player-scope and must not be here" % str(id))


# --- the payload is exactly what PlayerState eats -----------------------------

func test_apply_restores_a_character_onto_a_player_state() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))

	# A second process, arriving with nothing.
	var arriving := FIXTURE.game(db, false)
	var player: RefCounted = load("res://autoload/player_state.gd").new()
	player.call("configure", db)
	arriving.local = player
	assert_true(bool(characters.call("apply", arriving, "slot-1")))
	assert_eq(str(player.get("character_id")), "slot-1")
	assert_eq(str(player.get("realm")), "meadows")
	assert_eq(str(player.get("pending_realm_entry")), "south_gate")
	assert_almost_eq(float(player.get("satiety")), 63.5)
	assert_eq(int((player.get("party") as RefCounted).call("size")), 1,
		"the team came with the trainer")
	assert_true(bool((player.get("flags") as RefCounted).call("has", "tam_tools_given")))
	assert_false(bool((player.get("flags") as RefCounted).call("has", "defeated_warden")),
		"and nothing that belongs to a world came with it")


func test_apply_refuses_a_character_that_is_not_there() -> void:
	var arriving := FIXTURE.game(db, false)
	assert_false(bool(characters.call("apply", arriving, "nobody")))
	assert_false(bool(characters.call("apply", null, "slot-1")))


# --- D100's ownership rule ----------------------------------------------------

func test_a_client_writes_its_own_character_and_only_that() -> void:
	var game := FIXTURE.populated_game(db)
	game.host = false
	assert_true(bool(saver.call("save_character", game, "joiner-1")))
	assert_true(bool(characters.call("has", "joiner-1")),
		"every peer writes its own character, host or not -- that is the whole point")
	assert_true(((saver.call("worlds") as RefCounted).call("list_ids") as Array).is_empty(),
		"and writing a character never writes a world")


func test_save_character_refuses_an_empty_id_and_a_missing_game() -> void:
	var game := FIXTURE.populated_game(db)
	assert_false(bool(saver.call("save_character", game, "")))
	assert_false(bool(saver.call("save_character", null, "someone")))


# --- never fatal --------------------------------------------------------------

func test_a_missing_character_reads_as_nothing_to_load() -> void:
	assert_false(bool(characters.call("has", "nobody")))
	assert_eq(characters.call("read", "nobody"), {})
	assert_eq(characters.call("state", "nobody"), {})
	assert_eq(characters.call("list_ids"), [])


func test_a_corrupt_character_file_reads_as_nothing_to_load() -> void:
	DirAccess.make_dir_recursive_absolute(str(characters.call("dir_for", "broken")))
	var file := FileAccess.open(str(characters.call("path_for", "broken")), FileAccess.WRITE)
	file.store_string("not json at all")
	file.close()
	assert_eq(characters.call("read", "broken"), {})


func test_a_newer_than_this_build_character_file_refuses() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var path := str(characters.call("path_for", "slot-1"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data["version"] = CHARACTER_SAVE.VERSION + 1
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	assert_eq(characters.call("read", "slot-1"), {})
