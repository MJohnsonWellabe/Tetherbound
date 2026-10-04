extends SceneTree

## Queue-only F37 proof. Explicit party/L30/deep-water fixtures; real controller
## taps, buoyancy, serialization and host claims. Not an earned campaign run,
## real device, visual judgment or two-peer rejoin proof.
const SCENE := preload("res://scenes/world/water_archipelago.tscn")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
var world: Node3D
var game: Node
var failures: Array[String] = []
var finished := false

func _init() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	print("F37 ", "PASS " if value else "FAIL ", message)
	if not value: failures.append(message)

func frames(count: int) -> void:
	for frame in count: await physics_frame

func tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await frames(3)

func run() -> void:
	create_timer(240).timeout.connect(func() -> void:
		if not finished:
			check(false,"watchdog")
			finish())
	await process_frame
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "f37-ripplet-fixture"
	game.world.world_id = "f37-ripplet-world"
	game.save_system = SAVE.new("user://f37_ripplet_%d" % Time.get_ticks_usec())
	var creature := SPECIES.spawn("ripplet")
	creature.level = 30
	creature.recompute_stats_from_base(preload("res://scripts/creatures/progression.gd").config())
	game.party.add(creature)
	game.local.save_data()
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	while not world.shell_build_complete(): await process_frame
	var player: CharacterBody3D = world.get_node("Player")
	var camera: Node = world.get_node("CameraRig")
	var director: Node = world.get_node("EncounterDirector")
	var riding: Node = world.get_node("RidingController")
	var swimming: Node = player.swim_controller
	check(game.inventory.count("swim_saddle") == 0 and not game.local.flags.has("water_swim_stone_earned"),"opening has no saddle/Stone")
	check(director.summon_active_creature(),"summon owned Ripplet")
	await frames(30)
	# Fixture seats the trainer within the normal mount prompt's reach.
	var body: CharacterBody3D = director.ally_body()
	player.global_position = body.global_position + Vector3(2,0,0)
	await frames(2)
	riding.interaction_activate()
	await frames(10)
	check(riding.is_mounted(),"ordinary Interact mounts with host authorization")
	if not riding.is_mounted():
		finish()
		return
	body.global_position = Vector3(-215,-0.7,166)
	body.velocity = Vector3.ZERO
	await frames(10)
	check(world.water_depth_at(body.global_position) >= 8.0,"optional dive fixture has clearance")
	check(riding.ride_speed_now() > 3.8,"surface speed exceeds human")
	var before := body.global_position
	camera.set("yaw",0.0)
	Input.action_press("move_forward")
	await frames(120)
	Input.action_release("move_forward")
	check(body.global_position.distance_to(before) > 8.0,"ordinary input drives surface displacement")
	await tap("jump")
	check(not riding.diving,"level without L30 feast cannot Dive")
	# Explicit admitted breakthrough fixture. Real feast proof is F28 dependency.
	game.local.redesign_character.creatures[creature.uid].breakthroughs = [10,20,30]
	game.local.redesign_character.creatures[creature.uid].cap_level = 40
	await tap("jump")
	await frames(30)
	check(riding.diving,"tap Jump starts unlocked Dive")
	check(body.global_position.y < -4.5,"production buoyancy submerges carrier")
	var aquatic: Dictionary = swimming.save_data()
	check(aquatic.mount.creature_uid == creature.uid,"save binds stable UID")
	check(aquatic.mount.dive.remaining_s < 20.0,"save captures spent dive timer")
	var clean: Dictionary = preload("res://scripts/save/water_traversal_save.gd").sanitise(JSON.parse_string(JSON.stringify(aquatic)))
	check(clean.mount.dive.remaining_s == aquatic.mount.dive.remaining_s,"JSON preserves remaining dive debt")
	await tap("jump")
	await frames(30)
	check(not riding.diving and body.global_position.y > -1.0,"tap surfaces without held input")
	check(is_equal_approx(creature.swim_stamina_fraction,float(world.get_node("MountedSwimming").state.stamina_fraction)),"stamina remains on owned creature")
	finish()

func finish() -> void:
	if finished: return
	finished = true
	Input.action_release("move_forward")
	print("F37 RIPPLET FIXTURE ","PASS" if failures.is_empty() else "FAIL", " ",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
