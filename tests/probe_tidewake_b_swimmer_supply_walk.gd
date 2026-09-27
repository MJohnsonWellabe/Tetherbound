extends SceneTree

## DRY RUN probe (does not count): reproduces the four-biome DRY RUN 5 saddle
## supply stall without replaying the campaign. The production Water world is
## loaded with declared fixture flags; the trainer is POSED (probe-only position
## write) where the SWIMMER preparation leaves it after harvest:014, then the
## SWIMMER segment's own walk to harvest:004 residency is run, first as the
## unplanned straight residency walk (the DRY RUN 5 path), then with the
## segment's planned approach.
## --swimmer: DRY RUN 6 stall instead - posed where the supply walk ended,
## ~10 m below the chosen mosshell's ledge; walks the planned legs to its spot.
##   godot --headless --path . --script tests/probe_tidewake_b_swimmer_supply_walk.gd [-- --planned-only|--swimmer]
const WORLD := preload("res://scenes/world/water_archipelago.tscn")
const HARVEST := preload("res://tests/helpers/water_reedhaven_segment.gd")
const PREP := preload("res://tests/helpers/water_earned_swimmer_preparation_segment.gd")
const POCKET := preload("res://tests/smoke_water_pocket_walk_claim.gd")
const TARGET_ID := "water:tidal_cradle:harvest:004"
## After harvest:014's interaction stance (DRY RUN 5) and the Tidal end pose.
const STARTS := [Vector3(803.0, 0.0, 1647.0), Vector3(713.58, 0.0, 1549.52)]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	print("DRY RUN probe - does not count: posed trainer, declared fixture flags")
	var game: Node = root.get_node("Game")
	game.reset_for_new_game()
	game.current_realm = "water"
	for flag: String in ["water_swim_lesson_complete", "water_dock_reedhaven_repaired",
			"water_dock_brine_steps_trial_won", "water_aquaryn_resolved",
			"water_dock_salt_crown_landing_charted",
			"water_dock_shellwatch_residents_freed_and_pump_disabled",
			"water_dock_sluice_isle_both_controls_disabled"]:
		game.world.flags.set_flag(flag)
	for flag: String in ["water_swim_lesson_briefed", "water_swim_stone_earned", "water_swim_saddle_recipe_learned"]:
		game.local.flags.set_flag(flag)
	var world: Node3D = WORLD.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 1200:
		await physics_frame
		if bool(world.call("shell_build_complete")):
			break
	var player: CharacterBody3D = world.get_node("Player")
	var camera: Node3D = world.get_node("CameraRig")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HARVEST.PICKUP_DATA))
	var row: Dictionary = {}
	for candidate: Dictionary in data.harvest:
		if str(candidate.id) == TARGET_ID:
			row = candidate
	var target := Vector3(float(row.position[0]), 0.0, float(row.position[2]))
	target.y = float(world.call("ground_height_at", target.x, target.z)) + 0.1
	if OS.get_cmdline_user_args().has("--swimmer"):
		await _swimmer_probe(world, player, camera)
		return
	var ok := true
	for start: Vector3 in STARTS:
		var plan: Dictionary = POCKET.plan_route(world, Vector2(start.x, start.z), Vector2(target.x, target.z))
		print("PLAN from %s -> %s points=%d" % [start, target, (plan.points as Array).size()])
	var modes := ["planned"] if OS.get_cmdline_user_args().has("--planned-only") else ["straight", "planned"]
	for mode: String in modes:
		var start: Vector3 = STARTS[0]
		start.y = float(world.call("ground_height_at", start.x, start.z)) + 0.3
		player.global_position = start
		player.velocity = Vector3.ZERO
		print("POSE probe start -> %s (%s)" % [start, mode])
		await _frames(30)
		var harvest: RefCounted = HARVEST.new()
		harvest.setup(self, world, player, camera)
		var started := Time.get_ticks_msec()
		var arrived := false
		if mode == "straight":
			arrived = await harvest._walk_to(target, TARGET_ID + " residency", 4.0)
		else:
			arrived = await PREP.planned_approach(harvest, world, player, target, TARGET_ID)
			if arrived:
				arrived = await harvest._walk_to(target, TARGET_ID + " residency", 4.0)
		harvest._stop_stick()
		print("PROBE %s arrived=%s player=%s failures=%s ms=%d" % [mode, arrived,
			player.global_position, str(harvest.failures), Time.get_ticks_msec() - started])
		if mode == "planned":
			ok = arrived
	print("PROBE RESULT %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


## DRY RUN 6 poses: player end of the straight engage drive and the chosen
## water_tidal_cradle_wild_009_0 residency (log dry_run_6_swimmer_walk_fix).
func _swimmer_probe(world: Node3D, player: CharacterBody3D, camera: Node3D) -> void:
	var start := Vector3(561.6458, 0.0, 1329.651)
	var target := Vector3(567.7319, 12.76485, 1318.479)
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 0.3
	player.global_position = start
	player.velocity = Vector3.ZERO
	print("POSE probe swimmer start -> %s target %s ground=%.2f" % [start, target,
		float(world.call("ground_height_at", target.x, target.z))])
	await _frames(30)
	var harvest: RefCounted = HARVEST.new()
	harvest.setup(self, world, player, camera)
	var arrived: bool = await PREP.planned_approach(harvest, world, player, target, "swimmer")
	var last := false
	if arrived:
		last = await harvest._walk_to(target, "swimmer last leg", 2.5)
	harvest._stop_stick()
	var dy := absf(player.global_position.y - target.y)
	var ok := arrived and last and dy < 3.0
	print("PROBE swimmer planned=%s last=%s player=%s dy=%.2f failures=%s" % [arrived, last,
		player.global_position, dy, str(harvest.failures)])
	print("PROBE RESULT %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame
