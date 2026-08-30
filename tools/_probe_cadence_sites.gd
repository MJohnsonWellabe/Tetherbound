extends SceneTree

## T5-CADENCE scratch probe: real ground height, local relief and worst slope
## at every site this lane is about to author into band 3's and band 4's
## measured dead stretches, BEFORE any of them go into data.
##
## Same pattern and the same numbers as tools/_probe_activities_sites.gd and
## tools/_probe_band4_sites.gd -- a camp on a 1.2m drop is what put band 1's
## trail camp through three rounds of relocation (that cluster's own `_why`),
## and a probe is cheaper than a fourth.
##
##   godot --headless --path . --script tools/_probe_cadence_sites.gd

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


func _report(label: String, x: float, z: float, r: float = 6.0) -> void:
	var out := _pad(x, z, r)
	print("%-34s [%7.1f,%7.1f] r=%2.0f  h=%7.2f spread=%5.2f worst=%5.1f" % [
		label, x, z, r, out[0], out[1], out[2]])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	print("--- band3 opening (arc 0-668, the 668m dead run) ---")
	_report("haulage_wreck", -70.0, 3252.0)
	_report("lockwater_overlook", -128.0, 3450.0)
	_report("lockwater_overlook alt", -140.0, 3462.0)
	_report("springhead", -6.0, 3552.0)
	_report("springhead alt", 8.0, 3560.0)
	print("--- band3 exit (arc 1855-2375, the 519m dead run) ---")
	_report("northbank_ironwood_cut", 65.0, 4490.0)
	_report("northbank alt", 78.0, 4500.0)
	_report("bluff alpha", 152.0, 4552.0)
	_report("crossing_watchpost", 127.0, 4649.0)
	_report("watchpost alt", 118.0, 4664.0)
	print("--- band4 (arc 1386-2547, the 1161m dead run) ---")
	_report("highfield_stockcamp", 270.0, 5665.0)
	_report("stockcamp alt", 258.0, 5652.0)
	_report("stockcamp alt2", 285.0, 5678.0)
	_report("herd bull alpha", 425.0, 5844.0)
	_report("severed_conduit_post", 385.0, 6055.0)
	_report("conduit alt", 372.0, 6068.0)
	_report("wind_stones", 205.0, 6140.0)
	_report("wind_stones alt", 218.0, 6128.0)
	_report("ridge_road_picket", -25.0, 6285.0)
	_report("picket alt", -12.0, 6276.0)
	quit(0)
