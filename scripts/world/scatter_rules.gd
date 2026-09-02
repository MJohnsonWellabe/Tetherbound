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
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

## How many candidate clump centres a ridge-biased layer samples before
## keeping the highest. Small enough to stay cheap (at most a few dozen
## calls per layer build), large enough that the bias is real.
const RIDGE_CANDIDATES := 6

## How many samples an authored anchor may draw per instance it wants before
## giving up. Anchors sit on ground their own layer mostly refuses (a rock
## outcrop on a hillside collar), so a healthy anchor rejects most of its
## draws; 12 is enough for a spot passing roughly one sample in eight and
## cheap enough that a badly-placed anchor costs nothing.
const ANCHOR_ATTEMPTS_PER_INSTANCE := 12

## Metres per lattice cell of the noise that decides WHICH instances a drain
## radius kills. Small enough that the thinning is patchy rather than a clean
## gradient, large enough that neighbouring tufts tend to share a fate --
## which is how ground actually dies. TUNABLE.
const DRAIN_PATCHINESS := 1.8
## Its own noise stream, unrelated to any path standoff salt.
const DRAIN_SALT := 8681

static var _config: Dictionary = {}


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	# BAND-SPLIT-2: `clearings` and `footprints` are cut per band under
	# data/config/bands/<band>/vegetation.json and merged back here, the same
	# way band_content.gd already merges spawns/props/harvest/trainers. The
	# scatter rules (layers, corridor_bands, retint, seed) are not split and
	# come straight off the head file's own keys, which `load_config` returns
	# untouched aside from filling in the one array key it was asked for.
	var merged := BAND_CONTENT.load_config(CONFIG_PATH, "clearings")
	if merged.is_empty():
		push_error("vegetation.json missing at %s" % CONFIG_PATH)
		return {}
	var footprints := BAND_CONTENT.load_config(CONFIG_PATH, "footprints")
	merged["footprints"] = footprints.get("footprints", [])
	# VP4-CORRIDOR: see `_merge_band_layer_anchors`'s own header for why this
	# exists and why it could not use `BAND_CONTENT.load_config()` the way
	# `clearings`/`footprints` do.
	_merge_band_layer_anchors(merged.get("layers", {}))
	_config = merged
	return _config


