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

## How many bedding planes one thickness cycle spans (`bed_thickness_jitter`).
## Deliberately not a whole number, so the sequence of thick and thin beds
## never lines up with itself and the stack does not repeat.
const BED_CYCLE := 3.7

var _config: Dictionary = {}
var _hills := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _path_edge := FastNoiseLite.new()
var _path_dominant := FastNoiseLite.new()
var _outcrop := FastNoiseLite.new()
var _outcrop_detail := FastNoiseLite.new()
var _ridge := FastNoiseLite.new()
var _warp_x := FastNoiseLite.new()
var _warp_z := FastNoiseLite.new()
var _fracture := FastNoiseLite.new()


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

	# OF11 round 6. A SECOND, much finer jitter on the same band boundary. The
	# 35m field above decides where the rock band bulges into a lobe; it cannot
	# do anything about the EDGE of that lobe, which at 35m is a smooth vector
	# curve however many lobes it makes. The round-5 blind critic named exactly
	# that: the moss/dirt patches "meet bare stone in hard stencil-edged shapes
	# with no organic blend... it looks like a stencil laid over the rock, not
	# moss actually growing in a crevice." An edge is ragged at the scale of the
	# thing growing along it, so this runs at metres, not tens of metres, and
	# breaks the boundary into interlocking fingers of turf and stone. A sixth
	# seed, uncorrelated with the lobe field it perturbs.
	_outcrop_detail.seed = seed_value + 5
	_outcrop_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_outcrop_detail.fractal_type = FastNoiseLite.FRACTAL_FBM
	_outcrop_detail.frequency = float(_config.get("colour", {}).get("outcrop_detail_frequency", 0.28))
	_outcrop_detail.fractal_octaves = 3

	# OF11: the rises' rock FORM. See `_rise_relief` for the whole argument;
	# in short, five earlier rounds all perturbed a smooth analytic dome and
	# then painted it, and a smoothly-perturbed dome cannot read as stone
	# however it is painted. Three fields cooperate here:
	#
	# `_ridge` is a RIDGED fractal, not FBM. That is the whole point: FBM is
	# C-continuous blobs — every surface it makes is a soft swell, which is
	# exactly the "smooth procedural blend" verdict — while a ridged fractal
	# folds the noise about zero, so its extrema are CREASES. Ribs with sharp
	# crests and gullies with sharp floors are what a rock hillside has and a
	# noise bump does not.
	#
	# `_warp_x`/`_warp_z` domain-warp the coordinates the ridge field is
	# sampled at. Unwarped ridged noise is recognisably isotropic and evenly
	# spaced; warping it by a lower-frequency field makes the ribs meander,
	# converge and pinch out the way real drainage does.
	#
	# Seeds 5, 6, 7 — the sixth, seventh and eighth distinct field in this
	# file — so none of this correlates with `_hills`, `_detail` or `_outcrop`.
	var form: Dictionary = _config.get("rock_form", {})
	_ridge.seed = seed_value + 5
	_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridge.frequency = float(form.get("frequency", 0.028))
	_ridge.fractal_octaves = int(form.get("octaves", 4))
	_ridge.fractal_lacunarity = float(form.get("lacunarity", 2.1))
	_ridge.fractal_gain = float(form.get("gain", 0.5))

	_warp_x.seed = seed_value + 6
	_warp_x.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_warp_x.fractal_type = FastNoiseLite.FRACTAL_FBM
	_warp_x.frequency = float(form.get("warp_frequency", 0.012))
	_warp_x.fractal_octaves = 2

	_warp_z.seed = seed_value + 7
	_warp_z.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_warp_z.fractal_type = FastNoiseLite.FRACTAL_FBM
	_warp_z.frequency = float(form.get("warp_frequency", 0.012))
	_warp_z.fractal_octaves = 2

	# Round 3. The finer of the two scales that break up a bedding plane's
	# outcrop edge — `_outcrop` (~35m) is the coarse one. One scale of
	# raggedness still has a recognisable tooth size; two do not.
	_fracture.seed = seed_value + 8
	_fracture.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_fracture.fractal_type = FastNoiseLite.FRACTAL_FBM
	_fracture.frequency = float(form.get("bed_fracture_frequency", 0.085))
	_fracture.fractal_octaves = 3


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
	height -= _stream_carve(x, z)
	height -= _spoke_carve(x, z)
	height -= _shore_step(height)

	return height


