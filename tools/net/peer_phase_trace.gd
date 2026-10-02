extends RefCounted

## Default-OFF timing of existing peer operations. No sampler, snapshot, save,
## cached packet, input, background callback or deadline is added.
static func begin(phase: String, frame: int, physics: int) -> int:
	if OS.get_environment("TB_PEER_PHASE_TRACE") != "1": return 0
	var started := Time.get_ticks_usec()
	print("TB_PEER_PHASE_TRACE BEGIN phase=%s at_usec=%d process_frame=%d physics_frame=%d" % [phase, started, frame, physics])
	return started

static func end(phase: String, started: int, frame: int, physics: int, outcome: String = "returned") -> void:
	if started == 0: return
	var finished := Time.get_ticks_usec()
	print("TB_PEER_PHASE_TRACE END phase=%s at_usec=%d elapsed_usec=%d process_frame=%d physics_frame=%d outcome=%s" % [phase, finished, finished - started, frame, physics, outcome])
