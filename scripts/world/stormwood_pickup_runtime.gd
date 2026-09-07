extends Node3D

## Stormwood's catalogue adapter.  It intentionally owns no pickup mechanics:
## each ordinary row becomes the established ItemCachePickup, which submits its
## stable realm-qualified cache flag to the host-led world ledger.  The
## catalogue's story_reward rows are events, not loose props, and rows without
## an installed item definition remain absent until their owning item lane adds
## one.

const CACHE := preload("res://scripts/world/item_cache_pickup.gd")

const REALM_ID := "stormwood"
const DATA_PATH := "res://data/config/stormwood_pickups.json"
const ITEM_DATA_PATH := "res://data/items/items.json"

## These six ordinary Stormwood rewards already have item definitions but no
## `world_model` metadata. Reuse the installed pickup art instead of asking
## ItemCachePickup to stand its warning-box fallback. This maps presentation
## only; grants remain the catalogue's exact item ids.
const PRESENTATION_FALLBACKS := {
	"orb_basic": {"model": "res://assets/props/tm_orb/tm_orb.glb", "scale": 0.13},
	"orb_greater": {"model": "res://assets/props/tm_orb/tm_orb.glb", "scale": 0.13},
	"orb_prime": {"model": "res://assets/props/tm_orb/tm_orb.glb", "scale": 0.13},
	"swift_tonic": {"model": "res://assets/props/potion_plant/potion_plant.glb", "scale": 0.35},
	"attack_tonic": {"model": "res://assets/props/potion_plant/potion_plant.glb", "scale": 0.35},
	"stoneguard_brew": {"model": "res://assets/props/potion_plant/potion_plant.glb", "scale": 0.35},
}

var world: Node3D
var _game: Node
var _flags: RefCounted
var _placements: Dictionary = {}
var _revision := -1

func _process(_delta: float) -> void:
	if _flags != null and int(_flags.get("revision")) != _revision:
		_revision = int(_flags.get("revision"))
		sync_progression()


static func read(path: String = DATA_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func item_definitions() -> Dictionary:
	return read(ITEM_DATA_PATH).get("items", {}) as Dictionary


## Only an ordinary catalogue record with a current item definition may become
## a world pickup.  `story_reward` is deliberately excluded even when its
## eventual item exists: awarding it belongs to its successful story event.
static func can_mount(spec: Dictionary, definitions: Dictionary = {}) -> bool:
	if str(spec.get("runtime_kind", "")) != "item":
		return false
	var item_id := str(spec.get("item_id", ""))
	var id := str(spec.get("id", ""))
	var source := item_definitions() if definitions.is_empty() else definitions
	return not id.is_empty() and not item_id.is_empty() and source.has(item_id)


static func ordinary_specs() -> Array[Dictionary]:
	var definitions := item_definitions()
	var out: Array[Dictionary] = []
	for raw: Variant in (read().get("pickups", []) as Array):
		if raw is Dictionary and can_mount(raw as Dictionary, definitions):
			out.append((raw as Dictionary).duplicate(true))
	return out


static func withheld_specs() -> Array[Dictionary]:
	var definitions := item_definitions()
	var out: Array[Dictionary] = []
	for raw: Variant in (read().get("pickups", []) as Array):
		if raw is Dictionary and not can_mount(raw as Dictionary, definitions):
			out.append((raw as Dictionary).duplicate(true))
	return out


static func presentation_for(item_id: String, definition: Dictionary) -> Dictionary:
	var model := str(definition.get("world_model", ""))
	if not model.is_empty():
		return {"model": model, "scale": float(definition.get("world_model_scale", 1.0))}
	return (PRESENTATION_FALLBACKS.get(item_id, {}) as Dictionary).duplicate(true)


func mount(owner_world: Node3D) -> void:
	world = owner_world
	_game = get_node_or_null(^"/root/Game")
	_flags = _game.get("progression") if _game != null else null
	add_to_group("progression_restore")
	sync_progression()


func restore_progression_from_game(game: Node) -> void:
	_game = game
	_flags = game.get("progression") if game != null else null
	for candidate: Variant in _placements.values():
		if is_instance_valid(candidate):
			(candidate as Node).queue_free()
	_placements.clear()
	sync_progression()


func sync_progression() -> void:
	if _game == null or _flags == null:
		return
	for spec: Dictionary in ordinary_specs():
		var id := str(spec["id"])
		var unlock := str(spec.get("requires_unlock", ""))
		if (not unlock.is_empty() and not bool(_flags.call("has", unlock))) \
				or CACHE.was_taken(_game, str(spec["item_id"]), id, REALM_ID):
			continue
		if _placements.has(id) and is_instance_valid(_placements[id]):
			continue
		_mount_pickup(spec)


func _mount_pickup(spec: Dictionary) -> void:
	var id := str(spec["id"])
	var item_id := str(spec["item_id"])
	var position: Array = spec.get("position", []) as Array
	if position.size() != 3:
		return
	var definition: Dictionary = _game.get("items").call("definition", item_id)
	if definition.is_empty():
		return
	var pickup := CACHE.new()
	pickup.name = id
	add_child(pickup)
	pickup.global_position = Vector3(float(position[0]), float(position[1]), float(position[2]))
	var presentation := presentation_for(item_id, definition)
	pickup.setup(item_id, "Take " + str(definition.get("name", item_id)),
		str(presentation.get("model", "")), float(presentation.get("scale", 1.0)),
		id, REALM_ID, int(spec.get("count", 1)))
	_placements[id] = pickup
