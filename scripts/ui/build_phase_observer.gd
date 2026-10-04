extends RefCounted

## Explicit diagnostic only. BEGIN survives a synchronous stall whose END
## never arrives. Disabled shipping calls emit nothing and change no state.
static func enabled() -> bool:
	return OS.get_environment("TB_BUILD_PHASE_TRACE") == "1"

static func begin(phase: String, detail: Dictionary = {}) -> int:
	if not enabled(): return 0
	var started := Time.get_ticks_usec()
	print("BUILD_PHASE ", JSON.stringify({"edge": "begin", "phase": phase,
		"usec": started, "pid": OS.get_process_id(), "detail": detail}))
	return started

static func finish(phase: String, started: int) -> void:
	if started <= 0: return
	var ended := Time.get_ticks_usec()
	print("BUILD_PHASE ", JSON.stringify({"edge": "end", "phase": phase,
		"usec": ended, "elapsed_usec": ended - started, "pid": OS.get_process_id()}))
