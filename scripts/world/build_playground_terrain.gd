extends SceneTree

## Bakes the M1 movement playground into Terrain3D region data.
##
##   godot --headless --path . --script scripts/world/build_playground_terrain.gd
##
## Run once; the output is committed as data. Nothing generates terrain at
## runtime. Re-run after editing data/config/terrain_playground.json.
##
## This exists because Terrain3D is normally sculpted by hand in the editor, and
## the development environment for this project is headless. Generating the
## heightfield from a seeded recipe is also reproducible, which hand-sculpting
## is not — the same config always bakes the same playground.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")
const TERRAIN_BAKE := preload("res://scripts/world/terrain_bake.gd")
const DATA_DIR := "res://data/terrain/playground"

# Terrain3DData.MapType. The enum is not reachable through ClassDB on this
# build, so the values are named here rather than left as bare indices.
const MAP_HEIGHT := 0
const MAP_CONTROL := 1
const MAP_COLOR := 2


func _init() -> void:
	# Terrain3D builds its Terrain3DData on the node's first frame, not on
	# add_child, so the body has to be able to await. A SceneTree's _init cannot
	# be a coroutine; this can.
	_run()


## Region-set support. Every per-pixel function this bake calls (`height_at`,
## `slope_degrees_at`, `rock_bias_deg`, `building_apron_factor`,
## `drain_factor`, ...) is a pure function of `(config, world_x, world_z)` and
## nothing else -- no pixel reads a neighbour, there is no blur/erosion/flow
## pass, and nothing needs the whole map resident. That means a sub-rectangle
## can be baked in complete isolation and must come out byte-for-byte
## identical to what a full bake would have written there: two regions baked
## independently agree exactly at the boundary because both evaluate the same
## continuous function at the same coordinates
## (`tools/verify_incremental_bake_identity.sh` is the test that this holds,
## not just an assertion that it should).
##
## So a "full bake" is not a separate code path from a partial one -- it is
## the SAME per-region bake, called once per region in the world's bounds
## instead of once for a caller-supplied subset. `_requested_region_locations`
## below is the only place that distinction lives.
##
## Region set on the command line: `-- --regions=col:row,col:row,...` (region
## LOCATIONS, Terrain3D's own convention -- a region's world origin is
## `location * region_size * vertex_spacing`, see terrain_region_alignment.gd).
## Absent or empty: every region in the configured world bounds, i.e. a full
## bake. Dirty-region detection from a config diff is deliberately NOT built
## here -- that is a further, separate decision and guessing at it now would
## produce something wrong; this only takes an explicit set.
func _requested_region_locations(bounds: Dictionary, region_size: int, spacing: float) -> Array[Vector2i]:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--regions="):
			var raw := arg.substr("--regions=".length())
			var out: Array[Vector2i] = []
			for pair: String in raw.split(",", false):
				var parts := pair.split(":")
				if parts.size() != 2:
					push_error("--regions entry %s is not COL:ROW" % pair)
					return []
				out.append(Vector2i(int(parts[0]), int(parts[1])))
			return out
	return ALIGNMENT.region_locations(bounds, region_size, spacing)


func _run() -> void:
	var config := HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config; nothing baked")
		quit(1)
		return

	var field: RefCounted = HEIGHTFIELD.new(config)
	var region_size := int(config.get("region_size", 256))
	var spacing := float(config.get("vertex_spacing", 1.0))

	# §1.3(a)/(b): a region's origin is region_location * region_size *
	# vertex_spacing, so the lattice pitch is that product in METRES and both
	# bounds of every axis must land on it -- extent alone (the old
	# `world_size % region_size` check) is not enough. See
	# terrain_region_alignment.gd for why.
	var bounds := ALIGNMENT.world_bounds(config)
	var alignment_error := ALIGNMENT.check_alignment(bounds, region_size, spacing)
	if not alignment_error.is_empty():
		push_error(alignment_error)
		quit(1)
		return

	var region_counts := ALIGNMENT.region_counts(bounds, region_size, spacing)
	var locations := _requested_region_locations(bounds, region_size, spacing)
	if locations.is_empty():
		push_error("no regions requested; nothing baked")
		quit(1)
		return

	var full_bake := locations.size() == region_counts.x * region_counts.y
	print("baking x[%.1f, %.1f] z[%.1f, %.1f], %d of %d regions (%dx%d full-world grid) at %.2fm spacing, %d of %d" %
		[bounds["min_x"], bounds["max_x"], bounds["min_z"], bounds["max_z"],
		locations.size(), region_counts.x * region_counts.y, region_counts.x, region_counts.y,
		spacing, region_size, region_size])
	if not full_bake:
		print("  PARTIAL bake -- %d region(s): %s" % [locations.size(), str(locations)])

	# Overridable ONLY for the bit-identity test
	# (`tools/verify_incremental_bake_identity.sh`), which has to write
	# two independent runs of THIS SAME script to two scratch directories
	# without touching the real shipped `data/terrain/playground`. Absent:
	# the real, committed output path, exactly as before this file took a
	# region set at all.
	var data_dir := DATA_DIR
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--data-dir="):
			data_dir = arg.substr("--data-dir=".length())

	var colour_cfg: Dictionary = config.get("colour", {})
	# EV4-hillside-seam: texture-band decisions are deliberately sampled at a
	# WIDER step than the geometry (see terrain_playground.json's own comment)
	# so the fine `detail` noise layer doesn't flicker the grass/soil/rock pick
	# pixel to pixel. Height itself still bakes at `spacing`.
	var texture_step := float(colour_cfg.get("slope_sample_step", spacing))
	# Round 4 (OF11): on the rises, sample it FINE instead. See
	# playground_heightfield.gd::rise_form_factor for the whole argument — in
	# short, the coarse step exists to low-pass the `detail` noise out on the
	# meadow, and on a rise it low-passes away the rock form itself.
	var rock_step := float(colour_cfg.get("slope_sample_step_rock", texture_step))

	var terrain: Node = ClassDB.instantiate("Terrain3D")
	terrain.set("region_size", region_size)
	terrain.set("vertex_spacing", spacing)
	terrain.set("data_directory", data_dir)
	root.add_child(terrain)
	await process_frame

	var data: Object = terrain.get("data")
	if data == null:
		push_error("Terrain3D exposed no data object even after a frame")
		quit(1)
		return

	# Whole-run stats ACCUMULATE across regions rather than being computed
	# per-region: one summary line at the end, matching what a full bake
	# printed before this was split into a region loop, regardless of whether
	# this run covers 1 region or all 64.
	var lowest := INF
	var highest := -INF
	var steep_samples := 0
	var total_pixels := 0

	for location: Vector2i in locations:
		var rect := ALIGNMENT.region_world_rect(location, region_size, spacing)
		var stats: Dictionary = await _bake_region(field, config, colour_cfg, texture_step, rock_step, spacing, rect, data)
		lowest = minf(lowest, stats["lowest"])
		highest = maxf(highest, stats["highest"])
		steep_samples += int(stats["steep_samples"])
		total_pixels += int(stats["pixel_count"])
		print("  region %s x[%.1f,%.1f] z[%.1f,%.1f] baked" % [
			str(location), rect["min_x"], rect["max_x"], rect["min_z"], rect["max_z"]])

	print("  height range %.1fm .. %.1fm (relief %.1fm)" % [lowest, highest, highest - lowest])
	print("  %.1f%% of the surface is steeper than 30 degrees" % (100.0 * steep_samples / float(total_pixels)))

	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(data_dir)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(data_dir))
	data.call("save_directory", data_dir)

	# Stamp the freshness manifest only for a full bake: a `--regions=` subset
	# run (the bit-identity test's own use of this script) touches a fraction
	# of the world and must never mark the WHOLE world fresh against the
	# live config. See terrain_bake.gd::write_manifest.
	if full_bake:
		TERRAIN_BAKE.write_manifest(data_dir, locations.size())

	print("baked -> %s (%d region(s))" % [data_dir, locations.size()])
	quit(0)


