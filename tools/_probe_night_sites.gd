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
	# Band 0 -- the home meadow. The candidate has to be close enough to the
	# village that a player standing at home after dark can see it, and clear
	# of every vegetation clearing (band1 vegetation.json clearings 0-4: spawn
	# r16, square r22, Grandpa r16, practice meadow r16, trainer ground r14),
	# because a clearing is where the trees are NOT and an owl wants cover.
	print("--- band 0: home meadow, night hook ---")
	_report("village_east_treeline", 52.0, 58.0)
	_report("village_east alt", 60.0, 46.0)
	_report("north_of_square", -8.0, 152.0)
	_report("north_of_square alt", 4.0, 160.0)
	_report("west_hedge", -62.0, 96.0)
	# Band 1 -- the oak grove ring loop, whose own terrain feature
	# (data/config/terrain_playground.json id `oak_grove_ring`) carries the
	# _why "Duskhush at night, the trainer circuit's second fight, wood at
	# scale". Loop points: (230,830) (300,880) (370,950) (400,1040) (370,1100)
	# (330,1130). The trail camp sits at (344,935), inside the loop.
	print("--- band 1: oak grove ring loop ---")
	_report("ring_mouth", 262.0, 852.0)
	_report("ring_mouth alt", 275.0, 862.0)
	_report("grove_interior_s", 322.0, 900.0)
	_report("grove_interior_s alt", 310.0, 892.0)
	_report("camp_grove_edge", 382.0, 986.0)
	_report("camp_grove_edge alt", 392.0, 998.0)
	_report("ring_far_side", 402.0, 1052.0)
	_report("ring_far_side alt", 392.0, 1064.0)
	_report("ring_north", 352.0, 1108.0)
	_report("ring_north alt", 344.0, 1118.0)
	# The pipwing grove pocket (spawns order 1046) and the tm_wind_blade
	# pickup (playground_world.gd) already bank on the grove interior south of
	# the ring mouth being worth a detour; a night population there is the same
	# ground rewarding the same curiosity after dark.
	print("--- band 1: grove pocket south of the ring mouth ---")
	_report("pipwing_pocket_night", 326.0, 796.0)
	_report("pipwing_pocket alt", 318.0, 806.0)
	print("--- FINAL candidates: separation-swept ring sites ---")
	_report("f_ring_mouth", 247.0, 806.0)
	_report("f_grove_west", 269.0, 894.0)
	_report("f_grove_east", 342.0, 880.0)
	_report("f_camp_grove", 338.0, 961.0)
	_report("f_ring_far", 365.0, 1043.0)
	_report("f_ring_north", 382.0, 1128.0)
	print("--- FINAL candidates: band 0 ---")
	_report("f_home_east", 60.0, 46.0)
	_report("f_home_north", 4.0, 160.0)
	quit(0)
