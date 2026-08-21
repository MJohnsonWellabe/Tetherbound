extends RefCounted

## Bakes the minimap's top-down terrain texture, once, from the same
## heightfield the terrain itself is built from — `D33`: the minimap renders
## a BAKED image, not a second live camera. A live orthographic `Camera3D`
## re-rendering terrain, foliage and structures from above every frame is the
## expensive option on exactly the hardware this project treats as primary
## (ROG Ally, GL Compatibility); baking answers "what does the ground look
## like from above" once instead of every frame. See
## `docs/decisions/D33-one-map-database.md` and `D09` (never re-derive ground
## data through a second mechanism when the primary one already answers the
## question — the same argument, applied to a camera instead of a raycast).
##
## Pure/deterministic: no randomness, no `Time`/`Date` calls. The same world
## always bakes the same bytes (`tests/test_map_baker.gd::test_bake_is_
## deterministic`), which is what makes `bake_cached()`'s disk cache honest.
##
## WATER LEVEL SOURCE. The task brief that spawned this file pointed at
## `data/config/water.json` for the water surface height; that file's own
## `_comment` says otherwise — water.json is presentation only (colours,
## foam, reeds); the actual level lives in `data/config/terrain_playground.json`'s
## `water.level` (-22.5 today), because the heightfield, the terrain bake and
## the vegetation scatter all read it from there and must agree with each
## other about where the shoreline is (see that file's own
## `_comment_water`). This baker reads the same field, for the same reason:
## a minimap that drew its shoreline from a different source than the
## terrain that makes it would be the exact "two mechanisms answering the
## same question" failure `D09` already named once. SIMPLIFICATION (v1, per
## the task brief): one flat global threshold, not a per-body level — honest
## for a single meadows map with one pond and one stream, both already
## authored to the same flat `water.level` (confirmed in
## `terrain_playground.json`'s own `_comment_water`); a multi-body map would
## need this to become a per-region lookup.

const TERRAIN_CONFIG_PATH := "res://data/config/terrain_playground.json"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const WORLD_EXTENT := preload("res://scripts/world/world_extent.gd")

## PER-REGION/PER-BAND BAKE — DEFERRED, NOT SKIPPED. `docs/MEADOWS_MACRO_
## LAYOUT.md` §8.6(b) calls the whole-world bake becoming per-region/per-band
## (or a committed pre-baked asset) the "second hard prerequisite" before the
## corridor lands: at the corridor's pixel density this walks 16.78M pixels
## on the player's own machine, on first launch. That is NOT done here. This
## pass only removes the hard-coded ±256m assumption everywhere the map
## system carries it — `bake()` below now takes an explicit `bounds`
## rectangle instead of a baked-in half-span, which is the precondition for a
## future per-region caller (pass a sub-rectangle, get that region's texture)
## but does not itself add region-splitting, incremental baking, or
## band-crossing triggers. §8.5 sequences those with the footprint change
## itself (`OW5B`), because there is exactly one region-count today (the
## current world is 512m over a 256m `region_size`, i.e. already more than
## one region) and no reason yet to build a system against a world that has
## not resized — the corridor's actual region count, and whether the honest
## answer is "bake per-region" or "ship the PNG as a committed asset" (§8.6b
## raises both), is a decision for whoever lands `OW5B`, not one to guess at
## here on a world this bake still finishes in a fraction of a second.

## Owner playtest report: "can we put paths and structures onto the mini
## map." Before this, the bake coloured purely by height/slope -- a real
## dirt road and a village square baked into the exact same green-to-ochre
## ramp as open pasture, because nothing here ever asked
## `playground_heightfield.gd` whether a sample point was ON anything. That
## file already answers both questions authoritatively (`path_factor`,
## `building_apron_factor` -- the same functions the terrain shader and the
## vegetation scatter read, D09's "one mechanism answers the question"),
## so this reuses them rather than re-deriving path/footprint geometry a
## second time from the raw config, which is exactly the drift D09 exists
## to prevent. Warm brown for paths (matches the terrain material's own
## post-playtest retint, terrain_playground.json's `paths.textures[0].tint`)
## and a cooler worked-stone grey for building aprons, blended in that
## order so a path crossing a village square still reads as path -- the
## same "paths win" rule the terrain shader itself already follows.
const PATH_COLOUR := Color(0.44, 0.30, 0.18)
const BUILDING_APRON_COLOUR := Color(0.58, 0.56, 0.52)

