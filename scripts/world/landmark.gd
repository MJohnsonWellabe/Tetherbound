extends Node3D

## The stronghold on the ridge -- a real assembled castle, not a shader
## silhouette.
##
## OF4-rebuild (D28, 2026-08-13): the owner rejected the procedural-primitive
## silhouette this file used to build (`SHADER_CODE`, `CylinderMesh`/
## `BoxMesh`/`PrismMesh` under one unshaded flat-fill material -- six blind
## critique rounds of tuning that geometry, recorded below and in
## `ralph/DONE.md`'s `OF4`/`OF4-visual-remainder`/`OF9`/`OF13` entries, is
## kept as history, not as the current build) and asked for the real thing:
## "then don't worry about it being a silhouette. just make it render the
## actual built castle." `BG1` (a real grid/rotate/snap placement system) and
## `BG2` (a genuine CC0 castle-parts kit, Quaternius's Modular Medieval
## Building Pack) both shipped as this task's two prerequisites.
##
## What actually builds the castle is the `castle` prefab in
## `data/config/building_prefabs.json` -- 113 hand-placed modules (curtain
## walls two courses tall on every run, a gate with its own arch-cut module,
## four corner towers of four different pieces/heights from 3.69m to a
## 6.20m stacked keep, twin gatehouse flankers, a mid-wall turret, a banner)
## assembled through the same `building_prefabs.gd` composer `EV6`'s whole
## settlement already uses -- author-time recipe, not a runtime generator.
## This file's only remaining job is siting: ground-snap at `SITE`, build a
## stone plinth that absorbs the site's own measured terrain relief, and
## instantiate the prefab on top of it. `SITE` moved once, GATE-E2
## (2026-08-23, owner directive "move the castle to the end") -- see the
## history block below for why the old `RISE_CENTRE + OFFSET` site stopped
## being correct and how the new one was derived.
##
## `building_prefabs.gd` was extended (not replaced) to load `.obj` modules
## as a bare `Mesh` alongside its existing `.gltf` scene path -- BG2's kit
## exports OBJ+MTL, the same format the Furniture/Survival props already use
## directly (`grandpa_house.gd::_furnish`), so this is one more format
## `_build_template` already had a real precedent for, not a new mechanism.
##
## Real geometry gets real (shaded) lighting instead of the old `unshaded`
## flat-fill: the whole point of composing from a real kit is that a wall
## face, a merlon and a roof cap now read as distinct built forms under
## normal light, which an unshaded flat colour would erase. The old
## wayfinding argument for `unshaded` (a wayfinding silhouette must read the
## same from every approach) no longer applies at this site: `OF13` moved
## the complex ~105m onto the rise's far shoulder specifically so it is NOT
## visible from the village square or the Rise path -- there is no longer a
## long-range wayfinding frame this geometry has to win from every angle,
## only the two close vantages `capture_wayfinding.gd`'s `silhouette-close`
## (~70m) and `silhouette-approach` (~26m) already use. (GATE-E2, 2026-08-23:
## `SITE` moved -- see the header block below -- and that capture tool's own
## vantage points were not re-derived by this pass, so those two distances
## are now stale; the lighting argument they support is not.)

