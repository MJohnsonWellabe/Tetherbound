extends SceneTree

## WHERE THE DASHED SEAM LINES COME FROM. Headless, no renderer, seconds to run.
##
##   godot --headless --path . --script tools/_probe_ground_seams.gd
##
## Two blind visual passes and two ground lanes have now reported "faint
## dotted/dashed lines cross the terrain... visible enough for a player to
## steer by" (JUDGE-VISUAL-2026-08-29 subject 5) without isolating a cause.
## T1-GROUND left two hypotheses open and T1-GROUND-2 did not reattempt them.
## Both proposed instrument was a debug-overlay RENDER, which on this container
## costs 10-30 minutes per round. Every hypothesis worth testing here is
## arithmetic over the analytic heightfield and the config, so this tests them
## without drawing anything.
##
## H1 -- THE sin() PSEUDO-HASH.
## build_playground_terrain.gd dithers five threshold decisions with
## `absf(fmod(sin(px*12.9898 + pz*78.233) * 43758.5453, 1.0))`, the classic
## GLSL sin-dot hash, which is known to alias into visible periodic banding in
## float32. T1-GROUND flagged it and could not confirm it. Measured here as a
## distribution and an autocorrelation, which is what "does it alias" actually
## means.
##
## H2 -- FAR COVER POKE-THROUGH.
## grass_field.json's `far_cover` is one terrain-following sheet on a FIXED,
## WORLD-AXIS-ALIGNED grid (`far_cell`, 6m), whose vertices the vertex shader
## lifts to the sampled terrain height plus `lift` (0.35m). Between vertices
## the sheet is a flat triangle while the ground under it curves, so anywhere
## the terrain is locally convex by more than `lift` across one cell, the
## ground pokes through the wash. Those breaches sit on a fixed 6m world
## lattice, so at a grazing angle they line up into rows -- regularly spaced
## dark marks along world X and Z, converging in perspective. That is the
## artefact's exact description.
##
## H2 is NOT covered by the ruling-out already on record. GRASS_HANDOVER_
## 2026-08-26 reports hiding "the field's own MultiMeshes" and seeing the lines
## unchanged, and T1-GROUND repeated that as the reason the grass field is
## ruled out. The far cover is NOT a MultiMesh -- `_build_far_cover` adds a
## single MeshInstance3D child (`FarCover`) -- so that check could not have
## hidden it.
##
## `lift` itself is the tunable this reports against: the probe prints the
## smallest lift that would clear the terrain everywhere it sampled, which is
## the number to set if H2 confirms.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

## Sub-samples per cell edge when hunting a cell's worst breach. 7 puts a
## sample every ~0.85m across a 6m cell -- fine enough to catch a bulge the
## width of the dashes, coarse enough to keep the whole sweep under a minute.
const SUB := 7

## Where to sample. The band viewpoints `_capture_ground_and_sky.gd` shoots
## from, so a confirmation here is about the ground the judged frames show
## rather than about the world in general. Radius is the far cover's own
## visible band -- past `fade_in_start` (52m), inside `fade_out_start` (320m).
const SITES := [
	["band1-opening", Vector2(8.0, 90.0)],
	["band2-stone-root", Vector2(310.0, 1660.0)],
	["band3-crossing", Vector2(-40.0, 3980.0)],
	["band4-ironwood", Vector2(170.0, 5590.0)],
	["band5-approach", Vector2(120.0, 7180.0)],
]
const SAMPLE_RADIUS := 240.0


func _init() -> void:
	_h1_sin_hash()
	print("")
	_h2_far_cover()
	quit(0)


