extends SceneTree

## BAND2-FLOOR scratch probe: real ground heights and local slope for four
## forest-floor anchor candidates along Band 2's oak stretch (leaf litter /
## undergrowth / saplings dressing), so each site is measured rather than
## guessed. Same pattern as tools/_probe_band4_sites.gd; no terrain bake is
## touched, and this file is not committed. Run with:
##   godot --headless --path . --script tools/_probe_band2_floor.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

var _field: RefCounted = null


func _slope_deg(x: float, z: float, r: float = 1.0) -> float:
	var h := float(_field.call("height_at", x, z))
	var worst := 0.0
	for off: Vector2 in [Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		var d: float = absf(float(_field.call("height_at", x + off.x, z + off.y)) - h)
		worst = maxf(worst, rad_to_deg(atan2(d, r)))
	return worst


func _pad(x: float, z: float, r: float) -> Array:
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
	worst = maxf(worst, _slope_deg(x, z))
	return [c, hi - lo, worst]


func _dist(x: float, z: float, cx: float, cz: float) -> float:
	return Vector2(x - cx, z - cz).length()


func _report(label: String, x: float, z: float, r: float) -> void:
	var out := _pad(x, z, r)
	var d_camp := _dist(x, z, -259.0, 2256.5)
	var d_warrens := _dist(x, z, -357.0, 2610.0)
	var d_quarry := _dist(x, z, 400.0, 1800.0)
	print("%-28s [%7.1f,%7.1f] r=%.0f  h=%7.2f spread=%5.2f worst=%5.1f  d_camp=%6.1f d_warrens=%6.1f d_quarry=%6.1f" % [
		label, x, z, r, out[0], out[1], out[2], d_camp, d_warrens, d_quarry])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	print("--- band2 forest-floor anchor candidates (pad r=6m) ---")
	print("clearings to clear: ranger_camp r=15 @(-259,2256.5), warrens r=30 @(-357,2610), quarry r=17 @(400,1800)")
	for c: Array in [
		["A early-forest (survey01)", 140.0, 1540.0],
		["B quarry-camp ridge", 100.0, 2090.0],
		["C camp-warrens forest", -340.0, 2380.0],
		["D late-ridge (survey05)", 70.0, 2965.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 6.0)
	quit(0)
