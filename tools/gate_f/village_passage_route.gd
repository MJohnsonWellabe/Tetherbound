extends RefCounted
## Harness-only visibility route around the authored village fence. Every
## waypoint is walked by the existing navigator, under the caller's one budget.
const BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const CLEARANCE := 1.65 # Corner guard half-width 1.1 + player radius .4 + margin.
const OFFSET := 2.25
const OPEN_HALF_WIDTH := 2.0 # Conservative central portion of the 4.4m gate edge.
const WAYPOINT_CLOSE := 0.45
var _boundary: Node3D
var _config: Dictionary = {}
var _waypoints: Array[Vector2] = []
var _destination := Vector2(INF, INF)
var _signature := ""
var _failure := ""
var last_plan: Dictionary = {}

func _init(world: Node = null) -> void:
	if world != null:
		_boundary = world.get_node_or_null(^"VillageBoundary") as Node3D
		if _boundary != null:
			_config = _boundary.get("_config")

func next(from: Vector2, destination: Vector2) -> Dictionary:
	if not is_instance_valid(_boundary):
		return {"ok": true, "at": destination, "changed": false}
	var gates: Array[Dictionary] = []
	var signature := ""
	for gate: Node3D in _boundary.get("_gates"):
		var opened := bool(gate.call("is_open"))
		gates.append({"id": str(gate.name), "at": Vector2(gate.global_position.x, gate.global_position.z), "open": opened})
		signature += str(gate.name) + str(opened)
	var changed := false
	if destination.distance_to(_destination) > 2.0 or signature != _signature:
		last_plan = plan(_config, from, destination, gates)
		_destination = destination
		_signature = signature
		_failure = str(last_plan.get("reason", "")) if not last_plan.ok else ""
		_waypoints.assign(last_plan.get("waypoints", []))
		changed = true
	if not _failure.is_empty():
		return {"ok": false, "why": _failure}
	while _waypoints.size() > 1 and from.distance_to(_waypoints[0]) <= WAYPOINT_CLOSE:
		_waypoints.pop_front()
		changed = true
	# The final target remains live, including a moving pinned creature.
	return {"ok": true, "at": _waypoints[0] if _waypoints.size() > 1 else destination,
		"changed": changed}

static func plan(config: Dictionary, from: Vector2, destination: Vector2,
		gates: Array[Dictionary]) -> Dictionary:
	var outline := BOUNDARY.outline(config)
	if outline.size() < 3:
		return {"ok": false, "reason": "village passage route has no valid authored outline", "waypoints": []}
	var walls := solid_edges(outline, gates)
	if clear_segment(from, destination, walls):
		return {"ok": true, "waypoints": [destination], "length_m": from.distance_to(destination)}
	var points: Array[Vector2] = [from, destination]
	for distance: float in [-OFFSET, OFFSET]:
		for polygon: PackedVector2Array in Geometry2D.offset_polygon(outline, distance, Geometry2D.JOIN_MITER):
			for point: Vector2 in polygon:
				if clear_segment(point, point, walls): points.append(point)
	for gate: Dictionary in gates:
		if not bool(gate.get("open", false)): continue
		var at: Vector2 = gate.at
		# Derive the normal from the authored edge closest to the live gate.
		var closest := INF
		var tangent := Vector2.ZERO
		for i in outline.size():
			var a := outline[i]
			var b := outline[(i + 1) % outline.size()]
			var gap := at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b))
			if gap < closest:
				closest = gap
				tangent = (b - a).normalized()
		if closest > 0.25: continue # A moved or unrelated gate cannot cut the fence.
		var normal := Vector2(-tangent.y, tangent.x)
		for sign_value: float in [-1.0, 1.0]:
			var point := at + normal * 4.0 * sign_value
			if clear_segment(point, point, walls): points.append(point)
	var costs: Array[float] = []
	var previous: Array[int] = []
	var visited: Array[bool] = []
	for i in points.size():
		costs.append(INF)
		previous.append(-1)
		visited.append(false)
	costs[0] = 0.0
	for iteration in points.size():
		var selected := -1
		for i in points.size():
			if not visited[i] and (selected < 0 or costs[i] < costs[selected]): selected = i
		if selected < 0 or is_inf(costs[selected]): break
		if selected == 1: break
		visited[selected] = true
		for i in points.size():
			if visited[i] or i == selected: continue
			var cost := costs[selected] + points[selected].distance_to(points[i])
			if cost < costs[i] and clear_segment(points[selected], points[i], walls):
				costs[i] = cost
				previous[i] = selected
	if is_inf(costs[1]):
		return {"ok": false, "reason": "no verified open village passage connects this walk to its target", "waypoints": []}
	var route: Array[Vector2] = []
	var cursor := 1
	while cursor > 0:
		route.push_front(points[cursor])
		cursor = previous[cursor]
	return {"ok": true, "waypoints": route, "length_m": costs[1]}

## Split only where an actual open gate lies on the authored fence. Remaining
## segments include closed gate leaves; no progression flags are fabricated.
static func solid_edges(outline: PackedVector2Array, gates: Array[Dictionary]) -> Array[Dictionary]:
	var walls: Array[Dictionary] = []
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var length := a.distance_to(b)
		var tangent := (b - a).normalized()
		var cuts: Array[Vector2] = []
		for gate: Dictionary in gates:
			if not bool(gate.get("open", false)): continue
			var at: Vector2 = gate.at
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)) > 0.25: continue
			var along := (at - a).dot(tangent)
			cuts.append(Vector2(maxf(0.0, along - OPEN_HALF_WIDTH), minf(length, along + OPEN_HALF_WIDTH)))
		cuts.sort_custom(func(x: Vector2, y: Vector2) -> bool: return x.x < y.x)
		var cursor := 0.0
		for cut: Vector2 in cuts:
			if cut.x > cursor: walls.append({"a": a + tangent * cursor, "b": a + tangent * cut.x})
			cursor = maxf(cursor, cut.y)
		if cursor < length: walls.append({"a": a + tangent * cursor, "b": b})
	return walls

static func clear_segment(from: Vector2, to: Vector2, walls: Array[Dictionary]) -> bool:
	for wall: Dictionary in walls:
		var a: Vector2 = wall.a
		var b: Vector2 = wall.b
		if Geometry2D.segment_intersects_segment(from, to, a, b) != null: return false
		var gap := minf(from.distance_to(Geometry2D.get_closest_point_to_segment(from, a, b)),
			to.distance_to(Geometry2D.get_closest_point_to_segment(to, a, b)))
		gap = minf(gap, a.distance_to(Geometry2D.get_closest_point_to_segment(a, from, to)))
		gap = minf(gap, b.distance_to(Geometry2D.get_closest_point_to_segment(b, from, to)))
		if gap < CLEARANCE: return false
	return true
