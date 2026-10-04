extends RefCounted

## Opt-in attribution of existing synchronous background work. No sampling,
## snapshot, cache, retry, extra callback, or deadline is supplied here.
static func begin(phase: String, peer: int = -1) -> int:
	if OS.get_environment("TB_BACKGROUND_WORK_TRACE") != "1": return 0
	var started := Time.get_ticks_usec()
	print("TB_BACKGROUND_WORK_TRACE BEGIN phase=%s peer=%d at_usec=%d process_frame=%d engine_physics_frame=%d" % [phase, peer, started, Engine.get_process_frames(), Engine.get_physics_frames()])
	return started

static func end(phase: String, started: int, peer: int = -1) -> void:
	if started == 0: return
	var finished := Time.get_ticks_usec()
	print("TB_BACKGROUND_WORK_TRACE END phase=%s peer=%d started_usec=%d at_usec=%d elapsed_usec=%d process_frame=%d engine_physics_frame=%d" % [phase, peer, started, finished, finished - started, Engine.get_process_frames(), Engine.get_physics_frames()])
