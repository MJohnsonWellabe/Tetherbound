extends Node3D

## R7.8: the door verb. One script, reused by every prefab that declares a
## `door` in its recipe (data/config/building_prefabs.json) — not a bespoke
## door per building.
##
## Composes `interactable.gd` rather than registering with the arbiter
## itself (interaction_arbiter.gd's own provider contract), because a door is
## exactly the thing interactable.gd already describes: something the player
## walks up to and presses a button on, wall-mounted, needing the same
## line-of-sight check Grandpa's prompt does. `riding_controller.gd` skips
## that check because nothing can occlude a mount standing in the open; a
## door is set INTO a wall, so it keeps it.
##
## Grandpa's `set_door_open()` (grandpa_house.gd) is not the precedent here —
## that gate is polled by sequence_director.gd and has no player verb at all.
## This one flips on `interaction_activate()` and owns its own state.
##
## The doorway hole itself is authored once in building_prefabs.json's
## `colliders` array (a permanent gap, same shape cottage_a's kit recipe
## already used while its leaf stood hard open). What THIS script adds is the
## one collider that makes a shut door actually block the opening — the leaf
## mesh already sitting in the kit shell is only ever a picture without it.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")

const SWING_TIME := 0.45
## kit door: DoorFrame_Flat_WoodDark, a 2.3m-tall ~1.6m-clear opening.
const DEFAULT_WIDTH := 1.6
const DEFAULT_HEIGHT := 2.3
## Wall body thickness, matching every hand-authored `colliders` box in
## building_prefabs.json (cottage_a's own lintel/side pieces use the same
## 0.45 for the kit's wall depth).
const GATE_THICKNESS := 0.45

var _leaf: Node3D = null
var _gate_shape: CollisionShape3D = null
var _interactable: Node3D = null
var _closed_yaw := 0.0  # radians, captured from the leaf's authored rest pose
var _open_yaw := 0.0    # radians
var _open := false
var _tween: Tween = null


## `leaf`: the door leaf mesh node already in the tree (a direct child of the
## building, found by building_prefabs.gd's `door_leaf_index`). `door_at`:
## the doorway centre in the SAME local space the leaf's own position is in.
func setup(leaf: Node3D, door_at: Vector3, label_noun: String,
		width := DEFAULT_WIDTH, height := DEFAULT_HEIGHT,
		open_yaw_deg := -100.0) -> void:
	_leaf = leaf
	_closed_yaw = leaf.rotation.y
	_open_yaw = deg_to_rad(open_yaw_deg)
	position = door_at

	var body := StaticBody3D.new()
	body.name = "Gate"
	_gate_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, height, GATE_THICKNESS)
	_gate_shape.shape = box
	body.add_child(_gate_shape)
	body.position = Vector3(0.0, height * 0.5, 0.0)
	add_child(body)

	_interactable = INTERACTABLE.new()
	_interactable.name = "Prompt"
	add_child(_interactable)
	_interactable.position = Vector3(0.0, height * 0.5, 0.0)
	_interactable.call("configure", "Open %s" % label_noun, 3.0)
	_interactable.connect("activated", _on_activated)


func _on_activated() -> void:
	_open = not _open
	if _gate_shape != null:
		_gate_shape.disabled = _open
	if _interactable != null:
		_interactable.set("label", ("Close %s" if _open else "Open %s") % _label_noun())
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var target_yaw := _open_yaw if _open else _closed_yaw
	if _leaf != null:
		_tween.tween_property(_leaf, "rotation:y", target_yaw, SWING_TIME)


func _label_noun() -> String:
	# The label the prompt was configured with the noun already appended
	# ("Open Door") -- strip the verb back off rather than storing the noun
	# twice.
	var current: String = str(_interactable.get("label"))
	for verb in ["Open ", "Close "]:
		if current.begins_with(verb):
			return current.substr(verb.length())
	return current


func is_open() -> bool:
	return _open


## Test/story hook, same shape as grandpa_house.gd's `set_door_open` so a
## smoke test can drive the gate directly without simulating an interact
## press through the arbiter.
func force_open(open: bool) -> void:
	if _open == open:
		return
	_on_activated()
