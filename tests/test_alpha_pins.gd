extends "res://tests/test_case.gd"

## CL-W1 / owner directive D-0904B-1 with amendment A-3: an alpha within 300 m
## pins itself to the map, the pin SURVIVES A SAVE AND LOAD, and it clears when
## that alpha is caught or beaten.
##
## The closure plan's *fails if* on this row is the save one — "a pin that
## survives only until the next load is worse than none" — so the middle third
## of this file is a real `SaveGame` write to disk and a real read back into a
## fresh `MapState`, not an in-memory copy of a dictionary.
##
## ## What is real here and what is not
##
## Real: `MapState` (the live class the running game uses, not a double),
## `SaveGame` writing and re-reading an actual file under
## `user://test_saves_alpha_pins/`, `ProgressionState` as the flag store, and
## the authored contents of `data/config/bands/*/spawns.json` read through
## `alpha_pins.gd`'s own cluster loader.
##
## Not real, and deliberately: the `AlphaPins` NODE's `_process` tick.
## `--script` boots no autoloads and no SceneTree (`test_shiny.gd`'s header
## documents this for the whole suite), and that node reaches `/root/Game` for
## both the map and the progression store, so nothing here can stand one up.
## The proximity DECISION it makes is pure arithmetic on data this file loads
## itself, and it is tested as such: `_pin_within()` below applies the exact
## rule `AlphaPins.tick()` applies (XZ distance against `map.json`'s own
## `radius_m`), against the real authored cluster positions. The live half —
## the node ticking in a running world and a pin appearing at 300 m — is
## `tests/smoke_alpha_pins.gd`.
##
## ## Seen red first
##
## Every assertion below was watched fail for the right reason before it was
## trusted, per the lane rules. What was broken, and what went red:
##   * persistence — `save_game.gd`'s `"alpha_pins"` write replaced with a
##     literal `[]`: 3 failures, led by `test_a_pin_survives_a_save_and_load`
##     ("expected 1, got 0 — the pinned set did not survive the save").
##   * ordering — `alpha_pin_load_data` moved to BEFORE `map.load_data` in
##     `load_slot`: 2 failures, because `load_data` clears the pinned set
##     wholesale along with the markers, so restoring first loses both.
##   * marker rebuild — the `_dynamic` write inside `alpha_pin_load_data`
##     deleted: `test_restoring_the_pinned_set_alone_rebuilds_its_markers`
##     fails "expected 1, got 0". This one is worth its own note. The end-to-end
##     load test does NOT catch it, and that is not a gap in the test — it is
##     the belt and the braces both being real. `map_state.save_data()` already
##     round-trips `_dynamic`, so a full `load_slot()` restores the markers by
##     that path even with the rebuild gone; the rebuild is what makes the
##     PINNED SET the source of truth rather than a duplicate of the marker
##     list, and it is asserted directly instead of through a path that would
##     hide it.
##   * clearing — `unpin_alpha` made a no-op: 3 failures, led by
##     `test_the_pin_clears_when_the_alphas_once_flag_fires` ("expected false,
##     got true", then "the pin cleared but its marker did not").

const MAP_STATE := preload("res://autoload/map_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const ALPHA_PINS := preload("res://scripts/world/alpha_pins.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const ENCOUNTER_DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const PARTY := preload("res://autoload/party.gd")

const TEST_DIR := "user://test_saves_alpha_pins/"
const MAP_CONFIG := "res://data/config/map.json"

## The same minimal stand-in for the `Game` autoload `test_save_format.gd`
## uses — `save_game.gd` reads nothing else off it.
class FakeGame:
	extends RefCounted
	var day: int = 1
	var party: RefCounted = null
	var inventory: RefCounted = null
	var placed_buildings: Array = []
	var farm_plots: Array = []
	var death_satchels: Array = []
	var harvested_vegetation: Dictionary = {}
	var felled_vegetation: Dictionary = {}
	var world_seed: int = 0
	var saved_player_pose: Dictionary = {}
	var map: RefCounted = null
	var progression: RefCounted = null
	var satiety: float = 100.0

	func player_vitals() -> RefCounted:
		return null

var db: RefCounted = null
var saver: RefCounted = null


func before_each() -> void:
	db = ITEM_DB.new()
	saver = SAVE_GAME.new(TEST_DIR)
	_wipe_test_dir()


func after_each() -> void:
	_wipe_test_dir()


func _wipe_test_dir() -> void:
	var dir := DirAccess.open(TEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _game() -> RefCounted:
	var game := FakeGame.new()
	game.party = PARTY.new()
	game.inventory = INVENTORY.new(db)
	game.progression = PROGRESSION_STATE.new()
	game.map = MAP_STATE.new()
	game.map.call("configure", {})
	return game


func _clusters() -> Array[Dictionary]:
	return ALPHA_PINS.build_clusters()


func _config_radius() -> float:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_CONFIG))
	var config: Dictionary = parsed as Dictionary if parsed is Dictionary else {}
	var pin: Dictionary = config.get("alpha_pin", {})
	return float(pin.get("radius_m", -1.0))


