extends SceneTree

## Controller acceptance for the real naming prompt. Unlike the pure
## name_entry unit tests, every action here starts as a physical joypad event
## and must travel through the shipped InputMap before the prompt can see it.

const NAME_PROMPT_SCENE := "res://scenes/ui/name_prompt.tscn"
const ENTRY := preload("res://scripts/ui/name_entry.gd")

var _failures: Array[String] = []
var _prompt: CanvasLayer = null
var _confirmed: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_prompt = (load(NAME_PROMPT_SCENE) as PackedScene).instantiate()
	root.add_child(_prompt)
	for i in 10:
		await physics_frame
	_prompt.connect("confirmed", _on_confirmed)
	_prompt.call("open", "Test")
	for i in 6:
		await physics_frame

	# Headless starts in keyboard mode. A real d-pad event switches the shared
	# glyph tracker, and the prompt's mode guard intentionally consumes the
	# transition edge rather than moving or typing on it.
	_prime_gamepad(JOY_BUTTON_DPAD_RIGHT)
	for i in 6:
		await physics_frame
	if not bool(_prompt.get("_using_gamepad")):
		_fail("a physical d-pad event did not switch the naming prompt to its controller grid")
		_report()
		return

	var entry: RefCounted = _prompt.call("entry")
	if str(entry.selected()) != "A":
		_fail("the device-switch guard moved the cursor; expected A, got '%s'" % str(entry.selected()))

	# A types, d-pad navigates, and B deletes. Retyping after B proves B is
	# backspace here rather than a hidden cancel/escape path.
	await _tap_button(JOY_BUTTON_A)
	await _tap_button(JOY_BUTTON_DPAD_RIGHT)
	await _tap_button(JOY_BUTTON_A)
	if str(_prompt.call("current_text")) != "AB":
		_fail("raw A/d-pad input typed '%s', expected 'AB'" % str(_prompt.call("current_text")))
	await _tap_button(JOY_BUTTON_B)
	if str(_prompt.call("current_text")) != "A":
		_fail("raw B did not delete one character; name is '%s'" % str(_prompt.call("current_text")))
	await _tap_button(JOY_BUTTON_A)
	if str(_prompt.call("current_text")) != "AB":
		_fail("raw A could not retype after delete; name is '%s'" % str(_prompt.call("current_text")))

	# Hold the left stick past REPEAT_DELAY. One physical deflection must move
	# more than one cell; otherwise long names still require dozens of taps.
	var before_hold := int(entry.column)
	await _hold_axis(JOY_AXIS_LEFT_X, 1.0, 40)
	var travelled := posmod(int(entry.column) - before_hold, (ENTRY.ROWS[int(entry.row)] as Array).size())
	if travelled <= 1:
		_fail("held left-stick Right moved %d cell(s); repeat never engaged" % travelled)
	else:
		print("controller naming: held stick repeated across %d cells" % travelled)

	if not await _select_cell(entry, ENTRY.DONE):
		_report()
		return
	await _tap_button(JOY_BUTTON_A)
	for i in 8:
		await physics_frame
	if bool(_prompt.call("is_open")):
		_fail("raw A on OK did not close the naming prompt")
	if _confirmed != ["AB"]:
		_fail("controller confirmation emitted %s, expected exactly ['AB']" % str(_confirmed))

	_report()


func _on_confirmed(chosen: String) -> void:
	_confirmed.append(chosen)


func _tap_button(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	for i in 3:
		await physics_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await physics_frame


## Device selection is an event edge, not a held navigation gesture. Send the
## matching down/up pair together so the prompt can observe the device switch
## without manufacturing three frames of d-pad hold after its mode guard.
func _prime_gamepad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)


func _hold_axis(axis: JoyAxis, value: float, frames: int) -> void:
	var down := InputEventJoypadMotion.new()
	down.axis = axis
	down.axis_value = value
	Input.parse_input_event(down)
	for i in frames:
		await physics_frame
	var up := InputEventJoypadMotion.new()
	up.axis = axis
	up.axis_value = 0.0
	Input.parse_input_event(up)
	for i in 4:
		await physics_frame


func _select_cell(entry: RefCounted, cell: String) -> bool:
	var target := _cell_position(cell)
	if target.x < 0:
		_fail("'%s' is not present on the naming grid" % cell)
		return false
	for i in 12:
		if int(entry.row) == target.x:
			break
		await _tap_button(JOY_BUTTON_DPAD_DOWN)
	for i in 12:
		if int(entry.column) == target.y:
			break
		await _tap_button(JOY_BUTTON_DPAD_RIGHT)
	if str(entry.selected()) != cell:
		_fail("physical d-pad stopped on '%s' instead of '%s'" % [str(entry.selected()), ENTRY.cell_label(cell)])
		return false
	return true


func _cell_position(cell: String) -> Vector2i:
	for r in ENTRY.ROWS.size():
		var row: Array = ENTRY.ROWS[r]
		for c in row.size():
			if str(row[c]) == cell:
				return Vector2i(r, c)
	return Vector2i(-1, -1)


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("name prompt controller: OK -- type, delete, held repeat, and confirm use physical pad events.")
		quit(0)
		return
	for line in _failures:
		print("name prompt controller FAIL: %s" % line)
	quit(1)
