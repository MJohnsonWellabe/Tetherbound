extends SceneTree

## T5-CAMPS scratch probe: real ground height, local relief and worst slope at
## every candidate night-spawn site in bands 0 and 1, BEFORE any of them go into
## data.
##
## Same pattern and the same numbers as tools/_probe_cadence_sites.gd. The
## specific failure this is guarding against is named in
## data/config/spawns.json's own `_comment_placement`: Galecrest and Burrowback
## were originally authored on the rocky rise at [140,-90], whose rim is a
## closed >45-degree band by design -- "measured at 71 of 72 radial approaches
## unwalkable" -- so a creature up there can never be met, fought or caught. A
## night-gated creature is harder to notice is unreachable, not easier, because
## the player only ever has a chance to meet it after dark.
##
##   godot --headless --path . --script tools/_probe_night_sites.gd

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


func _report(label: String, x: float, z: float, r: float = 12.0) -> void:
	var out := _pad(x, z, r)
	var verdict := "ok"
	if float(out[2]) >= 45.0:
		verdict = "UNWALKABLE"
	elif float(out[2]) >= 30.0:
		verdict = "steep"
	print("%-30s [%7.1f,%7.1f] r=%2.0f  h=%7.2f spread=%5.2f worst=%5.1f  %s" % [
		label, x, z, r, out[0], out[1], out[2], verdict])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	# BAND 0 -- the home meadow. Close enough to the village that a player
	# standing at home after dark can see it, and clear of every vegetation
	# clearing (band1 vegetation.json clearings 0-4), because a clearing is
	# where the trees are NOT and an owl wants cover.
	print("--- band 0: home meadow, the night hook ---")
	_report("home_east      (1050)", 60.0, 46.0)
	_report("home_north     (1051)", 4.0, 160.0)
	# BAND 1 -- the oak grove ring. docs/MEADOWS_MACRO_LAYOUT.md: "grove
	# (Trailpup/Duskhush/Burrowback) in Band 1's oak ring and Band 2". Band 1
	# held NEITHER named grove species. Both halves go in here: Duskhush gated
	# to night, Trailpup ungated as the ring's ordinary resident population.
	# Every site below cleared >=38 m from every pre-existing cluster centre in
	# the band, >=46 m from each other and >=25 m from the trail camp clearing,
	# swept over the ring polyline before being probed.
	print("--- band 1: oak grove ring -- Duskhush, night-gated ---")
	_report("grove_west     (1052)", 265.0, 897.0)
	_report("camp_grove     (1053)", 337.0, 965.0)
	_report("ring_rejoin    (1054)", 382.0, 1133.0)
	print("--- band 1: oak grove ring -- Trailpup, ungated ---")
	_report("ring_mouth     (1058)", 251.0, 803.0)
	_report("grove_east     (1059)", 347.0, 879.0)
	_report("far_side_west  (1060)", 362.0, 1041.0)
	_report("far_side_east  (1061)", 416.0, 1048.0)
	quit(0)
