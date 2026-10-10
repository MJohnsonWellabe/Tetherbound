extends SceneTree

## F26: cost of build_placer's per-physics-tick station gate, before and after.
## "before" is `config().get("runtime_enabled")` (deep copy of the cached
## stations config); "after" is `runtime_enabled()`. Same process, alternating.
## -- --calls=N

const STATION_RULES := preload("res://scripts/build/station_rules.gd")


func _init() -> void:
	var calls := 200
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--calls="):
			calls = maxi(1, int(arg.trim_prefix("--calls=")))
	STATION_RULES.config()  # load once; both paths read the same cache
	var before := 0.0
	var after := 0.0
	var mismatch := 0
	for i in calls:
		var t := Time.get_ticks_usec()
		var old_value: bool = STATION_RULES.config().get("runtime_enabled") == true
		before += (Time.get_ticks_usec() - t) / 1000.0
		t = Time.get_ticks_usec()
		var new_value: bool = STATION_RULES.runtime_enabled()
		after += (Time.get_ticks_usec() - t) / 1000.0
		if old_value != new_value:
			mismatch += 1
	print("STATION GATE COST mode=before calls=%d mean_ms=%.4f" % [calls, before / calls])
	print("STATION GATE COST mode=after calls=%d mean_ms=%.4f mismatches=%d" % [calls, after / calls, mismatch])
	quit(1 if mismatch > 0 else 0)
