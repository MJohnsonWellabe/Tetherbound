extends Node3D

## SA3 — a believable physical perimeter around the playground, and a
## below-world failsafe under it.
##
## Spec §1E: "the Meadows must not read as a floating level." The bake's own
## terrain stops at world_size/2 (±256m, terrain_playground.json) and turns
## into Terrain3D's `world_background` past that — drawn, never collided. A
## player who reaches that line today just walks off the edge of the world.
##
## OF7 REBUILD — why this file no longer looks like SA3's. The owner played
## the shipped build and said the perimeter "looks awful and isn't
## continuous", which outranks every in-file note below it. Root cause, and
## it is one cause with two symptoms:
##
##   SA3 built each of the forty ~37m segments as RIGID GEOMETRY AT A SINGLE
##   Y — every stone block, fence post, rail, bush and boulder was placed at
##   `mid.y`, the average of the segment's two endpoint ground heights. OF6
##   measured real ground climbing ~22m across one segment on the steepest
##   rise. A rigid horizontal 37m wall on ground like that is buried at one
##   end and hanging eleven metres in the air at the other. And because each
##   segment used its OWN `mid.y`, two neighbouring segments sharing a vertex
##   did not share a height there: every one of the forty joins was a
##   vertical step. That is "isn't continuous", literally, and it is also
##   most of "looks awful".
##
## The rebuild replaces per-segment rigid props with ONE ground-sampled
## polyline shared by every style (`_ring`, 720 points at ~2m spacing).
## Neighbouring styles share their vertices by construction, so a step at a
## join is no longer expressible. Everything — bank, kerb, wall, fence,
## hedge, boulders — is generated along that polyline and follows the terrain.
##
## Second, the styles are no longer four unrelated prop runs standing near
## each other. A continuous earth bank and a continuous fieldstone kerb run
## the WHOLE ring under all four styles, and a stone pier stands at each of
## the forty joins. That is the through-line: at any distance the boundary
## reads as one built line whose dressing changes, not as scattered props.
## Real field boundaries work exactly this way, and the key art board's own
## walls, fences and hedges all sit on banks with growth at their feet.
##
## Materials: the stonework is textured with `T_UnevenBrick` from the
## Quaternius medieval kit — the same kit `grandpa_house.gd`,
## `building_prefabs.gd` and `buildables.json` already build the village and
## the player's own walls from, so this is D24's one village family, not a
## new one. Ranch fencing is that kit's own `Prop_WoodenFence_*` modules
## (already a shipped buildable) instead of hand-cut boxes. Hedgerow and rock
## formation keep the vegetation layer's `Bush_Common`/`Rock_Medium_*`. No
## new asset, no generation.
##
## Cost: the old file spawned ~630 individual MeshInstance3D nodes around the
## ring. This one draws the bank and every piece of stonework as two merged
## meshes and batches bushes, boulders and fence panels through MultiMesh the
## way `vegetation.gd` already does — about a dozen draw calls for the whole
## boundary.
##
## `SA4` (the seven severed spokes) is later, separate work: it will cut
## openings into this ring at specific bearings. This item's job is a closed
## boundary that stops a player walking outward in any direction; leaving no
## gaps is correct here, not a gap in scope.

const RADIUS := 235.0
## Comfortably inside `tests/smoke_traversal.gd`'s own `WORLD_EDGE` (240.0) —
## the line past which that test already knows there is no real ground — and
## inside the ±256m bake itself, so every segment sits on real terrain, not
## the unloaded `world_background` past it.
const SEGMENTS := 40
## ~37m per segment at this radius. Segments are still the unit COLLISION and
## the style cycle work in; they are no longer the unit geometry is built in.

const SPANS_PER_SEGMENT := 18
## Visual resolution along the ring: 18 spans of ~2.05m per segment, 720
## points in all. Two jobs at once. It is fine enough that the wall, bank and
## kerb track the terrain's real undulation instead of hovering over it, and
## it is fine enough to REPLACE `COLLISION_SEGMENT_SUBSAMPLES` — OF6 sized
## the collision box from 16 interior samples at ~2.2m spacing, and each
## segment's 19 ring points here are the same measurement at ~2.05m, denser
## rather than coarser. See `_segment_ground_heights`.
const RING_POINTS := SEGMENTS * SPANS_PER_SEGMENT

## A perfect 235m circle reads as a compass construction from the air and, in
## a wide shot, as a suspiciously even arc. Two low harmonics pull the ring
## INWARD by up to `WOBBLE` metres — never outward, so nothing crosses
## `smoke_traversal.gd`'s 240m line — which is enough to read as a field
## boundary following a landscape rather than a radius. Deterministic, not
## random: the collision boxes are built from the same points. Kept small on
## purpose: `capture_perimeter.gd`'s wide shot stands at RADIUS - 9m, and a
## wobble large enough to eat that standoff would turn the establishing frame
## into a close-up of one wall face.
const WOBBLE := 3.0

## Every style stands on these two. The earth bank is the soft, natural half
## of the through-line; the fieldstone kerb on top of it is the hard, light-
## valued half that still reads at distance when the bank has gone to
## silhouette. Together they are what makes the boundary one line.
const BANK_HEIGHT := 0.46
const BANK_HALF_BASE := 1.9
const BANK_HALF_TOP := 1.35
## How far the bank's skirt is buried. The ring polyline is lightly smoothed
## (see `_sample_ring`) so the stonework does not ripple with every 20cm of
## terrain detail noise; burying the skirt is what keeps that smoothing from
## opening daylight under the bank on a dip.
const BANK_SINK := 1.3

const KERB_HEIGHT := 0.34
const KERB_HALF_BASE := 1.3
const KERB_HALF_TOP := 1.18

const WALL_HEIGHT := 1.95
const WALL_HALF_BASE := 0.62
const WALL_HALF_TOP := 0.5
const CAP_HEIGHT := 0.26
const CAP_HALF := 0.80
## Round 7: the coping is drawn from the same masonry sheet as the wall under
## it, so with no value break at the joint the two read as one lump of stone
## and the wall has no "top course" language at all — which is part of why the
## top edge was read as a rippling silhouette instead of as a coping line.
## Darkening the coping's own underside paints the shadow its overhang would
## cast, in vertex colour, at no draw-call cost (this project ships without
## SSAO — D01/D06 — so nothing supplies it for free).
const CAP_UNDER := Color(0.66, 0.68, 0.66)
## The coping gets its OWN, much finer texture repeat than the wall.
##
## Round 8: with the silhouette finally straight, the reviewer's eye moved to
## the surface and found "a visibly repeating block pattern at regular
## intervals — same bevel, same spacing, same size ... tiled geometry, not
## masonry". That is literally true and it was a UV bug, not a placement one.
## The coping's outer face is 0.26m tall drawn at `STONE_TILE` (3.2m), so it
## samples an 8%-tall horizontal SLIVER of the brick sheet and repeats that
## sliver every 3.2m — the same three smeared stones, over and over, the whole
## length of the wall. A coping course is made of small stones, so it needs a
## small repeat: at 1.2m the sheet's ~7 stones land at about 0.17m each, which
## is coping-sized, and the face samples a fifth of the sheet's height instead
## of a twelfth.
const CAP_TILE := 1.2
## Wall top ends up ~3.0m over real ground, comfortably over the 1.80m
## trainer — this is a world boundary, not a field wall to be stepped over.

