extends "res://tests/capture_tidewake_named_fights.gd"

## Reuse the production named-fight capture with a fixed random seed and a
## Phase 2 evidence path. It keeps the test's legal party and ordinary prompt,
## fight, tell and hit recording path; fixture flags remain in its log.

func _run() -> void:
	var target := ""
	var capture_seed := 2042
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			target = arg.trim_prefix("--out=")
		elif arg.begins_with("--seed="):
			capture_seed = int(arg.trim_prefix("--seed="))
	if not target.begins_with("res://ralph/reports/VISUAL/phase2/tidewake/"):
		push_error("Tidewake fight frames must stay in the Phase 2 report")
		quit(1)
		return
	seed(capture_seed)
	await super._run()