## SA4. How deep the severed spokes' own trenches cut at a world XZ — the
## river gorge and the storm road's ravine. Zero everywhere else on the map.
##
## Alongside `_stream_carve` and for the same reason it sits after the flats:
## a carve is the LAST thing applied to the shape, so it cuts through whatever
## the rest of the recipe produced rather than being ironed out by it. The
## difference is what the two are for. The stream's channel is 0.7m deep and
## exists so water sits in the ground; a spoke's carve is 11-16m deep and IS
## the blocker — the wall angle it leaves (roughly atan(depth/rim), 57-66
## degrees as authored) has to stay well past the player's own 45-degree
## floor_max_angle, or the road is not severed at all, it just dips.
##
## Straight trenches, not polylines: a gorge here is one clean cut across one
## road, and a straight segment is testable arithmetic. Both cross-section and
## along-axis profiles are smoothstep, so nothing leaves a crease or a squared
## end wall in open grass.
func _spoke_carve(x: float, z: float) -> float:
	var routes: Array = _config.get("spokes", {}).get("routes", [])
	if routes.is_empty():
		return 0.0
	var spot := Vector2(x, z)
	var deepest := 0.0
	for entry: Variant in routes:
		if not entry is Dictionary:
			continue
		if not bool((entry as Dictionary).get("built", false)):
			continue
		var carve: Dictionary = ((entry as Dictionary).get("blocker", {}) as Dictionary).get("carve", {})
		if carve.is_empty():
			continue
		deepest = maxf(deepest, _carve_depth(spot, carve))
	return deepest


func _carve_depth(spot: Vector2, carve: Dictionary) -> float:
	var depth := float(carve.get("depth", 0.0))
	if depth <= 0.0:
		return 0.0
	var at: Array = carve.get("centre", [])
	if at.size() < 2:
		return 0.0
	var centre := Vector2(float(at[0]), float(at[1]))
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var local := spot - centre
	var u := absf(local.dot(axis))
	var v := absf(local.dot(Vector2(-axis.y, axis.x)))

	var half_width := maxf(float(carve.get("half_width", 6.0)), 0.01)
	var rim := maxf(float(carve.get("rim", 5.0)), 0.01)
	var across := 1.0 - smoothstep(half_width, half_width + rim, v)
	if across <= 0.0:
		return 0.0

	var half_length := maxf(float(carve.get("half_length", 40.0)), 0.01)
	var fade := maxf(float(carve.get("end_fade", 16.0)), 0.01)
	var along := 1.0 - smoothstep(half_length, half_length + fade, u)
	return depth * across * along


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
	return _rise_cone(x, z) + _rise_relief(x, z)


## The rises' underlying analytic shape: one smoothstepped cone per peak. This
## is the ONLY part of a rise that sets its footprint and summit height, and it
## is unchanged from the original M1 recipe — everything OF11 added lives in
## `_rise_relief`, which is exactly zero at each rise's rim.
func _rise_cone(x: float, z: float) -> float:
	var rises: Dictionary = _config.get("rises", {})
	var sharpness := float(rises.get("sharpness", 2.1))
	var total := 0.0
	for entry: Variant in rises.get("peaks", []):
		var peak: Dictionary = entry
		var radius := float(peak.get("radius", 60.0))
		if radius <= 0.0:
			continue
		var centre: Array = peak.get("centre", [0.0, 0.0])
		var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
		if distance >= radius:
			continue
		var t := 1.0 - (distance / radius)
		# pow above 1 steepens the flanks while keeping the summit rounded,
		# which is what makes these testable slopes rather than smooth domes.
		total += pow(smoothstep(0.0, 1.0, t), 1.0 / sharpness) * float(peak.get("height", 40.0))
	return total


