extends Node3D

## R8.2 -- the authored stronghold route, and SG38's gauntlet standing in it.
##
## MEADOWS_PROGRESSION_SPEC.md §8 gives five spaces in one order -- Outer Works
## -> Courtyard / Hall Approach -> Tether Chamber Approach -> Warden Arena ->
## Legendary Chamber -- a 30-60 minute first-clear target, and one instruction
## in its own sentence: "Do not turn this into a giant puzzle dungeon." So this
## is a compact authored ROUTE, not a maze. One spine, no branches, no keys to
## hunt, one door, and every space readable from its own doorway.
##
## Everything that is a number, a position, a colour or a trainer lives in
## `data/config/stronghold.json`; this file is only the machine that stands it
## up. That file's own header carries the siting evidence and the design calls.
##
## Built on `burrow_warrens.gd`'s grammar deliberately -- boxes with REAL
## colliders, walls split around their openings so a CharacterBody3D can only
## leave through a doorway that was actually cut, named markers so later items
## ask the building where its rooms are, an Area3D that swaps the camera
## profile, one door that follows a progression flag, and a `ground_height_at`
## override so anything parented here stands on the built floor rather than on
## the meadow underneath it. Three things are new, because a fortress is not a
## cave:
##
##  * `open` chambers get no ceiling. The outer works and the courtyard are
##    yards inside high walls, under the real sky and the real weather; only
##    the three inner spaces are roofed.
##  * The whole complex shares ONE floor level, chosen at build time as the
##    HIGHEST ground under its own footprint plus a clearance. A cave can bury
##    itself under rising ground; a built fortress cannot have the hillside
##    coming up through its floor. The 6.4m of relief this site actually has
##    (measured -- see the config header) is absorbed by the skirt below the
##    floor slabs, which reads as a revetment, the same answer `landmark.gd`'s
##    plinth already gives for the castle.
##  * Team Tether hardware is bolted ONTO the stone rather than replacing it:
##    oxblood girder bands and braces, teal conduit runs pointing deeper. Both
##    colours come from `palette.json` through `severed_spokes.gd`'s own
##    reserved-colour reading, so the faction cannot drift between the pylons
##    on the spokes, the quarry's conduits and this building.
##
## THE MACHINE IS THE REAL ASSET NOW (D49, 2026-08-16). `docs/art/reference/
## 15_Legendary_Tether_Machine.png` is an owner-supplied board and the machine
## is one of the three hero objects D24 reserves Meshy for; the owner
## authorised the generation and it is installed at `machine.model`, fitted to
## `machine.height` by its own visual bounds. `machine.placeholder` is false
## and the node is named `TetherMachine`.
##
## The primitive massing below is NOT dead. It is the fallback `_build_machine`
## still takes when `model` is unset or its file is missing, it is what let the
## chamber be built and verified at the right SCALE before the asset existed,
## and it is the record of what the room was designed around. Leave it.
##
## AND THE RULE THAT COMES WITH THAT BOARD: it draws a legendary bound inside
## the containment ring because that is what the machine does. It licenses the
## MACHINE, never its occupant. §20/D23 forbid a new creature mesh at any
## credit balance, so nothing in here creates a creature and nothing may.

const CONFIG_PATH := "res://data/config/stronghold.json"
const TRAINER_NPCS := preload("res://scripts/world/trainer_npc.gd")
const CREATURE_BED := preload("res://scripts/build/creature_bed.gd")
const SEVERED_SPOKES := preload("res://scripts/world/severed_spokes.gd")
const APPROACH_DRAIN := preload("res://scripts/world/approach_drain_skin.gd")
## T1-HALL (2026-08-30). `building_prefabs.gd` is the same composer
## `landmark.gd`'s (retiring) castle and every settlement building already go
## through -- see `_build_hall_massing()` below for why this building needs it
## too, now that the castle IS this building.
const PREFABS := preload("res://scripts/world/building_prefabs.gd")

## CONTENT-0828B. The shared constructed-interior method. The owner named the
## castle and the Warrens together as "the lame looking locations. basically
## everywhere we had to build an under ground or build a building", so the two
## consume ONE method rather than getting a dressing pass each. See
## interior_structure.gd's header for the mechanism and
## `interior_structure` in stronghold.json for this building's vocabulary of it.
const INTERIOR_STRUCTURE := preload("res://scripts/world/interior_structure.gd")

## STRONGHOLD-MAT. Every wall/floor box in this file was a flat
## StandardMaterial3D colour with no texture at all -- the same class of bug
## `MAT-BLOCKOUT` already fixed for the Warrens (`burrow_warrens.gd::_material`)
## and the quarry/relay stone (`severed_spokes.gd::_stone_material`): one model
## family, reached down a code path that never warmed its material. Confirmed
## by rendering `tools/_probe_storm_pass.gd`'s own viewpoints on 2026-08-22 —
## the stronghold is still a flat grey/tan blockout from the approach, on the
## single largest structure in the chapter. `T_UnevenBrick` is the SAME cut
## stone the castle's plinth, the boundary wall and every Team Tether blocker's
## masonry already use (`severed_spokes.gd`'s own `STONE_ALBEDO/NORMAL/ROUGHNESS`
## constants) -- stronghold.json's own header already claims this shell is
## "the same weathered value family the castle's own plinth uses"; it just
## never got the texture that claim describes. Reused, not re-picked, so the
## works stay visually the same masonry family as the castle behind them
## (D24: one village family).
const STONE_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
const STONE_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
const STONE_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")
## MEASURED, after the blind visual pass round 1 called the walls "television
## static… a corrupted texture or per-pixel dither, not masonry" and was right.
##
## Two compounding causes, both invisible until this texture was tiled across
## something very large. `severed_spokes.gd` uses the same 3.2 and gets away
## with it because its stone objects are sub-metre to ~6m; the stronghold is
## the first thing in the project to run this material across 30-41m walls.
##
## 1. THE TILING WAS ~11x TOO FINE. In triplanar, `uv1_scale` multiplies world
##    position, so 3.2 repeats the tile every 1/3.2 = 0.31m. Counted off the
##    texture itself, T_UnevenBrick is about NINE stones across; at 0.31m that
##    makes each stone 3.5cm. That is gravel, not masonry. Real stones of this
##    shape run 0.3-0.5m, so the tile represents ~3.6m of wall and the scale
##    that says so is 1/3.6 = 0.28.
## 2. THE TEXTURE HAD NO MIPMAPS (`mipmaps/generate=false`, now true on all
##    three maps). Every stone in this texture is outlined in a thin, bright,
##    high-contrast white highlight -- the single worst thing to minify without
##    a mip chain. ~100 repeats across a wall, each highlight thinner than a
##    pixel at distance, is precisely the white per-pixel speckle the critic saw.
##
## Fixing only one would not have worked: mipmaps alone would blur 3.5cm
## pebbles into grey mud, and rescaling alone would still shimmer at distance.
const STONE_TILE := 0.28

## Which trainers.json rows belong to this building. `trainer_npc.gd` skips
## every row naming a `placed_by` it was not asked for, so the table stays the
## one source of teams, rewards and defeat flags while the ROOM decides where
## its people stand.
const PLACED_BY := "stronghold"

## OP21-25. `combat_arena.gd`'s default radius is a flat 11m (data/config/
## combat.json) and every fight that starts inside this building asks for it
## uniformly, whatever room it lands in. `tether_approach` is 16x18, so an 11m
## radius already clears its walls with only 2-3m to spare; the gauntlet
## trainers ahead of and behind it (`outer_works` 20x24, `courtyard` 22x28) are
## the same story. `combat_arena_bounds_at()` below is CombatManager's own
## `_ground_height()` pattern for radius instead of Y: walk up from the fight,
## ask the room what it can afford. This margin is how far inside the wall
## FACE the boundary is required to sit -- clearance for a body's own radius
## plus the base course/trim geometry proud of the wall, not a fudge factor.
const ARENA_WALL_MARGIN := 1.0

## Roomier than the warrens' cave profile: the arena is 24x26m and a 2.6m arm
## puts the camera inside the player's back in a space that size. Still tighter
## than the meadow default, because every one of these rooms has a wall close
## enough to clip through.
const INTERIOR_PROFILE := {
	"distance": 3.6,
	"height": 1.9,
	"fov": 72.0,
	"pitch_min_deg": -35.0,
	"pitch_max_deg": 30.0,
	"retarget_lag": 10.0,
}

var _config: Dictionary = {}
var _world: Node = null
var _camera_rig: Node = null
var _player: Node3D = null

var _floor_y: float = 0.0
var _wall_t: float = 1.2
var _skirt: float = 18.0
var _chambers: Dictionary = {}          # id -> chamber dict
var _order: Array[String] = []          # route order, as authored
var _markers: Dictionary = {}           # name -> global Vector3
var _materials: Dictionary = {}

## How many approach pylons stood, for `stats()` and for the capture tools --
## so neither has to count nodes by name.
var _approach_pylons := 0

## The approach drained-ground skin, held so tests and captures can reach it.
var _approach_drain: Node3D = null
var _footprint: Array = []              # local AABB rects [minx, minz, maxx, maxz]
var _doors: Array = []                  # [{flag, body, mesh}]
## CONTENT-0828B. `[centre, radius]` per passage and one entry per passage END,
## both in complex-local metres, both filled by `_build_passages()`. The
## structure pass keeps its members out of the first and stands a frame in the
## second. Recorded here rather than re-derived because the passage arithmetic
## that produces them is not trivial and a second copy of it would drift.
var _doorways: Array = []
var _openings: Array = []
var _trainers: Node3D = null
var _bed: Node3D = null
var _machine: Node3D = null
var _colours: Node3D = null             # a throwaway severed_spokes instance, for palette reads
var _palette_cache: Dictionary = {}


## --- build -----------------------------------------------------------------

## `world` answers `ground_height_at`; `camera_rig` and `player` may be null in
## a bare test scene and the complex still stands, just without the camera swap
## and without anybody to greet.
func build(world: Node, camera_rig: Node = null, player: Node3D = null) -> bool:
	_world = world
	_camera_rig = camera_rig
	_player = player
	_config = _load_config()
	if _config.is_empty():
		push_error("stronghold.json missing or malformed; the stronghold route does not exist")
		return false

	var site: Dictionary = _config.get("site", {})
	var at: Array = site.get("at", [0.0, 0.0])
	_wall_t = float(site.get("wall_thickness", 1.2))
	_skirt = float(site.get("skirt", 18.0))
	position = Vector3(float(at[0]), 0.0, float(at[1]))
	rotation.y = deg_to_rad(float(site.get("yaw_deg", 0.0)))

	for entry: Variant in _config.get("chambers", []):
		var chamber: Dictionary = entry as Dictionary
		var id := str(chamber.get("id", ""))
		if id == "":
			push_error("a stronghold.json chamber has no id; it was skipped")
			continue
		_chambers[id] = chamber
		_order.append(id)
		var centre := _local_of(chamber.get("at", [0.0, 0.0]))
		var size := _size_of(chamber.get("size", [8.0, 8.0]))
		_footprint.append([centre.x - size.x * 0.5, centre.z - size.y * 0.5,
			centre.x + size.x * 0.5, centre.z + size.y * 0.5])
	if _order.is_empty():
		push_error("stronghold.json lists no chambers; there is no route")
		return false

	# The one measurement that has to happen before any geometry: a built floor
	# sits above ALL of its own ground, never through it.
	if not _choose_floor_level():
		return false

	for id: String in _chambers:
		var centre := _local_of((_chambers[id] as Dictionary).get("at", []))
		_markers[id] = to_global(Vector3(centre.x, _floor_y, centre.z))

	_load_palette()
	_build_approach_conduits(world)
	_build_approach_drain(world)
	_build_chambers()
	_build_passages()
	_build_approach_ramp()
	_build_trim()
	_build_structure()
	_build_conduits()
	_build_lights()
	_build_exterior_facing()
	_build_exterior_dressing()
	_build_keep_parapets()
	_build_gate_frame()
	_build_hall_massing()
	_build_interior_area()
	_build_machine()
	_build_recovery_point()
	_build_marks()
	_place_gauntlet()
	_sync_doors()

	# The entrance is the ramp's own foot when there is one -- the point of a
	# marker is that a caller lands somewhere they can stand.
	if not _markers.has("entrance"):
		_markers["entrance"] = _markers.get("ramp_foot",
			to_global(Vector3(0.0, _floor_y, _mouth_outer_z() - 4.0)))
	set_process(true)
	print("[stronghold] %d spaces on the route (%s), floor y=%.2f, %d gauntlet trainer(s), %d approach pylon(s)%s" % [
		_order.size(), " -> ".join(_order), global_position.y + _floor_y, gauntlet_size(),
		_approach_pylons,
		", machine is a PLACEHOLDER" if machine_is_placeholder() else ""])
	return true


