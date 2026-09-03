extends MultiMeshInstance3D

## GRASS-FIELD. The camera-relative ground cover that replaces stored grass
## placements.
##
## `shaders/grass_field.gdshader` carries the argument for why this exists; the
## short version is that `ralph/reports/WORLD_GRASS_2026-08-25.md` measured a
## continuous carpet at ~40x outside the chapter's placement ceiling however it
## is spent, so a system that stores a transform per tuft cannot reach it. This
## stores nothing: a fixed ring of tufts follows the camera and the vertex
## shader puts each one on the terrain surface by sampling Terrain3D's own
## height data.
##
## Cost is a function of the RING, not of the world. The same number of tufts
## renders standing in the village and eight kilometres down the corridor, and
## nothing about it grows when the corridor does.
##
## OFF BY DEFAULT, AND THAT IS THE POINT. `data/config/grass_field.json`'s
## `enabled` decides, the scatter path is left completely intact behind it, and
## `suppress_scatter_layers` names the layers `vegetation.gd` skips when this is
## on. The one thing this container cannot measure is the only hardware that
## matters (`PERF-ROG-GPU`: Compatibility counts MultiMesh batches, not
## instances, and this box rasterises in software), so the owner has to be able
## to A/B it on the Ally and a bad result has to be one flag away from gone.
##
## Everything here is vertex maths, one texelFetch and an alpha scissor. No
## compute shader, no RenderingDevice, no subsurface scattering -- Godot lists
## all three as unsupported on the GL Compatibility renderer that `D01` locks
## this project to.

const CONFIG_PATH := "res://data/config/grass_field.json"
const SHADER_PATH := "res://shaders/grass_field.gdshader"
const STONE_SHADER_PATH := "res://shaders/stone_field.gdshader"
const COVER_SHADER_PATH := "res://shaders/cover_tier.gdshader"
const FAR_SHADER_PATH := "res://shaders/far_cover.gdshader"
## Read for its `footprints` list and nothing else -- see the BUILT GROUND note
## below. The two systems have to exclude the same building ground, and the way
## to guarantee that is to read one list rather than keep two in step.
const SCATTER_RULES := preload("res://scripts/world/scatter_rules.gd")

## Read once and cached, the same way `scatter_rules.gd::config()` does it, so a
## test can ask what the config says without standing a world up.
static var _config: Dictionary = {}

## Test seam. `data/config/grass_field.json`'s `enabled` is the production
## switch and defaults to off; a probe or a smoke test that wants the field
## standing without editing the shipped config sets this before adding the node
## to the tree. Deliberately NOT a way to turn it on in the game -- nothing in
## `scripts/` sets it.
@export var force_enabled := false

var _camera: Camera3D = null
## T1-GROUND-3. Set once the first time the rendering camera turns out not to
## be the bound one, so `_follow_camera` complains loudly exactly once instead
## of every frame. See that function for the evidence-integrity bug this is.
var _warned_camera_swap := false
var _terrain: Node = null
var _material: ShaderMaterial = null
## The stone tier rides as a CHILD of this node, so the camera-follow in
## `_process` moves both rings with one transform write and the two can never
## disagree about where the field is centred.
var _stones: MultiMeshInstance3D = null
var _stone_material: ShaderMaterial = null
## Every generic cover tier's material -- bushes, flowers, litter. They all
## run `shaders/cover_tier.gdshader` and differ only by mesh and config, so
## binding, centring and winding them is one loop rather than one branch per
## tier.
var _cover_materials: Array[ShaderMaterial] = []
## The far tier. One MeshInstance3D, not a MultiMesh -- see FAR COVER below --
## riding as a child of this node so the camera-follow moves it too, with its
## own offset so its vertices stay on their own coarser world grid.
var _far: MeshInstance3D = null
var _far_material: ShaderMaterial = null
var _bound := false
var _wind := 0.0
## The lattice cell the ring is currently anchored to. The node only moves when
## this changes, which is most frames a no-op; `field_centre` is written every
## frame and is a different thing -- see `_process`.
var _centre := Vector3(INF, INF, INF)
## How many tuft instances the ring stood up, across every tile. The ring's own
## `multimesh` is null once tiled, so the count lives here.
var _ring_instances := 0


static func config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_config = parsed
	return _config


## Whether the field is on. Read by `vegetation.gd` as well as by this node, so
## the two cannot disagree about which system owns the ground.
static func is_enabled() -> bool:
	return bool(config().get("enabled", false))


## Layer names `vegetation.gd` skips while the field is on. Returned as a
## Dictionary-as-set so the caller's inner loop is a hash lookup, not a scan.
static func suppressed_layers() -> Dictionary:
	var out: Dictionary = {}
	if not is_enabled():
		return out
	for name: Variant in config().get("suppress_scatter_layers", []):
		out[str(name)] = true
	return out


# ---------------------------------------------------------------------------
# STABLE RING. Where the items in the ring stand, and why it is not a disc of
# random points any more.
#
# THE DEFECT THIS ANSWERS, in the owner's words on 2026-08-28: "the grass
# rerenders like every step". `docs/owner/OWNER_PLAYTEST_2026-08-28.md` is the
# record, and the same note carries the other half of the report -- "don't
# change the look of my grass, it's awesome" -- so this is a placement change
# that is required to leave density, colour, silhouette, wind and every cover
# tier exactly where they were.
#
# THE MECHANISM. The ring is a fixed set of LOCAL positions and it follows the
# camera by moving this node. Every coverage roll, height, lean and shade in
# the three field shaders is hashed on the item's WORLD position. So the moment
# the node moves, every item's world position moves with it and every one of
# those hashes returns a fresh number: the field does not translate, it
# RE-ROLLS. `snap` did not remove that, it made it periodic -- one whole-field
# re-roll every `snap` metres, which at combat.json's 5 m/s walk is one every
# 0.4 seconds. That is the "every step".
#
# THE FIX, stated as the constraint it really is: moving the ring by one snap
# step must map the set of occupied world positions onto ITSELF. A set of
# points with that property is a lattice (strictly: any pattern periodic in the
# snap step, and a lattice is the one that also carries a density gradient
# cheaply). So the instances are laid out on a world-aligned grid of `snap`
# metre cells, the node only ever moves in whole cells, and each item's actual
# position inside its cell -- with its yaw, its rank and everything else that
# used to be hashed off a moving coordinate -- is hashed from that cell's own
# INTEGER coordinates in the shader. An item is then a property of the ground,
# not of the ring: walk forward and instance 400 simply takes over the cell
# instance 617 was drawing a moment ago, at the same offset, the same height,
# the same lean. Nothing pops because nothing changed.
#
# WHAT HAD TO BE PRESERVED, AND HOW. The old disc drew `r = radius * u^bias`,
# which is not uniform: `centre_bias` 0.62 puts ~78 tufts/m2 at the camera
# against ~15 at the ring's edge, and that gradient is most of why the near
# field reads as thick. A single uniform lattice cannot have it. So the ring is
# built as NESTED lattices: a base one over the whole disc at the outer
# density, and a stack of smaller discs each adding the difference, every one
# of them on the same cell grid so all of them are stable together. The
# schedule is fitted numerically against the analytic density the old disc law
# produced -- `_lattice_plan` below is that fit, and it lands within a few per
# cent of it at every radius the player can see.
#
# The joins between those discs would be visible density rings following the
# camera around, so each layer FADES: `layer_in`/`layer_out` in the shaders,
# against a per-cell rank, so an item near the boundary grows out of the ground
# over a metre or two of travel rather than appearing. That is the one thing in
# this system that still changes as you walk, and it is a smooth height ramp on
# a fraction of one layer rather than a whole-field re-roll.
#
# COST. The layer discs overlap their fade bands, so the ring stands up a few
# per cent more instances than `tuft_count` asks for. `_build` prints the exact
# figure at boot; the measured numbers for the shipped config are in
# `ralph/reports/GRASS_REROLL_2026-08-28.md`. NOT MEASURED HERE: what any of
# this costs the Ally's GPU. `PERF-ROG-GPU` records that no container in this
# project can measure that, and it has not become measurable.
# ---------------------------------------------------------------------------

## How many sub-cell slots a lattice cell is divided into for the purpose of
## TAGGING an instance. Nothing is placed on this grid: the tag is an identity,
## not a position, and where an item actually stands is hashed from the world
## cell it currently occupies. The shader recovers the tag from the instance's
## world coordinate, so the slot step has to survive float32 at world scale --
## at 128 slots to a 2m cell the step is 15.6mm, which is two orders of
## magnitude above the mantissa's resolution eight kilometres down the
## corridor. It also caps items-per-cell and layer count at 126 each.
const LATTICE_SLOTS := 128
## The length of the `layer_in[]`/`layer_out[]` uniform arrays in the three
## field shaders. A longer plan would index off the end of them.
const LATTICE_MAX_LAYERS := 16


## The cell the whole field is quantised to. Deliberately the SAME number as
## `snap`: the node may only move in whole cells, and `snap` is what it moves
## in. Reading one value for both is what makes it impossible to set them to
## two numbers that do not divide each other, which would silently reintroduce
## the re-roll while looking correct in a still frame.
static func lattice_cell() -> float:
	return maxf(0.25, float(config().get("snap", 2.0)))


## The nested-lattice schedule for one tier, fitted against the density profile
## the old `r = radius * pow(u, bias)` disc produced.
##
## That law puts `N * (r/R)^(1/bias)` items inside radius r, so its areal
## density is `A * r^(1/bias - 2)` with `A = N/(bias * TAU * R^(1/bias))`. Each
## layer is a uniform lattice over a disc, contributing `per_cell / cell^2`
## everywhere inside `ramp_in` and fading to nothing at `ramp_out`; `per_cell`
## is an integer, so the fit is a short integer search rather than a division.
##
## Returned outermost-first. Entry 0 is the base layer and never fades -- its
## ramp radii are pushed past the ring so the shader's `smoothstep` is a
## constant 1 for every distance that can occur.
static func _lattice_plan(count: int, radius: float, bias: float, cell: float,
		cfg: Dictionary) -> Array:
	var ratio := maxf(1.1, float(cfg.get("lattice_layer_ratio", 1.5)))
	var band := clampf(float(cfg.get("lattice_band", 0.85)), 0.1, 0.98)
	var min_radius := maxf(cell, float(cfg.get("lattice_min_radius", 2.0)))
	# How far a layer has to reach BEYOND the radius it fades out at. The node
	# is quantised to the cell while the fade is measured from the camera's
	# true position, so the two disagree by up to half a cell on each axis. A
	# layer built to exactly its fade radius would come up short on the side
	# the camera has drifted toward, and the shortfall is a hard edge.
	var wobble := cell * 0.70711
	var exponent := 1.0 / maxf(bias, 0.05)
	var scale := float(count) * exponent / (TAU * pow(radius, exponent))

	var plan: Array = []
	# The base layer is fitted to the area-weighted mean density of the outer
	# annulus rather than to the density at the rim, because that annulus is
	# more than half the disc and fitting the rim leaves the whole of it thin.
	var outer := radius / ratio
	var mean := 2.0 * scale * (pow(radius, exponent) - pow(outer, exponent)) \
			/ (exponent * maxf(radius * radius - outer * outer, 0.0001))
	plan.append({
		# Capped at what one cell's tags can address: two items sharing a tag
		# would hash to the same spot and render on top of each other. Only
		# reachable by asking for an implausible density -- the shipped grass
		# tier's base layer is 64 -- but silent if it ever happened.
		"per_cell": clampi(int(round(mean * cell * cell)), 1, LATTICE_SLOTS - 2),
		"ramp_in": radius * 4.0,
		"ramp_out": radius * 8.0,
		# The base layer gets NO wobble margin, unlike the ones below it, and
		# it is the one place where that is worth the arithmetic: it is 83% of
		# the ring, so a margin ring costs ten thousand instances. It can be
		# dropped because the base layer already has an edge -- `field_radius`,
		# where `v_fade` culls -- and an item the camera's drift takes past it
		# was at a few per cent of its own height on the way out anyway. `-
		# wobble` here means the CELLS reach exactly `radius`, since a cell is
		# taken whenever any part of it is in reach.
		"geo": radius - wobble,
	})

	var ring := outer
	while ring >= min_radius and plan.size() < LATTICE_MAX_LAYERS:
		var ramp_in := ring * band
		var inner := ring / ratio
		var want := scale * pow(ramp_in, exponent - 2.0) \
				- _plan_density(plan, cell, ramp_in)
		var guess := int(round(want * cell * cell))
		var best := 0
		var best_err := INF
		for per in range(maxi(0, guess - 4), maxi(1, guess + 5)):
			var err := 0.0
			for i in 48:
				var r: float = inner + (ring - inner) * (float(i) + 0.5) / 48.0
				var add := float(per) / (cell * cell) * (1.0 - smoothstep(ramp_in, ring, r))
				var target := scale * pow(r, exponent - 2.0)
				var e := (_plan_density(plan, cell, r) + add - target) / target
				err += e * e * r
			if err < best_err:
				best_err = err
				best = per
		if best > 0:
			plan.append({
				"per_cell": mini(best, LATTICE_SLOTS - 2),
				"ramp_in": ramp_in,
				"ramp_out": ring,
				"geo": ring + wobble,
			})
		ring /= ratio
	return plan


