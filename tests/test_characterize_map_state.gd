extends "res://tests/test_case.gd"

## STAGE B 0.E — characterization fence for autoload/map_state.gd.
##
## Pins today's behaviour. Wave 1 lane 1.B re-homed `grid_x()`/`grid_z()`/
## `origin()` off `static var`s and onto a per-instance extent, and the one
## test in this file whose expected value that CHANGED is the last one,
## `test_two_instances_can_now_hold_two_different_extents` (was
## `test_the_static_extent_is_the_same_object_across_two_instances`). 0.E wrote
## the original assertion to be changed here rather than to quietly stop being
## true; the change is the evidence the hazard is gone, not a regression.
##
## Lane 1.B also added `alpha_pins` to `save_data()`, which is why the key-set
## test below names ten keys and not the nine 0.E pinned -- see its own comment.

const MAP_STATE := preload("res://autoload/map_state.gd")
const LANDMARKS_PATH := "res://data/config/map_landmarks.json"


## The shipped landmark config, minus `starting_reveal` -- same reasoning as
## test_map_state.gd's own `_config()`: this file is about the map DATABASE
## mechanism, not the owner's "reveal the village first" seed.
func _config() -> Dictionary:
	var file := FileAccess.open(LANDMARKS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var config: Dictionary = (parsed as Dictionary).duplicate(true)
	config.erase("starting_reveal")
	return config


func _map() -> RefCounted:
	var m: RefCounted = MAP_STATE.new()
	m.configure(_config())
	return m


# --- save_data(): the exact key set -----------------------------------------

## SECOND DELIBERATE EXPECTED-VALUE CHANGE, lane 1.B: nine keys became ten.
##
## `MP_STATE_SEAM.md` §2 moved the alpha-pin set from a top-level v22 save key
## into each realm map's own `save_data()`, where the fog and the landmarks it
## is drawn beside already live -- one top-level key could only ever describe
## whichever map happened to be active, which is wrong the moment fog is per
## player and per realm. `alpha_pin_save_data()` remains as the accessor, and
## `Game.save_game()` still emits the v22 top-level `alpha_pins` key off the
## active map, so `save_game.gd` and lane 1.C see no change.
func test_save_data_has_exactly_these_ten_keys() -> void:
	var m := _map()
	var data: Dictionary = m.save_data()
	var expected := [
		"visited_b64", "grid_x", "grid_z", "cell", "origin_x", "origin_z",
		"landmarks", "dynamic_markers", "regions", "alpha_pins",
	]
	var actual: Array = data.keys()
	assert_eq(actual.size(), expected.size(),
		"save_data() key count changed -- got %s" % str(actual))
	for key in expected:
		assert_true(data.has(key), "save_data() is missing '%s'" % key)


# --- load_data(): round-trips visited_b64 / landmarks / dynamic markers / regions ---

func test_load_data_round_trips_fog_landmarks_dynamic_markers_and_regions() -> void:
	var m := _map()
	m.mark_visited(Vector3(-22.0, 0.0, -16.0))  # inside grandpa_house's discover_radius
	m.add_dynamic_marker("camp_1", "camp", Vector3(10.0, 0.0, 20.0), "My Camp")
	m.update_region(Vector3(6.0, 0.0, -22.0))  # inside grandpas_village
	var saved: Dictionary = m.save_data()
	assert_true(bool(_entry_discovered(m, "grandpa_house")), "sanity: the landmark was actually discovered")

	var loaded := _map()
	loaded.take_fog_dirty()  # consume configure()'s own full-rebuild flag
	loaded.load_data(saved)

	assert_eq(loaded.visited_bytes(), m.visited_bytes(), "fog bitfield round-trips byte for byte")
	assert_true(_entry_discovered(loaded, "grandpa_house"), "landmark discovery round-trips")
	assert_true(loaded.is_landmark_discovered("grandpa_house"))
	var markers: Array = loaded.landmarks()
	var found_marker := false
	for entry in markers:
		if str(entry.get("id", "")) == "camp_1":
			found_marker = true
			var pos: Vector2 = entry.get("position")
			assert_almost_eq(pos.x, 10.0, 0.001)
			assert_almost_eq(pos.y, 20.0, 0.001)
			assert_eq(str(entry.get("display_name", "")), "My Camp")
	assert_true(found_marker, "dynamic marker round-trips")
	var region_found := false
	for entry in loaded.regions():
		if str(entry.get("id", "")) == "grandpas_village":
			region_found = bool(entry.get("discovered", false))
	assert_true(region_found, "region discovery round-trips")


func _entry_discovered(m: RefCounted, id: String) -> bool:
	for entry in m.landmarks():
		if str(entry.get("id", "")) == id:
			return bool(entry.get("discovered", false))
	return false


# --- grid-descriptor mismatch discards fog, per §8.6a -----------------------

func test_load_data_discards_fog_when_the_saved_grid_descriptor_does_not_match() -> void:
	var m := _map()
	m.mark_visited(Vector3(-22.0, 0.0, -16.0))
	var saved: Dictionary = m.save_data()
	saved["grid_x"] = int(saved["grid_x"]) + 7  # a world resize this build no longer matches

	var loaded := _map()
	loaded.load_data(saved)

	assert_eq(loaded.discovered_fraction(), 0.0,
		"a grid_x mismatch must discard the whole visited_b64, not misread it")
	# Landmarks/regions/markers are independent of the fog grid and must
	# still load even though the fog itself was rejected.
	assert_true(loaded.is_landmark_discovered("grandpa_house"),
		"only the fog grid is discarded on a descriptor mismatch -- landmarks are untouched")


func test_load_data_with_no_descriptor_falls_back_to_the_length_only_check() -> void:
	# A save from a build that predates the grid descriptor fields. On today's
	# unresized world the length-only path is the benign case §8.6a describes.
	var m := _map()
	m.mark_visited(Vector3(-22.0, 0.0, -16.0))
	var saved: Dictionary = m.save_data()
	saved.erase("grid_x")
	saved.erase("grid_z")
	saved.erase("cell")
	saved.erase("origin_x")
	saved.erase("origin_z")

	var loaded := _map()
	loaded.load_data(saved)
	assert_eq(loaded.visited_bytes(), m.visited_bytes(),
		"no descriptor + matching byte length must still load the fog (legacy-save contract)")


# --- alpha_pin_save_data() / alpha_pin_load_data() round trip ---------------

func test_alpha_pin_round_trip_restores_the_pinned_set_and_its_markers() -> void:
	var m := _map()
	assert_true(m.pin_alpha(7, "galecrest", "Alpha Galecrest", Vector3(50.0, 0.0, -30.0), "alpha_icon"))
	assert_eq(m.alpha_pin_count(), 1)
	var saved: Array = m.alpha_pin_save_data()
	assert_eq(saved.size(), 1)
	assert_eq(int(saved[0].get("order", -1)), 7)

	var loaded := _map()
	loaded.alpha_pin_load_data(saved)
	assert_true(loaded.is_alpha_pinned(7))
	assert_eq(loaded.alpha_pin_count(), 1)
	var pins: Array = loaded.alpha_pins()
	assert_eq(str(pins[0].get("species", "")), "galecrest")
	assert_eq(str(pins[0].get("display_name", "")), "Alpha Galecrest")

	var marker_id := MAP_STATE.alpha_marker_id(7)
	var found := false
	for entry in loaded.landmarks():
		if str(entry.get("id", "")) == marker_id:
			found = true
	assert_true(found, "alpha_pin_load_data() must also rebuild the dynamic marker, not just the pin set")


func test_a_second_pin_at_the_same_order_is_a_no_op() -> void:
	var m := _map()
	assert_true(m.pin_alpha(3, "a", "A", Vector3.ZERO, "i"))
	assert_false(m.pin_alpha(3, "b", "B", Vector3(1, 0, 1), "j"), "an already-pinned order refuses a second pin")
	assert_eq(m.alpha_pin_count(), 1)


func test_unpin_alpha_removes_the_pin_and_its_marker() -> void:
	var m := _map()
	m.pin_alpha(4, "a", "A", Vector3(1.0, 0.0, 2.0), "icon")
	assert_true(m.unpin_alpha(4))
	assert_false(m.is_alpha_pinned(4))
	assert_false(m.unpin_alpha(4), "unpinning twice returns false the second time")
	var marker_id := MAP_STATE.alpha_marker_id(4)
	for entry in m.landmarks():
		assert_ne(str(entry.get("id", "")), marker_id, "unpin must remove the dynamic marker too")


# --- add_dynamic_marker / remove_dynamic_marker -----------------------------

func test_add_dynamic_marker_replaces_rather_than_stacks_on_a_repeated_id() -> void:
	var m := _map()
	m.add_dynamic_marker("objective", "flag", Vector3(1, 0, 1), "First")
	var rev_after_first: int = m.revision
	m.add_dynamic_marker("objective", "flag", Vector3(2, 0, 2), "Second")
	assert_true(m.revision > rev_after_first, "a replace still bumps revision")
	var matches := 0
	var last: Dictionary = {}
	for entry in m.landmarks():
		if str(entry.get("id", "")) == "objective":
			matches += 1
			last = entry
	assert_eq(matches, 1, "the same id must replace, never stack, a second entry")
	assert_eq(str(last.get("display_name", "")), "Second")


func test_remove_dynamic_marker_is_a_no_op_on_an_unknown_id() -> void:
	var m := _map()
	var rev_before: int = m.revision
	m.remove_dynamic_marker("never_added")
	assert_eq(m.revision, rev_before, "removing an id that was never added must not bump revision")


func test_remove_dynamic_marker_removes_it_and_bumps_revision() -> void:
	var m := _map()
	m.add_dynamic_marker("camp_1", "camp", Vector3.ZERO)
	var rev_before: int = m.revision
	m.remove_dynamic_marker("camp_1")
	assert_true(m.revision > rev_before)
	for entry in m.landmarks():
		assert_ne(str(entry.get("id", "")), "camp_1")


# --- the process-global hazard, RESOLVED by Wave 1 lane 1.B -----------------

func test_two_instances_can_now_hold_two_different_extents() -> void:
	# THE ONE DELIBERATE EXPECTED-VALUE CHANGE IN THIS FILE, made by lane 1.B
	# and predicted by lane 0.E when it wrote the original assertion.
	#
	# Until 1.B, `grid_x()`/`grid_z()`/`origin()` read three `static var`s on
	# the SCRIPT: one grid for the whole process, so every MapState necessarily
	# agreed, and `cloudreach_map_state.gd` had to override five accessors to
	# describe a differently-shaped world without touching them. The original
	# test asserted that agreement ("grid_x is process-global (static), not
	# per-instance") and was written to be changed here, not to quietly stop
	# being true.
	#
	# `MP_STATE_SEAM.md` §2 moved the extent onto the instance, because a
	# per-player map for two realms at once cannot share one grid. So: two
	# UNCONFIGURED instances still agree -- both lazily derive the same Meadows
	# extent from `world_extent.gd`, which is why nothing that never heard of
	# `set_extent()` changed -- and an instance told a different extent no
	# longer drags the other one with it. That second half is the evidence the
	# hazard is gone, and it is exactly what the old assertion forbade.
	var a := MAP_STATE.new()
	var b := MAP_STATE.new()
	assert_eq(a.grid_x(), b.grid_x(), "two unconfigured maps still derive the same default grid")
	assert_eq(a.grid_z(), b.grid_z())
	assert_eq(a.origin(), b.origin())

	var default_grid_x: int = a.grid_x()
	var default_origin: Vector2 = a.origin()
	var default_cell: float = a.cell_size()

	# Cloudreach's shape, declared the way `configure_cloudreach()` declares it.
	b.set_extent(Vector2(-1600.0, -500.0), 400, 813, 8.0)
	assert_eq(b.grid_x(), 400, "the instance told an extent reports that extent")
	assert_eq(b.grid_z(), 813)
	assert_eq(b.origin(), Vector2(-1600.0, -500.0))
	assert_almost_eq(b.cell_size(), 8.0, 0.0001)

	assert_eq(a.grid_x(), default_grid_x,
		"the OTHER instance is untouched -- this is the assertion the static version could not make")
	assert_eq(a.origin(), default_origin)
	assert_almost_eq(a.cell_size(), default_cell, 0.0001)

	# And a third, still-unconfigured instance derives the default rather than
	# inheriting whatever the last configured map happened to set.
	var c := MAP_STATE.new()
	assert_eq(c.grid_x(), default_grid_x, "a fresh map is not contaminated by a configured one")
	assert_eq(c.origin(), default_origin)
