extends RefCounted

## Region-lattice bounds and the alignment guard. `MEADOWS_MACRO_LAYOUT.md`
## section 1.3(a)/(b): a Terrain3D region's world origin is
## `region_location * region_size * vertex_spacing`, so region boundaries fall
## on a lattice whose pitch (in metres) is `region_size * vertex_spacing`, not
## on multiples of `region_size` alone. A world's bounds must land on that
## lattice on BOTH sides of every axis — checking extent
## (`(max - min) % pitch`) is not enough: 1536 % 512 == 0, but a 1536m width
## centred on the origin runs -768..+768 and neither bound is a multiple of
## 512. Checking every bound subsumes the extent check (if min and max are
## both multiples of the pitch, so is max - min).
##
## Split out of `build_playground_terrain.gd` so the guard is a pure function
## a test can call directly, without spinning up the bake's SceneTree.

## World bounds from config, in metres: {min_x, max_x, min_z, max_z}.
##
## Three ways a config can specify its extent, checked in this priority order:
##   1. `world_bounds`: {min_x, max_x, min_z, max_z} -- fully explicit, the
##      only shape that can express an off-centre corridor (macro layout
##      §1.3c: x in [-1024, +1024], z in [-512, +7680], not centred at z=0).
##   2. `world_size_x` / `world_size_z` -- a rectangle, still centred on the
##      origin.
##   3. `world_size` -- legacy: a square, centred on the origin. Kept so every
##      caller that still reads `world_size` directly (vegetation.gd's
##      scatter, the minimap, the map baker, the existing 512m playground
##      config) keeps working unchanged; this task does not touch the
##      footprint.
static func world_bounds(config: Dictionary) -> Dictionary:
	if config.has("world_bounds"):
		var explicit: Dictionary = config["world_bounds"]
		return {
			"min_x": float(explicit.get("min_x", 0.0)),
			"max_x": float(explicit.get("max_x", 0.0)),
			"min_z": float(explicit.get("min_z", 0.0)),
			"max_z": float(explicit.get("max_z", 0.0)),
		}
	if config.has("world_size_x") or config.has("world_size_z"):
		var size_x := float(config.get("world_size_x", config.get("world_size", 512)))
		var size_z := float(config.get("world_size_z", config.get("world_size", 512)))
		return {
			"min_x": -0.5 * size_x, "max_x": 0.5 * size_x,
			"min_z": -0.5 * size_z, "max_z": 0.5 * size_z,
		}
	var size := float(config.get("world_size", 512))
	return {
		"min_x": -0.5 * size, "max_x": 0.5 * size,
		"min_z": -0.5 * size, "max_z": 0.5 * size,
	}


## "" if every bound of `bounds` lands on the region lattice; otherwise a
## human-readable reason naming the first offending bound.
##
## `fposmod`, not `%`: GDScript's `%` on a negative float operand does not
## return a value in [0, pitch), and every west/north bound of an off-centre
## corridor world is negative.
static func check_alignment(bounds: Dictionary, region_size: int, vertex_spacing: float) -> String:
	if region_size <= 0:
		return "region_size %d must be positive" % region_size
	if vertex_spacing <= 0.0:
		return "vertex_spacing %.3f must be positive" % vertex_spacing
	var pitch := float(region_size) * vertex_spacing
	for axis in ["x", "z"]:
		for edge in ["min_" + axis, "max_" + axis]:
			var bound := float(bounds.get(edge, 0.0))
			var remainder := fposmod(bound, pitch)
			if not is_zero_approx(remainder) and not is_zero_approx(remainder - pitch):
				return (
					"world bound %s=%.1f is not a multiple of the %.1fm region pitch " % [edge, bound, pitch]
					+ "(region_size %d * vertex_spacing %.2f); the outermost regions would be " % [region_size, vertex_spacing]
					+ "partly written and bake as flat gaps")
	if bounds.get("min_x", 0.0) >= bounds.get("max_x", 0.0):
		return "world min_x %.1f must be less than max_x %.1f" % [bounds.get("min_x", 0.0), bounds.get("max_x", 0.0)]
	if bounds.get("min_z", 0.0) >= bounds.get("max_z", 0.0):
		return "world min_z %.1f must be less than max_z %.1f" % [bounds.get("min_z", 0.0), bounds.get("max_z", 0.0)]
	return ""


## Region columns × rows covered by `bounds` at this lattice pitch. Only
## meaningful once `check_alignment` has returned "" for the same bounds.
static func region_counts(bounds: Dictionary, region_size: int, vertex_spacing: float) -> Vector2i:
	var pitch := float(region_size) * vertex_spacing
	var columns := int(round((bounds.get("max_x", 0.0) - bounds.get("min_x", 0.0)) / pitch))
	var rows := int(round((bounds.get("max_z", 0.0) - bounds.get("min_z", 0.0)) / pitch))
	return Vector2i(columns, rows)


## Every `region_location` (Terrain3D's own Vector2i convention: a region's
## world origin is `region_location * region_size * vertex_spacing`) covering
## `bounds` at this lattice pitch. This is "every region is dirty" -- the
## default, whole-world region set a plain (non-incremental) bake asks for.
## Only meaningful once `check_alignment` has returned "" for the same bounds.
static func region_locations(bounds: Dictionary, region_size: int, vertex_spacing: float) -> Array[Vector2i]:
	var pitch := float(region_size) * vertex_spacing
	var col0 := int(round(bounds.get("min_x", 0.0) / pitch))
	var row0 := int(round(bounds.get("min_z", 0.0) / pitch))
	var counts := region_counts(bounds, region_size, vertex_spacing)
	var out: Array[Vector2i] = []
	for row in counts.y:
		for col in counts.x:
			out.append(Vector2i(col0 + col, row0 + row))
	return out


## The world-space rectangle one `region_location` covers, at this lattice
## pitch: {min_x, max_x, min_z, max_z}. Inverse of the arithmetic
## `region_locations` uses to enumerate locations from bounds.
static func region_world_rect(location: Vector2i, region_size: int, vertex_spacing: float) -> Dictionary:
	var pitch := float(region_size) * vertex_spacing
	var min_x := float(location.x) * pitch
	var min_z := float(location.y) * pitch
	return {"min_x": min_x, "max_x": min_x + pitch, "min_z": min_z, "max_z": min_z + pitch}
