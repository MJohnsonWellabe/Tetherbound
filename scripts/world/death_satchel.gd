extends Node3D

## GAME_DESIGN.md §22: on player death, everything carried drops into a
## satchel at the death location. Old satchels never move and several can
## coexist, so `player_death.gd` spawns a fresh one of these per death rather
## than reusing a single instance.
##
## Reuses `storage_state.gd`/`storage_panel.gd` wholesale — a death satchel
## is "another slot+stack container standing in the world," exactly the shape
## a placed chest (`storage_container.gd`) already is. `set_slot()` rather
## than `add()` because these are the exact stacks the player was carrying,
## durability and all, not a fresh deposit that should re-pack or re-stack.

const STORAGE_STATE := preload("res://scripts/world/storage_state.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const STORAGE_PANEL := preload("res://scripts/ui/storage_panel.gd")

const MESH_PATH := "res://assets/props/quaternius_fantasy/Bag.gltf"
const MESH_SCALE := 0.6

## Shared across every satchel the same way `storage_container.gd`'s own
## panel is shared across every chest — one screen, re-pointed at whichever
## container opened it.
static var _panel: CanvasLayer = null

var state: RefCounted = null


## `dropped` is `inventory.gd`'s `drain()` result: an ordered Array of
## `{id, n, ...}` stack dicts. `db` is the item database the transfer panel
## needs for names/icons, passed in rather than reached for through
## `/root/Game` so this stays testable headless the way `storage_state.gd` is.
func build(dropped: Array, db: RefCounted) -> void:
	state = STORAGE_STATE.new(db)
	for i in dropped.size():
		state.inventory.call("set_slot", i, dropped[i])

	if ResourceLoader.exists(MESH_PATH):
		var mesh := MeshInstance3D.new()
		mesh.mesh = load(MESH_PATH)
		mesh.scale = Vector3.ONE * MESH_SCALE
		add_child(mesh)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0.0, 0.5, 0.6)
	prompt.call("configure", "Open Satchel", 2.6, true)
	prompt.connect("activated", _on_open)
	add_child(prompt)


func _on_open() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = STORAGE_PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self)
