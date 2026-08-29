extends SceneTree

## T3-PICKUPS scratch probe: real ground heights and local slope for candidate
## consumable/armor/TM positions before they're authored into data, same
## pattern as tools/_probe_band4_sites.gd. No terrain bake touched.
##   godot --headless --path . --script tools/_probe_pickups_sites.gd

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
	print("%-24s [%7.1f,%7.1f] r=%.0f  h=%7.2f spread=%5.2f worst=%5.1f" % [
		label, x, z, r, out[0], out[1], out[2]])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	print("--- band1 ---")
	_report("1028 potion_small", -470.0, 540.0)
	_report("1029 orb_basic", -245.0, 935.0)
	_report("1030 travel_pack", 515.0, 1035.0)
	print("--- band2 ---")
	_report("2013 potion_large", 350.0, 1968.0)
	_report("2014 revive", -165.0, 2745.0)
	_report("2015 hide_boots", -165.0, 2225.0)
	print("--- band3 ---")
	_report("3016 potion_small", -140.0, 4175.0)
	_report("3017 orb_basic", 515.0, 4225.0)
	_report("3018 hide_leggings", 165.0, 4548.0)
	print("--- band4 ---")
	_report("4021 revive", 55.0, 6815.0)
	_report("4022 potion_large", -270.0, 5240.0)
	_report("4023 hide_helm", -360.0, 5065.0)
	_report("TM_AT candidate", 85.0, 6260.0)
	print("--- band5 ---")
	_report("5007 elixir_might", -165.0, 7065.0)
	_report("5008 revive", 165.0, 7480.0)
	quit(0)