## VP4-CORRIDOR, 2026-09-02. A band's own `layer_anchors` (optional,
## `data/config/bands/<band>/vegetation.json`, TUNABLE): `{layer_name: [anchor,
## ...]}`, each anchor the same shape `_place_anchor` already reads off a
## layer's own `anchors` array. Appended onto that layer's `anchors` in band
## order, AFTER the head file's own -- the same append-only contract the head
## file's anchors, verge and corridor fill already keep with each other (see
## `placements_for`'s own header), so a band with no `layer_anchors` key, or
## none at all, changes no existing placement.
##
## Why this could not be `BAND_CONTENT.load_config()`, which already merges
## `clearings`/`footprints` for this same file: that helper merges ONE flat
## top-level array by an `order` field, because a clearing's array position
## used to matter and still has to survive the split unchanged (see
## `tests/test_band_vegetation.gd`). An anchor has no such identity -- it is
## an unordered, absolute-coordinate append, the same as every other anchor
## already in this file -- and it does not live at the config's top level, it
## lives nested inside `layers.<name>`, which a flat array merge cannot reach.
## So this reads each band file directly instead, in `BAND_CONTENT.BANDS`
## order, and appends straight into the matching layer dict.
##
## VP4's own working file (`ralph/reports/visual-parity/CORRIDOR/REPORT.md`)
## records that this function did not exist before that pass: the lane's brief
## named `data/config/bands/*/vegetation.json` as the file that carries
## per-band anchors, but no merge for them existed anywhere in the repo (this
## branch or `claude/vp-veg`, checked directly) -- only `clearings`/
## `footprints` were band-split. Without this, authoring anchors in a band
## file would be inert config nobody reads. Flagged here and in that report
## for whoever next touches this file, since it crosses this lane's own
## nominal ownership boundary to make the assigned mechanism actually exist.
static func _merge_band_layer_anchors(layers: Dictionary) -> void:
	for band_id: String in BAND_CONTENT.BANDS:
		var band_path := "%s/%s/vegetation.json" % [BAND_CONTENT.BANDS_DIR, band_id]
		if not FileAccess.file_exists(band_path):
			continue
		var file := FileAccess.open(band_path, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not parsed is Dictionary:
			push_error("%s is not a JSON object" % band_path)
			continue
		var band_doc: Dictionary = parsed
		var layer_anchors: Dictionary = band_doc.get("layer_anchors", {})
		for layer_name: String in layer_anchors.keys():
			if not layers.has(layer_name):
				push_error("%s: layer_anchors names unknown layer '%s'" % [band_path, layer_name])
				continue
			var extra: Array = layer_anchors[layer_name] as Array
			if extra.is_empty():
				continue
			var layer: Dictionary = layers[layer_name]
			var existing: Array = (layer.get("anchors", []) as Array).duplicate()
			existing.append_array(extra)
			layer["anchors"] = existing
			layers[layer_name] = layer


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
	layer: Dictionary, field: RefCounted, world_size: float, seed_value: int,
	drained_out: Array[Dictionary] = []
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

	for clump in clumps:
		var centre := _clump_centre(rng, half, field, ridge_bias, path_bias)
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

	# Verge fringe last, so a layer gaining one keeps its clump and stray
	# draws bit-identical — the fringe only ever appends.
	var verge: Dictionary = layer.get("verge", {})
	if not verge.is_empty() and field.has_method("path_polylines"):
		_place_verge(out, layer, field, models, verge, half, rng)

	# Authored anchors after everything else, same append-only contract as the
	# verge and for the same reason -- but, unlike the verge, EACH ANCHOR GETS
	# ITS OWN RNG rather than drawing from the shared `rng` stream.
	#
	# VP4-CORRIDOR, round 2. Before this: an anchor's own draws (angle,
	# distance, scale, model, yaw -- `_place_anchor`/`_consider`) came out of
	# the SAME stream `_place_corridor_fill`/`_place_heroes`/`_place_water_edge`
	# go on to use below. Every draw an anchor makes shifts the cursor those
	# later calls start from, so adding, enlarging, or moving ONE anchor
	# reshuffles EVERY corridor-fill placement for the WHOLE CORRIDOR in that
	# layer -- not just near the anchor. `JUDGE-round1.md` (blind visual
	# review) caught the result: two stations came back emptier after a pass
	# that only ever added content, because pre-existing corridor-fill trees
	# that happened to stand on their sightlines were shuffled elsewhere.
	# `vegetation.json`'s own BAND2-FLOOR comment on `_place_corridor_fill`
	# already names this exact mechanism as a known cost of raising an
	# anchor's `count` -- this removes that cost instead of continuing to pay
	# it. Seeded from this layer's own `seed_value` plus a large per-anchor
	# stride (deterministic and stable given a fixed anchor order -- the same
	# contract `seed_offset` already keeps between layers), so the result is
	# still fully reproducible and untouched by `test_the_meadow_is_the_same_
	# every_run`. Nothing downstream of this loop advances differently
	# whether an anchor is absent, present, bigger, or moved.
	for anchor_index in layer.get("anchors", []).size():
		var entry: Variant = layer["anchors"][anchor_index]
		if entry is Dictionary:
			var anchor_rng := RandomNumberGenerator.new()
			anchor_rng.seed = seed_value + 104729 * (anchor_index + 1)
			_place_anchor(out, layer, field, models, entry as Dictionary, half, anchor_rng)

	# VEG-CORRIDOR: the corridor fill, dead last and for the same append-only
	# reason as the verge and anchors above -- every draw made before this
	# point (clumps, strays, verge, anchors) must stay bit-identical to the
	# meadow already tuned and shipped inside the old +-256m square, whether
	# or not a layer opts into this at all. See `_place_corridor_fill`'s own
	# comment for why it is opt-in per layer rather than automatic.
	_place_corridor_fill(out, layer, field, models, half, rng)

	# VP3: hero trees and the water-edge bands, appended after the corridor
	# fill under the same append-only contract. A layer without either key
	# draws nothing extra and consumes no rng.
	_place_heroes(out, layer, field, models, half, rng)
	_place_water_edge(out, layer, field, models, half, rng)

	# OP21-19: nothing stands in the pond. Applied here, as a filter, for
	# exactly the reason D41's own filter is -- see `_drop_below_waterline`.
	var dry: Array[Dictionary] = _drop_below_waterline(out, field)

	# D41 (SD16): the drained ground around a Tether station, applied LAST and
	# as a filter. See `_thin_by_drain` for why it cannot be a gate inside
	# `_consider` like every other rule here.
	return _thin_by_drain(dry, layer, field, drained_out)


## D41 (SD16), the vegetation half of the drained-ground grammar: Team Tether's
## hardware is pulling something out of the ground, and what grows there gives
## up. `drain_factor` (playground_heightfield.gd) is the same 0..1 field the
## bake discolours the ground with, so the dead earth and the bald patch end at
## exactly the same contour -- which is the entire effect. A layer's own
## `drain_suppression` (vegetation.json, TUNABLE, default 1.0) scales it: 1.0
## means gone at the machine, 0.0 means this layer does not care, and the
## values in between are what let dry grass hang on in ground the green has
## abandoned.
##
## THIS IS A FILTER, NEVER A GATE. Every other rule in this file rejects a
## candidate inside `_consider`, before its scale and yaw are drawn -- which
## means a rejection shifts every later instance in that layer onto different
## random draws. That is fine for a rule that has always been there and is
## exactly wrong for one being added now: a new rejection in the far south
## would reshuffle the whole map's trees and rocks, including placements three
## visual passes have already tuned around the village. Filtering the finished
## list instead removes instances and moves nothing.
##
## Which instance dies is coherent position noise, not `rng`, for the same
## reason -- drawing here would consume the layer's stream and reintroduce the
## shuffle the filter exists to avoid. It also gives a better result: noise is
## patchy at metre scale, so the survivors thin out in drifts rather than at a
## uniform per-instance rate.
## OP21-19, and a second lesson in `_thin_by_drain`'s rule.
##
## OW5D relocated the pond and moved `water.level` from -22.5 to -17.0 without
## re-deriving the per-layer `min_height` numbers anchored to the old, deeper
## waterline -- so trees and bushes stood in the new water. The first repair
## added a hard `water_level() - 0.5` floor as a GATE inside `_consider`,
## which fixed the pond and broke something bigger.
##
## `_thin_by_drain`'s header, twenty lines below, already says why: "a new
## rejection in the far south would reshuffle the whole map's trees and rocks."
## A gate rejects a candidate BEFORE its scale, model and yaw are drawn, so
## every instance after it in that layer lands on different random numbers.
## The pond is roughly 0.02% of a 8192x2048m corridor and the re-roll was
## total: 257 of 256 region files changed, and one of the re-rolled colliding
## layers stood a rock and a pebble on a slope in the practice meadow at
## (59.7, -49.1), where `tests/smoke_traversal.gd`'s OF15 wedge detector
## caught a held `move_back` dead-stopped for a full second. That is the exact
## owner-reported failure the detector was written for, produced by a pond fix
## 100m away.
##
## As a filter it removes the instances that are genuinely in the water and
## moves nothing else. Half a metre, not zero, so a layer that deliberately
## wades the `shore_step` lip is not pushed dry -- it only stops anything
## standing in water deep enough to read as "in the pond" rather than "at its
## edge". No `rng` is touched here, for the same reason `_thin_by_drain` uses
## position noise instead.
static func _drop_below_waterline(out: Array[Dictionary], field: RefCounted) -> Array[Dictionary]:
	if not field.has_method("water_level"):
		return out
	var level: float = field.water_level()
	if is_nan(level):
		return out
	var floor_y := level - 0.5
	var kept: Array[Dictionary] = []
	for placement: Dictionary in out:
		var pos: Vector3 = placement.get("position", Vector3.ZERO)
		if pos.y >= floor_y:
			kept.append(placement)
	return kept


static func _thin_by_drain(
	out: Array[Dictionary], layer: Dictionary, field: RefCounted,
	drained_out: Array[Dictionary] = []
) -> Array[Dictionary]:
	if field == null or not field.has_method("drain_factor"):
		return out
	var suppression := clampf(float(layer.get("drain_suppression", 1.0)), 0.0, 1.0)
	if suppression <= 0.0:
		return out
	var kept: Array[Dictionary] = []
	for placement: Dictionary in out:
		var at: Vector3 = placement["position"]
		var drain: float = field.drain_factor(at.x, at.z)
		if drain > 0.0:
			var spot := Vector2(at.x, at.z)
			if _value_noise(spot / DRAIN_PATCHINESS, DRAIN_SALT) < drain * suppression:
				# SG46/D41: what the drain took, kept rather than dropped, so
				# the healing can put back exactly these instances and not a
				# freshly-rolled second scatter that would not match the
				# meadow the player walked through. See this function's own
				# note below on why that list can be handed out safely.
				drained_out.append(placement)
				continue
		kept.append(placement)
	return kept

## An AUTHORED clump: this layer, this many instances, at this spot on the map.
##
## OF4-remainder-mound. Everything above chooses its own centres — randomly,
## or biased toward high ground or toward a road. That is right for a meadow
## and wrong for the one thing a scatter cannot do: put a specific rock on a
## specific hillside because a frame needs it there. The rise east of the
## village had, measurably, four boulders and no trees anywhere on the whole
## face the village square looks at (`tools/_probe_mound.gd`), because
## `rocks`' 44-degree ceiling and `trees`' 21-degree one exclude most of a
## 46m landform's flank — so the layer that exists to "make steep ground read
## as stone" was locked out of the steepest ground in the game.
##
## An anchor may override ANY of its layer's own keys for its own draws
## (`max_slope_deg` to let an outcrop stand on a collar the meadow scatter
## must not, `scale_min`/`scale_max` for an outcrop rather than a field
## boulder, and — since SD16 — `models`, to narrow the layer's own list to a
## subset that suits one site), so a hand-placed group stays part of its
## layer — same retint, same collision, same harvest rules — instead of becoming a
## parallel layer with its own copy of all of that. Sharing a model across two
## LAYERS silently drops one layer's tint (see vegetation.gd's
## `_warn_about_shared_models`), which is exactly what a separate `outcrops`
## layer reusing `Rock_Medium_*` would have done.
##
## `count` is instances actually PLACED, not draws attempted: an anchor on a
## flank rejects most samples on slope, and "6" meaning "6 unless the ground
## disagrees" makes authoring unpredictable. Attempts are capped
## (`ANCHOR_ATTEMPTS_PER_INSTANCE`) so an impossible anchor fails cheaply
## rather than spinning.
static func _place_anchor(
	out: Array[Dictionary], layer: Dictionary, field: RefCounted, models: Array,
	anchor: Dictionary, half: float, rng: RandomNumberGenerator
) -> void:
	var at: Array = anchor.get("at", [])
	if at.size() < 2:
		push_warning("a scatter anchor has no `at` — ignored")
		return
	var centre := Vector2(float(at[0]), float(at[1]))
	var radius := maxf(float(anchor.get("radius", 8.0)), 0.0)
	var wanted := int(anchor.get("count", 6))
	if wanted <= 0:
		return

	# The anchor's own keys win over the layer's for these draws only.
	var local: Dictionary = layer.duplicate(true)
	local.erase("anchors")
	for key: Variant in anchor.keys():
		var name := str(key)
		if name in ["at", "radius", "count"] or name.begins_with("_"):
			continue
		local[name] = anchor[key]

	# `models` was silently exempt from "any of its layer's own keys" above:
	# the list is read once at the top of `placements_for` and handed down, so
	# an anchor overriding it changed nothing. SD16 needs the exemption gone --
	# the quarry's dead stand is the `deadfall` layer (same retint, same
	# collision, same everything) narrowed to its three dead trees, because
	# mushrooms sprouting in drained ground says the opposite of what the
	# ground is for. Still one list per draw, still no new layer.
	var anchor_models: Array = local.get("models", models)
	if anchor_models.is_empty():
		anchor_models = models

	var placed := 0
	var attempts := 0
	var budget := wanted * ANCHOR_ATTEMPTS_PER_INSTANCE
	while placed < wanted and attempts < budget:
		attempts += 1
		var angle := rng.randf_range(0.0, TAU)
		var distance := sqrt(rng.randf()) * radius
		var spot := centre + Vector2(sin(angle), cos(angle)) * distance
		var before := out.size()
		_consider(out, local, field, anchor_models, spot, half, rng)
		if out.size() > before:
			placed += 1
	if placed < wanted:
		push_warning("scatter anchor at %s placed %d of %d in %d attempts" % [
			centre, placed, wanted, attempts])


## The verge fringe (OF12): extra instances strung along the authored routes
## by arc length, densest just off the worn edge and thinning outward
## (`inner + band * r^2`). A blind critic's round-1 verdict on the standoff
## rework named the gap this fills: with the old constant-radius exclusions
## gone, nothing GREW near the paths at all — "the verge immediately beside
## each path is the baldest ground in the frame, when it should be the
## densest", and the dirt/grass boundary was a clean cut with no
## interpenetration.
##
## What stops this from recreating the planted border those exclusions were
## removed for: every fringe draw still passes through `_consider`, so the
## per-side noise standoff culls it wherever the meadow's edge is locally
## standing back. One noise field drives both WHERE the edge sits and HOW
## MUCH fringe survives near it — stretches where the noise swings low get
## growth crowding the raveled dirt line, stretches where it swings high
## stay open — so density varies along the route and per side by
## construction, instead of tracing a constant-width strip. The path_factor
## gate (with `path_edge_jitter`) still trims draws that land too deep in
## the worn zone, irregularly, which is what lets an occasional tuft lean
## into the dirt line instead of the two materials meeting in a clean cut.
static func _place_verge(
	out: Array[Dictionary], layer: Dictionary, field: RefCounted,
	models: Array, verge: Dictionary, half: float, rng: RandomNumberGenerator
) -> void:
	var polylines: Array = field.path_polylines()
	if polylines.is_empty():
		return
	var segment_a: Array[Vector2] = []
	var segment_b: Array[Vector2] = []
	var segment_length: Array[float] = []
	var total := 0.0
	for entry: Variant in polylines:
		var line: PackedVector2Array = entry
		for i in line.size() - 1:
			var length := line[i].distance_to(line[i + 1])
			if length <= 0.001:
				continue
			segment_a.append(line[i])
			segment_b.append(line[i + 1])
			segment_length.append(length)
			total += length
	if total <= 0.0:
		return
	var count := int(verge.get("count", 0))
	# `inner` starts the fringe at the dirt's own half-width, not the
	# centreline; `band` is how far it reaches before ordinary meadow density
	# takes over. The lateral draw is UNIFORM over [inner, inner + band] on
	# purpose: the first cut weighted it toward the edge (`inner + band*r^2`)
	# and a blind critic read the result exactly right — most survivors
	# landed at one modal offset (wherever the standoff cull happened to sit
	# in that stretch), printing "a run of tufts... same offset from the
	# dirt, same rough spacing, in lockstep with the path". A uniform draw
	# has no modal distance, so the fringe's density gradient comes only
	# from the standoff noise, which varies. Both keys TUNABLE per layer in
	# vegetation.json.
	var inner := float(verge.get("inner", 1.5))
	var band := maxf(float(verge.get("band", 4.0)), 0.0)
	# T1-GROUND-3: the verge honours `layer.band_scale` too, and it is the half
	# that matters most for reading a region change -- corridor_fill spreads
	# over 16.8 km2 the camera never sees, while every verge draw lands within
	# `inner + band` metres of an authored route, which is the ground the
	# player is standing on when they notice what the region is made of.
	#
	# Normalised by the layer's own LARGEST weight rather than applied raw:
	# a raw keep-roll would clip every weight at or above 1.0 to "keep
	# everything", collapsing exactly the distinction between the bands the
	# species belongs to. So the draw is scaled up by that maximum and each
	# candidate kept with weight/maximum, which preserves the ratios between
	# all five bands and leaves `count` meaning what it always did: the number
	# placed where the layer is at its thickest.
	#
	# A layer with no `band_scale` takes neither branch and consumes no extra
	# rng call, so its placements stay bit-identical to before this existed --
	# which is what lets the re-bake this shipped with be read as "the second
	# species moved" rather than "the whole meadow reshuffled".
	var band_gain := 1.0
	var layer_bands: Dictionary = layer.get("band_scale", {})
	var bands: Array = config().get("corridor_bands", [])
	if not layer_bands.is_empty():
		for weight: Variant in layer_bands.values():
			band_gain = maxf(band_gain, float(weight))
		count = int(round(float(count) * band_gain))
	for i in count:
		var u := rng.randf() * total
		var segment := segment_length.size() - 1
		for s in segment_length.size():
			if u <= segment_length[s]:
				segment = s
				break
			u -= segment_length[s]
		var tangent := (segment_b[segment] - segment_a[segment]).normalized()
		var along := segment_a[segment] + tangent * u
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var spot := along + Vector2(-tangent.y, tangent.x) * side * (inner + band * rng.randf())
		if not layer_bands.is_empty():
			if rng.randf() > _layer_band_scale_at(spot.y, bands, layer_bands) / band_gain:
				continue
		_consider(out, layer, field, models, spot, half, rng)


## VEG-CORRIDOR. `half`/`world_size` is still the old +-256m square everything
## above this samples — see `placements_for`'s own header. The corridor
## (`field.world_bounds()`) runs to x +-1024, z -512..7680, roughly 64x that
## square's area, and naively drawing the square's own density everywhere in
## it was measured to cost ~64x the instance count and, by extension, ~64x
## `scatter_rules.all_placements()`'s own share of boot time — the ~45s of a
## 3m08s boot (`PERF2`) that was already the single largest phase becomes
## something like 45 minutes. That is not a tuning question, it is a "the
## game does not boot" one, so this does not do that.
##
## Opt-in PER LAYER (`layer.corridor_fill`, absent/empty is a no-op, same
## contract as `verge`/`anchors`/`path_standoff`) rather than automatic: a
## hand-built layer Dictionary in a test (no `corridor_fill` key) must keep
## placing exactly what it always has, and layers this scatter has never
## tuned outside the square (the smallest ground-cover strays, mostly) should
## not silently start appearing 8km down the corridor because a global switch
## flipped.
##
## Candidates are drawn proportional to the CORRIDOR's area at the layer's own
## origin-square density (`clumps`/`strays` per m²) — not `world_size`'s old
## count — so a wide, sparse layer and a tight, dense one both fill at the
## rate they were already tuned to, rather than every layer getting the same
## flat instance budget. Each candidate is then kept or dropped by
## `_band_scale_at(z)`, the top-level `corridor_bands` table in
## vegetation.json — a z-ranged list of `density_scale` (0..1) that content
## lanes can tune per band without touching this file, which is what lets the
## corridor read as five different reaches instead of one uniform density
## rubber-stamped 64x wider. `layer.corridor_fill.density_scale` is a second,
## layer-wide multiplier on top of that (default 1.0) for a layer that should
## fill lighter (or not at all) than the band table alone would give it.
##
## The reject roll happens BEFORE the per-clump instances are drawn, so a
## dropped candidate costs one rng call and one dictionary lookup, not a
## wasted pass through `_consider`'s heightfield/slope/path sampling — the
## actual cost `all_placements` pays per candidate.
##
## Candidates whose CENTRE lands inside the old square are dropped outright,
## never merely thinned — the square's density was tuned across five visual
## passes and this must add to the corridor, never to ground already spoken
## for. A clump's spread can still nudge a few of its own instances back
## across that line; that is the same boundary softness `_place_anchor` and
## `_place_verge` already accept and is harmless, since nothing here can ever
## remove or move an instance the square already had.
static func _place_corridor_fill(
	out: Array[Dictionary], layer: Dictionary, field: RefCounted, models: Array,
	half: float, rng: RandomNumberGenerator
) -> void:
	var fill: Dictionary = layer.get("corridor_fill", {})
	if fill.is_empty():
		return
	if not field.has_method("world_bounds"):
		return
	var bounds: Dictionary = field.world_bounds()
	if bounds.is_empty():
		return
	var min_x := float(bounds.get("min_x", -half))
	var max_x := float(bounds.get("max_x", half))
	var min_z := float(bounds.get("min_z", -half))
	var max_z := float(bounds.get("max_z", half))
	var corridor_area := (max_x - min_x) * (max_z - min_z)
	var origin_side := half * 2.0
	var origin_area := origin_side * origin_side
	if corridor_area <= origin_area or origin_area <= 0.0:
		return

	# VEG-SITING: ceiling raised 1.0 -> 8.0. This multiplier was previously
	# capped at "the origin square's own per-area clump rate", which made
	# sense while every corridor layer matched the square's density exactly.
	# Trail-biased siting (below) means a layer can now afford to run
	# RICHER than the square per area actually covered, because the
	# candidates that would have landed on ground nobody walks near are the
	# ones being concentrated onto the trail instead -- the total instance
	# count this multiplies is still gated by `_band_scale_at`'s own
	# corridor_bands table, which is what actually protects the boot-time
	# budget (see corridor_bands' own comment in vegetation.json). TUNABLE
	# per layer; still defaults to 1.0 for any layer that never asks for more.
	var layer_scale := clampf(float(fill.get("density_scale", 1.0)), 0.0, 8.0)
	if layer_scale <= 0.0:
		return
	var bands: Array = config().get("corridor_bands", [])
	# T1-GROUND-3: this layer's own per-band weight on top of the band table.
	# See `_layer_band_scale_at` for why the two tables are separate.
	var layer_bands: Dictionary = layer.get("band_scale", {})

	var clumps := int(layer.get("clumps", 0))
	var per_clump := int(layer.get("per_clump", 0))
	var strays := int(layer.get("strays", 0))
	var spread := float(layer.get("clump_radius", 14.0))

	var candidate_clumps := int(round(float(clumps) / origin_area * corridor_area))
	var candidate_strays := int(round(float(strays) / origin_area * corridor_area))

	# VEG-SITING: see this function's own header for the area-proportional
	# candidate math above -- that part is unchanged. What changes is WHERE a
	# kept candidate's centre lands. `trail_bias` (0..1, TUNABLE per layer's
	# corridor_fill, default 0.0 -- no behaviour change for a layer that
	# doesn't opt in) draws that fraction of candidates from beside the
	# corridor's own authored routes instead of uniformly across the whole
	# min_x..max_x / min_z..max_z rectangle. See `_sample_near_trail`'s own
	# header for why: a uniform draw over a corridor 2048m wide spreads
	# copses across ground the player's own route never approaches, so a
	# viewpoint standing ON the trail can render bare no matter how the
	# per-clump/per-stray counts are tuned -- confirmed, not guessed:
	# docs/reviews/band2/round-05 measured HARVEST-ALL's 4x thickening as
	# byte-identical `spread` and pixel-identical frames on these same eight
	# viewpoints, because none of them happened to sit near a kept clump.
	var trail_bias := clampf(float(fill.get("trail_bias", 0.0)), 0.0, 1.0)
	var trail_offset_min := float(fill.get("trail_offset_min", 15.0))
	var trail_offset_max := float(fill.get("trail_offset_max", 65.0))
	var trail_segments: Dictionary = {}
	if trail_bias > 0.0:
		trail_segments = _trail_segments(field)
	# VP3: the ecology field. Absent -> `_ecology_gate` returns 1.0 for every
	# point and this function is byte-identical to before.
	var ecology: Dictionary = fill.get("ecology", {})

	for c in candidate_clumps:
		var centre := Vector2.ZERO
		# VP3: with an ecology block, redraw the centre until the field
		# accepts it (bounded). The keep roll below is untouched, so the
		# layer places the same NUMBER of clumps; only WHERE they land moves.
		for attempt in ECOLOGY_ATTEMPTS:
			centre = Vector2(rng.randf_range(min_x, max_x), rng.randf_range(min_z, max_z))
			if trail_bias > 0.0 and rng.randf() < trail_bias:
				var near_trail := _sample_near_trail(rng, trail_segments, trail_offset_min, trail_offset_max)
				if near_trail != Vector2.INF:
					centre = near_trail
			if ecology.is_empty() or rng.randf() <= _ecology_gate(centre, ecology):
				break
		var keep_chance := layer_scale * _band_scale_at(centre.y, bands) \
			* _layer_band_scale_at(centre.y, bands, layer_bands)
		if rng.randf() > keep_chance:
			continue
		if absf(centre.x) <= half and absf(centre.y) <= half:
			continue
		for i in per_clump:
			var angle := rng.randf_range(0.0, TAU)
			var radius := sqrt(rng.randf()) * spread
			var spot := centre + Vector2(sin(angle), cos(angle)) * radius
			_consider(out, layer, field, models, spot, half, rng)

	for s in candidate_strays:
		var spot := Vector2.ZERO
		for attempt in ECOLOGY_ATTEMPTS:
			spot = Vector2(rng.randf_range(min_x, max_x), rng.randf_range(min_z, max_z))
			if ecology.is_empty() or rng.randf() <= _ecology_gate(spot, ecology):
				break
		var keep_chance := layer_scale * _band_scale_at(spot.y, bands) \
			* _layer_band_scale_at(spot.y, bands, layer_bands)
		if rng.randf() > keep_chance:
			continue
		if absf(spot.x) <= half and absf(spot.y) <= half:
			continue
		_consider(out, layer, field, models, spot, half, rng)


## VEG-SITING. Every authored route (`field.path_polylines()`) as arc-length
## segments, for `_sample_near_trail` below. Built once per corridor_fill
## call -- a few hundred points at most across the whole 12km trail network
## -- not once per candidate; `path_polylines()` is itself cached
## (`playground_heightfield.gd::road_polylines`'s own `_road_polylines_ready`
## flag), so this is a cheap array walk, not a re-parse of the config.
static func _trail_segments(field: RefCounted) -> Dictionary:
	if field.has_method("path_polylines"):
		return _polyline_segments(field.path_polylines())
	return _polyline_segments([])


## VP3. One polyline set flattened into arc-length segments, the shape
## `_sample_near_trail` walks. `reaches` (optional, one PackedFloat32Array per
## polyline, one value per vertex) is a per-vertex "half-width" the sampler
## adds to its lateral offset -- zero for a trail, whose worn width the path
## gate already handles, but the river's channel is up to 20m across and its
## bank is `half_width + rim` out from the centreline, so a fixed offset from
## the centreline would put every draw in the water. `outward_from`, when a
## caller sets it on the result, makes the sampler take only the side facing
## away from that point: a pond's shore is a closed loop and "either side"
## of it is half in the pond.
static func _polyline_segments(polylines: Array, reaches: Array = []) -> Dictionary:
	var seg_a := PackedVector2Array()
	var seg_b := PackedVector2Array()
	var seg_length := PackedFloat32Array()
	var reach_a := PackedFloat32Array()
	var reach_b := PackedFloat32Array()
	var total := 0.0
	var has_reach := false
	for p in polylines.size():
		var line: PackedVector2Array = polylines[p]
		var reach: PackedFloat32Array = PackedFloat32Array()
		if p < reaches.size():
			reach = reaches[p]
		for i in line.size() - 1:
			var length := line[i].distance_to(line[i + 1])
			if length <= 0.001:
				continue
			seg_a.append(line[i])
			seg_b.append(line[i + 1])
			seg_length.append(length)
			if reach.size() > i + 1:
				reach_a.append(reach[i])
				reach_b.append(reach[i + 1])
				has_reach = true
			else:
				reach_a.append(0.0)
				reach_b.append(0.0)
			total += length
	var out := {"a": seg_a, "b": seg_b, "length": seg_length, "total": total}
	if has_reach:
		out["reach_a"] = reach_a
		out["reach_b"] = reach_b
	return out


## A point beside the trail rather than anywhere in the corridor's box: a
## random point along the authored routes by arc length (the same mechanism
## `_place_verge` already uses for the ground-cover fringe), stepped
## sideways by a random offset in `[offset_min, offset_max]`, mirrored to
## either shoulder so copses do not all favour one side of every leg.
## `Vector2.INF` if there is nothing to sample against (no routes
## configured), the same "no answer" contract `nearest_point_on_paths`
## already uses elsewhere in this file, so the caller falls back to its own
## uniform draw instead of collapsing every candidate to the map origin.
static func _sample_near_trail(
	rng: RandomNumberGenerator, segments: Dictionary, offset_min: float, offset_max: float
) -> Vector2:
	var total: float = segments.get("total", 0.0)
	if total <= 0.0:
		return Vector2.INF
	var seg_a: PackedVector2Array = segments["a"]
	var seg_b: PackedVector2Array = segments["b"]
	var seg_length: PackedFloat32Array = segments["length"]
	var u := rng.randf() * total
	var segment := seg_length.size() - 1
	for s in seg_length.size():
		if u <= seg_length[s]:
			segment = s
			break
		u -= seg_length[s]
	var tangent := (seg_b[segment] - seg_a[segment]).normalized()
	var along := seg_a[segment] + tangent * u
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var offset := lerpf(offset_min, offset_max, rng.randf())
	# VP3: a water course's bank is `reach` out from its centreline (see
	# `_polyline_segments`); a trail's is 0, so this is byte-identical for it.
	if segments.has("reach_a"):
		var reach_a: PackedFloat32Array = segments["reach_a"]
		var reach_b: PackedFloat32Array = segments["reach_b"]
		var t := u / maxf(seg_length[segment], 0.001)
		offset += lerpf(reach_a[segment], reach_b[segment], t)
	var normal := Vector2(-tangent.y, tangent.x)
	if segments.has("outward_from"):
		var centre: Vector2 = segments["outward_from"]
		# Only the bank side. The rng side draw above still happens so the
		# stream is consumed identically whether or not this key is set.
		side = 1.0 if normal.dot(along - centre) >= 0.0 else -1.0
	return along + normal * side * offset


## VP3. A copy of `layer` with one block's own keys laid over it, the same
## override contract `_place_anchor` gives an anchor: `scale_min`/`scale_max`
## for a different age class, `max_slope_deg` for a bank, `models` for a
## subset that suits the site. `skip` lists the block's own control keys, which
## are not layer keys. Every placement block is stripped so the local copy
## cannot recurse into itself.
static func _local_layer(layer: Dictionary, block: Dictionary, skip: Array) -> Dictionary:
	var local: Dictionary = layer.duplicate(true)
	for placement_key in ["anchors", "verge", "corridor_fill", "heroes", "water_edge"]:
		local.erase(placement_key)
	for key: Variant in block.keys():
		var name := str(key)
		if name in skip or name.begins_with("_"):
			continue
		local[name] = block[key]
	return local


## VP3: HERO TREES. `layer.heroes` (optional, TUNABLE) places a few LONE,
## oversized instances of the layer along the authored routes -- a landmark
## tree standing on its own in a clearing, which is the one silhouette a
## copse of same-sized trees can never produce and the one every reference
## board has. Sited by trail arc length (`_sample_near_trail`) so the player
## actually walks past them, then gated by an `ecology` block of its own --
## normally the `open` band of the shared tree field, so a hero stands in the
## gap BETWEEN groves rather than lost inside one -- and by `spacing`, the
## minimum distance to any hero already placed, so two never read as a pair.
##
##   count         how many to try for across the whole route network
##   trail_offset_min/max  lateral distance off the centreline
##   spacing       minimum metres between heroes (default 60)
##   ecology       optional gate, same keys as corridor_fill.ecology
##   anything else overrides the layer's own key for these draws only
##                 (scale_min/scale_max is the point; models narrows the list)
##
## Bounded like the corridor fill: a hero that finds no acceptable spot in
## ECOLOGY_ATTEMPTS draws is skipped, never spun on.
static func _place_heroes(
	out: Array[Dictionary], layer: Dictionary, field: RefCounted, models: Array,
	half: float, rng: RandomNumberGenerator
) -> void:
	var heroes: Dictionary = layer.get("heroes", {})
	if heroes.is_empty():
		return
	var count := int(heroes.get("count", 0))
	if count <= 0:
		return
	var segments := _trail_segments(field)
	if float(segments.get("total", 0.0)) <= 0.0:
		return
	var control := ["count", "trail_offset_min", "trail_offset_max", "spacing", "ecology"]
	var local := _local_layer(layer, heroes, control)
	var hero_models: Array = local.get("models", models)
	if hero_models.is_empty():
		hero_models = models
	var offset_min := float(heroes.get("trail_offset_min", 12.0))
	var offset_max := float(heroes.get("trail_offset_max", 45.0))
	var spacing := maxf(float(heroes.get("spacing", 60.0)), 0.0)
	var ecology: Dictionary = heroes.get("ecology", {})
	var placed := PackedVector2Array()
	for i in count:
		var spot := Vector2.INF
		for attempt in ECOLOGY_ATTEMPTS:
			var candidate := _sample_near_trail(rng, segments, offset_min, offset_max)
			if candidate == Vector2.INF:
				return
			if not ecology.is_empty() and rng.randf() > _ecology_gate(candidate, ecology):
				continue
			var crowded := false
			for other in placed:
				if other.distance_to(candidate) < spacing:
					crowded = true
					break
			if crowded:
				continue
			spot = candidate
			break
		if spot == Vector2.INF:
			continue
		var before := out.size()
		_consider(out, local, field, hero_models, spot, half, rng)
		if out.size() > before:
			placed.append(spot)


## VP3: THE WATER-EDGE BANDS. `layer.water_edge` (optional, TUNABLE) strings
## extra instances along the banks of the map's water -- the starter stream,
## the river and the pond's shoreline -- the way `verge` strings them along
## the paths. The bible's "stream vegetation / wet-ground bands" and the
## reference boards' reeds-and-willows waterline were unreachable before
## this: the scatter's only relationship to water was the gates that keep
## things OUT of it, so a bank read as the same meadow as everywhere else,
## cut off by a waterline.
##
## Courses come from the terrain config the field was built from, read
## through the field (`_water_segments`), not re-parsed from disk, so a test
## field built on its own config gets its own water. Each course carries its
## bank as a per-vertex reach (`_polyline_segments`): the stream's water
## half-width plus shoulder, the river's `half_width + rim`, the pond's
## traced shoreline at zero -- and draws step `offset_min..offset_max` metres
## beyond that, onto the bank. `_consider`'s own stream/river gates and
## `_drop_below_waterline` still apply, so an offset that lands wet is
## rejected rather than planted.
##
##   per_100m      instances per hundred metres of bank (before gating)
##   sources       {stream: mult, river: mult, pond: mult}; absent source = 0
##   offset_min/max  metres beyond the bank line
##   anything else overrides the layer's own key for these draws only
##                 (models is the point: the reed rosette belongs here and
##                 nowhere else; scale/slope for a bank)
static func _place_water_edge(
	out: Array[Dictionary], layer: Dictionary, field: RefCounted, models: Array,
	half: float, rng: RandomNumberGenerator
) -> void:
	var edge: Dictionary = layer.get("water_edge", {})
	if edge.is_empty():
		return
	var per_100m := float(edge.get("per_100m", 0.0))
	if per_100m <= 0.0:
		return
	var sources: Dictionary = edge.get("sources", {"stream": 1.0, "river": 1.0, "pond": 1.0})
	var control := ["per_100m", "sources", "offset_min", "offset_max"]
	var local := _local_layer(layer, edge, control)
	var edge_models: Array = local.get("models", models)
	if edge_models.is_empty():
		edge_models = models
	var offset_min := float(edge.get("offset_min", 0.5))
	var offset_max := float(edge.get("offset_max", 6.0))
	var courses := _water_segments(field)
	# Fixed order so the rng stream does not depend on Dictionary iteration.
	for source in ["stream", "river", "pond"]:
		var multiplier := float(sources.get(source, 0.0))
		if multiplier <= 0.0 or not courses.has(source):
			continue
		var segments: Dictionary = courses[source]
		var total: float = segments.get("total", 0.0)
		if total <= 0.0:
			continue
		var count := int(round(per_100m * multiplier * total / 100.0))
		for i in count:
			var spot := _sample_near_trail(rng, segments, offset_min, offset_max)
			if spot == Vector2.INF:
				break
			_consider(out, local, field, edge_models, spot, half, rng)


## How many rays the pond shoreline is traced with, and how far out from
## `pond_centre` each ray looks before giving up. 72 gives a 5-degree polygon
## on a ~100m basin: a few metres of chord error, under the offset band.
const POND_SHORE_RAYS := 72
const POND_SHORE_REACH := 260.0
const POND_SHORE_STEP := 2.0

static var _water_cache: Dictionary = {}

## The map's water courses as `_polyline_segments` sets, keyed "stream",
## "river", "pond" -- built once per field and cached on the field's own
## identity, since tracing the pond shore is a few thousand height samples.
##
## The config is read off the field (`_config`, the dictionary it was built
## from) rather than `HEIGHTFIELD.load_config()`, so a test field carrying a
## custom config sees its own water and a field with none sees none.
static func _water_segments(field: RefCounted) -> Dictionary:
	var key := field.get_instance_id()
	if _water_cache.has(key):
		return _water_cache[key]
	var courses: Dictionary = {}
	var config: Variant = field.get("_config")
	if config is Dictionary and not (config as Dictionary).is_empty():
		var cfg: Dictionary = config
		var water: Dictionary = cfg.get("water", {})
		# The starter stream: an authored point list, one water half-width
		# plus shoulder either side (the same numbers `stream_factor` gates on).
		var stream: Dictionary = water.get("stream", {})
		var points: Array = stream.get("points", [])
		if points.size() >= 2:
			var line := PackedVector2Array()
			var reach := PackedFloat32Array()
			var bank := float(stream.get("width", 2.4)) * 0.5 + float(stream.get("shoulder", 1.2))
			for p: Variant in points:
				line.append(Vector2(float((p as Array)[0]), float((p as Array)[1])))
				reach.append(bank)
			courses["stream"] = _polyline_segments([line], [reach])
		# The river: `half_width + rim` per course vertex is the top of the
		# bank, exactly where `river_factor` falls to zero.
		var course: Array = cfg.get("river", {}).get("course", [])
		if course.size() >= 2:
			var line := PackedVector2Array()
			var reach := PackedFloat32Array()
			for entry: Variant in course:
				var vertex: Dictionary = entry
				var at: Array = vertex.get("at", [])
				if at.size() < 2:
					continue
				line.append(Vector2(float(at[0]), float(at[1])))
				reach.append(float(vertex.get("half_width", 9.0)) + float(vertex.get("rim", 5.0)))
			courses["river"] = _polyline_segments([line], [reach])
		# The pond: no authored outline, so the shoreline is traced -- walk
		# each ray out from the centre until the ground first rises above the
		# waterline and keep that point. Skipped entirely if the map has no
		# level or no centre.
		var pond_at: Array = water.get("pond_centre", [])
		if pond_at.size() >= 2 and water.has("level") and field.has_method("height_at"):
			var centre := Vector2(float(pond_at[0]), float(pond_at[1]))
			var level := float(water.get("level"))
			var shore := PackedVector2Array()
			for r in POND_SHORE_RAYS:
				var angle := TAU * float(r) / float(POND_SHORE_RAYS)
				var dir := Vector2(cos(angle), sin(angle))
				var found := Vector2.INF
				var d := POND_SHORE_STEP
				while d <= POND_SHORE_REACH:
					var p := centre + dir * d
					var h: float = field.height_at(p.x, p.y)
					if not is_nan(h) and h > level + 0.1:
						# Bisect the last step so the chord sits on the line.
						var lo := d - POND_SHORE_STEP
						var hi := d
						for it in 6:
							var mid := (lo + hi) * 0.5
							var pm := centre + dir * mid
							var hm: float = field.height_at(pm.x, pm.y)
							if is_nan(hm) or hm > level + 0.1:
								hi = mid
							else:
								lo = mid
						found = centre + dir * hi
						break
					d += POND_SHORE_STEP
				if found != Vector2.INF:
					shore.append(found)
			if shore.size() >= 3:
				shore.append(shore[0])
				var segments := _polyline_segments([shore])
				segments["outward_from"] = centre
				courses["pond"] = segments
	_water_cache[key] = courses
	return courses


## The `density_scale` (0..1, TUNABLE) of the first band in `corridor_bands`
## (vegetation.json, top-level) whose `[z_min, z_max)` contains `z`. 1.0 (full
## origin-square density) if `bands` is empty or `z` matches none of them, so
## an unconfigured corridor fills at the same rate the old square was tuned
## to rather than silently going bald outside every authored band.
static func _band_scale_at(z: float, bands: Array) -> float:
	for entry: Variant in bands:
		var band: Dictionary = entry
		if z >= float(band.get("z_min", -INF)) and z < float(band.get("z_max", INF)):
			return clampf(float(band.get("density_scale", 1.0)), 0.0, 1.0)
	return 1.0


## T1-GROUND-3. A layer's OWN per-band weight, multiplied on top of the
## chapter-wide `corridor_bands` table above. Optional and defaulting to 1.0,
## so every layer that does not carry the key places exactly what it placed
## before this existed.
##
## The two tables answer different questions and neither can answer the
## other's. `corridor_bands.density_scale` is how much scatter a band can
## AFFORD -- one number for all eleven layers, tuned against boot cost and the
## placement ceiling, which is why it is clamped to 0..1 and why a content lane
## moves it for budget reasons. `layer.band_scale` is which SPECIES that band
## is made of, which is a look question with no budget content: shifting a
## layer's share from band 1 to band 5 costs the same placements either way.
##
## Without it, "regional differentiation is prop-deep -- bands 1, 3, 4 and 5
## share the same grass carpet, same tree family, same palette; they differ by
## what is parked on them" (2026-08-29 blind pass, subject 8) is not reachable
## from config at all: the only per-band lever was one scalar that thins every
## layer together, so a band could be sparser or denser but never made of
## different plants. This is the lever that lets the dry species thicken toward
## the stronghold while the green stays where it is.
##
## Keyed by the band's own `id` in `corridor_bands` rather than by index, so a
## band inserted or reordered cannot silently move a weight onto its
## neighbour. NOT clamped to 1.0 -- unlike the affordability table above, a
## value over 1 is meaningful here (this band is where the species belongs);
## the product still passes through `randf() > keep_chance`, so anything at or
## over 1 simply keeps every candidate the affordability table already allowed.
static func _layer_band_scale_at(z: float, bands: Array, band_scale: Dictionary) -> float:
	if band_scale.is_empty():
		return 1.0
	for entry: Variant in bands:
		var band: Dictionary = entry
		if z >= float(band.get("z_min", -INF)) and z < float(band.get("z_max", INF)):
			return maxf(float(band_scale.get(str(band.get("id", "")), 1.0)), 0.0)
	return 1.0


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
## OF12 removed the rest of the path-proximity toolkit that used to live
## here — `path_bias_jitter`, `path_bias_side_offset`, `path_bias_per_clump`
## and `path_avoid_radius`. All four were CONSTANT-DISTANCE rules measured
## from the path centreline, and five verified tuning rounds
## (`EV3-remainder` through `-6`, see `DONE.md`) never moved the owner's
## verdict on `grandpas-house-route.png` past "a landscaped flanking
## border", because the defect was never any one distance — it was the
## constancy. A rule that holds every instance exactly N metres off the
## centreline, or anchors clumps to it, produces edges geometrically
## parallel to the path at matched offsets on both sides no matter what N
## is. Ground-cover layers now use `path_standoff` (see `_consider`), whose
## exclusion distance drifts with position noise and is sampled per SIDE of
## the path, so a matched pair across the path cannot occur by
## construction. `path_bias` itself survives for `path_stones` only:
## stones ARE the path, and the exact centreline snap is correct for them.
static func _clump_centre(
	rng: RandomNumberGenerator, half: float, field: RefCounted, ridge_bias: float,
	path_bias: float = 0.0
) -> Vector2:
	var base := Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))

	if path_bias > 0.0 and rng.randf() <= path_bias and field.has_method("nearest_point_on_paths"):
		var on_path: Vector2 = field.nearest_point_on_paths(base.x, base.y)
		if on_path != Vector2.INF:
			base = on_path

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


