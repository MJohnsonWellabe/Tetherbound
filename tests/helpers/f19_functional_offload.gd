extends RefCounted

## The same real controller/physics/save route on a real OpenGL backend.
## Hosted llvmpipe rasterization does not provide F19 mechanics evidence; keep
## drawing disabled as existing remote net proofs do. No world, input, clock,
## encounter, resource, progress or save state is supplied or changed here.
static func configure(scenario: String) -> bool:
	if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method() != "gl_compatibility":
		print("F19 FUNCTIONAL OFFLOAD refused: requires a real Compatibility display and OpenGL backend")
		return false
	for arg: String in OS.get_cmdline_user_args():
		if arg in ["--fight-log", "--aftermath-capture"]:
			print("F19 FUNCTIONAL OFFLOAD refused: frame capture requires continuous drawing")
			return false
	RenderingServer.render_loop_enabled = false
	print("F19 FUNCTIONAL OFFLOAD " + JSON.stringify({"scenario": scenario,
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"display_server": DisplayServer.get_name(), "continuous_drawing": false,
		"ordinary_controller_physics_saves": true,
		"scope": "Full mechanics driver; no visual, audio, owner-play or device-performance acceptance"}))
	return true
