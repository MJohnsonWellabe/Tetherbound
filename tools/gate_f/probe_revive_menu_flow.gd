extends SceneTree

## T2-BUILDPLACE round 3: validates the Satchel's Revive-item flow against a
## REAL live Backpack tab, both branches (nobody eligible / a real fainted
## creature), so a fix that uses it in S03.json is not guesswork.
##
## Two full S03 replays this round both left party_size==1 with the sole
## starter fainted after the catch loop (tools/gate_f/segments/S03.json's own
## pre-existing gathering/catch steps, unowned by this lane) -- a state
## party_cycle (autoload/party.gd) cannot fix, since there is no second
## creature to cycle to. data/items/items.json's `revive` item
## (creature_instance.gd::revive()) is the game's own designed answer, used
## through scripts/ui/tab_backpack.gd's target picker (open backpack, focus
## the item, `interact` opens the picker, `ui_accept` confirms on the
## auto-focused eligible row). Before adding that sequence to a real segment,
## this probe checks the one thing that made it risky to guess at blind:
## does pressing `interact` on the Revive slot when NOBODY needs reviving
## truly no-op (message only), or does a stray `ui_accept` afterward pick the
## stack up into "held" state and leave the satchel in a bad state for later
## steps?
##
##   godot --headless --path . --script tools/gate_f/probe_revive_menu_flow.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 120


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("PROBE FAIL: no Game autoload")
		quit(1)
		return
	var party: RefCounted = game.get("party")
	var inventory: RefCounted = game.get("inventory")
	if party == null or inventory == null:
		print("PROBE FAIL: no party/inventory")
		quit(1)
		return

	# --- branch A: nobody needs reviving (party size 1, healthy) ---
	var healthy: RefCounted = game.call("make_creature", "terrapup")
	party.call("add", healthy)
	inventory.call("add", "revive", 2)
	print("--- branch A: 1 healthy creature, revive x2 in satchel ---")
	await _open_backpack_and_try_revive(game)
	var stack_a: Dictionary = inventory.call("stack_at", _find_slot(inventory, "revive"))
	print("  after: revive stack = %s" % str(stack_a))
	await _close_menu(game)

	# --- branch B: the sole party member is fainted ---
	healthy.fainted = true
	print("")
	print("--- branch B: the sole party member is now fainted ---")
	print("  fainted before: %s" % str(healthy.get("fainted")))
	await _open_backpack_and_try_revive(game)
	print("  fainted after: %s" % str(healthy.get("fainted")))
	var stack_b: Dictionary = inventory.call("stack_at", _find_slot(inventory, "revive"))
	print("  after: revive stack = %s" % str(stack_b))
	await _close_menu(game)

	quit(0)


func _find_slot(inventory: RefCounted, id: String) -> int:
	for i in 60:
		var s: Dictionary = inventory.call("stack_at", i)
		if not s.is_empty() and str(s.get("id", "")) == id:
			return i
	return -1


func _open_backpack_and_try_revive(game: Node) -> void:
	var menu := _find_by_script(root, "playground_hud.gd")
	# The shell/menu opener: reuse the SAME shortcut S03.json's own
	# open_menu(tab:backpack) step drives, through the real input map, rather
	# than reaching into UI internals.
	await _tap("inventory")
	for i in 20:
		await physics_frame
	var backpack := _find_by_script(root, "tab_backpack.gd")
	if backpack == null:
		print("  PROBE FAIL: no live tab_backpack.gd node")
		return
	var inventory: RefCounted = game.get("inventory")
	var slot := _find_slot(inventory, "revive")
	if slot < 0:
		print("  PROBE FAIL: no revive stack in the satchel")
		return
	backpack.set("_focused", slot)
	if backpack.has_method("_describe"):
		backpack.call("_describe", slot)
	for i in 5:
		await physics_frame
	print("  focused slot %d (revive), _held before=%s _targeting before=%s" % [
		slot, str(backpack.get("_held")), str(backpack.get("_targeting"))])
	await _tap("interact")
	for i in 10:
		await physics_frame
	print("  after interact: _held=%s _targeting=%s" % [
		str(backpack.get("_held")), str(backpack.get("_targeting"))])
	await _tap("ui_accept")
	for i in 10:
		await physics_frame
	print("  after ui_accept: _held=%s _targeting=%s" % [
		str(backpack.get("_held")), str(backpack.get("_targeting"))])


func _close_menu(game: Node) -> void:
	# UNCONDITIONAL sequence -- no branching available in a real segment
	# script, so this is exactly what S03.json would press regardless of
	# which branch just happened: menu_cancel once (branch A: puts the
	# accidentally-picked-up stack back, menu stays open; branch B: already
	# in normal grid mode, so the shell reads this as Close), then again
	# (branch A: now also in normal grid mode, closes; branch B: menu
	# already closed, this press should be an inert no-op in world context).
	await _tap("menu_cancel")
	for i in 10:
		await physics_frame
	print("  after menu_cancel x1: %s" % _describe_state())
	await _tap("menu_cancel")
	for i in 10:
		await physics_frame
	print("  after menu_cancel x2: %s" % _describe_state())


func _describe_state() -> String:
	var shell := _find_by_script(root, "game_menu.gd")
	return "shell.is_open=%s" % (
		str(shell.call("is_open")) if shell != null and shell.has_method("is_open") else "?")


func _tap(action: String) -> void:
	var down := _joy_event_for(action, true)
	if down == null:
		Input.action_press(action)
		for i in 2:
			await process_frame
		Input.action_release(action)
		for i in 5:
			await process_frame
		return
	Input.parse_input_event(down)
	Input.action_press(action)
	for i in 2:
		await process_frame
	Input.parse_input_event(_joy_event_for(action, false))
	Input.action_release(action)
	for i in 5:
		await process_frame


func _joy_event_for(action: String, pressed: bool) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			var out := InputEventJoypadButton.new()
			out.device = 0
			out.button_index = button.button_index
			out.pressed = pressed
			return out
	return null


func _find_by_script(node: Node, suffix: String) -> Node:
	var script: Script = node.get_script()
	if script != null and str(script.resource_path).ends_with(suffix):
		return node
	for child in node.get_children():
		var found := _find_by_script(child, suffix)
		if found != null:
			return found
	return null