## The exclusion distance a `path_standoff` layer keeps from the path at
## this exact spot, in metres — `lerp(min, max, noise)`, where the noise is
## coherent over `wavelength` metres, so the meadow's edge advances to the
## worn dirt in one stretch and retreats several metres in the next instead
## of tracing a constant offset. Config keys, all TUNABLE per layer:
## `min`/`max` (the standoff's range), `wavelength` (how many metres one
## advance-or-retreat lasts; the Grandpa's-house frame sees ~20m of path,
## so a wavelength near 15 gives it at least one full swing), `salt`
## (decorrelates layers from each other, so grass and drygrass do not
## advance and retreat in lockstep).
##
## Two properties are load-bearing, both aimed at the "flanking" read:
## - The noise is sampled with the SIDE of the path folded into the hash,
##   so the left verge and the right verge draw from independent fields
##   even directly across from each other. Symmetric-pair edges — the
##   matched border five tuning rounds never killed — are impossible by
##   construction, not just unlikely.
## - Two octaves: the coarse one moves the edge in ~wavelength stretches,
##   the fine one (a quarter the wavelength, a third the weight) frays the
##   edge itself so a locally-flat stretch of the coarse noise cannot
##   print a straight line.
##
## Pure function of position and config — no RNG state — so placement
## order cannot change it and a test can probe it directly.
static func path_standoff_at(
	spot: Vector2, nearest_path_point: Vector2, standoff_config: Dictionary, field: RefCounted
) -> float:
	var min_standoff := float(standoff_config.get("min", 0.0))
	var max_standoff := float(standoff_config.get("max", 0.0))
	if max_standoff <= min_standoff:
		return min_standoff
	var wavelength := maxf(float(standoff_config.get("wavelength", 16.0)), 1.0)
	var salt := int(standoff_config.get("salt", 0))
	var side := 0
	if field != null and field.has_method("nearest_path_tangent"):
		var tangent: Vector2 = field.nearest_path_tangent(nearest_path_point.x, nearest_path_point.y)
		if tangent.cross(spot - nearest_path_point) < 0.0:
			side = 1
	var coarse := _value_noise(spot / wavelength, salt * 131 + side)
	var fine := _value_noise(spot / (wavelength * 0.25), salt * 131 + side + 977)
	return lerpf(min_standoff, max_standoff, clampf(coarse * 0.7 + fine * 0.3, 0.0, 1.0))