## Keep the historical ~262k-sample cost while giving the corridor square
## world texels: 2,048x8,192m becomes 256x1,024px. The authored route overlay
## below preserves narrow trails that an 8m centre sample can legitimately miss.
const DEFAULT_METRES_PER_PIXEL := 8.0
const CACHE_SCHEMA := "corridor-aspect-8m-routes-v1"

## Set by `bake_cached()` on every call — true when the cached PNG was reused,
## false when a bake actually ran. Exists purely so `tests/test_map_baker.gd`
## can honestly tell the two cases apart without guessing from file mtimes.
static var last_bake_was_cache_hit := false


## Samples `world.call("ground_height_at", x, z)` on a grid
## across `bounds` (default: the whole playground, per `world_extent.gd`) and
## colours each pixel by height/slope. `world` is typed `Object`, not `Node`,
## deliberately: it only needs to answer `ground_height_at`, and
## `tests/test_map_baker.gd` exercises this with a bare `RefCounted` fake —
## no scene tree, no Terrain3D — so this stays testable headlessly the same
## way the rest of the pure-logic layer (`playground_heightfield.gd`,
## `map_state.gd`) already is. The real caller (`tools/capture_minimap.gd`)
## passes the actual playground `Node`, which is an `Object` too.
##
## `bounds`, when given, is `{min_x, max_x, min_z, max_z}` — a sub-rectangle
## of the world rather than the whole thing, for a future per-region caller
## (see the DEFERRED note above this function's const block). An explicit
## `resolution` keeps the historical square test/probe contract; production
## derives each axis from the rectangle so texels cover equal world distances.
## `resolution > 0` retains the square synthetic/test contract. Production
## omits it, producing a rectangular texture with square 8m world texels; a
## square texture over the 2,048x8,192m corridor destroys both aspect and the
## local trail signal the minimap needs.
static func bake(world: Object, resolution: int = 0, bounds: Dictionary = {}) -> ImageTexture:
	var extent := bounds if not bounds.is_empty() else WORLD_EXTENT.bounds()
	var min_x: float = float(extent.get("min_x", 0.0))
	var min_z: float = float(extent.get("min_z", 0.0))
	var span_x := float(extent.get("max_x", 0.0)) - min_x
	var span_z := float(extent.get("max_z", 0.0)) - min_z
	var resolution_x := resolution if resolution > 0 else maxi(1, int(ceil(span_x / DEFAULT_METRES_PER_PIXEL)))
	var resolution_z := resolution if resolution > 0 else maxi(1, int(ceil(span_z / DEFAULT_METRES_PER_PIXEL)))
	var step_x := span_x / float(resolution_x)
	var step_z := span_z / float(resolution_z)

	var heights := PackedFloat32Array()
	heights.resize(resolution_x * resolution_z)

	var min_height := INF
	var max_height := -INF

	# Two-pass: sample every height first (and remember it) so the slope
	# shading pass below can read already-sampled neighbours instead of
	# calling back into `world` a second time per pixel.
	for iz in resolution_z:
		var z := min_z + (float(iz) + 0.5) * step_z
		for ix in resolution_x:
			var x := min_x + (float(ix) + 0.5) * step_x
			var h: float = world.call("ground_height_at", x, z)
			if is_nan(h):
				h = 0.0
			heights[iz * resolution_x + ix] = h
			min_height = minf(min_height, h)
			max_height = maxf(max_height, h)

	if max_height <= min_height:
		max_height = min_height + 1.0 # a perfectly flat sample area still colours sanely

	var water_level := _water_level()
	var land_floor := water_level if not is_nan(water_level) else min_height

	# Colour ramp stops, built from UITokens per the brief rather than
	# hand-picked hexes — see each comment for the derivation.
	var meadow_green := UITokens.HP_GREEN.lerp(Color(0.5, 0.5, 0.5), 0.2) ## ~20% desaturated toward grey; reads as grass, not a stat bar.
	var pale_high := UITokens.GROUND_OCHRE.lerp(Color(0.85, 0.83, 0.78), 0.55) ## highest ground: pale gray-ochre.

	var image := Image.create(resolution_x, resolution_z, false, Image.FORMAT_RGB8)
	var heightfield: RefCounted = HEIGHTFIELD.new()

	for iz in resolution_z:
		var z := min_z + (float(iz) + 0.5) * step_z
		for ix in resolution_x:
			var x := min_x + (float(ix) + 0.5) * step_x
			var h := heights[iz * resolution_x + ix]
			var h_east := heights[iz * resolution_x + mini(ix + 1, resolution_x - 1)]
			var h_south := heights[mini(iz + 1, resolution_z - 1) * resolution_x + ix]

			var colour := _colour_for(h, water_level, land_floor, max_height, meadow_green, pale_high)

			# Slope shading: finite difference against the +x/+z neighbours,
			# darkened by up to ~25% on the steepest ground sampled. Averaged
			# over both axes' step so a non-square `bounds` (a future
			# per-region call) does not skew the darkening toward whichever
			# axis has the coarser step.
			var slope := absf(h_east - h) + absf(h_south - h)
			var darken := clampf(slope / (((step_x + step_z) * 0.5) * 6.0), 0.0, 0.25)
			colour = colour.darkened(darken)

			# Paths/structures, on top of the height ramp -- never under
			# water (a road does not paint through the pond), and paths win
			# over building aprons where both overlap, same rule the
			# terrain shader itself already follows.
			if is_nan(water_level) or h >= water_level:
				var apron_t: float = heightfield.call("building_apron_factor", x, z)
				if apron_t > 0.0:
					colour = colour.lerp(BUILDING_APRON_COLOUR, apron_t)
				var path_t: float = heightfield.call("path_factor", x, z)
				if path_t > 0.0:
					colour = colour.lerp(PATH_COLOUR, path_t)

			image.set_pixel(ix, iz, colour)

	# A 3m road cannot be trusted to intersect the centre of every 8m terrain
	# texel. Raster the SAME canonical polylines the heightfield/world consume,
	# after the terrain pass, so route continuity does not depend on accidental
	# sampling alignment. This is thousands of segment pixels rather than a
	# second per-pixel scan of the whole authored route network.
	_overlay_authored_routes(image, heightfield, extent)

	return ImageTexture.create_from_image(image)


