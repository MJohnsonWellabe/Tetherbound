extends "res://tests/test_case.gd"

## D100: **the union of the two new key sets equals the v22 key set, and their
## intersection is empty.** Key coverage is a test, not a claim.
##
## The claim is easy to state and easy to fake. Two things make this test real
## rather than a restatement of a table:
##
##   1. it asserts against the keys `save_game.gd::snapshot()` ACTUALLY produces
##      for a populated game, not against a hand-written list of what v22 is
##      supposed to contain -- so a v23 key added tomorrow and partitioned
##      nowhere fails here;
##   2. the coverage claim is proved by ROUND TRIP.
##      `merge(partition_world(v22), partition_character(v22))` must equal the
##      original dictionary. A key that quietly failed to cross the split cannot
##      survive that, and neither can a key whose VALUE was mangled on the way.
##
## Three v22 keys are not owned by one half, and each is named explicitly rather
## than quietly excluded:
##
##   * `version` -- each file carries its own (D100's table says "both"), so it
##     is the file's key and not a partitioned one;
##   * `progression` -- the one key that SPLITS, by flag scope, into the world
##     file's `flags` and the character file's `flags`;
##   * `map` and `alpha_pins` -- DERIVED on merge from the character half's
##     `realm_maps`, which already carries both. Storing them a second time is
##     what an eleventh top-level key looks like, and that is how the world
##     half's own coverage test got broken once already.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")
const CHARACTER_SAVE := preload("res://scripts/save/character_save.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")

const TEST_DIR := "user://test_split_coverage/"

## The v22 key that splits by scope, and the two that are rebuilt from
## `realm_maps` rather than stored twice.
const SPLIT_KEY := "progression"
const DERIVED_KEYS: Array[String] = ["map", "alpha_pins"]
## Each file carries its own `version`; it partitions to neither half.
const FILE_KEY := "version"

var db: RefCounted = null
var saver: RefCounted = null


func before_each() -> void:
	FIXTURE.wipe(TEST_DIR)
	db = ITEM_DB.new()
	saver = SAVE_GAME.new(TEST_DIR)


func after_each() -> void:
	FIXTURE.wipe(TEST_DIR)


func _v22() -> Dictionary:
	return saver.call("snapshot", FIXTURE.populated_game(db))


func _sorted(values: Array) -> Array:
	var out := values.duplicate()
	out.sort()
	return out


# --- union and intersection ---------------------------------------------------

func test_every_v22_key_is_owned_by_exactly_one_half() -> void:
	var v22 := _v22()
	assert_true(v22.size() >= 20, "the fixture produced a real v22 dictionary (%d keys)" % v22.size())
	var world: Array = WORLD_SAVE.STATE_KEYS
	var character: Array = CHARACTER_SAVE.STATE_KEYS
	var unowned: Array = []
	var doubly_owned: Array = []
	for key: String in v22.keys():
		if key == FILE_KEY or key == SPLIT_KEY or DERIVED_KEYS.has(key):
			continue
		var owners := 0
		if world.has(key):
			owners += 1
		# `current_realm` is the one v22 key the character half RENAMES, so it
		# is matched by its new name.
		if character.has(key) or key == "current_realm":
			owners += 1
		if owners == 0:
			unowned.append(key)
		elif owners > 1:
			doubly_owned.append(key)
	assert_eq(unowned, [],
		"these v22 keys are partitioned into neither half: %s" % str(unowned))
	assert_eq(doubly_owned, [],
		"the intersection of the two halves must be empty; these are in both: %s" % str(doubly_owned))


func test_the_two_halves_share_no_state_key() -> void:
	var shared: Array = []
	for key: String in CHARACTER_SAVE.STATE_KEYS:
		if (WORLD_SAVE.STATE_KEYS as Array).has(key):
			shared.append(key)
	assert_eq(shared, [], "intersection must be empty, got %s" % str(shared))


func test_the_world_half_includes_the_v23_realm_environment() -> void:
	# `tests/test_world_state.gd::test_save_data_carries_the_world_half_of_the_v22_keys`
	# pins `WorldState.save_data()` at eleven keys: the nine below plus
	# `world_id` (the file's identity) and `flags` (the split key's world half).
	# This asserts the SAVER agrees with the STATE object, so the two cannot
	# drift into writing different world files.
	assert_eq((WORLD_SAVE.STATE_KEYS as Array).size(), 9,
		"got %s" % str(WORLD_SAVE.STATE_KEYS))
	assert_true(WORLD_SAVE.STATE_KEYS.has("realm_environment"), "the host world owns persisted weather")
	var partitioned: Dictionary = WORLD_SAVE.partition(_v22())
	assert_eq(_sorted(partitioned.keys()),
		_sorted((WORLD_SAVE.STATE_KEYS as Array) + ["flags"]),
		"the partition produces exactly the world half plus its flag store")


# --- the round trip, which is the real proof ----------------------------------

