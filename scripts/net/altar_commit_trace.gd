extends RefCounted

## Opt-in attribution of the ORIGINAL paid Altar transaction. No state,
## entitlement, save, retry or input behavior is supplied by this observer.
static func begin(phase: String) -> int:
	if OS.get_environment("TB_ALTAR_COMMIT_TRACE") != "1": return 0
	var started := Time.get_ticks_usec()
	print("TB_ALTAR_COMMIT_TRACE BEGIN phase=%s at_usec=%d" % [phase, started])
	return started

static func end(phase: String, started: int, outcome: String = "returned") -> void:
	if started == 0: return
	var finished := Time.get_ticks_usec()
	print("TB_ALTAR_COMMIT_TRACE END phase=%s at_usec=%d elapsed_usec=%d outcome=%s" % [phase, finished, finished - started, outcome])
