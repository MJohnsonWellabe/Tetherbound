extends Node3D

## OW5C — the ring becomes a corridor. Same job as the file this replaces
## (`scripts/world/world_perimeter.gd`): spec §1E's "believable physical
## perimeter ... invisible collision only supporting a visible boundary,
## never being the boundary", plus the below-world kill-volume failsafe.
## What changes is the SHAPE, per `docs/decisions/D51` and
## `docs/MEADOWS_MACRO_LAYOUT.md` §6 — read both before touching this file.
##
## D50 grew the Meadows from a 512m square to an 8192 x 2048m corridor,
## `x` in [-1024, 1024], `z` in [-512, 7680]. A 235m-radius ring cannot
## enclose that; D51's own "why the ring cannot be adapted" section is blunt
## about why this could not be done by feeding the old generator different
## points — `RADIUS` is a scalar, the ring is walked as one closed loop of
## angles, and the style cycle, the collision boxes and the merged meshes
## all derive from that same angular walk. There is no polyline input to
## hand a corridor to. This is a rewrite of the SHAPE, not of the idea.
##
## THE SHAPE: two long edges, each an open, ground-sampled polyline running
## the corridor's full 8192m length —
##   west edge   x = -1024, z: -512 -> 7680
##   east edge   x = +1024, z: -512 -> 7680
## — plus two short end-caps, each 2048m —
##   north cap   z = -512,  x: -1024 -> 1024  (behind Grandpa's farm)
##   south cap   z = +7680, x: -1024 -> 1024  (past the stronghold)
## The four share their corner vertices exactly (see WOBBLE_TAPER below), so
## together they close into one continuous boundary around the corridor —
## still a closed line, just a rectangle instead of a circle. Total length
## ~20.5km against the ring's 1.48km, a cost D51 already accepts.
##
## WHAT SURVIVES UNCHANGED, because it is what actually made the old file
## work and neither doc asks for it to change: ONE ground-sampled polyline
## per edge/cap (not per style); a continuous earth bank and fieldstone kerb
## running that polyline's WHOLE length under every dressing, with a stone
## pier at every ~37m join, so at any distance the boundary reads as one
## built line whose dressing changes — never as scattered props; collision
## boxes derived from the SAME sampled points that draw the bank, never
## preceding the visible line (spec §1E, and D51 repeats it by name).
##
## WHAT CHANGES BEYOND THE SHAPE: the style is no longer a per-segment CYCLE
## (stone wall / fence / hedge / rock, repeating every 4 of 40 segments). It
## is a per-band SEQUENCE, looked up from which of the spine's five z-bands
## (`MEADOWS_MACRO_LAYOUT.md` §3) a given point falls in, crossed with which
## edge (west/east) it is on — the table in D51 / §6, reproduced in
## `_style_for()` below. The two short ends get their own fixed styles
## (`_segment_style()`): north is fieldstone-and-hedge, "the gentlest
## boundary on the map"; south is the same authored Team Tether barrier the
## approach bands end in, plus the stronghold's own outer works (those outer
## works are the stronghold scene's own content, not this file's — see the
## honest remainder below).
##
## WOBBLE, reconsidered for a straight line. The old ring pulled itself
## inward by up to WOBBLE metres on two low harmonics so a perfect 235m
## circle didn't read as a compass construction. An 8192m dead-straight line
## is a WORSE version of that same tell — a ruled edge is more obviously
## artificial than a slightly imperfect circle, because there is nothing
## else in the world that long and that straight to confuse it with. So the
## wobble survives, but the mechanism changed: two fixed sine harmonics
## repeating for 8km would themselves read as a visible period (the same
## few metres of drift, over and over, is as mechanical as no drift at all).
## `_wobble_noise` is a single low-frequency FastNoiseLite instead — the same
## tool `playground_heightfield.gd` already uses for the hills/detail layers
## — sampled once per edge along its own arc length, which meanders without
## ever repeating over a run this long. It is switched OFF entirely on
## BARRIER-styled stretches (the approach bands and the south cap): an
## authored Team Tether wall should read as built and true, not as a hedge
## line that wandered. And it is tapered to exactly zero over the last
## WOBBLE_TAPER metres of every edge/cap, which is what makes the four
## pieces' corners land on the same world-space point without any explicit
## vertex-sharing between separately-generated polylines.
##
## THE HONEST REMAINDER — three things this item does not close, on purpose:
##
##   1. Band 3's west edge is "water — the broad marsh the river drains
##      into, reed-choked and unwadeable" (D51/§6). D51 flags this AS THE ONE
##      EDGE STYLE WITH NO EXISTING IMPLEMENTATION: real impassable water
##      needs either depth the player will not enter or reed density enough
##      to collide, and there is no swimming system to make the first of
##      those legible. This file does not invent one. `_dress_marsh()` below
##      dresses that stretch's bank with the SAME reed vocabulary
##      `scripts/world/water.gd` already uses at the pond/river shoreline
##      (`Grass_Wispy_Tall/Short`, the same marsh-green tint), so it at
##      least reads as wetland rather than an unexplained bare kerb — but
##      there is no water plane, no depth, and the collision doing the actual
##      blocking is the same box every other style uses, not a marsh
##      mechanic. See the TODO on `_dress_marsh()`.
##   2. Band 2 west ("quarried rock face ... run as a scarp") and Band 4
##      east ("terrain ridge climbing to the wind ridge's own shoulder") are
##      LANDFORM descriptions. This file samples the ground
##      (`world.call("ground_height_at", ...)`); it does not shape it — that
##      is `playground_heightfield.gd`'s job, driven by `terrain_playground.json`,
##      at BAKE time, which is `OW5B`'s work, not this file's. What this file
##      can and does do is dress whatever ground the bake produces: a denser,
##      taller rock-formation run for the scarp (`_dress_rock(..., true)`,
##      Style.ROCK_SCARP) and a deliberately light dressing for the ridge
##      climb (Style.RIDGE_CLIMB, no per-band props beyond the shared
##      through-line) because that band's identity is meant to come from the
##      terrain rising under the player, not from props standing on it. If
##      `OW5B`'s bake does not actually carve a scarp/ridge there, this
##      dressing alone will not read as one — that is a real dependency
##      between the two items, not a defect in either.
##   3. The seven severed spokes still need openings cut into this edge.
##      D51's own "honest remainder" raises exactly this and says `OW5C`
##      (this item) should confirm an authored polyline can simply be
##      authored WITH the openings in it, rather than assuming they are
##      free. This file's `_sample_edge()` walks a straight two-point
##      corridor bound with no spoke openings cut in yet — that confirmation
##      is NOT done here. Whoever wires the spokes in will need to either
##      break each long edge into multiple `_sample_edge()` calls around a
##      gap, or add a "skip this stretch" predicate to the sampling walk.
##      Flagged, not solved.
##
## Materials and asset families are unchanged from the ring's own choices,
## per D24 (one village family, one nature family) and this task's own
## constraint (no new asset, no generation): `T_UnevenBrick` from the
## Quaternius medieval kit for every piece of stonework (`grandpa_house.gd`,
## `building_prefabs.gd`, `buildables.json` already build from the same
## kit); `Prop_WoodenFence_*` for ranch fencing (an already-shipped
## buildable); `Bush_Common`/`Rock_Medium_*` for hedgerow and rock, exactly
## as `vegetation.gd` already uses them. Two additions this file needed that
## the ring genuinely never did, both pulled from asset families the game
## ALREADY scatters rather than invented fresh: `CommonTree_1/2/3` (the same
## three `vegetation.json`'s own `trees` layer already uses, with the same
## `Leaves_NormalTree` magenta-canopy fix that layer's own comments record)
## for the dense/impassable growth styles, and `Grass_Wispy_Tall/Short` (the
## same reed models `water.gd` already scatters at the pond and river banks)
## for the marsh placeholder above.
##
## Also unbuilt here, recorded so nobody re-discovers it by surprise:
## `OW5B`'s cost note in D51/§6 — build the edge PER REGION so it streams
## with the terrain instead of loading 20.5km of merged mesh and MultiMesh
## at once — is a residency change, not a shape change, and this file still
## builds the whole boundary in one `build()` call the way the ring did.
## `tools/capture_perimeter.gd` (the survey tool) still hard-codes `RADIUS`/
## `SEGMENTS` and orbits a circle that no longer exists; D51 already says it
## needs rewriting as a traverse. Neither is done in this file.

# ---------------------------------------------------------------------------
# The corridor's shape — D51 / MEADOWS_MACRO_LAYOUT.md §2, §3, §6
# ---------------------------------------------------------------------------

## Authored world bounds (`MEADOWS_MACRO_LAYOUT.md` §1.3(c), §2). Both x
## bounds and both z bounds sit on the 512m region lattice; that is a bake
## concern, not this file's, but it is also exactly where these four numbers
## come from and why they are not round in the "512, 2048" sense a
## corridor's own dimensions might suggest.
const WORLD_X_WEST := -1024.0
const WORLD_X_EAST := 1024.0
const WORLD_Z_NORTH := -512.0
const WORLD_Z_SOUTH := 7680.0

## OW5E. How far inward of the true boundary `_sample_edge` queries ground
## height from. `WORLD_X_EAST`/`WORLD_Z_SOUTH` are the EXCLUSIVE upper edge of
## the baked region grid (`region_location * region_size * vertex_spacing`,
## half-open per region) — a query exactly on them always returns NaN, while
## the true lower edges (`WORLD_X_WEST`/`WORLD_Z_NORTH`) are inclusive and
## sample fine. Measured directly (a probe, not a guess): the dead band is not
## a single point, it is the LAST `vertex_spacing` (2.0m) or so of the region —
## `ground_height_at` on the east edge stayed valid to x=1022.0 and went NaN at
## 1022.5, 1.5-2.0m short of `WORLD_X_EAST`, and the south edge the same shape
## a further ~1.5m short of `WORLD_Z_SOUTH`. 3.0m clears both with room to
## spare for a region boundary that lands slightly differently elsewhere on
## the corridor's edges.
const GROUND_SAMPLE_INSET := 3.0

