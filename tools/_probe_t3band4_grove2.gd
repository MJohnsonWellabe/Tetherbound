extends SceneTree

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
	print("%-28s [%7.1f,%7.1f] r=%.0f  h=%7.2f spread=%5.2f worst=%5.1f" % [
		label, x, z, r, out[0], out[1], out[2]])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	print("--- grove near-spine (r=4m) ---")
	for c: Array in [
		["grove2 A", -63.0, 4823.0], ["grove2 A2", -56.0, 4818.0], ["grove2 A3", -68.0, 4828.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 4.0)
	print("--- meadowhart near-spine (r=3m) ---")
	for c: Array in [
		["mh A", -40.0, 4800.0], ["mh B", -45.0, 4793.0], ["mh C", -35.0, 4805.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 3.0)
	quit(0)
