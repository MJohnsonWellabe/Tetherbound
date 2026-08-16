extends SceneTree

## OW5A. Two measurements the corridor footprint decision needs and nobody had.
##
##   godot --headless --path . --script tools/_probe_corridor_footprint.gd
##
## CORRECTIONS, 2026-08-16 (OW5A revision 2). A blind review found two errors in
## this header and in how docs/MEADOWS_MACRO_LAYOUT.md read the output. Both are
## corrected in place below rather than deleted, because the wrong versions were
## quoted into three documents and the next reader needs to see which is which.
##
##   (A) `max_deg` IS THE WRONG STATISTIC and must not be the headline. It is
##       the single steepest 0.1m finite difference on a 48-68m transect.
##       Whether a body climbs out is decided by the SHALLOWEST SUSTAINED LINE,
##       and a smoothstepped wall's peak gradient exceeds its mean by 1.5x by
##       construction. `blocked_60` below -- the longest UNBROKEN run of >=60
##       degree slope -- is the right proxy and this probe already computes it.
##       Report blocked_60 against depth. The repo's own recorded figures agree
##       with the mean and not the peak: severed_spokes.gd:24 says 57-66 deg,
##       smoke_riding.gd:163 pins SHALLOWEST_SPOKE_WALL_DEG := 65.0, and
##       ralph/DONE.md:16 records storm_road at 65.6. atan(depth/rim) for
##       storm_road's 11m over a 5m rim is exactly 65.6. THE REAL MARGIN OVER
##       THE RIDDEN 60 IS ~5 DEGREES, NOT ~15.
##
##   (B) THERE IS NO "12 MINUTE" BAKE FIGURE IN THIS REPO. Section 2's header
##       below claimed three recorded times and the layout document then said
##       this probe's 11.3 min "confirms the 12". Grepped: the only recorded
##       bake times are ralph/DONE.md:2752 (~5.5 min) and D45 /
##       meadow_healing.gd (~15 min). They differ by 2.7x, neither matches 11.3,
##       and both are whole-bake wall-clock against this probe's field-work-only
##       figure. The unit cost is MEASURED but UNVALIDATED. Say so.
##
##   (C) Section 2's two-tile design cannot detect content scaling, so do not
##       conclude "cost scales with pixel count and nothing else" from it.
##       `path_factor` calls `road_polylines()`, which rebuilds the whole road
##       set from JSON on EVERY call with no cache and no distance rejection --
##       so the "far field" tile at (900,900) pays the identical 47-segment scan
##       the busy tile does. To measure content scaling, vary the road count in
##       the config with the tile held fixed, or add a roads-removed tile.
##
## 1. WALL ANGLE VS VERTEX SPACING. Growing the map to an 8km corridor is only
##    affordable if `vertex_spacing` goes from 1.0 to 2.0, which halves the
##    heightfield's resolution. FIVE blockers on this map are `_carve_depth`
##    trenches whose *walls* are the blocker -- three spokes (river_gorge,
##    storm_road, cliff_road), the south_bridge gully and the river's own
##    course. The other four spokes are rockslides, a sealed gate and a sealed
##    road: props and collision, indifferent to vertex_spacing. (The original
##    header said "every blocker on this map is a carve", which is false.)
##    If the coarser grid rounds the five carves' walls below the limits below,
##    a gorge stops being a gorge and the world stops being sealed. Two limits,
##    both real and both already tested:
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
##    over a size*size grid. The repo carries two conflicting bake times (5.5
##    min in ralph/DONE.md:2752, ~15 min in D45 / meadow_healing.gd) and neither
##    was re-measured after the river landed, so the corridor projection has
##    nothing honest to stand on. This times both passes' per-pixel field work
##    on representative tiles and prints a projection. It deliberately does NOT
##    bake: a 64-region bake is the next item's job, and the point here is the
##    unit cost. See correction (B) and (C) above before quoting any of it --
##    the unit cost has no anchor and the two tiles do not differ in content.

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
	print("summed over both walls; a wall only blocks if it is unbroken.")
	print("READ 'walls>60' AGAINST 'depth', NOT 'steepest'. 'steepest' is the")
	print("single worst 0.1m difference and overstates the margin by ~1.5x;")
	print("see correction (A) in this file's header. The mean wall angle the")
	print("repo asserts elsewhere is atan(depth/rim) and runs 65.6-66.4 deg.\n")
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
		# Footprints are REGION-ALIGNED: at region_size 256 and vertex_spacing
		# 2.0 the region pitch is 512m, so both world bounds must be multiples
		# of 512. A 1536m width centred on the origin runs -768..+768 and is
		# NOT aligned -- that error is why OW5A needed a second revision, and
		# the unaligned candidates are deliberately absent from this list.
		for footprint: Array in [
			["current 512m @1.0 (512x512)", 512, 512],
			["corridor 6144x2048 @2.0 (3072x1024)", 3072, 1024],
			["corridor 8192x1024 @2.0 (4096x512)", 4096, 512],
			["CHOSEN 8192x2048 @2.0 (4096x1024)", 4096, 1024],
			["corridor 8192x2048 @1.0 (8192x2048)", 8192, 2048],
		]:
			var w: int = footprint[1]
			var hgt: int = footprint[2]
			print("      %-38s %8d px -> %6.1f min of field work" % [
				footprint[0], w * hgt, per * w * hgt / 1e6 / 60.0])
		print("")
