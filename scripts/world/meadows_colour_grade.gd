extends RefCounted

## A small shared 1D correction after tone mapping. Clock/weather still own
## exposure and BCS adjustments; this does not grade CanvasLayer HUD colours.
static var _luts: Dictionary = {}


static func apply_to(source: Environment, candidate: Dictionary) -> Environment:
	var grade: Dictionary = candidate.get("colour_grade", {})
	if source == null or not bool(candidate.get("enabled", false)) or not bool(grade.get("enabled", false)):
		return source
	var path := str(grade.get("lut", ""))
	if path.is_empty():
		return source
	if not _luts.has(path):
		var loaded := load(path) as GradientTexture1D
		if loaded == null:
			push_error("Meadows colour grade requires its authored GradientTexture1D")
			return source
		_luts[path] = loaded
	var result := source
	if not source.has_meta("meadows_colour_grade"):
		result = source.duplicate() as Environment
		result.set_meta("meadows_colour_grade", true)
	result.adjustment_enabled = true
	result.adjustment_color_correction = _luts[path]
	return result