## The rule `AlphaPins.tick()` applies, applied here to the real authored data:
## every not-yet-cleared cluster whose authored centre is within the config
## radius of `here` gets pinned, measured on XZ.
func _pin_within(map: RefCounted, progression: RefCounted, here: Vector2) -> int:
	var radius := _config_radius()
	var pinned := 0
	for cluster: Dictionary in _clusters():
		var order := int(cluster.order)
		if map.call("is_alpha_pinned", order):
			continue
		if bool(progression.call("has", str(cluster.once_id))):
			continue
		if here.distance_to(cluster.position as Vector2) > radius:
			continue
		if map.call("pin_alpha", order, str(cluster.species), str(cluster.display_name),
				Vector3((cluster.position as Vector2).x, 0.0, (cluster.position as Vector2).y), "alpha"):
			pinned += 1
	return pinned


# --- the authored content this feature advertises ---------------------------

func test_every_authored_alpha_and_elder_cluster_is_found() -> void:
	# The closure plan's own count for this merge. A band lane adding a
	# seventeenth is not a failure — but it must be a deliberate edit to this
	# number, not a silent drift, because a cluster this loader drops is a
	# creature the map will never advertise and nothing else would notice.
	assert_eq(_clusters().size(), 16,
		"the alpha/elder clusters authored across data/config/bands/*/spawns.json")


func test_every_cluster_has_a_real_position_and_a_name() -> void:
	for cluster: Dictionary in _clusters():
		var position: Vector2 = cluster.position
		assert_ne(position, Vector2.ZERO,
			"cluster %d has no authored centre; a pin at the world origin is a lie" % int(cluster.order))
		assert_false(str(cluster.display_name).is_empty(),
			"cluster %d would pin with a blank label" % int(cluster.order))
		assert_false(str(cluster.species).is_empty(),
			"cluster %d names no species" % int(cluster.order))


func test_cluster_orders_are_unique() -> void:
	# `order` IS the pin's identity and the once-flag's. Two clusters sharing one
	# would make a single catch clear two pins.
	var seen: Dictionary = {}
	for cluster: Dictionary in _clusters():
		var order := int(cluster.order)
		assert_false(seen.has(order), "two alpha clusters both claim order %d" % order)
		seen[order] = true


func test_the_once_id_matches_the_one_the_encounter_director_fires() -> void:
	# Two independent spellings of this id would be a pin that never clears,
	# with no error anywhere. The director mints "wild_once_%d" % order.
	var source := FileAccess.get_file_as_string("res://scripts/combat/encounter_director.gd")
	assert_true(source.contains('once_id = "wild_once_%d" % int(spawn.get("order", index))'),
		"encounter_director.gd no longer mints the flag id alpha_pins.gd derives")
	for cluster: Dictionary in _clusters():
		assert_eq(str(cluster.once_id), "wild_once_%d" % int(cluster.order))


func test_the_pin_radius_is_the_owners_three_hundred_metres() -> void:
	assert_almost_eq(_config_radius(), 300.0, 0.001,
		"D-0904B-1 says 300 m; data/config/map.json says otherwise")


# --- proximity: MapState is real, the arithmetic is the node's --------------

func test_nothing_is_pinned_before_the_player_goes_anywhere() -> void:
	var map: RefCounted = MAP_STATE.new()
	map.call("configure", {})
	assert_eq(int(map.call("alpha_pin_count")), 0)


func test_a_far_away_alpha_does_not_pin() -> void:
	var game: RefCounted = _game()
	# Band 5's northernmost alpha sits at z=7255; the village is at z~0. Nothing
	# in the corridor is within 300 m of a point 20 km off the end of it.
	assert_eq(_pin_within(game.map, game.progression, Vector2(0.0, 20000.0)), 0)
	assert_eq(int(game.map.call("alpha_pin_count")), 0)


