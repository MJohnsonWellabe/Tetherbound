extends SceneTree

## F12#6 on the load/join seam. `player_pose` (position, aquatic safe anchor,
## swim-mount position) is part of the portable CHARACTER save, so a character
## who stood on Salt Crown in world A can load or join world B whose Salt
## Crown dock fact is missing. The real Water scene applies that pose through
## `game_state.apply_loaded_player_pose()` -> `swim_controller.restore_save_data`:
## the trainer must not be restored behind the closed race, a saved mount
## there must not be summoned, and the anchor must stay stored so it counts
## again once this world opens the dock.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SEALS := preload("res://scripts/world/water_gate_seals.gd")
var game: Node
var world: Node3D
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

func run() -> void:
	create_timer(180.0).timeout.connect(func() -> void:
		if not finished:
			check(false, "180 second watchdog expired")
			finish())
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "water-sealed-anchor-fixture"
	game.world.world_id = "water-sealed-anchor-world"
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 600:
		await process_frame
		if bool(world.call("shell_build_complete")):
			break
	if not check(bool(world.call("shell_build_complete")), "Water world finished building"):
		finish()
		return
	var player: CharacterBody3D = world.get_node("Player")
	var swimming: Node = player.get("swim_controller")
	var recovery: Node = world.get_node("PlayerDeath")
	var seals: Array[Dictionary] = SEALS.compile(world.config)
	var rules: Dictionary = SEALS.load_rules()
	var crown: Dictionary = {}
	for seal: Dictionary in seals:
		if str(seal.id) == "salt_crown":
			crown = seal
	var landing := Vector3.INF
	for anchor: Dictionary in world.config.anchors:
		if str(anchor.id) == "tidal_cradle_to_salt_crown_arrival":
			landing = Vector3(float(anchor.safe_position[0]), 0.0, float(anchor.safe_position[2]))
	landing.y = world.ground_height_at(landing.x, landing.z)
	if not check(not crown.is_empty() and landing.is_finite(), "Salt Crown seal and dry arrival anchor exist"):
		finish()
		return
	# World B holds every fact before Salt Crown's own.
	for flag: String in crown.required_flags.slice(0, -1):
		game.world.flags.set_flag(flag)
	check(SEALS.is_sealed(crown, game.world.flags), "Salt Crown is closed in this world")
	var pose := {"realm": "water", "position": [landing.x, landing.y + 1.0, landing.z],
		"model_yaw": 0.0, "camera_yaw": 0.0, "camera_pitch": 0.0,
		"aquatic": {"version": 1, "mode": 0, "health_fraction": 1.0, "stamina_fraction": 1.0,
			"safe_anchor": [landing.x, landing.y, landing.z],
			"mount": {"party_index": 0, "species_id": "fixture", "position": [landing.x + 2.0, landing.y, landing.z]}}}
	game.saved_player_pose = pose.duplicate(true)
	check(bool(game.apply_loaded_player_pose()), "Production pose apply ran")
	var at := player.global_position
	check(SEALS.closed_seal_at(seals, rules, at, game.world.flags).is_empty(),
		"Loaded trainer at %s is behind no closed seal" % at)
	check(Vector2(at.x, at.z).distance_to(crown.centre) >= SEALS.outer_radius(crown, rules),
		"Loaded trainer is off sealed Salt Crown and its race")
	check((swimming.get("_pending_mount") as Dictionary).is_empty(), "Saved mount behind the closed race is not summoned")
	check(swimming.state.has_safe_landing and Vector2(swimming.state.safe_landing.x, swimming.state.safe_landing.z).distance_to(Vector2(landing.x, landing.z)) < 0.01,
		"The portable anchor is kept, not erased")
	var fallback: Vector3 = recovery.recovery_position(game, at)
	check(SEALS.closed_seal_at(seals, rules, fallback, game.world.flags).is_empty(), "Death recovery ignores the sealed anchor")
	# Positive control: once this world clears the Salt Crown dock, the same
	# character pose restores in place and the anchor counts again.
	game.world.flags.set_flag(str(crown.required_flags[-1]))
	check(not SEALS.is_sealed(crown, game.world.flags), "Salt Crown opened")
	game.saved_player_pose = pose.duplicate(true)
	check(bool(game.apply_loaded_player_pose()), "Production pose apply ran again")
	check(player.global_position.distance_to(Vector3(landing.x, landing.y + 1.0, landing.z)) < 0.01,
		"Open Salt Crown pose restores in place: %s" % player.global_position)
	check(not (swimming.get("_pending_mount") as Dictionary).is_empty(), "Open Salt Crown mount is queued for restore")
	check(recovery.recovery_position(game, Vector3.ZERO).distance_to(landing + Vector3.UP) < 0.01,
		"Open Salt Crown anchor determines recovery again")
	await process_frame
	await process_frame
	finish()

func finish() -> void:
	finished = true
	print("Water sealed-anchor reload smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