## Distribution and autocorrelation of the sin-dot hash over one region's worth
## of pixel indices -- the exact integer domain `_paint_control_map` feeds it
## (`pixel_x`/`pixel_z` are region-LOCAL loop indices, 0..region_size-1, which
## is itself worth stating: the pattern repeats identically in every region).
##
## An aliasing hash shows up as autocorrelation at some lag: that is what a
## periodic ripple IS. A hash whose worst lag correlation is at the noise floor
## cannot be drawing a line, whatever its reputation.
func _h1_sin_hash() -> void:
	print("H1  sin-dot hash, absf(fmod(sin(px*12.9898 + pz*78.233)*43758.5453, 1.0))")
	var n := 256
	var total := 0.0
	var total_sq := 0.0
	for px in n:
		for pz in n:
			var v := _sin_hash(px, pz)
			total += v
			total_sq += v * v
	var count := float(n * n)
	var mean := total / count
	var sd := sqrt(maxf(total_sq / count - mean * mean, 0.0))
	print("    distribution: mean %.4f (ideal 0.5000)  sd %.4f (ideal 0.2887)" % [mean, sd])

	var worst_lag := 0
	var worst_r := 0.0
	for axis in 2:
		for lag in range(1, 40):
			var r := _autocorr(n, axis, lag)
			if absf(r) > absf(worst_r):
				worst_r = r
				worst_lag = lag * (1 if axis == 0 else -1)
	print("    worst autocorrelation over lags 1..39, both axes: r = %+.4f at lag %d" % [
		worst_r, absf(worst_lag)])
	if absf(worst_r) < 0.05:
		print("    VERDICT: NOT ALIASING. White to within the noise floor of a %d-sample row." % n)
		print("    H1 is ruled out -- this hash is not drawing the dashes.")
	else:
		print("    VERDICT: ALIASES. A periodic ripple at that lag is a dashed contour.")


func _sin_hash(px: int, pz: int) -> float:
	return absf(fmod(sin(float(px) * 12.9898 + float(pz) * 78.233) * 43758.5453, 1.0))


## Mean over all rows of the lag-`lag` autocorrelation along `axis`.
func _autocorr(n: int, axis: int, lag: int) -> float:
	var acc := 0.0
	for fixed in n:
		var mean := 0.0
		var row := PackedFloat32Array()
		row.resize(n)
		for i in n:
			var v := _sin_hash(i, fixed) if axis == 0 else _sin_hash(fixed, i)
			row[i] = v
			mean += v
		mean /= float(n)
		var cov := 0.0
		var var_ := 0.0
		for i in n:
			var_ += (row[i] - mean) * (row[i] - mean)
		for i in n - lag:
			cov += (row[i] - mean) * (row[i + lag] - mean)
		if var_ > 0.0:
			acc += (cov / float(n - lag)) / (var_ / float(n))
	return acc / float(n)


