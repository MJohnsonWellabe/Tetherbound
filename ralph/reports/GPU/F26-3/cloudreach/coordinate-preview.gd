extends "res://tools/capture_lookdev_catalogue.gd"

## Private F26 coordinate preview. Default catalogue behavior is unchanged.
## With --preview-authored-arch, move only the selected Broken Skyroad Arch
## rows to the authored Cloudreach landmark center. Production teleport and
## walkability guards remain in force.
const CLOUDREACH_WORLD_PATH := "res://data/config/cloudreach_world.json"
const TARGET_DISPLAY_NAME := "Broken Skyroad Arch"
const TARGET_BAND := "broken_causeways"
const TARGET_LANDMARK_ID := "broken_skyroad_arch"

var _coordinate_preview: Dictionary = {}


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if not OS.get_cmdline_user_args().has("--preview-authored-arch"):
		return true

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CLOUDREACH_WORLD_PATH))
	if not parsed is Dictionary or not parsed.get("landmarks", []) is Array:
		push_error("Authored arch coordinate preview could not read cloudreach_world.json")
		return false
	var authored_position: Variant = null
	for landmark: Variant in parsed.landmarks:
		if landmark is Dictionary and str(landmark.get("id", "")) == TARGET_LANDMARK_ID:
			authored_position = landmark.get("position")
			break
	if not authored_position is Array or authored_position.size() < 3:
		push_error("Authored Broken Skyroad Arch landmark must declare an XYZ position")
		return false
	for coordinate: Variant in authored_position:
		if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)):
			push_error("Authored Broken Skyroad Arch coordinate is not finite numeric XYZ")
			return false
	var destination := [float(authored_position[0]), float(authored_position[2])]
	var target_indices := {}
	var original_position: Array = []
	var target_frames: Array[String] = []
	for row: Dictionary in _planned:
		if str(row.get("biome_id", "")) != "cloudreach" \
				or str(row.get("band_id", "")) != TARGET_BAND \
				or str(row.get("destination_display_name", "")) != TARGET_DISPLAY_NAME:
			continue
		if original_position.is_empty():
			original_position = (row.get("position_xz", []) as Array).duplicate()
		row["position_xz"] = destination.duplicate()
		target_indices[int(row.destination_index)] = true
		target_frames.append(str(row.get("frame_id", "")))
	if target_indices.is_empty():
		push_error("Preview requires the Broken Skyroad Arch row in the selected catalogue subset")
		return false
	for destination_row: Dictionary in _all_destinations:
		if target_indices.has(int(destination_row.destination_index)):
			destination_row["position_xz"] = destination.duplicate()

	_coordinate_preview = {
		"enabled": true,
		"flag": "--preview-authored-arch",
		"landmark_config": CLOUDREACH_WORLD_PATH,
		"landmark_id": TARGET_LANDMARK_ID,
		"frame_ids": target_frames,
		"original_catalogue_position_xz": original_position,
		"preview_authored_landmark_center_xz": destination,
		"disclosure": "Private capture-only coordinate preview. The catalogue source is unchanged. Game.debug_teleport_to and its production grounding/walkability guard remain active; a refusal is still a failed frame. This does not establish a shipping catalogue correction or acceptance."
	}
	return true


func _begin_manifest() -> void:
	super._begin_manifest()
	if not _coordinate_preview.is_empty():
		_manifest["coordinate_preview"] = _coordinate_preview.duplicate(true)
