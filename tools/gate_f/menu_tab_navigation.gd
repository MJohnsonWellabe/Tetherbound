extends RefCounted

## Navigate only through the supplied physical-input callback. Read the live
## context after every press so conditional tabs cannot invalidate a route.
static func navigate(tree: SceneTree, read_context: Callable, press_next: Callable,
		tab: String, max_presses: int = 16) -> String:
	if tab.is_empty():
		return "HARNESS-ERROR select_menu_tab requires a tab id"
	var target := "menu_" + tab
	var visited: Array[String] = []
	var context := str(read_context.call())
	for count in clampi(max_presses, 1, 32) + 1:
		if not context.begins_with("menu_"):
			return "FAIL select_menu_tab left the pause shell: %s" % context
		if context == target:
			return "selected %s after %d controller RB presses; route %s" % [tab, count, visited]
		if visited.has(context):
			return "FAIL select_menu_tab target %s unavailable; tab cycle %s" % [tab, visited]
		visited.append(context)
		if count == clampi(max_presses, 1, 32):
			break
		var sent: Dictionary = await press_next.call()
		if not bool(sent.get("ok", false)):
			return "HARNESS-ERROR select_menu_tab: %s" % str(sent.get("why", "input failed"))
		var before := context
		for _frame in 40:
			await tree.process_frame
			context = str(read_context.call())
			if context != before:
				# Focus assignment is deferred by the production tab body.
				await tree.process_frame
				await tree.process_frame
				context = str(read_context.call())
				break
		if context == before:
			return "FAIL select_menu_tab RB did not change %s" % before
	return "FAIL select_menu_tab budget exhausted before %s; route %s" % [tab, visited]