static func _overlay_authored_routes(image: Image, heightfield: RefCounted, extent: Dictionary) -> void:
	var routes: Array = heightfield.call("road_polylines")
	var min_world := Vector2(float(extent.get("min_x", 0.0)), float(extent.get("min_z", 0.0)))
	var world_size := Vector2(
		maxf(float(extent.get("max_x", 0.0)) - min_world.x, 0.001),
		maxf(float(extent.get("max_z", 0.0)) - min_world.y, 0.001))
	var image_size := Vector2(image.get_width(), image.get_height())
	for raw_line: Variant in routes:
		var line := raw_line as PackedVector2Array
		for index in line.size() - 1:
			var from_pixel := (line[index] - min_world) / world_size * image_size
			var to_pixel := (line[index + 1] - min_world) / world_size * image_size
			var steps := maxi(1, int(ceil(maxf(absf(to_pixel.x - from_pixel.x), absf(to_pixel.y - from_pixel.y)))))
			for sample in steps + 1:
				var point := from_pixel.lerp(to_pixel, float(sample) / float(steps))
				var pixel := Vector2i(int(floor(point.x)), int(floor(point.y)))
				if pixel.x >= 0 and pixel.y >= 0 and pixel.x < image.get_width() and pixel.y < image.get_height():
					image.set_pixelv(pixel, PATH_COLOUR)


