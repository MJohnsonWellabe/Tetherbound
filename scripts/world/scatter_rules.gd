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
	# Footprints are narrower and unconditional, unlike clearings above:
	# grass and flowers are deliberately exempt from the wide clearings (see
	# the comment above) so the meadow does not go bald near the arena, but
	# that exemption also let them grow straight through a building's own
	# floor and roof, since a footprint's few metres are not "near a
	# structure" the way a 16m clearing is -- they ARE the structure.
	# R9.4-remainder-8 found grass tufts inside Grandpa's house, on the rug.
	if spot != Vector2.INF and _inside_a_footprint(spot):
		return false
	return true


static func _inside_a_clearing(spot: Vector2) -> bool:
	for entry: Variant in config().get("clearings", []):
		var clearing: Dictionary = entry
		var centre := Vector2(float(clearing.get("x", 0.0)), float(clearing.get("z", 0.0)))
		if spot.distance_to(centre) < float(clearing.get("radius", 0.0)):
			return true
	return false


static func _inside_a_footprint(spot: Vector2) -> bool:
	for entry: Variant in config().get("footprints", []):
		var footprint: Dictionary = entry
		var centre := Vector2(float(footprint.get("x", 0.0)), float(footprint.get("z", 0.0)))
		if spot.distance_to(centre) < float(footprint.get("radius", 0.0)):
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
	var path_bias := clampf(float(layer.get("path_bias", 0.0)), 0.0, 1.0)
	var path_bias_jitter := maxf(float(layer.get("path_bias_jitter", 0.0)), 0.0)
	var path_avoid_radius := maxf(float(layer.get("path_avoid_radius", 0.0)), 0.0)

	for clump in clumps:
		var centre := _clump_centre(
			rng, half, field, ridge_bias, path_bias, path_bias_jitter, path_avoid_radius
		)
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
## and start there instead, and independently, a `path_bias`-weighted fraction
## snap straight onto the nearest authored path.
##
## Deliberately not slope-based ridge DETECTION — there is no map of named
## ridgelines to check against, and hand-picking coordinates is exactly the
## kind of thing that breaks the next time the terrain config changes.
## "The tallest of a handful of tries near where this clump was already
## going" concentrates each clump toward whatever local high ground is
## nearby, with no knowledge of where that is, while leaving the clumps'
## overall spread across the map unchanged from the unbiased distribution.
##
## `path_bias` does not need the same candidate-search trick: unlike height,
## which varies smoothly everywhere, `path_factor` is zero almost everywhere
## and only nonzero in a band a few metres either side of a route — a handful
## of random tries would land off the road nearly every time. So a
## path-biased clump snaps straight to `nearest_point_on_paths`, the same
## fix `EV3`'s own backlog entry names for `path_stones`: "clumps bias
## toward path_factor() instead of scattering independently of it, so a
## stone cluster sits ON the dirt it's supposedly part of." The clump's own
## `clump_radius` still spreads instances off the snapped centre, so a
## path-biased clump straddles the road rather than lining up on its
## centreline.
##
## `path_bias_jitter` (EV3-remainder): every exact snap lands ON the
## centreline, so several clumps strung along the same straight route are
## themselves collinear — each one's own instance scatter is a symmetric
## disc around a shared line, which a blind critic read as "a hedge planted
## with a ruler... same interval, same offset distance from the path edge".
## `path_stones` wants the exact snap (stones ARE the path, so this defaults
## to 0.0 and that layer is untouched); a layer that wants clumps to merely
## favour path-adjacent ground — `flowers`, a garden bed rather than the
## road's own material — can set this to displace the snapped centre by a
## random amount, so clump centres land at genuinely different distances
## from the path instead of all sitting on its exact line.
##
## `path_avoid_radius` (EV3-remainder-3): the opposite problem, on layers
## that never opted into `path_bias` at all. `clump_radius` (10-12m for
## grass/drygrass) is far wider than the path's own exclusion band
## (~3-4m), so a purely UNBIASED clump that happens to land within a few
## metres of a path by chance still has most of its disc survive as a
## crescent hugging the near edge of what's left — and because the path is
## straight over a real distance, one ordinary clump's own crescent reads
## as a hedge/row paralleling the path, not a placement bug at all.
## Confirmed against real placement data before writing this: the two
## frames a blind critic named (`grandpas-house-route.png`,
## `the-rise-route.png`) each had exactly one or two grass/drygrass clump
## CENTRES sitting 2-4m from the nearest path, nowhere near enough of them
## to be "several clumps chaining into a band" — one clump is already
## enough at this radius. Resamples the unbiased draw (never touches a
## clump `path_bias` already snapped this pass) until it lands outside the
## radius or the attempt budget runs out, so an incidental near-path clump
## becomes a rare miss instead of an always-present border. Defaults to
## 0.0 (no change) — opt in per layer.
const PATH_AVOID_ATTEMPTS := 4

