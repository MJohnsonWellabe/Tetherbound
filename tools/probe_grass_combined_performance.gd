extends "res://tools/probe_grass_nearest_height_control.gd"

## Local rendered-frame regression screen for the combined grass grounding and
## blade-arc candidate. This is not an Ally measurement. It mounts the ordinary
## catalogue South Bridge view and alternates the candidate against the original
## nearest-height/straight-blade control on the same live ShaderMaterial objects.
##
## Root engine lease only; never run headless:
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/probe_grass_combined_performance.gd -- \
##     --biome=meadows --subset=south_bridge --times=day \
##     --output=res://shots/diagnostics/grass-combined-performance01

const PERFORMANCE_TOOL_PATH := "res://tools/probe_grass_combined_performance.gd"
const WARMUP_DRAWN_FRAMES := 60
const MEASURED_DRAWN_FRAMES := 180
const BATCHES := [
	{"batch":"A1", "state":"candidate"},
	{"batch":"B1", "state":"original_control"},
	{"batch":"B2", "state":"original_control"},
	{"batch":"A2", "state":"candidate"},
]

var _batches: Array[Dictionary] = []
var _prior_vsync_mode := -1
var _vsync_changed := false
var _candidate_arc_values: Dictionary = {}
var _performance_receipt: Dictionary = {}


func _load_plan() -> bool:
	if not super._load_plan():
		return false
	if _biome_id != "meadows" or _planned.size() != 1:
		push_error("grass performance probe requires one Meadows catalogue destination")
		return false
	var row := _planned[0]
	if str(row.get("destination_display_name", "")) != "The South Bridge" \
			or str(row.get("time", "")) != "day":
		push_error("grass performance probe requires The South Bridge at daytime")
		return false
	return true


func _mount_production_world() -> bool:
	# The parent provides the production mount, exact control shader construction,
	# material deduplication, parameter snapshots and raw Terrain3D RID snapshots.
	# It leaves the same live materials on the nearest-height control shader.
	if not await super._mount_production_world():
		return false
	if _materials.is_empty():
		_failures.append("grass performance probe found zero live material targets")
		return false
	for material: ShaderMaterial in _materials:
		var identity := material.get_instance_id()
		var original: Dictionary = _snapshots[identity]
		if not original.parameters.has("blade_arc_angle"):
			_failures.append("grass material %d has no candidate blade_arc_angle" % identity)
			continue
		_candidate_arc_values[identity] = original.parameters.blade_arc_angle
		material.set_shader_parameter("blade_arc_angle", 0.0)
		if not _state_matches(material, false):
			_failures.append("initial original control lost its material parameters or Terrain3D RIDs")
	_performance_receipt = {
		"scope": "local large-regression detector; not ROG Ally or GPU-isolated proof",
		"pose": "production Meadows catalogue / The South Bridge / day",
		"batch_order": BATCHES.duplicate(true),
		"warmup_drawn_frames_per_batch": WARMUP_DRAWN_FRAMES,
		"measured_drawn_frames_per_batch": MEASURED_DRAWN_FRAMES,
		"unique_live_materials": _materials.size(),
		"material_instance_ids": _materials.map(
			func(material: ShaderMaterial): return material.get_instance_id()),
		"material_objects_replaced": false,
		"density_camera_hud_gameplay_or_world_config_mutation": false,
		"render_monitors": ["draw_calls", "objects", "primitives"],
		"vertex_monitor_supported": false,
		"vertex_monitor_note": "Godot Performance exposes submitted primitives, not a vertex counter.",
		"engine_max_fps_unchanged": Engine.max_fps,
	}
	_write_manifest()
	return _failures.is_empty()


func _capture_row(row: Dictionary) -> void:
	# Reuse the catalogue's exact teleport, player placement, production camera,
	# ordinary HUD, clear weather and frozen daylight before touching VSync.
	await super._capture_row(row)
	if not _failures.is_empty():
		return
	_prior_vsync_mode = int(DisplayServer.window_get_vsync_mode())
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_vsync_changed = true
	_performance_receipt["vsync_before"] = _prior_vsync_mode
	_performance_receipt["vsync_requested_for_batches"] = DisplayServer.VSYNC_DISABLED
	_performance_receipt["vsync_observed_for_batches"] = int(
		DisplayServer.window_get_vsync_mode())

	for spec: Dictionary in BATCHES:
		var candidate := str(spec.state) == "candidate"
		if not _apply_state(candidate):
			break
		for _frame in WARMUP_DRAWN_FRAMES:
			await RenderingServer.frame_post_draw
		_batches.append(await _measure_batch(str(spec.batch), str(spec.state)))
		_write_manifest()


