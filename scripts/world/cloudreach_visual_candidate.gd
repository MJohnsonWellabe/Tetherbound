extends RefCounted

## F40 local presentation switch. No RPC, durable field or receipt: identical
## authored dressing is reconstructed on every peer after world mount/rejoin.
## Only the dedicated visual harness can opt in while the config stays off.
const PATH := "res://data/config/cloudreach_f40_visual.json"


static func apply(base: Dictionary, section: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not raw is Dictionary:
		return base
	var spec := raw as Dictionary
	var preview := false
	if OS.get_cmdline_user_args().has("--f40-candidate"):
		for argument: String in OS.get_cmdline_args():
			if argument in ["res://tools/capture_cloudreach_f40_matrix.gd",
					"tools/capture_cloudreach_f40_matrix.gd",
					"res://tools/capture_cloudreach_f40_fight.gd",
					"tools/capture_cloudreach_f40_fight.gd"]:
				preview = true
	if not bool(spec.get("enabled", false)) and not preview:
		return base
	return _merge(base, spec.get(section, {}))


static func _merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key: Variant in overlay:
		if result.get(key) is Dictionary and overlay[key] is Dictionary:
			result[key] = _merge(result[key], overlay[key])
		else:
			result[key] = overlay[key]
	return result