## Bake exactly one region's worth of world (`rect`, one lattice cell at this
## `region_size`/`spacing`) into `data`: colour pass, import_images, control
## pass. Returns this region's own height range / steep-pixel stats so the
## caller can fold them into a whole-run total. Identical work per pixel
## whether this is called once for the whole world or once per region — see
## this file's region-set header comment for why that is safe.
## GROUND-LAYERS. The two macro-variation noise fields, built identically
## wherever they are needed so the colour pass and the control pass cannot drift
## apart. Separate seeds rather than two octaves of one: two octaves share their
## zero crossings, so the patches would sit centred inside the drifts and the
## whole field would read as one shape with a halo.
func _macro_noise(cfg: Dictionary) -> Array:
	var drift := FastNoiseLite.new()
	var patch := FastNoiseLite.new()
	var seed_value := int(cfg.get("seed", 20260823))
	drift.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	drift.seed = seed_value
	drift.frequency = float(cfg.get("drift_frequency", 0.0055))
	patch.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	patch.seed = seed_value + 977
	patch.frequency = float(cfg.get("patch_frequency", 0.019))
	return [drift, patch]


func _bake_region(
	field: RefCounted, config: Dictionary, colour_cfg: Dictionary,
	texture_step: float, rock_step: float, spacing: float, rect: Dictionary, data: Object
) -> Dictionary:
	var origin_x: float = rect["min_x"]
	var origin_z: float = rect["min_z"]
	var size_x := int(round((rect["max_x"] - rect["min_x"]) / spacing))
	var size_z := int(round((rect["max_z"] - rect["min_z"]) / spacing))

	var height_image := Image.create_empty(size_x, size_z, false, Image.FORMAT_RF)
	var colour_image := Image.create_empty(size_x, size_z, false, Image.FORMAT_RGBA8)

	var lowest := INF
	var highest := -INF
	var steep_samples := 0
	var water_level: float = field.water_level()

	var macro_cfg: Dictionary = config.get("macro", {})
	var macro_pair := _macro_noise(macro_cfg)
	var macro_drift: FastNoiseLite = macro_pair[0]
	var macro_patch: FastNoiseLite = macro_pair[1]
	for pixel_z in size_z:
		var world_z := origin_z + pixel_z * spacing
		for pixel_x in size_x:
			var world_x := origin_x + pixel_x * spacing
			var height: float = field.height_at(world_x, world_z)
			height_image.set_pixel(pixel_x, pixel_z, Color(height, 0.0, 0.0, 1.0))

			var slope: float = field.slope_degrees_at(
				world_x, world_z, _band_step(field, world_x, world_z, texture_step, rock_step))
			# OF11: the band pick is no longer slope-plus-noise. `rock_bias_deg`
			# reads the rise's own relief field — rib/gully sign, local
			# convexity, and height up the rise — so rock lands on the
			# geometry that actually is rock. See its own comment.
			var band_slope: float = slope + field.rock_bias_deg(world_x, world_z)
			var ground := _ground_colour(
				band_slope, colour_cfg, _band_blend(field, world_x, world_z, colour_cfg))
			# EV5: darken the bed and the damp shore ring toward wet sand. Half
			# of the shallow-edge colour shift — the water shader's own depth
			# gradient is the other half — and it survives even where the water
			# surface is transparent enough to see straight through.
			# EV6-remainder-polish: nudge the colour multiplier toward the soil
			# tone across each building's worked-soil apron, so the far-LOD
			# colour agrees with the soil texture the control map swaps in
			# below — the same both-halves treatment the wet shore gets. Before
			# the wet lerp on purpose: a stream bank stays wet, not dug.
			# GROUND-LAYERS round 3. Macro dryness lives HERE, in the colour
			# map, and not in the control map, and that is a measurement.
			#
			# Round 2 put it in the control map as a base-id assignment behind a
			# noise threshold, because a partial control BLEND was measured not
			# to draw on this build (see _paint_control_map). That worked, and
			# an elevated frame showed why it was still wrong: control ids
			# cannot interpolate, so every 2m control cell is wholly one texture
			# or wholly the other and the patch boundaries render as hard
			# rectangular steps. Invisible from a 2m player camera, obvious from
			# 38m up -- which is the entire reason the elevated shot exists.
			#
			# The colour map has no such limit. It is a continuous per-pixel
			# albedo multiply sampled with normal texture filtering, so a value
			# written per 2m pixel arrives on screen as a smooth gradient. Every
			# other broad ground effect in this bake -- the wet shore, the
			# building aprons, the drained ground -- is already a colour lerp
			# for the same reason, and none of them steps.
			#
			# Placed before those three so all of them still override it: a
			# worked apron, a wet bank and dying ground each say something more
			# specific than "this stretch is drier".
			if not macro_cfg.is_empty():
				var dry_here := _macro_dry(macro_drift, macro_patch, world_x, world_z, height, macro_cfg)
				if dry_here > 0.0:
					ground = ground.lerp(
						Color(str(macro_cfg.get("dry_tint", "#d0bd7a"))),
						dry_here * float(macro_cfg.get("dry_colour_strength", 0.85)))

			var apron: float = field.building_apron_factor(world_x, world_z)
			if apron > 0.0:
				var soil_tint := Color(str(colour_cfg.get("soil", "#d1b37e")))
				ground = ground.lerp(soil_tint,
					apron * float(config.get("building_aprons", {}).get("colour_strength", 0.6)))
			var wet := _wet_weight(field, height, world_x, world_z, water_level)
			if wet > 0.0:
				var wet_tint := Color(str(colour_cfg.get("wet_tint", "#c2b49a")))
				ground = ground.lerp(wet_tint, wet * float(colour_cfg.get("wet_strength", 0.5)))
			# D41/SD16: the drained ground around a Tether station. Last of the
			# three colour lerps, so it discolours whatever the ground already
			# was -- dying grass, dying path and a dying stream bank all read as
			# the same sickness, which is the point. It cannot come earlier for
			# that reason: applied before the wet lerp, a drained bank would come
			# back damp and healthy.
			var drain: float = field.drain_factor(world_x, world_z)
			if drain > 0.0:
				var drain_cfg: Dictionary = config.get("drains", {})
				var drain_tint := Color(str(drain_cfg.get("tint", "#bfb6a0")))
				ground = ground.lerp(drain_tint,
					drain * float(drain_cfg.get("colour_strength", 0.85)))
			colour_image.set_pixel(pixel_x, pixel_z, ground)

			lowest = minf(lowest, height)
			highest = maxf(highest, height)
			if slope >= 30.0:
				steep_samples += 1

	# import_images' position places pixel (0,0) of the image at that world
	# coordinate -- i.e. the MIN corner, not a centre point, despite the name
	# this file used to give the variable. For the shipped symmetric config
	# `origin_x`/`origin_z` are `-half_extent`, which is exactly why the
	# imported block ends up spanning a symmetric range around the world
	# origin and the player spawns in the middle rather than at a corner. An
	# off-centre corridor (§1.3c) passes an off-centre `min_x`/`min_z` here
	# the same way. Sized to exactly one region (`size_x`/`size_z` are
	# `region_size` samples), so this call touches only the one
	# `Terrain3DRegion` this rect covers, never its neighbours.
	var images: Array[Image] = [null, null, null]
	images[MAP_HEIGHT] = height_image
	images[MAP_CONTROL] = null
	images[MAP_COLOR] = colour_image
	data.call("import_images", images, Vector3(origin_x, 0.0, origin_z), 0.0, 1.0)
	await process_frame

	_paint_control_map(data, field, config, colour_cfg, origin_x, origin_z, size_x, size_z, spacing, texture_step, rock_step)

	return {"lowest": lowest, "highest": highest, "steep_samples": steep_samples, "pixel_count": size_x * size_z}


