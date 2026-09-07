extends "res://tests/test_case.gd"

## Pure host-ledger proof for the rod-station data contract. Runtime prompts,
## visuals, and combat presentation are intentionally outside this fixture.
const WORLD_STATE := preload("res://autoload/world_state.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")
const SURGE := preload("res://scripts/world/stormwood_surge_rules.gd")
const STATIONS_PATH := "res://data/config/stormwood_rod_stations.json"

const PEER_A := 1
const PEER_B := 771240190

var world: RefCounted
var ledger: RefCounted
var stations: Array


func before_each() -> void:
	world = WORLD_STATE.new()
	ledger = WORLD_LEDGER.new(world)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(STATIONS_PATH))
	stations = data.get("stations", []) as Array


func _intent(id: String, forged: Dictionary = {}) -> Dictionary:
	var intent := {"kind": "stormwood_disable_rod", "realm": "stormwood", "id": id}
	intent.merge(forged, true)
	return intent


func _unlock(station: Dictionary) -> void:
	for flag: String in station.get("requires_flags", []) as Array:
		world.flags.set_flag(flag)
	world.flags.set_flag(str(station.guard_defeat_flag))


func test_every_exact_station_requires_its_real_guard_and_prerequisite_then_disables_once() -> void:
	assert_eq(stations.size(), 4, "the authored four-station contract is loaded")
	for raw: Variant in stations:
		# Each station needs an independent world: the two lower stations share
		# their chapter prerequisite, so one successful fixture iteration must
		# not unlock its sibling's prerequisite assertion.
		world = WORLD_STATE.new()
		ledger = WORLD_LEDGER.new(world)
		var station: Dictionary = raw
		var id := str(station.id)
		var forged: Dictionary = ledger.commit(_intent(id, {"guard_defeat_flag": str(station.guard_defeat_flag)}), PEER_A)
		assert_false(bool(forged.get("ok")), "%s ignores a client-forged guard result" % id)
		assert_eq(str(forged.get("code", "")), "locked", "%s checks its prerequisite first" % id)
		for flag: String in station.get("requires_flags", []) as Array:
			world.flags.set_flag(flag)
		var guarded: Dictionary = ledger.commit(_intent(id, {"guard_defeat_flag": "stormwood:forged:defeated"}), PEER_A)
		assert_false(bool(guarded.get("ok")), "%s remains guarded after a forged request field" % id)
		assert_eq(str(guarded.get("code", "")), "guarded")
		world.flags.set_flag(str(station.guard_defeat_flag))
		var committed: Dictionary = ledger.commit(_intent(id), PEER_A)
		assert_true(bool(committed.get("ok")), "%s disables after its real guard is defeated" % id)
		assert_true(world.flags.has(str(station.disabled_flag)))


func test_two_peers_contending_for_one_station_commit_one_disabled_flag() -> void:
	var station: Dictionary = stations[0]
	_unlock(station)
	var first: Dictionary = ledger.commit(_intent(str(station.id)), PEER_B)
	var second: Dictionary = ledger.commit(_intent(str(station.id)), PEER_A)
	assert_true(bool(first.get("ok")), "first host-serialised claimant wins")
	assert_false(bool(second.get("ok")))
	assert_eq(str(second.get("code", "")), "already_taken")
	assert_true(world.flags.has(str(station.disabled_flag)))
	assert_eq((first.delta.get("ops", []) as Array).size(), 1, "winner writes one world flag")
	assert_true((second.delta.get("ops", []) as Array).is_empty(), "loser writes no delta")


func test_saved_world_state_prevents_a_station_from_being_disabled_again() -> void:
	var station: Dictionary = stations[2]
	_unlock(station)
	assert_true(bool(ledger.commit(_intent(str(station.id)), PEER_A).get("ok")))
	var restored: RefCounted = WORLD_STATE.new()
	restored.load_data(world.save_data())
	var restored_ledger: RefCounted = WORLD_LEDGER.new(restored)
	var repeat: Dictionary = restored_ledger.commit(_intent(str(station.id)), PEER_B)
	assert_true(restored.flags.has(str(station.disabled_flag)))
	assert_false(bool(repeat.get("ok")))
	assert_eq(str(repeat.get("code", "")), "already_taken")


func test_each_disabled_station_flag_applies_its_region_surge_duration_modifier() -> void:
	var surge: RefCounted = SURGE.new()
	var building_seconds := float((surge.config.phases[1] as Dictionary).get("seconds", 0.0))
	for raw: Variant in stations:
		var station: Dictionary = raw
		var region := str(station.region_id)
		var baseline_calm: Dictionary = surge.phase_at(0.0, region, false)
		var disabled_calm: Dictionary = surge.phase_at(0.0, region, true)
		assert_eq(str(baseline_calm.phase), "calm")
		assert_eq(str(disabled_calm.phase), "calm")
		assert_true(float(disabled_calm.duration) > float(baseline_calm.duration), "%s lengthens Calm" % station.id)
		var baseline_break: Dictionary = surge.phase_at(float(baseline_calm.duration) + building_seconds + 0.1, region, false)
		var disabled_break: Dictionary = surge.phase_at(float(disabled_calm.duration) + building_seconds + 0.1, region, true)
		assert_eq(str(baseline_break.phase), "break")
		assert_eq(str(disabled_break.phase), "break")
		assert_true(float(disabled_break.duration) < float(baseline_break.duration), "%s shortens Break" % station.id)
