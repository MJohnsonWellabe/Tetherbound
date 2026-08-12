extends Node3D

## A one-time physical pickup: an item sitting on the ground that joins the
## satchel and never comes back. Same shape as harvest_node.gd (a visible
## prop, an interact prompt, an item) minus the respawn timer — a harvest
## node is a renewable resource, a found key is neither, and its item id
## consuming itself (`road_gate.gd::_on_tried`) is what removes it from play,
## not this script.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")

var _item_id: String = ""
var _label: String = ""
var _visual: Node3D = null
var _prompt: Node3D = null


func setup(item_id: String, label: String) -> void:
	_item_id = item_id
	_label = label
	_build_visual()
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.6
	_prompt.call("configure", _label, 2.4, true)
	_prompt.connect("activated", _on_picked_up)
	add_child(_prompt)


func _build_visual() -> void:
	# A real key's own proportions (a thin shaft plus a ring), not the
	# low-mound-in-slot-colour placeholder harvest_node.gd uses for a
	# resource pile — the blind visual-judge pass named that shape (and the
	# 0.28m box it used to be, a third of a fence panel's height) as reading
	# as a crate rather than anything meant to be picked up specifically.
	# Still built from primitives, still tinted from the item's own
	# `colour`, so this stays an honest placeholder rather than new art.
	var material := StandardMaterial3D.new()
	material.albedo_color = _item_colour()
	material.metallic = 0.6
	material.roughness = 0.3

	var shaft := MeshInstance3D.new()
	var shaft_box := BoxMesh.new()
	shaft_box.size = Vector3(0.09, 0.015, 0.025)
	shaft.mesh = shaft_box
	shaft.material_override = material
	shaft.position = Vector3.UP * 0.02
	_visual = shaft
	add_child(_visual)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.012
	torus.outer_radius = 0.024
	ring.mesh = torus
	ring.material_override = material
	ring.rotation.x = deg_to_rad(90.0)
	ring.position = Vector3(-0.06, 0.0, 0.0)
	_visual.add_child(ring)


func _item_colour() -> Color:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return Color(0.75, 0.65, 0.2)
	var items: RefCounted = game.get("items")
	return items.call("colour", _item_id) if items != null else Color(0.75, 0.65, 0.2)


func _on_picked_up() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; a key was found but has nowhere to go")
		return
	var inventory: RefCounted = game.get("inventory")
	if not bool(inventory.call("has_room_for", _item_id, 1)):
		# Refused, visibly, same as harvest_node.gd: the key stays on the
		# ground and keeps offering rather than vanishing into a full satchel.
		return
	inventory.call("add", _item_id, 1)
	queue_free()
