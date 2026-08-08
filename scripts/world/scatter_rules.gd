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
## The build kit's own measurements — 2m cell, 3m storey. Read, never written:
## D12 established that these are measured off the art pack's glTF accessors
## rather than chosen, so the settlement quotes them instead of restating them.
## If the kit is ever replaced, the village follows it without an edit here.
const GRID := preload("res://scripts/building/build_grid.gd")
const CONFIG_PATH := "res://data/config/vegetation.json"
const SETTLEMENT_PATH := "res://data/config/settlement.json"
const TRAILS_PATH := "res://data/config/trails.json"
const PIECES_PATH := "res://data/building/pieces.json"

static var _config: Dictionary = {}
static var _settlement: Dictionary = {}
static var _trails: Dictionary = {}
static var _pieces: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	_config = _read(CONFIG_PATH, "vegetation.json")
	return _config


## The authored architecture: what stands where, in grid coordinates.
static func settlement() -> Dictionary:
	if not _settlement.is_empty():
		return _settlement
	_settlement = _read(SETTLEMENT_PATH, "settlement.json")
	return _settlement


## The authored routes. One source of truth for the trail, because three
## different things need it and they must agree to the metre: the bake paints
## the track into the ground colour, the path stones are laid along it, and the
## grass layers refuse to grow on it. Three copies of a polyline is three
## polylines the moment anybody moves one.
static func trails() -> Dictionary:
	if not _trails.is_empty():
		return _trails
	_trails = _read(TRAILS_PATH, "trails.json")
	return _trails


## The build catalogue, READ ONLY. This is the same file the player's build mode
## places from, which is the whole argument for authoring the world's
## architecture out of it: the kit the player builds with and the kit the world
## is built from being the same kit is why a house they raise beside Grandpa's
## looks like it belongs there.
static func pieces() -> Dictionary:
	if not _pieces.is_empty():
		return _pieces
	_pieces = _read(PIECES_PATH, "pieces.json").get("pieces", {})
	return _pieces


