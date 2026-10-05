extends EngineProfiler

## Pinned engine iteration data. physics_time is the MAX completed physics
## step CPU duration in this rendered iteration, not the sum or average.
## physics_frame_time is simulation delta, never CPU duration.
var capture: Callable
var _previous_physics_frame := 0


func _tick(frame_time: float, process_time: float, physics_time: float, physics_frame_time: float) -> void:
	var current := Engine.get_physics_frames()
	var row := {"process_frame": Engine.get_process_frames(), "physics_frame": current,
		"executed_physics_steps": current - _previous_physics_frame,
		"engine_iteration_ms": frame_time * 1000.0,
		"engine_process_ms": process_time * 1000.0,
		"physics_max_step_ms": physics_time * 1000.0,
		"physics_simulation_delta_seconds": physics_frame_time}
	_previous_physics_frame = current
	if capture.is_valid():
		capture.call(row)
