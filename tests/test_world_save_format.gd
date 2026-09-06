extends "res://tests/test_case.gd"

## D100, the host-owned half: `user://worlds/<world_id>/world.json`
## (`scripts/save/world_save.gd`).
##
## Every failure here is one the owner would meet as a world that forgot what
## happened in it -- a fence that is not there on Continue, a day counter that
## went backwards, a Warden who has to be beaten twice -- or, worse, as a client
## quietly overwriting the host's world with its own replica.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const TEST_DIR := "user://test_world_save/"

var db: RefCounted = null
var saver: RefCounted = null
var worlds: RefCounted = null


func before_each() -> void:
	FIXTURE.wipe(TEST_DIR)
	db = ITEM_DB.new()
	saver = SAVE_GAME.new(TEST_DIR)
	worlds = saver.call("worlds")


func after_each() -> void:
	FIXTURE.wipe(TEST_DIR)


# --- the file exists, where D100 says it does ---------------------------------

func test_a_host_save_writes_a_world_file_at_the_partitioned_path() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	assert_true(bool(worlds.call("has", "slot-1")),
		"a slot write must produce a world file; got ids %s" % str(worlds.call("list_ids")))
	assert_eq(str(worlds.call("path_for", "slot-1")), TEST_DIR + "worlds/slot-1/world.json",
		"the path is <root>/<world_id>/world.json, so a world is one directory")


func test_the_real_saver_writes_worlds_under_the_d100_directory() -> void:
	# The scratch directory above is a test convenience; the shipped path is
	# not, and D100 names it. Nothing is written here -- this reads the path
	# a default-constructed saver would use.
	var shipped: RefCounted = SAVE_GAME.new()
	assert_eq(str((shipped.call("worlds") as RefCounted).call("path_for", "w1")),
		"user://worlds/w1/world.json")


# --- what is in it ------------------------------------------------------------

func test_the_world_file_carries_the_world_half_and_its_envelope() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = worlds.call("read", "slot-1")
	assert_false(data.is_empty(), "the world file must read back")
	for key: String in WORLD_SAVE.STATE_KEYS:
		assert_true(data.has(key), "world.json is missing state key '%s'" % key)
	assert_true(data.has("flags"), "world.json carries the world-scope flag store")
	for key: String in WORLD_SAVE.ENVELOPE_KEYS:
		assert_true(data.has(key), "world.json is missing envelope key '%s'" % key)
	assert_eq(int(data.get("version", 0)), WORLD_SAVE.VERSION,
		"the world file stamps its OWN version, not the v22 slot version")
	assert_eq(str(data.get("world_id", "")), "slot-1")


func test_the_world_file_carries_no_character_key() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = worlds.call("read", "slot-1")
	for key: String in ["party", "inventory", "hotbar", "satiety", "player_pose",
			"realm", "current_realm", "pending_realm_entry", "realm_hearts",
			"realm_maps", "map", "alpha_pins", "character_id"]:
		assert_false(data.has(key),
			"world.json must not carry the character key '%s' -- a world is not a trainer" % key)


func test_the_world_file_values_are_the_ones_the_game_held() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = worlds.call("read", "slot-1")
	assert_eq(int(data.get("day", 0)), 7)
	assert_eq(int(data.get("world_seed", 0)), 4242)
	assert_almost_eq(float(data.get("clock_elapsed_seconds", 0.0)), 512.5)
	assert_eq((data.get("placed_buildings", []) as Array).size(), 1)
	assert_eq(str(((data["placed_buildings"] as Array)[0] as Dictionary).get("id", "")), "fence")
	assert_eq((data.get("death_satchels", []) as Array).size(), 1)
	assert_eq((data.get("farm_plots", []) as Array).size(), 1)
	assert_eq((data.get("harvested_vegetation", {}) as Dictionary).size(), 1)
	assert_eq((data.get("felled_vegetation", {}) as Dictionary).size(), 1)


func test_only_world_scope_flags_land_in_the_world_file() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var data: Dictionary = worlds.call("read", "slot-1")
	var ids: Array = ((data.get("flags", {}) as Dictionary).get("flags", []) as Array)
	assert_true(ids.has("defeated_warden"),
		"a world-scope flag belongs to the world -- got %s" % str(ids))
	assert_false(ids.has("tam_tools_given"),
		"a player-scope flag must not be in the world file: it would follow the world, not the trainer")
	for id: Variant in ids:
		assert_ne(PROGRESSION_STATE.scope_of(str(id)), PROGRESSION_STATE.SCOPE_PLAYER,
			"'%s' is player-scope and must not be here" % str(id))


# --- the payload is exactly what WorldState eats ------------------------------

