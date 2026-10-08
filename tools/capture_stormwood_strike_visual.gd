extends "res://tools/capture_stormwood_surge_phases.gd"
## Native production-camera presentation fixtures; no earned or damage proof.
const STRIKE_MOTION = preload("res://scripts/ui/motion_prefs.gd")
const STRIKE_BOOTSTRAP := preload("res://tools/lookdev_capture_bootstrap.gd")
const SURGE_CONFIG := "res://data/config/stormwood_surge.json"
var _receipt: FileAccess
var _serial := 8000
var _timed := false
var _graphics_capture: Dictionary = {}
var _native_resolution := Vector2i(1920, 1080)
var _original_surge := PackedByteArray()
var _volume_preview := false
var _live_strikes := false
var _live_clock := 0.0
var _live_events: Array[Dictionary] = []

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var named_preset := false
	for arg: String in args:
		if arg.begins_with("--preset="):
			named_preset = true
	_volume_preview = args.has("--leader-volume-candidate")
	_live_strikes = args.has("--live-strikes")
	if _live_strikes and (not named_preset or _volume_preview or args.has("--timed")):
		push_error("Live strikes require a named shipping preset and cannot use dry-run/candidate modes")
		quit(2)
		return
	if named_preset:
		_graphics_capture = STRIKE_BOOTSTRAP.prepare(self, "--out=")
		if _graphics_capture.is_empty():
			quit(1)
			return
		var size: Array = _graphics_capture.resolution
		_native_resolution = Vector2i(size[0], size[1])
	elif _volume_preview:
		push_error("Warning candidate requires named preset, exact source SHA and fresh output")
		quit(2)
		return
	if _volume_preview and not _stage_volume():
		_restore_volume()
		quit(1)
		return
	await _capture_run()
	_restore_volume()
	if _receipt != null:
		_receipt.flush()
		if _receipt.get_error() != OK:
			_failures.append("Warning receipt final flush failed")
		_receipt.close()
	if _live_strikes:
		var receipt_path := _output_dir.path_join("manifest.jsonl")
		var reader := FileAccess.open(receipt_path, FileAccess.READ)
		if reader == null:
			_failures.append("Live strike final receipt cannot be read back")
		else:
			var rows := reader.get_as_text().strip_edges().split("\n", false)
			reader.close()
			if rows.size() != 20:
				_failures.append("Live strike final receipt expected 20 frames, got %d" % rows.size())
			for row: String in rows:
				var parsed: Variant = JSON.parse_string(row)
				if not parsed is Dictionary or bool(parsed.get("candidate_preview", true)):
					_failures.append("Live strike final receipt contains an invalid/non-shipping row")
	for failure: String in _failures:
		push_error(failure)
	print("STRIKE_CAPTURE_COMPLETE failures=", _failures)
	quit(0 if _failures.is_empty() else 1)


func _stage_volume() -> bool:
	_original_surge = FileAccess.get_file_as_bytes(SURGE_CONFIG)
	var parsed: Variant = JSON.parse_string(_original_surge.get_string_from_utf8())
	if not parsed is Dictionary or not parsed.get("presentation", {}).get("telegraph", {}).get("leader_volume_candidate") is Dictionary:
		_failures.append("Warning candidate config missing")
		return false
	parsed.presentation.telegraph.leader_volume_candidate.enabled = true
	var file := FileAccess.open(SURGE_CONFIG, FileAccess.WRITE)
	if file == null:
		_failures.append("Warning candidate config cannot be staged")
		return false
	file.store_string(JSON.stringify(parsed, "\t") + "\n")
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		_failures.append("Warning candidate config flush failed")
	return error == OK


func _restore_volume() -> void:
	if _original_surge.is_empty():
		return
	var file := FileAccess.open(SURGE_CONFIG, FileAccess.WRITE)
	if file == null:
		_failures.append("Warning original config cannot be restored")
		return
	file.store_buffer(_original_surge)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or FileAccess.get_file_as_bytes(SURGE_CONFIG) != _original_surge:
		_failures.append("Warning config byte restoration failed")
	_original_surge.clear()