## BAND5-CONTENT, prompt 66's navigation spine / machinery readability /
## environmental storytelling, which are one object rather than three -- see
## `stronghold.json::_comment_approach_pylons` for the reasoning and
## `_comment_approach_pylons_measured` for why every station is where it is.
##
## BORROWED, NOT REBUILT, exactly as `old_quarry.gd::_build_conduit_run` is:
## `severed_spokes.gd::_build_pylons` already does mesh fitting, per-pylon
## lit/dead materials, aim-along-the-line orientation, box colliders and the
## sampled-parabola conduit spans, including the `gl_compatibility` emissive
## bug that turned a pylon white. It takes a spoke dictionary and reads only
## its `pylons` key, so this block goes in unchanged.
##
## THE HOLDER IS PARENTED TO THE WORLD, NOT TO THIS NODE, and that is not a
## style choice. This node carries `site.at` (0,7560) AND `site.yaw_deg` 90 --
## every chamber below is authored in the complex's own rotated local frame.
## `_build_pylons` places its children at ABSOLUTE world coordinates, so
## hanging them here would put the run 90 degrees off through the meadow.
## The quarry does not hit this because its own node sits unrotated at origin.
func _build_approach_conduits(world: Node3D) -> void:
	var config: Dictionary = _config.get("approach_pylons", {})
	var list: Array = config.get("list", [])
	if list.is_empty():
		return
	var builder: Node3D = SEVERED_SPOKES.new()
	builder.name = "ApproachConduits"
	world.add_child(builder)
	builder.call("_build_pylons", world, builder, {"pylons": config})
	_approach_pylons = list.size()


## Prompt 66's environmental storytelling clause. All of the reasoning, and
## the honest statement of what this does NOT yet do, is in
## `scripts/world/approach_drain_skin.gd`'s own header -- it is that file's
## subject, not this one's. Parented to the WORLD for the same reason the
## conduit run is: this node is yawed 90 degrees and the skin is authored in
## world metres.
func _build_approach_drain(world: Node3D) -> void:
	var config: Dictionary = _config.get("approach_drain", {})
	if config.is_empty():
		return
	var skin: Node3D = APPROACH_DRAIN.new()
	skin.name = "ApproachDeadGround"
	world.add_child(skin)
	skin.call("build", world, config)
	_approach_drain = skin


func _load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


## The floor. Sampled on a 4m grid over every chamber's own footprint (plus its
## walls), taking the MAXIMUM -- see this file's header for why a fortress
## cannot do what a cave does. The node itself is placed at the lowest sampled
## ground so the skirt has somewhere honest to hang from.
func _choose_floor_level() -> bool:
	var highest := -INF
	var lowest := INF
	if _world == null or not _world.has_method("ground_height_at"):
		# A bare test scene with no terrain: stand the complex at y=0.
		position.y = 0.0
		_floor_y = float(_config.get("site", {}).get("floor_clearance", 0.5))
		return true
	for rect: Array in _footprint:
		var min_x := float(rect[0]) - _wall_t
		var min_z := float(rect[1]) - _wall_t
		var max_x := float(rect[2]) + _wall_t
		var max_z := float(rect[3]) + _wall_t
		var steps_x := maxi(2, int(ceil((max_x - min_x) / 4.0)))
		var steps_z := maxi(2, int(ceil((max_z - min_z) / 4.0)))
		for ix in steps_x + 1:
			for iz in steps_z + 1:
				var local := Vector3(
					lerpf(min_x, max_x, float(ix) / float(steps_x)), 0.0,
					lerpf(min_z, max_z, float(iz) / float(steps_z)))
				var world_at := to_global(local)
				var height: float = float(_world.call("ground_height_at", world_at.x, world_at.z))
				if is_nan(height):
					push_error("no ground under the stronghold at %.0f, %.0f; the route cannot stand" % [
						world_at.x, world_at.z])
					return false
				highest = maxf(highest, height)
				lowest = minf(lowest, height)
	position.y = lowest
	_floor_y = (highest - lowest) + float(_config.get("site", {}).get("floor_clearance", 0.5))
	if _floor_y + 2.0 > _skirt:
		push_warning("the stronghold's skirt (%.1fm) is shorter than its own relief (%.1fm); slabs may float" % [
			_skirt, _floor_y])
	return true


func _local_of(raw: Variant) -> Vector3:
	var list: Array = raw if raw is Array else []
	if list.size() < 2:
		return Vector3.ZERO
	return Vector3(float(list[0]), 0.0, float(list[1]))


func _size_of(raw: Variant) -> Vector2:
	var list: Array = raw if raw is Array else []
	if list.size() < 2:
		return Vector2(8.0, 8.0)
	return Vector2(float(list[0]), float(list[1]))


## Height of the decorative dark base course run along the foot of each
## chamber wall, and how far it stands proud of the wall face. TUNABLE.
const BASE_COURSE_H := 0.9
const BASE_COURSE_PROUD := 0.35

## T1-ARCH (2026-08-29). Two independent blind passes -- the owner, then a
## Fable judge rendering `S-ext-02-flank-wide.png` cold, having read nothing
## either lane wrote -- called the same thing: from any side but the gate
## this building is "a featureless near-black box... no roofline
## articulation, no openings, no banners, no machinery, no propaganda... an
## unlit warehouse dropped on the meadow." A prior T1-ARCH pass fixed the
## VALUE half of that on the gate face only (`stronghold.json`'s
## `_comment_lights_exterior` fire+sky-fill recipe) and said outright in its
## own report that the flank was untouched and a "full occupation-scale
## dressing pass... is a separate task." This is that task, plus the texture
## -scale collision the same judge frame named: "the wall ahead is a flat
## slab of the same kind of cobble texture at 2-3x the scale... the two
## scales collide at the junction" (the floor's own `STONE_TILE *
## floor_tile_scale` against the bare `STONE_TILE` every chamber wall wears).
##
## Only the two OPEN yards (`outer_works`, `courtyard`) are dressed -- the
## three roofed rooms behind them are never seen from the meadow, and
## `_opening_on(id, side).is_empty()` is the same test `_build_wall` already
## uses to find a TRUE perimeter face (one with no passage cut through it),
## so this can never dress a wall the player actually walks through.
const EXTERIOR_CHAMBERS: Array[String] = ["outer_works", "courtyard"]

## The castle's own reused, oxblood-retinted banner module
## (`stronghold_occupation.gd`'s header already establishes it as the
## castle's banner, no new asset, no new colour) -- second building, same
## mesh, same tint.
const BANNER_MODEL := "res://assets/buildings/quaternius_castle/Banner.obj"
const BANNER_COLOUR := Color("#7a2430")
const BANNER_SCALE := 2.2

## A thin decorative skin flush against the TRUE exterior wall faces only,
## at a finer tile than the shared `_wall_material(true)` every chamber wall
## (interior rooms included) wears. It is a skin rather than a retune of
## that shared material so the already-tuned roofed interiors
## (CONTENT-0828B rounds 1-6) cannot drift: nothing about the real wall, its
## collision, or any other room's material changes, only what is glued to
## the two yards' outward faces.
const EXTERIOR_FACE_TILE_MULT := 1.8
const EXTERIOR_FACE_SKIN := 0.06

## Roofline: a proud cap at the wall HEAD, the same cue `BASE_COURSE_*`
## already gives the wall's FOOT, plus a broken merlon row on top of it --
## the "no roofline articulation beyond one step" the judge named.
const COPING_H := 0.5
const COPING_PROUD := 0.3
const MERLON_W := 1.0
const MERLON_H := 0.9
const MERLON_GAP := 1.4


## --- materials --------------------------------------------------------------

func _material(colour: Color, emissive := 0.0, textured := false) -> StandardMaterial3D:
	var key := "%s_%.2f_%s" % [colour.to_html(), emissive, textured]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.92
	if textured:
		# Same triplanar-on-a-primitive-box technique `burrow_warrens.gd` and
		# `severed_spokes.gd::_stone_material` already use: no authored UVs on
		# these procedurally-sized walls/floors, so the texture has to project
		# itself. `albedo_color` still multiplies the texture, so every config
		# key that used to BE the wall's colour (`_stone`, `_stone_light`,
		# `_floor_colour`) still tints it -- the works keep their own palette,
		# they just stop being flat.
		m.albedo_texture = STONE_ALBEDO
		m.albedo_color = colour
		m.normal_enabled = true
		m.normal_texture = STONE_NORMAL
		m.roughness_texture = STONE_ROUGHNESS
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * STONE_TILE
	else:
		m.albedo_color = colour
	if emissive > 0.0:
		m.emission_enabled = true
		m.emission = colour
		m.emission_energy_multiplier = emissive
	_materials[key] = m
	return m


## The two reserved faction colours, read through `severed_spokes.gd`'s own
## palette reader rather than typed in here -- palette.json calls both of them
## reserved, and a second copy of the lookup is how a reserved colour drifts.
func _palette(key: String, fallback: Color) -> Color:
	return _palette_cache.get(key, fallback)


## Read once, at the top of the build, through a throwaway `severed_spokes.gd`
## instance. That file already owns the reserved-colour lookup (and the reason
## the emission floor exists); a second copy of it here is exactly how a colour
## palette.json calls RESERVED drifts between the pylons, the quarry and this
## building. The instance is freed immediately -- it is a Node3D and nothing
## here wants it in the tree.
func _load_palette() -> void:
	_colours = SEVERED_SPOKES.new()
	for pair: Array in [["tether_oxblood", Color("#332228")], ["tether_teal", Color("#3fe8c4")]]:
		_palette_cache[str(pair[0])] = _colours.call("_palette_colour", str(pair[0]), pair[1] as Color)
	_colours.free()
	_colours = null


func _stone() -> Color:
	return Color(str(_config.get("site", {}).get("stone", "#6a6157")))


## The castle's own kit palette, so the works read as the same fortress the
## walls above them belong to.
##
## Owner, seeing the complex from the valley: "it looks too sterile overall.
## make the whole thing look a little more like the actual castle in the back
## and give it color not a plain grey all the way through." He was right, and
## the cause was structural: every wall, floor and ceiling in here asked for
## ONE colour, so a 116m fortress interior was a single flat grey from end to
## end, while the Quaternius castle beside it carries six retinted materials
## (building_prefabs.json's `castle.retint`). These are those same values --
## quoted from that block, not re-picked -- so the two structures share a
## palette rather than merely coexisting.
##
## `_stone()` stays the base wall tone and the config key still overrides it;
## these are the accents that were missing. All TUNABLE.
func _stone_light() -> Color:
	return Color(str(_config.get("site", {}).get("stone_light", "#786d5e")))


func _stone_dark() -> Color:
	return Color(str(_config.get("site", {}).get("stone_dark", "#463f37")))


## The ceiling slab's tint, and it is NOT `_timber()` -- it is `_timber()`
## lifted far enough to survive being multiplied by a texture.
##
## This is the one number in the pass that was measured rather than judged, and
## it had to be: texturing the ceiling cost the two inner rooms most of their
## value range, and two rounds of adjusting the DARKENING did not find it,
## because darkening was never the cause.
##
## `_material(colour, 0, true)` multiplies `T_UnevenBrick` by its colour, and
## that texture averages (0.53, 0.47, 0.40). So the untextured slab this
## replaced rendered its flat `_timber()` at luminance 96, and the same colour
## through the texture lands at 46 -- the ceiling is the largest bright surface
## in every roofed room, so the warden arena went from 76.0% of pixels below
## luminance 40 to 96.7% against `origin/main`, and a blind critic's FIRST
## finding on these frames was already the value crush. Lifting the tint 0.65
## toward white puts the textured result back at 95.8, which is where the flat
## slab was: the room keeps the brightness it had and gains the grain and the
## ribs. TUNABLE via `site.ceiling_lift`.
func _ceiling_colour() -> Color:
	var lift := clampf(float(_config.get("site", {}).get("ceiling_lift", 0.65)), 0.0, 1.0)
	return _timber().lerp(Color.WHITE, lift)


func _timber() -> Color:
	return Color(str(_config.get("site", {}).get("timber", "#7a5c39")))