## VP3 (visual parity program, 2026-09-01). THE ECOLOGY FIELD, and why the
## corridor read as "uniform procedural noise" in every blind pass.
##
## `_place_corridor_fill` draws clump centres UNIFORMLY over the corridor
## rectangle and keeps each by an independent Bernoulli roll. That is a
## Poisson process: at 150+ clumps per kilometre with 6.5m clump envelopes it
## averages to "no bare patches, no thickets" -- the same density everywhere,
## which is exactly the read the handover for T1-WORLD root-caused and the
## judges keep naming ("scattered rather than composed", "identical clumps at
## uniform scale"). Nature is not Poisson. Trees stand in groves with open
## ground between; bushes and saplings crowd the grove's EDGE where the light
## is; flowers and dry grass take the clearings.
##
## The field is one low-frequency value noise (the same lattice noise
## `_thin_by_drain` uses -- position and salt only, deterministic) sampled at
## a candidate centre and turned into an ACCEPTANCE PROBABILITY in [0, 1].
## `_place_corridor_fill` redraws a rejected centre (bounded by
## ECOLOGY_ATTEMPTS) rather than dropping it, so a layer places the same
## number of clumps as before -- the corridor floor in test_veg_corridor.gd
## and the boot budget do not move -- and only WHERE they land changes.
##
##   core: eco^gamma                -- masses with open ground between
##   edge: 1 - |eco - 0.5| * 2      -- a ring where the mask crosses 0.5
##   open: (1 - eco)^gamma          -- the clearings
##
## Layers that share a `salt` see the SAME field, which is the whole trick:
## trees on `core`, bushes/saplings on `edge` and flowers on `open` of one
## salt gives groves with understory rings and flowered clearings between,
## without any cross-layer bookkeeping. `contrast` mixes the probability
## toward 1.0 so a layer can opt in gently. `wavelength` is the noise's cell
## size in metres: ~120m puts two or three groves in a 400m view. The field is
## contrast-stretched before shaping because bilinear value noise crowds the
## middle of its range. Absent block -> no extra RNG draws -> byte-identical
## placements. TUNABLE, all of it, per layer under `corridor_fill.ecology`.
const ECOLOGY_ATTEMPTS := 8

