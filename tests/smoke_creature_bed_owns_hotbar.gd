extends SceneTree

## Real mapped B closes the production bed picker; that same held/released
## edge must not consume a potion when the world resumes. A fresh B must work.
const PANEL := preload("res://scripts/ui/creature_bed_panel.gd")
const BED := preload("res://scripts/build/creature_bed.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	await _frames(10)
	await _check_case(false)
	await _check_case(true)
	if failures.is_empty():
		print("Creature Bed owns close B through release; fresh world B heals: PASS")
	else:
		for failure in failures:
			print("FAIL: ", failure)
	quit(0 if failures.is_empty() else 1)

func _check_case(hud_after_panel: bool) -> void:
	print("Checking HUD after bed panel: ", hud_after_panel)
	var game := root.get_node("Game")
	var party: RefCounted = game.get("party")
	party.call("clear")
	var creature := CREATURE.from_species("terrapup", {"display_name": "Terrapup",
		"type": "ground", "base_hp": 200.0, "base_attack": 20.0, "base_defence": 20.0})
	creature.hp = 20.0
	party.call("add", creature)
	var inventory: RefCounted = game.get("inventory")
	inventory.call("add", "potion_small", 4)
	var hotbar: Array = game.get("hotbar")
	hotbar[0] = "potion_small"
	game.set("hotbar", hotbar)
	var hud := (load("res://scenes/ui/playground_hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	var bed := BED.new()
	root.add_child(bed)
	bed.set_build_index(0)
	var panel := PANEL.new()
	root.add_child(panel)
	if hud_after_panel:
		root.move_child(hud, root.get_child_count() - 1)
	panel.open(bed)
	await _frames(10)
	_check(panel.is_open() and paused, "bed picker did not open and pause")
	var before := int(inventory.call("count", "potion_small"))
	_button(true)
	await _frames(6)
	_check(not panel.is_open() and not paused, "physical B did not close picker and resume world")
	_check(int(inventory.call("count", "potion_small")) == before and creature.hp == 20.0,
		"closing/holding bed-picker B consumed a world potion")
	_button(false)
	await _frames(4)
	_check(int(inventory.call("count", "potion_small")) == before,
		"releasing bed-picker B consumed a potion")
	_button(true)
	await _frames(4)
	_button(false)
	await _frames(4)
	_check(int(inventory.call("count", "potion_small")) == before - 1 and creature.hp == 70.0,
		"fresh world B did not consume exactly one potion and heal 50HP")
	panel.queue_free()
	bed.queue_free()
	hud.queue_free()
	await _frames(2)

func _button(down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_B
	event.pressed = down
	Input.parse_input_event(event)

func _frames(count: int) -> void:
	for frame in count:
		await process_frame

func _check(ok: bool, why: String) -> void:
	if not ok:
		failures.append(why)
