extends SceneTree

## Real Game Party/Inventory and production Satchel controls, no world boot.
## Fixture setup alone creates injured creatures/items. The snapshot under
## test only observes actual focus and the live production item picker.
const RECOVERY := preload("res://tools/gate_f/party_revive_recovery.gd")
const OWNER := preload("res://scripts/ui/input_owner.gd")
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await _frames(10)
	var game := root.get_node("Game")
	var party: RefCounted = game.get("party")
	var inventory: RefCounted = game.get("inventory")
	party.call("clear")
	for row in 3:
		var creature: RefCounted = game.call("make_creature", "bramblebun", "Twin")
		_check(creature != null, "fixture creature must be built by production species database")
		if creature == null:
			_report()
			return
		creature.set("hp", 0.0 if row < 2 else 1.0)
		creature.set("fainted", row < 2)
		party.call("add", creature)
	inventory.call("add", "revive", 3)
	inventory.call("add", "potion_small", 3)
	var count := int(inventory.call("count", "revive"))
	var identities: Array = [party.call("at", 0), party.call("at", 1), party.call("at", 2)]
	var menu: Node = game.call("menu")
	menu.call("open")
	await _frames(6)
	menu.call("select", 0)
	await _frames(6)
	var tab: Node = menu.get("_bodies")[0]
	_check(tab.get_script().resource_path.ends_with("tab_backpack.gd"), "fixture must use production TabBackpack")
	var revive_slot := int(inventory.call("find_slot", "revive"))
	var potion_slot := int(inventory.call("find_slot", "potion_small"))
	var buttons: Array = tab.get("_buttons")
	(buttons[revive_slot] as Button).grab_focus()
	await _frames(2)
	var state := RECOVERY.snapshot(game, tab, "menu_backpack", OWNER.current(self))
	_check(state.party == party and state.revives == count, "snapshot must read real party and owned Revive total")
	_check(state.menu_owned and state.grid_item == "revive", "actual focused grid cell must identify Revive")
	_check(state.picker_item == "" and state.focused_creature == null, "grid focus must not masquerade as target selection")
	(buttons[potion_slot] as Button).grab_focus()
	await _frames(2)
	state = RECOVERY.snapshot(game, tab, "menu_backpack", OWNER.current(self))
	_check(state.grid_item == "potion_small", "grid readback must follow actual focus, not cached Revive slot")
	(buttons[revive_slot] as Button).grab_focus()
	await _frames(2)
	await _pad("interact")
	var rows: Array = tab.get("_target_rows")
	state = RECOVERY.snapshot(game, tab, "menu_backpack", OWNER.current(self))
	_check(state.picker_item == "revive", "mapped X must open actual Revive picker")
	_check(state.focused_creature == identities[0], "first eligible real button maps to first creature identity")
	(rows[1] as Button).grab_focus()
	await _frames(2)
	state = RECOVERY.snapshot(game, tab, "menu_backpack", OWNER.current(self))
	_check(state.focused_creature == identities[1] and state.focused_creature != identities[0], "duplicate-name second row must preserve distinct creature identity")
	_check((rows[2] as Button).disabled, "healthy creature is disabled for a Revive")
	var trainer: Button = rows[5]
	_check(trainer.disabled and not trainer.visible and trainer.focus_mode == Control.FOCUS_NONE, "trainer is not a Revive target")
	# A button can become disabled while focus changes are deferred. Such a
	# transient must never become authorization to confirm a target.
	(rows[1] as Button).disabled = true
	state = RECOVERY.snapshot(game, tab, "menu_backpack", OWNER.current(self))
	_check(state.focused_creature == null, "disabled focused control is not an eligible creature")
	tab.call("_refresh_target_panel")
	var foreign := Node.new()
	root.add_child(foreign)
	state = RECOVERY.snapshot(game, tab, "panel:foreign", foreign)
	_check(not state.menu_owned and state.focused_creature == null and state.picker_item == "", "foreign input ownership must hide all actionable picker readback")
	foreign.queue_free()
	await _pad("menu_cancel")
	(buttons[potion_slot] as Button).grab_focus()
	await _frames(2)
	await _pad("interact")
	_check(int(tab.get("_targeting")) >= 0 and float(tab.get("_targeting_heal")) > 0.0, "wrong-picker fixture must be a real production potion picker")
	state = RECOVERY.snapshot(game, tab, "menu_backpack", OWNER.current(self))
	_check(state.picker_item == "" and state.focused_creature == null, "potion picker cannot authorize a Revive confirmation")
	await _pad("menu_cancel")
	menu.call("close")
	await _frames(3)
	state = RECOVERY.snapshot(game, tab, "world", OWNER.current(self))
	_check(not state.menu_owned and state.grid_item == "" and state.focused_creature == null, "closed Satchel exposes no actionable focus")
	_check(int(inventory.call("count", "revive")) == count, "snapshot/picker observation must not spend a Revive")
	for row in 3:
		_check(party.call("at", row) == identities[row], "snapshot preserves roster identity")
		_check(float(identities[row].get("hp")) == (0.0 if row < 2 else 1.0), "snapshot does not heal")
	_report()


func _pad(action: String) -> void:
	for binding in InputMap.action_get_events(action):
		if binding is InputEventJoypadButton:
			var event := InputEventJoypadButton.new()
			event.button_index = binding.button_index
			event.pressed = true
			Input.parse_input_event(event)
			await _frames(2)
			event = InputEventJoypadButton.new()
			event.button_index = binding.button_index
			# Some polling actions share a button with UI actions. Release the
			# physical binding itself, exactly as a real controller would.
			event.pressed = false
			Input.parse_input_event(event)
			await _frames(4)
			return
	_check(false, "missing mapped controller button: " + action)


func _frames(count: int) -> void:
	for frame in count: await process_frame


func _check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures.append(why)


func _report() -> void:
	for failure in failures: print("FAIL: ", failure)
	print("Party Revive production snapshot: %d checks, %d failed" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