## A wall's own tone, varied by where it stands. Outer walls take the castle's
## lighter face stone (they are what a player sees from outside), inner walls
## the base tone, and every wall gets a dark base course under it -- the single
## cheapest cue that turns a flat box into built masonry, and the one the
## castle's own two-course curtain already uses.
func _wall_material(outer: bool) -> StandardMaterial3D:
	return _material(_stone_light() if outer else _stone(), 0.0, true)


func _floor_colour() -> Color:
	return Color(str(_config.get("site", {}).get("floor_colour", "#57503f")))


## The floor's own material -- the same stone as the walls at its OWN grain.
##
## Floor and wall shared `STONE_TILE`, and a blind critic measured what that
## costs against the 1.80 m trainer standing in the frame: the near-field
## cobbles in the tether approach read close to a metre across, "paving slabs
## the size of a car bonnet, laid in a corridor". A wall is seen face-on and a
## floor is seen at a grazing angle running away from the camera, so the same
## tile size cannot serve both -- the floor needs the tighter one.
func _floor_material() -> StandardMaterial3D:
	var key := "floor_stone"
	if _materials.has(key):
		return _materials[key]
	var m: StandardMaterial3D = _material(_floor_colour(), 0.0, true).duplicate() as StandardMaterial3D
	m.uv1_scale = Vector3.ONE * (STONE_TILE * float(_config.get("site", {}).get("floor_tile_scale", 2.6)))
	_materials[key] = m
	return m


## Oxblood: dark faction paint on stone. The emission is a value FLOOR, not a
## glow -- severed_spokes.gd's own header records why (under gl_compatibility
## the bare albedo shades to pure black and the colour stops being readable as
## a colour at all).
func _tether_material() -> StandardMaterial3D:
	# CONTENT-0828B: `textured` was defaulting to false here, so every girder
	# and pillar in the complex was a flat unshaded colour. A blind critic
	# probed the courtyard's tallest pillar down its full height and got the
	# same three values top to bottom -- "it does not change value once" --
	# and called it blockout material on the most prominent vertical element in
	# the frame. It is faction paint ON STONE (this function's own name for it),
	# so it takes the same masonry the wall behind it does and keeps its
	# oxblood as the tint. The emission stays: `severed_spokes.gd` records that
	# it is a value FLOOR, not a glow -- without it the bare albedo shades to
	# pure black under gl_compatibility and the reserved colour stops reading as
	# a colour at all.
	return _material(_palette("tether_oxblood", Color("#332228")), 0.55, true)


## Teal: the reserved ENERGY colour, and it appears only where Team Tether's
## machinery is live.
func _live_material() -> StandardMaterial3D:
	return _material(_palette("tether_teal", Color("#3fe8c4")), 1.4)


## --- geometry ---------------------------------------------------------------

## A box with matching collision, positioned by its centre in complex-local
## space. `solid: false` is decoration that must never block a doorway.
func _box(size: Vector3, at: Vector3, material: StandardMaterial3D, solid := true,
		node_name := "") -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	if node_name != "":
		mesh.name = node_name
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		body.position = at
		add_child(body)
	return mesh


## Every chamber: a floor slab reaching `skirt` metres down, a ceiling slab
## unless the chamber is `open`, and four walls split around whatever passages
## meet them.
func _build_chambers() -> void:
	for id: String in _chambers:
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		var height := float(chamber.get("height", 6.0))
		var outer := Vector2(size.x + _wall_t * 2.0, size.y + _wall_t * 2.0)

		_box(Vector3(outer.x, _skirt, outer.y),
			Vector3(centre.x, _floor_y - _skirt * 0.5, centre.z), _floor_material())
		if not bool(chamber.get("open", false)):
			# CONTENT-0828B: this was `_material(_timber())` -- a flat untextured
			# colour, on a slab up to 28x28 m. It is the single largest surface
			# in every roofed space in the complex and `C2-warden-arena` and
			# `C3-tether-approach` both came back with a plain tan plane filling
			# the top third of the frame. Same defaulted `textured` argument
			# STRONGHOLD-MAT already fixed for the walls and floors here and
			# MAT-BLOCKOUT for the Warrens; the ceiling was the surface neither
			# pass looked at. Textured now, and darker: a lit ceiling competes
			# with everything below it, and the ribs `_build_structure()` hangs
			# under it only read as ribs against a ground they are darker than.
			_box(Vector3(outer.x, 1.0, outer.y),
				Vector3(centre.x, _floor_y + height + 0.5, centre.z),
			# See `_ceiling_colour()` for why this slab's tint is not `_timber()`.
				_material(_ceiling_colour(), 0.0, true))

		for side: String in ["-x", "+x", "-z", "+z"]:
			_build_wall(centre, size, height, side, _opening_on(id, side))


## The opening (if any) in one side of one chamber, derived from the passage
## table rather than authored twice.
func _opening_on(chamber_id: String, side: String) -> Dictionary:
	for entry: Variant in _config.get("passages", []):
		var passage: Dictionary = entry as Dictionary
		var from := str(passage.get("from", ""))
		var to := str(passage.get("to", ""))
		if from != chamber_id and to != chamber_id:
			continue
		var other := to if from == chamber_id else from
		if not _chambers.has(other):
			continue
		if _side_toward(chamber_id, other) == side:
			return {"width": float(passage.get("width", 3.0)),
				"height": float(passage.get("height", 4.0))}
	# The way in: the first space's outward wall carries the same opening its
	# inward passage does.
	if chamber_id == _order[0] and side == "-z":
		var first: Dictionary = _first_passage()
		return {"width": float(first.get("width", 4.0)), "height": float(first.get("height", 4.5))}
	return {}


func _first_passage() -> Dictionary:
	var list: Array = _config.get("passages", [])
	return list[0] as Dictionary if not list.is_empty() else {}


## Which of `a`'s four sides faces `b`. Passages are axis-aligned by contract
## (see stronghold.json's own frame note), so this is a comparison, not a ray.
func _side_toward(a_id: String, b_id: String) -> String:
	var a := _local_of((_chambers[a_id] as Dictionary).get("at", []))
	var b := _local_of((_chambers[b_id] as Dictionary).get("at", []))
	if absf(b.x - a.x) >= absf(b.z - a.z):
		return "+x" if b.x > a.x else "-x"
	return "+z" if b.z > a.z else "-z"


## The wall geometry for one side, as the list of pieces `_build_wall` builds
## (a single full-span entry when there is no opening, else two flanks and a
## lintel). Shared with the exterior facing/dressing passes below so neither
## can place a skin or a banner somewhere the real wall is not -- the same
## reason `_footprint`/`_opening_on` are computed once and read everywhere.
func _wall_rects(centre: Vector3, size: Vector2, height: float, side: String,
		opening: Dictionary) -> Array:
	var along_x := side == "-z" or side == "+z"
	var span := (size.x if along_x else size.y) + _wall_t * 2.0
	var offset := (size.y if along_x else size.x) * 0.5 + _wall_t * 0.5
	var sign_ := -1.0 if side.begins_with("-") else 1.0
	var wall_centre := centre
	if along_x:
		wall_centre.z += sign_ * offset
	else:
		wall_centre.x += sign_ * offset
	var wall_h := height + 1.4

	if opening.is_empty():
		return [{"along_x": along_x, "sign": sign_, "at": wall_centre, "span": span,
			"height": wall_h, "base": 0.0}]

	var gap := float(opening.get("width", 3.0))
	var gap_h := minf(float(opening.get("height", 4.0)), height)
	var flank := (span - gap) * 0.5
	var out: Array = []
	if flank > 0.05:
		out.append({"along_x": along_x, "sign": sign_,
			"at": _shift(wall_centre, along_x, -(gap * 0.5 + flank * 0.5)),
			"span": flank, "height": wall_h, "base": 0.0})
		out.append({"along_x": along_x, "sign": sign_,
			"at": _shift(wall_centre, along_x, gap * 0.5 + flank * 0.5),
			"span": flank, "height": wall_h, "base": 0.0})
	out.append({"along_x": along_x, "sign": sign_, "at": wall_centre, "span": gap,
		"height": wall_h - gap_h, "base": gap_h})
	return out


## One wall, in up to three pieces: two flanks either side of the opening and a
## lintel over it. A gap that was never cut is a wall, whatever the mesh shows.
func _build_wall(centre: Vector3, size: Vector2, height: float, side: String,
		opening: Dictionary) -> void:
	for rect: Dictionary in _wall_rects(centre, size, height, side, opening):
		_wall_piece(bool(rect["along_x"]), rect["at"] as Vector3, float(rect["span"]),
			float(rect["height"]), float(rect["base"]))


func _shift(at: Vector3, along_x: bool, by: float) -> Vector3:
	if along_x:
		at.x += by
	else:
		at.z += by
	return at


func _wall_piece(along_x: bool, at: Vector3, span: float, height: float, base: float) -> void:
	if span <= 0.01 or height <= 0.01:
		return
	var size := Vector3(span, height, _wall_t) if along_x else Vector3(_wall_t, height, span)
	# Walls reach the skirt below the floor too, so the outside reads as built
	# stone meeting the ground rather than as a floating box.
	var extra := 0.0 if base > 0.0 else _skirt
	size.y += extra
	_box(size, Vector3(at.x, _floor_y + base + (height + extra) * 0.5 - extra, at.z),
		_wall_material(true))
	# A darker base course along the foot of every chamber wall. Thin, slightly
	# proud, and purely decorative (solid: false) so it can never narrow a
	# doorway -- the flat-box-into-masonry cue, and the reason the interior no
	# longer reads as one grey extrusion.
	var course := Vector3(size.x, BASE_COURSE_H, size.z)
	# Proud on the two FACE sides only, never along the run's length.
	if along_x:
		course.z += BASE_COURSE_PROUD
	else:
		course.x += BASE_COURSE_PROUD
	_box(course, Vector3(at.x, _floor_y + base - extra + BASE_COURSE_H * 0.5, at.z),
		_material(_stone_dark(), 0.0, true), false)


## The ways between spaces: floor, side walls, and a ceiling wherever BOTH ends
## are roofed (a passage between two open yards stays open to the sky).
func _build_passages() -> void:
	for entry: Variant in _config.get("passages", []):
		var passage: Dictionary = entry as Dictionary
		var from := str(passage.get("from", ""))
		var to := str(passage.get("to", ""))
		if not _chambers.has(from) or not _chambers.has(to):
			push_warning("stronghold.json passage names an unknown chamber (%s -> %s)" % [from, to])
			continue
		var side := _side_toward(from, to)
		var along_x := side == "+x" or side == "-x"
		var a := _local_of((_chambers[from] as Dictionary).get("at", []))
		var b := _local_of((_chambers[to] as Dictionary).get("at", []))
		var a_size := _size_of((_chambers[from] as Dictionary).get("size", []))
		var b_size := _size_of((_chambers[to] as Dictionary).get("size", []))
		var a_edge: float = (a.x + signf(b.x - a.x) * a_size.x * 0.5) if along_x \
			else (a.z + signf(b.z - a.z) * a_size.y * 0.5)
		var b_edge: float = (b.x - signf(b.x - a.x) * b_size.x * 0.5) if along_x \
			else (b.z - signf(b.z - a.z) * b_size.y * 0.5)
		var mid: float = (a_edge + b_edge) * 0.5
		var length := absf(b_edge - a_edge) + _wall_t * 2.0
		var width := float(passage.get("width", 3.0))
		var height := float(passage.get("height", 4.0))
		var lateral := a.z if along_x else a.x
		var centre := Vector3(mid, 0.0, lateral) if along_x else Vector3(lateral, 0.0, mid)
		var roofed := not bool((_chambers[from] as Dictionary).get("open", false)) \
			or not bool((_chambers[to] as Dictionary).get("open", false))
		_doorways.append([centre, maxf(width, length) * 0.5 + 1.6])
		# Both ends: each room sees its own opening, and a frame at the passage
		# MIDPOINT is a frame inside the tunnel that nobody standing in either
		# room can see. `along_x` flips because the reveal pass is told about
		# the HOLE, whose width runs across the passage, not about the tunnel.
		for edge: float in [a_edge, b_edge]:
			_openings.append({
				"centre": Vector3(edge, 0.0, lateral) if along_x else Vector3(lateral, 0.0, edge),
				"along_x": not along_x, "width": width, "height": height,
			})

		var floor_size := Vector3(length, _skirt, width + _wall_t * 2.0)
		var ceiling_size := Vector3(length, 1.0, width + _wall_t * 2.0)
		if not along_x:
			floor_size = Vector3(width + _wall_t * 2.0, _skirt, length)
			ceiling_size = Vector3(width + _wall_t * 2.0, 1.0, length)
		_box(floor_size, Vector3(centre.x, _floor_y - _skirt * 0.5, centre.z), _floor_material())
		if roofed:
			# Same untextured-ceiling fix as `_build_chambers()`. This one is
			# seen END-ON above every doorway, which is where `C3` caught it:
			# a flat tan block over the way through, reading as cardboard.
			_box(ceiling_size, Vector3(centre.x, _floor_y + height + 0.5, centre.z),
			# See `_ceiling_colour()` for why this slab's tint is not `_timber()`.
				_material(_ceiling_colour(), 0.0, true))

		for s in [-1.0, 1.0]:
			var wall_at := centre
			var wall_size := Vector3(length, height + _skirt, _wall_t)
			if along_x:
				wall_at.z += s * (width * 0.5 + _wall_t * 0.5)
			else:
				wall_at.x += s * (width * 0.5 + _wall_t * 0.5)
				wall_size = Vector3(_wall_t, height + _skirt, length)
			_box(wall_size, Vector3(wall_at.x, _floor_y + height * 0.5 - _skirt * 0.5, wall_at.z),
				_wall_material(false))

		var flag := str(passage.get("gated_by_flag", ""))
		if flag != "":
			_build_door(flag, centre, along_x, width, height)


