extends "res://tests/test_case.gd"

const ROUTE := preload("res://tests/helpers/gate_a_material_route.gd")
const ROAD_GATE := preload("res://scripts/world/road_gate.gd")

## These doubles exercise the existing walk loop's accounting with synthetic
## observed poses. They do not prove controller, terrain or collision travel.
class ObservedNavigator:
	extends "res://tests/helpers/stick_navigator.gd"
	var aims: Array[Vector3] = []
	var hold_checks := 0
	var hold_after_first := false
	var stall := false
	func can_walk() -> bool:
		if hold_after_first and aims.size() == 1 and hold_checks < 3:
			hold_checks += 1
			return false
		return true
	func step(point: Vector3) -> void:
		aims.append(point)
		if not stall:
			_player.position = _player.position.move_toward(Vector3(point.x, _player.position.y, point.z), 1.0)
		await _tree.physics_frame

func _boundary() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ROUTE.VILLAGE_BOUNDARY_PATH))

func _terrain() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(ROUTE.MATERIAL_TERRAIN_PATH))

func test_real_closed_edge_approach_uses_entire_authored_rise_then_clear_outside_chord() -> void:
	var boundary := _boundary()
	var terrain := _terrain()
	var start := Vector2(36, -16)
	var target := Vector2(59, -53)
	var outline := ROUTE._bounded_points(boundary.outline.points, 3, 128)
	assert_false(ROUTE._perimeter_hits(start, target, outline).is_empty(), "the original direct bearing crosses a closed fence")
	assert_false(ROUTE._perimeter_hits(Vector2(45, -22), target, outline).is_empty(), "the first outside road point still cuts back through the concave outline")
	var plan: Dictionary = ROUTE.scatter_perimeter_plan(start, target, boundary, terrain)
	assert_true(plan.get("ok", false))
	assert_true(plan.get("crosses_gate", false))
	assert_eq(plan.get("headings"), [Vector2(20, -18), Vector2(28, -18), Vector2(38.72, -19.85), Vector2(45, -22), Vector2(74, -41)])
	assert_true(ROUTE._perimeter_hits(Vector2(74, -41), target, outline).is_empty())
	var back: Dictionary = ROUTE.scatter_perimeter_plan(target, start, boundary, terrain)
	var reversed: Array = plan.headings.duplicate()
	reversed.reverse()
	assert_true(back.get("ok", false))
	assert_eq(back.get("headings"), reversed)

func test_same_side_concave_chord_requires_verified_detour_and_bad_authored_data_refuses() -> void:
	var boundary := _boundary()
	var terrain := _terrain()
	var clear: Dictionary = ROUTE.scatter_perimeter_plan(Vector2(20, -18), Vector2(28, -18), boundary, terrain)
	assert_true(clear.get("ok", false))
	assert_eq(clear.get("headings"), [])
	var concave: Dictionary = ROUTE.scatter_perimeter_plan(Vector2(45, -22), Vector2(59, -53), boundary, terrain)
	assert_true(concave.get("ok", false))
	assert_eq(concave.get("headings"), [Vector2(74, -41)], "same-side endpoints alone cannot waive a crossing")
	for bad: Variant in [null, [], {}, {"outline": {"points": [["20", -18]]}}, {"outline": {"points": [[NAN, -18]]}}]:
		assert_false(ROUTE.scatter_perimeter_plan(Vector2.ZERO, Vector2.ONE, bad, terrain).get("ok", false))
	var duplicate := terrain.duplicate(true)
	for row: Dictionary in terrain.paths.routes:
		if row.label == "The Rise": duplicate.paths.routes.append(row.duplicate(true))
	assert_false(ROUTE.scatter_perimeter_plan(Vector2(36, -16), Vector2(59, -53), boundary, duplicate).get("ok", false))
	var duplicate_gate := boundary.duplicate(true)
	duplicate_gate.gates.entries.append(duplicate_gate.gates.entries[0].duplicate(true))
	assert_false(ROUTE.scatter_perimeter_plan(Vector2(36, -16), Vector2(59, -53), duplicate_gate, terrain).get("ok", false))
	assert_true(ROUTE._bounded_points([["20", -18]], 1, 1).is_empty())
	assert_true(ROUTE._bounded_points([[NAN, -18]], 1, 1).is_empty())
	assert_true(ROUTE._bounded_points([[4097, -18]], 1, 1).is_empty())
	var oversized := boundary.duplicate(true)
	oversized.outline.points.resize(129)
	assert_false(ROUTE.scatter_perimeter_plan(Vector2.ZERO, Vector2.ONE, oversized, terrain).get("ok", false))
	assert_false(ROUTE.scatter_perimeter_plan(Vector2.INF, Vector2.ONE, boundary, terrain).get("ok", false))

