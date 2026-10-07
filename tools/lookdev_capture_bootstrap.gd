extends RefCounted

const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")


## Common preflight for visual matrices; config comes from the production
## device preference API, never a separate imitation of its renderer rules.
static func prepare(tree: SceneTree, output_argument: String = "--output=") -> Dictionary:
	var preset := ""
	var source := ""
	var output := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			preset = arg.trim_prefix("--preset=")
		elif arg.begins_with("--source-commit="):
			source = arg.trim_prefix("--source-commit=")
		elif arg.begins_with(output_argument):
			output = arg.trim_prefix(output_argument).trim_suffix("/")
	var sha_pattern := RegEx.new()
	sha_pattern.compile("^[0-9a-f]{40}$")
	if DisplayServer.get_name() == "headless" or not GRAPHICS.PRESETS.has(preset) \
			or sha_pattern.search(source) == null:
		push_error("Look-dev matrix requires native renderer, named preset and source SHA")
		return {}
	if output.is_empty() or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
		push_error("Look-dev matrix requires an explicit fresh output directory")
		return {}
	var required := "gl_compatibility" if preset == "Low" else "forward_plus"
	if RenderingServer.get_current_rendering_method() != required or GRAPHICS.choose(preset) != OK:
		push_error("Look-dev matrix renderer/preset mismatch or device preference write failed")
		return {}
	# Owner 2026-10-07: named visual gates use Low at the handheld stress
	# raster. High/Medium remain native 1080p confirmation/performance cuts.
	var resolution := Vector2i(1280, 720) if preset == "Low" else Vector2i(1920, 1080)
	tree.root.size = resolution
	return {"preset": preset, "source_commit": source,
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(), "resolution": [resolution.x, resolution.y],
		"graphics_config_sha256": FileAccess.get_file_as_string("res://data/config/art.json").sha256_text()}
