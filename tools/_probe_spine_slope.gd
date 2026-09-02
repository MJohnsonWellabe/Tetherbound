extends SceneTree

## SPINE-WEDGE. Sample the authored trail against the authored landform and
## name every feature that makes it unwalkable -- without baking anything and
## without booting a world.
##
##   godot --headless --path . --script tools/_probe_spine_slope.gd
##   godot --headless --path . --script tools/_probe_spine_slope.gd -- --step=0.5
##
## WHY THIS IS ALLOWED TO SAMPLE THE HEIGHTFIELD, when `_probe_ow5_walk.gd`'s
## own header says three investigations died doing exactly that.
##
## Those two uses are opposites and the distinction is the whole point:
##
##   * DIAGNOSING a stopped body is a physics question. `height_at` is analytic
##     and does not know what `move_and_slide` will do, so a height sample is
##     evidence about the config and none at all about the body. WALL1, COLL1
##     and OW5C each mistook one for the other.
##   * ASSERTING that an authored route does not cross authored terrain is a
##     CONFIG question, and the config is the only thing that can answer it.
##
## `docs/CURRENT_STATE.md` states this constraint in as many words, as something
## `OW5C` inherited from `OF15`: "No trail segment may cross ground steeper
## than `floor_max_angle`. Assert it with a probe over the candidate route
## BEFORE the bake, not by walking it afterwards: `height_at` is analytic and
## unbounded, so the whole spine can be sampled without baking anything, and at
## hours per bake that is not optional."
##
## Nothing ever built that probe. This is it, three trail-authoring passes
## late, and on its first run it named the feature behind the corridor's worst
## blockage in eight seconds -- a blockage a real body had needed half an hour
## of walking to find and could only describe as "Terrain, 12 degrees".
##
## It does not replace walking. A slope this reports is a candidate; the walk
## is what proves a body passes. It replaces GUESSING which authored feature a
## walk has just run into.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CONFIG := "res://data/config/terrain_playground.json"

## player.tscn's `floor_max_angle` (0.7854 rad). A body refuses to treat
## anything steeper as floor, so a trail crossing it is not a trail.
const FLOOR_MAX_ANGLE_DEG := 45.0

## Report a run only once it is at least this long. A single 1m sample over the
## limit is a heightfield ripple; a body walks over it. A metre of it is a wall.
const MIN_RUN_M := 1.0

var _step := 1.0
var _hf: RefCounted = null
var _cfg := {}


func _init() -> void:
	_run()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.split("=", true, 1)
		if parts[0].lstrip("-") == "step" and parts.size() > 1:
			_step = maxf(0.25, float(parts[1]))

	_cfg = HEIGHTFIELD.load_config()
	_hf = HEIGHTFIELD.new(_cfg)
	print("=== spine slope probe ===")
	print("floor_max_angle %.0f deg, sampling every %.2f m" % [FLOOR_MAX_ANGLE_DEG, _step])

	var routes := _routes()
	var total_findings := 0
	for route: Dictionary in routes:
		total_findings += _scan(str(route["name"]), route["points"])

	print("\n=== %d unwalkable run(s) on authored routes ===" % total_findings)
	if total_findings == 0:
		print("Every authored route stays inside the body's own floor limit.")
	quit(0)


## The spine, then the loops and shortcuts. All of them are routes the game
## asks a player to walk, and all of them were authored the same way.
func _routes() -> Array:
	var trail: Dictionary = _cfg.get("trail", {})
	var out: Array = []

	var spine: Array[Vector2] = []
	for band in trail.get("bands", []):
		for p in band.get("points", []):
			var v := Vector2(float(p[0]), float(p[1]))
			if spine.is_empty() or spine[spine.size() - 1].distance_to(v) > 0.01:
				spine.append(v)
	out.append({"name": "spine", "points": spine})

	for key in ["loops", "shortcuts"]:
		for entry in trail.get(key, []):
			var pts: Array[Vector2] = []
			for p in (entry as Dictionary).get("points", []):
				pts.append(Vector2(float(p[0]), float(p[1])))
			if pts.size() >= 2:
				out.append({"name": "%s:%s" % [key, str((entry as Dictionary).get("id", "?"))],
					"points": pts})
	return out


