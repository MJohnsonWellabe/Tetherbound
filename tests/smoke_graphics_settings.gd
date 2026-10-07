extends SceneTree

## One bounded F26 batch: actual Settings controls, physical pad focus,
## persisted device choices and checked host/guest restart-save routing.
## Run only with isolated APPDATA and -- --graphics-proof. This does not
## certify biome visuals, Ally performance or an actual process restart.
const GRAPHICS := preload("res://scripts/ui/graphics_prefs.gd")
const RESTART := preload("res://scripts/ui/graphics_restart.gd")
const OWNER := preload("res://scripts/ui/input_owner.gd")
var _failures: Array[String] = []

class PortableSave extends RefCounted:
	var writes := 0
	var success := true
	func save_character(_game: Node, id: String) -> bool:
		writes += 1
		return success and id == "graphics-guest"

class Identity extends RefCounted:
	var character_id := "graphics-guest"

class Peer extends Node:
	var admitted := true
	func client_character_save_ready() -> bool:
		return admitted

class RestartGame extends Node:
	var host := true
	var writes := 0
	var success := true
	var captured := false
	var session := Peer.new()
	var save_system := PortableSave.new()
	var local := Identity.new()
	func is_host() -> bool:
		return host
	func autosave_slot() -> int:
		return 0
	func save_game(_slot: int) -> bool:
		writes += 1
		return success
	func _capture_player_pose() -> void:
		captured = true


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


func _run() -> void:
	await process_frame
	if not OS.get_cmdline_user_args().has("--graphics-proof"):
		print("Refusing graphics proof without explicit isolated-run argument.")
		quit(2)
		return
	for i in 8:
		await process_frame
	if OS.get_cmdline_user_args().has("--graphics-forward-reload"):
		_check(GRAPHICS.forward_plus() and not GRAPHICS.restart_required(), "fresh process boots persisted Forward+ without renderer override")
		_check(GRAPHICS.selected() == "Custom", "fresh process loads Custom preset")
		for key: String in GRAPHICS.FEATURES:
			_check(GRAPHICS.values().get(key) == (not bool(GRAPHICS._config.High.get(key))), "fresh process retains custom " + key)
		_check(GRAPHICS.values().get("shadow_quality") == "Off" and GRAPHICS.values().get("draw_distance") == "Near", "fresh process retains custom shadow and distance")
		quit(0 if _failures.is_empty() else 1)
		return
	if OS.get_cmdline_user_args().has("--graphics-forward-proof"):
		await _run_forward_controls()
		quit(0 if _failures.is_empty() else 1)
		return
	if OS.get_cmdline_user_args().has("--graphics-reload-only"):
		_check(GRAPHICS.selected() == "Custom" and GRAPHICS.overlay_enabled() and GRAPHICS.values().get("shadow_quality") == "High", "new process loads persisted custom device choices")
		_check(GRAPHICS.requested_renderer() == "forward_plus", "new process retains requested Forward+ renderer")
		print("Fresh-process graphics reload: actual renderer=%s" % RenderingServer.get_current_rendering_method())
		quit(0 if _failures.is_empty() else 1)
		return
	var game: Node = root.get_node(^"Game")
	var menu: Node = game.call("menu")
	_check(menu != null and menu.call("open", "settings"), "production Settings shell opens")
	if menu == null or not menu.call("is_open"):
		quit(1)
		return
	var bodies: Array = menu.get("_bodies")
	var tab: Node = bodies[int(menu.get("_index"))]
	var graphics: VBoxContainer = tab.get("_graphics")
	_check(graphics != null and graphics.is_in_group(OWNER.GROUP) and graphics.owns_input(), "graphics joins input owner without world input")
	_check(GRAPHICS.selected() == "Low" and GRAPHICS.requested_renderer() == "gl_compatibility", "shipping default remains Low")
	var preset: Button = graphics.get("_preset")
	preset.grab_focus()
	await _tap(JOY_BUTTON_A)
	_check(GRAPHICS.selected() == "Medium" and GRAPHICS.requested_renderer() == "forward_plus", "physical A chooses Medium and persists Forward+ request")
	_check((graphics.get("_restart_note") as Label).visible and not OS.is_restart_on_exit_set(), "renderer change offers explicit restart without arming restart")
	await _tap(JOY_BUTTON_DPAD_DOWN)
	_check(root.gui_get_focus_owner() == graphics.get("_shadow"), "physical Down skips unavailable Forward+ toggles")
	await _tap(JOY_BUTTON_A)
	_check(GRAPHICS.selected() == "Custom" and GRAPHICS.values().get("shadow_quality") == "High", "shadow toggle selects Custom and persists")
	(graphics.get("_overlay") as Button).grab_focus()
	await _tap(JOY_BUTTON_A)
	_check(GRAPHICS.overlay_enabled(), "physical A enables device-only frame readout")
	(graphics.get("_later") as Button).grab_focus()
	await _tap(JOY_BUTTON_A)
	_check(not (graphics.get("_restart_now") as Button).visible and not OS.is_restart_on_exit_set(), "Later leaves the game running")
	var last: Control = graphics.last_focus()
	last.grab_focus()
	await _tap(JOY_BUTTON_DPAD_DOWN)
	var audio_rows: Array = tab.get("_volume_rows")
	_check(root.gui_get_focus_owner() == audio_rows[0]["button"], "graphics focus reaches existing audio controls")
	await _tap(JOY_BUTTON_DPAD_UP)
	_check(root.gui_get_focus_owner() == last, "audio focus returns to graphics")
	GRAPHICS._loaded = false
	GRAPHICS.load_preferences()
	_check(GRAPHICS.selected() == "Custom" and GRAPHICS.overlay_enabled() and GRAPHICS.values().get("shadow_quality") == "High", "fresh preference load retains choices")
	var valid := ConfigFile.new()
	_check(valid.load(GRAPHICS.OVERRIDE_PATH) == OK and GRAPHICS._usable_document(valid), "canonical device document validates")
	valid.set_value("tetherbound_graphics", "preset", "Low")
	_check(not GRAPHICS._usable_document(valid), "contradictory Low label with Medium renderer is rejected")
	var fake := RestartGame.new()
	_check(RESTART.save_progress(fake) and fake.writes == 1 and fake.save_system.writes == 0, "host restart saves world through existing checked API")
	fake.success = false
	_check(not RESTART.save_progress(fake), "failed host save blocks restart preparation")
	fake.host = false
	_check(RESTART.save_progress(fake) and fake.save_system.writes == 1 and fake.captured and fake.writes == 2, "guest restart saves only its own character with captured pose")
	fake.session.admitted = false
	_check(not RESTART.save_progress(fake) and fake.save_system.writes == 1, "incomplete guest join cannot save or restart")
	fake.session.admitted = true
	fake.save_system.success = false
	_check(not RESTART.save_progress(fake), "failed portable save blocks restart preparation")
	fake.session.free()
	fake.free()
	menu.call("close")
	print("Graphics Settings bounded proof: %d failures; actual renderer=%s" % [_failures.size(), RenderingServer.get_current_rendering_method()])
	quit(0 if _failures.is_empty() else 1)