## The complex's one door: a Tether blast shutter filling a passage, gone for
## good once `flag` is set. No prompt, no UI, no key -- a mechanism, the same
## way the warrens' vault door and SC14's bridge are.
func _build_door(flag: String, centre: Vector3, along_x: bool, width: float, height: float) -> void:
	var size := Vector3(0.7, height, width) if along_x else Vector3(width, height, 0.7)
	var colour := Color(str(_config.get("site", {}).get("door_colour", "#3a3f3c")))
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(colour)
	mesh.position = Vector3(centre.x, _floor_y + height * 0.5, centre.z)
	mesh.name = "BlastShutter_%s" % flag
	add_child(mesh)

	var body := StaticBody3D.new()
	body.name = "BlastShutterBody_%s" % flag
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	body.position = mesh.position
	add_child(body)
	_doors.append({"flag": flag, "body": body, "mesh": mesh})


## The way in, and the one piece of this build that had to be rebuilt once.
##
## The complex's floor stands above its own highest ground, which on this site
## is several metres over the meadow at the west end. `burrow_warrens.gd`'s
## apron answers the same problem with a flight of shallow STEPS, and that works
## there because its whole rise is 0.35m. Here the rise is metres, and a flight
## of steps that tall has risers a CharacterBody3D simply stops against: the
## first run of `smoke_stronghold.gd` walked 0.5m out of a 26m ramp and reported
## the entrance as unreachable. Godot's character body does no stair-stepping of
## its own, so the fix is not more steps -- it is an actual INCLINE.
##
## So: one long slab, tilted to the real gradient, with a matching rotated
## collider. Sampled at both ends (the floor here, whatever the terrain actually
## is `ramp_run` metres out) so it meets the meadow wherever the site is retuned
## to, and the slope is reported at build time because a ramp steeper than the
## player's floor-max-angle is a wall wearing a ramp's shape.
func _build_approach_ramp() -> void:
	var first: String = _order[0]
	var width := float(_first_passage().get("width", 4.0)) + 3.0
	var outer_z := _mouth_outer_z()
	var run := maxf(4.0, float(_config.get("site", {}).get("ramp_run", 26.0)))
	var lateral := _local_of((_chambers[first] as Dictionary).get("at", [])).x
	var end_local := _floor_y - 1.0
	if _world != null and _world.has_method("ground_height_at"):
		var far := to_global(Vector3(lateral, 0.0, outer_z - run))
		var height: float = float(_world.call("ground_height_at", far.x, far.z))
		if not is_nan(height):
			end_local = height - global_position.y

	var rise := _floor_y - end_local
	var angle := atan2(rise, run)
	var length := sqrt(run * run + rise * rise) + 3.0   # overlap the floor slab at the top
	var thickness := 4.0
	var top_mid := Vector3(lateral, (_floor_y + end_local) * 0.5, outer_z - run * 0.5)
	# The slab's own up vector once tilted, so the WALKING SURFACE passes through
	# both sampled ends rather than the slab's centreline.
	var up := Vector3(0.0, cos(angle), -sin(angle))
	var mesh := MeshInstance3D.new()
	mesh.name = "ApproachRamp"
	var box := BoxMesh.new()
	box.size = Vector3(width, thickness, length)
	mesh.mesh = box
	mesh.material_override = _floor_material()
	mesh.position = top_mid - up * (thickness * 0.5)
	mesh.rotation.x = -angle
	add_child(mesh)

	var body := StaticBody3D.new()
	body.name = "ApproachRampBody"
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box.size
	shape.shape = box_shape
	body.add_child(shape)
	body.position = mesh.position
	body.rotation.x = mesh.rotation.x
	add_child(body)

	_markers["ramp_foot"] = to_global(Vector3(lateral, end_local, outer_z - run))
	if rad_to_deg(angle) > 40.0:
		push_warning("the stronghold's approach ramp climbs at %.0f degrees; that is a wall, not a way in" % [
			rad_to_deg(angle)])
	print("[stronghold] approach ramp: %.1fm of rise over %.0fm (%.0f degrees)" % [
		rise, run, rad_to_deg(angle)])


## --- the industrial layer ---------------------------------------------------

func _build_trim() -> void:
	for entry: Variant in _config.get("trim", []):
		var spec: Dictionary = entry as Dictionary
		var id := str(spec.get("chamber", ""))
		if not _chambers.has(id):
			continue
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		var height := float(chamber.get("height", 6.0))
		var material := _live_material() if bool(spec.get("lit", false)) else _tether_material()

		match str(spec.get("kind", "band")):
			"band":
				var side := str(spec.get("side", "+x"))
				var along_x := side == "-z" or side == "+z"
				var sign_ := -1.0 if side.begins_with("-") else 1.0
				var y := minf(float(spec.get("y", height * 0.6)), height - 0.5)
				var at := centre
				if along_x:
					at.z += sign_ * (size.y * 0.5 - 0.35)
				else:
					at.x += sign_ * (size.x * 0.5 - 0.35)
				var band := Vector3(size.x, 0.5, 0.6) if along_x else Vector3(0.6, 0.5, size.y)
				# Decoration: never solid. A girder with a collider is a ledge
				# the player can stand on halfway up a wall.
				_box(band, Vector3(at.x, _floor_y + y, at.z), material, false)
			"pillar":
				var offset := _local_of(spec.get("offset", [0.0, 0.0]))
				_box(Vector3(0.7, height, 0.7),
					Vector3(centre.x + offset.x, _floor_y + height * 0.5, centre.z + offset.z),
					material, true)
			_:
				push_warning("stronghold.json trim has an unknown kind '%s'" % str(spec.get("kind", "")))


## --- exterior dressing (T1-ARCH) ---------------------------------------------

## The texture-scale collision half of the judge's finding: a thin decorative
## skin flush against every TRUE exterior wall face (`_wall_rects` for a side
## `_opening_on` calls empty, i.e. no passage cut through it -- the entrance
## counts too, its two flank pieces ARE true exterior wall), at a finer tile
## than the shared `_wall_material(true)` every chamber wall wears. See this
## file's `EXTERIOR_FACE_TILE_MULT` for why this is a skin and not a retune
## of that shared material.
func _build_exterior_facing() -> void:
	for id in EXTERIOR_CHAMBERS:
		if not _chambers.has(id):
			continue
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		var height := float(chamber.get("height", 6.0))
		var sides := ["-x", "+x", "-z"] if id == _order[0] else ["-x", "+x"]
		for side in sides:
			var opening := _opening_on(id, side)
			for rect: Dictionary in _wall_rects(centre, size, height, side, opening):
				_face_rect(rect)


func _exterior_face_material() -> StandardMaterial3D:
	var key := "exterior_face_stone"
	if _materials.has(key):
		return _materials[key]
	var m: StandardMaterial3D = _material(_stone_light(), 0.0, true).duplicate() as StandardMaterial3D
	m.uv1_scale = Vector3.ONE * (STONE_TILE * EXTERIOR_FACE_TILE_MULT)
	_materials[key] = m
	return m


func _face_rect(rect: Dictionary) -> void:
	var along_x: bool = rect["along_x"]
	var at: Vector3 = rect["at"]
	var span: float = rect["span"]
	var ht: float = rect["height"]
	var base: float = rect["base"]
	var sign_: float = rect["sign"]
	if span <= 0.05 or ht <= 0.05:
		return
	var facing_at := at
	var size: Vector3
	if along_x:
		facing_at.z += sign_ * (_wall_t * 0.5 + EXTERIOR_FACE_SKIN * 0.5)
		size = Vector3(span, ht, EXTERIOR_FACE_SKIN)
	else:
		facing_at.x += sign_ * (_wall_t * 0.5 + EXTERIOR_FACE_SKIN * 0.5)
		size = Vector3(EXTERIOR_FACE_SKIN, ht, span)
	facing_at.y = _floor_y + base + ht * 0.5
	_box(size, facing_at, _exterior_face_material(), false)


## The occupation half: hardware, banners and a broken roofline on the two
## FLANK faces (`-x`/`+x`) of each open yard -- the walls a player crossing
## the meadow actually sees, and the ones `_build_trim()` above has never
## reached because its bands and pillars mount 0.35m onto a wall's INNER
## face. `hardware` is false for the gate face's own flank pieces (dressed by
## `_build_gate_frame()` instead, which wants the coping/roofline read without
## competing with the jambs it plants right where a girder would land).
func _build_exterior_dressing() -> void:
	for id in EXTERIOR_CHAMBERS:
		if not _chambers.has(id):
			continue
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		var height := float(chamber.get("height", 6.0))
		for side in ["-x", "+x"]:
			if not _opening_on(id, side).is_empty():
				continue
			_dress_exterior_wall(centre, size, height, side, true)


## T1-HALL (2026-08-30). Design acceptance item 6: "continuous parapet line".
## `_build_exterior_dressing()` above only ever reached the two OPEN yards'
## flank walls; the three roofed keep chambers behind them (the ones the
## judge's "no roofline articulation beyond one step" and "one flat
## roofline" verdicts are actually about) never got a coping/merlon pass at
## all. `_dress_exterior_wall(..., hardware: false)` already handles any
## side safely with no opening cut through it (`_build_gate_frame()` proves
## this calling it on a "-z" face); this just widens the same call to every
## side of every keep chamber, skipping only what `_build_exterior_dressing`/
## `_build_gate_frame` already dress (outer_works' -x/+x/-z, courtyard's
## -x/+x) so nothing doubles a coping box onto itself. `hardware` stays false
## here -- the occupation layer's girders/banners concentrate on the gate
## and the cable landing (`_build_hall_massing()`), not on every keep wall.
const KEEP_CHAMBERS: Array[String] = ["tether_approach", "warden_arena", "legendary_chamber"]
func _build_keep_parapets() -> void:
	for id in KEEP_CHAMBERS:
		if not _chambers.has(id):
			continue
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		var height := float(chamber.get("height", 6.0))
		for side in ["-x", "+x", "-z", "+z"]:
			_dress_exterior_wall(centre, size, height, side, false)