static func _read(path: String, label: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("%s missing at %s" % [label, path])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Route waypoints, parsed once and kept. `allowed()` asks for the trail on every
## candidate placement in every ground-cover layer — tens of thousands of times
## per build — and rebuilding a fifteen-point array each time is the kind of cost
## that only shows up as the world taking a second longer to appear.
static var _route_points: Dictionary = {}


## The named route's waypoints, in world metres.
static func trail_points(name: String) -> Array[Vector2]:
	if _route_points.has(name):
		return _route_points[name]
	var out: Array[Vector2] = []
	var route: Dictionary = trails().get("routes", {}).get(name, {})
	for entry: Variant in route.get("points", []):
		var at: Array = entry
		out.append(Vector2(float(at[0]), float(at[1])))
	_route_points[name] = out
	return out


## Metres from the nearest point on a named route's polyline.
static func distance_to_trail(name: String, spot: Vector2) -> float:
	var points := trail_points(name)
	if points.size() < 2:
		return INF
	var best := INF
	for i in range(points.size() - 1):
		var a := points[i]
		var span := points[i + 1] - a
		var length_squared := span.length_squared()
		var t := 0.0 if length_squared <= 0.0 else clampf((spot - a).dot(span) / length_squared, 0.0, 1.0)
		best = minf(best, spot.distance_to(a + span * t))
	return best


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
	# Nothing grows on a trodden path. This is what turns a line of stones into
	# a track: the stones alone read as a decorative border laid THROUGH the
	# meadow, because the meadow closes over them from both sides and there is
	# no bare ground anywhere along it. A path is defined by the absence of
	# vegetation at least as much as by what is laid on it.
	if spot != Vector2.INF and float(layer.get("off_trail", 0.0)) > 0.0:
		for name: String in trails().get("routes", {}).keys():
			if name.begins_with("_"):
				continue
			if distance_to_trail(name, spot) < float(layer["off_trail"]):
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
	# THE HANDHELD DIAL. Ground cover is the layer whose count actually matters
	# on a ROG Ally — everything else in the meadow is in the low thousands and
	# this is in the tens of thousands — so the layers that carry it are marked
	# `density_scaled` and one number in vegetation.json moves all of them
	# together. It is a presentation tunable and nothing reads it but this.
	var density := 1.0 if not bool(layer.get("density_scaled", false)) \
		else maxf(0.0, float(config().get("ground_cover_density", 1.0)))
	var clumps := int(layer.get("clumps", 20))
	var per_clump: int = maxi(0, int(round(float(layer.get("per_clump", 12)) * density)))
	var spread := float(layer.get("clump_radius", 14.0))
	var strays: int = maxi(0, int(round(float(layer.get("strays", 0)) * density)))

	# AUTHORED clump centres, when the layer states them.
	#
	# This is the line between the two halves of GAME_DESIGN.md §7. Where a wood
	# goes is macro geography and belongs to whoever is composing the region;
	# which tree stands where inside it is dressing and belongs to a rule. A
	# random clump centre gives you trees in a group, which is not the same thing
	# as a GROVE — a grove is a place, it has a name, the road goes through it,
	# and it is still there when the seed changes.
	##
	## Authored centres come FIRST and rule-based ones fill in after, so a layer
	## can be both: the wood by the grove is where somebody put it, and the other
	## eleven copses are wherever the seed likes. `clumps` is still the total.
	var authored: Array = layer.get("clump_at", [])
	clumps = maxi(clumps, authored.size())

	for clump in clumps:
		# The rng is consumed either way, so adding an authored centre does not
		# reshuffle the copses that follow it.
		var centre := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))
		if clump < authored.size():
			var at: Array = authored[clump]
			centre = Vector2(float(at[0]), float(at[1]))
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
	# SCALE IS BIASED SMALL. A uniform draw between two limits gives a population
	# clustered around the middle, which is how a stand of trees ends up "at
	# uniform height" even with a 2:1 range configured — the extremes are rare and
	# the eye reads the mode. Squaring the sample makes small the common case and
	# large the exception, which is the size distribution a real wood has: a lot
	# of saplings, a few giants. `size_bias` 1.0 restores the old uniform draw.
	var bias := maxf(0.05, float(layer.get("size_bias", 1.0)))
	var pick: float = pow(rng.randf(), bias)
	# A LEAN. Nothing in a meadow stands perfectly plumb, and every tree in this
	# one did. Degrees of tilt off vertical, about a random horizontal axis.
	# `lean_min_deg` is what turns the same mechanism into FALLEN TIMBER: a dead
	# trunk at 70-100 degrees is lying on the ground, and a grove floor with logs
	# on it is a place rather than a tree density.
	var lean := deg_to_rad(float(layer.get("lean_deg", 0.0)))
	var lean_min := deg_to_rad(float(layer.get("lean_min_deg", 0.0)))
	out.append({
		"model": str(models[rng.randi_range(0, models.size() - 1)]),
		"position": Vector3(spot.x, height, spot.y),
		"yaw": rng.randf_range(0.0, TAU),
		"scale": lerpf(low, high, pick),
		"tilt": 0.0 if lean <= 0.0 else rng.randf_range(lean_min, lean) * (1.0 if rng.randf() < 0.5 else -1.0),
		"tilt_dir": rng.randf_range(0.0, TAU),
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
		if layer.has("sites"):
			built[name] = buildings_for(layer, field)
		elif layer.has("at"):
			built[name] = authored_for(layer, field)
		elif layer.has("route") or layer.has("route_from"):
			built[name] = route_for(layer, field, world_size, base_seed + offset * 7919)
		else:
			built[name] = placements_for(layer, field, world_size, base_seed + offset * 7919)
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
	# `route_from` names a route in trails.json instead of restating one. The
	# trail is drawn by three different systems and they have to agree to the
	# metre or the path stones sit beside the painted track rather than on it.
	var points: Array[Vector2] = trail_points(str(layer.get("route_from", ""))) \
		if layer.has("route_from") else []
	if points.is_empty():
		for entry: Variant in layer.get("route", []):
			var at: Array = entry
			points.append(Vector2(float(at[0]), float(at[1])))
	if models.is_empty() or points.size() < 2:
		return out

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var half := world_size * 0.5
	var spacing := float(layer.get("route_spacing", 1.6))
	var width := float(layer.get("route_width", 1.5))
	var per_step := int(layer.get("route_per_step", 2))
	var align := bool(layer.get("route_align", false))

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
				var before := out.size()
				_consider(out, layer, field, models, spot, half, rng)
				# A fence panel is a flat 2m board, and a random yaw turns a
				# fence into scattered planks. Stones want the random yaw and
				# panels want the path's heading, so it is a per-layer choice
				# rather than a rule about routes.
				if align and out.size() > before:
					var heading := ahead - centre
					if heading != Vector2.ZERO:
						out[out.size() - 1]["yaw"] = atan2(heading.x, heading.y)
	return out


## Individually placed objects, exactly where somebody put them.
##
## The third and last layer type, and the only one with no randomness in it at
## all. A landmark is not a density and it is not a line — it is one object, in
## one place, chosen because that is where it should be. A wagon that lands
## somewhere different each seed is not a landmark; it is litter.
##
## Only the HEIGHT is computed, from the field, so an authored landmark sits on
## the ground rather than needing its elevation typed in and retyped every time
## the terrain moves. Everything else — position, facing, size — is stated.
static func authored_for(layer: Dictionary, field: RefCounted) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var base := float(layer.get("base_scale", 1.0))
	# The spawn clearance is enforced here rather than through `allowed()`,
	# because none of `allowed()`'s other questions mean anything for an authored
	# object: it is on a slope because somebody chose that slope. But the spawn
	# pad still has to stay clear, and "the coordinates are typed by hand so it
	# will be fine" is precisely the assumption that puts a wagon on top of the
	# player one refactor later.
	var clear := float(layer.get("clear_radius", 0.0))
	for entry: Variant in layer.get("at", []):
		var item: Dictionary = entry
		var spot := Vector2(float(item.get("x", 0.0)), float(item.get("z", 0.0)))
		if spot.length() < clear:
			push_warning("authored landmark '%s' is inside the spawn clearing" % item.get("model", "?"))
			continue
		var height: float = field.height_at(spot.x, spot.y)
		if is_nan(height):
			push_warning("authored landmark '%s' is off the terrain" % item.get("model", "?"))
			continue
		out.append({
			"model": str(item.get("model", "")),
			"position": Vector3(spot.x, height + float(item.get("lift", 0.0)), spot.y),
			"yaw": deg_to_rad(float(item.get("yaw_deg", 0.0))),
			"scale": float(item.get("scale", 1.0)) * base,
		})
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


## ---------------------------------------------------------------------------
## Authored architecture
## ---------------------------------------------------------------------------
##
## The fourth and last layer type. Scatter answers "how much of this and where
## is it allowed", a route answers "from here to there", a landmark answers
## "this one object, exactly here" — and a building answers none of those. A
## building is a set of pieces in a fixed relationship to each other, and the
## only coordinates worth writing down for one are the grid's.
##
## So `data/config/settlement.json` states sites in CELLS and piece ids, and
## this expands them. Two consequences worth stating, because both were the
## reason for doing it this way:
##
##   * The world's architecture and the player's build kit are the same 28
##     pieces from `data/building/pieces.json`, read here and never written. A
##     cabin the player raises next to Grandpa's is made of the same walls, so
##     it belongs there. Nothing in `scripts/building/` is touched.
##   * A building is one draw call per distinct piece across the WHOLE
##     settlement, because the renderer batches by mesh. Four cottages, a
##     gatehouse and a fort perimeter cost about as much as one cottage.
##
## A site takes ONE ground height, sampled at its own origin. Buildings do not
## drape. Every site stands on a levelled pad in `terrain_playground.json`, and
## the pad's target height is read from the same heightfield, so the two cannot
## drift apart.
static func buildings_for(layer: Dictionary, field: RefCounted) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var sites: Dictionary = settlement().get("sites", {})
	var clear := float(layer.get("clear_radius", 0.0))
	for entry: Variant in layer.get("sites", []):
		var name := str(entry)
		if not sites.has(name):
			push_warning("settlement.json has no site called '%s'" % name)
			continue
		var site: Dictionary = sites[name]
		var at: Array = site.get("origin", [0.0, 0.0])
		var origin := Vector2(float(at[0]), float(at[1]))
		# Same guard as an authored landmark, and for the same reason: the
		# coordinates are typed by hand, and "typed by hand so it will be fine"
		# is how a wall ends up through the player's spawn one edit later.
		if origin.length() < clear:
			push_warning("site '%s' is inside the spawn clearing" % name)
			continue
		var ground: float = field.height_at(origin.x, origin.y)
		if is_nan(ground):
			push_warning("site '%s' is off the terrain" % name)
			continue
		_expand_site(out, site, origin, ground + float(site.get("lift", 0.0)))
	return out


static func _expand_site(
	out: Array[Dictionary], site: Dictionary, origin: Vector2, ground: float
) -> void:
	var yaw := deg_to_rad(float(site.get("yaw_deg", 0.0)))
	var local: Array[Dictionary] = []
	for entry: Variant in site.get("rooms", []):
		_expand_room(local, entry)
	for entry: Variant in site.get("runs", []):
		_expand_run(local, entry)
	for entry: Variant in site.get("props", []):
		_expand_prop(local, entry)

	# GODOT'S handedness, not the textbook 2D one. `Basis(Vector3.UP, yaw)` is a
	# right-handed rotation about +Y, so local +Z swings toward +X and local +X
	# swings toward -Z. The renderer turns each piece with that basis; if the
	# LAYOUT were turned with the textbook (cos, sin / -sin, cos) matrix instead,
	# the two would disagree in the sign of Z and every rotated building would
	# come out mirrored — walls on the outside of the floors they bound, the door
	# on the wrong face. Which reads as a placement bug and is not one.
	var turn_cos := cos(yaw)
	var turn_sin := sin(yaw)
	for piece: Dictionary in local:
		var flat: Vector2 = piece["at"]
		# Rotate the whole site about its origin, so a cottage can face the
		# trail without every piece in it being re-authored.
		var turned := Vector2(
			flat.x * turn_cos + flat.y * turn_sin,
			-flat.x * turn_sin + flat.y * turn_cos
		)
		out.append({
			"model": str(piece["model"]),
			"position": Vector3(origin.x + turned.x, ground + float(piece["y"]), origin.y + turned.y),
			"yaw": float(piece["yaw"]) + yaw,
			"scale": float(piece.get("scale", 1.0)),
		})


## An enclosed building: floors, a perimeter of walls with one doorway and some
## windows, and a roof over the lot.
##
## The layout rule is the same one `tools/preview_build.gd` proves in a picture:
## every cell gets a floor, every cell edge that is NOT shared with another cell
## of the same room gets a wall, and the roof goes at the room's centre one
## storey up. Interior edges are skipped or the room comes out subdivided.
static func _expand_room(out: Array[Dictionary], entry: Variant) -> void:
	var room: Dictionary = entry
	var cells := Vector2i(
		int((room.get("cells", [1, 1]) as Array)[0]),
		int((room.get("cells", [1, 1]) as Array)[1])
	)
	if cells.x < 1 or cells.y < 1:
		return
	var base := Vector2(
		float((room.get("at", [0.0, 0.0]) as Array)[0]),
		float((room.get("at", [0.0, 0.0]) as Array)[1])
	)
	var storeys: int = maxi(1, int(room.get("storeys", 1)))
	var wall := str(room.get("wall", "wall_plaster_straight"))
	var window := str(room.get("window", ""))
	var door := str(room.get("door", ""))
	var leaf := str(room.get("door_leaf", ""))
	var door_side := str(room.get("door_side", "south"))
	var door_index := int(room.get("door_index", cells.x / 2))
	var floor_piece := str(room.get("floor", ""))
	var roof := str(room.get("roof", ""))
	var walls_only := bool(room.get("walls_only", false))

	const SIDES := {
		"east": Vector2i(1, 0), "west": Vector2i(-1, 0),
		"north": Vector2i(0, 1), "south": Vector2i(0, -1),
	}

	for storey in storeys:
		var lift: float = float(storey) * GRID.STOREY
		for cx in cells.x:
			for cz in cells.y:
				var centre := base + Vector2(float(cx) * GRID.CELL, float(cz) * GRID.CELL)
				if storey == 0 and floor_piece != "" and not walls_only:
					_emit(out, floor_piece, centre, 0.0, lift)
				for key: String in SIDES.keys():
					var side: Vector2i = SIDES[key]
					var neighbour := Vector2i(cx + side.x, cz + side.y)
					if neighbour.x >= 0 and neighbour.x < cells.x \
							and neighbour.y >= 0 and neighbour.y < cells.y:
						continue
					var along := cx if side.y != 0 else cz
					var piece := wall
					if storey == 0 and door != "" and key == door_side and along == door_index:
						piece = door
					elif window != "" and (cx + cz + storey) % 2 == 0:
						piece = window
					var spot := centre + Vector2(float(side.x), float(side.y)) * (GRID.CELL * 0.5)
					# A wall lying on an X-facing edge runs along Z. That is not
					# a preference, it is what the kit's own origin means, and
					# getting it wrong puts every wall half a cell out and reads
					# as a rotation bug (D12).
					var facing: float = PI * 0.5 if side.x != 0 else 0.0
					_emit(out, piece, spot, facing, lift)
					# The kit splits a doorway into the WALL WITH A HOLE IN IT and
					# the door that hangs in it, and they are two separate pieces
					# on the same edge. Placing only the first gives a cottage
					# with a dark rectangle where its front door should be, which
					# is what the first render of Grandpa's house showed.
					if piece == door and leaf != "":
						_emit(out, leaf, spot, facing, lift)

	if roof != "" and not walls_only:
		var centre := base + Vector2(
			float(cells.x - 1) * GRID.CELL * 0.5,
			float(cells.y - 1) * GRID.CELL * 0.5
		)
		# THE ROOF SITS ON TOP OF THE WALL, not part-way down it.
		#
		# The kit's roofs hang 0.78m below their own origin, so a roof placed at
		# storey height puts its eave at 2.22m over a wall that draws to 3.12m —
		# the top third of every wall in the settlement was inside the roof, and
		# what was left read as a wall band one third of the roof's pitch. That is
		# exactly the "the cottage is 2.5m tall and the eave is at his chest"
		# reading in MA-05: the buildings are not small, they are 72% roof.
		#
		# `roof_lift` raises the roof so the eave meets the wall top. Nothing about
		# the grid moves — the walls are still 2m pieces on a 3m storey (D12) — and
		# the ridge goes from 7.9m to 8.8m as a consequence rather than as a scale
		# multiplier.
		var top: float = float(storeys) * GRID.STOREY + float(room.get("roof_lift", 0.0))
		_emit(out, roof, centre, 0.0, top)
		# A SECOND ROOF, slightly smaller, directly inside the first.
		#
		# The tile rows in `Roof_RoundTiles_*` do not quite meet, and terrain shows
		# through the seams across whole roofs — the most visible artefact in the
		# survey at full size. The mesh is not ours to edit and the gaps are
		# geometric, not a sorting problem, so this backs them with roof instead of
		# with meadow. A gable roof is star-shaped about its own centre, so a
		# uniform shrink about that point lies strictly inside the shell; the
		# shrink is a few centimetres of offset, which is more than the seams are
		# wide, so the two sets of gaps cannot line up.
		var under := float(room.get("roof_underlay", 0.0))
		if under > 0.0:
			_emit(out, roof, centre, 0.0, top, 1.0 - under)

		# AND A CEILING, because the shrunken roof alone does not finish the job.
		#
		# A uniform shrink moves a seam at radius r by r*(1-s), so the offset
		# between the two shells' seams is proportional to distance from the
		# centre — it lands on half a tile pitch at one radius and back on zero at
		# another. Measured in the render: most seams closed, a band of them still
		# showed grass. There is no single scale that misaligns a periodic pattern
		# everywhere.
		#
		# A floor laid across the room at the wall top is not periodic and not
		# nearly-parallel to the line of sight. Any seam over the room now shows
		# floorboards. It costs nine instances in a batch these buildings already
		# have, and it is what a real house has under its rafters anyway.
		if bool(room.get("ceiling", false)) and floor_piece != "":
			for cx in cells.x:
				for cz in cells.y:
					_emit(
						out, floor_piece,
						base + Vector2(float(cx) * GRID.CELL, float(cz) * GRID.CELL),
						0.0, float(storeys) * GRID.STOREY
					)


## A straight run of pieces: a stretch of curtain wall, a garden fence, a
## palisade. Whatever a room's perimeter rule would give you all four sides of
## when you wanted one.
static func _expand_run(out: Array[Dictionary], entry: Variant) -> void:
	var run: Dictionary = entry
	var piece := str(run.get("piece", ""))
	var count: int = maxi(0, int(run.get("count", 0)))
	if piece == "" or count == 0:
		return
	var start := Vector2(
		float((run.get("from", [0.0, 0.0]) as Array)[0]),
		float((run.get("from", [0.0, 0.0]) as Array)[1])
	)
	var along_x := str(run.get("axis", "x")) == "x"
	var step := float(run.get("spacing", GRID.CELL))
	var storeys: int = maxi(1, int(run.get("storeys", 1)))
	var direction := Vector2(step, 0.0) if along_x else Vector2(0.0, step)
	# A run along X is a wall standing across X, so its edge faces Z: yaw 0.
	var yaw: float = 0.0 if along_x else PI * 0.5
	for storey in storeys:
		for i in count:
			_emit(out, piece, start + direction * float(i), yaw, float(storey) * GRID.STOREY)


## One stated object. Either a catalogue piece by id, or a raw model path for
## the props that are not build pieces at all — a wagon, a crate, a boulder
## standing in for a monolith.
static func _expand_prop(out: Array[Dictionary], entry: Variant) -> void:
	var prop: Dictionary = entry
	var at := Vector2(
		float((prop.get("at", [0.0, 0.0]) as Array)[0]),
		float((prop.get("at", [0.0, 0.0]) as Array)[1])
	)
	var model := str(prop.get("model", ""))
	if model == "":
		model = str(pieces().get(str(prop.get("piece", "")), {}).get("model", ""))
	if model == "":
		push_warning("settlement prop names neither a model nor a known piece: %s" % prop)
		return
	out.append({
		"model": model,
		"at": at,
		"y": float(prop.get("lift", 0.0)),
		"yaw": deg_to_rad(float(prop.get("yaw_deg", 0.0))),
		"scale": float(prop.get("scale", 1.0)),
	})


static func _emit(
	out: Array[Dictionary], piece_id: String, at: Vector2, yaw: float,
	lift: float, scale: float = 1.0
) -> void:
	var piece: Dictionary = pieces().get(piece_id, {})
	var model := str(piece.get("model", ""))
	if model == "":
		push_warning("settlement names a piece the catalogue does not have: '%s'" % piece_id)
		return
	out.append({"model": model, "at": at, "y": lift, "yaw": yaw, "scale": scale})
