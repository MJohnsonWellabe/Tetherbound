extends RefCounted

## Where things grow.
##
## Pure: handed a heightfield and a config, it returns a list of placements. No
## nodes, no meshes, no rendering. Same split as combat_math.gd and combat_ai.gd,
## and for the same reason — "the meadow looks like a golf course" and "there are
## trees on the cliff face" are both questions a unit test can ask directly.
##
## Seeded, so the meadow is identical every run. A world that reshuffles its
## trees on every launch cannot be surveyed, cannot be compared before and after
## a change, and cannot be authored on top of later.
##
## The scatter CLUSTERS rather than sprinkling evenly. Evenly-distributed props
## at uniform scale are the readable signature of generator output, and the
## visual rubric calls it out by name: clustering, scale variety and clearings
## read as designed, regular intervals do not. So each layer places a handful of
## clumps and scatters within them, with a few strays for the spaces between.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const CONFIG_PATH := "res://data/config/vegetation.json"

## How many candidate clump centres a ridge-biased layer samples before
## keeping the highest. Small enough to stay cheap (at most a few dozen
## calls per layer build), large enough that the bias is real.
const RIDGE_CANDIDATES := 6

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("vegetation.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


## May a prop of this layer stand here?
##
## Slope is the main gate. Trees growing out of a cliff face and grass on a
## vertical rock are the two artefacts that most cheaply destroy the illusion
## that a place was authored.
static func allowed(layer: Dictionary, height: float, slope: float, distance_from_spawn: float, spot: Vector2 = Vector2.INF) -> bool:
	if slope > float(layer.get("max_slope_deg", 26.0)):
		return false
	if slope < float(layer.get("min_slope_deg", -1.0)):
		return false
	if height < float(layer.get("min_height", -1000.0)):
		return false
	if height > float(layer.get("max_height", 1000.0)):
		return false
	# The spawn pad is deliberately clear. The player's first sight of the game
	# should not be the inside of a bush.
	if distance_from_spawn < float(layer.get("clear_radius", 0.0)):
		return false
	# Authored clearings. Fights happen where creatures stand, the arena is
	# eleven metres across, and a tree inside it ends up between the camera and
	# the whole fight — which is what made two survey frames show nothing but
	# green.
	#
	# A clearing keeps out what can BLOCK, not everything that grows. Applying it
	# to every layer is what left the spawn — where the camera always starts —
	# as forty metres of bare terrain in every frame, with the foreground of the
	# game's first sight of itself carrying no content at all. Grass and
	# wildflowers are walked straight through and cannot occlude a fight, so
	# there was never a reason to strip them; the reason was written for trees
	# and applied to everything within reach of it.
	if spot != Vector2.INF and bool(layer.get("cleared_by_clearings", true)) and _inside_a_clearing(spot):
		return false
	return true


static func _inside_a_clearing(spot: Vector2) -> bool:
	for entry: Variant in config().get("clearings", []):
		var clearing: Dictionary = entry
		var centre := Vector2(float(clearing.get("x", 0.0)), float(clearing.get("z", 0.0)))
		if spot.distance_to(centre) < float(clearing.get("radius", 0.0)):
			return true
	return false


## Build every placement for one layer.
##
## Returns dictionaries of `{ model, position, yaw, scale }` — enough for a
## renderer and nothing that assumes one.
static func placements_for(
	layer: Dictionary, field: RefCounted, world_size: float, seed_value: int
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var models: Array = layer.get("models", [])
	if models.is_empty():
		return out

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var half := world_size * 0.5
	var clumps := int(layer.get("clumps", 20))
	var per_clump := int(layer.get("per_clump", 12))
	var spread := float(layer.get("clump_radius", 14.0))
	var strays := int(layer.get("strays", 0))
	var ridge_bias := clampf(float(layer.get("ridge_bias", 0.0)), 0.0, 1.0)

	for clump in clumps:
		var centre := _clump_centre(rng, half, field, ridge_bias)
		for i in per_clump:
			# Square root of a uniform sample gives a disc that is denser at the
			# middle, which is what a copse looks like. Sampling the radius
			# directly produces a ring.
			var angle := rng.randf_range(0.0, TAU)
			var radius := sqrt(rng.randf()) * spread
			var spot := centre + Vector2(sin(angle), cos(angle)) * radius
			_consider(out, layer, field, models, spot, half, rng)

	for i in strays:
		var spot := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		_consider(out, layer, field, models, spot, half, rng)

	return out


## How far a ridge-biased clump is allowed to wander from its own unbiased
## draw while hunting for higher ground. Wide enough to reach genuinely
## nearby high ground — a ridge crest, not just the one exact sample —
## narrow enough that the clump stays roughly where the map's overall spread
## would have put it anyway. This is the difference between "nudge toward
## whatever local high ground is nearby" and "race toward the map's tallest
## peak", which the first version of this function did not distinguish and
## which rendering, not reasoning, is what caught: half-biasing the trees
## layer at a global search radius left the actual survey horizons just as
## bare, because a handful of clumps racing toward the map's two or three
## named rises does nothing for the compass directions those rises are not
## in.
const RIDGE_SEARCH_RADIUS := 140.0

## Where a clump starts. Plain uniform by default; a `ridge_bias`-weighted
## fraction of clumps instead search a local neighbourhood for higher ground
## and start there instead.
##
## Deliberately not slope-based ridge DETECTION — there is no map of named
## ridgelines to check against, and hand-picking coordinates is exactly the
## kind of thing that breaks the next time the terrain config changes.
## "The tallest of a handful of tries near where this clump was already
## going" concentrates each clump toward whatever local high ground is
## nearby, with no knowledge of where that is, while leaving the clumps'
## overall spread across the map unchanged from the unbiased distribution.
static func _clump_centre(
	rng: RandomNumberGenerator, half: float, field: RefCounted, ridge_bias: float
) -> Vector2:
	var base := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
	if ridge_bias <= 0.0 or rng.randf() > ridge_bias:
		return base

	var best := base
	var best_height: float = field.height_at(base.x, base.y)
	for i in RIDGE_CANDIDATES - 1:
		var offset := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		var candidate := base + offset * RIDGE_SEARCH_RADIUS
		candidate.x = clampf(candidate.x, -half, half)
		candidate.y = clampf(candidate.y, -half, half)
		var height: float = field.height_at(candidate.x, candidate.y)
		if not is_nan(height) and (is_nan(best_height) or height > best_height):
			best = candidate
			best_height = height
	return best


static func _consider(
	out: Array[Dictionary], layer: Dictionary, field: RefCounted,
	models: Array, spot: Vector2, half: float, rng: RandomNumberGenerator
) -> void:
	if absf(spot.x) > half or absf(spot.y) > half:
		return
	var height: float = field.height_at(spot.x, spot.y)
	if is_nan(height):
		return
	var slope: float = field.slope_degrees_at(spot.x, spot.y)
	if not allowed(layer, height, slope, spot.length(), spot):
		return
	# Nothing grows on the road. The paths double as wayfinding, and a path is
	# only legible if it stays visibly worn — path_stones are the one layer
	# allowed on it, because stones on a path ARE the path. The threshold is
	# past the half-width, so verges keep their growth right up to the edge.
	if not bool(layer.get("grows_on_paths", false)) \
			and field.has_method("path_factor") and float(field.path_factor(spot.x, spot.y)) > 0.3:
		return

	# `base_scale` corrects the pack's authoring scale for the whole layer;
	# scale_min/max then vary around it. Two numbers rather than one so "the
	# trees are too small" and "the trees are all the same size" stay separate
	# complaints with separate fixes.
	var base := float(layer.get("base_scale", 1.0))
	var low := float(layer.get("scale_min", 0.85)) * base
	var high := float(layer.get("scale_max", 1.25)) * base
	out.append({
		"model": str(models[rng.randi_range(0, models.size() - 1)]),
		"position": Vector3(spot.x, height, spot.y),
		"yaw": rng.randf_range(0.0, TAU),
		"scale": rng.randf_range(low, high),
	})


## Every layer, in one call. The seed is offset per layer so trees and grass do
## not land in identical patterns.
static func all_placements(field: RefCounted, world_size: float, base_seed: int) -> Dictionary:
	var layers: Dictionary = config().get("layers", {})
	var built: Dictionary = {}
	var offset := 0
	for name: String in layers.keys():
		if name.begins_with("_"):
			continue
		var layer: Dictionary = layers[name]
		built[name] = placements_for(layer, field, world_size, base_seed + offset * 7919)
		offset += 1
	return built