func _capture_run() -> void:
	_t0 = Time.get_ticks_msec()
	_biome_id = "stormwood"
	_character_id = "trainer"
	_output_dir = "res://shots/storm-strike-baseline"
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--timed":
			_timed = true
		if arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
	root.size = _native_resolution
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	_receipt = FileAccess.open(_output_dir.path_join("manifest.jsonl"), FileAccess.WRITE)
	if _receipt == null:
		_failures.append("Warning receipt could not be opened")
		return
	if not await _mount_production_world() or not _prepare_capture_shell():
		_failures.append("Warning production world or camera shell did not mount")
		return
	_game = root.get_node(^"Game")
	_surge = _world.get_node(^"StormwoodSurge")
	_lightning = _world.get_node(^"StormwoodLightning")
	_lightning.set_process(false)
	_pin_day()
	if _live_strikes:
		await _live_strike_views()
		STRIKE_MOTION.set_reduced_motion(false)
		return
	if _timed:
		await _timed_views()
		STRIKE_MOTION.set_reduced_motion(false)
		return
	for place: Dictionary in [
		{"id":"clearing", "at":Vector2(-610,755), "look_z":10.0},
		# The old verge seat is sheltered by production canopy. Use the
		# verified exposed clearing from the opposite ordinary-camera heading;
		# retain two actual host strikes per heading, all samples and guards.
		{"id":"clearing_reverse", "at":Vector2(-610,755), "look_z":-10.0}]:
		var xz: Vector2 = place.at
		var target := Vector3(xz.x, float(_world.call("ground_height_at",xz.x,xz.y)) + 0.08, xz.y)
		await _stand(xz - Vector2(0,10), target, -12.0)
		await _enter_phase("break", false)
		_surge.set("_flash_next", 100000.0)
		_surge.set("_sky_next", 100000.0)
		_surge.set("_flash_echo", -1.0)
		for _frame in 45:
			await process_frame
		for reduced: bool in [false,true]:
			STRIKE_MOTION.set_reduced_motion(reduced)
			var prefix := str(place.id) + ("_reduced" if reduced else "_normal")
			await _frame(prefix + "_00_clear", target, -1.0)
			var ring: MeshInstance3D = _lightning.call("_build_telegraph", target)
			_lightning.add_child(ring)
			ring.global_position = target
			_serial += 1
			_lightning.get("_visuals")[_serial] = ring
			var material := ring.material_override as ShaderMaterial
			for index in 3:
				var progress: float = [0.1,0.5,0.9][index]
				material.set_shader_parameter("progress", progress)
				await _frame(prefix + "_0%d_warning" % (index+1), target, progress)
			_lightning.call("_receive", {"id":_serial,"kind":"impact","at":target,"hits":{}})
			await _frame(prefix + "_04_impact", target, 1.0)
			for _frame in 5:
				await process_frame
			await _frame(prefix + "_05_decay", target, 1.0)
			for _frame in 45:
				await process_frame
	STRIKE_MOTION.set_reduced_motion(false)


func _record_frame(record: Dictionary) -> void:
	_receipt.store_line(JSON.stringify(record))
	_receipt.flush()
	if _receipt.get_error() != OK:
		_failures.append(str(record.get("file", "unknown")) + ": warning receipt write/flush failed")

func _frame(id: String, target: Vector3, progress: float) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != _native_resolution:
		_failures.append(id + ": native image missing")
		return
	if image.save_png(_output_dir.path_join(id + ".png")) != OK:
		_failures.append(id + ": write failed")
	var record := {"file":id + ".png", "proof":"DRY RUN — does not count", "target":_vec(target),
		"feet":_vec(_player.global_position), "camera":_vec(_camera.global_position),
		"rotation":_vec(_camera.global_rotation_degrees), "fov":_camera.fov,
		"warning_progress":progress,"phase":_surge.get("phase"),"flash":_surge.call("flash_level"),
		"reduced_motion":STRIKE_MOTION.reduced_motion(), "graphics_capture":_graphics_capture,
		"candidate_preview":_volume_preview, "surge_config_sha256":FileAccess.get_file_as_string(SURGE_CONFIG).sha256_text()}
	_record_frame(record)
	print("STRIKE_FRAME ", JSON.stringify(record))

