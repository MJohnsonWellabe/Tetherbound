extends "res://tests/capture_stormwood_b_named_fights.gd"

## Reuse the installed production Stormwood named-wild fight recorder while
## constraining its output to this report and pinning the random seed. Its
## declared party/placement/storm-clock fixtures remain disclosed in the log.
var _capture_party_level := 80

func _run() -> void:
	var target := ""
	var capture_seed := 2042
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			target = arg.trim_prefix("--out=")
		elif arg.begins_with("--seed="):
			capture_seed = int(arg.trim_prefix("--seed="))
		elif arg.begins_with("--party-level="):
			_capture_party_level = int(arg.trim_prefix("--party-level="))
	if _capture_party_level not in [42, 80]:
		push_error("Use --party-level=42 for the original loss fixture or 80 for the win fixture")
		quit(1)
		return
	var normalized := target.replace("\\", "/").simplify_path()
	var approved := false
	for directory: String in ["res://ralph/reports/VISUAL/phase2/stormwood/", "res://.tmp/stormwood-phase2/"]:
		var root_path := ProjectSettings.globalize_path(directory).replace("\\", "/").trim_suffix("/")
		approved = approved or normalized == root_path or normalized.begins_with(root_path + "/")
	if not approved:
		push_error("Stormwood fight frames must stay in its Phase 2 report or local capture directory")
		quit(1)
		return
	seed(capture_seed)
	_note("capture seed=%d party_level=%d; original loss fixture=42, win fixture=80" % [capture_seed, _capture_party_level])
	await super._run()


## The default level-42 footage party loses the long Hollows duel before
## reaching the requested win/aftermath beats. Raise only this in-memory
## capture party to 80 by default, keeping the normal input fight and cap.
## --party-level=42 restores the original loss sighting's fixture explicitly.
func _capture(id: String) -> Dictionary:
	for member: RefCounted in (_game.get("party").call("members") as Array):
		member.call("set_level", _capture_party_level, PROGRESSION.config())
	var row: Dictionary = await super._capture(id)
	if bool(row.get("started", false)) and not bool(_manager.call("is_fighting")):
		await _save("100-aftermath")
	return row