func test_partitioning_and_merging_a_v22_dictionary_is_lossless() -> void:
	var v22 := _v22()
	var world: Dictionary = WORLD_SAVE.partition(v22)
	var character: Dictionary = CHARACTER_SAVE.partition(v22)
	var rebuilt: Dictionary = CHARACTER_SAVE.merge(world, character, SAVE_GAME.VERSION)

	assert_eq(_sorted(rebuilt.keys()), _sorted(v22.keys()),
		"the merged dictionary must have exactly the v22 key set")
	var differing: Array = []
	for key: String in v22.keys():
		if key == SPLIT_KEY:
			# The flag list is reassembled world-first, so compare as sets.
			var before: Array = _sorted((v22[key] as Dictionary).get("flags", []) as Array)
			var after: Array = _sorted((rebuilt[key] as Dictionary).get("flags", []) as Array)
			if before != after:
				differing.append("%s (%s vs %s)" % [key, str(before), str(after)])
			continue
		if rebuilt[key] != v22[key]:
			differing.append(key)
	assert_eq(differing, [],
		"these keys did not survive the split intact: %s" % str(differing))


func test_a_flag_survives_the_split_on_whichever_side_it_belongs() -> void:
	var v22 := _v22()
	var world: Dictionary = WORLD_SAVE.partition(v22)
	var character: Dictionary = CHARACTER_SAVE.partition(v22)
	var world_ids: Array = (world["flags"] as Dictionary)["flags"]
	var player_ids: Array = (character["flags"] as Dictionary)["flags"]
	assert_true(world_ids.has("defeated_warden"))
	assert_true(player_ids.has("tam_tools_given"))
	assert_eq(world_ids.size() + player_ids.size(),
		((v22[SPLIT_KEY] as Dictionary)["flags"] as Array).size(),
		"no flag is dropped and none is duplicated across the two stores")


func test_the_derived_keys_come_back_from_the_realm_maps_and_not_from_thin_air() -> void:
	var v22 := _v22()
	assert_false((v22["map"] as Dictionary).is_empty(),
		"the fixture walked somewhere, so there is a real map to lose")
	var world: Dictionary = WORLD_SAVE.partition(v22)
	var character: Dictionary = CHARACTER_SAVE.partition(v22)
	for key: String in DERIVED_KEYS:
		assert_false(character.has(key),
			"'%s' is derived, not stored -- two copies of one value drift apart" % key)
		assert_false(world.has(key), "'%s' is not the world's either" % key)
	var rebuilt: Dictionary = CHARACTER_SAVE.merge(world, character, SAVE_GAME.VERSION)
	assert_eq(rebuilt["map"], v22["map"],
		"the active realm's map is rebuilt from realm_maps[realm]")
	assert_eq(rebuilt["alpha_pins"], v22["alpha_pins"])


func test_the_round_trip_holds_for_a_trainer_standing_in_the_other_realm() -> void:
	# The derivation reads `realm_maps[realm]`, so the realm being anything but
	# the default is the case that would catch a hard-coded "meadows".
	var game := FIXTURE.populated_game(db)
	game.set_realm("cloudreach")
	var v22: Dictionary = saver.call("snapshot", game)
	assert_ne(v22["map"], (v22["realm_maps"] as Dictionary)["meadows"],
		"the two realms' maps differ, so reading the wrong one is a visible failure")
	var rebuilt: Dictionary = CHARACTER_SAVE.merge(
		WORLD_SAVE.partition(v22), CHARACTER_SAVE.partition(v22), SAVE_GAME.VERSION)
	assert_eq(str(rebuilt["current_realm"]), "cloudreach")
	assert_eq(rebuilt["map"], v22["map"])
	assert_eq(rebuilt["alpha_pins"], v22["alpha_pins"])


func test_an_empty_dictionary_partitions_and_merges_without_a_crash() -> void:
	# Never fatal, the same rule every loader in this project follows.
	var world: Dictionary = WORLD_SAVE.partition({})
	var character: Dictionary = CHARACTER_SAVE.partition({})
	assert_eq((world["flags"] as Dictionary)["flags"], [])
	assert_eq((character["flags"] as Dictionary)["flags"], [])
	var rebuilt: Dictionary = CHARACTER_SAVE.merge(world, character, SAVE_GAME.VERSION)
	assert_eq(int(rebuilt["version"]), SAVE_GAME.VERSION)
	assert_eq(str(rebuilt["current_realm"]), "meadows")
	assert_eq(rebuilt["map"], {})
	assert_eq(rebuilt["alpha_pins"], [])


func test_garbage_in_the_progression_payload_does_not_abort_the_partition() -> void:
	# 1.B's handover: `int(<whatever arrived>)` is not a coercion in GDScript,
	# and a partition that aborted halfway would write a world file with the
	# day in it and nothing else.
	for junk: Variant in [[], 7, "flags", null, {"flags": "not-an-array"}, {"flags": [1, "", null]}]:
		var v22 := _v22()
		v22["progression"] = junk
		var world: Dictionary = WORLD_SAVE.partition(v22)
		var character: Dictionary = CHARACTER_SAVE.partition(v22)
		assert_eq(_sorted(world.keys()), _sorted((WORLD_SAVE.STATE_KEYS as Array) + ["flags"]),
			"the world half is complete even with progression = %s" % str(junk))
		assert_true(character.has("party"),
			"and so is the character half, with progression = %s" % str(junk))
