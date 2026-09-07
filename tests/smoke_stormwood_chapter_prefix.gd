extends SceneTree

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const TEST_SAVE_DIR := "user://stormwood_chapter_prefix_smoke_0907"
const FRAMES := 3600
var failures: Array[String] = []

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var game: Node = root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new(); game.name = "Game"; root.add_child(game)
	await physics_frame
	game.reset_for_new_game()
	game.save_system = SAVE_GAME.new(TEST_SAVE_DIR)
	_commit(game, "realm_key_stormwood")
	var source := Node3D.new(); root.add_child(source); current_scene = source
	_expect(await game.enter_realm("stormwood", "stormwood_arrival_from_cloudreach"), "router refused Stormwood arrival")
	var world := await _scene("Stormwood")
	_expect(world != null, "Stormwood did not mount")
	if world == null: _finish(); return
	var chapter: Node = null
	var people: Node = null
	for i in FRAMES:
		chapter = world.get_node_or_null(^"StormwoodChapter")
		people = world.get_node_or_null(^"StormwoodPeople")
		if chapter != null and people != null: break
		await physics_frame
	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var hesk := people.get_node_or_null(^"Rodkeeper Hesk") as Node3D if people != null else null
	_expect(chapter != null and hesk != null and player != null, "chapter, Hesk, or player missing")
	if chapter == null or hesk == null or player == null: _finish(); return
	# Test transport places the arrival at authored Ashfoot; progression remains
	# owned by the chapter's real proximity check and the NPC's interaction path.
	player.global_position = hesk.global_position + Vector3(0, 0, 1.2)
	for i in 90: await physics_frame
	_expect(game.progression.has("stormwood:chapter_started"), "Ashfoot arrival did not set chapter_started")
	var prompt := hesk.get_node_or_null(^"Interactable") as Node3D
	var arbiter := get_first_node_in_group(&"interaction_arbiter")
	_expect(prompt != null and arbiter != null, "Hesk has no live interaction prompt/arbiter")
	if prompt == null or arbiter == null: _finish(); return
	var won := false
	for i in 180:
		if arbiter.call("winning_provider") == prompt: won = true; break
		await physics_frame
	if not won:
		_print_interaction_diagnostic(arbiter, player, hesk, prompt)
	_expect(won, "Hesk prompt never won the live interaction arbiter")
	if won:
		await _press_interact()
	var panel := world.get_node_or_null(^"DialoguePanel")
	var opened := false
	for i in 90:
		if panel != null and panel.call("is_open"): opened = true; break
		await physics_frame
	_expect(opened, "Hesk prompt did not open dialogue")
	if opened:
		for i in 40:
			if not panel.call("is_open"): break
			await _press_interact()
	_expect(panel == null or not panel.call("is_open"), "Hesk dialogue did not finish through interact")
	for i in 30: await physics_frame
	_expect(game.progression.has("stormwood:crisis_learned"), "completed Hesk dialogue did not set crisis_learned")
	var hud := world.get_node_or_null(^"PlaygroundHUD")
	var objective_label := hud.get("_objective_text_label") as Label if hud != null else null
	_expect(objective_label != null, "PlaygroundHUD has no tracked objective label")
	if objective_label != null:
		_expect(objective_label.text == "Read a Break with Tamsin.",
			"PlaygroundHUD did not advance to Tamsin's Break objective (got '%s')" % objective_label.text)
	_finish()

func _commit(game: Node, id: String) -> void:
	game.ledger.submit({"kind":"set_world_flag", "realm":"cloudreach", "id":id, "value":true})

func _scene(name: String) -> Node:
	for i in FRAMES:
		if current_scene != null and current_scene.name == name: return current_scene
		await physics_frame
	return null

func _press_interact() -> void:
	Input.action_press(&"interact")
	await physics_frame
	await physics_frame
	Input.action_release(&"interact")
	await physics_frame

func _print_interaction_diagnostic(arbiter: Node, player: CharacterBody3D, hesk: Node3D, prompt: Node3D) -> void:
	var winner := arbiter.call("winning_provider") as Node
	print("STORMWOOD HESK DIAG player=%s hesk=%s prompt=%s winner=%s arbiter_enabled=%s input_owner=%s" % [
		player.global_position, hesk.global_position, prompt.global_position,
		_node_identity(winner), arbiter.get("_enabled"), _node_identity(get_first_node_in_group(&"input_owner"))])
	var direct_offer: Dictionary = prompt.call("interaction_offer", player.global_position)
	var los: Variant = prompt.call("_has_line_of_sight", player.global_position) if prompt.has_method("_has_line_of_sight") else "not_callable"
	print("STORMWOOD HESK DIAG enabled=%s actionable=%s radius=%s direct_offer=%s los=%s" % [
		prompt.get("enabled"), prompt.get("actionable"), prompt.get("radius"), direct_offer, los])
	var providers: Dictionary = arbiter.get("_provider_set") as Dictionary
	for provider: Variant in providers:
		var node := provider as Node3D
		if node == null or not is_instance_valid(node) or player.global_position.distance_to(node.global_position) > 6.0:
			continue
		var offer: Dictionary = provider.call("interaction_offer", player.global_position)
		print("STORMWOOD HESK DIAG nearby provider=%s distance=%.2f offer=%s" % [
			_node_identity(node), player.global_position.distance_to(node.global_position), offer])

func _node_identity(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return "<none>"
	return "%s (%s)" % [node.get_path(), node.name]

func _expect(ok: bool, text: String) -> void:
	if not ok: failures.append(text)

func _finish() -> void:
	if failures.is_empty(): print("STORMWOOD CHAPTER PREFIX OK: Ashfoot -> Hesk -> Tamsin objective"); quit(0)
	else:
		for failure in failures: push_error("STORMWOOD CHAPTER PREFIX: " + failure)
		quit(1)