## OF11: everything that makes a rise read as a rock landform rather than a
## dome, as a signed height offset in metres. Zero everywhere outside a rise's
## own radius, and faded to zero at the rim, so the landform's footprint and
## the ground the roads run over are untouched.
##
## WHY THIS IS NOT THE PREVIOUS RELIEF LAYER AGAIN. `EV4-hillside-seam` through
## `-remainder-4` (five rounds, all recorded in terrain_playground.json's own
## `_comment_ev4_*` fields) worked the same two levers over and over: which
## texture band a slope reading picks, and — in the last round — a single
## smooth FBM bump added to the dome. A blind critic still called the result
## "a single smooth, continuous, unbroken curve." That is not a tuning
## failure, it is what smooth noise makes: FBM's extrema are rounded, so a
## flank built from it is a swell, and a swell painted grey is a stain. Rock
## reads as rock because of DISCONTINUITY — creased ridgelines, and bedding
## planes that break a slope into ledge/riser/ledge. Neither exists anywhere
## in a smoothstepped cone plus FBM, at any amplitude.
##
## So this builds the two features directly:
##
## 1. WARPED RIDGED RELIEF. A ridged fractal (`_ridge`, see `_init`) sampled
##    through a domain warp (`_warp_x`/`_warp_z`). Its crests are creases, not
##    swells, and the warp makes the ribs meander and pinch out instead of
##    tiling evenly. `bias` subtracts a constant so gullies cut deeper than
##    ribs stand proud, which is what erosion actually does and what keeps
##    the layer from inflating the rise.
##
## 2. BEDDING PLANES. `_terrace` quantises the peak's own height contribution
##    into steps, with a soft riser between each pair of near-level ledges. A
##    stratified flank is the single clearest "this is stone" cue there is —
##    it is what the plateau in docs/reference/palworld-04 and the crags in
##    the key art's own panels are made of — and it is a shape, so no amount
##    of looking at it from further away turns it back into a blend.
##
## Both are multiplied by the same rim gate, so `_rise_cone` alone decides
## where a rise begins and ends. Unlike the previous relief layer this one is
## NOT gated off at the summit: the references put bare rock on the CROWN of a
## hill (key art panel 1's hilltop crag, palworld-04's plateau cap), and the
## old summit gate is part of why the rise read as a grass dome with a grey
## bruise on its side.
func _rise_relief(x: float, z: float) -> float:
	var form: Dictionary = _config.get("rock_form", {})
	var amplitude := float(form.get("amplitude", 0.0))
	var terrace_step := float(form.get("terrace_height", 0.0))
	var terrace_strength := float(form.get("terrace_strength", 0.0))
	if amplitude <= 0.0 and (terrace_step <= 0.0 or terrace_strength <= 0.0):
		return 0.0

	var rises: Dictionary = _config.get("rises", {})
	var sharpness := float(rises.get("sharpness", 2.1))
	var rim_in := float(form.get("rim_in", 0.03))
	var rim_out := float(form.get("rim_out", 0.18))
	var bias := float(form.get("bias", 0.25))
	var riser := clampf(float(form.get("terrace_riser", 0.38)), 0.02, 1.0)
	var bed_dip: Array = form.get("bed_dip", [0.0, 0.0])
	var dip_x := float(bed_dip[0]) if bed_dip.size() > 0 else 0.0
	var dip_z := float(bed_dip[1]) if bed_dip.size() > 1 else 0.0
	var bed_wobble := float(form.get("bed_wobble", 0.0))
	var bed_fracture := float(form.get("bed_fracture", 0.0))
	var bed_thickness := float(form.get("bed_thickness_jitter", 0.0))
	var rubble := float(form.get("rubble_amplitude", 0.0))

	var warp_amp := float(form.get("warp_amplitude", 14.0))
	var warped_x := x + _warp_x.get_noise_2d(x, z) * warp_amp
	var warped_z := z + _warp_z.get_noise_2d(x, z) * warp_amp
	var ridge := _ridge.get_noise_2d(warped_x, warped_z) - bias
	# Round 3: close-range crumble. A critic standing at the foot of the rise
	# reported "zero surface micro-detail — no grain, no crumble... a smooth
	# surface with a repeating displacement." The rib field alone has one
	# scale, and everything between its ribs is the bare cone. Sampling the
	# SAME ridged field at 3.4x the coordinate rate (offset so it does not
	# correlate with itself) gives metre-scale creases for free, without a
	# seventh noise object: creases, again, not bumps, so the extra detail
	# reads as fractured rock rather than as a lumpier dome.
	var crumble := _ridge.get_noise_2d(x * 3.4 + 917.0, z * 3.4 - 431.0) - bias

	var total := 0.0
	for entry: Variant in rises.get("peaks", []):
		var peak: Dictionary = entry
		var radius := float(peak.get("radius", 60.0))
		if radius <= 0.0:
			continue
		var centre: Array = peak.get("centre", [0.0, 0.0])
		var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
		if distance >= radius:
			continue
		var t := 1.0 - (distance / radius)
		var gate := smoothstep(rim_in, rim_out, t)
		if gate <= 0.0:
			continue

		var cone := pow(smoothstep(0.0, 1.0, t), 1.0 / sharpness) * float(peak.get("height", 40.0))
		var carve := (ridge * amplitude + crumble * rubble) * gate
		var relief := carve
		if terrace_step > 0.0 and terrace_strength > 0.0:
			# Terrace the cone PLUS the carve, so the bedding planes cut
			# across the ribs the way real strata do, rather than the two
			# layers reading as independent decorations of the same dome.
			#
			# Round 2: terracing the cone alone quantises a pure function of
			# RADIUS, so every bed outcrops as a concentric circle at the same
			# elevation all the way round — a wedding cake, and the blind
			# critic on round 1 read the result as "corduroy, not erosion...
			# the same scalloped sawtooth at identical frequency and amplitude
			# across the entire dome." Two terms break that, and neither is an
			# amplitude:
			#
			#   `dip` tilts the bedding planes off horizontal, which is what
			#   real strata do. Terracing `height + dip` and subtracting the
			#   same `dip` back off snaps the surface onto planes that lean
			#   across the hill instead of lying level in it, so a bed
			#   outcrops high on one side and low on the other and the rings
			#   become the long diagonal bands a real stratified hill shows.
			#
			#   `_outcrop` warps the bed boundaries so they are not flat
			#   planes either — thick beds in some places, thin in others,
			#   which is the difference between sedimentary rock and a stack
			#   of coins.
			var dip := (x - float(centre[0])) * dip_x + (z - float(centre[1])) * dip_z
			var wobble := _outcrop.get_noise_2d(x, z) * terrace_step * bed_wobble
			# Round 3, and the fix for the defect two independent blind
			# critics named in a row: "identical sawtooth grooves at identical
			# spacing and identical depth, wrapped uniformly around the whole
			# dome... every groove is the same tooth." The teeth are a
			# resonance — a bed boundary is a near-vertical band, the carve
			# field has one dominant wavelength, and where the two cross they
			# produce a row of same-sized triangles on every bed. Three terms
			# detune it, and none of them is an amplitude:
			#
			#   `fracture` is a SECOND, much finer wobble on the bed boundary
			#   (~12m against `_outcrop`'s ~35m), so an outcrop edge is
			#   ragged at two scales instead of one and there is no single
			#   tooth size to recognise.
			#
			#   `thickness` makes beds thicker in some parts of the sequence
			#   and thinner in others — a slow, deliberately non-integer
			#   cycle through the bed stack, so no two adjacent beds are the
			#   same height and the stack never repeats exactly. Real strata
			#   are not a stack of identical coins.
			var fracture := _fracture.get_noise_2d(x, z) * terrace_step * bed_fracture
			var raw := cone + carve + dip + wobble + fracture
			var thickness := 0.0
			if bed_thickness > 0.0:
				thickness = sin(TAU * raw / (terrace_step * BED_CYCLE)) * terrace_step * bed_thickness
			var combined := raw + thickness
			relief += (_terrace(combined, terrace_step, riser) - combined) * terrace_strength * gate
		total += relief
	return total


