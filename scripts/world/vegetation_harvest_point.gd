extends Node3D

## R2.3: a gather point bolted onto one of `vegetation.gd`'s OWN scattered
## trees or rocks, instead of one of `harvest_node.gd`'s ~10 authored tutorial
## props. The tree/rock itself is the MultiMesh instance already rendered by
## `vegetation.gd` — this only adds a small marker so the owner's reported
## "gathering seems to randomly pop up" (nothing distinguishes a harvestable
## prop from a decorative one until the prompt appears at close range) has an
## answer at a real approach distance.
##
## The marker is a small standalone glint, not a tint on the tree/rock's own
## material. A per-instance MultiMesh colour multiply was tried first (the
## same mechanism R7.1-remainder uses for grass jitter) and reached two
## independent blind critics reading it as "diseased/scorched foliage... a
## texture-atlas glitch" rather than a marker, on both a red-dominant and a
## gold-balanced attempt — the leaf mesh's own baked per-vertex shading
## variation survives any multiply, so the failure was structural, not a
## colour-tuning miss. A small unshaded sphere sidesteps it entirely: it
## reads as UI-adjacent (a resource glint, the genre's own convention) rather
## than as part of the tree.
##
## Respawn is a prompt-and-glint cooldown, not a hide/show like
## `harvest_node.gd`'s resource piles. A pile vanishing after one gather reads
## as "spent, come back later"; a living tree vanishing reads as a bug — real
## trees don't disappear because you took a few logs off them. The glint
## dimming instead says "nothing to gather here right now" without erasing
## the tree.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const HARVEST_LOGIC := preload("res://scripts/world/harvest_logic.gd")

## Warm gold, unshaded and emissive so it reads the same at any time of day
## and against any material behind it -- a rock's own grey or a tree's own
## green. One colour for every resource rather than per-item, so "glinting"
## itself is the convention a player learns, not a colour per material.
## TUNABLE.
const GLINT_COLOUR := Color(1.0, 0.78, 0.25, 1.0)
const GLINT_RADIUS := 0.16

var _item_id: String = ""
var _amount: int = 0
var _respawn_seconds: float = 90.0
var _prompt: Node3D = null
var _glint: MeshInstance3D = null
var _respawn_left: float = 0.0


func setup(spec: Dictionary) -> void:
	_item_id = str(spec.get("item", "wood"))
	_amount = int(spec.get("amount", 2))
	_respawn_seconds = float(spec.get("respawn_seconds", 90.0))
	var prompt_height := float(spec.get("prompt_height", 1.4))

	_prompt = INTERACTABLE.new()
	_prompt.name = "Interactable"
	_prompt.position = Vector3.UP * prompt_height
	_prompt.call("configure", str(spec.get("label", "Gather")), 2.6, true)
	_prompt.connect("activated", _on_gathered)
	add_child(_prompt)

	_glint = _build_glint()
	# Offset out to one side rather than straight up from the base -- a real
	# tree/rock's own trunk or bulk sits exactly on this node's local origin,
	# so a glint placed directly above it renders INSIDE that geometry from
	# most angles instead of beside it. `vegetation.gd` sets this node's own
	# `position` (a real, distinct world spot) before calling setup(), so
	# hashing it gives a deterministic-but-varied bearing per instance
	# without needing a separate seed threaded through the spec dict.
	var bearing := float(hash(position) & 0xFFFFFF) / float(0xFFFFFF) * TAU
	_glint.position = Vector3(sin(bearing) * 1.3, prompt_height * 0.75, cos(bearing) * 1.3)
	add_child(_glint)


func _build_glint() -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = GLINT_RADIUS
	mesh.height = GLINT_RADIUS * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = GLINT_COLOUR
	material.emission_enabled = true
	material.emission = GLINT_COLOUR
	material.emission_energy_multiplier = 1.8

	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


func _on_gathered() -> void:
	var game := get_node_or_null(^"/root/Game")
	if game == null:
		push_error("no Game autoload; gathered %s into nothing" % _item_id)
		return
	var inventory: RefCounted = game.get("inventory")
	var items: RefCounted = game.get("items")
	if items == null or inventory == null:
		return
	var gathered: Dictionary = HARVEST_LOGIC.gather(_item_id, _amount, inventory, items)
	var actual_amount: int = int(gathered["amount"])
	if actual_amount <= 0:
		# The wrong tool for this resource: refused, and the tree stays put for
		# whenever the player comes back with the right one.
		return
	if not bool(inventory.call("has_room_for", _item_id, actual_amount)):
		# Refused, visibly: the prompt keeps offering, the honest version of
		# "your satchel is full".
		return
	inventory.call("add", _item_id, actual_amount)
	var required_slot: int = int(gathered["required_slot"])
	if required_slot >= 0:
		inventory.call("damage_tool", required_slot)
	_prompt.call("set_enabled", false)
	_glint.visible = false
	_respawn_left = _respawn_seconds
	set_process(true)


func _process(delta: float) -> void:
	if _respawn_left <= 0.0:
		set_process(false)
		return
	_respawn_left -= delta
	if _respawn_left <= 0.0:
		_prompt.call("set_enabled", true)
		_glint.visible = true


func _ready() -> void:
	set_process(false)