## ---------------------------------------------------------------------
## GATE-E2 (2026-08-23, owner directive "move the castle to the end"): why
## the site moved off the ridge above the village to a point east of the
## stronghold's own route.
## ---------------------------------------------------------------------
##
## OW5D (docs/MEADOWS_MACRO_LAYOUT.md section 10.2) grew the Meadows into an
## 11.6km corridor and moved the Sigil Gate to (63.6,7400) and
## `stronghold.json`'s `site.at` to (0,7560) -- but `RISE_CENTRE + OFFSET`
## below (the old `OF9`/`OF13` site, see history below) stayed on the
## PRE-corridor map at (229.8,-144.4), 271m from the OLD Sigil Gate at
## (130,-176). Once the corridor moved, that bearing pointed at nothing: the
## castle stood 7.5km from the stronghold it is supposed to loom behind,
## beside the village instead, while `ralph/reports/
## VISUAL_STRUCTURES_AND_GROUND_2026-08-23.md` records three blind critics
## independently calling the ACTUAL destination (`stronghold.gd`'s route)
## "the antagonist made of nothing" without ever finding the real castle
## 7.5km away that would have answered the complaint.
##
## `SITE` was derived from the stronghold's OWN built footprint, not
## guessed. `stronghold.json`'s five chambers, rotated by `site.yaw_deg` 90
## around `site.at` (Godot's Y-rotation carries local +z onto world +x,
## local +x onto world -z -- `stronghold.gd::build()`'s own `rotation.y`
## does exactly this; nothing here reimplements it, this is the same
## arithmetic done by hand to plan a site before probing it), gives a
## chamber-footprint world AABB of x[-12.0, 104.2] z[7548.0, 7606.4] --
## `legendary_chamber`, the route's actual last room, is both the DEEPEST
## chamber (the room-progression axis, local +z, is world +x under this
## rotation) and the most northerly one (its -32 lateral offset maps to
## world +z), so "deeper into the stronghold" and "further along the
## approach corridor" point in nearly the same direction here. The
## complex's own entrance ramp and its 15 Team Tether approach pylons
## (`stronghold.json`'s `approach_pylons.list`) sit on the OPPOSITE side,
## converging from the southwest (world x -40..-8) onto the mouth at
## `_mouth_outer_z()` -- so nothing built or authored occupies the ground
## east of the chambers.
##
## North was ruled out first: `world_perimeter.gd`'s corridor rewrite
## (OW5C) puts the map's own south boundary cap at `WORLD_Z_SOUTH` = 7680,
## only 74m past the chambers' own north edge (7606) -- not enough room for
## a 44m-deep plinth plus a real clearance margin without risking the
## boundary wall's own collision. East has the rest of the 2048m-wide
## corridor to work with (`world_bounds.max_x` 1024) and reads as "the mass
## beyond the route's own last room" rather than "a shape stuck against the
## map edge".
##
## `SITE` sits at world (150.0, 7595.0). The hand math above (chamber
## rectangles only) said the plinth's west edge clears the chambers' east
## edge by ~27.8m; a real MESH AABB probe (every `MeshInstance3D` under each
## node, composed through its transform chain, the same walk `render_bounds.
## gd` uses for unskinned geometry) measured the two BUILT nodes instead --
## `StrongholdSilhouette` (this castle, ramp and kerbs included) at world
## x[131.2,172.8] z[7571.3,7629.8], `Stronghold` (the route, its own approach
## ramp included) at world x[-39.5,105.6] z[7546.6,7607.4] -- and found a
## real clearance of 25.7m on the X axis, the axis that actually separates
## them (they still overlap in Z; one separating axis is sufficient for two
## AABBs not to intersect). The castle's own north edge sits 50.3m inside
## `WORLD_Z_SOUTH` (7680.0). Ground relief was verified against the live
## heightfield with the same 8m-grid method `tools/_probe_stronghold.gd`
## used to site the stronghold itself: relief across the plinth's own
## footprint is +1.43m / -2.07m relative to the ground-snap point, gentler
## than the 2026-08-16 remass measured at the OLD site (+3.5 / -1.5) that
## `PLINTH_TOP`/`PLINTH_BOTTOM` below are sized for, so `PLINTH_TOP` (4.2)
## clears the new high corner with 2.77m to spare. `PLINTH_BOTTOM` needed
## one change: at -2.5 the exposed face would have cleared the new low
## corner by only 0.43m, under the 0.5m "reads as a built revetment, not a
## floating slab" bar the remass itself used, so it moved to -3.0 (0.93m of
## clearance) -- the one number this pass actually retuned; everything else
## about the plinth is unchanged.
##
## There is no named rise here the way `RISE_CENTRE` named one at the old
## site -- `terrain_playground.json`'s `rises.peaks[]` has nothing within
## several hundred metres of (150,7595); the ground is ordinary rolling
## corridor terrain. The plinth was never load-bearing on having a hill
## under it -- it is a self-levelling stone podium that ground-snaps to
## whatever is there and absorbs the local relief either way (see
## `PLINTH_TOP`/`PLINTH_BOTTOM` above and `_build_plinth` below); the old
## site's peak only ever supplied the visual backdrop, not the mechanism.
const SITE := Vector2(150.0, 7595.0)

## ---------------------------------------------------------------------
## History (OF4, OF9, OF13), retired by GATE-E2 above: why the OLD site sat
## where it did, on the pre-corridor map. Kept as a record of the reasoning,
## not as current siting -- `RISE_CENTRE`/`OFFSET` no longer drive anything.
## ---------------------------------------------------------------------
##
## `RISE_CENTRE` named the true peak of `terrain_playground.json`'s
## `rises.peaks[0]` (140,-90) -- kept as a reference point since
## `capture_hillside.gd`/`OF11` anchor to the same rise -- but `OFFSET` did
## not sit near that peak. `OF13` (the owner's direct answer to `OF9`: the
## stronghold must not be visible from the start, and must sit farther from
## the village) carried the site ~105m out onto the rise's FAR (east)
## shoulder, past the dome's own radius (78) and onto the surrounding
## rolling hills, computed (not guessed) from a ray-march probe against
## `playground_heightfield.gd::height_at` from the two vantage points
## `capture_wayfinding.gd` uses: at this offset, occlusion from both the
## village-square eye and the-rise-route's second waypoint was -17.0m /
## -23.2m (comfortably occluded, not marginal), net distance from the
## village-square eye 271m (up from the original site's 156.8m). Correct
## for the pre-corridor map, and stale the moment OW5D moved the Sigil Gate
## and the stronghold 7.5km north -- the eye these numbers occlude from is
## not a vantage anyone approaches this landmark from any more.
const RISE_CENTRE := Vector2(140.0, -90.0)
const OFFSET := Vector2(89.8, -54.4)

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const CASTLE_PREFAB := "castle"
const OCCUPATION := preload("res://scripts/world/stronghold_occupation.gd")

