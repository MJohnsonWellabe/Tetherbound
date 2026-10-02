extends Node3D

## The paid BuildPiece keeps its original mesh/collision. This child only
## registers the actual source and offers the existing typed Training UI.
const PATH := "res://scripts/ui/altar_station_interaction.gd"
const NODE_NAME := "AltarInteraction"
const PROMPT := preload("res://scripts/world/interactable.gd")
const SERVICE := preload("res://scripts/ui/altar_service.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const BUILD_PIECE := preload("res://scripts/build/build_piece.gd")
var _game: Node
var _session: Node
var _building: WeakRef
var _world: WeakRef
var _namespace := ""
var _world_id := ""
var _key := ""
var _prompt: Node3D

static func attach(building: Node3D, game: Node) -> Node:
	if not is_instance_valid(building) or not building.is_inside_tree() or building.is_queued_for_deletion() \
		or building.get_script() != BUILD_PIECE or not is_instance_valid(game) \
		or not game.is_inside_tree() or not building.is_in_group("placed_building") \
		or building.get_meta("building_id", "") != "altar" or building.get_meta("realm", "") != "meadows": return null
	var existing := building.get_node_or_null(NodePath(NODE_NAME))
	if existing != null:
		return existing if existing.get_script() != null and existing.get_script().resource_path == PATH \
			and existing.call("_live_binding") == true else null
	var session: Variant = game.get("session")
	var world: Variant = game.get("world")
	var uid: Variant = building.get_meta("building_uid", "")
	if not session is Node or not is_instance_valid(session) or not world is RefCounted \
		or not ESSENCE._component(uid) or not ESSENCE._opaque_id(world.get("reward_delivery_namespace")) \
		or not ESSENCE._opaque_id(world.get("world_id")): return null
	for method: String in ["altar_canonical_producer_available", "_register_altar_station_node", "_unregister_altar_station_node", "altar_station_available"]:
		if not session.has_method(method): return null
	var key: String = "altar:meadows:" + uid
	if session.call("altar_canonical_producer_available") != true \
		or session.call("_register_altar_station_node", key, building) != true: return null
	var interaction: Node3D = load(PATH).new()
	interaction.name = NODE_NAME
	interaction.set("_game", game)
	interaction.set("_session", session)
	interaction.set("_building", weakref(building))
	interaction.set("_world", weakref(world))
	interaction.set("_namespace", world.reward_delivery_namespace)
	interaction.set("_world_id", world.world_id)
	interaction.set("_key", key)
	building.add_child(interaction)
	return interaction

func _live_binding() -> bool:
	if not is_inside_tree() or is_queued_for_deletion() or not is_instance_valid(_game) \
		or not _game.is_inside_tree() or not is_instance_valid(_session) or _game.get("session") != _session \
		or _world == null or _world.get_ref() == null or _game.get("world") != _world.get_ref() \
		or _building == null or _building.get_ref() == null: return false
	var world: RefCounted = _world.get_ref()
	var building := _building.get_ref() as Node3D
	var scene := get_tree().current_scene
	return world.get("reward_delivery_namespace") == _namespace and world.get("world_id") == _world_id \
		and building != null and building.is_inside_tree() and not building.is_queued_for_deletion() \
		and get_parent() == building and scene != null and scene.is_ancestor_of(building) \
		and building.get_script() == BUILD_PIECE and building.is_in_group("placed_building") \
		and building.get_meta("building_id", "") == "altar" and building.get_meta("realm", "") == "meadows" \
		and _key == "altar:meadows:" + str(building.get_meta("building_uid", ""))

func _ready() -> void:
	var radius: Variant = ESSENCE.config().get("altar_interaction_radius_m")
	if not _live_binding() or not (radius is int or radius is float) or not is_finite(float(radius)) or float(radius) <= 0.0:
		queue_free()
		return
	_prompt = PROMPT.new()
	_prompt.name = "TrainingInteractable"
	_prompt.position = Vector3(0.65, 0.9, 0.0)
	_prompt.set("label", "Train creatures at Altar")
	_prompt.set("radius", float(radius))
	_prompt.connect("activated", _open)
	add_child(_prompt)

func _process(_delta: float) -> void:
	# Cheap lifetime fences only. Actual payment provenance, pose, reach and
	# combat are revalidated by Session at open and every typed transaction.
	if not _live_binding():
		queue_free()
		return
	if is_instance_valid(_prompt): _prompt.set("enabled", _game.get("current_realm") == "meadows" \
		and _session.call("altar_canonical_producer_available") == true)

func _open() -> void:
	if not _live_binding() or _game.get("current_realm") != "meadows": return
	var building := _building.get_ref() as Node3D
	if _session.call("_register_altar_station_node", _key, building) != true \
		or _session.call("altar_station_available", _key) != true: return
	var service := SERVICE.attach(_game)
	if service != null: service.call("open", _key)

func _exit_tree() -> void:
	var building := _building.get_ref() as Node3D if _building != null else null
	if is_instance_valid(_session) and building != null:
		_session.call("_unregister_altar_station_node", _key, building)