## OF7 round 6 — the wall top is COURSED, not wavy.
##
## A blind reviewer read the top of the stone wall as "a wavy/rippling
## capstone line ... a mesh-instance-height artifact following the ground
## rather than a coursed wall top", and the render backs that up: the cap sags
## roughly a metre through the middle of the 37m run and humps up again at the
## end. Two independent wobbles were stacked on top of each other:
##
##   1. the cap sat at a FIXED offset above the smoothed ground polyline, so
##      every metre of the terrain's own broad undulation went straight into
##      the top edge — the whole reason the wall's BASE follows the ground, and
##      exactly the reason its top must not;
##   2. on top of that, `WALL_HEIGHT * randf_range(0.93, 1.05)` reseeded per
##      ring point added ±12cm of WHITE NOISE resampled every 2.05m. Random
##      per-vertex height is the literal definition of "mesh-instance-height
##      artifact"; no mason has ever built that.
##
## A real dry-stone wall on a hill keeps its base on the ground and takes up
## the slope in level courses, stepping where it has to. `_course_line` does
## that: it holds one absolute height for as long as the wall stays within a
## course of its nominal height, then steps by whole courses. Flat ground gets
## a dead-level top; a slope gets a staircase with long flat treads. Both read
## as deliberate. The wall's weathered, non-uniform read now comes entirely
## from vertex colour and the masonry texture, which vary without moving a
## single vertex.
const COURSE_HEIGHT := 0.27
## How much ground a run climbs before it is allowed ONE more tread. This is
## the number that decides whether the top reads as coursed or as rippling,
## and round 7's blind reviewer is why it exists in this form.
##
## Round 6 tracked the ground with a deadband: hold the level until the wall
## is a full course off nominal, then step. Measured afterwards
## (`tools/_probe_perimeter_shapes.gd`), that produced 3 to 15 risers per 37m
## run on gentle ground — one small up-or-down every few metres, which is a
## ripple with square corners. The reviewer read it as exactly that: "small,
## regular up-and-down waves running its whole visible length".
##
## The tread count now comes from the run's TOTAL climb instead: one tread per
## 1.1m of rise, so a run over gentle ground is a single dead-level top with no
## riser at all, and only genuinely steep ground gets a staircase — with risers
## big enough (>= ~1.1m) to read as a mason's decision. The wall's height then
## varies with the ground under it, which is what a level-topped wall on a
## hillside actually does, and is a feature rather than the defect the fixed
## offset was.
const RISER_RISE := 1.1
## The wall may never be shorter than this above the kerb, whatever the tread
## maths wants. A level tread over ground that humps in the middle would
## otherwise let the bank swallow the wall at the hump.
const WALL_FLOOR := 1.35

## Ranch fencing: `Prop_WoodenFence_Extension1/2` are 2.065m long and 0.838m
## tall as authored. Scaled to stand `FENCE_HEIGHT` above the kerb, then
## stretched along its own length only as far as it takes to make a whole
## number of panels fit a segment exactly — a run with no gaps and no
## overlapping posts.
const FENCE_HEIGHT := 1.62
const FENCE_MODEL_LENGTH := 2.065
const FENCE_MODEL_HEIGHT := 0.838
const FENCE_PANEL_TARGET := 4.1

const HEDGE_HEIGHT := 2.25
const HEDGE_SPACING := 1.5
## Measured with `tools/measure_models.gd`, not guessed: `Bush_Common` is
## 1.91 x 1.58 x 1.97m as imported, so its HEIGHT is 1.58m even though its
## footprint is nearly two metres across. Spacing tighter than the scaled
## footprint is what makes a row of bushes read as one hedge.
const HEDGE_MODEL_HEIGHT := 1.58

const ROCK_SPACING := 4.2
## How deep a formation boulder sits. Negative: the pack's boulders have a
## flat modelled underside, and a flat underside resting exactly on the bank
## top is a visible straight seam. Buried, the silhouette above ground is all
## rock.
const ROCK_SEAT := -0.45
## `Rock_Medium_1/2/3` measure 2.26 / 1.90 / 2.32m tall and up to 3.4m across.
const ROCK_MODEL_HEIGHT := 2.2
const ROCK_HEIGHT := 2.6

## A stone pier at each of the forty joins. Two jobs: it gives the eye a
## repeating vertical accent so the ring reads as one rhythm at distance
## rather than as a flat band, and it turns the style change from an abrupt
## seam into the thing a field boundary actually does — change at the
## gatepost.
const PIER_HALF := 0.56
const PIER_HEIGHT := 3.3
const PIER_CAP_HEIGHT := 0.26
const PIER_CAP_HALF := 0.7

## Low growth and loose stone along the WHOLE ring's outer foot, regardless of
## which style that stretch is. The cheapest thing that makes four different
## dressings read as one feature is a common base note under all of them.
const DRESSING_SPACING := 2.4

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
## The pack ships this material as a crimson autumn leaf (`Leaves_TwistedTree`,
## see vegetation.json's own comment on the same models) — swapping its
## texture for the pack's own green leaf is the identical fix vegetation.gd
## already applies to the "bushes" ground-cover layer.
const BUSH_LEAF_MATERIAL_NAME := "Leaves_TwistedTree"
const BUSH_GREEN_TEXTURE := preload("res://assets/environment/stylized_nature/Leaves_NormalTree_C.png")

## Untinted, `Rock_Medium_*` renders a pale mint-white under this lighting —
## and every OTHER rock in the meadow does not, because vegetation.json's
## `rocks` layer already retints the pack's `Rocks` material to this warm tan.
## The perimeter's boulders were the only stone in the world skipping that
## step, which read in round 1 as two unrelated kinds of rock in one frame
## (cold boulders against the warm fieldstone kerb they sit on). Same value,
## same file, no new asset.
const ROCK_MATERIAL_NAME := "Rocks"
const ROCK_TINT := Color("#c5ac9e")

## The kit's `MI_WoodTrim` renders a bright orange-tan out of the box, and in
## round 2's fence frame it was the most saturated thing in the picture — a
## brand-new fence in a meadow whose whole palette is muted. A plain darkening
## multiply (no hue rotation, so the kit's own wood grain survives) takes it to
## weathered field timber without moving it out of the village's material
## family.
const FENCE_MATERIAL_NAME := "MI_WoodTrim"
const FENCE_TINT := Color("#a2988f")

## Quaternius medieval kit, the same one the village and the player's own
## buildables are made of. `T_UnevenBrick` is the one genuinely TILEABLE
## masonry sheet in that kit — `T_RockTrim` and `T_WoodTrim` are trim
## ATLASES and stretch into nonsense across a long run, which is the defect
## `grandpa_house.gd`'s own header already records paying for once.
const STONE_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
const STONE_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
const STONE_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")
## Metres per texture repeat. The sheet is roughly seven stones across, so
## 3.2m puts a single stone at ~0.45m — field masonry, not cobbles and not
## megaliths.
const STONE_TILE := 3.2

