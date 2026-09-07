extends SceneTree
## Actual installed bodies + production DialoguePanel, with teleported proximity
## fixtures. No NPC accessibility, visual quality or chapter completion claim.
const NPCS := preload("res://scripts/world/water_scene_npcs.gd")
var failures: Array[String] = []
var checks := 0
var events: Array = []
func _init() -> void:
	call_deferred("run")
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures.append(why)
		print("FAIL: ", why)
func frames(count: int = 3) -> void:
	for _frame in count:
		await process_frame
func run() -> void:
	var world: Node3D = (load("res://scenes/world/water_archipelago.tscn") as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	var game: Node = root.get_node("Game")
	game.set("current_realm", "water")
	var deadline := Time.get_ticks_msec() + 60000
	while not world.call("shell_build_complete"):
		if Time.get_ticks_msec() > deadline:
			check(false, "Water shell build timeout")
			quit(1)
			return
		await process_frame
	var player: CharacterBody3D = world.get_node("Player")
	player.set_physics_process(false)
	var service := NPCS.new()
	service.guarded_event_requested.connect(func(event_id: String, npc_id: String, peer_id: int) -> void:
		events.append([event_id, npc_id, peer_id]))
	var bodies: Dictionary = service.build(world)
	check(bodies.size() == 18, "All18 installed NPC bodies build")
	check(service.build(world).size() == 18 and service.get_child_count() == 18, "Repeated build does not duplicate bodies")
	for id: String in bodies:
		var npc: Node3D = bodies[id]
		check(npc.get_node_or_null("Body") != null and npc.call("prompt_node") != null, id + " has production collision and prompt")
		check(absf(npc.global_position.y - world.call("ground_height_at", npc.global_position.x, npc.global_position.z)) < 0.001, id + " is grounded by world")
	if not bodies.has("water_mara") or not bodies.has("water_iona") or not bodies.has("water_pell"):
		check(false, "Required speaking fixtures missing")
		quit(1)
		return
	var panel: Node = world.get_node("DialoguePanel")
	var world_before: Dictionary = game.get("world").flags.save_data()
	var personal_before: Dictionary = game.get("local").flags.save_data()
	player.global_position = bodies.water_mara.global_position + Vector3(1, 0, 0)
	bodies.water_mara.call("prompt_node").activated.emit()
	await frames()
	check(panel.call("is_open"), "Actual Mara prompt opens production panel")
	check(panel.call("current_speaker") == "Dockkeeper Mara", "Panel shows authored speaker")
	check(panel.call("current_portrait") == "res://assets/ui/portraits/corin.png", "Panel uses installed speaker portrait")
	while panel.call("is_open"):
		panel.call("advance")
		await frames()
	check(events.is_empty(), "Mara speech emits no gameplay completion")
	player.global_position = bodies.water_iona.global_position + Vector3(1, 0, 0)
	check(not service.start_conversation("water_iona", "water_iona_recipe"), "Recipe speech refuses without personal Swim Stone")
	player.global_position = bodies.water_pell.global_position + Vector3(1, 0, 0)
	check(service.start_conversation("water_pell"), "Pell starts authored briefing")
	panel.call("close")
	await frames()
	check(events.is_empty(), "Closing briefing before last line emits nothing")
	check(service.start_conversation("water_pell"), "Pell briefing can reopen")
	panel.call("advance")
	await frames()
	check(panel.call("drain_effects").is_empty(), "Generic effect drain cannot turn Water speech into flags")
	panel.call("advance")
	await frames()
	check(events.size() == 1 and events[0][0] == "water:water_swim_lesson_briefed" and events[0][1] == "water_pell", "Complete briefing emits one guarded request")
	check(game.get("world").flags.save_data() == world_before, "Dialogue leaves world flags unchanged")
	check(game.get("local").flags.save_data() == personal_before, "Dialogue leaves personal flags unchanged")
	# Explicit personal-unlock fixture: speech may request teaching, never award it.
	game.get("local").flags.set_flag("water_swim_stone_earned")
	var unlocked_flags: Dictionary = game.get("local").flags.save_data()
	var inventory_before: Dictionary = game.get("local").save_data()
	player.global_position = bodies.water_iona.global_position + Vector3(1, 0, 0)
	check(service.start_conversation("water_iona"), "Personal Swim Stone permits Iona teaching conversation")
	while panel.call("is_open"):
		await frames()
		panel.call("advance")
	check(events.size() == 2 and events[1][0] == "water:water_swim_saddle_recipe_taught", "Iona emits guarded teaching request")
	check(game.get("local").flags.save_data() == unlocked_flags, "Teaching request itself grants no recipe flag")
	check(game.get("local").save_data().inventory == inventory_before.inventory, "Teaching request grants no inventory items")
	player.global_position += Vector3(100, 0, 0)
	check(not service.start_conversation("water_pell"), "Remote call cannot talk from across the island")
	print("Water NPC smoke: ", checks, " checks, ", failures.size(), " failures")
	world.queue_free()
	await frames()
	quit(0 if failures.is_empty() else 1)

