extends RefCounted

## The M1 playground's shape, as a pure function of position.
##
## Separated from the Terrain3D import so it can be unit tested without the
## engine's terrain system, and so the same recipe can be re-baked at a
## different resolution without touching the importer.
##
## This is a fixed, seeded recipe for ONE authored test area. It is not a world
## generator and nothing calls it at runtime — `build_playground_terrain.gd`
## bakes it to disk once. The real Meadows is authored geography and replaces
## this entirely; see docs/decisions/D05-terrain3d-and-authored-geography.md.

const CONFIG_PATH := "res://data/config/terrain_playground.json"

var _config: Dictionary = {}
var _hills := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _path_edge := FastNoiseLite.new()
var _path_dominant := FastNoiseLite.new()
var _outcrop := FastNoiseLite.new()


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

	# Metres-scale wobble for `path_factor`'s edge, not terrain shape.
	#
	# EV4 round 3: a blind critic reading the baked result at 0.2 frequency /
	# 2 octaves called the edge "jagged, stair-stepped... a technical
	# resolution limit" rather than organic. The bake samples this at the
	# terrain's own 1m vertex spacing (build_playground_terrain.gd), so a
	# ~5m-wavelength wobble (1/0.2) carries real higher-frequency content from
	# the second octave that the 1m grid cannot represent smoothly — it
	# aliases into visible notches instead of a smooth bulge-and-pinch. A
	# longer ~20m wavelength with one octave still reads as organic width
	# variation over one path segment but stays well inside what a 1m grid
	# can resolve cleanly. A third seed so it does not correlate with `_hills`
	# or `_detail`.
	_path_edge.seed = seed_value + 2
	_path_edge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_path_edge.fractal_type = FastNoiseLite.FRACTAL_FBM
	_path_edge.frequency = 0.05
	_path_edge.fractal_octaves = 1

	# EV4-textures: `_path_control` (build_playground_terrain.gd) has to
	# collapse the slope-driven grass/soil/rock blend to a single "dominant"
	# texture wherever a path crosses it, since Terrain3D's control map holds
	# only one base/overlay pair. Doing that with a hard >=0.5 threshold on
	# the blend value flips the dominant texture in exactly one pixel step —
	# the ONLY un-smoothstepped transition in this whole bake — which reads
	# as a clean-edged notch cut into the path's own soft fade band wherever
	# a route climbs through a grass/soil or soil/rock boundary. This field
	# lets that pick dither across the width of the SAME blend_deg transition
	# band the natural ground already uses, instead of snapping on one line.
	# 0.15 frequency (~6.7m wavelength) keeps the dither coarse enough to read
	# as blotchy intermixing rather than pixel-grain noise. A fourth seed so
	# it does not correlate with `_hills`, `_detail` or `_path_edge`.
	_path_dominant.seed = seed_value + 3
	_path_dominant.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_path_dominant.fractal_type = FastNoiseLite.FRACTAL_FBM
	_path_dominant.frequency = 0.15
	_path_dominant.fractal_octaves = 1

	# EV4-hillside-seam-remainder: `_control_for`/`_ground_colour`
	# (build_playground_terrain.gd) pick grass/soil/rock purely from slope, so
	# every rise with a roughly circular cross-section bakes a perfectly
	# circular ring of each material — a "collar," not an authored outcrop, per
	# the round-4 blind critic. A coarse noise field sampled at world XZ and
	# added to the slope BEFORE the band lookup pushes the effective threshold
	# in or out per-region: where it is positive, rock/soil appear at a
	# genuinely lower slope than elsewhere and the band bulges outward into a
	# lobe; where negative, the band recedes and grass or soil holds on
	# longer. ~35m wavelength (frequency 0.03) is bigger than the meandering
	# grain a single outcrop should have but small enough that a 78m-radius
	# rise still shows several distinct lobes around its ring rather than one
	# smooth ellipse. A fifth seed so it does not correlate with any other
	# layer.
	_outcrop.seed = seed_value + 4
	_outcrop.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_outcrop.fractal_type = FastNoiseLite.FRACTAL_FBM
	_outcrop.frequency = float(_config.get("colour", {}).get("outcrop_jitter_frequency", 0.03))
	_outcrop.fractal_octaves = 2


