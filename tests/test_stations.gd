extends "res://tests/test_case.gd"

## Build pieces that do something.
##
## Two halves, and they fail in different ways, so they are both here:
##
##   1. The STATIONS themselves — capacity, occupancy, refusals, lit state. Pure
##      logic on nodes that never need a scene, in the spirit of D02.
##   2. The CATALOGUE and the RECORD — that the three station pieces exist, that
##      they name behaviours which exist, that a station's state reaches a save
##      record and comes back, and that the twenty-eight pieces which are only
##      geometry are untouched by any of it.
##
## What is deliberately NOT here is `structures.place()` driving real nodes.
## `run_tests.gd` does all its work inside `SceneTree._init()`, at which point
## `root` is not yet inside the tree, so a Node3D added to it reports
## `is_inside_tree() == false` and every `global_position` silently reads
## (0,0,0). A test that placed pieces there would assert against a world where
## everything is stacked on the origin. `tests/smoke_build.gd` runs in a real
## world across real frames and is where the node-level round trip belongs; the
## rendered frame from `tools/preview_build.gd` is where "and it looks like a
## bed" belongs.
##
## The hard rule this file is really guarding is at the bottom:
## `test_no_station_can_be_told_to_work` fails if anyone ever gives a station a
## verb that turns a pal into labour.

const STATION := preload("res://scripts/building/station.gd")
const CATALOGUE := "res://data/building/pieces.json"

const PAL_BED := "pal_bed_straw"
const BED := "bed_simple"
const CAMPFIRE := "campfire_stone"


## A stand-in for whatever ends up resting in a bed. The bed is deliberately
## told nothing about pals — it takes an Object and hands the same Object back
## in its signals — so the test can use the cheapest possible sleeper.
class Sleeper extends RefCounted:
	var who: String = ""

	func _init(name: String = "") -> void:
		who = name


## A sleeper that can actually be destroyed, for the one test about a sleeper
## that goes away. A `RefCounted` cannot: the bed holds a reference to it, which
## is precisely what keeps it alive. Only something freed by hand — a node in the
## world — can vanish out from under an occupancy list.
class NodeSleeper extends Node:
	pass


var _built: Array[Node] = []


func after_each() -> void:
	for node: Node in _built:
		if is_instance_valid(node):
			node.free()
	_built.clear()


## Build a station straight from its real catalogue entry, so these tests break
## if the DATA stops agreeing with the code rather than only if the code does.
func _station(piece_id: String) -> Node:
	var station: Node = STATION.create(_piece(piece_id))
	if station != null:
		station.call("setup", piece_id, STATION.config_of(_piece(piece_id)), Vector3.ZERO)
		_built.append(station)
	return station


func _piece(piece_id: String) -> Dictionary:
	return _pieces().get(piece_id, {})