## `along_x`-general for the coping/merlon roofline pass, which
## `_build_gate_frame()` also calls (with `side: "-z"`) to close the roofline
## over the gate face's own flank pieces. `hardware` is only ever true for a
## `-x`/`+x` call (`_build_exterior_dressing()`'s own loop), so that section
## stays written in this function's ORIGINAL x-only terms deliberately --
## generalising code that never runs the other way would just be more
## surface for a mistake to hide in.
func _dress_exterior_wall(centre: Vector3, size: Vector2, height: float, side: String,
		hardware: bool) -> void:
	var along_x := side == "-z" or side == "+z"
	var span := (size.x if along_x else size.y) + _wall_t * 2.0
	var offset := (size.y if along_x else size.x) * 0.5 + _wall_t * 0.5
	var sign_ := -1.0 if side.begins_with("-") else 1.0
	var wall_centre := centre
	if along_x:
		wall_centre.z += sign_ * offset
	else:
		wall_centre.x += sign_ * offset
	var wall_centre_x := wall_centre.x
	var face_x := wall_centre_x + sign_ * (_wall_t * 0.5)
	var wall_top := _floor_y + height + 1.4

	# Coping, and a broken merlon row on top of it -- the roofline the judge
	# asked for a second step of, past the one `_build_wall`'s parapet lip
	# already gives.
	var coping_size := Vector3(span, COPING_H, _wall_t + COPING_PROUD * 2.0) if along_x \
		else Vector3(_wall_t + COPING_PROUD * 2.0, COPING_H, span)
	_box(coping_size, Vector3(wall_centre.x, wall_top + COPING_H * 0.5, wall_centre.z),
		_material(_stone_dark(), 0.0, true), false)
	var count := maxi(1, int(floor(span / (MERLON_W + MERLON_GAP))))
	var start := -float(count - 1) * 0.5 * (MERLON_W + MERLON_GAP)
	for i in count:
		var d := start + float(i) * (MERLON_W + MERLON_GAP)
		var merlon_size := Vector3(MERLON_W, MERLON_H, _wall_t * 0.8) if along_x \
			else Vector3(_wall_t * 0.8, MERLON_H, MERLON_W)
		var merlon_at := Vector3(wall_centre.x + d, wall_top + COPING_H + MERLON_H * 0.5, wall_centre.z) \
			if along_x else Vector3(wall_centre.x, wall_top + COPING_H + MERLON_H * 0.5, wall_centre.z + d)
		_box(merlon_size, merlon_at, _material(_stone_light(), 0.0, true), false)

	if not hardware:
		return

	# Team Tether hardware, bolted proud of the OUTER face this time -- the
	# same faction paint `_build_trim()` already wears, in the one place a
	# player approaching from the meadow can actually see it. Only ever
	# reached for `-x`/`+x` (see this function's own header), so `centre.z`/
	# `face_x` are the right axis pair without checking `along_x` again.
	var girder_y := minf(height * 0.55, height - 1.0)
	_box(Vector3(0.5, 0.5, span * 0.62), Vector3(face_x + sign_ * 0.35, _floor_y + girder_y, centre.z),
		_tether_material(), false)
	for f in [-0.30, 0.30]:
		_box(Vector3(0.6, height, 0.6),
			Vector3(face_x + sign_ * 0.35, _floor_y + height * 0.5, centre.z + f * span * 0.5),
			_tether_material(), false)
	# A live conduit climbing to the parapet -- "the deeper you go the more of
	# the room is machine" (`_comment_language`), now readable from outside.
	_box(Vector3(0.3, height * 0.85, 0.3),
		Vector3(face_x + sign_ * 0.35, _floor_y + height * 0.42, centre.z), _live_material(), false)

	for f2 in [-0.22, 0.22]:
		_hang_banner(Vector3(face_x, _floor_y + height * 0.6, centre.z + f2 * span),
			0.0 if sign_ > 0.0 else PI)


## `yaw_rad` rotates the model's local +X onto the direction the mount should
## project. Read directly off `Banner.obj`'s own vertex data rather than
## assumed: it is a wall-bracket flagpole, a short vertical post near local
## origin (x~0) with a horizontal arm reaching to x=0.673 that carries the
## flag at its TIP -- so this asset's "forward" is +X, not Godot's usual -Z,
## and a caller wants local +X pointing along the wall's own OUTWARD NORMAL
## so the pole projects away from the stone rather than lying flat along it.
## `Vector3(1,0,0).rotated(UP, yaw_rad) == (cos(yaw_rad), 0, -sin(yaw_rad))`:
## `0` points +X (an east wall's own outward normal), `PI` points -X (west),
## `PI/2` points -Z (south, the gate).
func _hang_banner(at: Vector3, yaw_rad: float, colour: Color = BANNER_COLOUR, scale: float = BANNER_SCALE) -> void:
	if not ResourceLoader.exists(BANNER_MODEL):
		return
	var mesh: Mesh = load(BANNER_MODEL) as Mesh
	if mesh == null:
		return
	var instance := MeshInstance3D.new()
	instance.name = "ExteriorBanner"
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.9
	instance.material_override = material
	instance.scale = Vector3.ONE * scale
	instance.position = at
	instance.rotation.y = yaw_rad
	add_child(instance)


## Design §6.2's one invented story beat: a single faded Meadows-blue banner,
## torn, half-height, under a fresh oxblood one -- the seizure, read in one
## glance, at zero new asset cost (the same `Banner.obj` every other banner
## in this file already uses, just re-tinted and stood shorter). Placed on
## the west bailey wall (`outer_works`' own `-x` flank), where a player
## walking the approach sees it beside the ordinary oxblood rhythm
## `_dress_exterior_wall`'s hardware section already hangs there.
const BLUE_RELIC_COLOUR := Color("#3d4a63")
func _build_blue_relic_banner() -> void:
	var ow: Dictionary = _chambers.get("outer_works", {})
	if ow.is_empty():
		return
	var centre := _local_of(ow.get("at", []))
	var half := _size_of(ow.get("size", [])) * 0.5
	var face_x := centre.x - (half.x + _wall_t * 0.5)
	_hang_banner(Vector3(face_x, _floor_y + 3.2, centre.z), PI, BLUE_RELIC_COLOUR, BANNER_SCALE * 0.65)


## The gate: "a plain rectangular hole with no gatehouse, frame, reveal or
## depth" per the judge. Proud jambs either side of the entrance plus a
## lintel bridging them turn that hole into an actual doorway with a real
## shadow line, and a banner on each jamb claims the one spot in the complex
## every player is guaranteed to look at. Coping/merlons on the two flank
## pieces beside it (`hardware: false`) close the roofline the same way the
## flanks get it, without a girder run competing with the jambs.
func _build_gate_frame() -> void:
	if _order.is_empty():
		return
	var first: String = _order[0]
	var chamber: Dictionary = _chambers[first]
	var centre := _local_of(chamber.get("at", []))
	var size := _size_of(chamber.get("size", []))
	var height := float(chamber.get("height", 6.0))
	_dress_exterior_wall(centre, size, height, "-z", false)

	var opening := _opening_on(first, "-z")
	if opening.is_empty():
		return
	var lateral := centre.x
	var width: float = float(opening.get("width", 4.0))
	var op_height: float = float(opening.get("height", 4.5))
	var outer_face_z := _mouth_outer_z() - _wall_t
	var jamb_w := 0.9
	var jamb_proud := 1.0
	var jamb_h := op_height + 0.6
	var jamb_z := outer_face_z + _wall_t * 0.5 - jamb_proud * 0.5
	for s in [-1.0, 1.0]:
		_box(Vector3(jamb_w, jamb_h, _wall_t + jamb_proud),
			Vector3(lateral + s * (width * 0.5 + jamb_w * 0.5), _floor_y + jamb_h * 0.5, jamb_z),
			_material(_stone_dark(), 0.0, true), false)
	_box(Vector3(width + jamb_w * 2.0, 0.6, jamb_proud + _wall_t),
		Vector3(lateral, _floor_y + jamb_h + 0.3, jamb_z),
		_material(_stone_dark(), 0.0, true), false)
	for s2 in [-1.0, 1.0]:
		_hang_banner(Vector3(lateral + s2 * (width * 0.5 + jamb_w + 0.35), _floor_y + op_height * 0.7,
			outer_face_z), PI * 0.5)


## T1-HALL (2026-08-30). HALL_DESIGN_2026-08-30.md §4/§9 step 2: the castle
## kit's own massing, standing on the works instead of 154m away as a second
## building (`landmark.gd`'s castle, which retires once this lands --
## `playground_world.gd` stops calling it). `meadows_hall`
## (`building_prefabs.json`) is authored in the SAME local frame this file's
## own chambers are (x=lateral, z=depth), derived from their real `at`/`size`
## values rather than guessed, so it adds as one child at local
## `(0, _floor_y, 0)` -- no rotation, no per-piece transform math here, the
## same `add_child` composition every other placement in this file already
## relies on. Gatehouse flankers, bailey corner and mid-wall towers (real
## girth this time -- the direct fix for the judge's "sandcastle decoration"
## finding on the retiring castle's own skinny mid-wall towers), the great
## tower over the legendary chamber, and the tether_approach roof. The waist
## wall closes the one real gap in the flank silhouette this kit pass alone
## cannot reach (`_build_hall_waist()` below); openings are `_build_hall_slits()`.
const HALL_PREFAB := "meadows_hall"
var _hall_prefabs: RefCounted = null


func _build_hall_massing() -> void:
	_hall_prefabs = PREFABS.new()
	if not _hall_prefabs.call("load_recipes"):
		push_error("no building recipes; the Hall's massing cannot stand")
		return
	var template_holder := Node3D.new()
	template_holder.name = "HallPrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	_hall_prefabs.call("set_template_holder", template_holder)

	var massing: Node3D = _hall_prefabs.call("instantiate", HALL_PREFAB)
	if massing == null:
		push_error("meadows_hall prefab missing: %s" % HALL_PREFAB)
		return
	massing.name = "HallMassing"
	massing.position = Vector3(0.0, _floor_y, 0.0)
	add_child(massing)
	_weather_hall_massing(massing)
	_build_hall_waist()
	_build_hall_slits()
	_build_cable_landing()
	_build_blue_relic_banner()


## The SAME technique `landmark.gd::_weather_castle` uses on the same kit, for
## the same reason: the castle kit's stone surfaces ship with zero UVs (a
## direct probe of `WallBricks.obj` found 0 `vt` lines), so triplanar is the
## only mapping this geometry supports, and `T_UnevenBrick` at the works' own
## measured `STONE_TILE` = 0.28 is "one stone, one scale, one value ladder,
## both kits" (design §5) rather than a second texture re-picked for this
## pass. `building_prefabs.gd::_apply_retint` already set the flat colours;
## this mutates the SAME material instances (safe: `_hall_prefabs` above is a
## composer local to this one massing pass, shared by no other prefab) to
## carry the real stone photo under them.
const HALL_WEATHER_MATERIALS := [
	"LightRock", "LightRock.001", "LightRock.002",
	"DarkRock", "DarkRock.001",
]
func _weather_hall_massing(massing: Node3D) -> void:
	var done: Dictionary = {}
	for mi in _weather_hall_mesh_instances(massing):
		if mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(surface)
			if mat == null or not mat is StandardMaterial3D:
				continue
			var std := mat as StandardMaterial3D
			if not HALL_WEATHER_MATERIALS.has(std.resource_name):
				continue
			if done.has(std.get_instance_id()):
				continue
			done[std.get_instance_id()] = true
			std.albedo_texture = STONE_ALBEDO
			std.normal_enabled = true
			std.normal_texture = STONE_NORMAL
			std.roughness_texture = STONE_ROUGHNESS
			std.uv1_triplanar = true
			std.uv1_scale = Vector3.ONE * STONE_TILE
			std.roughness = maxf(std.roughness, 0.92)


func _weather_hall_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_weather_hall_mesh_instances(child))
	return found


## The waist: the real gap in the flank silhouette between `courtyard`'s back
## wall and `tether_approach`'s front wall (their own wall footprints do not
## touch -- design §4's "wrap with ONE course of TallWallBricks so bailey and
## keep read as one building"). Built directly, the same way every other
## chamber wall in this file is (`_wall_material`/`_box`), rather than as
## more kit modules: it is a short, flat infill panel, not an accented piece,
## and this file already owns the exact masonry material the panel needs to
## match.
func _build_hall_waist() -> void:
	var courtyard: Dictionary = _chambers.get("courtyard", {})
	var tether: Dictionary = _chambers.get("tether_approach", {})
	if courtyard.is_empty() or tether.is_empty():
		return
	var cy_z1: float = _local_of(courtyard.get("at", [])).z + _size_of(courtyard.get("size", [])).y * 0.5 + _wall_t
	var ta_z0: float = _local_of(tether.get("at", [])).z - _size_of(tether.get("size", [])).y * 0.5 - _wall_t
	if ta_z0 <= cy_z1:
		return
	var mid := (cy_z1 + ta_z0) * 0.5
	var length := ta_z0 - cy_z1
	var height := (float(courtyard.get("height", 9.0)) + float(tether.get("height", 6.5))) * 0.5
	var cy_half_x: float = _size_of(courtyard.get("size", [])).x * 0.5 + _wall_t
	var ta_half_x: float = _size_of(tether.get("size", [])).x * 0.5 + _wall_t
	for s in [-1.0, 1.0]:
		var wall_x: float = (cy_half_x + ta_half_x) * 0.5 * float(s)
		_box(Vector3(_wall_t, height + _skirt, length),
			Vector3(wall_x, _floor_y + height * 0.5 - _skirt * 0.5, mid),
			_wall_material(true), false)


