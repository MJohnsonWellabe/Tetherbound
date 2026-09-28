extends RefCounted

## Regional adapters share the existing Meadows tier treatment. The cache
## itself keeps ownership of interaction and claims; only its visual is dressed.
const CONFIG := "res://data/config/candy_pickup_presentation.json"
const TIERS := preload("res://scripts/world/band_pickups.gd")


static func apply(pickup: Node3D, item_id: String, definition: Dictionary, placement_id: String) -> void:
	if not TIERS.CANDY_LOOK.has(item_id):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if not parsed is Dictionary or not bool(parsed.get("enabled", false)):
		return
	var badge := Color(str(definition.get("colour", "#ffffff")))
	TIERS.dress(pickup, item_id, badge, TIERS.spin_phase_for(placement_id))
