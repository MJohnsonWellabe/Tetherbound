extends RefCounted

## Called only by a genuine physics callback. No timer, polling thread, cached
## packet or heartbeat emitter lives here. Silence remains the coordinator's
## original wall deadline; this only schedules fresh sampling while alive.
const MAX_INTERVAL_MS := 1000
var last_sample_ms: int = 0

func physics_callback(frame: int, now_ms: int, max_frames: int) -> bool:
	if frame < 1 or max_frames < 1 or now_ms < last_sample_ms: return false
	if frame % max_frames != 0 and now_ms - last_sample_ms < MAX_INTERVAL_MS: return false
	last_sample_ms = now_ms
	return true
