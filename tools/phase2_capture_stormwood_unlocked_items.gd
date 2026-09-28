extends "res://tools/phase2_capture_world_inventory.gd"

## Re-shoot ordinary Stormwood pickups hidden behind chapter flags. Uses
## their authored positions and production ItemCachePickup visuals/camera.
## Flags are in-memory capture fixtures, not campaign completion evidence.

const PICKUPS := preload("res://scripts/world/stormwood_pickup_runtime.gd")
const FLAGS := ["stormwood:crown_reached", "stormwood:rootgate_released"]


func _load_plan() -> bool:
	if not super._load_plan() or _biome_id != "stormwood":
		return false
	var gated := {}
	for spec: Dictionary in PICKUPS.ordinary_specs():
		if not str(spec.get("requires_unlock", "")).is_empty():
			gated[str(spec.get("item_id", ""))] = true
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		if str(row.get("family_type", "")) == "pickup" and gated.has(str(row.get("destination_display_name", ""))):
			selected.append(row)
	_planned = selected
	return not _planned.is_empty()


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["fixture_disclosure"] = "Production Stormwood scene, authored pickup coordinates, real ItemCachePickup visuals and normal production camera. Crown and Rootgate chapter flags set only in memory after world boot, then pickup runtime synced. No campaign progression or collection proof. Story rewards excluded because they are event grants, not loose pickups."


func _mount_production_world() -> bool:
	if not await super._mount_production_world():
		return false
	var game := root.get_node_or_null(^"Game")
	var runtime := _world.get_node_or_null(^"StormwoodPickups")
	if game == null or runtime == null:
		_failures.append("Stormwood pickup runtime missing")
		return false
	for flag: String in FLAGS:
		game.progression.set_flag(flag)
	runtime.call("sync_progression")
	for i in 12:
		await physics_frame
	return true
