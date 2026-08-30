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
const PICKUP_GLOW := preload("res://scripts/world/pickup_glow.gd")
const STORAGE_PANEL := preload("res://scripts/ui/storage_panel.gd")

const MESH_PATH := "res://assets/props/quaternius_fantasy/Bag.gltf"
const MESH_SCALE := 0.6

## The bag's own leather, warmed. A satchel holds whatever the player was
## carrying, so unlike every other pickup it has no single item colour to
## borrow -- and a warm tan is what separates "your dropped bag" from the
## cooler mineral tints the caches and deposits carry.
const SATCHEL_GLOW_COLOUR := Color("#e0a860")

## R3.2. Every death satchel joins this group, the same pattern
## `build_placer.gd`'s `PLACED_GROUP` uses for placed buildings — it is what
## lets `player_death.gd::sync_state_to_game`/`restore_from_game` find every
## live satchel in the scene without `GameState` needing a direct handle on
## each one.
const GROUP := "death_satchel"

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
	_build_visuals()


## R3.2. The load-side counterpart to `build()`: rehydrate a satchel from
## `storage_state.gd::save_data()`'s own output (a full-width array, `null`
## for an empty slot — see that file's header) instead of from a fresh
## `drain()`. `state.load_data` already re-coerces `n`/`durability` back from
## JSON's float-only numbers, so this needs no extra conversion of its own.
func restore(data: Variant, db: RefCounted) -> void:
	state = STORAGE_STATE.new(db)
	state.call("load_data", data)
	_build_visuals()


## OF20: `Bag.gltf` imports as a PackedScene (same pack, same `.import`
## sidecar shape as harvest_node.gd's own models), so `load(MESH_PATH)` handed
## straight to `MeshInstance3D.mesh` was an invalid assignment -- every death
## satchel was invisible. Same PackedScene-vs-Mesh branch as
## `harvest_node.gd::_build_visual` now uses, wrapped in a plain Node3D so
## `.scale` applies to the whole bag.
func _build_visuals() -> void:
	add_to_group(GROUP)

	if ResourceLoader.exists(MESH_PATH):
		var resource: Resource = load(MESH_PATH)
		if resource is PackedScene:
			var wrapper := Node3D.new()
			wrapper.add_child((resource as PackedScene).instantiate())
			wrapper.scale = Vector3.ONE * MESH_SCALE
			add_child(wrapper)
		elif resource is Mesh:
			var mesh := MeshInstance3D.new()
			mesh.mesh = resource as Mesh
			mesh.scale = Vector3.ONE * MESH_SCALE
			add_child(mesh)
		else:
			push_warning("death satchel mesh '%s' loaded as neither a Mesh nor a PackedScene" % MESH_PATH)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0.0, 0.5, 0.6)
	prompt.call("configure", "Open Satchel", 2.6, true)
	prompt.connect("activated", _on_open)
	add_child(prompt)

	# OP-0830-3. A death satchel is the one pickup the player is actively
	# HUNTING for, dropped wherever they happened to fall -- which is as likely
	# to be deep cover as open road. The shared highlight
	# (scripts/world/pickup_glow.gd) is what makes it findable; the tint is the
	# bag's own leather rather than an item colour, because a satchel is a
	# container and has no single item to speak for it.
	#
	# Registered AFTER the mesh, not before: `pickup_glow.gd` measures the
	# prop's own crown to decide where the mote sits, and a satchel that had not
	# built its bag yet would measure as flat.
	PICKUP_GLOW.attach(self, SATCHEL_GLOW_COLOUR)


func _on_open() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = STORAGE_PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self)
