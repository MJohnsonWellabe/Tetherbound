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
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")

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


## OF20. Every `model` in data/config/harvest.json is a `.gltf` from the
## Quaternius stylized-nature kit (see the header above, R9.4), and a glTF
## imports as a PackedScene, not a bare Mesh (check the `.import` sidecar:
## `type="PackedScene"`). `load(_model_path)` handed straight to
## `MeshInstance3D.mesh` was therefore an invalid assignment on every single
## authored node — none of the twelve ever rendered. Branch on what `load()`
## actually returns, the same PackedScene-vs-Mesh fork
## `grandpa_house.gd::_furnish` and `props.gd::_place` already use for this
## exact pack. A PackedScene gets instantiated and wrapped in a plain Node3D
## so `_visual` stays a single node whose `.visible` and `.scale` mean "the
## whole prop" regardless of how many parts the scene's own root has.
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
		else:
			push_warning("harvest model '%s' loaded as neither a Mesh nor a PackedScene; falling back to the box" % _model_path)
			_visual = _box_visual()
	else:
		_visual = _box_visual()
	add_child(_visual)


## A low mound in the item's own slot colour: legible from a distance without
## pretending to be final art. The fallback for a node with no `model` at
## all, and now also for a `model` that loads as something unusable.
func _box_visual() -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.35, 0.7)
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = _item_colour()
	material.roughness = 0.9
	mesh.material_override = material
	mesh.position = Vector3.UP * 0.18
	return mesh


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
	var items: RefCounted = game.get("items")
	var actual_amount := _amount
	var required_slot := -1
	if items != null and inventory != null:
		var gathered: Dictionary = HARVEST_LOGIC.gather(_item_id, _amount, inventory, items)
		actual_amount = int(gathered["amount"])
		required_slot = int(gathered["required_slot"])

	if actual_amount <= 0:
		# The wrong tool for this resource: refused, and the node stays put for
		# whenever the player comes back with the right one. OF20: say so on
		# the HUD -- a silent refusal reads as "gathering does nothing at
		# all," which was the owner's actual bug report, and this rule only
		# starts firing once OF30 puts tools in a player's hands.
		if items != null:
			var required_tool := str(items.call("gathered_with", _item_id))
			if not required_tool.is_empty():
				game.call("push_world_message", "Needs a %s." % str(items.call("item_name", required_tool)))
		return
	if not bool(inventory.call("has_room_for", _item_id, actual_amount)):
		# Refused, visibly: the node stays and the prompt keeps offering, which
		# is the honest version of "your satchel is full".
		return
	inventory.call("add", _item_id, actual_amount)
	# R2.2: only a full-yield gather with the right tool wears it down --
	# a bare-handed or wrong-tool gather has no tool in play to damage.
	if required_slot >= 0:
		inventory.call("damage_tool", required_slot)
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
	# So a tool swing can find this without knowing which of the two gather
	# scripts drew it (`harvest_logic.gd::GROUP`).
	add_to_group(HARVEST_LOGIC.GROUP)

## Gather this spot, the same as pressing the interact prompt on it.
##
## Public so a tool swing (`scripts/player/tool_hold.gd`) can drive the exact
## same path the prompt drives -- one gather implementation, two ways to reach
## it, so a swing and a press can never disagree about yield, tool gating,
## durability or respawn.
func gather() -> void:
	_on_gathered()

