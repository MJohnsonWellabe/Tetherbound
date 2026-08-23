extends SceneTree

## IS THE CHOKE POINT ACTUALLY A CHOKE POINT?
##
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_probe_crossings.gd
##
## Owner question: several places in the Meadows are designed around crossing
## at one bridge -- the Old Mill Crossing over the river, the South Bridge over
## the south gully. That design only works if the barrier is genuinely
## impassable everywhere else. This measures whether it is, rather than reading
## the intent out of a comment.
##
## WHY READING THE CONFIG IS NOT AN ANSWER. terrain_playground.json states the
## arithmetic plainly and the arithmetic is sound: the river is "every depth at
## least 10m against a rim of 3.4-7m: 55-77 degrees of wall against the
## player's own 45-degree floor_max_angle". But that describes the RECIPE, and
## the recipe is not what the player walks on. `playground_world.gd` loads a
## BAKED Terrain3D dataset off disk and errors out if it is missing; the
## analytic `playground_heightfield.gd` is only the source the bake was made
## from. Those two can drift, and this sweep has already measured them drifting
## HARD: `_probe_corridor_survey.gd`'s own header records the analytic field and
## the streamed collision disagreeing "by nearly 3 m on ordinary ground and up
## to 22 m near the river channel". 22 m is deeper than the gorge. So the one
## number that matters -- how deep is the ditch the player actually meets --
## has to come from `Terrain3D.data.get_height()`, which is the baked surface
## collision is generated from, and it has to be compared against the recipe
## rather than assumed equal to it.
##
## THREE MEASUREMENTS, in increasing order of how hard they are to argue with:
##
## 1. CROSS-SECTIONS. Walk the authored course, cut a transect across it every
##    few metres, and report the baked bed, the baked rim, the depth between
##    them and the steepest wall -- beside the analytic values at the same
##    points. A station whose baked depth has collapsed is a hole in the wall
##    even if every other station is perfect.
##
## 2. WALKABILITY FLOOD FILL. The honest form of the question. Grid the whole
##    corridor width at 1 m, mark a step between neighbouring cells passable
##    when its slope is within the body's own limit, then flood from the south
##    bank and ask whether the north bank is reached. This needs no judgement
##    about what "steep enough" means: either there is a connected path or
##    there is not, and if there is, this prints where it is.
##
## 3. THE SAME FILL AT THE MOUNTED LIMIT. `riding_controller.gd` raises
##    `floor_max_angle` to a species' `climb_max_slope_deg` while it is ridden
##    -- 55 degrees for ordinary rideables, 60 for the legendary -- and its own
##    header argues that is safe because "walls are 65-66 degrees, so this
##    stays a mobility perk and never a way out". That claim is about the
##    SPOKE gorges. Nobody has made it about the river, whose narrows are
##    authored at 77 degrees but whose shallow reaches are authored at 55 --
##    which is exactly the legendary's climb limit. So the fill runs twice.
##
## The grid is 1 m and not 4 m on purpose. The river's narrowest station is
## authored at half_width 3.6 with a 3.4 m rim, so the whole cut is about 14 m
## wide there; a 4 m grid can step across a feature that size and report a
## barrier as passable or a passage as blocked, depending on where the samples
## happen to land. 1 m over the corridor's full 2,048 m width is ~350k height
## lookups per band, which is a C++ array read each and costs seconds.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"

const BOOT_FRAMES := 60
const CELL := 1.0                  # flood-fill grid, metres
const STATION_SPACING := 12.0      # cross-sections along the course, metres
const TRANSECT_REACH := 60.0       # how far either side of the course to look
const TRANSECT_STEP := 0.5

## The two limits that matter, in degrees. 45 is `player.tscn`'s own
## floor_max_angle; 60 is the legendary's `climb_max_slope_deg`, the highest
## any body in the game reaches (riding_controller.gd).
const LIMIT_PLAYER := 45.0
const LIMIT_MOUNT := 60.0

## A barrier shallower than this cannot stop anybody regardless of its wall
## angle, because the step-up probe and a jump between them eat it.
const MIN_USEFUL_DEPTH := 4.0

## How far clear of the course's own z extent the flood band runs on each side.
## Large enough that the seed and target rows are unambiguously opposite banks
## at every x, which the first run's band was not.
const BAND_MARGIN := 90.0

## Width of the sliding window the passability scan confines each fill to.
## Wider than any barrier here is thick, so a meandering but real route still
## fits inside one window and is not chopped in half by the confinement.
const WINDOW_WIDTH := 64.0

var _field: RefCounted = null
var _world: Node = null
var _terrain_data: Object = null
var _config: Dictionary = {}