## What a plan already delivers at radius r, in items per square metre.
static func _plan_density(plan: Array, cell: float, r: float) -> float:
	var out := 0.0
	for entry: Variant in plan:
		var layer: Dictionary = entry
		out += float(layer["per_cell"]) / (cell * cell) \
				* (1.0 - smoothstep(float(layer["ramp_in"]), float(layer["ramp_out"]), r))
	return out


## An item's tag, as an offset inside its cell. Purely an identity: the x step
## says which of the cell's items this is and the y step says which layer it
## belongs to, and the shader reads both back out of the instance's world
## coordinate. The real position is hashed from the cell, not from this.
static func _slot_offset(item: int, layer: int, cell: float) -> Vector2:
	var step := cell / float(LATTICE_SLOTS)
	return Vector2(float(1 + item % (LATTICE_SLOTS - 2)) * step,
			float(1 + layer) * step)


## Lay a plan out into a MultiMesh, and report how many instances that took.
##
## A cell is included in a layer when any part of it is within the layer's
## reach, so the lattice covers the disc rather than stopping a cell short of
## it. Every transform is a pure translation: the per-item yaw that used to
## live in the instance basis is hashed from the cell in the shader now, for
## the same reason as everything else -- a yaw carried by the instance travels
## with the instance and would spin every tuft on the spot each time the ring
## moved a cell.
static func _fill_lattice(mm: MultiMesh, plan: Array, cell: float) -> int:
	var per_layer: Array[PackedVector2Array] = []
	var total := 0
	for entry: Variant in plan:
		var layer: Dictionary = entry
		var reach: float = float(layer["geo"])
		var steps := int(ceil(reach / cell)) + 1
		var half := cell * 0.5
		var corner := cell * 0.70711
		var cells := PackedVector2Array()
		for ix in range(-steps, steps + 1):
			for iz in range(-steps, steps + 1):
				var origin := Vector2(float(ix) * cell, float(iz) * cell)
				if (origin + Vector2(half, half)).length() - corner <= reach:
					cells.append(origin)
		per_layer.append(cells)
		total += cells.size() * int(layer["per_cell"])

	mm.instance_count = total
	var at := 0
	for index in plan.size():
		var layer: Dictionary = plan[index]
		var per: int = int(layer["per_cell"])
		for origin: Vector2 in per_layer[index]:
			for item in per:
				var slot := _slot_offset(item, index, cell)
				mm.set_instance_transform(at, Transform3D(Basis.IDENTITY,
						Vector3(origin.x + slot.x, 0.0, origin.y + slot.y)))
				at += 1
	return total


## VP2 (visual parity program, 2026-09-01). The ring's whole cost problem, and
## its fix, in one number.
##
## THE DEFECT: `ralph/reports/OWNER-0901-PERFORMANCE-LAG-V2.md` measured this
## field at 22.5M primitives a frame -- 71% of everything drawn -- and the owner
## felt it as ~10 FPS on the Ally. Not because 300,000 tufts is too many for
## the near field, but because every one of them was in ONE MultiMesh with ONE
## AABB the size of the whole ring. The ring follows the camera, so that AABB
## is never outside the frustum, so Godot submits every tuft every frame --
## the two thirds of the disc BEHIND a 70-degree camera included. A MultiMesh
## is culled as a unit; the renderer cannot drop the instances it cannot see.
##
## THE FIX: the same lattice, the same instances, the same shaders and hashes
## (nothing about where an item stands or what it looks like changes -- the
## STABLE RING note below still holds), laid out into square TILES of
## `cull_tile_m` metres, one MultiMeshInstance3D each, each with an AABB of its
## own tile. Every tile rides this node exactly as the single MultiMesh did, so
## the ring still hops in whole cells and every tile hops with it; but the
## renderer now frustum-culls tile by tile, and the tiles behind the camera
## and off to its sides stop being submitted at all. At the shipped 72m radius
## and a 16m tile that is ~80 tiles, and a third-person camera sees roughly a
## third of them. Draw calls rise by the number of VISIBLE tiles (tens, against
## the ~7,000 the frame already carries -- `PERF-ROG-GPU` records that
## Compatibility's cost is batches, and these are small batches), primitives
## fall by the tiles that are not. Measured with tools/perf_render_stats.gd,
## recorded in archive/docs/VISUAL_PARITY_PROGRESS.md.
##
## `cull_tile_m` 0 restores the single-MultiMesh path exactly, for A/B
## measurement. Forced to a whole multiple of the lattice cell so a tile edge
## never splits a cell: an item's cell decides its tile, and the cell's origin
## is what the tile's AABB is grown from.
static func cull_tile_m(cfg: Dictionary) -> float:
	var tile := float(cfg.get("cull_tile_m", 16.0))
	# A/B seam for tools/perf_render_stats.gd: `TB_GRASS_CULL_TILE_M=0|8|16`
	# in the environment overrides the config so three measurements can be
	# chained from one checkout without editing the shipped file between runs
	# (and without a mid-chain edit silently landing in the wrong run). Nothing
	# in `scripts/` sets it; an export never carries it.
	var env := OS.get_environment("TB_GRASS_CULL_TILE_M")
	if env != "" and env.is_valid_float():
		tile = float(env)
	if tile <= 0.0:
		return 0.0
	var cell := lattice_cell()
	return maxf(cell, snappedf(tile, cell))


## VP2, the second half of the far cost. Tiles let the renderer drop what the
## camera is not looking AT; these two take out what it is looking at but
## cannot see. Measured with the shipped config (tools/perf_render_stats.gd,
## recorded in ralph/reports/visual-parity/GROUND/REPORT.md): the base layer
## of every tier is one uniform density all the way to `field_radius`, and it
## is 83% of the ring -- 64 tufts in every 2m cell out to 72m for the grass
## tier, two thirds of those cells in the 42-72m band where `v_fade` is
## already shortening every blade toward nothing. Submitting a full-density
## blade in order to shrink it is the far cost.
##
## FAR THINNING splits the base layer's per-cell count into a floor that keeps
## full reach plus `steps` sub-layers whose `ramp_out` radii are spaced across
## the fade band. That is the SAME `layer_in`/`layer_out` mechanism the nested
## inner layers already use, so each sub-layer grows in per item, dithered
## against its stable rank, exactly as the inner layers do, and the tiler stops
## generating a sub-layer's cells past its own reach. No shader change, no new
## hash; nothing about where a surviving item stands moves.
static func _thin_far(plan: Array, fade_start: float, radius: float, floor_frac: float,
		steps: int, cell: float) -> Array:
	if plan.is_empty() or steps <= 0 or floor_frac >= 0.999 or fade_start >= radius:
		return plan
	var base: Dictionary = plan[0]
	var per: int = int(base["per_cell"])
	var keep := clampi(int(round(float(per) * clampf(floor_frac, 0.0, 1.0))), 1, per)
	var spare := per - keep
	if spare <= 0:
		return plan
	steps = mini(steps, LATTICE_MAX_LAYERS - plan.size())
	if steps <= 0:
		return plan
	var wobble := cell * 0.70711
	var out: Array = []
	var floor_layer := base.duplicate()
	floor_layer["per_cell"] = keep
	out.append(floor_layer)
	# `steps + 1` so the last sub-layer is gone one band short of the rim and
	# the outermost band carries the floor alone: that band is the largest
	# annulus of the ring, and the blades in it are already at a fraction of
	# their height from `v_fade`.
	var width := (radius - fade_start) / float(steps + 1)
	var handed := 0
	for k in steps:
		var share := int(round(float(spare) * float(k + 1) / float(steps))) - handed
		handed += share
		if share <= 0:
			continue
		var ramp_out := fade_start + width * float(k + 1)
		out.append({
			"per_cell": share,
			"ramp_in": ramp_out - width,
			"ramp_out": ramp_out,
			"geo": ramp_out + wobble,
		})
	for i in range(1, plan.size()):
		out.append(plan[i])
	return out


## REACH caps a tier's plan at `reach` metres. A 10cm stone or a fallen leaf
## is under a pixel long before the ring ends, and generating it out to 72m so
## the shader can collapse it to a point is pure cost. Layers wholly beyond the
## reach are dropped; the base layer gets a real `ramp_in`/`ramp_out` at the
## reach so it arrives per item like every inner layer, and its cells stop
## there. `band` is how many metres the arrival is spread over.
static func _cap_reach(plan: Array, reach: float, band: float, cell: float) -> Array:
	var out: Array = []
	var wobble := cell * 0.70711
	# A nested layer is fully present everywhere INSIDE its ramp, so one that
	# is dropped for being wholly beyond the reach was also contributing to the
	# near field. Its count is folded into the base layer so the density inside
	# the reach is exactly what it was.
	var folded := 0
	for index in plan.size():
		var layer: Dictionary = (plan[index] as Dictionary).duplicate()
		if index == 0:
			if float(layer["ramp_out"]) > reach:
				layer["ramp_in"] = maxf(reach - band, 0.0)
				layer["ramp_out"] = reach
				layer["geo"] = reach + wobble
		else:
			if float(layer["ramp_in"]) >= reach:
				folded += int(layer["per_cell"])
				continue
			if float(layer["ramp_out"]) > reach:
				layer["ramp_out"] = reach
				layer["geo"] = reach + wobble
		out.append(layer)
	if not out.is_empty() and folded > 0:
		out[0]["per_cell"] = mini(int(out[0]["per_cell"]) + folded, LATTICE_SLOTS - 2)
	return out


## MESH LOD BY TILE. The third far lever: a tile that can only ever be seen
## from `from_m` metres away carries a cheaper mesh. `lod` is a list of
## `{"from_m": float, "mesh": Mesh}` sorted by distance; a tile takes the last
## entry whose `from_m` is inside the nearest the eye can come to it (the tile
## square's nearest point, less the ring's own cell wobble), so the geometry a
## cell needs at any distance the shader can ask for it at is always there.
## The grass tier's far mesh drops blades and segments -- see `_tuft_mesh` --
## and the shader grows the dropped blades back in over `lod_band_m` as the
## player closes, so the swap is a ramp rather than a pop.
static func _lod_mesh_for_tile(key: Vector2i, tile_m: float, cell: float, base: Mesh, lod: Array) -> Mesh:
	if lod.is_empty():
		return base
	var x0 := float(key.x) * tile_m
	var z0 := float(key.y) * tile_m
	var dx := maxf(maxf(x0, 0.0), -(x0 + tile_m))
	var dz := maxf(maxf(z0, 0.0), -(z0 + tile_m))
	var nearest := sqrt(dx * dx + dz * dz) - cell * 1.5
	var pick := base
	for entry: Variant in lod:
		var level: Dictionary = entry
		if nearest >= float(level["from_m"]):
			pick = level["mesh"]
	return pick