## Paint the REAL control map with the same slope thresholds as the baked
## colour map, instead of leaving every pixel on Terrain3D's built-in
## per-pixel "auto" texturing.
##
## That auto mode looked like the right default — it is what `_apply_ground_
## materials()` turns on via `auto_shader = true` — but it switches textures
## at a FIXED slope threshold this build exposes no control over (confirmed by
## dumping Terrain3DMaterial's and Terrain3DTextureAsset's own property lists:
## no `auto_slope`, no per-texture slope/height range, anywhere reachable from
## script). On this terrain's rolling-hills noise that threshold sits low
## enough that almost the whole map reads as the OVERLAY texture (id 1) and
## only near-flat ground — the spawn pad, a path shoulder — reads as the BASE
## texture (id 0), with a hard, un-authored edge between them wherever slope
## happens to cross it. Rendered close up near spawn (`tools/survey.gd`'s
## 01/05 viewpoints) that edge is a saturated, zero-blue-channel green stripe
## against a dark marbled field — the "olive/lime ground seam" this was
## chasing. R7.1 tested only `03-rise-overlook`, whose eye sits ON the ridge
## silhouette's own rise, already past the threshold either way — the seam
## never showed up there because the whole frame was on one side of it.
##
## Painting the control map explicitly, per-pixel, with `auto` turned OFF,
## replaces that opaque 2-texture cutover with the SAME three-tier grass/
## soil/rock blend already authored for the colour map (`_ground_colour`
## below) — soil is a real texture in play for the first time, not just an
## unreachable auto-shader tier.
func _paint_control_map(
	data: Object, field: RefCounted, config: Dictionary, colour_cfg: Dictionary,
	origin_x: float, origin_z: float, size_x: int, size_z: int, spacing: float,
	texture_step: float, rock_step: float
) -> void:
	var ids := _texture_ids(config.get("textures", []))
	if ids.is_empty():
		push_warning("terrain_playground.json has no grass/soil/rock textures named; " +
			"leaving the control map on Terrain3D's built-in auto-shader, seam and all")
		return

	var painted_path_pixels := 0
	var painted_wet_pixels := 0
	var painted_apron_pixels := 0
	var painted_drain_pixels := 0
	var painted_dry_pixels := 0
	var painted_damp_pixels := 0
	var painted_verge_pixels := 0
	var water_level: float = field.water_level()

	# GROUND-LAYERS: the two macro-variation noise fields. Built here rather
	# than on the heightfield because nothing else needs them -- this is a
	# question about which MATERIAL a pixel wears, not about its shape, and
	# keeping it out of the heightfield keeps the scatter bake's own config
	# fingerprint honest about what it depends on.
	var macro_cfg: Dictionary = config.get("macro", {})
	var macro_pair := _macro_noise(macro_cfg)
	var macro_drift: FastNoiseLite = macro_pair[0]
	var macro_patch: FastNoiseLite = macro_pair[1]
	for pixel_z in size_z:
		var world_z := origin_z + pixel_z * spacing
		for pixel_x in size_x:
			var world_x := origin_x + pixel_x * spacing
			# Same smoothed, rock-biased slope as the colour map
			# (EV4-hillside-seam, OF11) so the control map's base/overlay/blend
			# pick matches what got painted into the colour map, band for band
			# — `rock_bias_deg` is a pure function of world XZ, so sampling it
			# again here in this separate loop still lands on the identical
			# value the colour-map pass used.
			var slope: float = field.slope_degrees_at(
				world_x, world_z, _band_step(field, world_x, world_z, texture_step, rock_step))
			var band_slope: float = slope + field.rock_bias_deg(world_x, world_z)
			# GROUND-REBUILD C1, extended to the slope threshold as well.
			#
			# The worker applying C1 left this site alone because the order
			# named the damp cut, the verge cut, the path thresholds and the
			# _blend_control_toward dithers, and not this one -- correctly, in
			# that it flagged the gap rather than widening its own scope. But
			# C1's whole purpose was to fix all THREE shapes of the visible
			# grid at their shared root, and the third shape is the rectangular
			# grass tiles a blind critic found on the band-1 cliff face. Those
			# come from exactly this threshold: a high-variance slope field
			# crossing a fixed cut, aliased against the 2m texel pitch.
			#
			# Same 50/50 mix for the same reason as the other four sites: the
			# coherent field has a ~6.7m wavelength sampled at 2m pitch, so it
			# moves whole runs of texels together and a contour still traces
			# aligned staircases; a per-texel hash is already at texel pitch and
			# cannot alias.
			var slope_hash := absf(fmod(sin(float(pixel_x) * 12.9898 + float(pixel_z) * 78.233) * 43758.5453, 1.0))
			var slope_dither: float = 0.5 * float(field.path_dominant_dither(world_x, world_z)) + 0.5 * slope_hash
			var control := _control_for(
				band_slope, colour_cfg, ids, _band_blend(field, world_x, world_z, colour_cfg),
				slope_dither, float(config.get("macro", {}).get("slope_raggedness", 1.6)))
			# GROUND-LAYERS. Macro material variation, applied ONLY where the
			# slope pick left this pixel on unblended grass. Above
			# soil_slope_deg the hillside transition owns the overlay slot and
			# has to keep it -- there is one blend per pixel and the slope
			# read is the more important of the two. On flat meadow that slot
			# was idle (`{grass, soil, 0.0}`), which is what makes this free.
			#
			# Damp wins over dry where both apply, for the obvious reason.
			# Both are applied BEFORE the apron/drain/path passes below so all
			# three still override where their own weight is stronger.
			if float(control["blend"]) <= 0.001 and int(control["base"]) == int(ids["grass"]):
				var here: float = field.height_at(world_x, world_z)
				var damp := 0.0
				if ids.has("damp") and not is_nan(water_level):
					var reach := float(macro_cfg.get("damp_reach", 1.1))
					damp = (1.0 - smoothstep(water_level + 0.35, water_level + 0.35 + reach, here)) \
						* float(macro_cfg.get("damp_max", 0.65))
				# GROUND-LAYERS round 2. The macro layers are assigned as the
				# BASE id behind a noise-raggedded threshold, NOT as an overlay
				# with a partial blend, and that is a measurement, not a
				# preference.
				#
				# Measured on this Terrain3D build by forcing the drygrass tint
				# to magenta and rendering the same viewpoint three ways:
				#   drygrass as BASE, blend 0.0        -> 3.66% magenta ground
				#   drygrass as OVERLAY, blend 1.0     -> 3.67% magenta ground
				#   drygrass as OVERLAY, blend ~0.39   -> 0.00% magenta ground
				# (that third case had blend mean 0.394 and max 0.949 across
				# 150 of 195 sampled points in the visible near field, so it
				# was not for want of coverage.)
				#
				# A partial blend value therefore does not draw here; the
				# overlay channel only expresses itself at full weight. That is
				# almost certainly the same wall EV4-hillside-seam-remainder
				# hit across four rounds trying to get a visible soil band
				# between grass and rock -- that transition is written as
				# {base: grass, overlay: soil, blend: smoothstep(...)}, a
				# partial blend, and every round a fresh blind critic reported
				# "grass goes straight to rock with nothing between them" while
				# the rounds themselves blamed the tint, then the photo's
				# saturation, then its hue. See the lane report.
				#
				# So the boundary is raggedded here instead, with coherent
				# position noise rather than a blend ramp -- the same technique
				# `_blend_control_toward` already uses to spread the path pick
				# stochastically across its own edge, which is a mechanism this
				# renderer demonstrably does express.
				# GROUND-LAYERS round 3: the DRY variation moved out of here
				# and into the colour map -- see the colour pass for the
				# measurement that forced it. What is left is the damp band,
				# which stays a real material swap because a wet shore genuinely
				# is a different surface and not merely a different tint of the
				# same one, and because it is a narrow contour at the waterline
				# where the step is short and reads as a shoreline rather than
				# as a grid.
				var ragged := clampf(float(macro_cfg.get("edge_raggedness", 0.06)), 0.0, 1.0)
				# GROUND-REBUILD round 2. `path_dominant_dither` is coherent noise
				# at a ~6.7m wavelength, sampled here at the 2m control pitch --
				# it therefore moves whole RUNS of texels together, and a
				# threshold contour driven only by it still traces long aligned
				# staircases along the damp/verge cut. A hash evaluated once per
				# texel is already at texel pitch and cannot alias, so mixing it
				# 50/50 with the coherent field converts residual staircase runs
				# into a stochastic single-texel fringe instead of a drawn line.
				var hash_dither := absf(fmod(sin(float(pixel_x) * 12.9898 + float(pixel_z) * 78.233) * 43758.5453, 1.0))
				var dither: float = 0.5 * float(field.path_dominant_dither(world_x, world_z)) + 0.5 * hash_dither
				var threshold := 0.5 + (dither - 0.5) * ragged
				if ids.has("damp") and damp > 0.004 and damp > threshold * float(macro_cfg.get("damp_max", 0.65)):
					control = {"base": int(ids["damp"]), "overlay": int(ids["damp"]), "blend": 0.0}
					painted_damp_pixels += 1
				elif ids.has("soil"):
					# GROUND-REBUILD: dry patches are a real SURFACE, not a tint.
					# The colour map can only ever darken (Terrain3D multiplies
					# by it), so a sun-bleached patch -- which has to read
					# LIGHTER than the meadow around it -- cannot be a colour
					# effect at all. It has to be verge grass in the splat.
					# The colour-map dryness stays as well, doing the half of
					# the job it can do: dimming and warming the ground between
					# the patches so they do not sit on a flat field.
					var dry_here := _macro_dry(macro_drift, macro_patch, world_x, world_z, here, macro_cfg)
					# An ABSOLUTE cut on the dryness field, jittered by the same
					# coherent noise that ravels every other boundary here. It
					# was briefly a fraction of the dither threshold, which put
					# the cut near the middle of the distribution and turned 95%
					# of the region into verge -- the art direction asks for 14%.
					# Calibrate this against the printed percentage, not by eye.
					var cut := float(macro_cfg.get("verge_cut", 0.62)) \
						+ (dither - 0.5) * ragged * 0.30
					if dry_here > cut:
						control = {"base": int(ids["soil"]), "overlay": int(ids["soil"]), "blend": 0.0}
						painted_dry_pixels += 1
			var path_weight: float = field.path_factor(world_x, world_z)
			# EV5: the pond bed, the damp shore ring and the stream channel
			# swap to the same dedicated Ground030 dirt/pebble texture the
			# paths use — a pebbled bed under the water, not grass seen
			# through a blue filter. Reuses `_path_control` verbatim: "blend
			# this pixel toward the worn-ground texture by this weight" is
			# the identical operation whether a boot or a stream wore it.
			var wet := _wet_weight(field, field.height_at(world_x, world_z), world_x, world_z, water_level)
			if wet > 0.0:
				painted_wet_pixels += 1
			# EV6-remainder-polish: the worked-soil ring around each building
			# footprint (playground_heightfield.building_apron_factor), applied
			# FIRST so a path or a wet stream bank crossing the ring wins where
			# its own weight is stronger — trodden pebbles and wet sand both
			# out-rank dug soil.
			var apron: float = field.building_apron_factor(world_x, world_z)
			var worn := maxf(path_weight, wet)
			if apron > 0.0:
				painted_apron_pixels += 1
				if apron > worn:
					# GROUND-REBUILD round 2: 50/50 mix with a per-texel hash, same
					# reason as the damp/verge cut above -- the coherent field alone
					# aliases into aligned runs of texels at this 2m sampling pitch,
					# and only a texel-pitch hash can break a run down to single
					# texels rather than merely relabelling which pixels form it.
					var apron_hash := absf(fmod(sin(float(pixel_x) * 12.9898 + float(pixel_z) * 78.233) * 43758.5453, 1.0))
					var apron_dither: float = 0.5 * float(field.path_dominant_dither(world_x, world_z)) + 0.5 * apron_hash
					control = _blend_control_toward(control, apron, int(ids["soil"]), apron_dither)
			# D41/SD16: the drained ground swaps toward the same dead soil the
			# aprons use -- a station kills the ground cover, it does not lay a
			# new material. Ordered with the apron and behind `worn` for the
			# reason the apron already is: a road worn through dying ground is
			# still a road, and the pebbled path texture has to survive crossing
			# a drain radius or the track vanishes exactly where the conduits
			# are. The colour lerp above still discolours the path itself, so
			# the road reads as sick without reading as gone.
			var drain: float = field.drain_factor(world_x, world_z)
			if drain > 0.0:
				painted_drain_pixels += 1
				var drain_weight: float = drain * float(config.get("drains", {}).get("control_strength", 0.7))
				if drain_weight > worn and drain_weight > apron:
					# GROUND-REBUILD round 2: same 50/50 coherent+hash dither as the
					# apron blend just above -- the coherent field's ~6.7m
					# wavelength against a 2m control pitch aliases into aligned
					# texel runs, and the per-texel hash breaks that alignment.
					var drain_hash := absf(fmod(sin(float(pixel_x) * 12.9898 + float(pixel_z) * 78.233) * 43758.5453, 1.0))
					var drain_dither: float = 0.5 * float(field.path_dominant_dither(world_x, world_z)) + 0.5 * drain_hash
					control = _blend_control_toward(control, drain_weight, int(ids["soil"]), drain_dither)
			if worn > 0.0:
				# GROUND-REBUILD. Threshold, not blend -- and this is a bug fix,
				# not a style change.
				#
				# `path_factor` returns 1.0 inside the path's own half-width and
				# falls to 0 across its shoulder, and `_blend_control_toward`
				# then set base=path for ANY weight above zero, expecting the
				# partial blend to carry the falloff. Partial blends are
				# measured not to draw on this build, so base won everywhere and
				# every pixel the falloff touched rendered as FULL path. Paths
				# have therefore been drawing at roughly half+shoulder instead of
				# half -- about double their authored width. That is the
				# "6-8m wide, a motorway for foot traffic" blind critics have
				# reported against a 1.80m player, and it is the same
				# non-rendering blend that produced the checkerboard meadow and
				# defeated the hillside soil band. Third instance of one cause.
				#
				# Replaced with the art direction's own staircase: path core,
				# then a verge-grass shoulder, then meadow. The eye sees two
				# ~13-point value steps instead of one 27-point cliff, which is
				# what a trampled shoulder actually looks like -- so the hard 2m
				# quantisation reads as wear rather than as a mask error.
				# GROUND-REBUILD round 2: same 50/50 coherent+hash dither as the
				# damp/verge cut above, applied to the path core/shoulder
				# comparison itself -- this is the boundary the checkerboard
				# critique was most about, since it is also authored at exactly
				# this 2m control pitch against the coherent field's ~6.7m
				# wavelength.
				var hash_dither := absf(fmod(sin(float(pixel_x) * 12.9898 + float(pixel_z) * 78.233) * 43758.5453, 1.0))
				var dither: float = 0.5 * float(field.path_dominant_dither(world_x, world_z)) + 0.5 * hash_dither
				var jitter := (dither - 0.5) * float(macro_cfg.get("path_edge_jitter", 0.20))
				var core := float(macro_cfg.get("path_core", 0.55)) + jitter
				var shoulder_at := float(macro_cfg.get("path_shoulder", 0.16)) + jitter
				if worn >= core:
					control = {"base": int(ids.get("path", ids["soil"])),
						"overlay": int(ids.get("path", ids["soil"])), "blend": 0.0}
					if path_weight > 0.0:
						painted_path_pixels += 1
				elif worn >= shoulder_at:
					# The shoulder is verge grass, never bare dirt: dirt here is
					# what made path and "generic worn area" the same material and
					# let the route dissolve at ground level.
					control = {"base": int(ids["soil"]), "overlay": int(ids["soil"]), "blend": 0.0}
					painted_verge_pixels += 1
			var pos := Vector3(world_x, 0.0, world_z)
			data.call("set_control_base_id", pos, control["base"])
			data.call("set_control_overlay_id", pos, control["overlay"])
			data.call("set_control_blend", pos, control["blend"])
			data.call("set_control_auto", pos, false)

	var total_px := float(maxi(1, size_x * size_z))
	# The path target moved 4% -> 0.6% when GRASS-FIELD narrowed the routes
	# (paths.width 2.0 -> 1.4, shoulder 2.5 -> 1.1, so the painted band is 3.6m
	# rather than 7.0m). That is a ~6x area reduction and 4 / 6 is 0.67, so the
	# new figure is the old target scaled by the same change rather than a
	# freshly measured one. Blind passes had measured the old band at "8-12m
	# across against a 1.80m figure -- that is a road, not the worn footpath the
	# framing describes". Nothing asserts this line; it is a reference for a
	# reader, which is exactly why leaving it at 4 would have been worse than
	# useless once the bake started reporting 0.6.
	print("  control map: verge dry %.1f%%, path %.1f%%, path shoulder %.1f%%, damp %.1f%% (target 14 / 0.6 / -- / 1)" %
		[painted_dry_pixels / total_px * 100.0, painted_path_pixels / total_px * 100.0,
		painted_verge_pixels / total_px * 100.0, painted_damp_pixels / total_px * 100.0])
	print("  control map painted: base/overlay/blend by slope, paths in %s (%d pixels), wet bed (%d pixels), building aprons in soil (%d pixels), drained ground in soil (%d pixels), auto-shader off" %
		["path" if ids.has("path") else "soil", painted_path_pixels, painted_wet_pixels, painted_apron_pixels, painted_drain_pixels])


