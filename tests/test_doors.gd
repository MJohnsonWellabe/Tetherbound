extends "res://tests/test_case.gd"

## Doors: the offset that put them in the wrong place, and the behaviour that
## made them open.
##
## The owner played and reported both at once — "there's no way to open doors and
## you have the doors placed in entirely the wrong place ... needs like a half
## offset" — and they are two separate defects with one thing in common: every
## test in the suite was green while both were true, because both are facts about
## MEASUREMENTS rather than about control flow.
##
## So the first half of this file is arithmetic against numbers read off the
## kit's own glTF accessors, written down here with their provenance. That is the
## D12 discipline applied to the one piece D12 did not measure: it established
## that a wall's origin is the middle of a cell EDGE and a floor's is the CELL,
## and stopped there. A door leaf has a third origin — its HINGE — and nothing
## had ever checked it.
##
## THE MEASUREMENTS, all from `assets/buildings/*.gltf` POSITION accessors:
##
##   Wall_Plaster_Door_Round   x -1.0000 .. 1.0000   the 2m cell, exactly
##     its opening               x -0.6495 .. 0.6551   centre +0.0028, 1.305m wide
##     its opening head          y 0 .. 2.1560         then an arch to 2.4820
##   Door_1_Round              x -0.0463 .. 1.0737   centre +0.5137, 1.120m wide
##   Door_2_Round              x -0.0427 .. 1.0728   centre +0.5151, 1.116m wide
##
## Put the leaf on the doorway's own origin and its centre lands at +0.514 while
## the hole's is at +0.003. That is the whole bug, and it is 0.511m — half a leaf
## — which is exactly what "needs like a half offset" describes.

const STATION := preload("res://scripts/building/station.gd")
const STRUCTURES := preload("res://scripts/building/structures.gd")
const CATALOGUE := "res://data/building/pieces.json"

const LEAF := "door_1_round"
const LEAF_2 := "door_2_round"
const DOORWAY := "wall_plaster_door_round"
const DOORWAY_BRICK := "wall_unevenbrick_door_round"

## Read off the accessors. Named constants rather than magic numbers in an
## assertion, so a future reader can check them against the models rather than
## against this file.
const OPENING_MIN_X := -0.6495
const OPENING_MAX_X := 0.6551
## The arch springing line: below this the opening is a clean rectangle.
const OPENING_HEAD_Y := 2.1560
const LEAF_MIN_X := -0.0463
const LEAF_MAX_X := 1.0737

var _built: Array[Node] = []


func after_each() -> void:
	for node: Node in _built:
		if is_instance_valid(node):
			node.free()
	_built.clear()


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


func _piece(piece_id: String) -> Dictionary:
	return _pieces().get(piece_id, {})


func _door(piece_id: String = LEAF, at: Vector3 = Vector3.ZERO, yaw: float = 0.0) -> Node:
	var station: Node = STATION.create(_piece(piece_id))
	if station != null:
		station.call("setup", piece_id, STATION.config_of(_piece(piece_id)), at, yaw)
		_built.append(station)
	return station


# --- the half offset --------------------------------------------------------


func test_the_kit_hinges_its_doors_on_their_own_edge() -> void:
	# The premise everything below rests on. A leaf whose origin were its centre
	# would need no offset and could not be swung about a hinge either.
	var mid := (LEAF_MIN_X + LEAF_MAX_X) * 0.5
	assert_almost_eq(mid, 0.5137, 0.001,
		"Door_1_Round's mesh centre is not half a leaf from its origin")
	assert_true(absf(LEAF_MIN_X) < 0.1, "the leaf's origin is not on its hinge edge")


func test_a_leaf_placed_on_the_doorways_origin_is_half_a_leaf_out() -> void:
	# THE BUG, as a number. This is what the owner saw and it is what the
	# settlement and the build palette both did.
	var opening_centre := (OPENING_MIN_X + OPENING_MAX_X) * 0.5
	var leaf_centre := (LEAF_MIN_X + LEAF_MAX_X) * 0.5
	assert_almost_eq(leaf_centre - opening_centre, 0.511, 0.005,
		"the uncorrected error is not the half-leaf the owner described")
	# And it is not a near miss: half the leaf ends up over the pier beside the
	# opening rather than in it.
	assert_true(leaf_centre + (LEAF_MAX_X - LEAF_MIN_X) * 0.5 > OPENING_MAX_X,
		"an uncorrected leaf would still be inside the opening, so this is not the bug")


