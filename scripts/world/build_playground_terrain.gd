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
	var world_size := int(config.get("world_size", 512))
	var region_size := int(config.get("region_size", 256))
	var spacing := float(config.get("vertex_spacing", 1.0))
	var size := int(world_size / spacing)

	if world_size % region_size != 0:
		push_error("world_size %d is not a multiple of region_size %d; the bake would straddle region boundaries and leave unfilled flat gaps" % [world_size, region_size])
		quit(1)
		return

	print("baking %dm playground, %dx%d samples at %.2fm spacing, %d regions of %d" %
		[world_size, size, size, spacing, (world_size / region_size) ** 2, region_size])

	var origin := -0.5 * size * spacing
	var height_image := Image.create_empty(size, size, false, Image.FORMAT_RF)
	var colour_image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)

	var colour_cfg: Dictionary = config.get("colour", {})
	# EV4-hillside-seam: texture-band decisions are deliberately sampled at a
	# WIDER step than the geometry (see terrain_playground.json's own comment)
	# so the fine `detail` noise layer doesn't flicker the grass/soil/rock pick
	# pixel to pixel. Height itself still bakes at `spacing`.
	var texture_step := float(colour_cfg.get("slope_sample_step", spacing))
	var lowest := INF
	var highest := -INF
	var steep_samples := 0

	for pixel_z in size:
		var world_z := origin + pixel_z * spacing
		for pixel_x in size:
			var world_x := origin + pixel_x * spacing
			var height: float = field.height_at(world_x, world_z)
			height_image.set_pixel(pixel_x, pixel_z, Color(height, 0.0, 0.0, 1.0))

			var slope: float = field.slope_degrees_at(world_x, world_z, texture_step)
			var ground := _ground_colour(slope, colour_cfg)
			colour_image.set_pixel(pixel_x, pixel_z, ground)

			lowest = minf(lowest, height)
			highest = maxf(highest, height)
			if slope >= 30.0:
				steep_samples += 1

	print("  height range %.1fm .. %.1fm (relief %.1fm)" % [lowest, highest, highest - lowest])
	print("  %.1f%% of the surface is steeper than 30 degrees" % (100.0 * steep_samples / float(size * size)))

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

	# import_images places the maps with their CENTRE at global_position, so the
	# region lands centred on the world origin and the player spawns in the
	# middle of the playground rather than at its corner.
	var images: Array[Image] = [null, null, null]
	images[MAP_HEIGHT] = height_image
	images[MAP_CONTROL] = null
	images[MAP_COLOR] = colour_image
	data.call("import_images", images, Vector3(origin, 0.0, origin), 0.0, 1.0)
	await process_frame

	_paint_control_map(data, field, config, colour_cfg, origin, size, spacing, texture_step)

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
	origin: float, size: int, spacing: float, texture_step: float
) -> void:
	var ids := _texture_ids(config.get("textures", []))
	if ids.is_empty():
		push_warning("terrain_playground.json has no grass/soil/rock textures named; " +
			"leaving the control map on Terrain3D's built-in auto-shader, seam and all")
		return

	var painted_path_pixels := 0
	for pixel_z in size:
		var world_z := origin + pixel_z * spacing
		for pixel_x in size:
			var world_x := origin + pixel_x * spacing
			# Same smoothed slope as the colour map (EV4-hillside-seam) so the
			# control map's base/overlay/blend pick matches what got painted
			# into the colour map, band for band.
			var slope: float = field.slope_degrees_at(world_x, world_z, texture_step)
			var control := _control_for(slope, colour_cfg, ids)
			var path_weight: float = field.path_factor(world_x, world_z)
			if path_weight > 0.0:
				var dither: float = field.path_dominant_dither(world_x, world_z)
				control = _path_control(control, path_weight, ids, dither)
				painted_path_pixels += 1
			var pos := Vector3(world_x, 0.0, world_z)
			data.call("set_control_base_id", pos, control["base"])
			data.call("set_control_overlay_id", pos, control["overlay"])
			data.call("set_control_blend", pos, control["blend"])
			data.call("set_control_auto", pos, false)

	print("  control map painted: base/overlay/blend by slope, paths in %s (%d pixels), auto-shader off" %
		["path" if ids.has("path") else "soil", painted_path_pixels])


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
	var path_tex: int = int(ids.get("path", ids["soil"]))
	if path_weight >= 0.999:
		return {"base": path_tex, "overlay": path_tex, "blend": 0.0}
	var dominant: int = natural["overlay"] if float(natural["blend"]) >= dither else natural["base"]
	if dominant == path_tex:
		return {"base": path_tex, "overlay": path_tex, "blend": 0.0}
	return {"base": path_tex, "overlay": dominant, "blend": 1.0 - path_weight}


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
func _control_for(slope_degrees: float, cfg: Dictionary, ids: Dictionary) -> Dictionary:
	var soil_at := float(cfg.get("soil_slope_deg", 24.0))
	var rock_at := float(cfg.get("rock_slope_deg", 38.0))
	var blend := maxf(0.001, float(cfg.get("blend_deg", 7.0)))

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
func _ground_colour(slope_degrees: float, cfg: Dictionary) -> Color:
	var grass_low := Color(str(cfg.get("grass_low", "#496c34")))
	var grass_high := Color(str(cfg.get("grass_high", "#7f8c3d")))
	var soil := Color(str(cfg.get("soil", "#d1b37e")))
	var rock := Color(str(cfg.get("rock", "#b4b1a6")))
	var soil_at := float(cfg.get("soil_slope_deg", 24.0))
	var rock_at := float(cfg.get("rock_slope_deg", 38.0))
	var blend := maxf(0.001, float(cfg.get("blend_deg", 7.0)))

	# Flat ground varies between the two greens by slope alone, so a hillside
	# reads lighter than a hollow without needing a second noise field.
	var grass := grass_low.lerp(grass_high, clampf(slope_degrees / soil_at, 0.0, 1.0))
	var to_soil := smoothstep(soil_at, soil_at + blend, slope_degrees)
	var to_rock := smoothstep(rock_at, rock_at + blend, slope_degrees)
	return grass.lerp(soil, to_soil).lerp(rock, to_rock)
