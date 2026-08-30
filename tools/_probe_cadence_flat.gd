extends SceneTree

## T5-CADENCE round 2: sweep for the flattest shelf near the two sites the
## first pass (`tools/_probe_cadence_sites.gd`) found rough, and re-check the
## two campfires this lane adds to existing clusters.
##
## Same job tools/_probe_camp_flat.gd did for band 1's trail camp, which is the
## reason that camp is at (344,935) and not at its first two addresses.
##
##   godot --headless --path . --script tools/_probe_cadence_flat.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

var _field: RefCounted = null


func _slope_deg(x: float, z: float, r: float = 1.0) -> float:
	var h := float(_field.call("height_at", x, z))
	var worst := 0.0
	for off: Vector2 in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		var d: float = absf(float(_field.call("height_at", x + off.x, z + off.y)) - h)
		worst = maxf(worst, rad_to_deg(atan2(d, r)))
	return worst


func _spread(x: float, z: float, r: float) -> Array:
	var lo := 1e9
	var hi := -1e9
	var worst := 0.0
	for i in 16:
		var a := TAU * float(i) / 16.0
		for rr: float in [r * 0.5, r]:
			var px := x + cos(a) * rr
			var pz := z + sin(a) * rr
			var h := float(_field.call("height_at", px, pz))
			lo = minf(lo, h)
			hi = maxf(hi, h)
			worst = maxf(worst, _slope_deg(px, pz))
	var c := float(_field.call("height_at", x, z))
	lo = minf(lo, c)
	hi = maxf(hi, c)
	return [c, hi - lo, maxf(worst, _slope_deg(x, z))]


func _sweep(label: String, cx: float, cz: float, reach: float, pad_r: float) -> void:
	var best := []
	for ix in range(-6, 7):
		for iz in range(-6, 7):
			var x := cx + float(ix) * reach / 6.0
			var z := cz + float(iz) * reach / 6.0
			var out := _spread(x, z, pad_r)
			best.append([out[1], out[2], x, z, out[0]])
	best.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	print("%s -- flattest %.0fm pads within %.0fm of (%.0f,%.0f):" % [label, pad_r, reach, cx, cz])
	for i in 4:
		var e: Array = best[i]
		print("    [%7.1f,%7.1f]  h=%6.2f spread=%5.2f worst=%5.1f" % [e[2], e[3], e[4], e[0], e[1]])


func _report(label: String, x: float, z: float, r: float) -> void:
	var out := _spread(x, z, r)
	print("%-30s [%7.1f,%7.1f] r=%.0f h=%6.2f spread=%5.2f worst=%5.1f" % [
		label, x, z, r, out[0], out[1], out[2]])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	_sweep("band4 highfield stock camp", 262.0, 5658.0, 26.0, 7.0)
	_sweep("band4 ridge road picket", -25.0, 6285.0, 22.0, 5.0)
	print()
	print("--- fires added to existing clusters ---")
	_report("band2 ranger_camp fire", -256.6, 2261.3, 2.5)
	_report("band2 ranger_camp anchor", -259.0, 2256.5, 2.5)
	_report("band3 riverwatch fire", 213.9, 3697.6, 2.5)
	_report("band3 riverwatch anchor", 211.9, 3698.9, 2.5)
	_report("band1 trail_camp new bed", 347.0, 934.0, 2.5)
	_report("band1 trail_camp fire", 344.0, 935.0, 2.5)
	quit(0)
