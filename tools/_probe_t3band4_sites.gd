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
	print("--- seam1 grove (tree line, band3->4), near spine m~7480-7620 (pad r=5m) ---")
	for c: Array in [
		["grove A", -20.0, 4800.0], ["grove B", -60.0, 4850.0], ["grove C", -100.0, 4900.0],
		["grove D", -150.0, 4950.0], ["grove E", 20.0, 4780.0], ["grove F", -180.0, 5000.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 5.0)
	print("--- gap A optional trainer, near spine m~8334 (-210.85,5384.47) (pad r=6m) ---")
	for c: Array in [
		["gapA a", -195.0, 5370.0], ["gapA b", -225.0, 5400.0], ["gapA c", -190.0, 5410.0],
		["gapA d", -230.0, 5360.0], ["gapA e", -205.0, 5395.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 6.0)
	print("--- gap B TM pickup, near spine m~9735 (57.67,6231.51) (pad r=4m) ---")
	for c: Array in [
		["gapB a", 45.0, 6220.0], ["gapB b", 70.0, 6245.0], ["gapB c", 50.0, 6250.0],
		["gapB d", 65.0, 6210.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 4.0)
	print("--- seam2 watchtower landmark, near spine m~10500-10650 (pad r=7m) ---")
	for c: Array in [
		["tower A", -30.0, 6790.0], ["tower B", -50.0, 6820.0], ["tower C", 40.0, 6800.0],
		["tower D", 10.0, 6850.0], ["tower E", -20.0, 6870.0], ["tower F", 60.0, 6830.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 7.0)
	print("--- seam2 TM reward, close beside watchtower (pad r=3m) ---")
	for c: Array in [
		["towerTM a", -25.0, 6800.0], ["towerTM b", -15.0, 6810.0], ["towerTM c", -35.0, 6795.0],
	]:
		_report(str(c[0]), float(c[1]), float(c[2]), 3.0)
	quit(0)
