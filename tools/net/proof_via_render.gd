extends SceneTree

## render.yml entry point for a two-peer PROOF. render.yml runs one `.gd`
## script with user args and no environment of its own, while a proof is a
## shell coordinator (`run_two_peer_proof.sh`) that starts its own peers. This
## runs that script, blocking, and exits with its status.
##
##   godot --headless --path . --script tools/net/proof_via_render.gd -- \
##       scenario=tools/net/proof_scenarios/<name>.json out=ralph/reports/<LANE>/<dir> [render=1]
##
## `out` should sit in the working tree so render.yml's artifact collects it.
## `render=1` needs render.yml's `render` mode (it installs xvfb-run); in
## `headless` mode it exits 2. The proof's own output is printed only when it
## exits, so a render.yml timeout leaves run.log without it -- read PROOF.md and
## the peer logs under `out` instead.
## A loopback run is local evidence, never internet or Steam acceptance.

func _init() -> void:
	var scenario := ""
	var out := ""
	var render := false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("scenario="):
			scenario = arg.trim_prefix("scenario=")
		elif arg.begins_with("out="):
			out = arg.trim_prefix("out=")
		elif arg == "render=1":
			render = true
	if scenario.is_empty() or out.is_empty() or scenario.contains("..") or out.contains(".."):
		printerr("proof_via_render: need scenario=<tools/net/proof_scenarios/*.json> out=<dir>")
		quit(2)
		return
	var root := ProjectSettings.globalize_path("res://")
	var argv := [root.path_join("tools/net/run_two_peer_proof.sh"), root.path_join(scenario),
		"--out=" + root.path_join(out)]
	if render:
		argv.append("--render")
	var output: Array = []
	var code := OS.execute("bash", argv, output, true)
	for chunk: Variant in output:
		print(str(chunk))
	print("proof_via_render: exit %d" % code)
	quit(code)