func _vec(v: Vector3) -> Array:
	return [v.x,v.y,v.z]


## Observe real host scheduling/publish/resolve in the production world. The
## stand and Break entry are staged, but no warning/impact is injected and no
## timer, damage, radius or RNG is changed. Images are retained in memory until
## impact/decay completes so PNG writes do not stall the warning being observed.
func _live_strike_event(event: Dictionary) -> void:
	if str(event.get("kind", "")) in ["warning", "impact"]:
		var row := event.duplicate(true)
		row["observed_game_seconds"] = _live_clock
		_live_events.append(row)


func _live_strike_views() -> void:
	var session: Node = _game.get_node("Session")
	if not session.is_host():
		_failures.append("Live strike capture requires the actual host")
		return
	session.stormwood_strike_received.connect(_live_strike_event)
	for place: Dictionary in [
		{"id":"clearing", "at":Vector2(-610,755)},
		{"id":"verge", "at":Vector2(-598,753)}]:
		for reduced: bool in [false, true]:
			_lightning.set_process(false)
			var xz: Vector2 = place.at
			var ground := float(_world.call("ground_height_at", xz.x, xz.y))
			await _stand(xz, Vector3(xz.x, ground, xz.y + float(place.look_z)), -12.0)
			await _enter_phase("break", false)
			STRIKE_MOTION.set_reduced_motion(reduced)
			_heal()
			if not is_equal_approx(float(_lightning.get("rules").get("config").strike.radius_m), 3.0):
				_failures.append("Live host strike radius is not 3 metres")
				continue
			if not bool(_lightning.call("exposed", _player.global_position, _player)):
				_failures.append(str(place.id) + ": live stand is sheltered")
				continue
			_live_events.clear()
			_live_clock = 0.0
			_lightning.set_process(true)
			var strike_id := -1
			var target := Vector3.ZERO
			var warning_at := -1.0
			var impact_at := -1.0
			var thresholds: Array[float] = [0.0, 0.5, 0.9]
			var images: Array[Image] = []
			var records: Array[Dictionary] = []
			var threshold_index := 0
			var impact_captured := false
			var decay_captured := false
			while _live_clock < 30.0 and not decay_captured:
				await process_frame
				_live_clock += _lightning.get_process_delta_time()
				await RenderingServer.frame_post_draw
				for event: Dictionary in _live_events:
					if strike_id < 0 and str(event.kind) == "warning":
						strike_id = int(event.id)
						target = event.at
						warning_at = float(event.observed_game_seconds)
						if not is_equal_approx(float(event.remaining), 1.2):
							_failures.append("Live host warning does not carry 1.2 seconds")
					elif int(event.id) == strike_id and str(event.kind) == "impact":
						impact_at = float(event.observed_game_seconds)
				_live_events.clear()
				var progress := -1.0
				var stage := ""
				if strike_id >= 0 and impact_at < 0.0:
					var ring: Variant = _lightning.get("_visuals").get(strike_id)
					if is_instance_valid(ring):
						progress = float((ring.material_override as ShaderMaterial).get_shader_parameter("progress"))
						if threshold_index < thresholds.size() and progress >= thresholds[threshold_index]:
							stage = "warning_%d" % threshold_index
							threshold_index += 1
				elif impact_at >= 0.0 and not impact_captured:
					stage = "impact"
					impact_captured = true
				elif impact_captured and _live_clock - impact_at >= 0.3:
					stage = "decay"
					decay_captured = true
				if not stage.is_empty():
					var id := "live_%s_%s_%s" % [str(place.id), "reduced" if reduced else "normal", stage]
					images.append(root.get_texture().get_image())
					records.append({"file":id + ".png", "proof":"production host scheduled strike; staged stand/Break entry",
						"strike_id":strike_id, "stage":stage, "warning_progress":progress,
						"warning_game_seconds":warning_at, "impact_game_seconds":impact_at,
						"sample_game_seconds":_live_clock, "target":_vec(target),
						"feet":_vec(_player.global_position), "camera":_vec(_camera.global_position),
						"reduced_motion":reduced, "phase":_surge.get("phase"),
						"radius_m":float(_lightning.get("rules").get("config").strike.radius_m),
						"graphics_capture":_graphics_capture, "candidate_preview":false})
			_lightning.set_process(false)
			if records.size() != 5 or threshold_index != 3 or not decay_captured:
				_failures.append("%s reduced=%s: expected three real warnings, impact and decay; got %d" % [place.id, reduced, records.size()])
			for index in images.size():
				if images[index] == null or images[index].is_empty() or images[index].get_size() != _native_resolution or images[index].save_png(_output_dir.path_join(records[index].file)) != OK:
					_failures.append(str(records[index].file) + ": live image write/size failed")
				_record_frame(records[index])
			print("LIVE_STRIKE_CAPTURE ", place.id, " reduced=", reduced, " frames=", records.size(), " warning=", warning_at, " impact=", impact_at)
	session.stormwood_strike_received.disconnect(_live_strike_event)