## OF4-rebuild: a probe against the live heightfield at this exact site
## (script, this task -- not re-committed) found ~2.3m of relief across the
## plinth's own footprint, rising toward the south/west and falling toward
## the north-east. The corners the PLINTH ITSELF actually covers (its own
## +-PLINTH_HALF_X/Z rectangle, wider than the castle prefab's own wall
## centrelines) are the binding measurement, not the castle's own corners:
## the plinth's own far NW corner (-13,+10) measured +1.434m relative to the
## site's ground-snap point, the highest point found. PLINTH_TOP clears it
## with a real margin, so no corner's terrain pokes through the floor;
## PLINTH_BOTTOM clears the lowest measured point (-0.56m, the far SE
## corner) by more than 0.5m so the exposed foundation face on the falling
## side reads as a built revetment, not a floating slab. Vertical faces
## only -- `OF4`'s own history below found a battered (sloped) terrace face
## read as a rock crag instead of built stone once flat-filled; kept here
## even though the plinth is shaded now, since there is no reason to
## reintroduce a slope that was already rejected on its own merits.
## RE-MASS 2026-08-16 (owner directive; see the castle prefab's own _why in
## building_prefabs.json): the plinth grew with the castle -- 40x44m,
## asymmetric on purpose. The SOUTH edge stays exactly where OF4-rebuild put
## it (local z -10 -- world -154.4 at the OLD site, world 7585.0 at the
## current `SITE`, GATE-E2 below) because the stronghold complex was sited
## against it; all growth goes north/east/west inside the envelope the
## terrain probe allowed. TOP/BOTTOM re-measured over the NEW footprint
## (probe grid, 2026-08-16): highest relief inside it +3.5m, lowest -1.5m,
## so 4.2 clears the high corner and -2.5 keeps the exposed face a built
## revetment on the falling side. The plinth is also a real STATIC BODY now
## -- the whole castle was walk-through before.
##
## GATE-E2 (2026-08-23): `SITE` moved (see the header block above), and
## `PLINTH_TOP`/`PLINTH_BOTTOM` were re-checked against the new footprint's
## OWN relief rather than assumed to still fit -- they do, with margin, at
## the new site's gentler +1.43m / -2.07m, EXCEPT `PLINTH_BOTTOM`: -2.5
## cleared the new low corner by only 0.43m, under the 0.5m bar the
## 2026-08-16 remass itself used for "reads as a built revetment, not a
## floating slab", so it moved to -3.0 for a real 0.93m of clearance.
## `PLINTH_TOP` needed no change -- 4.2 clears the new high corner by 2.77m.
const PLINTH_TOP := 4.2
const PLINTH_BOTTOM := -3.0
## Centre and half-extents of the grown footprint: x -18..+22, z -10..+34
## local. A margin past the new wall centrelines (x -16..+20, z -8.448..+32).
const PLINTH_CENTRE := Vector3(2.0, 0.0, 12.0)
const PLINTH_HALF_X := 20.0
const PLINTH_HALF_Z := 22.0

## The way in. The gate arch is real and OPEN now (the shadow slab is
## retired), and the courtyard floor is the plinth top -- which sits
## PLINTH_TOP above the ground, so a ramp runs down from the gate to the
## grass on the south side. 11m of run over 4.2m of rise is ~21 degrees,
## comfortably under the 45 the player walks. The castle has no rotation
## (`build()` sets only `position`), so this ramp exits toward decreasing
## world z regardless of `SITE` -- at the OLD site that put its foot 4m
## clear of the stronghold complex's own Legendary Chamber box, because the
## two stood immediately adjacent; GATE-E2 (2026-08-23) moved `SITE` a
## measured 25.7m clear of the stronghold's whole built footprint (see the
## header block above), so the ramp now lands on open ground with nothing
## nearby to clear.
const RAMP_RUN := 11.0
const RAMP_WIDTH := 6.0

