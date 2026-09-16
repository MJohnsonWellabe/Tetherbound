extends SceneTree

## Fixture smoke for the actual Gate F navigation algorithm and production menu.
## Skills reveal is fixture setup; all menu changes use parsed controller input.
const NAVIGATION := preload("res://tools/gate_f/menu_tab_navigation.gd")
var _failures := 0
var _checks := 0
var _menu: Node
var _presses := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		print("FAIL: ", message)

func _frames(count: int = 4) -> void:
	for _frame in count:
		await process_frame

func _context() -> String:
	return "menu_" + str(_menu.call("current_tab_id")) if _menu.call("is_open") else "world"

func _press(action: String = "menu_tab_right") -> Dictionary:
	var binding: InputEventJoypadButton
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			binding = event
			break
	if binding == null:
		return {"ok": false, "why": "no controller binding for " + action}
	_presses += 1
	for down: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = binding.button_index
		event.pressed = down
		Input.parse_input_event(event)
		if down:
			Input.action_press(action)
		else:
			Input.action_release(action)
		await _frames(3)
	return {"ok": true}

func _run() -> void:
	await _frames()
	var game := root.get_node("Game")
	_menu = game.call("menu")
	var local: RefCounted = game.get("local")
	local.reset()
	for revealed: bool in [false, true]:
		local.skills.load_data({"revealed": revealed})
		await _press("map")
		_check(_context() == "menu_map", "Map shortcut opens production menu")
		_presses = 0
		var result := await NAVIGATION.navigate(self, _context, _press, "save")
		_check(result.begins_with("selected save"), result)
		_check(_context() == "menu_save", "Save is the actual production tab")
		_check(_presses == (5 if revealed else 4), "Skills and Players affect real transition count")
		_check(root.gui_get_focus_owner() != null, "Save has controller focus")
		var unchanged := _presses
		result = await NAVIGATION.navigate(self, _context, _press, "save")
		_check(result.begins_with("selected save") and _presses == unchanged, "Already-selected tab uses no input")
		await _press("map")
		result = await NAVIGATION.navigate(self, _context, _press, "build")
		_check(result.begins_with("selected build") and _context() == "menu_build", "Build is reached with either Skills visibility")
		await _press("map")
		result = await NAVIGATION.navigate(self, _context, _press, "save", 1)
		_check(result.begins_with("FAIL"), "Too-small budget fails closed")
		result = await NAVIGATION.navigate(self, _context, _press, "missing_tab")
		_check(result.contains("unavailable"), "Unknown tab fails at first repeated live tab")
		result = await NAVIGATION.navigate(self, _context, func() -> Dictionary: return {"ok": true}, "missing_tab")
		_check(result.contains("did not change"), "Unresponsive RB fails closed")
		await _press("menu_cancel")
		result = await NAVIGATION.navigate(self, _context, _press, "save")
		_check(result.contains("left the pause shell"), "Closed menu is refused")
	print("Gate F menu navigation: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
