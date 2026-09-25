extends "res://tests/test_case.gd"

## F01-a (WORLD 3.2 "Village form is fixed for this pass", ACCEPTANCE F01/M1).
## The village is a ROAD SETTLEMENT: one continuous through-road from Grandpa's
## door to TrailGate and on to the South Bridge, lanes that branch off it at
## T-junctions, and at least one side lane to a named working subarea. The old
## plan radiated Practice Meadow, The Pond and The Rise from the well.
##
## Everything here is computed from the SAME road polylines
## playground_heightfield.road_bands() unions -- `paths.routes`,
## `paths.approaches` and the Lower Meadows `trail.bands` entry -- clipped to
## the live village fence. `paths.village_topology` only names which roads and
## which subarea the checks are about; every claim it makes is re-derived from
## the geometry, never trusted. ralph/reports/MEADOWS-PAYOFFS/village-road/
## topology.py is the same algorithm in Python and draws the OLD/NEW plan.

const BOUNDARY := preload("res://scripts/world/village_boundary.gd")
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const HARVEST_PATH := "res://data/config/bands/band1_lower_meadows/harvest.json"
const VILLAGE_PATH := "res://data/config/village.json"

## Road vertices closer than this are one node; a node this close to a
## segment splits it (a lane joining mid-street is a real T-junction).
const SNAP_M := 0.75
## Two arm crossings of the well circle closer than this are one arm (two
## routes sharing a street prefix draw the same centreline).
const ARM_MERGE_M := 2.5
## Distinct junctions along a street must be at least this far apart, or
## several "T-junctions" are one hub drawn in pieces.
const MIN_JUNCTION_SPACING_M := 6.0
## Building footprints are shrunk by this before the centreline test: the
## aprons carry +0.2m margin and door canopies, and a road legitimately ends
## on a threshold.
const FOOTPRINT_INSET_M := 1.0

var _terrain: Dictionary = {}
var _topology: Dictionary = {}
var _outline := PackedVector2Array()
var _gates: Dictionary = {}
var _gate_clear := 3.4
## id/label -> PackedVector2Array
var _roads: Dictionary = {}
var _nodes: Array[Vector2] = []
var _adj: Dictionary = {}
## [gate_id_or_NO_GATE, Vector2, road]
var _crossings: Array = []


func before_each() -> void:
	_terrain = _json(TERRAIN_PATH)
	_topology = (_terrain.get("paths", {}) as Dictionary).get("village_topology", {}) as Dictionary
	var boundary := BOUNDARY.load_config()
	_outline = BOUNDARY.outline(boundary)
	_gates = {}
	for raw: Variant in ((boundary.get("gates", {}) as Dictionary).get("entries", []) as Array):
		var gate := raw as Dictionary
		_gates[str(gate.get("id", ""))] = _v(gate.get("at", []))
	_gate_clear = float((boundary.get("wall", {}) as Dictionary).get("gate_clear_m", 3.4))
	_roads = _village_roads()
	_build_graph()


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s parses as a JSON object" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _v(raw: Variant) -> Vector2:
	var a := raw as Array
	if a == null or a.size() < 2:
		return Vector2.INF
	return Vector2(float(a[0]), float(a[1]))


func _line(raw: Variant) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Variant in (raw as Array):
		out.append(_v(p))
	return out


func _village_roads() -> Dictionary:
	var out := {}
	var paths := _terrain.get("paths", {}) as Dictionary
	for raw: Variant in (paths.get("routes", []) as Array):
		var entry := raw as Dictionary
		out[str(entry.get("id", entry.get("label", "")))] = _line(entry.get("points", []))
	for raw: Variant in (paths.get("approaches", []) as Array):
		var entry := raw as Dictionary
		out[str(entry.get("id", entry.get("label", "")))] = _line(entry.get("points", []))
	for raw: Variant in ((_terrain.get("trail", {}) as Dictionary).get("bands", []) as Array):
		var band := raw as Dictionary
		if str(band.get("id", "")) == "band1_lower_meadows":
			out["band1_lower_meadows"] = _line(band.get("points", []))
	return out


func _node(p: Vector2) -> int:
	for i in _nodes.size():
		if _nodes[i].distance_to(p) <= SNAP_M:
			return i
	_nodes.append(p)
	return _nodes.size() - 1