static func _clump_centre(
	rng: RandomNumberGenerator, half: float, field: RefCounted, ridge_bias: float,
	path_bias: float = 0.0, path_bias_jitter: float = 0.0, path_avoid_radius: float = 0.0
) -> Vector2:
	var base := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
	var snapped_to_path := false

	if path_bias > 0.0 and rng.randf() <= path_bias and field.has_method("nearest_point_on_paths"):
		var on_path: Vector2 = field.nearest_point_on_paths(base.x, base.y)
		if on_path != Vector2.INF:
			if path_bias_jitter > 0.0:
				var nudge := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
				on_path += nudge * path_bias_jitter
			base = on_path
			snapped_to_path = true

	if not snapped_to_path and path_avoid_radius > 0.0 and field.has_method("nearest_point_on_paths"):
		for attempt in PATH_AVOID_ATTEMPTS:
			var nearest: Vector2 = field.nearest_point_on_paths(base.x, base.y)
			if nearest == Vector2.INF or base.distance_to(nearest) >= path_avoid_radius:
				break
			base = Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))

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
	#
	# `path_edge_jitter` (EV3-remainder-2): a fixed 0.3 cutoff draws the exact
	# same isoline everywhere `path_factor` is evaluated, which is fine beside
	# one winding path but not where several straight routes meet at one
	# point — `terrain_playground.json`'s four routes all share a single
	# endpoint at the village well, so the vegetation-clear wedge each one
	# cuts reads as a geometric fan converging on it, across every ground-
	# cover layer at once, not a placement bug in any one of them. A blind
	# critic read the result as "a planted crop field." Jittering the cutoff
	# PER INSTANCE (not touching `path_factor` itself, which the terrain's
	# own dirt-texture blend also reads — see build_playground_terrain.gd —
	# so it stays exactly as tuned) ravels the edge into an irregular fringe
	# instead of a single straight isoline, the same fix shape as a coastline
	# needing noise, not more coastline. TUNABLE, defaults to 0.0 (no change)
	# so layers that never sit near a multi-path junction are unaffected.
	if not bool(layer.get("grows_on_paths", false)) and field.has_method("path_factor"):
		var edge_jitter := float(layer.get("path_edge_jitter", 0.0))
		var threshold := 0.3
		if edge_jitter > 0.0:
			threshold += rng.randf_range(-edge_jitter, edge_jitter)
		if float(field.path_factor(spot.x, spot.y)) > threshold:
			return

	# `base_scale` corrects the pack's authoring scale for the whole layer;
	# scale_min/max then vary around it. Two numbers rather than one so "the
	# trees are too small" and "the trees are all the same size" stay separate
	# complaints with separate fixes.
	var base := float(layer.get("base_scale", 1.0))
	var low := float(layer.get("scale_min", 0.85)) * base
	var high := float(layer.get("scale_max", 1.25)) * base
	var placement := {
		"model": str(models[rng.randi_range(0, models.size() - 1)]),
		"position": Vector3(spot.x, height, spot.y),
		"yaw": rng.randf_range(0.0, TAU),
		"scale": rng.randf_range(low, high),
	}
	# Rigid props (currently just rocks, the one layer with a MINIMUM slope)
	# rest flush with the ground they're placed on rather than standing
	# bolt-upright on it. A single centre-point height sample already handles
	# a small prop on flat ground, but a wide rock deliberately biased toward
	# slopes (min_slope_deg above) has a footprint the sample point knows
	# nothing about — the downhill side hangs in the air with a visible gap
	# under it. Plants stay world-up on purpose: a tree tilts toward the sun,
	# not the slope, so this is opt-in per layer rather than automatic.
	if bool(layer.get("align_to_slope", false)):
		placement["normal"] = field.normal_at(spot.x, spot.y)
	out.append(placement)


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