## Does the terrain break through the far-cover sheet, and on what pitch?
##
## Rebuilds the sheet's own geometry exactly as `grass_field.gd` does: cell
## from `far_lattice_cell` (a whole multiple of `snap`), vertices on the world
## lattice at terrain height plus `lift`, quads split into the same two
## triangles `_far_mesh` winds. A cell breaches when the real surface anywhere
## inside it stands above the triangle covering that point.
func _h2_far_cover() -> void:
	var cfg: Dictionary = _load_json("res://data/config/grass_field.json")
	var far_cfg: Dictionary = cfg.get("far_cover", {})
	print("H2  far cover sheet poke-through (grass_field.json far_cover)")
	if not bool(far_cfg.get("enabled", false)):
		print("    far cover is DISABLED in config -- H2 cannot be the cause. Nothing to test.")
		return
	var snap := float(cfg.get("snap", 2.0))
	var want := maxf(float(far_cfg.get("far_cell", 6.0)), snap)
	var cell := snap * maxf(round(want / snap), 1.0)
	var lift := float(far_cfg.get("lift", 0.35))
	print("    cell %.1fm on a fixed world lattice, lift %.2fm, visible %.0f-%.0fm from the eye" % [
		cell, lift, float(far_cfg.get("fade_in_start", 52.0)),
		float(far_cfg.get("fade_out_start", 320.0))])

	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())
	var worst_overall := 0.0
	var breached_total := 0
	var cells_total := 0
	for entry: Variant in SITES:
		var site: Array = entry
		var name: String = str(site[0])
		var eye: Vector2 = site[1]
		var stats := _breach_stats(field, eye, cell, lift)
		breached_total += int(stats["breached"])
		cells_total += int(stats["cells"])
		worst_overall = maxf(worst_overall, float(stats["worst"]))
		print("    %-18s %5d of %5d cells breached (%5.1f%%), worst excess %.2fm" % [
			name, int(stats["breached"]), int(stats["cells"]),
			100.0 * float(stats["breached"]) / maxf(float(stats["cells"]), 1.0),
			float(stats["worst"])])

	# The fix has two axes and they trade against each other, so choose from a
	# sweep rather than from the worst single number: a smaller `far_cell`
	# follows the ground more closely and costs triangles quadratically, while
	# a larger `lift` costs nothing but floats the wash off the ground at the
	# near hand-over. The worst excess is a cliff face nothing can follow, so
	# the number that matters is the percentage still breaching, not the max.
	print("")
	print("    fix sweep -- percentage of cells still breaching, all five sites:")
	print("      cell   lift=0.35  0.60  0.90  1.20   tris vs 6.0m")
	for try_cell: float in [6.0, 5.0, 4.0, 3.0]:
		var row := "      %4.1fm " % try_cell
		for try_lift: float in [0.35, 0.60, 0.90, 1.20]:
			var breach := 0
			var seen := 0
			for entry2: Variant in SITES:
				var site2: Array = entry2
				var st := _breach_stats(field, site2[1] as Vector2, try_cell, try_lift)
				breach += int(st["breached"])
				seen += int(st["cells"])
			row += "  %5.2f%%" % (100.0 * float(breach) / maxf(float(seen), 1.0))
		row += "    %.2fx" % ((6.0 / try_cell) * (6.0 / try_cell))
		print(row)

	# H3 -- THE PROPOSED FIX, measured before any shader is written.
	#
	# Neither sweep axis above is a good trade: a smaller cell buys the fix with
	# triangles on the tier whose GPU cost no container in this project can
	# measure (PERF-ROG-GPU), and a larger lift buys it by floating the wash off
	# the ground everywhere, including the 52-84m hand-over where the sheet is
	# closest to the eye and a parallax offset would show.
	#
	# The cause is narrower than either: the sheet is a chord between height
	# samples, and the ground bulges above the chord BETWEEN them. So lift each
	# vertex above its own neighbourhood's maximum instead of above its own
	# sample -- a morphological dilation of the height field at half a cell,
	# which is exactly the radius the chord spans. far_cover.gdshader's vertex()
	# already fetches four neighbours at +-far_cell for its normal, so this is
	# a handful more texture fetches PER VERTEX (never per fragment), no
	# triangles, and no global offset.
	#
	# `dilate_cap` bounds what the dilation may add, because an uncapped one at
	# a cliff would raise the sheet by the whole cliff and float it over the low
	# side. Cliff faces paint `rock`, which is in far_cover's own
	# `forbidden_ground`, so the wash is already masked off the worst of them.
	print("")
	print("    H3 fix -- lift each vertex above its own half-cell neighbourhood max:")
	print("      cell 6.0m, lift 0.35m, dilation radius half a cell")
	for cap: float in [0.0, 0.6, 1.0, 1.5, 99.0]:
		var breach := 0
		var seen := 0
		var floatmax := 0.0
		for entry3: Variant in SITES:
			var site3: Array = entry3
			var st2 := _dilated_breach_stats(field, site3[1] as Vector2, cell, lift, cap)
			breach += int(st2["breached"])
			seen += int(st2["cells"])
			floatmax = maxf(floatmax, float(st2["float_max"]))
		print("      dilate_cap %5.2fm -> %5.2f%% of cells still breach, wash floats at most %.2fm" % [
			cap, 100.0 * float(breach) / maxf(float(seen), 1.0), floatmax])
	print("      (dilate_cap 0.00m is today's behaviour, for comparison)")

	var pct := 100.0 * float(breached_total) / maxf(float(cells_total), 1.0)
	print("    ALL SITES: %d of %d cells breached (%.1f%%), worst excess %.2fm" % [
		breached_total, cells_total, pct, worst_overall])
	print("    a breach is a hole in the wash on a FIXED %.0fm world lattice; at a" % cell)
	print("    grazing angle those holes line up into rows along world X and Z.")
	if pct >= 1.0:
		print("    VERDICT: CONFIRMED as a real, lattice-aligned artefact source.")
		print("    Smallest lift that clears every sample here: %.2fm" % worst_overall)
	else:
		print("    VERDICT: negligible -- the sheet clears the ground almost everywhere.")


