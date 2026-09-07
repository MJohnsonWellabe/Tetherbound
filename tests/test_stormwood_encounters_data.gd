extends "res://tests/test_case.gd"

## Pure catalogue census.  This validates authored data only; it intentionally
## does not claim that a runtime has injected these entries into Stormwood.

const PATH := "res://data/config/stormwood_encounters.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const STARTERS := ["terrapup", "ripplet", "galewisp"]


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_catalogue_census_meets_the_stormwood_minimums() -> void:
	var data := _read(PATH)
	var clusters: Array = data.get("wild_clusters", [])
	assert_true(clusters.size() >= 330, "Stormwood needs at least 330 explicit wild clusters")
	var per_region := {}
	for entry: Dictionary in clusters:
		var region_id := str(entry.get("region_id", ""))
		per_region[region_id] = int(per_region.get(region_id, 0)) + 1
	for region_id: String in ["cinder_verge", "glowmoss_hollows", "conductor_run", "hollow_crown", "deepwood", "dynamo"]:
		assert_true(int(per_region.get(region_id, 0)) >= 40, region_id + " needs at least 40 explicit clusters")


func test_tables_are_replaceable_and_obey_role_and_crown_limits() -> void:
	var tables: Array = _read(PATH).get("tables", [])
	assert_eq(tables.size(), 12)
	for table: Dictionary in tables:
		assert_true(bool(table.get("replaceable", false)))
		assert_true((table.get("roles", []) as Array).size() >= 3)
		assert_false((table.get("night_role_weights", []) as Array).is_empty())
		var levels: Array = table.get("level_range", [])
		assert_eq(levels.size(), 2)
		if str(table.get("id", "")) == "crown_surge":
			assert_true(int(levels[1]) <= 40, "ordinary Crown Surge field stays at the exit-level cap")
		for role: Dictionary in table.get("roles", []):
			var species := str(role.get("placeholder_species", ""))
			assert_true(SPECIES.has(species), "missing placeholder species " + species)
			assert_false(STARTERS.has(species), "starter may not be a Stormwood wild placeholder")
			assert_false(str(role.get("replacement_point", "")).is_empty())


func test_positions_and_named_ranks_are_explicit_and_valid() -> void:
	var data := _read(PATH)
	var world := _read(WORLD_PATH)
	var regions := {}
	for region: Dictionary in world.get("regions", []):
		regions[str(region.get("id", ""))] = region.get("bounds", {})
	var ids := {}
	for cluster: Dictionary in data.get("wild_clusters", []):
		var id := str(cluster.get("id", ""))
		assert_false(id.is_empty() or ids.has(id))
		ids[id] = true
		var position: Array = cluster.get("position", [])
		assert_eq(position.size(), 3)
		var bounds: Dictionary = regions.get(str(cluster.get("region_id", "")), {})
		assert_false(bounds.is_empty())
		if position.size() == 3 and not bounds.is_empty():
			assert_between(float(position[0]), float(bounds.min_x), float(bounds.max_x))
			assert_between(float(position[2]), float(bounds.min_z), float(bounds.max_z))
	var named: Array = data.get("named_encounters", [])
	assert_eq(named.size(), 6)
	var high_ranked := 0
	for encounter: Dictionary in named:
		assert_true(bool(encounter.get("catchable", false)) and bool(encounter.get("once_only", false)))
		assert_false(str(encounter.get("behavior_profile", "")).is_empty())
		assert_true(SPECIES.has(str(encounter.get("placeholder_species", ""))))
		assert_false(str(encounter.get("replacement_point", "")).is_empty())
		if int(encounter.get("level", 0)) > 40:
			high_ranked += 1
	assert_true(high_ranked >= 3, "named encounters remain separately ranked above the ordinary Crown cap")