## `_fill_lattice`, cut into tiles. Same cells, same per-layer counts, same
## slot tags and same pure-translation transforms -- the only difference is
## which MultiMesh a cell's items land in. Returns one entry per non-empty
## tile: `{"mm": MultiMesh, "aabb": AABB, "key": Vector2i, "origins":
## PackedVector3Array}`. `origins` duplicates what went into the MultiMesh
## because the headless (Dummy) renderer the tests run under never stores a
## MultiMesh buffer -- `get_instance_transform()` reads back identity for
## every instance there -- so the tests pin the layout through this array.
static func _fill_lattice_tiles(mesh: Mesh, plan: Array, cell: float, tile_m: float,
		lod: Array = []) -> Array:
	var per_tile: Dictionary = {}  # Vector2i -> Array[Transform3D]
	for index in plan.size():
		var layer: Dictionary = plan[index]
		var reach: float = float(layer["geo"])
		var per: int = int(layer["per_cell"])
		var steps := int(ceil(reach / cell)) + 1
		var half := cell * 0.5
		var corner := cell * 0.70711
		for ix in range(-steps, steps + 1):
			for iz in range(-steps, steps + 1):
				var origin := Vector2(float(ix) * cell, float(iz) * cell)
				if (origin + Vector2(half, half)).length() - corner > reach:
					continue
				var key := Vector2i(int(floor(origin.x / tile_m)), int(floor(origin.y / tile_m)))
				if not per_tile.has(key):
					per_tile[key] = []
				var bucket: Array = per_tile[key]
				for item in per:
					var slot := _slot_offset(item, index, cell)
					bucket.append(Transform3D(Basis.IDENTITY,
							Vector3(origin.x + slot.x, 0.0, origin.y + slot.y)))
	var out: Array = []
	# Half a cell of hash jitter each way plus the slot offset inside the cell,
	# and blades lean with the wind: two cells of slack on each side, the same
	# margin the single-MultiMesh AABB carried.
	var slack := cell * 2.0
	for key: Vector2i in per_tile.keys():
		var bucket: Array = per_tile[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _lod_mesh_for_tile(key, tile_m, cell, mesh, lod)
		mm.instance_count = bucket.size()
		var origins := PackedVector3Array()
		origins.resize(bucket.size())
		for i in bucket.size():
			var xf: Transform3D = bucket[i]
			mm.set_instance_transform(i, xf)
			origins[i] = xf.origin
		var x0 := float(key.x) * tile_m
		var z0 := float(key.y) * tile_m
		out.append({
			"mm": mm, "key": key, "origins": origins,
			"aabb": AABB(Vector3(x0 - slack, -400.0, z0 - slack),
					Vector3(tile_m + slack * 2.0, 800.0, tile_m + slack * 2.0)),
		})
	return out


## Stand the tiles up as children of `under`, all sharing one material, and
## report how many instances that took. Children of the ring move with it.
static func _stand_up_tiles(under: Node3D, prefix: String, tiles: Array, mat: ShaderMaterial) -> int:
	var placed := 0
	for entry: Variant in tiles:
		var tile: Dictionary = entry
		var node := MultiMeshInstance3D.new()
		var key: Vector2i = tile["key"]
		node.name = "%s_%d_%d" % [prefix, key.x, key.y]
		node.multimesh = tile["mm"]
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.custom_aabb = tile["aabb"]
		under.add_child(node)
		placed += int((tile["mm"] as MultiMesh).instance_count)
	return placed


## Hand a plan to a material. The two arrays are the only per-layer state the
## shaders need; an instance finds its own row through the layer index encoded
## in its slot tag. Unused rows are pushed past any distance that can occur so
## a stale index cannot fade a layer that is not there.
static func _apply_lattice(mat: ShaderMaterial, plan: Array, cell: float) -> void:
	if mat == null:
		return
	var ins := PackedFloat32Array()
	var outs := PackedFloat32Array()
	for entry: Variant in plan:
		var layer: Dictionary = entry
		ins.append(float(layer["ramp_in"]))
		outs.append(float(layer["ramp_out"]))
	while ins.size() < LATTICE_MAX_LAYERS:
		ins.append(1.0e9)
		outs.append(2.0e9)
	mat.set_shader_parameter("layer_in", ins)
	mat.set_shader_parameter("layer_out", outs)
	mat.set_shader_parameter("lattice_cell", cell)
	var cfg := config()
	mat.set_shader_parameter("lattice_jitter", float(cfg.get("lattice_jitter", 1.0)))
	mat.set_shader_parameter("lod_dither", float(cfg.get("lod_dither", 0.3)))

func _ready() -> void:
	if not (is_enabled() or force_enabled):
		# Nothing built, nothing bound, no per-frame work. A disabled field is
		# not a cheap field, it is an absent one.
		set_process(false)
		visible = false
		return
	_build()
	set_process(true)


## Build the tuft mesh and the ring. Both are built once and never rebuilt: the
## ring moves by moving this node, not by rewriting instance transforms, which
## is what keeps the per-frame cost at "one uniform write".
func _build() -> void:
	var cfg := config()
	var count := int(cfg.get("tuft_count", 42000))
	var radius := float(cfg.get("field_radius", 48.0))

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _tuft_mesh(int(cfg.get("blades_per_tuft", 4)),
			int(cfg.get("blade_segments", 4)))

	# Distribution. The disc law `r = radius * u^centre_bias` is still what the
	# density profile is fitted to -- see the STABLE RING note above -- but the
	# tufts stand on a world-aligned lattice now rather than at random points,
	# because a random disc cannot survive its own ring moving.
	var cell := lattice_cell()
	var plan := _lattice_plan(count, radius, float(cfg.get("centre_bias", 0.62)), cell, cfg)
	# VP2: thin the base layer across the fade band. See `_thin_far`.
	plan = _thin_far(plan, float(cfg.get("fade_start", 30.0)), radius,
			float(cfg.get("far_thin_floor", 1.0)), int(cfg.get("far_thin_steps", 0)), cell)

	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH)
	material_override = _material
	# VP2: tiled, so the renderer can cull the ring behind and beside the
	# camera. See `cull_tile_m` above. This node itself then carries no
	# instances; its children do.
	var tile_m := cull_tile_m(cfg)
	var placed := 0
	if tile_m > 0.0:
		multimesh = null
		placed = _stand_up_tiles(self, "GrassTile",
				_fill_lattice_tiles(mm.mesh, plan, cell, tile_m, _grass_lod(cfg)), _material)
	else:
		placed = _fill_lattice(mm, plan, cell)
		multimesh = mm
	_ring_instances = placed
	_apply_config(cfg)
	_apply_lattice(_material, plan, cell)
	_apply_grass_lod(cfg)
	print("[grass_field] grass ring: %d instances over %d lattice layers (%s asked for %d), %s" % [
		placed, plan.size(), "tuft_count", count,
		("%.0fm cull tiles" % tile_m) if tile_m > 0.0 else "one uncullable MultiMesh"])

	# The field is ground cover: it must not push the camera around, must not
	# receive a harvest prompt, and must not cast the black carpet a thousand
	# overlapping blade shadows would make (`vegetation.json`'s grass layer
	# turned its own shadows off for exactly that measured reason).
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The ring is authored around the origin and moved; without this Godot culls
	# it against an AABB that does not follow. Two cells of slack on each side
	# because the lattice reaches a fade band past `radius` and each item is
	# then hash-jittered up to half a cell inside its own square.
	var slack := lattice_cell() * 2.0
	custom_aabb = AABB(Vector3(-radius - slack, -400.0, -radius - slack),
			Vector3((radius + slack) * 2.0, 800.0, (radius + slack) * 2.0))

	# AFTER `custom_aabb` is set, not before: the stone ring copies it, and
	# built first it copied the default zero AABB instead.
	_build_stones(cfg, radius)
	_build_cover_tiers(cfg, radius)
	_build_far_cover(cfg)
	_apply_clearing(cfg)


## The grass tier's mesh LOD list, from the config's `lod` block. Two cheaper
## tufts: `mid` keeps every blade and drops segments (a blade at 18m is a dozen
## pixels tall; a kink halfway up it is not one of them), `far` also drops the
## last blades of the tuft. Both are built by the same `_tuft_mesh` with the
## same blade offsets, so a blade that survives into the far mesh is the same
## blade, at the same spot, hashing the same height and lean -- the only
## difference between the tiers is which blades exist.
func _grass_lod(cfg: Dictionary) -> Array:
	var lod_cfg: Dictionary = cfg.get("lod", {})
	if not bool(lod_cfg.get("enabled", false)):
		return []
	var blades := int(cfg.get("blades_per_tuft", 4))
	var segments := int(cfg.get("blade_segments", 4))
	var out: Array = []
	var mid_m := float(lod_cfg.get("mid_m", 0.0))
	if mid_m > 0.0:
		out.append({"from_m": mid_m,
			"mesh": _tuft_mesh(blades, int(lod_cfg.get("mid_segments", segments)), blades)})
	var far_m := float(lod_cfg.get("far_m", 0.0))
	if far_m > mid_m:
		out.append({"from_m": far_m,
			"mesh": _tuft_mesh(blades, int(lod_cfg.get("far_segments", segments)),
				clampi(int(lod_cfg.get("far_blades", blades)), 1, blades))})
	return out


## Tell the grass shader which blades the far mesh lacks and where, so it can
## grow them back in as the player closes rather than have them appear at the
## tile boundary. Off (all blades everywhere) when the LOD block is.
func _apply_grass_lod(cfg: Dictionary) -> void:
	if _material == null:
		return
	var lod_cfg: Dictionary = cfg.get("lod", {})
	var blades := maxi(1, int(cfg.get("blades_per_tuft", 4)))
	var far_m := float(lod_cfg.get("far_m", 0.0))
	var far_blades := clampi(int(lod_cfg.get("far_blades", blades)), 1, blades)
	var on := bool(lod_cfg.get("enabled", false)) and far_m > 0.0 and far_blades < blades
	_material.set_shader_parameter("lod_far_m", far_m if on else 1.0e9)
	_material.set_shader_parameter("lod_far_blade_frac", float(far_blades) / float(blades) if on else 2.0)
	_material.set_shader_parameter("lod_band_m", maxf(float(lod_cfg.get("band_m", 6.0)), 0.5))


