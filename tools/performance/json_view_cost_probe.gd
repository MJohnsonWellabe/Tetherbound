extends SceneTree

## F26: per-call cost of the redesign_data reads the Meadows frame makes from
## read-only callers (crop plot index, altar recipe, lesson rules), before
## (`json()`, deep copy) and after (`json_view()`, cached parse). Same process,
## alternating per call, equal-content check. -- --calls=N

const DATA := preload("res://scripts/data/redesign_data.gd")
const PATHS := ["res://data/config/farm.json", "res://data/items/buildables.json",
	"res://data/config/onboarding.json", "res://data/schema/essences.json"]


func _init() -> void:
	var calls := 200
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--calls="):
			calls = maxi(1, int(arg.trim_prefix("--calls=")))
	var mismatch := 0
	var total_before := 0.0
	var total_after := 0.0
	for path: String in PATHS:
		DATA.json(path)  # warm the cache once; both paths share it
		var before := 0.0
		var after := 0.0
		for i in calls:
			var t := Time.get_ticks_usec()
			var copy: Variant = DATA.json(path)
			before += (Time.get_ticks_usec() - t) / 1000.0
			t = Time.get_ticks_usec()
			var view: Variant = DATA.json_view(path)
			after += (Time.get_ticks_usec() - t) / 1000.0
			if i == 0 and JSON.stringify(copy) != JSON.stringify(view):
				mismatch += 1
		total_before += before / calls
		total_after += after / calls
		print("JSON VIEW COST path=%s before_ms=%.4f after_ms=%.4f" % [path.get_file(), before / calls, after / calls])
	print("JSON VIEW COST total_per_call_set before_ms=%.4f after_ms=%.4f mismatches=%d" % [total_before, total_after, mismatch])
	quit(1 if mismatch > 0 else 0)
