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
const HALF_SPAN := 256.0 ## World spans ±256m (`terrain_playground.json`'s `world_size` 512).

## Set by `bake_cached()` on every call — true when the cached PNG was reused,
## false when a bake actually ran. Exists purely so `tests/test_map_baker.gd`
## can honestly tell the two cases apart without guessing from file mtimes.
static var last_bake_was_cache_hit := false


## Samples `world.call("ground_height_at", x, z)` on a `resolution`² grid
## across the full ±256m playground and colours each pixel by height/slope.
## `world` only needs to answer `ground_height_at` — the fake world
## `tests/test_map_baker.gd` builds is a bare `RefCounted`, not a real scene
## node, and never touches Terrain3D.
static func bake(world: Node, resolution: int = 512) -> ImageTexture:
	var step := (HALF_SPAN * 2.0) / float(resolution)

	var heights := PackedFloat32Array()
	heights.resize(resolution * resolution)

	var min_height := INF
	var max_height := -INF

	# Two-pass: sample every height first (and remember it) so the slope
	# shading pass below can read already-sampled neighbours instead of
	# calling back into `world` a second time per pixel.
	for iz in resolution:
		var z := -HALF_SPAN + (float(iz) + 0.5) * step
		for ix in resolution:
			var x := -HALF_SPAN + (float(ix) + 0.5) * step
			var h: float = world.call("ground_height_at", x, z)
			if is_nan(h):
				h = 0.0
			heights[iz * resolution + ix] = h
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

	var image := Image.create(resolution, resolution, false, Image.FORMAT_RGB8)

	for iz in resolution:
		for ix in resolution:
			var h := heights[iz * resolution + ix]
			var h_east := heights[iz * resolution + mini(ix + 1, resolution - 1)]
			var h_south := heights[mini(iz + 1, resolution - 1) * resolution + ix]

			var colour := _colour_for(h, water_level, land_floor, max_height, meadow_green, pale_high)

			# Slope shading: finite difference against the +x/+z neighbours,
			# darkened by up to ~25% on the steepest ground sampled.
			var slope := absf(h_east - h) + absf(h_south - h)
			var darken := clampf(slope / (step * 6.0), 0.0, 0.25)
			colour = colour.darkened(darken)

			image.set_pixel(ix, iz, colour)

	return ImageTexture.create_from_image(image)


## Same bake, cached to disk under `cache_path` (default `user://cache/`),
## keyed on a hash of `terrain_playground.json`'s own bytes via a sidecar
## `cache_path + ".key"` file — the terrain recipe is the only input that can
## change what this bakes, so hashing it (rather than e.g. a version
## constant someone has to remember to bump) makes a stale cache impossible
## without an explicit "I changed the terrain and forgot" bug in this file
## itself.
static func bake_cached(world: Node, cache_path: String = "user://cache/map_meadows.png") -> ImageTexture:
	var config_bytes := FileAccess.get_file_as_bytes(TERRAIN_CONFIG_PATH)
	var key := str(hash(config_bytes))
	var key_path := cache_path + ".key"

	if FileAccess.file_exists(cache_path) and FileAccess.file_exists(key_path):
		var key_file := FileAccess.open(key_path, FileAccess.READ)
		var cached_key := key_file.get_as_text().strip_edges() if key_file != null else ""
		if cached_key == key:
			var image := Image.new()
			if image.load(cache_path) == OK:
				last_bake_was_cache_hit = true
				return ImageTexture.create_from_image(image)
			# Corrupt/unreadable cache file: fall through and rebake honestly
			# rather than returning a texture from garbage bytes.

	var texture := bake(world)
	last_bake_was_cache_hit = false

	DirAccess.make_dir_recursive_absolute(cache_path.get_base_dir())
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
