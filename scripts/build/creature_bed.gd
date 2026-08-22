extends Node3D

## Gate A physical-rest implementation. The authoritative recovery state lives
## on the CreatureInstance/Game; this placed node owns only which bed index it is,
## assignment UI, and the visible sleeping body.

const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const REST_PANEL := preload("res://scripts/ui/creature_bed_panel.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

## GATEB-FLAGS: the ladder's `creature_bed_built` CONTRACT flag
## (data/progression/objectives.json) -- set the instant this object is
## actually placed, not merely armed/ghosted, so the HUD's next line clears
## on the real interaction the objective names.
const CREATURE_BED_FLAG := "creature_bed_built"

const MESH_PATH := "res://assets/props/quaternius_fantasy/Bed_Twin1.gltf"
const REST_ANCHOR := Vector3(0.0, 0.42, 0.0)

static var _panel: CanvasLayer = null
var _piece: Node3D = null
var _build_index: int = -1
var _rest_body: Node3D = null
var _last_occupant: int = -2


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
	var game := get_node_or_null(^"/root/Game")
	var progression: RefCounted = game.get("progression") if game != null else null
	if progression != null:
		progression.call("set_flag", CREATURE_BED_FLAG)


func tint_ghost(ok: bool) -> void:
	if _piece != null and is_instance_valid(_piece):
		_piece.call("tint_ghost", ok)


func set_build_index(index: int) -> void:
	_build_index = index
	_sync_rest_body(true)


func build_index() -> int:
	return _build_index


func occupant_index() -> int:
	if _build_index < 0:
		return -1
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	if party == null:
		return -1
	for i in party.call("size"):
		var creature: RefCounted = party.call("at", i)
		if creature != null and bool(creature.get("resting")) \
				and int(creature.get("rest_bed_index")) == _build_index:
			return i
	return -1


func assign_creature(index: int) -> bool:
	if _build_index < 0 or occupant_index() >= 0:
		return false
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	var creature: RefCounted = party.call("at", index) if party != null else null
	if creature == null or bool(creature.get("resting")):
		return false
	if not bool(party.call("set_resting", index, true, _build_index)):
		return false
	_sync_rest_body(true)
	return true


func wake_creature_early() -> bool:
	var index := occupant_index()
	if index < 0:
		return false
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	var creature: RefCounted = party.call("at", index) if party != null else null
	if creature == null:
		return false
	# HP already regenerated directly on the instance; clearing assignment is
	# all early wake does. No full-heal/rested bonus is granted.
	creature.set("rested", false)
	party.call("set_resting", index, false)
	_sync_rest_body(true)
	return true


func is_occupied() -> bool:
	return occupant_index() >= 0


func _process(_delta: float) -> void:
	_sync_rest_body(false)


func _sync_rest_body(force: bool) -> void:
	var index := occupant_index()
	if not force and index == _last_occupant:
		return
	_last_occupant = index
	if _rest_body != null and is_instance_valid(_rest_body):
		_rest_body.queue_free()
	_rest_body = null
	if index < 0:
		return
	var game := get_node_or_null(^"/root/Game")
	var party: RefCounted = game.get("party") if game != null else null
	var creature: RefCounted = party.call("at", index) if party != null else null
	if creature == null:
		return
	_rest_body = CREATURE_SCENE.instantiate() as Node3D
	if _rest_body == null:
		return
	_rest_body.name = "RestingCreature"
	_rest_body.set_script(CREATURE_BODY)
	add_child(_rest_body)
	_rest_body.call("setup", str(creature.get("species_id")), bool(creature.get("shiny")))
	_rest_body.position = REST_ANCHOR
	_rest_body.rotation.y = PI * 0.5
	_rest_body.collision_layer = 0
	_rest_body.collision_mask = 0
	_rest_body.set_physics_process(false)
	# Reuse the shipped creature faint/lie animation as the closest authored
	# resting pose. The body is visibly in bed and non-interactive; visual-judge
	# decides whether a later dedicated sleep pose is warranted.
	_rest_body.call_deferred("play_faint")


func _on_rest() -> void:
	if _panel == null or not is_instance_valid(_panel):
		_panel = REST_PANEL.new()
		get_tree().root.add_child(_panel)
	_panel.call("open", self)
