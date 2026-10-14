extends RefCounted

## Local presentation only: no save field, RPC, collision or progression change.
## One OFF gate owns the biome rig and its material response together.
const PATH := "res://data/config/cloudreach_biome_look.json"
const PREVIEW_SCRIPTS := [
	"tools/capture_cloudreach_biome_look.gd",
	"tools/capture_cloudreach_settlement_identity.gd",
	"tools/capture_cloudreach_f40_matrix.gd",
	"tools/capture_cloudreach_f40_fight.gd",
]
static var _config_loaded := false
static var _active_config: Dictionary = {}


static func preview_allowed(arguments: PackedStringArray, user_arguments: PackedStringArray) -> bool:
	if not user_arguments.has("--cloudreach-look-candidate"):
		return false
	return capture_script(arguments) in PREVIEW_SCRIPTS


static func capture_script(arguments: PackedStringArray) -> String:
	# Authorize the invoked script, never a matching path in an unrelated
	# option or positional argument. Ambiguous duplicate selectors fail closed.
	var selected := ""
	var seen := false
	for index in arguments.size():
		if arguments[index] == "--":
			break
		if arguments[index] in ["--script", "-s"]:
			if seen or index + 1 >= arguments.size():
				return ""
			seen = true
			selected = arguments[index + 1].trim_prefix("res://")
	return selected


static func config() -> Dictionary:
	# Immutable startup presentation choice. Material factories can be called
	# thousands of times while dressing a realm; never reread JSON per rock.
	if _config_loaded:
		return _active_config
	_config_loaded = true
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not raw is Dictionary:
		return {}
	if not bool(raw.get("enabled", false)) and not preview_allowed(
			OS.get_cmdline_args(), OS.get_cmdline_user_args()):
		return {}
	_active_config = raw
	return _active_config


static func merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key: Variant in overlay:
		if result.get(key) is Dictionary and overlay[key] is Dictionary:
			result[key] = merge(result[key], overlay[key])
		else:
			result[key] = overlay[key]
	return result


static func apply_rig(base: Dictionary, spec: Dictionary) -> Dictionary:
	if spec.is_empty():
		return base
	var result := merge(base, spec.get("rig", {}))
	# Same grade across the biome; time and weather supply the light colours.
	# Stamp presets too so the shared night's old desaturation cannot win.
	result["environment"] = merge(result.get("environment", {}), spec.get("grade", {}))
	var times: Dictionary = result.get("times", {})
	# The legacy sky-profile merge stamps values onto alias presets. Keep the
	# held night an alias rather than letting those values undo this rig at 4am.
	if times.get("night_end") is Dictionary:
		for section: String in ["sun", "sky", "environment"]:
			(times["night_end"] as Dictionary).erase(section)
	for key: String in times:
		if not key.begins_with("_") and times[key] is Dictionary:
			var preset: Dictionary = times[key]
			preset["environment"] = merge(preset.get("environment", {}), spec.get("grade", {}))
	return result


static func apply_visual(base: Dictionary) -> Dictionary:
	return merge(base, config().get("visual", {}))


static func material_detail(material: ShaderMaterial, family: String) -> void:
	var spec := config()
	if spec.is_empty():
		return
	var materials: Dictionary = spec.get("materials", {})
	material.set_shader_parameter("surface_detail_strength", float(materials.get(family + "_relief_m", 0.0)))
	material.set_shader_parameter("surface_detail_fade_m", float(materials.get("detail_fade_m", 0.8)))
