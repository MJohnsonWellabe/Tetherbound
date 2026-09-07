extends SceneTree
## Real Terrain3D camps and production rest/craft services. Teleported proximity
## and inventory fixtures; no ordinary progression, journey or multiplayer claim.
var checks := 0
var failures: Array[String] = []
var world: Node3D
var player: CharacterBody3D
func _init() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures.append(label)
		print("FAIL: ", label)
	return ok
func frames(n: int = 4) -> void:
	for _i in n:
		await physics_frame
func run() -> void:
	await process_frame
	var game: Node = root.get_node("Game")
	game.current_realm = "water"
	world = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete():
		if Time.get_ticks_msec() > deadline:
			check(false, "Water shell timed out")
			finish()
			return
		await process_frame
	player = world.get_node("Player")
	player.set_physics_process(false)
	await frames()
	var service: Node = world.get_node("WaterCamps")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_camps.json"))
	check(service.camps.size() == 8, "All eight camps build in the real Water world")
	var indices: Dictionary = {}
	for row: Dictionary in data.camps:
		var id := str(row.id)
		if not check(service.camps.has(id), id + " has its rest service"):
			continue
		var camp: Node3D = service.camps[id]
		check(absf(camp.global_position.y - world.ground_height_at(camp.global_position.x, camp.global_position.z)) < 0.001,
			id + " rest uses baked terrain")
		for suffix: String in ["_shelter", "_bedroll", "_workbench", "_fire", "_creature_bed"]:
			var component: Node3D = service.get_node_or_null(NodePath(id + suffix))
			if not check(component != null and component.get_child_count() > 0, id + suffix + " has real built content"):
				continue
			var ground: float = world.ground_height_at(component.global_position.x, component.global_position.z)
			check(is_finite(ground) and ground >= 0.6, id + suffix + " is on dry baked terrain")
		var bed: Node = service.get_node(id + "_creature_bed")
		var index: int = bed.build_index()
		check(index == int(row.creature_bed_index) and index <= -41 and index >= -48 and not indices.has(index),
			id + " creature bed has its unique reserved index")
		indices[index] = true
		check(await find_offer(camp.get_node("Interactable")), id + " offers real rest from nearby ground")
		check(await find_offer(camp.get_node("CraftInteractable")), id + " offers real craft from nearby ground")
	check(not game.local.flags.has("creature_bed_built"), "Authored beds do not award player construction progress")
	var first: Node = service.camps.get("water_camp_first_shore")
	if first == null:
		finish()
		return
	var craft: Node3D = first.get_node("CraftInteractable")
	await find_offer(craft)
	game.local.flags.set_flag("water_chapter_started")
	game.inventory.add("driftwood", 2)
	var wood_before: int = game.inventory.count("wood")
	var drift_before: int = game.inventory.count("driftwood")
	craft.interaction_activate()
	await frames()
	var panel: Node = first.get("_craft_panel")
	if check(panel != null and panel.is_open(), "Camp workbench opens actual CraftPanel"):
		var ids: Array = panel.get("_recipe_ids")
		var at := ids.find("water_camp_boards")
		if check(at >= 0, "Arrival fixture exposes Water boards conversion"):
			var rows: Array = panel.get("_rows")
			rows[at].pressed.emit()
			await frames()
			check(game.inventory.count("driftwood") == drift_before - 2 and game.inventory.count("wood") == wood_before + 6,
				"Actual craft row consumes two driftwood and creates six wood")
		panel.close()
		panel.queue_free()
	await frames()
	var rest: Node3D = first.get_node("Interactable")
	await find_offer(rest)
	var day_before: int = game.day
	rest.interaction_activate()
	deadline = Time.get_ticks_msec() + 10000
	while game.day == day_before and Time.get_ticks_msec() < deadline:
		await process_frame
	check(game.day == day_before + 1, "Actual rest interaction passes exactly one day")
	check(game.local.flags.has("player_slept_at_home"), "Completed night records production rest progress")
	check(game.save_game(2), "Rested Water state saves through production SaveGame")
	game.day += 3
	check(game.load_game(2) and game.day == day_before + 1, "Production load restores the rested day")
	await create_timer(1.0).timeout
	finish()
func find_offer(prompt: Node3D) -> bool:
	for i in 8:
		var angle := TAU * float(i) / 8.0
		var at := prompt.global_position + Vector3(cos(angle), 0, sin(angle)) * 2.0
		at.y = world.ground_height_at(at.x, at.z) + 0.1
		player.global_position = at
		player.velocity = Vector3.ZERO
		await frames(1)
		if not prompt.interaction_offer(at).is_empty():
			return true
	return false
func finish() -> void:
	print("Water camp production smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
