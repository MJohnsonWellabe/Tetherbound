extends SceneTree
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	# Along the quarry -> stronghold conduit bearing (0.565, -0.826) from the
	# quarry floor [23,158].
	for tv: float in [90.0, 105.0, 120.0, 135.0, 150.0, 165.0]:
		var t := tv
		var x := 23.0 + 0.565 * t
		var z := 158.0 - 0.826 * t
		var h := float(field.call("height_at", x, z))
		var s := float(field.call("slope_degrees_at", x, z)) if field.has_method("slope_degrees_at") else -1.0
		print("t=%5.0f  [%7.1f, %7.1f]  r=%6.1f  h=%7.2f  slope=%5.1f" % [t, x, z, sqrt(x*x+z*z), h, s])
	print("--- candidate sites, centre + 12m corners ---")
	for site: Array in [
		["hess [96.5,49]", 96.5, 49.0],
		["orrin [102,42]", 102.0, 42.0],
		["dell [105.5,37.5]", 105.5, 37.5],
		["vance [110,31]", 110.0, 31.0],
		["captive [114,27]", 114.0, 27.0],
		["site [108,34]", 108.0, 34.0],
	]:
		var cx := float(site[1])
		var cz := float(site[2])
		var hs := []
		var mx := -999.0
		var mn := 999.0
		for off: Vector2 in [Vector2.ZERO, Vector2(-4,-4), Vector2(4,-4), Vector2(-4,4), Vector2(4,4), Vector2(-4,0), Vector2(4,0), Vector2(0,-4), Vector2(0,4)]:
			var h2 := float(field.call("height_at", cx+off.x, cz+off.y))
			hs.append(h2)
			mx = maxf(mx, h2)
			mn = minf(mn, h2)
		print("%s centre %.2f  spread %.2f  (%s)" % [site[0], hs[0], mx-mn, ", ".join(hs.map(func(v): return "%.1f" % v))])
	quit(0)