## Same bake, cached to disk under `cache_path` (default `user://cache/`),
## keyed on a hash of `terrain_playground.json`'s own bytes via a sidecar
## `cache_path + ".key"` file — the terrain recipe is the only input that can
## change what this bakes, so hashing it (rather than e.g. a version
## constant someone has to remember to bump) makes a stale cache impossible
## without an explicit "I changed the terrain and forgot" bug in this file
## itself.
##
## WRITES ATOMICALLY, AND THIS IS NOT A HYPOTHETICAL. `cache_path` defaults
## to the same fixed path every caller uses (`minimap.gd`'s own callers,
## `tab_map.gd`'s full-map screen, `tools/capture_minimap.gd`) precisely so
## they share one bake — but this project's dev environment routinely runs
## several of those callers as SEPARATE, CONCURRENT Godot processes against
## the same `user://` directory (parallel capture/test tooling), and this
## item's own required visual check caught the consequence live: two of four
## real capture runs rendered a near-black minimap, byte-for-byte identical
## cache CONTENT notwithstanding (verified by hand — the saved PNG's own
## pixels were fine). The cause was a torn read, not a colour bug: a `save_png`
## direct to `cache_path` is not atomic, so a reader whose `Image.load()`
## lands mid-write decodes whatever partial bytes happen to be on disk at
## that instant, which for a PNG is typically most of the image reading back
## as black. Writing to a uniquely-named temp file first and renaming it
## into place closes that window — POSIX rename is atomic, so a concurrent
## reader always sees either the complete old file or the complete new one,
## never a partial one. A single-player game session was never at risk (one
## process, no concurrent writer) but the fix costs nothing and this is the
## honest way to make a shared on-disk cache safe rather than "safe until a
## second process touches it."
static func bake_cached(world: Object, cache_path: String = "user://cache/map_meadows.png") -> ImageTexture:
	var config_bytes := FileAccess.get_file_as_bytes(TERRAIN_CONFIG_PATH)
	var key := "%s:%s" % [CACHE_SCHEMA, str(hash(config_bytes))]
	var key_path := cache_path + ".key"

	if FileAccess.file_exists(cache_path) and FileAccess.file_exists(key_path):
		var key_file := FileAccess.open(key_path, FileAccess.READ)
		var cached_key := key_file.get_as_text().strip_edges() if key_file != null else ""
		if cached_key == key:
			var image := Image.new()
			if image.load(cache_path) == OK and image.get_width() > 0 and image.get_height() > 0:
				last_bake_was_cache_hit = true
				return ImageTexture.create_from_image(image)
			# Corrupt/unreadable cache file: fall through and rebake honestly
			# rather than returning a texture from garbage bytes.

	var texture := bake(world)
	last_bake_was_cache_hit = false

	var dir_path := cache_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)

	var tmp_path := "%s.tmp-%d" % [cache_path, Time.get_ticks_usec()]
	texture.get_image().save_png(tmp_path)
	var dir := DirAccess.open(dir_path)
	if dir != null and dir.rename(tmp_path.get_file(), cache_path.get_file()) == OK:
		pass # atomic swap into place; no reader can ever see a partial file
	else:
		# Same-filesystem rename should always succeed once the directory
		# opened; a direct save is the honest fallback if it somehow did not,
		# rather than leaving the bake result on disk only as a stray .tmp
		# file no cache-hit path will ever find.
		texture.get_image().save_png(cache_path)

	var key_file := FileAccess.open(key_path, FileAccess.WRITE)
	if key_file != null:
		key_file.store_string(key)

	return texture


## The still-water surface height in metres, or NAN when the config has no
## water block — the same "no answer" contract
## `playground_heightfield.gd::water_level()` already uses, mirrored here
## rather than instantiating a heightfield just to call it, so this file has
## no dependency beyond reading its own JSON.
static func _water_level() -> float:
	var file := FileAccess.open(TERRAIN_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return NAN
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return NAN
	var water: Dictionary = (parsed as Dictionary).get("water", {})
	if not water.has("level"):
		return NAN
	return float(water.get("level"))


static func _colour_for(height: float, water_level: float, land_floor: float, max_height: float, meadow_green: Color, pale_high: Color) -> Color:
	if not is_nan(water_level) and height < water_level:
		# Underwater: WATER_BLUE, darkened and desaturated further the deeper
		# below the surface a point sits (clamped over an 8m falloff — deep
		# enough that the pond's own -22.5m basin reads as clearly deeper
		# than its 1-2m shallows without needing an exact depth scale).
		var depth_t := clampf((water_level - height) / 8.0, 0.0, 1.0)
		var shallow := UITokens.WATER_BLUE.darkened(0.1)
		var deep := UITokens.WATER_BLUE.darkened(0.45).lerp(Color(0.5, 0.5, 0.5), 0.25)
		return shallow.lerp(deep, depth_t)

	var span := maxf(max_height - land_floor, 0.001)
	var t := clampf((height - land_floor) / span, 0.0, 1.0)

	if t <= 0.5:
		return meadow_green.lerp(UITokens.GROUND_OCHRE, t / 0.5)
	return UITokens.GROUND_OCHRE.lerp(pale_high, (t - 0.5) / 0.5)