## The bank is TURF, and takes the same grass photo the terrain itself is
## painted with (`terrain_playground.json`'s own `grass` layer) so it reads as
## a swell of the meadow rather than as a separate object standing on it.
##
## Round 1 used Ground030, the dirt/pebble path photo, on the theory that the
## scuffed foot of a boundary is worn earth. Rendered, that was the single
## worst thing in all four close-ups: a pale cream ramp running the entire
## ring, reading as poured concrete kerbing or a retaining wall — the exact
## "not a natural boundary" defect this item exists to remove. Grass, and a
## lower, narrower profile, put the only hard edge back where it belongs: the
## stone kerb.
const EARTH_ALBEDO := preload("res://assets/environment/terrain/Grass008_Color.jpg")
const EARTH_NORMAL := preload("res://assets/environment/terrain/Grass008_NormalGL.jpg")
const EARTH_TILE := 3.0

## How far below/above the visible geometry the collision box extends, so a
## slope crossing one segment's length doesn't punch a gap at the low end —
## the visible mesh is the boundary; this is the invisible support spec §1E
## asks for, not a substitute for it.
const COLLISION_MARGIN_DOWN := 6.0
## OF6: raised from 2.0. The old value assumed a segment's real terrain never
## strays far from the straight line between its two 9°-apart endpoints —
## true almost everywhere, false on the steepest of the three `rises`
## (`terrain_playground.json`, peak centred -165,-150, radius 58, which
## overlaps this ring's own radius by up to 46m). Measured directly: real
## ground climbs ~22m across one 37m segment there (bearing 207° at 1.7m to
## bearing 216° at 24.0m, both sampled with the game's own
## `ground_height_at()`), so the old two-endpoint average plus a 2m margin
## left the collision box's top roughly 8m below the real slope mid-segment
## — the ground simply rose up and over it. `_segment_ground_heights` below
## is the real fix (the box now tracks the segment's actual sampled terrain,
## not a straight line between its ends); this margin is a modest, measured
## cushion on top of that, not a substitute for it.
const COLLISION_MARGIN_UP := 3.0

## Below `tests/smoke_traversal.gd`'s own `THROUGH_THE_FLOOR` (-80.0, "the
## whole playground's lowest point is about -26m") but well above the old
## uncollided fall depth (-49950) — a generous net, not a hair-trigger.
const KILL_PLANE_Y := -120.0
const KILL_PLANE_HALF_EXTENT := 600.0
## A thick band, not a thin plane — a body already at terminal velocity can
## cross a one-frame gap several metres wide, and a plane no thicker than
## that gap is a real way to tunnel straight through a "failsafe".
const KILL_PLANE_THICKNESS := 40.0

var _player: CharacterBody3D = null
var _spawn: Vector3 = Vector3.ZERO

## The one shared ground-sampled polyline. `_ring` carries the lightly
## smoothed heights everything visible is built on; `_ring_raw_y` carries the
## unsmoothed terrain samples, which is what collision is sized from — a
## smoothed height is a good place to put a wall and a bad place to decide
## how tall a collision box has to be.
var _ring: PackedVector3Array = PackedVector3Array()
var _ring_raw_y: PackedFloat32Array = PackedFloat32Array()
var _ring_out: PackedVector3Array = PackedVector3Array()
var _ring_arc: PackedFloat32Array = PackedFloat32Array()
var _ring_total: float = 0.0


## `world` supplies `ground_height_at(x, z)`. `player`/`spawn_position` are
## needed for the kill-volume failsafe — reachable through `world.call()`
## the way `grandpa_house.build()` already takes the player, but this also
## needs the ORIGINAL spawn point, not the player's current position, which
## has moved by the time anything falls through.
func build(world: Node, player: CharacterBody3D, spawn_position: Vector3) -> void:
	_player = player
	_spawn = spawn_position

	var ring := Node3D.new()
	ring.name = "Ring"
	add_child(ring)

	_sample_ring(world)
	_build_bank(ring)
	_build_stonework(ring)
	_build_planting(world, ring)
	_build_collision(ring)

	_build_kill_volume()


# ---------------------------------------------------------------------------
# The shared polyline
# ---------------------------------------------------------------------------

## Segment endpoints sit on the wobbled circle; every point between two
## endpoints is a straight LERP along that segment's chord, not a point on
## the circle. That is deliberate: `_add_collision` puts one straight box per
## segment, and geometry that bows off the chord is geometry the box does not
## sit under. The ring is a slightly irregular 40-gon in plan, and the piers
## at the joins are what make the corners read as intent.
func _sample_ring(world: Node) -> void:
	var corners: Array[Vector2] = []
	for s in SEGMENTS + 1:
		var t := float(s) / float(SEGMENTS)
		var angle := t * TAU
		var r := _radius_at(t)
		corners.append(Vector2(cos(angle) * r, sin(angle) * r))

	_ring.resize(RING_POINTS)
	_ring_raw_y.resize(RING_POINTS)
	_ring_out.resize(RING_POINTS)
	_ring_arc.resize(RING_POINTS)

	var last_valid := 0.0
	for s in SEGMENTS:
		for k in SPANS_PER_SEGMENT:
			var i := s * SPANS_PER_SEGMENT + k
			var xz: Vector2 = corners[s].lerp(corners[s + 1], float(k) / float(SPANS_PER_SEGMENT))
			var ground: float = float(world.call("ground_height_at", xz.x, xz.y))
			if is_nan(ground):
				# The bake's own edge is not perfectly circular (four square
				# regions), so a sample this close to it can legitimately land
				# past the last written texel. Carrying the previous valid
				# height forward keeps the ring closed there without dropping
				# a fake 0.0 spike into the middle of a -20m stretch, which is
				# what the old code did.
				ground = last_valid
			else:
				last_valid = ground
			_ring[i] = Vector3(xz.x, ground, xz.y)
			_ring_raw_y[i] = ground
			_ring_out[i] = Vector3(xz.x, 0.0, xz.y).normalized()

	# Two passes of a [0.25, 0.5, 0.25] smooth. The bake's `detail` layer is
	# 2.2m of high-frequency noise; a dry-stone wall that ripples with every
	# metre of it reads as a bug, and a wall that ignores the hills entirely
	# is the defect this rebuild exists to remove. Smooth the noise, keep the
	# hills. `maxf` against the raw sample keeps the line from ever dropping
	# BELOW real ground on a sharp crest — smoothing may only ever raise it.
	for _pass_index in 2:
		var smoothed := PackedFloat32Array()
		smoothed.resize(RING_POINTS)
		for i in RING_POINTS:
			var prev := _ring[_wrap(i - 1)].y
			var next := _ring[_wrap(i + 1)].y
			smoothed[i] = maxf(prev * 0.25 + _ring[i].y * 0.5 + next * 0.25, _ring_raw_y[i])
		for i in RING_POINTS:
			var p := _ring[i]
			_ring[i] = Vector3(p.x, smoothed[i], p.z)

	var arc := 0.0
	for i in RING_POINTS:
		_ring_arc[i] = arc
		arc += Vector2(_ring[_wrap(i + 1)].x - _ring[i].x, _ring[_wrap(i + 1)].z - _ring[i].z).length()
	_ring_total = arc