func _init() -> void:
	_run()


func _run() -> void:
	_config = _load_config()
	if _config.is_empty():
		print("FAIL could not read %s" % TERRAIN_CONFIG)
		quit(1)
		return

	_field = HEIGHTFIELD.new()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in BOOT_FRAMES:
		await physics_frame

	var terrain: Node = _world.get_node_or_null(^"Terrain")
	if terrain == null:
		print("FAIL no Terrain node; there is no baked surface to measure")
		quit(1)
		return
	_terrain_data = terrain.get("data")
	if _terrain_data == null:
		print("FAIL Terrain3D has no data; the bake did not load")
		quit(1)
		return
	print("[probe] world up; measuring the BAKED surface via Terrain3D.data.get_height()")
	print("")

	var bounds: Dictionary = _config.get("world_bounds", {}) as Dictionary
	var min_x := float(bounds.get("min_x", -1024.0))
	var max_x := float(bounds.get("max_x", 1024.0))

	_report_river(min_x, max_x)
	_report_south_gully()

	print("")
	print("Every height above is the baked dataset the player collides with,")
	print("not playground_heightfield.gd's recipe. Where the two disagree the")
	print("baked value is the one that decides whether a crossing is a crossing.")
	quit(0)


## --- the river --------------------------------------------------------------

func _report_river(min_x: float, max_x: float) -> void:
	var river: Dictionary = _config.get("river", {}) as Dictionary
	var course: Array = river.get("course", []) as Array
	if course.size() < 2:
		print("FAIL terrain_playground.json has no river course")
		return

	print("=== THE RIVER (SE21) — the Old Mill Crossing's barrier ===")
	print("Authored course: %d points, x %.0f..%.0f, water level %.1f" % [
		course.size(),
		float((course[0] as Dictionary)["at"][0]),
		float((course[course.size() - 1] as Dictionary)["at"][0]),
		float(river.get("water_level", 0.0))])

	# Does the authored course actually reach both corridor walls? A barrier
	# that stops short of the boundary is walked around, however deep it is.
	var west := float((course[0] as Dictionary)["at"][0])
	var east := float((course[course.size() - 1] as Dictionary)["at"][0])
	var fade := float(river.get("end_fade", 0.0))
	print("Corridor is x %.0f..%.0f. West end %.0f (%.0f m short), east end %.0f (%.0f m short); end_fade %.0f." % [
		min_x, max_x, west, west - min_x, east, max_x - east, fade])

	print("")
	print("%-9s %-9s | %-7s %-7s %-7s %-6s | %-7s %-6s" % [
		"station", "along", "bed", "rim", "depth", "wall", "a-depth", "a-wall"])
	print("-------------------------------------------------------------------------------")

	var worst_depth := 1e9
	var worst_at := Vector2.ZERO
	var stations := 0
	var shallow := 0
	var lines: Array[String] = []

	for i in course.size() - 1:
		var a: Dictionary = course[i] as Dictionary
		var b: Dictionary = course[i + 1] as Dictionary
		var pa := Vector2(float(a["at"][0]), float(a["at"][1]))
		var pb := Vector2(float(b["at"][0]), float(b["at"][1]))
		var seg := pb - pa
		var seg_len := seg.length()
		if seg_len < 0.001:
			continue
		var dir := seg / seg_len
		var across := Vector2(-dir.y, dir.x)
		var walked := 0.0
		while walked < seg_len:
			var at := pa + dir * walked
			var cut := _transect(at, across)
			stations += 1
			if cut["depth"] < worst_depth:
				worst_depth = cut["depth"]
				worst_at = at
			if cut["depth"] < MIN_USEFUL_DEPTH or cut["wall"] < LIMIT_PLAYER:
				shallow += 1
				lines.append("SHALLOW  (%.0f,%.0f) baked depth %.1fm, steepest wall %.0f deg" % [
					at.x, at.y, cut["depth"], cut["wall"]])
			# One printed row per segment keeps the table readable; every
			# station is still measured and a failing one is always printed.
			if walked < STATION_SPACING:
				print("%-9d (%6.0f,%6.0f) | %7.1f %7.1f %7.1f %6.0f | %7.1f %6.0f" % [
					i, at.x, at.y, cut["bed"], cut["rim"], cut["depth"], cut["wall"],
					cut["a_depth"], cut["a_wall"]])
			walked += STATION_SPACING

	print("")
	print("%d stations measured. Shallowest baked cut %.1f m at (%.0f, %.0f)." % [
		stations, worst_depth, worst_at.x, worst_at.y])
	if shallow == 0:
		print("No station is under %.0f m deep or under %.0f degrees of wall." % [
			MIN_USEFUL_DEPTH, LIMIT_PLAYER])
	else:
		print("%d station(s) FAIL the barrier test:" % shallow)
		for line: String in lines:
			print("  " + line)

	# The measurement that does not need a threshold argued over.
	# The band has to straddle the river at EVERY x, not just in the middle.
	# The first run of this probe used z 4120..4300 and reported 2,041 of 2,049
	# columns crossable, which looked like a catastrophic finding and was
	# instead a broken measurement: the course swings from z 4080 at the west
	# end to z 4222 in the middle, so at both ends the whole river sits OUTSIDE
	# a band starting at 4120 and the fill walked along open ground it should
	# never have been given. Take the course's own extent and clear it by a
	# margin on both sides.
	var min_z := 1e9
	var max_z := -1e9
	for entry: Variant in course:
		var z := float((entry as Dictionary)["at"][1])
		min_z = minf(min_z, z)
		max_z = maxf(max_z, z)
	var lo := min_z - BAND_MARGIN
	var hi := max_z + BAND_MARGIN
	print("Course spans z %.0f..%.0f; flooding z %.0f..%.0f so it straddles everywhere." % [
		min_z, max_z, lo, hi])
	print("")
	_flood(min_x, max_x, lo, hi, LIMIT_PLAYER, "player (45 deg)")
	print("")
	_scan_windows(min_x, max_x, lo, hi, LIMIT_PLAYER, "player (45 deg)")
	print("")
	_scan_windows(min_x, max_x, lo, hi, LIMIT_MOUNT, "ridden legendary (60 deg)")


