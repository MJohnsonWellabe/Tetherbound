extends SceneTree

## GPU pass 22 Oct (F39-0 supplemental, Venn fight frames): a world verb
## ("E Gather Reef Stone") drew over the fight's command bar in every frame.
## Real shared HUD scenes; a stand-in CombatManager reports the fight. While
## the combat HUD's command bar is shown the world prompt stays hidden; once
## the bar is released (a relay phase, or the fight ends) the prompt returns.
const WORLD_HUD := preload("res://scenes/ui/playground_hud.tscn")
const COMBAT_HUD := preload("res://scenes/combat/combat_hud.tscn")

class FakeCombat extends Node:
	var fighting := false
	func is_fighting() -> bool:
		return fighting

var failures: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _check(value: bool, label: String) -> void:
	if not value:
		failures.append(label)
		push_error(label)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	game.set_process(false)
	var world := Node.new()
	world.name = "PromptYieldFixture"
	root.add_child(world)
	current_scene = world
	var manager := FakeCombat.new()
	manager.name = "CombatManager"
	world.add_child(manager)
	var hud: CanvasLayer = WORLD_HUD.instantiate()
	world.add_child(hud)
	var combat: CanvasLayer = COMBAT_HUD.instantiate()
	world.add_child(combat)
	await _frames(10)
	combat.set_process(false)
	var prompt: Control = hud._prompt_label
	var grid: Control = combat._grid_panel

	hud._prompt_label.text = "E Gather Reef Stone"
	hud._yield_bottom_to_build_menu()
	_check(prompt.visible, "Exploration: the world prompt shows")

	manager.fighting = true
	grid.show()
	hud._yield_bottom_to_build_menu()
	_check(grid.is_visible_in_tree(), "Fixture: combat command bar shown")
	_check(not prompt.visible, "Fight: the world prompt yields to the command bar")

	grid.hide()
	hud._yield_bottom_to_build_menu()
	_check(prompt.visible, "Released command bar (relay phase): the interaction prompt returns")

	manager.fighting = false
	hud._yield_bottom_to_build_menu()
	_check(prompt.visible, "After the fight: the world prompt shows again")

	if failures.is_empty():
		print("fight world prompt yield smoke passed")
		quit(0)
	else:
		print("FAILED: ", failures)
		quit(1)
