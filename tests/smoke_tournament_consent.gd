extends SceneTree

## OWNER-0912-HALDA. Exercise the real dialogue panel and shipped physical pad
## routes: B declines without entering, X accepts and emits the round effect.

const PANEL_SCENE := preload("res://scenes/ui/dialogue_panel.tscn")
const PICKER := preload("res://scripts/ui/tournament_team_picker.gd")
const PARTY := preload("res://autoload/party.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")

var _failures: Array[String] = []
var _panel: CanvasLayer


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame
	await _exercise_selection()
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


func _exercise_selection() -> void:
	var party := PARTY.new()
	for species: String in ["terrapup", "bramblebun", "mudsnout", "meadowhart", "burrowback"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set("level", 5)
		CONDITION.note_rest_completed(member, CONDITION.config())
		party.add(member)
	var picker := PICKER.new()
	root.add_child(picker)
	var chosen: Array = []
	var cancels: Array = []
	picker.confirmed.connect(func(members: Array) -> void: chosen.assign(members))
	picker.cancelled.connect(func() -> void: cancels.append(true))
	if not picker.open_for(party):
		_fail("selector did not open for five owned creatures")
		picker.queue_free()
		return
	await _press_pad_action("interact")
	if not picker.is_open() or not chosen.is_empty():
		_fail("fewer than three selections were allowed to register")
	# Deliberately choose a non-roster order using actual controller events.
	await _press_pad_action("ui_right")
	await _press_pad_action("menu_confirm")
	await _press_pad_action("ui_left")
	await _press_pad_action("menu_confirm")
	await _press_pad_action("ui_left")
	await _press_pad_action("menu_confirm")
	await _press_pad_action("ui_left")
	await _press_pad_action("menu_confirm")
	if picker.get("_selected") != [party.at(1), party.at(0), party.at(4)]:
		_fail("selector lost chosen order or allowed a fourth entrant")
	var capture := OS.get_environment("TETHERBOUND_TOURNAMENT_CAPTURE")
	if not capture.is_empty():
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		picture.save_png(capture)
		print("Tournament selector capture: " + capture)
		for button: Button in picker.get("_buttons"):
			if not Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(button.get_global_rect()):
				_fail("a creature card lies outside the viewport")
	await _press_pad_action("menu_cancel")
	if picker.is_open() or cancels.size() != 1 or not chosen.is_empty() or not party.tournament_selection_ids().is_empty():
		_fail("cancelling changed registration or left the modal open")
	picker.open_for(party, [party.at(1), party.at(0), party.at(4)])
	await _press_pad_action("interact")
	if picker.is_open() or chosen != [party.at(1), party.at(0), party.at(4)] or party.size() != 5:
		_fail("confirm failed to return exactly the chosen three while retaining all five")
	if not picker.open_for(party):
		_fail("the selector did not reopen")
	await _press_pad_action("menu_cancel")
	picker.queue_free()
	await process_frame


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
