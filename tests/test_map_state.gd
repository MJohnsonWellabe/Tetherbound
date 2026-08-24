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


## The shipped landmark config, MINUS its `starting_reveal`.
##
## Every test in this file is about the fog MECHANISM -- does `mark_visited`
## reveal a plausible disc, does a repeat visit change nothing, does a fresh
## grid start empty. The owner's 2026-08-22 §3 ruling seeds the village and its
## roads into that grid on a real save, which is correct and is not this file's
## subject: it would silently add ~1500 already-revealed cells to every count
## here, and did -- `test_mark_visited_reveals_a_plausible_area` measured 2742
## cells for an 80m radius that should give ~1257.
##
## The seed has its own test, from both sides, in `test_map_fog.gd`. Stripping
## it here keeps each file asking one question.
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

	# pi * reveal_radius^2 / cell_area is the ideal circle's cell count,
	# derived from `map.reveal_radius` itself (map_landmarks.json's own
	# tunable — OW3 raised it 45 -> 80 to keep an opaque fog from reading as
	# a void) rather than a number baked into this test, so a future retune
	# does not silently break this assertion the way OW3's own retune did
	# the first time this was hardcoded. A generous +/-15% band around the
	# ideal catches a badly wrong radius or an off-by-one in the cell math
	# without being pinned to the exact discretisation.
	var cell_area := MAP_STATE.CELL * MAP_STATE.CELL
	var ideal: float = PI * map.reveal_radius * map.reveal_radius / cell_area
	# OW5E: `GRID` (a single ±256m-square scalar) is gone — `map_state.gd`
	# derives a non-square, non-origin-centred grid from the world's own
	# extent now (`grid_x()`/`grid_z()`, see that file's own comment on why).
	var revealed := int(round(map.discovered_fraction() * float(MAP_STATE.grid_x() * MAP_STATE.grid_z())))
	assert_between(float(revealed), ideal * 0.85, ideal * 1.15,
		"revealed cell count %d is not plausible for a %.0fm radius (expected ~%.0f)" % [revealed, map.reveal_radius, ideal])


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
	# Wrong length -- three bytes instead of grid_x() * grid_z().
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


# --- fog dirty tracking (OP23-01) -------------------------------------------
#
# The owner's report was "freezes every few feet of walking", everywhere,
# including indoors. Root cause: the minimap and full map repainted EVERY fog
# cell whenever `revision` moved, and the corridor world's grid is 512x2048 =
# 1,048,576 cells -- 837ms per repaint, fired on essentially every 0.5s
# discovery tick, because an 80m reveal radius over a 4m cell always sweeps
# new cells while walking.
#
# These tests hold the property that actually protects the frame rate: the
# work a reveal creates is bounded by the REVEAL RADIUS, never by the size of
# the world. A future CELL/bounds/reveal_radius change that reintroduces a
# whole-grid repaint fails here rather than on the owner's device.

func test_walking_marks_only_a_small_rect_dirty_not_the_whole_grid() -> void:
	map.mark_visited(Vector3(0.0, 0.0, 0.0))
	map.take_fog_dirty() # consume the priming reveal

	map.mark_visited(Vector3(0.0, 0.0, 8.0)) # one walking tick forward
	var dirty: Dictionary = map.take_fog_dirty()

	assert_false(bool(dirty.get("all", false)),
		"an ordinary walking reveal must not demand a full-grid rebuild")
	var rect: Variant = dirty.get("rect")
	assert_true(rect != null, "a reveal that changed cells must report a dirty rect")

	var r: Rect2i = rect
	# The reveal disc is 2*radius across; the rect bounding one tick's NEW
	# cells can never exceed that, whatever the world's dimensions are.
	var max_span: int = int(ceil((map.reveal_radius * 2.0) / MAP_STATE.CELL)) + 2
	assert_true(r.size.x <= max_span and r.size.y <= max_span,
		"dirty rect %s exceeds the reveal disc (%d cells) -- the fog repaint is scaling with the world, not the reveal" % [r, max_span])

	var grid_cells: int = map.cell_grid_x() * map.cell_grid_z()
	assert_true(r.size.x * r.size.y < grid_cells / 10,
		"dirty rect covers %d of %d cells; a walking tick must touch a small fraction" % [r.size.x * r.size.y, grid_cells])


func test_standing_still_reports_no_dirty_region() -> void:
	map.mark_visited(Vector3(0.0, 0.0, 0.0))
	map.take_fog_dirty()

	map.mark_visited(Vector3(0.0, 0.0, 0.0)) # same spot, nothing new
	var dirty: Dictionary = map.take_fog_dirty()

	assert_false(bool(dirty.get("all", false)))
	assert_true(dirty.get("rect") == null,
		"a stationary player must not cause any fog repaint at all")


func test_load_and_reveal_all_demand_a_full_rebuild() -> void:
	map.mark_visited(Vector3(0.0, 0.0, 0.0))
	map.take_fog_dirty()

	# A loaded save replaces the whole grid, so a rect cannot describe it.
	var saved: Dictionary = map.save_data()
	var loaded: RefCounted = MAP_STATE.new()
	loaded.configure(_config())
	loaded.take_fog_dirty() # consume configure()'s own full flag
	loaded.load_data(saved)
	assert_true(bool(loaded.take_fog_dirty().get("all", false)),
		"loading a save must force a full fog rebuild, not a rect patch")

	map.reveal_all()
	assert_true(bool(map.take_fog_dirty().get("all", false)),
		"reveal_all must force a full fog rebuild")


func test_dirty_rect_accumulates_across_ticks_until_consumed() -> void:
	map.take_fog_dirty()
	map.mark_visited(Vector3(0.0, 0.0, 0.0))
	map.mark_visited(Vector3(0.0, 0.0, 40.0))
	map.mark_visited(Vector3(0.0, 0.0, 80.0))

	# The minimap may not draw on every tick (hidden, dimmed, offscreen). When
	# it does, one patch must cover everything revealed since its last one.
	var dirty: Dictionary = map.take_fog_dirty()
	var r: Rect2i = dirty.get("rect")
	var near: Vector2i = map.world_to_cell(Vector3(0.0, 0.0, 0.0))
	var far: Vector2i = map.world_to_cell(Vector3(0.0, 0.0, 80.0))
	assert_true(r.has_point(near) and r.has_point(far),
		"the accumulated rect %s must cover every cell revealed since the last consume" % r)
