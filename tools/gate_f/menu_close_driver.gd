extends RefCounted

## Physical pause-shell recovery, including picker/held-stack submodes.
## read() returns menu_open, menu_owns_input, context, and owner_is_menu.
## owner_is_menu compares InputOwner.current(tree) with the actual GameMenu.
## press() injects one guarded mapped cancel tap and returns {ok, why}.
## settle() advances ONE budgeted frame and returns {ok, why}; it must not inject.
## Upper bound: max_presses taps plus max_settle_frames settle callbacks.
## An already-closed world costs no input. A close-release latch costs only waits.
static func execute(read: Callable, press: Callable, settle: Callable,
		max_presses: int = 3, max_settle_frames: int = 12,
		interrupted: Callable = Callable()) -> Dictionary:
	var result := {"ok": false, "why": "", "presses": 0, "settle_frames": 0}
	if not read.is_valid() or not press.is_valid() or not settle.is_valid():
		return _fail(result, "missing physical menu-close callback")
	if max_presses < 1 or max_presses > 3 or max_settle_frames < 1 or max_settle_frames > 120:
		return _fail(result, "menu-close bounds require 1..3 taps and 1..120 settle frames")
	while true:
		if interrupted.is_valid() and bool(interrupted.call()):
			return _fail(result, "menu close interrupted by cost gate")
		var state: Dictionary = read.call()
		for key: String in ["menu_open", "menu_owns_input", "context", "owner_is_menu"]:
			if not state.has(key):
				return _fail(result, "menu-close observation missing " + key)
		var opened := bool(state.menu_open)
		var owns := bool(state.menu_owns_input)
		var context := str(state.context)
		if not opened and not owns:
			if context != "world":
				return _fail(result, "shell closed into unexpected context: " + context)
			result.ok = true
			return result
		if not bool(state.owner_is_menu) or not context.begins_with("menu"):
			return _fail(result, "pause shell does not own cancel: " + context)
		if int(result.settle_frames) >= max_settle_frames:
			return _fail(result, "menu-close settle budget exhausted")
		if opened:
			if int(result.presses) >= max_presses:
				return _fail(result, "pause shell remained open after bounded cancel taps")
			var sent: Dictionary = await press.call()
			if not bool(sent.get("ok", false)):
				return _fail(result, "cancel refused: " + str(sent.get("why", "")))
			result.presses += 1
		var advanced: Dictionary = await settle.call()
		result.settle_frames += 1
		if not bool(advanced.get("ok", false)):
			return _fail(result, "settle refused: " + str(advanced.get("why", "")))
	return result


static func _fail(result: Dictionary, why: String) -> Dictionary:
	result.why = why
	return result