## The step at which slope is sampled for the material band pick, in metres:
## `coarse` out on the open meadow, `fine` on a rise. Round 4 (OF11) — one
## global step cannot serve both, because the two places have their real
## surface detail at different scales. Sampling the meadow finely brings back
## the `detail`-noise blotching EV4-hillside-seam introduced this setting to
## kill; sampling a rise coarsely blurs away the ledges and riser lips
## `rock_form` builds, so the material lands in soft blobs that ignore the
## crevices under them. Interpolated rather than switched, so there is no line
## in the bake where the sampling scale changes.
func _band_step(field: RefCounted, x: float, z: float, coarse: float, fine: float) -> float:
	if is_equal_approx(coarse, fine):
		return coarse
	return lerpf(coarse, fine, clampf(field.rise_form_factor(x, z), 0.0, 1.0))


## The width of the grass->soil and soil->rock ramps in DEGREES of slope, at
## this pixel: `colour.blend_deg` out on the meadow, `colour.blend_deg_rock` on
## a rise, interpolated by the same `rise_form_factor` `_band_step` uses.
##
## OF11 round 6. `blend_deg` is a width in slope, but what a viewer sees is a
## width in METRES, and the conversion between them is the local rate of change
## of slope — which round 4 deliberately made very steep on the rises by
## sampling their slope at 2m instead of 6m. On the open meadow 6 degrees of
## ramp is metres of gradual transition; across a `rock_form` riser the same 6
## degrees is crossed inside a pixel or two, so the ramp collapses and the band
## boundary bakes as a hard edge. That is what the round-5 blind critic saw --
## "a hard vector edge with zero blend... a stencil laid over the rock" -- and
## it is a direct and predictable side effect of round 4's win, not a
## regression in it. Widening the ramp only where the slope field is steep
## restores a visible transition without touching the meadow, and without
## coarsening the sampling that made the material track the crevices.
func _band_blend(field: RefCounted, x: float, z: float, cfg: Dictionary) -> float:
	var coarse := maxf(0.001, float(cfg.get("blend_deg", 7.0)))
	var fine := maxf(0.001, float(cfg.get("blend_deg_rock", coarse)))
	# `_control_for` splits the range into five non-overlapping bands and relies
	# on `soil_at + blend <= rock_at` to do it. Past that gap the grass->soil
	# ramp would swallow the whole soil band and the soil->rock ramp with it, so
	# rock would not start until `soil_at + blend` -- widening the transition
	# would silently RAISE the rock threshold and bare less of the rise, the
	# opposite of the intent. Clamped here rather than left as a comment,
	# because this is now a tunable a future round will reach for first.
	var gap := float(cfg.get("rock_slope_deg", 38.0)) - float(cfg.get("soil_slope_deg", 24.0))
	if gap > 0.0:
		coarse = minf(coarse, gap)
		fine = minf(fine, gap)
	if is_equal_approx(coarse, fine):
		return coarse
	return lerpf(coarse, fine, clampf(field.rise_form_factor(x, z), 0.0, 1.0))