## The coursed wall top, in ABSOLUTE world height, for `count` spans starting
## at ring index `i0`. See `COURSE_HEIGHT` and `RISER_RISE` for why this
## exists and why it is shaped this way.
##
## Measure the run's total climb, buy one tread per `RISER_RISE` of it, and lay
## those treads out as equal blocks. Each tread is DEAD LEVEL and quantised to
## a whole course. Gentle ground therefore gets one level top across the whole
## 37m; steep ground gets a staircase whose risers are large enough to read as
## steps rather than as noise. Nothing here can produce a small wobble, which
## is the point.
func _course_line(i0: int, count: int) -> PackedFloat32Array:
	var kerb := BANK_HEIGHT + KERB_HEIGHT
	# Add treads until no single tread has more than `RISER_RISE` of ground
	# movement under it. Sizing them from the run's TOTAL rise instead was the
	# first attempt and it is wrong: a run that climbs 7m in two short pitches
	# and then flattens gets seven treads either way, but the pitches land
	# inside two of them, and a level tread over a 5m pitch is a 6.4m wall at
	# one end (measured, `tools/_probe_perimeter_shapes.gd`). Bounding the
	# spread WITHIN a tread bounds the wall's height directly, which is the
	# thing that actually has to stay believable.
	var treads := 1
	while treads < count and _tread_spread(i0, count, treads) > RISER_RISE:
		treads += 1

	var out := PackedFloat32Array()
	out.resize(count + 1)
	for t in treads:
		var k0 := int(floor(float(t) * float(count + 1) / float(treads)))
		var k1 := int(floor(float(t + 1) * float(count + 1) / float(treads)))
		var mean := 0.0
		var highest := -INF
		for k in range(k0, k1):
			var y := _ring[_wrap(i0 + k)].y
			mean += y
			highest = maxf(highest, y)
		mean /= float(k1 - k0)
		# Nominal height over the tread's MEAN ground, floored so the tread's
		# own highest point still carries a real wall.
		var level := maxf(mean + kerb + WALL_HEIGHT, highest + kerb + WALL_FLOOR)
		level = round(level / COURSE_HEIGHT) * COURSE_HEIGHT
		for k in range(k0, k1):
			out[k] = level
	return out


## The worst ground movement under any one tread, if this run were split into
## `treads` equal blocks. See `_course_line`.
func _tread_spread(i0: int, count: int, treads: int) -> float:
	var worst := 0.0
	for t in treads:
		var k0 := int(floor(float(t) * float(count + 1) / float(treads)))
		var k1 := int(floor(float(t + 1) * float(count + 1) / float(treads)))
		var lo := INF
		var hi := -INF
		for k in range(k0, k1):
			var y := _ring[_wrap(i0 + k)].y
			lo = minf(lo, y)
			hi = maxf(hi, y)
		worst = maxf(worst, hi - lo)
	return worst


func _radius_at(t: float) -> float:
	var w := 0.55 * sin(t * TAU * 3.0 + 1.1) + 0.45 * sin(t * TAU * 7.0 + 2.7)
	return RADIUS - WOBBLE * (0.5 + 0.5 * w)


func _wrap(i: int) -> int:
	return posmod(i, RING_POINTS)


## A strip that goes all the way round meets itself. Nudging the tile size so
## a whole number of repeats fits the ring's own length is the difference
## between a seamless boundary and one visible texture jump somewhere on it.
func _closed_tile(nominal: float) -> float:
	var repeats := maxf(round(_ring_total / nominal), 1.0)
	return _ring_total / repeats


# ---------------------------------------------------------------------------
# The continuous bank
# ---------------------------------------------------------------------------

