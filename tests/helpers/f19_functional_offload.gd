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
	var choice_fixture := scenario != "full_fresh_campaign"
	var veridian_group := OS.get_environment("TB_VERIDIAN_CASE_GROUP") if scenario == "veridian_choice_driver" else ""
	print("F19 FUNCTIONAL OFFLOAD " + JSON.stringify({"scenario": scenario,
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"display_server": DisplayServer.get_name(), "continuous_drawing": false,
		"original_driver_unchanged": true, "ordinary_controller_physics_saves": not choice_fixture,
		"uses_original_choice_fixtures": choice_fixture,
		"selected_veridian_case_group": ("all" if veridian_group.is_empty() else veridian_group) if scenario == "veridian_choice_driver" else "not_applicable",
		"scope": "Inherited mechanics driver; choice fixtures remain disclosed by parent; no visual, audio, owner-play or device-performance acceptance"}))
	return true
