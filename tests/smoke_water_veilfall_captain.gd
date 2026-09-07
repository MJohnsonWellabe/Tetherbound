extends SceneTree

## Isolated boss proof. Explicit preparation: legal five-member level-55 party,
## upstream pump flags and initial interior proximity. No enemy HP, damage,
## captain victory or Guardian release injection.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var checks := 0
var failures := 0

func _init() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ", label)
	return ok

func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.current_realm = "water"
	game.local.character_id = "captain-smoke"
	game.world.world_id = "captain-smoke-world"
	game.save_system = SAVE.new("user://water_captain_smoke_%d/" % Time.get_ticks_usec())
	for id: String in ["water_mosshell", "water_aquaryn", "water_cannonback", "water_riverdrake", "water_sirenseal"]:
		var creature := SPECIES.spawn(id)
		creature.set_level(55, preload("res://scripts/creatures/progression.gd").config())
		game.local.party.add(creature)
	for flag: String in ["water_veilfall_intake_stopped", "water_veilfall_return_opened"]:
		game.world.flags.set_flag(flag)
	var world: Node3D = load("res://scenes/world/water_archipelago.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	var deadline := Time.get_ticks_msec() + 90000
	while not world.shell_build_complete() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not check(world.shell_build_complete(), "Actual Water world builds for isolated captain encounter"):
		_finish()
		return
	var cave: Node3D = world.get_node("WaterVeilfall")
	var director: Node = world.get_node("EncounterDirector")
	var manager: Node = world.get_node("CombatManager")
	var player: Node3D = world.local_rig()
	var id := "water_trainer_nerissa"
	deadline = Time.get_ticks_msec() + 10000
	while not director.trainer_nodes.has(id) and Time.get_ticks_msec() < deadline:
		await process_frame
	var captain: Node3D = director.trainer_nodes.get(id)
	if not check(captain != null and captain.get_parent() == cave.interior, "Installed Nerissa body resides in actual Heart Chamber"):
		_finish()
		return
	var spec: Dictionary = director.trainer_specs[id]
	print("Nerissa authored team: ", spec.get("team", []))
	check(spec.get("team", []).size() == 4, "Captain retains authored four-creature team")
	check(str(spec.defeat_flag) == "water_captain_nerissa_defeated", "Captain battle routes exact finale victory flag")
	check(not game.world.flags.has("water_captain_nerissa_defeated") and not game.world.flags.has("water_guardian_freed"), "No fixture seeds victory or release")
	player.global_position = captain.global_position + Vector3(0, 0.1, -2.7)
	player.velocity = Vector3.ZERO
	await _frames(12)
	if not check(await director.summon_active_creature(), "Production summon deploys prepared owned Mosshell"):
		_finish()
		return
	await _frames(12)
	var prompt: Node3D = director.trainer_prompts[id]
	if not check(not prompt.interaction_offer(player.global_position).is_empty(), "Actual nearby captain challenge prompt is available"):
		print("Prompt at ", prompt.global_position, " player ", player.global_position, " spec ", spec)
		_finish()
		return
	prompt.interaction_activate()
	await _frames(3)
	if not check(director.trainer_battle_id() == id and manager.is_fighting(), "Production challenge starts Captain Nerissa fight"):
		_finish()
		return
	var opponents: Dictionary = {}
	var tick := 0
	deadline = Time.get_ticks_msec() + 180000
	while director.trainer_battle_active() and Time.get_ticks_msec() < deadline:
		var enemy: Node3D = manager.enemy_body()
		var ally: Node3D = director.ally_body()
		if is_instance_valid(enemy) and is_instance_valid(ally) and manager.is_fighting():
			var uid := enemy.get_instance_id()
			if not opponents.has(uid):
				opponents[uid] = str(enemy.instance.species_id)
				check(enemy.trainer_owned and enemy.instance.level == 55, "Production opponent %d is trainer-owned level55" % opponents.size())
				print("Captain opponent ", opponents.size(), ": ", enemy.instance.species_id, " HP ", enemy.instance.hp)
			ally.face_towards(enemy.global_position)
			var offset: Vector3 = enemy.global_position - ally.global_position
			offset.y = 0
			_release_movement()
			if offset.length() > 2.3:
				var direction: Vector3 = world.get_node("CameraRig").planar_basis().inverse() * offset.normalized()
				if direction.x < 0: Input.action_press("move_left", -direction.x)
				else: Input.action_press("move_right", direction.x)
				if direction.z < 0: Input.action_press("move_forward", -direction.z)
				else: Input.action_press("move_back", direction.z)
			if tick % 24 == 0: Input.action_press("combat_quick")
			elif tick % 24 == 2: Input.action_release("combat_quick")
		else:
			_release_movement()
			Input.action_release("combat_quick")
		tick += 1
		await physics_frame
	_release_movement()
	Input.action_release("combat_quick")
	check(opponents.size() == 4, "Normal combat reaches every authored captain opponent")
	if not check(game.world.flags.has("water_captain_nerissa_defeated"), "Actual final-round victory awards captain progression"):
		print("Captain stopped: active=", director.trainer_battle_active(), " seen=", opponents, " party=", SAVE.new()._party_to_array(game.local.party))
		_finish()
		return
	await _frames(6)
	var dialogue: Node = world.get_node("DialoguePanel")
	for step in 20:
		if not dialogue.is_open(): break
		dialogue.advance()
		await _frames(2)
	# Explicit local proximity fixture isolates the post-boss control seam;
	# walking the physical cave is proven by smoke_water_veilfall_runtime.
	var tether: Node3D = cave.get("_controls").guardian_tether
	player.global_position = tether.global_position + Vector3(0, -1.4, -2)
	player.velocity = Vector3.ZERO
	await _frames(6)
	if check(not tether.interaction_offer(player.global_position).is_empty(), "Guardian tether offers actual nearby post-victory interaction"):
		tether.interaction_activate()
		await _frames(4)
		check(game.world.flags.has("water_guardian_freed"), "Actual tether now frees Guardian after earned captain victory")
	_finish()

func _release_movement() -> void:
	for action: String in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)

func _frames(count: int) -> void:
	for frame in count: await physics_frame

func _finish() -> void:
	_release_movement()
	Input.action_release("combat_quick")
	print("Water Veilfall captain smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
