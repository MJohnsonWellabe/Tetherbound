extends "res://tests/test_case.gd"
## Production panel/runner and NPC conversation delivery in an initialized tree.
## Lightweight speaker and Game adapters exclude meshes, terrain and reward writes.
const PANEL := preload("res://scenes/ui/dialogue_panel.tscn")
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")

class Personal extends RefCounted:
	var flags := {"water_swim_stone_earned": true}

class Session extends RefCounted:
	func local_peer_id() -> int:
		return 17

class GameFixture extends Node:
	var current_realm := "water"
	var local := Personal.new()
	var progression: Dictionary = {}
	var session := Session.new()

func _case_synchronous_delivery() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var original := tree.root.get_node_or_null("Game")
	if original != null: original.name = "OriginalGameForDialogueTest"
	var game := GameFixture.new()
	game.name = "Game"
	tree.root.add_child(game)
	var fixture := Node3D.new()
	tree.root.add_child(fixture)
	var panel: Node = PANEL.instantiate()
	fixture.add_child(panel)
	panel.set_process(false)
	panel.set_physics_process(false)
	var npcs := NPCS.new()
	fixture.add_child(npcs)
	var speaker := Node3D.new()
	var player := Node3D.new()
	fixture.add_child(speaker)
	fixture.add_child(player)
	var dialogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/water.json"))
	var cast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	var conversation: Dictionary = dialogue.conversations.water_iona_recipe.duplicate(true)
	for line: Variant in conversation.lines:
		if line is Dictionary:
			line.erase("effect")
			line.erase("effects")
	var table := RUNNER.table()
	var had_conversation := table.has("water_iona_recipe")
	var previous: Variant = table.get("water_iona_recipe")
	table.water_iona_recipe = conversation
	# Same seams wired by build(), without constructing all installed NPC meshes.
	npcs._panel = panel
	npcs._player = player
	npcs._bodies = {"iona": speaker}
	npcs._specs = {"iona": {"display_name": "Researcher Iona", "portrait": conversation.portrait}}
	npcs._conversations = {"water_iona_recipe": conversation}
	npcs._guards = cast.dialogue_event_guards
	panel.finished.connect(npcs._on_finished)
	panel.line_presented.connect(npcs._on_line_presented)
	var events: Array = []
	npcs.guarded_event_requested.connect(func(event: String, npc: String, peer: int): events.append([event, npc, peer]))
	assert_eq(conversation.lines.size(), 2, "Fixture uses the authored two-line Iona lesson")
	assert_true(npcs.start_conversation("iona", "water_iona_recipe"))
	assert_eq(events.size(), 0, "Opening a lesson never grants its action")
	panel.close()
	assert_eq(events.size(), 0, "Closing before the final line cannot teach the recipe")
	assert_false(panel.is_open())
	assert_true(npcs.start_conversation("iona", "water_iona_recipe"))
	# Deliberately no await, idle callback or frame between these two advances.
	panel.advance()
	assert_true(panel.is_open())
	assert_eq(events.size(), 0, "Showing the final line does not complete it")
	panel.advance()
	assert_false(panel.is_open())
	assert_eq(events, [["water:water_swim_saddle_recipe_taught", "iona", 17]], "Finishing after a synchronous advance delivers exactly one guarded request")
	assert_eq(panel.drain_effects(), [], "No generic unguarded effect accompanies the request")
	panel.close()
	assert_eq(events.size(), 1, "An extra close cannot replay a finished lesson")
	assert_true(npcs.start_conversation("iona", "water_iona_recipe"))
	npcs._on_line_presented("unrelated_conversation", true)
	panel.close()
	assert_eq(events.size(), 1, "Another conversation's last line cannot authorize this one")
	assert_true(npcs.start_conversation("iona", "water_iona_recipe"))
	panel.advance()
	game.local.flags.clear()
	panel.advance()
	assert_eq(events.size(), 1, "The personal prerequisite is rechecked at delivery")
	assert_false(npcs.start_conversation("iona", "water_iona_recipe"), "A player without the Swim Stone cannot start the guarded lesson")
	assert_eq(game.local.flags, {}, "NPC dialogue emits requests and never writes rewards")
	fixture.free()
	game.free()
	if original != null: original.name = "Game"
	if had_conversation: table.water_iona_recipe = previous
	else: table.erase("water_iona_recipe")

func test_iona_delivery_without_an_idle_frame() -> void:
	var path := "user://water-dialogue-delivery-child.gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_true(file != null)
	if file == null: return
	file.store_string('extends SceneTree\nfunc _initialize():\n\tcall_deferred("run")\nfunc run():\n\tvar test = load("res://tests/test_water_dialogue_delivery.gd").new()\n\ttest._case_synchronous_delivery()\n\tprint("WATER_DIALOGUE_DELIVERY=" + JSON.stringify({"assertions":test.assertion_count,"failures":test.failures}))\n\tquit(0 if test.failures.is_empty() and test.assertion_count >= 18 else 1)\n')
	file.close()
	var absolute := ProjectSettings.globalize_path(path)
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", absolute, "--log-file", ProjectSettings.globalize_path("user://water-dialogue-delivery-child.log")], output, true)
	DirAccess.remove_absolute(absolute)
	var combined := "\n".join(output)
	assert_eq(code, 0, combined)
	assert_false(combined.contains("SCRIPT ERROR") or combined.contains("ERROR:"), combined)
	var result: Dictionary = {}
	for line: String in combined.split("\n"):
		if line.begins_with("WATER_DIALOGUE_DELIVERY="):
			result = JSON.parse_string(line.trim_prefix("WATER_DIALOGUE_DELIVERY="))
	assert_true(int(result.get("assertions", 0)) >= 18, "All conversation delivery paths must execute")
	assert_eq(result.get("failures", ["missing result"]), [])