## Snap a height onto bedding planes: near-level ledges separated by a riser
## occupying `riser` of each step. `riser` 1.0 degenerates back to the input
## (a pure ramp, no strata); small values make the risers steeper and the
## ledges flatter. The mapping is monotonic and preserves the mean, so a
## terraced slope still climbs to the same place the un-terraced one did.
func _terrace(height: float, step: float, riser: float) -> float:
	var q := height / step
	var index := floorf(q)
	var fraction := q - index
	return (index + smoothstep(0.5 - riser * 0.5, 0.5 + riser * 0.5, fraction)) * step


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


## The still-water surface height in metres, or NAN when the config has no
## water block. EV5: one flat level rather than an authored pond outline —
## the pond valley is the only terrain below -18m anywhere on the map (probed
## for EV5, see terrain_playground.json's own `_comment_water`), so "below
## this height" and "underwater" are the same statement. The bake, the
## scatter and the water composer all ask this one function so they cannot
## disagree about where the shoreline is.
func water_level() -> float:
	var water: Dictionary = _config.get("water", {})
	if not water.has("level"):
		return NAN
	return float(water.get("level"))


## How deep the stream channel is cut into the ground at a world XZ. Zero
## almost everywhere; up to `carve_depth` on the stream's centreline.
##
## EV5: the stream's course was probed downhill with no reversals, so the
## carve is not what makes the water run downhill — it is what makes the
## water sit IN the meadow rather than lie on top of it. A water ribbon laid
## over unbroken ground reads as painted; a channel with banks reads as worn.
## The cross profile is a smoothstep in both directions (no crease at the
## centre or the rim), and `head_ramp` fades the whole carve in over the
## first metres so the spring emerges rather than starting as a trench edge.
##
## Subtracted AFTER the flats on purpose: no authored route crosses a
## building pad, and applying the carve last means a future stream segment
## near a pad would still cut a visible channel instead of being ironed flat.
func _stream_carve(x: float, z: float) -> float:
	var stream: Dictionary = _config.get("water", {}).get("stream", {})
	var points: Array = stream.get("points", [])
	if points.size() < 2:
		return 0.0
	var depth := float(stream.get("carve_depth", 0.7))
	var half := float(stream.get("carve_width", 5.0)) * 0.5
	if depth <= 0.0 or half <= 0.0:
		return 0.0
	var spot := Vector2(x, z)
	var nearest := INF
	for i in points.size() - 1:
		var a := Vector2(float(points[i][0]), float(points[i][1]))
		var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
		nearest = minf(nearest, _segment_distance(spot, a, b))
	if nearest >= half:
		return 0.0
	var head := Vector2(float(points[0][0]), float(points[0][1]))
	var ramp: float = smoothstep(0.0, maxf(float(stream.get("head_ramp", 14.0)), 0.001), spot.distance_to(head))
	return depth * (1.0 - smoothstep(0.0, half, nearest)) * ramp


