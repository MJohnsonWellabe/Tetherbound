extends SceneTree

## Real Water scene, character disk save, then a destroyed/rebuilt world.
## This proves fresh-world continuation, not an ENet reconnect or peer migration.
## Starting position, exhaustion and an obsolete replication owner are fixtures;
## entering water and earning the safe landing use the production controller.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const CHARACTER_ID := "water-reconnect-save-fixture"
var game: Node
var world: Node3D
var player: CharacterBody3D
var swimming: Node
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
	for frame in 600:
		await process_frame
		if bool(world.call("shell_build_complete")):
			player = world.get_node("Player")
			swimming = player.get("swim_controller")
			return check(swimming != null, "Fresh Water world mounted production SwimController")
	return check(false, "Water world did not finish building")

func run() -> void:
	create_timer(180.0).timeout.connect(func() -> void:
		if not finished:
			check(false, "180 second watchdog expired")
			finish())
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = CHARACTER_ID
	game.world.world_id = "water-reconnect-save-world"
	game.save_system = SAVE.new("user://water_reconnect_save_%d/" % Time.get_ticks_usec())
	if not await boot():
		finish()
		return
	var lesson: Dictionary = world.config.swim_lesson
	var west := Vector3.INF
	for anchor: Dictionary in world.config.anchors:
		if str(anchor.id) == str(lesson.start_anchor):
			west = vector(anchor.safe_position)
	if not check(west.is_finite(), "Lesson's dry start anchor exists"):
		finish()
		return
	west.y = world.ground_height_at(west.x, west.z)
	player.global_position = west + Vector3.UP * 0.15
	player.velocity = Vector3.ZERO
	await frames(45)
	if not check(player.is_on_floor() and swimming.state.has_safe_landing,
			"Production capsule earned its dry recovery anchor"):
		finish()
		return
	var earned_anchor: Vector3 = swimming.state.safe_landing
	var target := vector(lesson.surface_polyline[0])
	var camera: Node = world.get_node("CameraRig")
	for frame in 900:
		var offset := target - player.global_position
		offset.y = 0.0
		if offset.length() <= 0.4:
			break
		camera.set("yaw", atan2(-offset.x, -offset.z))
		action(true)
		await physics_frame
	action(false)
	await frames(3)
	if not check(swimming.is_swimming(), "Real input walked the trainer into deep water"):
		finish()
		return
	var vitals: RefCounted = player.get("vitals")
	vitals.stamina = 0.0
	vitals.health = vitals.max_health * 0.8
	await frames(30)
	check(swimming.snapshot().drowning, "Exhausted swimmer is drowning before save")
	# Freeze simulation at the capture boundary without changing HUMAN mode.
	paused = true
	var saved_health: float = vitals.health
	var saved_position := player.global_position
	# Replication metadata must be newly owned after scene reconstruction, not
	# serialized as authority or an old revision inside the portable character.
	swimming.state.owner_peer_id = 777
	swimming.state.revision = 90000
	game.call("_capture_player_pose")
	if not check(game.save_system.save_character(game, CHARACTER_ID), "Production SaveGame wrote the exhausted character"):
		finish()
		return
	var disk: Dictionary = game.save_system.characters().read(CHARACTER_ID)
	if not check(disk.get("player_pose", {}).get("aquatic") is Dictionary,
			"Character file contains the aquatic continuation payload"):
		finish()
		return
	check(str(disk.character_id) == CHARACTER_ID and str(disk.realm) == "water",
		"Character disk record preserves identity and Water realm")
	check(is_zero_approx(float(disk.player_pose.aquatic.stamina_fraction)),
		"Character disk record preserves exhaustion")
	var old_world: WeakRef = weakref(world)
	current_scene = null
	world.queue_free()
	await process_frame
	await process_frame
	check(old_world.get_ref() == null, "Previous Water world was actually destroyed")
	game.local.reset()
	game.local.load_data(disk)
	if not await boot():
		finish()
		return
	vitals = player.get("vitals")
	check(game.local.character_id == CHARACTER_ID, "Fresh world resumes the same saved character")
	check(player.global_position.distance_to(saved_position) < 0.15,
		"Fresh world restores the midwater pose instead of its entry spawn")
	check(is_zero_approx(float(vitals.stamina)), "Fresh world does not refill exhausted stamina")
	check(is_equal_approx(float(vitals.health), saved_health), "Fresh world does not refill saved health")
	check(swimming.state.owner_peer_id == root.multiplayer.get_unique_id(),
		"Fresh SwimState belongs to the current process, not the saved fixture owner")
	check(swimming.state.revision > 0 and swimming.state.revision < 90000,
		"Fresh SwimState starts a new replication revision history")
	check(swimming.state.has_safe_landing and swimming.state.safe_landing.distance_to(earned_anchor) < 0.15,
		"Fresh world restores the earned dry recovery anchor")
	check(swimming.is_swimming() and swimming.snapshot().drowning,
		"Fresh controller resumes exhausted human swimming immediately")
	paused = false
	await frames(30)
	check(float(vitals.health) > 0.0 and float(vitals.health) < saved_health,
		"Production physics resumes gradual drowning after reload")
	check(is_zero_approx(float(vitals.stamina)), "Deep-water continuation grants no idle stamina")
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
	print("Water fresh-world character save smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
