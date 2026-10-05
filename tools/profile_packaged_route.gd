extends "res://tools/capture_lookdev_route.gd"

## External read-only overlay for pinned packaged PERF A/B. The ordinary
## production route, floor, camera and navigation are inherited unchanged.
## Both packages receive identical uncapping and monitor instrumentation.
const PROFILE_WRITER := preload("capture_manifest_writer.gd")
const ENGINE_PROFILE := preload("packaged_engine_profiler.gd")
var _profile_rows: Array[Dictionary] = []
var _engine_rows: Array[Dictionary] = []
var _profile_started := false
var _profiler: EngineProfiler


func _run() -> void:
	for argument: String in OS.get_cmdline_args():
		if argument.begins_with("--fixed-fps"):
			quit(2)
			return
	if DisplayServer.get_name() == "headless" or not RenderingServer.render_loop_enabled \
			or not is_equal_approx(Engine.time_scale, 1.0) or Engine.physics_ticks_per_second != 60:
		quit(2)
		return
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	if not EngineDebugger.is_active():
		print("Packaged diagnostic profile requires --debug engine iteration callbacks")
		quit(2)
		return
	_profiler = ENGINE_PROFILE.new()
	_profiler.set("capture", _record_engine_iteration)
	EngineDebugger.register_profiler(&"tetherbound_perf", _profiler)
	EngineDebugger.profiler_enable(&"tetherbound_perf", true)
	await super._run()
	EngineDebugger.profiler_enable(&"tetherbound_perf", false)
	EngineDebugger.unregister_profiler(&"tetherbound_perf")
	_profiler = null


func _capture_route_case() -> void:
	_profile_rows.clear()
	_engine_rows.clear()
	_profile_started = false
	await super._capture_route_case()


func _record_frame() -> void:
	if not _measuring:
		return
	if not _profile_started:
		print("PERF_ROUTE_BEGIN biome=", _biome_id, " source=", _source_commit)
		_profile_started = true
	super._record_frame()
	var row: Dictionary = _samples.back().duplicate()
	row.merge({
		"process_frame": Engine.get_process_frames(),
		"physics_frame": Engine.get_physics_frames(),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"objects_in_frame": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"render_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()),
		"render_gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()),
		"render_setup_cpu_ms": RenderingServer.get_frame_setup_time_cpu(),
	})
	_profile_rows.append(row)


func _record_engine_iteration(row: Dictionary) -> void:
	# Exclude the iteration containing start.png and any partial tail.
	if _measuring and _profile_started and not _profile_rows.is_empty() \
			and int(_profile_rows.back().process_frame) == int(row.process_frame):
		_engine_rows.append(row)


func _route_still(label: String) -> void:
	if label == "end" and _profile_started:
		print("PERF_ROUTE_END biome=", _biome_id, " frames=", _profile_rows.size())
	await super._route_still(label)


func _write_route_receipt(complete: bool) -> void:
	super._write_route_receipt(complete)
	var document := {
		"complete": complete and _failures.is_empty() and _profile_rows.size() == _samples.size(),
		"source_commit": _source_commit, "biome": _biome_id, "preset": _preset,
		"adapter": RenderingServer.get_video_adapter_name(), "engine": Engine.get_version_info(),
		"renderer": RenderingServer.get_current_rendering_method(), "resolution": [root.size.x, root.size.y],
		"camera_far_m": _camera.far if _camera != null else 0.0,
		"max_fps": Engine.max_fps, "vsync_mode": DisplayServer.window_get_vsync_mode(),
		"physics_ticks_per_second": Engine.physics_ticks_per_second, "time_scale": Engine.time_scale,
		"render_loop_enabled": RenderingServer.render_loop_enabled, "debug_build": OS.is_debug_build(),
		"instrumentation_sha256": FileAccess.get_sha256(get_script().resource_path),
		"engine_profiler_sha256": FileAccess.get_sha256(get_script().resource_path.get_base_dir().path_join("packaged_engine_profiler.gd")),
		"writer_sha256": FileAccess.get_sha256(get_script().resource_path.get_base_dir().path_join("capture_manifest_writer.gd")),
		"rows": _profile_rows, "engine_iterations": _engine_rows, "failures": _failures,
		"scope": "Same pinned packaged production routes with an external monitor-only overlay. Godot 4.7 TIME_PROCESS/TIME_PHYSICS_PROCESS are cached roughly one-second maxima, not frame-specific or step-specific costs. Correlated slowest-1% means rows selected by wall_ms with those cached readings, not each monitor's independent maximum. GPU timestamp measurement and --gpu-profile have identical instrumentation overhead in A/B. No scene edits, clip override, owner Ally acceptance or earned-campaign proof.",
	}
	if PROFILE_WRITER.write_json(_output_dir.path_join("performance.json"), document) != OK:
		_failures.append("Cannot publish packaged performance receipt")
		push_error("Cannot publish packaged performance receipt")
