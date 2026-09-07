extends SceneTree

## Actual Water scene and disk character save, destroyed then rebuilt. The
## owned Aquaryn, Stone, saddle, deep-water placement and resources are fixtures;
## mounting, serialization, reconstruction and resumed input are production.
## This is a scene/disk continuation smoke, not an ENet reconnect claim.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CHARACTER_ID := "water-mounted-reconnect-fixture"
var game: Node
var world: Node3D
var player: CharacterBody3D
var swimming: Node
var riding: Node
var director: Node
var checks := 0
var failures: Array[String] = []
var finished := false

func _init() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failures.append(message)
		print("FAIL: ", message)
	return ok

func frames(count: int) -> void:
	for frame in count:
		await physics_frame

func boot() -> bool:
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 1200:
		await process_frame
		if bool(world.call("shell_build_complete")):
			player = world.get_node("Player")
			swimming = player.get("swim_controller")
			riding = world.get_node("RidingController")
			director = world.get_node("EncounterDirector")
			return check(swimming != null, "Water mounted production SwimController")
	return check(false, "Water world failed to finish building")

func rebuild(disk: Dictionary) -> bool:
	paused = true
	var previous: WeakRef = weakref(world)
	current_scene = null
	world.queue_free()
	await process_frame
	await process_frame
	check(previous.get_ref() == null, "Previous Water scene was actually destroyed")
	game.local.reset()
	game.local.load_data(disk)
	if not await boot():
		return false
	# Deferred reconstruction can yield while loading its installed mesh. Keep
	# human physics frozen until it has either attached or safely refused.
	for frame in 300:
		await process_frame
		if frame >= 3 and swimming.get("_pending_mount").is_empty():
			return true
	return check(false, "Mounted restoration failed to leave its pending state")