static func _ecology_gate(point: Vector2, ecology: Dictionary) -> float:
	if ecology.is_empty():
		return 1.0
	var wavelength := maxf(8.0, float(ecology.get("wavelength", 120.0)))
	var salt := int(ecology.get("salt", 7001))
	var gamma := maxf(1.0, float(ecology.get("gamma", 2.5)))
	var contrast := clampf(float(ecology.get("contrast", 0.85)), 0.0, 1.0)
	# Two octaves so a grove has an irregular outline rather than a blob, then
	# stretched about the midpoint so the extremes are actually reachable.
	var raw := _value_noise(point / wavelength, salt) * 0.7 \
			+ _value_noise(point / (wavelength * 0.37) + Vector2(11.3, 7.1), salt + 17) * 0.3
	var eco := clampf((raw - 0.5) * 1.8 + 0.5, 0.0, 1.0)
	var g := 1.0
	match str(ecology.get("band", "core")):
		"core":
			g = pow(eco, gamma)
		"open":
			g = pow(1.0 - eco, gamma)
		"edge":
			g = 1.0 - absf(eco - 0.5) * 2.0
		"under":
			# VP3 round 1: the fringe AND the interior. `edge` alone peaks at
			# the grove's outline and falls to nothing under the canopy, which
			# left every grove floor bare -- the understory the bible asks for
			# ("bushes beneath trees") has to be allowed where the trees are,
			# not only around them.
			g = maxf(1.0 - absf(eco - 0.5) * 2.0, pow(eco, gamma))
		_:
			g = 1.0
	# `floor` (0..1, default 0): the acceptance a band never drops below, so
	# a species that mostly belongs to one band still strays into the others
	# -- a lone bush in a clearing, a fern outside the wood.
	g = maxf(g, clampf(float(ecology.get("floor", 0.0)), 0.0, 1.0))
	return lerpf(1.0, g, contrast)


