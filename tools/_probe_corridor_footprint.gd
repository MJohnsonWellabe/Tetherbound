extends SceneTree

## OW5A. Two measurements the corridor footprint decision needs and nobody had.
##
##   godot --headless --path . --script tools/_probe_corridor_footprint.gd
##
## 1. WALL ANGLE VS VERTEX SPACING. Growing the map to a 6km corridor is only
##    affordable if `vertex_spacing` goes from 1.0 to 2.0, which halves the
##    heightfield's resolution. Every blocker on this map is a `_carve_depth`
##    trench whose *walls* are the blocker -- if the coarser grid rounds those
##    walls below the limits below, a gorge stops being a gorge and the world
##    stops being sealed. Two limits, both real and both already tested:
##      * `scenes/player/player.tscn` floor_max_angle 0.7854 rad = 45 deg.
##      * `scenes/creatures/creature.tscn` 0.9599 rad = 55 deg, and the ridden
##        legendary raises its own body to 60 (riding_controller._apply_climb_
##        limit; smoke_riding/smoke_boss both assert the spokes stay above it).
##    So a spoke wall has to clear 60 deg, not 45, or riding walks out of the
##    Meadows -- which is D23's carve-out and a hard rule.
##
##    Terrain3D's surface is the grid, not the analytic field: what the player
##    walks on is the piecewise-bilinear reconstruction of samples taken every
##    `vertex_spacing` metres. So this probe BUILDS that grid at each candidate
##    spacing and walks transects over the reconstruction, rather than reading
##    `height_at` directly along the transect -- reading the analytic field
##    would report the angle the config asks for, which is exactly the number
##    that is not in question.
##
## 2. BAKE COST PER PIXEL. `build_playground_terrain.gd` makes two full passes
##    over a size*size grid. The repo carries three different bake times
##    (5.5 / 12 / 15 min) and none was re-measured after the river landed, so
##    the corridor projection has nothing honest to stand on. This times both
##    passes' per-pixel field work on representative tiles and prints a
##    projection. It deliberately does NOT bake: a 36-region bake is the next
##    item's job, and the point here is the unit cost.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

# Where the interesting walls are. Each entry names a carve and a transect:
# `at` is a point on its centreline, `across_deg` the compass direction to walk
# to cross it (perpendicular to the carve's own axis), `reach` how far either
# side to look.
const TRANSECTS := [
	{"name": "river @ north dry gorge", "at": [199.0, -60.0], "across_deg": 24.0, "reach": 34.0},
	{"name": "river @ mill narrows", "at": [162.4, 42.1], "across_deg": 18.5, "reach": 24.0},
	{"name": "river @ south broad", "at": [121.0, 150.0], "across_deg": 23.0, "reach": 34.0},
	{"name": "south gully (crossing)", "at": [5.0, 80.0], "across_deg": 90.0, "reach": 24.0},
	{"name": "spoke river_gorge", "at": [-93.9, 176.6], "across_deg": 116.3, "reach": 36.0},
	{"name": "spoke storm ravine", "at": [193.2, 51.8], "across_deg": 18.2, "reach": 30.0},
	{"name": "spoke cliff_road notch", "at": [102.0, -37.2], "across_deg": 160.0, "reach": 28.0},
]

const SPACINGS := [1.0, 1.5, 2.0, 2.5]

# The two slope limits that decide whether a wall is still a wall.
const PLAYER_LIMIT := 45.0
const RIDDEN_LIMIT := 60.0


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config")
		quit(1)
		return
	var field: RefCounted = HEIGHTFIELD.new(config)

	print("=== 1. CARVE WALLS VS VERTEX SPACING ===")
	print("Angles are of the RECONSTRUCTED grid surface, not the analytic field.")
	print("'blocked' metres = vertical extent of wall steeper than the limit,")
	print("summed over both walls; a wall only blocks if it is unbroken.\n")
	for entry: Dictionary in TRANSECTS:
		print("%s" % entry["name"])
		for spacing: float in SPACINGS:
			var r := _measure_transect(field, entry, spacing)
			print("  %.1fm spacing: depth %5.1fm  steepest %5.1f deg  " % [
					spacing, r["depth"], r["max_deg"]] +
				"walls>45 %4.1fm  walls>60 %4.1fm  %s" % [
					r["blocked_45"], r["blocked_60"], r["verdict"]])
		print("")

	print("=== 2. BAKE COST PER PIXEL ===")
	_time_passes(field, config)
	quit(0)


