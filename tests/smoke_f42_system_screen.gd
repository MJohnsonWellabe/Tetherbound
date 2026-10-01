extends SceneTree

## Shared-queue native proof of modal ownership and controller back release.
## No gameplay/service/save/visual acceptance is implied by this smoke.
const SCREEN := preload("res://scripts/ui/system_screen.gd")
const OWNER := preload("res://scripts/ui/input_owner.gd")
var _failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var mouse_before := Input.mouse_mode
	var panel := SCREEN.new()
	root.add_child(panel)
	_check(panel.begin("Controller ownership proof", "A Select · B Back"), "surface opens")
	var action := panel.button(panel.body, "Focus target", func() -> void: pass, "stable-target")
	panel.finish("stable-target")
	await process_frame
	await process_frame
	_check(OWNER.current(self) == panel, "modal owns input")
	_check(root.gui_get_focus_owner() == action, "initial focus targets enabled content")
	var competing := SCREEN.new()
	root.add_child(competing)
	_check(not competing.begin("Competing modal", "Back"), "second modal cannot steal input")
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_B
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	_check(not panel.is_open(), "physical B closes the modal")
	_check(OWNER.current(self) == panel, "closing B remains owned until release")
	event = InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_B
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	_check(OWNER.current(self) == null, "ownership releases after B release")
	_check(Input.mouse_mode == mouse_before, "mouse state restored")
	_check(panel.begin("Reopen", "Back"), "closed surface reopens cleanly")
	panel.queue_free()
	competing.queue_free()
	await process_frame
	_check(OWNER.current(self) == null, "disposal releases input")
	for failure: String in _failures: push_error(failure)
	print("F42 MODAL SMOKE: PASS" if _failures.is_empty() else "F42 MODAL SMOKE: FAIL")
	quit(0 if _failures.is_empty() else 1)

func _check(ok: bool, message: String) -> void:
	if not ok: _failures.append(message)
