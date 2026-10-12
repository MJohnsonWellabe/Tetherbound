extends "res://tools/phase2_capture_locations.gd"

## Named-stand variant of the Phase 2 location capture for landmark proof
## sheets: the same production world, trainer, CameraRig and ordinary HUD,
## but at explicit stands instead of catalogue spots. Repeat
##   --stand=<name>,<x>,<z>,<heading_deg>,<day|golden|night>
## Audit evidence only (Game.debug_teleport_to); never progression proof.


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	_planned.clear()
	for arg: String in OS.get_cmdline_user_args():
		if not arg.begins_with("--stand="):
			continue
		var parts := arg.trim_prefix("--stand=").split(",")
		if parts.size() != 5:
			push_error("named stands: expected name,x,z,heading,time: " + arg)
			return false
		var identity := "%s__stand__%s" % [_biome_id, parts[0]]
		_planned.append({"frame_id": "%s__%s__close" % [identity, parts[4]], "identity": identity,
			"biome_id": _biome_id, "biome_display_name": _biome_id.capitalize(),
			"band_id": "stand", "band_display_name": "", "destination_index": 0,
			"spot_index_in_band": 0, "destination_display_name": parts[0],
			"position_xz": [float(parts[1]), float(parts[2])], "view_heading_deg": float(parts[3]),
			"time": parts[4], "view": "close"})
	return not _planned.is_empty()