## Breach census over the disc of `SAMPLE_RADIUS` around `eye`.
func _breach_stats(field: RefCounted, eye: Vector2, cell: float, lift: float) -> Dictionary:
	# The sheet's lattice is anchored to the world, not to the eye -- that is
	# the whole point of `far_cell` dividing `snap` -- so quantise to it.
	var steps := int(ceil(SAMPLE_RADIUS / cell))
	var base_x: float = floor(eye.x / cell) * cell
	var base_z: float = floor(eye.y / cell) * cell
	var cells := 0
	var breached := 0
	var worst := 0.0
	for ix in range(-steps, steps):
		for iz in range(-steps, steps):
			var x0: float = base_x + float(ix) * cell
			var z0: float = base_z + float(iz) * cell
			var centre := Vector2(x0 + cell * 0.5, z0 + cell * 0.5)
			if centre.distance_to(eye) > SAMPLE_RADIUS:
				continue
			cells += 1
			# The four corner heights the vertex shader would lift.
			var h00: float = field.height_at(x0, z0)
			var h10: float = field.height_at(x0 + cell, z0)
			var h01: float = field.height_at(x0, z0 + cell)
			var h11: float = field.height_at(x0 + cell, z0 + cell)
			var excess := 0.0
			for su in SUB + 1:
				for sv in SUB + 1:
					var u := float(su) / float(SUB)
					var v := float(sv) / float(SUB)
					# _far_mesh winds (a,c,b) and (b,c,e): the diagonal runs
					# from the (u=1,v=0) corner to the (u=0,v=1) corner, so the
					# plane a point sits under depends on which side of u+v=1
					# it falls. Interpolating the quad bilinearly instead would
					# understate the breach on a saddle.
					var sheet: float
					if u + v <= 1.0:
						sheet = h00 + (h10 - h00) * u + (h01 - h00) * v
					else:
						sheet = h11 + (h01 - h11) * (1.0 - u) + (h10 - h11) * (1.0 - v)
					var here: float = field.height_at(x0 + u * cell, z0 + v * cell)
					excess = maxf(excess, here - (sheet + lift))
			if excess > 0.0:
				breached += 1
				worst = maxf(worst, excess + lift)
	return {"cells": cells, "breached": breached, "worst": worst}


func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


## The same census as `_breach_stats`, but with each corner vertex raised to its
## own half-cell neighbourhood maximum (capped by `cap`) before the chord is
## drawn -- i.e. what the sheet would do with the H3 shader change in it. Also
## reports how far the wash ends up floating above the real ground, which is
## the cost this fix pays and the number that decides `cap`.
func _dilated_breach_stats(
	field: RefCounted, eye: Vector2, cell: float, lift: float, cap: float
) -> Dictionary:
	var steps := int(ceil(SAMPLE_RADIUS / cell))
	var base_x: float = floor(eye.x / cell) * cell
	var base_z: float = floor(eye.y / cell) * cell
	var cells := 0
	var breached := 0
	var float_max := 0.0
	for ix in range(-steps, steps):
		for iz in range(-steps, steps):
			var x0: float = base_x + float(ix) * cell
			var z0: float = base_z + float(iz) * cell
			var centre := Vector2(x0 + cell * 0.5, z0 + cell * 0.5)
			if centre.distance_to(eye) > SAMPLE_RADIUS:
				continue
			cells += 1
			var h00 := _dilated(field, x0, z0, cell, cap)
			var h10 := _dilated(field, x0 + cell, z0, cell, cap)
			var h01 := _dilated(field, x0, z0 + cell, cell, cap)
			var h11 := _dilated(field, x0 + cell, z0 + cell, cell, cap)
			var excess := 0.0
			for su in SUB + 1:
				for sv in SUB + 1:
					var u := float(su) / float(SUB)
					var v := float(sv) / float(SUB)
					var sheet: float
					if u + v <= 1.0:
						sheet = h00 + (h10 - h00) * u + (h01 - h00) * v
					else:
						sheet = h11 + (h01 - h11) * (1.0 - u) + (h10 - h11) * (1.0 - v)
					var here: float = field.height_at(x0 + u * cell, z0 + v * cell)
					excess = maxf(excess, here - (sheet + lift))
					float_max = maxf(float_max, (sheet + lift) - here)
			if excess > 0.0:
				breached += 1
	return {"cells": cells, "breached": breached, "float_max": float_max}


## A vertex height dilated over its own half-cell neighbourhood: the eight
## half-cell offsets far_cover.gdshader can reach with the same kind of fetch it
## already does for its normal, capped so a cliff cannot lift the whole cell.
func _dilated(field: RefCounted, x: float, z: float, cell: float, cap: float) -> float:
	var here: float = field.height_at(x, z)
	if cap <= 0.0:
		return here
	var r := cell * 0.5
	var top := here
	for offset: Vector2 in [
		Vector2(r, 0.0), Vector2(-r, 0.0), Vector2(0.0, r), Vector2(0.0, -r),
		Vector2(r, r), Vector2(r, -r), Vector2(-r, r), Vector2(-r, -r),
	]:
		var sample: float = field.height_at(x + offset.x, z + offset.y)
		top = maxf(top, sample)
	return here + minf(top - here, cap)
