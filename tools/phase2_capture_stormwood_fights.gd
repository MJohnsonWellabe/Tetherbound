extends "res://tests/capture_stormwood_b_named_fights.gd"

## Reuse the installed production Stormwood named-wild fight recorder while
## constraining its output to this report and pinning the random seed. Its
## declared party/placement/storm-clock fixtures remain disclosed in the log.

func _run() -> void:
	var target := ""
	var capture_seed := 2042
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			target = arg.trim_prefix("--out=")
		elif arg.begins_with("--seed="):
			capture_seed = int(arg.trim_prefix("--seed="))
	var approved := ProjectSettings.globalize_path("res://ralph/reports/VISUAL/phase2/stormwood/")
	if not target.replace("\\", "/").begins_with(approved.replace("\\", "/")):
		push_error("Stormwood fight frames must stay in the Phase 2 report")
		quit(1)
		return
	seed(capture_seed)
	await super._run()


## The default level-42 footage party loses the long Hollows duel before
## reaching the requested win/aftermath beats. Raise only this in-memory
## capture party to 80, keeping the normal input fight and five-creature cap.
func _capture(id: String) -> Dictionary:
	for member: RefCounted in (_game.get("party").call("members") as Array):
		member.call("set_level", 80, PROGRESSION.config())
	var row: Dictionary = await super._capture(id)
	if bool(row.get("started", false)) and not bool(_manager.call("is_fighting")):
		await _save("100-aftermath")
	return row
