extends "res://tests/test_case.gd"

## MP_STATE_SEAM.md §1: `WorldState` is what happened to THIS WORLD, with no
## opinion about who is standing in it.
##
## The round trip matters more than usual here: from Wave 1 this dictionary is
## what the net harness hashes for its desync detector
## (`MP_NET_HARNESS_CONTRACT.md` §7) and what 1.C writes to world.json (D100),
## so a key that does not survive save/load is a world two peers disagree about.

const WORLD_STATE := preload("res://autoload/world_state.gd")

var world: RefCounted = null


func before_each() -> void:
	world = WORLD_STATE.new()


# --- what a fresh world is ---------------------------------------------------

func test_a_fresh_world_is_day_one_with_an_unset_clock_and_nothing_recorded() -> void:
	assert_eq(world.day, 1)
	assert_almost_eq(world.clock_elapsed_seconds, WORLD_STATE.CLOCK_UNSET, 0.0001,
		"a new world opens at the authored morning, not at hour zero")
	assert_eq(world.world_seed, 0, "0 is the authored world -- the roller is never entered")
	assert_true(world.placed_buildings.is_empty())
	assert_true(world.death_satchels.is_empty())
	assert_true(world.harvested_vegetation.is_empty())
	assert_true(world.felled_vegetation.is_empty())
	assert_ne(world.flags, null, "the world's own flag store exists from construction")


func test_advance_day_returns_the_new_day_and_moves_the_revision() -> void:
	var before: int = world.revision
	assert_eq(world.call("advance_day"), 2)
	assert_eq(world.day, 2)
	assert_true(world.revision > before, "a world mutation is something Wave 3 has to replicate")


# --- death satchels: D104's owner -------------------------------------------

func test_register_death_satchel_defaults_to_no_owner_and_the_realm_it_was_given() -> void:
	# The default is exactly what `realm_world_records.normalized()` stamps on a
	# legacy record, so a solo save written today is unchanged by D104.
	var index: int = world.call("register_death_satchel", Vector3(1.0, 2.0, 3.0))
	assert_eq(index, 0, "the caller gets the index it stashes as node metadata")
	var record: Dictionary = world.death_satchels[0]
	assert_eq(str(record.get("owner", "MISSING")), "",
		"no owner recorded is the default, not an absent key")
	assert_eq(str(record.get("realm", "")), "meadows")
	assert_eq(record.get("position"), [1.0, 2.0, 3.0])
	assert_true((record.get("state") as Array).is_empty(),
		"a freshly-registered satchel starts empty; player_death.gd fills it before every write")


func test_register_death_satchel_records_an_owner_and_a_realm_when_given_them() -> void:
	world.call("register_death_satchel", Vector3.ZERO, "character-7", "cloudreach")
	var record: Dictionary = world.death_satchels[0]
	assert_eq(str(record.get("owner", "")), "character-7")
	assert_eq(str(record.get("realm", "")), "cloudreach")


func test_each_registration_returns_its_own_index() -> void:
	assert_eq(world.call("register_death_satchel", Vector3.ZERO), 0)
	assert_eq(world.call("register_death_satchel", Vector3.ONE), 1)
	assert_eq(world.death_satchels.size(), 2)


# --- buildings: the realm is an argument, never a global read ---------------

func test_register_building_stamps_the_realm_it_was_told() -> void:
	world.call("register_building", "tent", Vector3(4.0, 0.0, 5.0), 1.5, false, "cloudreach")
	var record: Dictionary = world.placed_buildings[0]
	assert_eq(str(record.get("realm", "")), "cloudreach",
		"two peers stand in two realms from Wave 6; a record must not read one global answer")
	assert_eq(str(record.get("id", "")), "tent")
	assert_almost_eq(float(record.get("yaw_deg", 0.0)), 1.5)
	assert_false(bool(record.get("paid", true)), "a Free Build placement is recorded as unpaid")


# --- farm plots --------------------------------------------------------------

func test_farm_plot_at_grows_the_array_on_demand_and_refuses_a_negative_index() -> void:
	# A save written when farm.json listed four beds, loaded by a build that
	# lists six: the two new beds read as unworked ground, not an error.
	assert_false(world.call("farm_plot_at", 5).is_empty(), "an unreached bed is fallow, not missing")
	assert_false(world.call("farm_plot_at", -1).is_empty())
	world.call("set_farm_plot", 3, {"state": "sown", "ripe_on_day": 4})
	assert_eq(world.farm_plots.size(), 4, "set_farm_plot grew the array to fit")
	assert_eq(str(world.call("farm_plot_at", 3).get("state", "")), "sown")


# --- save / load -------------------------------------------------------------

func test_save_data_carries_the_world_half_of_the_v22_keys() -> void:
	var data: Dictionary = world.save_data()
	for key: String in ["world_id", "day", "clock_elapsed_seconds", "world_seed",
			"placed_buildings", "farm_plots", "death_satchels",
			"harvested_vegetation", "felled_vegetation", "flags", "realm_environment"]:
		assert_true(data.has(key), "world.save_data() is missing '%s'" % key)
	assert_eq(data.keys().size(), 11, "and nothing else -- got %s" % str(data.keys()))


