extends Node3D

## R2.7. A placed storage chest: `build_piece.gd`'s generic geometry, plus a
## real, independent inventory (`storage_state.gd`) and an interact prompt
## that opens the transfer panel — the second `buildables.json` entry after
## `camp` that carries state, so it gets its own hand-authored script the
## same way `camp.gd` does, rather than teaching `build_piece.gd` to
## sometimes have state and sometimes not.

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const STORAGE_STATE := preload("res://scripts/world/storage_state.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const STORAGE_PANEL := preload("res://scripts/ui/storage_panel.gd")

const MESH_PATH := "res://assets/props/quaternius_fantasy/Crate_Wooden.gltf"

## Not owned per-instance: one panel node is reused and re-pointed at
## whichever chest opened it, the same one-instance-built-lazily pattern
## camp.gd uses for its own craft panel.
static var _panel: CanvasLayer = null

var state: RefCounted = null

var _piece: Node3D = null


func build_ghost() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.call("build_ghost", MESH_PATH)


func build_real() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.call("build_real", MESH_PATH)

	var game := get_node_or_null(^"/root/Game")
	var db: RefCounted = game.get("items") if game != null else null
	state = STORAGE_STATE.new(db)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0.0, 0.6, 0.7)
	prompt.call("configure", "Open Storage", 2.6, true)
	prompt.connect("activated", _on_open)
	add_child(prompt)


## Legal (green) or not (red), at ghost alpha either way — delegated to the
## same build_piece.gd every other non-camp entry uses.
func tint_ghost(ok: bool) -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.call("tint_ghost", ok)


func _on_open() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = STORAGE_PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self)
