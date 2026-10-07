extends "res://tools/capture_lookdev_stormwood.gd"

## Shared queue only. 5 stands x 4 headings x 4 phases x 2 release states
## x 2 clock pins = 320 native frames per preset. Clock pins are invariance
## controls: Stormwood must remain purple at both hours after release too.
## Production CameraRig, HUD and terrain; placement/phase/flags are staged.
## This is a visual fixture, never earned route, performance or audio proof.
## --f41-candidate stages the same local config overlays as the installed
## capture runner, only in this capture process. Shipping flags stay off.
const REGIONAL_CONFIGS := ["stormheart_presentation", "stormwood_road_current",
	"stormwood_ground_finish", "stormwood_glass_field", "stormwood_surge"]
var _original_configs: Dictionary = {}
var _candidate_preview := false
const SEGMENTS := ["storm-day", "storm-night", "released-day", "released-night"]
var _segment := ""


func _run() -> void:
	# Hosted runs may capture a named quarter. All four quarters are required
	# for the matrix; a successful quarter never certifies full coverage.
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--segment="):
			if not _segment.is_empty() or arg.trim_prefix("--segment=") not in SEGMENTS:
				push_error("F41 needs exactly one known segment, or none for the full matrix")
				quit(2)
				return
			_segment = arg.trim_prefix("--segment=")
	# The installed runner stages externally and names its variant explicitly.
	# Re-applying the same overlay is idempotent; restoration returns its exact
	# incoming bytes for that runner's finally block to restore in turn.
	_candidate_preview = OS.get_cmdline_user_args().has("--f41-candidate") \
		or OS.get_cmdline_user_args().has("--label=candidate")
	if _candidate_preview and not _stage_candidate_configs():
		_restore_candidate_configs()
		for failure: String in _failures:
			push_error(failure)
		quit(1)
		return
	await super._run()
	# Parent preflight can reject before _done; preserve original config bytes.
	_restore_candidate_configs()


func _stage_candidate_configs() -> bool:
	for name: String in REGIONAL_CONFIGS:
		var path := "res://data/config/%s.json" % name
		var original := FileAccess.get_file_as_bytes(path)
		var parsed: Variant = JSON.parse_string(original.get_string_from_utf8())
		if not parsed is Dictionary:
			_failures.append("F41 candidate config is not a dictionary: %s" % path)
			return false
		_original_configs[path] = original
		var config: Dictionary = parsed
		match name:
			"stormheart_presentation":
				config.enabled = true
				for part: String in ["ancient_trunk", "built_detail", "branching_crown", "canopy_atlas", "core_finish", "visible_roots"]:
					config[part].enabled = true
			"stormwood_road_current": config.finish_candidate.enabled = true
			"stormwood_ground_finish": config.enabled = true
			"stormwood_glass_field": config.scorched_scars = true
			"stormwood_surge": config.presentation.telegraph.leader_volume_candidate.enabled = true
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			_failures.append("F41 candidate config cannot be staged: %s" % path)
			return false
		file.store_string(JSON.stringify(config, "\t") + "\n")
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK:
			_failures.append("F41 candidate config flush failed: %s" % path)
			return false
	return true


func _restore_candidate_configs() -> void:
	for path: String in _original_configs:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			_failures.append("F41 original config cannot be restored: %s" % path)
			continue
		file.store_buffer(_original_configs[path])
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK or FileAccess.get_file_as_bytes(path) != _original_configs[path]:
			_failures.append("F41 original config restore mismatch: %s" % path)
	_original_configs.clear()


func _matrix_pass(aftermath: bool) -> void:
	if not _segment.is_empty() and aftermath != _segment.begins_with("released-"):
		return
	var flags: RefCounted = _game.get("progression")
	if aftermath:
		flags.call("set_flag", "stormwood:long_storm_ended", true)
		_note("authoritative release flag staged for visual aftermath controls")
	for clock_pin: String in ["day", "night"]:
		if not _segment.is_empty() and clock_pin != _segment.get_slice("-", 1):
			continue
		_pin_clock(clock_pin)
		for stand: Dictionary in _matrix_stands():
			var at: Vector2 = stand.at
			var focus: Vector3 = stand.focus
			var direction := Vector2(focus.x-at.x, focus.z-at.y)
			for view: String in ["forward", "reverse", "left", "right"]:
				var heading := direction
				match view:
					"reverse": heading = -direction
					"left": heading = Vector2(-direction.y, direction.x)
					"right": heading = Vector2(direction.y, -direction.x)
				var framed := Vector3(at.x+heading.x, focus.y, at.y+heading.y)
				await _stand(at, framed, float(stand.pitch))
				for phase: String in PHASES:
					await _enter_phase(phase, aftermath)
					_heal()
					_hud_visible(true)
					var id := "%s_%s_%s_%s_%s" % [stand.id, view, clock_pin,
						"released" if aftermath else "storm", phase]
					await _capture(id, "%s %s; cosmetic %s clock; %s; release=%s" %
						[stand.text, view, clock_pin, phase, aftermath], true,
						{"clock_control": clock_pin, "view": view,
						"physical_geometry": "unchanged", "visual_fixture": true})


func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	var sources := {}
	for path: String in REGIONAL_CONFIGS:
		sources[path] = FileAccess.get_file_as_string("res://data/config/%s.json" % path).sha256_text()
	await super._capture(frame_id, description, full_size, extra.merged({"regional_config_sha256": sources,
		"candidate_preview": _candidate_preview}, true))
	# Preserve exact per-frame metadata when a hosted timeout stops a quarter.
	# A progress receipt is always partial and never upgrades a stopped run.
	_write_receipt(false)


func _done() -> void:
	_restore_candidate_configs()
	var full_expected := FULL_STAND_COUNT * 4 * PHASES.size() * 2 * 2
	var expected := full_expected if _segment.is_empty() else FULL_STAND_COUNT * 4 * PHASES.size()
	if _frames.size() != expected:
		_failures.append("F41 matrix captured %d/%d required native frames" % [_frames.size(), expected])
	_write_receipt(_failures.is_empty() and _frames.size() == expected)
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)


func _write_receipt(complete: bool) -> void:
	var full_expected := FULL_STAND_COUNT * 4 * PHASES.size() * 2 * 2
	var expected := full_expected if _segment.is_empty() else FULL_STAND_COUNT * 4 * PHASES.size()
	var file := FileAccess.open("%s/frames_%s.json" % [_output_dir, _label], FileAccess.WRITE)
	if file == null:
		_failures.append("F41 receipt could not be opened")
	else:
		file.store_string(JSON.stringify({"graphics_capture": _graphics_capture, "candidate_preview": _candidate_preview,
			"frames": _frames, "planned_frames": expected, "failures": _failures,
			"segment": _segment, "required_segments": SEGMENTS, "full_matrix_planned_frames": full_expected,
			"full_matrix_complete": complete and _segment.is_empty() and _failures.is_empty() and _frames.size() == full_expected,
			"complete": complete and _failures.is_empty() and _frames.size() == expected,
			"scope": "Staged native visual matrix. All four Surge phases before/after release; day/night pins verify fixed purple grading. Four production-camera headings per stand. Progress receipts are incomplete until all required frames pass. No earned progression, audio, performance or Ally claim."}, "\t") + "\n")
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK:
			_failures.append("F41 receipt flush failed")
