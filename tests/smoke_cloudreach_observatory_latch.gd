extends "res://tests/smoke_cloudreach_continuous.gd"

## F07#0 Summit: Observatory return latch, in the production world. Fixture
## start (disclosed): flags for the upper route and upper anchors, a level-30
## retained five, and teleports to each prompt's pad. The interactions use the
## real Interactable + interact input; the descent is walked by ordinary input.
##
##   godot --headless --path . --script tests/smoke_cloudreach_observatory_latch.gd

const TOP := Vector3(-520.0, 1080.0, 5300.0)
const FORK := Vector3(-180.0, 900.0, 4720.0)
const MID := Vector3(-350.0, 990.0, 5010.0)
const START_FLAGS: Array[String] = ["realm_key_cloudreach", "fly_traversal_unlocked", "cloudreach_crisis_learned",
	"cloudreach_upper_route_unlocked", "cloudreach_act_ii_complete", "storm_anchor_upper_west_disabled",
	"storm_anchor_upper_east_disabled", "cloudreach_upper_anchors_disabled"]


func _run() -> void:
	start_usec = Time.get_ticks_usec()
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	Engine.max_physics_steps_per_frame = 32
	accelerated = true
	output_dir = "user://observatory_latch"
	DirAccess.make_dir_recursive_absolute(output_dir)
	game = root.get_node("Game")
	game.reset_for_new_game()
	for flag: String in START_FLAGS:
		game.progression.set_flag(flag)
	for species: String in ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]:
		var member: RefCounted = SPECIES.spawn(species)
		member.set_level(30, PROGRESSION.config())
		game.party.add(member)
	game.current_realm = "cloudreach"
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	player = world.get_node("Player")
	chapter = world.get_node("CloudreachChapter")
	physical = chapter.physical_runtime()
	runtime = world.get_node("CloudreachRuntime")
	director = runtime.director
	manager = runtime.manager
	fly = player.fly_controller
	physics_frame.connect(_record_frame)
	world.get_node("InteractionArbiter").activated.connect(func(provider: Object) -> void:
		interaction_activations += 1
		last_activated_path = str(provider.get_path()))
	await _frames(30)
	var report := {}
	report["mid_ground_before"] = float(world.call("ground_height_near", MID))
	var stair := world.get_node_or_null(^"SuspendedBridges/ObservatoryLatchStair") as Node3D
	report["stair_built"] = stair != null
	report["deck_visible_before"] = stair != null and (stair.get_node(^"DeckSection1") as Node3D).visible
	# Sighting at the fork, then the latch at the summit loop's west pad.
	for step: Array in [["observatory_latch_sighting", "side_observatory_latch_sighted"],
			["observatory_return_latch", "side_observatory_latch_complete"]]:
		var prompt: Node3D = physical.get_node(str(step[0]) + "/Interactable")
		_place_near(prompt.global_position)
		await _frames(20)
		report[str(step[0])] = await _physical_action(str(step[0]), str(step[1]), false)
	await _frames(20)
	report["mid_ground_after"] = float(world.call("ground_height_near", MID))
	report["deck_visible_after"] = stair != null and (stair.get_node(^"DeckSection1") as Node3D).visible
	# Walk down from the top pad to the fork on the stair, ordinary input.
	failed = false
	_place_near(TOP)
	await _frames(30)
	var t0 := simulated_seconds
	var walked := await _walk(FORK, 2.0)
	_release()
	report["walked_down"] = walked and not failed
	report["walk_seconds"] = snappedf(simulated_seconds - t0, 0.1)
	report["end"] = str(player.global_position)
	var ok: bool = bool(report["stair_built"]) and is_nan(float(report["mid_ground_before"])) \
		and not bool(report["deck_visible_before"]) and bool(report.get("observatory_latch_sighting", false)) \
		and bool(report.get("observatory_return_latch", false)) and is_finite(float(report["mid_ground_after"])) \
		and bool(report["deck_visible_after"]) and bool(report["walked_down"])
	print("OBSERVATORY LATCH " + JSON.stringify(report))
	print("OBSERVATORY LATCH %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func _place_near(at: Vector3) -> void:
	var ground := float(world.call("ground_height_near", at))
	player.global_position = Vector3(at.x, (ground if is_finite(ground) else at.y) + 1.2, at.z)
	player.velocity = Vector3.ZERO
