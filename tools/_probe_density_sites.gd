extends SceneTree

## T3-DENSITY scratch probe: ground height/slope for candidate Band 2 TM
## and Band 3/4 gather positions before they're authored into data. Same
## pattern as tools/_probe_pickups_sites.gd (T3-PICKUPS) and
## tools/_probe_band4_sites.gd before it.
##   godot --headless --path . --script tools/_probe_density_sites.gd

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


func _report(label: String, x: float, z: float, r: float = 2.0) -> void:
	var out := _pad(x, z, r)
	print("%-28s [%7.1f,%7.1f] r=%.0f  h=%7.2f spread=%5.2f worst=%5.1f" % [
		label, x, z, r, out[0], out[1], out[2]])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	print("--- band2 quarry rim overlook candidates (dep 310,1660 / rejoin 330,1950; quarry floor 400,1800) ---")
	_report("known: quarry_station", 401.9, 1802.6)
	_report("known: 2013 potion_large", 350.0, 1968.0)
	_report("cand A (250,1820)", 250.0, 1820.0)
	_report("cand B (230,1870)", 230.0, 1870.0)
	_report("cand C (270,1900)", 270.0, 1900.0)
	_report("cand D (210,1790)", 210.0, 1790.0)
	print("--- band3 gather gap-fill candidates (on-route, 15m off spine) ---")
	_report("3020 fiber", -111.1, 3490.1)
	_report("3021 wood", -82.2, 4086.9)
	_report("3022 stone (rejected, 16.4deg)", -11.0, 4445.0)
	_report("3022 stone alt1 (rejected)", -15.0, 4460.0)
	_report("3022 stone SHIPPED", 5.0, 4430.0)
	_report("3022 stone alt3 (rejected)", -1.3, 4433.5)
	print("--- band4 gather gap-fill candidates (on-route, 15m off spine) ---")
	_report("4025 ironwood", -263.7, 5369.1)
	_report("4026 stone", 40.6, 5531.3)
	_report("4027 wood", 323.7, 5716.6)
	_report("4028 ironwood", 82.3, 6201.2)
	_report("4029 fiber", -194.9, 6381.5)
	_report("4030 ironwood", 14.5, 6794.3)
	quit(0)