## The unit the old `SEGMENTS` was: the spacing between style joins and
## piers. ~37m, unchanged from the ring — it is not a property of a circle,
## it is a property of how far apart a rhythm of stone piers reads as
## "posts" rather than either "one continuous wall" or "no rhythm at all".
const JOIN_SPACING := 37.0

## Visual/collision resolution within one join-to-join segment. Unchanged
## from the ring for the same two reasons the old file gave: fine enough to
## follow real ground undulation, and fine enough to size the collision box
## from (see `_segment_ground_heights`).
const SPANS_PER_SEGMENT := 18

## See the header's WOBBLE section. Same magnitude as the ring's own
## WOBBLE — this is a "reads as imperfect" amount, not a "reads as a
## different road" amount, and that job has not changed with the shape.
const WOBBLE := 3.0
const WOBBLE_FREQUENCY := 1.0 / 180.0
const WOBBLE_SEED := 90210
## How many metres of taper to zero wobble at each end of EVERY edge/cap
## polyline. Not a style choice — a CORRECTNESS one. Two polylines meeting
## at a shared corner (e.g. the west edge's z=-512 end and the north cap's
## x=-1024 end) only land on the exact same world point if both have
## decayed their own independent wobble to nothing by the time they get
## there. 30m is comfortably more than one period of `WOBBLE_FREQUENCY`.
const WOBBLE_TAPER := 30.0

## The spine's own five z-bands (`MEADOWS_MACRO_LAYOUT.md` §3's table,
## z FROM column). A point at z < BAND1_Z1 is band 1 — which, deliberately,
## also swallows the unauthored north fringe (z in [-512, -16), behind
## Grandpa's farm, before the spine's own Band 0 starts) into band 1's
## style rather than leaving it styleless. Symmetrically, z >= APPROACH_Z1
## swallows the unauthored south fringe (z in [7560, 7680], up to the south
## cap) into the approach's own Team Tether barrier style. Both fringes are
## exactly the ranges this task's own brief calls out as reasonable to
## extend from their nearest band rather than inventing a sixth style for.
const BAND1_Z1 := 1360.0
const BAND2_Z1 := 3180.0
const BAND3_Z1 := 4760.0
const BAND4_Z1 := 7000.0
const APPROACH_Z1 := 7560.0

enum EdgeId { WEST, EAST, NORTH_CAP, SOUTH_CAP }

## One entry per row of D51/§6's style table, plus GENTLE and BARRIER for
## the two end-caps. See `_style_for()` and `_segment_style()`.
enum Style {
	FIELD_WALL,    ## band 1 east — fieldstone wall, the village's own boundary continued
	HEDGE_FENCE,   ## band 1 west — hedgerow on bank, ranch fence at gaps
	ROCK_SCARP,    ## band 2 west — quarried rock face, run as a scarp
	GROWTH_RIDGE,  ## band 2 east — dense impassable growth over a terrain ridge
	MARSH,         ## band 3 west — the marsh; see the header's honest remainder
	ROCK_SCREE,    ## band 3 east — rock formation and scree
	IRONWOOD,      ## band 4 west — old-growth, impassable by density alone
	RIDGE_CLIMB,   ## band 4 east — terrain ridge; landform-carried, see header
	BARRIER,       ## approach (both edges) + south cap — authored Team Tether barrier
	GENTLE,        ## north cap — fieldstone and hedge, the gentlest boundary
}

# ---------------------------------------------------------------------------
# Through-line dimensions — unchanged from the ring. A bank is a bank and a
# kerb is a kerb regardless of whether the line it follows is a circle or a
# rectangle; nothing about the corridor shape asks these numbers to move.
# ---------------------------------------------------------------------------

const BANK_HEIGHT := 0.46
const BANK_HALF_BASE := 1.9
const BANK_HALF_TOP := 1.35
const BANK_SINK := 1.3

const KERB_HEIGHT := 0.34
const KERB_HALF_BASE := 1.3
const KERB_HALF_TOP := 1.18

const WALL_HEIGHT := 1.95
const WALL_HALF_BASE := 0.62
const WALL_HALF_TOP := 0.5
const CAP_HEIGHT := 0.26
const CAP_HALF := 0.80
const CAP_UNDER := Color(0.66, 0.68, 0.66)
const CAP_TILE := 1.2

const COURSE_HEIGHT := 0.27
const RISER_RISE := 1.1
const WALL_FLOOR := 1.35

const FENCE_HEIGHT := 1.62
const FENCE_MODEL_LENGTH := 2.065
const FENCE_MODEL_HEIGHT := 0.838
const FENCE_PANEL_TARGET := 4.1

const HEDGE_HEIGHT := 2.25
const HEDGE_SPACING := 1.5
const HEDGE_MODEL_HEIGHT := 1.58

const ROCK_SPACING := 4.2
const ROCK_SEAT := -0.45
const ROCK_MODEL_HEIGHT := 2.2
const ROCK_HEIGHT := 2.6

const PIER_HALF := 0.56
const PIER_HEIGHT := 3.3
const PIER_CAP_HEIGHT := 0.26
const PIER_CAP_HALF := 0.7

const DRESSING_SPACING := 2.4

# ---------------------------------------------------------------------------
# Assets — same families the ring used, plus the two additions the new
# styles need (see header). No new asset, no generation (D24, and this
# task's own constraint).
# ---------------------------------------------------------------------------

const ROCK_MESHES := [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]
const BUSH_MESHES := [
	preload("res://assets/environment/stylized_nature/Bush_Common.gltf"),
	preload("res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf"),
]
const FENCE_MESHES := [
	preload("res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Extension1.gltf"),
	preload("res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Extension2.gltf"),
]
const BUSH_LEAF_MATERIAL_NAME := "Leaves_TwistedTree"
const BUSH_GREEN_TEXTURE := preload("res://assets/environment/stylized_nature/Leaves_NormalTree_C.png")

## The three widest-canopy `CommonTree` forms — the same subset
## `vegetation.json`'s `trees` layer keeps (its own comment: "kept the 3
## forms with the widest canopy footprint"). `_tree_mesh()` below applies the
## identical magenta-canopy fix that layer documents at length: the pack's
## `Leaves_NormalTree` material samples nearly the whole of a multi-species
## leaf atlas per card unless pointed at `Leaves_NormalTree_C.png`, the same
## single-hue sheet the bush fix already uses.
const TREE_MESHES := [
	preload("res://assets/environment/stylized_nature/CommonTree_1.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_3.gltf"),
]
const TREE_LEAF_MATERIAL_NAME := "Leaves_NormalTree"
## One of `vegetation.json`'s own three `variant_retint` values for this
## material ("deep") rather than a new colour — a dense/impassable growth
## wall reads correctly a shade darker than the everyday copse trees use.
const TREE_TINT := Color("#325f3c")

## `water.gd`'s own reed vocabulary (`data/config/water.json`'s `reeds`
## layer): the SAME wispy-grass models the drygrass layer already owns, at
## the same marsh-green tint, so a player who has already seen reeds at the
## pond reads this stretch as the same kind of ground rather than a fourth
## unrelated plant.
const REED_MESHES := [
	preload("res://assets/environment/stylized_nature/Grass_Wispy_Tall.gltf"),
	preload("res://assets/environment/stylized_nature/Grass_Wispy_Short.gltf"),
]
const REED_TINT := Color("#7a9460")

const ROCK_MATERIAL_NAME := "Rocks"
const ROCK_TINT := Color("#c5ac9e")

const FENCE_MATERIAL_NAME := "MI_WoodTrim"
const FENCE_TINT := Color("#a2988f")

const STONE_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
const STONE_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
const STONE_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")
const STONE_TILE := 3.2

const EARTH_ALBEDO := preload("res://assets/environment/terrain/Grass008_Color.jpg")
const EARTH_NORMAL := preload("res://assets/environment/terrain/Grass008_NormalGL.jpg")
const EARTH_TILE := 3.0

const FOOT_TINT := Color(0.62, 0.68, 0.55)

## `palette.json`'s reserved danger accent, read live the same way
## `severed_spokes.gd::_palette_colour()` already does for the sealed-road
## blocker — so the boundary's own Team Tether marks and the spokes' cannot
## silently drift apart. See `_build_stonework()`'s pier-cap tinting and
## `_stone_material` is NOT retinted; only the piers carry the faction mark,
## matching `severed_spokes.gd`'s own "fieldstone wall, oxblood uprights"
## precedent exactly.
const PALETTE_CONFIG := "res://data/config/palette.json"

# ---------------------------------------------------------------------------
# Collision / failsafe dimensions
# ---------------------------------------------------------------------------

const COLLISION_MARGIN_DOWN := 6.0
const COLLISION_MARGIN_UP := 3.0
const COLLISION_OVERLAP := 3.0

## UNVERIFIED against the corridor's own terrain — carried forward from the
## ring's measured figures, which were measured against the OLD 512m bake's
## specific slopes (see the equivalent constants in `world_perimeter.gd`'s
## own history). The corridor's bands span very different ground (an 18m
## river gorge, a marsh, a wind-ridge climb) that has not been baked or
## measured yet. `OW5B` should re-probe `_add_collision`'s margins once the
## corridor bake exists, the same way it must re-probe the spoke carves
## (`MEADOWS_MACRO_LAYOUT.md` §1.2's own rule: re-measure after the origin
## is fixed, not before).
const KILL_PLANE_Y := -150.0
const KILL_PLANE_MARGIN := 120.0
const KILL_PLANE_THICKNESS := 40.0