## A stone tone distinct from (darker than) the castle's own retinted
## LightRock/DarkRock -- the foundation should read as a different, older
## mass under the walls, not a colour-matched continuation of them.
##
## OF4-rebuild round 3 (blind-critique pass, this task): round 2 darkened
## the castle's own retint (LightRock/DarkRock, building_prefabs.json) to
## fix a washed-out, poor-distance-legibility defect the first blind pass
## named -- and that fix worked (the castle went from a barely-visible pale
## smear to a clearly readable dark silhouette against the grass/hill at
## range) but inverted this value relationship: the ORIGINAL plinth colour
## (#544c44) ended up LIGHTER than the now-darker wall above it, so the
## foundation read as floating on top of a darker structure instead of
## grounding it. Darkened again here, below the wall's own darkest retint
## (DarkRock #463f37), to restore "foundation reads darkest, walls lighter
## above it" -- the ordinary value hierarchy a real base course has.
##
## GATE-E-STRONGHOLD-ART (2026-08-23): raised #332e28 -> #524a41, in step with
## the castle's own retint (building_prefabs.json, `castle`, which carries the
## full measurement). The relationship round 3 established is deliberately
## PRESERVED, not undone: the plinth is still darker than the wall's darkest
## stone (`DarkRock`, now #6b5f52), so the foundation still grounds the mass
## instead of floating on it. What changed is that both ends of that ladder
## moved up together, because the whole ladder was sitting in the castle's own
## permanent shadow -- the ramp and plinth in `gate-close` measured a near-
## field luma of 0.012, which is not a dark foundation, it is an absence.
const PLINTH_COLOUR := Color("#524a41")


func build(world: Node) -> void:
	var at := SITE
	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the stronghold at %.0f, %.0f" % [at.x, at.y])
		return
	position = Vector3(at.x, ground, at.y)

	_build_plinth()

	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; the stronghold cannot build its castle")
		return
	# building_prefabs.gd caches an un-parented Node3D template tree per
	# prefab name; without a real SceneTree parent it leaks RenderingServer
	# resources at engine shutdown (see building_prefabs.gd's own header on
	# `_holder`, and road_gate.gd/grandpa_house.gd's identical pattern).
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)

	var castle: Node3D = prefabs.call("instantiate", CASTLE_PREFAB)
	if castle == null:
		push_error("castle prefab missing: %s" % CASTLE_PREFAB)
		return
	castle.name = "Castle"
	castle.position = Vector3(0.0, PLINTH_TOP, 0.0)
	add_child(castle)
	_weather_castle(castle)

	_build_castle_colliders(prefabs)
	_build_ramp()
	_build_occupation(world)


## T1-CASTLE (2026-08-29). `ralph/reports/T1-ARCH_buildings_2026-08-29.md`
## diagnosed the owner's "up close the castle reads pale, flat and
## plastic/toylike" verdict (`ralph/OWNER_FEEDBACK_2026-08-29_BUILDINGS.md`)
## as real and NOT a broken retint: a wall face pixel-samples to the authored
## `LightRock` colour, correctly brightened by direct sun. The report's own
## conclusion was that the Quaternius kit is solid-colour and no-texture, with
## "no middle scale of visual interest ... nothing between 'wall' and
## 'crenellation'" -- the exact defect `interior_structure.gd`'s header
## already names for constructed interiors, and the exact defect this same
## file's own `_stone_material()`/STRONGHOLD-R2 already fixed once, for the
## plinth, with a generated triplanar detail texture (the plinth's own boxes
## have no UVs either; a direct probe of `WallBricks.obj` found the castle
## kit's geometry has NONE at all -- 0 `vt` lines -- so triplanar is not a
## style choice here, it is the only mapping this geometry supports).
##
## This reuses that exact proven technique on the castle's own stone
## surfaces, rather than inventing a second mechanism: a small generated
## grayscale multiply, triplanar-mapped, is set directly onto the ACTIVE
## material `building_prefabs.gd::_apply_retint` already put on every wall/
## tower/keep surface -- safe to mutate in place (not duplicate again) because
## `prefabs` above is a composer LOCAL to this one `build()` call, used for no
## prefab but `castle`, so nothing outside this landmark shares these
## material instances. Two octaves: a fine mineral grain (the same scale of
## effect as the plinth's own mottle) and a coarser, darken-only blotch layer
## standing in for the grime/staining a real quarried stone face weathers
## unevenly with -- real per-crevice curvature AO would need actual mesh
## analysis this lane did not have time to build safely, and an isotropic
## multiply is the cheap, already-shipped-on-this-kit alternative the report
## itself named as an acceptable route. `Banner`/`Celing`/`LightWood` are
## deliberately left out: the reserved heraldic cloth should stay clean and
## vivid (STRONGHOLD-R2's own reservation), and the small wood/ceiling trim
## has no `_why_retint`-documented "toy" complaint against it and needs no
## widened scope.
##
## Cost: one more StandardMaterial3D with `uv1_triplanar` set, the same flag
## the plinth's own material already carries in this exact scene -- a single
## extra texture sample per pixel of stone, not a shader, and shared by every
## wall/tower surface via one texture and up to eight material instances
## (mutated, not duplicated per-surface). Not measured on ROG Ally hardware --
## this environment has only the software (llvmpipe) renderer -- but the
## technique is the SAME class of cost the plinth already pays in this same
## frame, so it is not a new performance category for this scene, only more
## surface area paying a cost already present. Worth a real device check
## before calling this closed.
## T1-HALL-BUILD (2026-08-30), `ralph/reports/HALL_DESIGN_2026-08-30.md` §5.
## The generated 96px noise texture above (kept in history via git, not in
## this file) was a flat-value multiply and, per the design doc's diagnosis,
## "a flat colour at any value cannot produce coursing" -- it is isotropic
## grain/blotch, not stone shape, so no distance reads it as masonry. The
## works walls (`stronghold.gd`) already prove the real fix: a real
## photographic stone texture (`T_UnevenBrick`, the SAME cut stone, reused
## rather than re-picked -- D24 one family), triplanar-mapped at the works'
## own measured `STONE_TILE` = 0.28 (that file's own header has the tiling-
## collision math this number resolves). The castle kit has zero UVs (a
## direct probe of `WallBricks.obj` found 0 `vt` lines), so triplanar is not
## a style choice, it is the only mapping this geometry supports -- exactly
## the plinth's own precedent this function already followed.
const STONE_ALBEDO := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_BaseColor.png")
const STONE_NORMAL := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Normal.png")
const STONE_ROUGHNESS := preload("res://assets/buildings/quaternius_medieval/T_UnevenBrick_Roughness.png")
const STONE_TILE := 0.28
## `Black` (openings/iron slots) stays a FLAT retint, no stone texture --
## design §5's table calls it "flat", and a void/iron surface reading as
## quarried stone would be the wrong material story on a gate mouth.
const WEATHER_MATERIALS := [
	"LightRock", "LightRock.001", "LightRock.002",
	"DarkRock", "DarkRock.001",
]


