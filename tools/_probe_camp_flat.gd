extends SceneTree

## BAND1-D1 round 3: find a flat enough shelf for the trail camp beside the
## loop trail through (300,880)-(370,950)-(400,1040). The camp's current site
## drops 1.2m across its own 7m footprint, which is why its props sit at
## wildly different heights and the wide frame reads as a bare grass slope.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

func _init() -> void:
	var f: RefCounted = HEIGHTFIELD.new()
	var best: Array = []
	for gx in range(320, 380, 2):
		for gz in range(895, 960, 2):
			var x := float(gx)
			var z := float(gz)
			# distance to the loop polyline
			var d := _dist_to_trail(Vector2(x, z))
			if d < 5.0 or d > 14.0:
				continue
			var hs: Array[float] = []
			for o in [Vector2(0,0), Vector2(4,0), Vector2(-4,0), Vector2(0,4), Vector2(0,-4),
					Vector2(3,3), Vector2(-3,3), Vector2(3,-3), Vector2(-3,-3)]:
				hs.append(f.height_at(x + o.x, z + o.y))
			var lo := hs[0]
			var hi := hs[0]
			for h in hs:
				lo = min(lo, h)
				hi = max(hi, h)
			best.append({"x": x, "z": z, "spread": hi - lo, "h": hs[0], "d": d})
	best.sort_custom(func(a, b): return a["spread"] < b["spread"])
	for i in min(12, best.size()):
		var e: Dictionary = best[i]
		print("(%.0f, %.0f) spread=%.2fm over 8m  h=%.2f  trail_dist=%.1fm" % [
			e["x"], e["z"], e["spread"], e["h"], e["d"]])
	quit(0)


func _dist_to_trail(p: Vector2) -> float:
	var poly := [Vector2(230,830), Vector2(300,880), Vector2(370,950), Vector2(400,1040)]
	var best := 1e9
	for i in range(poly.size() - 1):
		var a: Vector2 = poly[i]
		var b: Vector2 = poly[i + 1]
		var ab := b - a
		var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = min(best, p.distance_to(a + ab * t))
	return best