var _player: CharacterBody3D = null
var _spawn: Vector3 = Vector3.ZERO
## GATE-F-LEG-S10CDE. The last position the player stood on real ground,
## tracked so the kill volume below can recover LOCALLY instead of sending a
## seven-kilometre walk back to `_spawn`. See `_on_kill_volume_entered`'s own
## comment for why this exists and what it does not fix.
var _last_safe_position: Vector3 = Vector3.ZERO
var _has_last_safe_position: bool = false
## Seconds since `_last_safe_position` was last refreshed. Only trusted below
## `_LAST_SAFE_MAX_AGE_S` -- see `_on_kill_volume_entered`'s own comment for
## the regression this stops: `tests/smoke_traversal.gd`'s `_check_kill_volume`
## deliberately teleports the player into the kill band as its own test, with
## no walking in between, and a STALE ground reading from several checks
## earlier (in that run, the far end of `_check_perimeter`'s cap-walk, 7+ km
## from the actual test) is a worse recovery than `_spawn` -- it is not where
## anything relevant just happened, only the last place that happened to be
## true. A real in-play glitch (the platform-velocity case this was built
## for) refreshes this every physics frame right up to the moment it fires,
## so the age check costs that path nothing.
var _last_safe_age_s: float = 0.0
const LAST_SAFE_MAX_AGE_S := 3.0
var _wobble_noise: FastNoiseLite = null
var _tether_tint: Color = Color(0.2, 0.133, 0.157)
var _edges: Array = []


## One ground-sampled, style-tagged open polyline: a long edge or an end
## cap. Plays the role the single global `_ring`/`_ring_out`/`_ring_arc`
## arrays played in the ring file, just one instance per boundary piece
## instead of one array for the whole (closed) boundary.
class EdgeSample:
	extends RefCounted
	var id: int = EdgeId.WEST
	var nominal_out: Vector2 = Vector2.ZERO
	var points: PackedVector3Array = PackedVector3Array()   ## smoothed, what everything visible is built on
	var raw_y: PackedFloat32Array = PackedFloat32Array()    ## unsmoothed, what collision is sized from
	var out: PackedVector3Array = PackedVector3Array()      ## outward unit normal per point
	var arc: PackedFloat32Array = PackedFloat32Array()      ## cumulative arc length per point
	var total: float = 0.0
	var point_count: int = 0
	var segment_count: int = 0


func build(world: Node, player: CharacterBody3D, spawn_position: Vector3) -> void:
	_player = player
	_spawn = spawn_position
	_tether_tint = _palette_colour("tether_oxblood", _tether_tint)
	set_process(true)

	var boundary := Node3D.new()
	boundary.name = "Boundary"
	add_child(boundary)

	_sample_edges(world)
	for edge in _edges:
		var group := Node3D.new()
		group.name = _edge_name(edge.id)
		boundary.add_child(group)
		_build_bank(group, edge)
		_build_stonework(group, edge)
		_build_planting(world, group, edge)
		_build_collision(group, edge)

	_build_kill_volume()


func _edge_name(id: int) -> String:
	match id:
		EdgeId.WEST:
			return "West"
		EdgeId.EAST:
			return "East"
		EdgeId.NORTH_CAP:
			return "NorthCap"
		EdgeId.SOUTH_CAP:
			return "SouthCap"
	return "Edge"


# ---------------------------------------------------------------------------
# Style lookup — replaces the ring's per-segment-index cycle
# ---------------------------------------------------------------------------

## Which of the spine's five z-bands a world z falls in, per
## `MEADOWS_MACRO_LAYOUT.md` §3. See the BAND*_Z1 constants' own comment for
## how the two unauthored fringes fold into band 1 / approach.
func _band_for(z: float) -> String:
	if z < BAND1_Z1:
		return "band1"
	elif z < BAND2_Z1:
		return "band2"
	elif z < BAND3_Z1:
		return "band3"
	elif z < BAND4_Z1:
		return "band4"
	return "approach"


## D51 / MEADOWS_MACRO_LAYOUT.md §6's style table, verbatim. Only meaningful
## for WEST/EAST — the two caps have a single fixed style each, handled in
## `_segment_style()`.
func _style_for(edge_id: int, z: float) -> Style:
	var band := _band_for(z)
	if edge_id == EdgeId.WEST:
		match band:
			"band1":
				return Style.HEDGE_FENCE
			"band2":
				return Style.ROCK_SCARP
			"band3":
				return Style.MARSH
			"band4":
				return Style.IRONWOOD
			_:
				return Style.BARRIER
	match band:
		"band1":
			return Style.FIELD_WALL
		"band2":
			return Style.GROWTH_RIDGE
		"band3":
			return Style.ROCK_SCREE
		"band4":
			return Style.RIDGE_CLIMB
		_:
			return Style.BARRIER


## The style a whole JOIN_SPACING segment builds in. West/east edges look up
## the band at the segment's own MIDPOINT z (the nominal, pre-wobble z —
## looking up style from a wobbled sample would let the wobble noise flip a
## segment's style back and forth near a band boundary, which is exactly the
## kind of jitter the through-line's whole job is to not have). The two caps
## are unconditional.
func _segment_style(edge: EdgeSample, s: int) -> Style:
	match edge.id:
		EdgeId.WEST, EdgeId.EAST:
			var t := (float(s) + 0.5) / float(edge.segment_count)
			var z := lerpf(WORLD_Z_NORTH, WORLD_Z_SOUTH, t)
			return _style_for(edge.id, z)
		EdgeId.NORTH_CAP:
			return Style.GENTLE
		EdgeId.SOUTH_CAP:
			return Style.BARRIER
	return Style.BARRIER


## Same lookup, but at one sampled POINT rather than a segment — used by the
## common dressing pass, which walks arc length rather than segment index.
func _style_at_point(edge: EdgeSample, i: int) -> Style:
	match edge.id:
		EdgeId.WEST, EdgeId.EAST:
			return _style_for(edge.id, edge.points[i].z)
		EdgeId.NORTH_CAP:
			return Style.GENTLE
		EdgeId.SOUTH_CAP:
			return Style.BARRIER
	return Style.BARRIER


func _has_wall(style: Style) -> bool:
	return style == Style.FIELD_WALL or style == Style.BARRIER or style == Style.GENTLE


# ---------------------------------------------------------------------------
# Sampling — replaces `_sample_ring`. Four calls instead of one closed walk.
# ---------------------------------------------------------------------------

func _sample_edges(world: Node) -> void:
	_wobble_noise = FastNoiseLite.new()
	_wobble_noise.seed = WOBBLE_SEED
	_wobble_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_wobble_noise.frequency = WOBBLE_FREQUENCY

	_edges.clear()
	_edges.append(_sample_edge(world, EdgeId.WEST,
		Vector2(WORLD_X_WEST, WORLD_Z_NORTH), Vector2(WORLD_X_WEST, WORLD_Z_SOUTH), Vector2(-1.0, 0.0)))
	_edges.append(_sample_edge(world, EdgeId.EAST,
		Vector2(WORLD_X_EAST, WORLD_Z_NORTH), Vector2(WORLD_X_EAST, WORLD_Z_SOUTH), Vector2(1.0, 0.0)))
	_edges.append(_sample_edge(world, EdgeId.NORTH_CAP,
		Vector2(WORLD_X_WEST, WORLD_Z_NORTH), Vector2(WORLD_X_EAST, WORLD_Z_NORTH), Vector2(0.0, -1.0)))
	_edges.append(_sample_edge(world, EdgeId.SOUTH_CAP,
		Vector2(WORLD_X_WEST, WORLD_Z_SOUTH), Vector2(WORLD_X_EAST, WORLD_Z_SOUTH), Vector2(0.0, 1.0)))


## `from2`/`to2` are the polyline's nominal (un-wobbled) endpoints in the XZ
## plane; `nominal_out` is the fixed direction "away from the playable
## corridor" for this whole piece (e.g. -X for the west edge). Ground-sampled
## at ~2m spacing (`SPANS_PER_SEGMENT` per `JOIN_SPACING`-metre segment),
## smoothed exactly the way the ring was (two passes of a [0.25,0.5,0.25]
## blur, floored against the raw sample so smoothing only ever raises the
## line, never drops it below real ground on a crest) — just without the
## wraparound a closed ring needed and an open edge must not have.
func _sample_edge(world: Node, id: int, from2: Vector2, to2: Vector2, nominal_out: Vector2) -> EdgeSample:
	var e := EdgeSample.new()
	e.id = id
	e.nominal_out = nominal_out

	var length := (to2 - from2).length()
	e.segment_count = maxi(1, int(round(length / JOIN_SPACING)))
	e.point_count = e.segment_count * SPANS_PER_SEGMENT + 1

	e.points.resize(e.point_count)
	e.raw_y.resize(e.point_count)
	e.out.resize(e.point_count)
	e.arc.resize(e.point_count)

	var last_valid := 0.0
	for i in e.point_count:
		var t := float(i) / float(e.point_count - 1)
		var base := from2.lerp(to2, t)
		var wobble := _wobble_at(id, base, t, length)
		var xz := base - nominal_out * wobble
		# OW5E: the HEIGHT QUERY is inset `GROUND_SAMPLE_INSET` further inward
		# than `xz` itself — `xz` (the wall's own visible/collidable position)
		# stays exactly on the true boundary, but `world_bounds`'s max_x/max_z
		# are the EXCLUSIVE edge of the last baked region ([region_min,
		# region_min+pitch)), so a query exactly AT `WORLD_X_EAST`/
		# `WORLD_Z_SOUTH` always misses. That is invisible on styles with
		# nonzero wobble (already pulled a few metres inward) but total on the
		# BARRIER stretches, which fix their wobble at zero by design (see
		# `_wobble_at`'s own header): every one of the south cap's 55 collision
		# segments sampled `ground_height_at(x, 7680.0)`, got NaN every time,
		# and fell through `last_valid`'s fallback to the SAME flat height for
		# the entire 2048m edge — the real 12m+ of relief the corridor's south
		# end actually has (verified: tools probe, height_at(500,7670)=8.6m)
		# sat metres above where the wall's own collision box reached, so a
		# player walking along the rising ground at the edge simply stepped
		# over it into the unbaked void beyond. Insetting the QUERY ONLY (not
		# the wall's own drawn position) fixes this the same way for every
		# style, wobble or none.
		var sample_xz := xz - nominal_out * GROUND_SAMPLE_INSET
		var ground: float = float(world.call("ground_height_at", sample_xz.x, sample_xz.y))
		if is_nan(ground):
			# Genuinely unbaked ground (past the corridor's own bounds
			# entirely, e.g. a spoke's or the river's authored overrun past
			# the world edge). Carrying the previous valid height forward
			# keeps the line continuous instead of dropping a fake 0.0 spike
			# into it.
			ground = last_valid
		else:
			last_valid = ground
		e.points[i] = Vector3(xz.x, ground, xz.y)
		e.raw_y[i] = ground

	for _pass_index in 2:
		var smoothed := PackedFloat32Array()
		smoothed.resize(e.point_count)
		for i in e.point_count:
			var prev_y: float = e.points[maxi(i - 1, 0)].y
			var next_y: float = e.points[mini(i + 1, e.point_count - 1)].y
			smoothed[i] = maxf(prev_y * 0.25 + e.points[i].y * 0.5 + next_y * 0.25, e.raw_y[i])
		for i in e.point_count:
			var p: Vector3 = e.points[i]
			e.points[i] = Vector3(p.x, smoothed[i], p.z)

	var arc := 0.0
	for i in e.point_count:
		e.arc[i] = arc
		if i + 1 < e.point_count:
			var a: Vector3 = e.points[i]
			var b: Vector3 = e.points[i + 1]
			arc += Vector2(b.x - a.x, b.z - a.z).length()
	e.total = arc

	# The outward normal, per point, from the local tangent — the general
	# version of what the ring got for free from `position.normalized()`
	# (which only works because a circle's outward normal IS its own
	# position vector). `nominal_out` breaks the sign ambiguity a bare
	# perpendicular has.
	for i in e.point_count:
		var prev: Vector3 = e.points[maxi(i - 1, 0)]
		var next: Vector3 = e.points[mini(i + 1, e.point_count - 1)]
		var tangent := Vector2(next.x - prev.x, next.z - prev.z)
		if tangent.length_squared() < 0.000001:
			tangent = to2 - from2
		tangent = tangent.normalized()
		var perp := Vector2(tangent.y, -tangent.x)
		if perp.dot(nominal_out) < 0.0:
			perp = -perp
		e.out[i] = Vector3(perp.x, 0.0, perp.y)

	return e