## An extra half-metre drop for everything already under the waterline, faded
## in across the waterline itself — a pure function of the height a point was
## already going to have. EV5 blind round 1: the basin's banks meet the water
## at the valley's own gentle grade, so from across the pond nothing marks
## where land stops ("no bank drop, no lip... a hole cut in a texture"). The
## step steepens only the last stretch of bank and deepens the shallows'
## colour ramp; ground at or above the waterline is untouched.
func _shore_step(height: float) -> float:
	var water: Dictionary = _config.get("water", {})
	var step := float(water.get("shore_step", 0.0))
	if step <= 0.0 or not water.has("level"):
		return 0.0
	var level := float(water.get("level"))
	return step * (1.0 - smoothstep(level - 0.4, level + 0.3, height))


## Public read of the carve for the water composer: the stream's surface
## ribbon must not begin until the channel is actually deep enough to hold
## its water — where the head ramp keeps the carve shallow, water at bed +
## surface_depth would sit proud of the meadow, which is exactly the
## "orphaned quads in the dry channel" a blind round caught.
func stream_carve_depth(x: float, z: float) -> float:
	return _stream_carve(x, z)


## How much a world point belongs to the stream channel: 1.0 on the
## centreline within the water's own width, fading to 0.0 across `shoulder`
## metres. Same contract as `path_factor` below and for the same reason —
## the bake paints the wet bed from it and the scatter keeps vegetation out
## of the channel with it, and both agreeing is why it lives here.
func stream_factor(x: float, z: float) -> float:
	var stream: Dictionary = _config.get("water", {}).get("stream", {})
	var points: Array = stream.get("points", [])
	if points.size() < 2:
		return 0.0
	var half := float(stream.get("width", 2.4)) * 0.5
	var shoulder := float(stream.get("shoulder", 1.2))
	var spot := Vector2(x, z)
	var nearest := INF
	for i in points.size() - 1:
		var a := Vector2(float(points[i][0]), float(points[i][1]))
		var b := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
		nearest = minf(nearest, _segment_distance(spot, a, b))
	var head := Vector2(float(points[0][0]), float(points[0][1]))
	var ramp: float = smoothstep(0.0, maxf(float(stream.get("head_ramp", 14.0)), 0.001), spot.distance_to(head))
	return (1.0 - smoothstep(half, half + shoulder, nearest)) * ramp


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
	var routes: Array = road_polylines()
	if routes.is_empty():
		return 0.0
	var half := float(paths.get("width", 3.0)) * 0.5
	var shoulder := float(paths.get("shoulder", 1.5))
	var spot := Vector2(x, z)
	var nearest := INF
	for line: PackedVector2Array in routes:
		for i in line.size() - 1:
			nearest = minf(nearest, _segment_distance(spot, line[i], line[i + 1]))
	var wobble := _path_edge.get_noise_2d(x, z) * shoulder * 0.5
	var edge_start := maxf(0.0, half + wobble)
	return 1.0 - smoothstep(edge_start, edge_start + shoulder, nearest)


