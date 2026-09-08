extends "res://tests/test_case.gd"
const DIRECTOR := preload("res://scripts/combat/water_encounter_director.gd")

class FixtureWild extends CharacterBody3D:
	var display_name := ""
	var instance: RefCounted = null

class FixtureDirector extends "res://scripts/combat/water_encounter_director.gd":
	var fixture_bodies: Array[FixtureWild] = []

	func occupied_positions() -> Array[Vector3]:
		return [Vector3.ZERO]

	func _flags_hold(_flags: Array) -> bool:
		return true

	func world_seed() -> int:
		return 404

	func _once_cleared(_once_id: String) -> bool:
		return false

	func spawn_wild(_species: String, _spot: Vector3, opts: Dictionary = {}) -> Node3D:
		var body := FixtureWild.new()
		body.name = str(opts.get("name", "FixtureWild"))
		fixture_bodies.append(body)
		return body

func test_two_islands_each_keep_their_nearest_population_budget() -> void:
	var sites: Array = []
	for i in 20:
		sites.append({"id": "west_%02d" % i, "position": [i, 0, 0], "count": 1})
		sites.append({"id": "east_%02d" % i, "position": [2000+i, 0, 0], "count": 1})
	var peers: Array[Vector3] = [Vector3.ZERO, Vector3(2000,0,0)]
	var selected := DIRECTOR.select_sites(sites, peers, 100, 16)
	assert_eq(selected.size(), 32)
	assert_true(selected.has("west_00"))
	assert_true(selected.has("east_00"))
	assert_false(selected.has("west_16"))
	assert_false(selected.has("east_16"))
	peers.reverse()
	assert_eq(DIRECTOR.select_sites(sites, peers, 100, 16), selected)
func test_overlapping_peers_do_not_duplicate_sites_and_empty_world_is_empty() -> void:
	var sites: Array = [{"id":"shared", "position":[0,0,0],"count":2}]
	var peers: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
	assert_eq(DIRECTOR.select_sites(sites, peers, 100, 16).size(), 1)
	assert_eq(DIRECTOR.select_sites(sites, peers, 100, 1).size(), 0)
	var nobody: Array[Vector3] = []
	assert_true(DIRECTOR.select_sites(sites, nobody, 100, 16).is_empty())


func test_water_spawn_path_clears_only_ordinary_road_creatures_from_player() -> void:
	var director := FixtureDirector.new()
	var player := CharacterBody3D.new()
	director._player = player
	director.chapter = {"encounter_tables": [{"id": "fixture", "selection_key": "fixture",
		"entries": [{"placeholder_species": "brooktail", "weight": 1}],
		"level_range": [1, 1]}]}
	director.encounter_config = {
		"activation_distance_m": 100.0,
		"active_wild_cap_per_peer": 16,
		"wild_respawn_seconds": 240.0,
		"behavior_profiles": {"scout": {}},
		"wild_sites": [
			{"id": "road", "table_id": "fixture", "position": [0, 0, 0], "count": 1,
				"radius_m": 3.0, "_why_road_visibility_0907": "fixture"},
			{"id": "ordinary", "table_id": "fixture", "position": [10, 0, 0], "count": 1,
				"radius_m": 3.0},
			{"id": "named", "table_id": "fixture", "position": [20, 0, 0], "count": 1,
				"radius_m": 3.0, "named_replacement_id": "named_fixture",
				"_why_road_visibility_0907": "named encounters remain physical"},
		],
		"named_encounters": [{"id": "named_fixture", "species": "brooktail",
			"replaces_wild_site_id": "named", "trainer_owned": false, "catchable": true,
			"position": [20, 0, 0], "completion_flag": "caught_named_fixture"}],
	}
	director._spawn_available_sites()
	var by_name: Dictionary = {}
	for body: FixtureWild in director.fixture_bodies:
		by_name[str(body.name)] = body
	assert_eq(by_name.size(), 3, "the production Water admission loop spawned every fixture")
	var road := by_name.road_0 as FixtureWild
	assert_true(road.get_collision_exceptions().has(player),
		"ordinary ROAD ecology cannot body-block the player corridor")
	assert_true(player.get_collision_exceptions().has(road),
		"the player carries the reciprocal ROAD ecology exception")
	assert_eq(road.collision_layer, 1,
		"ROAD ecology keeps its ordinary collision layer")
	assert_eq(road.collision_mask, 1,
		"ROAD ecology keeps collisions with terrain and other gameplay bodies")
	assert_false((by_name.ordinary_0 as FixtureWild).get_collision_exceptions().has(player),
		"ordinary non-ROAD ecology keeps physical player collision")
	assert_false((by_name.named_fixture as FixtureWild).get_collision_exceptions().has(player),
		"named encounters remain physical even if malformed with ROAD metadata")
	for body: FixtureWild in director.fixture_bodies:
		body.free()
	player.free()
	director.free()
