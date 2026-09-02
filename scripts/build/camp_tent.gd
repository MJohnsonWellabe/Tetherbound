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
## T1-CAMP, carried over from camp.gd: measured (tools/_probe_t1_camp.gd) --
## camp_tent.glb's own local origin sits 0.611m above its own geometric base,
## the same glTF-export quirk `docs/specs/ASSET_LEDGER.md` documents a `sink_m:
## -0.64` compensation for on this same mesh's AUTHORED placement
## (band1_lower_meadows/props.json). `build_piece.gd` positions a placed
## piece's model at its own local origin with no such support, so without
## this offset the tent's true visible base sits 0.611m below the ground
## plane it is placed on.
const TENT_SINK := 0.611

var _piece: Node3D = null


func build_ghost() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.position.y = TENT_SINK
	_piece.call("build_ghost", TENT)


func build_real() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.position.y = TENT_SINK
	_piece.call("build_real", TENT)


func tint_ghost(ok: bool) -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.call("tint_ghost", ok)
