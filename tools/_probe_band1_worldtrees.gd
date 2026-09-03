extends SceneTree

## WORLD-TREES-0903. Probes terrain height to site the Band 1 route contract's
## Place 1/2/4 anchors against real ground, not guessed coordinates. Prints a
## table for each named search so the anchor centres below can be picked from
## measured local maxima / flat shelves rather than eyeballed.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

## The authored trail spine (band1_lower_meadows points), used to keep every
## candidate a known lateral distance from the road.
const TRAIL: Array = [
	Vector2(27.5, -16), Vector2(14, 20), Vector2(8, 90), Vector2(-40, 180),
	Vector2(-120, 270), Vector2(-230, 330), Vector2(-360, 400), Vector2(-430, 510),
	Vector2(-330, 590), Vector2(-190, 650), Vector2(-50, 700), Vector2(90, 760),
	Vector2(230, 830), Vector2(360, 910), Vector2(430, 1020), Vector2(330, 1130),
	Vector2(180, 1200), Vector2(30, 1250), Vector2(-40, 1310), Vector2(8.0, 1330),
	Vector2(0, 1360),
]


func _init() -> void:
	var f: RefCounted = HEIGHTFIELD.new()

	print("--- Place 1: Gate Meadow tree station, within 120m of gate ---")
	_scan_offsets(f, 60.0, 12.0)

	print("\n--- Place 2: The Rise crest, arc 450-900 (searching offsets near -230,330 .. -330,590) ---")
	_scan_crest(f, [Vector2(-230, 330), Vector2(-360, 400), Vector2(-430, 510), Vector2(-330, 590)])

	print("\n--- Place 2: discovery cache 40-60m off the crest ---")
	# filled in after crest is known; see _scan_cache below once crest chosen

	print("\n--- Place 4: thin leg 1 grove, arc 1050-1200 (near -190,650 .. -50,700) ---")
	_scan_offsets_between(f, Vector2(-190, 650), Vector2(-50, 700), 20.0)

	print("\n--- Place 4: thin leg 2 grove, arc 2100-2250 (near 180,1200 .. 30,1250) ---")
	_scan_offsets_between(f, Vector2(180, 1200), Vector2(30, 1250), 20.0)

	quit(0)


func _dist_to_trail(p: Vector2) -> float:
	var best := 1e9
	for i in range(TRAIL.size() - 1):
		var a: Vector2 = TRAIL[i]
		var b: Vector2 = TRAIL[i + 1]
		var ab := b - a
		var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = min(best, p.distance_to(a + ab * t))
	return best


func _slope_at(f: RefCounted, x: float, z: float) -> float:
	var h0: float = f.height_at(x, z)
	var hx: float = f.height_at(x + 1.0, z)
	var hz: float = f.height_at(x, z + 1.0)
	var dx := hx - h0
	var dz := hz - h0
	return rad_to_deg(atan2(sqrt(dx * dx + dz * dz), 1.0))


func _scan_offsets(f: RefCounted, arc_hint: float, target_offset: float) -> void:
	# village-to-first-bend arc ~0-120: sample near the road_gate stretch
	for gx in range(-30, 60, 5):
		for gz in range(-10, 100, 5):
			var p := Vector2(float(gx), float(gz))
			var d := _dist_to_trail(p)
			if d < 6.0 or d > 16.0:
				continue
			var h: float = f.height_at(p.x, p.y)
			var slope := _slope_at(f, p.x, p.y)
			if slope > 21.0:
				continue
			print("(%.0f, %.0f) trail_dist=%.1f h=%.2f slope=%.1f" % [p.x, p.y, d, h, slope])


func _scan_crest(f: RefCounted, near_points: Array) -> void:
	var best: Array = []
	for np: Vector2 in near_points:
		for gx in range(int(np.x - 60), int(np.x + 60), 6):
			for gz in range(int(np.y - 60), int(np.y + 60), 6):
				var p := Vector2(float(gx), float(gz))
				var d := _dist_to_trail(p)
				if d < 8.0 or d > 70.0:
					continue
				var h: float = f.height_at(p.x, p.y)
				var slope := _slope_at(f, p.x, p.y)
				best.append({"x": p.x, "z": p.y, "h": h, "d": d, "slope": slope})
	best.sort_custom(func(a, b): return a["h"] > b["h"])
	for i in min(20, best.size()):
		var e: Dictionary = best[i]
		print("(%.0f, %.0f) h=%.2f trail_dist=%.1f slope=%.1f" % [e["x"], e["z"], e["h"], e["d"], e["slope"]])


func _scan_offsets_between(f: RefCounted, a: Vector2, b: Vector2, target_offset: float) -> void:
	var minx: int = int(min(a.x, b.x)) - 40
	var maxx: int = int(max(a.x, b.x)) + 40
	var minz: int = int(min(a.y, b.y)) - 40
	var maxz: int = int(max(a.y, b.y)) + 40
	var best: Array = []
	for gx in range(minx, maxx, 5):
		for gz in range(minz, maxz, 5):
			var p := Vector2(float(gx), float(gz))
			var d := _dist_to_trail(p)
			if d < 10.0 or d > 40.0:
				continue
			var slope := _slope_at(f, p.x, p.y)
			if slope > 21.0:
				continue
			# flatness over an 8m footprint, since a grove clearing wants a shelf
			var hs: Array[float] = []
			for o in [Vector2(0,0), Vector2(4,0), Vector2(-4,0), Vector2(0,4), Vector2(0,-4)]:
				hs.append(f.height_at(p.x + o.x, p.y + o.y))
			var lo: float = hs[0]
			var hi: float = hs[0]
			for h in hs:
				lo = min(lo, h)
				hi = max(hi, h)
			best.append({"x": p.x, "z": p.y, "d": d, "spread": hi - lo, "h": hs[0], "slope": slope})
	best.sort_custom(func(x, y): return x["spread"] < y["spread"])
	for i in min(12, best.size()):
		var e: Dictionary = best[i]
		print("(%.0f, %.0f) trail_dist=%.1f spread=%.2f h=%.2f slope=%.1f" % [
			e["x"], e["z"], e["d"], e["spread"], e["h"], e["slope"]])
