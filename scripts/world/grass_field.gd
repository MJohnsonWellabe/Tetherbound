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
var _bound := false
var _wind := 0.0
## The lattice cell the ring is currently anchored to. The node only moves when
## this changes, which is most frames a no-op; `field_centre` is written every
## frame and is a different thing -- see `_process`.
var _centre := Vector3(INF, INF, INF)


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
# rerenders like every step". `ralph/OWNER_PLAYTEST_2026-08-28.md` is the
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
	var placed := _fill_lattice(mm, plan, cell)
	multimesh = mm

	_material = ShaderMaterial.new()
	_material.shader = load(SHADER_PATH)
	material_override = _material
	_apply_config(cfg)
	_apply_lattice(_material, plan, cell)
	print("[grass_field] grass ring: %d instances over %d lattice layers (%s asked for %d)" % [
		placed, plan.size(), "tuft_count", count])

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
	_apply_clearing(cfg)


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
		var placed := _fill_lattice(mm, plan, cell)

		var node := MultiMeshInstance3D.new()
		node.name = "Cover_" + str(tier.get("name", "tier"))
		node.multimesh = mm
		var mat := ShaderMaterial.new()
		mat.shader = load(COVER_SHADER_PATH)
		node.material_override = mat
		# Same reasoning as the grass and stone tiers: thousands of small
		# shadows overlap into a black carpet rather than reading as shade, and
		# the shader darkens each item at its own contact instead.
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.custom_aabb = custom_aabb
		add_child(node)

		for key: String in [
			"item_size", "size_jitter", "sink", "slope_lie", "density_gain",
			"drift_scale", "drift_contrast", "tint_jitter", "ground_blend",
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


func _bush_mesh() -> ArrayMesh:
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
	var placed := _fill_lattice(mm, plan, cell)

	_stones = MultiMeshInstance3D.new()
	_stones.name = "StoneField"
	_stones.multimesh = mm
	_stone_material = ShaderMaterial.new()
	_stone_material.shader = load(STONE_SHADER_PATH)
	_stones.material_override = _stone_material
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
func _tuft_mesh(blades: int, segments: int) -> ArrayMesh:
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


func _terrain_texture_names() -> Array:
	var file := FileAccess.open("res://data/config/terrain_playground.json", FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	var out: Array = []
	if parsed is Dictionary:
		for entry: Variant in (parsed as Dictionary).get("textures", []):
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

	var rids: Array[RID] = [_material.get_rid()]
	if _stone_material != null:
		rids.append(_stone_material.get_rid())
	for cover: ShaderMaterial in _cover_materials:
		rids.append(cover.get_rid())
	for rid: RID in rids:
		_bind_maps(rid, data)
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

	var all: Array[ShaderMaterial] = [_material, _stone_material]
	all.append_array(_cover_materials)
	for mat: ShaderMaterial in all:
		if mat == null:
			continue
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
		multimesh.instance_count if multimesh != null else 0,
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
	return out

func _process(delta: float) -> void:
	if _material == null:
		return
	_wind += delta
	_material.set_shader_parameter("wind_time", _wind)
	for cover: ShaderMaterial in _cover_materials:
		cover.set_shader_parameter("wind_time", _wind)
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

	var cell := lattice_cell()
	var anchor := Vector3(snappedf(at.x, cell), 0.0, snappedf(at.z, cell))
	if anchor.is_equal_approx(_centre):
		return
	_centre = anchor
	global_position = anchor
	# Which buildings the ring can currently see. Done on the ring's own move
	# rather than every frame: the list can only change when the ring has
	# travelled, and a player laying a floor panel is standing still inside the
	# cell they are building on, so the next step picks it up.
	_apply_built(anchor)
