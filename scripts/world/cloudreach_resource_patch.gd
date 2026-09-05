extends Node3D

## Cloudreach's explicitly day-regrowing resource contract, around the shared
## tool swing / capacity / durability / feedback gather implementation. The
## Meadows harvest node remains permanently depleted. Each Cloudreach crop has
## a stable realm + placement + world-day identity in the existing save flags.
## Encounter-cycle resources are not hand-gather nodes: their source is deferred
## with the creature encounter pass.

const HARVEST := preload("res://scripts/world/harvest_node.gd")
const CHAPTER_PATH := "res://data/config/cloudreach_chapter.json"
const PRESENTATION_PATH := "res://data/config/cloudreach_resources.json"

var _spec: Dictionary = {}
var _crop: Node3D
var _day: int = -1
var _poll_left: float = 0.0


static func load_config(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


static func gatherable_nodes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var tier: Dictionary = load_config(CHAPTER_PATH).get("resource_tier", {})
	for raw: Dictionary in tier.get("nodes", []):
		if str(raw.get("respawn_policy", "")) == "world_day_regrow":
			result.append(raw.duplicate(true))
	return result


static func harvest_spec(spec: Dictionary, world_day: int) -> Dictionary:
	var resource_id := str(spec.get("resource_id", ""))
	var presentation: Dictionary = load_config(PRESENTATION_PATH).get("resources", {}).get(resource_id, {})
	if str(spec.get("id", "")).is_empty() or presentation.is_empty():
		return {}
	return {
		"order": "cloudreach:%s:day:%d" % [str(spec["id"]), maxi(1, world_day)],
		"item": resource_id, "amount": int(spec.get("amount", 1)),
		"at": spec.get("position", []), "label": str(presentation.get("label", "Gather")),
		"model": str(presentation.get("model", "")),
		"model_scale": float(presentation.get("model_scale", 1.0)),
	}


static func depletion_flag(spec: Dictionary, world_day: int) -> String:
	var crop_spec := harvest_spec(spec, world_day)
	return HARVEST.flag_id("order:" + str(crop_spec.get("order", ""))) if not crop_spec.is_empty() else ""


func setup(spec: Dictionary) -> void:
	_spec = spec.duplicate(true)
	add_to_group("progression_restore")
	_refresh(get_node_or_null(^"/root/Game"))


func _process(delta: float) -> void:
	_poll_left -= delta
	if _poll_left > 0.0:
		return
	_poll_left = 1.0
	var game := get_node_or_null(^"/root/Game")
	if game != null and int(game.get("day")) != _day:
		_refresh(game)


func restore_progression_from_game(game: Node) -> void:
	_refresh(game)


func _refresh(game: Node) -> void:
	if game == null or _spec.is_empty():
		return
	_day = int(game.get("day"))
	if is_instance_valid(_crop):
		remove_child(_crop)
		_crop.queue_free()
	_crop = null
	var spec := harvest_spec(_spec, _day)
	if spec.is_empty():
		return
	var progression: RefCounted = game.get("progression")
	if progression != null and bool(progression.call("has", depletion_flag(_spec, _day))):
		return
	_crop = HARVEST.new()
	_crop.name = "DailyHarvest"
	add_child(_crop)
	_crop.call("setup", spec)
