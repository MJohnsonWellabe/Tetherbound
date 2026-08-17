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

	var origin_x: float = bounds["min_x"]
	var origin_z: float = bounds["min_z"]
	var size_x := int(round((bounds["max_x"] - bounds["min_x"]) / spacing))
	var size_z := int(round((bounds["max_z"] - bounds["min_z"]) / spacing))
	var region_counts := ALIGNMENT.region_counts(bounds, region_size, spacing)

	print("baking x[%.1f, %.1f] z[%.1f, %.1f], %dx%d samples at %.2fm spacing, %d regions (%dx%d) of %d" %
		[bounds["min_x"], bounds["max_x"], bounds["min_z"], bounds["max_z"],
		size_x, size_z, spacing, region_counts.x * region_counts.y, region_counts.x, region_counts.y, region_size])

	var height_image := Image.create_empty(size_x, size_z, false, Image.FORMAT_RF)
	var colour_image := Image.create_empty(size_x, size_z, false, Image.FORMAT_RGBA8)

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
	var lowest := INF
	var highest := -INF
	var steep_samples := 0
	var water_level: float = field.water_level()

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

	print("  height range %.1fm .. %.1fm (relief %.1fm)" % [lowest, highest, highest - lowest])
	print("  %.1f%% of the surface is steeper than 30 degrees" % (100.0 * steep_samples / float(size_x * size_z)))

	var terrain: Node = ClassDB.instantiate("Terrain3D")
	terrain.set("region_size", region_size)
	terrain.set("vertex_spacing", spacing)
	terrain.set("data_directory", DATA_DIR)
	root.add_child(terrain)
	await process_frame

	var data: Object = terrain.get("data")
	if data == null:
		push_error("Terrain3D exposed no data object even after a frame")
		quit(1)
		return

	# import_images' position places pixel (0,0) of the image at that world
	# coordinate -- i.e. the MIN corner, not a centre point, despite the name
	# this file used to give the variable. For the shipped symmetric config
	# `origin_x`/`origin_z` are `-half_extent`, which is exactly why the
	# imported block ends up spanning a symmetric range around the world
	# origin and the player spawns in the middle rather than at a corner. An
	# off-centre corridor (§1.3c) passes an off-centre `min_x`/`min_z` here
	# the same way.
	var images: Array[Image] = [null, null, null]
	images[MAP_HEIGHT] = height_image
	images[MAP_CONTROL] = null
	images[MAP_COLOR] = colour_image
	data.call("import_images", images, Vector3(origin_x, 0.0, origin_z), 0.0, 1.0)
	await process_frame

	_paint_control_map(data, field, config, colour_cfg, origin_x, origin_z, size_x, size_z, spacing, texture_step, rock_step)

	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(DATA_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DATA_DIR))
	data.call("save_directory", DATA_DIR)

	print("baked -> %s" % DATA_DIR)
	quit(0)


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
	var water_level: float = field.water_level()
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
			var control := _control_for(
				band_slope, colour_cfg, ids, _band_blend(field, world_x, world_z, colour_cfg))
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
					var apron_dither: float = field.path_dominant_dither(world_x, world_z)
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
					var drain_dither: float = field.path_dominant_dither(world_x, world_z)
					control = _blend_control_toward(control, drain_weight, int(ids["soil"]), drain_dither)
			if worn > 0.0:
				var dither: float = field.path_dominant_dither(world_x, world_z)
				control = _path_control(control, worn, ids, dither)
				if path_weight > 0.0:
					painted_path_pixels += 1
			var pos := Vector3(world_x, 0.0, world_z)
			data.call("set_control_base_id", pos, control["base"])
			data.call("set_control_overlay_id", pos, control["overlay"])
			data.call("set_control_blend", pos, control["blend"])
			data.call("set_control_auto", pos, false)

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
func _control_for(slope_degrees: float, cfg: Dictionary, ids: Dictionary, blend_deg: float) -> Dictionary:
	var soil_at := float(cfg.get("soil_slope_deg", 24.0))
	var rock_at := float(cfg.get("rock_slope_deg", 38.0))
	var blend := maxf(0.001, blend_deg)

	var grass: int = ids["grass"]
	var soil: int = ids["soil"]
	var rock: int = ids["rock"]

	if slope_degrees <= soil_at:
		return {"base": grass, "overlay": soil, "blend": 0.0}
	if slope_degrees < soil_at + blend:
		return {"base": grass, "overlay": soil, "blend": smoothstep(soil_at, soil_at + blend, slope_degrees)}
	if slope_degrees <= rock_at:
		return {"base": soil, "overlay": rock, "blend": 0.0}
	if slope_degrees < rock_at + blend:
		return {"base": soil, "overlay": rock, "blend": smoothstep(rock_at, rock_at + blend, slope_degrees)}
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
