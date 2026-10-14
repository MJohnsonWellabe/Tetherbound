extends "res://tools/capture_stormwood_look.gd"

## Root-admitted diagnostic only. Uses the same full production mount as the
## failed Medium OFF capture, without teleporting, making an image or changing
## build yields. Node-entry observations precede _ready/mount work; they are
## boundaries, not attribution of an allocation to the named node.
## Requires the external supervisor's existing resource/diagnostic guards and
## a <=180 s wall cap. This script cannot interrupt a blocked native call.
const TRACE_PREFIX := "STORMWOOD_LOAD_MEMORY "
const MAX_BOUNDARIES := 96
var _trace_sequence := 0
var _trace_source := ""
var _trace_seen: Dictionary = {}
var _trace_failed := false


func _run() -> void:
	_t0 = Time.get_ticks_msec()
	var arguments: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		var key := arg.get_slice("=", 0)
		if key not in ["--preset", "--source-commit", "--out"] \
				or arguments.has(key) or not arg.contains("="):
			push_error("Stormwood memory probe accepts one preset, source-commit and fresh out only")
			quit(2)
			return
		arguments[key] = arg.substr(key.length() + 1)
	if arguments.get("--preset", "") != "Medium" or bool(LOOK.read_config().get("enabled", false)):
		push_error("Stormwood memory probe requires Medium and the shipped look OFF")
		quit(2)
		return
	_trace_source = str(arguments.get("--source-commit", ""))
	_phase_graphics_capture = preload("res://tools/lookdev_capture_bootstrap.gd").prepare(self, "--out=")
	if _phase_graphics_capture.is_empty():
		quit(2)
		return
	_camera_set = JSON.parse_string(FileAccess.get_file_as_string(CAMERAS))
	_capture_resolution = RASTER.exact_size(_camera_set.get("resolution"))
	if _capture_resolution == Vector2i.ZERO or not await _prepare_native_viewport():
		quit(2)
		return
	_biome_id = "stormwood"
	_character_id = "trainer"
	_hud = true
	_coarse()
	_sample("before_mount")
	node_added.connect(_trace_node_entry)
	var mounted := await _mount_production_world()
	node_added.disconnect(_trace_node_entry)
	for required: String in ["Vegetation", "StormwoodTrainers", "StormwoodEncounterHub",
			"StormwoodDynamo", "StormwoodEnding", "WorldLook", "BuildPlacer"]:
		if not _trace_seen.has("enter:" + required):
			_failures.append("memory observer missed production boundary " + required)
	if not mounted or _trace_failed or not _failures.is_empty():
		_sample("mount_failed")
		push_error("Stormwood memory probe production mount failed: " + str(_failures))
		quit(2)
		return
	# Parent mount has already observed shell_build_complete and 24 physics
	# frames. These samples separate that point from additional render drainage.
	_sample("mount_returned")
	for frame in 60:
		await process_frame
		await RenderingServer.frame_post_draw
		if frame in [0, 29, 59]:
			_sample("post_draw_%d" % (frame + 1))
	_sample("quit_scheduled")
	quit(0)
	# External receipt, not this marker, must prove natural exit and clean logs.
	print("STORMWOOD_LOAD_MEMORY_COMPLETE source=", _trace_source)


func _trace_node_entry(node: Node) -> void:
	if _trace_failed or _world == null or node.get_parent() != _world:
		return
	var boundary := "enter:" + str(node.name)
	if _trace_seen.has(boundary):
		return
	if _trace_seen.size() >= MAX_BOUNDARIES:
		_trace_failed = true
		push_error("Stormwood memory probe exceeded its boundary limit")
		quit(2)
		return
	_trace_seen[boundary] = true # Strings only; do not retain nodes/resources.
	_sample(boundary)


func _sample(boundary: String) -> void:
	print(TRACE_PREFIX, JSON.stringify({
		"sequence": _trace_sequence, "boundary": boundary,
		"source_commit": _trace_source, "pid": OS.get_process_id(),
		"ticks_ms": Time.get_ticks_msec(), "unix_seconds": Time.get_unix_time_from_system(),
		"static_bytes": OS.get_static_memory_usage(),
		"peak_static_bytes": OS.get_static_memory_peak_usage(),
		"system": OS.get_memory_info(),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"render_video_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"render_texture_bytes": int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"render_buffer_bytes": int(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),
	}))
	_trace_sequence += 1
