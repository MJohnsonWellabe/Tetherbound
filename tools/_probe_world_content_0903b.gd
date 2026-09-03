extends SceneTree

## WORLD-CONTENT follow-up probe: the pond-shore candidates and the harvest
## berries stop at order 1043 came back underwater (water.level -17.0) in the
## first pass; the shepherd trainer's arena pad came back steeper than wanted.
## This scans a ring/grid around each to find real dry, flatter ground.
##   godot --headless --path . --script tools/_probe_world_content_0903b.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const WATER_LEVEL := -17.0

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


func _scan_ring(label: String, cx: float, cz: float, radii: Array, r: float = 2.0) -> void:
	print("--- ring scan: %s (centre %.1f,%.1f) ---" % [label, cx, cz])
	for radius: float in radii:
		for i in 12:
			var a := TAU * float(i) / 12.0
			var px := cx + cos(a) * radius
			var pz := cz + sin(a) * radius
			var out := _pad(px, pz, r)
			var h: float = out[0]
			if h > WATER_LEVEL + 1.0:
				print("  rad=%5.1f ang=%3.0f  pos=(%7.1f,%7.1f)  h=%6.2f  spread=%5.2f  worst=%5.1f  %s" % [
					radius, rad_to_deg(a), px, pz, h, out[1], out[2],
					"DRY" if h > WATER_LEVEL else "WET"])


func _scan_grid(label: String, cx: float, cz: float, half: float, step: float, r: float = 5.0) -> void:
	print("--- grid scan: %s (centre %.1f,%.1f) ---" % [label, cx, cz])
	var best_worst := 1e9
	var best_pos := Vector2(cx, cz)
	var d := -half
	while d <= half:
		var e := -half
		while e <= half:
			var px := cx + d
			var pz := cz + e
			var out := _pad(px, pz, r)
			var worst: float = out[2]
			if worst < best_worst:
				best_worst = worst
				best_pos = Vector2(px, pz)
			e += step
		d += step
	print("  best: pos=(%.1f,%.1f) worst_slope=%.1f" % [best_pos.x, best_pos.y, best_worst])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	_scan_ring("pond shore (for fisher NPC + camp prop)", -395.0, 545.0, [20.0, 30.0, 40.0, 50.0])
	_scan_ring("harvest 1043 berries (Pond pocket, near bridge_repair_site)", -391.7, 520.9, [15.0, 25.0, 35.0])
	_scan_grid("shepherd_the_rise flatter pad", -372.0, 446.8, 20.0, 5.0, 5.0)
	_scan_grid("wanderer_trail_camp flatter pad", 313.3, 900.1, 15.0, 5.0, 5.0)
	quit(0)
