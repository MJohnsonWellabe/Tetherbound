extends "res://tests/test_case.gd"

## The wild spawn table, data/config/spawns.json.
##
## Every failure mode this file guards is silent at run time: a species renamed
## in one file but not the other, an evolved form quietly added to the wild
## table, a role pointing at a creature that never spawns, a cluster centred off
## the edge of the world. None of them crash. They produce a meadow with a hole
## in it — a missing creature, an unreachable one, an ambush that cannot happen —
## and nobody notices until someone walks the whole map wondering where the
## thing went.
##
## The DIRECTOR is not tested here. Per docs/decisions/D02 the suite is pure
## logic only; standing twenty-two creatures on Terrain3D is the smoke tests'
## job. This file owns the TABLE those tests and that code read.

const SPAWNS_PATH := "res://data/config/spawns.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")
const WEATHER_PATH := "res://data/config/weather.json"
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


## BAND-SPLIT. Through the same merge the game uses, not a raw file read: the
## `spawns` array now lives in `data/config/bands/<band>/spawns.json` and the
## head file carries only `respawn_seconds` and `roles`. Reading the head file
## directly here would have left every assertion below testing an empty table,
## which is the "a test that passes because the feature is absent" failure this
## repo already paid for once.
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")


func _config() -> Dictionary:
	return BAND_CONTENT.load_config(SPAWNS_PATH, "spawns")


