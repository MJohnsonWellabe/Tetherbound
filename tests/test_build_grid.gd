extends "res://tests/test_case.gd"

## Where a build piece lands.
##
## Snapping is arithmetic, so it is testable with numbers and no scene — which
## matters here more than usual, because every way this goes wrong produces a
## piece that places successfully, saves, reloads and reads as an art bug. A
## wall half a cell out looks like a bad model. A wall taking the player's yaw
## instead of its edge's looks like a rotation bug. Neither would fail a test
## that only asserted "the piece exists".
##
## These also pin the numbers against the ART. If the kit is ever swapped, the
## first thing that should break is `test_the_grid_matches_the_kit_it_was_measured_from`.

const GRID := preload("res://scripts/building/build_grid.gd")
const CATALOGUE := "res://data/building/pieces.json"


# --- the measured constants -----------------------------------------------

func test_the_grid_matches_the_kit_it_was_measured_from() -> void:
	# Read off the Quaternius kit's glTF accessors: walls are 2.000m wide,
	# floors 2x2, `Wall_Arch` exactly 3.0 tall, stairs rise exactly 1m.
	assert_almost_eq(GRID.CELL, 2.0, 0.0001, "cell size must match the kit's 2m wall")
	assert_almost_eq(GRID.HALF_CELL, 1.0, 0.0001, "half-step must match the kit's half floors")
	assert_almost_eq(GRID.STOREY, 3.0, 0.0001, "storey must match Wall_Arch's 3.0m height")
	assert_almost_eq(GRID.STAIR_RISE, 1.0, 0.0001, "three stairs must make one storey")
	assert_almost_eq(GRID.STOREY / GRID.STAIR_RISE, 3.0, 0.0001, "stairs must divide a storey exactly")


# --- cell anchoring -------------------------------------------------------

func test_a_point_snaps_to_the_centre_of_its_cell() -> void:
	# Cell centres sit at odd multiples of half a cell: 1, 3, 5...
	var snapped: Vector3 = GRID.snap_to_cell(Vector3(0.4, 12.0, 0.4))
	assert_almost_eq(snapped.x, 1.0)
	assert_almost_eq(snapped.z, 1.0)
	assert_almost_eq(snapped.y, 12.0, 0.0001, "height must pass through untouched")


func test_snapping_is_stable() -> void:
	# Snapping an already-snapped point must not move it, or a ghost jitters
	# between two cells while the player stands still.
	var once: Vector3 = GRID.snap_to_cell(Vector3(5.3, 0.0, -2.9))
	var twice: Vector3 = GRID.snap_to_cell(once)
	assert_almost_eq(once.x, twice.x)
	assert_almost_eq(once.z, twice.z)


func test_negative_coordinates_snap_the_same_way() -> void:
	# `floor` rather than `int` truncation: at -0.4 the two disagree, and the
	# bug only ever shows up west or north of the origin.
	var snapped: Vector3 = GRID.snap_to_cell(Vector3(-0.4, 0.0, -0.4))
	assert_almost_eq(snapped.x, -1.0)
	assert_almost_eq(snapped.z, -1.0)


func test_adjacent_cells_are_exactly_one_cell_apart() -> void:
	var a: Vector3 = GRID.snap_to_cell(Vector3(0.5, 0.0, 0.5))
	var b: Vector3 = GRID.snap_to_cell(Vector3(2.5, 0.0, 0.5))
	assert_almost_eq(b.x - a.x, GRID.CELL, 0.0001, "neighbouring floors must meet with no gap")


# --- edge anchoring, the one that matters ---------------------------------

func test_a_wall_snaps_to_an_edge_not_a_centre() -> void:
	# Near the +X edge of the cell centred at (1, 1).
	var edge: Dictionary = GRID.snap_to_edge(Vector3(1.9, 0.0, 1.0))
	var at: Vector3 = edge["position"]
	assert_almost_eq(at.x, 2.0, 0.0001, "an X edge sits on a cell boundary")
	assert_almost_eq(at.z, 1.0, 0.0001, "and stays centred along the other axis")


func test_an_edge_decides_its_own_facing() -> void:
	# A wall lies ALONG the edge it is on, so the two axes must differ by 90
	# degrees. Taking yaw from the player instead floats walls diagonally across
	# cell corners, which is the defect this return value exists to prevent.
	var on_x: Dictionary = GRID.snap_to_edge(Vector3(1.9, 0.0, 1.0))
	var on_z: Dictionary = GRID.snap_to_edge(Vector3(1.0, 0.0, 1.9))
	assert_almost_eq(absf(angle_difference(float(on_x["yaw"]), float(on_z["yaw"]))), PI * 0.5, 0.0001)


func test_the_four_edges_of_one_cell_are_distinct() -> void:
	var centre := Vector3(1.0, 0.0, 1.0)
	var seen: Array[String] = []
	for offset in [Vector3(0.9, 0, 0), Vector3(-0.9, 0, 0), Vector3(0, 0, 0.9), Vector3(0, 0, -0.9)]:
		var at: Vector3 = (GRID.snap_to_edge(centre + offset) as Dictionary)["position"]
		var key := "%.2f,%.2f" % [at.x, at.z]
		assert_false(seen.has(key), "two edges of one cell landed on the same spot: %s" % key)
		seen.append(key)