func test_the_catalogue_corrects_it_and_centres_the_leaf() -> void:
	# THE FIX, checked against the same numbers. `hangs` must land the leaf's
	# middle on the opening's middle.
	var opening_centre := (OPENING_MIN_X + OPENING_MAX_X) * 0.5
	for id: String in [LEAF, LEAF_2]:
		var offset := STRUCTURES.hang_offset(_piece(id))
		assert_ne(offset, Vector3.ZERO, "piece '%s' declares no `hangs` offset" % id)
		var extents: Array = (_piece(id) as Dictionary)["collider_extents"]
		var centre: Array = (_piece(id) as Dictionary)["collider_centre"]
		var hung := float(centre[0]) + offset.x
		assert_almost_eq(hung, opening_centre, 0.02,
			"'%s' hangs with its centre at %.3f, not in the middle of the opening" % [id, hung])
		# And the whole leaf fits: no part of it buried in a pier.
		assert_true(hung - float(extents[0]) >= OPENING_MIN_X - 0.01,
			"'%s' overhangs the left jamb" % id)
		assert_true(hung + float(extents[0]) <= OPENING_MAX_X + 0.01,
			"'%s' overhangs the right jamb" % id)


func test_the_offset_is_in_the_pieces_own_frame_so_it_turns_with_it() -> void:
	# A door on the north face of a cottage and one on the east face are the same
	# piece at different yaws. If the correction were a world-space offset it
	# would be right on one wall and a metre out on the next — which is the same
	# class of bug as taking a wall's facing from the player instead of from its
	# edge (D12), and it would look identical.
	var offset := STRUCTURES.hang_offset(_piece(LEAF))
	var snapped := Vector3(4.0, 0.0, 7.0)
	var placed_north := snapped + Basis(Vector3.UP, 0.0) * offset
	var placed_east := snapped + Basis(Vector3.UP, PI * 0.5) * offset
	assert_almost_eq(placed_north.x - snapped.x, offset.x, 0.001)
	assert_almost_eq(placed_north.z - snapped.z, 0.0, 0.001)
	# Turned a quarter, the same local -X becomes +Z.
	assert_almost_eq(placed_east.z - snapped.z, -offset.x, 0.001)
	assert_almost_eq(placed_east.x - snapped.x, 0.0, 0.001)


func test_only_a_leaf_is_offset_and_the_rest_of_the_kit_is_not() -> void:
	# `hangs` must not spread. Every other piece sits on the point it was snapped
	# to, and a stray offset on a wall would move a whole village.
	var offset_pieces: Array[String] = []
	for id: String in _pieces().keys():
		if STRUCTURES.hang_offset(_pieces()[id] as Dictionary) != Vector3.ZERO:
			offset_pieces.append(id)
	offset_pieces.sort()
	assert_eq(offset_pieces, [LEAF, LEAF_2] as Array[String],
		"exactly the two door leaves hang off their snap point")


func test_a_leaf_may_share_its_grid_slot_with_the_doorway_it_hangs_in() -> void:
	# They are two models of one thing and snap to the same cell edge. Before
	# this exception the palette refused the second of them with "something is
	# already there", which makes the pair unusable.
	var structures := Node3D.new()
	structures.set_script(STRUCTURES)
	_built.append(structures)
	var at := Vector3(6.0, 0.0, 4.0)
	assert_ne(structures.call("place", DOORWAY, at, 0.0), null, "the doorway did not place")
	assert_false(bool(structures.call("occupied", at, 0.0, LEAF)),
		"a door leaf was refused the doorway it belongs in")
	assert_true(bool(structures.call("occupied", at, 0.0, "wall_plaster_straight")),
		"a solid wall must still be refused a slot that is taken")


func test_placing_a_leaf_puts_it_where_the_offset_says() -> void:
	# The offset arriving in the world, rather than only in the data. `place()`
	# is the one path a fresh placement and a load from disk share.
	var structures := Node3D.new()
	structures.set_script(STRUCTURES)
	_built.append(structures)
	var at := Vector3(6.0, 1.5, 4.0)
	var node: Node3D = structures.call("place", LEAF, at, 0.0)
	assert_ne(node, null, "the leaf did not place")
	if node == null:
		return
	var offset := STRUCTURES.hang_offset(_piece(LEAF))
	assert_almost_eq(node.position.x, at.x + offset.x, 0.001,
		"the placed leaf ignored its `hangs` offset")
	# And the RECORD keeps the snapped point, so a reload applies it once rather
	# than drifting by half a leaf every time the game is loaded.
	var record: Dictionary = (structures.call("records") as Array)[0]
	assert_almost_eq(float(record["x"]), at.x, 0.001,
		"the record moved with the art; a reload would offset it again")