## Inward pull-in in metres, never outward — same rule the ring's own
## `_radius_at` kept, for the same reason: nothing here may cross this
## piece's own nominal boundary line. Zero on BARRIER-styled stretches
## (see header) and smoothstep-tapered to zero over the last WOBBLE_TAPER
## metres of every piece so the four pieces' corners coincide exactly.
func _wobble_at(id: int, base: Vector2, t: float, length: float) -> float:
	var style_scale := _wobble_style_scale(id, base)
	if style_scale <= 0.0:
		return 0.0
	var d := minf(t * length, (1.0 - t) * length)
	var taper := clampf(d / WOBBLE_TAPER, 0.0, 1.0)
	if taper <= 0.0:
		return 0.0
	var coord := t * length + float(id) * 200000.0  # offset per piece so they don't share one noise run
	var n := _wobble_noise.get_noise_1d(coord)
	return WOBBLE * style_scale * taper * (0.5 + 0.5 * n)


func _wobble_style_scale(id: int, base: Vector2) -> float:
	match id:
		EdgeId.WEST, EdgeId.EAST:
			return 0.0 if _style_for(id, base.y) == Style.BARRIER else 1.0
		EdgeId.NORTH_CAP:
			return 1.0   # "the gentlest boundary" can still be gently uneven
		EdgeId.SOUTH_CAP:
			return 0.0   # built, and should read as built
	return 1.0


# ---------------------------------------------------------------------------
# Coursed wall top — unchanged mechanism from the ring, parameterised per
# edge instead of assuming one global `_ring`. See the ring file's own
# comments on `_course_line`/`_tread_spread` for why the top is coursed
# rather than following the ground: the base rides the terrain because it
# has to meet the bank; the top holds level in treads because a wavy
# capstone reads as a mesh-height artifact, not weather.
# ---------------------------------------------------------------------------

func _course_line(edge: EdgeSample, i0: int, count: int) -> PackedFloat32Array:
	var kerb := BANK_HEIGHT + KERB_HEIGHT
	var treads := 1
	while treads < count and _tread_spread(edge, i0, count, treads) > RISER_RISE:
		treads += 1

	var out := PackedFloat32Array()
	out.resize(count + 1)
	for t in treads:
		var k0 := int(floor(float(t) * float(count + 1) / float(treads)))
		var k1 := int(floor(float(t + 1) * float(count + 1) / float(treads)))
		var mean := 0.0
		var highest := -INF
		for k in range(k0, k1):
			var y: float = edge.points[i0 + k].y
			mean += y
			highest = maxf(highest, y)
		mean /= float(k1 - k0)
		var level := maxf(mean + kerb + WALL_HEIGHT, highest + kerb + WALL_FLOOR)
		level = round(level / COURSE_HEIGHT) * COURSE_HEIGHT
		for k in range(k0, k1):
			out[k] = level
	return out


func _tread_spread(edge: EdgeSample, i0: int, count: int, treads: int) -> float:
	var worst := 0.0
	for t in treads:
		var k0 := int(floor(float(t) * float(count + 1) / float(treads)))
		var k1 := int(floor(float(t + 1) * float(count + 1) / float(treads)))
		var lo := INF
		var hi := -INF
		for k in range(k0, k1):
			var y: float = edge.points[i0 + k].y
			lo = minf(lo, y)
			hi = maxf(hi, y)
		worst = maxf(worst, hi - lo)
	return worst


## Fit a whole number of texture repeats to this piece's own total length.
## The ring's `_closed_tile` did this to hide a seam where a closed loop met
## itself; an open edge has no such seam, but the same trick still avoids one
## partial repeat sitting against the pier at the piece's own far end, so it
## is kept under a name that no longer claims to be "closing" anything.
func _edge_tile(edge: EdgeSample, nominal: float) -> float:
	var repeats := maxf(round(edge.total / nominal), 1.0)
	return edge.total / repeats


# ---------------------------------------------------------------------------
# The continuous bank
# ---------------------------------------------------------------------------

func _build_bank(parent: Node3D, edge: EdgeSample) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var low := PackedFloat32Array()
	var high := PackedFloat32Array()
	low.resize(edge.point_count)
	high.resize(edge.point_count)
	for k in edge.point_count:
		low[k] = -BANK_SINK
		high[k] = BANK_HEIGHT
	_strip(st, edge, 0, edge.point_count - 1, low, high, BANK_HALF_BASE, BANK_HALF_TOP,
		_edge_tile(edge, EARTH_TILE), Color(1.0, 1.0, 1.0))

	st.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.name = "Bank"
	mesh.mesh = st.commit()
	mesh.material_override = _earth_material()
	parent.add_child(mesh)


# ---------------------------------------------------------------------------
# Every piece of stone in one mesh, per edge/cap
# ---------------------------------------------------------------------------

func _build_stonework(parent: Node3D, edge: EdgeSample) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# The kerb: unbroken, the whole piece, under every style. This is the
	# half of the through-line D51 names by name as the property that must
	# survive the rewrite.
	var kerb_low := PackedFloat32Array()
	var kerb_high := PackedFloat32Array()
	kerb_low.resize(edge.point_count)
	kerb_high.resize(edge.point_count)
	for k in edge.point_count:
		kerb_low[k] = BANK_HEIGHT - 0.5
		kerb_high[k] = BANK_HEIGHT + KERB_HEIGHT
	_strip(st, edge, 0, edge.point_count - 1, kerb_low, kerb_high, KERB_HALF_BASE, KERB_HALF_TOP,
		_edge_tile(edge, STONE_TILE), Color(0.78, 0.78, 0.72), FOOT_TINT)

	# Masonry wall runs — only where `_has_wall()` says this segment's style
	# carries one (FIELD_WALL, GENTLE, BARRIER). Every other style dresses
	# the bare kerb with its own props in `_build_planting` instead.
	var rng := RandomNumberGenerator.new()
	var top := BANK_HEIGHT + KERB_HEIGHT
	for s in edge.segment_count:
		var style := _segment_style(edge, s)
		if not _has_wall(style):
			continue
		var i0 := s * SPANS_PER_SEGMENT
		var course := _course_line(edge, i0, SPANS_PER_SEGMENT)
		var low := PackedFloat32Array()
		var high := PackedFloat32Array()
		var cap_low := PackedFloat32Array()
		var cap_high := PackedFloat32Array()
		var colours: Array[Color] = []
		var cap_colours: Array[Color] = []
		low.resize(SPANS_PER_SEGMENT + 1)
		high.resize(SPANS_PER_SEGMENT + 1)
		cap_low.resize(SPANS_PER_SEGMENT + 1)
		cap_high.resize(SPANS_PER_SEGMENT + 1)
		for k in SPANS_PER_SEGMENT + 1:
			rng.seed = hash(edge.id * 1000000 + i0 + k)
			var h := course[k] - edge.points[i0 + k].y
			low[k] = top - 0.12
			high[k] = h
			cap_low[k] = h
			cap_high[k] = h + CAP_HEIGHT
			colours.append(Color(0.93, 0.92, 0.88).darkened(rng.randf_range(0.0, 0.30)))
			var cap_nominal := Color(1.0, 0.99, 0.95).darkened(rng.randf_range(0.0, 0.26))
			# Team Tether's own build carries its reserved accent on the
			# coping, not the wall face — the same split
			# `severed_spokes.gd::_build_sealed_road` uses ("a fieldstone
			# wall ... with uprights standing proud of it in tether_oxblood")
			# so the two read as the same faction's work without duplicating
			# a whole new material.
			cap_colours.append(_tether_tint.lerp(cap_nominal, 0.4) if style == Style.BARRIER else cap_nominal)
		_strip_shaded(st, edge, i0, SPANS_PER_SEGMENT, low, high, WALL_HALF_BASE, WALL_HALF_TOP, STONE_TILE, colours, FOOT_TINT)
		_strip_shaded(st, edge, i0, SPANS_PER_SEGMENT, cap_low, cap_high, CAP_HALF, CAP_HALF, CAP_TILE, cap_colours, CAP_UNDER)

	# A pier at every join, INCLUDING the piece's own far end. The ring's
	# loop only visited SEGMENTS joins because join `SEGMENTS` and join `0`
	# were the same closed-loop vertex; an open edge has no such vertex, so
	# its own last join needs an explicit pier or the piece's far corner
	# stands bare. (Each of the four corners therefore gets a pier built
	# TWICE — once by each of the two pieces that meet there. Harmless and
	# cheap; not worth the bookkeeping to dedupe for a whole-world, one-shot
	# build like this one.)
	for s in edge.segment_count + 1:
		var i := mini(s * SPANS_PER_SEGMENT, edge.point_count - 1)
		var p: Vector3 = edge.points[i]
		var yaw := _yaw_at(edge, i)
		var join_style := _segment_style(edge, mini(s, edge.segment_count - 1))
		var cap_colour := _tether_tint.lerp(Color(1.0, 0.99, 0.95), 0.25) if join_style == Style.BARRIER else Color(1.0, 0.99, 0.95)
		_box(st, Vector3(p.x, p.y - 0.6, p.z), Vector3(PIER_HALF * 2.0, PIER_HEIGHT + 0.6, PIER_HALF * 2.0), yaw, Color(0.92, 0.91, 0.88))
		_box(st, Vector3(p.x, p.y + PIER_HEIGHT, p.z), Vector3(PIER_CAP_HALF * 2.0, PIER_CAP_HEIGHT, PIER_CAP_HALF * 2.0), yaw, cap_colour)

	st.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.name = "Stonework"
	mesh.mesh = st.commit()
	mesh.material_override = _stone_material()
	parent.add_child(mesh)


