extends SceneTree

## SF31/SF34 scratch probe: real ground heights and local slope across the
## upper Meadows (the country between the high-pass trainer road and the
## Rise's flank, inside world_perimeter.gd's 235m ring), so the Ironwood
## stands, the three captains and the Sigil gate are sited on measured numbers
## rather than guesses. Same pattern as tools/_probe_ground.gd; no terrain bake
## is touched.

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


func _report(label: String, x: float, z: float, r: float) -> void:
	var out := _pad(x, z, r)
	print("%-22s [%6.1f,%7.1f] r=%.0f  h=%7.2f spread=%5.2f worst=%5.1f  ring=%.0f" % [
		label, x, z, r, out[0], out[1], out[2], sqrt(x * x + z * z)])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	print("--- captain arena candidates (pad r=8m) ---")
	for c: Array in [
		["field A", 62.0, -118.0], ["field B", 58.0, -124.0], ["field C", 62.0, -112.0],
		["field D", 56.0, -112.0], ["field E", 52.0, -122.0],
		["ridge A", 84.0, -152.0], ["ridge B", 88.0, -155.0], ["ridge C", 80.0, -150.0],
		["ridge D", 78.0, -156.0], ["ridge E", 92.0, -157.0],
		["river A", 112.0, -177.0], ["river B", 108.0, -170.0], ["river C", 116.0, -182.0],
		["river D", 104.0, -174.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 8.0)
	print("--- gate candidates (pad r=5m) ---")
	for c: Array in [
		["gate A", 126.0, -180.0], ["gate B", 124.0, -176.0], ["gate C", 130.0, -176.0],
		["gate D", 122.0, -184.0], ["gate E", 128.0, -184.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 5.0)
	print("--- ironwood stand candidates (pad r=3m) ---")
	for c: Array in [
		["iron 1", 70.0, -128.0], ["iron 2", 76.0, -146.0], ["iron 3", 92.0, -158.0],
		["iron 4", 100.0, -166.0], ["iron 5", 66.0, -152.0], ["iron 6", 80.0, -152.0],
		["iron 7", 104.0, -172.0], ["iron 8", 118.0, -186.0], ["iron 9", 60.0, -136.0],
		["iron 10", 88.0, -150.0], ["iron 11", 96.0, -162.0], ["iron 12", 110.0, -178.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 3.0)
	quit(0)
