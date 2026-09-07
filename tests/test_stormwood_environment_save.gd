extends "res://tests/test_case.gd"

## Stormwood's weather clock is world state: it has to migrate from the v22
## slot shape, survive the host's late-join snapshot, and never turn malformed
## disk/network input into an invented weather state.

const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const WORLD_SAVE := preload("res://scripts/save/world_save.gd")
const WORLD_STATE := preload("res://autoload/world_state.gd")


func test_v22_migration_adds_an_empty_environment_without_mutating_legacy_payload() -> void:
	var legacy := {
		"version": 22,
		"day": 6,
		"clock_elapsed_seconds": 531.25,
		"world_seed": 451,
		"placed_buildings": [{"id": "campfire", "realm": "meadows"}],
		"progression": {"flags": ["stormwood:entered"]},
	}
	var saver := SAVE_GAME.new()
	var migrated: Dictionary = saver._migrate_to_current(legacy, 22, 1)

	assert_eq(int(migrated.get("version", 0)), SAVE_GAME.VERSION,
		"a v22 save reaches the current v23 format")
	assert_eq(migrated.get("realm_environment"), {},
		"a pre-weather save starts no realm weather cycle")
	assert_eq(float(migrated.get("clock_elapsed_seconds", -2.0)), 531.25,
		"v22's carried clock is preserved rather than reset with weather")
	assert_eq(migrated.get("placed_buildings"), legacy.get("placed_buildings"),
		"the migration only adds the v23 field")
	assert_false(legacy.has("realm_environment"),
		"migration duplicates the legacy payload instead of back-writing it")
	assert_eq(int(legacy.get("version", 0)), 22,
		"the source remains a v22 document")


func test_world_state_snapshot_preserves_nested_environment_for_a_late_joiner() -> void:
	var host := WORLD_STATE.new()
	host.world_id = "stormwood-host"
	host.day = 8
	host.realm_environment = {
		"stormwood": {
			"schema_version": 1,
			"elapsed": 187.5,
			"surge": {"phase": "rising", "strikes": 3},
		},
		"cloudreach": {"wind": 0.25},
	}
	var snapshot: Dictionary = host.save_data()

	# The host continues simulating after it has sent this snapshot. A joiner
	# must receive the sent state, not an alias to the host's mutable state.
	(host.realm_environment["stormwood"] as Dictionary)["elapsed"] = 999.0
	var joiner := WORLD_STATE.new()
	joiner.load_data(snapshot)
	(snapshot["realm_environment"] as Dictionary)["cloudreach"] = {"wind": 0.99}

	var storm: Dictionary = joiner.realm_environment.get("stormwood", {})
	assert_eq(joiner.world_id, "stormwood-host")
	assert_eq(joiner.day, 8)
	assert_almost_eq(float(storm.get("elapsed", -1.0)), 187.5, 0.0001,
		"the late joiner receives the host state at snapshot time")
	assert_eq((storm.get("surge", {}) as Dictionary).get("strikes"), 3,
		"nested environment state survives WorldState.save_data/load_data")
	assert_almost_eq(float((joiner.realm_environment.get("cloudreach", {}) as Dictionary).get("wind", -1.0)), 0.25, 0.0001,
		"the joiner owns a deep copy of the received snapshot")


func test_world_save_partition_keeps_environment_in_the_world_half() -> void:
	var world := WORLD_STATE.new()
	world.realm_environment = {"stormwood": {"elapsed": 44.0, "schema_version": 1}}
	var payload: Dictionary = WORLD_SAVE.partition(world.save_data())
	assert_true(payload.has("realm_environment"),
		"the split world file owns realm environment state")
	assert_eq(payload.get("realm_environment"), world.realm_environment)
	(world.realm_environment["stormwood"] as Dictionary)["elapsed"] = 45.0
	assert_almost_eq(float(((payload.get("realm_environment", {}) as Dictionary).get("stormwood", {}) as Dictionary).get("elapsed", -1.0)), 44.0, 0.0001,
		"partitioning does not retain a mutable alias to the host world")


func test_reset_and_malformed_environment_return_to_empty_state() -> void:
	var world := WORLD_STATE.new()
	world.realm_environment = {"stormwood": {"elapsed": 12.0}}
	world.reset()
	assert_eq(world.realm_environment, {}, "a new game starts without an inherited Stormwood surge")

	world.realm_environment = {"stormwood": {"elapsed": 12.0}}
	world.load_data({"realm_environment": ["not", "a", "dictionary"]})
	assert_eq(world.realm_environment, {}, "an array payload is rejected safely")

	world.realm_environment = {"stormwood": {"elapsed": 12.0}}
	world.load_data({"realm_environment": "stormwood"})
	assert_eq(world.realm_environment, {}, "a scalar payload is rejected safely")
