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


func _legacy_id_game() -> RefCounted:
	var game := FIXTURE.populated_game(db)
	game.local.character_id = "slot-1"
	return game


# --- the file exists, where D100 says it does ---------------------------------

func test_independent_characters_using_the_same_slot_get_distinct_portable_ids_and_reload() -> void:
	var saver_a: RefCounted = SAVE_GAME.new(TEST_DIR + "owner-a/")
	var saver_b: RefCounted = SAVE_GAME.new(TEST_DIR + "owner-b/")
	var game_a := FIXTURE.populated_game(db)
	var game_b := FIXTURE.populated_game(db)
	game_a.local.chosen_character = "kael"
	game_b.local.chosen_character = "mira"
	assert_true(saver_a.save(game_a, 0))
	assert_true(saver_b.save(game_b, 0))
	var id_a := str(game_a.local.character_id)
	var id_b := str(game_b.local.character_id)
	assert_true(id_a.begins_with("character-") and id_a.length() == 42)
	assert_true(id_b.begins_with("character-") and id_b.length() == 42)
	assert_ne(id_a, id_b, "slot 0 is a world locator, not a portable character identity")

	var loaded_a := FIXTURE.game(db, false)
	var loaded_b := FIXTURE.game(db, false)
	assert_true(SAVE_GAME.new(TEST_DIR + "owner-a/").load_slot(loaded_a, 0))
	assert_true(SAVE_GAME.new(TEST_DIR + "owner-b/").load_slot(loaded_b, 0))
	assert_eq(str(loaded_a.local.character_id), id_a)
	assert_eq(str(loaded_b.local.character_id), id_b)
	assert_eq(str(loaded_a.local.chosen_character), "kael")
	assert_eq(str(loaded_b.local.chosen_character), "mira")
	assert_eq(loaded_a.inventory.count("wood"), 12)
	assert_eq(loaded_b.inventory.count("wood"), 12)
	assert_eq(loaded_a.party.size(), 1)
	assert_eq(loaded_b.party.size(), 1)


func test_existing_character_id_survives_saves_to_other_slots_and_reload() -> void:
	var game := FIXTURE.populated_game(db)
	game.local.character_id = "character-explicit-existing"
	game.local.chosen_character = "sera"
	assert_true(saver.save(game, 0), "autosave path writes the selected character")
	assert_eq(str(game.local.character_id), "character-explicit-existing")
	game.inventory.add("potion_small", 1)
	assert_true(saver.save(game, 3), "manual save to another slot keeps that character")
	assert_eq(str(game.local.character_id), "character-explicit-existing")
	for slot: int in [0, 3]:
		var flat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saver.slot_path(slot)))
		var locator := flat.get(SAVE_GAME.SPLIT_LOCATOR_KEY, {}) as Dictionary
		assert_eq(str(locator.get("world_id", "")), "slot-%d" % slot,
			"each manual slot still selects its own home world")
		assert_eq(str(locator.get("character_id", "")), "character-explicit-existing",
			"manual slots refer to the current portable character rather than cloning it")
		var loaded := FIXTURE.game(db, false)
		assert_true(SAVE_GAME.new(TEST_DIR).load_slot(loaded, slot))
		assert_eq(str(loaded.world.world_id), "slot-%d" % slot)
		assert_eq(str(loaded.local.character_id), "character-explicit-existing")
		assert_eq(str(loaded.local.chosen_character), "sera")
		assert_eq(loaded.inventory.count("wood"), 12)
		assert_eq(loaded.inventory.count("potion_small"), 1,
			"both worlds load the portable character's latest saved state")
		assert_eq(loaded.party.size(), 1)


func test_scratch_save_does_not_mint_or_rename_live_identity() -> void:
	var game := FIXTURE.populated_game(db)
	assert_eq(str(game.local.character_id), "")
	assert_true(saver.save(game, 4, false))
	assert_eq(str(game.local.character_id), "")
	assert_eq(str(game.world.world_id), "")
	assert_true((saver.call("characters") as RefCounted).call("list_ids").is_empty())
	assert_true((saver.call("worlds") as RefCounted).call("list_ids").is_empty())


func test_unsafe_nonempty_identity_refuses_before_live_or_durable_mutation() -> void:
	var game := FIXTURE.populated_game(db)
	game.local.character_id = "../not-a-character"
	game.world.world_id = "world-before-refusal"
	assert_false(saver.save(game, 2))
	assert_eq(str(game.local.character_id), "../not-a-character")
	assert_eq(str(game.world.world_id), "world-before-refusal")
	assert_false(FileAccess.file_exists(saver.slot_path(2)))
	assert_true((saver.call("characters") as RefCounted).call("list_ids").is_empty())
	assert_true((saver.call("worlds") as RefCounted).call("list_ids").is_empty())


func test_a_save_writes_a_character_file_at_the_partitioned_path() -> void:
	var game := _legacy_id_game()
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
	var game := _legacy_id_game()
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
	var game := _legacy_id_game()
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	for key: String in WORLD_SAVE.STATE_KEYS:
		assert_false(data.has(key),
			"character.json must not carry the world key '%s' -- a trainer is not a world" % key)
	assert_false(data.has("world_id"),
		"a portable character names the world it last played, not one it owns")


func test_a_character_names_the_world_it_last_played_without_belonging_to_it() -> void:
	var game := _legacy_id_game()
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	assert_eq(str(data.get("last_world_id", "")), "slot-1",
		"the file records where this trainer was, which is what makes a return possible")
	assert_eq(str(data.get("last_world_instance_id", "")),
		str(game.world.reward_delivery_namespace),
		"the exact world instance, rather than its reused slot locator, owns the pose")
	assert_false(str(data.get("last_world_instance_id", "")).is_empty())


