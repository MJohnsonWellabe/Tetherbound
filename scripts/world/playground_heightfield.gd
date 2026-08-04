extends RefCounted

## The Meadows' shape, as a pure function of position.
##
## Separated from the Terrain3D import so it can be unit tested without the
## engine's terrain system, and so the same recipe can be re-baked at a
## different resolution without touching the importer.
##
## Everything here is AUTHORED MACRO GEOGRAPHY expressed as a recipe, not a
## world generator. Two layers of noise supply the rolling break-up that hand
## sculpting would take a week to fake, and every feature that a player can
## navigate by — the basin, the rises, the stronghold bluff, the brook, the
## terraces the settlement stands on — is a named entry in
## `data/config/terrain_playground.json` with coordinates somebody chose.
## Nothing calls this at runtime; `build_playground_terrain.gd` bakes it to disk
## once. See docs/decisions/D05-terrain3d-and-authored-geography.md.
##
## The order features are applied in is the order the land was made in, and it
## matters:
##
##   noise -> valley -> rises -> channels (cut) -> pads (level)
##
## Channels only ever CUT and pads always WIN. A brook cannot fill a hollow it
## crosses, and a terrace under a house is flat no matter what the noise wanted,
## because a building placed on a "mostly flat" pad has one corner in the air.

const CONFIG_PATH := "res://data/config/terrain_playground.json"

var _config: Dictionary = {}
var _hills := FastNoiseLite.new()
var _detail := FastNoiseLite.new()

## Stream beds, resolved once: each entry is `{points, bed, half_width, bank}`
## where `bed[i]` is the carved floor height at `points[i]`. Precomputed because
## the bed profile has to DESCEND along the route, and "descending" is a property
## of the whole route rather than of a point — it cannot be evaluated inside
## `height_at`, which only ever sees one position.
var _channels: Array = []


func _init(config: Dictionary = {}) -> void:
	_config = config if not config.is_empty() else load_config()

	var seed_value := int(_config.get("seed", 0))
	var hills: Dictionary = _config.get("hills", {})
	var detail: Dictionary = _config.get("detail", {})

	_hills.seed = seed_value
	_hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hills.fractal_type = FastNoiseLite.FRACTAL_FBM
	_hills.frequency = float(hills.get("frequency", 0.0035))
	_hills.fractal_octaves = int(hills.get("octaves", 4))

	# A different seed, or the two layers share their peaks and the detail
	# reinforces the hills instead of breaking them up.
	_detail.seed = seed_value + 1
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_type = FastNoiseLite.FRACTAL_FBM
	_detail.frequency = float(detail.get("frequency", 0.018))
	_detail.fractal_octaves = int(detail.get("octaves", 3))

	_resolve_channels()


