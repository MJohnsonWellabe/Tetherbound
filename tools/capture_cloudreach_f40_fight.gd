extends "res://tools/phase2_capture_cloudreach_live_fight.gd"

## Keep the existing real-interaction/live-input challenge. Add quality/source
## preflight and current-band fixture metadata; no combat mechanics change.
const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
const CANDIDATE_PATH := "res://data/config/cloudreach_f40_visual.json"
const P2_033_CANDIDATE_PATH := "res://data/config/cloudreach_pickup_readability.json"
var _graphics_capture: Dictionary = {}
var _save_fixture := ""


func _run() -> void:
	_graphics_capture = BOOTSTRAP.prepare(self)
	if _graphics_capture.is_empty():
		quit(2)
		return
	var game := root.get_node_or_null(^"Game")
	if game == null:
		push_error("F40 fight Game service unavailable")
		quit(2)
		return
	_save_fixture = "user://f40_fight_capture_%s_%s/" % [
		str(Time.get_unix_time_from_system()).replace(".", "_"), OS.get_process_id()]
	game.set("save_system", SAVE.new(_save_fixture))
	await super._run()


func _fixture_level() -> int:
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/cloudreach_f40_visual.json"))
	return int(candidate.capture.fight_fixture_level)


func _write_manifest() -> void:
	super._write_manifest()
	var path := output_dir.path_join("manifest.json")
	var receipt: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not receipt is Dictionary:
		push_error("F40 fight manifest missing")
		return
	receipt["graphics_capture"] = _graphics_capture
	receipt["candidate_preview"] = OS.get_cmdline_user_args().has("--f40-candidate")
	receipt["f40_visual_candidate_preview"] = receipt["candidate_preview"]
	receipt["p2_033_pickup_candidate_preview"] = receipt["candidate_preview"]
	receipt["candidate_config_sha256"] = FileAccess.get_file_as_string(CANDIDATE_PATH).sha256_text()
	receipt["p2_033_candidate_config_sha256"] = FileAccess.get_file_as_string(P2_033_CANDIDATE_PATH).sha256_text()
	receipt["fixture_level"] = _fixture_level()
	receipt["fixture"] = "Isolated capture save; in-memory summit flags and five directly created current-band creatures; production captain interaction and live controller-input combat pilot. No earned campaign, balance or device claim."
	receipt["isolated_save_fixture"] = _save_fixture
	var stream := FileAccess.open(path, FileAccess.WRITE)
	if stream == null:
		push_error("F40 fight receipt cannot be written")
		return
	stream.store_string(JSON.stringify(receipt, "\t") + "\n")
	stream.flush()
	var error := stream.get_error()
	stream.close()
	if error != OK:
		push_error("F40 fight receipt write failed")