func test_save_data_carries_no_player_key() -> void:
	# The partition's intersection is empty (D100). Anything about a trainer
	# belongs in character.json, and a world file that carried it would be a
	# world file that overwrites a friend's team.
	var data: Dictionary = world.save_data()
	for key: String in ["party", "inventory", "hotbar", "satiety", "player_pose",
			"realm", "current_realm", "realm_hearts", "realm_maps", "alpha_pins"]:
		assert_false(data.has(key), "world.save_data() must not carry '%s'" % key)


func test_save_then_load_round_trips_everything() -> void:
	world.world_id = "world-a"
	world.world_seed = 4242
	world.day = 9
	world.clock_elapsed_seconds = 137.5
	world.call("register_building", "campfire", Vector3(1.0, 0.0, 2.0), 0.25, true, "meadows")
	world.call("register_death_satchel", Vector3(3.0, 4.0, 5.0), "character-1", "meadows")
	world.call("set_farm_plot", 1, {"state": "sown", "ripe_on_day": 11})
	world.harvested_vegetation = {"trees": "AAEC"}
	world.felled_vegetation = {"trees#3": {"item": "wood", "amount": 2}}
	world.flags.set_flag("defeated_warden")
	var payload: Dictionary = world.save_data()

	var restored: RefCounted = WORLD_STATE.new()
	restored.load_data(payload)
	assert_eq(restored.world_id, "world-a")
	assert_eq(restored.world_seed, 4242)
	assert_eq(restored.day, 9)
	assert_almost_eq(restored.clock_elapsed_seconds, 137.5)
	assert_eq(restored.placed_buildings.size(), 1)
	assert_eq(str((restored.placed_buildings[0] as Dictionary).get("id", "")), "campfire")
	assert_eq(restored.death_satchels.size(), 1)
	assert_eq(str((restored.death_satchels[0] as Dictionary).get("owner", "")), "character-1")
	assert_eq(str(restored.call("farm_plot_at", 1).get("state", "")), "sown")
	assert_eq(restored.harvested_vegetation, {"trees": "AAEC"})
	assert_true(restored.felled_vegetation.has("trees#3"))
	assert_true(restored.flags.has("defeated_warden"))
	assert_eq(restored.save_data(), payload, "the whole payload survives the round trip")


func test_load_data_of_an_empty_dictionary_is_a_working_fresh_world() -> void:
	# The contract map_state.gd and progression_state.gd already give
	# save_game.gd: a missing key is a default, never a crash.
	world.day = 12
	world.flags.set_flag("defeated_warden")
	world.load_data({})
	assert_eq(world.day, 1)
	assert_almost_eq(world.clock_elapsed_seconds, WORLD_STATE.CLOCK_UNSET, 0.0001)
	assert_false(world.flags.has("defeated_warden"), "a load replaces the flag store wholesale")


func test_load_data_survives_garbage_in_every_field() -> void:
	world.load_data({
		"day": "nine", "clock_elapsed_seconds": "soon", "world_seed": [],
		"placed_buildings": 3, "farm_plots": "none", "death_satchels": {},
		"harvested_vegetation": [], "felled_vegetation": 7, "flags": "yes",
	})
	assert_eq(world.day, 1, "a garbage day falls back to day one rather than to zero")
	assert_eq(world.world_seed, 0,
		"and a garbage seed to the authored world -- `int([])` would abort the load half-done")
	assert_almost_eq(world.clock_elapsed_seconds, WORLD_STATE.CLOCK_UNSET, 0.0001)
	assert_true(world.placed_buildings.is_empty())
	assert_true(world.death_satchels.is_empty())
	assert_true(world.harvested_vegetation.is_empty())
	assert_true(world.flags.all_set().is_empty())


func test_a_nan_or_negative_clock_becomes_the_unset_sentinel() -> void:
	# A NaN would come back out of JSON as `null` and restore the world to hour
	# NaN; save_game.gd's own `_finite_clock` draws the same line.
	world.load_data({"clock_elapsed_seconds": NAN})
	assert_almost_eq(world.clock_elapsed_seconds, WORLD_STATE.CLOCK_UNSET, 0.0001)
	world.load_data({"clock_elapsed_seconds": -3.0})
	assert_almost_eq(world.clock_elapsed_seconds, WORLD_STATE.CLOCK_UNSET, 0.0001)
	world.load_data({"clock_elapsed_seconds": 0.0})
	assert_almost_eq(world.clock_elapsed_seconds, 0.0, 0.0001, "zero is a real carried clock")


func test_save_data_hands_back_copies_not_the_live_arrays() -> void:
	# The harness hashes this dictionary and 1.C writes it to disk; a caller
	# mutating what it got back must not reach into the live world.
	world.call("register_building", "tent", Vector3.ZERO)
	var data: Dictionary = world.save_data()
	(data["placed_buildings"] as Array).clear()
	assert_eq(world.placed_buildings.size(), 1, "the live registry is untouched")


# --- reset -------------------------------------------------------------------

func test_reset_empties_the_world_but_keeps_the_flag_store_object() -> void:
	# `merged_progression.gd` holds a reference to `flags`; replacing the object
	# on every New Game would leave the merged view pointing at a dead store.
	var store: RefCounted = world.flags
	world.day = 7
	world.call("register_building", "tent", Vector3.ZERO)
	world.flags.set_flag("defeated_warden")
	world.call("reset")
	assert_eq(world.day, 1)
	assert_true(world.placed_buildings.is_empty())
	assert_true(world.flags == store, "same store object")
	assert_false(world.flags.has("defeated_warden"), "emptied, not replaced")
