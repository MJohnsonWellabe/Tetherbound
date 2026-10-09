extends "res://tools/phase2_capture_cloudreach_live_fight.gd"

## Keep the existing real-interaction/live-input challenge. Add quality/source
## preflight and current-band fixture metadata; no combat mechanics change.
const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
var _graphics_capture: Dictionary = {}


func _run() -> void:
	_graphics_capture = BOOTSTRAP.prepare(self)
	if _graphics_capture.is_empty():
		quit(2)
		return
	await super._run()


func _fixture_level() -> int:
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/cloudreach_f40_visual.json"))
	return int(candidate.capture.fight_fixture_level)


func _write_manifest() -> void:
	super._write_manifest()
	if failed:
		return
	var path := output_dir.path_join("manifest.json")
	var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not fight_manifest_matches(receipt, _graphics_capture):
		failed = true
		push_error("F40 fight manifest missing")
		return
	receipt["graphics_capture"] = _graphics_capture
	receipt["candidate_preview"] = OS.get_cmdline_user_args().has("--f40-candidate")
	receipt["fixture_level"] = _fixture_level()
	receipt["fixture"] = "In-memory summit flags and five directly created current-band creatures; production captain interaction and live controller-input combat pilot. No earned campaign, balance or device claim."
	if MANIFEST_WRITER.write_json(path, receipt) != OK \
			or FileAccess.get_file_as_string(path) != JSON.stringify(receipt, "\t") + "\n":
		failed = true
		push_error("F40 fight receipt persistence/readback failed")


static func fight_manifest_matches(receipt: Variant, graphics: Dictionary) -> bool:
	if not receipt is Dictionary or typeof(receipt.get("complete")) != TYPE_BOOL \
			or receipt.get("complete") != true or receipt.get("fight_id", "") != FIGHT_ID:
		return false
	var renderer: Variant = graphics.get("renderer")
	if typeof(renderer) != TYPE_STRING or renderer.is_empty() \
			or receipt.get("rendering_method") != renderer:
		return false
	var actual: Variant = receipt.get("resolution")
	var expected: Variant = graphics.get("resolution")
	if not actual is Array or not expected is Array or actual.size() != 2 or expected.size() != 2:
		return false
	for index: int in range(2):
		if typeof(expected[index]) != TYPE_INT or expected[index] <= 0 \
				or typeof(actual[index]) not in [TYPE_INT, TYPE_FLOAT]:
			return false
		# JSON decodes numbers as floats; Array equality compares their Variant types.
		var dimension: float = float(actual[index])
		if not is_finite(dimension) or dimension != float(expected[index]):
			return false
	return true