func test_the_state_payload_loads_straight_into_a_world_state() -> void:
	# The key names are `WorldState.save_data()`'s verbatim precisely so this
	# needs no adapter. If they ever drift, this is where it shows.
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var world: RefCounted = WORLD_STATE.new()
	world.call("load_data", worlds.call("state", "slot-1"))
	assert_eq(world.get("day"), 7)
	assert_eq(world.get("world_seed"), 4242)
	assert_almost_eq(float(world.get("clock_elapsed_seconds")), 512.5)
	assert_eq((world.get("placed_buildings") as Array).size(), 1)
	assert_eq(str(world.get("world_id")), "slot-1")
	assert_true(bool((world.get("flags") as RefCounted).call("has", "defeated_warden")))
	assert_false(bool((world.get("flags") as RefCounted).call("has", "tam_tools_given")))


# --- D100's ownership rule ----------------------------------------------------

func test_a_client_save_writes_no_world_file() -> void:
	var game := FIXTURE.populated_game(db)
	game.host = false
	assert_true(saver.save(game, 1), "a client's slot write still succeeds")
	assert_false(bool(worlds.call("has", "slot-1")),
		"a client never writes a world file (D100) -- found %s" % str(worlds.call("list_ids")))
	assert_true((worlds.call("list_ids") as Array).is_empty(),
		"and its user://worlds/ stays empty, which is what smoke_net_host_join_leave asserts")


func test_save_world_refuses_on_a_client_and_refuses_an_empty_id() -> void:
	var game := FIXTURE.populated_game(db)
	game.host = false
	assert_false(bool(saver.call("save_world", game, "anything")),
		"the explicit world writer refuses a client too, so no caller can route around the rule")
	game.host = true
	assert_false(bool(saver.call("save_world", game, "")), "an empty world id is not a world")
	assert_true(bool(saver.call("save_world", game, "explicit")))
	assert_true(bool(worlds.call("has", "explicit")))


# --- never fatal --------------------------------------------------------------

func test_a_missing_world_reads_as_nothing_to_load() -> void:
	assert_false(bool(worlds.call("has", "nobody")))
	assert_eq(worlds.call("read", "nobody"), {})
	assert_eq(worlds.call("state", "nobody"), {})
	assert_eq(worlds.call("list_ids"), [])


func test_a_corrupt_world_file_reads_as_nothing_to_load() -> void:
	DirAccess.make_dir_recursive_absolute(str(worlds.call("dir_for", "broken")))
	var file := FileAccess.open(str(worlds.call("path_for", "broken")), FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()
	assert_eq(worlds.call("read", "broken"), {},
		"a corrupt world is 'nothing to load', never a crash (D15)")


func test_a_newer_than_this_build_world_file_refuses() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var path := str(worlds.call("path_for", "slot-1"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data["version"] = WORLD_SAVE.VERSION + 1
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	assert_eq(worlds.call("read", "slot-1"), {},
		"there is nothing to migrate an unreleased future format DOWN from")


# --- envelope behaviour -------------------------------------------------------

func test_resaving_a_world_keeps_its_created_at_and_moves_last_played() -> void:
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	var first: Dictionary = worlds.call("read", "slot-1")
	game.day = 9
	assert_true(saver.save(game, 1))
	var second: Dictionary = worlds.call("read", "slot-1")
	assert_eq(str(second.get("created_at", "")), str(first.get("created_at", "X")),
		"a world is created once; playing it again does not re-create it")
	assert_eq(int(second.get("day", 0)), 9, "and the second write is the one on disk")


func test_the_slot_owns_the_world_id_so_a_new_game_does_not_overwrite_the_old_world() -> void:
	# The failure this closes: load slot 1, start a New Game, save to slot 2.
	# A saver that trusted whatever id was left on the live state would have
	# written slot 2's brand-new world over slot 1's finished one.
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 1))
	assert_eq(str(game.world.world_id), "slot-1", "the slot stamps its id onto the live world")
	assert_true(saver.save(game, 2))
	assert_eq(str(game.world.world_id), "slot-2")
	assert_true(bool(worlds.call("has", "slot-1")), "and slot 1's world is still there")
	assert_true(bool(worlds.call("has", "slot-2")))
	assert_eq(worlds.call("list_ids"), ["slot-1", "slot-2"])


# --- a scratch write is not a save of record ----------------------------------

func test_a_scratch_save_writes_no_world_no_character_and_renames_nobody() -> void:
	# `tools/net/peer_runner.gd` saves into a scratch slot on every heartbeat,
	# on every peer, only to hash the bytes back. Before this was gated, that
	# probe minted a world and a character named after the scratch slot and
	# stamped that id onto the live trainer -- which the peer registry then
	# advertised to the whole session.
	var game := FIXTURE.populated_game(db)
	assert_true(saver.save(game, 4, false), "the slot file is still written")
	assert_true(FileAccess.file_exists(str(saver.slot_path(4))))
	assert_eq(worlds.call("list_ids"), [], "and no world file")
	assert_eq((saver.call("characters") as RefCounted).call("list_ids"), [],
		"and no character file")
	assert_eq(str(game.world.world_id), "", "and nothing was renamed")
	assert_eq(str(game.local.character_id), "")