## How "wet" a point of ground is, 0..1: fully wet under the pond's waterline
## and inside the stream channel, fading out across a damp ring ~0.7m of
## elevation above the waterline. EV5. Keyed off HEIGHT for the pond (below
## the flat water level IS underwater, see playground_heightfield.water_level)
## and off `stream_factor` for the channel, whose own water surface follows
## the carved bed downhill rather than sitting at one level.
##
## T1-WATER (§8): the river never earned this. `water.gd::_build_river`'s own
## header records why it uses the pond's mechanism and not the stream's — the
## channel is authored to hold ONE level, the same "height below a flat
## surface is wet" shape the pond already uses here — but this function was
## never extended to ask `river_level()`/`river_factor()`, so the river's bed
## and banks bake with whatever the slope pick alone gives them: ordinary
## grass or hillside rock, with no wet/mud transition where the water
## actually sits. Owner brief calls this out directly as "mismatched
## water-edge ecology" and asks for one baseline treatment across every body
## of water, not an isolated pond.
##
## Gated by `river_factor(x, z)` (not a bare height test like the pond's):
## the pond is one basin, so any nearby ground sharing its absolute elevation
## IS the pond, but the river runs ~340m through terrain that swings 27m and
## briefly crosses the SAME elevation as ground far from the channel. The
## gate gets multiplied against the height term rather than substituted for
## it, so a pixel has to be both near the channel horizontally (river_factor)
## and near the water's height to read as wet — the same two-part shape
## `_pond_surface_mask`/`_river_surface_mask` already use in water.gd for the
## identical reason.
func _wet_weight(field: RefCounted, height: float, x: float, z: float, water_level: float) -> float:
	var wet := 0.0
	if not is_nan(water_level):
		# +0.35, not +0.7: at the basin's gentle bank slopes an 0.7m damp ring
		# fanned out to ~8m of sand apron, which the first render showed as a
		# beach halo dominating the pond's own footprint. Half the elevation
		# keeps a readable damp edge at half the width.
		wet = 1.0 - smoothstep(water_level - 0.1, water_level + 0.35, height)
	if field.has_method("stream_factor"):
		wet = maxf(wet, float(field.stream_factor(x, z)))
	if field.has_method("river_level") and field.has_method("river_factor"):
		var river_level: float = field.river_level()
		# Cheap reject before the expensive per-segment scan `river_factor`
		# runs (measured ~4x `stream_factor`'s own per-call cost, and this is
		# an unconditional per-pixel call across a 64-region corridor). Height
		# above the wet band's own ceiling makes the result 0 regardless of
		# the gate -- smoothstep saturates to 1 there, so `river_wet` is
		# already 0 -- so skipping the scan changes nothing it would have
		# added. Below `river_level - 0.1` cannot be skipped this way: the bed
		# runs 6-9m under the rims through the middle reaches and every one of
		# those pixels is genuinely wet, at `river_wet == 1.0` however far
		# down they sit.
		if not is_nan(river_level) and height <= river_level + 0.35:
			var gate := float(field.river_factor(x, z))
			if gate > 0.0:
				var river_wet := 1.0 - smoothstep(river_level - 0.1, river_level + 0.35, height)
				wet = maxf(wet, river_wet * gate)
	return wet


