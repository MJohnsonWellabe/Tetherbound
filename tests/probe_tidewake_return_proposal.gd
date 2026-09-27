extends SceneTree

## F15#2 evidence tool: measure the whole physical return with PROPOSED Meadows
## sources added (another lane's data, not landed), exactly as
## tests/test_tidewake_return_cadence.gd measures the landed data.
##   godot --headless --path . --script tests/probe_tidewake_return_proposal.gd -- --add=x:z[,x:z...]
## Each --add is a proposed wild cluster centre (radius 3, like the Cloudreach
## F15#2 pairs); it counts only when the walk passes within engage + 3 m.
const CADENCE := preload("res://tests/test_tidewake_return_cadence.gd")


func _init() -> void:
	var probe: Object = CADENCE.new()
	var engage := float((JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat.json")) as Dictionary).get("flow", {}).get("engage_range", 6.0))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--add="):
			for pair: String in arg.trim_prefix("--add=").split(",", false):
				var xz := pair.split(":")
				probe.extra_meadows_sources.append({"id": "meadows:proposed:%s" % pair, "kind": "encounter",
					"at": Vector2(float(xz[0]), float(xz[1])), "radius": engage + 3.0})
	for arches: bool in [false, true]:
		var result: Dictionary = probe.call("_whole_return", true, arches)
		var over: Array = []
		for gap: Dictionary in result.over:
			over.append("%ds %s -> %s @%s" % [int(gap.gap_s), gap.from, gap.to, str(gap.get("midpoint", ""))])
		var worst := 0.0
		for gap: Dictionary in result.gaps:
			if str(gap.get("from", "")).begins_with("meadows") or str(gap.get("to", "")).begins_with("meadows"):
				worst = maxf(worst, float(gap.gap_s))
		print("F15#2 PROPOSAL arches=%s minutes=%.1f over_a7=%s meadows_worst_s=%.0f" % [arches, float(result.seconds) / 60.0, str(over), worst])
	quit()