func _weather_castle(castle: Node3D) -> void:
	var done: Dictionary = {}
	for mi in _weather_mesh_instances(castle):
		if mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(surface)
			if mat == null or not mat is StandardMaterial3D:
				continue
			var std := mat as StandardMaterial3D
			if not WEATHER_MATERIALS.has(std.resource_name):
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
			# The kit's own materials import fully rough already (roughness
			# 1.0 -- confirmed by direct probe); `maxf` only ever holds that
			# or raises it, never sharpens a surface that isn't already flat.
			std.roughness = maxf(std.roughness, 0.92)


func _weather_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_weather_mesh_instances(child))
	return found


## GATE-E-STRONGHOLD-ART (2026-08-23): the site is HELD, and until this pass
## nothing in the frame said so. `stronghold_occupation.gd`'s own header
## carries the full reasoning; the short version is that two blind critics
## independently called this castle bannerless, unlit-looking and empty of
## Team Tether, and that the "unlit" half of that is a real measured defect
## rather than an impression -- `art.json` puts the sun in the north sky and
## every approach to this building is on its south side, so the hero face is
## backlit at every hour the chapter is played and was rendering at a near-
## field luma of 0.012.
##
## Presentation only: no collider, no interaction, no flag, no navigation, and
## nothing inside the ramp's own 6m width. It is built LAST, after the castle
## and the ramp, so it can be deleted wholesale without disturbing either.
func _build_occupation(world: Node) -> void:
	var occupation: Node3D = OCCUPATION.new()
	add_child(occupation)
	occupation.call("build", world, PLINTH_TOP, position, RAMP_RUN)


## A simple vertical-faced stone podium the whole castle stands on --
## see PLINTH_TOP's own comment for why the height and footprint are what
## they are. Not a kit module (the castle kit ships no plain foundation
## slab), so built directly here the same way the old `_terrace`
## primitive was: one box, one material.
func _build_plinth() -> void:
	var plinth := MeshInstance3D.new()
	plinth.name = "Plinth"
	var box := BoxMesh.new()
	box.size = Vector3(PLINTH_HALF_X * 2.0, PLINTH_TOP - PLINTH_BOTTOM, PLINTH_HALF_Z * 2.0)
	box.material = _stone_material(PLINTH_COLOUR)
	plinth.mesh = box
	plinth.position = PLINTH_CENTRE + Vector3(0.0, (PLINTH_TOP + PLINTH_BOTTOM) * 0.5, 0.0)
	add_child(plinth)
	_build_plinth_courses()

	# The courtyard floor and the foundation the player can stand against.
	var body := StaticBody3D.new()
	body.name = "PlinthBody"
	var shape := CollisionShape3D.new()
	var solid := BoxShape3D.new()
	solid.size = box.size
	shape.shape = solid
	body.add_child(shape)
	add_child(body)
	body.position = plinth.position