## Blend a pixel's already-computed slope control toward the path texture,
## weighted by `field.path_factor()`. EV4 (bible sec8): "paths become a
## control-map material, not a colour-map tint" — the colour map's own
## `#c8a874` lerp multiplied grass-coloured grass toward tan, which is why
## R9.4-remainder-4 found "no worked ground anywhere," just a tinted variant
## of whatever texture was already there. This instead swaps in a real
## texture for the pixel, so a path reads as a different material.
##
## Round 1 shipped this reusing `soil` (the only dirt-family texture that
## existed at the time) and three rounds of blind critique never accepted it
## as reading as dirt rather than tinted grass — round 3 root-caused it to
## Ground003_Color.jpg's own baked-in green flecks, not a tunable value. EV4
## round 5 switches to `ids["path"]`, a dedicated texture (ambientCG
## Ground030, a real dirt/pebble pathway photo) sourced and ledgered for
## exactly this while this file's own path-conversion work was in flight —
## see the EV4-textures entry in DONE.md. Falls back to `soil` if `path`
## is not configured, so an older/pared-down textures list still bakes.
##
## Terrain3D's control map holds one base id, one overlay id and one blend
## weight per pixel — never three textures — so the natural (slope-driven)
## blend has to collapse to a single "dominant" id before it can be re-blended
## against the path texture. That collapse is exact off the path
## (`path_weight` 0 or 1) and an approximation only inside the fade band,
## where the path signal already dominates the frame.
##
## EV4-textures: a fixed `>= 0.5` cut picks that dominant id in one pixel
## step, with none of the smoothstepping every other transition in this file
## uses — so wherever a route's fade band crosses a grass/soil or soil/rock
## boundary, the texture showing through the path's edge hops cleanly from
## one material to another along a single line. On a flat, axis-unaligned
## boundary that line aliases into the "small rectangular notches" EV4's
## round-5 critic named, distinct from the flat-ground edge wobble already
## fixed. `dither` (`Heightfield.path_dominant_dither`, a coherent noise
## field, not per-pixel white noise) spreads that pick stochastically across
## the same `blend_deg` width the natural ground already transitions over,
## so the boundary reads as blotchy intermixing instead of a drawn line.
func _path_control(natural: Dictionary, path_weight: float, ids: Dictionary, dither: float) -> Dictionary:
	return _blend_control_toward(natural, path_weight, int(ids.get("path", ids["soil"])), dither)