func _pieces() -> Dictionary:
	var file := FileAccess.open(CATALOGUE, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var out: Dictionary = {}
	if parsed is Dictionary:
		for id: String in (parsed as Dictionary).get("pieces", {}).keys():
			if not id.begins_with("_"):
				out[id] = (parsed as Dictionary)["pieces"][id]
	return out


# --- the hook -------------------------------------------------------------

func test_a_piece_with_no_station_block_gets_no_station() -> void:
	# The whole no-regression story for the twenty-eight in one line: a wall is
	# what it always was.
	assert_eq(STATION.create(_piece("wall_plaster_straight")), null)
	assert_eq(STATION.create(_piece("floor_wooddark")), null)
	assert_eq(STATION.create({}), null, "a definition with nothing in it must not produce a station")


func test_a_piece_with_a_station_block_gets_one() -> void:
	var bed := _station(PAL_BED)
	assert_ne(bed, null, "the pal bed must attach a station")
	assert_eq(str(bed.get("behaviour")), STATION.BEHAVIOUR_REST)
	assert_eq(str(bed.get("piece_id")), PAL_BED, "a station must know which piece it is")


func test_a_station_knows_where_it_is() -> void:
	# "Is a pal resting HERE" needs a position, and it must not come from
	# `global_position`, which is (0,0,0) for anything outside a running tree.
	var bed: Node = STATION.create(_piece(PAL_BED))
	_built.append(bed)
	bed.call("setup", PAL_BED, STATION.config_of(_piece(PAL_BED)), Vector3(12.0, 3.0, -4.0))
	assert_eq(bed.call("where"), Vector3(12.0, 3.0, -4.0))
	assert_almost_eq(float(bed.call("distance_to", Vector3(12.0, 3.0, -1.0))), 3.0)


func test_an_unknown_behaviour_is_refused_rather_than_placed_empty() -> void:
	# A piece that names a behaviour nobody wrote must not place a station that
	# does nothing — that is indistinguishable from a working one until the day
	# somebody needs it.
	assert_eq(STATION.create({"station": {"behaviour": "sawmill"}}), null)


# --- the pal bed ----------------------------------------------------------

func test_the_pal_bed_holds_one_pal() -> void:
	# The capacity decision, pinned against the data rather than against a
	# constant, because the decision lives in pieces.json.
	var bed := _station(PAL_BED)
	assert_eq(int(bed.get("capacity")), 1, "a pal bed sleeps one pal; five pals need five beds")
	assert_true(bool(bed.call("is_for_pals")))


func test_a_pal_begins_and_ends_resting() -> void:
	var bed := _station(PAL_BED)
	var pal := Sleeper.new("bruno")
	assert_false(bool(bed.call("is_resting", pal)), "nobody is asleep in a fresh bed")
	assert_true(bool(bed.call("begin_rest", pal)))
	assert_true(bool(bed.call("is_resting", pal)))
	assert_eq(int(bed.call("occupant_count")), 1)
	assert_true(bool(bed.call("end_rest", pal)))
	assert_false(bool(bed.call("is_resting", pal)))
	assert_eq(int(bed.call("occupant_count")), 0)


func test_resting_is_announced_so_recovery_can_hang_off_it() -> void:
	# The signals are the entire interface M6's recovery and rest animation will
	# use. If they stop firing, both fail silently.
	var bed := _station(PAL_BED)
	var pal := Sleeper.new("ernie")
	var began: Array = []
	var ended: Array = []
	bed.connect("rest_began", func(who: Object) -> void: began.append(who))
	bed.connect("rest_ended", func(who: Object, why: String) -> void: ended.append([who, why]))

	bed.call("begin_rest", pal)
	assert_eq(began.size(), 1, "beginning to rest must be announced")
	assert_eq(began[0], pal)

	bed.call("end_rest", pal)
	assert_eq(ended.size(), 1, "ending must be announced too")
	assert_eq((ended[0] as Array)[1], "done")


func test_a_second_pal_is_refused_with_a_reason() -> void:
	# Five pals, one bed. The answer is a refusal token, not a queue — so the
	# thing that owns recovery can say "build another bed" rather than stalling.
	var bed := _station(PAL_BED)
	var first := Sleeper.new("bruno")
	var second := Sleeper.new("ollie")
	assert_true(bool(bed.call("begin_rest", first)))
	assert_false(bool(bed.call("begin_rest", second)), "a one-capacity bed must refuse a second pal")
	assert_eq(str(bed.call("last_refusal")), "station_full")
	assert_eq(int(bed.call("occupant_count")), 1, "the refusal must not have disturbed the sleeper")


func test_the_same_pal_cannot_take_the_bed_twice() -> void:
	var bed := _station(PAL_BED)
	var pal := Sleeper.new("bruno")
	assert_true(bool(bed.call("begin_rest", pal)))
	assert_false(bool(bed.call("begin_rest", pal)))
	assert_eq(str(bed.call("last_refusal")), "already_resting")
	assert_eq(int(bed.call("occupant_count")), 1, "a double begin must not double-count a sleeper")


func test_waking_someone_who_is_not_there_is_refused_not_ignored() -> void:
	var bed := _station(PAL_BED)
	assert_false(bool(bed.call("end_rest", Sleeper.new("nobody"))))
	assert_eq(str(bed.call("last_refusal")), "nobody")


func test_the_trainers_bed_is_a_different_bed() -> void:
	# §20 lists "beds" and "pal beds" as separate categories, and the base is for
	# "safety, recovery, respawn and rest". The human one is the respawn point.
	var bed := _station(BED)
	assert_false(bool(bed.call("is_for_pals")), "the trainer's bed is not a pal bed")
	assert_true(bool(bed.call("is_respawn_point")), "the trainer's bed is where the trainer respawns")
	assert_false(bool(_station(PAL_BED).call("is_respawn_point")), "a pal bed is not a respawn point")


func test_sleepers_do_not_stack_on_one_spot() -> void:
	# Capacity is data, so a bed with room for two is one JSON edit away. When it
	# happens the second sleeper must not be put inside the first.
	var bed := _station(PAL_BED)
	assert_eq(bed.call("rest_point", 0), Vector3.ZERO, "the first sleeper takes the bed's own spot")
	assert_ne(bed.call("rest_point", 1), bed.call("rest_point", 0))


# --- removal --------------------------------------------------------------

func test_deleting_a_bed_wakes_whoever_is_in_it() -> void:
	# The crash this prevents: a pal left holding a bed that has been freed, and
	# then asked where it is sleeping.
	var bed := _station(PAL_BED)
	var pal := Sleeper.new("bruno")
	var ended: Array = []
	bed.connect("rest_ended", func(who: Object, why: String) -> void: ended.append([who, why]))
	bed.call("begin_rest", pal)

	bed.call("release")

	assert_eq(ended.size(), 1, "a deleted bed must wake its sleeper")
	assert_eq((ended[0] as Array)[0], pal)
	assert_eq((ended[0] as Array)[1], "removed", "and say that it was the bed that went, not the night")
	assert_eq(int(bed.call("occupant_count")), 0)


func test_removal_is_announced_before_anything_is_freed() -> void:
	var bed := _station(PAL_BED)
	# An Array rather than an int, because a GDScript lambda captures a local by
	# VALUE — `removals += 1` inside the closure would increment a copy and this
	# test would fail against working code.
	var removals: Array = []
	bed.connect("removed", func() -> void: removals.append(true))
	bed.call("release")
	assert_eq(removals.size(), 1)


func test_a_sleeper_that_has_gone_away_stops_occupying_the_bed() -> void:
	# A sleeper destroyed by anything else — despawned, scene unloaded — must not
	# hold a bed open forever, because nothing will ever come to wake it.
	var bed := _station(PAL_BED)
	var pal := NodeSleeper.new()
	bed.call("begin_rest", pal)
	assert_eq(int(bed.call("occupant_count")), 1)
	pal.free()
	assert_eq(int(bed.call("occupant_count")), 0, "a vanished sleeper must free its bed")
	assert_true(bool(bed.call("has_room")))


# --- the campfire ---------------------------------------------------------

func test_a_campfire_is_lit_when_you_build_it() -> void:
	var fire := _station(CAMPFIRE)
	assert_ne(fire, null)
	assert_eq(str(fire.get("behaviour")), STATION.BEHAVIOUR_HEARTH)
	assert_true(bool(fire.call("is_lit")))


func test_a_campfire_can_go_out_and_says_so() -> void:
	var fire := _station(CAMPFIRE)
	var changes: Array = []
	fire.connect("lit_changed", func(lit: bool) -> void: changes.append(lit))
	fire.call("set_lit", false)
	assert_false(bool(fire.call("is_lit")))
	assert_eq(changes.size(), 1)
	# Setting it to what it already is must not re-announce, or every listener
	# fires on every load.
	fire.call("set_lit", false)
	assert_eq(changes.size(), 1, "an unchanged fire must not re-announce itself")


func test_the_campfire_carries_the_light_radius_from_its_data() -> void:
	var fire := _station(CAMPFIRE)
	assert_almost_eq(float(fire.get("light_radius")), 6.0, 0.001)
	assert_almost_eq(
		float((_piece(CAMPFIRE)[STATION.KEY] as Dictionary)["light_radius"]),
		float(fire.get("light_radius")), 0.001,
		"the light must come from the catalogue, not from a number in the code"
	)


# --- the save round trip --------------------------------------------------

func test_a_station_puts_its_state_into_a_placement_record() -> void:
	var fire := _station(CAMPFIRE)
	fire.call("set_lit", false)
	var record := STATION.write_record({"piece": CAMPFIRE, "x": 1.0, "y": 0.0, "z": 2.0}, fire)
	assert_true(record.has(STATION.KEY), "a station's record must carry its state")
	assert_false(bool((record[STATION.KEY] as Dictionary)["lit"]))
	assert_eq(str(record["piece"]), CAMPFIRE, "and must not disturb the placement it is merged into")


func test_a_fire_the_player_put_out_stays_out_across_a_reload() -> void:
	# The reason a record carries station state at all. The catalogue knows a
	# campfire starts lit; only the save file knows this one does not.
	var before := _station(CAMPFIRE)
	before.call("set_lit", false)
	var record := STATION.write_record({"piece": CAMPFIRE}, before)

	var after := _station(CAMPFIRE)
	assert_true(bool(after.call("is_lit")), "a fresh campfire starts lit")
	after.call("load_state", STATION.read_record(record))
	assert_false(bool(after.call("is_lit")), "a reloaded campfire must come back as it was left")


func test_a_reloaded_station_comes_back_a_station_not_bare_geometry() -> void:
	# What `structures.load_data()` does, at the level this file can reach: the
	# record names the piece, the piece names the behaviour, so the station is
	# rebuilt from the catalogue with no help from the save file.
	var record := {"piece": PAL_BED, "x": 4.0, "y": 1.0, "z": 6.0, "yaw_deg": 90.0}
	var rebuilt: Node = STATION.create(_piece(str(record["piece"])))
	assert_ne(rebuilt, null, "a saved pal bed must reload as a pal bed")
	_built.append(rebuilt)
	rebuilt.call("setup", str(record["piece"]), STATION.config_of(_piece(str(record["piece"]))),
		Vector3(float(record["x"]), float(record["y"]), float(record["z"])))
	assert_eq(rebuilt.call("where"), Vector3(4.0, 1.0, 6.0))
	assert_eq(int(rebuilt.get("capacity")), 1)


func test_a_wall_saves_exactly_what_it_saved_before_stations_existed() -> void:
	# The no-regression guard on the twenty-eight. A record for a piece with no
	# station must not grow a key, or every existing save file changes shape.
	var record := {"piece": "wall_plaster_straight", "x": 0.0, "y": 0.0, "z": 0.0, "yaw_deg": 0.0}
	var written := STATION.write_record(record, null)
	assert_false(written.has(STATION.KEY), "a wall's record must stay a wall's record")
	assert_eq(written.size(), record.size())


func test_a_bed_saves_no_occupancy() -> void:
	# Nothing is asleep at the moment a save loads: pals come back through the
	# party domain as records, not as the objects that were in this array, so a
	# persisted sleeper would restore a reference to something that is gone.
	var bed := _station(PAL_BED)
	bed.call("begin_rest", Sleeper.new("bruno"))
	var written := STATION.write_record({"piece": PAL_BED}, bed)
	assert_false(written.has(STATION.KEY), "occupancy is runtime state and must not be saved")


func test_reading_a_record_with_no_station_gives_nothing_rather_than_junk() -> void:
	assert_eq(STATION.read_record({"piece": "floor_brick"}), {})
	assert_eq(STATION.read_record({"piece": "floor_brick", "station": "nonsense"}), {},
		"a corrupted station key must not be handed to a station as state")


# --- the catalogue agrees with the code -----------------------------------

func test_the_three_station_pieces_are_in_the_catalogue() -> void:
	var pieces := _pieces()
	for id: String in [BED, PAL_BED, CAMPFIRE]:
		assert_true(pieces.has(id), "the M8 list needs '%s'" % id)
		assert_true(ResourceLoader.exists(str((pieces[id] as Dictionary)["model"])),
			"'%s' names a model that does not exist" % id)


func test_every_station_in_the_catalogue_names_a_behaviour_that_exists() -> void:
	var known := [STATION.BEHAVIOUR_REST, STATION.BEHAVIOUR_HEARTH]
	var found := 0
	for id: String in _pieces().keys():
		var config := STATION.config_of(_pieces()[id] as Dictionary)
		if config.is_empty():
			continue
		found += 1
		assert_true(known.has(str(config.get("behaviour", ""))),
			"piece '%s' asks for behaviour '%s', which nothing implements" % [id, config.get("behaviour", "")])
	assert_eq(found, 3, "three pieces carry behaviour; the rest are geometry")


func test_stations_place_on_the_same_grid_as_everything_else() -> void:
	# A station is a normal piece. If one of these ever needed its own anchor or
	# its own footprint it would be a special case in placement, and it is not.
	for id: String in [BED, PAL_BED, CAMPFIRE]:
		var piece := _piece(id)
		var cells: Array = piece["size_cells"]
		assert_eq(str(piece["anchor"]), "cell", "'%s' must snap like any other piece" % id)
		# `int()`, because JSON has one number type and every size in the file
		# parses back as a float.
		assert_eq(Vector2i(int(cells[0]), int(cells[1])), Vector2i(1, 1),
			"'%s' must fit one cell" % id)


func test_no_piece_carries_a_build_cost_yet() -> void:
	# There is no inventory to spend from, and a placeholder `cost` key is the
	# kind of thing that gets read as working. When costs arrive they go on every
	# piece at once, and this test is the one to delete.
	var without := 0
	for id: String in _pieces().keys():
		assert_false((_pieces()[id] as Dictionary).has("cost"),
			"piece '%s' has a cost, but nothing can pay it yet" % id)
		without += 1
	assert_eq(without, _pieces().size())


func test_no_station_can_be_told_to_work() -> void:
	# CLAUDE.md, twice over: "Pals do not perform base jobs." A pal bed is
	# somewhere a pal sleeps. The day one of these answers to `assign` or
	# `produce`, the hard rule has been broken by whoever added the method and
	# this is where it should stop.
	for id: String in [BED, PAL_BED, CAMPFIRE]:
		var station := _station(id)
		for verb: String in ["assign", "work", "produce", "staff", "set_worker", "output"]:
			assert_false(station.has_method(verb),
				"station '%s' has a '%s' method; pals do not perform base jobs" % [id, verb])