# ---------------------------------------------------------------------------
# Dressing — one function per style, dispatched from `_build_planting`.
# The techniques (thickets that wander and clump, fence runs that lose a
# panel, boulder knots with a dominant piece) are kept from the ring's own
# `_build_planting` because they are what stops the dressing reading as
# generated, not because they are shape-specific.
# ---------------------------------------------------------------------------

func _build_planting(world: Node, parent: Node3D, edge: EdgeSample) -> void:
	var bush_transforms: Array[Array] = [[], []]
	var rock_transforms: Array[Array] = [[], [], []]
	var fence_transforms: Array[Array] = [[], []]
	var tree_transforms: Array[Array] = [[], [], []]
	var reed_transforms: Array[Array] = [[], []]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242 + edge.id * 977
	var kerb_top := BANK_HEIGHT + KERB_HEIGHT

	for s in edge.segment_count:
		var style := _segment_style(edge, s)
		match style:
			Style.FIELD_WALL:
				_dress_wall_growth(edge, s, rng, bush_transforms)
			Style.GENTLE:
				# Fieldstone AND hedge, unconditionally — "the gentlest
				# boundary on the map" gets no fence gaps, just a soft foot.
				_dress_wall_growth(edge, s, rng, bush_transforms)
				_dress_hedgerow(edge, s, rng, kerb_top, bush_transforms)
			Style.HEDGE_FENCE:
				# "Hedgerow on bank, ranch fence at gaps" — hedge is the
				# default cover; a minority of segments are the gap a fence
				# panel run fills instead, not the other way round.
				if rng.randf() < 0.28:
					_dress_fence(edge, s, rng, kerb_top, fence_transforms, bush_transforms)
				else:
					_dress_hedgerow(edge, s, rng, kerb_top, bush_transforms)
			Style.ROCK_SCARP:
				_dress_rock(edge, s, rng, rock_transforms, true)
			Style.ROCK_SCREE:
				_dress_rock(edge, s, rng, rock_transforms, false)
			Style.GROWTH_RIDGE:
				_dress_forest_wall(edge, s, rng, false, tree_transforms, bush_transforms)
			Style.IRONWOOD:
				_dress_forest_wall(edge, s, rng, true, tree_transforms, bush_transforms)
			Style.MARSH:
				_dress_marsh(edge, s, rng, reed_transforms)
			Style.RIDGE_CLIMB:
				pass  # landform-carried; see header's honest remainder #2
			Style.BARRIER:
				pass  # authored and stark on purpose; no naturalised dressing

	_dress_common(world, edge, rng, bush_transforms, rock_transforms)

	for m in BUSH_MESHES.size():
		_batch(parent, "Hedge%d" % m, _bush_mesh(BUSH_MESHES[m]), bush_transforms[m])
	for m in ROCK_MESHES.size():
		_batch(parent, "Boulder%d" % m, _tinted_mesh(ROCK_MESHES[m], ROCK_MATERIAL_NAME, ROCK_TINT), rock_transforms[m])
	for m in FENCE_MESHES.size():
		_batch(parent, "Fence%d" % m, _tinted_mesh(FENCE_MESHES[m], FENCE_MATERIAL_NAME, FENCE_TINT), fence_transforms[m])
	for m in TREE_MESHES.size():
		_batch(parent, "Tree%d" % m, _tree_mesh(TREE_MESHES[m]), tree_transforms[m])
	for m in REED_MESHES.size():
		_batch(parent, "Reed%d" % m, _reed_mesh(REED_MESHES[m]), reed_transforms[m])


## FIELD_WALL/GENTLE only: low growth hard against the wall's own inner
## face, so a dry-stone wall does not meet mown grass in one hard, obviously
## generated line for the whole segment.
func _dress_wall_growth(edge: EdgeSample, s: int, rng: RandomNumberGenerator, bush_transforms: Array[Array]) -> void:
	var length := _segment_length(edge, s)
	var tufts: int = maxi(int(round(length / 3.0)), 6)
	for j in tufts:
		var f := (float(j) + 0.5 + rng.randf_range(-0.45, 0.45)) / float(tufts)
		var at := _point_along(edge, s, f)
		var out := _out_along(edge, s, f)
		var origin := at - out * rng.randf_range(0.65, 1.5) + Vector3(0.0, -0.1, 0.0)
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.4, 0.95))
		(bush_transforms[rng.randi() % 2] as Array).append(Transform3D(basis, origin))


## HEDGE_FENCE's "ranch fence" half. Panel count fits the segment exactly
## (no gap, no doubled post); one run in five loses a panel to the ground
## (fallen), one run in two loses a panel to a bush clump grown through it
## (breach) — both kept from the ring's own fence logic, which existed
## specifically to answer a blind reviewer's "generated, not designed"
## verdict on a perfectly even fence line.
func _dress_fence(edge: EdgeSample, s: int, rng: RandomNumberGenerator, kerb_top: float,
		fence_transforms: Array[Array], bush_transforms: Array[Array]) -> void:
	var length := _segment_length(edge, s)
	var panels: int = maxi(int(round(length / FENCE_PANEL_TARGET)), 4)
	var panel_length := length / float(panels)
	var scale_y := FENCE_HEIGHT / FENCE_MODEL_HEIGHT
	var scale_x := panel_length / FENCE_MODEL_LENGTH * 1.16
	var tangent := _tangent_along(edge, s)
	var side := tangent.cross(Vector3.UP)
	var fallen: int = rng.randi_range(1, panels - 2) if rng.randf() < 0.4 else -1
	var breach: int = rng.randi_range(1, panels - 2) if rng.randf() < 0.5 else -1
	for j in panels:
		var f := (float(j) + 0.5 + rng.randf_range(-0.05, 0.05)) / float(panels)
		var at := _point_along(edge, s, f)
		if j == fallen:
			var down := Basis(tangent, Vector3.UP, side)
			down = down.rotated(tangent, rng.randf_range(1.15, 1.45))
			down = down.rotated(Vector3.UP, rng.randf_range(-0.35, 0.35))
			var down_y := scale_y * rng.randf_range(0.92, 1.02)
			(fence_transforms[j % 2] as Array).append(Transform3D(
				Basis(down.x * scale_x, down.y * down_y, down.z * down_y),
				at + _out_along(edge, s, f) * rng.randf_range(-0.9, -0.3) + Vector3(0.0, kerb_top - 0.95, 0.0)))
			continue
		if j == breach:
			var bush_out := _out_along(edge, s, f)
			for _b in rng.randi_range(3, 4):
				var bush_at := at + bush_out * rng.randf_range(-0.7, 0.7) + tangent * rng.randf_range(-0.9, 0.9)
				var bush_basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
					Vector3.ONE * (HEDGE_HEIGHT / HEDGE_MODEL_HEIGHT) * rng.randf_range(0.55, 0.9))
				(bush_transforms[rng.randi() % 2] as Array).append(
					Transform3D(bush_basis, bush_at + Vector3(0.0, kerb_top - 0.5, 0.0)))
			continue
		var rot := Basis(tangent, Vector3.UP, side)
		rot = rot.rotated(tangent, rng.randf_range(-0.11, 0.11))
		rot = rot.rotated(Vector3.UP, rng.randf_range(-0.09, 0.09))
		var sy := scale_y * rng.randf_range(0.88, 1.08)
		var basis := Basis(rot.x * scale_x, rot.y * sy, rot.z * sy)
		var origin := at + Vector3(0.0, kerb_top - 0.16 + rng.randf_range(-0.14, 0.05), 0.0)
		(fence_transforms[j % 2] as Array).append(Transform3D(basis, origin))


