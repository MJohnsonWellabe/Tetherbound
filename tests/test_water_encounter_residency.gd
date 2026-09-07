extends "res://tests/test_case.gd"
const DIRECTOR := preload("res://scripts/combat/water_encounter_director.gd")
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
