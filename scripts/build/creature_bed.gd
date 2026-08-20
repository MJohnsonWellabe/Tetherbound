extends Node3D

## R4.8. A placed creature bed: `build_piece.gd`'s generic geometry, plus a
## real interaction -- the same "carries state and an interaction, so it gets
## its own hand-authored script" shape `storage_container.gd` already set
## (R2.7). GAME_DESIGN.md 16/20's full brief for the `creature_bed` buildable
## (`R2.8` shipped it as a bare, non-interactive placeable and deferred this
## part on purpose: "revives a fainted creature... visible creature rest
## behaviour") lands here.

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const REST_PANEL := preload("res://scripts/ui/creature_bed_panel.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

const MESH_PATH := "res://assets/props/quaternius_fantasy/Bed_Twin1.gltf"

## One panel, reused and re-pointed at whichever bed opened it -- the same
## lazily-built shared-panel shape `storage_container.gd` uses for its own
## transfer screen.
static var _panel: CanvasLayer = null

var _piece: Node3D = null
var _occupant: RefCounted = null
var _resting_body: Node3D = null


func build_ghost() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.call("build_ghost", MESH_PATH)


func build_real() -> void:
	_piece = BUILD_PIECE.new()
	add_child(_piece)
	_piece.call("build_real", MESH_PATH)

	var prompt: Node3D = INTERACTABLE.new()
	prompt.name = "Interactable"
	prompt.position = Vector3(0.0, 0.6, 0.7)
	prompt.call("configure", "Rest a Creature", 2.6, true)
	prompt.connect("activated", _on_rest)
	add_child(prompt)


## Legal (green) or not (red), at ghost alpha either way -- delegated to the
## same build_piece.gd every other non-camp/storage entry uses.
func tint_ghost(ok: bool) -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.call("tint_ghost", ok)


func _on_rest() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = REST_PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self)


func occupant() -> RefCounted:
	if _occupant != null and not bool(_occupant.get("resting")):
		_occupant = null
		_clear_occupant_body()
	return _occupant


func assign(creature: RefCounted) -> bool:
	if creature == null or occupant() != null:
		return false
	if not bool(creature.call("begin_bed_rest")):
		return false
	_occupant = creature
	_show_occupant(creature)
	return true


func wake() -> RefCounted:
	var creature := occupant()
	if creature == null:
		return null
	creature.call("wake_from_bed")
	_occupant = null
	_clear_occupant_body()
	return creature


func is_occupied() -> bool:
	return occupant() != null


func resting_body() -> Node3D:
	return _resting_body


func _show_occupant(creature: RefCounted) -> void:
	_clear_occupant_body()
	_resting_body = CREATURE_SCENE.instantiate()
	_resting_body.name = "RestingCreature"
	_resting_body.set_script(CREATURE_BODY)
	# The bed is a readable care vignette, not a second full-size combat body.
	# Keep the creature upright in its authored model frame and let play_faint()
	# supply the resting pose; rotating the CharacterBody itself put large
	# quadrupeds vertically through the mattress. Scale is deliberately modest
	# so every Meadows species remains visibly contained by this shared bed.
	_resting_body.position = Vector3(0.0, 0.14, -0.05)
	_resting_body.rotation = Vector3(0.0, PI * 0.5, 0.0)
	_resting_body.scale = Vector3.ONE * 0.32
	_resting_body.set_physics_process(false)
	add_child(_resting_body)
	_resting_body.call("setup", str(creature.get("species_id")), bool(creature.get("shiny")))
	var model := _resting_body.call("model_pivot") as Node3D
	if model != null:
		model.rotation.z = PI * 0.5
		model.position = Vector3(0.0, 0.0, 0.0)
	var collision := _resting_body.get_node_or_null(^"Collision") as CollisionShape3D
	if collision != null:
		collision.disabled = true


func _clear_occupant_body() -> void:
	if _resting_body != null and is_instance_valid(_resting_body):
		_resting_body.queue_free()
	_resting_body = null