func test_gate_requires_exact_current_world_live_retained_open_leaf() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var world := Node3D.new()
	tree.root.add_child(world)
	var gate: Node3D = ROAD_GATE.new()
	world.add_child(gate)
	gate.position = Vector3(38.72, 0, -19.85)
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	gate.add_child(shape)
	gate.set("_shape", shape)
	# Disclosed retained-state controls; no production gate is opened or built.
	gate.set("_open", true)
	shape.disabled = true
	var at := Vector2(38.72, -19.85)
	assert_true(ROUTE._open_material_gate(world, gate, at))
	shape.disabled = false
	assert_false(ROUTE._open_material_gate(world, gate, at))
	shape.disabled = true
	gate.set("_open", false)
	assert_false(ROUTE._open_material_gate(world, gate, at))
	gate.set("_open", true)
	gate.position.x += 1.0
	assert_false(ROUTE._open_material_gate(world, gate, at))
	gate.position.x -= 1.0
	var other := Node3D.new()
	tree.root.add_child(other)
	assert_false(ROUTE._open_material_gate(other, gate, at))
	var impostor := Node3D.new()
	world.add_child(impostor)
	assert_false(ROUTE._open_material_gate(world, impostor, at))
	world.free()
	other.free()

func test_one_walk_budget_cannot_restart_at_a_heading_or_finish_before_it() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var body := Node3D.new()
	tree.root.add_child(body)
	var nav := ObservedNavigator.new(tree, body, body, func(_x: float, _y: float) -> void: pass)
	var headings: Array[Vector3] = [Vector3(3, 100, 0)]
	assert_false(await nav.walk_to_guided(Vector3.ZERO, 4, 0.1, headings), "a waypoint must not grant a new four-frame budget, nor final-point proximity skip it")
	assert_eq(nav.aims.size(), 4)
	assert_eq(nav.aims[0], headings[0])
	assert_eq(nav.aims[3], Vector3.ZERO)
	assert_almost_eq(body.position.x, 2.0)
	body.position = Vector3.ZERO
	nav.aims.clear()
	nav.hold_after_first = true
	assert_true(await nav.walk_to_guided(Vector3(4, 0, 0), 5, 0.1, headings))
	assert_eq(nav.hold_checks, 3, "held frames resume the same retained heading")
	assert_eq(nav.aims.size(), 4, "held frames consume none of the original walking budget")
	body.free()

func test_confined_watchdog_and_finite_heading_guards_remain_in_the_same_loop() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var body := Node3D.new()
	tree.root.add_child(body)
	var nav := ObservedNavigator.new(tree, body, body, func(_x: float, _y: float) -> void: pass)
	nav.stall = true
	var headings: Array[Vector3] = [Vector3.ZERO, Vector3(2, 0, 0)]
	assert_false(await nav.walk_to_guided(Vector3(8, 0, 0), 1201, 0.1, headings))
	assert_eq(nav.aims.size(), 1201)
	assert_eq(nav.confined_resets(), 1, "waypoint transitions cannot refresh the rolling confinement watchdog")
	assert_eq(nav.aims[-1], headings[1], "confinement reset retains the unconsumed heading")
	var invalid: Array[Vector3] = [Vector3.INF]
	assert_false(await nav.walk_to_guided(Vector3.ZERO, 10, 0.1, invalid))
	assert_eq(nav.aims.size(), 1201, "nonfinite guidance cannot drive even one frame")
	body.free()