## The shared collapse-and-reblend rule `_path_control` describes above,
## parameterised by the texture being blended toward — EV6-remainder-polish
## reuses it verbatim for the worked-soil apron around each building
## footprint, which blends toward `soil` where a path blends toward `path`.
## GROUND-LAYERS. How dry this pixel's grass is, 0..1, as a blend weight for the
## `drygrass` overlay.
##
## Two independent noise fields plus a mild elevation term:
##
## - `drift` is the ~180m "you are crossing into a drier stretch" scale. It
##   carries most of the weight because it is the only one of the three a player
##   walking at ground level actually reads as a place changing around them.
## - `patch` is the ~53m "this hollow is greener" scale, mixed in at
##   `patch_weight` to break the drift's own edges up so they do not read as
##   soft-edged continents.
## - elevation bleaches ridges and keeps hollows green, which is both true of
##   real grassland and what stops the pattern reading as arbitrary. Held to a
##   minority share (`height_influence`) because variation that tracks the
##   landform exactly reads as a contour map, which is a different wrong answer.
##
## `dry_gain` then pushes the midtones apart so the field spends more of its
## area committed to green or to dry and less in the middle, and `dry_max` caps
## the result below 1.0 so no pixel ever fully abandons the meadow grass. Both
## are what separate "one biome with weather in it" from "two biomes with a
## seam".
func _macro_dry(
	drift: FastNoiseLite, patch: FastNoiseLite,
	x: float, z: float, height: float, cfg: Dictionary
) -> float:
	# FastNoiseLite returns -1..1; both are remapped to 0..1 before mixing so a
	# negative patch cannot cancel a positive drift into a false zero.
	var a := drift.get_noise_2d(x, z) * 0.5 + 0.5
	var b := patch.get_noise_2d(x, z) * 0.5 + 0.5
	var patch_weight := clampf(float(cfg.get("patch_weight", 0.42)), 0.0, 1.0)
	var mixed := lerpf(a, b, patch_weight)

	var lift := clampf(float(cfg.get("height_influence", 0.35)), 0.0, 1.0)
	if lift > 0.0:
		var low := float(cfg.get("height_low", -20.0))
		var high := float(cfg.get("height_high", 12.0))
		mixed = lerpf(mixed, smoothstep(low, high, height), lift)

	# Centre on 0.5, scale, recentre: gain above 1.0 spreads the midtones toward
	# both ends without moving the mean, so the proportion of dry ground stays
	# roughly what the noise gave and only its contrast changes.
	var gain := maxf(0.01, float(cfg.get("dry_gain", 1.4)))
	var shaped := clampf((mixed - 0.5) * gain + 0.5, 0.0, 1.0)
	return shaped * clampf(float(cfg.get("dry_max", 0.72)), 0.0, 1.0)


