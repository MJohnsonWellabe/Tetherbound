extends SceneTree

## Prints one CI segment boundary's roles (producer, peer, runner) as a JSON
## line `BOUNDARY_INFO {...}`, so tools/ci/segments/regen.sh reads the same
## table the checks use (tests/helpers/ci_segments.gd) instead of a copy.
##
##   godot --headless --path . --script tools/ci/segments/boundary_info.gd -- --boundary=midride/setup
##   godot --headless --path . --script tools/ci/segments/boundary_info.gd -- --chain=midride

const SEGMENTS := preload("res://tests/helpers/ci_segments.gd")


func _initialize() -> void:
	var boundary := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--boundary="):
			boundary = arg.substr("--boundary=".length())
		elif arg.begins_with("--chain="):
			# `BOUNDARY_LIST a b c`: the chain's boundaries, upstream first.
			var chain := arg.substr("--chain=".length())
			var names: Array = SEGMENTS.boundary_names().filter(func(b: String) -> bool:
				return str(SEGMENTS.BOUNDARIES[b]["chain"]) == chain)
			print("BOUNDARY_LIST " + " ".join(names))
			quit(0 if not names.is_empty() else 2)
			return
	if not SEGMENTS.BOUNDARIES.has(boundary):
		printerr("unknown boundary '%s' (known: %s)" % [boundary, ", ".join(SEGMENTS.boundary_names())])
		quit(2)
		return
	var roles := {}
	for role: String in (SEGMENTS.BOUNDARIES[boundary]["roles"] as Dictionary):
		var spec := SEGMENTS.role_spec(boundary, role)
		roles[role] = {"producer": ProjectSettings.globalize_path(str(spec.producer)),
			"peer": int(spec.peer), "runner": str(spec.runner), "runner_args": spec.get("runner_args", []),
			"producer_fingerprint": SEGMENTS.producer_fingerprint(boundary, role),
			"dir": ProjectSettings.globalize_path(SEGMENTS.checkpoint_dir(boundary, role))}
	print("BOUNDARY_INFO " + JSON.stringify({"boundary": boundary, "roles": roles,
		"manifest": ProjectSettings.globalize_path(SEGMENTS.manifest_path(boundary))}))
	quit(0)
