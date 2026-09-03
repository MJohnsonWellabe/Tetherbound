extends SceneTree

## WORLD-CONTENT (BAND1_ROUTE_CONTRACT) scratch probe: real ground heights and
## local slope for the two new field trainers, the Rise signpost, the item
## cache, the Pond fisher/camp-prop candidates and the eight new harvest
## nodes -- before any of it is authored into data. Same pattern as
## tools/_probe_offroute_site.gd / tools/_probe_activities_sites.gd.
##   godot --headless --path . --script tools/_probe_world_content_0903.gd

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
	print("%-28s [%8.1f,%8.1f] r=%.0f  h=%7.2f spread=%5.2f worst=%5.1f" % [
		label, x, z, r, out[0], out[1], out[2]])


func _init() -> void:
	_field = HEIGHTFIELD.new()
	print("--- trainers (need a flat arena pad, r=5) ---")
	_report("shepherd_the_rise", -372.0, 446.8, 5.0)
	_report("wanderer_trail_camp", 313.3, 900.1, 5.0)
	print("--- Rise crest: signpost + cache ---")
	_report("rise_signpost", -239.1, 341.7, 2.0)
	_report("rise_cache", -235.9, 389.9, 2.0)
	_report("rise_cache_dead_tree", -235.9, 389.9, 1.0)
	print("--- Pond: fisher NPC + camp prop ---")
	_report("pond_fisher_candidate_A", -410.0, 545.0, 2.0)
	_report("pond_fisher_candidate_B", -405.0, 535.0, 2.0)
	_report("pond_camp_prop_candidate", -415.0, 560.0, 2.0)
	print("--- Bridge approach: broken-fence line ---")
	_report("bridge_fence_A", 60.0, 1230.0, 2.0)
	_report("bridge_fence_B", 45.0, 1215.0, 2.0)
	print("--- 8 new harvest nodes ---")
	_report("h_1040_stone", -10.8, 104.1, 1.5)
	_report("h_1041_wood", -326.9, 368.5, 1.5)
	_report("h_1042_stone", -390.6, 470.5, 1.5)
	_report("h_1043_berries", -390.1, 565.0, 1.5)
	_report("h_1044_wood", 126.8, 762.8, 1.5)
	_report("h_1045_stone", 221.7, 841.5, 1.5)
	_report("h_1046_wood", 107.5, 1236.8, 1.5)
	_report("h_1047_stone", -32.7, 1288.0, 1.5)
	quit(0)