# --- the doorway is not sealed shut -----------------------------------------


func _covers(piece: Dictionary, point: Vector3) -> bool:
	for box: Dictionary in STRUCTURES.collider_boxes(piece):
		var centre: Array = box["centre"]
		var extents: Array = box["extents"]
		var local := point - Vector3(float(centre[0]), float(centre[1]), float(centre[2]))
		if absf(local.x) <= float(extents[0]) \
				and absf(local.y) <= float(extents[1]) \
				and absf(local.z) <= float(extents[2]):
			return true
	return false


func test_a_doorway_has_collision_where_the_wall_is() -> void:
	for id: String in [DOORWAY, DOORWAY_BRICK]:
		var piece := _piece(id)
		assert_true(_covers(piece, Vector3(-0.85, 1.0, 0.0)),
			"'%s' has no collision in its left pier" % id)
		assert_true(_covers(piece, Vector3(0.85, 1.0, 0.0)),
			"'%s' has no collision in its right pier" % id)
		assert_true(_covers(piece, Vector3(0.0, 2.9, 0.0)),
			"'%s' has no collision in its lintel" % id)


func test_a_doorway_has_none_where_the_doorway_is() -> void:
	# The defect this catches: `collider_extents` alone is one box 2m x 3.12m,
	# which seals the opening. Every pre-built cottage in the Meadows was shut,
	# and the door hanging in it would have been decoration.
	for id: String in [DOORWAY, DOORWAY_BRICK, "doorframe_round_brick", "doorframe_round_wooddark"]:
		var piece := _piece(id)
		for height in [0.1, 0.9, 1.8]:
			assert_false(_covers(piece, Vector3(0.0, height, 0.0)),
				"'%s' is solid in the middle of its own doorway at %.1fm" % [id, height])


func test_the_opening_is_wide_and_tall_enough_for_the_trainer() -> void:
	# The trainer is a 1.80m capsule. A doorway that technically has a hole in it
	# and is 1.2m tall is the same bug wearing a different number.
	var piece := _piece(DOORWAY)
	assert_false(_covers(piece, Vector3(0.0, 1.75, 0.0)), "the head clearance is under 1.8m")
	assert_true(OPENING_HEAD_Y >= 2.0, "the measured head is lower than a person")
	assert_true(OPENING_MAX_X - OPENING_MIN_X >= 1.0, "the measured opening is under a metre wide")


func test_every_collider_box_stays_inside_the_pieces_own_bounds() -> void:
	# A box outside the measured bound is an invisible wall beside a doorway,
	# which is the failure `test_colliders_are_not_larger_than_their_footprint_claims`
	# guards for the single-box case. The multi-box case needs the same guard.
	for id: String in _pieces().keys():
		var piece: Dictionary = _pieces()[id]
		if not piece.has("collider_boxes"):
			continue
		var centre: Array = piece["collider_centre"]
		var extents: Array = piece["collider_extents"]
		for box: Dictionary in STRUCTURES.collider_boxes(piece):
			var box_centre: Array = box["centre"]
			var box_extents: Array = box["extents"]
			for axis in 3:
				var low := float(box_centre[axis]) - float(box_extents[axis])
				var high := float(box_centre[axis]) + float(box_extents[axis])
				assert_true(low >= float(centre[axis]) - float(extents[axis]) - 0.005,
					"'%s' has a collider box outside its own bounds on axis %d" % [id, axis])
				assert_true(high <= float(centre[axis]) + float(extents[axis]) + 0.005,
					"'%s' has a collider box outside its own bounds on axis %d" % [id, axis])


# --- the door opens ---------------------------------------------------------


func test_a_door_starts_shut() -> void:
	var door := _door()
	assert_ne(door, null, "the door leaf has no station")
	assert_eq(str(door.get("behaviour")), STATION.BEHAVIOUR_DOOR)
	assert_false(bool(door.call("is_open")))
	assert_almost_eq(float(door.call("angle")), 0.0, 0.0001)


func test_a_door_opens_and_shuts_again() -> void:
	var door := _door()
	assert_true(bool(door.call("toggle", Vector3(0.0, 0.0, 2.0))), "the door refused to open")
	assert_true(bool(door.call("is_open")))
	assert_true(bool(door.call("toggle", Vector3(0.0, 0.0, 2.0))), "the door refused to shut")
	assert_false(bool(door.call("is_open")))