## How much a world point belongs to a building's worked-soil apron: 1.0
## inside a placed structure's footprint (and `margin` metres beyond it),
## fading to 0.0 across `feather` metres. EV6-remainder-polish — the bake
## blends the ground control map toward the soil texture by this weight, so
## the kit buildings' stone border skirts meet dug ground instead of a hard
## grey line against lawn (the settlement-wide edge the blind pass named).
##
## Footprints are rotated rectangles authored in `building_aprons.footprints`
## (terrain_playground.json), mirroring village.json's placements the same
## way the capture tools mirror them — the bake is offline and cannot ask the
## live scene. Same contract shape as `path_factor`/`stream_factor` so the
## bake composes all three with one rule (strongest wins per pixel), and the
## ring's outer edge is nudged by the same `_path_edge` noise the paths use,
## for the same reason: a mathematically exact offset rectangle reads as
## drawn, not dug.
func building_apron_factor(x: float, z: float) -> float:
	var apron: Dictionary = _config.get("building_aprons", {})
	var footprints: Array = apron.get("footprints", [])
	if footprints.is_empty():
		return 0.0
	var margin := float(apron.get("margin", 0.55))
	var feather := maxf(float(apron.get("feather", 2.4)), 0.001)
	var spot := Vector2(x, z)
	var best := 0.0
	for entry: Variant in footprints:
		if not entry is Dictionary:
			continue
		var footprint: Dictionary = entry
		var centre_spec: Array = footprint.get("centre", [0.0, 0.0])
		var centre := Vector2(float(centre_spec[0]), float(centre_spec[1]))
		# Cheap reject: no footprint half-extent here exceeds ~7m, and the
		# wobble below moves the edge by well under a metre.
		if spot.distance_to(centre) > 12.0 + margin + feather:
			continue
		var half_spec: Array = footprint.get("half_extents", [3.0, 3.0])
		# Rotate the world offset into the footprint's own frame. The recipe's
		# yaw is the node's Y rotation (counter-clockwise seen from above, i.e.
		# +X toward -Z), so the world offset comes back by the same angle.
		var local := (spot - centre).rotated(deg_to_rad(float(footprint.get("yaw_deg", 0.0))))
		var outside := Vector2(
			maxf(absf(local.x) - float(half_spec[0]), 0.0),
			maxf(absf(local.y) - float(half_spec[1]), 0.0)).length()
		var wobble := _path_edge.get_noise_2d(x, z) * feather * 0.4
		var edge_start := maxf(0.0, margin + wobble)
		best = maxf(best, 1.0 - smoothstep(edge_start, edge_start + feather, outside))
	return best


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
	var routes: Array = road_polylines()
	if routes.is_empty():
		return Vector2.INF
	var spot := Vector2(x, z)
	var best := Vector2.INF
	var best_distance := INF
	for line: PackedVector2Array in routes:
		for i in line.size() - 1:
			var candidate := _segment_closest_point(spot, line[i], line[i + 1])
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
	var routes: Array = road_polylines()
	if routes.is_empty():
		return Vector2.ZERO
	var spot := Vector2(x, z)
	var best_tangent := Vector2.ZERO
	var best_distance := INF
	for line: PackedVector2Array in routes:
		for i in line.size() - 1:
			var candidate := _segment_closest_point(spot, line[i], line[i + 1])
			var distance := spot.distance_to(candidate)
			if distance < best_distance:
				best_distance = distance
				var along := line[i + 1] - line[i]
				best_tangent = along.normalized() if along.length_squared() > 0.0001 else Vector2.ZERO
	return best_tangent


## The authored route polylines as PackedVector2Arrays, for scatter layers
## that place a verge fringe ALONG the paths by arc length (OF12,
## scatter_rules.gd::_place_verge) rather than merely reacting to the nearest
## one the way `nearest_point_on_paths` allows. Empty when no routes are
## configured — the caller places no fringe, the same graceful fallback the
## other path queries use.
func path_polylines() -> Array:
	return road_polylines()


