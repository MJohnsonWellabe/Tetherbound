extends Node3D

## T3-ACTIVITIES. Spec sec6's "Broken Cart: gather materials to repair a
## bridgehand's cart" -- Band 1's Local Request.
##
## Reuses two mechanisms that already exist rather than inventing a third
## "turn in materials" system: `item_gate.gd` (SB10, already the South Bridge
## key's and the three Sigils' own "does the player have what it takes" check
## -- a multi-item gate consumes exactly one of each id it names, which is
## what "gather wood, stone and fiber and hand them over" needs) and the
## `building_prefabs.gd`/`Prop_Wagon` visual `data/config/village.json`
## already parks once by the workshop (`_why`: "Bible secE names carts among
## what embeds a building"). No new mesh, no new turn-in mechanic.
##
## Deliberately NOT `road_gate.gd`: that file's own leaf/lock/wing machinery
## exists to physically block a road, and a parked cart on the shoulder blocks
## nothing. This is the same shape stripped to what a stationary, repairable
## prop actually needs -- a visual, a collision box so it reads as a real
## object, a prompt, and the shared item_gate contract.

const PREFABS := preload("res://scripts/world/building_prefabs.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const ITEM_GATE := preload("res://scripts/world/item_gate.gd")

const PREFAB_NAME := "wagon"
const ITEM_IDS := ["wood", "stone", "fiber"]
const FLAG_ID := "band1_broken_cart_repaired"
const MET_FLAG := "broken_cart_met"
const BROKEN_CONVERSATION := "broken_cart_broken"
const REPAIRED_CONVERSATION := "broken_cart_repaired"

var _gate: RefCounted = null
var _prompt: Node3D = null


func build(world: Node3D, at: Vector2, yaw_deg: float) -> void:
	_gate = ITEM_GATE.new(ITEM_IDS, FLAG_ID)
	var prefabs: RefCounted = PREFABS.new()
	if not prefabs.call("load_recipes"):
		push_error("no building recipes; the broken cart cannot build its wagon")
		return
	var template_holder := Node3D.new()
	template_holder.name = "PrefabTemplates"
	template_holder.visible = false
	add_child(template_holder)
	prefabs.call("set_template_holder", template_holder)

	var wagon: Node3D = prefabs.call("instantiate", PREFAB_NAME)
	if wagon == null:
		push_error("broken cart prefab missing: %s" % PREFAB_NAME)
		return

	var ground: float = float(world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		push_error("no ground under the broken cart at %.0f, %.0f" % [at.x, at.y])
		return

	position = Vector3(at.x, ground - 0.05, at.y)
	rotation.y = deg_to_rad(yaw_deg)
	wagon.name = "Wagon"
	add_child(wagon)

	var aabb: AABB = prefabs.call("combined_aabb", wagon)
	var body := StaticBody3D.new()
	body.name = "Collision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = aabb.size
	shape.shape = box
	shape.position = aabb.get_center()
	body.add_child(shape)
	add_child(body)

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 1.0
	_prompt.call("configure", "Look at the cart", 3.6, true)
	_prompt.connect("activated", _on_tried)
	add_child(_prompt)

	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null and _gate.is_open(progression):
		_prompt.call("set_enabled", false)


func is_repaired() -> bool:
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	return progression != null and _gate.is_open(progression)


func _on_tried() -> void:
	if is_repaired():
		return
	var game := get_node_or_null(^"/root/Game")
	var inventory: RefCounted = game.get("inventory") if game != null else null
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null:
		progression.call("set_flag", MET_FLAG)
	if inventory != null and progression != null and _gate.try_open(inventory, progression):
		_prompt.call("set_enabled", false)
		_say(REPAIRED_CONVERSATION)
	else:
		_say(BROKEN_CONVERSATION)


func _say(conversation_id: String) -> void:
	var panel := get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		push_warning("no node in the 'dialogue_panel' group; the cart has nothing to say")
		return
	if bool(panel.call("is_open")):
		return
	panel.call("start", conversation_id)
