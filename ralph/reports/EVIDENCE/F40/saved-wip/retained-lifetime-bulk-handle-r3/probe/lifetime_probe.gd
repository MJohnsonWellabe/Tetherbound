extends SceneTree

## Prepared source only. Root must provide an admitted supervisor and isolated
## user directory. Every measurement blocks on a matching on-disk acknowledgment.
const COUNT := 135000
const PHASE_TIMEOUT_MS := 5000
const TOTAL_TIMEOUT_MS := 45000
var _mode := ""
var _started := 0
var _sequence := 0
var _samples: Array[Dictionary] = []


func _init() -> void:
	_started = Time.get_ticks_msec()
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or args[0] not in ["--mode=setters", "--mode=bulk"]:
		_fail("Exactly one fixed mode is required")
		return
	if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method() != "forward_plus":
		_fail("Real root-admitted Forward+ required")
		return
	_mode = args[0].trim_prefix("--mode=")
	if DirAccess.dir_exists_absolute("user://lifetime"):
		_fail("Fresh isolated user directory required")
		return
	if DirAccess.make_dir_absolute("user://lifetime") != OK:
		_fail("Cannot create phase directory")
		return
	if not await _phase("baseline"):
		return
	var transforms: Array[Transform3D] = []
	var packed := PackedFloat32Array()
	if _mode == "bulk":
		packed.resize(COUNT * 12)
	for i in COUNT:
		if _mode == "setters":
			transforms.append(_transform(i))
		else:
			_store(packed, i * 12, _transform(i))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	multimesh.instance_count = COUNT
	if _mode == "setters":
		for i in COUNT:
			multimesh.set_instance_transform(i, transforms[i])
	else:
		multimesh.buffer = packed
	if not await _phase("submitted_inputs_live"):
		return
	transforms.clear()
	packed.clear()
	# No individual getter or buffer readback has run before this checkpoint.
	if not await _phase("callers_released"):
		return
	var actual := multimesh.buffer
	var expected := PackedFloat32Array()
	expected.resize(12)
	if actual.size() != COUNT * 12:
		_fail("Readback size mismatch")
		return
	for i in COUNT:
		_store(expected, 0, _transform(i))
		for component in 12:
			if actual[i * 12 + component] != expected[component]:
				_fail("Readback mismatch at %d:%d" % [i, component])
				return
	expected.clear()
	var digest := _digest(actual)
	if not await _phase("readback_live"):
		return
	actual.clear()
	if not await _phase("readback_released"):
		return
	# Positive control: one individual getter should materialize the complete
	# persistent renderer cache in bulk mode, even though its return is tiny.
	if not multimesh.get_instance_transform(COUNT - 1).is_equal_approx(_transform(COUNT - 1)):
		_fail("Individual getter mismatch")
		return
	if not await _phase("scalar_read_retained"):
		return
	multimesh = null
	if not await _phase("resource_released"):
		return
	print("CLOUDREACH_LIFETIME_RESULT " + JSON.stringify({
		"mode": _mode, "count": COUNT, "buffer_bytes": COUNT * 48,
		"buffer_sha256": digest, "verified_floats": COUNT * 12,
		"samples": _samples, "elapsed_ms": Time.get_ticks_msec() - _started,
		"scope": "Retained storage diagnostic only; no world or visual acceptance"}))
	quit(0)


func _phase(label: String) -> bool:
	for frame in 8:
		await RenderingServer.frame_post_draw
	if Time.get_ticks_msec() - _started > TOTAL_TIMEOUT_MS:
		_fail("Total elapsed deadline")
		return false
	var record := {"sequence": _sequence, "phase": label, "mode": _mode,
		"pid": OS.get_process_id(), "ticks_ms": Time.get_ticks_msec(),
		"static_bytes": OS.get_static_memory_usage(),
		"static_peak_bytes": OS.get_static_memory_peak_usage(),
		"resource_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"render_buffer_bytes": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED),
		"render_video_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
	_samples.append(record)
	var stem := "user://lifetime/%02d" % _sequence
	var file := FileAccess.open(stem + ".tmp", FileAccess.WRITE)
	if file == null:
		_fail("Cannot open phase file")
		return false
	file.store_string(JSON.stringify(record))
	file.close()
	if DirAccess.rename_absolute(stem + ".tmp", stem + ".json") != OK:
		_fail("Cannot publish phase file")
		return false
	var phase_started := Time.get_ticks_msec()
	while not FileAccess.file_exists(stem + ".ack.json"):
		if Time.get_ticks_msec() - phase_started > PHASE_TIMEOUT_MS or Time.get_ticks_msec() - _started > TOTAL_TIMEOUT_MS:
			_fail("Supervisor acknowledgment deadline")
			return false
		await process_frame
	var ack: Variant = JSON.parse_string(FileAccess.get_file_as_string(stem + ".ack.json"))
	if not ack is Dictionary or ack.get("pid") != OS.get_process_id() or ack.get("sequence") != _sequence or ack.get("mode") != _mode:
		_fail("Supervisor acknowledgment identity mismatch")
		return false
	_sequence += 1
	return true


func _fail(message: String) -> void:
	push_error("CLOUDREACH_LIFETIME_FAILED " + message)
	quit(2)


func _digest(values: PackedFloat32Array) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(values.to_byte_array())
	return hash.finish().hex_encode()


func _transform(index: int) -> Transform3D:
	var n := float(index)
	return Transform3D(Basis.from_euler(Vector3(n * 0.001, n * 0.003, n * 0.002)).scaled(
		Vector3(0.52 + float(index % 7) * 0.03, 0.95, 1.17)),
		Vector3(n * 0.125, float(index % 19) * 0.25, -n * 0.0625))


func _store(buffer: PackedFloat32Array, offset: int, value: Transform3D) -> void:
	for row in 3:
		for column in 3:
			buffer[offset + row * 4 + column] = value.basis[column][row]
		buffer[offset + row * 4 + 3] = value.origin[row]
