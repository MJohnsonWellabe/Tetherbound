extends "res://tools/capture_bramblebun_world_ab.gd"

## MEADOWS-0912-BRAMBLEBUN-LOW-LIGHT. Matched production-world proof for the
## small base emission floor in art.json. The inherited fixture mounts the real
## Meadows world/Terrain3D/grass/WorldLook, spawns through the production
## EncounterDirector, freezes the real Bramblebun body and uses the production
## camera. This subclass changes only CreatureBody's already-live shared floor
## scale between frames; no texture, material, light, pose or transform changes.
##
## Day catches any washed-out/self-lit regression. Golden is the lower-light
## case that previously inherited a zero floor. Night is a same-config endpoint
## receipt: both base and candidate keep the accepted 0.22 value.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const CHECK := preload("res://tools/capture_check.gd")
const CONTROL_FLOOR := 0.0
const CANDIDATE_FLOOR := 0.08
const ACCEPTED_NIGHT_FLOOR := 0.22


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Bramblebun low-light capture requires a rendering display")
		quit(1)
		return
	_biome_id = "meadows"
	_times.assign(["day", "golden", "night"])
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output_dir = arg.trim_prefix("--output=").strip_edges()
	if _output_dir.is_empty():
		push_error("Bramblebun low-light capture requires a unique --output=res://... directory")
		quit(1)
		return
	for time_name: String in ["day", "golden"]:
		for treatment: String in ["zero_floor_control", "base_floor_candidate"]:
			_planned.append({
				"frame_id": "bramblebun_low_light__%s__%s" % [time_name, treatment],
				"time": time_name,
				"treatment": treatment,
				"floor": CONTROL_FLOOR if treatment == "zero_floor_control" else CANDIDATE_FLOOR,
			})
	_planned.append({
		"frame_id": "bramblebun_low_light__night__accepted_endpoint",
		"time": "night",
		"treatment": "accepted_endpoint",
		"floor": ACCEPTED_NIGHT_FLOOR,
	})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	if not _output_is_fresh():
		quit(1)
		return
	_begin_manifest()
	_manifest["fixture_disclosure"] = (
		"Production Meadows world, Terrain3D, grass, WorldLook, EncounterDirector and "
		+ "production Camera3D. One audit-spawned production Bramblebun is frozen in place. "
		+ "Matched frames change only the existing CreatureBody shared emission-floor scale. "
		+ "Day and golden compare old zero base with candidate 0.08; night records the unchanged "
		+ "accepted 0.22 endpoint. HUD hidden. No gameplay/progression claim."
	)
	_manifest["floor_values"] = {
		"zero_floor_control": CONTROL_FLOOR,
		"base_floor_candidate": CANDIDATE_FLOOR,
		"accepted_night_endpoint": ACCEPTED_NIGHT_FLOOR,
	}
	_write_manifest()
	if not await _mount_production_world() or not _prepare_capture_shell():
		_finish(false)
		return
	_hide_hud()
	if not await _prepare_subject():
		_finish(false)
		return
	for row: Dictionary in _planned:
		await _capture_floor(row)
	BODY.set_emission_floor_scale(CANDIDATE_FLOOR)
	_restore_materials()
	_finish(_failures.is_empty() and _records.size() == _planned.size())


func _capture_floor(row: Dictionary) -> void:
	_restore_materials()
	var observed_clock := await _pin_time(str(row.time))
	if observed_clock.is_empty():
		return
	var floor := float(row.floor)
	BODY.set_emission_floor_scale(floor)
	for _frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var problems := CHECK.problems(self, _camera, "clear", _wild)
	CHECK.require(self, _camera, "clear", _wild)
	if not problems.is_empty():
		_failures.append("%s capture check: %s" % [str(row.frame_id), "; ".join(problems)])
		return
	var path := "%s/%s.png" % [_output_dir, str(row.frame_id)]
	var captured := root.get_texture().get_image()
	if captured == null or captured.is_empty() or captured.save_png(path) != OK:
		_failures.append("%s image capture/save failed" % str(row.frame_id))
	else:
		var record := row.duplicate(true)
		record["file"] = path
		record["observed_clock"] = observed_clock
		record["camera_transform"] = _transform(_camera.global_transform)
		record["subject_transform"] = _transform(_wild.global_transform)
		record["bound_materials"] = _material_records()
		record["bytes"] = FileAccess.get_file_as_bytes(path).size()
		_records.append(record)
		print("BRAMBLEBUN LOW LIGHT %s floor=%.2f -> %s" % [str(row.frame_id), floor, path])
	_write_manifest()
