extends TestCase
const ROUTE := preload("res://tools/gate_f/village_passage_route.gd")
const BOUNDARY := preload("res://scripts/world/village_boundary.gd")

func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/village_boundary.json"))

func gates(opened: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for gate: Dictionary in config().gates.entries:
		out.append({"id": gate.id, "at": Vector2(gate.at[0], gate.at[1]), "open": opened})
	return out

func check_route(from: Vector2, target: Vector2, opened: bool) -> Dictionary:
	var result := ROUTE.plan(config(), from, target, gates(opened))
	assert_true(result.ok, str(result))
	if not result.ok: return result
	var walls := ROUTE.solid_edges(BOUNDARY.outline(config()), gates(opened))
	var previous := from
	for point: Vector2 in result.waypoints:
		assert_true(ROUTE.clear_segment(previous, point, walls), "Every physical leg clears the same solid fence")
		previous = point
	assert_eq(previous, target, "Routing never substitutes another foe or endpoint")
	return result

func test_native_r14_inside_to_galecrest_and_reverse_use_open_passage() -> void:
	var start := Vector2(45.99, -42.67)
	var target := Vector2(34.3026, -119.1532)
	var out := check_route(start, target, true)
	assert_true(out.waypoints.size() > 1)
	assert_true(float(out.length_m) < 2000.0 * 5.0 / 60.0,
		"Geometry must fit original walk budget before any live traversal claim")
	check_route(target, start, true)

func test_closed_gate_refuses_crossing_but_allows_outside_detour() -> void:
	assert_false(ROUTE.plan(config(), Vector2(45.99, -42.67), Vector2(34.3026, -119.1532), gates(false)).ok)
	var around := check_route(Vector2(-60, -10), Vector2(70, -10), false)
	assert_true(around.waypoints.size() > 1, "Both endpoints outside does not make a fence-crossing chord valid")
	check_route(Vector2(-60, -10), Vector2(70, -10), true)

func test_clear_same_side_walk_needs_no_detour_and_unrelated_open_gate_cannot_cut_fence() -> void:
	var result := check_route(Vector2(0, 0), Vector2(5, 0), false)
	assert_eq(result.waypoints.size(), 1)
	var unrelated: Array[Dictionary] = [{"id": "fake", "at": Vector2(0, 1000), "open": true}]
	assert_false(ROUTE.plan(config(), Vector2(45.99, -42.67), Vector2(34.3026, -119.1532), unrelated).ok)

func test_near_panel_walk_away_and_square_corner_clearance() -> void:
	check_route(Vector2(53, -50), Vector2(50, -50), false)
	var walls := ROUTE.solid_edges(BOUNDARY.outline(config()), gates(true))
	var overlapping := Vector2(54, -58) + Vector2(1, -1).normalized() * 1.7
	assert_false(ROUTE.clear_segment(overlapping, overlapping, walls),
		"A radius-.4 capsule overlaps the square corner even beyond its half-width")

class BoundaryFixture extends Node3D:
	var _config: Dictionary
	var _gates: Array[Node3D] = []

func test_next_replans_a_small_moving_target_across_fence() -> void:
	var world := Node3D.new()
	var boundary := BoundaryFixture.new()
	boundary.name = "VillageBoundary"
	boundary._config = config()
	world.add_child(boundary)
	var router = ROUTE.new(world)
	var first: Dictionary = router.next(Vector2(50, -50), Vector2(53.2, -50))
	assert_true(first.ok)
	var moved: Dictionary = router.next(Vector2(50, -50), Vector2(54.2, -50))
	assert_false(moved.ok, "A sub-two-metre target move cannot cross a closed fence")
	world.free()

func test_existing_endpoint_can_leave_padding_but_cannot_cut_through_it() -> void:
	var result := ROUTE.plan(config(), Vector2(55.6, -58), Vector2(60, -58), gates(false))
	assert_true(result.ok, "Physically clear square-face start can move away")
	assert_eq(result.waypoints.size(), 1)
	var panel := ROUTE.plan(config(), Vector2(54.7, -50), Vector2(60, -50), gates(false))
	assert_true(panel.ok, "Actual capsule clearance need not satisfy extra planner margin")
	var corner: Array[Dictionary] = [{"a": Vector2.ZERO, "b": Vector2.ZERO, "clearance": 2.05}]
	assert_false(ROUTE.clear_segment(Vector2(-1.6, 0), Vector2(1.6, 0), corner, true),
		"Endpoint relaxation never permits a chord nearer the post than both endpoints")