## The generic cover tiers, from `cover_tiers` in the config: small bushes,
## flower drifts, forest litter. Each is one more MultiMesh child on the same
## ring, running `shaders/cover_tier.gdshader`, differing only by mesh and
## numbers -- see that shader's header for the rule about what may and may not
## be generated this way, and why harvestable bushes are not on the list.
func _build_cover_tiers(cfg: Dictionary, radius: float) -> void:
	var names := _terrain_texture_names()
	for entry: Variant in cfg.get("cover_tiers", []):
		var tier: Dictionary = entry
		if not bool(tier.get("enabled", true)):
			continue
		var count := int(tier.get("count", 0))
		if count <= 0:
			continue

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _cover_mesh(str(tier.get("mesh", "bush")))
		# Its own lattice schedule, fitted to its own count and bias. The tiers
		# no longer need separate RNG streams to stay independent of each
		# other: nothing here is drawn from a stream at all, and where an item
		# stands is hashed from its own world cell and its own tier.
		var cell := lattice_cell()
		var plan := _lattice_plan(count, radius,
				float(tier.get("centre_bias", 0.6)), cell, cfg)
		# VP2: a tier's own reach, where it has one. See `_cap_reach`.
		if tier.has("reach_m"):
			plan = _cap_reach(plan, float(tier["reach_m"]),
					float(tier.get("reach_band_m", cfg.get("reach_band_m", 6.0))), cell)
		# GRASS-CULL: the same graduated far-band thinning `_build` already
		# applies to the grass tier's own base layer (see `_thin_far` above),
		# now reachable by any cover tier that opts in with `far_thin`. Bushes
		# are the one tier this fixes: at 0.85m they are too large for a hard
		# `reach_m` cliff the way a 10cm stone or a fallen leaf takes one --
		# that would trade the grass ring's own solved "hard line at the edge"
		# defect for a new one in the understorey -- so they get the graduated
		# floor-plus-steps ramp instead, which is the mechanism this file
		# already built and tested for exactly this shape of cost. A tier that
		# does not set `far_thin` is unaffected -- flowers and litter keep
		# their existing hard `reach_m` caps, which already zero them well
		# inside the ring and need nothing added.
		if bool(tier.get("far_thin", false)):
			plan = _thin_far(plan, float(tier.get("fade_start", cfg.get("fade_start", 42.0))), radius,
					float(tier.get("far_thin_floor", cfg.get("far_thin_floor", 1.0))),
					int(tier.get("far_thin_steps", cfg.get("far_thin_steps", 0))), cell)
		# VP2: a cheaper bush past `lod.far_bush_m`, every other leaf dropped.
		var lod: Array = []
		var lod_cfg: Dictionary = cfg.get("lod", {})
		if bool(lod_cfg.get("enabled", false)) and str(tier.get("mesh", "bush")) == "bush" \
				and float(lod_cfg.get("far_bush_m", 0.0)) > 0.0:
			lod.append({"from_m": float(lod_cfg["far_bush_m"]), "mesh": _bush_mesh(2)})

		var node := MultiMeshInstance3D.new()
		node.name = "Cover_" + str(tier.get("name", "tier"))
		var mat := ShaderMaterial.new()
		mat.shader = load(COVER_SHADER_PATH)
		node.material_override = mat
		# VP2: tiled like the grass ring, for the same culling reason.
		var tile_m := cull_tile_m(cfg)
		var placed := 0
		if tile_m > 0.0:
			placed = _stand_up_tiles(node, "Tile",
					_fill_lattice_tiles(mm.mesh, plan, cell, tile_m, lod), mat)
		else:
			placed = _fill_lattice(mm, plan, cell)
			node.multimesh = mm
		# Same reasoning as the grass and stone tiers: thousands of small
		# shadows overlap into a black carpet rather than reading as shade, and
		# the shader darkens each item at its own contact instead.
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.custom_aabb = custom_aabb
		add_child(node)

		for key: String in [
			"item_size", "size_jitter", "sink", "slope_lie", "density_gain",
			"drift_scale", "drift_contrast", "drift_gate", "tint_jitter", "ground_blend",
			"contact_darken", "normal_soften", "sway", "wind_scale", "gust", "gust_speed",
			"gust_length", "field_radius", "fade_start", "leaf_cut", "leaf_serrate",
			"leaf_teeth", "leaf_root_darken", "leaf_tint_jitter",
		]:
			if tier.has(key):
				mat.set_shader_parameter(key, float(tier[key]))
			elif cfg.has(key):
				mat.set_shader_parameter(key, float(cfg[key]))
		for key2: String in ["tint_base", "tint_tip", "tint_wood"]:
			if tier.has(key2):
				mat.set_shader_parameter(key2, Color(str(tier[key2])))
		if tier.has("wind_dir"):
			var d: Array = tier["wind_dir"]
			mat.set_shader_parameter("wind_dir", Vector2(float(d[0]), float(d[1])).normalized())
		elif cfg.has("wind_dir"):
			var d2: Array = cfg["wind_dir"]
			mat.set_shader_parameter("wind_dir", Vector2(float(d2[0]), float(d2[1])).normalized())
		# Where it grows, by terrain texture NAME. Same list the grass tier
		# builds its forbidden mask from, so a lane that reorders
		# terrain_playground.json's textures cannot silently move a tier onto
		# the wrong surface.
		var allowed: Array = tier.get("ground", ["grass", "soil"])
		var mask := 0
		for i in names.size():
			if str(names[i]) in allowed:
				mask |= 1 << i
		mat.set_shader_parameter("allowed_base_mask", mask)
		_apply_lattice(mat, plan, cell)
		_cover_materials.append(mat)
		print("[grass_field] cover tier %-8s %d instances over %d lattice layers (count %d)" % [
			str(tier.get("name", "tier")), placed, plan.size(), count])
	if not _cover_materials.is_empty():
		print("[grass_field] %d cover tier(s) up" % _cover_materials.size())


# ---------------------------------------------------------------------------
# FAR COVER. The cheap tier BEYOND the grass ring, and the one place in this
# file that is not instances.
#
# THE DEFECT. The ring reaches `field_radius` 72m and fades from `fade_start`
# 42m. Past that the meadow is painted terrain carrying whatever scatter is
# still allowed on it, and from an overlook the world visibly ends at a line
# you can read across the hill. `_comment_ring` in the config records the two
# answers already spent on that line -- the ring pushed 40 -> 56 -> 72m, the
# last step a 43% vertex increase on the most expensive tier in the game and
# unmeasured on the device -- and the owner has since said the grass already
# feels expensive on the Ally. So the ring does not move a third time.
#
# THE INSTRUMENT. A ground-colour blend, laid over the terrain from inside the
# grass ring's own fade out to the haze. It carries the meadow's cover READ --
# hue, value, drifts, mottle -- and none of its geometry. At the distances it
# is visible, that is all real blades would have been contributing anyway.
#
# WHY A SHEET AND NOT MORE INSTANCES. Every other tier here is a MultiMesh on
# the lattice, and copying that would have been the smaller diff. It is the
# wrong shape for this one. Flat cards lie flat while the ground under them
# does not, so they cut into every slope or float off it; they overlap, and
# overlapping blended quads inside one MultiMesh have no sort order, so they
# double-darken in a pattern that follows the camera; and a card has a boundary
# for the eye to find. A single sheet samples the terrain height at each of its
# own vertices, never overlaps itself, and carries one continuous world-space
# noise field with nothing to tile.
#
# THE FAR LATTICE, and why the node's offset is compensated for. The sheet is a
# fixed grid in its own local space, so if it simply rode this node it would
# move in `snap` (2m) steps while its grid is `far_cell` (4m) -- every step
# would move its sampling points to different places on the terrain and the
# surface would swim exactly the way the whole STABLE RING note above exists to
# stop. `far_cell` is therefore forced to a multiple of `snap`, and the child
# is offset by the difference between this node's anchor and the same position
# snapped to `far_cell`. The sheet's vertices then land on one fixed world grid
# and stay there however far the player walks.
#
# COST. One instance, one material, one draw. `_build_far_cover` prints the
# vertex and triangle count it stood up; for the shipped numbers it is tens of
# thousands of triangles against the grass tier's fourteen million. The fill is
# a single blended layer over ground the frame was already drawing. NOT
# MEASURED ON THE DEVICE -- `PERF-ROG-GPU` records that no container in this
# project can measure GPU cost, and that has not changed.
# ---------------------------------------------------------------------------

## The far sheet, from `far_cover` in the config. Absent entirely when the block
## is missing or disabled, the same way every other tier here is: a tier that is
## off is not a cheap tier, it is no tier.
func _build_far_cover(cfg: Dictionary) -> void:
	var far_cfg: Dictionary = cfg.get("far_cover", {})
	if not bool(far_cfg.get("enabled", false)):
		return
	var cell := far_lattice_cell(cfg)
	var outer := maxf(float(far_cfg.get("far_radius", 640.0)), cell * 4.0)
	var fade_in_start := float(far_cfg.get("fade_in_start", 52.0))
	# The hole in the middle. Cut a couple of cells inside where the sheet
	# starts to become visible, not AT it: the mesh is anchored to the snapped
	# node while the fade is measured from the true eye, so the two disagree by
	# up to a cell on each axis and a hole cut to the exact radius would open a
	# crescent of missing cover on whichever side the camera has drifted toward.
	var inner := maxf(fade_in_start - cell * 2.0, 0.0)

	var mesh := _far_mesh(inner, outer, cell)
	_far = MeshInstance3D.new()
	_far.name = "FarCover"
	_far.mesh = mesh
	# A blended overlay must not cast anything. The grass, stone and cover tiers
	# are all shadow-off for their own reasons; this one has no geometry a
	# shadow could describe.
	_far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The sheet is authored around the origin and moved, and it reaches far
	# past the grass ring's own AABB, so it needs its own.
	_far.custom_aabb = AABB(Vector3(-outer - cell, -400.0, -outer - cell),
			Vector3((outer + cell) * 2.0, 800.0, (outer + cell) * 2.0))

	_far_material = ShaderMaterial.new()
	_far_material.shader = load(FAR_SHADER_PATH)
	# Before every other transparent material in the world. The sheet lies ON
	# the ground, and water is drawn over ground; left to the default priority
	# the two sort by origin distance and the wash can end up painted over the
	# pond it is supposed to be under.
	_far_material.render_priority = -1
	_far.material_override = _far_material
	add_child(_far)

	for key: String in [
		"fade_in_start", "fade_in_end", "fade_out_start", "far_radius",
		"strength", "lift", "dilate_lift", "ground_blend", "mottle_scale", "mottle_strength",
		"mottle_value", "mottle_detail", "mottle_detail_range",
	]:
		if far_cfg.has(key):
			_far_material.set_shader_parameter(key, float(far_cfg[key]))
	for key2: String in ["tint_base", "tint_tip"]:
		if far_cfg.has(key2):
			_far_material.set_shader_parameter(key2, Color(str(far_cfg[key2])))
	_far_material.set_shader_parameter("far_cell", cell)
	# VP2: the TERRAIN'S macro colours and scales, read off its own config so
	# the sheet cannot drift a different green from the ground under it.
	var terrain_shader: Dictionary = _terrain_config().get("shader", {})
	if bool(terrain_shader.get("enable_macro_variation", false)):
		_far_material.set_shader_parameter("macro_variation1",
				Color(str(terrain_shader.get("macro_variation1", "#ffffff"))))
		_far_material.set_shader_parameter("macro_variation2",
				Color(str(terrain_shader.get("macro_variation2", "#ffffff"))))
		_far_material.set_shader_parameter("macro_scale1", float(terrain_shader.get("noise1_scale", 0.012)))
		_far_material.set_shader_parameter("macro_scale2", float(terrain_shader.get("noise2_scale", 0.03)))
		_far_material.set_shader_parameter("macro_strength", float(far_cfg.get("macro_strength", 1.0)))
	# The GRASS TIER'S drift field, by its own numbers, not a second one shaped
	# to look similar. The far ground's open patches have to be the same
	# world-space patches the near field's are, or the hand-over is two
	# different meadows meeting -- which is the line, with a softer edge.
	_far_material.set_shader_parameter("drift_scale", float(cfg.get("clump_scale", 0.11)))
	_far_material.set_shader_parameter("drift_contrast", float(cfg.get("clump_contrast", 0.78)))
	# Same ground refusal as the grass, by NAME, and for the sharper reason
	# here: a green wash over the paths at distance erases the lines the chapter
	# is navigated by.
	var names := _terrain_texture_names()
	var forbidden: Array = far_cfg.get("forbidden_ground", cfg.get("forbidden_ground", ["rock", "path"]))
	var mask := 0
	for i in names.size():
		if str(names[i]) in forbidden:
			mask |= 1 << i
	_far_material.set_shader_parameter("forbidden_base_mask", mask)

	var drawn := 0
	var used := 0
	if mesh.get_surface_count() > 0:
		drawn = mesh.surface_get_array_index_len(0) / 3
		used = mesh.surface_get_array_len(0)
	print("[grass_field] far cover: 1 sheet, %d tris, %d verts, %.0fm cell, %.0f-%.0fm reach" % [
		drawn, used, cell, inner, outer])
	if drawn == 0:
		push_warning("[grass_field] far cover built an empty sheet; nothing beyond the ring")


