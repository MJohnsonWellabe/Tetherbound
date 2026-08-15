extends Node3D

## R4.4: a TM sitting in the world. Picking it up is not an inventory pickup
## like key_pickup.gd's key -- GAME_DESIGN.md 13 says a TM is "not consumed
## after one teaching", which means it is not consumed by ANY teaching: the
## physical prop is a one-time find, but what it grants (the move is now
## teachable) is permanent knowledge, not a held item with a use count. So
## this sets a flag on progression_state (SB9's flat flag store, namespaced
## `tm:<id>` so it cannot collide with an objective/completion flag that
## happens to share a plain id) and disappears, rather than joining the
## satchel.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const TM_DB := preload("res://scripts/creatures/tm_db.gd")

## progression_state flag ids for TMs live in this namespace so a TM id and
## an unrelated objective/completion flag can never collide in the one flat
## store SB9 documents.
const FLAG_PREFIX := "tm:"

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
		push_error("no Game autoload; a TM was found but has nowhere to record it")
		return
	var progression: RefCounted = game.get("progression")
	if progression == null:
		push_error("no progression_state; a TM was found but has nowhere to record it")
		return
	progression.call("set_flag", FLAG_PREFIX + _tm_id)
	queue_free()
