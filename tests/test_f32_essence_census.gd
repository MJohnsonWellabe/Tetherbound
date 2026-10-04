extends "res://tests/test_case.gd"

## F32#2 census: one or two attuned essence nodes per type in each live biome,
## each a registered renewable site that regrows on the configured host-day
## timer. Off-route distance is measured separately (see the F32 evidence).
const CATALOGUE := preload("res://scripts/world/essence_node_catalog.gd")
const SITES := preload("res://scripts/world/renewable_site_catalog.gd")
const REALMS := ["meadows", "water", "cloudreach", "stormwood"]

func test_one_or_two_nodes_per_type_per_live_biome() -> void:
	var data := CATALOGUE.read()
	assert_eq(CATALOGUE.validation_errors(data), [] as Array[String])
	var types := CATALOGUE.known_types()
	assert_eq(types.size(), 8, "eight creature types")
	for realm: String in REALMS:
		var counts := {}
		for node: Dictionary in CATALOGUE.nodes_for(realm, data):
			counts[node.type] = int(counts.get(node.type, 0)) + 1
		for type: String in types:
			var n := int(counts.get(type, 0))
			assert_true(n >= 1 and n <= 2, "%s has %d %s essence node(s)" % [realm, n, type])

func test_every_node_is_a_registered_site_on_the_configured_host_day_timer() -> void:
	var data := CATALOGUE.read()
	assert_eq(data.clock, "host_world_day")
	var respawn := int(data.respawn_days)
	assert_true(respawn >= 1, "configured respawn timer")
	for realm: String in REALMS:
		for node: Dictionary in CATALOGUE.nodes_for(realm, data):
			var site := SITES.by_id(realm, str(node.id))
			assert_false(site.is_empty(), str(node.id) + " is a registered renewable site")
			assert_eq(int(site.get("respawn_days", 0)), respawn, str(node.id) + " regrows on the configured timer")
			assert_true((site.get("outputs", {}) as Dictionary).has("essence_" + str(node.type)), str(node.id) + " yields its type essence")