func run() -> void:
	create_timer(300.0).timeout.connect(func() -> void:
		if not finished:
			check(false, "300 second watchdog expired")
			finish())
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = CHARACTER_ID
	game.world.world_id = "water-mounted-reconnect-world"
	game.save_system = SAVE.new("user://water_mounted_reconnect_%d/" % Time.get_ticks_usec())
	game.local.flags.set_flag("water_swim_stone_earned", true)
	game.local.inventory.add("swim_saddle", 1)
	check(game.local.party.add(SPECIES.spawn("water_aquaryn")), "Owned Aquaryn fixture enters the real party")
	check(game.local.party.add(SPECIES.spawn("water_mosshell")), "Second owned species pins saved party ordering")
	if not await boot():
		finish()
		return
	var lesson: Dictionary = world.config.swim_lesson
	var anchor := Vector3.INF
	for row: Dictionary in world.config.anchors:
		if str(row.id) == str(lesson.start_anchor):
			anchor = vector(row.safe_position)
	anchor.y = world.ground_height_at(anchor.x, anchor.z)
	player.global_position = anchor + Vector3.UP * 0.15
	player.velocity = Vector3.ZERO
	await frames(45)
	if not check(player.is_on_floor() and swimming.state.has_safe_landing, "Actual dry landing earns the recovery anchor"):
		finish()
		return
	var earned_anchor: Vector3 = swimming.state.safe_landing
	if not check(director.summon_active_creature(), "Production summon deploys owned Aquaryn"):
		finish()
		return
	await frames(30)
	if not check(riding.mount(), "Production riding mounts Aquaryn from dry land"):
		finish()
		return
	var body: CharacterBody3D = riding.mount_body()
	var deep := vector(lesson.surface_polyline[0]).lerp(vector(lesson.surface_polyline[-1]), 0.5)
	deep += Vector3(deep.x, 0, deep.z).normalized() * 15.0
	deep.y = -0.65
	if not check(world.water_depth_at(deep) > 3.0, "Explicit saved-pose fixture is deep water"):
		finish()
		return
	body.global_position = deep
	body.velocity = Vector3.ZERO
	await frames(15)
	if not check(riding.is_mounted() and int(swimming.state.mode) == 2, "Production mounted state follows the deep-water fixture"):
		finish()
		return
	var creature: RefCounted = director.ally_instance()
	creature.swim_stamina_fraction = 0.37
	creature.energy = 20.0
	player.vitals.stamina = 0.0
	player.vitals.health = player.vitals.max_health * 0.8
	paused = true
	var saved_health: float = player.vitals.health
	var saved_body_position := body.global_position
	swimming.state.owner_peer_id = 777
	swimming.state.revision = 90000
	game.call("_capture_player_pose")
	if not check(game.save_system.save_character(game, CHARACTER_ID), "Production character serializer wrote the mounted disk save"):
		finish()
		return
	var disk: Dictionary = game.save_system.characters().read(CHARACTER_ID)
	var aquatic: Dictionary = disk.get("player_pose", {}).get("aquatic", {})
	if not check(aquatic.get("mount") is Dictionary, "Disk payload explicitly names the mounted party member"):
		finish()
		return
	check(str(aquatic.mount.species_id) == "water_aquaryn" and int(aquatic.mount.party_index) == 0,
		"Disk mount identity is Aquaryn at its original party index")
	check(disk.party.size() == 2, "Disk contains exactly the two owned creatures")
	if not await rebuild(disk):
		finish()
		return
	check(game.local.character_id == CHARACTER_ID, "Rebuilt world restores the same character identity")
	check(game.local.party.members().size() == 2 and game.local.party.at(0).species_id == "water_aquaryn"
		and game.local.party.at(1).species_id == "water_mosshell", "Restoration preserves owned party ordering without creating another creature")
	if not check(riding.is_mounted() and player.is_carried(), "Fresh scene reconstructs a real mounted carrier"):
		finish()
		return
	body = riding.mount_body()
	creature = director.ally_instance()
	check(creature == game.local.party.at(0) and body.species_id == creature.species_id,
		"Rebuilt director uses the deserialized party object and carrier matches its species")
	check(body.global_position.distance_to(saved_body_position) < 0.15,
		"Mount resumes its surface position instead of the seabed or entry shore")
	check(player.carrier() == body, "Trainer carrier is the reconstructed mount body")
	check(is_equal_approx(creature.swim_stamina_fraction, 0.37), "Disk restoration preserves mount stamina without refill")
	check(is_equal_approx(creature.energy, 20.0), "Disk restoration preserves positive combat energy")
	check(is_zero_approx(player.vitals.stamina) and is_equal_approx(player.vitals.health, saved_health),
		"Disk restoration preserves exhausted human stamina and existing health")
	check(int(swimming.state.mode) == 2 and not swimming.snapshot().drowning,
		"Healthy mount immediately prevents exhausted rider from drowning")
	check(swimming.state.owner_peer_id == root.multiplayer.get_unique_id()
		and swimming.state.revision > 0 and swimming.state.revision < 90000,
		"Reconstructed state has current authority and fresh replication history")
	check(swimming.state.has_safe_landing and swimming.state.safe_landing.distance_to(earned_anchor) < 0.15,
		"Reconstruction preserves the earned dry recovery anchor")
	paused = false
	await frames(3)
	check(player.global_position.distance_to(body.to_global(player.carry_offset())) < 0.2,
		"Resumed physics places the rider at the mount's real seat")
	var before := body.global_position
	world.get_node("CameraRig").yaw = 0.0
	action(true)
	await frames(60)
	action(false)
	check(body.global_position.distance_to(before) > 2.0, "Real directional input resumes mounted movement after disk reconstruction")
	check(creature.swim_stamina_fraction < 0.37 and creature.swim_stamina_fraction > 0.30,
		"Resumed mounted movement spends the saved swim resource")
	check(is_equal_approx(player.vitals.health, saved_health) and is_zero_approx(player.vitals.stamina),
		"Exhausted rider neither drowns nor receives a stamina refill on the healthy mount")
	check(is_equal_approx(creature.energy, 20.0), "Mounted continuation does not spend positive combat energy")
	for invalid in ["wrong_species", "missing_stone"]:
		# Negative cases use the saved continuation payload on the live rebuilt
		# controller. They test refusal, not additional whole-world rebuilding.
		paused = true
		riding.dismount()
		var corrupt: Dictionary = disk.player_pose.aquatic.duplicate(true)
		game.local.flags.set_flag("water_swim_stone_earned", true)
		if invalid == "wrong_species":
			corrupt.mount.species_id = "water_mosshell"
		else:
			game.local.flags.set_flag("water_swim_stone_earned", false)
		player.global_position = deep
		check(swimming.restore_save_data(corrupt), invalid + " saved continuation reaches the production restore seam")
		for frame in 10:
			await process_frame
		check(not riding.is_mounted() and not player.is_carried(), invalid + " refuses the reconstructed mount")
		check(game.local.party.members().size() == 2, invalid + " refusal creates no extra owned creature")
		check(int(swimming.state.mode) == 1 and swimming.snapshot().drowning,
			invalid + " returns to honest exhausted human swimming")
		check(is_equal_approx(player.vitals.health, saved_health), invalid + " refusal does not heal the character")
		paused = false
		await frames(12)
		check(player.vitals.health < saved_health and player.vitals.health > 0.0,
			invalid + " resumes gradual drowning without an instant death")
	finish()

func vector(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))

func action(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = "move_forward"
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)

func finish() -> void:
	finished = true
	action(false)
	paused = false
	print("Water mounted disk reconstruction smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
