extends "res://tools/capture_cloudreach_high_perch_live.gd"

## Pin randomness and constrain the installed production-camera flight pass to
## Phase 2 evidence. The parent drives arrival, landing, rim and lookback.
func _run() -> void:
	var target := ""
	var capture_seed := 2042
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			target = arg.trim_prefix("--output=")
		elif arg.begins_with("--seed="):
			capture_seed = int(arg.trim_prefix("--seed="))
	if not target.begins_with("res://ralph/reports/VISUAL/phase2/cloudreach/"):
		push_error("Cloudreach flight frames must stay in the Phase 2 report")
		quit(1)
		return
	seed(capture_seed)
	await super._run()
