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
## This file's only remaining job is siting: ground-snap at the existing
## `RISE_CENTRE + OFFSET` site (unchanged from `OF9`/`OF13` -- moving the
## site is a `BLOCKED.md`-class question, not this task's to decide), build
## a stone plinth that absorbs the site's own measured terrain relief, and
## instantiate the prefab on top of it.
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
## (~70m) and `silhouette-approach` (~26m) already use.

## ---------------------------------------------------------------------
## History (OF4, OF9, OF13): why the site sits where it does. Unchanged by
## this rebuild -- moving it is outside this task's authority (see D28).
## ---------------------------------------------------------------------
##
## `RISE_CENTRE` names the true peak of `terrain_playground.json`'s
## `rises.peaks[0]` (140,-90) -- kept as a reference point since
## `capture_hillside.gd`/`OF11` anchor to the same rise -- but `OFFSET` does
## not sit near that peak. `OF13` (the owner's direct answer to `OF9`: the
## stronghold must not be visible from the start, and must sit farther from
## the village) carries the site ~105m out onto the rise's FAR (east)
## shoulder, past the dome's own radius (78) and onto the surrounding
## rolling hills, computed (not guessed) from a ray-march probe against
## `playground_heightfield.gd::height_at` from the two vantage points
## `capture_wayfinding.gd` uses: at this offset, occlusion from both the
## village-square eye and the-rise-route's second waypoint is -17.0m /
## -23.2m (comfortably occluded, not marginal), net distance from the
## village-square eye 271m (up from the original site's 156.8m).
const RISE_CENTRE := Vector2(140.0, -90.0)
const OFFSET := Vector2(89.8, -54.4)

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const CASTLE_PREFAB := "castle"

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
const PLINTH_TOP := 1.8
const PLINTH_BOTTOM := -1.1
## Half-extents, a small margin past the castle prefab's own wall centrelines
## (x +-11.52, z +-8.448 in building_prefabs.json) so the walls stand ON the
## plinth rather than at its exact edge.
const PLINTH_HALF_X := 13.0
const PLINTH_HALF_Z := 10.0

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
const PLINTH_COLOUR := Color("#332e28")


func build(world: Node) -> void:
	var at := RISE_CENTRE + OFFSET
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
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PLINTH_COLOUR
	mat.roughness = 0.95
	box.material = mat
	plinth.mesh = box
	plinth.position = Vector3(0.0, (PLINTH_TOP + PLINTH_BOTTOM) * 0.5, 0.0)
	add_child(plinth)


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
## Rise path -- see the active `RISE_CENTRE`/`OFFSET` comment above, which
## carries this history forward since the siting math is unchanged.
