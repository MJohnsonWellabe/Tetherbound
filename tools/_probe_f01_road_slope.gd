extends SceneTree

## F01-a probe: along-road grade and terrain slope under every village road,
## read from the live terrain_playground.json through the same
## playground_heightfield.gd the bake uses. Pure data -- no world, no render.
##
##   godot --headless --path . --script tools/_probe_f01_road_slope.gd
##
## Grade is measured over a 2m baseline along the centreline; `slope` is the
## terrain normal's tilt at the same point (what floor_max_angle 45deg sees).
## Only the part of each road within CLIP_RADIUS of the well is sampled: the
## village plan, not the 12km spine.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const WELL := Vector2(10.0, -10.0)
const CLIP_RADIUS := 75.0
const STEP := 0.5
const BASE := 2.0
## The pre-F01 village polylines (origin/main 47774c350), measured the same way
## so the report can compare like with like.
const OLD_ROADS := [
	["OLD Practice Meadow", [[10.0, -10.0], [18.0, -24.0], [30.0, -40.0]]],
	["OLD The Pond", [[10.0, -10.0], [-14.0, 14.0], [-45.0, 45.0], [-80.0, 85.0], [-105.0, 115.0]]],
	["OLD The Rise", [[10.0, -10.0], [45.0, -22.0], [74.0, -41.0]]],
	["OLD The Inn", [[7.0, -7.0], [2.0, -8.5], [-1.5, -8.1]]],
	["OLD band1 stub", [[27.5, -16.0], [14.0, 20.0]]],
]


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	var field: RefCounted = HEIGHTFIELD.new(config)
	var paths: Dictionary = config.get("paths", {})
	var roads: Array = []
	for raw: Variant in paths.get("routes", []):
		roads.append([str((raw as Dictionary).get("label", "")), (raw as Dictionary).get("points", [])])
	for raw: Variant in paths.get("approaches", []):
		roads.append([str((raw as Dictionary).get("id", "")), (raw as Dictionary).get("points", [])])
	for raw: Variant in (config.get("trail", {}) as Dictionary).get("bands", []):
		if str((raw as Dictionary).get("id", "")) == "band1_lower_meadows":
			roads.append(["band1_lower_meadows", (raw as Dictionary).get("points", [])])
	roads.append_array(OLD_ROADS)
	for road: Array in roads:
		var pts: Array = road[1]
		var max_grade := 0.0
		var max_grade_at := Vector2.ZERO
		var max_slope := 0.0
		var max_slope_at := Vector2.ZERO
		var sampled := 0
		for i in pts.size() - 1:
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var length := a.distance_to(b)
			var dir := (b - a) / maxf(length, 0.001)
			var s := 0.0
			while s <= length:
				var p := a + dir * s
				s += STEP
				if p.distance_to(WELL) > CLIP_RADIUS:
					continue
				sampled += 1
				var h0: float = field.height_at(p.x - dir.x * BASE * 0.5, p.y - dir.y * BASE * 0.5)
				var h1: float = field.height_at(p.x + dir.x * BASE * 0.5, p.y + dir.y * BASE * 0.5)
				var grade := rad_to_deg(atan(absf(h1 - h0) / BASE))
				if grade > max_grade:
					max_grade = grade
					max_grade_at = p
				var n: Vector3 = field.normal_at(p.x, p.y)
				var slope := rad_to_deg(acos(clampf(n.y, -1.0, 1.0)))
				if slope > max_slope:
					max_slope = slope
					max_slope_at = p
		if sampled == 0:
			continue
		print("F01 road %-24s samples %4d  max grade %5.2f deg at (%.1f,%.1f)  max terrain slope %5.2f deg at (%.1f,%.1f)" % [
			road[0], sampled, max_grade, max_grade_at.x, max_grade_at.y, max_slope, max_slope_at.x, max_slope_at.y])
	# F01-b: terrain slope across each named subarea's disk.
	for raw: Variant in ((paths.get("village_topology", {}) as Dictionary).get("subareas", []) as Array):
		var sub := raw as Dictionary
		var c := Vector2(float(sub.centre[0]), float(sub.centre[1]))
		var r := float(sub.get("radius", 0.0))
		var worst := 0.0
		var lo := INF
		var hi := -INF
		var x := -r
		while x <= r:
			var z := -r
			while z <= r:
				if Vector2(x, z).length() <= r:
					var n: Vector3 = field.normal_at(c.x + x, c.y + z)
					worst = maxf(worst, rad_to_deg(acos(clampf(n.y, -1.0, 1.0))))
					var h: float = field.height_at(c.x + x, c.y + z)
					lo = minf(lo, h)
					hi = maxf(hi, h)
				z += 1.0
			x += 1.0
		print("F01 subarea %-14s max slope %5.2f deg  relief %.2fm" % [str(sub.get("name", "")), worst, hi - lo])
	quit(0)
