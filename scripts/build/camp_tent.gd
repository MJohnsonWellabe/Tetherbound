extends Node3D

## OWNER-0902-CAMP-SPLIT: the tent, split out of camp.gd's bundled camp into
## its own independently placeable buildable (`data/items/buildables.json`'s
## `tent`). Purely decorative shelter -- no interaction, no lit state, the
## same as it was inside the old bundle. Its own script rather than plain
## `mesh` geometry (the floor/wall/fence path) only because it needs the sink
## compensation below, which `build_piece.gd` has no generic field for
## (`creature_bed.gd` carries the identical pattern for the same reason).

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")

const TENT := "res://assets/props/generated_camp/camp_tent.glb"

## CAMP-SHELTER-0903, owner playtest 2026-09-03 item 7: "Tents need to be way
## bigger... you should have to have the tent over your head to sleep." At
## its authored size the tent's own local AABB (measured by a throwaway probe
## against the raw glb, same technique as `_probe_bed_float.gd`) was only
## 1.209m tall -- shorter than the 1.80m trainer standing outside it, let
## alone with room to duck under the roof and lie down. Scaled non-uniformly
## rather than by one uniform factor: Y climbs the most (2.2x, peak height
## 1.209*2.2=2.66m -- 0.86m of headroom over the trainer) because height was
## the actual defect; X/Z grow enough (1.45x/1.25x) to comfortably fit the
## bedroll's own footprint (measured 1.229w x 1.901d) inside with the trainer
## still able to stand beside it, while staying just small enough that a tent
## and a campfire placed one build-grid cell apart (2m, `build_grid.gd::
## GRID_SIZE`) still clear each other: the campfire's own scaled stone-ring
## footprint (measured 1.6w x 1.599d, `campfire.gd::STONE_RING_SCALE`) has a
## 0.8m half-extent on both axes, and this tent's own half-extents (below)
## both stay under 2.0 - 0.8 = 1.2m.
const TENT_SCALE := Vector3(1.45, 2.2, 1.25)

## T1-CAMP, carried over from camp.gd: measured (tools/_probe_t1_camp.gd) --
## camp_tent.glb's own local origin sits 0.611m above its own geometric base,
## the same glTF-export quirk `docs/specs/ASSET_LEDGER.md` documents a `sink_m:
## -0.64` compensation for on this same mesh's AUTHORED placement
## (band1_lower_meadows/props.json). `build_piece.gd` positions a placed
## piece's model at its own local origin with no such support, so without
## this offset the tent's true visible base sits 0.611m below the ground
## plane it is placed on. CAMP-SHELTER-0903: that 0.611m offset lives in the
## mesh's own local space, so it scales with `TENT_SCALE.y` the same as every
## other vertex does -- 0.611 * 2.2 = 1.3442.
const TENT_SINK := 0.611 * TENT_SCALE.y

## CAMP-SHELTER-0903. Half the tent's own scaled floor footprint, in the
## tent's local X/Z (pre-yaw) -- from the same raw measurement as `TENT_SCALE`
## above (local AABB size.x=1.598, size.z=1.897), each shrunk by half the
## bedroll's own scaled footprint (measured size.x=1.229, size.z=1.901,
## unscaled -- `player_bed.gd::MESH_PATH` is the identical mesh at
## `Vector3.ONE`) so a bedroll placed with its CENTER inside this box also
## keeps its edges under the roof rather than poking out through the canvas.
## (0.544m / 0.235m of margin either side -- tight on Z, the axis both meshes
## are long on, but never negative.)
const INTERIOR_HALF_X := (1.598 * TENT_SCALE.x) / 2.0 - (1.229 / 2.0)
const INTERIOR_HALF_Z := (1.897 * TENT_SCALE.z) / 2.0 - (1.901 / 2.0)

## CAMP-SHELTER-0903. This tent's own scaled floor half-extents, X and Z --
## `INTERIOR_HALF_X`/`_Z` above already shrink these by the bedroll's own
## footprint for the containment check; the campfire-clearance test wants the
## tent's REAL edge instead.
const HALF_X := (1.598 * TENT_SCALE.x) / 2.0
const HALF_Z := (1.897 * TENT_SCALE.z) / 2.0

## CAMP-SHELTER-0903. Scaled peak height above the ground plane: the same raw
## local AABB `TENT_SINK` measures the bottom of (min y=-0.611398) also has a
## top at y=+0.597301, so bottom-to-peak is 1.208699m unscaled -- `tests/
## test_build_catalogue.gd`'s tent-size assertion reads this directly rather
## than re-deriving it from the raw AABB a second time.
const PEAK_HEIGHT := 1.208699 * TENT_SCALE.y

var _piece: Node3D = null


func build_ghost() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.position.y = TENT_SINK
	_piece.call("build_ghost", TENT, TENT_SCALE)


## CAMP-SHELTER-0903. A layer the player's own `collision_mask` (default 1)
## does not include -- see `build_piece.gd::build_real`'s own comment on
## `collision_layer`. The tent's generic solid collider is one box spanning
## its whole AABB floor-to-ridge, and now that the tent is large enough to
## require the trainer standing (and the bedroll sitting) inside that same
## footprint, a layer-1 interior would fight the rest this file's own
## `contains_point` is meant to allow. Kept on a REAL collider (not dropped
## to no collision at all) so a placed tent stays a raycastable
## `StaticBody3D` -- `build_placer.gd`'s dismantle ray uses the default
## all-layers mask, so this still finds and removes it.
const NON_BLOCKING_LAYER := 2


func build_real() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.position.y = TENT_SINK
	_piece.call("build_real", TENT, {}, TENT_SCALE, NON_BLOCKING_LAYER)


func tint_ghost(ok: bool) -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.call("tint_ghost", ok)


## CAMP-SHELTER-0903. True if `point` (a bedroll's own world position, or the
## trainer's) falls under this tent's roof -- `tent_pos`/`tent_yaw_deg` are a
## placed tent's own world position and yaw (`placed_buildings`' own
## `position`/`yaw_deg` fields, or a live node's `global_position`/
## `rotation.y`). Rotates `point` into the tent's own local frame first so a
## tent the player has turned away from world-axis-aligned still contains
## points correctly, then checks the plain axis-aligned box `INTERIOR_HALF_X`/
## `INTERIOR_HALF_Z` describe in that local frame -- the same
## rotate-then-axis-check shape `build_snap_contract.gd::_thickness_correction`
## already uses for a placed piece's own yaw.
static func contains_point(tent_pos: Vector3, tent_yaw_deg: float, point: Vector3) -> bool:
	var local := (point - tent_pos).rotated(Vector3.UP, deg_to_rad(-tent_yaw_deg))
	return absf(local.x) <= INTERIOR_HALF_X and absf(local.z) <= INTERIOR_HALF_Z