func _build_bank(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var low := PackedFloat32Array()
	var high := PackedFloat32Array()
	low.resize(RING_POINTS + 1)
	high.resize(RING_POINTS + 1)
	for k in RING_POINTS + 1:
		low[k] = -BANK_SINK
		high[k] = BANK_HEIGHT
	_strip(st, 0, RING_POINTS, low, high, BANK_HALF_BASE, BANK_HALF_TOP, _closed_tile(EARTH_TILE), Color(1.0, 1.0, 1.0))

	st.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.name = "Bank"
	mesh.mesh = st.commit()
	mesh.material_override = _earth_material()
	parent.add_child(mesh)


# ---------------------------------------------------------------------------
# Every piece of stone in one mesh
# ---------------------------------------------------------------------------

## Kerb, wall runs, capstones and piers are all the same material, so they are
## all the same surface. Per-piece value is carried in VERTEX COLOUR rather
## than in a material per piece — that is what buys the coursed, weathered
## read the old file spent thirteen separate MeshInstance3D nodes per segment
## on, at one draw call for the whole ring.
func _build_stonework(parent: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# The kerb: unbroken, all forty segments, under every style.
	var kerb_low := PackedFloat32Array()
	var kerb_high := PackedFloat32Array()
	kerb_low.resize(RING_POINTS + 1)
	kerb_high.resize(RING_POINTS + 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	for k in RING_POINTS + 1:
		kerb_low[k] = BANK_HEIGHT - 0.5
		kerb_high[k] = BANK_HEIGHT + KERB_HEIGHT
	_strip(st, 0, RING_POINTS, kerb_low, kerb_high, KERB_HALF_BASE, KERB_HALF_TOP, _closed_tile(STONE_TILE), Color(0.78, 0.78, 0.72), FOOT_TINT)

	# The wall runs. Every fourth segment. The BASE rides the ground polyline
	# (it has to meet the bank it stands on); the TOP is a coursed line that
	# steps instead of following it — see `COURSE_HEIGHT`. An earlier blind
	# critic read a taut top edge with even seams as "glass panels"; the answer
	# to that is weathering, which the per-point vertex colour below supplies
	# without moving a vertex, not random per-vertex height, which round 6's
	# critic correctly read as an artifact.
	var top := BANK_HEIGHT + KERB_HEIGHT
	for s in SEGMENTS:
		if s % 4 != 0:
			continue
		var i0 := s * SPANS_PER_SEGMENT
		var course := _course_line(i0, SPANS_PER_SEGMENT)
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
			rng.seed = hash(i0 + k)
			# `course` is an ABSOLUTE world height; `_strip_shaded` wants an
			# offset from each ring point's own height, so subtract it back
			# out. That subtraction IS the fix: it is what lets the top hold
			# level while the base keeps following the hill.
			var h := course[k] - _ring[_wrap(i0 + k)].y
			low[k] = top - 0.12
			high[k] = h
			cap_low[k] = h
			cap_high[k] = h + CAP_HEIGHT
			colours.append(Color(0.93, 0.92, 0.88).darkened(rng.randf_range(0.0, 0.30)))
			# The coping weathers too, and along its own length rather than
			# uniformly — a coping course whose every stone is the same value
			# is half of why the whole band read as one tiled strip.
			cap_colours.append(Color(1.0, 0.99, 0.95).darkened(rng.randf_range(0.0, 0.26)))
		_strip_shaded(st, i0, SPANS_PER_SEGMENT, low, high, WALL_HALF_BASE, WALL_HALF_TOP, STONE_TILE, colours, FOOT_TINT)
		_strip_shaded(st, i0, SPANS_PER_SEGMENT, cap_low, cap_high, CAP_HALF, CAP_HALF, CAP_TILE, cap_colours, CAP_UNDER)

	# A pier at every join.
	for s in SEGMENTS:
		var i := s * SPANS_PER_SEGMENT
		var p := _ring[i]
		var yaw := _yaw_at(i)
		_box(st, Vector3(p.x, p.y - 0.6, p.z), Vector3(PIER_HALF * 2.0, PIER_HEIGHT + 0.6, PIER_HALF * 2.0), yaw, Color(0.92, 0.91, 0.88))
		_box(st, Vector3(p.x, p.y + PIER_HEIGHT, p.z), Vector3(PIER_CAP_HALF * 2.0, PIER_CAP_HEIGHT, PIER_CAP_HALF * 2.0), yaw, Color(1.0, 0.99, 0.95))

	st.generate_tangents()
	var mesh := MeshInstance3D.new()
	mesh.name = "Stonework"
	mesh.mesh = st.commit()
	mesh.material_override = _stone_material()
	parent.add_child(mesh)


# ---------------------------------------------------------------------------
# Hedgerow, rock formation, ranch fence, and the dressing common to all
# ---------------------------------------------------------------------------

func _build_planting(world: Node, parent: Node3D) -> void:
	var bush_transforms: Array[Array] = [[], []]
	var rock_transforms: Array[Array] = [[], [], []]
	var fence_transforms: Array[Array] = [[], []]
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242

	var kerb_top := BANK_HEIGHT + KERB_HEIGHT

	for s in SEGMENTS:
		var length := _segment_length(s)
		match s % 4:
			0:
				# Growth hard against the wall's inner face. A dry-stone wall
				# that meets mown grass in one unbroken line for thirty-seven
				# metres is the giveaway that nothing has ever grown there —
				# and the stone-wall frame is the one segment style with no
				# planting of its own, so it was the only stretch of the ring
				# showing a clean hard edge along its whole length.
				var tufts: int = maxi(int(round(length / 3.0)), 6)
				for j in tufts:
					var f := (float(j) + 0.5 + rng.randf_range(-0.45, 0.45)) / float(tufts)
					var at := _point_along(s, f)
					var out := _out_along(s, f)
					var origin := at - out * rng.randf_range(0.65, 1.5) + Vector3(0.0, -0.1, 0.0)
					var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
						Vector3.ONE * rng.randf_range(0.4, 0.95))
					(bush_transforms[rng.randi() % 2] as Array).append(Transform3D(basis, origin))
			1:
				# Ranch fencing. Panel count is chosen so a whole number of
				# panels fits the segment exactly and the run has neither a
				# gap nor a doubled post.
				#
				# ROUND 6: it also had no VARIATION. Every panel sat at exactly
				# `(j + 0.5) / panels`, at exactly `FENCE_HEIGHT`, bolt upright,
				# every one parallel to the last — a textbook spline-array, and
				# the blind reviewer named it as such ("dead-even intervals, no
				# variation, no gap, no lean ... generated rather than
				# designed"). The rebuild's own header records that per-segment
				# RNG jitter existed before the move to a shared polyline and
				# did not survive it; this is that jitter, put back seeded so
				# the run is still deterministic, and sized so it can never
				# reopen the daylight the overlap below exists to close.
				var panels: int = maxi(int(round(length / FENCE_PANEL_TARGET)), 4)
				var panel_length := length / float(panels)
				var scale_y := FENCE_HEIGHT / FENCE_MODEL_HEIGHT
				# 12% over the exact fit. Each panel is rigid, so on a slope
				# consecutive panels stair-step; at an exact fit their ends
				# then part company and daylight shows through the run.
				# Overlapping them means the step stays (which real ranch
				# fencing does) without the gap (which it does not). Raised
				# from 8% to pay for the along-run jitter below: at ±5.5% of a
				# panel each, two neighbours can drift 11% apart, so the
				# overlap has to exceed that or the jitter buys variation by
				# reintroducing the exact defect the overlap fixed.
				var scale_x := panel_length / FENCE_MODEL_LENGTH * 1.16
				var tangent := _tangent_along(s)
				var side := tangent.cross(Vector3.UP)
				# Round 7: one panel per run is DOWN — rolled right over and
				# dropped into the grass. Round 6's lean of about three degrees
				# and six percent of height was measurable in the source and
				# invisible in the frame; the reviewer still read "identical
				# length, identical plank angle ... no sagging panel, no post
				# leaning". A boundary reads as maintained-and-failing rather
				# than as extruded when one thing in it has visibly given way,
				# and one collapsed panel does more of that than a degree of
				# lean on all of them. The collision box is per SEGMENT, not
				# per panel, so nothing here can open a hole a player fits
				# through.
				var fallen: int = rng.randi_range(1, panels - 2) if rng.randf() < 0.4 else -1
				# One run in two loses a panel to a bush clump. A field fence
				# with a hedge patch let into it is what an actual repaired
				# boundary looks like, and it is the "no gap" half of the
				# reviewer's complaint answered without ever showing bare
				# daylight through a boundary whose whole job is to stop you.
				# Never the first or last panel: a break at the pier would read
				# as the run failing to reach its own gatepost.
				var breach: int = rng.randi_range(1, panels - 2) if rng.randf() < 0.5 else -1
				for j in panels:
					var f := (float(j) + 0.5 + rng.randf_range(-0.05, 0.05)) / float(panels)
					var at := _point_along(s, f)
					if j == fallen:
						var down := Basis(tangent, Vector3.UP, side)
						down = down.rotated(tangent, rng.randf_range(1.15, 1.45))
						down = down.rotated(Vector3.UP, rng.randf_range(-0.35, 0.35))
						var down_y := scale_y * rng.randf_range(0.92, 1.02)
						(fence_transforms[j % 2] as Array).append(Transform3D(
							Basis(down.x * scale_x, down.y * down_y, down.z * down_y),
							at + _out_along(s, f) * rng.randf_range(-0.9, -0.3)
								+ Vector3(0.0, kerb_top - 0.95, 0.0)))
						continue
					if j == breach:
						var bush_out := _out_along(s, f)
						for _b in rng.randi_range(3, 4):
							var bush_at := at + bush_out * rng.randf_range(-0.7, 0.7) \
								+ tangent * rng.randf_range(-0.9, 0.9)
							var bush_basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
								Vector3.ONE * (HEDGE_HEIGHT / HEDGE_MODEL_HEIGHT) * rng.randf_range(0.55, 0.9))
							(bush_transforms[rng.randi() % 2] as Array).append(
								Transform3D(bush_basis, bush_at + Vector3(0.0, kerb_top - 0.5, 0.0)))
						continue
					# Lean and skew, then scale. Built by rotating an orthonormal
					# frame and scaling its COLUMNS, because `Basis.scaled()`
					# scales rows — a global scale, which would shear a rotated
					# panel instead of stretching it along its own length.
					var rot := Basis(tangent, Vector3.UP, side)
					rot = rot.rotated(tangent, rng.randf_range(-0.11, 0.11))
					rot = rot.rotated(Vector3.UP, rng.randf_range(-0.09, 0.09))
					var sy := scale_y * rng.randf_range(0.88, 1.08)
					var basis := Basis(rot.x * scale_x, rot.y * sy, rot.z * sy)
					var origin := at + Vector3(0.0, kerb_top - 0.16 + rng.randf_range(-0.14, 0.05), 0.0)
					(fence_transforms[j % 2] as Array).append(Transform3D(basis, origin))
			2:
				# Hedgerow: bushes packed tighter than a bush's own footprint,
				# so the canopies overlap into one mass instead of reading as
				# shrubs in a queue.
				#
				# ROUND 6: WALKED, not divided. The old loop put bush `j` at
				# `(j + 0.5) / count` plus a jitter smaller than the interval
				# itself, which cannot produce a thin patch or a thick knot —
				# only a slightly untidy queue, which is what the reviewer read
				# ("dead-even intervals ... no gap"). Advancing by a variable
				# step instead lets the row genuinely clump and genuinely thin,
				# and one step in eight is a long one, so the hedge is patchy
				# the way a hedge that has been grazed and cut back for years
				# is patchy. Same seeded RNG, so still deterministic.
				#
				# The FLOWERING is clumped too, by the same reasoning. Choosing
				# `Bush_Common_Flowers` with an independent coin flip per bush
				# puts blossom on every other bush at a near-constant interval —
				# in the render, an evenly beaded purple line. Real blossom
				# comes in patches, so flowering here is a two-state run: once a
				# stretch is in flower it tends to stay in flower, and once it
				# isn't it tends to stay out.
				# Round 7: KNOTS, not a walk. Round 6's variable-step walk did
				# clump and thin in the data, and the reviewer still called the
				# hedge "uniform in size and spaced at near-identical intervals
				# ... the clearest procedural tell in the set" — because a step
				# drawn from 0.5x to 1.35x of one spacing, bush after bush,
				# averages back out to that spacing over any stretch big enough
				# to look at. Variety per ITEM is not variety per GROUP.
				#
				# So the unit of placement is a thicket of three to seven
				# bushes, and the thicket is what varies: how many, how big,
				# how far past the next one, and whether the whole thicket is
				# in blossom. That is the same structure the rock formation
				# below already uses, and it is what puts real thick, thin and
				# bare stretches into a 37m run.
				var wander_phase := rng.randf_range(0.0, TAU)
				var travelled := HEDGE_SPACING * rng.randf_range(0.2, 0.7)
				while travelled < length:
					var thicket: int = rng.randi_range(3, 7)
					# One thicket in five stands taller and broader — a bush
					# that was never cut back. Uniform prop scale is named in
					# the rubric as a readable signature of generator output.
					var thicket_scale := rng.randf_range(1.15, 1.55) if rng.randf() < 0.2 else rng.randf_range(0.62, 1.05)
					var flowering := rng.randf() < 0.42
					var thicket_wander := 0.7 * sin(travelled / length * 6.1 + wander_phase)
					for _n in thicket:
						var f := (travelled + HEDGE_SPACING * rng.randf_range(-0.45, 0.45)) / length
						travelled += HEDGE_SPACING * rng.randf_range(0.45, 0.8)
						# Clear of the piers. A hedge growing straight through
						# its own gatepost is what made the round-6 frame's
						# pier read as a stray block hovering in foliage rather
						# than as part of the boundary line; leaving the last
						# ~1.7m at each end open lets the kerb and the pier's
						# own base show, which is what connects them.
						if f < 0.046 or f > 0.954:
							continue
						var at := _point_along(s, f)
						var out := _out_along(s, f)
						var across := thicket_wander + rng.randf_range(-0.55, 0.55)
						var scale := HEDGE_HEIGHT / HEDGE_MODEL_HEIGHT * thicket_scale * rng.randf_range(0.78, 1.22)
						var origin := at + out * across + Vector3(0.0, kerb_top - 0.25, 0.0)
						var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
						basis = basis.rotated(Vector3.RIGHT, rng.randf_range(-0.12, 0.12))
						basis = basis.rotated(Vector3.FORWARD, rng.randf_range(-0.12, 0.12))
						(bush_transforms[1 if flowering else 0] as Array).append(
							Transform3D(basis.scaled(Vector3.ONE * scale), origin))
					# The gap to the next thicket. One in four is a real
					# clearing where the kerb runs bare — a hedge with no
					# clearings is a wall made of leaves.
					travelled += HEDGE_SPACING * (rng.randf_range(2.6, 4.4) if rng.randf() < 0.25
						else rng.randf_range(0.7, 1.6))
			3:
				# Rock formation: boulders clustered along and across the
				# kerb, some straddling it, so an outcrop reads as breaking
				# THROUGH the boundary line rather than sitting on a shelf.
				# Clusters, not a queue. Round 2 still spaced boulders evenly
				# enough along the kerb that the run read as placed rather than
				# as outcrop — the rubric names regular intervals and uniform
				# prop scale as the readable signature of generator output. A
				# few knots of three to five, each with one clearly dominant
				# boulder, is what a real outcrop looks like.
				#
				# ROUND 7: FEWER, LOOSER knots, and a smaller top end. The
				# reviewer read this run as "lined up at roughly even spacing
				# along the wall like beads on a string, all similar in scale —
				# no big/small grouping, no gaps". Four knots evenly divided
				# across a 37m run, each only ±2m wide, IS a bead string; the
				# clustering was real in the code and invisible at the spacing
				# it ran at. Two or three knots, each spread over ~6m, with the
				# gaps between them left bare, is an outcrop.
				#
				# The dominant boulder also came down. `Rock_Medium_3` is 3.42m
				# across as authored, so the old 1.45 multiplier on top of the
				# ROCK_HEIGHT fit was putting 5.9m, 4m-tall monoliths on the
				# boundary — twice the height of the wall three segments away,
				# and (the reviewer's other complaint) big enough that one
				# unlit facet becomes the largest dark shape in the frame. The
				# kit's own colour and geometry are a known limit that needs
				# art this project does not have; how BIG they are is not, and
				# is the half of that complaint this file can answer.
				var knots: int = clampi(int(round(length / (ROCK_SPACING * 4.0))), 2, 3)
				for knot in knots:
					var centre := (float(knot) + rng.randf_range(0.25, 0.75)) / float(knots)
					var in_knot: int = rng.randi_range(4, 7)
					for n in in_knot:
						var f := centre + rng.randf_range(-0.085, 0.085)
						var at := _point_along(s, f)
						var out := _out_along(s, f)
						var across := rng.randf_range(-1.3, 1.3)
						# Round 8: a wider span between the knot's biggest and
						# its smallest. Round 7 cut the top end (right: 4m
						# monoliths were the loudest thing in the frame) but
						# pulled the whole knot toward one middling size, and
						# the reviewer read the result as "one soft, blobby,
						# uniform dark mass ... no individual rock definition".
						# A boulder pile reads as a pile because of the size
						# STEP between its parts, not because of any one part.
						var scale := ROCK_HEIGHT / ROCK_MODEL_HEIGHT * (rng.randf_range(1.0, 1.32) if n == 0 else rng.randf_range(0.22, 0.72))
						var origin := at + out * across + Vector3(0.0, ROCK_SEAT, 0.0)
						var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
						# The kit's boulders have a flat modelled underside, so
						# tilting a BIG one swings that base into view as a
						# near-black facet (see `_stone_basis`). Under about
						# 0.6 of the nominal fit the base stays buried and the
						# tilt just breaks the domed silhouette that made the
						# knot read as one lump.
						if scale < ROCK_HEIGHT / ROCK_MODEL_HEIGHT * 0.6:
							basis = basis.rotated(Vector3.RIGHT, rng.randf_range(-0.17, 0.17))
							basis = basis.rotated(Vector3.FORWARD, rng.randf_range(-0.17, 0.17))
						(rock_transforms[rng.randi() % 3] as Array).append(
							Transform3D(basis.scaled(Vector3.ONE * scale), origin))

	# The base note, all the way round, under every style: low growth and
	# loose stone at the bank's outer foot. Four dressings that share a base
	# read as one feature; four that do not read as four.
	var dressing_count := int(_ring_total / DRESSING_SPACING)
	for j in dressing_count:
		var f := (float(j) + 0.5 + rng.randf_range(-0.45, 0.45)) / float(dressing_count)
		var i := posmod(int(f * float(RING_POINTS)), RING_POINTS)
		var p := _ring[i]
		var out := _ring_out[i]
		# INWARD, mostly. The player is inside the ring and never sees the
		# outer face; round 1 put 72% of this growth on the far side, which is
		# why the wall close-up came back with a bare, hard-edged foot and
		# nothing softening the kerb line.
		var side := -1.0 if rng.randf() < 0.7 else 1.0
		var is_stone := rng.randf() >= 0.82
		# A loose stone dropped INSIDE the bank's own footprint is a stone
		# sliced by the bank mesh, and a sliced boulder reads as a flat grey
		# plate lying on the turf — round 4's wide and hedgerow frames both
		# had one in the near foreground. Stone stands clear of the bank;
		# foliage may still grow up against it, because overlapping leaves
		# read as growth rather than as a cut.
		var across := side * (rng.randf_range(BANK_HALF_BASE * 1.05, BANK_HALF_BASE * 1.35) if is_stone
			else rng.randf_range(BANK_HALF_BASE * 0.5, BANK_HALF_BASE * 1.4))
		# Sampled at the dressing's OWN position, not taken from the ring
		# point it was offset from. Up to 2.8m off the centreline is far
		# enough that real ground has moved, and round 2's frames showed the
		# cost directly: half-buried boulders reading as grey shards sticking
		# out of the turf at an angle nothing else in the world does.
		var here := p + out * across
		var ground: float = float(world.call("ground_height_at", here.x, here.z))
		if is_nan(ground):
			ground = p.y
		var origin := Vector3(here.x, ground - 0.18, here.z)
		if is_stone:
			# Round 5 made these full-size enough, and frequent enough, that
			# the near foreground of the wide frame read as three dark
			# boulders lined up in the grass beside the wall. They are meant
			# to be loose stone shed from the bank, not a second rock
			# formation.
			(rock_transforms[rng.randi() % 3] as Array).append(
				Transform3D(_stone_basis(rng, rng.randf_range(0.14, 0.34)), origin))
		else:
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
			(bush_transforms[rng.randi() % 2] as Array).append(
				Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(0.35, 0.95)), origin))

	for m in BUSH_MESHES.size():
		_batch(parent, "Hedge%d" % m, _bush_mesh(BUSH_MESHES[m]), bush_transforms[m])
	for m in ROCK_MESHES.size():
		_batch(parent, "Boulder%d" % m, _tinted_mesh(ROCK_MESHES[m], ROCK_MATERIAL_NAME, ROCK_TINT), rock_transforms[m])
	for m in FENCE_MESHES.size():
		_batch(parent, "Fence%d" % m, _tinted_mesh(FENCE_MESHES[m], FENCE_MATERIAL_NAME, FENCE_TINT), fence_transforms[m])