## Clip every road to the fence (recording where and through which gate it
## crosses), node every vertex and intersection, split segments at every node
## on them and de-duplicate, so two routes sharing a street are one edge.
func _build_graph() -> void:
	_nodes = []
	_adj = {}
	_crossings = []
	var segs: Array = []
	for id: String in _roads:
		var pts: PackedVector2Array = _roads[id]
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var cuts: Array = [[0.0, a], [1.0, b]]
			for k in _outline.size():
				var hit: Variant = Geometry2D.segment_intersects_segment(a, b, _outline[k], _outline[(k + 1) % _outline.size()])
				if hit == null:
					continue
				var at := hit as Vector2
				cuts.append([a.distance_to(at) / maxf(a.distance_to(b), 0.0001), at])
				var gate_id := "NO GATE"
				var nearest := INF
				for gid: String in _gates:
					var d: float = (_gates[gid] as Vector2).distance_to(at)
					if d < nearest:
						nearest = d
						gate_id = gid if d <= _gate_clear + 1.0 else "NO GATE"
				_crossings.append([gate_id, at, id])
			cuts.sort_custom(func(l: Array, r: Array) -> bool: return float(l[0]) < float(r[0]))
			for c in cuts.size() - 1:
				var p0: Vector2 = cuts[c][1]
				var p1: Vector2 = cuts[c + 1][1]
				if p0.distance_to(p1) < 0.0001:
					continue
				if BOUNDARY.contains(_outline, (p0 + p1) * 0.5):
					segs.append([p0, p1])
	for s: Array in segs:
		_node(s[0])
		_node(s[1])
	for i in segs.size():
		for j in range(i + 1, segs.size()):
			var hit: Variant = Geometry2D.segment_intersects_segment(segs[i][0], segs[i][1], segs[j][0], segs[j][1])
			if hit != null:
				_node(hit as Vector2)
	for i in _nodes.size():
		_adj[i] = {}
	for s: Array in segs:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		var on: Array = []
		for k in _nodes.size():
			var c := Geometry2D.get_closest_point_to_segment(_nodes[k], a, b)
			if c.distance_to(_nodes[k]) <= SNAP_M:
				on.append([a.distance_to(c), k])
		on.sort_custom(func(l: Array, r: Array) -> bool: return float(l[0]) < float(r[0]))
		var prev := -1
		for entry: Array in on:
			var k: int = entry[1]
			if prev != -1 and prev != k:
				(_adj[prev] as Dictionary)[k] = true
				(_adj[k] as Dictionary)[prev] = true
			prev = k


func _degree(i: int) -> int:
	return (_adj[i] as Dictionary).size()


func _nearest_node(p: Vector2) -> int:
	var best := -1
	var best_d := INF
	for i in _nodes.size():
		var d := _nodes[i].distance_to(p)
		if d < best_d:
			best_d = d
			best = i
	return best


func _shortest(from: int, to: int) -> float:
	var dist := {from: 0.0}
	var todo: Array[int] = [from]
	while not todo.is_empty():
		todo.sort_custom(func(l: int, r: int) -> bool: return float(dist[l]) < float(dist[r]))
		var u: int = todo.pop_front()
		for v: int in (_adj[u] as Dictionary):
			var nd: float = float(dist[u]) + _nodes[u].distance_to(_nodes[v])
			if nd < float(dist.get(v, INF)):
				dist[v] = nd
				todo.append(v)
	return float(dist.get(to, INF))


func _distance_to_line(p: Vector2, line: PackedVector2Array) -> float:
	var best := INF
	for i in line.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, line[i], line[i + 1])))
	return best


func _through_road_lines() -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for raw: Variant in ((_topology.get("through_road", {}) as Dictionary).get("roads", []) as Array):
		if _roads.has(str(raw)):
			out.append(_roads[str(raw)] as PackedVector2Array)
	return out


func _on_through_road(p: Vector2) -> bool:
	for line: PackedVector2Array in _through_road_lines():
		if _distance_to_line(p, line) <= SNAP_M:
			return true
	return false


func _well() -> Vector2:
	return _v(_topology.get("well", []))


func _well_radius() -> float:
	return float(_topology.get("well_hub_radius_m", 0.0))


## --- the through-road -----------------------------------------------------

