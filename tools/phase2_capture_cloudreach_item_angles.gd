extends "res://tools/phase2_capture_world_inventory.gd"

## Four normal-camera approaches to five Cloudreach pickups that were not
## isolated in the first authored-coordinate survey. Only visibly valid
## views are indexed; unsuccessful angles remain in this probe manifest.

const IDS := [
	"cloudreach__inventory__pickup__potion_small",
	"cloudreach__inventory__pickup__rare_candy",
	"cloudreach__inventory__pickup__tm_aerial_flash",
	"cloudreach__inventory__pickup__tm_heavenfall",
	"cloudreach__inventory__pickup__stamina_mushroom",
]


func _load_plan() -> bool:
	if not super._load_plan() or _biome_id != "cloudreach":
		return false
	var selected: Array[Dictionary] = []
	for row: Dictionary in _planned:
		if str(row.frame_id) not in IDS:
			continue
		for heading: int in [0, 90, 180, 270]:
			var angle := row.duplicate(true)
			angle["frame_id"] = "%s__h%d" % [str(row.frame_id), heading]
			angle["view_heading_deg"] = float(heading)
			angle["stand_offsets_m"] = [3.0, 5.0, 8.0, 12.0, 20.0]
			angle["stand_laterals_m"] = [0.0, -3.0, 3.0, -8.0, 8.0]
			angle["min_camera_player_distance_m"] = 1.2
			selected.append(angle)
	_planned = selected
	return not _planned.is_empty()


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["fixture_disclosure"] = "Production Cloudreach scene and camera at authored pickup coordinates, with four approach headings per item. Fly and upper-route pickup flags set only in memory after world boot, then pickup runtime synced; no items granted or campaign progression proof. Only visibly isolated frames should enter the final frame manifest."


func _mount_production_world() -> bool:
	if not await super._mount_production_world():
		return false
	var game := root.get_node_or_null(^"Game")
	var chapter := _world.get_node_or_null(^"CloudreachChapter")
	var physical: Node = chapter.call("physical_runtime") if chapter != null else null
	if game == null or physical == null:
		_failures.append("Cloudreach pickup runtime missing")
		return false
	game.progression.set_flag("fly_traversal_unlocked")
	game.progression.set_flag("cloudreach_upper_route_unlocked")
	physical.call("sync_progression")
	for i in 12:
		await physics_frame
	return true