## Walk a polyline in `_step` metres and collect the runs that are too steep.
func _scan(name: String, points: Array) -> int:
	if points.size() < 2:
		return 0
	var runs: Array = []
	var open := {}
	var walked := 0.0
	var worst := 0.0
	var worst_at := Vector2.ZERO

	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var leg := a.distance_to(b)
		var n := maxi(1, int(ceil(leg / _step)))
		for k in range(n + 1):
			var at: Vector2 = a.lerp(b, float(k) / float(n))
			var slope := float(_hf.call("slope_degrees_at", at.x, at.y, 1.0))
			if slope > worst:
				worst = slope
				worst_at = at
			if slope > FLOOR_MAX_ANGLE_DEG:
				if open.is_empty():
					open = {"from": at, "to": at, "peak": slope, "peak_at": at, "wp": i}
				else:
					open["to"] = at
					if slope > float(open["peak"]):
						open["peak"] = slope
						open["peak_at"] = at
			elif not open.is_empty():
				runs.append(open)
				open = {}
			walked += leg / float(n)
	if not open.is_empty():
		runs.append(open)

	var kept: Array = []
	for r: Dictionary in runs:
		if float(r["from"].distance_to(r["to"])) >= MIN_RUN_M:
			kept.append(r)

	print("\n--- %s: %d points, %.1f m, steepest %.1f deg at (%.1f, %.1f) ---" % [
		name, points.size(), walked, worst, worst_at.x, worst_at.y])
	if kept.is_empty():
		print("  clear: nothing over %.0f deg for %.0f m or more" % [FLOOR_MAX_ANGLE_DEG, MIN_RUN_M])
		return 0

	for r: Dictionary in kept:
		var mid: Vector2 = (r["from"] as Vector2).lerp(r["to"] as Vector2, 0.5)
		print("  UNWALKABLE %.1f m from (%.1f, %.1f) to (%.1f, %.1f), peak %.1f deg at (%.1f, %.1f), after waypoint %d" % [
			float(r["from"].distance_to(r["to"])), r["from"].x, r["from"].y,
			r["to"].x, r["to"].y, r["peak"], r["peak_at"].x, r["peak_at"].y, r["wp"]])
		for line in _blame(mid):
			print("      %s" % line)
	return kept.size()


## Name the authored feature, not the coordinate.
##
## The same rule `_probe_ow5_walk.gd::_describe_wedge` follows for colliders,
## one layer up: a slope reading says a route is unwalkable and says nothing at
## all about WHOSE it is, and "the trail is steep at (-22, 7526)" is exactly the
## kind of finding that gets fixed by moving terrain at one coordinate while the
## mechanism stands. This asks each authored feature how much depth it is
## contributing at the point, and reports the ones that answer.
func _blame(at: Vector2) -> Array[String]:
	var out: Array[String] = []

	var spokes: Dictionary = _cfg.get("spokes", {})
	for entry in spokes.get("routes", []):
		var blocker: Dictionary = (entry as Dictionary).get("blocker", {})
		var carve: Dictionary = blocker.get("carve", {})
		if carve.is_empty():
			continue
		var d := _carve_depth_at(at, carve)
		if d > 0.05:
			out.append("cut %.1f m deep by spokes.routes[%s].blocker.carve (%s), centre %s, reach %.0f m along its axis" % [
				d, str((entry as Dictionary).get("id", "?")), str(blocker.get("kind", "?")),
				str(carve.get("centre", [])),
				float(carve.get("half_length", 0.0)) + float(carve.get("end_fade", 0.0))])

	for entry in _cfg.get("crossings", []):
		var carve: Dictionary = (entry as Dictionary).get("carve", {})
		if carve.is_empty():
			continue
		var d := _carve_depth_at(at, carve)
		if d > 0.05:
			out.append("cut %.1f m deep by crossings[%s].carve, centre %s -- there is a bridge here; the route has to be ON it" % [
				d, str((entry as Dictionary).get("id", "?")), str(carve.get("centre", []))])

	var river := float(_hf.call("_river_carve", at.x, at.y))
	if river > 0.05:
		out.append("cut %.1f m deep by the river channel (river.course)" % river)

	var stream := float(_hf.call("_stream_carve", at.x, at.y))
	if stream > 0.05:
		out.append("cut %.1f m deep by the stream channel (water.stream)" % stream)

	for peak in (_cfg.get("rises", {}) as Dictionary).get("peaks", []):
		var c := Vector2(float(peak["centre"][0]), float(peak["centre"][1]))
		var radius := float(peak.get("radius", 0.0))
		if c.distance_to(at) <= radius:
			out.append("inside rises.peaks centre %s radius %.0f height %.0f" % [
				str(peak["centre"]), radius, float(peak.get("height", 0.0))])

	if out.is_empty():
		out.append("no authored carve or rise here -- this is the base landform (hills/detail/valley noise)")
	return out


## `playground_heightfield._prepared_carve_depth` through its own preparation,
## so this reads exactly what the bake will cut and never a second opinion.
func _carve_depth_at(at: Vector2, carve: Dictionary) -> float:
	var prepared: Dictionary = _hf.call("_prepare_carve", carve)
	if prepared.is_empty():
		return 0.0
	return float(_hf.call("_prepared_carve_depth", at, prepared))