func test_the_topology_block_names_real_roads_and_places() -> void:
	assert_false(_topology.is_empty(), "paths.village_topology is missing; nothing says which road is the through-road")
	var through := _through_road_lines()
	assert_eq(through.size(), 3, "the through-road is Grandpa's west street, South Street and the Lower Meadows spine, and all three exist")
	assert_eq(_well(), Vector2(10.0, -10.0), "the well is the fixed village.json well")
	assert_true(_well_radius() >= 8.0, "the no-hub radius still covers the square around the well")
	var village := _json(VILLAGE_PATH)
	var well_found := false
	for raw: Variant in (village.get("structures", []) as Array):
		if str((raw as Dictionary).get("prefab", "")) == "well":
			well_found = _v((raw as Dictionary).get("at", [])) == _well()
	assert_true(well_found, "the topology's well is where village.json builds it")


func test_one_continuous_through_road_runs_from_grandpas_door_to_trailgate() -> void:
	var home := _v(_topology.get("home_door", []))
	assert_eq(home, Vector2(-16.5, -16.0), "the through-road starts at Grandpa's real door")
	var start := _nearest_node(home)
	assert_true(start >= 0 and _nodes[start].distance_to(home) <= SNAP_M,
		"a village road actually ends at Grandpa's door")
	var exit_gate := str(_topology.get("bridge_exit_gate", ""))
	assert_eq(exit_gate, "TrailGate", "the bridge-side exit is the TrailGate leaf")
	var exits: Array = _crossings.filter(func(c: Array) -> bool: return str(c[0]) == exit_gate)
	assert_false(exits.is_empty(), "a village road leaves the fence through TrailGate")
	if start < 0 or exits.is_empty():
		return
	var goal := _nearest_node(exits[0][1] as Vector2)
	var walked := _shortest(start, goal)
	assert_true(walked < INF, "Grandpa's door and TrailGate are on one connected road network")
	var direct := _nodes[start].distance_to(_nodes[goal])
	assert_true(walked <= direct * 1.6,
		"the home-to-TrailGate road is %.1fm for a %.1fm crow-flight: a street, not a detour through lanes" % [walked, direct])
	# The declared pieces really are one line: each ends where the next begins.
	var through := _through_road_lines()
	if through.size() != 3:
		return
	var west: PackedVector2Array = through[0]
	var south: PackedVector2Array = through[1]
	var spine: PackedVector2Array = through[2]
	assert_true(west[west.size() - 1].distance_to(home) <= SNAP_M or west[0].distance_to(home) <= SNAP_M,
		"the west street is the road that ends at Grandpa's door")
	var bend := west[0] if west[west.size() - 1].distance_to(home) <= SNAP_M else west[west.size() - 1]
	assert_true(south[0].distance_to(bend) <= SNAP_M, "South Street begins exactly where the west street ends")
	assert_true(_distance_to_line(spine[0], south) <= SNAP_M and _distance_to_line(spine[1], south) <= SNAP_M,
		"the Lower Meadows spine begins ON South Street, continuing it rather than crossing the village on its own")
	for c: Array in _crossings:
		if str(c[2]) == "band1_lower_meadows":
			assert_eq(str(c[0]), exit_gate, "the spine leaves the village only through TrailGate")


func test_the_through_road_continues_to_the_south_bridge() -> void:
	var bridge: Dictionary = {}
	for raw: Variant in (_terrain.get("crossings", []) as Array):
		if str((raw as Dictionary).get("id", "")) == "south_bridge":
			bridge = raw as Dictionary
	assert_false(bridge.is_empty(), "the South Bridge crossing is authored")
	var centre := _v((bridge.get("carve", {}) as Dictionary).get("centre", []))
	var spine: PackedVector2Array = _roads.get("band1_lower_meadows", PackedVector2Array())
	assert_true(spine.size() >= 2, "the Lower Meadows spine exists")
	assert_true(_distance_to_line(centre, spine) <= 1.0,
		"the through-road's spine crosses the South Bridge at its carve centre (%.1f,%.1f)" % [centre.x, centre.y])


## --- no radial hub --------------------------------------------------------

