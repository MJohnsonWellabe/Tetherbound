extends SceneTree

## PW2 / prompt 30 / BAND1-D1: find sites for Lower Meadows' two optional draws.
##
## The requirements are specific and pull against each other, so this is
## measured rather than eyeballed. It wants to be OFF the route -- prompt 62
## asks for something that tempts the player away from direct progress, and
## tools/_probe_band1_cadence.py counts anything beyond 60m lateral as an
## optional detour rather than as corridor cadence -- but not so far that
## nobody finds it. It wants to be near the pond, because that is where band1
## already puts every mosshell and PW2 says to use habitat rather than to
## drop a boss circle every fixed distance. And it wants flat ground, because
## an encounter arena forms where the creature stands.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const POND := Vector2(-395.0, 545.0)

## Two sitings, one probe, because they are the same question asked twice and
## band1 needs both draws to be in different places rather than one optional
## corner. `x`/`z` are the search box, `near`/`near_min`/`near_max` an anchor
## the site should be close to (the pond, for a mosshell; the route's own
## eastern leg, for someone who wants to be found), `lat` the lateral
## corridor off every authored route.
const SEARCHES := [
	{
		"name": "elder mosshell hollow (west of the pond)",
		"x": [-560, -280], "z": [400, 700],
		"anchor": Vector2(-395.0, 545.0), "near": [45.0, 115.0],
		"lat": [70.0, 110.0], "above_water": true,
	},
	{
		"name": "old champion (eastern lower meadows, off the road)",
		"x": [60, 460], "z": [700, 1200],
		"anchor": Vector2(230.0, 830.0), "near": [70.0, 220.0],
		"lat": [70.0, 130.0], "above_water": true,
	},
]

## Band 1's spine leg AND the pond loop, copied from terrain_playground.json's
## `trail.bands[0]` and `trail.loops[0]`. Both matter: the pond is ON the loop,
## so measuring against the spine alone would call a spot beside the water
## "off-route" when the player walks straight past it.
const ROUTE := [
	[Vector2(27.5,-16), Vector2(14,20), Vector2(8,90), Vector2(-40,180), Vector2(-120,270),
	 Vector2(-230,330), Vector2(-360,400), Vector2(-430,510), Vector2(-330,590),
	 Vector2(-190,650), Vector2(-50,700), Vector2(90,760), Vector2(230,830),
	 Vector2(360,910), Vector2(430,1020), Vector2(330,1130), Vector2(180,1200),
	 Vector2(30,1250), Vector2(-40,1310), Vector2(8,1330), Vector2(0,1360)],
	[Vector2(-360,400), Vector2(-390,460), Vector2(-395,545), Vector2(-382,514),
	 Vector2(-350,507), Vector2(-330,590), Vector2(-260,630), Vector2(-190,650)],
]


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	for entry: Variant in SEARCHES:
		var search: Dictionary = entry
		print("== %s ==" % search["name"])
		var xr: Array = search["x"]
		var zr: Array = search["z"]
		var near: Array = search["near"]
		var lat: Array = search["lat"]
		var anchor: Vector2 = search["anchor"]
		var best: Array = []
		for gx in range(int(xr[0]), int(xr[1]), 5):
			for gz in range(int(zr[0]), int(zr[1]), 5):
				var p := Vector2(float(gx), float(gz))
				var anchor_d := p.distance_to(anchor)
				if anchor_d < float(near[0]) or anchor_d > float(near[1]):
					continue
				var lateral := _lateral(p)
				if lateral < float(lat[0]) or lateral > float(lat[1]):
					continue
				var hs: Array[float] = []
				for o in [Vector2(0,0), Vector2(5,0), Vector2(-5,0), Vector2(0,5), Vector2(0,-5),
						Vector2(4,4), Vector2(-4,4), Vector2(4,-4), Vector2(-4,-4)]:
					hs.append(field.height_at(p.x + o.x, p.y + o.y))
				var lo := hs[0]
				var hi := hs[0]
				for h in hs:
					lo = minf(lo, h)
					hi = maxf(hi, h)
				# Above the water line, or the arena is in the pond.
				if bool(search["above_water"]) and lo < -16.0:
					continue
				best.append({"p": p, "spread": hi - lo, "h": hs[0], "anchor": anchor_d, "lat": lateral})
		best.sort_custom(func(a, b): return a["spread"] < b["spread"])
		print("  candidates: %d" % best.size())
		for i in mini(6, best.size()):
			var e: Dictionary = best[i]
			var p: Vector2 = e["p"]
			print("  (%.0f, %.0f) spread=%.2f over 10m  h=%.2f  anchor=%.0fm  route_lateral=%.0fm" % [
				p.x, p.y, e["spread"], e["h"], e["anchor"], e["lat"]])
	quit(0)


func _lateral(p: Vector2) -> float:
	var best := 1.0e9
	for line: Variant in ROUTE:
		var poly: Array = line
		for i in range(poly.size() - 1):
			var a: Vector2 = poly[i]
			var b: Vector2 = poly[i + 1]
			var ab := b - a
			var t: float = clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			best = minf(best, p.distance_to(a + ab * t))
	return best