## STRONGHOLD-R2. Two proud bands around the plinth, and the mottled stone the
## plinth and ramp are now made of.
##
## The round-1 frames put the whole foundation on screen as ONE flat rectangle
## of a single value, ~20m wide and 6.7m tall, running the full width of every
## approach frame -- the blind critique's "dark untextured plinth skirt". Three
## separate things produce that reading and only one of them is colour:
##
##   1. it carried a bare `albedo_color` with no map of any kind, so every
##      pixel of it is literally the same number (`_stone_material` below);
##   2. nothing broke it horizontally, so there is no scale cue on it at all
##      -- a 6.7m face and a 0.7m face look identical when both are blank;
##   3. its top edge met the castle's own base as one unbroken line, so the
##      foundation read as a slab the castle was standing ON rather than as
##      the base course of the same building.
##
## The coping takes (3) -- a capping course proud of the face, which is what
## the top of a real revetment is -- and the string course takes (2). Both are
## drawn in the castle's own `DarkRock` retint rather than in `PLINTH_COLOUR`,
## so the ladder round 3 established (foundation darkest, walls lighter) still
## holds face-to-face while the BANDS are lighter than the face they stand on,
## which is how a dressed stone course reads against rubble.
##
## Visual only. `PlinthBody` above is untouched and still spans the plinth's
## full authored footprint, so nothing here changes where a player can stand;
## the bands are proud of that footprint by 0.25m, which is inside the 0.93m
## apron the plinth already has south of the wall centrelines.
const COPING_PROUD := 0.25
const COPING_HEIGHT := 0.55
const STRING_PROUD := 0.15
const STRING_HEIGHT := 0.30
## Where the string course sits below the coping. Chosen so the face is cut
## into two unequal bands (roughly 2:1) rather than halved -- a halved wall
## reads as a mistake, an unequal split reads as construction.
const STRING_DROP := 2.4
## `building_prefabs.json`'s `castle` retint, `DarkRock`. Named here rather
## than loaded: this is one colour off one recipe, and landmark.gd already
## carries PLINTH_COLOUR the same way. If that retint moves, move this with it.
const COURSE_COLOUR := Color("#6b5f52")


func _build_plinth_courses() -> void:
	var bands := [
		{"name": "PlinthCoping", "proud": COPING_PROUD, "height": COPING_HEIGHT,
			"centre_y": PLINTH_TOP - COPING_HEIGHT * 0.5},
		{"name": "PlinthStringCourse", "proud": STRING_PROUD, "height": STRING_HEIGHT,
			"centre_y": PLINTH_TOP - COPING_HEIGHT - STRING_DROP - STRING_HEIGHT * 0.5},
	]
	for entry: Variant in bands:
		var spec: Dictionary = entry
		var proud: float = float(spec["proud"])
		var band := MeshInstance3D.new()
		band.name = str(spec["name"])
		var box := BoxMesh.new()
		box.size = Vector3(
			PLINTH_HALF_X * 2.0 + proud * 2.0,
			float(spec["height"]),
			PLINTH_HALF_Z * 2.0 + proud * 2.0)
		box.material = _stone_material(COURSE_COLOUR)
		band.mesh = box
		band.position = PLINTH_CENTRE + Vector3(0.0, float(spec["centre_y"]), 0.0)
		add_child(band)


## A stone surface with an actual albedo map on it.
##
## The map is generated here rather than loaded or hung off a `NoiseTexture2D`:
## `NoiseTexture2D` fills on a worker thread and is empty for the first frames
## after it is created, which is exactly the window a scripted capture or a
## headless test reads the scene in -- a texture that is correct a second later
## is not correct for the frame that gets saved. This is 64x64 samples in a
## tight loop, deterministic, finished before the function returns.
##
## `TRIPLANAR` because the plinth and the bands are boxes with no meaningful
## UVs: without it the grain stretches to the size of each face and a 44m face
## and a 0.55m band would be wearing the same four pixels.
const STONE_TEXTURE_SIZE := 64
## Metres per tile of the generated grain. Small enough that a 40m plinth face
## carries visible variation, large enough that the mottle does not alias into
## noise at the 70m `silhouette-close` range.
const STONE_TEXTURE_METRES := 3.0
## How far the mottle swings either side of the base colour. Deliberately
## small -- this is meant to stop the surface being one literal number, not to
## turn the foundation into camouflage.
const STONE_MOTTLE := 0.13


func _stone_material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.albedo_texture = _stone_texture()
	mat.roughness = 0.95
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE / STONE_TEXTURE_METRES
	return mat


var _stone_texture_cache: ImageTexture = null


func _stone_texture() -> ImageTexture:
	if _stone_texture_cache != null:
		return _stone_texture_cache
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 20260823
	noise.frequency = 0.06
	noise.fractal_octaves = 3
	var image := Image.create_empty(
		STONE_TEXTURE_SIZE, STONE_TEXTURE_SIZE, false, Image.FORMAT_RGB8)
	for y in STONE_TEXTURE_SIZE:
		for x in STONE_TEXTURE_SIZE:
			# `albedo_texture` MULTIPLIES `albedo_color`, so the neutral value
			# here is 1.0 and the mottle rides either side of it.
			var value: float = 1.0 + noise.get_noise_2d(float(x), float(y)) * STONE_MOTTLE
			image.set_pixel(x, y, Color(value, value, value))
	_stone_texture_cache = ImageTexture.create_from_image(image)
	return _stone_texture_cache


