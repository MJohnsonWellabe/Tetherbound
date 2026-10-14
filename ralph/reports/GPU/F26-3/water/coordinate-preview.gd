extends "res://tools/capture_lookdev_catalogue.gd"

## Private F26 coordinate preview. Default catalogue behavior is unchanged.
## With --preview-authored-camp, move only the selected Tidal Cradle Saddle
## Camp rows to the authored Water camp coordinate; production teleport and
## walkability guards remain in force.
const WATER_CAMPS_PATH := "res://data/config/water_camps.json"
const TARGET_DISPLAY_NAME := "Tidal Cradle Saddle Camp"
const TARGET_BAND := "tidal_cradle"
const TARGET_CAMP_ID := "water_camp_tidal_cradle"

var _preview_camp := false
var _coordinate_preview: Dictionary = {}


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	_preview_camp = OS.get_cmdline_user_args().has("--preview-authored-camp")
	if not _preview_camp:
		return true

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WATER_CAMPS_PATH))
	if not parsed is Dictionary or not parsed.get("camps", []) is Array:
		push_error("Authored camp coordinate preview could not read water_camps.json")
		return false
	var camp_at: Variant = null
	for camp: Variant in parsed.camps:
		if camp is Dictionary and str(camp.get("id", "")) == TARGET_CAMP_ID:
			camp_at = camp.get("at")
			break
	if not camp_at is Array or camp_at.size() != 2 \
			or typeof(camp_at[0]) not in [TYPE_INT, TYPE_FLOAT] \
			or typeof(camp_at[1]) not in [TYPE_INT, TYPE_FLOAT]:
		push_error("Authored Tidal Cradle camp must declare a two-value XZ coordinate")
		return false
	var destination := [float(camp_at[0]), float(camp_at[1])]
	if not is_finite(destination[0]) or not is_finite(destination[1]):
		push_error("Authored Tidal Cradle camp coordinate is not finite")
		return false

	var target_identities := {}
	var original_position: Array = []
	var target_frames: Array[String] = []
	for row: Dictionary in _planned:
		if str(row.get("biome_id", "")) != "water" \
				or str(row.get("band_id", "")) != TARGET_BAND \
				or str(row.get("destination_display_name", "")) != TARGET_DISPLAY_NAME:
			continue
		if original_position.is_empty():
			original_position = (row.get("position_xz", []) as Array).duplicate()
		row["position_xz"] = destination.duplicate()
		target_identities[int(row.destination_index)] = true
		target_frames.append(str(row.get("frame_id", "")))
	if target_identities.is_empty():
		push_error("Preview requires the Tidal Cradle Saddle Camp row in the selected catalogue subset")
		return false
	for destination_row: Dictionary in _all_destinations:
		if target_identities.has(int(destination_row.destination_index)):
			destination_row["position_xz"] = destination.duplicate()

	_coordinate_preview = {
		"enabled": true,
		"flag": "--preview-authored-camp",
		"camp_config": WATER_CAMPS_PATH,
		"camp_id": TARGET_CAMP_ID,
		"frame_ids": target_frames,
		"original_catalogue_position_xz": original_position,
		"preview_authored_camp_position_xz": destination,
		"disclosure": "Private capture-only coordinate preview. The catalogue source is unchanged. Game.debug_teleport_to and its production grounding/walkability guard remain active; a refusal is still a failed frame. This does not establish a shipping catalogue correction or acceptance."
	}
	return true


func _begin_manifest() -> void:
	super._begin_manifest()
	if not _coordinate_preview.is_empty():
		_manifest["coordinate_preview"] = _coordinate_preview.duplicate(true)