## Smoothed value noise on an integer lattice, in [0, 1]. Deterministic from
## position and salt alone — the same spot always gets the same value, which
## is what lets the standoff above be a stable property of the terrain
## rather than of the order things were placed in.
static func _value_noise(point: Vector2, salt: int) -> float:
	var cell_x := floori(point.x)
	var cell_y := floori(point.y)
	var fraction_x := point.x - cell_x
	var fraction_y := point.y - cell_y
	# Smoothstep the interpolant, or the lattice prints visible creases.
	var smooth_x := fraction_x * fraction_x * (3.0 - 2.0 * fraction_x)
	var smooth_y := fraction_y * fraction_y * (3.0 - 2.0 * fraction_y)
	var corner_a := _lattice_value(cell_x, cell_y, salt)
	var corner_b := _lattice_value(cell_x + 1, cell_y, salt)
	var corner_c := _lattice_value(cell_x, cell_y + 1, salt)
	var corner_d := _lattice_value(cell_x + 1, cell_y + 1, salt)
	return lerpf(lerpf(corner_a, corner_b, smooth_x), lerpf(corner_c, corner_d, smooth_x), smooth_y)


static func _lattice_value(cell_x: int, cell_y: int, salt: int) -> float:
	# An explicit integer mix rather than Godot's hash(): the meadow's layout
	# must not depend on engine hashing internals staying stable across
	# versions.
	var mixed := cell_x * 374761393 + cell_y * 668265263 + salt * 2147483647
	mixed = (mixed ^ (mixed >> 13)) * 1274126177
	mixed = mixed ^ (mixed >> 16)
	return float(mixed & 0xffff) / 65535.0


