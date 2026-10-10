extends SceneTree

## F26: host cost of one Water dock/pickup range check, before and after the
## shared heightfield. "before" rebuilds the surface and re-reads the world
## config the way each intent used to; "after" uses `water_heightfield.shared()`.
## Same process, same runner, alternating rounds. Prints one line per mode.
## -- --rounds=N

const FIELD := preload("res://scripts/world/water_heightfield.gd")


func _init() -> void:
	var rounds := 5
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--rounds="):
			rounds = maxi(1, int(arg.trim_prefix("--rounds=")))
	FIELD.shared()  # first build is paid once per process, at the first intent
	var before := PackedFloat64Array()
	var after := PackedFloat64Array()
	var mismatch := 0
	for i in rounds:
		var x := 10.0 + float(i)
		var t := Time.get_ticks_usec()
		var old_field := FIELD.new()
		var old_config := FIELD.load_config()
		var old_h := old_field.height_at(x, 10.0)
		before.append((Time.get_ticks_usec() - t) / 1000.0)
		t = Time.get_ticks_usec()
		var shared: RefCounted = FIELD.shared()
		var new_config: Dictionary = shared.call("config")
		var new_h := float(shared.call("height_at", x, 10.0))
		after.append((Time.get_ticks_usec() - t) / 1000.0)
		if not is_equal_approx(old_h, new_h) or old_config.hash() != new_config.hash():
			mismatch += 1
	print("WATER FIELD COST mode=before rounds=%d mean_ms=%.3f max_ms=%.3f" % [rounds, _mean(before), _max(before)])
	print("WATER FIELD COST mode=after rounds=%d mean_ms=%.3f max_ms=%.3f mismatches=%d" % [rounds, _mean(after), _max(after), mismatch])
	quit(1 if mismatch > 0 else 0)


func _mean(values: PackedFloat64Array) -> float:
	var total := 0.0
	for v in values:
		total += v
	return total / maxf(1.0, float(values.size()))


func _max(values: PackedFloat64Array) -> float:
	var best := 0.0
	for v in values:
		best = maxf(best, v)
	return best