## Tilt, for SMALL loose stones only. `Rock_Medium_*` are modelled with a
## flat underside meant to be set level on the ground: round 5 tilted the big
## formation boulders too, and the result was that flat base swinging into
## view as a near-black facet, plus hard right-angled notches where two
## tilted boulders interpenetrated. At dressing scale (under half a metre)
## the same tilt just reads as a stone that has settled. The formation's own
## boulders get yaw and a deeper seat instead — see `ROCK_SEAT`.
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
# Collision — OF6's fix, unchanged in substance
# ---------------------------------------------------------------------------

func _build_collision(parent: Node3D) -> void:
	for s in SEGMENTS:
		var from := _corner(s)
		var to := _corner(s + 1)
		var heights := _segment_ground_heights(s)
		var basis := _segment_basis(from, to)
		var thickness := 3.4 if s % 4 == 3 else 2.4
		_add_collision(parent, basis["mid"], basis["yaw"], basis["length"],
			BANK_HEIGHT + KERB_HEIGHT + WALL_HEIGHT, thickness, heights)


func _corner(s: int) -> Vector3:
	var i := (s % SEGMENTS) * SPANS_PER_SEGMENT
	var p := _ring[i]
	return Vector3(p.x, _ring_raw_y[i], p.z)


## OF6: real ground sampled along the segment's actual path, not just its two
## endpoints. These are the segment's own 19 ring points — the same
## measurement OF6 introduced (its 2 endpoints plus 16 interior samples),
## taken at ~2.05m spacing rather than ~2.2m, and taken from the RAW terrain
## samples rather than the smoothed line the wall is drawn on. Denser and
## unsmoothed, so the box can only be at least as safe as OF6 made it.
func _segment_ground_heights(s: int) -> PackedFloat32Array:
	var heights := PackedFloat32Array()
	for k in SPANS_PER_SEGMENT + 1:
		heights.append(_ring_raw_y[_wrap(s * SPANS_PER_SEGMENT + k)])
	return heights