## HEDGE_FENCE's default cover and GENTLE's own dressing: bushes packed into
## thickets (3-7) that wander and thin along the segment rather than a
## divided, evenly-stepped row — the ring's own "knots, not a walk" fix.
func _dress_hedgerow(edge: EdgeSample, s: int, rng: RandomNumberGenerator, kerb_top: float, bush_transforms: Array[Array]) -> void:
	var length := _segment_length(edge, s)
	var wander_phase := rng.randf_range(0.0, TAU)
	var travelled := HEDGE_SPACING * rng.randf_range(0.2, 0.7)
	while travelled < length:
		var thicket: int = rng.randi_range(3, 7)
		var thicket_scale := rng.randf_range(1.15, 1.55) if rng.randf() < 0.2 else rng.randf_range(0.62, 1.05)
		var flowering := rng.randf() < 0.42
		var thicket_wander := 0.7 * sin(travelled / length * 6.1 + wander_phase)
		for _n in thicket:
			var f := (travelled + HEDGE_SPACING * rng.randf_range(-0.45, 0.45)) / length
			travelled += HEDGE_SPACING * rng.randf_range(0.45, 0.8)
			if f < 0.046 or f > 0.954:
				continue  # clear of the piers at each end
			var at := _point_along(edge, s, f)
			var out := _out_along(edge, s, f)
			var across := thicket_wander + rng.randf_range(-0.55, 0.55)
			var scale := HEDGE_HEIGHT / HEDGE_MODEL_HEIGHT * thicket_scale * rng.randf_range(0.78, 1.22)
			var origin := at + out * across + Vector3(0.0, kerb_top - 0.25, 0.0)
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
			basis = basis.rotated(Vector3.RIGHT, rng.randf_range(-0.12, 0.12))
			basis = basis.rotated(Vector3.FORWARD, rng.randf_range(-0.12, 0.12))
			(bush_transforms[1 if flowering else 0] as Array).append(
				Transform3D(basis.scaled(Vector3.ONE * scale), origin))
		travelled += HEDGE_SPACING * (rng.randf_range(2.6, 4.4) if rng.randf() < 0.25 else rng.randf_range(0.7, 1.6))


## ROCK_SCARP (band 2 west) and ROCK_SCREE (band 3 east). Both are boulder
## knots straddling the kerb, kept from the ring's own rock-formation logic;
## `dense` is the one thing the two styles change. A "quarried rock face run
## as a scarp" needs to read as closer to continuous than a loose scree
## field does, so `dense` shortens the gap between knots, adds a knot, and
## raises the nominal scale — it does NOT change technique, because the
## technique (a dominant piece plus a size step down from it, not a uniform
## pile) is what kept these from reading as generator output in the first
## place.
func _dress_rock(edge: EdgeSample, s: int, rng: RandomNumberGenerator, rock_transforms: Array[Array], dense: bool) -> void:
	var length := _segment_length(edge, s)
	var spacing := ROCK_SPACING * (2.6 if dense else 4.0)
	var knots: int = clampi(int(round(length / spacing)), 2 if not dense else 3, 4 if dense else 3)
	var height_mul := 1.2 if dense else 1.0
	for knot in knots:
		var centre := (float(knot) + rng.randf_range(0.25, 0.75)) / float(knots)
		var in_knot: int = rng.randi_range(5, 9) if dense else rng.randi_range(4, 7)
		for n in in_knot:
			var f := centre + rng.randf_range(-0.09, 0.09)
			var at := _point_along(edge, s, f)
			var out := _out_along(edge, s, f)
			var across := rng.randf_range(-1.3, 1.3)
			var scale := ROCK_HEIGHT * height_mul / ROCK_MODEL_HEIGHT * (
				rng.randf_range(1.0, 1.32) if n == 0 else rng.randf_range(0.22, 0.72))
			var origin := at + out * across + Vector3(0.0, ROCK_SEAT, 0.0)
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
			if scale < ROCK_HEIGHT * height_mul / ROCK_MODEL_HEIGHT * 0.6:
				basis = basis.rotated(Vector3.RIGHT, rng.randf_range(-0.17, 0.17))
				basis = basis.rotated(Vector3.FORWARD, rng.randf_range(-0.17, 0.17))
			(rock_transforms[rng.randi() % 3] as Array).append(
				Transform3D(basis.scaled(Vector3.ONE * scale), origin))


## GROWTH_RIDGE (band 2 east) and IRONWOOD (band 4 west): "dense impassable
## growth" / "old-growth, impassable by density alone". New relative to the
## ring — reuses `CommonTree_*` (already the game's forest family, see
## header) at tight, gapless spacing, with a bush understory closing the gap
## between trunks at eye height. Deliberately NO clearings, unlike
## `_dress_hedgerow` — a hedge earns its gaps because it is a maintained
## field boundary; a wall of impassable growth should never show daylight
## through it, or it reads as a place to squeeze past rather than a
## boundary. `old_growth` (IRONWOOD) runs two rows instead of one and skews
## both spacing and scale larger.
func _dress_forest_wall(edge: EdgeSample, s: int, rng: RandomNumberGenerator, old_growth: bool,
		tree_transforms: Array[Array], bush_transforms: Array[Array]) -> void:
	var length := _segment_length(edge, s)
	var kerb_top := BANK_HEIGHT + KERB_HEIGHT
	var spacing := 3.4 if old_growth else 4.1
	var rows := 2 if old_growth else 1
	var count: int = maxi(int(round(length / spacing)), 4)
	for row in rows:
		for j in count:
			var f := (float(j) + 0.5 + rng.randf_range(-0.4, 0.4)) / float(count)
			var at := _point_along(edge, s, f)
			var out := _out_along(edge, s, f)
			var row_out := 1.6 + float(row) * 2.8 + rng.randf_range(-0.5, 0.5)
			var origin := at + out * row_out + Vector3(0.0, kerb_top - 0.3, 0.0)
			var scale_base := 1.15 if old_growth else 0.85
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
				Vector3.ONE * scale_base * rng.randf_range(0.85, 1.25))
			(tree_transforms[rng.randi() % TREE_MESHES.size()] as Array).append(Transform3D(basis, origin))
			# Understory bush at the same station, offset only slightly
			# inward — this is what closes the sightline BETWEEN trunks;
			# without it the "wall" is a colonnade a player can see through
			# and might expect to walk between.
			var bush_out := row_out * 0.55
			var bush_origin := at + out * bush_out + Vector3(0.0, kerb_top - 0.25, 0.0)
			var bush_basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
				Vector3.ONE * (HEDGE_HEIGHT / HEDGE_MODEL_HEIGHT) * rng.randf_range(0.55, 0.95))
			(bush_transforms[rng.randi() % 2] as Array).append(Transform3D(bush_basis, bush_origin))


## MARSH (band 3 west). See the header's honest remainder #1 before changing
## this function — it is BANK DRESSING, not a water feature.
##
## TODO(D51 honest remainder, unresolved by design): D51 names Band 3's west
## edge as "the one edge style with no existing implementation" — real
## impassable water needs either depth the player will not enter or reed
## density enough to collide, and there is no swimming system to make the
## first of those legible. This function does not invent either. It places
## the same reed clumps `water.gd` already scatters at the pond/river shore
## (same models, same tint) along the bank, so the stretch reads as wetland
## rather than an unexplained bare kerb — but there is no water plane, no
## depth, and the actual blocking collision is the same box every other
## style gets from `_build_collision`, not a marsh mechanic. Do not remove
## this TODO until a real water/depth/reed-collision answer exists.
func _dress_marsh(edge: EdgeSample, s: int, rng: RandomNumberGenerator, reed_transforms: Array[Array]) -> void:
	var length := _segment_length(edge, s)
	var kerb_top := BANK_HEIGHT + KERB_HEIGHT
	var tangent := _tangent_along(edge, s)
	var clumps: int = maxi(int(round(length / 3.4)), 5)
	for j in clumps:
		var f := (float(j) + 0.5 + rng.randf_range(-0.4, 0.4)) / float(clumps)
		var at := _point_along(edge, s, f)
		var out := _out_along(edge, s, f)
		for _n in rng.randi_range(3, 6):
			var origin := at + out * rng.randf_range(-0.6, 1.6) + tangent * rng.randf_range(-1.0, 1.0) \
				+ Vector3(0.0, kerb_top - 0.3, 0.0)
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.7, 1.3))
			(reed_transforms[rng.randi() % REED_MESHES.size()] as Array).append(Transform3D(basis, origin))


## Low growth and loose stone along the whole piece's outer foot, regardless
## of style — the base note that reads several different dressings as one
## feature. Skipped on BARRIER stretches: an authored, maintained Team
## Tether wall should not have casual litter growing at its foot the way a
## field boundary does.
func _dress_common(world: Node, edge: EdgeSample, rng: RandomNumberGenerator,
		bush_transforms: Array[Array], rock_transforms: Array[Array]) -> void:
	var dressing_count := int(edge.total / DRESSING_SPACING)
	for j in dressing_count:
		var f := (float(j) + 0.5 + rng.randf_range(-0.45, 0.45)) / float(dressing_count)
		var i := clampi(int(f * float(edge.point_count)), 0, edge.point_count - 1)
		if _style_at_point(edge, i) == Style.BARRIER:
			continue
		var p: Vector3 = edge.points[i]
		var out: Vector3 = edge.out[i]
		var side := -1.0 if rng.randf() < 0.7 else 1.0
		var is_stone := rng.randf() >= 0.82
		var across := side * (rng.randf_range(BANK_HALF_BASE * 1.05, BANK_HALF_BASE * 1.35) if is_stone
			else rng.randf_range(BANK_HALF_BASE * 0.5, BANK_HALF_BASE * 1.4))
		var here := p + out * across
		var ground: float = float(world.call("ground_height_at", here.x, here.z))
		if is_nan(ground):
			ground = p.y
		var origin := Vector3(here.x, ground - 0.18, here.z)
		if is_stone:
			(rock_transforms[rng.randi() % 3] as Array).append(
				Transform3D(_stone_basis(rng, rng.randf_range(0.14, 0.34)), origin))
		else:
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
			(bush_transforms[rng.randi() % 2] as Array).append(
				Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.35, 0.95)), origin))


func _stone_basis(rng: RandomNumberGenerator, scale: float) -> Basis:
	var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
	basis = basis.rotated(Vector3.RIGHT, rng.randf_range(-0.16, 0.16))
	basis = basis.rotated(Vector3.FORWARD, rng.randf_range(-0.16, 0.16))
	return basis.scaled(Vector3.ONE * scale)


func _batch(parent: Node3D, node_name: String, mesh: Mesh, transforms: Array) -> void:
	if mesh == null or transforms.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
	var node := MultiMeshInstance3D.new()
	node.name = node_name
	node.multimesh = multi
	parent.add_child(node)


