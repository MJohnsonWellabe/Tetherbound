extends "res://tools/capture_stormwood_f10_matrix.gd"

const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
var _graphics_capture: Dictionary = {}
const FULL_STAND_COUNT := 5


func _run() -> void:
	_graphics_capture = BOOTSTRAP.prepare(self, "--out=")
	if _graphics_capture.is_empty():
		quit(1)
		return
	# Full visual weather matrix, using the existing authored phase/aftermath
	# staging. Production always-purple grading is preserved in every phase.
	_phases_only.assign(PHASES)
	_hud = true
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--phases=") or arg == "--no-aftermath" \
				or arg.begins_with("--stands=") or arg.begins_with("--custom="):
			push_error("Look-dev Stormwood matrix requires all five authored stands, phases and aftermath")
			quit(2)
			return
	await super._run()


func _capture(frame_id: String, description: String, full_size: bool, extra: Dictionary = {}) -> void:
	var finish: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_ground_finish.json"))
	var ground := {"enabled": bool(finish.get("enabled", false)),
		"config_sha256": FileAccess.get_file_as_string("res://data/config/stormwood_ground_finish.json").sha256_text()}
	if bool(ground.enabled):
		var cover := _world.get_node_or_null("StormwoodGroundCover")
		if cover == null or not bool(cover.get("_bound")):
			_failures.append(frame_id + ": enabled forest profile has no bound production cover")
			return
		var profile: Dictionary = cover.get("_profile_config")
		for key: String in finish.grass:
			if profile.get(key) != finish.grass[key]:
				_failures.append(frame_id + ": forest grass profile did not apply " + key)
		for name: String in finish.tiers:
			var matching := false
			for tier: Dictionary in profile.get("cover_tiers", []):
				if str(tier.get("name", "")) != name:
					continue
				matching = true
				for key: String in finish.tiers[name]:
					if tier.get(key) != finish.tiers[name][key]:
						_failures.append(frame_id + ": forest cover tier did not apply " + name + "/" + key)
			if not matching:
				_failures.append(frame_id + ": forest cover tier is absent " + name)
		ground["profile"] = profile
		ground["terrain_bound"] = cover.get("_terrain") != null
		ground["camera_is_rendering"] = cover.get("_camera") == root.get_camera_3d()
		if not bool(ground.terrain_bound) or not bool(ground.camera_is_rendering):
			_failures.append(frame_id + ": forest profile is not bound to actual terrain/rendering camera")
	if bool(finish.get("understory_readability", {}).get("enabled", false)):
		var cover := _world.get_node_or_null("StormwoodGroundCover")
		if cover == null or not cover.is_inside_tree() or not bool(cover.get("_bound")) \
				or cover.get("_terrain") != _world.get("_terrain") or cover.get("_camera") != root.get_camera_3d():
			_failures.append(frame_id + ": understory profile is not bound to production terrain/rendering camera")
			return
		ground["understory_readability"] = _ground_material_receipt(frame_id)
		if (ground.understory_readability as Dictionary).is_empty():
			return
	await super._capture(frame_id, description, full_size, extra.merged({
		"graphics_capture": _graphics_capture, "forest_ground_profile": ground}, true))
	if not _frames.is_empty() and _frames.back().get("size", []) != _graphics_capture.get("resolution", []):
		_failures.append("Stormwood look-dev frame does not match its declared native preset raster")


func _done() -> void:
	# No world access here: a failed mount must still produce a failed receipt.
	var expected := FULL_STAND_COUNT * (PHASES.size() + 1)
	if _frames.size() != expected:
		_failures.append("Stormwood matrix captured %d/%d planned frames" % [_frames.size(), expected])
	var file := FileAccess.open("%s/frames_%s.json" % [_output_dir, _label], FileAccess.WRITE)
	if file == null:
		_failures.append("Stormwood matrix receipt could not be opened")
	else:
		var text := JSON.stringify({"graphics_capture": _graphics_capture, "frames": _frames,
			"failures": _failures, "complete": _failures.is_empty(), "planned_frames": expected,
				"scope": "Production CameraRig, staged stand/phase and aftermath flag, health restoration between Break frames, hour pin with production always-purple grading, ordinary HUD. Existing physics catch-up cap retained. Visual audit only; no earned campaign, performance, Hall or owner Ally claim."}, "\t") + "\n"
		file.store_string(text)
		file.flush()
		var error := file.get_error()
		file.close()
		if error != OK or FileAccess.get_file_as_string("%s/frames_%s.json" % [_output_dir, _label]) != text:
			_failures.append("Stormwood matrix receipt flush/readback failed")
	for failure: String in _failures:
		push_error(failure)
	quit(0 if _failures.is_empty() else 1)