func test_opening_and_shutting_are_announced() -> void:
	# So a sound, a prompt or a pal's pathing can hang off them later without
	# polling every door in the village.
	var door := _door()
	var log: Array[String] = []
	door.connect("opened", func() -> void: log.append("opened"))
	door.connect("closed", func() -> void: log.append("closed"))
	door.call("toggle", Vector3(0.0, 0.0, 2.0))
	door.call("toggle", Vector3(0.0, 0.0, 2.0))
	assert_eq(log, ["opened", "closed"] as Array[String])


func test_a_door_already_open_is_not_opened_again() -> void:
	var door := _door()
	assert_true(bool(door.call("set_open", true, Vector3(0.0, 0.0, 2.0))))
	assert_false(bool(door.call("set_open", true, Vector3(0.0, 0.0, 2.0))),
		"opening an open door reported a change")


func test_a_door_swings_away_from_whoever_opened_it() -> void:
	# Not politeness. A leaf that always swings the same way sweeps its collider
	# through the player half the time, and a StaticBody3D travelling through a
	# CharacterBody3D is how somebody ends up inside geometry.
	var outside := _door()
	outside.call("toggle", Vector3(0.0, 0.0, 2.0))
	outside.call("snap")
	var inside := _door()
	inside.call("toggle", Vector3(0.0, 0.0, -2.0))
	inside.call("snap")
	assert_eq(int(outside.call("swing")), 1)
	assert_eq(int(inside.call("swing")), -1)
	assert_true(float(outside.call("angle")) * float(inside.call("angle")) < 0.0,
		"two doors opened from opposite sides swung the same way")


func test_it_opens_from_either_side_however_the_wall_is_turned() -> void:
	# The side is decided in the PIECE's frame, so a cottage turned 28 degrees to
	# face the road — which is what `settlement.json` does to Grandpa's — does not
	# get doors that swing into the people opening them.
	for yaw_deg in [0.0, 90.0, 180.0, -28.0]:
		var yaw := deg_to_rad(yaw_deg)
		var at := Vector3(3.0, 0.0, -5.0)
		var door := _door(LEAF, at, yaw)
		# Two metres out along the door's own +Z, whichever way that points.
		var outward: Vector3 = at + Basis(Vector3.UP, yaw) * Vector3(0.0, 0.0, 2.0)
		assert_eq(int(door.call("swing_for", outward)), 1,
			"a door at %.0f degrees swung the wrong way for somebody in front of it" % yaw_deg)
		var inward: Vector3 = at + Basis(Vector3.UP, yaw) * Vector3(0.0, 0.0, -2.0)
		assert_eq(int(door.call("swing_for", inward)), -1,
			"a door at %.0f degrees swung the wrong way for somebody behind it" % yaw_deg)


func test_an_open_door_is_not_left_across_its_own_doorway() -> void:
	# The other half of "must not trap the player". The leaf's collider is a child
	# of the piece node and rotates with it, so this is a question about where the
	# leaf ENDS UP: swung by ninety-odd degrees about a hinge at the jamb, its far
	# edge has to be out of the opening entirely.
	var door := _door()
	door.call("toggle", Vector3(0.0, 0.0, 2.0))
	door.call("snap")
	var angle := float(door.call("angle"))
	assert_true(absf(angle) >= deg_to_rad(85.0), "the door barely moved: %.1f degrees" % rad_to_deg(angle))
	# The free edge of the leaf, in the piece's frame, hinged on its own origin.
	var hinge := STRUCTURES.hang_offset(_piece(LEAF))
	var free_edge: Vector3 = hinge + Basis(Vector3.UP, angle) * Vector3(LEAF_MAX_X, 0.0, 0.0)
	assert_true(absf(free_edge.z) > 1.0,
		"the open leaf's free edge is still in the doorway at z=%.2f" % free_edge.z)
	assert_true(absf(free_edge.x) < 0.7,
		"the open leaf is not against the jamb it hinges on")


func test_the_swing_takes_time_rather_than_teleporting() -> void:
	var door := _door()
	door.call("toggle", Vector3(0.0, 0.0, 2.0))
	var swing_seconds := float(door.get("swing_seconds"))
	assert_true(swing_seconds > 0.0, "a door with no travel time cannot be watched opening")
	door.call("swing_towards", swing_seconds * 0.5)
	var half := absf(float(door.call("angle")))
	assert_between(half, deg_to_rad(30.0), deg_to_rad(60.0),
		"half the swing time did not put the leaf about half way")
	door.call("swing_towards", swing_seconds)
	assert_almost_eq(absf(float(door.call("angle"))), deg_to_rad(float(door.get("open_degrees"))), 0.001,
		"the swing did not finish")