## --- the south gully --------------------------------------------------------

func _report_south_gully() -> void:
	var crossings: Array = _config.get("crossings", []) as Array
	for entry: Variant in crossings:
		var crossing: Dictionary = entry as Dictionary
		var carve: Dictionary = crossing.get("carve", {}) as Dictionary
		if carve.is_empty():
			continue
		var centre := Vector2(float(carve["centre"][0]), float(carve["centre"][1]))
		var axis := deg_to_rad(float(carve.get("axis_deg", 0.0)))
		var half_len := float(carve.get("half_length", 0.0))
		var fade := float(carve.get("end_fade", 0.0))
		print("")
		var label := str(crossing.get("label", crossing.get("id", "?")))
		print("=== %s (%s) ===" % [label, str(crossing.get("id", "?"))])
		print("Authored: depth %.1f, half_width %.1f, rim %.1f, half_length %.1f, end_fade %.1f" % [
			float(carve.get("depth", 0.0)), float(carve.get("half_width", 0.0)),
			float(carve.get("rim", 0.0)), half_len, fade])

		# A straight trench, so its axis and its across-vector are constants.
		# `Vector2.RIGHT.rotated(axis_deg)` is playground_heightfield.gd's own
		# convention (_prepare_carve), NOT a guess: the first run of this probe
		# used Vector2(sin, cos), which is 90 degrees off, so it cut its
		# transects ALONG the ditch instead of across it and reported a 11 m
		# trench as 2.5 m deep. Take the convention from the code that digs it.
		var dir := Vector2.RIGHT.rotated(axis)
		var across := Vector2(-dir.y, dir.x)
		var reach := half_len + fade
		var u := -reach
		var worst := 1e9
		var worst_at := Vector2.ZERO
		var ends_open := 0
		while u <= reach:
			var at := centre + dir * u
			var cut := _transect(at, across)
			if cut["depth"] < worst:
				worst = cut["depth"]
				worst_at = at
			if absf(u) <= half_len and cut["depth"] < MIN_USEFUL_DEPTH:
				ends_open += 1
			u += STATION_SPACING
		print("Across its full-depth length the shallowest baked cut is %.1f m at (%.0f, %.0f)." % [
			worst, worst_at.x, worst_at.y])
		if ends_open > 0:
			print("  %d station(s) inside the full-depth run are under %.0f m." % [
				ends_open, MIN_USEFUL_DEPTH])

		# A trench that does not reach a wall is walked around at its end. This
		# is the property the river's own config comment says the south gully
		# could NOT have, so it is measured rather than assumed either way.
		var end_a := centre + dir * reach
		var end_b := centre - dir * reach
		print("  Trench ends at (%.0f,%.0f) and (%.0f,%.0f) -- a %.0f m bar." % [
			end_a.x, end_a.y, end_b.x, end_b.y, reach * 2.0])
		# Measured rather than asserted. A trench shorter than the corridor is
		# obviously walked around on paper; what the fill adds is whether the
		# ROAD's own bearing is closed and how wide the way round actually is.
		var span := maxf(reach * 2.0, 200.0)
		_scan_windows(centre.x - span, centre.x + span,
			centre.y - BAND_MARGIN, centre.y + BAND_MARGIN,
			LIMIT_PLAYER, "%s, player (45 deg)" % label)