## The "no arrow slits along entire wall runs" fix (design §4). Recessed dark
## boxes at upper-course height along the two open yards' true flank walls --
## the same `_box(..., false)` decoration-only technique every trim/hardware
## piece in this file already uses, so a slit can never become a ledge or a
## collider a fight snags on. Only the two yards: the three roofed keep
## chambers behind them are never seen from the meadow at this range, and
## `interior_structure.gd`'s own `reveals` pass already gives THEM a window
## grammar from the inside.
const SLIT_SPACING := 8.0
const SLIT_SIZE := Vector3(0.4, 1.8, 0.35)
func _build_hall_slits() -> void:
	for id in EXTERIOR_CHAMBERS:
		if not _chambers.has(id):
			continue
		var chamber: Dictionary = _chambers[id]
		var centre := _local_of(chamber.get("at", []))
		var size := _size_of(chamber.get("size", []))
		var height := float(chamber.get("height", 6.0))
		for side in ["-x", "+x"]:
			if not _opening_on(id, side).is_empty():
				continue
			_slit_row(centre, size, height, side)


func _slit_row(centre: Vector3, size: Vector2, height: float, side: String) -> void:
	var sign_ := -1.0 if side.begins_with("-") else 1.0
	var face_x := centre.x + sign_ * (size.x * 0.5 + _wall_t * 0.5 + SLIT_SIZE.x * 0.5 - 0.05)
	var span := size.y
	var count := maxi(1, int(floor(span / SLIT_SPACING)))
	var start := centre.z - float(count - 1) * 0.5 * SLIT_SPACING
	var slit_y := _floor_y + height * 0.72
	var slit_material := _material(_stone_dark(), 0.0, false)
	for i in count:
		var z := start + float(i) * SLIT_SPACING
		_box(SLIT_SIZE, Vector3(face_x, slit_y, z), slit_material, false)


## Design §6.1: "the single highest-value occupation object... the moment
## the judge's praised pylons and the condemned building become one
## system." One `severed_spokes.gd`-style conduit span from the last
## approach pylon's own head to a brass anchor on the north-west bailey
## tower (`meadows_hall`'s own gatehouse-adjacent corner tower, the same
## corner `_build_hall_massing()`'s generator sited at the outer_works'
## own NW wall corner). `severed_spokes.gd::_conduit_span` is reused rather
## than re-implemented, the same way `_build_approach_conduits()` above
## already reuses `_build_pylons` wholesale -- a throwaway instance, freed
## the moment this function returns, exactly like `_load_palette()`'s.
##
## Parented to the WORLD: both ends are real world coordinates (the pylon's
## own siting, and this node's own `to_global` of the tower corner), and a
## sagging cable is drawn as a chain of world-space cylinder segments, not
## as chamber-local geometry.
func _build_cable_landing() -> void:
	if _world == null:
		return
	var config: Dictionary = _config.get("approach_pylons", {})
	var list: Array = config.get("list", [])
	if list.is_empty():
		return
	var last: Dictionary = list[list.size() - 1] as Dictionary
	var last_at: Array = last.get("at", [])
	if last_at.size() < 2:
		return
	var pylon_x := float(last_at[0])
	var pylon_z := float(last_at[1])
	var pylon_height := float(config.get("height", 12.0))
	var pylon_ground: float = float(_world.call("ground_height_at", pylon_x, pylon_z))
	if is_nan(pylon_ground):
		return
	# CONDUIT_ATTACH (0.66) matches severed_spokes.gd's own pylon-head
	# attachment fraction, so this span leaves the pylon at the same point
	# its own conduit run does, not a seam a player can see from the trail.
	var pylon_head := Vector3(pylon_x, pylon_ground + pylon_height * 0.66, pylon_z)

	# The NW bailey tower corner, in this node's own local frame -- the same
	# point `tools/_gen_meadows_hall.py`'s generator sited the tower at
	# (outer_works' own wall corner), nudged 1m proud on both faces so the
	# anchor sits on the tower's own stone rather than buried inside it.
	var ow: Dictionary = _chambers.get("outer_works", {})
	if ow.is_empty():
		return
	var ow_half := _size_of(ow.get("size", [])) * 0.5
	var corner_local := Vector3(-(ow_half.x + _wall_t) - 1.0, 12.0, -(ow_half.y + _wall_t) - 1.0)
	var anchor := to_global(corner_local)

	# A brass-and-oxblood bracket at the anchor -- the fitting the cable
	# actually terminates on, not a cable ending in mid-air against stone.
	var bracket_mat := StandardMaterial3D.new()
	bracket_mat.albedo_color = Color("#8a6f3a")
	bracket_mat.metallic = 0.55
	bracket_mat.roughness = 0.45
	var bracket := MeshInstance3D.new()
	bracket.name = "CableAnchorBracket"
	var bracket_box := BoxMesh.new()
	bracket_box.size = Vector3(0.5, 0.35, 0.5)
	bracket_box.material = bracket_mat
	bracket.mesh = bracket_box
	bracket.position = corner_local
	add_child(bracket)

	var builder := Node3D.new()
	builder.name = "HallCableLanding"
	_world.add_child(builder)
	var spokes: Node3D = SEVERED_SPOKES.new()
	spokes.call("_conduit_span", builder, 0, pylon_head, anchor, _live_material(), 1.0)
	spokes.free()


## CONTENT-0828B. The shared constructed-interior method, in the fortress's own
## vocabulary.
##
## `_build_trim()` above is NOT this and is deliberately left alone: its bands
## and pillars are Team Tether HARDWARE bolted onto the stone, authored one
## entry at a time in oxblood and teal, and they say who occupies the building.
## They were never architecture, and 21 hand-placed faction girders cannot give
## a 28-metre hall a scale reference -- which is what the owner was looking at
## when he called this one of the two lame locations.
##
## This building's vocabulary is `jitter: 0` -- masonry is regular, and the
## members have to land on their pitch exactly or the rhythm reads as an
## accident -- and the castle's own three stone values for the roles, so the
## works stay the same palette the curtain wall and the plinth already use
## (D24: one village family) rather than introducing a fourth stone.
##
## The `legendary_chamber` is the room this matters most in and the reason the
## pass is worth its nodes: 28x28 metres and 22 metres tall, lit by two
## shadowless omnis, with a single object in the middle of it. Before this it
## had nothing at all between the machine and the walls for the eye to measure
## the room against, so the largest interior in the chapter read as the
## smallest kind of space there is -- a box.
func _build_structure() -> void:
	var cfg: Dictionary = _config.get("interior_structure", {})
	if cfg.is_empty():
		return
	var chambers: Array = []
	for id: String in _chambers:
		var chamber: Dictionary = _chambers[id]
		chambers.append({
			"id": id, "centre": _local_of(chamber.get("at", [])),
			"size": _size_of(chamber.get("size", [])),
			"height": float(chamber.get("height", 6.0)),
			# A yard has no ceiling to rib, and `interior_structure.gd` reads
			# this to skip that one pass. The bays, course and corners still
			# run: the outer works and the courtyard are walled spaces and
			# their walls are as flat as any interior one.
			"open": bool(chamber.get("open", false)),
		})
	var placed: int = INTERIOR_STRUCTURE.new().dress(self, {
		"chambers": chambers, "doorways": _doorways, "openings": _openings,
		"floor_y": _floor_y, "config": cfg,
		"material_for": func(role: String) -> StandardMaterial3D:
			return _material(_structure_colour(role), 0.0, true),
	})
	if placed > 0:
		print("[stronghold] %d structural members across %d spaces" % [placed, _chambers.size()])


## One of the castle's own three stone values per role, so a member reads as
## built out of the same fortress rather than as a decal on it. Tunable from
## `interior_structure.tints`.
##
## The steps are deliberate and they are doing the job light cannot: every
## interior light in this building sets `shadow_enabled = false`
## (`_build_lights`, a Compatibility-renderer cost decision this pass does not
## reopen), so a shaft standing proud of a wall is lit almost identically to
## the wall behind it. If the value does not separate them, nothing will.
func _structure_colour(role: String) -> Color:
	var tints: Dictionary = _config.get("interior_structure", {}).get("tints", {})
	if tints.has(role):
		return Color(str(tints[role]))
	# ONE VALUE FOR EVERY MEMBER: structure is a lighter stone than the infill
	# it stands against. Round 1 returned `_stone()` for shafts and corners --
	# the same value `_wall_material(false)` gives the wall behind them -- and
	# `C1`/`C2` came back with walls that had no members in them at all.
	#
	# Round 2 then put the course and the ribs at `_stone_dark()`, and `C4`
	# says why that is wrong: in the courtyard, under the real sun, a near-black
	# horizontal band on a curtain wall reads as an ARROW SLIT. A dark band is
	# only a recess when something casts a shadow into it, and nothing in this
	# building does (`_build_lights` sets `shadow_enabled = false` on every
	# omni, deliberately). Dressed stone standing proud reads correctly in both
	# the dark inner rooms and the daylit yards, so that is what all of it is.
	#
	# The ribs go light here for the reason they go DARK in the Warrens: a rib
	# is read against its own ceiling, and this building's ceilings are now the
	# darkened stone `_build_chambers()` gives them, where the cave's are pale
	# rock. Same rule, opposite answer, and that is what a per-consumer role
	# map is for.
	return _stone_light().lightened(0.22)


## Lit cable runs along the floor between chambers, all of them pointing at the
## Legendary Chamber. Decoration only -- no collider, ever: these cross
## doorways, and a doorway with a kerb in it is a doorway the player catches on.
func _build_conduits() -> void:
	for entry: Variant in _config.get("conduits", []):
		var spec: Dictionary = entry as Dictionary
		var from := str(spec.get("from", ""))
		var to := str(spec.get("to", ""))
		if not _chambers.has(from) or not _chambers.has(to):
			continue
		var a := _local_of((_chambers[from] as Dictionary).get("at", []))
		var b := _local_of((_chambers[to] as Dictionary).get("at", []))
		var offset := float(spec.get("offset", 0.0))
		var along_x := absf(b.x - a.x) >= absf(b.z - a.z)
		var mid := (a + b) * 0.5
		var length := absf(b.x - a.x) if along_x else absf(b.z - a.z)
		var size := Vector3(length, 0.16, 0.34) if along_x else Vector3(0.34, 0.16, length)
		if along_x:
			mid.z += offset
		else:
			mid.x += offset
		_box(size, Vector3(mid.x, _floor_y + 0.08, mid.z), _live_material(), false)


func _build_lights() -> void:
	# T1-ARCH-STRONGHOLD: `lights_flanks` is the gate-face fire+sky-fill recipe
	# (`lights` above) re-aimed at the two `-x`/`+x` walls it never reached --
	# kept as its own config array (see `_comment_lights_flanks`) rather than
	# spliced into `lights` by hand, so a future diff on either block stays
	# readable.
	for entry: Variant in _config.get("lights", []) + _config.get("lights_flanks", []):
		var spec: Dictionary = entry as Dictionary
		var at := _local_of(spec.get("at", []))
		var light := OmniLight3D.new()
		light.position = Vector3(at.x, _floor_y + float(spec.get("y", 5.0)), at.z)
		light.light_color = Color(str(spec.get("colour", "#8a8a8a")))
		light.light_energy = float(spec.get("energy", 0.5))
		light.omni_range = float(spec.get("range", 14.0))
		light.shadow_enabled = false
		add_child(light)


## The camera swap, over the whole footprint -- the same Area3D grandpa_house.gd
## and burrow_warrens.gd both use, handed back on exit.
func _build_interior_area() -> void:
	if _footprint.is_empty():
		return
	var min_x := INF
	var min_z := INF
	var max_x := -INF
	var max_z := -INF
	for rect: Array in _footprint:
		min_x = minf(min_x, float(rect[0]))
		min_z = minf(min_z, float(rect[1]))
		max_x = maxf(max_x, float(rect[2]))
		max_z = maxf(max_z, float(rect[3]))
	var area := Area3D.new()
	area.name = "Interior"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(max_x - min_x, 26.0, max_z - min_z)
	shape.shape = box
	area.add_child(shape)
	area.position = Vector3((min_x + max_x) * 0.5, _floor_y + 13.0, (min_z + max_z) * 0.5)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	add_child(area)


