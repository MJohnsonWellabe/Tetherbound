extends SceneTree

## EV5-remainder-2 (outlet) — does the pond actually drain into the gorge?
##
##   godot --headless --path . --script tools/_probe_outlet.gd
##
## Analytic only: `playground_heightfield.height_at` reads the JSON live, so
## this measures a candidate WITHOUT a bake. Three readings:
##
## 1. An ASCII map of the wet field around the pond and the river gorge, with
##    `water.gd::_build_pond`'s own 8-connected flood fill from the pond centre
##    re-run on it — so "connected to the pond" here means exactly what the
##    water composer means by it, not something adjacent.
## 2. The narrowest wet cross-section along the pond -> gorge corridor (is the
##    join a stream-width neck, or a reservoir-wide merge?).
## 3. A height transect from the pond centre out along the gorge axis.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const STEP := 2.0
const HALF := 70.0


func _init() -> void:
	var cfg: Dictionary = HEIGHTFIELD.load_config()
	if OS.get_cmdline_user_args().has("--no-gorge"):
		for entry: Variant in cfg.get("spokes", {}).get("routes", []):
			if entry is Dictionary and str((entry as Dictionary).get("id", "")) == "river_gorge":
				(entry as Dictionary)["built"] = false
		print("*** river_gorge carve SUPPRESSED: this is the pond's own shape ***")
	var field: RefCounted = HEIGHTFIELD.new(cfg)
	var water: Dictionary = cfg.get("water", {})
	var level := float(water.get("level", -22.5))
	var pc: Array = water.get("pond_centre", [0.0, 0.0])
	var centre := Vector2(float(pc[0]), float(pc[1]))

	var carve := _gorge_carve(cfg)
	var gc := Vector2(float(carve.get("centre", [0, 0])[0]), float(carve.get("centre", [0, 0])[1]))
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))

	print("water level %.2f  pond centre %s  gorge centre %s  axis %.1f deg" % [
		level, centre, gc, float(carve.get("axis_deg", 0.0))])
	print("carve: half_length %.1f end_fade %.1f half_width %.1f rim %.1f depth %.1f" % [
		float(carve.get("half_length", 0.0)), float(carve.get("end_fade", 0.0)),
		float(carve.get("half_width", 0.0)), float(carve.get("rim", 0.0)),
		float(carve.get("depth", 0.0))])

	# ---- wet field + flood fill -------------------------------------------
	var cols := int(HALF * 2.0 / STEP) + 1
	var origin := centre - Vector2(HALF, HALF) * 0.6 - Vector2(20.0, 0.0)
	var wet: Dictionary = {}
	for row in cols:
		for col in cols:
			var p := origin + Vector2(col, row) * STEP
			if field.call("height_at", p.x, p.y) < level:
				wet[Vector2i(col, row)] = true

	var seed_cell := Vector2i(
		int(round((centre.x - origin.x) / STEP)), int(round((centre.y - origin.y) / STEP)))
	var kept: Dictionary = {}
	if wet.has(seed_cell):
		var frontier: Array[Vector2i] = [seed_cell]
		kept[seed_cell] = true
		while not frontier.is_empty():
			var cell: Vector2i = frontier.pop_back()
			for off: Vector2i in [
				Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
				Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
				var n := cell + off
				if wet.has(n) and not kept.has(n):
					kept[n] = true
					frontier.append(n)
	print("wet cells %d, connected to pond %d, orphaned %d (cell = %.1fm)" % [
		wet.size(), kept.size(), wet.size() - kept.size(), STEP])

	# ---- map ---------------------------------------------------------------
	print("\nmap: '#' wet+connected, 'o' wet but NOT connected, '.' dry.")
	print("     'P' pond centre, 'G' gorge centre, origin %s, step %.1fm, +z down" % [origin, STEP])
	for row in cols:
		var line := ""
		for col in cols:
			var c := Vector2i(col, row)
			if c == seed_cell:
				line += "P"
			elif c == Vector2i(int(round((gc.x - origin.x) / STEP)), int(round((gc.y - origin.y) / STEP))):
				line += "G"
			elif kept.has(c):
				line += "#"
			elif wet.has(c):
				line += "o"
			else:
				line += "."
		print(line)

	# ---- corridor cross-sections ------------------------------------------
	# March along the gorge axis from the pond side; at each station measure how
	# wide the connected wet band is perpendicular to the axis.
	print("\ncorridor: wet width perpendicular to the gorge axis, by along-axis u")
	print("  (u measured from the gorge centre; negative = pond side)")
	for i in range(-34, 26, 2):
		var u := float(i)
		var base := gc + axis * u
		var perp := Vector2(-axis.y, axis.x)
		var width := 0.0
		var runs := 0
		var was_wet := false
		for j in range(-60, 61):
			var q := base + perp * (float(j) * 0.5)
			var w: bool = field.call("height_at", q.x, q.y) < level
			if w:
				width += 0.5
				if not was_wet:
					runs += 1
			was_wet = w
		var floor_h: float = field.call("height_at", base.x, base.y)
		print("  u %+6.1f  bed %7.2f  %s  wet width %5.1fm  bands %d" % [
			u, floor_h, ("WET " if floor_h < level else "dry "), width, runs])

	# ---- transect pond centre -> along the axis ----------------------------
	print("\ntransect from pond centre toward the gorge (bearing %.1f deg):" % float(carve.get("axis_deg", 0.0)))
	var dir := (gc - centre).normalized()
	for i in range(0, 46):
		var d := float(i) * 2.0
		var p := centre + dir * d
		var h: float = field.call("height_at", p.x, p.y)
		print("  d %5.1f  at (%7.1f,%7.1f)  h %7.2f  %s" % [
			d, p.x, p.y, h, ("water %.2f deep" % (level - h)) if h < level else "DRY"])

	quit()


func _gorge_carve(cfg: Dictionary) -> Dictionary:
	for entry: Variant in cfg.get("spokes", {}).get("routes", []):
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == "river_gorge":
			return ((entry as Dictionary).get("blocker", {}) as Dictionary).get("carve", {})
	return {}
