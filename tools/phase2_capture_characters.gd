extends "res://tools/phase2_capture_world_inventory.gd"

## Character posts in the production world. This records the authored post
## coordinate and normal trainer camera; it does not substitute for dialogue,
## fight, or defeated-state evidence.


func _plan_path() -> String:
	return "res://tools/phase2_character_plan.json"


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	for row: Dictionary in _planned:
		row["view"] = "post"
		row["stand_offsets_m"] = [3.0, 5.0, 8.0]
		row["stand_laterals_m"] = [0.0, -3.0, 3.0]
		row["camera_pitch_deg"] = -10.0
	return true