## --- measurement primitives -------------------------------------------------

## One cut across the barrier at `at`, looking `across`. Returns the baked bed,
## the baked rim (the higher of the two lips, so a barrier is only as good as
## its LOW side), the depth between them, and the steepest wall found on either
## flank -- plus the analytic recipe's answer for the same cut, so drift shows.
func _transect(at: Vector2, across: Vector2) -> Dictionary:
	var bed := 1e9
	var a_bed := 1e9
	var left_rim := -1e9
	var right_rim := -1e9
	var a_left := -1e9
	var a_right := -1e9
	var wall := 0.0
	var a_wall := 0.0
	var previous := NAN
	var a_previous := NAN

	var d := -TRANSECT_REACH
	while d <= TRANSECT_REACH:
		var spot := at + across * d
		var h := _baked(spot)
		var a := float(_field.height_at(spot.x, spot.y))
		if not is_nan(h):
			bed = minf(bed, h)
			if d < 0.0:
				left_rim = maxf(left_rim, h)
			else:
				right_rim = maxf(right_rim, h)
			if not is_nan(previous):
				wall = maxf(wall, rad_to_deg(atan(absf(h - previous) / TRANSECT_STEP)))
			previous = h
		a_bed = minf(a_bed, a)
		if d < 0.0:
			a_left = maxf(a_left, a)
		else:
			a_right = maxf(a_right, a)
		if not is_nan(a_previous):
			a_wall = maxf(a_wall, rad_to_deg(atan(absf(a - a_previous) / TRANSECT_STEP)))
		a_previous = a
		d += TRANSECT_STEP

	# The LOWER of the two rims, because a moat with one high side and one low
	# side is only as deep as the low side makes it.
	var rim := minf(left_rim, right_rim)
	var a_rim := minf(a_left, a_right)
	return {
		"bed": bed, "rim": rim, "depth": maxf(0.0, rim - bed), "wall": wall,
		"a_depth": maxf(0.0, a_rim - a_bed), "a_wall": a_wall,
	}


func _baked(at: Vector2) -> float:
	return float(_terrain_data.call("get_height", Vector3(at.x, 0.0, at.y)))


## Grid the band, mark a step between neighbours passable when it is within
## `limit`, flood from the south edge, and report whether the north edge is
## reached and where. No threshold to argue about: either a connected route
## exists or it does not.
func _flood(min_x: float, max_x: float, min_z: float, max_z: float,
		limit_deg: float, who: String) -> void:
	var cols := int((max_x - min_x) / CELL) + 1
	var rows := int((max_z - min_z) / CELL) + 1
	var rise := tan(deg_to_rad(limit_deg)) * CELL

	var height := PackedFloat32Array()
	height.resize(cols * rows)
	for j in rows:
		var z := min_z + float(j) * CELL
		for i in cols:
			height[j * cols + i] = _baked(Vector2(min_x + float(i) * CELL, z))

	var seen := PackedByteArray()
	seen.resize(cols * rows)
	var queue := PackedInt32Array()
	# Seed the whole SOUTH edge -- the near bank, the side the player arrives
	# from. Any NaN cell (outside a baked region) is left unseeded rather than
	# treated as ground.
	for i in cols:
		var index := (rows - 1) * cols + i
		if is_nan(height[index]):
			continue
		seen[index] = 1
		queue.append(index)

	var head := 0
	var reached_north := -1
	while head < queue.size():
		var index := queue[head]
		head += 1
		var i := index % cols
		var j := index / cols
		if j == 0 and reached_north < 0:
			reached_north = i
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ni := i + step.x
			var nj := j + step.y
			if ni < 0 or ni >= cols or nj < 0 or nj >= rows:
				continue
			var next := nj * cols + ni
			if seen[next] == 1:
				continue
			if is_nan(height[next]) or is_nan(height[index]):
				continue
			if absf(height[next] - height[index]) > rise:
				continue
			seen[next] = 1
			queue.append(next)

	var reached := false
	for i in cols:
		if seen[i] == 1:
			reached = true
			break

	print("FLOOD FILL, %s: z %.0f (far bank) <- z %.0f (near bank), %d x %d cells at %.1f m" % [
		who, min_z, max_z, cols, rows, CELL])
	if not reached:
		print("  BLOCKED. No connected route from the near bank to the far bank")
		print("  anywhere across the corridor's full %.0f m width." % (max_x - min_x))
		return
	print("  REACHABLE. The far bank is connected to the near bank somewhere.")
	print("  Where, from the windowed scan below -- NOT from this fill: once a")
	print("  single leak exists the flood spreads along the whole far bank, so a")
	print("  per-column read of THIS fill reports the entire corridor as crossed")
	print("  and means only 'the far bank is one connected surface'. The first")
	print("  run of this probe reported 2,047 of 2,049 columns on exactly that")
	print("  artifact, next to cross-sections measuring 69-80 degree walls.")