func test_standing_on_a_band_two_alpha_pins_exactly_that_cluster() -> void:
	var game: RefCounted = _game()
	# order 2011, trailpup, authored centre [-180, 0, 2250] (band 2). The nearest
	# other authored cluster is order 2012 at [-150, 2650] — 401 m away, outside
	# the radius, which is what makes this a single-pin case rather than a
	# "some number of pins appeared" one.
	var target := Vector2(-180.0, 2250.0)
	assert_eq(_pin_within(game.map, game.progression, target), 1)
	assert_true(bool(game.map.call("is_alpha_pinned", 2011)))
	var pins: Array = game.map.call("alpha_pins")
	assert_eq(pins.size(), 1)
	assert_eq(str((pins[0] as Dictionary).get("display_name")), "Alpha Trailpup",
		"the full map must say WHICH alpha, and say it the way the nameplate will")


func test_the_elder_pins_under_its_authored_title() -> void:
	var game: RefCounted = _game()
	# order 1900, mosshell, `elder.title` "Elder", authored centre [-490, 0, 555].
	_pin_within(game.map, game.progression, Vector2(-490.0, 555.0))
	assert_true(bool(game.map.call("is_alpha_pinned", 1900)))
	for pin: Dictionary in (game.map.call("alpha_pins") as Array):
		if int(pin.get("order", 0)) == 1900:
			assert_eq(str(pin.get("display_name")), "Elder Mosshell")
			return
	_fail("the elder cluster pinned but is not in alpha_pins()")


func test_pinning_the_same_cluster_twice_is_a_no_op() -> void:
	# `tick()` re-tests every cluster twice a second for the whole chapter. A
	# second pin that bumped `revision` would rebuild the entire map UI forever.
	var game: RefCounted = _game()
	var target := Vector2(-180.0, 2250.0)
	_pin_within(game.map, game.progression, target)
	var revision_after_first := int(game.map.get("revision"))
	assert_eq(_pin_within(game.map, game.progression, target), 0)
	assert_eq(int(game.map.get("revision")), revision_after_first,
		"a repeat pin bumped revision and would rebuild the map UI every tick")


func test_a_pin_also_becomes_a_marker_the_map_can_draw() -> void:
	var game: RefCounted = _game()
	_pin_within(game.map, game.progression, Vector2(-180.0, 2250.0))
	assert_eq(_alpha_markers(game.map).size(), 1,
		"the pin exists in the set but nothing would be drawn for it")
	var marker: Dictionary = _alpha_markers(game.map)[0]
	assert_eq(str(marker.get("display_name")), "Alpha Trailpup")
	assert_eq(str(marker.get("icon")), "alpha")
	assert_true(bool(marker.get("dynamic", false)))


## The marker entries `minimap.gd` and `tab_map.gd` actually iterate, filtered
## the way both of them filter — so this asserts what gets DRAWN, not a private
## dictionary.
func _alpha_markers(map: RefCounted) -> Array:
	var out: Array = []
	for entry: Dictionary in (map.call("landmarks") as Array):
		if not bool(entry.get("dynamic", false)):
			continue
		if str(entry.get("id", "")).begins_with(MAP_STATE.ALPHA_MARKER_PREFIX):
			out.append(entry)
	return out


# --- persistence: the row's own *fails if* ----------------------------------

func test_a_pin_survives_a_save_and_load() -> void:
	var written: RefCounted = _game()
	_pin_within(written.map, written.progression, Vector2(-180.0, 2250.0))
	assert_eq(int(written.map.call("alpha_pin_count")), 1)
	assert_true(saver.call("save", written, 1))

	var read: RefCounted = _game()
	assert_true(saver.call("load_slot", read, 1))
	assert_eq(int(read.map.call("alpha_pin_count")), 1,
		"the pinned set did not survive the save — the closure plan's own fails-if")
	var pins: Array = read.map.call("alpha_pins")
	var pin: Dictionary = pins[0]
	assert_eq(int(pin.get("order")), 2011)
	assert_eq(str(pin.get("species")), "trailpup")
	assert_eq(str(pin.get("display_name")), "Alpha Trailpup")
	assert_almost_eq((pin.get("position") as Vector2).x, -180.0, 0.01)
	assert_almost_eq((pin.get("position") as Vector2).y, 2250.0, 0.01)


