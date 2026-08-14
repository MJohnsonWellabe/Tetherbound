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
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func _config() -> Dictionary:
	var file := FileAccess.open(SPAWNS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


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
	# The playground is world_size metres on a side, centred on the origin. A
	# centre outside it stands a creature on Terrain3D's procedural background
	# noise — ground that LOOKS real but has no collision — where place_on_ground
	# still answers and nothing errors.
	var terrain_file := FileAccess.open(TERRAIN_PATH, FileAccess.READ)
	var terrain: Dictionary = JSON.parse_string(terrain_file.get_as_text())
	var half := float(terrain.get("world_size", 512)) / 2.0

	for entry: Variant in _spawns():
		var spawn: Dictionary = entry
		var centre: Array = spawn.get("centre", [])
		assert_eq(centre.size(), 3,
			"the %s entry's centre is not an [x, y, z] triple" % str(spawn.get("species", "?")))
		if centre.size() != 3:
			continue
		var radius := float(spawn.get("radius", 0.0))
		assert_true(radius >= 0.0, "the %s entry has a negative radius" % str(spawn.get("species", "?")))
		for axis: int in [0, 2]:
			var reach := absf(float(centre[axis])) + radius
			assert_true(reach <= half,
				"the %s cluster reaches %.0fm from the origin; the world ends at %.0fm" % [
					str(spawn.get("species", "?")), reach, half])


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