## OP23-02 (owner playtest 2026-08-23): "teleported to the stronghold, battle
## start takes the camera, can't see." This Area3D's `body_entered`/
## `body_exited` used to hand the rig back to the player UNCONDITIONALLY --
## with no regard for whether `CombatManager` had just taken it for a fight
## (`combat_manager.gd::_take_camera()`). The two events are not
## synchronized: nothing stops the whole-building overlap notification from
## landing the same window a gauntlet trainer's challenge closes, and
## `outer_works`' trainer sits close enough to the entrance that a player
## crossing the threshold and starting that fight in the same beat is an
## ordinary way to play, not an edge case. When that race lands, this handler
## fires AFTER `_take_camera()` and silently reassigns the rig to the player
## body, mid-fight -- exactly "battle start takes the camera, can't see."
## Guarded the same way `_arena_bounds()` already asks a room for state: a
## fight owns the camera for its own duration, this Area3D only otherwise.
func _combat_owns_the_camera() -> bool:
	var manager: Node = _world.get_node_or_null(^"CombatManager") if _world != null else null
	return manager != null and manager.has_method("is_fighting") and bool(manager.call("is_fighting"))


func _on_body_entered(body: Node3D) -> void:
	if body != _player or _camera_rig == null or _combat_owns_the_camera():
		return
	_camera_rig.call("set_target", _player, INTERIOR_PROFILE)


func _on_body_exited(body: Node3D) -> void:
	if body != _player or _camera_rig == null or _combat_owns_the_camera():
		return
	_camera_rig.call("set_target", _player, {})


## --- the centrepiece --------------------------------------------------------

## THE TETHER MACHINE. Read this file's header before touching it. The licensed
## hero mesh is installed (D49); the massing below is the fallback path, kept
## because it still runs whenever `machine.model` is unset or missing, and
## because it is the record of the scale the chamber was designed around.
##
## What stands here is deliberately, visibly primitive: a stepped base, a ring
## of upright containment pillars with a lit collar, a tapering core column and
## a light inside it. It is sized off the board's own 0-20m scale bar (~15m
## tall, containment ring a little under half that across) so the room around it
## is honestly proportioned and does not have to be rebuilt when the mesh lands.
## The player-blocking collision is the BASE only -- the ring and the core are
## decoration, so a later freeing sequence can play inside the ring without
## fighting a collider that was never part of the design.
##
## NOTHING HERE IS A CREATURE. The board draws a legendary bound in the ring;
## the board licenses the machine, not its occupant, and §20/D23 forbid a new
## creature mesh outright. R8.4 places an existing roster body or a VFX there.
func _build_machine() -> void:
	var spec: Dictionary = _config.get("machine", {})
	if spec.is_empty():
		return
	var id := str(spec.get("chamber", ""))
	if not _chambers.has(id):
		push_warning("stronghold.json's machine names an unknown chamber '%s'" % id)
		return
	var centre := _local_of((_chambers[id] as Dictionary).get("at", []))
	var placeholder := bool(spec.get("placeholder", true))
	var model := str(spec.get("model", ""))

	_machine = Node3D.new()
	_machine.name = "TetherMachinePlaceholder" if placeholder else "TetherMachine"
	_machine.position = Vector3(centre.x, _floor_y, centre.z)
	add_child(_machine)

	var height := float(spec.get("height", 15.0))
	if model != "" and ResourceLoader.exists(model):
		# The seam closes here: a real mesh replaces the DECORATIVE primitives
		# below. It does NOT replace the base collider, the core light or the
		# marker — those three are contract, not decoration, and the first
		# version of this branch returned before all of them. That would have
		# shipped a 15m machine the player walks straight through, in an
		# unlit chamber, with `_markers["machine"]` missing from the dictionary
		# R8.4's freeing sequence reads its position out of. The bug could only
		# ever appear on the day the seam was actually used, which is exactly
		# the day nobody is looking at the placeholder path any more.
		var scene := load(model) as PackedScene
		if scene != null:
			var instance := scene.instantiate() as Node3D
			if instance != null:
				instance.name = "Model"
				_machine.add_child(instance)
				_fit_to_height(instance, height)
				_machine_shell(spec, height)
				_markers["machine"] = _machine.global_position
				return

	var base_r := float(spec.get("base_radius", 5.6))
	var ring_r := float(spec.get("ring_radius", 7.2))
	var pillars := maxi(3, int(spec.get("ring_pillars", 8)))
	var core_r := float(spec.get("core_radius", 1.9))
	var stone := _material(_stone())
	var tether := _tether_material()
	var live := _live_material()

	# Base: two stepped drums, solid, so the machine is a thing the player walks
	# around rather than through.
	_drum(_machine, "BasePlinth", base_r, 1.2, 0.6, stone, true)
	_drum(_machine, "BaseCollar", base_r * 0.78, 1.0, 1.7, tether, true)

	# Containment ring: uprights on a circle, a lit collar band at their tops.
	var ring_h := height * 0.62
	for i in pillars:
		var angle := TAU * float(i) / float(pillars)
		var post := MeshInstance3D.new()
		post.name = "RingPost%d" % (i + 1)
		var box := BoxMesh.new()
		box.size = Vector3(0.8, ring_h, 0.8)
		post.mesh = box
		post.material_override = tether
		post.position = Vector3(cos(angle) * ring_r, ring_h * 0.5, sin(angle) * ring_r)
		post.rotation.y = -angle
		_machine.add_child(post)
		var lamp := MeshInstance3D.new()
		lamp.name = "RingLamp%d" % (i + 1)
		var lamp_box := BoxMesh.new()
		lamp_box.size = Vector3(0.9, 0.5, 0.9)
		lamp.mesh = lamp_box
		lamp.material_override = live
		lamp.position = Vector3(cos(angle) * ring_r, ring_h, sin(angle) * ring_r)
		_machine.add_child(lamp)

	# Core: a tapering column up the middle, lit inside.
	_drum(_machine, "CoreColumn", core_r, height * 0.86, 1.5, tether, false)
	_drum(_machine, "CoreCrown", core_r * 1.5, 1.4, height * 0.86, live, false)
	var glow := OmniLight3D.new()
	glow.name = "CoreLight"
	var light_spec: Dictionary = spec.get("core_light", {})
	glow.light_color = _palette("tether_teal", Color("#3fe8c4"))
	glow.light_energy = float(light_spec.get("energy", 3.2))
	glow.omni_range = float(light_spec.get("range", 26.0))
	glow.shadow_enabled = false
	glow.position = Vector3(0.0, height * 0.55, 0.0)
	_machine.add_child(glow)

	_markers["machine"] = _machine.global_position


## Scale a generated mesh to the authored height. A Meshy GLB arrives in the
## generator's own units — roughly a unit cube, never metres — so dropping one
## in unscaled puts a 15-metre machine in the chamber at the size of a stool.
## The board's 0-20m bar is the authority for what 15m means here, and
## `stronghold.json`'s `machine.height` is where that number already lives, so
## the mesh is fitted to it rather than to a magic multiplier.
##
## Fitted by its own visual bounds, not by an exported transform: a generated
## scene's root transform is not something we control or can trust.
func _fit_to_height(instance: Node3D, height: float) -> void:
	var bounds := _visual_bounds(instance)
	if bounds.size.y <= 0.001:
		return
	var scale_to := height / bounds.size.y
	instance.scale = Vector3.ONE * scale_to
	# Sit it ON the floor: the mesh's own lowest point goes to y = 0, whatever
	# the exporter thought the origin was.
	instance.position = Vector3(
		-bounds.get_center().x * scale_to,
		-bounds.position.y * scale_to,
		-bounds.get_center().z * scale_to)


func _visual_bounds(node: Node) -> AABB:
	var total := AABB()
	var seeded := false
	for child in node.find_children("*", "VisualInstance3D", true, false):
		var visual := child as VisualInstance3D
		var box := visual.get_aabb()
		# Into the instance's own space, so a nested exporter transform counts.
		var here := (node as Node3D).global_transform.affine_inverse() \
			* visual.global_transform
		box = here * box
		total = box if not seeded else total.merge(box)
		seeded = true
	return total


## What the machine owes the room no matter who drew it: something solid to walk
## around, and the light the chamber is lit by. The primitive path builds both
## out of its own drums; the model path has no drums, so it gets them here.
func _machine_shell(spec: Dictionary, height: float) -> void:
	var base_r := float(spec.get("base_radius", 5.6))
	var body := StaticBody3D.new()
	body.name = "MachineBody"
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = base_r
	cyl.height = 2.7
	shape.shape = cyl
	body.add_child(shape)
	body.position = Vector3(0.0, 1.35, 0.0)
	_machine.add_child(body)

	var glow := OmniLight3D.new()
	glow.name = "CoreLight"
	var light_spec: Dictionary = spec.get("core_light", {})
	glow.light_color = _palette("tether_teal", Color("#3fe8c4"))
	glow.light_energy = float(light_spec.get("energy", 3.2))
	glow.omni_range = float(light_spec.get("range", 26.0))
	glow.shadow_enabled = false
	glow.position = Vector3(0.0, height * 0.55, 0.0)
	_machine.add_child(glow)


