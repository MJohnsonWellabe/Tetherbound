extends RefCounted

## Broad phase only. The caller retains the original height/shape predicates.
## Index the already-filtered patch list, preserving its exclusion semantics.
const CELL_M := 32.0
const MAX_CELLS := 4096
const MAX_CELL_REFERENCES := 16384
const MAX_COORD := 10000000.0
const BOUNDS_PAD_M := 0.01
var _cells: Dictionary = {}
var _empty: Array[Dictionary] = []
var unbounded: Array[Dictionary] = []


func build(exclusions: Array[Dictionary]) -> void:
	_cells.clear()
	unbounded.clear()
	var references := 0
	for exclusion: Dictionary in exclusions:
		var low: Vector2
		var high: Vector2
		if str(exclusion.get("kind", "")) == "segment":
			var a: Vector3 = exclusion["a"]
			var b: Vector3 = exclusion["b"]
			var reach := absf(float(exclusion["half_width"])) + BOUNDS_PAD_M
			low = Vector2(minf(a.x, b.x) - reach, minf(a.z, b.z) - reach)
			high = Vector2(maxf(a.x, b.x) + reach, maxf(a.z, b.z) + reach)
		else:
			var centre: Vector3 = exclusion["centre"]
			var half: Vector2 = exclusion["half"]
			var angle := float(exclusion.get("rotation", 0.0))
			var c := absf(cos(angle))
			var s := absf(sin(angle))
			# A rotated rectangle bounds both rectangle and ellipse predicates.
			var extent := Vector2(c * absf(half.x) + s * absf(half.y),
				s * absf(half.x) + c * absf(half.y)) + Vector2.ONE * BOUNDS_PAD_M
			low = Vector2(centre.x, centre.z) - extent
			high = Vector2(centre.x, centre.z) + extent
		if not (is_finite(low.x) and is_finite(low.y) and is_finite(high.x) and is_finite(high.y)):
			unbounded.append(exclusion)
			continue
		if maxf(maxf(absf(low.x), absf(low.y)), maxf(absf(high.x), absf(high.y))) > MAX_COORD:
			unbounded.append(exclusion)
			continue
		var first := Vector2i(floori(low.x / CELL_M), floori(low.y / CELL_M))
		var last := Vector2i(floori(high.x / CELL_M), floori(high.y / CELL_M))
		var count := (last.x - first.x + 1) * (last.y - first.y + 1)
		# Bound the whole patch index too. Large/dense shape sets retain the
		# linear fallback instead of trading CPU cost for unbounded allocation.
		if count > MAX_CELLS or references + count > MAX_CELL_REFERENCES:
			unbounded.append(exclusion)
			continue
		references += count
		for x in range(first.x, last.x + 1):
			for z in range(first.y, last.y + 1):
				var key := Vector2i(x, z)
				if not _cells.has(key):
					var bucket: Array[Dictionary] = []
					_cells[key] = bucket
				(_cells[key] as Array).append(exclusion)


func candidates(at: Vector3) -> Array[Dictionary]:
	return _cells.get(Vector2i(floori(at.x / CELL_M), floori(at.z / CELL_M)), _empty)
