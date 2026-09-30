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