## Real production warning tween, sampled without saving PNGs in the timed
## loop. Fixed-FPS frames are simulation-time evidence, not a performance run.
func _timed_views() -> void:
	for view: Dictionary in [
		{"id":"outside", "at":Vector2(-598,753), "distance":10.0},
		{"id":"inside", "at":Vector2(-598,753), "distance":0.0},
		{"id":"brush_inside", "at":Vector2(-610,755), "distance":0.0}]:
		var xz: Vector2 = view.at
		var target := Vector3(xz.x, float(_world.call("ground_height_at",xz.x,xz.y)) + 0.08, xz.y)
		await _stand(xz - Vector2(0,float(view.distance)), target + Vector3(0,0,10), -12.0)
		await _enter_phase("break", false)
		_surge.set("_flash_next", 100000.0)
		_surge.set("_sky_next", 100000.0)
		_surge.set("_flash_echo", -1.0)
		for reduced: bool in [false,true]:
			STRIKE_MOTION.set_reduced_motion(reduced)
			for _settle in 45:
				await process_frame
			_serial += 1
			_lightning.call("_receive", {"id":_serial,"kind":"warning","at":target})
			var ring: MeshInstance3D = _lightning.get("_visuals")[_serial]
			var mat := ring.material_override as ShaderMaterial
			var images: Array[Image] = []
			var records: Array[Dictionary] = []
			var impact := false
			var end_frames := 0
			for frame in 110:
				await process_frame
				await RenderingServer.frame_post_draw
				var progress := float(mat.get_shader_parameter("progress"))
				if frame % 6 == 0 or progress >= 0.999 and not impact or impact and end_frames < 3:
					var shot := root.get_texture().get_image()
					images.append(shot)
					var id := "%s_%s_%03d" % [str(view.id), "reduced" if reduced else "normal",frame]
					records.append({"file":id+".png","proof":"DRY RUN — does not count", "frame":frame,
						"warning_progress":progress,"impact":impact,"flash":_surge.call("flash_level"),
						"reduced_motion":reduced,"target":_vec(target),"feet":_vec(_player.global_position),
						"camera":_vec(_camera.global_position),"rotation":_vec(_camera.global_rotation_degrees),"fov":_camera.fov,
						"graphics_capture":_graphics_capture,"candidate_preview":_volume_preview,
						"surge_config_sha256":FileAccess.get_file_as_string(SURGE_CONFIG).sha256_text()})
				if impact:
					end_frames += 1
					if end_frames >= 24:
						break
				elif progress >= 0.999:
					impact = true
					_lightning.call("_receive", {"id":_serial,"kind":"impact","at":target,"hits":{}})
			if not impact:
				_failures.append(str(view.id)+": warning never reached impact")
			for i in images.size():
				if images[i] == null or images[i].is_empty() or images[i].get_size() != _native_resolution or images[i].save_png(_output_dir.path_join(records[i].file)) != OK:
					_failures.append(str(records[i].file)+": image write/size failed")
				_record_frame(records[i])
			print("TIMED_STRIKE ", view.id, " reduced=", reduced, " frames=", images.size(), " impact=", impact)
