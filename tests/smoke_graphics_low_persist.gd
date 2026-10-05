extends SceneTree

## F26#0 Low half: Compatibility stays selectable as Low through the real
## Settings control, and that choice survives an actual process restart.
## Two separate processes with the same isolated user data directory:
##   1. -- --graphics-proof --low-select   (seeds High, physical A cycles to Low)
##   2. -- --graphics-proof --low-reload   (fresh process, no --rendering-method)
## Step 2 must be launched WITHOUT --rendering-method so the project settings
## override (user://graphics_override.cfg) is what picks the renderer.
## Device-local presentation only; no biome visual or performance claim.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
var _failures: Array[String] = []


func _init() -> void:
	_run()


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
	print("%s: %s" % ["PASS" if condition else "FAIL", description])


func _tap(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	event = event.duplicate() as InputEventJoypadButton
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _stored_renderer() -> String:
	var doc := ConfigFile.new()
	if doc.load(GRAPHICS.OVERRIDE_PATH) != OK:
		return ""
	return str(doc.get_value("rendering", "renderer/rendering_method", ""))


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	if not args.has("--graphics-proof"):
		print("Refusing graphics proof without explicit isolated-run argument.")
		quit(2)
		return
	for i in 8:
		await process_frame
	if args.has("--low-reload"):
		_check(GRAPHICS.selected() == "Low", "fresh process loads persisted Low preset")
		_check(GRAPHICS.requested_renderer() == "gl_compatibility", "fresh process requests Compatibility")
		_check(str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "gl_compatibility",
			"project settings override resolves Compatibility at boot")
		_check(RenderingServer.get_current_rendering_method() == "gl_compatibility",
			"actual running renderer is Compatibility")
		_check(not GRAPHICS.restart_required(), "no restart pending after relaunch")
		print("Low reload proof: %d failures; actual renderer=%s; adapter=%s" % [_failures.size(),
			RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name()])
		quit(0 if _failures.is_empty() else 1)
		return
	if not args.has("--low-select"):
		print("Expected --low-select or --low-reload.")
		quit(2)
		return
	# Seed a non-Low device choice so the later Low reading is discriminating.
	_check(GRAPHICS.choose("High") == OK and GRAPHICS.selected() == "High"
		and _stored_renderer() == "forward_plus", "seeded High persists Forward+ request")
	var game: Node = root.get_node(^"Game")
	var menu: Node = game.call("menu")
	_check(menu != null and menu.call("open", "settings"), "production Settings shell opens")
	if menu == null or not menu.call("is_open"):
		quit(1)
		return
	var bodies: Array = menu.get("_bodies")
	var tab: Node = bodies[int(menu.get("_index"))]
	var graphics: VBoxContainer = tab.get("_graphics")
	var preset: Button = graphics.get("_preset")
	_check(preset != null and preset.visible and not preset.disabled, "preset control is visible and enabled")
	preset.grab_focus()
	await _tap(JOY_BUTTON_A)
	_check(GRAPHICS.selected() == "Low" and GRAPHICS.requested_renderer() == "gl_compatibility",
		"physical A on preset cycles High to Low (Compatibility)")
	_check(_stored_renderer() == "gl_compatibility", "device document persists Compatibility renderer")
	_check(preset.text.contains("Low"), "preset control labels the choice Low (text=%s)" % preset.text)
	menu.call("close")
	print("Low select proof: %d failures; actual renderer=%s" % [_failures.size(),
		RenderingServer.get_current_rendering_method()])
	quit(0 if _failures.is_empty() else 1)
