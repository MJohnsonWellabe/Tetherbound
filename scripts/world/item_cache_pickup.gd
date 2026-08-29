extends Node3D

## T3-PICKUPS. A one-time, non-renewable item find: the mechanism
## `key_pickup.gd` already proves (item_id -> satchel, a `pickup:<id>` flag
## that survives reload, refuse-not-vanish on a full satchel) with the one
## piece that doesn't generalise -- a literal key-shaped mesh -- swapped for
## a plain prop, loaded the same PackedScene-vs-Mesh way
## `harvest_node.gd::_build_visual()` and `props.gd::place()` already load
## every glTF in this project.
##
## Why not just call `key_pickup.gd` directly: its `setup(item_id, label)`
## really is generic (nothing in its persistence logic is key-specific), but
## `_build_visual()` hard-builds a shaft-and-ring key regardless of what
## `item_id` names. A permanent elixir sitting in the world as a brass key
## would read as a bug, not a find. This file exists ONLY to swap that one
## piece; the flag/inventory contract below is deliberately the same shape,
## not a second design.
##
## `data/items/items.json` has no `_comment` claiming every world item must
## be a `key_pickup`/`tm_pickup` -- both are already item-id-driven, both
## already coexist as separate one-time pickup props, and CLAUDE.md's own
## reuse rule is "prefer existing infrastructure", not "there may be only
## one file". No new inventory, currency, recipe or loot system is added:
## this is a third THIN PROP wired to the one satchel every pickup already
## shares.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")

const FLAG_PREFIX := "cache:"


var _item_id: String = ""
var _label: String = ""
var _model_path: String = ""
var _model_scale: float = 1.0
var _visual: Node3D = null
var _prompt: Node3D = null


func setup(item_id: String, label: String, model_path: String, model_scale: float = 1.0) -> void:
	_item_id = item_id
	_label = label
	_model_path = model_path
	_model_scale = model_scale
	add_to_group("progression_restore")
	_build_visual()
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.6
	_prompt.call("configure", _label, 2.4, true)
	_prompt.connect("activated", _on_picked_up)
	add_child(_prompt)
	var game := get_node_or_null(^"/root/Game")
	if was_taken(game, _item_id):
		_deactivate()


static func flag_id(item_id: String) -> String:
	return FLAG_PREFIX + item_id


static func was_taken(game: Node, item_id: String) -> bool:
	if game == null or item_id == "":
		return false
	var progression: RefCounted = game.get("progression")
	return progression != null and bool(progression.call("has", flag_id(item_id)))


func restore_progression_from_game(game: Node) -> void:
	if was_taken(game, _item_id):
		_deactivate()


func _deactivate() -> void:
	if _prompt != null and is_instance_valid(_prompt):
		_prompt.call("set_enabled", false)
	visible = false
	queue_free()


## Same PackedScene-vs-Mesh branch harvest_node.gd::_build_visual() and
## props.gd::place() already use for this exact glTF pack -- a bare
## `load()` result assigned straight to `MeshInstance3D.mesh` type-fails
## silently on a multi-part scene.
func _build_visual() -> void:
	if _model_path != "" and ResourceLoader.exists(_model_path):
		var resource: Resource = load(_model_path)
		if resource is PackedScene:
			var wrapper := Node3D.new()
			wrapper.add_child((resource as PackedScene).instantiate())
			wrapper.scale = Vector3.ONE * _model_scale
			_visual = wrapper
		elif resource is Mesh:
			var mesh := MeshInstance3D.new()
			mesh.mesh = resource as Mesh
			mesh.scale = Vector3.ONE * _model_scale
			_visual = mesh
	if _visual == null:
		var fallback := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.3
		fallback.mesh = box
		_visual = fallback
		push_warning("item_cache_pickup: '%s' did not load as a Mesh or PackedScene" % _model_path)
	add_child(_visual)

	# A light of its own, the same short-range presence cue tm_pickup.gd's
	# own header argues for: this is a one-time find worth noticing, met at
	# dusk or in cover as often as in the open.
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.light_color = Color(0.85, 0.72, 0.35)
	glow.light_energy = 0.7
	glow.omni_range = 3.0
	glow.position = Vector3.UP * 0.5
	add_child(glow)


func _on_picked_up() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; a cache was found but has nowhere to go")
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		push_error("no inventory; a cache was found but has nowhere to go")
		return
	if not bool(inventory.call("has_room_for", _item_id, 1)):
		# Refused, visibly, same as key_pickup.gd/harvest_node.gd: stays in
		# the world and keeps offering rather than vanishing into a full
		# satchel.
		game.call("push_world_message", "Satchel is full.")
		return
	inventory.call("add", _item_id, 1)
	var progression: RefCounted = game.get("progression")
	if progression != null:
		progression.call("set_flag", flag_id(_item_id))
	_deactivate()