## OW5E. `half` is `world_size * 0.5` — the OLD world's symmetric, origin-
## centred square, still the right bound for a clump/stray candidate (their
## own sampling never draws outside it; see `placements_for`). It is the
## WRONG bound for an authored `anchor`, whose `at` is an absolute world
## coordinate with no relationship to `half` at all: every anchor placed
## anywhere in the corridor beyond the old +-256m square (the quarry's own
## `deadfall` anchor at (403,1803) included) was silently rejected on every
## single attempt, which is why `tests/smoke_boss.gd`'s D41 regrowth check
## found nothing had ever been drained -- the one authored placement inside
## any drain station's radius could never exist in the first place. Checked
## against `field.world_bounds()` (the corridor's real, non-square,
## non-origin-centred extent) when the field has one; falls back to the old
## square for a bare/legacy config. This widens what an ANCHOR may pass, not
## what a clump/stray may sample — `half` itself, and every clump/stray call
## site, is untouched, so the already-tuned Band 0 density is unaffected.
static func _out_of_bounds(field: RefCounted, spot: Vector2, half: float) -> bool:
	if field.has_method("world_bounds"):
		var bounds: Dictionary = field.world_bounds()
		if not bounds.is_empty():
			return spot.x < float(bounds.get("min_x", -half)) \
				or spot.x > float(bounds.get("max_x", half)) \
				or spot.y < float(bounds.get("min_z", -half)) \
				or spot.y > float(bounds.get("max_z", half))
	return absf(spot.x) > half or absf(spot.y) > half