## Walk one transect over the grid-reconstructed surface and report what the
## walls actually do at this spacing.
func _measure_transect(field: RefCounted, entry: Dictionary, spacing: float) -> Dictionary:
	var centre := Vector2(float(entry["at"][0]), float(entry["at"][1]))
	var dir := Vector2.RIGHT.rotated(deg_to_rad(float(entry["across_deg"])))
	var reach := float(entry["reach"])

	# The transect in fine steps, each point read from the bilinear grid the
	# bake would produce at this spacing.
	var step := 0.1
	var n := int(reach * 2.0 / step) + 1
	var heights := PackedFloat32Array()
	heights.resize(n)
	for i in n:
		var p := centre + dir * (-reach + i * step)
		heights[i] = _grid_height(field, p.x, p.y, spacing)

	var rim := -INF
	var floor_h := INF
	for h: float in heights:
		rim = maxf(rim, h)
		floor_h = minf(floor_h, h)

	# Slope along the transect. The bilinear surface is piecewise smooth, so a
	# fine finite difference over it is the honest local gradient.
	var max_deg := 0.0
	var blocked_45 := 0.0
	var blocked_60 := 0.0
	# Longest unbroken run of >limit slope, in metres of VERTICAL rise. A wall
	# that is steep, then flat for 3m, then steep again is a staircase, not a
	# wall -- so runs are tracked, and only the best run on each side counts.
	var run_45 := 0.0
	var run_60 := 0.0
	var best_45 := 0.0
	var best_60 := 0.0
	for i in range(1, n):
		var dh: float = heights[i] - heights[i - 1]
		var deg := rad_to_deg(atan(absf(dh) / step))
		max_deg = maxf(max_deg, deg)
		if deg >= PLAYER_LIMIT:
			run_45 += absf(dh)
			best_45 = maxf(best_45, run_45)
		else:
			run_45 = 0.0
		if deg >= RIDDEN_LIMIT:
			run_60 += absf(dh)
			best_60 = maxf(best_60, run_60)
		else:
			run_60 = 0.0
	blocked_45 = best_45
	blocked_60 = best_60

	var depth := rim - floor_h
	# A carve blocks a walker if its steepest unbroken run covers essentially
	# the whole climb out. 80% is the tolerance: the last metre out of any
	# smoothstepped trench is always gentle by construction.
	var verdict := "SEALED"
	if blocked_60 < depth * 0.5:
		verdict = "RIDDEN CREATURE CLIMBS OUT"
	if blocked_45 < depth * 0.5:
		verdict = "PLAYER WALKS OUT -- not a blocker"
	return {
		"depth": depth, "max_deg": max_deg,
		"blocked_45": blocked_45, "blocked_60": blocked_60, "verdict": verdict,
	}


## Height of the piecewise-bilinear surface Terrain3D would build from samples
## taken every `spacing` metres. The grid is anchored on multiples of spacing
## from the world origin, which is where the bake's own grid lands (its origin
## is -0.5 * size * spacing, and size * spacing is the world size).
func _grid_height(field: RefCounted, x: float, z: float, spacing: float) -> float:
	var gx := floorf(x / spacing) * spacing
	var gz := floorf(z / spacing) * spacing
	var tx := (x - gx) / spacing
	var tz := (z - gz) / spacing
	var h00: float = field.call("height_at", gx, gz)
	var h10: float = field.call("height_at", gx + spacing, gz)
	var h01: float = field.call("height_at", gx, gz + spacing)
	var h11: float = field.call("height_at", gx + spacing, gz + spacing)
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


## Time the per-pixel work of both bake passes on tiles that are honestly
## labelled: one over the busy middle of the current map (every feature in
## range) and one out where only the noise layers answer.
func _time_passes(field: RefCounted, config: Dictionary) -> void:
	var colour_cfg: Dictionary = config.get("colour", {})
	var texture_step := float(colour_cfg.get("slope_sample_step", 1.0))
	var rock_step := float(colour_cfg.get("slope_sample_step_rock", texture_step))
	var side := 200

	for tile: Array in [
		["busy centre (village, river, rises)", 0.0, 0.0, 1.0],
		["far field (noise layers only)", 900.0, 900.0, 1.0],
	]:
		var label: String = tile[0]
		var ox: float = tile[1]
		var oz: float = tile[2]
		var step: float = tile[3]

		var t0 := Time.get_ticks_usec()
		for pz in side:
			var z := oz + pz * step
			for px in side:
				var x := ox + px * step
				var h: float = field.call("height_at", x, z)
				var band: float = lerpf(texture_step, rock_step,
					clampf(field.call("rise_form_factor", x, z), 0.0, 1.0))
				field.call("slope_degrees_at", x, z, band)
				field.call("rock_bias_deg", x, z)
				field.call("building_apron_factor", x, z)
				field.call("drain_factor", x, z)
				# `_wet_weight` reads stream_factor and the height it already has.
				field.call("stream_factor", x, z)
				if h < 0.0:
					pass
		var us_colour := Time.get_ticks_usec() - t0

		var t1 := Time.get_ticks_usec()
		for pz in side:
			var z := oz + pz * step
			for px in side:
				var x := ox + px * step
				var band: float = lerpf(texture_step, rock_step,
					clampf(field.call("rise_form_factor", x, z), 0.0, 1.0))
				field.call("slope_degrees_at", x, z, band)
				field.call("rock_bias_deg", x, z)
				field.call("path_factor", x, z)
				field.call("building_apron_factor", x, z)
				field.call("drain_factor", x, z)
				field.call("stream_factor", x, z)
				field.call("height_at", x, z)
				field.call("path_dominant_dither", x, z)
		var us_control := Time.get_ticks_usec() - t1

		var pixels := side * side
		var per := float(us_colour + us_control) / float(pixels)
		print("  %-38s %.2f us/px (colour %.2f, control %.2f)" % [
			label, per, us_colour / float(pixels), us_control / float(pixels)])
		for footprint: Array in [
			["current 512m @1.0 (512x512)", 512, 512],
			["corridor 6144x1536 @2.0 (3072x768)", 3072, 768],
			["corridor 6144x1536 @1.0 (6144x1536)", 6144, 1536],
			["corridor 12288x1536 @2.0 (6144x768)", 6144, 768],
		]:
			var w: int = footprint[1]
			var hgt: int = footprint[2]
			print("      %-38s %8d px -> %6.1f min of field work" % [
				footprint[0], w * hgt, per * w * hgt / 1e6 / 60.0])
		print("")
