extends Node3D

## One gatherable spot: a visible prop, an interact prompt, and an item that
## lands in the satchel.
##
## The first day's gathering, deliberately NOT the real harvesting system. M8's
## tools-and-durability loop works the instanced vegetation itself; these are
## a dozen hand-placed nodes along the tutorial path (data/config/harvest.json)
## so "gather enough to make camp" is playable today without touching ten
## thousand MultiMesh instances. When M8 lands, these become the tutorial-only
## seed spots or disappear — either is fine, nothing else depends on them.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")

const RESPAWN_SECONDS := 60.0

var _item_id: String = ""
var _amount: int = 0
var _label: String = ""
var _model_path: String = ""
var _model_scale: float = 1.0
var _prompt: Node3D = null
var _visual: Node3D = null
var _respawn_left: float = 0.0


func setup(spec: Dictionary) -> void:
	_item_id = str(spec.get("item", "wood"))
	_amount = int(spec.get("amount", 3))
	_label = str(spec.get("label", "Gather"))
	_model_path = str(spec.get("model", ""))
	_model_scale = float(spec.get("model_scale", 1.0))

	_build_visual()
	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * 0.6
	_prompt.call("configure", _label, 2.4, true)
	_prompt.connect("activated", _on_gathered)
	add_child(_prompt)


func _build_visual() -> void:
	if _model_path != "" and ResourceLoader.exists(_model_path):
		var mesh := MeshInstance3D.new()
		mesh.mesh = load(_model_path)
		mesh.scale = Vector3.ONE * _model_scale
		_visual = mesh
	else:
		# A low mound in the item's own slot colour: legible from a distance
		# without pretending to be final art.
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.7, 0.35, 0.7)
		mesh.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = _item_colour()
		material.roughness = 0.9
		mesh.material_override = material
		mesh.position = Vector3.UP * 0.18
		_visual = mesh
	add_child(_visual)


func _item_colour() -> Color:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		return Color(0.6, 0.5, 0.4)
	var items: RefCounted = game.get("items")
	return items.call("colour", _item_id) if items != null else Color(0.6, 0.5, 0.4)


func _on_gathered() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; gathered %s into nothing" % _item_id)
		return
	var inventory: RefCounted = game.get("inventory")
	if not bool(inventory.call("has_room_for", _item_id, _amount)):
		# Refused, visibly: the node stays and the prompt keeps offering, which
		# is the honest version of "your satchel is full".
		return
	inventory.call("add", _item_id, _amount)
	_visual.visible = false
	_prompt.call("set_enabled", false)
	_respawn_left = RESPAWN_SECONDS
	set_process(true)


func _process(delta: float) -> void:
	if _respawn_left <= 0.0:
		set_process(false)
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		_visual.visible = true
		_prompt.call("set_enabled", true)
		set_process(false)


func _ready() -> void:
	set_process(false)