func test_a_loaded_pin_still_draws_on_the_map() -> void:
	# Separate from the set assertion above ON PURPOSE: `map.load_data()` clears
	# every dynamic marker wholesale, so restoring the set before it leaves a
	# save that "persisted the pins" and draws nothing.
	var written: RefCounted = _game()
	_pin_within(written.map, written.progression, Vector2(-180.0, 2250.0))
	assert_true(saver.call("save", written, 1))

	var read: RefCounted = _game()
	assert_true(saver.call("load_slot", read, 1))
	var markers: Array = _alpha_markers(read.map)
	assert_eq(markers.size(), 1,
		"the pinned set came back but no marker did; nothing would be drawn")
	assert_eq(str((markers[0] as Dictionary).get("display_name")), "Alpha Trailpup")


## The pinned set alone, with no `map` blob at all, is enough to put the pins
## back on the screen. This is the property that makes `alpha_pins` the record
## and `_dynamic` the drawing of it, rather than two half-copies of one thing.
func test_restoring_the_pinned_set_alone_rebuilds_its_markers() -> void:
	var written: RefCounted = _game()
	_pin_within(written.map, written.progression, Vector2(-180.0, 2250.0))
	var pinned_set: Array = written.map.call("alpha_pin_save_data")

	var fresh: RefCounted = MAP_STATE.new()
	fresh.call("configure", {})
	assert_eq(_alpha_markers(fresh).size(), 0, "precondition: a fresh map draws nothing")
	fresh.call("alpha_pin_load_data", pinned_set)
	assert_eq(int(fresh.call("alpha_pin_count")), 1)
	var markers: Array = _alpha_markers(fresh)
	assert_eq(markers.size(), 1,
		"the pinned set restored but rebuilt no marker; nothing would be drawn")
	assert_eq(str((markers[0] as Dictionary).get("display_name")), "Alpha Trailpup")
	assert_eq(str((markers[0] as Dictionary).get("icon")), "alpha")


func test_the_save_file_carries_the_pinned_set_at_its_top_level() -> void:
	var written: RefCounted = _game()
	_pin_within(written.map, written.progression, Vector2(-180.0, 2250.0))
	assert_true(saver.call("save", written, 1))
	var raw := FileAccess.get_file_as_string(saver.call("slot_path", 1))
	var parsed: Variant = JSON.parse_string(raw)
	assert_true(parsed is Dictionary, "the save slot is not readable JSON")
	var data: Dictionary = parsed
	assert_eq(int(data.get("version", 0)), SAVE_GAME.VERSION)
	assert_true(data.has("alpha_pins"), "no top-level alpha_pins key in the written save")
	assert_eq((data.get("alpha_pins") as Array).size(), 1)


func test_a_save_with_no_pins_round_trips_as_no_pins() -> void:
	var written: RefCounted = _game()
	assert_true(saver.call("save", written, 1))
	var read: RefCounted = _game()
	assert_true(saver.call("load_slot", read, 1))
	assert_eq(int(read.map.call("alpha_pin_count")), 0)


func test_a_pre_seventeen_save_loads_with_no_pins_rather_than_refusing() -> void:
	# The migration default. A version bump that bricks an existing save is a
	# strictly worse failure than the feature not being there — `save_game.gd`'s
	# own `_migrate_v13` neighbour says so.
	var written: RefCounted = _game()
	assert_true(saver.call("save", written, 1))
	var path: String = saver.call("slot_path", 1)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data["version"] = 16
	data.erase("alpha_pins")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file = null

	var read: RefCounted = _game()
	assert_true(saver.call("load_slot", read, 1),
		"a VERSION 16 save must still load after the alpha-pin bump")
	assert_eq(int(read.map.call("alpha_pin_count")), 0)


func test_a_corrupt_pinned_set_loads_as_no_pins_rather_than_crashing() -> void:
	var map: RefCounted = MAP_STATE.new()
	map.call("configure", {})
	for junk: Variant in [null, "not an array", {}, [null], ["x"], [{}], [{"order": 1}]]:
		map.call("alpha_pin_load_data", junk)
		assert_eq(int(map.call("alpha_pin_count")), 0,
			"malformed pin data %s produced a pin" % str(junk))


# --- clearing: A-3, caught OR beaten ----------------------------------------