func test_the_well_is_beside_the_road_not_a_hub() -> void:
	var well := _well()
	var radius := _well_radius()
	var hits: Array[Vector2] = []
	for i: int in _adj:
		for j: int in (_adj[i] as Dictionary):
			if j <= i:
				continue
			var a := _nodes[i]
			var d := _nodes[j] - a
			var f := a - well
			var qa := d.dot(d)
			var qb := 2.0 * f.dot(d)
			var qc := f.dot(f) - radius * radius
			var disc := qb * qb - 4.0 * qa * qc
			if disc < 0.0:
				continue
			for sgn: float in [-1.0, 1.0]:
				var t := (-qb + sgn * sqrt(disc)) / (2.0 * qa)
				if t >= 0.0 and t <= 1.0:
					hits.append(a + d * t)
	var arms: Array[Vector2] = []
	for h: Vector2 in hits:
		var fresh := true
		for q: Vector2 in arms:
			if q.distance_to(h) <= ARM_MERGE_M:
				fresh = false
		if fresh:
			arms.append(h)
	assert_true(arms.size() <= 2,
		"%d road arms meet within %.0fm of the well; a road settlement passes its well, it does not radiate from it (%s)" % [
			arms.size(), radius, str(arms)])
	for i: int in _adj:
		if _nodes[i].distance_to(well) <= radius:
			assert_true(_degree(i) <= 2,
				"road node (%.1f,%.1f) is a %d-way junction %.1fm from the well" % [
					_nodes[i].x, _nodes[i].y, _degree(i), _nodes[i].distance_to(well)])


func test_every_junction_is_a_branch_off_the_through_road() -> void:
	var junctions: Array[Vector2] = []
	for i: int in _adj:
		assert_true(_degree(i) <= 4,
			"road node (%.1f,%.1f) joins %d roads: that is a hub, not a street junction" % [_nodes[i].x, _nodes[i].y, _degree(i)])
		if _degree(i) >= 3:
			junctions.append(_nodes[i])
			assert_true(_on_through_road(_nodes[i]),
				"junction (%.1f,%.1f) is not on the through-road: lanes branch off the street, not off each other in a knot" % [
					_nodes[i].x, _nodes[i].y])
	assert_true(junctions.size() >= 2, "the through-road carries several branch lanes (%d junctions)" % junctions.size())
	for a in junctions.size():
		for b in range(a + 1, junctions.size()):
			assert_true(junctions[a].distance_to(junctions[b]) >= MIN_JUNCTION_SPACING_M,
				"junctions (%.1f,%.1f) and (%.1f,%.1f) are %.1fm apart: one hub drawn in pieces" % [
					junctions[a].x, junctions[a].y, junctions[b].x, junctions[b].y, junctions[a].distance_to(junctions[b])])


## --- the side lane and its subarea -----------------------------------------

func test_a_side_lane_leads_off_the_through_road_to_a_named_subarea() -> void:
	var lanes := _topology.get("side_lanes", []) as Array
	assert_false(lanes.is_empty(), "no side lane is declared")
	var subareas := {}
	for raw: Variant in (_topology.get("subareas", []) as Array):
		subareas[str((raw as Dictionary).get("id", ""))] = raw
	for raw: Variant in lanes:
		var lane_spec := raw as Dictionary
		var road_id := str(lane_spec.get("road", ""))
		assert_true(_roads.has(road_id), "side lane %s is a real road polyline" % road_id)
		var sub := subareas.get(str(lane_spec.get("subarea", "")), {}) as Dictionary
		assert_false(sub.is_empty(), "side lane %s names a declared subarea" % road_id)
		if not _roads.has(road_id) or sub.is_empty():
			continue
		assert_false(str(sub.get("name", "")).is_empty(), "the subarea has a player-facing name")
		var line: PackedVector2Array = _roads[road_id]
		var centre := _v(sub.get("centre", []))
		var radius := float(sub.get("radius", 0.0))
		assert_true(_on_through_road(line[0]), "side lane %s leaves from the through-road" % road_id)
		assert_true(line[line.size() - 1].distance_to(centre) <= radius,
			"side lane %s ends inside %s" % [road_id, str(sub.get("name", ""))])
		var length := 0.0
		for i in line.size() - 1:
			length += line[i].distance_to(line[i + 1])
		assert_true(length >= 15.0, "side lane %s is a visible lane (%.1fm), not a doorstep" % [road_id, length])
		for p: Vector2 in line:
			assert_true(BOUNDARY.contains(_outline, p), "side lane %s stays inside the village fence" % road_id)
		# Graph-connected from Grandpa's door, not just geometrically nearby.
		var home := _nearest_node(_v(_topology.get("home_door", [])))
		var lane_end := _nearest_node(line[line.size() - 1])
		assert_true(_shortest(home, lane_end) < INF, "side lane %s is reachable along roads from home" % road_id)
		# The name is backed by what stands there.
		if str(sub.get("kind", "")) == "stone_work":
			var stones := 0
			for node_raw: Variant in (_json(HARVEST_PATH).get("nodes", []) as Array):
				var node := node_raw as Dictionary
				if str(node.get("item", "")) == "stone" and _v(node.get("at", [])).distance_to(centre) <= radius:
					stones += 1
			assert_true(stones >= 2, "%s is a stone-working area with %d authored stone nodes in it" % [
				str(sub.get("name", "")), stones])


