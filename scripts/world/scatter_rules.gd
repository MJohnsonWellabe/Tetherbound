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

	for clump in clumps:
		var centre := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
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
	# Two passes, because a skirt layer needs the layer it skirts to exist first
	# and dictionary order is not a dependency graph.
	for name: String in layers.keys():
		var layer_cfg: Dictionary = layers[name] if not name.begins_with("_") else {}
		if name.begins_with("_") or layer_cfg.has("skirt_of"):
			continue
		var layer: Dictionary = layers[name]
		built[name] = route_for(layer, field, world_size, base_seed + offset * 7919) \
			if layer.has("route") \
			else placements_for(layer, field, world_size, base_seed + offset * 7919)
		offset += 1
	for name: String in layers.keys():
		if name.begins_with("_") or not (layers[name] as Dictionary).has("skirt_of"):
			continue
		var layer: Dictionary = layers[name]
		built[name] = skirt_for(layer, built, field, world_size, base_seed + offset * 7919)
		offset += 1
	return built


## Stones laid along an authored line, rather than sprinkled over an area.
##
## A path is the one thing in this file that a density cannot produce. Every
## other layer answers "how much of this, and where is it allowed" — a path
## answers "from here, to there, past that", and no amount of tuning clumps and
## strays gets you a line. `path_stones` had been a scatter with a comment
## admitting as much: *"Not a path yet."*
##
## It matters because the references all use one compositionally. A path is what
## tells the eye where to enter a landscape and where it is being led, and the
## critic's third-ranked gap was that its frames give the eye nothing to do.
##
## The waypoints are world coordinates in config, authored against the terrain's
## own geography — this is the same argument as the terrain itself being authored
## rather than seeded. What is randomised is only the scatter ACROSS the path:
## how far each stone strays from the centre line, its yaw and its size, so the
## result reads as trodden rather than as tiling.
##
## Catmull-Rom through the waypoints, so a path bends rather than turning
## corners. Height comes from the field at every stone, so it drapes over the
## ground it crosses instead of cutting through hills.
static func route_for(
	layer: Dictionary, field: RefCounted, world_size: float, seed_value: int
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var models: Array = layer.get("models", [])
	var route: Array = layer.get("route", [])
	if models.is_empty() or route.size() < 2:
		return out

	var points: Array[Vector2] = []
	for entry: Variant in route:
		var at: Array = entry
		points.append(Vector2(float(at[0]), float(at[1])))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var half := world_size * 0.5
	var spacing := float(layer.get("route_spacing", 1.6))
	var width := float(layer.get("route_width", 1.5))
	var per_step := int(layer.get("route_per_step", 2))

	# Duplicated ends give Catmull-Rom the control points it needs at the
	# extremities without inventing a curve beyond them.
	var control: Array[Vector2] = [points[0]]
	control.append_array(points)
	control.append(points[points.size() - 1])

	for segment in control.size() - 3:
		var a: Vector2 = control[segment]
		var b: Vector2 = control[segment + 1]
		var c: Vector2 = control[segment + 2]
		var d: Vector2 = control[segment + 3]
		# Steps sized from the straight-line length, so a long span gets more
		# stones than a short one instead of every segment getting the same count.
		var steps: int = maxi(2, int(b.distance_to(c) / spacing))
		for step in steps:
			var t := float(step) / float(steps)
			var centre := _spline(a, b, c, d, t)
			var ahead := _spline(a, b, c, d, minf(1.0, t + 0.01))
			var across := (ahead - centre).orthogonal().normalized()
			if across == Vector2.ZERO:
				continue
			for i in per_step:
				# Across the path, not along it: the line is authored and only
				# the wander off it is random.
				var spot := centre + across * rng.randf_range(-width, width)
				_consider(out, layer, field, models, spot, half, rng)
	return out


## Catmull-Rom, so the path bends through its waypoints instead of turning
## corners at them. A path made of straight segments reads as a survey line.
static func _spline(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		2.0 * b
		+ (c - a) * t
		+ (2.0 * a - 5.0 * b + 4.0 * c - d) * t2
		+ (-a + 3.0 * b - 3.0 * c + d) * t3
	)


## Small growth banked around the base of something else.
##
## The critic's artefact list included, for four frames running: *"trunks meet
## the ground with a straight cut, no root flare, no AO, no tuft"*. A tree model
## ends at a flat disc where its trunk was cut off, and a scatter that places
## trees independently of ferns will only ever put a fern near a trunk by luck.
##
## So this layer type does not scatter at all — it reads another layer's
## placements and rings each one. That is the difference between "there is
## sometimes a plant near a tree" and "every tree has something growing out of
## its base", and only the second one reads as a root flare.
##
## Placed in an ANNULUS, not a disc: `skirt_inner` keeps the tufts off the trunk
## itself, where they would be swallowed by it and cost their draw call for
## nothing. The ring scales with the tree, so a big one gets a wide skirt.
static func skirt_for(
	layer: Dictionary, built: Dictionary, field: RefCounted, world_size: float, seed_value: int
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var models: Array = layer.get("models", [])
	var source: Array = built.get(str(layer.get("skirt_of", "")), [])
	if models.is_empty() or source.is_empty():
		return out

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var half := world_size * 0.5
	var per := int(layer.get("skirt_count", 4))
	var inner := float(layer.get("skirt_inner", 0.35))
	var outer := float(layer.get("skirt_outer", 1.1))
	var chance := float(layer.get("skirt_chance", 1.0))

	for entry: Variant in source:
		var host: Dictionary = entry
		if rng.randf() > chance:
			continue
		# The host's own scale sets the ring, so the skirt fits the tree it
		# belongs to rather than being one size for a layer whose members vary
		# by 40%.
		var host_scale := float(host.get("scale", 1.0))
		var at: Vector3 = host["position"]
		for i in per:
			var angle := rng.randf_range(0.0, TAU)
			var radius := rng.randf_range(inner, outer) * host_scale
			var spot := Vector2(at.x, at.z) + Vector2(sin(angle), cos(angle)) * radius
			_consider(out, layer, field, models, spot, half, rng)
	return out