## SA4. Every authored road on the map as PackedVector2Arrays: the village's
## own `paths.routes` PLUS each built spoke's `spokes.routes[].road`.
##
## One list, because a spoke is a road in every sense the terrain cares
## about — the bake paints the same soil into the control map along it
## (`build_playground_terrain.gd::_path_control` reads `path_factor`), the
## scatter keeps grass and trees off it and lays path stones down it
## (`scatter_rules.gd` reads `nearest_point_on_paths`/`path_polylines`), and
## the verge fringe follows it. Adding the spokes as extra `paths.routes`
## entries would have got all of that for free too, and was rejected for one
## reason: `signpost.gd`'s village junction sign draws ONE ARM PER ENTRY in
## `paths.routes`, so seven more entries would silently turn the four-arm
## fingerpost in the square into an eleven-arm mast. The spokes keep their own
## section and this function is where the two meet.
##
## Unbuilt spokes (`built: false`) contribute nothing: an authored bearing
## with no blocker standing yet should not paint a road across the meadow to
## nowhere.
func road_polylines() -> Array:
	var out: Array = []
	for entry: Variant in _config.get("paths", {}).get("routes", []):
		if entry is Dictionary:
			_append_line(out, (entry as Dictionary).get("points", []))
	for entry: Variant in _config.get("spokes", {}).get("routes", []):
		if entry is Dictionary and bool((entry as Dictionary).get("built", false)):
			_append_line(out, (entry as Dictionary).get("road", []))
	return out


func _append_line(out: Array, points: Array) -> void:
	if points.size() < 2:
		return
	var line := PackedVector2Array()
	for p: Variant in points:
		line.append(Vector2(float((p as Array)[0]), float((p as Array)[1])))
	out.append(line)


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


## OF11. Degrees to add to a sampled slope before the grass/soil/rock band
## lookup — the whole rule for WHERE rock shows, and the second half of this
## item's rebuild.
##
## The five earlier rounds all picked the band from slope alone (plus
## `outcrop_jitter_deg`, an unrelated noise field). On a smooth dome slope is a
## pure function of radius, so rock could only ever be a ring; jittering it
## made a lobed ring. Either way the material and the surface underneath it
## are describing different objects, which is precisely what "reads as a
## stain, not stone" means.
##
## Every term here is read off the rise's OWN relief field instead, so the
## material can only ever land where the geometry actually has the feature:
##
## * `rock_exposure_deg` follows `_rise_relief`'s sign — a rib that stands
##   proud of the cone is exposed bedrock, a gully that cuts into it collects
##   soil and grass. Ribs get rock, hollows do not.
## * `rock_curvature_deg` follows its local convexity, measured on the relief
##   field alone at a fine step. Crests and the lips of terrace risers are
##   convex and go to rock; the inside corner where a riser meets the next
##   ledge is concave and holds soil, the way scree and turf really do gather
##   at the foot of a ledge.
## * `rock_crown_deg` bares the summit. Both reference boards put rock on the
##   CROWN of a hill (key art panel 1, palworld-04's plateau cap) and this
##   terrain put grass there and rock in a mid-flank band, which is the wrong
##   way round before any question of material quality.
##
## Measuring convexity on `_rise_relief` rather than on `height_at` matters:
## `height_at` carries the `detail` noise layer, whose curvature is everywhere
## on the map, so a curvature rule read off it would sprinkle rock across the
## whole meadow. `_rise_relief` is identically zero off the rises, so this
## returns nothing but the residual jitter anywhere else.
func rock_bias_deg(x: float, z: float) -> float:
	var cfg: Dictionary = _config.get("colour", {})
	var bias := outcrop_jitter_deg(x, z)

	# OF11 round 6. The fine boundary octave, gated to the rises by the same
	# `rise_form_factor` `slope_sample_step_rock` uses. It is deliberately NOT
	# in `outcrop_jitter_deg` itself: at this wavelength an ungated few degrees
	# would ride the open meadow's own grass/soil threshold and speckle soil
	# across flat ground, which is the blotching `slope_sample_step` exists to
	# suppress. On a rise there is real rock form for it to ragged the edge of;
	# out on the meadow there is nothing it could improve.
	var detail_gain := float(cfg.get("outcrop_detail_deg", 0.0))
	if detail_gain != 0.0:
		bias += detail_gain * _outcrop_detail.get_noise_2d(x, z) * clampf(rise_form_factor(x, z), 0.0, 1.0)

	var form: Dictionary = _config.get("rock_form", {})
	var relief_ref := maxf(float(form.get("amplitude", 1.0)), 0.001)
	var relief := _rise_relief(x, z)

	bias += float(cfg.get("rock_exposure_deg", 0.0)) * clampf(relief / relief_ref, -1.0, 1.0)

	var curvature_gain := float(cfg.get("rock_curvature_deg", 0.0))
	if curvature_gain != 0.0:
		var step := maxf(float(form.get("curvature_step", 2.5)), 0.1)
		var neighbours := (
			_rise_relief(x + step, z) + _rise_relief(x - step, z)
			+ _rise_relief(x, z + step) + _rise_relief(x, z - step)
		)
		# How far the centre stands above the mean of its four neighbours, in
		# metres. Positive on a crest or a riser lip, negative in a hollow.
		var convexity := relief - neighbours * 0.25
		var curvature_ref := maxf(float(form.get("curvature_ref", 1.0)), 0.001)
		bias += curvature_gain * clampf(convexity / curvature_ref, -1.0, 1.0)

	var crown_gain := float(cfg.get("rock_crown_deg", 0.0))
	if crown_gain != 0.0:
		bias += crown_gain * rise_crown_factor(x, z)
	return bias


