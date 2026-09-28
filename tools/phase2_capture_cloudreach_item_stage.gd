extends "res://tools/phase2_capture_locations.gd"

## Two Cloudreach TM art views where authored-location camera approaches
## overlap the pickup with the trainer. A real ItemCachePickup visual is
## staged on clear production terrain; no pickup is claimed or saved.

const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const ITEMS := ["tm_aerial_flash", "tm_heavenfall"]
const STAGE := Vector2(-14.5, -207.0)


func _load_plan() -> bool:
	if _biome_id != "cloudreach":
		return false
	for item_id: String in ITEMS:
		if not _matches_subset(item_id):
			continue
		_planned.append({
			"frame_id": "cloudreach__inventory__pickup__%s__stage" % item_id,
			"identity": "cloudreach__inventory__pickup__%s" % item_id,
			"biome_id": "cloudreach", "biome_display_name": "Cloudreach",
			"band_id": "visual_stage", "band_display_name": "",
			"destination_index": _planned.size() + 1, "spot_index_in_band": 0,
			"destination_display_name": item_id,
			"position_xz": [STAGE.x, STAGE.y], "view_heading_deg": 0.0,
			"time": "day", "view": "close", "route_class": "off",
			"family_type": "pickup",
			"stand_offsets_m": [5.0, 8.0], "stand_laterals_m": [4.0, -4.0],
			"camera_pitch_deg": -18.0,
		})
	return not _planned.is_empty()


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["fixture_disclosure"] = "Production Cloudreach scene, trainer, camera, and exact item world models through ItemCachePickup, temporarily staged on clear Cloudreach terrain. Art/scale evidence only: not authored placement, progression, collection, or campaign proof."


func _capture_row(row: Dictionary) -> void:
	var game := root.get_node_or_null(^"Game")
	var items: Object = game.get("items") if game != null else null
	var definition: Dictionary = items.call("definition", str(row.destination_display_name)) if items != null else {}
	var ground := float(_world.call("ground_height_at", STAGE.x, STAGE.y))
	if definition.is_empty() or not is_finite(ground):
		_failures.append("TM stage missing definition or finite ground: %s" % str(row.frame_id))
		return
	var pickup := CACHE.new()
	pickup.name = "Phase2StagedPickup"
	_world.add_child(pickup)
	pickup.global_position = Vector3(STAGE.x, ground + 0.05, STAGE.y)
	pickup.setup(str(row.destination_display_name), str(definition.get("name", row.destination_display_name)),
		str(definition.get("world_model", "")), float(definition.get("world_model_scale", 1.0)),
		"phase2_visual_stage", "cloudreach", 1)
	await super._capture_row(row)
	pickup.queue_free()
	for i in 2:
		await physics_frame