## The sheet's grid step. Forced to a whole multiple of the lattice cell, which
## is what makes the node's own 2m hop compensable into an exact offset -- see
## the FAR LATTICE note above. A step that did not divide would leave the sheet
## sampling different ground every time the ring moved.
static func far_lattice_cell(cfg: Dictionary) -> float:
	var base := lattice_cell()
	var want := maxf(float(cfg.get("far_cover", {}).get("far_cell", 6.0)), base)
	return base * maxf(round(want / base), 1.0)


## A terrain-following annulus on a `cell` grid.
##
## Vertices are generated for the whole square that bounds the disc and indexed
## only where they are used: an unreferenced vertex costs memory in the buffer
## and nothing on the GPU, which is the cheaper trade than the arithmetic to
## renumber a ragged grid. Heights are NOT baked in -- every vertex is placed
## onto the terrain in the vertex shader, the same way every other tier here is,
## so the sheet costs nothing when the terrain streams and needs no rebuild when
## the player walks somewhere else.
##
## A quad is included when its CENTRE is inside the ring, so the sheet's own
## outer boundary is ragged at the cell scale rather than a drawn circle. That
## is free and it helps: the alpha is already near zero out there, and a ragged
## edge under a noise field has nothing for the eye to lock onto.
func _far_mesh(inner: float, outer: float, cell: float) -> ArrayMesh:
	var steps := int(ceil(outer / cell))
	var side := steps * 2 + 1
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	verts.resize(side * side)
	normals.resize(side * side)
	for ix in side:
		for iz in side:
			var at := Vector3(float(ix - steps) * cell, 0.0, float(iz - steps) * cell)
			verts[ix * side + iz] = at
			# Overwritten per vertex in the shader from the height data. Supplied
			# because a surface with no normal array is lit as if it faced the
			# camera, which would show for the one frame before the shader runs
			# and in any tool that reads the mesh rather than renders it.
			normals[ix * side + iz] = Vector3.UP
	var indices := PackedInt32Array()
	var inner_sq := inner * inner
	var outer_sq := outer * outer
	for ix in side - 1:
		for iz in side - 1:
			var cx := (float(ix - steps) + 0.5) * cell
			var cz := (float(iz - steps) + 0.5) * cell
			var d := cx * cx + cz * cz
			if d < inner_sq or d > outer_sq:
				continue
			var a := ix * side + iz
			var b := (ix + 1) * side + iz
			var c := ix * side + iz + 1
			var e := (ix + 1) * side + iz + 1
			# Wound so the sheet faces up. `cull_disabled` in the shader means a
			# mistake here would not show as a hole, only as a normal pointing
			# into the ground, which is the harder failure to see.
			indices.append_array([a, c, b, b, c, e])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## The meshes the cover tiers use, generated rather than imported so no asset
## enters the repository -- `CLAUDE.md`'s no-new-assets rule for the Meadows is
## untouched by any of this. UV.y runs 0 at the base to 1 at the top in every
## one of them, because that is the channel the shader's tint gradient and its
## contact darken both read.
func _cover_mesh(kind: String) -> ArrayMesh:
	match kind:
		"flower":
			return _flower_mesh()
		"litter":
			return _litter_mesh()
		_:
			return _bush_mesh()


## A small bush: leaves carried on branches, not floating in a dome.
##
## The owner's words on the previous version were the whole brief: "they can't
## just be random leaves in the air. there needs to be some sort of stick
## connecting the leaves". That version placed its leaves on five concentric
## RINGS at fixed radii, so every leaf's stem end touched nothing -- the shape
## was right from a distance and fell apart the moment you stood next to it.
##
## So the structure is the plant now. A short trunk, `BUSH_BRANCHES` sticks
## arcing up and outward from it, and every leaf anchored at a point ON one of
## those sticks with its stem end (UV2.x = 0) exactly at the wood. That is what
## "connected" means geometrically: not a stem drawn near the leaf, but the leaf
## built from the branch point outward.
##
## Branch and trunk vertices carry UV2.y = WOOD_FLAG. `cover_tier.gdshader`
## reads it to do two things it must not do to wood: skip the leaf-outline
## alpha cut, which would eat a twig, and take the wood tint instead of the
## leaf gradient. Leaf seeds are all in [0, 1), so a flag at 2.0 cannot collide
## with one.
##
## DECORATIVE ONLY -- the harvestable bushes stay scattered, because harvesting
## needs an identity that survives and a generated thing has none.
# Eight branches of ten, not six of nine, and wider than the first attempt.
# That first attempt gave the leaves a stick and lost the MASS doing it -- six
# sparse branches at 0.80m read as a spindly sapling with bare wood at the
# bottom, where the tier's whole job is the knee-height band between 50cm
# grass and 6m canopy. Denser, shorter and broader gets the structure and the
# mass at the same time. Costs about 190 triangles a bush against 104 before;
# `count` in the config is the dial if a handheld pass says no.
const BUSH_BRANCHES := 8
const BUSH_LEAVES_PER_BRANCH := 10
const BUSH_HEIGHT := 0.72
const WOOD_FLAG := 2.0


## Where a branch is at `t` along itself, 0 at the trunk and 1 at the tip. The
## outward term is powered so the branch leaves the trunk steeply and only bends
## away near its end -- a shrub's branches rise before they spread, and a linear
## fan reads as an umbrella.
func _branch_point(out: Vector3, t: float) -> Vector3:
	return Vector3.UP * (0.05 + t * (BUSH_HEIGHT - 0.05)) + out * (pow(t, 1.5) * 0.36)


## VP2: `leaf_step` > 1 emits every `leaf_step`-th leaf of each branch, for the
## far LOD bush. The kept leaves are the same leaves at the same points on the
## same branches; the bush just carries fewer of them where it is a few pixels.
func _bush_mesh(leaf_step: int = 1) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()

	# Trunk: two crossed quads, so it does not vanish edge-on the way a single
	# strip would. Short, because what the eye needs is the leaves having
	# somewhere to come from, not a visible stem.
	for cross in 2:
		var dir := Vector3(1.0, 0.0, 0.0) if cross == 0 else Vector3(0.0, 0.0, 1.0)
		var first := verts.size()
		for corner in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
			var w: float = 0.020 * (1.0 - 0.35 * float(corner.y))
			verts.append(dir * corner.x * w + Vector3.UP * corner.y * 0.13)
			normals.append(Vector3(dir.z, 0.6, -dir.x).normalized())
			uvs.append(Vector2(0.5, clamp(float(corner.y) * 0.16 / 0.95, 0.0, 1.0)))
			uv2s.append(Vector2(float(corner.y), WOOD_FLAG))
		indices.append_array([first, first + 1, first + 2, first + 1, first + 3, first + 2])

	for b in BUSH_BRANCHES:
		# Golden-ratio yaw rather than an even fan: six branches at exactly 60
		# degrees read as a manufactured rosette from above.
		var yaw := TAU * (float(b) * 0.6180339 + 0.11)
		var out := Vector3(sin(yaw), 0.0, cos(yaw))
		var side := Vector3(out.z, 0.0, -out.x)

		# The branch itself: a tapered strip in the plane containing `out` and
		# up, so it presents its face outward and is seen from most angles.
		var segments := 3
		var first_b := verts.size()
		for seg in segments + 1:
			var t := float(seg) / float(segments)
			var at := _branch_point(out, t)
			var w := 0.013 * (1.0 - 0.70 * t)
			for sign_x in [-1.0, 1.0]:
				verts.append(at + side * sign_x * w)
				normals.append((side * sign_x * 0.3 + Vector3.UP * 0.7).normalized())
				uvs.append(Vector2(0.5, clamp(at.y / 0.95, 0.0, 1.0)))
				uv2s.append(Vector2(t, WOOD_FLAG))
			if seg > 0:
				var a := first_b + (seg - 1) * 2
				indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])

		for k in BUSH_LEAVES_PER_BRANCH:
			if leaf_step > 1 and k % leaf_step != 0:
				continue
			# Leaves start a little up the branch: bare wood at the bottom is
			# what makes the branch readable as a branch at all.
			# From 0.14, not 0.22: a long bare shank at the bottom of every
			# branch was the loudest thing wrong with the first branched version.
			var t: float = 0.14 + 0.86 * float(k) / float(BUSH_LEAVES_PER_BRANCH - 1)
			var at := _branch_point(out, t)
			var ahead := _branch_point(out, min(t + 0.06, 1.0))
			var behind := _branch_point(out, max(t - 0.06, 0.0))
			var tangent := (ahead - behind).normalized()
			# Alternate sides down the branch, the way a shrub actually sets
			# them, rather than radiating every leaf outward from a centre.
			var sign_k := 1.0 if k % 2 == 0 else -1.0
			var axis := (tangent * 0.5 + side * sign_k * 0.62 + Vector3.UP * 0.42).normalized()
			var leaf_side := axis.cross(Vector3.UP)
			if leaf_side.length() < 0.05:
				leaf_side = out
			leaf_side = leaf_side.normalized()

			var length: float = 0.150 * (1.0 - 0.30 * t)
			var half := length * 0.5 * 0.56
			var seed := fposmod(float(b) * 0.317 + float(k) * 0.6180339, 1.0)
			var first := verts.size()
			for corner in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
				# `corner.y` 0 is the leaf's STEM END and it sits exactly on the
				# branch point. That is the whole fix: the leaf is built out of
				# the wood rather than placed beside it.
				verts.append(at + leaf_side * corner.x * half + axis * corner.y * length)
				# Weighted toward the leaf's own axis rather than world up. An
				# even split put whole rings' normals nearly straight up, so
				# every leaf took full sun at once and the bush read as a
				# handful of bright flat flakes sitting in the grass.
				normals.append((axis * 0.85 + Vector3.UP * 0.25).normalized())
				# UV.y across the whole BUSH height, not the leaf's own, so the
				# shader's base-to-tip tint gradient runs up the plant.
				# Typed, not inferred: `corner` comes from an untyped Array
				# literal so `corner.y` is a Variant.
				var cy: float = float(corner.y)
				var world_y: float = at.y + cy * length * axis.y
				uvs.append(Vector2(corner.x * 0.5 + 0.5, clamp(world_y / 0.95, 0.0, 1.0)))
				# Leaf-local height and this leaf's own seed, for the outline
				# mask and the per-leaf shading in the fragment stage.
				uv2s.append(Vector2(cy, seed))
			indices.append_array([first, first + 1, first + 2, first + 1, first + 3, first + 2])

	return _mesh_from(verts, normals, uvs, indices, uv2s)


