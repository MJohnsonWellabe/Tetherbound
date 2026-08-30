extends SceneTree

## Can the PLAYER eat, from the screen a player would try?
##
##   godot --headless --path . --script tests/smoke_backpack_player_eats.gd
##
## T5-CARE. `tests/test_food.gd` asserted that every food item restores satiety
## and that eating berries applies their buff, and it passed throughout a period
## when **the player could not eat from the Satchel at all** -- because it calls
## `player_vitals.eat()` directly. Its own comment claimed the call was made
## "exactly the way tab_backpack.gd's _read_use() does it", and that had stopped
## being true: D68 gave `berries` a `creature_food` key, `_read_use()` tests that
## BEFORE `satiety`, and `berries` is the only item in the game carrying a
## satiety value. So the Use verb opened a creature picker with no row for the
## player, the player-eating branch below it was dead code, and the test that
## should have caught it asserted the function rather than the path.
##
## Played evidence of the defect, from `tools/_play_t5_care.gd` against the real
## Satchel with a real pad press:
##
##   the Use verb opened the CREATURE target picker; the player's own satiety
##   was untouched (40). picker rows: [1. T0 HP 120/120, 2. empty, ...]
##
## So this test asserts REACHABILITY, at the player's own input level: real
## joypad buttons through the live InputMap, the real `game_menu.gd` shell, the
## real `tab_backpack.gd`. It does not call `eat()` and it must never be
## rewritten to -- the whole point is the route.
##
## Deliberately a smoke test rather than a unit test, and deliberately NOT
## against `meadows_playground.tscn`: `tab_backpack.gd::_player_node()` wants
## `get_tree().get_current_scene()` to have a `Player` child with a `vitals`
## property, and nothing more. A full Meadows build would cost minutes and
## prove nothing extra about this routing.

const VITALS := preload("res://scripts/player/player_vitals.gd")
const SETTLE := 8
## `interact` is USE and is joypad X; `menu_confirm` is joypad A. Read from the
## live InputMap so a rebind moves this test with them.
const USE_ACTION := "interact"
const CONFIRM_ACTION := "menu_confirm"


## The minimum `_player_node()` needs: a node named Player carrying vitals.
class StandInWorld extends Node3D:
	var vitals: RefCounted


