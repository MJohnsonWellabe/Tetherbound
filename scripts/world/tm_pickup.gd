extends Node3D

## A TM sitting in the world, picked up into the satchel.
##
## R4.4 originally argued the opposite: GAME_DESIGN.md 13's "not consumed
## after one teaching" was read as "a TM is permanent knowledge, not an
## object", so this set a `tm:<id>` progression flag and vanished. OF29
## overrules that on the owner's own words -- "I can pick up a TM but it needs
## to go in my inventory and then I see it's stats and choose who to teach it
## to." A thing you inspect and then spend on ONE creature is an item, not a
## flag, and there is nowhere but the satchel for an item to live. So this is
## now exactly key_pickup.gd's contract: `inventory.add`, and a full satchel
## REFUSES -- the prop stays in the world, still offering, rather than
## deleting a find the player cannot carry yet.
##
## The `tm:<id>` flag survives, with a narrower job: "this world pickup has
## been taken". `playground_world.gd::_place_tms()` reads it and skips
## placing an already-taken TM, which is what stops a reload from minting a
## fresh copy now that the pickup grants a real item. Old saves carrying that
## flag from before OF29 therefore keep their TM prop gone and get no free
## item -- see that function's own comment for the migration note.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const TM_DB := preload("res://scripts/creatures/tm_db.gd")

## progression_state flag ids for TMs live in this namespace so a TM id and
## an unrelated objective/completion flag can never collide in the one flat
## store SB9 documents. Set once the pickup is actually taken (OF29: "taken
## from the world", no longer "this move is teachable forever").
const FLAG_PREFIX := "tm:"

## A `kind: "tm"` item id is the SAME string as its data/moves/tms.json id
## (see items.json's own `_comment_tm`), so this prop hands `_tm_id` straight
## to the satchel with no mapping table to keep in step -- and
## tests/test_moves.gd asserts the two files agree in both directions.

var _tm_id: String = ""
var _tms: RefCounted = null


func setup(tm_id: String) -> void:
	_tm_id = tm_id
	_tms = TM_DB.load_default()
	_build_visual()

	var prompt := INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3.UP * 0.5
	prompt.call("configure", "Learn %s" % str(_tms.call("display_name", _tm_id)), 2.4, true)
	prompt.connect("activated", _on_picked_up)
	add_child(prompt)


## A flat standing tablet, not key_pickup.gd's dropped-key shaft-and-ring --
## a TM is found knowledge, not a found object with a hand-holdable shape,
## so it reads better as something planted upright than something lying on
## the ground. Emissive for the same reason key_pickup.gd's key is: the
## Compatibility renderer's flat ambient leaves a purely-diffuse small prop
## unreadable at a distance (see that file's own material comment).
func _build_visual() -> void:
	var colour: Color = _tms.call("colour", _tm_id) if _tms != null else Color(0.6, 0.6, 0.6)

	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.metallic = 0.05
	material.roughness = 0.5
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 0.9

	var slab := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.32, 0.46, 0.04)
	slab.mesh = box
	slab.material_override = material
	slab.position = Vector3.UP * 0.28
	add_child(slab)

	var rune := MeshInstance3D.new()
	var rune_mesh := BoxMesh.new()
	rune_mesh.size = Vector3(0.16, 0.16, 0.01)
	rune.mesh = rune_mesh
	var rune_material := StandardMaterial3D.new()
	rune_material.albedo_color = Color(1.0, 1.0, 1.0)
	rune_material.emission_enabled = true
	rune_material.emission = Color(1.0, 1.0, 1.0)
	rune_material.emission_energy_multiplier = 1.4
	rune.material_override = rune_material
	rune.position = Vector3(0.0, 0.28, 0.026)
	add_child(rune)


func _on_picked_up() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; a TM was found but has nowhere to go")
		return
	var inventory: RefCounted = game.get("inventory")
	if inventory == null:
		push_error("no inventory; a TM was found but has nowhere to go")
		return
	if not bool(inventory.call("has_room_for", _tm_id, 1)):
		# Refused, visibly, same as key_pickup.gd/harvest_node.gd: the disc
		# stays planted and keeps offering rather than vanishing into a full
		# satchel. The flag below is deliberately NOT set on this path -- a
		# TM that is still in the world must not be recorded as taken.
		game.call("push_world_message", "Satchel is full.")
		return
	inventory.call("add", _tm_id, 1)
	var progression: RefCounted = game.get("progression")
	if progression != null:
		progression.call("set_flag", FLAG_PREFIX + _tm_id)
	queue_free()
