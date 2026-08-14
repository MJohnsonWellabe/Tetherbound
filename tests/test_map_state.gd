extends "res://tests/test_case.gd"

## D33's map database — autoload/map_state.gd.
##
## Every failure here is one the player would meet as a lying map: fog that
## re-hides itself, a landmark that never lights up when walked past, a
## save/load that forgets which corner of the meadow was already explored,
## or — worst — a discovery that quietly reverses. None of it crashes; it
## just makes the minimap a thing the player learns not to trust.
##
## Runs against the real data/config/map_landmarks.json rather than a
## fixture, the same way test_inventory.gd runs against the real items.json:
## a landmark renamed in the data file should fail here, not in the menu.

const MAP_STATE := preload("res://autoload/map_state.gd")
const LANDMARKS_PATH := "res://data/config/map_landmarks.json"

var map: RefCounted = null


func _config() -> Dictionary:
	var file := FileAccess.open(LANDMARKS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func before_each() -> void:
	map = MAP_STATE.new()
	map.configure(_config())


func _entry(id: String) -> Dictionary:
	for entry in map.landmarks():
		if str(entry.get("id", "")) == id:
			return entry
	return {}


# --- fresh state -------------------------------------------------------

func test_fresh_state_has_nothing_discovered() -> void:
	assert_almost_eq(map.discovered_fraction(), 0.0)
	assert_false(map.is_discovered(Vector3(0.0, 0.0, 0.0)))
	for entry in map.landmarks():
		assert_false(bool(entry.get("discovered", false)),
			"'%s' must not start discovered" % str(entry.get("id")))


# --- mark_visited: fog reveal --------------------------------------------

func test_mark_visited_reveals_a_plausible_area_and_returns_true() -> void:
	# A point far from every landmark, so this test is only about the fog.
	var point := Vector3(100.0, 0.0, 100.0)
	var before: int = map.revision
	var changed: bool = map.mark_visited(point)

	assert_true(changed, "the first visit to fresh ground must report a change")
	assert_true(map.revision > before, "a real reveal must bump revision")

	# pi * 45^2 / 16 (cell area) ~= 397.6 cells; a generous band around it
	# catches a badly wrong radius or an off-by-one in the cell math without
	# being pinned to the exact discretisation.
	var revealed := int(round(map.discovered_fraction() * float(MAP_STATE.GRID * MAP_STATE.GRID)))
	assert_between(float(revealed), 350.0, 450.0,
		"revealed cell count %d is not plausible for a %.0fm radius" % [revealed, map.reveal_radius])


func test_repeating_mark_visited_at_the_same_spot_changes_nothing() -> void:
	var point := Vector3(100.0, 0.0, 100.0)
	map.mark_visited(point)
	var after_first: int = map.revision

	var changed_again: bool = map.mark_visited(point)
	assert_false(changed_again, "revisiting already-fogged-clear ground must report no change")
	assert_eq(map.revision, after_first, "a no-op visit must not bump revision")


# --- is_discovered ---------------------------------------------------------

func test_is_discovered_is_true_near_a_mark_and_false_far_away() -> void:
	var point := Vector3(100.0, 0.0, 100.0)
	map.mark_visited(point)

	assert_true(map.is_discovered(point))
	assert_false(map.is_discovered(Vector3(point.x, 0.0, point.z + 100.0)),
		"100m away from a 45m reveal radius must still be fogged")


func test_is_discovered_is_safe_out_of_bounds() -> void:
	assert_false(map.is_discovered(Vector3(300.0, 0.0, 300.0)))
	assert_false(map.is_discovered(Vector3(-300.0, 0.0, -300.0)))
	assert_false(map.is_discovered(Vector3(300.0, 0.0, -300.0)))


# --- revision ------------------------------------------------------------

func test_revision_bumps_exactly_on_real_change_and_not_on_repeats() -> void:
	var r0: int = map.revision
	map.mark_visited(Vector3(100.0, 0.0, 100.0))
	var r1: int = map.revision
	map.mark_visited(Vector3(100.0, 0.0, 100.0))
	var r2: int = map.revision
	map.discover_landmark("village")
	var r3: int = map.revision
	map.discover_landmark("village")
	var r4: int = map.revision

	assert_true(r1 > r0, "a real fog reveal must bump revision")
	assert_eq(r2, r1, "a repeated identical visit must not bump revision")
	assert_true(r3 > r2, "a fresh landmark discovery must bump revision")
	assert_eq(r4, r3, "rediscovering an already-discovered landmark must not bump revision")


# --- landmark auto-discovery -----------------------------------------------

func test_mark_visited_discovers_a_nearby_landmark_but_not_a_distant_one() -> void:
	assert_false(map.is_landmark_discovered("village"))
	assert_false(map.is_landmark_discovered("stronghold"))

	map.mark_visited(Vector3(10.0, 0.0, -10.0))

	assert_true(map.is_landmark_discovered("village"),
		"standing on the village must discover it")
	assert_false(map.is_landmark_discovered("stronghold"),
		"the far-off stronghold must not be discovered by walking the village")


func test_silhouette_flag_survives_into_landmarks_before_and_after_discovery() -> void:
	var before := _entry("stronghold")
	assert_false(before.is_empty(), "stronghold must be listed even before discovery")
	assert_true(bool(before.get("silhouette", false)))
	assert_false(bool(before.get("discovered", false)))

	assert_true(map.discover_landmark("stronghold"))
	var after := _entry("stronghold")
	assert_true(bool(after.get("silhouette", false)), "silhouette must not disappear on discovery")
	assert_true(bool(after.get("discovered", false)))


func test_discover_landmark_refuses_unknown_ids_and_repeats() -> void:
	assert_false(map.discover_landmark("not_a_real_landmark"))
	assert_true(map.discover_landmark("village"))
	assert_false(map.discover_landmark("village"), "discovering twice must report no change")


# --- dynamic markers -------------------------------------------------------

func test_dynamic_markers_add_replace_and_remove() -> void:
	assert_eq(map.objective_marker(), {})

	map.add_dynamic_marker("objective", "flag", Vector3(5.0, 0.0, 6.0))
	var obj: Dictionary = map.objective_marker()
	assert_eq(str(obj.get("id")), "objective")
	assert_eq(obj.get("icon"), "flag")
	assert_eq(obj.get("position"), Vector2(5.0, 6.0))
	assert_true(bool(obj.get("dynamic")))

	# Same id replaces rather than stacking a second marker.
	map.add_dynamic_marker("objective", "flag2", Vector3(9.0, 0.0, -3.0))
	var replaced: Dictionary = map.objective_marker()
	assert_eq(replaced.get("icon"), "flag2")
	assert_eq(replaced.get("position"), Vector2(9.0, -3.0))

	map.add_dynamic_marker("camp_1", "camp", Vector3(1.0, 0.0, 1.0))
	assert_false(_entry("camp_1").is_empty())

	map.remove_dynamic_marker("camp_1")
	assert_true(_entry("camp_1").is_empty())

	map.remove_dynamic_marker("objective")
	assert_eq(map.objective_marker(), {})


func test_removing_a_marker_that_does_not_exist_is_a_safe_no_op() -> void:
	var before: int = map.revision
	map.remove_dynamic_marker("nothing_here")
	assert_eq(map.revision, before)


# --- save / load -------------------------------------------------------

func test_save_and_load_round_trips_fog_landmarks_and_markers() -> void:
	map.mark_visited(Vector3(100.0, 0.0, 100.0))
	map.discover_landmark("village")
	map.add_dynamic_marker("objective", "flag", Vector3(5.0, 0.0, 6.0))
	map.add_dynamic_marker("camp_1", "camp", Vector3(-40.0, 0.0, 12.0))

	var data: Dictionary = map.save_data()

	var loaded: RefCounted = MAP_STATE.new()
	loaded.configure(_config())
	loaded.load_data(data)

	assert_true(loaded.is_discovered(Vector3(100.0, 0.0, 100.0)))
	assert_almost_eq(loaded.discovered_fraction(), map.discovered_fraction())
	assert_true(loaded.is_landmark_discovered("village"))
	assert_false(loaded.is_landmark_discovered("stronghold"))

	var obj: Dictionary = loaded.objective_marker()
	assert_eq(obj.get("position"), Vector2(5.0, 6.0))
	var all_landmarks: Array = loaded.landmarks()
	var camp := all_landmarks.filter(func(e: Dictionary) -> bool: return str(e.get("id")) == "camp_1")
	assert_eq(camp.size(), 1)


func test_load_data_with_an_empty_dictionary_is_a_working_fresh_state() -> void:
	map.mark_visited(Vector3(100.0, 0.0, 100.0))
	map.discover_landmark("village")
	map.add_dynamic_marker("objective", "flag", Vector3(1.0, 0.0, 1.0))

	map.load_data({})

	assert_almost_eq(map.discovered_fraction(), 0.0)
	assert_false(map.is_landmark_discovered("village"))
	assert_eq(map.objective_marker(), {})
	# A fresh state must still be a WORKING one: revealing still works after.
	assert_true(map.mark_visited(Vector3(100.0, 0.0, 100.0)))


func test_a_corrupted_visited_grid_is_discarded_without_crashing() -> void:
	map.mark_visited(Vector3(100.0, 0.0, 100.0))
	var data: Dictionary = map.save_data()
	# Wrong length -- three bytes instead of GRID*GRID.
	data["visited_b64"] = Marshalls.raw_to_base64(PackedByteArray([1, 2, 3]))

	map.load_data(data)

	assert_almost_eq(map.discovered_fraction(), 0.0, 0.0001,
		"a corrupt grid must fall back to a fresh, fully-hidden one, not a partial read")
	assert_false(map.is_discovered(Vector3(100.0, 0.0, 100.0)))
	# The grid must still be USABLE, not merely empty.
	assert_true(map.mark_visited(Vector3(100.0, 0.0, 100.0)))


# --- named regions -----------------------------------------------------------
#
# Real ids/centres from data/config/map_landmarks.json's own "regions" array,
# same "run against the real data file" convention this whole test file uses
# for landmarks. grandpas_village: centre (6,-22), radius 60 -- one region for
# the whole starting hub (village square, Grandpa's house, the practice
# meadow), not three that used to sit close enough to collide on the map.


func test_regions_start_undiscovered_with_no_current_region() -> void:
	assert_eq(map.take_pending_region_announcement(), "")
	var found := false
	for region: Dictionary in map.regions():
		if str(region.get("id")) == "grandpas_village":
			found = true
			assert_false(bool(region.get("discovered")))
	assert_true(found, "map_landmarks.json must still define grandpas_village")


func test_entering_a_region_queues_its_display_name_exactly_once() -> void:
	map.update_region(Vector3(10.0, 0.0, -10.0))

	assert_eq(map.take_pending_region_announcement(), "Grandpa's Village")
	assert_eq(map.take_pending_region_announcement(), "",
		"a second poll before the next entry must find nothing queued")


func test_standing_still_inside_a_region_does_not_requeue() -> void:
	map.update_region(Vector3(10.0, 0.0, -10.0))
	map.take_pending_region_announcement()

	map.update_region(Vector3(11.0, 0.0, -9.0))

	assert_eq(map.take_pending_region_announcement(), "")


func test_leaving_and_returning_to_an_already_discovered_region_does_not_requeue() -> void:
	map.update_region(Vector3(10.0, 0.0, -10.0))
	map.take_pending_region_announcement()

	map.update_region(Vector3(250.0, 0.0, 250.0)) # open pasture, no authored region
	map.update_region(Vector3(10.0, 0.0, -10.0)) # back into Grandpa's Village

	assert_eq(map.take_pending_region_announcement(), "",
		"a region only announces itself the first time it is ever entered")


func test_update_region_outside_every_authored_region_is_a_silent_no_op() -> void:
	var before: int = map.revision

	map.update_region(Vector3(250.0, 0.0, 250.0))

	assert_eq(map.revision, before)
	assert_eq(map.take_pending_region_announcement(), "")


func test_regions_persist_through_save_and_load() -> void:
	map.update_region(Vector3(10.0, 0.0, -10.0))
	map.take_pending_region_announcement()

	var data: Dictionary = map.save_data()
	var loaded: RefCounted = MAP_STATE.new()
	loaded.configure(_config())
	loaded.load_data(data)

	var discovered := false
	for region: Dictionary in loaded.regions():
		if str(region.get("id")) == "grandpas_village":
			discovered = bool(region.get("discovered"))
	assert_true(discovered)

	# Re-entering the same region after a fresh load must not re-announce —
	# load_data resets `_current_region_id` to "", not the discovery itself.
	loaded.update_region(Vector3(250.0, 0.0, 250.0))
	loaded.update_region(Vector3(10.0, 0.0, -10.0))
	assert_eq(loaded.take_pending_region_announcement(), "")


# --- debug / testing helpers ------------------------------------------------

func test_reveal_circle_reveals_fog_but_never_discovers_landmarks() -> void:
	map.reveal_circle(Vector3(10.0, 0.0, -10.0), 5.0)
	assert_true(map.is_discovered(Vector3(10.0, 0.0, -10.0)))
	assert_false(map.is_landmark_discovered("village"),
		"reveal_circle is a debug helper; only mark_visited discovers landmarks")


func test_reveal_all_reveals_the_whole_grid_once() -> void:
	var before: int = map.revision
	map.reveal_all()

	assert_almost_eq(map.discovered_fraction(), 1.0)
	assert_true(map.revision > before)
	assert_true(map.is_discovered(Vector3(-250.0, 0.0, -250.0)))
	assert_true(map.is_discovered(Vector3(250.0, 0.0, 250.0)))

	var after: int = map.revision
	map.reveal_all()
	assert_eq(map.revision, after, "revealing an already-full grid must not bump again")
