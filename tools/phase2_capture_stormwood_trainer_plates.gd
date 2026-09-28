extends "res://tools/_capture_portraits.gd"

## Four raw-profile plates missing from the installed portrait recipe set.
## Render the unchanged world configuration through the existing portrait stage.
## Scratch outputs only; no production portrait or configuration is overwritten.
const TRAINER_CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const TRAINER_BODY := preload("res://scripts/world/trainer_npc.gd")
const RAW_PROFILES := ["grunt_c", "officer_a", "officer_b", "captain_a"]

func _run() -> void:
	var output := "res://.tmp/stormwood-phase2/trainer-plates-r1"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=").replace("\\", "/").simplify_path()
		else:
			push_error("Unknown trainer plate argument: " + arg)
			quit(1)
			return
	if not output.begins_with("res://.tmp/stormwood-phase2/") or DirAccess.dir_exists_absolute(output):
		push_error("Trainer plates require a fresh Stormwood scratch output directory")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Trainer plates require a native renderer")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(output) != OK or DirAccess.make_dir_recursive_absolute(OUT_DIR) != OK:
		push_error("Cannot create trainer plate scratch directories")
		quit(1)
		return
	var jobs := []
	for profile: String in RAW_PROFILES:
		var spec := {"file":"phase2_stormwood_raw_" + profile, "config_key":profile, "scratch_only":true}
		var cfg := VILLAGE_NPCS.model_config(spec)
		var speakers := []
		for trainer: Dictionary in TRAINER_CATALOGUE.trainer_specs():
			if str(trainer.config_key) == profile:
				if cfg.is_empty() or TRAINER_BODY.model_config(trainer) != cfg:
					_failures.append("Plate configuration differs from world trainer: " + str(trainer.id))
				speakers.append(str(trainer.id))
		if speakers.is_empty():
			_failures.append("No world trainer uses profile " + profile)
		jobs.append({"spec":spec,"world_config":cfg,"trainer_ids":speakers})
	if not _failures.is_empty():
		_write_result(output, [], false)
		quit(1)
		return
	CHARACTER_MODEL.set_emission_floor_scale(0.0)
	_build_stage()
	for frame in 10:
		await process_frame
	var records := []
	for job: Dictionary in jobs:
		await _render_plate(job.spec)
		var file := str(job.spec.file)
		if not _plates.has(file):
			continue
		var plate: Image = _plates[file]
		var target := output + "/" + file + ".png"
		if plate.save_png(target) != OK:
			_failures.append("Cannot retain plate " + target)
			continue
		records.append({"file":target,"profile":job.spec.config_key,
			"trainer_ids":job.trainer_ids,"world_config":job.world_config,
			"size":[plate.get_width(),plate.get_height()],
			"top_or_head_side_touches_edge":_touches_edge(plate),
			"clipped_white_fraction":_blown_fraction(plate)})
	var complete := _failures.is_empty() and records.size() == RAW_PROFILES.size()
	_write_result(output, records, complete)
	print("STORMWOOD RAW PLATES complete=", complete, " count=", records.size(), " failures=", _failures)
	quit(0 if complete else 1)

func _write_result(output: String, records: Array, complete: bool) -> void:
	var file := FileAccess.open(output + "/manifest.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write trainer plate manifest")
		return
	file.store_string(JSON.stringify({"complete":complete,"plates":records,"failures":_failures,
		"fixture":"Existing portrait stage and framing; unchanged world body configurations; no world interaction or panel acceptance proof.",
		"renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name()},"\t")+"\n")
	file.close()
