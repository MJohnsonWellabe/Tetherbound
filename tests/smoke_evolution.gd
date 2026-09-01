extends SceneTree

## R4.6: does the evolution ceremony actually reach the player, through the
## real Team screen, on real input?
##
##   godot --headless --path . --script tests/smoke_evolution.gd
##
## `tests/test_evolution.gd` proves `scripts/creatures/evolution.gd`'s pure
## logic in isolation. It cannot see whether pressing the real button on the
## real Team screen (`tab_creatures.gd`) actually reaches that logic, drives
## the ceremony's two-beat `menu_confirm` sequence, swaps the live 3D preview,
## and hands the menu back in a state where `menu_cancel` still closes it --
## the same "wiring, not just the model" gap `smoke_menu.gd`'s own header
## names for reorder/activate. This is that test for evolve.
##
## Not currently wired into `.github/workflows/ci.yml` as its own job, the
## same honest gap `smoke_creature_control.gd`/`smoke_art.gd`/
## `smoke_mouse_look.gd`/`smoke_no_double_prompt.gd`/`smoke_wake_softlock.gd`
## already carry -- five smoke tests exist and are not CI-wired; this is a
## sixth, not a new pattern. Recorded in `ralph/DONE.md` rather than left
## silent.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240

var _failures: Array[String] = []
var _menu: CanvasLayer = null
var _game: Node = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("the Game autoload is not in the tree")
		_report()
		return
	_menu = _game.call("menu")
	if _menu == null:
		_fail("the autoload did not stand up the menu")
		_report()
		return

	await _refuses_below_the_requirements()
	await _evolves_a_ready_creature_and_hands_the_menu_back_clean()
	_report()


## An ineligible creature (fresh-caught, no bond) must explain itself and
## start no ceremony -- pressing the verb should feel like `TEACH_ACTION` on
## a creature with nothing to learn, not silence and not a crash.
func _refuses_below_the_requirements() -> void:
	var party: RefCounted = _game.get("party")
	var creature: RefCounted = _game.call("make_creature", "mudsnout")
	if creature == null or not bool(party.call("add", creature)):
		_fail("could not seed a Mudsnout to test the refusal path")
		return

	await _press("inventory")
	if not bool(_menu.call("is_open")):
		_fail("`inventory` did not open the menu")
		return
	_menu.call("select", 1)
	for i in 4:
		await process_frame

	await _press("backpack_drop")

	var body: Node = _menu.get("_bodies")[1]
	if str(body.get("_evolution_stage")) != "":
		_fail("a level-1, zero-bond Mudsnout started a ceremony; it should have been refused")
	var status := str(_menu.get("_status").text)
	if not status.contains("level"):
		_fail("the refusal message did not explain the level gate: '%s'" % status)
	else:
		print("an ineligible Mudsnout is refused, with a reason, and starts no ceremony")

	await _press("menu_cancel")
	if bool(_menu.call("is_open")):
		_fail("the menu did not close after the refusal check")


## The real path: level, bond AND the catalyst item met -- evolve, watch the
## two-beat ceremony, and confirm the menu is handed back usable.
##
## SD17 flipped `evolution.mudsnout.item_id` in the shipped
## data/config/progression.json from "" to `heartstone`, because the Burrow
## Warrens now has a real one to find. So this path has to carry one, exactly
## as a player would: the stone goes in the satchel first and the evolution
## spends it. (The refusal path above is unchanged -- a level-1 creature is
## refused on the level gate long before the item is looked at.)
func _evolves_a_ready_creature_and_hands_the_menu_back_clean() -> void:
	var party: RefCounted = _game.get("party")
	var creature: RefCounted = _game.call("make_creature", "mudsnout", "Snorty")
	if creature == null:
		_fail("could not build a second Mudsnout for the real evolve path")
		return
	creature.set("level", 20)
	# OWNER-0901-BOND-MILESTONES: the mudsnout evolution gate now reads
	# `bond_tier` (real shipped requirement: 3) off the milestone ladder
	# instead of a raw bond value. Generous margin above every one of the
	# shipped ladder's first three targets, the same "well past the gate"
	# spirit `bond = 80` (well past the old threshold of 55) had.
	creature.set("battles_fought", 200)
	creature.set("landmarks_visited_together", 20)
	creature.set("distance_m_together", 20000.0)
	if not bool(party.call("add", creature)):
		_fail("could not seed the ready Mudsnout")
		return
	var inventory: RefCounted = _game.get("inventory")
	var catalyst := str(_evolution_item_id())
	if catalyst != "" and int(inventory.call("count", catalyst)) < 1:
		inventory.call("add", catalyst, 1)
	var slot := int(party.call("size")) - 1

	if not bool(_menu.call("is_open")):
		await _press("inventory")
	_menu.call("select", 1)
	for i in 4:
		await process_frame

	var body: Node = _menu.get("_bodies")[1]
	(body.get("_rows")[slot] as Button).grab_focus()
	for i in 2:
		await process_frame

	await _press("backpack_drop")
	if str(body.get("_evolution_stage")) != "glow":
		_fail("pressing evolve on a ready Mudsnout did not start the ceremony (_evolution_stage=%s)" \
			% str(body.get("_evolution_stage")))
		return
	if str(party.call("at", slot).get("species_id")) != "mudsnout":
		_fail("the species swapped before the player's own confirm press")

	await _press("menu_confirm")
	if str(body.get("_evolution_stage")) != "reveal":
		_fail("the first confirm press did not reach the reveal stage (_evolution_stage=%s)" \
			% str(body.get("_evolution_stage")))
	var evolved: RefCounted = party.call("at", slot)
	if str(evolved.get("species_id")) != "tuskroot":
		_fail("the creature did not actually evolve into Tuskroot (species_id=%s)" % str(evolved.get("species_id")))
	if str(evolved.get("nickname")) != "Snorty":
		_fail("the nickname was lost across evolution")
	if int(evolved.get("level")) != 20:
		_fail("the level was not preserved across evolution (level=%d)" % int(evolved.get("level")))

	await _press("menu_confirm")
	if str(body.get("_evolution_stage")) != "":
		_fail("the second confirm press did not close the ceremony")
	if bool(body.get("_evolution_panel").visible):
		_fail("the ceremony panel is still visible after closing")
	if not bool(body.get("_list").visible):
		_fail("the party list did not come back after the ceremony closed")

	print("a ready Mudsnout evolves into Tuskroot through the real ceremony, nickname and level intact")

	# The real regression this proves: `hold_input(true)` during the ceremony
	# must be undone, or the menu is left deaf and the player is stuck.
	await _press("menu_cancel")
	if bool(_menu.call("is_open")):
		_fail("the menu did not close after the ceremony; `hold_input` was likely never released")
	else:
		print("the menu is handed back usable — `menu_cancel` still closes it")


func _press(action: String) -> void:
	Input.action_press(action)
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	await process_frame
	Input.action_release(action)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	for i in 4:
		await process_frame


## The catalyst the SHIPPED config asks for, read rather than hard-coded --
## `item_id` is tunable (and was "" until SD17), so this test follows it
## instead of pinning it.
func _evolution_item_id() -> String:
	var file := FileAccess.open("res://data/config/progression.json", FileAccess.READ)
	if file == null:
		return ""
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ""
	var entry: Variant = (parsed as Dictionary).get("evolution", {}).get("mudsnout", {})
	return str((entry as Dictionary).get("item_id", "")) if entry is Dictionary else ""


func _fail(message: String) -> void:
	_failures.append(message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("evolution smoke test passed")
		quit(0)
		return
	for line in _failures:
		print("  FAIL: %s" % line)
	quit(1)
