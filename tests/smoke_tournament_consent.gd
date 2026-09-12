extends SceneTree

## OWNER-0912-HALDA. Exercise the real dialogue panel and shipped physical pad
## routes: B declines without entering, X accepts and emits the round effect.

const PANEL_SCENE := preload("res://scenes/ui/dialogue_panel.tscn")

var _failures: Array[String] = []
var _panel: CanvasLayer


func _init() -> void:
	_run()


func _run() -> void:
	_panel = PANEL_SCENE.instantiate() as CanvasLayer
	root.add_child(_panel)
	await process_frame

	if not bool(_panel.call("start", "tournament_halda_signup")):
		_fail("Halda's sign-up conversation did not open")
		return _report()
	# Reach the terminal question without answering it. The registration handoff
	# on the preceding line is unrelated to tournament consent.
	_panel.call("advance")
	_panel.call("drain_effects")
	_panel.call("advance")
	var runner: RefCounted = _panel.call("runner")
	if not bool(runner.call("line").get("confirmation", false)):
		_fail("sign-up did not stop on a Yes/No confirmation")
	else:
		await _press_pad_action("menu_cancel")
		if bool(_panel.call("is_open")):
			_fail("B did not close the sign-up question")
		if not (_panel.call("drain_effects") as Array).is_empty():
			_fail("declining sign-up still emitted tournament entry")

	if not bool(_panel.call("start", "tournament_quarter_begin")):
		_fail("round-one readiness conversation did not open")
		return _report()
	await _press_pad_action("interact")
	if bool(_panel.call("is_open")):
		_fail("X did not accept and close the readiness question")
	var effects: Array = _panel.call("drain_effects")
	if effects != ["battle:tournament_quarter_mira"]:
		_fail("accepting round one emitted %s" % str(effects))
	_report()


func _press_pad_action(action: String) -> void:
	# Clear the opening guard before injecting the same physical event the Ally
	# sends through the live InputMap.
	for i in 4:
		await physics_frame
	var button := -1
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			button = (event as InputEventJoypadButton).button_index
			break
	if button < 0:
		_fail("%s has no pad binding" % action)
		return
	var down := InputEventJoypadButton.new()
	down.button_index = button
	down.pressed = true
	Input.parse_input_event(down)
	await physics_frame
	var up := down.duplicate() as InputEventJoypadButton
	up.pressed = false
	Input.parse_input_event(up)
	await physics_frame


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  " + message)


func _report() -> void:
	if _failures.is_empty():
		print("Tournament sign-up and round readiness require explicit Yes: OK")
	quit(0 if _failures.is_empty() else 1)
