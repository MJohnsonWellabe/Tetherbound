extends SceneTree
## Quick, no-bake sanity check: flood-fill / windowed-scan the ANALYTIC
## playground_heightfield.height_at() (not baked Terrain3D) across a z-band,
## to catch gross leaks before spending a full bake+import cycle. Not a
## substitute for the real _probe_crossings.gd against the baked surface --
## just a fast design-iteration loop.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const CELL := 2.0
const LIMIT_DEG := 45.0
const WINDOW := 64.0
const STRIDE := 32.0

var _field: RefCounted


func _init() -> void:
	_field = HEIGHTFIELD.new()
	_check("south_bridge", -1024.0, 1024.0, 1330.0 - 90.0, 1330.0 + 90.0)
	_check("sigil_west+east_band", -1024.0, 1024.0, 7370.8 - 120.0, 7429.2 + 120.0)
	quit(0)


func _h(x: float, z: float) -> float:
	return float(_field.height_at(x, z))


func _standable(at: Vector2, limit_tan: float) -> bool:
	var h := _h(at.x, at.y)
	if is_nan(h):
		return false
	var e := _h(at.x + CELL, at.y)
	var w := _h(at.x - CELL, at.y)
	var n := _h(at.x, at.y + CELL)
	var s := _h(at.x, at.y - CELL)
	if is_nan(e) or is_nan(w) or is_nan(n) or is_nan(s):
		return false
	var dx := (e - w) / (2.0 * CELL)
	var dz := (n - s) / (2.0 * CELL)
	return sqrt(dx * dx + dz * dz) <= limit_tan


func _connects(left: float, right: float, min_z: float, max_z: float, limit_deg: float) -> bool:
	var cols := int((right - left) / CELL) + 1
	var rows := int((max_z - min_z) / CELL) + 1
	var limit_tan := tan(deg_to_rad(limit_deg))
	var walkable := PackedByteArray()
	walkable.resize(cols * rows)
	for j in rows:
		var z := min_z + float(j) * CELL
		for i in cols:
			walkable[j * cols + i] = 1 if _standable(Vector2(left + float(i) * CELL, z), limit_tan) else 0
	var seen := PackedByteArray()
	seen.resize(cols * rows)
	var queue := PackedInt32Array()
	for i in cols:
		var idx := (rows - 1) * cols + i
		if walkable[idx] == 0:
			continue
		seen[idx] = 1
		queue.append(idx)
	var head := 0
	while head < queue.size():
		var idx := queue[head]
		head += 1
		var i := idx % cols
		var j := idx / cols
		if j == 0:
			return true
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ni := i + step.x
			var nj := j + step.y
			if ni < 0 or ni >= cols or nj < 0 or nj >= rows:
				continue
			var next := nj * cols + ni
			if seen[next] == 1 or walkable[next] == 0:
				continue
			seen[next] = 1
			queue.append(next)
	return false


func _check(label: String, min_x: float, max_x: float, min_z: float, max_z: float) -> void:
	print("=== %s: x %.0f..%.0f, z %.0f..%.0f ===" % [label, min_x, max_x, min_z, max_z])
	var open_cols: Array[int] = []
	var left := min_x
	while left < max_x:
		var right := minf(left + WINDOW, max_x)
		if _connects(left, right, min_z, max_z, LIMIT_DEG):
			var from := int((left - min_x) / CELL)
			var to := int((right - min_x) / CELL)
			for i in range(from, to + 1):
				if not open_cols.has(i):
					open_cols.append(i)
		left += STRIDE
	if open_cols.is_empty():
		print("  SEALED")
		return
	open_cols.sort()
	var start := open_cols[0]
	var prev := open_cols[0]
	for k in range(1, open_cols.size()):
		if open_cols[k] != prev + 1:
			print("  PASSABLE x %.0f..%.0f (%.0f m)" % [
				min_x + float(start) * CELL, min_x + float(prev) * CELL, float(prev - start + 1) * CELL])
			start = open_cols[k]
		prev = open_cols[k]
	print("  PASSABLE x %.0f..%.0f (%.0f m)" % [
		min_x + float(start) * CELL, min_x + float(prev) * CELL, float(prev - start + 1) * CELL])