func test_the_pin_clears_when_the_alphas_once_flag_fires() -> void:
	var game: RefCounted = _game()
	_pin_within(game.map, game.progression, Vector2(-180.0, 2250.0))
	assert_true(bool(game.map.call("is_alpha_pinned", 2011)))
	# What `encounter_director.gd::_on_combat_exited()` does on BOTH "won" and
	# CAUGHT — A-3's whole point is that these are the same outcome for a pin.
	game.progression.call("set_flag", "wild_once_2011")
	_prune(game.map, game.progression)
	assert_false(bool(game.map.call("is_alpha_pinned", 2011)))
	assert_eq(int(game.map.call("alpha_pin_count")), 0)
	assert_eq(_alpha_markers(game.map).size(), 0, "the pin cleared but its marker did not")


func test_a_cleared_alpha_does_not_pin_again_when_the_player_walks_back() -> void:
	var game: RefCounted = _game()
	game.progression.call("set_flag", "wild_once_2011")
	assert_eq(_pin_within(game.map, game.progression, Vector2(-180.0, 2250.0)), 0)
	assert_eq(int(game.map.call("alpha_pin_count")), 0)


func test_a_pin_whose_flag_fired_before_the_save_is_pruned_on_load() -> void:
	# The `_prune_cleared()` call on `_ready()`. This is the ordering a real
	# session can produce: the fight ends, the flag fires, the autosave happens
	# on the same tick, and the pin is still in the set when it is written.
	var written: RefCounted = _game()
	_pin_within(written.map, written.progression, Vector2(-180.0, 2250.0))
	written.progression.call("set_flag", "wild_once_2011")
	assert_true(saver.call("save", written, 1))

	var read: RefCounted = _game()
	assert_true(saver.call("load_slot", read, 1))
	assert_eq(int(read.map.call("alpha_pin_count")), 1, "precondition: the stale pin loaded")
	_prune(read.map, read.progression)
	assert_eq(int(read.map.call("alpha_pin_count")), 0,
		"a pin whose alpha was already beaten survived the load")


## `AlphaPins._prune_cleared()`'s rule, applied to the same data.
func _prune(map: RefCounted, progression: RefCounted) -> void:
	for cluster: Dictionary in _clusters():
		var order := int(cluster.order)
		if not map.call("is_alpha_pinned", order):
			continue
		if bool(progression.call("has", str(cluster.once_id))):
			map.call("unpin_alpha", order)


func test_clearing_one_alpha_leaves_its_neighbours_pinned() -> void:
	var game: RefCounted = _game()
	# Band 4's cluster of three: orders 4001 [-410, 5150], 4007 [-285, 5080] and
	# 4100 [-440, 5210] all sit inside 300 m of this point.
	var pinned := _pin_within(game.map, game.progression, Vector2(-380.0, 5140.0))
	assert_true(pinned >= 3, "precondition: expected at least three band 4 pins, got %d" % pinned)
	game.progression.call("set_flag", "wild_once_4007")
	_prune(game.map, game.progression)
	assert_false(bool(game.map.call("is_alpha_pinned", 4007)))
	assert_true(bool(game.map.call("is_alpha_pinned", 4001)),
		"beating one alpha cleared a different alpha's pin")
	assert_true(bool(game.map.call("is_alpha_pinned", 4100)))


# --- the one-shot intro line ------------------------------------------------

func test_the_intro_flag_is_a_real_progression_flag_that_survives_a_save() -> void:
	# The line must fire once per SAVE, not once per session — the alternative
	# is the player being told what an alpha pin is every time they load.
	var written: RefCounted = _game()
	written.progression.call("set_flag", ALPHA_PINS.INTRO_FLAG)
	assert_true(saver.call("save", written, 1))
	var read: RefCounted = _game()
	assert_true(saver.call("load_slot", read, 1))
	assert_true(bool(read.progression.call("has", ALPHA_PINS.INTRO_FLAG)))


func test_the_intro_message_is_authored_in_config_not_hard_coded() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_CONFIG))
	var pin: Dictionary = (parsed as Dictionary).get("alpha_pin", {})
	assert_false(str(pin.get("first_pin_message", "")).is_empty())
	assert_eq(str(pin.get("icon", "")), "alpha")
	assert_true(ResourceLoader.exists("res://assets/ui/icons/map/alpha.png"),
		"the pin icon the config names does not exist")