func test_the_swing_does_not_drift_past_its_target() -> void:
	# `_apply()` writes `facing + angle` rather than adding to the node's own
	# rotation, so a door opened and shut fifty times is exactly where it began.
	var door := _door()
	for i in 25:
		door.call("toggle", Vector3(0.0, 0.0, 2.0))
		door.call("snap")
		door.call("toggle", Vector3(0.0, 0.0, 2.0))
		door.call("snap")
	assert_almost_eq(float(door.call("angle")), 0.0, 0.0001, "the door drifted off its frame")


# --- and it survives a reload -----------------------------------------------


func test_a_door_left_open_comes_back_open() -> void:
	# The campfire's `lit` is the precedent: the catalogue knows a door starts
	# shut, and only the save file knows this one was left standing open.
	var before := _door()
	before.call("toggle", Vector3(0.0, 0.0, -2.0))
	var record := STATION.write_record({"piece": LEAF, "x": 1.0, "y": 0.0, "z": 2.0}, before)
	assert_true(record.has(STATION.KEY), "an open door wrote nothing into its record")

	var after := _door()
	assert_false(bool(after.call("is_open")), "a fresh door is shut")
	after.call("load_state", STATION.read_record(record))
	assert_true(bool(after.call("is_open")), "the door came back shut")
	assert_eq(int(after.call("swing")), -1, "the door came back swinging the other way")
	# And it is already there rather than swinging open in front of the player.
	assert_almost_eq(absf(float(after.call("angle"))),
		deg_to_rad(float(after.get("open_degrees"))), 0.001,
		"a reloaded door was mid-swing")


func test_a_door_left_shut_comes_back_shut() -> void:
	var before := _door()
	var record := STATION.write_record({"piece": LEAF}, before)
	var after := _door()
	after.call("toggle", Vector3(0.0, 0.0, 2.0))
	after.call("load_state", STATION.read_record(record))
	assert_false(bool(after.call("is_open")))
	assert_almost_eq(float(after.call("angle")), 0.0, 0.0001)


func test_a_reloaded_door_is_still_a_door() -> void:
	var record := STATION.write_record({"piece": LEAF}, _door())
	var rebuilt: Node = STATION.create(_piece(str(record.get("piece", LEAF))))
	assert_ne(rebuilt, null, "a saved door came back as bare geometry")
	if rebuilt != null:
		_built.append(rebuilt)
		rebuilt.call("setup", LEAF, STATION.config_of(_piece(LEAF)), Vector3.ZERO, 0.0)
		assert_eq(str(rebuilt.get("behaviour")), STATION.BEHAVIOUR_DOOR)


# --- the settlement ---------------------------------------------------------


func test_the_settlement_hands_its_doors_over_rather_than_drawing_them() -> void:
	# `door_leaf` made `scatter_rules._expand_room()` emit a STATIC mesh, which is
	# a door that can never open, at the doorway's own origin, which is the half
	# offset. `door_hangs` is read by `scripts/building/doors.gd` instead. A room
	# carrying BOTH would get two leaves in one doorway, one of them dead — so
	# the old key must be gone, not merely ignored.
	var file := FileAccess.open("res://data/config/settlement.json", FileAccess.READ)
	assert_ne(file, null, "settlement.json is missing")
	if file == null:
		return
	var text := file.get_as_text()
	assert_false(text.contains("\"door_leaf\""),
		"settlement.json still draws static door leaves")

	var parsed: Variant = JSON.parse_string(text)
	assert_true(parsed is Dictionary, "settlement.json is not readable")
	if not parsed is Dictionary:
		return
	var doors := 0
	var sites: Dictionary = (parsed as Dictionary).get("sites", {})
	for site_name: String in sites.keys():
		var site: Dictionary = sites[site_name]
		for entry: Variant in site.get("rooms", []):
			var room: Dictionary = entry
			var leaf := str(room.get("door_hangs", ""))
			if leaf.is_empty():
				continue
			doors += 1
			assert_true(_pieces().has(leaf),
				"site '%s' hangs '%s', which is not in the catalogue" % [site_name, leaf])
			assert_ne(STRUCTURES.hang_offset(_piece(leaf)), Vector3.ZERO,
				"site '%s' hangs '%s', which has no `hangs` offset" % [site_name, leaf])
			# And the doorway it hangs in has to actually have a hole in it.
			var doorway := str(room.get("door", ""))
			assert_true(STRUCTURES.is_an_opening(_piece(doorway)),
				"site '%s' hangs a door in '%s', which is not an opening" % [site_name, doorway])
	assert_eq(doors, 5, "the five pre-built houses each hang one door")