## The prefab's own collider list (the {at,size} local-space format
## village.gd already consumes), built under one StaticBody at the castle's
## transform. The old castle carried none -- the endgame landmark was
## walk-through -- and this is half of what "not a prop" means.
func _build_castle_colliders(prefabs: RefCounted) -> void:
	var boxes: Array = prefabs.call("colliders", CASTLE_PREFAB)
	if boxes.is_empty():
		return
	var body := StaticBody3D.new()
	body.name = "CastleBody"
	for entry: Variant in boxes:
		if not entry is Dictionary:
			continue
		var spec := entry as Dictionary
		var at: Array = spec.get("at", [0.0, 0.0, 0.0])
		var size: Array = spec.get("size", [1.0, 1.0, 1.0])
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(float(size[0]), float(size[1]), float(size[2]))
		shape.shape = box
		shape.position = Vector3(float(at[0]), float(at[1]), float(at[2]))
		body.add_child(shape)
	add_child(body)
	body.position = Vector3(0.0, PLINTH_TOP, 0.0)


## The stone ramp from the grass up to the open gate: one rotated box, mesh
## and collider in the same body, plinth-coloured so it reads as part of the
## foundation.
func _build_ramp() -> void:
	var rise := PLINTH_TOP
	var length := sqrt(RAMP_RUN * RAMP_RUN + rise * rise)
	var angle := atan2(rise, RAMP_RUN)

	var body := StaticBody3D.new()
	body.name = "GateRamp"
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(RAMP_WIDTH + RAMP_SHOULDER * 2.0, 0.8, length)
	# Same generated stone as the plinth (STRONGHOLD-R2): the ramp fills the
	# bottom third of `gate-close` on its own, and a flat single-value slab
	# that close to the eye is the largest untextured surface in the frame.
	box.material = _stone_material(PLINTH_COLOUR)
	mesh.mesh = box
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var solid := BoxShape3D.new()
	solid.size = box.size
	shape.shape = solid
	body.add_child(shape)
	add_child(body)
	# Centred on the slope from the gate sill (local z -10 at plinth top) down
	# to the grass at z -10-RAMP_RUN. Gate bay sits at local x +2.
	body.position = Vector3(2.0, PLINTH_TOP - rise * 0.5 - 0.2, -10.0 - RAMP_RUN * 0.5)
	body.rotation.x = -angle
	_build_ramp_kerbs(body, length)


## STRONGHOLD-R2. A low kerb down each side of the ramp.
##
## The ramp is 6m wide and 11.8m long and it fills the bottom third of
## `gate-close` and a quarter of `silhouette-approach` as one unbroken plane
## with a hard edge and nothing on it. The key art's own stronghold panel
## approaches its gate up a built stair with kerbs and a parapet; this is the
## cheapest honest version of that, and it is what stops the causeway reading as
## a ramp asset dropped in front of a castle asset.
##
## Children of the ramp body, so they inherit its rotation and can never
## disagree with the slope. `MESH ONLY` — no collider of their own; the slab
## under them is the collider, and it grew rather than the walked width
## shrinking, so nothing a player could stand on before is lost.
##
## THE SLAB IS NOW WIDER THAN `RAMP_WIDTH` AND THAT IS DELIBERATE. `RAMP_WIDTH`
## is still 6.0 and still means what `stronghold_occupation.json` says it means:
## the walked width, which nothing is allowed inside. `RAMP_SHOULDER` is the
## verge either side of it, and it exists because the ramp-head braziers stand
## at local x -1.3 / +5.3 — i.e. 3.3m off the ramp's own centre, 0.3m PAST the
## old slab edge, tuned there over three rounds of the previous pass and
## overhanging air. Widening the slab puts them on real ground and leaves room
## for the kerb outside them; narrowing the kerb to fit inside the old edge
## would have put masonry through the fire baskets instead. Drawn in
## `COURSE_COLOUR`, the same dressed stone as the plinth's coping and string
## course, so the approach and the foundation read as one construction.
const RAMP_SHOULDER := 1.2
const KERB_WIDTH := 0.5
const KERB_HEIGHT := 1.0
## The kerb's own centre, from the ramp's centreline. Seated on the slab's outer
## edge, with its inner face at 3.7 — clear of the brazier bowls, whose widest
## point reaches 3.625.
const KERB_CENTRE_X := 3.95
## The kerb's centre relative to the deck's own centre plane. The slab is 0.8m
## thick and centred on the body, so its top face is at +0.4; this seats the
## kerb's bottom inside the slab and leaves it standing 0.45m proud.
const KERB_CENTRE_Y := 0.35


func _build_ramp_kerbs(body: Node3D, length: float) -> void:
	for side in [-1.0, 1.0]:
		var kerb := MeshInstance3D.new()
		kerb.name = "RampKerb_%s" % ("west" if side < 0.0 else "east")
		var box := BoxMesh.new()
		box.size = Vector3(KERB_WIDTH, KERB_HEIGHT, length)
		box.material = _stone_material(COURSE_COLOUR)
		kerb.mesh = box
		kerb.position = Vector3(side * KERB_CENTRE_X, KERB_CENTRE_Y, 0.0)
		body.add_child(kerb)


