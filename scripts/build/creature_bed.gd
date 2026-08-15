extends Node3D

## R4.8. A placed creature bed: `build_piece.gd`'s generic geometry, plus a
## real interaction -- the same "carries state and an interaction, so it gets
## its own hand-authored script" shape `storage_container.gd` already set
## (R2.7). GAME_DESIGN.md 16/20's full brief for the `creature_bed` buildable
## (`R2.8` shipped it as a bare, non-interactive placeable and deferred this
## part on purpose: "revives a fainted creature... visible creature rest
## behaviour") lands here.

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const REST_PANEL := preload("res://scripts/ui/creature_bed_panel.gd")

const MESH_PATH := "res://assets/props/quaternius_fantasy/Bed_Twin1.gltf"

## One panel, reused and re-pointed at whichever bed opened it -- the same
## lazily-built shared-panel shape `storage_container.gd` uses for its own
## transfer screen.
static var _panel: CanvasLayer = null

var _piece: Node3D = null


func build_ghost() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.call("build_ghost", MESH_PATH)


func build_real() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.call("build_real", MESH_PATH)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0.0, 0.6, 0.7)
	prompt.call("configure", "Rest a Creature", 2.6, true)
	prompt.connect("activated", _on_rest)
	add_child(prompt)


## Legal (green) or not (red), at ghost alpha either way -- delegated to the
## same build_piece.gd every other non-camp/storage entry uses.
func tint_ghost(ok: bool) -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.call("tint_ghost", ok)


func _on_rest() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = REST_PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self)
