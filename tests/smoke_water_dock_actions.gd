extends SceneTree

## Production WaterDockActions prompts, ledger costs, physical barriers and
## sampled currents. Player poses and prerequisite trainer victories are
## explicit fixtures; this does not claim traversal or trainer-fight evidence.
## Real slot reloads rebuild dock equipment in the same production world.
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const SAVE := preload("res://scripts/save/save_game.gd")
const REED := "water_dock_reedhaven_repaired"
const SHELL := "water_dock_shellwatch_residents_freed_and_pump_disabled"
var game: Node
var world: Node3D
var player: CharacterBody3D
var docks: Node3D
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

func frames(count: int = 4) -> void:
	for frame in count:
		await physics_frame

func run() -> void:
	create_timer(180.0).timeout.connect(func() -> void:
		if not finished:
			check(false, "180 second watchdog expired")
			finish())
	game = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	game.local.character_id = "water-dock-fixture"
	game.save_system = SAVE.new("user://water_dock_actions_%d/" % Time.get_ticks_usec())
	world = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for frame in 600:
		await process_frame
		if world.shell_build_complete():
			break
	if not check(world.shell_build_complete(), "Production Water world built"):
		finish()
		return
	player = world.get_node("Player")
	# Pose fixtures must remain fixed while equipment, ledger and physics space
	# run. No replacement controller or analytic terrain is used.
	player.set_physics_process(false)
	docks = world.get_node("WaterDocks")
	await frames()
	var current_spot := current_probe("reedhaven_to_brine_steps")
	if not check(current_spot.is_finite(), "Reedhaven outbound current has an unambiguous sample"):
		finish()
		return
	var closed_speed: float = world.current_at(current_spot).length()
	check(is_equal_approx(closed_speed, 6.0), "Closed dock current pushes at configured 6m/s")
	var barrier: StaticBody3D = docks.get("_barriers").get(REED)
	if not check(barrier != null, "Reedhaven has a physical departure barrier"):
		finish()
		return
	var ray_from := barrier.global_position + Vector3.UP * 1.25 - barrier.global_basis.z * 2.0
	var ray_to := barrier.global_position + Vector3.UP * 1.25 + barrier.global_basis.z * 2.0
	check(ray_hits(ray_from, ray_to) == barrier, "Physics ray collides with closed departure gate")
	game.inventory.add("reed_fiber", 9)
	game.inventory.add("driftwood", 7)
	await activate("reedhaven_repair")
	check(not game.world.flags.has(REED), "Repair refuses before the swim lesson")
	check(game.inventory.count("reed_fiber") == 9 and game.inventory.count("driftwood") == 7,
		"Prerequisite refusal spends no materials")
	game.world.flags.set_flag("water_swim_lesson_complete")
	check(game.save_game(0), "Closed dock fixture saved through production SaveGame")
	game.inventory.remove("reed_fiber", 4)
	await activate("reedhaven_repair")
	check(not game.world.flags.has(REED) and game.inventory.count("reed_fiber") == 5 and game.inventory.count("driftwood") == 7,
		"Insufficient repair materials refuse without a partial charge")
	game.inventory.add("reed_fiber", 4)
	await activate("reedhaven_repair")
	check(game.world.flags.has(REED), "Real repair prompt commits its world flag")
	check(game.inventory.count("reed_fiber") == 3 and game.inventory.count("driftwood") == 3,
		"Real repair consumes exactly six reed fiber and four driftwood")
	check(not docks.get("_barriers").has(REED), "Repair removes departure barrier from the scene")
	check(ray_hits(ray_from, ray_to) == null, "Former gate span becomes physically clear")
	var open_speed: float = world.current_at(current_spot).length()
	check(open_speed > 0.0 and open_speed < closed_speed, "Repair weakens the actual outbound current")
	var repair_prompt: Node = docks.get("_prompts")[REED]
	check(not repair_prompt.enabled, "Completed repair disables its interaction prompt")
	# A queued activation cannot charge again, even after its prompt disabled.
	await activate("reedhaven_repair")
	check(game.inventory.count("reed_fiber") == 3 and game.inventory.count("driftwood") == 3,
		"Repeated queued repair activation charges nothing")
	check(game.save_game(1), "Open dock fixture saved")
	check(game.load_game(0), "Closed dock save reloads")
	await frames()
	check(not game.world.flags.has(REED) and docks.get("_barriers").has(REED),
		"Loading closed state rebuilds a previously removed barrier")
	check(ray_hits(ray_from, ray_to) != null and is_equal_approx(world.current_at(current_spot).length(), closed_speed),
		"Closed reload restores physical obstruction and strong current")
	check(game.inventory.count("reed_fiber") == 9 and game.inventory.count("driftwood") == 7,
		"Closed save restores its unspent material inventory")
	check(game.load_game(1), "Open dock save reloads")
	await frames()
	check(game.world.flags.has(REED) and not docks.get("_barriers").has(REED) and ray_hits(ray_from, ray_to) == null,
		"Open reload leaves the physical gate removed")
	check(is_equal_approx(world.current_at(current_spot).length(), open_speed), "Open reload retains weakened current")
	check(game.inventory.count("reed_fiber") == 3 and game.inventory.count("driftwood") == 3,
		"Open save preserves the exact charged inventory")
	await activate("shellwatch_release")
	await activate("shellwatch_pump")
	check(not game.world.flags.has("water_shellwatch_residents_freed") and not game.world.flags.has("water_shellwatch_pump_disabled"),
		"Shellwatch actions refuse before their respective trainer victories")
	game.world.flags.set_flag("defeated_water_trainer_solm")
	await activate("shellwatch_release")
	check(game.world.flags.has("water_shellwatch_residents_freed"), "Solm victory permits the real resident-release prompt")
	check(not game.world.flags.has(SHELL) and docks.get("_barriers").has(SHELL),
		"Freeing residents alone leaves Shellwatch departure closed")
	await activate("shellwatch_pump")
	check(not game.world.flags.has("water_shellwatch_pump_disabled"), "Solm victory does not substitute for Irva at the pump")
	game.world.flags.set_flag("defeated_water_trainer_irva")
	await frames()
	check(not game.world.flags.has(SHELL), "Both trainer victories alone do not perform the missing dock action")
	await activate("shellwatch_pump")
	check(game.world.flags.has("water_shellwatch_pump_disabled") and game.world.flags.has(SHELL),
		"Second physical objective completes the combined Shellwatch world gate")
	check(not docks.get("_barriers").has(SHELL), "Combined objective removes the Shellwatch barrier")
	finish()

func activate(id: String) -> void:
	var equipment: Node3D = docks.get_node(id)
	player.global_position = equipment.global_position + Vector3(2.0, 0.0, 0.0)
	player.velocity = Vector3.ZERO
	for child: Node in equipment.get_children():
		if child.has_method("interaction_activate"):
			child.call("interaction_activate")
			await frames()
			return
	check(false, "Production equipment has no interaction provider: " + id)

func current_probe(route: String) -> Vector3:
	for current: Dictionary in world.config.currents:
		if not str(current.route_id).begins_with(route + "_"):
			continue
		for i in range(1, current.polyline.size()):
			var at := (vector(current.polyline[i - 1]) + vector(current.polyline[i])) * 0.5
			var sampled: Dictionary = world.currents.sample(at)
			if str(sampled.id) == str(current.id) and is_equal_approx(float(sampled.influence), 1.0):
				return at
	return Vector3.INF

func vector(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))

func ray_hits(from: Vector3, to: Vector3) -> Object:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player.get_rid()]
	return world.get_world_3d().direct_space_state.intersect_ray(query).get("collider")

func finish() -> void:
	finished = true
	print("Water dock production smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