func _weather_presets() -> Dictionary:
	var file := FileAccess.open(WEATHER_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return (parsed as Dictionary).get("presets", {}) if parsed is Dictionary else {}


func _spawns() -> Array:
	return _config().get("spawns", []) as Array


func _spawned_species() -> Array[String]:
	var out: Array[String] = []
	for entry: Variant in _spawns():
		var id := str((entry as Dictionary).get("species", ""))
		if not out.has(id):
			out.append(id)
	return out


# --- the table is well-formed ------------------------------------------------

func test_the_table_exists_and_is_not_empty() -> void:
	assert_false(_spawns().is_empty(),
		"spawns.json has no spawn table; the meadow would be empty")


func test_every_spawned_species_is_in_the_species_table() -> void:
	# The rename that breaks this is silent: the director push_errors and skips
	# the entry, and the creature is simply not in the world.
	for id: String in _spawned_species():
		assert_true(SPECIES.has(id),
			"spawns.json names '%s', which is not in species.json" % id)


func test_every_count_is_positive() -> void:
	for entry: Variant in _spawns():
		var spawn: Dictionary = entry
		assert_true(int(spawn.get("count", 0)) > 0,
			"the %s entry spawns %d creatures; zero is a deleted entry wearing a live one's clothes" % [
				str(spawn.get("species", "?")), int(spawn.get("count", 0))])


func test_every_cluster_is_inside_the_world() -> void:
	# OW5D: was symmetric (world_size / 2 on every side), which the corridor
	# cannot express -- z runs -512..7680, nowhere near symmetric. Uses the
	# same world_bounds() the bake and its own alignment guard read. A centre
	# outside it stands a creature on Terrain3D's procedural background
	# noise — ground that LOOKS real but has no collision — where place_on_ground
	# still answers and nothing errors.
	var terrain_file := FileAccess.open(TERRAIN_PATH, FileAccess.READ)
	var terrain: Dictionary = JSON.parse_string(terrain_file.get_as_text())
	var bounds := ALIGNMENT.world_bounds(terrain)

	for entry: Variant in _spawns():
		var spawn: Dictionary = entry
		var centre: Array = spawn.get("centre", [])
		assert_eq(centre.size(), 3,
			"the %s entry's centre is not an [x, y, z] triple" % str(spawn.get("species", "?")))
		if centre.size() != 3:
			continue
		var radius := float(spawn.get("radius", 0.0))
		assert_true(radius >= 0.0, "the %s entry has a negative radius" % str(spawn.get("species", "?")))
		var x := float(centre[0])
		var z := float(centre[2])
		var species := str(spawn.get("species", "?"))
		assert_true(x - radius >= float(bounds.get("min_x", -256.0)) and x + radius <= float(bounds.get("max_x", 256.0)),
			"the %s cluster's x reach [%.0f, %.0f] is outside the authored world bounds %s" % [
				species, x - radius, x + radius, str(bounds)])
		assert_true(z - radius >= float(bounds.get("min_z", -256.0)) and z + radius <= float(bounds.get("max_z", 256.0)),
			"the %s cluster's z reach [%.0f, %.0f] is outside the authored world bounds %s" % [
				species, z - radius, z + radius, str(bounds)])


# --- the roles resolve -------------------------------------------------------

func test_the_roles_resolve_to_species_that_actually_spawn() -> void:
	# The whole point of the roles block is that wild_creature()/aggressive_creature() and
	# the smoke tests never name a species. A role pointing at a creature the
	# table does not spawn is those accessors returning null forever, reported as
	# "no wild creature was spawned" by a test that is telling the truth about a lie.
	var roles: Dictionary = _config().get("roles", {}) as Dictionary
	var spawned := _spawned_species()
	for role: String in ["practice", "aggressor"]:
		var id := str(roles.get(role, ""))
		assert_ne(id, "", "spawns.json declares no '%s' role" % role)
		assert_true(spawned.has(id),
			"the '%s' role names '%s', which never spawns" % [role, id])


func test_the_practice_creature_is_peaceful_and_the_aggressor_is_not() -> void:
	# The roles carry meaning, not just names: the practice creature is the one
	# the opening walks a brand-new player up to.
	var roles: Dictionary = _config().get("roles", {}) as Dictionary
	assert_false(SPECIES.is_aggressive(str(roles.get("practice", ""))),
		"the practice creature would ambush the tutorial")
	assert_true(SPECIES.is_aggressive(str(roles.get("aggressor", ""))),
		"the aggressor role names a creature that never initiates; smoke_aggression has no subject")


func test_something_in_the_meadow_is_dangerous() -> void:
	# GAME_DESIGN.md pillar 3 wants the world to be able to come at you. A table
	# retuned to all-peaceful would pass every other test here and quietly delete
	# the ambush from the game.
	var any_aggressive := false
	for id: String in _spawned_species():
		if SPECIES.is_aggressive(id):
			any_aggressive = true
	assert_true(any_aggressive, "no spawned species is aggressive; nothing can ambush the trainer")


# --- evolved forms are not wild ----------------------------------------------

func test_no_evolved_form_spawns_wild() -> void:
	# D20: Tuskroot is only obtainable by evolving a caught Mudsnout. That is a
	# rule about the whole shape of the game — an evolution you can just walk up
	# to and catch makes evolving pointless — and it generalises: anything with
	# an `evolves_from` is somebody's reward, not part of the wild population.
	for id: String in _spawned_species():
		assert_false(SPECIES.definition(id).has("evolves_from"),
			"'%s' is an evolved form and spawns wild; evolutions are earned, not encountered (D20)" % id)


# --- respawn -----------------------------------------------------------------

func test_the_respawn_delay_is_a_real_duration() -> void:
	assert_true(float(_config().get("respawn_seconds", 0.0)) > 0.0,
		"respawn_seconds must be positive; zero would put a beaten creature back on its feet mid-faint")


# --- R5.3: spawn conditions ---------------------------------------------------
# D20 deferred a schema extension for time-of-day/weather gating to this item.
# encounter_director.gd is what actually gates a wild creature's presence
# (untested here, per D02 — this file owns the TABLE, not the director); these
# tests only guard the data these gates are built from.

func test_at_least_one_spawn_is_gated_to_night() -> void:
	# M10's own bar: at least one nocturnal creature. A table edited down to
	# zero night-gated entries would pass every other test here.
	var any_night := false
	for entry: Variant in _spawns():
		if str((entry as Dictionary).get("time", "")) == "night":
			any_night = true
	assert_true(any_night, "no spawns.json entry is gated to night; M10 wants at least one nocturnal")


func test_at_least_one_spawn_is_gated_to_weather() -> void:
	var any_weather := false
	for entry: Variant in _spawns():
		var gate: Variant = (entry as Dictionary).get("weather", [])
		if gate is Array and not (gate as Array).is_empty():
			any_weather = true
	assert_true(any_weather, "no spawns.json entry is gated to weather; M10 wants at least one weather-gated species")


func test_every_time_gate_is_day_or_night() -> void:
	for entry: Variant in _spawns():
		var spawn: Dictionary = entry
		var value := str(spawn.get("time", ""))
		if value == "":
			continue
		assert_true(value == "day" or value == "night",
			"the %s entry's time gate is '%s'; world_look.gd only distinguishes day/night" % [
				str(spawn.get("species", "?")), value])


func test_every_weather_gate_names_a_real_preset() -> void:
	# A typo here is silent at runtime: encounter_director.gd's Array.has()
	# just never matches, and the creature never spawns for any weather at all.
	var presets := _weather_presets()
	for entry: Variant in _spawns():
		var spawn: Dictionary = entry
		var gate: Variant = spawn.get("weather", [])
		if not (gate is Array):
			continue
		for name: Variant in gate as Array:
			assert_true(presets.has(str(name)),
				"the %s entry's weather gate names '%s', which is not a preset in weather.json" % [
					str(spawn.get("species", "?")), str(name)])


func test_the_practice_and_aggressor_roles_are_never_gated() -> void:
	# Both roles must always be reachable — smoke_combat/smoke_aggression have
	# no fallback subject if either is hidden by a time/weather condition the
	# opening's fixed morning/clear boot state happens not to satisfy.
	var roles: Dictionary = _config().get("roles", {}) as Dictionary
	var gated_species: Array[String] = []
	for entry: Variant in _spawns():
		var spawn: Dictionary = entry
		var has_time := str(spawn.get("time", "")) != ""
		var weather_gate: Variant = spawn.get("weather", [])
		var has_weather := weather_gate is Array and not (weather_gate as Array).is_empty()
		if has_time or has_weather:
			gated_species.append(str(spawn.get("species", "")))
	for role: String in ["practice", "aggressor"]:
		var id := str(roles.get(role, ""))
		assert_false(gated_species.has(id),
			"the '%s' role names '%s', which spawns.json gates by time/weather" % [role, id])


func test_the_nocturnal_role_resolves_to_a_night_gated_species() -> void:
	var roles: Dictionary = _config().get("roles", {}) as Dictionary
	var id := str(roles.get("nocturnal", ""))
	assert_ne(id, "", "spawns.json declares no 'nocturnal' role")
	var found := false
	for entry: Variant in _spawns():
		var spawn: Dictionary = entry
		if str(spawn.get("species", "")) == id:
			found = str(spawn.get("time", "")) == "night"
	assert_true(found, "the 'nocturnal' role names '%s', which is not gated to night" % id)


func test_the_weather_gated_role_resolves_to_a_weather_gated_species() -> void:
	var roles: Dictionary = _config().get("roles", {}) as Dictionary
	var id := str(roles.get("weather_gated", ""))
	assert_ne(id, "", "spawns.json declares no 'weather_gated' role")
	var found := false
	for entry: Variant in _spawns():
		var spawn: Dictionary = entry
		if str(spawn.get("species", "")) == id:
			var gate: Variant = spawn.get("weather", [])
			found = gate is Array and not (gate as Array).is_empty()
	assert_true(found, "the 'weather_gated' role names '%s', which carries no weather gate" % id)
