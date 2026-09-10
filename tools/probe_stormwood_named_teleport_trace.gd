extends "res://tools/catalogue_survey.gd"

## Native diagnostic wrapper around the actual catalogue survey. Run only the
## consecutive Fallen Giant and Glass Field rows so BuiltFloor resolution,
## camera snapping, clock/weather pinning, pose settling and image capture are
## the exact production evidence path that showed the discontinuity.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/probe_stormwood_named_teleport_trace.gd -- \
##     --biome=stormwood --subset=fallen_giant --subset=glass_field \
##     --times=day --times=night \
##     --output=res://.artifacts/broad-visual-0910/runs/stormwood-named-catalogue-trace

const ELDER_PATH := ^"Named_blackwater_elder"
const DISCONTINUITY_M := 5.0

var _trace_elder: Node3D
var _trace_active := false
var _trace_phase := ""
var _trace_last := Vector3.ZERO
var _trace_serial := 0


func _capture_row(row: Dictionary) -> void:
	_trace_elder = _world.get_node_or_null(ELDER_PATH) as Node3D
	_trace_phase = str(row.get("frame_id", "<unnamed>"))
	_trace_serial += 1
	_trace_state("row_before", _trace_serial)
	_trace_active = _trace_elder != null
	if _trace_active:
		_trace_last = _trace_elder.global_position
		_trace_monitor(_trace_serial)
	await super._capture_row(row)
	_trace_active = false
	_trace_state("row_after", _trace_serial)


func _pin_time(time_name: String) -> Dictionary:
	_trace_state("pin_%s_before" % time_name, _trace_serial)
	var result: Dictionary = await super._pin_time(time_name)
	_trace_state("pin_%s_after" % time_name, _trace_serial)
	return result


func _trace_monitor(serial: int) -> void:
	var frame := 0
	while _trace_active and serial == _trace_serial:
		await physics_frame
		frame += 1
		if _trace_elder == null or not is_instance_valid(_trace_elder):
			print("BLACKWATER DISCONTINUITY phase=%s frame=%d elder_freed=true" % [_trace_phase, frame])
			return
		var moved := _trace_elder.global_position.distance_to(_trace_last)
		if moved > DISCONTINUITY_M:
			print("BLACKWATER DISCONTINUITY phase=%s frame=%d frame_delta=%.3f from=%s to=%s" % [
				_trace_phase, frame, moved, _trace_last, _trace_elder.global_position])
			_trace_state("frame_discontinuity", serial)
		_trace_last = _trace_elder.global_position


func _trace_state(operation: String, serial: int) -> void:
	if _trace_elder == null or not is_instance_valid(_trace_elder):
		print("BLACKWATER SNAPSHOT phase=%s operation=%s serial=%d elder_missing=true" % [
			_trace_phase, operation, serial])
		return
	var player_distance := -1.0
	if _player != null and is_instance_valid(_player):
		player_distance = _trace_elder.global_position.distance_to(_player.global_position)
	print("BLACKWATER SNAPSHOT phase=%s operation=%s serial=%d global=%s local=%s home=%s target=%s velocity=%s player=%s distance=%.3f parent=%s process=%s physics=%s floor=%s" % [
		_trace_phase, operation, serial, _trace_elder.global_position,
		_trace_elder.position, _trace_elder.get("home"), _trace_elder.get("_target"),
		_trace_elder.get("velocity"),
		_player.global_position if _player != null and is_instance_valid(_player) else Vector3.ZERO,
		player_distance,
		_trace_elder.get_parent().get_path() if _trace_elder.get_parent() != null else NodePath(),
		_trace_elder.is_processing(), _trace_elder.is_physics_processing(),
		_trace_elder.call("is_on_floor") if _trace_elder.has_method("is_on_floor") else false])