## A flower: a thin stem with a small flat head. The head is what carries the
## colour, so the shader's tint_tip is the bloom and tint_base the stalk.
func _flower_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()
	# Stem.
	var first := verts.size()
	for corner in [Vector2(-1.0, 0.0), Vector2(1.0, 0.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
		verts.append(Vector3(corner.x * 0.016, corner.y * 0.80, 0.0))
		normals.append(Vector3(0.0, 0.5, 1.0).normalized())
		uvs.append(Vector2(corner.x * 0.5 + 0.5, corner.y * 0.74))
		uv2s.append(Vector2(corner.y, 0.0))
	indices.append_array([first, first + 1, first + 2, first + 1, first + 3, first + 2])
	# Head: five petals SPLAYED outward from a centre, wider than the head is
	# tall. Two earlier versions were wrong in opposite directions. Horizontal
	# quads facing up read as white paper squares lying in the grass. Tall
	# vertical crossed petals, narrow at the base and wide at the top, read as
	# paper CONES -- a field of lilac arrowheads, which is what the owner saw.
	#
	# A bloom is a disc with a rim, not a spike: so each petal leaves the centre
	# at about 40 degrees above horizontal, is widest across its middle and
	# rounds off at its tip, and five of them close into a shape whose
	# silhouette is round from the side and from above alike.
	var head_y := 0.72
	for i in 5:
		var yaw := TAU * float(i) / 5.0 + 0.31
		var out := Vector3(sin(yaw), 0.0, cos(yaw))
		var side := Vector3(out.z, 0.0, -out.x)
		var axis := (out * 0.78 + Vector3.UP * 0.62).normalized()
		var start_i := verts.size()
		# Four spans along the petal rather than one quad, so it can be narrow
		# at the throat, broad across the middle and rounded at the tip.
		var spans := [
			{"at": 0.00, "w": 0.022},
			{"at": 0.38, "w": 0.062},
			{"at": 0.72, "w": 0.058},
			{"at": 1.00, "w": 0.020},
		]
		for span_index in spans.size():
			var span: Dictionary = spans[span_index]
			var along: float = float(span["at"]) * 0.135
			var half: float = float(span["w"])
			for sign_x in [-1.0, 1.0]:
				verts.append(Vector3.UP * head_y + axis * along + side * (sign_x * half))
				normals.append((Vector3.UP * 0.85 + out * 0.4).normalized())
				uvs.append(Vector2(sign_x * 0.5 + 0.5, 0.84 + float(span["at"]) * 0.16))
				uv2s.append(Vector2(float(span["at"]), float(i) * 0.2))
			if span_index > 0:
				var a := start_i + (span_index - 1) * 2
				indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])
	return _mesh_from(verts, normals, uvs, indices, uv2s)


## Forest litter: flat irregular scraps lying on the ground. Near-zero height,
## so `slope_lie` puts them ON the terrain rather than standing them up on it.
func _litter_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in 4:
		var yaw := TAU * float(i) / 4.0 + 0.4 * float(i)
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		var side := Vector3(dir.z, 0.0, -dir.x)
		var at := dir * (0.18 + 0.22 * float(i % 2))
		var w := 0.16 + 0.08 * float(i % 3)
		var first := verts.size()
		for corner in [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]:
			verts.append(at + side * corner.x * w + dir * corner.y * w
					+ Vector3.UP * (0.012 + 0.01 * float(i % 2)))
			normals.append(Vector3.UP)
			# UV.y near 1 everywhere: litter has no base-to-tip gradient, it is
			# all "tip", so the shader's contact darken does not black it out.
			uvs.append(Vector2(corner.x * 0.5 + 0.5, 0.85))
			# Leaf-local, so `leaf_cut` can carve these scraps into fallen
			# leaves. The comment above calls them "irregular"; as squares they
			# were not, and the same mask that shapes a bush leaf shapes these.
			uv2s.append(Vector2(corner.y * 0.5 + 0.5, float(i) * 0.23))
		indices.append_array([first, first + 1, first + 2, first + 1, first + 3, first + 2])
	return _mesh_from(verts, normals, uvs, indices, uv2s)


