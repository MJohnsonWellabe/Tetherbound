extends SceneTree

## Production director + manager + real creature bodies in a high/stacked floor
## fixture. Only lethal damage is deterministic test code; production code owns
## round resolution, XP, callbacks, rewards and persistence. Never owner saves.
const DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const PARTY := preload("res://autoload/party.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const ARBITER := preload("res://scripts/world/interaction_arbiter.gd")
const PROMPT := preload("res://scripts/world/interactable.gd")
const PREVIEW := preload("res://scripts/combat/throw_preview.gd")

class FixtureWorld extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 400.0
	func ground_height_near(at: Vector3) -> float:
		return 100.0 if at.y < 250.0 else 400.0

class TrainerStandIn extends Node3D:
	func add_prompt(label: String, radius: float) -> Node3D:
		var prompt := PROMPT.new()
		prompt.position = Vector3.UP
		prompt.configure(label, radius)
		add_child(prompt)
		return prompt

class FixtureManager extends "res://scripts/combat/cloudreach_combat_manager.gd":
	func resolve_enemy_for_fixture() -> void:
		assert(state == State.ACTIVE)
		_enemy.take_damage(_enemy.hp + 1.0)
		_award_victory()
		_begin_resolve("won")

var failures: Array[String] = []
var victories: Array[String] = []
var starts: Array[String] = []
var catch_refusals: Array[String] = []
var _manager: FixtureManager
var _director: Node


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame


func _press(action: String, down: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = down
	Input.parse_input_event(event)


func _run() -> void:
	await process_frame
	var game := root.get_node("Game")
	game.set_process(false)
	game.progression = FLAGS.new()
	game.party = PARTY.new()
	game.inventory = INVENTORY.new(game.items)
	game.inventory.add("orb_basic", 5)
	game.progression.set_flag("cloudreach_chapter_started")
	var member: RefCounted = SPECIES.spawn("terrapup")
	member.set_level(25, preload("res://scripts/creatures/progression.gd").config())
	game.party.add(member)
	var world := FixtureWorld.new()
	world.name = "CloudreachEncounterFixture"
	root.add_child(world)
	current_scene = world
	var camera := Camera3D.new()
	camera.position = Vector3(6, 104, 8)
	world.add_child(camera)
	camera.look_at(Vector3(0, 101, -5))
	camera.current = true
	var preview := PREVIEW.new()
	world.add_child(preview)
	preview.update_arc(Vector3(0, 101.4, 0), Vector3(0, 0.2, -1), 18.0, null)
	_check(preview.get("_line_mesh").get_surface_count() > 0,
		"Lower-deck catch trajectory produces visible ribbon geometry below upper deck")
	_check(preview.get("_marker").global_position.y < 105.0,
		"Trajectory landing marker remains on the intended lower deck")
	preview.queue_free()
	for height: float in [100.0, 400.0]:
		var floor := StaticBody3D.new()
		floor.position.y = height - 0.5
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(160, 1, 160)
		collision.shape = box
		floor.add_child(collision)
		world.add_child(floor)
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 100, 0)
	world.add_child(player)
	var trainer := TrainerStandIn.new()
	trainer.position = Vector3(0, 100, -3)
	world.add_child(trainer)
	_manager = FixtureManager.new()
	_manager.name = "CombatManager"
	_manager.ground_world = world
	_manager.catch_refused.connect(func(reason: String) -> void: catch_refusals.append(reason))
	world.add_child(_manager)
	var arbiter := ARBITER.new()
	world.add_child(arbiter)
	arbiter.set_player(player)
	var data := DIRECTOR.read_json(DIRECTOR.CONFIG_PATH)
	data["trainers"] = [data["trainers"][0]]
	data["trainers"][0]["reuse_npc_id"] = "fixture"
	data["trainers"][0]["position"] = [0, 100, -3]
	data["wild_sites"] = []
	_director = DIRECTOR.new()
	_director.name = "EncounterDirector"
	_director.player_path = ^"../Player"
	_director.manager_path = ^"../CombatManager"
	_director.setup(world, {"fixture": trainer}, data)
	_director.trainer_started.connect(func(id: String) -> void: starts.append(id))
	_director.trainer_victory.connect(func(id: String) -> void: victories.append(id))
	world.add_child(_director)
	_director.set_arbiter(arbiter)
	await _frames(12)
	_check(await _director.summon_active_creature(), "Production party deployment succeeds")
	await _frames(6)
	_check(absf(_director.ally_body().global_position.y - 100.0) < 4.0, "Deployed creature uses lower intended stratum")
	var coins_before: int = game.inventory.count("coin")
	_press("interact", true)
	await _frames(3)
	_press("interact", false)
	await _frames(6)
	_check(_manager.is_fighting(), "Ordinary trainer prompt starts real-time production battle")
	_check(starts == ["trainer_ila_lower_ring"], "Start callback is exact and once")
	if not _manager.is_fighting():
		quit(1)
		return
	_check(_manager.get("_enemy_owned"), "Production battle marks trainer ownership")
	_manager.call("_try_throw")
	_check(not _manager.is_aiming(), "Production throw path refuses trained creature")
	_check(catch_refusals == ["You can't catch a trained creature"], "Ownership is the actual catch refusal reason")
	_check(player.global_position.y < 110 and _manager.enemy_body().global_position.y < 110,
		"Combat placement does not jump to upper stacked deck")
	var ally: Node3D = _director.ally_body()
	var before: Vector3 = ally.global_position
	_press("move_right", true)
	await _frames(20)
	_press("move_right", false)
	_check(ally.global_position.distance_to(before) > 0.5, "Real stick input pilots creature in active battle")
	var rounds := 0
	for frame in range(750):
		if _manager.state == _manager.State.ACTIVE:
			_manager.resolve_enemy_for_fixture()
			rounds += 1
		if not _director.trainer_battle_active():
			break
		await physics_frame
	_check(rounds == 2, "Both authored trainer creatures resolve through production rounds")
	_check(victories == ["trainer_ila_lower_ring"], "Final-round callback emitted exactly once")
	_check(game.progression.has("defeated_cloudreach_ila"), "Production canonical defeated flag recorded")
	_check(game.inventory.count("coin") == coins_before + 45, "Production reward tier paid once")
	_check(not _manager.last_xp_award.is_empty(), "Production XP award was executed")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(game.progression.save_data()))
	game.progression = FLAGS.new()
	game.progression.load_data(saved)
	_check(not _director.can_challenge(_director.trainer_specs["trainer_ila_lower_ring"]), "Reload refuses defeated trainer rematch")
	_director.call("_record_trainer_defeat", _director.trainer_specs["trainer_ila_lower_ring"])
	_check(game.inventory.count("coin") == coins_before + 45 and victories.size() == 1,
		"Repeated completion cannot duplicate payout/callback")
	await _frames(160)
	player.position = Vector3(25, 100, 25)
	var wild: Node3D = _director.spawn_wild("sparkit", Vector3(25, 100, 21), {"level": 19, "aggressive": false, "wander_radius": 1.0})
	_check(wild != null, "Production wild instantiation succeeds")
	_director.call("_start_fight", wild)
	_check(_manager.is_fighting() and not _manager.get("_enemy_owned"), "Wild starts same manager without trainer ownership")
	_manager.call("_try_throw")
	_check(_manager.is_aiming(), "Production catch aim accepts living wild creature")
	_check(game.party.size() == 1, "No party member or hidden slot created by encounter setup")
	_manager.call("_begin_resolve", "fled")
	await _frames(100)
	world.queue_free()
	await process_frame
	print("CLOUDREACH ENCOUNTERS %s: trainer input→real combat→test-only lethal resolution→production reward→reload; wild/trainer catch rules" % ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