func _run_forward_controls() -> void:
	_check(DisplayServer.get_name() != "headless" and GRAPHICS.forward_plus(), "Forward+ control proof uses an actual native renderer")
	if not GRAPHICS.forward_plus() or DisplayServer.get_name() == "headless":
		return
	var game: Node = root.get_node(^"Game")
	var menu: Node = game.call("menu")
	_check(menu != null and menu.call("open", "settings"), "production Settings opens on Forward+")
	if menu == null or not menu.call("is_open"):
		return
	var bodies: Array = menu.get("_bodies")
	var graphics: VBoxContainer = bodies[int(menu.get("_index"))].get("_graphics")
	var preset: Button = graphics.get("_preset")
	# Mount the installed presentation nodes, not the procedural world/terrain.
	# Settings.changed -> tab_settings -> day_cycle -> WorldLook remains real.
	# Injected pad events prove controls, not a hardware-controller witness.
	var world := (load("res://scenes/world/meadows_playground.tscn") as PackedScene).instantiate()
	var holder := world.get_node("WorldEnvironment") as WorldEnvironment
	var environment: Environment = holder.environment
	var camera := world.get_node("CameraRig/Camera3D") as Camera3D
	var sun := world.get_node("Sun") as DirectionalLight3D
	var look: Node = world.get_node("WorldLook")
	var previous_environment := root.world_3d.environment
	for node: Node in [holder, sun, camera, look]:
		node.get_parent().remove_child(node)
		root.add_child(node)
		if node == camera:
			camera.make_current()
	look.call("set_clock_frozen", true)
	look.call("apply_time", "day")
	# Root startup normally declares this floor. Keep the authored horizon and
	# measure actual distance control through LOD, never clip it for the smoke.
	var horizon: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadows_horizon.json"))
	camera.set_meta(&"vista_far_floor_m", float(horizon.camera_vista_far_floor_m))
	for expected: String in ["Medium", "High", "Low"]:
		preset.grab_focus()
		await _tap(JOY_BUTTON_A)
		_check(GRAPHICS.selected() == expected, "physical preset control selects " + expected)
		var values := GRAPHICS.values()
		for key: String in GRAPHICS.FEATURES:
			var property := "volumetric_fog_enabled" if key == "volumetric_fog" else key + "_enabled"
			_check(environment.get(property) == bool(values.get(key)), "%s applies %s to production environment" % [expected, key])
			var button: Button = graphics.get("_feature_buttons")[key]
			_check(button.disabled == (expected == "Low"), "%s availability follows %s renderer choice" % [key, expected])
		var distance: Dictionary = GRAPHICS._config.draw_distance_options[values.draw_distance]
		_check(is_equal_approx(root.mesh_lod_threshold, float(distance.lod_threshold)) and is_equal_approx(camera.far, maxf(float(distance.far), float(horizon.camera_vista_far_floor_m))), expected + " applies actual viewport LOD and preserves authored camera horizon")
		_check(is_equal_approx(environment.volumetric_fog_density, float(values.get("volumetric_fog_density", 0.0))) and is_equal_approx(environment.volumetric_fog_length, float(values.get("volumetric_fog_length", 64.0))), expected + " applies authored fog density and length")
		_check(GRAPHICS.restart_required() == (expected == "Low"), expected + " reports the actual renderer restart requirement")
		GRAPHICS._loaded = false
		GRAPHICS.load_preferences()
		_check(GRAPHICS.selected() == expected, expected + " persists across a fresh preference load")
	# Low is only a requested renderer change; the process still runs Forward+.
	preset.grab_focus()
	await _tap(JOY_BUTTON_A)
	await _tap(JOY_BUTTON_A)
	_check(GRAPHICS.selected() == "High", "physical control returns Low through Medium to High")
	for key: String in GRAPHICS.FEATURES:
		var button: Button = graphics.get("_feature_buttons")[key]
		button.grab_focus()
		await _tap(JOY_BUTTON_A)
		var property := "volumetric_fog_enabled" if key == "volumetric_fog" else key + "_enabled"
		_check(GRAPHICS.selected() == "Custom" and environment.get(property) == (not bool(GRAPHICS._config.High.get(key))), "physical custom " + key + " changes active environment")
	(graphics.get("_shadow") as Button).grab_focus()
	await _tap(JOY_BUTTON_A)
	_check(GRAPHICS.values().shadow_quality == "Off" and sun.shadow_opacity == 0.0, "physical shadow control suppresses actual sun shadow opacity")
	await _tap(JOY_BUTTON_A)
	_check(GRAPHICS.values().shadow_quality == "Low" and sun.shadow_opacity > 0.0, "WorldLook restores authored shadow opacity when leaving Off")
	for i in 3:
		await _tap(JOY_BUTTON_A)
	_check(GRAPHICS.values().shadow_quality == "Off" and sun.shadow_opacity == 0.0, "shadow control cycles Low Medium High back to Off")
	(graphics.get("_distance") as Button).grab_focus()
	await _tap(JOY_BUTTON_A)
	_check(GRAPHICS.values().draw_distance == "Near" and is_equal_approx(camera.far, float(horizon.camera_vista_far_floor_m)) and is_equal_approx(root.mesh_lod_threshold, 4.0), "physical distance control applies Near LOD without removing the horizon")
	menu.call("close")
	for node: Node in [look, camera, sun, holder]:
		node.free()
	root.world_3d.environment = previous_environment
	world.free()
	# Hosted-only execution: the child shares this isolated user:// directory.
	# No --rendering-method: the real preboot preference selects the renderer.
	var output: Array = []
	var exit_code := OS.execute(OS.get_executable_path(), PackedStringArray([
		"--path", ProjectSettings.globalize_path("res://"), "--audio-driver", "Dummy",
		"--resolution", "1920x1080", "--script", "res://tests/smoke_graphics_settings.gd",
		"--", "--graphics-proof", "--graphics-forward-reload"]), output, true)
	for line: String in output:
		print(line)
	_check(exit_code == 0, "fresh native process reloads all six custom controls and persisted renderer")
	# Run the unchanged complementary Low/default/focus/save-routing branch
	# with a separate device profile, sequentially in this same hosted batch.
	var data_key := "XDG_DATA_HOME" if OS.get_name() == "Linux" else "APPDATA"
	var had_data_key := OS.has_environment(data_key)
	var previous_data_root := OS.get_environment(data_key)
	OS.set_environment(data_key, ProjectSettings.globalize_path("user://graphics-low-%d" % OS.get_process_id()))
	output.clear()
	exit_code = OS.execute(OS.get_executable_path(), PackedStringArray([
		"--path", ProjectSettings.globalize_path("res://"), "--audio-driver", "Dummy",
		"--rendering-method", "gl_compatibility", "--rendering-driver", "opengl3",
		"--resolution", "1920x1080", "--script", "res://tests/smoke_graphics_settings.gd",
		"--", "--graphics-proof"]), output, true)
	if had_data_key:
		OS.set_environment(data_key, previous_data_root)
	else:
		OS.unset_environment(data_key)
	for line: String in output:
		print(line)
	_check(exit_code == 0, "complementary Low/default/focus/restart-save smoke passes in a separate native process")
	print("Forward+ graphics controls proof: %d failures; no biome appearance or performance claim" % _failures.size())
