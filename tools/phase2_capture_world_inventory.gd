extends "res://tools/phase2_capture_locations.gd"

## Production-camera survey of authored pickups, harvest nodes, and prop
## families. The plan is generated from the pinned game data by
## phase2_make_world_inventory_plan.py; one representative of each family is
## selected, and every frame retains its exact authored coordinate.

const PLAN := "res://tools/phase2_world_inventory_plan.json"


func _plan_path() -> String:
	return PLAN


func _load_plan() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_plan_path()))
	if not parsed is Dictionary:
		push_error("Phase 2 world inventory plan is missing or invalid")
		return false
	var rows: Array = (parsed as Dictionary).get(_biome_id, [])
	if rows.is_empty():
		push_error("No world inventory plan for %s" % _biome_id)
		return false
	for entry: Variant in rows:
		if not entry is Dictionary:
			continue
		var item := entry as Dictionary
		var position: Array = item.get("position_xz", [])
		if position.size() != 2 and position.size() != 3:
			continue
		var identity := "%s__inventory__%s__%s" % [
			_biome_id, str(item.get("family_type", "item")), str(item.get("slug", "unknown"))]
		if not _matches_subset(identity.to_lower()):
			continue
		# Character authoring stores XYZ; pickup plans store XZ.
		var target := [float(position[0]), float(position[2] if position.size() == 3 else position[1])]
		_planned.append({
			"frame_id": identity,
			"identity": identity,
			"biome_id": _biome_id,
			"biome_display_name": _biome_id.capitalize(),
			"band_id": str(item.get("band", "")),
			"band_display_name": "",
			"destination_index": _planned.size() + 1,
			"spot_index_in_band": 0,
			"destination_display_name": str(item.get("subject", "")),
			"position_xz": target,
			"view_heading_deg": float(item.get("heading_deg", 0.0)),
			"time": "day",
			"view": str(item.get("view", "close")),
			"route_class": str(item.get("route", "off")),
			"family_type": str(item.get("family_type", "")),
			"authored_source": str(item.get("source", "")),
			"authored_id": str(item.get("authored_id", "")),
			"stand_offsets_m": [2.0, 3.0, 5.0] if str(item.get("family_type", "")) != "prop" else [5.0, 8.0, 12.0],
			"stand_laterals_m": [2.5, -2.5] if str(item.get("family_type", "")) != "prop" else [0.0, -5.0, 5.0],
			"camera_pitch_deg": -25.0 if str(item.get("family_type", "")) != "prop" else -12.0,
		})
	return not _planned.is_empty()
