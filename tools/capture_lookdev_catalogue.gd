extends "res://tools/catalogue_survey.gd"

const BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")


func _run() -> void:
	_graphics_capture = BOOTSTRAP.prepare(self)
	if _graphics_capture.is_empty():
		quit(1)
		return
	# Stormwood's matrix must show its own Surge phases and always-purple
	# weather look; use capture_lookdev_stormwood.gd for that biome.
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--biome=stormwood":
			push_error("Use the Surge matrix for Stormwood look development")
			quit(2)
			return
	await super._run()


func _begin_manifest() -> void:
	super._begin_manifest()
	_manifest["graphics_capture"] = _graphics_capture
	_manifest["acceptance_scope"] = "Production-camera catalogue frame matrix with explicit staged poses and day/night clock. Visual evidence only; no earned campaign, frame-time route, Hall or owner Ally claim."


func _write_manifest() -> void:
	_manifest["frames"] = _records
	_manifest["failures"] = _failures
	var file := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	if file == null:
		_failures.append("Look-dev catalogue receipt could not be opened")
		push_error(_failures.back())
		quit(1)
		return
	file.store_string(JSON.stringify(_manifest, "\t") + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		_failures.append("Look-dev catalogue receipt flush failed")
		push_error(_failures.back())
		quit(1)


func _finish(complete: bool) -> void:
	_manifest["capture_finished_utc"] = Time.get_datetime_string_from_system(true)
	_manifest["captured_frame_count"] = _records.size()
	_manifest["planned_frame_count"] = _planned.size()
	_manifest["complete"] = complete and _failures.is_empty() and not _planned.is_empty()
	_write_manifest()
	for failure: String in _failures:
		push_error(failure)
	quit(0 if bool(_manifest.complete) and _failures.is_empty() else 1)