func _drum(parent: Node3D, node_name: String, radius: float, height: float, base_y: float,
		material: StandardMaterial3D, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.material_override = material
	mesh.position = Vector3(0.0, base_y + height * 0.5, 0.0)
	parent.add_child(mesh)
	if not solid:
		return
	var body := StaticBody3D.new()
	body.name = "%sBody" % node_name
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	body.add_child(shape)
	body.position = mesh.position
	parent.add_child(body)


## --- contents ---------------------------------------------------------------

## SG38's recovery opportunity: R4.8's creature bed, the object the player has
## already met at home, standing past the elite and before the Warden. Same
## object, same panel, same recovery -- reusing it is the point.
##
## It is a REAL bed (`build_real()`), so it recovers through the live path:
## `game_state.gd::_tick_creature_bed_recovery()` heals gradually per frame and
## `complete_creature_bed_rests()` pays the full-rest bonus overnight.
##
## This comment used to say "same `home_recovery.rest`, same rest XP". That was
## wrong in a way worth naming: `home_recovery.gd::rest()` is an INSTANT
## `heal_fully()`, it has no production callers anywhere in the project (its only
## callers are `tests/test_fainting.gd` and `tests/smoke_stronghold.gd`, which
## call it directly), and this file never called it. The stronghold reuses the
## bed, which is the better half of the claim -- the prose just named the wrong
## mechanism, and named a dead one.
func _build_recovery_point() -> void:
	var spec: Dictionary = _config.get("recovery", {})
	var id := str(spec.get("chamber", ""))
	if spec.is_empty() or not _chambers.has(id):
		return
	var centre := _local_of((_chambers[id] as Dictionary).get("at", []))
	var offset := _local_of(spec.get("offset", [0.0, 0.0]))
	_bed = CREATURE_BED.new()
	_bed.name = "StrongholdRestPoint"
	_bed.position = Vector3(centre.x + offset.x, _floor_y, centre.z + offset.z)
	_bed.rotation.y = deg_to_rad(float(spec.get("facing_deg", 0.0)))
	add_child(_bed)
	# GATE-E, two arguments that are both about this bed NOT being a player's.
	#
	# `player_built = false`: `build_real()` sets the chapter's
	# `creature_bed_built` objective flag, and this bed is built with the world
	# at boot -- so on a fresh save the tournament ladder's "Build a creature
	# bed" line was already complete before the player owned a hammer. Measured.
	#
	# `set_build_index`: without one this bed sat at UNASSIGNED and
	# `assign_creature()` refused every creature, so SG38's one recovery
	# opportunity before the Warden opened a panel that could not rest anything.
	# The reserved negative index is documented in creature_bed.gd -- it is in no
	# build store, so the dismantle renumbering can never move it.
	_bed.call("build_real", false)
	_bed.call("set_build_index", CREATURE_BED.AUTHORED_STRONGHOLD_REST)
	_markers["recovery"] = _bed.global_position


## SG38's gauntlet. Every fight is an ordinary trainers.json row carrying
## `placed_by: "stronghold"`; this hands `trainer_npc.gd` that group plus the
## world position each one's own room says they stand at. The Trainers node is
## a CHILD of this one, so `npc_body.gd::_ground_source` walks up and finds this
## file's `ground_height_at` -- which is what puts them on the stronghold floor
## instead of on the meadow several metres below it.
func _place_gauntlet() -> void:
	var list: Array = _config.get("gauntlet", [])
	if list.is_empty():
		return
	var positions := {}
	var facings := {}
	for entry: Variant in list:
		var spec: Dictionary = entry as Dictionary
		var id := str(spec.get("chamber", ""))
		if not _chambers.has(id):
			push_warning("stronghold.json's gauntlet names an unknown chamber '%s'" % id)
			continue
		var centre := _local_of((_chambers[id] as Dictionary).get("at", []))
		var offset := _local_of(spec.get("offset", [0.0, 0.0]))
		var at := to_global(Vector3(centre.x + offset.x, _floor_y, centre.z + offset.z))
		var trainer := str(spec.get("trainer", ""))
		positions[trainer] = Vector2(at.x, at.z)
		# T1-HALL (2026-08-30): `facing_deg` is authored in the complex's own
		# LOCAL frame (the same frame `offset`/`at` above are), but the Trainers
		# node these bodies land under is parented to the WORLD, unrotated --
		# `trainer_npc.gd::_spawn` sets `npc.rotation.y` from this value
		# directly as a WORLD angle, with no yaw composition of its own. Every
		## OTHER placement in this function goes through `to_global()`, which DOES
		## carry the site's `yaw_deg` -- position was always yaw-safe, facing was
		## not. That was invisible while `yaw_deg` stayed 90 for this content's
		## whole life (the authored facing_deg values were tuned to look right at
		## that one yaw and nobody ever changed it), and it broke silently the
		## moment T1-HALL's re-site moved `yaw_deg` 90 -> 0: `smoke_gate_e_finale`
		## started reporting the elite's and the Warden's own fights forming
		## metres under the floor, because the trainer's wrong-by-90-degrees
		## facing put the player's engagement position somewhere this room's
		## narrower footprint had never been exercised against. Adding the site's
		## own rotation composes it back, exactly the way `add_child`'s ordinary
		## parent-child rotation composition already does for free everywhere
		## else in this file (the recovery bed, every wall, every prop).
		facings[trainer] = float(spec.get("facing_deg", 0.0)) + rad_to_deg(rotation.y)
		_markers["trainer_%s" % trainer] = at

	_trainers = TRAINER_NPCS.new()
	_trainers.name = "StrongholdTrainers"
	# Parented to the WORLD, not to this node. `trainer_npc.gd::_director()`
	# finds the fight through `get_parent().get_node_or_null("EncounterDirector")`,
	# so a placer hung under any node but the world silently finds no director,
	# decides its trainers cannot be challenged, and opens their DEFEATED
	# conversation instead — a gauntlet that greets you politely and never
	# fights. Found by R8.3's agent, which hit the identical shape placing the
	# Warden and cost itself a debug cycle on it. The trainers' own world
	# positions are absolute, so where the placer hangs changes nothing else.
	var host: Node = _world if _world != null else self
	host.add_child(_trainers)
	_trainers.call("build", _player, PLACED_BY, positions, facings)

	# Same floor-vs-terrain correction the Warden needs (see
	# stronghold_climax.gd's own note): the placer grounds to the terrain
	# under a point, and inside these spaces the terrain is metres below the
	# authored floor slab. Each gauntlet trainer is lifted onto the floor of
	# the room it belongs to, which is the height its own marker already
	# carries.
	for spec: Variant in list:
		var who := str((spec as Dictionary).get("trainer", ""))
		var body: Node3D = _trainers.call("body_for", who) as Node3D
		var mark: Vector3 = _markers.get("trainer_%s" % who, Vector3.ZERO)
		if body != null and mark != Vector3.ZERO:
			body.global_position = Vector3(body.global_position.x, mark.y, body.global_position.z)


## Named spots later items ask for by name: where the Warden stands, where the
## player is stopped for his dialogue, where the reveal is delivered, the
## machine's foot, and where a freed legendary appears. Registering them here
## is what stops R8.3/SG40/R8.4 hard-coding a metre.
func _build_marks() -> void:
	for entry: Variant in _config.get("marks", []):
		var spec: Dictionary = entry as Dictionary
		var id := str(spec.get("chamber", ""))
		if not _chambers.has(id):
			push_warning("stronghold.json's marks name an unknown chamber '%s'" % id)
			continue
		var centre := _local_of((_chambers[id] as Dictionary).get("at", []))
		var offset := _local_of(spec.get("offset", [0.0, 0.0]))
		_markers[str(spec.get("id", ""))] = to_global(
			Vector3(centre.x + offset.x, _floor_y, centre.z + offset.z))


## --- the one door -----------------------------------------------------------

## Polled rather than signal-driven for the same reason burrow_warrens.gd polls
## its guardian: a trainer defeat is written to the flag store by the encounter
## director, and there is no single signal this node could listen to that covers
## a fight won now and a fight won before the last save.
func _process(_delta: float) -> void:
	if _doors.is_empty():
		return
	_sync_doors()


func _sync_doors() -> void:
	var progression := _progression()
	for entry: Variant in _doors:
		var door: Dictionary = entry as Dictionary
		var open: bool = progression != null and bool(progression.call("has", str(door["flag"])))
		var body: StaticBody3D = door["body"]
		var mesh: MeshInstance3D = door["mesh"]
		if is_instance_valid(body):
			body.process_mode = Node.PROCESS_MODE_DISABLED if open else Node.PROCESS_MODE_INHERIT
			for child in body.get_children():
				if child is CollisionShape3D:
					(child as CollisionShape3D).disabled = open
		if is_instance_valid(mesh):
			mesh.visible = not open


## Whether the way into the Warden Arena is open. False before the elite in
## front of it has been beaten.
func door_is_open(flag: String = "") -> bool:
	if _doors.is_empty():
		return true
	for entry: Variant in _doors:
		var door: Dictionary = entry as Dictionary
		if flag != "" and str(door["flag"]) != flag:
			continue
		var body: StaticBody3D = door["body"]
		if not is_instance_valid(body):
			return true
		for child in body.get_children():
			if child is CollisionShape3D:
				return (child as CollisionShape3D).disabled
	return true


## --- queries other systems use ---------------------------------------------

## The stronghold floor inside its own footprint, the meadow outside it. Same
## contract burrow_warrens.gd keeps, and the reason trainers, the creature bed
## and anything else parented here stand on the built floor.
func ground_height_at(x: float, z: float) -> float:
	var built := built_floor_height_at(x, z)
	if not is_nan(built):
		return built
	if _world != null and is_instance_valid(_world) and _world.has_method("ground_height_at"):
		return float(_world.call("ground_height_at", x, z))
	return NAN


## GATE-E. The half of `ground_height_at()` above that says "this building
## claims this spot, and its floor is here" -- NAN when it does not claim it,
## with no fall-through to the meadow.
##
## Split out rather than duplicated so the two answers can never drift apart,
## and made public because the callers that need it CANNOT reach the function
## above. `ground_height_at` is discovered by walking UP the tree
## (`creature_body._ground_height`, `combat_manager._ground_height`), and a
## trainer's deployed creature is added to the world root by
## `encounter_director._send_out_next_creature`, not under this node -- the same
## parenting `combat_manager._arena_bounds` already had to work around. So every
## body a fight places resolved the ground as the TERRAIN, and the terrain here
## is metres under the floor:
##
##   elite body y=8.56  floor y=8.56  terrain y=1.37
##   ally(75.0, 1.92, 7555.5)  foe(77.2, 2.49, 7555.5)
##
## That is a gauntlet fight held seven metres below the room it started in.
## `scripts/world/built_floor.gd` is the reader; its header carries the rest.
##
## T1-HALL (2026-08-30): the margin below grew from `_wall_t` (1.2m) alone to
## `_wall_t + FLOOR_CLAIM_MARGIN_M`. `combat_manager.gd::_place_fighters()`
## (owned by `scripts/combat/**`, not this file) can place a fight up to
## `deploy_offset + separation` (~7.6m by default) past wherever the player
## engaged from, and a multi-creature trainer battle re-places its next
## fighter from wherever the PREVIOUS one ended up, so successive rounds can
## walk a fight several more metres in the same direction -- a pre-existing
## combat-placement characteristic, not something this file's re-site
## introduced. `smoke_gate_e_finale` measured it landing a genuine 5-6m past
## the ORIGINAL 1.2m pad for `stronghold_elite` (tether_approach, the
## smallest roofed chamber) and the Warden (a multi-creature battle in
## warden_arena), and the historical example quoted above (`foe(77.2, ...)`)
## shows the same class of overflow already living in this codebase before
## this pass touched it. This function only answers "whose floor is this",
## never where a fighter may stand or how far a fight may drift -- containing
## that drift is `combat_manager.gd`'s own arena-bounds job and stays there;
## widening this margin only stops a fight that has already drifted past a
## wall from being told its floor is metres of open meadow below it.
const FLOOR_CLAIM_MARGIN_M := 10.0
func built_floor_height_at(x: float, z: float) -> float:
	var local := to_local(Vector3(x, 0.0, z))
	var margin := _wall_t + FLOOR_CLAIM_MARGIN_M
	for rect: Array in _footprint:
		if local.x >= float(rect[0]) - margin and local.x <= float(rect[2]) + margin \
				and local.z >= float(rect[1]) - margin and local.z <= float(rect[3]) + margin:
			return global_position.y + _floor_y
	return NAN


## OP21-25: the largest radius `combat_arena.gd` can draw around `(x, z)`
## without its boundary reaching a real wall -- the containment fix.
## `combat_arena.hold_inside()` corrects a fighter with a raw position write,
## not a physics move, so it has no collision to stop it: a boundary that
## reaches past this room's walls does not clip a knocked-back fighter against
## them, it teleports the fighter straight through to the far side. Sized off
## the same `_footprint` rects `ground_height_at()` above already tests
## against, so a fight can never open somewhere this file thinks has no floor.
##
## Returns -1.0 -- "no opinion, keep the caller's own default" -- when `(x, z)`
## is not inside any chamber this building knows about (a passage, mid-route
## outdoors, a bare test scene with no footprint yet). CombatManager falls
## back to `combat.json`'s flat radius in that case, same as it always did.
func combat_arena_bounds_at(x: float, z: float) -> float:
	var local := to_local(Vector3(x, 0.0, z))
	var best := -1.0
	for rect: Array in _footprint:
		if local.x < float(rect[0]) or local.x > float(rect[2]) \
				or local.z < float(rect[1]) or local.z > float(rect[3]):
			continue
		var clearance: float = minf(
			minf(local.x - float(rect[0]), float(rect[2]) - local.x),
			minf(local.z - float(rect[1]), float(rect[3]) - local.z))
		var usable := maxf(0.5, clearance - ARENA_WALL_MARGIN)
		best = usable if best < 0.0 else minf(best, usable)
	return best


## Global position of a named place: any chamber id, any `marks` id, plus
## "entrance", "recovery", "machine" and "trainer_<id>".
func marker(name_key: String) -> Vector3:
	return _markers.get(name_key, global_position)


func has_marker(name_key: String) -> bool:
	return _markers.has(name_key)


func marker_names() -> Array:
	return _markers.keys()


## The five spaces, in the order §8 names them. A test or a later item walks
## this rather than assuming ids.
func route() -> Array[String]:
	return _order.duplicate()


func chamber_ids() -> Array:
	return _chambers.keys()


## The inside dimensions of one space, in metres [lateral, depth, height].
func chamber_size(id: String) -> Vector3:
	if not _chambers.has(id):
		return Vector3.ZERO
	var size := _size_of((_chambers[id] as Dictionary).get("size", []))
	return Vector3(size.x, size.y, float((_chambers[id] as Dictionary).get("height", 0.0)))


func trainers_node() -> Node3D:
	return _trainers


func gauntlet_size() -> int:
	return int(_trainers.call("placed")) if _trainers != null else 0


## How many approach pylons stood. For tests and capture tools, so neither has
## to find them by node name -- the run hangs off the WORLD, not off this node
## (see `_build_approach_conduits`), which makes a name search the wrong shape.
func approach_pylons() -> int:
	return _approach_pylons


## The approach drained-ground skin node, or null. `meadow_healing.gd` finds it
## by duck-typing rather than through here; this is for tests and captures.
func approach_drain() -> Node3D:
	return _approach_drain


func recovery_point() -> Node3D:
	return _bed


func machine() -> Node3D:
	return _machine


## True while the centrepiece is the primitive massing rather than the licensed
## hero asset. Public so a test, a capture tool or a later art pass can assert
## on the seam instead of guessing at it.
func machine_is_placeholder() -> bool:
	return bool(_config.get("machine", {}).get("placeholder", true))


func _mouth_outer_z() -> float:
	var first: Dictionary = _chambers[_order[0]]
	return _local_of(first.get("at", [])).z - _size_of(first.get("size", [])).y * 0.5


func _progression() -> RefCounted:
	var game := get_node_or_null(^"/root/Game")
	return game.get("progression") if game != null else null