func test_the_stoneyard_lane_mouth_carries_a_named_fingerpost() -> void:
	var lanes := _topology.get("side_lanes", []) as Array
	var subareas := {}
	for raw: Variant in (_topology.get("subareas", []) as Array):
		subareas[str((raw as Dictionary).get("id", ""))] = raw
	for raw: Variant in lanes:
		var lane_spec := raw as Dictionary
		var line: PackedVector2Array = _roads.get(str(lane_spec.get("road", "")), PackedVector2Array())
		var name := str((subareas.get(str(lane_spec.get("subarea", "")), {}) as Dictionary).get("name", ""))
		var found := false
		for th_raw: Variant in ((_terrain.get("paths", {}) as Dictionary).get("trailheads", []) as Array):
			var th := th_raw as Dictionary
			if str(th.get("label", "")) != name or line.is_empty():
				continue
			var at := _v(th.get("at", []))
			found = at.distance_to(line[0]) <= 6.0
			var clearance := INF
			for id: String in _roads:
				clearance = minf(clearance, _distance_to_line(at, _roads[id] as PackedVector2Array))
			assert_true(clearance >= 1.8, "the %s fingerpost stands off every road's painted band (%.2fm)" % [name, clearance])
		assert_true(found, "a one-arm fingerpost names %s at its lane mouth" % name)


## --- fence, gates, buildings ------------------------------------------------

func test_every_village_road_leaves_the_fence_through_a_gate() -> void:
	assert_false(_crossings.is_empty(), "no village road crosses the fence; this check is vacuous")
	var used := {}
	for c: Array in _crossings:
		assert_ne(str(c[0]), "NO GATE",
			"road %s crosses the village fence at (%.1f,%.1f) with no gate within %.1fm" % [
				str(c[2]), (c[1] as Vector2).x, (c[1] as Vector2).y, _gate_clear + 1.0])
		used[str(c[0])] = true
	for gid: String in _gates:
		assert_true(used.has(gid), "gate %s no longer has a road through it" % gid)


func test_no_road_centreline_runs_through_a_building() -> void:
	var footprints := (_terrain.get("building_aprons", {}) as Dictionary).get("footprints", []) as Array
	for raw: Variant in footprints:
		var fp := raw as Dictionary
		var centre := _v(fp.get("centre", []))
		if centre.distance_to(_well()) > 90.0:
			continue
		var half := _v(fp.get("half_extents", [])) - Vector2(FOOTPRINT_INSET_M, FOOTPRINT_INSET_M)
		var yaw := deg_to_rad(float(fp.get("yaw_deg", 0.0)))
		var poly := PackedVector2Array()
		for corner: Vector2 in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
			poly.append(centre + Vector2(corner.x * cos(yaw) + corner.y * sin(yaw), -corner.x * sin(yaw) + corner.y * cos(yaw)))
		for id: String in _roads:
			var line: PackedVector2Array = _roads[id]
			for i in line.size() - 1:
				var clipped := Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([line[i], line[i + 1]]), poly)
				assert_true(clipped.is_empty(),
					"road %s runs through the building footprint at (%.1f,%.1f)" % [id, centre.x, centre.y])


func test_every_house_door_fronts_a_road() -> void:
	# WORLD 3.2: "Face house fronts/doors and civic activity onto those roads."
	# Every authored threshold (village.json doorsteps) plus Grandpa's own door
	# must lie within a short front path of a road centreline.
	var doors: Array[Vector2] = [_v(_topology.get("home_door", []))]
	for raw: Variant in (_json(VILLAGE_PATH).get("structures", []) as Array):
		if str((raw as Dictionary).get("prefab", "")) == "doorstep":
			doors.append(_v((raw as Dictionary).get("at", [])))
	assert_true(doors.size() >= 4, "the village authors its door thresholds (%d found)" % doors.size())
	for door: Vector2 in doors:
		var nearest := INF
		for id: String in _roads:
			nearest = minf(nearest, _distance_to_line(door, _roads[id] as PackedVector2Array))
		assert_true(nearest <= 4.5,
			"the door at (%.2f,%.2f) is %.1fm from the nearest road; a road settlement's houses front its roads" % [
				door.x, door.y, nearest])
