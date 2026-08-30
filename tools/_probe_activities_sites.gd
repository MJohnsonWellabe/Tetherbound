extends SceneTree

## T3-ACTIVITIES scratch probe: real ground heights and local slope for the
## five new local-request giver/battle sites, before they are authored into
## data. Same pattern as tools/_probe_pickups_sites.gd / _probe_band4_sites.gd.
##   godot --headless --path . --script tools/_probe_activities_sites.gd

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


func _report(label: String, x: float, z: float, r: float = 3.0) -> void:
	var out := _pad(x, z, r)
	print("%-32s [%7.1f,%7.1f] r=%.0f  h=%7.2f spread=%5.2f worst=%5.1f" % [
		label, x, z, r, out[0], out[1], out[2]])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	print("--- band1 ---")
	_report("meadowhart_herd giver Rae", -205.0, 1185.0)
	_report("broken_cart bridgehand Coll", 80.0, 1240.0)
	print("--- band2 ---")
	_report("night_watch giver Perrin", 52.0, 2851.0)
	_report("night_watch trainer Farro", 95.0, 2900.0)
	print("--- band3 ---")
	_report("river_nest trainer Doss", 66.0, 3988.0)
	print("--- band4 ---")
	_report("lost_creature giver Yara", -260.0, 5820.0)
	_report("lost_creature trainer Rue", -300.0, 5870.0)
	quit(0)