## `uv2` carries the LEAF-LOCAL coordinate that `cover_tier.gdshader`'s
## `leaf_cut` carves its outline against: x runs 0 at the leaf's stem end to 1
## at its tip, y is a per-leaf random so no two leaves on one bush get the same
## silhouette. It cannot be folded into UV, because UV.y is already spoken for
## -- it runs up the whole BUSH, which is what the tint gradient and the contact
## darken read. Every cover mesh must supply it: a mesh with no UV2 reads (0, 0)
## in the shader, and a leaf-local height pinned at 0 is a leaf of zero width.
func _mesh_from(verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, indices: PackedInt32Array,
		uv2s: PackedVector2Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## The stone tier: loose grit, gravel and field stone, on the same ring.
##
## Built as a child rather than a second top-level node so it inherits the
## camera follow for free. It is a separate MultiMesh because it is a different
## mesh, a different mask and a different shader -- stone lies on the ground
## where grass refuses to grow, and the two read the SAME control map with the
## mask inverted, so they tile the ground between them without either being told
## where the other is.
##
## The defect it exists for, from a blind pass asked the question directly:
## stones, path edges and tree bases "sit on top" of the ground rather than
## bedding into it, and the path "shares one texture with the meadow, so the
## boundary is a density edge rather than a material edge, and it looks cut".
func _build_stones(cfg: Dictionary, radius: float) -> void:
	var stone_cfg: Dictionary = cfg.get("stones", {})
	if not bool(stone_cfg.get("enabled", true)):
		return
	var count := int(stone_cfg.get("count", 26000))
	if count <= 0:
		return

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _stone_mesh(int(stone_cfg.get("sides", 7)))

	# Same disc law and the same lattice as the tufts, fitted to this tier's
	# own count and bias. Its own schedule rather than a shared one: the two
	# tiers have different densities, so a plan good for 300,000 tufts would
	# quantise 90,000 stones badly.
	var cell := lattice_cell()
	var plan := _lattice_plan(count, radius,
			float(stone_cfg.get("centre_bias", 0.58)), cell, cfg)
	# VP2: a 10cm stone is sub-pixel long before the ring ends. See `_cap_reach`.
	if stone_cfg.has("reach_m"):
		plan = _cap_reach(plan, float(stone_cfg["reach_m"]),
				float(stone_cfg.get("reach_band_m", cfg.get("reach_band_m", 6.0))), cell)

	_stones = MultiMeshInstance3D.new()
	_stones.name = "StoneField"
	_stone_material = ShaderMaterial.new()
	_stone_material.shader = load(STONE_SHADER_PATH)
	_stones.material_override = _stone_material
	# VP2: tiled like the grass ring, for the same culling reason.
	var tile_m := cull_tile_m(cfg)
	var placed := 0
	if tile_m > 0.0:
		placed = _stand_up_tiles(_stones, "StoneTile",
				_fill_lattice_tiles(mm.mesh, plan, cell, tile_m), _stone_material)
	else:
		placed = _fill_lattice(mm, plan, cell)
		_stones.multimesh = mm
	# A pebble's shadow is not information at this size, and thousands of them
	# would be the same black carpet `vegetation.json`'s grass layer turned its
	# own shadows off for. The shader darkens each stone at its own contact
	# instead, which is the read that was actually missing.
	_stones.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stones.custom_aabb = custom_aabb
	add_child(_stones)
	_apply_lattice(_stone_material, plan, cell)
	print("[grass_field] stone ring: %d instances over %d lattice layers (count %d)" % [
		placed, plan.size(), count])

	for key: String in [
		"stone_size", "size_jitter", "sink", "density_gain", "clump_scale",
		"clump_contrast", "tint_jitter", "ground_blend", "contact_darken", "slope_lie",
		"stray_chance", "verge_gain", "field_radius", "fade_start",
	]:
		if stone_cfg.has(key):
			_stone_material.set_shader_parameter(key, float(stone_cfg[key]))
		elif cfg.has(key):
			_stone_material.set_shader_parameter(key, float(cfg[key]))
	if stone_cfg.has("tint_stone"):
		_stone_material.set_shader_parameter("tint_stone", Color(str(stone_cfg["tint_stone"])))
	# Where stone is ALLOWED is built from the same named texture list the grass
	# field builds its forbidden mask from, so the two are inverses by
	# construction rather than by two lists somebody has to keep in step.
	var names := _terrain_texture_names()
	var allowed: Array = stone_cfg.get("ground", ["rock", "path"])
	var mask := 0
	for i in names.size():
		if str(names[i]) in allowed:
			mask |= 1 << i
	_stone_material.set_shader_parameter("allowed_base_mask", mask)


## One stone: a squat faceted dome, generated rather than imported so no asset
## enters the repository. Flat-bottomed on purpose -- the shader buries the
## bottom, and a sphere would show its underside on a slope.
func _stone_mesh(sides: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	# Two rings and a crown: enough to read as a rounded stone at the size these
	# are drawn, and 3 * sides triangles rather than a sphere's dozens.
	var rings := [
		{"y": 0.0, "r": 0.5},
		{"y": 0.22, "r": 0.44},
		{"y": 0.38, "r": 0.26},
	]
	for ring_index in rings.size():
		var ring: Dictionary = rings[ring_index]
		for i in sides:
			var a := TAU * float(i) / float(sides)
			# A little per-vertex wobble so the silhouette is not a polygon.
			var wobble := 1.0 + 0.16 * sin(float(i) * 2.7 + float(ring_index) * 1.9)
			verts.append(Vector3(sin(a), 0.0, cos(a)) * float(ring["r"]) * wobble
					+ Vector3.UP * float(ring["y"]))
			normals.append(Vector3(sin(a) * 0.7, 0.6, cos(a) * 0.7).normalized())
	var crown := verts.size()
	verts.append(Vector3.UP * 0.44)
	normals.append(Vector3.UP)
	for ring_index in rings.size() - 1:
		for i in sides:
			var a0 := ring_index * sides + i
			var a1 := ring_index * sides + (i + 1) % sides
			var b0 := a0 + sides
			var b1 := a1 + sides
			indices.append_array([a0, b0, a1, a1, b0, b1])
	var top := (rings.size() - 1) * sides
	for i in sides:
		indices.append_array([top + i, crown, top + (i + 1) % sides])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## One tuft: a handful of tapered blades at different yaws, sharing one mesh.
##
## Generated rather than imported, and that is deliberate on two counts. It adds
## no asset to the repository, so `CLAUDE.md`'s no-new-assets rule for the
## Meadows is untouched. And it is what lets the blade carry `UV.y` as "height
## along the blade", which is the channel the base-to-tip gradient and the
## ground blend both read -- the two things a blind critic named as missing from
## the scattered tufts ("flat two-tone polygon... no base-to-tip gradient, no
## translucency, no ground blend").
## VP2: `keep` is how many of the `blades` are actually emitted. The loop still
## runs over all of them so a kept blade's yaw and offset are the ones it has
## in the full mesh -- the far LOD tuft is the near tuft with its last blades
## missing, not a different tuft.
func _tuft_mesh(blades: int, segments: int, keep: int = -1) -> ArrayMesh:
	if keep < 0:
		keep = blades
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	# UV2.x carries WHICH BLADE of the tuft this vertex belongs to. Without it
	# every blade in a tuft hashes on the same instance origin and therefore
	# gets the same height, the same lean and the same lean direction -- five
	# parallel strips, which a blind critic read exactly as "a comb, or a field
	# of leeks, not a meadow".
	var uv2s := PackedVector2Array()
	var indices := PackedInt32Array()

	# Metres, baked. An earlier version carried the mesh in [-0.5, 0.5] and let
	# the shader's `blade_width` scale x -- which also scaled the OFFSET below,
	# so the four blades of a tuft collapsed to two centimetres apart and every
	# tuft rendered as one wide leaf. Real dimensions here, and `blade_width`
	# is a multiplier around 1.0.
	# 16mm half-width and a tip that keeps 40% of it. An earlier version tapered
	# to 15% of an 11mm blade, which is a 1.6mm tip -- sub-pixel at any distance
	# past a couple of metres, and it aliased into white speckle across the whole
	# field rather than reading as grass.
	# 11mm blades, and the number has now been wrong in both directions. At 19mm
	# a blind critic measured them against the 1.80m trainer and called them
	# 4-6cm where real meadow grass at this height is 3-6mm -- "a field of
	# leeks". At a literal 6mm they are correct and read WORSE: a 6mm blade is
	# under a pixel wide beyond a few metres on a 1280-wide frame, so the field
	# dissolves into wisp and the software rasteriser has no coverage AA to
	# recover it. 11mm is the compromise the render resolution actually
	# supports, not the botanically right answer. Revisit if the game ever
	# renders at a resolution where a thinner blade survives minification.
	var half_width := 0.0055
	var spread := 0.075
	for b in blades:
		if b >= keep:
			continue
		var yaw := TAU * float(b) / float(blades) + 0.37 * float(b)
		var dir := Vector3(sin(yaw), 0.0, cos(yaw))
		var side := Vector3(dir.z, 0.0, -dir.x)
		var normal := dir
		# Blades of one tuft start at slightly different points so the tuft has
		# a footprint rather than a single stem.
		var offset := (dir * 0.6 + side * (float(b) - float(blades - 1) * 0.5)) * spread
		var first := verts.size()
		for s in segments + 1:
			var t := float(s) / float(segments)
			# Taper: full width at the base, a point at the tip.
			var half := half_width * (1.0 - t * t * 0.55)
			verts.append(offset + side * -half + Vector3.UP * t)
			verts.append(offset + side * half + Vector3.UP * t)
			normals.append(normal)
			normals.append(normal)
			uvs.append(Vector2(0.0, t))
			uvs.append(Vector2(1.0, t))
			var blade_id := float(b) / float(blades)
			uv2s.append(Vector2(blade_id, 0.0))
			uv2s.append(Vector2(blade_id, 0.0))
		for s in segments:
			var a := first + s * 2
			indices.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = uv2s
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _apply_config(cfg: Dictionary) -> void:
	for key: String in [
		"field_radius", "fade_start", "blade_width", "height_near", "height_far",
		"height_jitter", "bend", "shade_jitter", "density_gain", "clump_scale", "clump_contrast",
		"ground_blend", "translucency", "wind_strength", "wind_scale",
		"gust", "gust_speed", "gust_length", "edge_shorten_floor", "edge_shorten_bias",
	]:
		if cfg.has(key):
			_material.set_shader_parameter(key, float(cfg[key]))
	for key: String in ["tint_base", "tint_tip"]:
		if cfg.has(key):
			_material.set_shader_parameter(key, Color(str(cfg[key])))
	if cfg.has("wind_dir"):
		var d: Array = cfg["wind_dir"]
		_material.set_shader_parameter("wind_dir",
				Vector2(float(d[0]), float(d[1])).normalized())
	# Which terrain textures grass refuses. Named rather than numbered in the
	# config, because `terrain_playground.json`'s texture ORDER is what decides
	# the ids and a lane that reorders it must not silently move the mask.
	var names: Array = []
	var terrain_cfg := _terrain_texture_names()
	for entry: Variant in cfg.get("forbidden_ground", ["rock", "path"]):
		names.append(str(entry))
	var mask := 0
	for i in terrain_cfg.size():
		if str(terrain_cfg[i]) in names:
			mask |= 1 << i
	_material.set_shader_parameter("forbidden_base_mask", mask)


## Tell the grass where the bushes gather, so it gives way to them.
##
## The grass and the cover tiers are separate MultiMeshes that know nothing
## about each other, so without this they simply occupy the same ground: blades
## stand through leaves and the near field reads as two systems drawn over each
## other rather than as one meadow. A bush shades out what grows beneath it, and
## this is that, done the only way two independent procedural fields can agree
## on anything -- by evaluating the SAME function.
##
## So the numbers are read off the claiming tier's own config entry rather than
## written twice. A tier claims clearings with `clears_grass`, and the shader's
## `clearing_*` uniforms are its `drift_scale` and `drift_contrast` verbatim; if
## the bushes move, the thinning moves with them. With no tier claiming,
## `clearing_strength` stays 0 and the grass shader skips the work entirely.
func _apply_clearing(cfg: Dictionary) -> void:
	if _material == null:
		return
	for entry: Variant in cfg.get("cover_tiers", []):
		var tier: Dictionary = entry
		if not (bool(tier.get("enabled", true)) and bool(tier.get("clears_grass", false))):
			continue
		_material.set_shader_parameter("clearing_scale", float(tier.get("drift_scale", 0.05)))
		_material.set_shader_parameter("clearing_contrast", float(tier.get("drift_contrast", 0.88)))
		_material.set_shader_parameter("clearing_strength",
				float(cfg.get("clearing_strength", 0.85)))
		_material.set_shader_parameter("clearing_floor", float(cfg.get("clearing_floor", 0.78)))
		_material.set_shader_parameter("clearing_shorten", float(cfg.get("clearing_shorten", 0.45)))
		return


## The terrain config, read once. Two readers here: the texture NAME list the
## masks are built from, and (VP2) the shader block's macro colours the far
## sheet mirrors.
static var _terrain_cfg: Dictionary = {}
static var _terrain_cfg_read := false


static func _terrain_config() -> Dictionary:
	if _terrain_cfg_read:
		return _terrain_cfg
	_terrain_cfg_read = true
	var file := FileAccess.open("res://data/config/terrain_playground.json", FileAccess.READ)
	if file == null:
		return _terrain_cfg
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_terrain_cfg = parsed
	return _terrain_cfg


func _terrain_texture_names() -> Array:
	var out: Array = []
	for entry: Variant in _terrain_config().get("textures", []):
		out.append(str((entry as Dictionary).get("name", "")))
	return out


## Point the field at the terrain whose height data it should sample, and at the
## camera it should follow. Called by `playground_world.gd` once both exist;
## kept explicit rather than searched for, so a scene that has no terrain gets a
## clear "not bound" rather than a field lying flat at y=0.
func bind(terrain: Node, camera: Camera3D) -> void:
	_terrain = terrain
	_camera = camera
	_bind_terrain()


## Follow whichever camera is ACTUALLY RENDERING, and say so loudly the first
## time that is not the one `bind` was handed.
##
## T1-GROUND-3, and this is an evidence-integrity fix rather than a look one.
## The 2026-08-30 blind pass opened with the owner's words -- "some of those
## renders are just a bad shot not actual game. the game doesn't have the haze
## and has real grass" -- and found frame after frame of committed lane
## evidence showing bushes, reeds and fern cards standing on a bare splat with
## not one blade between them. It attributed that to "the capture path
## generally (or software GL)". It is neither. It is this binding.
##
## `playground_world.gd::_stand_up_the_grass_field` binds the field to the
## GAMEPLAY camera, and its own comment already states the failure mode in so
## many words: "handed the wrong one it centres its ring somewhere the player
## is not and the ground goes bare exactly where they are standing." A capture
## tool that builds its own Camera3D and calls `make_current()` does exactly
## that -- the ring stays parked on the gameplay camera and the shot frames
## ground the field is not dressing. Every such frame shows the baked scatter
## (which is placed in world space and does not care) on naked terrain, which
## is precisely the artefact the judge described.
##
## Measured across `tools/`: 128 scripts construct their own Camera3D, and
## FIVE of them rebind this field. So 123 capture tools could silently produce
## grass-free evidence, and the ones that happen to be fine are fine by
## accident -- `_capture_ground_and_sky.gd`'s frames have grass only because it
## stands the PLAYER at every shot, which drags the gameplay camera along with
## it. Nobody reading a frame can tell which kind they are holding.
##
## Fixing 123 tools by hand would not hold: tool 129 reintroduces it. So the
## field follows the rendering camera instead. That is also simply more
## correct -- this node's whole job is to dress the ground being drawn -- and
## it costs one viewport lookup per frame. `bind` stays the authority for the
## terrain handle and for the initial camera; this only ever redirects the
## follow, and it complains once when it has to, so a genuine mis-binding in
## gameplay is still loud rather than silently papered over.
func _follow_camera() -> void:
	var rendering := get_viewport().get_camera_3d() if get_viewport() != null else null
	if rendering == null or rendering == _camera:
		return
	if not _warned_camera_swap:
		_warned_camera_swap = true
		push_warning(("[grass_field] the rendering camera (%s) is not the one bind() was given (%s); " +
			"following the rendering one. In a CAPTURE this is expected -- see _follow_camera. " +
			"In GAMEPLAY it means the ground is being dressed around the wrong eye.") % [
				rendering.name, _camera.name if is_instance_valid(_camera) else "<none>"])
		print("[grass_field] now following rendering camera '%s'" % rendering.name)
	_camera = rendering


## Mirror Terrain3D's own map textures and region lookup onto this material.
##
## Read off the LIVE terrain rather than configured here, because the two must
## agree exactly: the shader reproduces Terrain3D's region arithmetic, and a
## region size or vertex spacing that disagreed by one would put the whole field
## on the wrong ground without erroring.
##
## The three map textures are bound through `RenderingServer.material_set_param`
## rather than `set_shader_parameter` because `Terrain3DData` hands them out as
## RIDs (`get_height_maps_rid()` and friends) and there is no Texture2DArray
## object to pass.
func _bind_terrain() -> void:
	if _terrain == null or _material == null:
		return
	var data: Object = _terrain.get("data")
	if data == null:
		push_warning("[grass_field] terrain has no data; the field cannot find the ground")
		return

	# Every tier, through the one list, so a tier added later cannot be left
	# unbound -- which does not error, it renders the tier at whatever an
	# unbound sampler2DArray returns, kilometres off the ground.
	for material: ShaderMaterial in _field_materials():
		_bind_maps(material.get_rid(), data)
	_bind_region_uniforms(data)

	# Say out loud whether the stone tier actually got the terrain, because the
	# failure mode when it does not is silent and spectacular: an unbound
	# `sampler2DArray` still texelFetches, at a layer index this shader takes up
	# to the region count, and the undefined result goes straight into a vertex
	# Y offset. The stones then render kilometres up as a dome of white shards.
	# It cost two render cycles of guessing before this line existed.
	if _stone_material != null:
		var stone_rid: RID = _stone_material.get_rid()
		print("[grass_field] stone tier: rid_valid=%s height_map=%s region_map=%d entries" % [
			str(stone_rid.is_valid()),
			str(RenderingServer.material_get_param(stone_rid, "_height_maps")),
			(RenderingServer.material_get_param(stone_rid, "_region_map") as Array).size()
				if RenderingServer.material_get_param(stone_rid, "_region_map") != null else -1])


## The three map textures, onto one material. Bound through the RenderingServer
## rather than `set_shader_parameter` because `Terrain3DData` hands them out as
## RIDs and there is no Texture2DArray object to pass.
func _bind_maps(rid: RID, data: Object) -> void:
	for pair: Array in [
		["_height_maps", "get_height_maps_rid"],
		["_control_maps", "get_control_maps_rid"],
		["_color_maps", "get_color_maps_rid"],
	]:
		if data.has_method(str(pair[1])):
			RenderingServer.material_set_param(rid, str(pair[0]), data.call(str(pair[1])))


## The region arithmetic, onto both materials. Read off the LIVE terrain: the
## shaders reproduce Terrain3D's own lookup and a region size or vertex spacing
## that disagreed by one would put the whole field on the wrong ground.
func _bind_region_uniforms(data: Object) -> void:
	var region_size := float(_terrain.get("region_size"))
	var vertex_spacing := float(_terrain.get("vertex_spacing"))
	var region_map: Array = data.call("get_region_map") if data.has_method("get_region_map") else []
	var map := PackedInt32Array()
	map.resize(region_map.size())
	for i in region_map.size():
		map[i] = int(region_map[i])

	for mat: ShaderMaterial in _field_materials():
		mat.set_shader_parameter("_region_size", region_size)
		mat.set_shader_parameter("_region_texel_size", 1.0 / region_size)
		mat.set_shader_parameter("_region_map_size", int(sqrt(float(region_map.size()))))
		mat.set_shader_parameter("_vertex_density", 1.0 / vertex_spacing)
		mat.set_shader_parameter("_region_map", map)
	_bound = true
	# The first list, before the ring has moved at all: a probe or a boot that
	# starts the player inside a building must not have to walk a cell before
	# the floor is clear.
	_apply_built(global_position)
	print("[grass_field] bound: %d tufts, radius %.0fm, region_size %.0f, vertex_spacing %.1f, %d region slots" % [
		_ring_instances,
		float(config().get("field_radius", 48.0)), region_size, vertex_spacing, map.size()])


# ---------------------------------------------------------------------------
# BUILT GROUND. Where the field must not grow, because something is standing
# there.
#
# THE DEFECT, in the owner's words on 2026-08-28: "grass grows through indoor
# buildings now". The word that dates it is NOW -- the field was switched on
# the day before, and this is what it brought with it. The field's only
# exclusion was terrain TEXTURE names (`forbidden_ground`, rock and path), and
# a texture name cannot know that a farmhouse is standing on the grass it
# names. So the ground under Grandpa's floor is grass-painted, and the field
# grew grass out of it, through the boards and the rug.
#
# THE SCATTER ALREADY SOLVED THIS AND THE FIELD DID NOT READ THE ANSWER.
# `scatter_rules.gd::_inside_a_footprint` gates every baked placement on a list
# of building footprints, and that list is authored with this exact defect in
# its own comments -- "grass was standing on the floor and the rug" against
# Grandpa's house, "grass out of the tower and from under the wheel" against
# the mill. So this reads `vegetation.json`'s OWN `footprints` rather than
# copying the numbers, for the same reason `_apply_clearing` reads the bush
# tier's own drift numbers: two lists of building positions would be one edit
# away from disagreeing, and the way you would find out is grass on a rug.
#
# RUNTIME BUILDINGS TOO. The player lays floor panels with the Build verb and
# those did not exist when anything was baked, so authored footprints cannot
# cover them. Live nodes in `build_placer.gd`'s `placed_building` group are
# folded into the same list every time the ring moves a cell.
#
# COST, and why it is a list rather than a mask texture. The loop below runs
# `built_count` times per vertex, and `built_count` is ZERO almost everywhere
# in a 16.8 km2 corridor -- the whole world holds seven authored footprints.
# Where it is not zero it is one or two, and a bounding circle rejects the rest
# of the ring in a single test before the loop is entered at all. A mask
# texture would cost a vertex texture fetch everywhere to save work in the
# village, which is the wrong trade for this world.
# ---------------------------------------------------------------------------

## The most footprints the field will consider at once. Shared with the
## `built[]` uniform's own length in all three field shaders -- raising it here
## alone would index off the end of that array.
const MAX_BUILT := 24
## `build_placer.gd`'s own group and meta names, so a rename there is one grep
## away rather than a silent failure here.
const PLACED_GROUP := "placed_building"
const BUILDING_ID_META := "building_id"
## The group any placed structure may put itself in to say "nothing grows on
## the ground I am standing on", carrying its own radius in metres as
## `CLEAR_RADIUS_META`. `village.gd` and `burrow_warrens.gd` use it.
##
## WHY A GROUP RATHER THAN MORE CONFIG. `vegetation.json`'s `footprints` is the
## right home for a building's footprint and it is the list this file reads
## first -- but it is hashed into `scatter_bake.gd::config_fingerprint`, so
## adding an entry to it invalidates the committed scatter bake and costs a
## re-bake of 256 binary region files. That is the correct price for the
## SCATTER's own placements and the wrong one for a structure that only the
## runtime field grows through. A structure that knows its own extents can say
## so from its own code instead, which also covers everything a baked list
## cannot: geometry built at load, and geometry the player builds.
const CLEAR_GROUP := "grass_clear"
const CLEAR_RADIUS_META := "grass_clear_radius"

## The authored footprints, resolved once. `scatter_rules.gd` merges them per
## band and caches; this only keeps the flattened (x, z, radius) form.
static var _authored: PackedVector3Array = PackedVector3Array()
static var _authored_ready := false

## The list currently pushed to the materials, so a ring move that changes
## nothing does not re-upload three uniform arrays.
var _built: PackedVector3Array = PackedVector3Array()


static func authored_footprints() -> PackedVector3Array:
	if _authored_ready:
		return _authored
	_authored_ready = true
	for entry: Variant in SCATTER_RULES.config().get("footprints", []):
		if not entry is Dictionary:
			continue
		var footprint: Dictionary = entry
		var radius := float(footprint.get("radius", 0.0))
		if radius <= 0.0:
			continue
		_authored.append(Vector3(float(footprint.get("x", 0.0)),
				float(footprint.get("z", 0.0)), radius))
	return _authored


## Every footprint the ring can currently see, nearest first, capped.
##
## Runtime pieces are filtered by id rather than taken wholesale: a floor panel
## is ground the player has covered over and grass through it is the reported
## defect, but a fence rail or a workbench is a thing STANDING in the meadow and
## clearing a disc of grass around it would read as a scorch mark. `_why` for
## the radius: pieces snap to `build_grid.gd`'s 2.0m cells, so 1.45m is that
## cell's half-diagonal -- the circle that covers a panel completely. The
## inscribed 1.0m circle does not: four of them around a shared corner leave
## that corner uncovered, and a floor grid would sprout a tuft at every corner
## in a regular pattern, which is a worse artefact than the one being fixed.
func _visible_footprints(centre: Vector3) -> PackedVector3Array:
	var cfg := config()
	var reach := float(cfg.get("field_radius", 48.0))
	var found: Array[Vector3] = []
	for spot: Vector3 in authored_footprints():
		if Vector2(spot.x - centre.x, spot.y - centre.z).length() <= reach + spot.z:
			found.append(spot)
	# Structures that declared their own footprint at build time -- village
	# buildings with a floor, the Warrens' approach apron, anything else that
	# knows its own extents. See CLEAR_GROUP above for why these are not in
	# `vegetation.json` with the authored seven.
	if is_inside_tree():
		for node: Node in get_tree().get_nodes_in_group(CLEAR_GROUP):
			var structure := node as Node3D
			if structure == null or not is_instance_valid(structure):
				continue
			var radius := float(structure.get_meta(CLEAR_RADIUS_META, 0.0))
			if radius <= 0.0:
				continue
			var here := structure.global_position
			if Vector2(here.x - centre.x, here.z - centre.z).length() <= reach + radius:
				found.append(Vector3(here.x, here.z, radius))
	var ids: Array = cfg.get("built_clear_ids", ["floor"])
	var piece_radius := float(cfg.get("built_piece_radius", 1.45))
	if is_inside_tree() and piece_radius > 0.0 and not ids.is_empty():
		for node: Node in get_tree().get_nodes_in_group(PLACED_GROUP):
			var body := node as Node3D
			if body == null or not is_instance_valid(body):
				continue
			if not (str(body.get_meta(BUILDING_ID_META, "")) in ids):
				continue
			var at := body.global_position
			if Vector2(at.x - centre.x, at.z - centre.z).length() <= reach + piece_radius:
				found.append(Vector3(at.x, at.z, piece_radius))
	if found.size() > MAX_BUILT:
		# Nearest first, because the ones the player is standing among are the
		# ones whose grass they can see through.
		found.sort_custom(func(a: Vector3, b: Vector3) -> bool:
			return Vector2(a.x - centre.x, a.y - centre.z).length_squared() \
					< Vector2(b.x - centre.x, b.y - centre.z).length_squared())
		found.resize(MAX_BUILT)
	var out := PackedVector3Array()
	for spot: Vector3 in found:
		out.append(spot)
	return out


## Push the footprint list to every field material, if it changed.
func _apply_built(centre: Vector3) -> void:
	if _material == null:
		return
	var built := _visible_footprints(centre)
	if built == _built:
		return
	_built = built
	# The bounding circle is the early-out: one test rejects the whole ring
	# wherever nothing is built, which is nearly all of it.
	var bounds := Vector3(centre.x, centre.z, 0.0)
	if not built.is_empty():
		var min_x := INF
		var max_x := -INF
		var min_z := INF
		var max_z := -INF
		for spot: Vector3 in built:
			min_x = minf(min_x, spot.x - spot.z)
			max_x = maxf(max_x, spot.x + spot.z)
			min_z = minf(min_z, spot.y - spot.z)
			max_z = maxf(max_z, spot.y + spot.z)
		var mid := Vector2((min_x + max_x) * 0.5, (min_z + max_z) * 0.5)
		bounds = Vector3(mid.x, mid.y,
				Vector2(max_x - mid.x, max_z - mid.y).length())
	var padded := built.duplicate()
	padded.resize(MAX_BUILT)
	for material: ShaderMaterial in _field_materials():
		material.set_shader_parameter("built", padded)
		material.set_shader_parameter("built_count", built.size())
		material.set_shader_parameter("built_bounds", bounds)


## Every material the field draws with. The three tiers take the same
## exclusions -- gravel and bushes inside a farmhouse are the same defect as
## grass inside it, and `scatter_rules.gd` gates every baked layer on
## footprints for exactly that reason.
func _field_materials() -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	if _material != null:
		out.append(_material)
	if _stone_material != null:
		out.append(_stone_material)
	out.append_array(_cover_materials)
	if _far_material != null:
		out.append(_far_material)
	return out

func _process(delta: float) -> void:
	if _material == null:
		return
	_wind += delta
	_material.set_shader_parameter("wind_time", _wind)
	for cover: ShaderMaterial in _cover_materials:
		cover.set_shader_parameter("wind_time", _wind)
	_follow_camera()
	if _camera == null or not is_instance_valid(_camera):
		return

	# TWO CENTRES, and separating them is half of the re-roll fix.
	#
	# `field_centre` is the eye, unquantised, written every frame. Everything
	# measured FROM it is a smooth function of distance -- the ring's edge
	# fade, the near-to-far blade height, each lattice layer's ramp -- and all
	# three used to step 2m at a time because they were reading the snapped
	# value. A distance that jumps is a height that jumps.
	#
	# The NODE, on the other hand, may only sit on whole lattice cells: it is
	# what anchors every instance to a world cell, and an unquantised node
	# would put the whole ring between cells and destroy the stability the
	# lattice exists for. So the eye moves continuously and the ring hops, and
	# the hop is invisible because nothing in the frame is measured from it.
	var at := _camera.global_position
	var eye := Vector3(at.x, 0.0, at.z)
	_material.set_shader_parameter("field_centre", eye)
	if _stone_material != null:
		_stone_material.set_shader_parameter("field_centre", eye)
	for cover: ShaderMaterial in _cover_materials:
		cover.set_shader_parameter("field_centre", eye)
	if _far_material != null:
		_far_material.set_shader_parameter("field_centre", eye)

	var cell := lattice_cell()
	var anchor := Vector3(snappedf(at.x, cell), 0.0, snappedf(at.z, cell))
	if anchor.is_equal_approx(_centre):
		return
	_centre = anchor
	global_position = anchor
	# The far sheet keeps its own coarser grid. Offsetting it by the difference
	# between this node's anchor and the same point snapped to `far_cell` puts
	# its vertices on one fixed world grid and holds them there -- without it
	# the sheet would resample the terrain every 2m step and the far ground
	# would swim, which is the defect the STABLE RING note above exists for,
	# reintroduced one tier further out.
	if _far != null:
		var far_cell := far_lattice_cell(config())
		_far.position = Vector3(snappedf(at.x, far_cell), 0.0, snappedf(at.z, far_cell)) - anchor
	# Which buildings the ring can currently see. Done on the ring's own move
	# rather than every frame: the list can only change when the ring has
	# travelled, and a player laying a floor panel is standing still inside the
	# cell they are building on, so the next step picks it up.
	_apply_built(anchor)