static func _consider(
	out: Array[Dictionary], layer: Dictionary, field: RefCounted,
	models: Array, spot: Vector2, half: float, rng: RandomNumberGenerator
) -> void:
	if _out_of_bounds(field, spot, half):
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
			# Floor at a small positive value: `path_factor` is exactly 0.0
			# everywhere except the few metres around a route, so a jitter
			# draw that pushes the threshold below zero rejects instances
			# ACROSS THE WHOLE MAP, not just at the path edge — a silent
			# global density cut that grew with the jitter. Found in OF12's
			# round-2 blind pass chasing "the meadow is close to empty".
			threshold = maxf(threshold + rng.randf_range(-edge_jitter, edge_jitter), 0.02)
		if float(field.path_factor(spot.x, spot.y)) > threshold:
			return

	# OP21-19: a hard floor at the pond's own waterline, underneath every
	# layer's `min_height`. Written first as a gate right here; that was the
	# bug, and the fix is `_drop_below_waterline` below. The pond is handled by height, not a band — see
	# `playground_heightfield.gd::water_level()`'s own comment, "below this
	# height and underwater are the same statement" — so per-layer
	# `min_height` (vegetation.json) is normally enough on its own to let reeds
	# and marsh grass wade a little into the shallows while keeping trees dry.
	# It is not a *geometric* gate, though: it is one more tunable number per
	# layer, and OW5D's blind (-250,+407) relocation of the pond basin moved
	# `water.level` (from -22.5 to -17.0, restoring a rendered surface at the
	# new basin) without anyone re-deriving those per-layer numbers, which is
	# exactly how trees/bushes ended up standing in the new water — every
	# layer's `min_height` was still anchored to the OLD, deeper waterline
	# (fixed alongside this gate, see vegetation.json). This is the backstop:
	# whatever a layer's own `min_height` says, nothing stands more than half
	# a metre below the CURRENT water surface. Half a metre, not zero, so a
	# layer that deliberately wades the shore_step lip (grass/reeds) is not
	# pushed dry — it only stops anything from standing in water deep enough
	# to read as "in the pond" rather than "at its edge."
	# The pond's waterline is NOT gated here. It is applied as a filter over
	# the finished list -- see `_drop_below_waterline`, and see
	# `_thin_by_drain`'s header for the rule both of them obey.

	# Nothing grows IN the stream channel either (EV5) — a grass tuft standing
	# mid-current reads as a bug the way a tree on a path does. Same shape as
	# the path gate above, same per-instance edge jitter so the channel's clear
	# band ravels instead of tracing an exact offset curve. The pond's OWN
	# waterline is now also a hard gate (immediately above); per-layer
	# `min_height` remains for how far into the shallows a wading layer goes.
	if not bool(layer.get("grows_in_stream", false)) and field.has_method("stream_factor"):
		var stream_jitter := float(layer.get("path_edge_jitter", 0.0))
		var stream_threshold := 0.35
		if stream_jitter > 0.0:
			# Same positive floor as the path gate above, same global-cull bug.
			stream_threshold = maxf(stream_threshold + rng.randf_range(-stream_jitter, stream_jitter), 0.02)
		if float(field.stream_factor(spot.x, spot.y)) > stream_threshold:
			return

	# SE21: nor in the river's channel, and here it matters more than it does
	# for the brook. The river's bed is 10-18m below its rims and, at the
	# bottom, FLAT and gentle -- exactly the ground every layer's slope rule
	# says yes to -- so without this gate the scatter grows a meadow, with
	# trees in it, along the floor of a river, several metres under the water
	# surface. Same shape and same jitter as the two gates above; the reeds and
	# scrub that DO belong at this waterline are placed by water.gd against the
	# river's own measured shoreline, not by this scatter.
	if not bool(layer.get("grows_in_stream", false)) and field.has_method("river_factor"):
		var river_jitter := float(layer.get("path_edge_jitter", 0.0))
		var river_threshold := 0.2
		if river_jitter > 0.0:
			river_threshold = maxf(river_threshold + rng.randf_range(-river_jitter, river_jitter), 0.02)
		if float(field.river_factor(spot.x, spot.y)) > river_threshold:
			return

	# `path_standoff` (OF12): how far off a path this layer keeps, and the
	# replacement for `path_avoid_radius`'s constant exclusion circle. The
	# owner's verdict on `grandpas-house-route.png` — a landscaped
	# "flanking" border — survived five verified rounds of tuning constant
	# distances (`EV3-remainder` through `-6`), because a constant IS a
	# border: every instance held exactly N metres off the centreline gives
	# the meadow a ruler-straight inner edge at the same offset on both
	# sides of the road. A real footpath's verge does the opposite — growth
	# crowds the worn edge in one stretch and stands metres back in the
	# next, and the two sides do it independently. So the exclusion
	# distance here drifts between `min` and `max` with coherent position
	# noise (`path_standoff_at`), decorrelated per side of the path, and
	# raveled at metre scale by a second octave. One mechanism for clump
	# instances and strays alike.
	if field.has_method("nearest_point_on_paths"):
		var standoff_config: Dictionary = layer.get("path_standoff", {})
		if not standoff_config.is_empty():
			var nearest_path_point: Vector2 = field.nearest_point_on_paths(spot.x, spot.y)
			if nearest_path_point != Vector2.INF:
				var distance := spot.distance_to(nearest_path_point)
				if distance < path_standoff_at(spot, nearest_path_point, standoff_config, field):
					return

	# `base_scale` corrects the pack's authoring scale for the whole layer;
	# scale_min/max then vary around it. Two numbers rather than one so "the
	# trees are too small" and "the trees are all the same size" stay separate
	# complaints with separate fixes.
	var base := float(layer.get("base_scale", 1.0))
	var low := float(layer.get("scale_min", 0.85)) * base
	var high := float(layer.get("scale_max", 1.25)) * base
	var instance_scale := rng.randf_range(low, high)
	var model := str(models[rng.randi_range(0, models.size() - 1)])
	var yaw := rng.randf_range(0.0, TAU)

	# WORLD-GRASS. `model_scale` (vegetation.json, optional, model path -> float,
	# default 1.0 for anything unlisted) multiplies ONE model's draws inside a
	# layer that otherwise shares `scale_min`/`scale_max`.
	#
	# Why it has to exist: this layer's `scale_min`/`scale_max` is the only size
	# lever, and it applies to every model equally, so a layer holding a 1.20m
	# mesh and a 1.84m mesh can only ever render them 53% apart however the
	# range is tuned. A blind critic looking at the grass layer's four species
	# read them as "a single blade-fan type, always roughly knee height" and
	# called the even result generator output -- which it was, because there was
	# no way to say "the tall species is genuinely tall and the wide one is
	# genuinely low". `vegetation.json`'s own `_comment_species_of12_b` names
	# the same gap from the other side ("scatter_rules.gd has no per-model
	# weight/scale field") while adding a second species it could not
	# differentiate. This is that field.
	#
	# RNG-SAFE BY CONSTRUCTION, and that is why the model and yaw draws moved
	# above rather than the multiplier being folded into `low`/`high`. Both
	# draws still happen, in the same order, drawing the same values from the
	# same stream; the multiplier is applied to the RESULT. So a layer with no
	# `model_scale` key places byte-identically to before this change -- which
	# matters more here than usual, because a stream perturbation reshuffles
	# every clump in the corridor and invalidates every tuned anchor position in
	# this file.
	var model_scale: Dictionary = layer.get("model_scale", {})
	if model_scale.has(model):
		instance_scale *= float(model_scale[model])

	# `sink`: metres of the prop buried at scale 1.0, times its own scale, so a
	# big block sits deeper than a cobble. A blind critic on the first round of
	# OF4-remainder-mound's outcrops: "boulders of that mass do not rest tangent
	# on a smooth slope... they sit part-buried in a scar they made. Every one
	# of these sits on the surface." Placement cannot make a scar, but it can
	# stop a rock balancing on the ground plane — and burying the foot also
	# hides the gap `align_to_slope` still leaves on broken ground. Opt-in per
	# layer or per anchor, defaults to 0, and never applied to anything that
	# grows: a half-buried tree is a bug.
	var sink := float(layer.get("sink", 0.0)) * instance_scale
	var placement := {
		"model": model,
		"position": Vector3(spot.x, height - sink, spot.y),
		"yaw": yaw,
		"scale": instance_scale,
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
##
## OF12-remainder: a layer may also carry its own `seed_offset` (int,
## TUNABLE, default 0) added on top of the per-layer 7919 stride. That is
## for re-rolling ONE layer's own RNG stream in place -- the `trees` layer
## used it to break a mirrored pair of copses the-rise-route's viewpoint
## framed like a gateway (three blind critics named it, all seed luck, no
## authored anchor involved) without perturbing every other layer's
## already-tuned placement the way changing the top-level `seed` would.
static func all_placements(field: RefCounted, world_size: float, base_seed: int,
		drained_out: Dictionary = {}) -> Dictionary:
	var layers: Dictionary = config().get("layers", {})
	var built: Dictionary = {}
	var offset := 0
	for name: String in layers.keys():
		if name.begins_with("_"):
			continue
		var layer: Dictionary = layers[name]
		var seed_value := base_seed + offset * 7919 + int(layer.get("seed_offset", 0))
		var removed: Array[Dictionary] = []
		built[name] = placements_for(layer, field, world_size, seed_value, removed)
		if not removed.is_empty():
			drained_out[name] = removed
		offset += 1
	return built