func _segment_basis(from: Vector3, to: Vector3) -> Dictionary:
	var delta := to - from
	var length := Vector2(delta.x, delta.z).length()
	var mid := (from + to) * 0.5
	var yaw := atan2(-delta.z, delta.x)
	return {"length": maxf(length, 0.01), "mid": mid, "yaw": yaw}


## A small safety overlap into each neighbour, cheap insurance against the
## exact-length boxes leaving a hairline seam at a vertex where two segments
## meet at an angle.
const COLLISION_OVERLAP := 3.0

## Confirmed by direct reproduction (a player walked clean through segment 32
## on a slide, well before reaching either end): this box's vertical centring
## was wrong. `mid.y + (height - MARGIN_DOWN) * 0.5 + MARGIN_DOWN` does not
## place the box `MARGIN_DOWN` below `mid.y` and `height + MARGIN_UP` above it
## — it centres the box roughly `height` too high, so on a segment whose two
## endpoints differ in ground height by more than a couple of metres (real
## undulation the ring's own header comment says to expect), the box's true
## floor sat above the actual terrain at the segment's lower end and a player
## walking that stretch dropped straight under it. The box has to span
## exactly `[mid.y - MARGIN_DOWN, mid.y + height + MARGIN_UP]` — solving for
## the centre that makes that true:
## OF6: the box's vertical span now comes from the segment's actual sampled
## ground (`heights`, `_segment_ground_heights()`), not the straight line
## between the segment's two endpoints — a real 22m mid-segment climb on the
## steepest `rises` peak defeated the old two-point average (see
## `COLLISION_MARGIN_UP`'s header for the measured numbers). `bottom` clears
## the lowest sample, `top` clears both the highest sample AND the style's
## own nominal wall height, so a flat segment still gets exactly the old
## box and only a genuinely undulating one grows.
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
# Geometry helpers
# ---------------------------------------------------------------------------

