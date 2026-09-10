extends SceneTree

## HUD-FREED-WINNER01. Reproduces the world-teardown seam from CI AD9 with
## the production HUD, InteractionArbiter and EncounterDirector. The arbiter
## has published the director's real Put-away offer; then that director is
## freed before the arbiter's next recompute, leaving its one-frame cached
## winner stale while the HUD polls prompt ownership.
##
##   godot --headless --path . --script tests/smoke_hud_freed_combat_prompt_lifecycle.gd

const HUD_SCENE := preload("res://scenes/ui/playground_hud.tscn")
const ARBITER_SCRIPT := preload("res://scripts/world/interaction_arbiter.gd")
const ENCOUNTER_DIRECTOR_SCRIPT := preload("res://scripts/combat/encounter_director.gd")

var _failures: Array[String] = []


class CombatStub extends Node:
	func is_fighting() -> bool:
		return false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var game := root.get_node_or_null(^"Game")
	_expect(game != null, "Game autoload is available")
	if game == null:
		_finish()
		return
	var party := game.get("party") as RefCounted
	_expect(party != null, "Game party is available")
	if party == null:
		_finish()
		return
	party.call("clear")
	var creature := game.call("make_creature", "terrapup", "Biscuit") as RefCounted
	_expect(creature != null and bool(party.call("add", creature)),
		"the production party holds an available ally")
	if creature == null or int(party.call("size")) == 0:
		_finish()
		return

	var world := Node3D.new()
	world.name = "FreedCombatPromptWorld"
	root.add_child(world)
	current_scene = world
	var player := CharacterBody3D.new()
	player.name = "Player"
	world.add_child(player)
	var arbiter := ARBITER_SCRIPT.new()
	arbiter.name = "InteractionArbiter"
	arbiter.set("player_path", NodePath("../Player"))
	world.add_child(arbiter)
	var hud := HUD_SCENE.instantiate() as CanvasLayer
	world.add_child(hud)
	for _frame in 5:
		await process_frame

	var legend := hud.get_node_or_null(^"Root/BottomDock/ExplorationLegend/Margin/Label") as RichTextLabel
	var prompt := hud.get_node_or_null(^"Root/BottomDock/Prompt") as RichTextLabel
	_expect(legend != null and prompt != null,
		"the production HUD built its exploration legend and contextual prompt")
	if legend == null or prompt == null:
		world.queue_free()
		_finish()
		return

	# Use the real director's creature-control offer rather than a test provider.
	# Attach its production script after a plain Node has entered the tree: that
	# gives BUILD_HOLD the real SceneTree it requires without running the
	# director's full world-population _ready() in this bounded HUD fixture.
	var manager := CombatStub.new()
	var ally_body := CharacterBody3D.new()
	ally_body.name = "BoundAllyBody"
	world.add_child(ally_body)
	var director := Node.new()
	director.name = "EncounterDirector"
	world.add_child(director)
	director.set_script(ENCOUNTER_DIRECTOR_SCRIPT)
	director.set("_manager", manager)
	director.set("_ally", creature)
	director.set("_ally_body", ally_body)
	director.call("set_arbiter", arbiter)
	arbiter.call("_recompute")
	var live_winner: Variant = arbiter.call("winning_provider")
	_expect(live_winner == director,
		"the real EncounterDirector is the arbiter's published winner")
	_expect(str(arbiter.call("prompt")).contains("Put Biscuit away"),
		"the bound ally produces the director's real Put-away offer")
	hud.call("_on_prompt_changed", str(arbiter.call("prompt")))
	hud.call("_update_exploration_legend")
	_expect(prompt.text.is_empty(),
		"PlaygroundHUD yields the director-owned prompt to CombatHUD")
	_expect(not legend.text.contains("Call Out") and not legend.text.contains("Put Away"),
		"the live director prompt suppresses the duplicate legend action")

	# Do not unregister or recompute first: this is the exact cached-winner window
	# seen during scene teardown in Gate A and core-verb CI jobs.
	director.free()
	_expect(not is_instance_valid(director), "the winning EncounterDirector is actually freed")
	var stale_belongs_to_combat: Variant = hud.call("_prompt_belongs_to_combat")
	_expect(stale_belongs_to_combat is bool and not bool(stale_belongs_to_combat),
		"a freed cached winner is treated as absent without touching its class")
	hud.call("_update_exploration_legend")
	_expect(legend.text.contains("Call Out"),
		"the available ally action returns after the stale director disappears")
	_expect(not legend.text.contains("Change Creature"),
		"stale-winner recovery does not invent an unavailable alternate-slot action")

	manager.free()
	world.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
	else:
		_failures.append(message)


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("PASS: freed EncounterDirector winner is safe and HUD action availability recovers")
		quit(0)
		return
	for failure: String in _failures:
		print("FAIL: %s" % failure)
	quit(1)
