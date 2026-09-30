extends RefCounted

const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")


## Common preflight for visual matrices; config comes from the production
## device preference API, never a separate imitation of its renderer rules.
static func prepare(tree: SceneTree) -> Dictionary:
	var preset := ""
	var source := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--preset="):
			preset = arg.trim_prefix("--preset=")
		elif arg.begins_with("--source-commit="):
			source = arg.trim_prefix("--source-commit=")
	var sha_pattern := RegEx.new()
	sha_pattern.compile("^[0-9a-f]{40}$")
	if DisplayServer.get_name() == "headless" or not GRAPHICS.PRESETS.has(preset) \
			or sha_pattern.search(source) == null:
		push_error("Look-dev matrix requires native renderer, named preset and source SHA")
		return {}
	var required := "gl_compatibility" if preset == "Low" else "forward_plus"
	if RenderingServer.get_current_rendering_method() != required or GRAPHICS.choose(preset) != OK:
		push_error("Look-dev matrix renderer/preset mismatch or device preference write failed")
		return {}
	tree.root.size = Vector2i(1920, 1080)
	return {"preset": preset, "source_commit": source,
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(), "resolution": [1920, 1080],
		"graphics_config_sha256": FileAccess.get_file_as_string("res://data/config/art.json").sha256_text()}