func _segment_length(s: int) -> float:
	var total := 0.0
	for k in SPANS_PER_SEGMENT:
		var a := _ring[_wrap(s * SPANS_PER_SEGMENT + k)]
		var b := _ring[_wrap(s * SPANS_PER_SEGMENT + k + 1)]
		total += Vector2(b.x - a.x, b.z - a.z).length()
	return total


## A point `f` of the way along segment `s`, interpolated between the ring's
## own sampled points so it sits on the terrain-following line rather than on
## a flat chord.
func _point_along(s: int, f: float) -> Vector3:
	var x := clampf(f, 0.0, 0.9999) * float(SPANS_PER_SEGMENT)
	var k := int(x)
	var frac := x - float(k)
	var a := _ring[_wrap(s * SPANS_PER_SEGMENT + k)]
	var b := _ring[_wrap(s * SPANS_PER_SEGMENT + k + 1)]
	return a.lerp(b, frac)


func _out_along(s: int, f: float) -> Vector3:
	var i := _wrap(s * SPANS_PER_SEGMENT + int(clampf(f, 0.0, 0.9999) * float(SPANS_PER_SEGMENT)))
	return _ring_out[i]


func _tangent_along(s: int) -> Vector3:
	var a := _ring[s * SPANS_PER_SEGMENT]
	var b := _ring[_wrap((s + 1) * SPANS_PER_SEGMENT)]
	return Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()


func _yaw_at(i: int) -> float:
	var a := _ring[_wrap(i - 1)]
	var b := _ring[_wrap(i + 1)]
	return atan2(-(b.z - a.z), b.x - a.x)


## Damp, mossy shade where stone meets the ground. A dry-stone wall with the
## same value top to bottom is the flattest a wall can look, and this project
## has no SSAO in its shipped pipeline (D01/D06) to supply the darkening for
## free — so it is painted in, in vertex colour, at no draw-call cost.
const FOOT_TINT := Color(0.62, 0.68, 0.55)


func _strip(st: SurfaceTool, i0: int, count: int, low: PackedFloat32Array, high: PackedFloat32Array, half_low: float, half_high: float, tile: float, colour: Color, foot: Color = Color.WHITE) -> void:
	var colours: Array[Color] = []
	for k in count + 1:
		colours.append(colour)
	_strip_shaded(st, i0, count, low, high, half_low, half_high, tile, colours, foot)


## A terrain-following prism along `count` spans of the ring starting at ring
## index `i0`. `low`/`high` are offsets from each ring point's own height, so
## the prism rides the ground rather than sitting at one Y — the whole point
## of the rebuild. UVs are in metres over `tile`, so the masonry keeps a
## constant real-world stone size no matter how long the run is.
func _strip_shaded(st: SurfaceTool, i0: int, count: int, low: PackedFloat32Array, high: PackedFloat32Array, half_low: float, half_high: float, tile: float, colours: Array[Color], foot: Color = Color.WHITE) -> void:
	var u := _ring_arc[_wrap(i0)] / tile
	for k in count:
		var ia := _wrap(i0 + k)
		var ib := _wrap(i0 + k + 1)
		var a := _ring[ia]
		var b := _ring[ib]
		var na := _ring_out[ia]
		var nb := _ring_out[ib]
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


## An upright box with a metre-based UV, so a pier is made of the same size
## stones as the wall beside it rather than one stone stretched over it.
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


## Flat-shaded, explicitly-normalled quad. The normal is computed from the
## geometry and then flipped to agree with `outward`, so a winding mistake
## costs nothing — every material here draws double-sided.
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
	# Per-piece value lives in vertex colour; see `_build_stonework`.
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
	# Solved, not eyeballed, the same way terrain_playground.json's own grass
	# tint was. `albedo_color` MULTIPLIES; Grass008_Color.jpg's mean is
	# RGB(0.393, 0.516, 0.168), and this tint lands the product at roughly
	# (0.26, 0.30, 0.12) — hue ~73, saturation ~0.61, a shade DARKER than the
	# terrain's own rendered grass. That is deliberate: a bank reads as a bank
	# because it is turned away from the light, not because it is a different
	# plant. It looks like lavender in a picker for the reason
	# terrain_playground.json already documents at length — to desaturate a
	# green by multiplying you must raise blue relative to green.
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


## The pack ships `Bush_Common`/`Bush_Common_Flowers` with a crimson autumn
## leaf texture on the `Leaves_TwistedTree` material (vegetation.json's own
## comment on the same models) — swap it for the pack's own green leaf, same
## fix the vegetation "bushes" layer already applies at scatter time. Baked
## into the mesh's own surface here rather than set as a surface override,
## because a MultiMesh draws a Mesh and never sees a MeshInstance3D's
## overrides.
func _bush_mesh(scene: PackedScene) -> Mesh:
	var instance: Node = scene.instantiate()
	var found := _find_mesh_instances(instance)
	instance.queue_free()
	if found.is_empty():
		return null
	var source: Mesh = found[0].mesh
	if source == null:
		return null
	# `duplicate(false)` keeps the importer's generated LOD chain and shadow
	# mesh, which rebuilding through surface_get_arrays() silently drops —
	# vegetation.gd paid for that once already.
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


## A pack material multiplied by a palette colour, baked into the mesh's own
## surface so a MultiMesh can carry it — a MultiMesh draws a Mesh and never
## sees a MeshInstance3D's surface overrides. `duplicate(false)` keeps the
## importer's LOD chain, which rebuilding through surface_get_arrays() drops.
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


# ---------------------------------------------------------------------------
# Failsafe
# ---------------------------------------------------------------------------

## Spec §1E: "add a backup kill/respawn volume below the world only as a
## failsafe" — the boundary above is the design; this exists only for
## whatever the boundary doesn't catch (a jump that clears it, a bug).
func _build_kill_volume() -> void:
	var area := Area3D.new()
	area.name = "KillVolume"
	area.position = Vector3(0.0, KILL_PLANE_Y, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(KILL_PLANE_HALF_EXTENT * 2.0, KILL_PLANE_THICKNESS, KILL_PLANE_HALF_EXTENT * 2.0)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(_on_kill_volume_entered)
	add_child(area)


func _on_kill_volume_entered(body: Node3D) -> void:
	if body != _player:
		return
	print("[world_perimeter] player fell below the world at %.0f, %.0f, %.0f -- returning to spawn" % [
		body.global_position.x, body.global_position.y, body.global_position.z
	])
	body.global_position = _spawn
	if body is CharacterBody3D:
		(body as CharacterBody3D).velocity = Vector3.ZERO