var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("FAIL: the Game autoload is not in the tree")
		quit(1)
		return

	var world := Node3D.new()
	world.name = "StandIn"
	var player := StandInWorld.new()
	player.name = "Player"
	player.vitals = VITALS.new()
	player.vitals.call("configure", {"stamina": {"max": 100.0}, "health": {"max": 100.0}})
	player.vitals.call("configure_satiety", _vitals_config())
	world.add_child(player)
	root.add_child(world)
	# `current_scene` is a SceneTree property, not a Window one -- setting it on
	# `root` silently creates a stray property and `tab_backpack.gd::_player_node()`
	# still sees nothing.
	current_scene = world
	for i in 10:
		await process_frame

	var inventory: RefCounted = game.get("inventory")
	inventory.call("add", "berries", 5)
	var slot := int(inventory.call("find_slot", "berries"))
	if slot < 0:
		_fail("berries never reached a satchel slot")
		_report()
		return

	# The player is hungry. Half a bar: unambiguously below full, so the
	# trainer's row is eligible and the restore is measurable.
	player.vitals.set("satiety", 40.0)

	var menu: CanvasLayer = game.call("menu")
	menu.call("open", "backpack")
	for i in SETTLE:
		await process_frame
	var body: Node = _tab_body(menu, "backpack")
	if body == null:
		_fail("could not open the Satchel tab")
		_report()
		return
	var buttons: Array = body.get("_buttons")
	if slot >= buttons.size():
		_fail("berries landed in slot %d, past the rendered grid" % slot)
		_report()
		return
	(buttons[slot] as Button).grab_focus()
	await process_frame

	var use_button := _pad_button_for(USE_ACTION)
	var confirm_button := _pad_button_for(CONFIRM_ACTION)
	if use_button < 0 or confirm_button < 0:
		_fail("%s or %s has no joypad binding; a controller cannot reach this screen"
			% [USE_ACTION, CONFIRM_ACTION])
		_report()
		return

	# Against a build without the trainer row these helpers do not exist. Ask
	# before calling, so this file reports a clean failure naming what is
	# missing rather than erroring out mid-run -- a regression test that
	# crashes is a regression test nobody can read.
	if not body.has_method("_trainer_row_index") or not body.has_method("_player_vitals"):
		_fail("tab_backpack.gd has no trainer row in its target picker, so the Satchel "
			+ "cannot feed the player at all (berries carry both `satiety` and "
			+ "`creature_food`, and _read_use() tests `creature_food` first)")
		_report()
		return

	await _pad(use_button)
	if int(body.get("_targeting")) < 0:
		# Failure context, because "no picker" has more than one cause and the
		# message should say which.
		var seen_party: Variant = body.call("_party")
		var seen_vitals: Variant = body.call("_player_vitals")
		_fail(("a pad press of %s on Berries opened no picker at all "
			+ "(party size=%s, current_scene=%s, vitals=%s, trainer_eligible=%s, "
			+ "targeting_food='%s')") % [
			USE_ACTION,
			str(int(seen_party.call("size"))) if seen_party != null else "-",
			str(current_scene), str(seen_vitals),
			str(bool(body.call("_trainer_row_eligible"))),
			str(body.get("_targeting_food"))])
		_report()
		return
	print("  ok    Use on Berries opened the eater picker")

	# The trainer's row must exist, be visible, and be the focused one when the
	# player is the only hungry party present (there are no creatures here).
	var rows: Array = body.get("_target_rows")
	var trainer_index: int = int(body.call("_trainer_row_index"))
	if trainer_index >= rows.size():
		_fail("the picker has no trainer row (%d rows, trainer index %d)" % [
			rows.size(), trainer_index])
		_report()
		return
	var trainer_row := rows[trainer_index] as Button
	if not trainer_row.visible:
		_fail("the trainer's row is hidden for Berries, which restore %d satiety"
			% int((game.get("items") as RefCounted).call("definition", "berries").get("satiety", 0)))
	elif trainer_row.disabled:
		_fail("the trainer's row is disabled at 40%% satiety: '%s'" % trainer_row.text)
	else:
		print("  ok    the picker offers the player their own row: '%s'" % trainer_row.text.strip_edges())

	var focused := root.gui_get_focus_owner()
	if focused != trainer_row:
		_fail("focus did not land on the only eligible eater (the trainer); it is on %s"
			% (str((focused as Button).text) if focused is Button else "<nothing>"))
	else:
		print("  ok    focus landed on the trainer's row")

	var satiety_before := float(player.vitals.get("satiety"))
	var berries_before := int(inventory.call("count", "berries"))

	await _pad(confirm_button)

	var satiety_after := float(player.vitals.get("satiety"))
	var berries_after := int(inventory.call("count", "berries"))
	if int(body.get("_targeting")) != -1:
		_fail("confirming the trainer's row left the picker open")
	if satiety_after <= satiety_before:
		_fail("confirming the trainer's row fed nobody (satiety %.1f -> %.1f)"
			% [satiety_before, satiety_after])
	if berries_after != berries_before - 1:
		_fail("eating spent %d berries, expected 1 (%d -> %d)"
			% [berries_before - berries_after, berries_before, berries_after])
	if _failures.is_empty():
		print("  ok    the player ate from the Satchel (satiety %.0f -> %.0f, berries %d -> %d)"
			% [satiety_before, satiety_after, berries_before, berries_after])

	# And the buff the quick bar grants must be the same one, so a berry cannot
	# behave two ways depending on which screen reached it.
	var buffs: Array = player.vitals.get("active_buffs")
	var wanted: Dictionary = ((game.get("items") as RefCounted).call("definition", "berries")
		as Dictionary).get("buff", {})
	if not wanted.is_empty():
		if buffs.size() != 1 or str((buffs[0] as Dictionary).get("id", "")) != str(wanted.get("id", "")):
			_fail("eating from the Satchel did not apply the item's own buff (%s); got %s"
				% [str(wanted.get("id", "")), str(buffs)])
		else:
			print("  ok    it applied the same buff the quick bar applies (%s)" % str(wanted.get("id", "")))

	_report()


func _vitals_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/vitals.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if typeof(parsed) == TYPE_DICTIONARY else {}


func _tab_body(menu: CanvasLayer, tab_id: String) -> Node:
	var tabs: Array = menu.get("_tabs") as Array
	var bodies: Array = menu.get("_bodies") as Array
	for i in tabs.size():
		if str((tabs[i] as Dictionary).get("id", "")) == tab_id:
			menu.call("select", i)
			return bodies[i] as Node
	return null


func _pad_button_for(action: String) -> int:
	if not InputMap.has_action(action):
		return -1
	for event in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button != null:
			return button.button_index
	return -1


## A real controller button, the way hardware delivers it. Deliberately NOT an
## InputEventAction: routing through the InputMap is part of what this proves.
func _pad(button_index: int) -> void:
	var down := InputEventJoypadButton.new()
	down.button_index = button_index
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	await process_frame
	var up := InputEventJoypadButton.new()
	up.button_index = button_index
	up.pressed = false
	Input.parse_input_event(up)
	for i in 4:
		await process_frame


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL  %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("backpack player-eats smoke test passed")
		quit(0)
		return
	print("backpack player-eats smoke test FAILED (%d)" % _failures.size())
	quit(1)