# ---------------------------------------------------------------------------
# Collision — same derivation rule as the ring (spec §1E: never precede the
# visible line), adapted to open per-edge segments instead of a closed
# per-ring one.
# ---------------------------------------------------------------------------

func _build_collision(parent: Node3D, edge: EdgeSample) -> void:
	for s in edge.segment_count:
		var from := _corner(edge, s)
		var to := _corner(edge, s + 1)
		var heights := _segment_ground_heights(edge, s)
		var basis := _segment_basis(from, to)
		var style := _segment_style(edge, s)
		var thickness := _collision_thickness(style)
		_add_collision(parent, basis["mid"], basis["yaw"], basis["length"],
			BANK_HEIGHT + KERB_HEIGHT + WALL_HEIGHT, thickness, heights)


## Thicker where the visible dressing juts further past the kerb line
## (boulders, trunks) than a flush wall or fence face does — same reasoning
## the ring applied per style, generalised to the new style set.
func _collision_thickness(style: Style) -> float:
	match style:
		Style.ROCK_SCARP, Style.ROCK_SCREE, Style.IRONWOOD, Style.GROWTH_RIDGE:
			return 3.4
		_:
			return 2.4


func _corner(edge: EdgeSample, s: int) -> Vector3:
	var i := mini(s * SPANS_PER_SEGMENT, edge.point_count - 1)
	var p: Vector3 = edge.points[i]
	return Vector3(p.x, edge.raw_y[i], p.z)


func _segment_ground_heights(edge: EdgeSample, s: int) -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	for k in SPANS_PER_SEGMENT + 1:
		heights.append(edge.raw_y[s * SPANS_PER_SEGMENT + k])
	return heights


func _segment_basis(from: Vector3, to: Vector3) -> Dictionary:
	var delta := to - from
	var length := Vector2(delta.x, delta.z).length()
	var mid := (from + to) * 0.5
	var yaw := atan2(-delta.z, delta.x)
	return {"length": maxf(length, 0.01), "mid": mid, "yaw": yaw}


func _add_collision(parent: Node3D, mid: Vector3, yaw: float, length: float, height: float, thickness: float, heights: PackedFloat32Array) -> void:
	var bottom := mid.y - COLLISION_MARGIN_DOWN
	var top := mid.y + height + COLLISION_MARGIN_UP
	for h in heights:
		bottom = minf(bottom, h - COLLISION_MARGIN_DOWN)
		top = maxf(top, h + COLLISION_MARGIN_UP)

	var body := StaticBody3D.new()
	body.position = Vector3(mid.x, (bottom + top) * 0.5, mid.z)
	body.rotation.y = yaw
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length + COLLISION_OVERLAP, top - bottom, thickness)
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)


# ---------------------------------------------------------------------------
# Geometry helpers — same role as the ring's, indexed against one edge's own
# arrays instead of a global closed ring, and clamped at open ends instead
# of wrapped.
# ---------------------------------------------------------------------------

func _segment_length(edge: EdgeSample, s: int) -> float:
	var total := 0.0
	for k in SPANS_PER_SEGMENT:
		var a: Vector3 = edge.points[s * SPANS_PER_SEGMENT + k]
		var b: Vector3 = edge.points[s * SPANS_PER_SEGMENT + k + 1]
		total += Vector2(b.x - a.x, b.z - a.z).length()
	return total


func _point_along(edge: EdgeSample, s: int, f: float) -> Vector3:
	var x := clampf(f, 0.0, 0.9999) * float(SPANS_PER_SEGMENT)
	var k := int(x)
	var frac := x - float(k)
	var a: Vector3 = edge.points[s * SPANS_PER_SEGMENT + k]
	var b: Vector3 = edge.points[s * SPANS_PER_SEGMENT + k + 1]
	return a.lerp(b, frac)


func _out_along(edge: EdgeSample, s: int, f: float) -> Vector3:
	var i := s * SPANS_PER_SEGMENT + int(clampf(f, 0.0, 0.9999) * float(SPANS_PER_SEGMENT))
	return edge.out[i]


func _tangent_along(edge: EdgeSample, s: int) -> Vector3:
	var a: Vector3 = edge.points[s * SPANS_PER_SEGMENT]
	var b: Vector3 = edge.points[mini((s + 1) * SPANS_PER_SEGMENT, edge.point_count - 1)]
	return Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()


func _yaw_at(edge: EdgeSample, i: int) -> float:
	var a: Vector3 = edge.points[maxi(i - 1, 0)]
	var b: Vector3 = edge.points[mini(i + 1, edge.point_count - 1)]
	return atan2(-(b.z - a.z), b.x - a.x)


func _strip(st: SurfaceTool, edge: EdgeSample, i0: int, count: int, low: PackedFloat32Array, high: PackedFloat32Array,
		half_low: float, half_high: float, tile: float, colour: Color, foot: Color = Color.WHITE) -> void:
	var colours: Array[Color] = []
	for k in count + 1:
		colours.append(colour)
	_strip_shaded(st, edge, i0, count, low, high, half_low, half_high, tile, colours, foot)


## A terrain-following prism along `count` spans of `edge` starting at point
## index `i0`. Identical mechanism to the ring's own `_strip_shaded` — the
## only change is reading `edge.points`/`edge.out`/`edge.arc` instead of a
## global `_ring`/`_ring_out`/`_ring_arc`, and no `_wrap()`: an open edge
## never indexes past its own ends because every caller sizes `count` to
## fit inside `edge.point_count`.
func _strip_shaded(st: SurfaceTool, edge: EdgeSample, i0: int, count: int, low: PackedFloat32Array, high: PackedFloat32Array,
		half_low: float, half_high: float, tile: float, colours: Array[Color], foot: Color = Color.WHITE) -> void:
	var u := edge.arc[i0] / tile
	for k in count:
		var ia := i0 + k
		var ib := i0 + k + 1
		var a: Vector3 = edge.points[ia]
		var b: Vector3 = edge.points[ib]
		var na: Vector3 = edge.out[ia]
		var nb: Vector3 = edge.out[ib]
		var span := Vector2(b.x - a.x, b.z - a.z).length()
		var u2 := u + span / tile

		var a_lo_o := a + na * half_low + Vector3(0.0, low[k], 0.0)
		var a_hi_o := a + na * half_high + Vector3(0.0, high[k], 0.0)
		var a_lo_i := a - na * half_low + Vector3(0.0, low[k], 0.0)
		var a_hi_i := a - na * half_high + Vector3(0.0, high[k], 0.0)
		var b_lo_o := b + nb * half_low + Vector3(0.0, low[k + 1], 0.0)
		var b_hi_o := b + nb * half_high + Vector3(0.0, high[k + 1], 0.0)
		var b_lo_i := b - nb * half_low + Vector3(0.0, low[k + 1], 0.0)
		var b_hi_i := b - nb * half_high + Vector3(0.0, high[k + 1], 0.0)

		var ca := colours[mini(k, colours.size() - 1)]
		var cb := colours[mini(k + 1, colours.size() - 1)]
		var fa := ca * foot
		var fb := cb * foot
		var va := low[k] / tile
		var ha := high[k] / tile
		var vb := low[k + 1] / tile
		var hb := high[k + 1] / tile

		_quad(st, a_lo_o, b_lo_o, b_hi_o, a_hi_o,
			Vector2(u, va), Vector2(u2, vb), Vector2(u2, hb), Vector2(u, ha),
			[fa, fb, cb, ca], na)
		_quad(st, a_hi_i, b_hi_i, b_lo_i, a_lo_i,
			Vector2(u, ha), Vector2(u2, hb), Vector2(u2, vb), Vector2(u, va),
			[ca, cb, fb, fa], -na)
		_quad(st, a_hi_o, b_hi_o, b_hi_i, a_hi_i,
			Vector2(u, 0.0), Vector2(u2, 0.0), Vector2(u2, half_high * 2.0 / tile), Vector2(u, half_high * 2.0 / tile),
			[ca, cb, cb, ca], Vector3.UP)
		u = u2


func _box(st: SurfaceTool, base: Vector3, size: Vector3, yaw: float, colour: Color) -> void:
	var right := Vector3(cos(yaw), 0.0, -sin(yaw)) * size.x * 0.5
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw)) * size.z * 0.5
	var up := Vector3(0.0, size.y, 0.0)
	var corners: Array[Vector3] = [
		base - right - fwd, base + right - fwd, base + right + fwd, base - right + fwd,
	]
	var cols: Array[Color] = [colour, colour, colour, colour]
	for i in 4:
		var p0: Vector3 = corners[i]
		var p1: Vector3 = corners[(i + 1) % 4]
		var w := (p1 - p0).length() / STONE_TILE
		var h := size.y / STONE_TILE
		_quad(st, p0, p1, p1 + up, p0 + up,
			Vector2(0.0, 0.0), Vector2(w, 0.0), Vector2(w, h), Vector2(0.0, h),
			cols, (p0 + p1) * 0.5 - base)
	_quad(st, corners[0] + up, corners[1] + up, corners[2] + up, corners[3] + up,
		Vector2(0.0, 0.0), Vector2(size.x / STONE_TILE, 0.0),
		Vector2(size.x / STONE_TILE, size.z / STONE_TILE), Vector2(0.0, size.z / STONE_TILE),
		cols, Vector3.UP)


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, uv0: Vector2, uv1: Vector2, uv2: Vector2, uv3: Vector2, corner_colours: Array, outward: Vector3) -> void:
	var n := (p1 - p0).cross(p3 - p0)
	if n.length_squared() < 0.000001:
		return
	n = n.normalized()
	if n.dot(outward) < 0.0:
		n = -n
	var pts: Array[Vector3] = [p0, p1, p2, p0, p2, p3]
	var uvs: Array[Vector2] = [uv0, uv1, uv2, uv0, uv2, uv3]
	var cols: Array[Color] = [corner_colours[0], corner_colours[1], corner_colours[2], corner_colours[0], corner_colours[2], corner_colours[3]]
	for i in 6:
		st.set_normal(n)
		st.set_uv(uvs[i])
		st.set_color(cols[i])
		st.add_vertex(pts[i])


