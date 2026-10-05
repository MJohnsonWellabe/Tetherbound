extends "res://tools/catalogue_survey.gd"

## F26 Low stand capture: production camera/HUD stills at explicit stands
## --cand=x,z,heading_deg (repeatable), day. Records camera distance in the
## manifest. Visual only; no frame time, traversal or gameplay claim.
##   godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##     --script tools/capture_f26_low_stands.gd -- --biome=meadows \
##     --output=<fresh dir> --cand=313.4,939.2,0 --cand=-23.5,4120.5,0

func _load_plan() -> bool:
	var index := 0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--cand="):
			var p := arg.trim_prefix("--cand=").split(",")
			index += 1
			_planned.append({"frame_id": "%s__cand_%02d_%s_%s_%s" % [_biome_id, index, p[0], p[1], p[2]],
				"biome_id": _biome_id, "destination_index": index, "position_xz": [float(p[0]), float(p[1])],
				"view_heading_deg": float(p[2]), "time": "day"})
	_times.assign(["day"])
	return not _planned.is_empty()