static func load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("terrain_playground.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


## Ground height in metres at a world XZ position.
func height_at(x: float, z: float) -> float:
	var hills: Dictionary = _config.get("hills", {})
	var detail: Dictionary = _config.get("detail", {})

	var height := _hills.get_noise_2d(x, z) * float(hills.get("amplitude", 15.0))
	height += _detail.get_noise_2d(x, z) * float(detail.get("amplitude", 2.2))

	height -= _valley_depth(x, z)
	height += _rise_height(x, z)
	height = _apply_spawn_pad(x, z, height)
	height = _apply_flats(x, z, height)

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
	var sharpness := float(rises.get("sharpness", 2.1))
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
		var t := 1.0 - (distance / radius)
		# pow above 1 steepens the flanks while keeping the summit rounded,
		# which is what makes these testable slopes rather than smooth domes.
		total += pow(smoothstep(0.0, 1.0, t), 1.0 / sharpness) * float(peak.get("height", 40.0))
	return total


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


## Building pads. Unlike the spawn pad's gentle 0.85 pull, these flatten FULLY
## inside `radius` — a barn on an 0.85-flattened slope still tilts, and a
## tilted building reads as a mistake where a tilted tree reads as a tree. The
## `skirt` blends back to natural ground so the pad has no cliff edge.
##
## R7.1-found-2: this used to pick a single winning TARGET by raw weight (the
## strongest pad wins outright, full stop) and blend toward that one alone.
## That is correct for a single pad shading into natural ground, but where
## TWO pads' skirts overlap and their target heights differ, the winner flips
## from one pad to the other at one point, and near that point both weights
## are still close to 1 (deep inside both pads' overlap, not out at the
## fringe) — so the height snapped almost the FULL difference between the two
## targets over centimetres. Grandpa's-house-pad (was 2.2m) and the
## village-square-pad (was 0.6m) leave barely half a metre of open ground
## between their two circles, and that combination measured a live 81-degree
## wall there — the near-vertical earthen bank the survey caught, misread at
## first as a carved path trench or a texture-projection bug; it is neither,
## see DONE.md's R7.1-found-2 entry. Two independent changes fix it: pad
## heights were brought closer together below (2.2/0.6 -> tunable), and
## STRICTLY outside every pad's own radius this now blends the target
## HEIGHTS themselves by relative weight, instead of one winning outright, so
## a point balanced between two different-height pads lands on their
## weighted average rather than snapping to whichever is marginally closer.
## Strictly INSIDE a pad's own radius this still returns that pad's height
## alone, ignoring every other pad completely — the part that has to stay
## exact, since blending in a neighbour's height there is the tilted-barn
## regression the original winner-take-all rule existed to prevent (a
## sequential-blend version of that bug is what `test_the_building_pads_are_
## genuinely_flat` already guards against).
func _apply_flats(x: float, z: float, height: float) -> float:
	var flats: Array = _config.get("flats", [])
	var in_core := false
	var core_fraction := INF
	var core_height := height
	var total_weight := 0.0
	var weighted_target := 0.0
	var max_weight := 0.0
	for entry: Variant in flats:
		if not entry is Dictionary:
			continue
		var flat: Dictionary = entry
		var centre: Array = flat.get("centre", [0.0, 0.0])
		var radius := float(flat.get("radius", 10.0))
		var skirt := float(flat.get("skirt", 8.0))
		var target := float(flat.get("height", _raw_height(float(centre[0]), float(centre[1]))))
		var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
		if distance <= radius:
			# Two authored pads never overlap cores today (checked by the
			# pad-flatness test) but if a future one ever did, the nearer
			# centre wins rather than whichever happened to be listed last.
			var fraction := distance / maxf(radius, 0.0001)
			if fraction < core_fraction:
				core_fraction = fraction
				core_height = target
				in_core = true
			continue
		if distance >= radius + skirt:
			continue
		var weight := 1.0 - smoothstep(radius, radius + skirt, distance)
		total_weight += weight
		weighted_target += weight * target
		max_weight = maxf(max_weight, weight)

	if in_core:
		return core_height
	if total_weight <= 0.0:
		return height
	var blended_target := weighted_target / total_weight
	return lerpf(height, blended_target, clampf(max_weight, 0.0, 1.0))


## How much a world point belongs to a dirt path: 1.0 on the centreline,
## fading to 0.0 across `shoulder` metres past the path's half-width.
##
## Paths are authored polylines in the config (`paths.routes`), walked as
## straight segments — enough points bend a route organically, and a segment
## distance is testable arithmetic where a spline is not. The bake reads this
## to paint the control map (`build_playground_terrain.gd::_paint_control_map`),
## the scatter reads it to keep vegetation off the road, and both agreeing is
## exactly why it lives here as one function.
##
## The fade band itself is nudged by `_path_edge` noise so the boundary bulges
## and pinches rather than tracing a perfect parallel offset of the polyline —
## a mathematically exact curve reads as drawn, not worn. The nudge moves
## `half`/`half+shoulder` together, so the band KEEPS its width and only its
## position wobbles; a route waypoint (`nearest == 0`) stays fully on the path
## regardless (bible sec8: "feathered irregular edges").
func path_factor(x: float, z: float) -> float:
	var paths: Dictionary = _config.get("paths", {})
	var routes: Array = paths.get("routes", [])
	if routes.is_empty():
		return 0.0
	var half := float(paths.get("width", 3.0)) * 0.5
	var shoulder := float(paths.get("shoulder", 1.5))
	var spot := Vector2(x, z)
	var nearest := INF
	for entry: Variant in routes:
		if not entry is Dictionary:
			continue
		var points: Array = (entry as Dictionary).get("points", [])
		for i in points.size() - 1:
			var a := Vector2(float(points[i][0]), float(points[i][1]))
			var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
			nearest = minf(nearest, _segment_distance(spot, a, b))
	var wobble := _path_edge.get_noise_2d(x, z) * shoulder * 0.5
	var edge_start := maxf(0.0, half + wobble)
	return 1.0 - smoothstep(edge_start, edge_start + shoulder, nearest)


func _segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	return point.distance_to(_segment_closest_point(point, a, b))


func _segment_closest_point(point: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var along := b - a
	var length_sq := along.length_squared()
	if length_sq < 0.0001:
		return a
	var t := clampf((point - a).dot(along) / length_sq, 0.0, 1.0)
	return a + along * t


## The closest point on any authored path route to a world position, for
## scatter layers that want to ANCHOR a clump to the road rather than merely
## avoid it (`path_factor` only answers "how close"). `Vector2.INF` when the
## config has no routes at all, the same sentinel `height_at` already uses for
## "no answer" — a scatter layer with `path_bias` set but no paths configured
## falls back to its unbiased placement rather than snapping to a phantom road.
func nearest_point_on_paths(x: float, z: float) -> Vector2:
	var paths: Dictionary = _config.get("paths", {})
	var routes: Array = paths.get("routes", [])
	if routes.is_empty():
		return Vector2.INF
	var spot := Vector2(x, z)
	var best := Vector2.INF
	var best_distance := INF
	for entry: Variant in routes:
		if not entry is Dictionary:
			continue
		var points: Array = (entry as Dictionary).get("points", [])
		for i in points.size() - 1:
			var a := Vector2(float(points[i][0]), float(points[i][1]))
			var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
			var candidate := _segment_closest_point(spot, a, b)
			var distance := spot.distance_to(candidate)
			if distance < best_distance:
				best_distance = distance
				best = candidate
	return best


## The direction of travel along the nearest authored path route to a world
## position -- the matching segment's own (b - a), normalised. `Vector2.ZERO`
## when no routes are configured, the same "no answer" contract
## `nearest_point_on_paths` uses.
##
## A clump that snaps ONTO the path (`path_bias`) sits exactly on the
## centreline, so its own symmetric instance disc straddles both edges at
## once -- two matched crescents, which is what a blind critic reads as "a
## hedge planted along a driveway" regardless of instance count. Rotating
## this tangent 90 degrees gives the one thing `nearest_point_on_paths` alone
## cannot: which way is SIDEWAYS, so a biased clump can be pushed to favour
## one shoulder instead of straddling both.
func nearest_path_tangent(x: float, z: float) -> Vector2:
	var paths: Dictionary = _config.get("paths", {})
	var routes: Array = paths.get("routes", [])
	if routes.is_empty():
		return Vector2.ZERO
	var spot := Vector2(x, z)
	var best_tangent := Vector2.ZERO
	var best_distance := INF
	for entry: Variant in routes:
		if not entry is Dictionary:
			continue
		var points: Array = (entry as Dictionary).get("points", [])
		for i in points.size() - 1:
			var a := Vector2(float(points[i][0]), float(points[i][1]))
			var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
			var candidate := _segment_closest_point(spot, a, b)
			var distance := spot.distance_to(candidate)
			if distance < best_distance:
				best_distance = distance
				var along := b - a
				best_tangent = along.normalized() if along.length_squared() > 0.0001 else Vector2.ZERO
	return best_tangent


## Height before the spawn pad flattening, used as the pad's own target so the
## pad does not recurse into itself.
func _raw_height(x: float, z: float) -> float:
	var hills: Dictionary = _config.get("hills", {})
	var detail: Dictionary = _config.get("detail", {})
	var height := _hills.get_noise_2d(x, z) * float(hills.get("amplitude", 15.0))
	height += _detail.get_noise_2d(x, z) * float(detail.get("amplitude", 2.2))
	height -= _valley_depth(x, z)
	height += _rise_height(x, z)
	return height


## Surface normal, sampled by central difference. Shared by slope_degrees_at
## below and by scatter placement (scatter_rules.gd), which needs the actual
## direction, not just the angle, to rest a rigid object flush with a slope
## instead of standing it bolt-upright on one.
func normal_at(x: float, z: float, step: float = 1.0) -> Vector3:
	var dx := height_at(x + step, z) - height_at(x - step, z)
	var dz := height_at(x, z + step) - height_at(x, z - step)
	return Vector3(-dx, 2.0 * step, -dz).normalized()


## Surface slope in degrees. Used to drive the ground colour and to
## sanity-check that the playground actually contains slopes worth testing
## against.
func slope_degrees_at(x: float, z: float, step: float = 1.0) -> float:
	var normal := normal_at(x, z, step)
	return rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))


## 0..1 dither for `_path_control`'s dominant-texture pick — see `_init`'s own
## comment on `_path_dominant` for why this exists instead of a fixed 0.5.
func path_dominant_dither(x: float, z: float) -> float:
	return _path_dominant.get_noise_2d(x, z) * 0.5 + 0.5


## Degrees to add to a sampled slope before picking a grass/soil/rock band —
## see `_init`'s own comment on `_outcrop` for why. `amplitude` is read from
## config at call time (not cached in `_init`), matching `height_at`'s own
## pattern for `hills`/`detail` amplitude, so a config edit doesn't require
## rebuilding the field. Symmetric around 0 so it neither inflates nor
## shrinks the total rock/soil area on average, only redistributes where it
## falls.
func outcrop_jitter_deg(x: float, z: float) -> float:
	var amplitude := float(_config.get("colour", {}).get("outcrop_jitter_deg", 0.0))
	return _outcrop.get_noise_2d(x, z) * amplitude