func test_walls_on_a_shared_edge_land_on_the_same_spot() -> void:
	# Approached from either of the two cells that share it. If these disagree,
	# a room's walls do not meet its neighbour's and every terrace has a seam.
	var from_left: Vector3 = (GRID.snap_to_edge(Vector3(1.8, 0, 1.0)) as Dictionary)["position"]
	var from_right: Vector3 = (GRID.snap_to_edge(Vector3(2.2, 0, 1.0)) as Dictionary)["position"]
	assert_almost_eq(from_left.x, from_right.x, 0.0001)
	assert_almost_eq(from_left.z, from_right.z, 0.0001)


func test_snap_dispatches_on_the_anchor() -> void:
	var cell: Dictionary = GRID.snap(Vector3(1.9, 0, 1.0), GRID.ANCHOR_CELL)
	var edge: Dictionary = GRID.snap(Vector3(1.9, 0, 1.0), GRID.ANCHOR_EDGE)
	assert_almost_eq((cell["position"] as Vector3).x, 1.0, 0.0001, "a floor takes the cell centre")
	assert_almost_eq((edge["position"] as Vector3).x, 2.0, 0.0001, "a wall takes the edge")
	assert_true(is_nan(float(cell["yaw"])), "a cell anchor must not dictate a facing")


# --- rotation -------------------------------------------------------------

func test_yaw_snaps_to_quarter_turns() -> void:
	assert_almost_eq(GRID.snap_yaw(0.3), 0.0, 0.0001)
	assert_almost_eq(GRID.snap_yaw(1.4), PI * 0.5, 0.0001)
	assert_almost_eq(GRID.snap_yaw(PI - 0.2), PI, 0.0001)


func test_yaw_is_normalised_so_a_save_file_is_stable() -> void:
	# -90 and +270 are the same rotation; if they serialise differently, two
	# identical houses produce two different save files.
	assert_almost_eq(GRID.snap_yaw(-PI * 0.5), GRID.snap_yaw(PI * 1.5), 0.0001)
	assert_between(GRID.snap_yaw(-PI * 0.5), 0.0, TAU)


# --- footprints -----------------------------------------------------------

func test_a_footprint_has_four_corners_spanning_its_cells() -> void:
	var corners: Array[Vector3] = GRID.footprint_corners(Vector3.ZERO, Vector2i(1, 1), 0.0)
	assert_eq(corners.size(), 4)
	for corner: Vector3 in corners:
		assert_almost_eq(absf(corner.x), GRID.CELL * 0.5, 0.0001)
		assert_almost_eq(absf(corner.z), GRID.CELL * 0.5, 0.0001)


func test_a_bigger_piece_samples_a_bigger_area() -> void:
	# The reason corners are sampled at all: a 3x4 roof spans ground a 1x1 check
	# would never look at.
	var small: Array[Vector3] = GRID.footprint_corners(Vector3.ZERO, Vector2i(1, 1), 0.0)
	var large: Array[Vector3] = GRID.footprint_corners(Vector3.ZERO, Vector2i(3, 4), 0.0)
	assert_true(absf(large[0].z) > absf(small[0].z), "a 3x4 piece must sample further out than a 1x1")


func test_rotating_a_footprint_moves_its_corners() -> void:
	var square: Array[Vector3] = GRID.footprint_corners(Vector3.ZERO, Vector2i(1, 3), 0.0)
	var turned: Array[Vector3] = GRID.footprint_corners(Vector3.ZERO, Vector2i(1, 3), PI * 0.5)
	assert_almost_eq(absf(square[0].z), absf(turned[0].x), 0.0001,
		"a rotated footprint must sample the ground it actually covers")


# --- the catalogue agrees with the grid -----------------------------------

func test_every_piece_names_a_model_that_exists() -> void:
	for id: String in _pieces().keys():
		var piece: Dictionary = _pieces()[id]
		assert_true(ResourceLoader.exists(str(piece["model"])),
			"piece '%s' names a model that does not exist: %s" % [id, piece["model"]])


func test_every_piece_declares_a_known_anchor() -> void:
	for id: String in _pieces().keys():
		var anchor := str((_pieces()[id] as Dictionary)["anchor"])
		assert_true(anchor == GRID.ANCHOR_CELL or anchor == GRID.ANCHOR_EDGE,
			"piece '%s' has anchor '%s', which the grid does not know" % [id, anchor])


func test_walls_and_floors_disagree_about_their_anchor() -> void:
	# The whole reason `anchor` exists. If a refactor ever makes these the same,
	# every wall in the game moves a metre and it will look like an art problem.
	var pieces := _pieces()
	assert_eq(str((pieces["wall_plaster_straight"] as Dictionary)["anchor"]), GRID.ANCHOR_EDGE)
	assert_eq(str((pieces["floor_wooddark"] as Dictionary)["anchor"]), GRID.ANCHOR_CELL)


func test_colliders_are_not_larger_than_their_footprint_claims() -> void:
	# A collider wider than the piece is an invisible wall beside a doorway.
	for id: String in _pieces().keys():
		var piece: Dictionary = _pieces()[id]
		var cells: Array = piece["size_cells"]
		var extents: Array = piece["collider_extents"]
		# Roofs legitimately overhang their footprint, so they are exempt.
		if str(piece["category"]) == "roof":
			continue
		var allowed_x := float(cells[0]) * GRID.CELL * 0.5 + 0.2
		assert_true(float(extents[0]) <= allowed_x,
			"piece '%s' has a collider %.2fm wide for a %d-cell footprint" % [id, float(extents[0]) * 2.0, int(cells[0])])


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