func _apply_state(candidate: bool) -> bool:
	for material: ShaderMaterial in _materials:
		var identity := material.get_instance_id()
		var live := _snapshot(material)
		var original: Dictionary = _snapshots[identity]
		material.shader = original.shader if candidate else _control_shader
		# Use the inherited restore path so the three raw Terrain3D texture arrays
		# are copied back through RenderingServer after every Shader assignment.
		# The live parameter snapshot preserves controller-updated centre/wind data.
		_restore(material, live)
		material.set_shader_parameter("blade_arc_angle",
			_candidate_arc_values[identity] if candidate else 0.0)
		if not _state_matches(material, candidate):
			_failures.append("%s state lost the live material or raw Terrain3D bindings" %
				("candidate" if candidate else "original control"))
			return false
	return true


func _state_matches(material: ShaderMaterial, candidate: bool) -> bool:
	var identity := material.get_instance_id()
	var original: Dictionary = _snapshots[identity]
	var expected_shader: Shader = original.shader if candidate else _control_shader
	if material.shader != expected_shader:
		return false
	var expected_arc := float(_candidate_arc_values.get(identity, NAN)) if candidate else 0.0
	if not is_finite(expected_arc) \
			or not is_equal_approx(float(material.get_shader_parameter("blade_arc_angle")),
				expected_arc):
		return false
	for key: StringName in original.raw:
		var expected: RID = original.raw[key]
		var actual: RID = RenderingServer.material_get_param(material.get_rid(), key)
		if not expected.is_valid() or not actual.is_valid() or actual != expected:
			return false
	return true


func _measure_batch(batch_name: String, state_name: String) -> Dictionary:
	var frame_ms: Array[float] = []
	var draw_calls: Array[float] = []
	var objects: Array[float] = []
	var primitives: Array[float] = []
	var prior_usec := Time.get_ticks_usec()
	for _frame in MEASURED_DRAWN_FRAMES:
		await RenderingServer.frame_post_draw
		var now_usec := Time.get_ticks_usec()
		frame_ms.append(float(now_usec - prior_usec) / 1000.0)
		prior_usec = now_usec
		draw_calls.append(float(Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		objects.append(float(Performance.get_monitor(
			Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
		primitives.append(float(Performance.get_monitor(
			Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	var receipt := {
		"batch": batch_name,
		"state": state_name,
		"warmup_drawn_frames": WARMUP_DRAWN_FRAMES,
		"measured_drawn_frames": frame_ms.size(),
		"wall_frame_ms": _distribution(frame_ms),
		"render_draw_calls": _distribution(draw_calls),
		"render_objects": _distribution(objects),
		"render_primitives": _distribution(primitives),
		"materials_match_requested_state": _materials.all(
			func(material: ShaderMaterial) -> bool:
				return _state_matches(material, state_name == "candidate")),
	}
	if not bool(receipt.materials_match_requested_state):
		_failures.append("%s material binding audit failed after measurement" % batch_name)
	return receipt


func _distribution(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"count": 0, "median": 0.0, "p95": 0.0}
	var ordered: Array[float] = values.duplicate()
	ordered.sort()
	var count := ordered.size()
	var middle := int(count / 2)
	var median: float = ordered[middle] if count % 2 == 1 \
		else (ordered[middle - 1] + ordered[middle]) * 0.5
	var p95_index := mini(count - 1, maxi(0, int(ceil(float(count) * 0.95)) - 1))
	return {"count": count, "median": median, "p95": ordered[p95_index]}


func _finish(complete: bool) -> void:
	if _vsync_changed:
		DisplayServer.window_set_vsync_mode(_prior_vsync_mode)
		_performance_receipt["vsync_restored"] = int(
			DisplayServer.window_get_vsync_mode()) == _prior_vsync_mode
	_performance_receipt["batches"] = _batches.duplicate(true)
	_performance_receipt["complete_batch_count"] = _batches.size()
	_manifest["grass_combined_performance"] = _performance_receipt.duplicate(true)
	super._finish(complete and _batches.size() == BATCHES.size())


func _write_manifest() -> void:
	_manifest["grass_combined_performance"] = _performance_receipt.duplicate(true)
	_manifest["grass_combined_performance"]["batches"] = _batches.duplicate(true)
	_manifest["capture_tool"] = {
		"path": PERFORMANCE_TOOL_PATH,
		"sha256": FileAccess.get_file_as_string(PERFORMANCE_TOOL_PATH).sha256_text(),
	}
	super._write_manifest()
