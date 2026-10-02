extends "res://tests/test_case.gd"

## Pure authored-data census. Runtime inclusion is covered by
## test_stormwood_encounter_catalogue.gd.

const PATH := "res://data/config/stormwood_encounters.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const POLICY := preload("res://scripts/creatures/level_curve_policy.gd")
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
	var live := _read(PATH)
	var candidate := POLICY.config()
	assert_true(candidate.get("runtime_enabled") is bool)
	assert_eq(candidate.get("runtime_enabled"), true)
	assert_eq(POLICY.apply(PATH, live), live)
	assert_eq(POLICY.apply(PATH, live, true, candidate), live, "the shipped table already carries RD-10")
	_assert_tables(live, [48, 50], "live RD-10")


func test_repeated_manifest_preserves_roles_and_pins_crown_surge_at_50() -> void:
	var live := _read(PATH)
	var before := live.duplicate(true)
	var candidate := POLICY.config()
	assert_eq(candidate.get("runtime_enabled"), true)
	for activation: Variant in [false, 1, "true"]:
		assert_eq(POLICY.apply(PATH, live, activation, candidate), before, "activation must be a literal true boolean")
	var next := POLICY.apply(PATH, live, true, candidate)
	assert_false(next.is_empty(), "the manifest validates its exact live inputs")
	_assert_tables(next, [48, 50], "repeat RD-10 application")
	assert_eq(live, before, "a candidate projection cannot relevel the production dictionary")
	var live_tables: Array = live.get("tables", [])
	var next_tables: Array = next.get("tables", [])
	assert_eq(next_tables.size(), live_tables.size())
	for index in mini(live_tables.size(), next_tables.size()):
		var actual: Dictionary = next_tables[index].duplicate(true)
		var expected: Dictionary = live_tables[index].duplicate(true)
		actual.erase("level_range")
		expected.erase("level_range")
		assert_eq(actual, expected, "table identities, roles, clocks and replacement data survive projection")
	assert_eq(POLICY.config().get("runtime_enabled"), true, "shipping data remains active")


func _assert_tables(data: Dictionary, crown_band: Array, context: String) -> void:
	var tables: Array = data.get("tables", [])
	assert_eq(tables.size(), 12)
	var crown_count := 0
	for table: Dictionary in tables:
		assert_true(bool(table.get("replaceable", false)))
		assert_true((table.get("roles", []) as Array).size() >= 3)
		# Owner ruling: Stormwood has no day or night, so a table is one
		# always-on list. A night variant would hide roles behind a clock the
		# player never sees.
		assert_false(table.has("night_role_weights"), str(table.get("id", "")) + " must not carry a night table")
		var levels: Array = table.get("level_range", [])
		assert_eq(levels.size(), 2)
		if str(table.get("id", "")) == "crown_surge":
			crown_count += 1
			for index in mini(levels.size(), crown_band.size()):
				assert_true(levels[index] is int or levels[index] is float)
				if levels[index] is int or levels[index] is float:
					assert_true(is_finite(float(levels[index])) and float(levels[index]) == floorf(float(levels[index])))
					assert_eq(float(levels[index]), float(crown_band[index]), context + " pins the exact Crown Surge envelope")
		for role: Dictionary in table.get("roles", []):
			var species := str(role.get("placeholder_species", ""))
			assert_true(SPECIES.has(species), "missing placeholder species " + species)
			assert_false(STARTERS.has(species), "starter may not be a Stormwood wild placeholder")
			assert_false(str(role.get("replacement_point", "")).is_empty())
	assert_eq(crown_count, 1, "both views retain exactly one Crown Surge table")


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
