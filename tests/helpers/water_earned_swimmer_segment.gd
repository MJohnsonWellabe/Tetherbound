extends "res://tests/helpers/earned_roster_replacement_segment.gd"

## Bounded post-Iona seam. Caller supplies an already-engaged ordinary Water
## swimmer and earned materials/tools. Never creates catch state or inventory.
## Source/focused validation only until composed with an earned runtime caller.
const WATER_WALK := preload("res://tests/helpers/water_shellwatch_segment.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")
const SADDLE_RECIPE := "water_swim_saddle"
var _caught_swimmer: RefCounted


func _replacement_realm() -> String:
	return "water"


func _collect_world_nodes() -> bool:
	_encounter = _world.get_node_or_null("EncounterDirector")
	_combat = _world.get_node_or_null("CombatManager")
	_arbiter = _world.get_node_or_null("InteractionArbiter")
	if _game == null or _player == null or _rig == null or _encounter == null \
			or _combat == null or _arbiter == null or _game.menu() == null:
		_fail("Water replacement requires live combat, player, camera, arbiter and farewell UI")
		return false
	var throw: Node = _combat.call("throw_aim")
	if throw == null:
		_fail("Water replacement lacks its physical throw controller")
		return false
	_combat.catch_resolved.connect(func(success: bool, _shakes: int) -> void: _catch_results.append(success))
	throw.orb_struck.connect(func(_target: Node3D, _offset: float) -> void: _throw_strikes += 1)
	throw.orb_missed.connect(func(message: String) -> void:
		_throw_misses += 1
		print("Water earned throw missed: ", message))
	return true


static func compatible_swimmer(species_id: String) -> bool:
	return bool(SPECIES.definition(species_id).get("swim_mount", {}).get("compatible", false))


func replace_swimmer(tree: SceneTree, world: Node, game: Node,
		player: CharacterBody3D, rig: Node3D, wild: Node3D, outgoing_index: int) -> Dictionary:
	if game == null or not game.local.flags.has("water_swim_stone_earned") \
			or not game.local.flags.has("water_swim_saddle_recipe_learned") \
			or game.inventory.count("pickaxe") < 1:
		_fail("Water swimmer continuation requires earned Stone, Iona recipe and carried pickaxe")
		return _result()
	if not is_instance_valid(wild) or not compatible_swimmer(str(wild.get("species_id"))):
		_fail("Water replacement target is not an actual compatible wild swimmer")
		return _result()
	var newcomer: RefCounted = wild.get("instance")
	var result: Dictionary = await replace_existing(tree, world, game, player, rig, wild, outgoing_index)
	if bool(result.get("passed", false)) and _game.pending_catch == null \
			and _game.party.members().has(newcomer) and _game.party.size() == 5:
		_caught_swimmer = newcomer
	return result


func craft_earned_saddle() -> Dictionary:
	if _caught_swimmer == null or not _game.party.members().has(_caught_swimmer) \
			or _game.pending_catch != null or _game.party.size() != 5 or not _failures.is_empty():
		_fail("Paid Water craft requires this helper's completed actual catch/farewell")
		return _result()
	if _game.inventory.count("pickaxe") < 1 or not _game.can_craft(SADDLE_RECIPE):
		_fail("Paid saddle lacks earned tools/materials/recipe; no fixture supply permitted")
		return _result()
	var before: Dictionary = {}
	var costs: Array = _game.recipe_cost_for(SADDLE_RECIPE)
	for cost: Dictionary in costs:
		before[str(cost.id)] = _game.inventory.count(str(cost.id))
	var saddle_before := int(_game.inventory.count("swim_saddle"))
	var walker := WATER_WALK.new()
	walker.setup(_tree, _world as Node3D, _player, _rig)
	var prompt := _world.get_node_or_null("WaterCamps/water_camp_tidal_cradle/CraftInteractable") as Node3D
	if not await walker._activate(prompt, "Tidal paid saddle workbench"):
		_fail("Ordinary workbench approach/interaction failed: %s" % str(walker.failures))
		return _result()
	var panel: Node = INPUT_OWNER.current(_tree)
	if panel == null or not panel.has_method("is_open") or not panel.is_open():
		_fail("Ordinary workbench did not open its craft UI")
		return _result()
	var recipes: Array = panel.get("_recipe_ids")
	var rows: Array = panel.get("_rows")
	var index := recipes.find(SADDLE_RECIPE)
	if index < 0 or index >= rows.size():
		_fail("Earned Swim Saddle recipe absent from workbench")
		return _result()
	for step in rows.size():
		if _tree.root.gui_get_focus_owner() == rows[index]:
			break
		await _ceremony_tap("ui_down")
	if _tree.root.gui_get_focus_owner() != rows[index]:
		_fail("Controller did not select the earned saddle craft row")
		return _result()
	await _ceremony_tap("ui_accept")
	for cost: Dictionary in costs:
		if int(_game.inventory.count(str(cost.id))) != int(before[str(cost.id)]) - int(cost.n):
			_fail("Paid saddle did not spend the exact production recipe cost")
	if int(_game.inventory.count("swim_saddle")) != saddle_before + 1:
		_fail("Paid saddle did not produce exactly one saddle")
	await _ceremony_tap("menu_cancel")
	if panel.is_open() or _tree.paused or _tree.current_scene != _world:
		_fail("Paid saddle craft did not return control to the same world")
	_checkpoint("STOP after actual five-slot swimmer farewell and paid saddle; no mounted suffix claimed")
	return _result()