# ---------------------------------------------------------------------------
# Materials and meshes
# ---------------------------------------------------------------------------

func _stone_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = STONE_ALBEDO
	m.normal_enabled = true
	m.normal_texture = STONE_NORMAL
	m.normal_scale = 0.7
	m.roughness_texture = STONE_ROUGHNESS
	m.roughness = 1.0
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _earth_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = EARTH_ALBEDO
	m.normal_enabled = true
	m.normal_texture = EARTH_NORMAL
	m.normal_scale = 0.5
	m.roughness = 1.0
	m.albedo_color = Color("#a892b0")
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _mesh_of(scene: PackedScene) -> Mesh:
	var instance: Node = scene.instantiate()
	var found := _find_mesh_instances(instance)
	instance.queue_free()
	if found.is_empty():
		return null
	return found[0].mesh


func _bush_mesh(scene: PackedScene) -> Mesh:
	var instance: Node = scene.instantiate()
	var found := _find_mesh_instances(instance)
	instance.queue_free()
	if found.is_empty():
		return null
	var source: Mesh = found[0].mesh
	if source == null:
		return null
	var out: ArrayMesh = source.duplicate(false)
	for surface in out.get_surface_count():
		var material: Material = out.surface_get_material(surface)
		var standard := material as StandardMaterial3D
		if standard == null or standard.resource_name != BUSH_LEAF_MATERIAL_NAME:
			continue
		var greened: StandardMaterial3D = standard.duplicate()
		greened.albedo_texture = BUSH_GREEN_TEXTURE
		out.surface_set_material(surface, greened)
	return out


## Same mechanism as `_bush_mesh`, for `CommonTree_*`'s `Leaves_NormalTree`
## material — see the TREE_MESHES const comment for why this fix exists.
## Also applies TREE_TINT so the boundary's forest reads a shade darker than
## the everyday copse trees `vegetation.gd` scatters elsewhere.
func _tree_mesh(scene: PackedScene) -> Mesh:
	var instance: Node = scene.instantiate()
	var found := _find_mesh_instances(instance)
	instance.queue_free()
	if found.is_empty():
		return null
	var source: Mesh = found[0].mesh
	if source == null:
		return null
	var out: ArrayMesh = source.duplicate(false)
	for surface in out.get_surface_count():
		var material: Material = out.surface_get_material(surface)
		var standard := material as StandardMaterial3D
		if standard == null or standard.resource_name != TREE_LEAF_MATERIAL_NAME:
			continue
		var greened: StandardMaterial3D = standard.duplicate()
		greened.albedo_texture = BUSH_GREEN_TEXTURE
		greened.albedo_color = TREE_TINT
		out.surface_set_material(surface, greened)
	return out


## Marsh-green modulate over whatever texture the source mesh already
## carries — the same treatment `water.gd::_reed_material` applies to the
## identical models, kept local for the same reason that function's own
## comment gives: a MultiMesh batch cannot see a MeshInstance3D's per-node
## material override, only a bake into the mesh's own surface.
func _reed_mesh(scene: PackedScene) -> Mesh:
	var source: Mesh = _mesh_of(scene)
	if source == null:
		return null
	var out: ArrayMesh = source.duplicate(false)
	for surface in out.get_surface_count():
		var standard := out.surface_get_material(surface) as StandardMaterial3D
		var tinted := StandardMaterial3D.new()
		tinted.albedo_color = REED_TINT
		tinted.vertex_color_use_as_albedo = true
		if standard != null:
			if standard.albedo_texture != null:
				tinted.albedo_texture = standard.albedo_texture
			tinted.transparency = standard.transparency
			tinted.alpha_scissor_threshold = standard.alpha_scissor_threshold
			tinted.cull_mode = standard.cull_mode
		out.surface_set_material(surface, tinted)
	return out


func _tinted_mesh(scene: PackedScene, material_name: String, tint: Color) -> Mesh:
	var source: Mesh = _mesh_of(scene)
	if source == null:
		return null
	var out: ArrayMesh = source.duplicate(false)
	for surface in out.get_surface_count():
		var standard := out.surface_get_material(surface) as StandardMaterial3D
		if standard == null or standard.resource_name != material_name:
			continue
		var tinted: StandardMaterial3D = standard.duplicate()
		tinted.albedo_color = tint
		out.surface_set_material(surface, tinted)
	return out


func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		out.append_array(_find_mesh_instances(child))
	return out


## Read live from `palette.json` rather than typed in here, the same reason
## `severed_spokes.gd::_palette_colour` does it: the faction colour must not
## be able to drift between the boundary's own Team Tether marks, the
## spokes' sealed road/gate, and the Warden's badge.
func _palette_colour(key: String, fallback: Color) -> Color:
	var file := FileAccess.open(PALETTE_CONFIG, FileAccess.READ)
	if file == null:
		push_warning("cannot read %s; '%s' falls back to a hard-coded value" % [PALETTE_CONFIG, key])
		return fallback
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for section: Variant in (parsed as Dictionary).values():
			if section is Dictionary and (section as Dictionary).has(key):
				return Color(str((section as Dictionary)[key]))
	return fallback


# ---------------------------------------------------------------------------
# Failsafe
# ---------------------------------------------------------------------------

## Spec §1E: "add a backup kill/respawn volume below the world only as a
## failsafe" — the boundary above is the design; this exists only for
## whatever it doesn't catch. Sized from the corridor's own authored bounds
## rather than a fixed square half-extent, since the corridor (unlike the
## old 512m world) is not centred on the origin — its z range runs
## -512..7680, so the kill volume's own centre has to move with it or half
## the corridor's length would sit outside a plane still centred at z=0.
const KILL_PLANE_HALF_X := (WORLD_X_EAST - WORLD_X_WEST) * 0.5 + KILL_PLANE_MARGIN
const KILL_PLANE_HALF_Z := (WORLD_Z_SOUTH - WORLD_Z_NORTH) * 0.5 + KILL_PLANE_MARGIN

## GATE-F-LEG-S10CDE. Track the last position the player was genuinely
## standing on the ground, so a kill-volume trigger can recover locally.
## `on_floor()` is read straight off the body rather than re-derived, the
## same "trust the physics server's own answer" the rest of this class
## already follows for collision.
func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.is_on_floor() and _player.global_position.y > KILL_PLANE_Y + 10.0:
		_last_safe_position = _player.global_position
		_has_last_safe_position = true
		_last_safe_age_s = 0.0
	elif _has_last_safe_position:
		_last_safe_age_s += delta


func _build_kill_volume() -> void:
	var area := Area3D.new()
	area.name = "KillVolume"
	var centre_x := (WORLD_X_WEST + WORLD_X_EAST) * 0.5
	var centre_z := (WORLD_Z_NORTH + WORLD_Z_SOUTH) * 0.5
	area.position = Vector3(centre_x, KILL_PLANE_Y, centre_z)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(KILL_PLANE_HALF_X * 2.0, KILL_PLANE_THICKNESS, KILL_PLANE_HALF_Z * 2.0)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(_on_kill_volume_entered)
	add_child(area)


## GATE-F-LEG-S10CDE. Measured against the real corridor: a player who was
## genuinely, stably standing on solid ground (`on_floor` true, unmoving, at
## the analytically-correct terrain height) can still land in this volume a
## handful of frames later with no gravity-paced fall in between -- `tools/
## _probe_s10c_stall_repro.gd`'s own log shows exactly that at (13.47, -0.08,
## 7416.99), band 5's approach corridor. That is the SAME mechanism
## `player_controller.gd::_clamp_runaway_velocity`'s own header already
## documents and admits is not fully closed ("there is more than one thing in
## the Meadows that gets built under a standing body... a CLAMP and not a fix
## to whatever moved the collider") -- a one-frame position jump large enough
## to land past this volume before the velocity clamp (which runs on the
## FOLLOWING frame's read) ever sees it. That root cause is not this file's
## to chase down; what IS this file's problem is what happens next. Resetting
## to `_spawn` unconditionally turns one transient physics glitch into
## catastrophic damage for anything walking a long route -- `move_to`'s own
## target is unrelated to spawn, so the walk wakes up ~7km from both its
## start and its destination, burns its entire remaining budget trying to
## walk back, and the whole leg reports FAIL for a reason that has nothing to
## do with the route itself. Recovering to the last position the player was
## actually, verifiably standing on real ground turns the same glitch into a
## few centimetres of correction -- the walk simply continues -- while still
## catching a genuine fall off the map (nothing here was ever on solid
## ground) by falling back to `_spawn` exactly as before.
##
## `_last_safe_age_s` guards a second, measured regression: `tests/
## smoke_traversal.gd`'s `_check_kill_volume` deliberately teleports the
## player straight into this volume as its own test, with no walking in
## between, so the only "last safe" reading on record was whatever the
## PREVIOUS, unrelated check left behind -- in that run, the far end of
## `_check_perimeter`'s cap-walk, 7+ km from anything the kill-volume test
## itself was about. Recovering there is not a local correction, it is a
## second teleport to a stale, irrelevant place, and it cascaded into the
## South Bridge check finding the player "entombed" and unsticking to the
## same stale spot next. A real in-play glitch never has this problem: the
## position is refreshed every physics frame right up to the moment the
## kill volume fires, so its age is ~0. Only a reading younger than
## `LAST_SAFE_MAX_AGE_S` is trusted; anything older falls back to `_spawn`,
## same as before this fix existed.
func _on_kill_volume_entered(body: Node3D) -> void:
	if body != _player:
		return
	var use_last_safe := _has_last_safe_position and _last_safe_age_s <= LAST_SAFE_MAX_AGE_S
	var recover_to := _last_safe_position if use_last_safe else _spawn
	print(("[world_perimeter_corridor] player fell below the world at %.0f, %.0f, %.0f -- "
		+ "returning to %s") % [
		body.global_position.x, body.global_position.y, body.global_position.z,
		"last safe ground" if use_last_safe else "spawn"
	])
	body.global_position = recover_to
	if body is CharacterBody3D:
		(body as CharacterBody3D).velocity = Vector3.ZERO