func test_the_character_file_values_are_the_ones_the_game_held() -> void:
	var game := _legacy_id_game()
	assert_true(saver.save(game, 1))
	var data: Dictionary = characters.call("read", "slot-1")
	assert_eq(str(data.get("realm", "")), "meadows",
		"`current_realm` becomes `realm`: which realm a trainer stands in is per player now")
	assert_eq(str(data.get("chosen_character", "")), "sera",
		"the body choice travels with the trainer")
	assert_eq(str(data.get("pending_realm_entry", "")), "south_gate")
	assert_almost_eq(float(data.get("satiety", 0.0)), 63.5)
	assert_eq((data.get("party", []) as Array).size(), 1)
	assert_eq(str(((data["party"] as Array)[0] as Dictionary).get("nickname", "")), "Biscuit")
	assert_eq((data.get("player_pose", {}) as Dictionary).get("position"), [12.0, 1.0, -30.0])


func test_a_character_file_is_one_party_and_nothing_more() -> void:
	# CLAUDE.md: five creatures total, no storage, no reserve box, no hidden
	# sixth slot. A portable file is exactly the place a sixth slot would try to
	# appear, so it is asserted here rather than assumed.
	var game := _legacy_id_game()
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
	var game := _legacy_id_game()
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
	var game := _legacy_id_game()
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
	var game := _legacy_id_game()
	assert_true(saver.save(game, 1))

	# A second process, arriving with nothing.
	var arriving := FIXTURE.game(db, false)
	var player: RefCounted = load("res://autoload/player_state.gd").new()
	player.call("configure", db)
	arriving.local = player
	assert_true(bool(characters.call("apply", arriving, "slot-1")))
	assert_eq(str(player.get("character_id")), "slot-1")
	assert_eq(str(player.get("chosen_character")), "sera")
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
	var game := _legacy_id_game()
	game.host = false
	game.world.reward_delivery_namespace = "friend-instance"
	assert_true(bool(saver.call("save_character", game, "joiner-1")))
	assert_true(bool(characters.call("has", "joiner-1")),
		"every peer writes its own character, host or not -- that is the whole point")
	assert_true(((saver.call("worlds") as RefCounted).call("list_ids") as Array).is_empty(),
		"and writing a character never writes a world")
	var written: Dictionary = characters.call("read", "joiner-1")
	assert_eq(str(written.get("last_world_instance_id", "")), "friend-instance",
		"a client records the host instance received in its world snapshot")


func test_rewriting_character_preserves_world_instance_envelope() -> void:
	var game := _legacy_id_game()
	game.world.reward_delivery_namespace = "stable-instance"
	assert_true(saver.save(game, 1))
	var payload: Dictionary = characters.call("state", "slot-1")
	assert_true(characters.call("write", "slot-1", payload, {"last_world_id": "slot-1"}))
	var rewritten: Dictionary = characters.call("read", "slot-1")
	assert_eq(str(rewritten.get("last_world_instance_id", "")), "stable-instance")


func test_rewriting_character_does_not_turn_malformed_provenance_into_identity() -> void:
	var game := _legacy_id_game()
	assert_true(saver.save(game, 1))
	var path := str(characters.call("path_for", "slot-1"))
	var malformed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	malformed["last_world_instance_id"] = 123
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file.close()
	var fresh_characters: RefCounted = SAVE_GAME.new(TEST_DIR).call("characters")
	var payload: Dictionary = fresh_characters.call("state", "slot-1")
	assert_true(fresh_characters.call("write", "slot-1", payload,
		{"last_world_id": "slot-1"}))
	var rewritten: Dictionary = fresh_characters.call("read", "slot-1")
	assert_eq(str(rewritten.get("last_world_instance_id", "")), "",
		"a number from corrupt JSON cannot become a world-instance proof")


func test_save_character_refuses_an_empty_id_and_a_missing_game() -> void:
	var game := _legacy_id_game()
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
	var game := _legacy_id_game()
	assert_true(saver.save(game, 1))
	var path := str(characters.call("path_for", "slot-1"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data["version"] = CHARACTER_SAVE.VERSION + 1
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	assert_eq(characters.call("read", "slot-1"), {})


func test_version_two_character_remains_readable_with_legacy_escrow() -> void:
	var game := _legacy_id_game()
	assert_true(saver.save(game, 1))
	var path := str(characters.call("path_for", "slot-1"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data["version"] = 2
	# The old format already carried death-satchel escrow. Its tolerant default
	# remains valid while v3 reserves this field for durable reward rows too.
	data["satchel_escrow"] = {"death-txn": {
		"kind": "death_satchel_transfer", "status": "settled",
	}}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var read: Dictionary = characters.call("read", "slot-1")
	assert_false(read.is_empty(), "the prior character format remains readable")
	assert_true((read.get("satchel_escrow", {}) as Dictionary).has("death-txn"))


func test_version_three_character_without_world_instance_remains_readable() -> void:
	var game := _legacy_id_game()
	assert_true(saver.save(game, 1))
	var path := str(characters.call("path_for", "slot-1"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data["version"] = 3
	data.erase("last_world_instance_id")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	var read: Dictionary = characters.call("read", "slot-1")
	assert_false(read.is_empty(), "v3 predates pose provenance but remains readable")
	assert_eq(str(read.get("last_world_instance_id", "")), "",
		"missing legacy provenance is explicitly unknown")