## Where the barrier is actually passable. Slide a window along x and run the
## same fill CONFINED to it: a route that leaves the window does not count, so
## a single hole at one end can no longer make the whole length read as open.
## That confinement is the entire point -- it is the difference between "the far
## bank is reachable" (which one leak anywhere satisfies) and "the barrier fails
## here", which is the answer somebody fixing it needs.
##
## The window is wider than the barrier is thick so a legitimately meandering
## route still fits inside one, and the stride is half the window so a crossing
## on a window seam is caught by its neighbour.
func _scan_windows(min_x: float, max_x: float, min_z: float, max_z: float,
		limit_deg: float, who: String) -> void:
	var open_cols: Array[int] = []
	var window := WINDOW_WIDTH
	var stride := WINDOW_WIDTH * 0.5
	var left := min_x
	while left < max_x:
		var right := minf(left + window, max_x)
		if _connects(left, right, min_z, max_z, limit_deg):
			var from := int((left - min_x) / CELL)
			var to := int((right - min_x) / CELL)
			for i in range(from, to + 1):
				if not open_cols.has(i):
					open_cols.append(i)
		left += stride
	open_cols.sort()

	print("WINDOWED SCAN, %s: %.0f m windows, %.0f m stride" % [who, window, stride])
	if open_cols.is_empty():
		print("  SEALED. No %.0f m window anywhere across the barrier's full" % window)
		print("  %.0f m span lets a route from one bank reach the other." % (max_x - min_x))
		return
	var runs := _runs(open_cols, min_x)
	print("  PASSABLE in %d stretch(es), %.0f m of the %.0f m span:" % [
		runs.size(), float(open_cols.size()) * CELL, max_x - min_x])
	for run: String in runs:
		print("    " + run)


## One confined fill. Returns whether the far edge is reached using only cells
## inside [left, right].
func _connects(left: float, right: float, min_z: float, max_z: float,
		limit_deg: float) -> bool:
	var cols := int((right - left) / CELL) + 1
	var rows := int((max_z - min_z) / CELL) + 1
	var rise := tan(deg_to_rad(limit_deg)) * CELL
	var height := PackedFloat32Array()
	height.resize(cols * rows)
	for j in rows:
		var z := min_z + float(j) * CELL
		for i in cols:
			height[j * cols + i] = _baked(Vector2(left + float(i) * CELL, z))
	var seen := PackedByteArray()
	seen.resize(cols * rows)
	var queue := PackedInt32Array()
	for i in cols:
		var index := (rows - 1) * cols + i
		if is_nan(height[index]):
			continue
		seen[index] = 1
		queue.append(index)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var i := index % cols
		var j := index / cols
		if j == 0:
			return true
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ni := i + step.x
			var nj := j + step.y
			if ni < 0 or ni >= cols or nj < 0 or nj >= rows:
				continue
			var next := nj * cols + ni
			if seen[next] == 1:
				continue
			if is_nan(height[next]) or is_nan(height[index]):
				continue
			if absf(height[next] - height[index]) > rise:
				continue
			seen[next] = 1
			queue.append(next)
	return false


## Contiguous column indices collapsed into "x A..B (N m wide)" so a 200-cell
## leak prints as one line instead of two hundred.
func _runs(columns: Array[int], min_x: float) -> Array[String]:
	var out: Array[String] = []
	var start := columns[0]
	var previous := columns[0]
	for k in range(1, columns.size()):
		if columns[k] != previous + 1:
			out.append("x %.0f .. %.0f (%.0f m wide)" % [
				min_x + float(start) * CELL, min_x + float(previous) * CELL,
				float(previous - start + 1) * CELL])
			start = columns[k]
		previous = columns[k]
	out.append("x %.0f .. %.0f (%.0f m wide)" % [
		min_x + float(start) * CELL, min_x + float(previous) * CELL,
		float(previous - start + 1) * CELL])
	return out


func _load_config() -> Dictionary:
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