## How strongly a world point is inside a rise's rock-form gate, 0..1 — the
## same `rim_in`/`rim_out` ramp `_rise_relief` uses, exposed so the bake can
## ask "does this pixel have metre-scale rock form on it, or is it open
## meadow?" without recomputing the relief itself.
##
## Round 4. The two bakes sample slope at `colour.slope_sample_step` (6m) to
## low-pass the `detail` noise layer, whose curvature would otherwise flicker
## the material pick pixel to pixel across the whole map. That was right when
## a rise was a smooth cone and everything above 6m was unwanted noise. It is
## wrong now: `rock_form` puts real ledges, riser lips and metre-scale creases
## on the rises, and a 6m slope sample cannot see any of them — which is
## precisely what the round-3 blind critic described as "the dark olive
## patches have hard, rounded, blobby edges that don't track the crevice
## geometry underneath them... the bumps and the tint aren't talking to each
## other." They were not talking because the material pick was deaf at the
## scale the geometry speaks at. The bake now interpolates its slope step
## between the coarse value out on the meadow and a fine one on the rises,
## using this factor — sample at the scale of the features that are actually
## there, rather than one global compromise.
func rise_form_factor(x: float, z: float) -> float:
	var form: Dictionary = _config.get("rock_form", {})
	var rim_in := float(form.get("rim_in", 0.03))
	var rim_out := float(form.get("rim_out", 0.18))
	var best := 0.0
	for entry: Variant in _config.get("rises", {}).get("peaks", []):
		var peak: Dictionary = entry
		var radius := float(peak.get("radius", 60.0))
		if radius <= 0.0:
			continue
		var centre: Array = peak.get("centre", [0.0, 0.0])
		var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
		if distance >= radius:
			continue
		best = maxf(best, smoothstep(rim_in, rim_out, 1.0 - (distance / radius)))
	return best


## How far up a rise a point sits, 0..1, taken over whichever peak claims it
## most strongly — 0 anywhere off the rises, 1 at a summit. `rock_crown_range`
## sets where the ramp begins and ends as a fraction of the rise's radius from
## its rim.
func rise_crown_factor(x: float, z: float) -> float:
	var range_cfg: Array = _config.get("colour", {}).get("rock_crown_range", [0.55, 0.9])
	var from := float(range_cfg[0]) if range_cfg.size() > 0 else 0.55
	var to := float(range_cfg[1]) if range_cfg.size() > 1 else 0.9
	var best := 0.0
	for entry: Variant in _config.get("rises", {}).get("peaks", []):
		var peak: Dictionary = entry
		var radius := float(peak.get("radius", 60.0))
		if radius <= 0.0:
			continue
		var centre: Array = peak.get("centre", [0.0, 0.0])
		var distance := Vector2(x - float(centre[0]), z - float(centre[1])).length()
		if distance >= radius:
			continue
		best = maxf(best, smoothstep(from, to, 1.0 - (distance / radius)))
	return best
