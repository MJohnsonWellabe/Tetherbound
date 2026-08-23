extends SceneTree

## STRONGHOLD-R2 scratch probe. The wayfinding frames show no road reaching the
## stronghold, and a road cannot simply be drawn straight there: the straight
## line from the Rise road's truncated end (74,-41) to the castle's ramp foot
## passes within ~2.5m of `rises.peaks[0]`'s summit (140,-90), i.e. straight
## over the designed 40-52 degree collar OF10a already had to truncate a road
## against. This searches the real heightfield for a line that stays walkable
## instead of guessing one and rendering it to find out.
##
## Dijkstra over a grid, cost = length * (1 + slope penalty), any cell whose
## slope exceeds MAX_SLOPE is impassable. Then Douglas-Peucker down to a
## handful of polyline points, and a report of the worst slope on the
## simplified line (which is what actually gets authored, not the grid path).

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const STEP := 4.0
const MAX_SLOPE := 22.0
const SLOPE_PENALTY := 0.25
const SIMPLIFY_TOLERANCE := 7.0

const FROM := Vector2(74.0, -41.0)
const TO := Vector2(231.8, -215.0)

const MIN_X := 40.0
const MAX_X := 300.0
const MIN_Z := -260.0
const MAX_Z := -10.0


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()

	var cols := int((MAX_X - MIN_X) / STEP) + 1
	var rows := int((MAX_Z - MIN_Z) / STEP) + 1

	var slope := PackedFloat32Array()
	slope.resize(cols * rows)
	for r in rows:
		for c in cols:
			var p := _world(c, r)
			slope[r * cols + c] = field.slope_degrees_at(p.x, p.y, 2.0)

	var start := _cell(FROM, cols, rows)
	var goal := _cell(TO, cols, rows)
	print("start cell %s slope %.1f, goal cell %s slope %.1f" % [
		start, slope[start.y * cols + start.x], goal, slope[goal.y * cols + goal.x]])

	var dist := PackedFloat32Array()
	dist.resize(cols * rows)
	dist.fill(INF)
	var prev := PackedInt32Array()
	prev.resize(cols * rows)
	prev.fill(-1)

	var start_index := start.y * cols + start.x
	dist[start_index] = 0.0
	var open := {start_index: 0.0}

	var neighbours := [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
	]

	while not open.is_empty():
		var best := -1
		var best_cost := INF
		for index: int in open:
			if float(open[index]) < best_cost:
				best_cost = float(open[index])
				best = index
		open.erase(best)
		if best == goal.y * cols + goal.x:
			break
		var bc := best % cols
		var br := best / cols
		for offset: Vector2i in neighbours:
			var nc := bc + offset.x
			var nr := br + offset.y
			if nc < 0 or nc >= cols or nr < 0 or nr >= rows:
				continue
			var ni := nr * cols + nc
			var s: float = slope[ni]
			if s > MAX_SLOPE:
				continue
			var span := STEP * (1.4142 if offset.x != 0 and offset.y != 0 else 1.0)
			var cost: float = dist[best] + span * (1.0 + SLOPE_PENALTY * s)
			if cost < dist[ni]:
				dist[ni] = cost
				prev[ni] = best
				open[ni] = cost

	var goal_index := goal.y * cols + goal.x
	if is_inf(dist[goal_index]):
		print("NO WALKABLE ROUTE at max slope %.0f" % MAX_SLOPE)
		quit(1)
		return

	var chain: Array[Vector2] = []
	var walk := goal_index
	while walk != -1:
		chain.append(_world(walk % cols, walk / cols))
		walk = prev[walk]
	chain.reverse()
	print("grid path: %d cells, cost %.0f" % [chain.size(), dist[goal_index]])

	var simple := _simplify(chain, SIMPLIFY_TOLERANCE)
	print("simplified: %d points" % simple.size())
	# Chaikin twice, endpoints pinned: the 8-way grid can only turn in 45-degree
	# steps, so a simplified line inherits corners the ground never asked for.
	# The trailhead and the ramp foot must not move, hence the pin.
	var smooth: Array[Vector2] = _chaikin(_chaikin(simple))
	smooth = _simplify(smooth, 1.5)
	print("smoothed: %d points" % smooth.size())
	var out := "["
	for i in smooth.size():
		out += "\n    [%.1f, %.1f]%s" % [smooth[i].x, smooth[i].y, "," if i < smooth.size() - 1 else ""]
	print(out + "\n  ]")

	_report("grid path", field, chain)
	_report("simplified line", field, simple)
	_report("smoothed line", field, smooth)
	quit(0)


func _chaikin(line: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if line.size() < 3:
		for p: Vector2 in line:
			out.append(p)
		return out
	out.append(line[0])
	for i in line.size() - 1:
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		out.append(a.lerp(b, 0.25))
		out.append(a.lerp(b, 0.75))
	out.append(line[line.size() - 1])
	return out


func _report(label: String, field: RefCounted, line: Array) -> void:
	var worst := 0.0
	var worst_at := Vector2.ZERO
	var length := 0.0
	var rise_centre := Vector2(140.0, -90.0)
	var nearest_rise := INF
	for i in line.size() - 1:
		var a: Vector2 = line[i]
		var b: Vector2 = line[i + 1]
		var seg := a.distance_to(b)
		length += seg
		var steps := maxi(2, int(seg / 1.0))
		for s in steps + 1:
			var p := a.lerp(b, float(s) / float(steps))
			var deg: float = field.slope_degrees_at(p.x, p.y, 1.0)
			if deg > worst:
				worst = deg
				worst_at = p
			nearest_rise = minf(nearest_rise, p.distance_to(rise_centre))
	print("%s: %.1fm long, worst slope %.1f deg at (%.1f, %.1f), nearest rise-peak approach %.1fm" % [
		label, length, worst, worst_at.x, worst_at.y, nearest_rise])


func _world(c: int, r: int) -> Vector2:
	return Vector2(MIN_X + float(c) * STEP, MIN_Z + float(r) * STEP)


func _cell(p: Vector2, cols: int, rows: int) -> Vector2i:
	return Vector2i(
		clampi(int(round((p.x - MIN_X) / STEP)), 0, cols - 1),
		clampi(int(round((p.y - MIN_Z) / STEP)), 0, rows - 1))


func _simplify(line: Array, tolerance: float) -> Array[Vector2]:
	if line.size() < 3:
		var short: Array[Vector2] = []
		for p: Vector2 in line:
			short.append(p)
		return short
	var worst := 0.0
	var index := 0
	var first: Vector2 = line[0]
	var last: Vector2 = line[line.size() - 1]
	for i in range(1, line.size() - 1):
		var d := _perp(line[i], first, last)
		if d > worst:
			worst = d
			index = i
	var out: Array[Vector2] = []
	if worst > tolerance:
		var left := _simplify(line.slice(0, index + 1), tolerance)
		var right := _simplify(line.slice(index), tolerance)
		out.append_array(left.slice(0, left.size() - 1))
		out.append_array(right)
	else:
		out.append(first)
		out.append(last)
	return out


func _perp(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() < 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return point.distance_to(a + ab * t)