func _blend_control_toward(natural: Dictionary, weight: float, tex: int, dither: float) -> Dictionary:
	if weight >= 0.999:
		return {"base": tex, "overlay": tex, "blend": 0.0}
	var dominant: int = natural["overlay"] if float(natural["blend"]) >= dither else natural["base"]
	if dominant == tex:
		return {"base": tex, "overlay": tex, "blend": 0.0}
	return {"base": tex, "overlay": dominant, "blend": 1.0 - weight}


## `name -> texture id`, read from the same `textures` list `playground_world.
## gd`'s `_build_texture_list()` builds the Texture2DArray from — one source of
## truth for which index is which species of ground. Empty if any of the
## three `_control_for` needs is missing, so the caller can fall back
## cleanly. `path` is optional — `_path_control` falls back to `soil` when
## it is absent, so an older textures list still bakes paths, just without a
## dedicated dirt texture.
func _texture_ids(entries: Array) -> Dictionary:
	var by_name: Dictionary = {}
	for i in entries.size():
		var spec: Dictionary = entries[i]
		by_name[str(spec.get("name", ""))] = i
	var needed := ["grass", "soil", "rock"]
	for name in needed:
		if not by_name.has(name):
			return {}
	var ids := {"grass": by_name["grass"], "soil": by_name["soil"], "rock": by_name["rock"]}
	if by_name.has("path"):
		ids["path"] = by_name["path"]
	# GROUND-LAYERS: both optional, same contract as `path` above. A textures
	# list without them bakes exactly what it baked before -- slope bands and
	# paths, no macro variation and no damp shore -- rather than failing.
	if by_name.has("drygrass"):
		ids["drygrass"] = by_name["drygrass"]
	if by_name.has("damp"):
		ids["damp"] = by_name["damp"]
	return ids


## Same three bands as `_ground_colour`, expressed as a base/overlay texture
## pair plus a blend weight rather than a colour — Terrain3D's control map
## only ever carries two texture ids and one blend factor per pixel, so a
## true three-way blend has to be two adjacent two-way blends instead. Because
## `soil_at + blend <= rock_at` for every value this config has shipped, the
## bands never need to overlap: grass user, then a grass->soil ramp, then pure
## soil, then a soil->rock ramp, then rock. Any pixel is always on exactly one
## of those five, matching `_ground_colour`'s own `smoothstep` windows band for
## band rather than approximating them.
func _control_for(slope_degrees: float, cfg: Dictionary, ids: Dictionary, blend_deg: float,
		dither: float = 0.5, ragged: float = 0.0) -> Dictionary:
	var soil_at := float(cfg.get("soil_slope_deg", 24.0))
	var rock_at := float(cfg.get("rock_slope_deg", 38.0))
	var blend := maxf(0.001, blend_deg)

	var grass: int = ids["grass"]
	var soil: int = ids["soil"]
	var rock: int = ids["rock"]

	# GROUND-REBUILD. One surface per pixel, chosen against a slope threshold
	# that is JITTERED by coherent position noise -- not a partial blend across
	# a transition band.
	#
	# The band this replaces returned {base: grass, overlay: soil, blend:
	# smoothstep(...)} through the whole transition, and partial blends are
	# measured not to draw on this build, so `base` won and the "band" was
	# always a hard line at the point base flipped. That is why
	# EV4-hillside-seam-remainder could never make a soil band appear across
	# four rounds: it was retuning the colour of a surface that was never being
	# mixed in. It also produced the blocky green cells scattered over rock
	# faces -- a noisy slope field crossing a fixed threshold aliases into
	# isolated 2m squares.
	#
	# `blend_deg` keeps its meaning as the WIDTH of the transition, but it now
	# sets how far the threshold wanders rather than how far two textures mix,
	# so a wider setting still gives a softer-looking edge. The jitter is
	# coherent noise, not per-pixel random, so the boundary ravels into an
	# organic edge instead of dissolving into salt-and-pepper.
	var wander := (dither - 0.5) * blend * ragged
	if slope_degrees < soil_at + wander:
		return {"base": grass, "overlay": grass, "blend": 0.0}
	if slope_degrees < rock_at + wander:
		return {"base": soil, "overlay": soil, "blend": 0.0}
	return {"base": rock, "overlay": rock, "blend": 0.0}


## Slope-driven ground colour. Grass on walkable ground, soil on the shoulders,
## rock on genuinely steep faces.
##
## This is a MULTIPLIER over the PBR albedo, not a paint layer, and that changed
## what belongs in it. It was authored when the colour map WAS the ground — real
## grass green, real soil brown, no textures anywhere — and those values kept
## being multiplied into the textures after the textures arrived. Grass albedo at
## luminance 0.40 times a #496c34 colour map at 0.36 is a ground of 0.14 before
## a photon reaches it, which is why the near field measured 0.096 against
## 0.27-0.60 across the references and why nothing about the lighting fixed it:
## the surface was dark on paper.
##
## So these are near-white now. The textures carry the colour; this carries the
## slope-driven VARIATION, which is the job it is actually good at. Anything
## much below #c0 here is a brightness change pretending to be a colour.
func _ground_colour(slope_degrees: float, cfg: Dictionary, blend_deg: float) -> Color:
	var grass_low := Color(str(cfg.get("grass_low", "#496c34")))
	var grass_high := Color(str(cfg.get("grass_high", "#7f8c3d")))
	var soil := Color(str(cfg.get("soil", "#d1b37e")))
	var rock := Color(str(cfg.get("rock", "#b4b1a6")))
	var soil_at := float(cfg.get("soil_slope_deg", 24.0))
	var rock_at := float(cfg.get("rock_slope_deg", 38.0))
	var blend := maxf(0.001, blend_deg)

	# Flat ground varies between the two greens by slope alone, so a hillside
	# reads lighter than a hollow without needing a second noise field.
	var grass := grass_low.lerp(grass_high, clampf(slope_degrees / soil_at, 0.0, 1.0))
	var to_soil := smoothstep(soil_at, soil_at + blend, slope_degrees)
	var to_rock := smoothstep(rock_at, rock_at + blend, slope_degrees)
	return grass.lerp(soil, to_soil).lerp(rock, to_rock)
