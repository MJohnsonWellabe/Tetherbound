extends "res://tests/test_case.gd"

## F13#3 lure (WORLD §11): each Tidewake requester points to a place, and that
## place is pinned on the local map while the chain's lead is held and its
## completion is not. Derived pins in `water_local_chains.gd`
## (`lead_map_markers`/`sync_lead_map`), never saved; the flags mirror each
## chain's `water_objectives.json` local row.

const CHAINS := preload("res://scripts/world/water_local_chains.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const MAP := preload("res://autoload/map_state.gd")

var flags: RefCounted
var data: Dictionary


func before_each() -> void:
	flags = PROGRESSION.new()
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_local_chains.json"))


func _local_objectives() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_objectives.json"))
	var out := {}
	for row: Dictionary in parsed.get("local", []):
		out[str(row.get("id", ""))] = row
	return out


func _pin(objective: String) -> Dictionary:
	for pin: Dictionary in data.get("lead_map_pins", []):
		if str(pin.objective) == objective:
			return pin
	return {}


func _dynamic_ids(map: RefCounted) -> Array:
	var ids: Array = []
	for entry: Dictionary in map.call("landmarks"):
		if bool(entry.get("dynamic", false)):
			ids.append(str(entry.id))
	ids.sort()
	return ids


func test_every_chain_has_one_pin_matching_its_objective_row() -> void:
	var objectives := _local_objectives()
	var chains := ["side_water_lantern_return", "side_water_gull_research", "side_water_cradle_care",
		"side_water_garden_records", "side_water_deep_watch_chart", "side_water_lastlight_shelter"]
	assert_eq((data.get("lead_map_pins", []) as Array).size(), chains.size(), "one pin per WORLD §11 chain")
	for chain: String in chains:
		var pin := _pin(chain)
		assert_false(pin.is_empty(), "%s has a lead pin" % chain)
		assert_true(objectives.has(chain), "%s has a local objective row" % chain)
		assert_eq(str(pin.get("lead_flag", "")), str(objectives[chain].get("revealed_by", "")), "%s pin appears with its quest-log row" % chain)
		assert_eq(str(pin.get("done_flag", "")), str(objectives[chain].get("flag_id", "")), "%s pin clears with its quest-log row" % chain)


func test_nothing_is_pinned_before_a_lead() -> void:
	assert_eq(CHAINS.lead_map_markers(flags, data).size(), 0)


func test_a_lead_pins_its_destination_until_the_chain_completes() -> void:
	var pin := _pin("side_water_lantern_return")
	flags.set_flag(str(pin.lead_flag))
	var markers := CHAINS.lead_map_markers(flags, data)
	assert_eq(markers.keys(), ["water_lead_side_water_lantern_return"])
	var at: Vector3 = markers["water_lead_side_water_lantern_return"].at
	assert_almost_eq(at.x, float(pin.at_xz[0]), 0.001)
	assert_almost_eq(at.z, float(pin.at_xz[1]), 0.001)
	flags.set_flag(str(pin.done_flag))
	assert_eq(CHAINS.lead_map_markers(flags, data).size(), 0, "completion clears the pin")


func test_sync_is_idempotent_removes_stale_pins_and_restores_after_a_map_reload() -> void:
	var map: RefCounted = MAP.new()
	flags.set_flag(str(_pin("side_water_gull_research").lead_flag))
	flags.set_flag(str(_pin("side_water_garden_records").lead_flag))
	assert_true(CHAINS.sync_lead_map(map, flags, data), "first sync adds the pins")
	var revision := int(map.get("revision"))
	assert_false(CHAINS.sync_lead_map(map, flags, data), "a repeat sync changes nothing")
	assert_eq(int(map.get("revision")), revision)
	assert_eq(_dynamic_ids(map), ["water_lead_side_water_garden_records", "water_lead_side_water_gull_research"])
	flags.set_flag(str(_pin("side_water_gull_research").done_flag))
	assert_true(CHAINS.sync_lead_map(map, flags, data), "completion removes its pin")
	assert_eq(_dynamic_ids(map), ["water_lead_side_water_garden_records"])
	var fresh: RefCounted = MAP.new()
	assert_true(CHAINS.sync_lead_map(fresh, flags, data), "a reloaded map (no dynamic markers) gets the pin back")
	assert_eq(_dynamic_ids(fresh), ["water_lead_side_water_garden_records"])


func test_sync_leaves_other_dynamic_markers_alone() -> void:
	var map: RefCounted = MAP.new()
	map.call("add_dynamic_marker", "objective", "objective", Vector3(1, 0, 2), "Main")
	CHAINS.sync_lead_map(map, flags, data)
	assert_eq(_dynamic_ids(map), ["objective"])