## The far end of the gate passage: a plain dark slab standing across the
## tunnel just inside the castle, so the archway reads as a shadowed way in
## rather than a hole with a lit courtyard behind it.
##
## OF4-gate-arch (2026-08-13). The gate is two rings of the kit's entrance
## module deep (see `building_prefabs.json`'s `castle` recipe), and that
## reveal alone was not enough: the courtyard floor and the far curtain's
## inner face both sit in the opening and both render within a few values of
## the shaded wall around it, so a blind critic reading the frames called the
## gate "bricked up ... a shallow niche or a walled-up arch, not a gate you
## could enter". The missing cue was contrast, not geometry -- a real gate
## mouth is the darkest thing on a castle's face. Nothing in the kit can
## supply it: `building_prefabs.json`'s `retint` keys off material NAMES, and
## every wall piece in the castle shares the same handful of material names,
## so any module dark enough to serve here would darken the whole fortress.
## Hence a slab built directly, the same way the plinth is and for the same
## reason (no kit part does this job).
##
## Deliberately NOT pure black -- an absolute void reads as a hole in the
## render, not a shadow. GATE_SHADOW_COLOUR sits below PLINTH_COLOUR, which
## is itself below the wall's darkest retint, so the value ladder stays
## foundation-dark, walls lighter, gate mouth darkest of all.
const GATE_SHADOW_COLOUR := Color("#16130f")
## Sized and sited from the gate's own numbers: the arch opening is 1.53m
## wide and 1.69m tall (the kit module's authored arch at the recipe's 1.72
## scale), so 3.0 x 3.0 covers it several times over from every angle these
## frames use, while staying under the 3.76m curtain so it never shows above
## the parapet. Z: the inner ring's own inner face is at -7.514, so a 0.4m
## slab centred at -7.35 closes the tunnel right where it ends, with a small
## overlap into it rather than a gap.
const GATE_SHADOW_SIZE := Vector3(3.0, 3.0, 0.4)
const GATE_SHADOW_AT := Vector3(0.0, 0.0, -7.35)


## Retired by the 2026-08-16 re-mass: the gate passage is genuinely open now
## (walkable courtyard behind it), so closing its far end with a shadow slab
## would wall up a doorway that finally works. Kept for the history above.
func _build_gate_shadow() -> void:
	var slab := MeshInstance3D.new()
	slab.name = "GatePassageShadow"
	var box := BoxMesh.new()
	box.size = GATE_SHADOW_SIZE
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GATE_SHADOW_COLOUR
	mat.roughness = 1.0
	box.material = mat
	slab.mesh = box
	slab.position = Vector3(
		GATE_SHADOW_AT.x,
		PLINTH_TOP + GATE_SHADOW_SIZE.y * 0.5,
		GATE_SHADOW_AT.z
	)
	add_child(slab)


## ---------------------------------------------------------------------
## History kept for context: the procedural-primitive silhouette this file
## used to build, six blind-critique rounds deep, retired by OF4-rebuild
## (D28) in favour of the real assembled castle above. None of the code
## below runs any more.
## ---------------------------------------------------------------------
##
## R7.1: M7 asked for a distant landmark so the far edge of the map reads as
## a destination instead of a fence. Placeholder geometry was deliberate at
## the time -- nothing in either vendored asset pack was a ruin or tower,
## and a silhouette's whole job is a dark, angular shape on the skyline,
## which primitives already did at range.
##
## OF4 (2026-08-12 owner playtest): "reads as a toy." Rebuilt the massing
## (a long gabled great-hall block, a dominant SQUARE keep with a
## corner-post crown, square perimeter towers at three heights, curtain
## walls of varying height over a ~36m polygon, a twin-towered gatehouse, a
## lateral rampart down the village-facing flank) rather than tuning the
## four-tapered-cylinder version that preceded it. `TOWER_COLOUR`/
## `SHADER_CODE`'s `unshaded, fog_disabled` render mode was the one setting
## that survived every round after R7.1-visual and R9.4 both found normal
## shading wash out on the two viewpoints players actually use (the sun-lit
## face reads pale grey against the haze from those angles, while the
## shadowed face read fine from `silhouette-close` alone) -- a real
## constraint OF4-rebuild's own header explains is no longer load-bearing
## now that `OF13` moved the site out of long-range view entirely.
##
## OF13 (owner's direct answer to `OF9`): moved the site ~105m out onto the
## rise's far shoulder so it is not visible from the village square or the
## Rise path -- see the retired `RISE_CENTRE`/`OFFSET` history comment
## above, which carried this reasoning forward until GATE-E2 (2026-08-23)
## moved `SITE` again, onto the new corridor map.
