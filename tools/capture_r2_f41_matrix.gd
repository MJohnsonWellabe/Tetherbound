extends "res://tools/capture_lookdev_stormwood.gd"

## Shared queue only. 5 stands x 4 headings x 4 phases x 2 release states
## x 2 clock pins = 320 native frames per preset. Clock pins are invariance
## controls: Stormwood must remain purple at both hours after release too.
## Production CameraRig, HUD and terrain; placement/phase/flags are staged.
## This is a visual fixture, never earned route, performance or audio proof.
func _matrix_pass(aftermath: bool) -> void:
	var flags: RefCounted = _game.get("progression")
	if aftermath:
		flags.call("set_flag", "stormwood:long_storm_ended", true)
		_note("authoritative release flag staged for visual aftermath controls")
	for clock_pin: String in ["day", "night"]:
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
	for path: String in ["stormheart_presentation", "stormwood_road_current", "stormwood_ground_finish", "stormwood_glass_field"]:
		sources[path] = FileAccess.get_file_as_string("res://data/config/%s.json" % path).sha256_text()
	await super._capture(frame_id, description, full_size, extra.merged({"regional_config_sha256": sources}, true))


func _done() -> void:
	var expected := FULL_STAND_COUNT * 4 * PHASES.size() * 2 * 2
	if _frames.size() != expected:
		_failures.append("F41 matrix captured %d/%d required native frames" % [_frames.size(), expected])
	var file := FileAccess.open("%s/frames_%s.json" % [_output_dir, _label], FileAccess.WRITE)
	if file == null:
		_failures.append("F41 receipt could not be opened")
	else:
		file.store_string(JSON.stringify({"graphics_capture": _graphics_capture,
			"frames": _frames, "planned_frames": expected, "failures": _failures,
			"complete": _failures.is_empty(), "scope": "Staged native visual matrix. All four Surge phases before/after release; day/night pins verify fixed purple grading. Four production-camera headings per stand. No earned progression, audio, performance or Ally claim."}, "\t") + "\n")
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK:
			_failures.append("F41 receipt flush failed")
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)