static func load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("terrain_playground.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Ground height in metres at a world XZ position.
func height_at(x: float, z: float) -> float:
	var height := _raw_height(x, z)
	height = _apply_channels(x, z, height)
	height = _apply_spawn_pad(x, z, height)
	height = _apply_pads(x, z, height)
	return height


func _valley_depth(x: float, z: float) -> float:
	var valley: Dictionary = _config.get("valley", {})
	if valley.is_empty():
		return 0.0
	var centre: Array = valley.get("centre", [0.0, 0.0])
	var radius := float(valley.get("radius", 150.0))
	if radius <= 0.0:
		return 0.0
	var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
	if distance >= radius:
		return 0.0
	# smoothstep rather than a linear cone, so the basin has no crease at its rim.
	var falloff := 1.0 - smoothstep(0.0, 1.0, distance / radius)
	return falloff * float(valley.get("depth", 22.0))


func _rise_height(x: float, z: float) -> float:
	var rises: Dictionary = _config.get("rises", {})
	var peaks: Array = rises.get("peaks", [])
	var default_sharpness := float(rises.get("sharpness", 2.1))
	var total := 0.0
	for entry: Variant in peaks:
		var peak: Dictionary = entry
		var centre: Array = peak.get("centre", [0.0, 0.0])
		var radius := float(peak.get("radius", 60.0))
		if radius <= 0.0:
			continue
		var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
		if distance >= radius:
			continue
		var sharpness := float(peak.get("sharpness", default_sharpness))
		var height := float(peak.get("height", 40.0))
		# A `flat_top` peak is a BLUFF rather than a hill: the inner disc is
		# level and the whole rise happens in the annulus outside it. That is
		# what makes the stronghold's crag carry a buildable summit and flanks
		# too steep for the character controller to walk up, which is how the
		# landmark stays a silhouette instead of becoming a place.
		var plateau := clampf(float(peak.get("flat_top", 0.0)), 0.0, 0.95) * radius
		if distance <= plateau:
			total += height
			continue
		var t := 1.0 - ((distance - plateau) / maxf(0.001, radius - plateau))
		# pow above 1 steepens the flanks while keeping the summit rounded,
		# which is what makes these testable slopes rather than smooth domes.
		total += pow(smoothstep(0.0, 1.0, t), 1.0 / sharpness) * height
	return total


## Levelled terraces, for anything that has to stand on flat ground.
##
## A building is the reason this exists. `build_grid.gd` checks the four corners
## of a footprint and refuses a placement over 0.55m of step, and the spawn pad's
## smoothstep-toward-the-centre flattening never actually reaches flat anywhere
## except at the exact centre point — so a house on it has one corner in the air
## and the wall above that corner has a stripe of daylight under it.
##
## So a pad here has TWO radii. Inside `flat_radius` the ground is exactly the
## target height, full stop; from there out to `radius` it blends back to what
## the noise wanted. The result is a yard, which is what a house in a meadow sits
## on anyway.
func _apply_pads(x: float, z: float, height: float) -> float:
	for entry: Variant in _config.get("pads", []):
		var pad: Dictionary = entry
		var centre: Array = pad.get("centre", [0.0, 0.0])
		var radius := float(pad.get("radius", 20.0))
		var flat := minf(float(pad.get("flat_radius", radius * 0.5)), radius)
		if radius <= 0.0:
			continue
		var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
		if distance >= radius:
			continue
		# The target is the RAW height at the pad's own centre unless one is
		# stated, so retuning the hills moves the terrace with them rather than
		# leaving a mesa where a house used to be.
		var target: float = float(pad["level"]) if pad.has("level") \
			else _raw_height(float(centre[0]), float(centre[1]))
		if distance <= flat:
			height = target
			continue
		var t := (distance - flat) / maxf(0.001, radius - flat)
		height = lerpf(target, height, smoothstep(0.0, 1.0, t))
	return height


## Resolve every stream bed once, at construction.
##
## A brook has to run DOWNHILL, and downhill is a property of a route rather
## than of a point: `height_at` is handed one position and cannot know whether
## the ground fifty metres upstream was higher. So the natural ground under each
## waypoint is sampled here, forced into a monotonically falling profile, and
## the result is what the channel cuts to.
##
## `min_fall` is what stops a brook running along a contour and pooling. It is
## metres of drop per metre travelled, so a route that crosses genuinely level
## ground still descends into it — which is why the channel gets deeper as it
## goes and why the water reads as going somewhere.
func _resolve_channels() -> void:
	_channels = []
	for entry: Variant in _config.get("channels", []):
		var channel: Dictionary = entry
		var route: Array = channel.get("route", [])
		if route.size() < 2:
			continue
		var points: Array[Vector2] = []
		for at: Variant in route:
			var pair: Array = at
			points.append(Vector2(float(pair[0]), float(pair[1])))

		var fall := float(channel.get("min_fall", 0.02))
		var bed: Array[float] = []
		bed.append(_raw_height(points[0].x, points[0].y))
		for i in range(1, points.size()):
			var natural := _raw_height(points[i].x, points[i].y)
			var ceiling: float = bed[i - 1] - fall * points[i - 1].distance_to(points[i])
			bed.append(minf(natural, ceiling))

		_channels.append({
			"points": points,
			"bed": bed,
			"half_width": float(channel.get("half_width", 3.0)),
			"bank": float(channel.get("bank", 6.0)),
			"depth": float(channel.get("depth", 1.2)),
		})


## Cut the stream beds into the ground.
##
## Only ever cuts. `min` rather than a blend, because a channel that could also
## RAISE ground would build an aqueduct across every hollow the route crosses,
## and the last twenty metres of this brook run into a basin that is already
## twenty metres below it.
func _apply_channels(x: float, z: float, height: float) -> float:
	for entry: Variant in _channels:
		var channel: Dictionary = entry
		var near: Dictionary = _nearest_on_route(channel, Vector2(x, z))
		var distance: float = near["distance"]
		var half: float = channel["half_width"]
		var bank: float = channel["bank"]
		if distance >= half + bank:
			continue
		var bed: float = float(near["height"]) - float(channel["depth"])
		var cut := bed
		if distance > half:
			cut = lerpf(bed, height, smoothstep(0.0, 1.0, (distance - half) / maxf(0.001, bank)))
		height = minf(height, cut)
	return height


## Closest point on a resolved channel, with the bed height interpolated along
## the segment it landed on.
func _nearest_on_route(channel: Dictionary, spot: Vector2) -> Dictionary:
	var points: Array = channel["points"]
	var bed: Array = channel["bed"]
	var best := INF
	var best_height := 0.0
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var span := b - a
		var length_squared := span.length_squared()
		var t := 0.0 if length_squared <= 0.0 else clampf((spot - a).dot(span) / length_squared, 0.0, 1.0)
		var on := a + span * t
		var distance := spot.distance_to(on)
		if distance < best:
			best = distance
			best_height = lerpf(float(bed[i]), float(bed[i + 1]), t)
	return {"distance": best, "height": best_height}


## The centreline of a resolved channel, sampled every `spacing` metres, at the
## height of the BED this file cut rather than of the ground above it.
##
## Read by `water.gd` to lay a stream surface down that bed, and by the bake to
## paint the shingle along it. Exposed rather than recomputed there so the water
## and the ground it runs in can never disagree about where the brook is or how
## far it has fallen.
func channel_centreline(index: int, spacing: float = 2.0) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if index < 0 or index >= _channels.size():
		return out
	var channel: Dictionary = _channels[index]
	var points: Array = channel["points"]
	var bed: Array = channel["bed"]
	var depth: float = channel["depth"]
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var steps: int = maxi(1, int(a.distance_to(b) / maxf(0.1, spacing)))
		for step in steps:
			var t := float(step) / float(steps)
			var on := a.lerp(b, t)
			out.append(Vector3(on.x, lerpf(float(bed[i]), float(bed[i + 1]), t) - depth, on.y))
	var last: Vector2 = points[points.size() - 1]
	out.append(Vector3(last.x, float(bed[bed.size() - 1]) - depth, last.y))
	return out


func channel_count() -> int:
	return _channels.size()


## Distance in metres from the nearest channel centreline, or INF if there are
## none. Used by the scatter to keep a meadow out of a watercourse.
func distance_to_channel(x: float, z: float) -> float:
	var best := INF
	for entry: Variant in _channels:
		best = minf(best, float(_nearest_on_route(entry, Vector2(x, z))["distance"]))
	return best


func _apply_spawn_pad(x: float, z: float, height: float) -> float:
	var pad: Dictionary = _config.get("spawn_pad", {})
	if pad.is_empty():
		return height
	var centre: Array = pad.get("centre", [0.0, 0.0])
	var radius := float(pad.get("radius", 34.0))
	if radius <= 0.0:
		return height
	var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
	if distance >= radius:
		return height
	# Pull toward the height at the pad's own centre, strongest in the middle.
	var strength := float(pad.get("flatten", 0.85)) * (1.0 - smoothstep(0.0, 1.0, distance / radius))
	var centre_height := _raw_height(float(centre[0]), float(centre[1]))
	return lerpf(height, centre_height, strength)


## The land before anything was done to it: noise, the basin and the rises, with
## no channel cut into it and no terrace levelled out of it.
##
## Used as every pad's own target, so a pad cannot recurse into itself, and as
## the profile a stream bed is measured against, so a channel cannot chase its
## own cut downhill forever.
func _raw_height(x: float, z: float) -> float:
	var hills: Dictionary = _config.get("hills", {})
	var detail: Dictionary = _config.get("detail", {})
	var height := _hills.get_noise_2d(x, z) * float(hills.get("amplitude", 15.0))
	height += _detail.get_noise_2d(x, z) * float(detail.get("amplitude", 2.2))
	height -= _valley_depth(x, z)
	height += _rise_height(x, z)
	return height


## Surface slope in degrees, sampled by central difference. Used to drive the
## ground colour and to sanity-check that the playground actually contains
## slopes worth testing against.
func slope_degrees_at(x: float, z: float, step: float = 1.0) -> float:
	var dx := height_at(x + step, z) - height_at(x - step, z)
	var dz := height_at(x, z + step) - height_at(x, z - step)
	var normal := Vector3(-dx, 2.0 * step, -dz).normalized()
	return rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))
